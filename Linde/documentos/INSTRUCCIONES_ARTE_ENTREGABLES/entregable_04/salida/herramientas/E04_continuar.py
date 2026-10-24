"""E04 v002: reuse only existing sources; periodic 47-pattern terrain and native trees.
No writes outside this deliverable, no generation service, no gameplay edits.
"""
from pathlib import Path
import json,hashlib,shutil
import numpy as np
from PIL import Image,ImageFilter
HERE=Path(__file__).resolve();OUT=HERE.parents[1];LOT=OUT/'lotes/E04_v002';A=LOT/'assets';S=LOT/'fuentes/entradas/assets';PV=LOT/'previews'
def image(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def canonical(m):
 for a,b,d in [(1,2,16),(2,4,32),(4,8,64),(8,1,128)]:
  if not(m&a and m&b):m&=~d
 return m
def periodic(im):
 a=np.array(im);a[-1]=a[0];a[:,-1]=a[:,0];return a
def shape(m):
 out=np.ones((16,16),bool)
 for bit,sl in [(1,np.s_[:2,:]),(2,np.s_[:,14:]),(4,np.s_[14:,:]),(8,np.s_[:,:2])]:
  if not m&bit:out[sl]=False
 for a,b,d,ys,xs in [(1,8,128,slice(0,2),slice(0,2)),(1,2,16,slice(0,2),slice(14,16)),(4,8,64,slice(14,16),slice(0,2)),(4,2,32,slice(14,16),slice(14,16))]:
  if m&a and m&b and not m&d:out[ys,xs]=False
 return out
def neigh(g,x,y,val):
 m=0
 for dx,dy,bit in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8),(1,-1,16),(1,1,32),(-1,1,64),(-1,-1,128)]:
  if 0<=x+dx<g.shape[1] and 0<=y+dy<g.shape[0] and g[y+dy,x+dx]==val:m|=bit
 return canonical(m)

def terrain():
 patterns=sorted({canonical(m) for m in range(256)});assert len(patterns)==47
 grass=periodic(image(S/'grass.png'));Image.fromarray(grass).save(A/'E04_grass_periodica.png')
 definitions={'path':('path_fill','grass'),'water':('water_fill','grass'),'ruins':('floor_ruins','grass'),'wall':('wall_stone','floor_ruins')}
 mappings={};tiles={};sources={}
 for kind,(fg,bg) in definitions.items():
  f=periodic(image(S/f'{fg}.png'));b=periodic(image(S/f'{bg}.png'))
  atlas=Image.new('RGBA',(128,96));ms=Image.new('RGBA',(128,96));mapping={};tiles[kind]={}
  for i,m in enumerate(patterns):
   semantic=shape(m);out=np.where(semantic[:,:,None],f,b)
   if kind=='water':
    pad=np.pad(semantic,1,mode='edge');interior=semantic&pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]
    ring=semantic&~interior;shore=periodic(image(S/'path_fill.png'));out[ring]=shore[ring]
   tile=Image.fromarray(out);pos=((i%8)*16,(i//8)*16);atlas.paste(tile,pos)
   test=np.zeros((16,16,4),np.uint8);test[semantic]=[255,255,255,255];ms.paste(Image.fromarray(test),pos)
   tiles[kind][m]=out;mapping[str(m)]=[i%8,i//8]
  atlas.save(A/f'E04_{kind}_47.png');ms.save(A/f'E04_{kind}_mascaras.png')
  dump(A/f'E04_{kind}_conexiones.json',{'id':f'E04_{kind}_47_v002','celda':[16,16],'atlas':[128,96],'patrones':47,'mapping':mapping,
   'bits':{'n':1,'e':2,'s':4,'w':8,'ne':16,'se':32,'sw':64,'nw':128},'normalizacion':'Diagonal solo si existen las dos cardinales.','procedencia':{'textura':fg+'.png','fondo':bg+'.png','sha256_textura':sha(S/f'{fg}.png'),'sha256_fondo':sha(S/f'{bg}.png')},
   'cambios':'Composición por máscara topológica; último borde copia el primero para continuidad. El original no se modifica.','slot_no_usado':[7,5]})
  mappings[kind]=mapping
  atlas.resize((512,384),Image.Resampling.NEAREST).save(PV/f'E04_{kind}_47.png')
  sources[kind]=[fg,bg]
 # Verify all legal horizontal/vertical interfaces of two adjacent cells in 4x3 / 3x4 binary neighborhoods.
 checks=0
 for bits in range(4096):
  g=np.array([(bits>>i)&1 for i in range(12)],np.uint8).reshape(3,4)
  if g[1,1] and g[1,2]:
   left=neigh(g,1,1,1);right=neigh(g,2,1,1)
   assert np.array_equal(shape(left)[:,-1],shape(right)[:,0])
   for kind in tiles:assert np.array_equal(tiles[kind][left][:,-1],tiles[kind][right][:,0]),(kind,left,right)
   checks+=5
  g=g.T
  if g[1,1] and g[2,1]:
   top=neigh(g,1,1,1);bottom=neigh(g,1,2,1)
   assert np.array_equal(shape(top)[-1],shape(bottom)[0])
   for kind in tiles:assert np.array_equal(tiles[kind][top][-1],tiles[kind][bottom][0]),(kind,top,bottom)
   checks+=5
 # Water animates only interior pixels; fixed shore and seam borders.
 base=np.array(image(S/'water_fill.png'));anim=Image.new('RGBA',(64,16))
 for i,dx in enumerate([0,1,2,1]):
  frame=periodic(Image.fromarray(np.roll(base,dx,axis=1)));anim.paste(Image.fromarray(frame),(i*16,0))
 anim.save(A/'E04_water_anim_propuesto.png')
 # Full 47-pattern animated water atlas, all frames share land/shore exactly.
 animated=Image.new('RGBA',(512,96))
 for frame in range(4):
  fill=np.array(anim.crop((frame*16,0,(frame+1)*16,16)))
  for i,m in enumerate(patterns):
   sem=shape(m);pad=np.pad(sem,1,mode='edge');inter=sem&pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:]
   pic=tiles['water'][m].copy();pic[inter]=fill[inter]
   animated.paste(Image.fromarray(pic),(frame*128+(i%8)*16,(i//8)*16))
 animated.save(A/'E04_water_47_anim.png')
 return checks,patterns,mappings

def trees():
 master=image(LOT/'fuentes/entradas/originales/objetos.png');conf=json.loads((LOT/'fuentes/entradas/config.json').read_text(encoding='utf-8'))[0]
 metadata=[]
 for name in ['tree_broadleaf','tree_pine','tree_fruit']:
  i=conf['ids'].index(name);x,y,w,h=map(int,conf['rects'][i]);crop=master.crop((x,y,x+w,y+h));a=np.array(crop);a[a[:,:,3]<128]=0;a[a[:,:,3]>=128,3]=255
  crop=Image.fromarray(a);bbox=crop.getbbox();crop=crop.crop(bbox);ratio=min(60/crop.width,60/crop.height)
  crop=crop.resize((round(crop.width*ratio),round(crop.height*ratio)),Image.Resampling.NEAREST)
  dst=Image.new('RGBA',(64,64));dst.paste(crop,(32-crop.width//2,62-crop.height));dst.save(A/f'E04_{name}_64.png')
  a=np.array(dst);brown=(a[:,:,0]>a[:,:,1]*1.2)&(a[:,:,0]>a[:,:,2]*1.2)&(a[:,:,3]>0)
  ys=np.where(brown)[0];split=int(ys.min()) if ys.size else 50
  canopy=np.indices(a.shape[:2])[0]<split
  crown=a.copy();crown[~canopy]=0;trunk=a.copy();trunk[canopy]=0
  assert np.array_equal((crown.astype(np.uint16)+trunk).astype(np.uint8),a)
  Image.fromarray(crown).save(A/f'E04_{name}_64_copa.png');Image.fromarray(trunk).save(A/f'E04_{name}_64_tronco.png')
  metadata.append({'id':f'E04_{name}_64','canvas':[64,64],'pivote':[32,62],'escala_dibujada':1,'celda_colision_existente':[16,16],
   'fuente':'fuentes/entradas/originales/objetos.png','sha256_fuente':sha(LOT/'fuentes/entradas/originales/objetos.png'),'rect_fuente':[x,y,w,h],'bbox_core_fuente':list(bbox),'escala_conversion':ratio,
   'nota':'Reextracción de fuente existente, no ampliación48→64. Propuesta de tamaño nativo; mantener original48 como alternativa.'})
 dump(A/'E04_arboles_64.json',metadata)
 return 3

def main():
 for p in [A,PV,LOT/'validacion']:p.mkdir(exist_ok=True)
 
 for p in (LOT/'fuentes/reutilizados_v001').iterdir():
  if p.is_file() and p.name!='RECIBO.json':shutil.copy2(p,A/p.name)
 checks,patterns,mapping=terrain();checks+=trees()
 objects={}
 for p in A.glob('E04_*.png'):
  if any(s in p.stem for s in ['47','mascaras','water_anim','grass_periodica']):continue
  obj=image(p);b=obj.getbbox()
  if b:
   base=p.stem.replace('_copa','').replace('_tronco','');base_path=A/(base+'.png');anchor=image(base_path).getbbox() if base_path.exists() else b
   objects[p.stem]={'archivo':p.name,'canvas':list(obj.size),'bbox':list(b),'pivote':[32,62] if '_64' in p.stem else [(anchor[0]+anchor[2])//2,anchor[3]],'escala_dibujada':1}
 dump(A/'E04_objetos.json',objects)
 dump(A/'E04_catalogo.json',{'id':'E04_v002','celda':16,'patrones':47,'mapping':mapping,'objetos':'E04_objetos.json','agua':{'archivo':'E04_water_47_anim.png','pasos':4,'ms':[150,150,150,150],'desplazamiento_frame_px':128,'rango_por_frame':[128,96]},'arboles_predeterminados':'64 nativo, alternativa48 preservada; aceptación artística pendiente'})
 # Comparison at native scale and integer zoom, not a generated concept image.
 compare=Image.new('RGBA',(384,144),(55,78,48,255));pj=image(LOT/'fuentes/entradas/E00_personaje_escala.png').crop((0,0,32,32))
 for i,name in enumerate(['tree_broadleaf','tree_pine','tree_fruit']):
  small=image(S/f'{name}.png');compare.alpha_composite(small,(i*128+3,17));compare.alpha_composite(pj,(i*128+48,31))
  compare.alpha_composite(image(A/f'E04_{name}_64.png'),(i*128,73));compare.alpha_composite(pj,(i*128+54,103))
 compare.resize((1152,432),Image.Resampling.NEAREST).save(PV/'E04_comparacion_48_64.png')
 dump(LOT/'validacion/E04_topologia.json',{'resultado':'CORRECTO','interfaces_y_reconstruccion':checks,'patrones':47,'mascaras_entrada':256,'vecindarios_exhaustivos_por_eje':4096,'tipos':['path','water','ruins','wall'],'compara':'máscara semántica y RGBA en cada borde compartido de dos celdas conectadas','limite':'No certifica calidad artística ni todos los contactos entre materiales diferentes.'})
 print('E04 v002:',checks,'comprobaciones de continuidad/reconstrucción; reutilización sin generación nueva')
if __name__=='__main__':main()
