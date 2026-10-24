"""First native art sublot; each copy writes only its own deliverable salida."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import json,hashlib,shutil
import numpy as np

OUT=Path(__file__).resolve().parents[1];E=OUT.parent.name[-2:];LOT=OUT/f'lotes/E{E}_v001';SRC=LOT/'fuentes/entradas/assets';A=LOT/'assets';PV=LOT/'previews'
def image(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,data):p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def mask(im):return np.array(im)[:,:,3]>0
def measure(im):
 b=im.getbbox()
 return {'size':list(im.size),'bbox':list(b) if b else None,'pivot':[round((b[0]+b[2])/2),b[3]] if b else [im.width//2,im.height]}
def put(canvas,pic,pos):canvas.alpha_composite(pic,pos)
def canonical(m):
 for a,b,d in [(1,2,16),(2,4,32),(4,8,64),(8,1,128)]:
  if not(m&a and m&b):m&=~d
 return m
def neighbours(grid,x,y,value):
 m=0
 for dx,dy,bit in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8),(1,-1,16),(1,1,32),(-1,1,64),(-1,-1,128)]:
  if 0<=y+dy<grid.shape[0] and 0<=x+dx<grid.shape[1] and grid[y+dy,x+dx]==value:m|=bit
 return canonical(m)

def terrain(kind):
 fill=np.array(image(SRC/('path_fill.png' if kind=='path' else 'water_fill.png')))
 bg=np.array(image(SRC/('grass.png' if kind=='path' else 'path_fill.png')))
 prefix='path_grass_' if kind=='path' else 'water_shore_'
 edges={d:np.array(image(SRC/f'{prefix}{d}.png')) for d in ['n','e','s','w']}
 patterns=sorted({canonical(m) for m in range(256)});assert len(patterns)==47
 atlas=Image.new('RGBA',(128,96));tiles={};mapping={}
 for i,m in enumerate(patterns):
  out=fill.copy()
  for qx,qy,a,b,diag,ea,eb in [(0,0,1,8,128,'n','w'),(8,0,1,2,16,'n','e'),(0,8,4,8,64,'s','w'),(8,8,4,2,32,'s','e')]:
   aa=bool(m&a);bb=bool(m&b)
   for y in range(qy,qy+8):
    for x in range(qx,qx+8):
     dx=(x if qx==0 else 15-x);dy=(y if qy==0 else 15-y)
     if aa and bb:
      out[y,x]=bg[y,x] if not m&diag and dx*dx+dy*dy<9 else fill[y,x]
     elif aa:out[y,x]=edges[eb][y,x]
     elif bb:out[y,x]=edges[ea][y,x]
     else:out[y,x]=fill[y,x] if (8-dx)**2+(8-dy)**2<=64 else bg[y,x]
  im=Image.fromarray(out);tiles[m]=im;atlas.paste(im,((i%8)*16,(i//8)*16));mapping[str(m)]=[i%8,i//8]
 atlas.save(A/f'E04_{kind}_47.png')
 dump(A/f'E04_{kind}_conexiones.json',{'id':f'E04_{kind}_47','atlas':[128,96],'celda':[16,16],'bits':{'n':1,'e':2,'s':4,'w':8,'ne':16,'se':32,'sw':64,'nw':128},'regla':'Diagonal válida solo cuando están presentes sus dos cardinales. 47 patrones normalizados, todo mask 0..255 tiene salida.','mapping':mapping,'estado':'candidato; conexiones topológicas completas, continuidad visual por revisar en contexto'})
 atlas.resize((512,384),Image.Resampling.NEAREST).save(PV/f'E04_{kind}_47_x4.png')
 return tiles

def generated(name,cols,rows,ids,originals):
 master=image(LOT/'fuentes'/name);records=[]
 for i,id in enumerate(ids):
  c=i%cols;r=i//cols;rect=[round(c*master.width/cols),round(r*master.height/rows),round((c+1)*master.width/cols),round((r+1)*master.height/rows)]
  raw=master.crop(rect);a=np.array(raw);a[a[:,:,3]<192]=0;a[a[:,:,3]>=192,3]=255;raw=Image.fromarray(a)
  assert raw.getbbox(),id
  crop=raw.crop(raw.getbbox());old=image(SRC/f'{originals[i]}.png');b=old.getbbox();w=b[2]-b[0];h=b[3]-b[1]
  if E=='04':
   if 'stump' in id:w=max(7,round(w*.48));h=max(7,round(h*.35))
   elif 'depleted' in id:h=max(6,round(h*.48))
  else:w=32;h=36
  scale=min(w/crop.width,h/crop.height);crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.Resampling.NEAREST)
  # Remap only the candidate to the existing domain palette; never recolor inputs.
  sourcecolors=[]
  for s in originals:
   v=np.array(image(SRC/f'{s}.png'));sourcecolors.extend(set(map(tuple,v[v[:,:,3]>0])))
  colors=np.array(sorted(set(sourcecolors)),dtype=np.int32)
  a=np.array(crop)
  for y,x in np.argwhere(a[:,:,3]>0):
   k=int(np.argmin(((colors[:,:3]-a[y,x,:3].astype(np.int32))**2).sum(axis=1)));a[y,x]=colors[k]
  crop=Image.fromarray(a);out=Image.new('RGBA',(48,48));px=(b[0]+b[2])//2;py=b[3] if E=='04' else 44
  out.paste(crop,(max(1,min(47-crop.width,px-crop.width//2)),py-crop.height));out.save(A/f'E{E}_{id}.png')
  records.append({'id':f'E{E}_{id}','source_grid_rect':rect,'alpha_threshold':192,'source':name,'source_sha256':sha(LOT/'fuentes'/name),'scale':scale,'native':measure(out),'estado':'muestra candidata; no certifica coincidencia artística'})
 dump(LOT/f'fuentes/E{E}_recortes.json',records)

def sample04():
 paths=terrain('path');water=terrain('water')
 for name in ['grass','grass_flecks','tree_broadleaf','tree_pine','tree_fruit','rock','ore_copper','bush_berries','wall_stone','floor_ruins','steps_n']:
  shutil.copy2(SRC/f'{name}.png',A/f'E04_{name}.png')
 for name in ['tree_broadleaf','tree_pine','tree_fruit']:
  a=np.array(image(SRC/f'{name}.png'));b=Image.fromarray(a).getbbox()
  brown=(a[:,:,0]>a[:,:,1]*1.2)&(a[:,:,0]>a[:,:,2]*1.2)&(a[:,:,3]>0)
  ys=np.where(brown)[0];split=int(ys.min()) if ys.size else b[3]-8
  crown=np.indices(a.shape[:2])[0]<split
  top=a.copy();top[~crown]=0;bottom=a.copy();bottom[crown]=0
  assert np.array_equal((top.astype('uint16')+bottom).astype('uint8'),a)
  Image.fromarray(top).save(A/f'E04_{name}_copa.png');Image.fromarray(bottom).save(A/f'E04_{name}_tronco.png')
 waterfill=image(SRC/'water_fill.png');anim=Image.new('RGBA',(64,16))
 for i,shift in enumerate([0,1,2,1]):anim.paste(Image.fromarray(np.roll(np.array(waterfill),shift,axis=1)),(i*16,0))
 anim.save(A/'E04_water_anim_propuesto.png')
 generated('E04_estados_generados.png',3,2,['stump_broadleaf','stump_pine','stump_fruit','rock_depleted','ore_depleted','bush_without_berries'],['tree_broadleaf','tree_pine','tree_fruit','rock','ore_copper','bush_berries'])
 grid=np.zeros((20,32),dtype=int);grid[3:18,10:12]=1;grid[9:11,3:28]=1;grid[2:8,20:29]=2
 scene=Image.new('RGBA',(512,320))
 for y in range(20):
  for x in range(32):
   v=grid[y,x];tile=paths[neighbours(grid,x,y,1)] if v==1 else water[neighbours(grid,x,y,2)] if v==2 else image(SRC/'grass.png')
   scene.paste(tile,(x*16,y*16))
 pj=image(LOT/'fuentes/entradas/E00_personaje_escala.png').crop((0,0,32,32))
 for i,name in enumerate(['tree_broadleaf','tree_pine','tree_fruit','rock','ore_copper','bush_berries']):
  x=35+i*77;put(scene,image(A/f'E04_{name}.png'),(x,205));put(scene,pj,(x+26,222))
 states=['stump_broadleaf','stump_pine','stump_fruit','rock_depleted','ore_depleted','bush_without_berries']
 for i,name in enumerate(states):put(scene,image(A/f'E04_{name}.png'),(35+i*77,264))
 scene.save(PV/'E04_muestra_nativa.png');scene.resize((1024,640),Image.Resampling.NEAREST).save(PV/'E04_muestra_x2.png')
 return {'patrones_por_terreno':47,'reglas_256_mascaras':all(canonical(m) in paths for m in range(256)),
  'agua_propuesta':{'atlas':[64,16],'celda':[16,16],'frames':4,'ms_por_frame':150,'scope':'preview, no reloj de juego'},
  'pendientes':['Aceptar escala y paleta aplicadas antes de serie','Revisar visualmente esquinas y transiciones en el mapa real','Decidir si árboles de fuente48 requieren nuevas versiones grandes en píxel nativo, sin escalar48→32','Integración de agotados y profundidad sin cambiar colisión/regeneración']}

def sample05():
 for p in SRC.glob('*.png'):shutil.copy2(p,A/f'E05_{p.name}')
 generated('E05_vallas_generadas.png',4,1,['fence_vertical','fence_corner_ne','fence_t_nes','fence_cross'],['fence_horizontal']*4)
 closed=image(SRC/'cottage_closed.png');a=np.array(closed);yy=np.indices(a.shape[:2])[0]
 roof=a.copy();roof[yy>=65]=0
 facade=a.copy();facade[yy<65]=0
 door_rect=(34,65,52,89);door=Image.new('RGBA',(96,96));door.paste(closed.crop(door_rect),door_rect[:2]);facade[65:89,34:52]=0
 pieces=[Image.fromarray(roof),Image.fromarray(facade),door]
 reconstructed=Image.new('RGBA',(96,96))
 for part in pieces:reconstructed.alpha_composite(part)
 # Disjoint planes preserve even hidden RGB in fully transparent source pixels.
 exact=sum((np.array(part).astype('uint16') for part in pieces)).astype('uint8')
 assert np.array_equal(exact,a)
 for name,part in zip(['casa_tejado','casa_fachada_sin_puerta','casa_puerta_cerrada'],pieces):part.save(A/f'E05_{name}.png')
 # The only changed pixels between these presentation states are the door rectangle.
 open_view=Image.new('RGBA',(96,96));open_view.alpha_composite(pieces[1]);open_view.alpha_composite(pieces[0]);open_view.save(A/'E05_casa_abierta_muestra.png')
 floor=Image.new('RGBA',(128,112));wood=image(SRC/'floor_wood.png')
 for y in range(16,96,16):
  for x in range(16,112,16):floor.paste(wood,(x,y))
 floor.paste(wood,(48,96));floor.save(A/'E05_casa_interior_logico.png')
 canvas=Image.new('RGBA',(512,320),(46,61,49,255));d=ImageDraw.Draw(canvas)
 # Screen origin, world house origin and proposed source translation are explicit.
 for i,opened in enumerate([False,True]):
  origin=(35+i*256,18);put(canvas,floor,origin)
  d.rectangle((origin[0],origin[1],origin[0]+127,origin[1]+111),outline=(255,185,70,255))
  shift=(origin[0]+13,origin[1]+23)
  put(canvas,pieces[1],shift)
  if not opened:put(canvas,door,shift)
  put(canvas,pieces[0],shift)
  dx=origin[0]+56;dy=origin[1]+104
  d.line((dx-5,dy,dx+5,dy),fill='cyan');d.line((dx,dy-5,dx,dy+5),fill='cyan')
  d.text((origin[0],140),'Cerrada' if not opened else 'Abierta: misma fachada/tejado',fill='white')
 pj=image(LOT/'fuentes/entradas/E00_personaje_escala.png').crop((0,0,32,32));put(canvas,pj,(183,97))
 names=['fence_horizontal','fence_vertical','fence_corner_ne','fence_t_nes','fence_cross','barrel','chest_closed','chest_open','palisade','workbench','furnace','bed']
 for i,name in enumerate(names):
  put(canvas,image(A/f'E05_{name}.png'),(8+(i%8)*62,172+(i//8)*70))
 canvas.save(PV/'E05_muestra_nativa.png');canvas.resize((1024,640),Image.Resampling.NEAREST).save(PV/'E05_muestra_x2.png')
 return {'reconstruccion_casa_cerrada_exacta':True,'puerta_rect_fuente':list(door_rect),
  'casa_logica':{'rect_celdas':[24,16,8,7],'puerta_celda':[27,22],'size_px':[128,112],'umbral_local_px':[56,104]},
  'casa_muestra':{'atlas':[96,96],'traslacion_fuente_al_rect_logico':[13,23],'ancla_umbral_fuente':[43,81],'nota':'Ancla propuesta para mostrar desajuste. El sprite96 no cubre toda la huella lógica128x112; no declararlo modular terminado.'},
  'ghost':'Proponer tintado del mismo PNG en el render; no se crea otro atlas.',
  'pendientes':['Confirmar anclas y escala con muestra antes de producir la casa modular extendida','Completar paredes/fachada/tejado para huella lógica sin desplazar puerta ni colisión','Revisar extremos conectables de las nuevas vallas en rejilla16','Pivotes y profundidad en integración','Puente/cueva/cobertizo solo referencia separada, sin acceso nuevo']}

def main():
 for p in [A,PV,LOT/'validacion']:p.mkdir(exist_ok=True)
 reused=[]
 for p in sorted(SRC.glob('*.png')):reused.append({'id':f'E{E}_FUENTE_{p.stem}','ruta':p.relative_to(LOT).as_posix(),'sha256':sha(p),**measure(image(p))})
 dump(LOT/'INVENTARIO.json',{'id':f'E{E}_INVENTARIO','entradas':reused,'estado':'inicio; muestras de escala/anclas, no aceptación de lote final'})
 contract=sample04() if E=='04' else sample05()
 contract.update({'id':f'E{E}_CONTRATO_PROPUESTO','estado':'muestra inicial pendiente de revisión','escala_nativa':1,'escala_dibujada':1,'zoom_preview':2,'filtro':'nearest','colisiones_modificadas':False})
 dump(LOT/'CONTRATO_PROPUESTO.json',contract)
 records=[];checks=0
 for p in sorted(A.glob('*.png')):
  im=image(p);a=np.array(im);assert set(np.unique(a[:,:,3])).issubset({0,255});assert (a[:,:,3]>0).any();checks+=2
  records.append({'id':f'E{E}_{p.stem}','tipo':'png_nativo_candidato','ruta':p.relative_to(LOT).as_posix(),'sha256':sha(p),**measure(im),
   'origen':'Fuentes de escenario suministradas + recortes/generación referenciada del propio entregable','herramienta':'image_gen integrada para estados/vallas nuevos; Python/Pillow/NumPy para compilación y composición','licencia_restricciones':'No certificada; conservar procedencia y consultar autores antes de redistribuir.','estado':'muestra_candidata','pendientes':contract['pendientes']})
 dump(LOT/'validacion/RESULTADOS.json',{'comprobaciones':checks,'fallos':0,'scope':'estructura y reconstrucción; no acredita aprobación artística ni integración','png':len(records)})
 dump(LOT/'MANIFIESTO.json',{'id':f'E{E}_v001','fase':'primer sublote','recursos':records,'contrato':'CONTRATO_PROPUESTO.json'})
 (LOT/'INFORME.md').write_text(f'''# E{E} — primer sublote

Estado: iniciado, con inventario, contrato propuesto, PNG candidatos y muestra compuesta nativa. No es una entrega cerrada.

Se reutilizan originales sin modificaciones y se guardan hashes. Las imágenes nuevas se normalizan a PNG nativos y se presentan junto a personaje/objetos reales; las generaciones grandes no se presentan como atlas finales.

Hecho: {len(records)} PNG candidatos; {checks} comprobaciones estructurales. Ver CONTRATO_PROPUESTO para reconstrucción/topología. Revisión y límites en validacion/.

Pendiente: '''+'; '.join(contract['pendientes'])+'''.

No se modificaron juego activo, colisión, tiempos, cosecha, regeneración, guardados ni salidas ajenas. Toda propuesta visual necesita revisión dentro del motor. Puente/cueva/cobertizo no crean accesos nuevos. Los recursos que ya servían se conservan, no se redibujan por contar archivos.
''',encoding='utf-8')
 (LOT/'GALERIA.html').write_text(f'''<!doctype html><html lang="es"><meta charset="utf-8"><title>Linde E{E} — inicio</title><style>body{{background:#202a30;color:white;font:17px system-ui;max-width:1100px;margin:35px auto;padding:20px}}img{{max-width:100%;image-rendering:pixelated}}a{{color:#b3ddff}}</style><h1>Linde E{E} · primer sublote</h1><p>Muestra nativa a zoom entero. Pendientes de escala/anclas en el contrato; no representa integración al juego.</p><img src="previews/E{E}_muestra_x2.png" alt="Muestra compuesta de escala y recursos"><p><a href="INFORME.md">Informe</a> · <a href="CONTRATO_PROPUESTO.json">Contrato</a> · <a href="MANIFIESTO.json">Recursos y hashes</a></p></html>''',encoding='utf-8')
 print(f'E{E}: {len(records)} PNG, {checks} checks, primer sublote')

if __name__=='__main__':main()
