extends SceneTree
const RED=Color8(255,0,0)
const GREEN=Color8(0,255,0)
const BLUE=Color8(0,0,255)
const GRAY=Color8(128,128,128)
var base: Image
var records: Array=[]
var slot_names=["casco","torso","guantes","botas","pantalones"]
func read(path: String) -> Image:
 var img=Image.load_from_file("res://"+path)
 assert(img!=null,path)
 img.convert(Image.FORMAT_RGBA8)
 return img
func cell(img: Image,row: int,col: int=0) -> Image:
 return img.get_region(Rect2i(col*32,row*32,32,32))
func index_color(c: Color) -> Color:
 if c.a<0.5:return Color(0,0,0,0)
 if c in [RED,GREEN,BLUE,GRAY]:return c
 var value=maxf(c.r,maxf(c.g,c.b))
 if value<0.32:return GREEN
 if c.r>c.b*1.35 and c.g>c.b*1.2 and c.r>0.48:return BLUE
 if value>0.82 and c.s<0.3:return GRAY
 return RED
func index_image(img: Image) -> Image:
 var out=img.duplicate()
 for y in img.get_height():
  for x in img.get_width():out.set_pixel(x,y,index_color(img.get_pixel(x,y)))
 return out
func span(img: Image,y: int,part: String) -> Vector2i:
 y=clampi(y,5,16) if part=="casco" else clampi(y,18,25)
 var lo=32;var hi=-1
 for x in range(1,31):
  var c=img.get_pixel(x,y)
  # All head contour; exclude skin hands when finding clothing bounds.
  var hand=c.r>0.68 and c.g>0.33 and c.b<c.r*0.85 and y>=18
  if c.a>0.5 and not hand:lo=mini(lo,x);hi=maxi(hi,x)
 if hi<lo:return Vector2i(13,19)
 return Vector2i(lo,hi)
func warp(source: Image, reference: Image, target: Image,part: String) -> Image:
 var out=Image.create(32,32,false,Image.FORMAT_RGBA8)
 # Horizontal scanline transport follows real outline changes, with no synthetic bob or changing colours.
 for y in range(1,31):
  var a=span(reference,y,part);var b=span(target,y,part)
  var ratio=float(b.y-b.x+1)/maxi(1,a.y-a.x+1)
  for x in range(1,31):
   var c=source.get_pixel(x,y)
   if c.a<0.5:continue
   var nx=roundi(b.x+(x-a.x)*ratio)
   if nx>=1 and nx<=30:out.set_pixel(nx,y,c)
 return out
func skin_hand(c: Color,y: int) -> bool:
 return y>=19 and y<=27 and c.a>0.5 and c.r>0.68 and c.g>0.33 and c.b<c.r*0.85
func hands(img: Image,left: bool,row: int) -> Vector2i:
 var pts=[]
 for y in range(19,28):
  for x in range(1,31):
   if skin_hand(img.get_pixel(x,y),y):pts.append(Vector2i(x,y))
 if pts.is_empty():return Vector2i(21 if left else 10,23)
 # Profiles: visible near hand is the lowest cluster. Handedness is the contract convention.
 var selected=[]
 if row==0 or row==2:
  var want_right=(left if row==0 else not left)
  for p in pts:
   if (p.x>=16)==want_right:selected.append(p)
 else:
  var near=(not left if row==1 else left)
  var maxy=0
  for p in pts:maxy=maxi(maxy,p.y)
  for p in pts:
   if (p.y>=maxy-2)==near:selected.append(p)
 if selected.is_empty():selected=pts
 var sum=Vector2.ZERO
 for p in selected:sum+=Vector2(p)
 return Vector2i((sum/selected.size()).round())
func derived_slot(target: Image,slot: String,arq: String) -> Image:
 var out=Image.create(32,32,false,Image.FORMAT_RGBA8)
 for y in range(1,31):
  for x in range(1,31):
   var c=target.get_pixel(x,y)
   if c.a<0.5:continue
   var pick=false
   if slot=="guantes":pick=skin_hand(c,y)
   elif slot=="pantalones":pick=y>=24 and y<=(27 if arq=="ligera" else 28) and not skin_hand(c,y)
   elif slot=="botas":pick=y>=(28 if arq=="ligera" else (27 if arq=="media" else 26)) and not skin_hand(c,y)
   if pick:out.set_pixel(x,y,index_color(c))
 # Fitted reinforcement, derived from the existing shape; no independent redrawing of body frames.
 if arq=="pesada" and slot in ["guantes","botas"]:
  var thick=out.duplicate()
  for y in range(1,31):
   for x in range(2,30):
    if out.get_pixel(x,y).a>0.5:
     for dx in [-1,1]:
      if thick.get_pixel(x+dx,y).a<0.5:thick.set_pixel(x+dx,y,GREEN)
  out=thick
 # Main role must reflect the piece's material, not skin or neutral-only remnants.
 for y in range(1,31):
  for x in range(1,31):
   var c=out.get_pixel(x,y)
   if c.a>0.5:
    if slot=="guantes":out.set_pixel(x,y,RED if c!=GREEN else GREEN)
    elif slot=="botas" and c==BLUE:out.set_pixel(x,y,RED)
 return out
func point_inside(img:Image,p:Vector2i) -> bool:
 if p.x<1 or p.x>30 or p.y<1 or p.y>30:return false
 for y in range(maxi(0,p.y-3),mini(32,p.y+4)):
  for x in range(maxi(0,p.x-3),mini(32,p.x+4)):
   if img.get_pixel(x,y).a>0.5:return true
 return false
func attachment(source: Image,target: Image,left: bool,row: int,kind: String) -> Image:
 var box=source.get_used_rect()
 var item=source.get_region(box)
 # Rest weapons remain close to their hand; sword/blade fit is checked without deleting individual bad pixels.
 var scales=[0.75,0.65,0.55,0.45] if kind=="escudo" else [0.8,0.7,0.6,0.5]
 var anchor=hands(target,left,row)
 for factor in scales:
  var sprite=item.duplicate()
  var w=maxi(3,roundi(box.size.x*factor));var h=maxi(4,roundi(box.size.y*factor))
  sprite.resize(w,h,Image.INTERPOLATE_NEAREST)
  var ox=anchor.x-w/2;var oy=anchor.y-h/2 if kind=="escudo" else anchor.y-h+2
  var out=Image.create(32,32,false,Image.FORMAT_RGBA8);var valid=true
  for y in h:
   for x in w:
    var c=sprite.get_pixel(x,y)
    if c.a<0.5:continue
    var p=Vector2i(ox+x,oy+y)
    if not point_inside(target,p):valid=false;break
    out.set_pixel(p.x,p.y,c)
   if not valid:break
  if valid:return out
 push_error("No attachment fit "+kind+" row "+str(row))
 return Image.create(32,32,false,Image.FORMAT_RGBA8)
func _initialize():
 base=read("base/caminata.png")
 var arqs=["media"] if "--piloto" in OS.get_cmdline_user_args() else ["media","ligera","pesada"]
 for arq in arqs:
  for slot in slot_names:
   var sheet=Image.create(128,128,false,Image.FORMAT_RGBA8)
   var static_source:Image=null
   if slot in ["casco","torso"]:
    if arq=="media":static_source=index_image(read("fuentes_reutilizadas/"+("casco" if slot=="casco" else "coraza")+".png"))
    else:static_source=read("fuentes_arquetipos/%s_%s_quieto.png"%[arq,slot])
   for row in 4:
    var reference=cell(base,row,0)
    for col in 4:
     var target=cell(base,row,col)
     var result:Image
     if static_source!=null:
      var seed=cell(static_source,row,0)
      result=warp(seed,reference,target,slot)
     else:result=derived_slot(target,slot,arq)
     sheet.blit_rect(result,Rect2i(0,0,32,32),Vector2i(col*32,row*32))
   var file="equipo_%s_%s_caminata.png"%[arq,slot]
   sheet.save_png("res://hojas/"+file)
   records.append({"file":file,"arquetipo":arq,"ranura":slot,"cell":32,"size":[128,128],"pivot":[16,32],"motion_source":"base/caminata.png; scanline contours or original hand/leg pixels","state":"caminata","source":"fuentes_reutilizadas" if arq=="media" else "fuentes_arquetipos and reused base"})
 if not "--piloto" in OS.get_cmdline_user_args():
  for kind in ["escudo","espada"]:
   var source=index_image(read("fuentes_reutilizadas/"+kind+".png"))
   var sheet=Image.create(128,128,false,Image.FORMAT_RGBA8)
   for row in 4:
    for col in 4:
     var result=attachment(cell(source,row),cell(base,row,col),kind=="escudo",row,kind)
     sheet.blit_rect(result,Rect2i(0,0,32,32),Vector2i(col*32,row*32))
   sheet.save_png("res://hojas/%s_caminata.png"%kind)
   records.append({"file":kind+"_caminata.png","ranura":kind,"arquetipo":"compartido","cell":32,"size":[128,128],"pivot":[16,32],"motion_source":"anatomical hand anchor from original skin pixels","state":"caminata"})
 var f=FileAccess.open("res://manifest.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"assets":records,"order":["frente","derecha","espalda","izquierda"],"index":["ff0000","00ff00","0000ff","808080"],"grey_is_proposed":true,"profiles_inverted":false,"base_unchanged":true,"phase":"piloto" if arqs.size()==1 else "lote_1"},"  "));f.close()
 print("HOJAS_GENERADAS ",records.size())
 quit()
