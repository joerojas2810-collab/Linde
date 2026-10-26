extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
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
	e.ruta = "/tmp/linde-lugares-ui.json"
	root.add_child(e)
	await process_frame
	e.j = J.nueva(123, "Viajera", [0, 0, 0], "poblado")
	e.modo = "juego"
	var j = e.j
	var lugar: Dictionary = j.d.mundo.registro.lugares["ruinas@0,0"]
	ok(not j.Exploracion.hitos(j, J.LOCAL).any(func(h): return h.get("id", "") == lugar.id), "el mapa no revela destinos desconocidos")
	var npc: String = j.habitantes.ids[0]
	var centro := Vector2i(lugar.centro[0], lugar.centro[1])
	j.autonomia.estado(npc)["bloques"] = {j.autonomia._bloque(centro): true}
	j.pies = j.habitantes.pos(npc)
	j.preguntar_lugares(npc)
	ok(j.Exploracion.hitos(j, J.LOCAL).any(func(h): return h.get("id", "") == lugar.id and h.fuente == "npc:" + npc), "el NPC aporta una referencia aproximada real")
	j.pies = M.pies_de_celda(Vector2i(lugar.entrada[0], lugar.entrada[1]))
	j.actualizar_regiones()
	j.actualizar_mapa()
	ok(j.Exploracion.hitos(j, J.LOCAL).any(func(h): return h.get("id", "") == lugar.id and h.fuente == "visto"), "la visita confirma el destino")
	tecla(e, KEY_E)
	ok(e.panel == "dialogo" and e.dialogo_nombre == lugar.nombre and e.dialogo_npc == "" and e.dialogo_txt == lugar.descripcion, "E examina el lugar con nombre y descripción")
	tecla(e, KEY_ESCAPE)
	for h in M.HITOS_INICIALES:
		j.jug().mapa.bloques[j.autonomia._bloque(Vector2i(h.area[0] + h.area[2]/2, h.area[1] + h.area[3]/2))] = "visto"
	for l in j.d.mundo.registro.lugares.values():
		j.jug().mapa.bloques[j.autonomia._bloque(Vector2i(l.centro[0], l.centro[1]))] = "visto"
	tecla(e, KEY_M)
	tecla(e, KEY_PAGEDOWN)
	ok(e.panel == "mapa" and e.mapa_primera > 0, "mapa pagina referencias sin desbordar")
	await process_frame
	tecla(e, KEY_ESCAPE)
	var camp: Dictionary = j.d.mundo.registro.lugares["campamento@0,0"]
	var ruta: Array = j.d.mundo.registro.rutas[camp.ruta].celdas
	j.pies = M.pies_de_celda(M.ENTRADA)
	j.combate.enemigos.clear()
	var camino_valido := true
	for paso in ruta.slice(1):
		var hasta := M.pies_de_celda(Vector2i(paso[0], paso[1]))
		var delta: Vector2 = hasta - j.pies
		var dir := Vector2i(roundi(delta.x / M.P.CELDA), roundi(delta.y / M.P.CELDA))
		for i in 4: j.mover_pj(dir, 0.0625)
		if j.pies.distance_to(hasta) > 0.1: camino_valido = false; break
	ok(camino_valido, "jugador recorre el sendero al campamento con el movimiento normal")
	j.pies = M.pies_de_celda(Vector2i(camp.centro[0] - 2, camp.centro[1]))
	j.actualizar_regiones()
	j.jug().inv = {"madera": 6, "fibra": 2}
	ok(j.fabricar("escudo_madera").ok and j.jug().inv == {"escudo_madera": 1}, "mesa del campamento fabrica con costes existentes")
	var cc := Vector2i(camp.centro[0] + 2, camp.centro[1] - 1)
	var cid := "c@" + M.clave(cc)
	j.pies = M.pies_de_celda(cc + Vector2i.DOWN)
	ok(j.mover_cofre(cid, "escudo_madera", true).ok and j.jug().inv.is_empty(), "cofre compartido recibe provisiones sin duplicarlas")
	j.guardar("/tmp/linde-campamento.json")
	var guardado = J.cargar("/tmp/linde-campamento.json")
	ok(guardado.d.cofres[cid].inv == {"escudo_madera": 1}, "cofre usado conserva contenido al reiniciar")
	j.unir("otra", "Otra", [0, 0, 0])
	j.rt.otra.pies = j.pies
	ok(j.mover_cofre(cid, "escudo_madera", false, "otra").ok and j.jug("otra").inv == {"escudo_madera": 1} and j.d.cofres[cid].inv.is_empty(), "otro jugador usa el mismo cofre compartido")
	quit(1 if fallos else 0)
