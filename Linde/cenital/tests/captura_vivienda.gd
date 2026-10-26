extends "res://tests/captura_lugares.gd"
const Prueba = preload("res://tests/prueba_vivienda.gd")
func foto(n: String) -> void:
 var e: Dictionary=esc.j.d.mundo.get("registro",{}).get("edificios",{}).values()[0] if not esc.j.d.mundo.get("registro",{}).get("edificios",{}).is_empty() else {}
 if e.is_empty():esc.cam.position=esc.j.pies-Vector2(0,48)
 else:esc.cam.position=esc.Mundo.pies_de_celda(Vector2i(e.entrada[0],e.entrada[1]-2))
 esc.queue_redraw()
 for i in 20:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+n+".png")
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/vivienda")
 DirAccess.make_dir_recursive_absolute(carpeta)
 esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-vivienda-captura.json"
 root.add_child(esc)
 await process_frame
 esc.j=esc.J.nueva(123,"Constructora",[0,0,0],"poblado")
 esc.modo="juego";esc.set_process(false)
 esc.j.gestionar_pista("silenciar");esc.j.combate.enemigos.clear()
 var c:=Prueba.solar_preparado(esc.j,Vector2i(94,94))
 var plan: Dictionary=esc.J.Edificios.plano("vivienda",c,esc.J.LOCAL)
 esc.j.jug().inv=esc.J.Edificios.coste(plan)
 esc.j.mira=Vector2i.UP;esc.build=true;esc.pieza_i=0
 await foto("plano-previo")
 esc.j.construir("vivienda",c);esc.build=false
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(0,3));esc.pista=esc._pista()
 await foto("exterior")
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i.DOWN);esc.pista=esc._pista()
 await foto("entrada")
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(0,-2));esc.pista=esc._pista()
 await foto("interior")
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(2,-3));esc.j.mira=Vector2i.UP
 esc._interactuar();await foto("cofre-interior");esc._cerrar()
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i.DOWN);esc.j.mira=Vector2i.UP
 esc.j.mundo.destechar(c+Vector2i(0,-3))
 esc._interactuar();await foto("reparacion");esc._cerrar()
 var cama:=c+Vector2i(-2,-4)
 esc.j.d.mundo.poblados.inicial.camas.maren=[cama.x,cama.y]
 var p0: Vector2=esc.Mundo.pies_de_celda(c+Vector2i.DOWN)
 esc.j.d.npcs.maren.pos=[p0.x,p0.y];esc.j.d.npcs.maren.energia=20.0;esc.j.d.min=23*60
 for i in 180:esc.j.habitantes.paso(0.1)
 esc.j.pies=esc.Mundo.pies_de_celda(c+Vector2i(0,-2));esc.pista=esc._pista()
 await foto("npc-descanso")
 quit()
