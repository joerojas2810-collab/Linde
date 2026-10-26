extends SceneTree
## Evidencia visual de Mundo 1 (pasos 1c-1e): aparición en el poblado, referencias y estaciones comunitarias. Requiere render (sin --headless).
## Uso: godot --path Linde/cenital --script res://tests/captura_mundo1.gd   → production/qa/evidence/mundo-1/fase-1/*.png
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
var esc
var carpeta: String

func foto(nombre: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/" + nombre + ".png")

func _init() -> void:
	carpeta = ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/fase-1")
	DirAccess.make_dir_recursive_absolute(carpeta)
	esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-captura-mundo1.json"
	root.add_child(esc)
	await process_frame
	esc.j = J.nueva(123, "Visitante", [0, 0, 0], M.MODO_POBLADO)
	esc.modo = "juego"
	await foto("1-aparicion-primer-jugador")
	var mesa := Vector2i(-1, -1)
	for k in esc.j.d.mundo.constr:
		if esc.j.d.mundo.constr[k].t == "mesa": mesa = Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
	esc.j.rt[J.LOCAL].pies = M.pies_de_celda(mesa + Vector2i(0, 2))
	await foto("3-plaza-mesa-y-horno")
	esc.j.rt[J.LOCAL].pies = M.pies_de_celda(Vector2i(10, 12))
	await foto("4-cantera")
	quit(0)
