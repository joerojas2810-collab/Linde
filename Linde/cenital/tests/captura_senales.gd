extends SceneTree
const J=preload("res://scripts/juego.gd")
const Fix=preload("res://tests/fixture_senales.gd")
var esc
var out:String
func _initialize():call_deferred("run")
func foto(nombre:String):
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 5:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+nombre+".png")
func run():
 out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1280,720)
 esc=load("res://main.tscn").instantiate();esc.forzar_acceso=true;esc.cuentas_config_path=out+"/conexion_fixture.cfg";esc.ruta=out+"/mundo_fixture.json";root.add_child(esc)
 await process_frame
 esc.set_process(false);esc.acceso_panel.raiz.hide();esc.j=J.nueva(123,"Exploradora",[0,0,0],J.MODO_JUEGO);esc.modo="juego"
 var fixture=Fix.preparar(esc.j)
 if fixture.is_empty():push_error("Sin fuente real para capturar");quit(1);return
 esc.cam.position=esc.j.pies;esc.cam.reset_smoothing();esc.j.actualizar_mapa()
 esc.actores.actualizar(0.01,esc.j.combate.enemigos,int(esc.j.jug().hp),esc.j.combate.centro_pj(),esc.j.mundo,false)
 assert(not esc.j.aviso_ecologico().is_empty());await foto("01_presencia_observada")
 esc.j.combate._danar(fixture.enemigo,999)
 esc.actores.actualizar(0.01,esc.j.combate.enemigos,int(esc.j.jug().hp),esc.j.combate.centro_pj(),esc.j.mundo,false,esc.j.d.fauna.bajas)
 assert(esc.j.aviso_ecologico().is_empty());await foto("02_aviso_retirado")
 esc.panel="mapa";esc.mapa_centro=J.Mundo.celda_de(esc.j.pies)
 esc.mapa_primera=maxi(0,esc.j.Exploracion.hitos(esc.j,J.LOCAL).size()-7)
 await foto("03_memoria_historica")
 var original=esc.j;original.pies=original.habitantes.pos("maren");original.preguntar_lugares("maren")
 original.unir("lector","Lector",[0,0,0]);original.rt.lector.pies=original.habitantes.pos("maren");original.preguntar_lugares("maren","lector")
 var srv=load("res://scripts/red_servidor.gd").new();srv.j=original
 var cli=load("res://scripts/red_cliente.gd").new();cli._bienvenida(srv.estado_para("lector"));esc.j=cli.j
 esc.mapa_primera=maxi(0,esc.j.Exploracion.hitos(esc.j,J.LOCAL).size()-7)
 await foto("04_testimonio_npc")
 cli.free();srv.free()
 print("PASS UI: aviso vivo, retirada tras derrota y registro histórico en mapa")
 esc.j=null;esc.modo="cuentas";esc.queue_free();await process_frame;quit()
