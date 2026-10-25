extends Node2D
const COLORS=[Color8(255,0,0),Color8(0,255,0),Color8(0,0,255),Color8(128,128,128)]
const PALETTES={"media":[Color("91a3b2"),Color("304150"),Color("c4a04e"),Color("808080")],"ligera":[Color("90613d"),Color("34291f"),Color("c4984e"),Color("808080")],"pesada":[Color("6f8091"),Color("222c38"),Color("6694b1"),Color("808080")]}
var images={}
var textures={}
var t=0.0
var running=true
var only_media=false
var equipped={"casco":true,"torso":true,"guantes":true,"botas":true,"pantalones":true,"escudo":false,"espada":false}
var ground:Texture2D
var path_tex:Texture2D
func read(p:String)->Image:
 var img=Image.load_from_file(p)
 if img!=null:img.convert(Image.FORMAT_RGBA8)
 return img
func recolorear_indices(img:Image,palette:Array)->Image:
 var out=img.duplicate()
 for y in img.get_height():
  for x in img.get_width():
   var c=img.get_pixel(x,y)
   if c.a==0:continue
   var role=COLORS.find(c)
   if role>=0:out.set_pixel(x,y,palette[role])
 return out
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 only_media="--piloto" in OS.get_cmdline_user_args()
 var raw=read("res://base/caminata.png")
 textures["base"]=ImageTexture.create_from_image(raw)
 textures["pelo_base"]=ImageTexture.create_from_image(read("res://base/capas/pelo.png"))
 for arq in ["media","ligera","pesada"]:
  for slot in ["casco","torso","guantes","botas","pantalones","escudo","espada"]:
   var file=("equipo_%s_%s_caminata.png"%[arq,slot]) if slot not in ["escudo","espada"] else slot+"_caminata.png"
   var img=read("res://hojas/"+file) if FileAccess.file_exists("res://hojas/"+file) else null
   if img!=null:
    images[arq+"_"+slot]=img
    var demo=recolorear_indices(img,PALETTES[arq])
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://previews/recolor/"+arq))
    demo.save_png("res://previews/recolor/%s/%s.png"%[arq,slot])
    textures[arq+"_"+slot]=ImageTexture.create_from_image(demo)
 # Independent preview terrain from previous native assets, not current game code.
 if FileAccess.file_exists("res://previews/grass.png"):
  ground=ImageTexture.create_from_image(read("res://previews/grass.png"))
  path_tex=ImageTexture.create_from_image(read("res://previews/path_fill.png"))
 if "--captura" in OS.get_cmdline_user_args():
  t=0.0
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://previews/piloto_media.png" if only_media else "res://previews/arquetipos_recoloreados.png")
  equipped.escudo=true;equipped.espada=true
  queue_redraw()
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://previews/equipo_completo.png")
  get_tree().quit()
func _process(dt):
 if running:t+=dt
 queue_redraw()
func _unhandled_key_input(event):
 if not event.pressed:return
 if event.keycode==KEY_SPACE:running=not running
 var keys={KEY_1:"casco",KEY_2:"torso",KEY_3:"guantes",KEY_4:"botas",KEY_5:"pantalones",KEY_6:"escudo",KEY_7:"espada"}
 if keys.has(event.keycode):equipped[keys[event.keycode]]=not equipped[keys[event.keycode]]
func txt(s:String,p:Vector2,size:int=18):
 draw_string(ThemeDB.fallback_font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("f2ead4"))
func draw_actor(arq:String,row:int,col:int,foot:Vector2,zoom:float):
 var rect=Rect2(foot-Vector2(16,32)*zoom,Vector2(32,32)*zoom)
 var src=Rect2(col*32,row*32,32,32)
 draw_texture_rect_region(textures.base,rect,src)
 var order=["botas","pantalones","torso","guantes","escudo","espada","pelo_base","casco"]
 if row==1:order=["escudo","botas","pantalones","torso","guantes","espada","pelo_base","casco"]
 if row==3:order=["espada","botas","pantalones","torso","guantes","escudo","pelo_base","casco"]
 for slot in order:
  if slot=="pelo_base":
   draw_texture_rect_region(textures.pelo_base,rect,src)
   continue
  if equipped[slot] and textures.has(arq+"_"+slot):
   draw_texture_rect_region(textures[arq+"_"+slot],rect,src)
func _draw():
 draw_rect(Rect2(0,0,1280,880),Color("25372f"))
 txt("LINDE | Equipo por arquetipo - prueba de encaje",Vector2(24,35),25)
 txt("Indices exactos; paletas de demostracion. Cuadros 0-3 sobre la caminata original.",Vector2(24,64),17)
 var archetypes=["media"] if only_media else ["media","ligera","pesada"]
 var dir_names=["frente","derecha","espalda","izquierda"]
 for r in archetypes.size():
  var arq=archetypes[r]
  var floor_y=250.0+r*215.0
  if ground!=null:
   for gy in range(3):
    for gx in range(22):
     draw_texture_rect(ground,Rect2(160+gx*48,floor_y-80+gy*48,48,48),false)
   for gx in range(22):draw_texture_rect(path_tex,Rect2(160+gx*48,floor_y,48,48),false)
  txt(arq.to_upper(),Vector2(24,floor_y-75),22)
  var frame=int(t/0.14)%4
  for d in 4:
   var foot=Vector2(280+d*250,floor_y+4)
   draw_actor(arq,d,frame,foot,4.0)
   txt(dir_names[d],Vector2(240+d*250,floor_y+76),16)
 txt("1 casco | 2 torso | 3 guantes | 4 botas | 5 pantalones | 6 escudo | 7 espada | Espacio pausa",Vector2(24,827),17)
 txt("Escena de arte independiente. No integra ni reemplaza el repositorio actual del juego.",Vector2(24,859),16)
