extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var carpeta: String
func corredor() -> Vector2i:
 var arboles: Array=[]
 for o in esc.j.mundo.objetos.values():
  if o.t=="arbol" and not M.es_valle(o.c):arboles.append(o.c)
 arboles.sort_custom(func(a,b):return a.x<b.x if a.y==b.y else a.y<b.y)
 for a in arboles:
  for b in arboles:
   if b.y!=a.y or b.x<=a.x or b.x-a.x>3:continue
   for x in range(a.x-1,b.x+2):
    var c:=Vector2i(x,a.y)
    var libre:=true
    for dy in range(-2,3):
     if not esc.j.mundo.caja_libre(M.pies_de_celda(c+Vector2i(0,dy))):libre=false
    if libre:return c
 return Vector2i(-248,-256)
func foto(nombre: String) -> void:
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/orden-dibujo")
 esc=load("res://main.tscn").instantiate();esc.ruta="/tmp/linde-captura-orden.json"
 root.add_child(esc);await process_frame
 esc.j=J.nueva(123,"Exploradora",[0,0,0]);esc.modo="juego"
 esc.j.pies=M.pies_de_celda(Vector2i(-248,-256));esc.j.actualizar_regiones()
 var c:=corredor()
 esc.j.pies=M.pies_de_celda(c+Vector2i.UP)
 esc.j.actualizar_regiones();esc.j.combate.enemigos.clear()
 esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
 await foto("01-detras")
 for i in 10:esc.j.mover_pj(Vector2i.DOWN,0.025)
 await foto("02-misma-fila")
 for i in 10:esc.j.mover_pj(Vector2i.DOWN,0.025)
 await foto("03-delante")
 print("CAPTURAS_ORDEN_OK corredor=",c)
 quit()
