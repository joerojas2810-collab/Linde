extends SceneTree
var esc
var carpeta := ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/fase-4")
func foto(n: String) -> void:
	esc.cam.position = esc.j.pies - Vector2(0, 12)
	esc.queue_redraw()
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/" + n + ".png")
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-lugares-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j = esc.J.nueva(123, "Exploradora", [0, 0, 0], "poblado")
	esc.modo = "juego"
	esc.set_process(false)
	esc.j.gestionar_pista("silenciar")
	esc.j.combate.enemigos.clear()
	var npc: String = esc.j.habitantes.ids[0]
	esc.j.pies = esc.j.habitantes.pos(npc)
	esc.j.preguntar_lugares(npc)
	for tipo in ["ruinas", "campamento", "cueva"]:
		var lugar: Dictionary = esc.j.d.mundo.registro.lugares[tipo + "@0,0"]
		var ruta: Array = esc.j.d.mundo.registro.rutas[lugar.ruta].celdas
		for q in ruta:
			esc.j.pies = esc.Mundo.pies_de_celda(Vector2i(q[0], q[1]))
			esc.j.actualizar_regiones()
			esc.j.actualizar_mapa()
		esc.pista = esc._pista()
		await foto(tipo)
		if tipo == "cueva":
			esc._interactuar()
			await foto("cueva-inspeccion")
			esc._cerrar()
	esc.mapa_centro = Vector2i(42, 54)
	esc.mapa_escala = 5.5
	esc.mapa_primera = 3
	esc._abrir("mapa")
	await foto("mapa-lugares-y-rutas")
	quit()
