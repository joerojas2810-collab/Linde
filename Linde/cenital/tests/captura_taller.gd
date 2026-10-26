extends "res://tests/captura_lugares.gd"
const P = preload("res://tests/prueba_vivienda.gd")
var foco: Vector2
func foto(n: String) -> void:
 esc.cam.position=foco
 esc.pista=esc._pista();esc.queue_redraw()
 for i in 20:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+n+".png")
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/taller")
 DirAccess.make_dir_recursive_absolute(carpeta)
 esc=load("res://main.tscn").instantiate();esc.ruta="/tmp/linde-taller-captura.json"
 root.add_child(esc);await process_frame
 esc.j=esc.J.nueva(123,"Artesana",[0,0,0],"poblado");esc.modo="juego";esc.set_process(false)
 esc.j.gestionar_pista("silenciar");esc.j.combate.enemigos.clear()
 var c:=P.solar_preparado(esc.j,Vector2i(94,94))
 foco=esc.Mundo.pies_de_celda(c+Vector2i(0,-2))
 esc.j.jug().inv=esc.J.Edificios.coste(esc.J.Edificios.plano("taller",c,esc.J.LOCAL))
 esc.j.mira=Vector2i.UP;esc.build=true;esc.pieza_i=1
 await foto("plano-taller")
 esc.j.construir("taller",c);esc.build=false
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(0,3));await foto("taller-exterior")
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(0,-2));await foto("taller-interior")
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(-2,-3));esc.j.mira=Vector2i.UP
 esc._interactuar();await foto("mesa-recetas");esc._cerrar()
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(2,-3));esc.j.mira=Vector2i.UP
 esc._interactuar();await foto("horno-recetas");esc._cerrar()
 for pid in esc.j.autonomia.asentamientos.datos().preexistentes.ids:
  var p: Dictionary=esc.j.mundo.poblado(pid)
  var centro:=Vector2i(p.centro[0],p.centro[1])
  foco=esc.Mundo.pies_de_celda(centro)
  esc.j.pies=esc.Mundo.pies_de_celda(centro+Vector2i(0,5));esc.j.actualizar_regiones();esc.j.actualizar_mapa()
  await foto(pid.replace("@","-").replace(",","-")+"-exterior")
  esc.j.pies=esc.Mundo.pies_de_celda(centro+Vector2i(0,1))
  await foto(pid.replace("@","-").replace(",","-")+"-interior")
 quit()
