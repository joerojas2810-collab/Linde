extends SceneTree
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func tecla(e, k: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = k
	e._unhandled_key_input(ev)
func _init() -> void:
	var e = load("res://main.tscn").instantiate()
	e.ruta = "/tmp/linde-pistas-ui.json"
	root.add_child(e)
	await process_frame
	e.j = e.J.nueva(123, "Pistas", [0, 0, 0], "poblado")
	e.modo = "juego"
	await process_frame
	ok(not e.j.pista_contextual().is_empty(), "pista contextual se solicita en juego")
	tecla(e, KEY_T)
	ok(e.j.pista_contextual().is_empty() and not e.j.jug().pistas.descartadas.is_empty(), "T descarta la pista")
	tecla(e, KEY_ESCAPE)
	ok(e.lineas.has("Ya conozco los sistemas: ocultar pistas"), "pausa ofrece ocultar ayuda contextual")
	e.sel = e.lineas.find("Ya conozco los sistemas: ocultar pistas")
	tecla(e, KEY_ENTER)
	ok(e.j.jug().pistas.silenciadas and e.lineas.has("Activar pistas contextuales"), "silencio y reactivación accesibles")
	tecla(e, KEY_ENTER)
	ok(not e.j.jug().pistas.silenciadas, "reactivación funciona")
	tecla(e, KEY_ESCAPE)
	tecla(e, KEY_H)
	e.pista_pedido_t = 0
	var antes: Dictionary = e.j.jug().pistas.mostradas.duplicate()
	await process_frame
	ok(e.j.jug().pistas.mostradas == antes, "ayuda abierta no consume pistas")
	quit(1 if fallos else 0)
