"""Independent structural checks for variable-width state atlases."""
from pathlib import Path
import json,hashlib,platform
import numpy as np
from PIL import Image,__version__ as pillow_version
HERE=Path(__file__).resolve();OUT=HERE.parents[4] if HERE.parent.parent.name=='fuentes' else HERE.parents[1];LOT=OUT/'lotes/E02_v001'
def im(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 records=[];checks=0;empty=[];borders=[]
 roles={(255,0,0,255),(0,255,0,255),(0,0,255,255),(128,128,128,255)}
 sourcehash=json.loads((LOT/'fuentes/E02_hashes_entradas.json').read_text(encoding='utf-8'))
 for path,h in sourcehash.items():
  assert sha(LOT/'fuentes/entradas'/path)==h,path
  checks+=1
 for state,n in [('herramienta',4),('dano',2),('caida',2),('dormir',1)]:
  root=LOT/'assets'/state;m=json.loads((root/'E02_estado.json').read_text(encoding='utf-8'))
  assert m['atlas']==[n*48,192] and m['pivote']==[24,48];checks+=1
  arrays=[np.array(im(root/p)) for p in m['base']['capas'].values()]
  occupied=np.stack([a[:,:,3]>0 for a in arrays]);assert occupied.sum(axis=0).max()==1;checks+=1
  rebuilt=sum((a.astype(np.uint16) for a in arrays)).astype(np.uint8)
  assert np.array_equal(rebuilt,np.array(im(root/m['base']['hoja'])));checks+=1
  for path in root.rglob('*.png'):
   a=np.array(im(path));assert a.shape==(192,n*48,4),str(path)
   assert set(np.unique(a[:,:,3])).issubset({0,255}),str(path);checks+=2
   is_index=path.name.startswith('E02_ligera_') or path.name.startswith('E02_media_') or path.name.startswith('E02_pesada_') or path.name.startswith('E02_compartido_')
   if is_index:
    assert set(map(tuple,a[a[:,:,3]>0])).issubset(roles),str(path);checks+=1
   boxes={}
   for r in range(4):
    for c in range(n):
     part=a[r*48:(r+1)*48,c*48:(c+1)*48];alpha=part[:,:,3]>0
     b=Image.fromarray(part).getbbox();boxes[f'{r},{c}']=list(b) if b else None
     if not b:empty.append({'archivo':path.relative_to(LOT).as_posix(),'celda':[r,c],'motivo':'Capa semántica o pieza completamente oculta/ausente en esta pose; revisar composición, nunca afirmar 16 cuadros universales.'})
     if alpha[0].any() or alpha[-1].any() or alpha[:,0].any() or alpha[:,-1].any():borders.append({'archivo':path.relative_to(LOT).as_posix(),'celda':[r,c]})
     if path.name=='E02_base.png':assert b,(state,r,c);checks+=1
   records.append({'archivo':path.relative_to(LOT).as_posix(),'sha256':sha(path),'dimensiones':[n*48,192],'colores_opacos':len(set(map(tuple,a[a[:,:,3]>0]))),'bbox_por_celda':boxes,'indice':is_index})
  # Combined gloves exactly equal the two separately ordered hand layers.
  for arq in ['ligera','media','pesada']:
   near=np.array(im(root/f'E02_{arq}_guantes_cercana.png'));far=np.array(im(root/f'E02_{arq}_guantes_lejana.png'))
   assert not ((near[:,:,3]>0)&(far[:,:,3]>0)).any()
   assert np.array_equal((near.astype(np.uint16)+far).astype(np.uint8),np.array(im(root/f'E02_{arq}_guantes.png')));checks+=2
 # Recover the tool source without any resampling or recoloring.
 p=LOT/'fuentes';a=im(p/'E02_herramienta_sin_hacha.png');a.alpha_composite(im(LOT/'assets/herramienta/E02_hacha.png'));a.alpha_composite(im(p/'E02_islas_fuente_excluidas.png'))
 assert np.array_equal(np.array(a),np.array(im(p/'entradas/personaje/herramienta.png')));checks+=1
 # Runtime compatibility accepted by user: 3 source poses, exact old duration.
 m=json.loads((LOT/'assets/herramienta/E02_estado.json').read_text(encoding='utf-8'))
 assert m['cuadros_runtime_a_fuente']==[1,2,3] and sum(m['duracion_cuadro_ms'])==300;checks+=1
 dump={'resultado':'CORRECTO','comprobaciones':checks,'python':platform.python_version(),'pillow':pillow_version,'numpy':np.__version__,
       'png_nativos':len(records),'recursos':records,'celdas_transparentes_declaradas':empty,'contenido_en_borde':borders,
       'limites':['Celdas transparentes de capas aisladas son legítimas, no equivalen a pieza flotante ni calidad aprobada.','El material ajustado y las armas ancladas requieren revisión visual de oclusión.','No demuestra integración de eventos caída/dormir ni red real.']}
 (LOT/'validacion').mkdir(exist_ok=True)
 (LOT/'validacion/E02_resultados.json').write_text(json.dumps(dump,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({'resultado':'CORRECTO','comprobaciones':checks,'png_nativos':len(records),'celdas_transparentes':len(empty),'bordes':len(borders)},ensure_ascii=False))
if __name__=='__main__':main()
