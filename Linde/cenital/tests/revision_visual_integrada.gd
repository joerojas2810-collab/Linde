extends SceneTree
var esc
var out="user://revision_visual_integrada/"
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
	out=ProjectSettings.globalize_path(out).trim_suffix("/")+"/"
	call_deferred("run")
func foto(n):
	esc.queue_redraw();esc.hud.queue_redraw()
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+n+".png")
func poner_hud(h):
	var anterior=esc.hud;var capa=anterior.get_parent();capa.remove_child(anterior);anterior.queue_free()
	esc.hud=h;h.esc=esc;h.set_anchors_preset(Control.PRESET_FULL_RECT);h.mouse_filter=Control.MOUSE_FILTER_IGNORE;capa.add_child(h)
func tecla(k):
	var e=InputEventKey.new();e.pressed=true;e.keycode=k;esc._unhandled_key_input(e)
func run():
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
	esc=load("res://main.tscn").instantiate();esc.ruta="user://vivo_muestra_aislada.json";root.add_child(esc)
	esc.j=preload("res://scripts/juego.gd").nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.modo="juego";esc.set_process(false)
	esc.j.pies=preload("res://scripts/mundo.gd").pies_de_celda(Vector2i(29,24));esc.j.actualizar_regiones();esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
	esc.j.jug().inv={"madera":12,"piedra":18,"baya":6,"espada_hierro":1,"hacha_piedra":1,"mena":4,"unguento":3,"escudo_madera":1}
	esc.j.guardar(out+"partida_muestra.json")
	var arte_nuevo=esc.arte_mundo
	for tipo in ["despues"]:
		esc.arte_mundo=arte_nuevo;esc.arte_mundo.cargar()
		poner_hud(preload("res://scripts/hud_vivo.gd").new())
		esc._cerrar();await foto("01_valle_"+tipo)
		esc._abrir("inv")
		var ks=esc.j.jug().inv.keys();ks.sort();esc.sel=11+ks.find("espada_hierro")
		await foto("02_inventario_"+tipo)
	assert(esc.hud.objetivos.size()==15)
	esc.sel=11;tecla(KEY_DOWN);assert(esc.sel==16);tecla(KEY_UP);assert(esc.sel==11);tecla(KEY_LEFT);assert(esc.sel==9);tecla(KEY_RIGHT);assert(esc.sel==11)
	var ks=esc.j.jug().inv.keys();ks.sort();esc.sel=11+ks.find("espada_hierro")
	esc.hud._activar();assert(esc.j.jug().equipo.arma=="espada_hierro")
	esc.sel=9;esc.hud._activar();assert(esc.j.jug().equipo.get("arma","")=="")
	esc.j.jug().hp=20;esc._armar();ks=esc.j.jug().inv.keys();ks.sort();esc.sel=11+ks.find("unguento");esc.hud._activar();assert(esc.j.jug().hp>20)
	var art=preload("res://scripts/equipo.gd")
	for slot in ["casco","torso","guantes","pantalones","botas"]:esc.j.jug().equipo[slot]=art.Artesania.clave(slot,"hierro","simple",1)
	esc._armar();esc.sel=3;await foto("03_equipo_real")
	# Many real catalog entries exercise inventory pages without adding unknown ids.
	for k in preload("res://scripts/catalogos.gd").ITEMS:esc.j.jug().inv[k]=1
	esc._armar();esc.sel=esc.lineas.size()-1;esc._sel_valida(-1);await foto("04_mochila_pagina_final")
	assert(esc.hud.objetivos.any(func(t):return t.i==esc.sel))
	var h=esc.hud;esc._cerrar();tecla(KEY_H);assert(esc.ayuda_visible);await foto("05_ayuda")
	assert(arte_nuevo.faltantes.is_empty() and h.ui.faltantes.is_empty())
	FileAccess.open(out+"REVISION.txt",FileAccess.WRITE).store_string("PASS: capturas de la escena principal integrada; equipar/quitar; usar ungüento; selección visible en última página; ayuda H; recursos disponibles. Cámara 3x. Avisos heredados de recursos al cerrar persisten. Interfaz y acabado integrados en main.tscn.")
	print("VISUAL_VIVO: equipar/quitar/usar, paginación, ayuda y recursos aprobados")
	esc.modo="creador";esc.j=null;esc.queue_free();await process_frame;quit()
