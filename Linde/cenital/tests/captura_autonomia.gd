extends SceneTree
## Evidencia visual de la escena real. Se ejecuta con render, sin --headless.
const J = preload("res://scripts/juego.gd")
var carpeta := ""
func _init() -> void:
	carpeta = ProjectSettings.globalize_path("res://../../production/qa/evidence/autonomia")
	var esc = load("res://main.tscn").instantiate()
	esc.ruta = "/tmp/linde-autonomia-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j = J.nueva(123, "Observador", [0, 0, 0])
	esc.j.autonomia.activar()
	esc.j.combate.enemigos.clear()
	# Evolución real de la simulación, no un estado narrativo prefabricado.
	for i in 1800: esc.j.tick(0.1)
	esc.modo = "juego"
	esc.j.pies = esc.j.habitantes.pos("ordal")
	esc._abrir("mis")
	var antes: int = esc.j.d.min
	for i in 60: esc._process(1.0 / 30.0)
	if esc.j.d.min <= antes:
		push_error("La autonomía se detuvo al abrir el panel")
		quit(1)
		return
	print("PASS UI: el panel de necesidades no congela la simulación")
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/necesidades.png")
	esc._cerrar()
	esc._tras_interactuar(esc.j.interactuar())
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta + "/dialogo.png")
	var f := FileAccess.open(carpeta + "/simulacion.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(esc.j.d.mundo_vivo.autonomia, "  "))
	f.close()
	print("CAPTURAS_AUTONOMIA: " + carpeta)
	quit()
