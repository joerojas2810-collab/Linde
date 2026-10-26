extends SceneTree
var esc
var carpeta := ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/fase-3")
func foto(n: String) -> void:
	for i in 60: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/" + n + ".png")
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-pistas-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j = esc.J.nueva(123, "Exploradora", [0, 0, 0], "poblado")
	esc.modo = "juego"
	await foto("pista-en-el-pueblo")
	esc._abrir("pausa")
	await foto("opcion-ocultar-pistas")
	esc._cerrar()
	esc.j.gestionar_pista("descartar")
	esc.j.rt[esc.J.LOCAL].pista_espera = 0
	esc.j.pies = esc.Mundo.pies_de_celda(Vector2i(32, 51))
	esc.j.gestionar_pista("pedir")
	await foto("pista-exterior")
	quit()
