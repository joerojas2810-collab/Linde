extends SceneTree
var esc
var out="user://arte_pendiente_revision/"
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
	out=ProjectSettings.globalize_path(out).trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func foto(n):
	esc.queue_redraw();esc.hud.queue_redraw()
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+n+".png")
func run():
	var raiz="res://arte/pendientes_v1/"
	var cat:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(raiz+"catalogo.json"))
	for n in cat:assert(ResourceLoader.exists(raiz+n+".png"))
	for id in ["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]:
		for accion in ["idle","attack","hit","defeat"]:
			for vista in [1,2,3]:assert(ResourceLoader.exists(raiz+"fauna_"+id+"_"+accion+"_"+str(vista)+".png"))
	var v=preload("res://scripts/viajero071.gd").new()
	for name in ["espada","escudo"]:
		var hashes=[]
		for i in 3:hashes.append(hash(v.held_image(name,{"_silueta":i}).get_data()))
		assert(hashes[0]!=hashes[1] and hashes[1]!=hashes[2] and hashes[0]!=hashes[2])
	root.size=Vector2i(1280,720);esc=load("res://main.tscn").instantiate();esc.ruta="user://pendientes_qa_aislada.json";root.add_child(esc)
	esc.j=preload("res://scripts/juego.gd").nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.modo="juego";esc.set_process(false)
	var sociedad=esc.j.autonomia.sociedad
	# Fixture de prueba: permite una llegada por el generador real sin cambiar reglas guardadas.
	sociedad.cfg.inmigracion.presion_minima=0;sociedad.cfg.inmigracion.espera_min=0
	sociedad._inmigrar()
	var colonos:Dictionary=esc.j.d.mundo_vivo.autonomia.get("colonos",{})
	if not colonos.is_empty():
		var id:String=colonos.keys()[0]
		assert(not esc.j.autonomia.perfil(id).get("biografia",{}).is_empty())
		esc.j.pies=esc.j.habitantes.pos(id)+Vector2(20,0);esc.j.actualizar_regiones();esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
		esc._ver_ficha(id);await foto("14_ficha_colono")
		colonos[id].permanencia.estado="ausente";esc._ver_ficha(id);await foto("15_ficha_ausente")
		var ev=InputEventKey.new();ev.pressed=true;ev.keycode=KEY_ESCAPE;esc._tecla_panel(ev);assert(esc.panel=="")
	else:assert(false,"La fixture no generó un colono")
	esc.j.pies=esc.j.habitantes.pos("maren")+Vector2(20,0);esc.j.actualizar_regiones();esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing();esc._ver_ficha("maren");await foto("12_ficha");esc._cerrar();esc.j.d.npcs.maren.act="sin_cama";await foto("13_al_raso")
	assert(esc.arte_mundo.faltantes.is_empty() and esc.hud.ui.faltantes.is_empty())
	FileAccess.open(out+"REVISION.json",FileAccess.WRITE).store_string(JSON.stringify({"objetos":cat.size(),"tiras_fauna":60,"siluetas_arma_escudo_distintas":true,"ficha_biografia_real_generada":true,"ficha_ausente":true,"cerrar_ficha":true,"recursos_faltantes":0,"alcance":"Comprobación artística dirigida; no suite general ni red. Oficios, campamento y casa comparados en fixtures."},"  "))
	print("PENDIENTES_QA: catálogo, 60 tiras, 6 siluetas, ficha de colono real/ausente y cierre aprobados")
	esc.modo="creador";esc.j=null;esc.queue_free();await process_frame;quit()
