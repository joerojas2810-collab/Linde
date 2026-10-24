"""E01: compile isolated, reproducible overrides; never run the upstream derivator.

Python 3 + Pillow + NumPy. Writes only next to this script in lotes/E01_v001.
First run freezes inputs from the supplied snapshot; subsequent builds use them.
The JSON pixel overrides are the editable native source of the repaired cells.
"""
from pathlib import Path
import hashlib, json, shutil, sys, platform
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, __version__ as pillow_version

HERE=Path(__file__).resolve()
OUT=HERE.parents[4] if HERE.parent.name=='herramientas' and HERE.parent.parent.name=='fuentes' else HERE.parent
PKG=OUT.parents[1]
LOT=OUT/'lotes/E01_v001'
FREEZE=LOT/'fuentes/entradas'
SRC=FREEZE/'ataque'
C=48
ROLES=[(255,0,0,255),(0,255,0,255),(0,0,255,255),(128,128,128,255)]
ARQS=['ligera','media','pesada']
DIRS=['frente','derecha','espalda','izquierda']
EXPECTED={'equipo_ligera_torso_ataque.png':[[0,2]],
          'equipo_ligera_botas_ataque.png':[[1,2],[3,2]],
          'equipo_media_torso_ataque.png':[[0,2]],
          'equipo_media_botas_ataque.png':[[1,2]],
          'equipo_pesada_torso_ataque.png':[[0,2],[1,2],[1,3]],
          'escudo_ataque.png':[[0,2]]}

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,data):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def image(p): return Image.open(p).convert('RGBA')
def cell(im,r,c,n=C): return im.crop((c*n,r*n,(c+1)*n,(r+1)*n))
def mask(im): return np.asarray(im)[:,:,3]>0
def dilate(m,n=1): return np.asarray(Image.fromarray(m.astype('uint8')*255).filter(ImageFilter.MaxFilter(2*n+1)))>0
def readlayer(layer,r,c): return cell(image(SRC/f'base/capas/{layer}.png'),r,c)

def freeze():
    if FREEZE.exists(): return
    snapshot=PKG/'base_proyecto/Linde/cenital/arte/equipo'
    shutil.copytree(snapshot/'ataque',SRC)
    (FREEZE/'caminata').mkdir()
    for name in EXPECTED:
        walk=name.replace('_ataque','_caminata')
        shutil.copy2(snapshot/walk,FREEZE/'caminata'/walk)
    shutil.copy2(PKG/'base_proyecto/Linde/cenital/datos/equipo/paletas.json',FREEZE/'paletas.json')
    shutil.copy2(PKG/'entradas/arte-entregado/equipo_indice_01/LEEME.md',FREEZE/'PROCEDENCIA_EQUIPO_ORIGINAL.md')
    shutil.copy2(PKG/'base_proyecto/herramientas/arte/validar_hoja.gd',FREEZE/'validar_hoja_original.gd')
    paths=[p for p in FREEZE.rglob('*') if p.is_file()]
    dump(LOT/'fuentes/E01_hashes_entradas.json',{p.relative_to(FREEZE).as_posix():sha(p) for p in paths})

def torso_geometry(arq,r,c):
    """Scanline native-pixel fit to the attack body; protect hair, skin and belt."""
    target=mask(readlayer('tunica',r,c)); body=mask(cell(image(SRC/'base/ataque_sin_espada.png'),r,c))
    skin=mask(readlayer('piel',r,c)); hair=mask(readlayer('pelo',r,c)); belt=mask(readlayer('cinturon',r,c))
    y0,y1=np.where(target)[0].min(),np.where(target)[0].max()
    shape=target.copy()
    # Fill scanline gaps in the garment but keep the sword-arm skin unobscured.
    for y in range(y0,y1+1):
        xs=np.where(target[y])[0]
        if xs.size: shape[y,xs.min():xs.max()+1]=True
    if arq=='pesada':
        # Pauldron width follows existing heavy silhouette, at most one native pixel.
        extra=dilate(shape)&body
        extra[y0+4:]=False
        shape|=extra
    shape&=body&~skin&~hair&~belt
    shape|=target # all pixels of the base layer that the compositor hides are replaced
    return shape

def project_material(source,shape):
    """Transport source indexed material by occupied scanline, without interpolation."""
    a=np.asarray(source); sm=mask(source); sy=np.where(sm)[0]; ty=np.where(shape)[0]
    out=np.zeros((48,48,4),dtype=np.uint8)
    for y in sorted(set(ty.tolist())):
        f=(y-ty.min())/max(1,ty.max()-ty.min())
        yy=min(set(sy.tolist()),key=lambda k:(abs(k-(sy.min()+f*(sy.max()-sy.min()))),k))
        sx=np.where(sm[yy])[0]; tx=np.where(shape[y])[0]
        for x in tx:
            q=(x-tx.min())/max(1,tx.max()-tx.min())
            xx=min(sx,key=lambda k:(abs(int(k)-(sx.min()+q*(sx.max()-sx.min()))),int(k)))
            out[y,x]=a[yy,xx]
    return Image.fromarray(out)

def boot_geometry(arq,r,c):
    # Native feet + one-pixel ankle area, split into two feet; no translated rigid boot.
    body=mask(cell(image(SRC/'base/ataque_sin_espada.png'),r,c))
    shape=mask(readlayer('botas',r,c)).copy()
    for y in (44,45,46):
        xs=np.where(shape[y])[0]
        if xs.size:
            for group in np.split(xs,np.where(np.diff(xs)>2)[0]+1):
                shape[y,group.min():group.max()+1]=True
    if arq=='media':
        # Ankle guard stays on body pixels immediately above each foot.
        top=np.zeros_like(shape); top[:-1]=shape[1:]
        shape|=top&body
    return shape&body

def make_overrides(man):
    path=LOT/'fuentes/E01_overrides.json'
    if path.exists(): return json.loads(path.read_text(encoding='utf-8'))
    records=[]
    for name,coords in EXPECTED.items():
        walk=image(FREEZE/'caminata'/name.replace('_ataque','_caminata'))
        for r,c in coords:
            if name.startswith('escudo'):
                # Concealed free hand: use a documented torso anchor, not a fictitious measured hand.
                patch=Image.new('RGBA',(48,48))
                shield=cell(walk,0,0,32)
                patch.paste(shield,(4,16))
                method='escudo de caminata frente/0 trasladado [4,16]; agarre oculto propuesto, no medido; borde superior debajo de cara'
            else:
                arq=name.split('_')[1]; part=name.split('_')[2]
                f=int(man['seguimiento'][arq+'/'+part][f'{r},{c}']['cuadro_caminata'])
                source=cell(walk,r,f,32)
                shape=torso_geometry(arq,r,c) if part=='torso' else boot_geometry(arq,r,c)
                patch=project_material(source,shape)
                method=f'material nativo caminata fila {r} cuadro {f}, reproyectado por filas a {part} de ataque'
            pixels=[[x,y,*patch.getpixel((x,y))[:3]] for y in range(48) for x in range(48) if patch.getpixel((x,y))[3]]
            records.append({'id':f'E01_{name[:-4]}_{r}_{c}','archivo':name,'celda':[r,c],
                            'metodo':method,'pixels_xy_rgb':pixels})
    result={'schema_version':1,'descripcion':'Coordenadas locales enteras cero-base. Cada registro reemplaza SOLO una celda vacía. Alfa opaco implícito 255; el resto 0. Fuente editable definitiva.',
            'overrides':records}
    dump(path,result)
    return result

def extract_trail():
    """Recover discarded source pixels, no new slash or damage geometry."""
    orig=np.asarray(image(SRC/'referencia/ataque.png'))
    body=np.asarray(image(SRC/'base/ataque_sin_espada.png'))
    sword=np.asarray(image(SRC/'espada_ataque.png'))
    valid=(orig[:,:,3]>0)&(body[:,:,3]==0)&(sword[:,:,3]==0)
    for k in range(4):
        valid[k*48,:]=False; valid[k*48+47,:]=False
        valid[:,k*48]=False; valid[:,k*48+47]=False
    result=orig.copy(); result[~valid]=0
    im=Image.fromarray(result)
    counts={f'{r},{c}':int(mask(cell(im,r,c)).sum()) for r in range(4) for c in range(4) if mask(cell(im,r,c)).any()}
    expected={'0,3':13,'1,2':12,'1,3':41,'2,3':24,'3,1':12}
    assert counts==expected,(counts,expected)
    return im,counts

def recolor(im,palette):
    a=np.asarray(im).copy()
    for idx,key in zip(ROLES,['principal','sombra','acento','detalle']):
        hx=palette.get(key,'#808080').lstrip('#')
        a[np.all(a==idx,axis=2)]=[int(hx[i:i+2],16) for i in (0,2,4)]+[255]
    return Image.fromarray(a)

def compose(root,arq,r,c,palette='pal_vigia',equipped=True,shield=True,trail=True,only_override=None):
    man=json.loads((SRC/'manifiesto.json').read_text(encoding='utf-8'))
    pals=json.loads((FREEZE/'paletas.json').read_text(encoding='utf-8'))['paletas']
    order=['b_cuerpo','b_piel','b_botas','b_pantalon']
    if r==1 and shield: order+=['escudo']
    if r==3: order+=['espada']
    order+=['b_tunica','b_cinturon','botas','pantalones','torso','guantes']
    if r!=1 and shield: order+=['escudo']
    if r!=3: order+=['espada']
    # Existing manifest promotes the sword for all 16 cells.
    if f'{r},{c}' in man['espada_delante']:
        order.remove('espada'); order+=['espada']
    order+=['b_pelo','casco']
    pic=Image.new('RGBA',(48,48))
    pending={key:coords for key,coords in EXPECTED.items()} if root==SRC else {}
    for role in order:
        if role.startswith('b_'):
            piece=role[2:]
            hides={'tunica':'torso','pantalon':'pantalones','botas':'botas'}
            fn=f'equipo_{arq}_{hides.get(piece,"")}_ataque.png'
            if equipped and piece in hides and ([r,c] not in pending.get(fn,[]) or fn==only_override): continue
            layer=readlayer(piece,r,c)
        else:
            if not equipped and role not in ['espada','escudo']: continue
            fn=f'{role}_ataque.png' if role in ['espada','escudo'] else f'equipo_{arq}_{role}_ataque.png'
            if [r,c] in pending.get(fn,[]) and fn!=only_override: continue
            layer=cell(image((LOT/'assets' if fn==only_override else root)/fn),r,c)
            pal='pal_espada_hierro' if role=='espada' else 'pal_escudo_madera' if role=='escudo' else palette
            layer=recolor(layer,pals[pal])
        pic.alpha_composite(layer)
    if trail and (LOT/'assets/E01_estela_ataque.png').exists():
        pic.alpha_composite(cell(image(LOT/'assets/E01_estela_ataque.png'),r,c))
    return pic

def previews():
    pv=LOT/'previews'; pv.mkdir(exist_ok=True)
    # A comparison for every changed cell, composed on base with the actual hiding rules.
    canvas=Image.new('RGB',(900,9*164+40),(32,39,47)); d=ImageDraw.Draw(canvas)
    d.text((12,12),'E01 | antes / candidato / pieza indice / diferencia | x3 nearest',fill='white')
    for i,rec in enumerate(json.loads((LOT/'fuentes/E01_overrides.json').read_text(encoding='utf-8'))['overrides']):
        r,c=rec['celda']; name=rec['archivo']; arq='media' if name.startswith('escudo') else name.split('_')[1]
        y=40+i*164
        d.text((8,y+10),f'{name}\n[{r},{c}]',fill='white')
        before=compose(SRC,arq,r,c,trail=False); after=compose(SRC,arq,r,c,trail=False,only_override=name)
        patch=cell(image(LOT/'assets'/name),r,c)
        diff=Image.new('RGBA',(48,48)); diff.paste((255,215,80,255),(0,0,48,48),patch.getchannel('A'))
        for j,im in enumerate([before,after,patch,diff]):
            pic=im.resize((144,144),Image.Resampling.NEAREST); canvas.paste(pic,(300+j*148,y),pic)
    canvas.save(pv/'E01_comparacion_nueve_celdas.png')
    for arq in ARQS:
        for pal in ['pal_vigia','pal_zarzal','pal_albor']:
            sheet=Image.new('RGBA',(192,192))
            for r in range(4):
                for c in range(4): sheet.alpha_composite(compose(LOT/'assets',arq,r,c,pal),(c*48,r*48))
            sheet.save(pv/f'E01_compuesto_{arq}_{pal}_x1.png')
            sheet.resize((576,576),Image.Resampling.NEAREST).save(pv/f'E01_compuesto_{arq}_{pal}_x3.png')
            frames=[]
            for c in range(4):
                frame=Image.new('RGB',(4*144,144),(36,44,52))
                for r in range(4):
                    pic=compose(LOT/'assets',arq,r,c,pal).resize((144,144),Image.Resampling.NEAREST)
                    frame.paste(pic,(r*144,0),pic)
                frames.append(frame)
            # Actual attack phase lengths, in GIF's 10 ms resolution: 50,50,100,250 ms.
            frames[0].save(pv/f'E01_ciclo_{arq}_{pal}.gif',save_all=True,append_images=frames[1:],duration=[50,50,100,250],loop=0,disposal=2)
    # Shield compatibility and slot hiding are also inspected without helmet/full equipment.
    sheet=Image.new('RGB',(576,288),(36,44,52))
    for equipped in [False,True]:
        for r in range(4):
            pic=compose(LOT/'assets','media',r,2,equipped=equipped).resize((144,144),Image.Resampling.NEAREST)
            sheet.paste(pic,(r*144,144*int(equipped)),pic)
    sheet.save(pv/'E01_base_y_equipo_impacto_x3.png')
    sheet=Image.new('RGB',(576,3*144),(36,44,52))
    for i,arq in enumerate(ARQS):
        for r in range(4):
            pic=compose(LOT/'assets',arq,r,2,shield=False).resize((144,144),Image.Resampling.NEAREST)
            sheet.paste(pic,(r*144,i*144),pic)
    sheet.save(pv/'E01_torsos_sin_escudo_x3.png')

def validate(man):
    checks=[]; changes=[]; same=0
    expected_inputs=json.loads((LOT/'fuentes/E01_hashes_entradas.json').read_text(encoding='utf-8'))
    assert all(sha(FREEZE/p)==h for p,h in expected_inputs.items()),'frozen source changed'
    for arq,pieces in man['hojas'].items():
        for part,meta in pieces.items():
            fn=meta['archivo']; old=image(SRC/fn); new=image(LOT/'assets'/fn)
            assert new.size==(192,192)
            a=np.asarray(new); opaque=a[:,:,3]>0
            assert set(np.unique(a[:,:,3])).issubset({0,255})
            assert set(map(tuple,a[opaque])).issubset(set(ROLES))
            changed=[]
            for r in range(4):
                for c in range(4):
                    before=np.asarray(cell(old,r,c)); after=np.asarray(cell(new,r,c))
                    cm=after[:,:,3]>0
                    assert cm.any(),(fn,r,c,'empty')
                    assert not(cm[0].any() or cm[-1].any() or cm[:,0].any() or cm[:,-1].any()),(fn,r,c,'border')
                    b=mask(cell(image(SRC/'referencia/ataque.png'),r,c))
                    outside=int((cm&~dilate(b,3)).sum())
                    assert outside==0,(fn,r,c,'outside 3',outside)
                    if not np.array_equal(before,after):
                        changed.append([r,c]); assert not before[:,:,3].any(),(fn,r,c,'was accepted')
                        changes.append({'archivo':fn,'celda':[r,c],'pixels_antes':int((before[:,:,3]>0).sum()),
                                        'pixels_despues':int(cm.sum()),'bbox':list(cell(new,r,c).getbbox()),
                                        'fuera_silueta_margen_1':int((cm&~dilate(b,1)).sum()),
                                        'fuera_silueta_margen_3':outside})
                    else: same+=1
            assert changed==EXPECTED.get(fn,[]),(fn,changed)
            checks.append({'archivo':fn,'sha256':sha(LOT/'assets'/fn),'celdas_cambiadas':changed,
                           'estructura':'correcta','indices':'correctos','alfa':'binaria','margen_1':'correcto','silueta_margen_3':'correcta'})
    assert len(changes)==9 and same==263
    result={'estado':'validado_estructural','python':platform.python_version(),'pillow':pillow_version,'numpy':np.__version__,
            'hojas':checks,'celdas_cambiadas':changes,'celdas_intactas':same,'celdas_totales':272,
            'entradas_inmutables':True,'limitaciones':['No valida calidad artística, agarre oculto ni render/red en Godot.','IoU del seguimiento rígido original no se reutiliza como aprobación de estas máscaras ajustadas.']}
    dump(LOT/'validacion/E01_resultados.json',result)
    return result

def main():
    for f in ['assets','fuentes','previews','validacion']: (LOT/f).mkdir(parents=True,exist_ok=True)
    freeze()
    man=json.loads((SRC/'manifiesto.json').read_text(encoding='utf-8'))
    # Copy eleven unmodified sheets byte for byte; six complete sheets receive only nine overrides.
    for arq,pieces in man['hojas'].items():
        for part,meta in pieces.items():
            assert sha(SRC/meta['archivo'])==meta['sha256'],meta['archivo']
            shutil.copy2(SRC/meta['archivo'],LOT/'assets'/meta['archivo'])
    shutil.copytree(SRC/'base',LOT/'assets/base',dirs_exist_ok=True)
    overrides=make_overrides(man)
    for rec in overrides['overrides']:
        fn=rec['archivo']; r,c=rec['celda']; im=image(LOT/'assets'/fn)
        assert not cell(im,r,c).getbbox(),'refusing to overwrite accepted cell'
        patch=Image.new('RGBA',(48,48))
        for x,y,red,green,blue in rec['pixels_xy_rgb']: patch.putpixel((x,y),(red,green,blue,255))
        im.paste(patch,(c*48,r*48)); im.save(LOT/'assets'/fn)
    trail,counts=extract_trail(); trail.save(LOT/'assets/E01_estela_ataque.png')
    dump(LOT/'fuentes/E01_estela.json',{'metodo':'píxeles originales menos cuerpo sin espada menos espada aceptada, excluyendo borde contractual','celdas_pixels':counts,
         'ancla':[24,48],'atlas':[192,192],'celda':[48,48],'capa':'propuesta sobre espada; no impacto ni hitbox','filas':DIRS,
         'fases':['preparado','anticipacion','impacto','recuperacion'],'duracion_ms':[50,50,100,250],
         'nota':'Se conserva incluso [3,1] anticipacion del original; retemporizar requiere decisión del integrador.'})
    result=validate(man)
    previews()
    proposed=json.loads(json.dumps(man))
    proposed['_nota']='E01_v001 CANDIDATO. Cambios aislados de nueve celdas; requiere revisión de usuario e integración. Estadísticas de seguimiento históricas no describen los overrides.'
    for arq,pieces in proposed['hojas'].items():
        for part,meta in pieces.items():
            fn=meta['archivo']; meta['sha256']=sha(LOT/'assets'/fn); meta['pendientes']=[]
            meta['estado']='validado_estructural_candidato'
    proposed['seguimiento_historico']=proposed.pop('seguimiento')
    proposed['validacion_historica']=proposed.pop('validacion')
    proposed['validacion']={'informe':'../validacion/E01_resultados.json','nota':'Verifica invariantes; no equivale a aprobación artística.'}
    proposed['overrides']=[{'id':r['id'],'archivo':r['archivo'],'celda':r['celda']} for r in overrides['overrides']]
    proposed['efecto_estela_propuesto']={'archivo':'E01_estela_ataque.png','sha256':sha(LOT/'assets/E01_estela_ataque.png'),'contrato':'../fuentes/E01_estela.json'}
    dump(LOT/'assets/E01_manifiesto_ataque_propuesto.json',proposed)
    print(json.dumps({'hojas':len(result['hojas']),'celdas_corregidas':9,'celdas_intactas':263,'estela_pixels':sum(counts.values()),'estado':'validado_estructural'},ensure_ascii=False))

if __name__=='__main__': main()
