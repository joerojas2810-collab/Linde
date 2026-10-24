"""Reproducible E02 native sprite compiler. Writes only its own salida.

Generated master sheet is a frozen raster source. Existing tool and walking
art are immutable inputs. No E01 assets or game scripts are changed.
"""
from pathlib import Path
import json,hashlib,colorsys,shutil
import numpy as np
from PIL import Image,ImageFilter,ImageDraw

HERE=Path(__file__).resolve()
OUT=HERE.parents[4] if HERE.parent.parent.name=='fuentes' else HERE.parents[1]
LOT=OUT/'lotes/E02_v001'; INP=LOT/'fuentes/entradas'
AS=LOT/'assets'; PV=LOT/'previews'
LAYERS=['cuerpo','piel','pelo','tunica','pantalon','botas','cinturon']
ARQS=['ligera','media','pesada']; DIRS=['frente','derecha','espalda','izquierda']
ROLES=np.array([[255,0,0,255],[0,255,0,255],[0,0,255,255],[128,128,128,255]],dtype=np.uint8)
STATES={'herramienta':4,'dano':2,'caida':2,'dormir':1}
C=48

def dump(p,x):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def im(p):return Image.open(p).convert('RGBA')
def cell(img,r,c,n=48):return img.crop((c*n,r*n,(c+1)*n,(r+1)*n))
def mask(img):return np.asarray(img)[:,:,3]>0
def dil(m,n=1):return np.asarray(Image.fromarray(m.astype('uint8')*255).filter(ImageFilter.MaxFilter(2*n+1)))>0
def cut(a,m):
 out=np.array(a).copy();out[~m]=0;return Image.fromarray(out)
def components(m):
 todo=set((int(x),int(y)) for y,x in np.argwhere(m));out=[]
 while todo:
  p=min(todo,key=lambda q:(q[1],q[0]));todo.remove(p);stack=[p];comp=[p]
  while stack:
   x,y=stack.pop()
   for dy in [-1,0,1]:
    for dx in [-1,0,1]:
     q=x+dx,y+dy
     if q in todo:todo.remove(q);stack.append(q);comp.append(q)
  out.append(comp)
 return sorted(out,key=lambda c:-len(c))
def centroid(m):
 p=np.argwhere(m)
 return p.mean(axis=0)[::-1] if p.size else np.array([24.,36.])

def palette():
 # Native palette and semantic color membership already used by the walking base.
 cols={}
 for role in LAYERS:
  a=np.asarray(im(INP/f'equipo/base/capas/{role}.png'))
  for color in set(map(tuple,a[a[:,:,3]>0])):cols.setdefault(color,set()).add(role)
 return cols

def classify(img,kind='herramienta',lying=False,row=0):
 a=np.asarray(img); layers={k:np.zeros_like(a) for k in LAYERS}
 # Tool and generated states use the existing semantic palette but different geometry.
 p=palette(); rgb=np.array([k[:3] for k in p],dtype=np.int32); keys=list(p)
 opaque=a[:,:,3]>0
 teal=opaque&(a[:,:,1]>a[:,:,0]*1.4)&(a[:,:,2]>a[:,:,0])
 top=int(np.where(teal)[0].min()) if teal.any() else int(np.where(opaque)[0].min())
 for y,x in np.argwhere(opaque):
  red,green,blue,_=map(int,a[y,x]);h,s,v=colorsys.rgb_to_hsv(red/255,green/255,blue/255)
  if kind=='herramienta':
   if h<.1 and v>.6 and s<.72: role='piel'
   elif green>red*1.4 and blue>red and v>.12:role='pelo' if y<top+13 else 'tunica'
   elif (h<.1 or h>.95) and .2<v<=.6 and s>.45:
    role='cinturon' if top+15<=y<=top+19 else 'botas' if y>=41 else 'cuerpo'
   elif blue>red*1.15 and v>=.1 and y>=41:role='pantalon'
   else:role='cuerpo'
   color=a[y,x]
  else:
   bx0,by0,bx1,by1=img.getbbox()
   in_head=(x>=bx1-17 if row==1 else x<bx0+17) and y<by0+15 if lying else y<by0+14
   # Semantic first, nearest palette second: dark generated hair must not be
   # quantized into the black outline and then mistaken for a bare scalp.
   teal_color=green>red*1.3 and blue>red*1.2 and green>blue*.65 and v>.12
   if teal_color:role='pelo' if in_head else 'tunica'
   elif .09<h<.18 and s>.35 and green>red*.74 and v>.3:role='cinturon'
   elif h<.12 and red>blue*1.3 and v>.55 and s<.82:role='piel'
   elif h<.17 and red>blue*1.3 and .18<v<=.65:role='botas'
   elif blue>red*1.15 and v>.1 and not in_head:role='pantalon'
   else:role='cuerpo'
   options=[key for key in keys if role in p[key]]
   if not options:options=keys
   choices=np.array(options,dtype=np.int32)
   j=int(np.argmin(((choices[:,:3]-np.array([red,green,blue]))**2).sum(axis=1)))
   color=choices[j].astype(np.uint8)
  layers[role][y,x]=color
 return {k:Image.fromarray(v) for k,v in layers.items()}

def separate_tool():
 source=im(INP/'personaje/herramienta.png');a=np.asarray(source);tool=np.zeros_like(a);excluded=np.zeros_like(a)
 count=[]
 for r in range(4):
  for c in range(4):
   b=np.array(cell(source,r,c)); op=b[:,:,3]>0
   val=b[:,:,:3].max(axis=2);low=b[:,:,:3].min(axis=2)
   sat=(val-low)/np.maximum(val,1)
   steel=op&(sat<.3)&(val>76)
   # Brown handle connected to steel; never classify boots/belt by color alone.
   brown=op&(b[:,:,0]>b[:,:,1]*1.2)&(b[:,:,0]>b[:,:,2]*1.2)&(val>50)&(val<180)
   region=steel.copy()
   for _ in range(10):
    nxt=region|(dil(region)&brown)
    if np.array_equal(nxt,region):break
    region=nxt
   # Thin dark edge only where adjacent to the tool, outside colored body.
   core=op&~region&(val>=51)
   edge=op&~region&(val<51)&dil(region)&~dil(core)
   region|=edge
   comps=components(region);main=np.zeros_like(region)
   if comps:
    for x,y in comps[0]:main[y,x]=True
   residual=region&~main
   tool[r*48:(r+1)*48,c*48:(c+1)*48]=np.where(main[:,:,None],b,0)
   excluded[r*48:(r+1)*48,c*48:(c+1)*48]=np.where(residual[:,:,None],b,0)
   count.append({'celda':[r,c],'pixels_hacha':int(main.sum()),'pixels_islas_excluidas':int(residual.sum())})
 body=a.copy();body[(tool[:,:,3]>0)|(excluded[:,:,3]>0)]=0
 # Preserve exact separability; do not infer invisible body underneath the handle.
 return Image.fromarray(body),Image.fromarray(tool),Image.fromarray(excluded),count

def normalize_generated():
 master=im(LOT/'fuentes/E02_estados_generado.png');w,h=master.size
 boxes=[];raw={}
 for r in range(4):
  for c in range(5):
   rect=[round(c*w/5),round(r*h/4),round((c+1)*w/5),round((r+1)*h/4)]
   part=master.crop(rect);a=np.array(part);a[a[:,:,3]<128]=0;a[a[:,:,3]>=128,3]=255;part=Image.fromarray(a)
   bbox=part.getbbox();assert bbox,(r,c)
   raw[r,c]=part.crop(bbox);boxes.append({'fila':r,'columna':c,'rect_fuente':rect,'bbox_dentro_rect':list(bbox)})
 scale=27/float(np.median([raw[r,c].height for r in range(4) for c in (0,1)]))
 outputs={s:Image.new('RGBA',(n*48,192)) for s,n in STATES.items() if s!='herramienta'}
 for r in range(4):
  for col in range(5):
   part=raw[r,col];native=part.resize((max(1,round(part.width*scale)),max(1,round(part.height*scale))),Image.Resampling.NEAREST)
   assert native.width<46 and native.height<46
   dest=Image.new('RGBA',(48,48));dest.paste(native,(24-native.width//2,47-native.height))
   state,c=('dano',col) if col<2 else ('caida',col-2) if col<4 else ('dormir',0)
   outputs[state].paste(dest,(c*48,r*48))
 dump(LOT/'fuentes/E02_recortes_generados.json',{'escala_uniforme':scale,'regla':'Altura mediana de las ocho poses de daño =27 px; misma escala para todas las poses, sin estirar por celda. Nearest, alfa umbral128, paleta existente.','rectangulos':boxes})
 return outputs

def material(source,shape):
 """Preserve indexed material using nearest occupied row and x-coordinate."""
 a=np.asarray(source);sm=mask(source);out=np.zeros((48,48,4),dtype=np.uint8)
 if not shape.any() or not sm.any():return Image.fromarray(out)
 sy=np.where(sm)[0];ty=np.where(shape)[0];rows=sorted(set(sy.tolist()))
 for y in sorted(set(ty.tolist())):
  yy=min(rows,key=lambda z:(abs(z-(sy.min()+(y-ty.min())/max(1,ty.max()-ty.min())*(sy.max()-sy.min()))),z))
  sx=np.where(sm[yy])[0];tx=np.where(shape[y])[0]
  for x in tx:
   xx=min(sx,key=lambda z:abs(z-(sx.min()+(x-tx.min())/max(1,tx.max()-tx.min())*(sx.max()-sx.min()))))
   out[y,x]=a[yy,xx]
 return Image.fromarray(out)

def hand_masks(layers,r,c):
 skin=mask(cell(layers['piel'],r,c));hair=mask(cell(layers['pelo'],r,c));head=centroid(hair)
 comps=components(skin)
 if not comps:return np.zeros_like(skin),np.zeros_like(skin)
 # Face is the component closest to the hair, with size as a tie-breaker.
 face=min(range(len(comps)),key=lambda i:(np.linalg.norm(np.mean(comps[i],axis=0)-head),-len(comps[i])))
 hands=[]
 for i,comp in enumerate(comps):
  if i==face:continue
  m=np.zeros_like(skin)
  for x,y in comp:m[y,x]=True
  hands.append(m)
 if not hands:return np.zeros_like(skin),np.zeros_like(skin)
 # Split by torso center and orientation. This is a proposal checked in compositions.
 cx=centroid(mask(cell(layers['tunica'],r,c)))[0]
 near=np.zeros_like(skin);far=np.zeros_like(skin)
 for m in hands:
  is_near=centroid(m)[0]>=cx if r!=3 else centroid(m)[0]<=cx
  if is_near:near|=m
  else:far|=m
 return near,far

def make_state(state,body,tool=None):
 n=STATES[state];root=AS/state;root.mkdir(parents=True,exist_ok=True)
 layers={k:Image.new('RGBA',(n*48,192)) for k in LAYERS}
 for r in range(4):
  for c in range(n):
   classified=classify(cell(body,r,c),state,state=='dormir' or (state=='caida' and c==1),r)
   for k in LAYERS:layers[k].paste(classified[k],(c*48,r*48))
 # Generated bases are quantized through semantic layers. Tool base retains original RGB.
 rebuilt=Image.new('RGBA',body.size)
 for k in LAYERS:
  (root/'base/capas').mkdir(parents=True,exist_ok=True)
  layers[k].save(root/f'base/capas/{k}.png');rebuilt.alpha_composite(layers[k])
 rebuilt.save(root/'base/E02_base.png')
 if state=='herramienta':assert np.array_equal(np.array(rebuilt),np.array(body))
 sheets={}
 for arq in ARQS:
  for piece in ['casco','torso','pantalones','botas','guantes','guantes_cercana','guantes_lejana']:
   sheets[arq+'/'+piece]=Image.new('RGBA',body.size)
 for piece in ['escudo','espada']:sheets['compartido/'+piece]=Image.new('RGBA',body.size)
 infos=[]
 for r in range(4):
  for c in range(n):
   b=mask(cell(rebuilt,r,c));skin=mask(cell(layers['piel'],r,c));hair=mask(cell(layers['pelo'],r,c));belt=mask(cell(layers['cinturon'],r,c))
   near,far=hand_masks(layers,r,c)
   for arq in ARQS:
    for piece,reference in [('casco','pelo'),('torso','tunica'),('pantalones','pantalon'),('botas','botas')]:
     target=mask(cell(layers[reference],r,c));shape=target.copy()
     if piece=='torso':shape=dil(target)&b&~skin&~hair&~belt
     if piece=='casco':
      # Helmet follows hair/head; use actual indexed source shape, scaled to head bbox.
      source=cell(im(INP/f'equipo/equipo_{arq}_{piece}_caminata.png'),r,0,32)
      bbox=Image.fromarray(target.astype('uint8')*255).getbbox()
      patch=Image.new('RGBA',(48,48))
      if bbox and source.getbbox():
       crop=source.crop(source.getbbox()).resize((bbox[2]-bbox[0],bbox[3]-bbox[1]),Image.Resampling.NEAREST)
       patch.paste(crop,bbox[:2])
     else:
      source=cell(im(INP/f'equipo/equipo_{arq}_{piece}_caminata.png'),r,0,32)
      if arq=='pesada' and piece in ['torso','botas']:shape|=dil(shape)&b&~skin&~hair&~belt
      patch=material(source,shape)
     sheets[arq+'/'+piece].paste(patch,(c*48,r*48))
    for suffix,m in [('guantes',near|far),('guantes_cercana',near),('guantes_lejana',far)]:
     a=np.zeros((48,48,4),dtype=np.uint8);a[m]=ROLES[0]
     for x in np.where(m.any(axis=0))[0]:
      ys=np.where(m[:,x])[0]
      if len(ys)>1:a[ys.max(),x]=ROLES[1]
     sheets[arq+'/'+suffix].paste(Image.fromarray(a),(c*48,r*48))
   # Weapon/shield stored as independent candidates; hidden in fall/sleep previews.
   torso_center=centroid(mask(cell(layers['tunica'],r,c)))
   for piece in ['escudo','espada']:
    source=cell(im(INP/f'equipo/{piece}_caminata.png'),r,0,32)
    patch=Image.new('RGBA',(48,48))
    if source.getbbox():
     small=source.crop(source.getbbox())
     hand=centroid(far if piece=='escudo' else near) if (far if piece=='escudo' else near).any() else torso_center
     if piece=='escudo' and state=='herramienta':
      # Do not anchor the shield to the raised hand holding the axe.
      hand=torso_center+np.array([3 if r in [0,3] else -2,1])
     x=int(round(hand[0]-small.width/2));y=int(round(hand[1]-small.height/2))
     x=max(1,min(46-small.width,x));y=max(1,min(46-small.height,y));patch.paste(small,(x,y))
    sheets['compartido/'+piece].paste(patch,(c*48,r*48))
   infos.append({'celda':[r,c],'bbox':list(cell(rebuilt,r,c).getbbox()),'mano_cercana_pixels':int(near.sum()),'mano_lejana_pixels':int(far.sum())})
 for arq in ARQS:
  sheets[arq+'/guantes']=Image.alpha_composite(sheets[arq+'/guantes_lejana'],sheets[arq+'/guantes_cercana'])
 for key,sheet in sheets.items():sheet.save(root/('E02_'+key.replace('/','_')+'.png'))
 if tool:tool.save(root/'E02_hacha.png')
 dump(root/'E02_estado.json',{'id':'E02_'+state,'estado':'candidato','atlas':[n*48,192],'celda':[48,48],'pivote':[24,48],
  'filas':DIRS,'columnas':n,'base':{'hoja':'base/E02_base.png','capas':{k:f'base/capas/{k}.png' for k in LAYERS}},
  'equipo':{k:'E02_'+k.replace('/','_')+'.png' for k in sheets},'herramienta':'E02_hacha.png' if tool else None,
  'cuadros_runtime_a_fuente':[1,2,3] if state=='herramienta' else list(range(n)),
  'duracion_cuadro_ms':[100,100,100] if state=='herramienta' else [300,300] if state=='dano' else None,
  'observaciones':infos,'orden':'Mano lejana detrás de túnica/torso; mano cercana y herramienta delante; pelo bajo casco; cinturón visible. Ver CONTRATO_PROPUESTO.',
  'presentacion':'Recurso y preview solamente; caída/dormir no crean eventos de juego ni tiempos nuevos.'})
 return layers,sheets

def recolor(image,pal):
 a=np.array(image);pals=json.loads((INP/'paletas.json').read_text(encoding='utf-8'))['paletas'];p=pals[pal]
 for idx,role in zip(ROLES,['principal','sombra','acento','detalle']):
  rgb=tuple(int(p.get(role,'#808080')[i:i+2],16) for i in (1,3,5))
  a[np.all(a==idx,axis=2)]=[*rgb,255]
 return Image.fromarray(a)

def compose(state,arq,r,c,options='baseline',pal='pal_vigia'):
 root=AS/state;img=Image.new('RGBA',(48,48));bare=options=='base'
 order=['b_cuerpo','b_piel','b_botas','b_pantalon','guantes_lejana','b_tunica','b_cinturon','botas','pantalones','torso','guantes_cercana']
 if r==1:order.insert(4,'escudo')
 elif state not in ['caida','dormir']:order+=['escudo']
 if options=='sin_cinturon':order.remove('b_cinturon')
 if options=='pelo_sobre_casco':order+=['casco','b_pelo']
 else:order+=['b_pelo','casco']
 if state=='herramienta':order+=['hacha']
 elif state=='dano':order.insert(order.index('b_pelo'),'espada')
 for layer in order:
  if layer.startswith('b_'):
   k=layer[2:]
   if not bare and k in ['tunica','pantalon','botas']:continue
   part=cell(im(root/f'base/capas/{k}.png'),r,c)
  elif layer=='hacha':part=cell(im(root/'E02_hacha.png'),r,c)
  else:
   if bare:continue
   if layer=='escudo' and state in ['caida','dormir']:continue
   shared=layer in ['escudo','espada'];key='compartido' if shared else arq
   part=cell(im(root/f'E02_{key}_{layer}.png'),r,c)
   part=recolor(part,'pal_escudo_madera' if layer=='escudo' else 'pal_espada_hierro' if layer=='espada' else pal)
  img.alpha_composite(part)
 return img

def previews():
 PV.mkdir(exist_ok=True)
 for state,n in STATES.items():
  for arq in ARQS:
   sheet=Image.new('RGBA',(n*48,192))
   for r in range(4):
    for c in range(n):sheet.alpha_composite(compose(state,arq,r,c),(c*48,r*48))
   sheet.save(PV/f'E02_{state}_{arq}_x1.png');sheet.resize((n*144,576),Image.Resampling.NEAREST).save(PV/f'E02_{state}_{arq}_x3.png')
   frames=[];seq=[1,2,3] if state=='herramienta' else list(range(n))
   for c in seq:
    f=Image.new('RGB',(576,144),(36,44,52))
    for r in range(4):
     pic=compose(state,arq,r,c).resize((144,144),Image.Resampling.NEAREST);f.paste(pic,(r*144,0),pic)
    frames.append(f)
   duration=[100]*3 if state=='herramienta' else [300]*n if state=='dano' else [450]*n
   frames[0].save(PV/f'E02_{state}_{arq}.gif',save_all=True,append_images=frames[1:],duration=duration,loop=0,disposal=2)
  # Four directions x three archetypes, all poses in contact at actual zoom 3.
  contact=Image.new('RGB',(n*144,3*576),(36,44,52))
  for i,a in enumerate(ARQS):
   p=im(PV/f'E02_{state}_{a}_x3.png');contact.paste(p,(0,i*576),p)
  contact.save(PV/f'E02_contacto_{state}.png')
 # Current belt/hair rules versus explicit alternatives, same poses and equipment.
 canvas=Image.new('RGB',(576,4*144),(36,44,52));d=ImageDraw.Draw(canvas)
 for r in range(4):
  for i,opt in enumerate(['baseline','sin_cinturon','pelo_sobre_casco','base']):
   p=compose('herramienta','pesada',r,2,opt).resize((144,144),Image.Resampling.NEAREST);canvas.paste(p,(i*144,r*144),p)
   d.text((i*144+2,r*144+3),opt[:21],fill='white')
 canvas.save(PV/'E02_oclusiones_alternativas.png')

def main():
 AS.mkdir(parents=True,exist_ok=True)
 sources=[p for p in INP.rglob('*') if p.is_file() and p.suffix not in ['.import','.uid'] and '.godot' not in p.parts and '__pycache__' not in p.parts]
 dump(LOT/'fuentes/E02_hashes_entradas.json',{p.relative_to(INP).as_posix():sha(p) for p in sources})
 body,tool,excluded,counts=separate_tool()
 root=AS/'herramienta';root.mkdir(exist_ok=True)
 body.save(LOT/'fuentes/E02_herramienta_sin_hacha.png')
 excluded.save(LOT/'fuentes/E02_islas_fuente_excluidas.png')
 # Exact reconstruction check (tool extraction does not repaint original body).
 reconstructed=body.copy();reconstructed.alpha_composite(tool);reconstructed.alpha_composite(excluded)
 assert np.array_equal(np.array(reconstructed),np.array(im(INP/'personaje/herramienta.png')))
 dump(LOT/'fuentes/E02_separacion_hacha.json',{'reconstruccion_original_exacta_con_islas_excluidas':True,'por_celda':counts,
   'limite':'El original solo representa hacha. No reutilizarla como pico. No se reconstruye anatomía oculta; propuesta de anclas en manifiestos.'})
 states=normalize_generated();states['herramienta']=body
 for state in STATES:make_state(state,states[state],tool if state=='herramienta' else None)
 previews()
 print('E02: 4 estados, capas base, equipo y hacha separados; previews producidos')

if __name__=='__main__':main()
