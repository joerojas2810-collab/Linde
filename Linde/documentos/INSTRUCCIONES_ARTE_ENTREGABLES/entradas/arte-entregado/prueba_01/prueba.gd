extends Node2D
var tex: Texture2D
var regions = [Rect2(139, 127, 284, 503), Rect2(668, 127, 288, 504), Rect2(1206, 125, 279, 505), Rect2(1754, 126, 282, 505)]
func _ready():
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 tex = load("res://personaje_cuatro_vistas_original.png")
 queue_redraw()
 if "--captura" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://prueba_escala_motor.png")
  get_tree().quit()
func label_at(text: String, pos: Vector2, size: int = 18):
 draw_string(ThemeDB.fallback_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("e5ecda"))
func _draw():
 draw_rect(Rect2(0,0,1120,720),Color("26352f"))
 label_at("LINDE | Primera prueba de personaje completo",Vector2(28,36),24)
 label_at("Original generado; escalado de pantalla. Sin limpieza ni atlas nativo validado.",Vector2(28,66),16)
 var names = ["Frente","Derecha","Espalda","Izquierda"]
 for row in range(3):
  var height = [28.0,40.0,56.0][row]
  var floor_y=200.0+row*185.0
  label_at("Cuerpo visible: %.0f px | vista ampliada x2" % height,Vector2(28,floor_y-108),16)
  draw_rect(Rect2(24,floor_y,1070,8),Color("65864e"))
  # Reference placeholders: dimensions explicit, not finished art or collision geometry.
  draw_rect(Rect2(48,floor_y-80,64,80),Color("7c5839"))
  draw_rect(Rect2(64,floor_y-64,32,64),Color("322d27"))
  label_at("Puerta 16x32",Vector2(30,floor_y+32),14)
  draw_rect(Rect2(191,floor_y-54,14,54),Color("795039"))
  draw_circle(Vector2(198,floor_y-52),28,Color("477556"))
  label_at("Arbol provisional",Vector2(140,floor_y+32),14)
  draw_rect(Rect2(290,floor_y-24,36,24),Color("a98046"))
  draw_rect(Rect2(290,floor_y-14,36,4),Color("4c3c2b"))
  label_at("Cofre 18x12",Vector2(266,floor_y+32),14)
  for i in range(4):
   var r: Rect2 = regions[i]
   var sh=height*2
   var sw=r.size.x/r.size.y*sh
   draw_texture_rect_region(tex,Rect2(440+i*165-sw/2,floor_y-sh,sw,sh),r)
   label_at(names[i],Vector2(410+i*165,floor_y+32),14)
 label_at("Comparacion visual en escena aislada; falta comprobar el mapa real y la animacion.",Vector2(28,700),16)
