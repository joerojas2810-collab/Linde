extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var etapa="despues"
var out="user://revision_minerales/"
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
	out=ProjectSettings.globalize_path(out).trim_suffix("/")+"/"
	call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
	esc=load("res://main.tscn").instantiate();esc.ruta="user://minerales_revision_aislada.json";root.add_child(esc)
	esc.j=J.nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.modo="juego";esc.set_process(false);esc.j.d.min=12*60
	esc.j.pies=M.pies_de_celda(Vector2i(29,30));esc.j.actualizar_regiones();esc.cam.position=M.pies_de_celda(Vector2i(29,27));esc.cam.reset_smoothing()
	var m=esc.j.mundo
	for id in m.objetos.keys():
		var c:Vector2i=m.objetos[id].c
		if Rect2i(21,24,16,10).has_point(c):m.por_celda.erase(c);m.objetos.erase(id)
	var tipos=["veta","veta_cobre","veta_estano","arcilla"]
	for fila in 2:
		for i in 4:
			var c=Vector2i(24+i*3,26+fila*3)
			var id="revision_"+str(fila)+"_"+tipos[i]
			m._agregar(tipos[i],c,id)
			if fila==1:m.estado.rotos[id]=true
	var firma=JSON.stringify(m.estado)
	for i in 6:esc.queue_redraw();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+etapa+"_juego.png")
	assert(esc.arte_mundo.faltantes.is_empty())
	assert(JSON.stringify(m.estado)==firma)
	print("MINERALES_",etapa,": ocho recursos llenos/agotados dibujados; estado conservado; sin faltantes")
	esc.modo="creador";esc.j=null;esc.queue_free();await process_frame;quit()
