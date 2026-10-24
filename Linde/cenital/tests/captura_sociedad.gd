extends SceneTree
## Capturas de la escena real tras tres días de simulación sin intervención.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
var carpeta := ""
func capturar(nombre: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/" + nombre + ".png")
func _init() -> void:
	carpeta = ProjectSettings.globalize_path("res://../../production/qa/evidence/sociedad")
	var esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-sociedad-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j = J.nueva(123, "Observador", [0, 0, 0])
	esc.j.autonomia.activar()
	esc.j.combate.enemigos.clear()
	for i in 43200: esc.j.tick(0.1)
	esc.modo = "juego"
	esc.j.pies = esc.j.habitantes.pos("ordal")
	esc._abrir("mis")
	await capturar("habitantes")
	# Recorrer el panel real, incluyendo filas de información no seleccionables.
	for i in esc.acc.size():
		if esc.lineas[i].contains("Aportar materiales"):
			esc.sel = i
			await capturar("grupos")
			break
	esc.sel = esc.acc.size()-1
	await capturar("historia")
	esc._cerrar()
	esc._tras_interactuar(esc.j.interactuar())
	await capturar("dialogo")
	esc._cerrar()
	esc.j.pies = M.pies_de_celda(esc.j.autonomia.sociedad._ancla("canteros"))
	await capturar("deposito")
	var f := FileAccess.open(carpeta + "/simulacion.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(esc.j.d.mundo_vivo.autonomia,"  "));f.close()
	print("CAPTURAS_SOCIEDAD: " + carpeta)
	quit()
