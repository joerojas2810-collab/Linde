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
	e.ruta = "/tmp/linde-exploracion-ui.json"
	root.add_child(e)
	await process_frame
	e.j = e.J.nueva(123, "Mapa", [0, 0, 0], "poblado")
	e.modo = "juego"
	tecla(e, KEY_M)
	ok(e.panel == "mapa", "M abre el mapa")
	var c: Vector2i = e.mapa_centro
	tecla(e, KEY_RIGHT)
	tecla(e, KEY_MINUS)
	ok(e.mapa_centro.x == c.x + 8 and e.mapa_escala < 10, "desplazamiento y zoom")
	tecla(e, KEY_HOME)
	ok(e.mapa_centro == e.Mundo.celda_de(e.j.pies), "Inicio centra al jugador")
	await process_frame
	tecla(e, KEY_M)
	ok(e.panel == "", "M cierra el mapa")
	var npc: String = e.j.habitantes.ids[0]
	e.j.pies = e.j.habitantes.pos(npc)
	tecla(e, KEY_E)
	ok(e.panel == "dialogo" and e.dialogo_npc == npc, "conversación conserva identidad")
	tecla(e, KEY_L)
	ok(e.panel == "" and e.j.jug().mapa.bloques.values().has("npc:" + npc), "L intercambia y cierra")
	quit(1 if fallos else 0)
