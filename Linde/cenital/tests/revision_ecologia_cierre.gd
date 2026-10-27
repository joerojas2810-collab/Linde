extends SceneTree
## Revisión breve automatizada sobre la escena y fuente reales; no sustituye prueba humana.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Fix=preload("res://tests/fixture_senales.gd")
var esc
var out:String
func _initialize():call_deferred("run")
func foto(nombre:String):
 esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
 esc.actores.actualizar(1.0/30.0,esc.j.combate.enemigos,int(esc.j.jug().hp),esc.j.combate.centro_pj(),esc.j.mundo,false)
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 5:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+nombre+".png")
func run():
 out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
 esc=load("res://main.tscn").instantiate();esc.forzar_acceso=true;esc.cuentas_config_path=out+"/conexion_qa.cfg";esc.ruta=out+"/mundo_qa.json";root.add_child(esc)
 await process_frame
 esc.set_process(false);esc.acceso_panel.raiz.hide();esc.j=J.nueva(123,"Revisión Fase 7",[0,0,0],J.MODO_JUEGO);esc.modo="juego"
 var fixture=Fix.preparar(esc.j)
 if fixture.is_empty():push_error("Sin fuente real");quit(1);return
 var e:Dictionary=fixture.enemigo;var j=esc.j;var hp=j.jug().hp
 j.actualizar_mapa()
 if j.aviso_ecologico().is_empty():push_error("Sin aviso perceptible");quit(1);return
 await foto("01_detectar")
 # Acercamiento breve mediante los controles del personaje y combate de autoridad.
 for n in range(30):
  var delta:Vector2=e.pos-j.pies
  var dir=Vector2i(signi(roundi(delta.x)),0) if absf(delta.x)>absf(delta.y) else Vector2i(0,signi(roundi(delta.y)))
  j.mover_pj(dir,1.0/30.0);j.combate._paso_enemigo(e,1.0/30.0)
 await foto("02_acercarse")
 # Elegir un rodeo alcanzable fuera del radio de observación, no teletransportarse.
 var radio=float(j.autonomia.reglas.conocimiento.radio_vision)*M.P.CELDA
 var camino=j.mundo.camino(M.celda_de(j.pies),func(c):return M.pies_de_celda(c).distance_to(e.pos)>radio,
  Rect2i(),func(c):return j.mundo.caja_libre(M.pies_de_celda(c)))
 if camino.is_empty():push_error("Sin retirada alcanzable");quit(1);return
 for c in camino:
  var punto=M.pies_de_celda(c)
  for n in range(120):
   var delta:Vector2=punto-j.pies
   if delta.length()<M.P.VELOCIDAD/30.0:break
   var dir=Vector2i(signi(roundi(delta.x)),0) if absf(delta.x)>absf(delta.y) else Vector2i(0,signi(roundi(delta.y)))
   j.mover_pj(dir,1.0/30.0);j.combate._paso_enemigo(e,1.0/30.0)
 j.actualizar_mapa();await foto("03_retirarse")
 var seguro=j.jug().hp==hp
 print(("PASS " if seguro else "FAIL ")+"revisión escena real: detectar, acercarse y retirarse; hp=%s inicial=%s"%[j.jug().hp,hp])
 print("RECORRIDO final_distancia=%.2f aviso_actual=%s celdas_ruta=%d"%[j.pies.distance_to(e.pos),not j.aviso_ecologico().is_empty(),camino.size()])
 esc.j=null;esc.modo="cuentas";esc.queue_free();await process_frame;quit(0 if seguro else 1)
