extends Node2D
var atlas={}
var time=0.0
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 for k in ["caminata","herramienta","ataque","variante_cobre","variante_violeta","variante_arena"]:atlas[k]=ImageTexture.create_from_image(Image.load_from_file("res://%s.png"%k))
 if "--captura" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://galeria.png")
  get_tree().quit()
func _process(dt):
 time+=dt;queue_redraw()
func txt(s,p,size=18):draw_string(ThemeDB.fallback_font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("eef2e6"))
func _draw():
 draw_rect(Rect2(0,0,1280,900),Color("23332e"))
 txt("LINDE | Personaje, acciones y variantes",Vector2(24,35),25)
 var names=["caminata","herramienta","ataque","variante_cobre","variante_violeta","variante_arena"]
 for row in 6:
  var k=names[row];var cell=48 if k in ["herramienta","ataque"] else 32
  var y=135+row*135
  txt(k,Vector2(24,y-58))
  for dir in 4:
   for col in 4:
    var x=240+dir*245+col*52
    draw_texture_rect_region(atlas[k],Rect2(x-cell,y-cell,cell*2,cell*2),Rect2(col*cell,dir*cell,cell,cell))
 txt("Cuadros de prueba. Herramienta y ataque requieren pulido de direccion y tiempos.",Vector2(24,880),16)
