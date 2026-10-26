extends SceneTree
var esc
var carpeta := ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/fase-2")
func foto(n: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/" + n + ".png")
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-mapa-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j = esc.J.nueva(123, "Exploradora", [0, 0, 0], "poblado")
	esc.modo = "juego"
	esc.mapa_centro = esc.Mundo.celda_de(esc.j.pies)
	esc._abrir("mapa")
	await foto("mapa-recorrido")
	esc._cerrar()
	var npc: String = esc.j.habitantes.ids[0]
	esc.j.pies = esc.j.habitantes.pos(npc)
	esc._interactuar()
	await foto("conversacion")
	esc.j.preguntar_lugares(npc)
	esc.mapa_escala = 7.0
	esc.mapa_centro = Vector2i(32, 24)
	esc._abrir("mapa")
	await foto("mapa-compartido")
	quit()
