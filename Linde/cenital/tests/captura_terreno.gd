extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var carpeta: String
func foto(nombre: String,c: Vector2i) -> void:
 esc.j.pies=M.pies_de_celda(c);esc.j.actualizar_regiones()
 esc.cam.position=esc.j.pies-Vector2(0,12)
 esc.cam.reset_smoothing()
 for i in 5:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func encontrar(bioma: String) -> Vector2i:
 for y in range(-256,257,8):
  for x in range(-256,257,8):
   var c:=Vector2i(x,y)
   if M.es_valle(c):continue
   var d: Dictionary=esc.j.mundo.generador.datos(c)
   if d.bioma==bioma and int(d.tipo)==M.T.PASTO and d.objeto=="":return c
 return Vector2i(32,60)
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/terreno")
 esc=load("res://main.tscn").instantiate();esc.ruta="/tmp/linde-captura-terreno.json"
 root.add_child(esc);await process_frame
 esc.j=J.nueva(123,"Exploradora",[0,0,0]);esc.j.combate.enemigos.clear();esc.modo="juego"
 await foto("valle",Vector2i(34,25))
 await foto("salida-sur",Vector2i(32,52))
 await foto("bosque",encontrar("bosque"))
 await foto("sierra",encontrar("sierra"))
 await foto("secano",encontrar("secano"))
 await foto("lejos",Vector2i(4096,23))
 print("CAPTURAS_TERRENO_OK")
 quit()
