"""Independent receiving checks on actual v002 PNGs, contracts and world snapshot."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
OUT=Path(__file__).resolve().parents[1];E=Path(__file__).name[1:3];LOT=OUT/f'lotes/E{E}_v002'
checks=0
def check(value,label):
 global checks
 checks+=1
 assert value,label
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def data(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rgba(p):return np.array(Image.open(p).convert('RGBA'))
def neigh(g,x,y,t):
 m=0
 for dx,dy,b in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8),(1,-1,16),(1,1,32),(-1,1,64),(-1,-1,128)]:
  if 0<=x+dx<g.shape[1] and 0<=y+dy<g.shape[0] and g[y+dy,x+dx]==t:m|=b
 for a,b,d in [(1,2,16),(2,4,32),(4,8,64),(8,1,128)]:
  if not(m&a and m&b):m&=~d
 return m
def main():
 inputs=data(LOT/'fuentes/HASHES_ENTRADAS.json')
 for rel,h in inputs.items():check(sha(LOT/rel)==h,'input changed '+rel)
 for rel,h in data(LOT/'fuentes/HASHES_REGLAS_ORIGINALES.json').items():
  check(sha(LOT/rel)==h,'rule changed '+rel)
  source=OUT.parents[3]/'cenital'/rel
  if source.exists():check(sha(source)==h,'differs from source '+rel)
 pngs=[]
 for p in sorted((LOT/'assets').glob('*.png')):
  a=rgba(p);check(set(np.unique(a[:,:,3])).issubset({0,255}),'partial alpha '+p.name);check((a[:,:,3]>0).any(),'empty '+p.name)
  pngs.append({'archivo':p.relative_to(LOT).as_posix(),'sha256':sha(p),'canvas':[a.shape[1],a.shape[0]],'bbox':list(Image.fromarray(a).getbbox())})
 motor=data(LOT/f'validacion/E{E}_motor.json');check(not motor['fallos'],'Godot failures')
 root=LOT/'assets' if E=='04' else LOT/'fuentes/dependencias/E04_v002/assets'
 cat=data(root/'E04_catalogo.json');g=np.array(motor['mapa_celdas']).reshape(48,64)
 grids={k:rgba(root/f'E04_{k}_47.png') for k in ['path','water','ruins','wall']};water=rgba(root/'E04_water_47_anim.png')
 def tile(kind,m,frame=0):
  x,y=cat['mapping'][kind][str(m)];arr=water if kind=='water' else grids[kind];xx=x*16+(frame*128 if kind=='water' else 0)
  return arr[y*16:y*16+16,xx:xx+16]
 edge_checks=0
 for y in range(48):
  for x in range(64):
   t=int(g[y,x]);kind={1:'path',2:'water',3:'wall',6:'ruins',7:'wall'}.get(t)
   if not kind:continue
   for dx,dy in [(1,0),(0,1)]:
    if x+dx>=64 or y+dy>=48 or g[y+dy,x+dx]!=t:continue
    for frame in range(4 if kind=='water' else 1):
     a=tile(kind,neigh(g,x,y,t),frame);b=tile(kind,neigh(g,x+dx,y+dy,t),frame)
     check(np.array_equal(a[:,-1] if dx else a[-1],b[:,0] if dx else b[0]),'actual map PNG seam '+str((kind,x,y,frame)))
     edge_checks+=1
 if E=='04':
  objects=data(root/'E04_objetos.json')
  for name in ['tree_broadleaf','tree_pine','tree_fruit']:
   for suffix in ['', '_64']:
    key='E04_'+name+suffix;whole=rgba(root/(key+'.png'));a=rgba(root/(key+'_tronco.png'));b=rgba(root/(key+'_copa.png'))
    check(np.array_equal((a.astype('uint16')+b).astype('uint8'),whole),'tree reconstruction')
    check(objects[key]['pivote']==objects[key+'_tronco']['pivote']==objects[key+'_copa']['pivote'],'canopy pivot')
 else:
  rec=data(LOT/'fuentes/dependencias/E04_v002/RECIBO.json')
  for rel,h in rec['recursos'].items():check(sha(LOT/'fuentes/dependencias/E04_v002'/rel)==h,'foreign asset changed')
  for p in ['casa_tejado_160','casa_fachada_160','casa_puerta_cerrada_160','casa_puerta_abierta_160','casa_interior_160','casa_paredes_interior_160']:
   check(rgba(LOT/f'assets/E05_{p}.png').shape==(160,160,4),'house canvas')
  a=rgba(LOT/'assets/E05_casa_compuesta_cerrada.png');b=rgba(LOT/'assets/E05_casa_compuesta_abierta.png')
  diff=np.any(a!=b,axis=2);permit=np.zeros((160,160),bool);permit[120:144,62:82]=True
  check(diff.any() and not(diff&~permit).any(),'house jumps outside portal')
  a=rgba(LOT/'assets/E05_cofre_cerrado_alineado.png');b=rgba(LOT/'assets/E05_cofre_abierto_alineado.png')
  check(np.array_equal(a[29:],b[29:]),'chest base jumps')
  fence=data(LOT/'assets/E05_vallas_conectadas.json')
  check(len(fence['nodos'])==16 and {n['mascara'] for n in fence['nodos']}==set(range(16)),'fence combinations')
  for node in fence['nodos']:check(rgba(LOT/'assets'/node['archivo']).shape==(64,48,4),'fence dimensions')
  for name,item in data(LOT/'assets/E05_objetos.json').items():check(sha(LOT/'assets'/item['archivo'])==item['sha256'],'reused object changed '+name)
 for p in (LOT/'validacion').glob(f'E{E}_*.png'):check(Image.open(p).size==(1280,800),'capture size')
 result={'id':f'E{E}_VALIDACION_v002','resultado':'CORRECTO','comprobaciones':checks,'interfaces_png_en_mapa_real':edge_checks,'png_propios':len(pngs),'recursos':pngs,
  'limites':['Validación estructural y de anclas; no es aceptación artística.','Preview aislado, no integración en el juego activo ni prueba de red.','No se introducen reglas de cosecha, colisión, apertura o construcción.']}
 (LOT/'validacion/RESULTADOS.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({k:v for k,v in result.items() if k not in ['recursos','limites']},ensure_ascii=False))
if __name__=='__main__':main()
