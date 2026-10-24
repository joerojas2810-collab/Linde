extends SceneTree
class Galeria extends Node2D:
	const A = preload("res://scripts/aspecto.gd")
	var arte = preload("res://scripts/arte_equipo.gd").new()
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,1000), Color("202b33"))
		draw_string(ThemeDB.fallback_font, Vector2(30,40), "LINDE · Aspectos de PJ y NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
		for i in 3:
			var look: Array = A.npc(["maren", "ordal", "nerea"][i])
			draw_string(ThemeDB.fallback_font, Vector2(40+i*480,82), ["Maren", "Ordal", "Nerea"][i], HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
			for k in 4:
				draw_set_transform(Vector2(35+i*480+k*80,90),0,Vector2(3,3))
				arte.dibujar(self,Vector2(12,32),[Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT][k],0,[],look)
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		for identidad in 2:
			var y := 260 + identidad*230
			draw_string(ThemeDB.fallback_font,Vector2(30,y),A.IDENTIDAD[identidad] + " · 10 peinados",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
			for estilo in 10:
				var x := 18+estilo*158
				draw_string(ThemeDB.fallback_font,Vector2(x,y+34),A.peinados(identidad)[estilo],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
				for k in 2:
					draw_set_transform(Vector2(x+k*66,y+50),0,Vector2(3,3))
					arte.dibujar(self,Vector2(12,32),Vector2i.DOWN if k==0 else Vector2i.UP,0,[],[4,6,5,identidad,estilo,3,2,1])
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		for piel in 8:
			draw_set_transform(Vector2(45+piel*190,770),0,Vector2(4,4))
			arte.dibujar(self,Vector2(12,32),Vector2i.DOWN,0,[],[piel,4,6,1,0,0,0,0])
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		draw_string(ThemeDB.fallback_font,Vector2(30,965),"8 tonos de piel · 10 colores de pelo y ropa · 8 pantalones · 6 botas y cinturones · cuerpo compartido",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color.WHITE)
class Detalle extends Node2D:
	var arte = preload("res://scripts/arte_equipo.gd").new()
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,1000), Color("202b33"))
		draw_string(ThemeDB.fallback_font, Vector2(30,50), "LINDE · Revisión de capas y siluetas en cuatro direcciones",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
		var nombres := ["Corto uniforme", "Despeinado", "Rizado", "Coleta", "Trenza", "Pixie"]
		var opciones := [[0,1], [0,4], [0,7], [1,4], [1,5], [1,0]]
		for i in 6:
			var pos := Vector2(25+(i%3)*530,120+(i/3)*420)
			draw_string(ThemeDB.fallback_font,pos,nombres[i],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
			for k in 4:
				draw_set_transform(pos+Vector2(k*120,40),0,Vector2(4,4))
				arte.dibujar(self,Vector2(12,32),[Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT][k],0,[],[4,5,5,opciones[i][0],opciones[i][1],3,2,1])
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			for k in 4: draw_string(ThemeDB.fallback_font,pos+Vector2(k*120,220),["Frente", "Derecha", "Espalda", "Izquierda"][k],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
func _initialize() -> void:
	call_deferred("capturar")
func capturar() -> void:
	var salida := ProjectSettings.globalize_path("user://pruebas_aspecto")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="): salida = arg.substr(9)
	DirAccess.make_dir_recursive_absolute(salida)
	root.size = Vector2i(1280,720)
	var esc = load("res://main.tscn").instantiate()
	root.add_child(esc)
	esc.modo = "creador"
	esc.cr.identidad = 1
	esc.cr.peinado = 2
	esc.cr.piel = 6
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join("creador.png"))
	esc.queue_free()
	await process_frame
	root.size = Vector2i(1600,1000)
	root.content_scale_size = Vector2i(1600,1000)
	var g := Galeria.new()
	root.add_child(g)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join("galeria.png"))
	g.queue_free()
	await process_frame
	var detalle := Detalle.new()
	root.add_child(detalle)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(salida.path_join("peinados_corregidos.png"))
	quit()
