extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
var esc
var carpeta:=""
func foto(nombre: String, c: Vector2i) -> void:
 esc.j.pies=M.pies_de_celda(c);esc.j.actualizar_regiones()
 esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 4:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/crecimiento")
 DirAccess.make_dir_recursive_absolute(carpeta)
 esc=load("res://main.tscn").instantiate();esc.ruta="/tmp/linde-captura-crecimiento.json"
 root.add_child(esc);await process_frame
 esc.set_process(false);esc.j=J.nueva(123,"Constructora",[0,0,0]);esc.modo="juego"
 var so=esc.j.autonomia.sociedad
 var p:Dictionary={}
 for intento in 50:
  p=so.habitat.reservar("maren")
  if not p.is_empty():break
 if p.is_empty():quit(1);return
 var b:=Vector2i(p.cama[0],p.cama[1])
 esc.j.jug().inv={"madera":80,"fibra":40,"ladrillo":50,"baya":20}
 esc.j.construir("cama_huesped",b)
 for d in so.cfg.vivienda.casa.base:esc.j.construir("muro_ladrillo",b+Vector2i(d[0],d[1]))
 for paso in so._celdas_casa(b):esc.j.construir(paso[0],paso[1])
 for dy in [0,1]:
  var c:=b+Vector2i(4,dy)
  if esc.j.mundo.puede_poner(c)=="":
   esc.j.construir("campo",c)
   if dy==1:esc.j.d.mundo.constr[M.clave(c)].listo=0
 await foto("casa-y-cultivos",b+Vector2i(0,3))
 await foto("interior-y-puerta",b+Vector2i(0,1))
 esc.j=J.nueva(123,"Pionera",[0,0,0]);var c:=Vector2i(-152,-96)
 esc.j.pies=M.pies_de_celda(c+Vector2i(0,-1));esc.j.actualizar_regiones()
 esc.j.jug().inv=C.CONSTR.puesto.coste.duplicate(true)
 var r:Dictionary=esc.j.construir("puesto",c)
 if not r.ok:print(r);quit(1);return
 for i in 2:esc.j.d.min+=360;esc.j.autonomia.asentamientos.actualizar()
 await foto("puesto-regional",c+Vector2i(0,3))
 esc.panel="mis";esc._armar()
 esc.sel=esc.lineas.size()-1
 esc.hud.queue_redraw()
 await foto("panel-puestos",c+Vector2i(0,3))
 if not esc.arte_mundo.faltantes.is_empty():push_error("Arte faltante");quit(1);return
 print("CAPTURAS_CRECIMIENTO_OK")
 quit()
