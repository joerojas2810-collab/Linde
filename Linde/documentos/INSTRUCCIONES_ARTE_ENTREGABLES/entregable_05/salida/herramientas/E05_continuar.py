"""E05 v002: native modules from the existing cottage/fence/chest source pixels.
No new illustration generation; no gameplay writes; common house origin is fixed.
"""
from pathlib import Path
import json,hashlib,shutil
import numpy as np
from PIL import Image,ImageDraw
OUT=Path(__file__).resolve().parents[1];LOT=OUT/'lotes/E05_v002';A=LOT/'assets';S=LOT/'fuentes/entradas/assets';PV=LOT/'previews'
def image(p):return Image.open(p).convert('RGBA')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def repeat(src,w,h):
 out=Image.new('RGBA',(w,h))
 for y in range(0,h,src.height):
  for x in range(0,w,src.width):out.paste(src,(x,y))
 return out
def put(canvas,im,x,y):canvas.alpha_composite(im,(x,y))
def house():
 src=image(S/'cottage_closed.png');op=image(S/'cottage_open.png');size=(160,160);origin=(16,32)
 # Keep one coordinate system for roof, front, doors and interior. No full-image resize.
 wall=repeat(src.crop((18,65,26,82)),128,32)
 foundation=repeat(src.crop((17,83,31,88)),128,5);wall.paste(foundation,(0,27))
 beam=repeat(src.crop((18,63,31,66)),128,3);wall.paste(beam,(0,0))
 post=repeat(src.crop((12,64,17,86)),5,32);wall.paste(post,(0,0));wall.paste(post,(123,0))
 # Source windows are copied, never regenerated or stretched.
 window=src.crop((55,68,81,82));put(wall,window,82,7)
 one=src.crop((55,68,68,82));put(wall,one,17,7)
 facade=Image.new('RGBA',size);facade.paste(wall,(16,112))
 # Portal x48..64, front row y96..112 in logical house coordinates.
 ar=np.array(facade);ar[120:144,64:80]=0;facade=Image.fromarray(ar)
 closed=Image.new('RGBA',size);opened=Image.new('RGBA',size)
 put(closed,src.crop((32,64,52,88)),62,120)
 put(opened,op.crop((28,64,48,88)),62,120)
 # Tiled roof texture with source ridge/eave borders and original chimney.
 roofsmall=repeat(src.crop((24,42,40,54)),144,92)
 ridge=repeat(src.crop((24,28,40,31)),144,3);roofsmall.paste(ridge,(0,0))
 eave=repeat(src.crop((24,60,48,64)),144,4);roofsmall.paste(eave,(0,88))
 edge=repeat(src.crop((12,44,15,52)),3,92);put(roofsmall,edge,0,0);put(roofsmall,edge.transpose(Image.Transpose.FLIP_LEFT_RIGHT),141,0)
 data=np.array(roofsmall)
 for y in range(12):
  inset=max(0,8-y)
  if inset:data[y,:inset]=0;data[y,144-inset:]=0
 roof=Image.new('RGBA',size);roof.paste(Image.fromarray(data),(8,20))
 chimney=np.array(src.crop((44,19,61,43)))
 gray=(np.abs(chimney[:,:,0].astype(int)-chimney[:,:,2])<24)&(np.abs(chimney[:,:,1].astype(int)-chimney[:,:,2])<24)
 chimney[~gray]=0;put(roof,Image.fromarray(chimney),96,8)
 floor=Image.new('RGBA',size);wood=image(S/'floor_wood.png')
 for y in range(1,6):
  for x in range(1,7):floor.paste(wood,(16+x*16,32+y*16))
 floor.paste(wood,(16+3*16,32+6*16))
 walls=Image.new('RGBA',size)
 panel=repeat(src.crop((18,64,26,68)),16,16)
 # Exact logical perimeter with a single existing doorway.
 for y in range(7):
  for x in range(8):
   if (x in [0,7] or y in [0,6]) and (x,y)!=(3,6):walls.paste(panel,(16+x*16,32+y*16))
 parts={'casa_tejado_160':roof,'casa_fachada_160':facade,'casa_puerta_cerrada_160':closed,'casa_puerta_abierta_160':opened,'casa_interior_160':floor,'casa_paredes_interior_160':walls}
 for name,im in parts.items():im.save(A/f'E05_{name}.png')
 renders=[]
 for door in [closed,opened]:
  canvas=Image.new('RGBA',size)
  for im in [floor,walls,facade,door,roof]:canvas.alpha_composite(im)
  renders.append(canvas)
 before=np.array(renders[0]);after=np.array(renders[1]);difference=np.any(before!=after,axis=2)
 allowed=np.zeros((160,160),bool);allowed[120:144,62:82]=True
 assert not (difference&~allowed).any();assert difference.any()
 # Interior floor follows exactly SUEL0 and PUERTA of the original 8x7 house.
 for y in range(7):
  for x in range(8):
   alpha=np.array(floor)[32+y*16:48+y*16,16+x*16:32+x*16,3]
   expected=(0<x<7 and 0<y<6) or (x,y)==(3,6)
   assert bool((alpha>0).all())==expected
   if not expected:assert not alpha.any()
 renders[0].save(A/'E05_casa_compuesta_cerrada.png');renders[1].save(A/'E05_casa_compuesta_abierta.png')
 contract={'id':'E05_CASA_MODULAR_v002','canvas':[160,160],'origen_casa_en_canvas':list(origin),'pivote_comun':[16,32],
 'casa_logica':{'rect_celdas':[24,16,8,7],'dimensiones_px':[128,112],'puerta_celda':[27,22],'puerta_local_rect':[48,96,16,16],'pies_celda_puerta_local':[56,108]},
 'fachada_local_rect':[0,80,128,32],'tejado_local_rect':[-8,-12,144,92],'portal_visual_local_rect':[46,88,20,24],
 'partes':{name:'E05_'+name+'.png' for name in parts},'orden_exterior':['interior','paredes_interiores','objetos_por_pies','fachada','puerta','tejado'],
 'orden_interior':'Ocultar tejado; fachada/puerta pueden atenuarse como en el render actual. Cama de Maren conserva celda [30,18].',
 'colision':'Sin cambios; no se deduce del PNG. El portal sigue la celda lógica original, no crea cerradura.',
 'fuentes':{'cerrada':{'archivo':'cottage_closed.png','sha256':sha(S/'cottage_closed.png')},'abierta':{'archivo':'cottage_open.png','sha256':sha(S/'cottage_open.png')}},
 'metodo':'Módulos de píxeles existentes, repetición de materiales sin redimensionar el edificio completo. Cerrada/abierta difieren únicamente en el portal.',
 'estado':'validado estructural; aspecto y repetición del tejado pendientes de recepción artística'}
 dump(A/'E05_casa_modular.json',contract)
 return 58

def fences():
 source=image(S/'fence_horizontal.png');post=source.crop((7,18,15,40));upper=source.crop((15,22,23,29));lower=source.crop((15,31,23,36))
 atlas=Image.new('RGBA',(192,192));records=[];ports={'n':[24,32],'e':[32,40],'s':[24,48],'w':[16,40]}
 for m in range(16):
  im=Image.new('RGBA',(48,64));cx=24;cy=40
  for bit,dx in [(2,0),(8,-8)]:
   if m&bit:
    put(im,upper,cx+dx,cy-18);put(im,lower,cx+dx,cy-9)
  for bit,dy in [(1,-8),(4,0)]:
   if m&bit:
    up=upper.crop((2,0,5,7)).resize((3,8),Image.Resampling.NEAREST)
    low=lower.crop((3,0,6,5)).resize((3,8),Image.Resampling.NEAREST)
    put(im,up,cx-2,cy-18+dy);put(im,low,cx+1,cy-9+dy)
  put(im,post,cx-4,cy-22)
  # Fixed 48x64 canvas leaves room for the southern half rail; same node pivot.
  im.save(A/f'E05_valla_mask_{m:02d}.png')
  records.append({'mascara':m,'archivo':f'E05_valla_mask_{m:02d}.png','canvas':[48,64],'pivote':[24,40],'puertos_activos':{d:ports[d] for d,b in [('n',1),('e',2),('s',4),('w',8)] if m&b}})
 dump(A/'E05_vallas_conectadas.json',{'id':'E05_VALLAS_16_v002','paso_mundo_px':16,'bits':{'n':1,'e':2,'s':4,'w':8},'nodos':records,
  'fuente':'fence_horizontal.png','sha256_fuente':sha(S/'fence_horizontal.png'),'metodo':'Postes y listones extraídos del original; todos los nodos comparten dimensiones y alturas. Los puertos son anclas de suelo, no píxeles de la parte alta del listón.',
  'nota':'La valla horizontal original y las muestras v001 permanecen disponibles; estos nodos reemplazan su escala inconsistente al construir redes.'})
 # Corresponding half-ports meet at exactly the same world coordinates.
 for p,q,shift in [('e','w',(16,0)),('s','n',(0,16))]:
  assert np.array_equal(np.array(ports[p]),np.array(ports[q])+shift)
 return 18

def chests():
 closed=image(S/'chest_closed.png');opened=image(S/'chest_open.png')
 c=Image.new('RGBA',(48,48));c.paste(closed,(2,0))
 o=Image.new('RGBA',(48,48));o.paste(c.crop((0,29,48,48)),(0,29))
 lid=opened.crop((11,15,37,29));wide=Image.new('RGBA',(33,14));wide.paste(lid.crop((0,0,5,14)),(0,0));wide.paste(lid.crop((21,0,26,14)),(28,0))
 middle=repeat(lid.crop((5,0,21,14)),23,14);wide.paste(middle,(5,0));o.paste(wide,(7,15))
 # Shared lower chest body is literally identical, preventing a base jump.
 assert np.array_equal(np.array(c)[29:],np.array(o)[29:])
 c.save(A/'E05_cofre_cerrado_alineado.png');o.save(A/'E05_cofre_abierto_alineado.png')
 dump(A/'E05_cofres_alineados.json',{'cerrado':'E05_cofre_cerrado_alineado.png','abierto':'E05_cofre_abierto_alineado.png','canvas':[48,48],'pivote':[24,44],'base_compartida_rect':[0,29,48,19],'fuentes':['chest_closed.png','chest_open.png'],'metodo':'Mismo cuerpo inferior y ancla; tapa/interior reutilizados del abierto y ajustados con repetición de sección central, sin reducir el PNG.','estado':'candidato por revisar visualmente'})
 return 1

def main():
 for p in [A,PV,LOT/'validacion']:p.mkdir(exist_ok=True)
 
 for p in S.glob('*.png'):shutil.copy2(p,A/('E05_'+p.name))
 n=house()+fences()+chests()
 objects={}
 for name in ['barrel','bed','workbench','furnace','palisade','chest_treasure','bridge_vertical','crafting_shed','cave_entrance','floor_wood']:
  p=A/f'E05_{name}.png';im=image(p);b=im.getbbox();objects[name]={'archivo':p.name,'canvas':list(im.size),'bbox':list(b),'pivote':[(b[0]+b[2])//2,b[3]],'escala_dibujada':1,'sha256':sha(p),'reutilizado_sin_cambios':sha(p)==sha(S/f'{name}.png')}
 dump(A/'E05_objetos.json',objects)
 dump(A/'E05_construcciones.json',{'muro':'E05_palisade.png','suelo':'E05_floor_wood.png','mesa':'E05_workbench.png','horno':'E05_furnace.png','cofre':['E05_cofre_cerrado_alineado.png','E05_cofre_abierto_alineado.png'],'cama':'E05_bed.png','ghost':'Reutiliza la misma textura con modulate RGBA; no atlas extra. Validar costes/ocupación con la lógica existente, no con el renderer.'})
 dump(LOT/'validacion/E05_geometria.json',{'resultado':'CORRECTO','comprobaciones_geometria':n,'puerta_fija':True,'pixeles_distintos_fuera_portal':0,'suelo_y_paredes_siguen_logica_8x7':True,'base_cofres_identica':True,'vallas_16_mascaras_puertos_16px':True,'limites':'No equivale a aceptación visual. No cambia colisiones ni comportamiento de puerta/cosecha/construcción.'})
 sample=Image.new('RGBA',(480,192),(43,66,44,255))
 for i,name in enumerate(['E05_casa_compuesta_cerrada.png','E05_casa_compuesta_abierta.png','E05_casa_interior_160.png']):put(sample,image(A/name),i*160,0)
 pj=image(LOT/'fuentes/entradas/E00_personaje_escala.png').crop((0,0,32,32));put(sample,pj,82,126)
 sample.resize((1440,576),Image.Resampling.NEAREST).save(PV/'E05_casa_modular_x3.png')
 print('E05 v002:',n,'comprobaciones; casa modular, vallas y cofre desde fuentes existentes')
if __name__=='__main__':main()
