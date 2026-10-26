extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Tips = preload("res://scripts/pistas.gd")
const Com = preload("res://tests/medir_comun.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func preparar(j, condicion: String) -> void:
	match condicion:
		"enemigo_cerca": j.combate.enemigos[0].pos = j.pies - Vector2(0, 6)
		"herido": j.jug().hp = 1
		"npc_cerca": j.pies = j.habitantes.pos(j.habitantes.ids[0])
		"mesa", "horno":
			j.d.mundo.constr.clear()
			j.d.mundo.constr[M.clave(M.celda_de(j.pies) + Vector2i.RIGHT)] = {"t": condicion}
			j.mundo.cambiar()
		"rumor": j.jug().mapa.bloques["100,100"] = "npc:maren"
		"exterior": j.pies = M.pies_de_celda(Vector2i(-30, -30))
		"noche": j.d.min = 21 * 60
		"madera", "piedra": j.jug().inv[condicion] = 1
		"equipable": j.jug().inv["espada_hierro"] = 1
		"saber_pendiente": j.jug().inv["madera"] = 1
		"cama_propia": j.jug().cama = [100, 100]
func _init() -> void:
	var reglas: Array = Tips.datos().reglas
	ok(reglas.size() >= 12, "al menos doce pistas en datos")
	for r in reglas:
		var j = J.nueva(123, "Pistas", [0, 0, 0], "poblado")
		preparar(j, r.precondicion)
		ok(Tips.cumple(j, J.LOCAL, r.precondicion), "contexto real: " + r.id)
		j.jug().pistas = {"mostradas": {}, "descartadas": {}, "silenciadas": false}
		for otra in reglas:
			if otra.id != r.id: j.jug().pistas.mostradas[otra.id] = true
		j.gestionar_pista("pedir")
		ok(j.pista_contextual().get("id", "") == r.id, "se muestra: " + r.id)
		j.gestionar_pista("pedir")
		ok(j.pista_contextual().get("id", "") == r.id and j.jug().pistas.mostradas.size() == reglas.size(), "una sola activa: " + r.id)
		j.gestionar_pista("descartar")
		ok(j.pista_contextual().is_empty() and j.jug().pistas.descartadas.has(r.id), "descarte: " + r.id)
		j.rt[J.LOCAL].pista_espera = 0
		j.gestionar_pista("pedir")
		ok(j.pista_contextual().is_empty(), "no se repite: " + r.id)
	var j = J.nueva(123, "Pistas", [0, 0, 0], "poblado")
	j.gestionar_pista("silenciar")
	j.gestionar_pista("pedir")
	ok(j.pista_contextual().is_empty(), "silencio impide toda pista")
	j.guardar("/tmp/linde-pistas.json")
	var c = J.cargar("/tmp/linde-pistas.json")
	ok(c.jug().pistas.silenciadas, "silencio persiste al cargar")
	j.gestionar_pista("activar")
	j.gestionar_pista("pedir")
	var primera: String = j.pista_contextual().id
	Tips.paso(j, J.LOCAL, float(Tips.datos().duracion_s))
	ok(j.pista_contextual().is_empty(), "desaparece al agotar duración")
	j.gestionar_pista("pedir")
	ok(j.pista_contextual().is_empty(), "enfriamiento evita encadenar pistas")
	j.guardar("/tmp/linde-pistas.json")
	c = J.cargar("/tmp/linde-pistas.json")
	c.gestionar_pista("pedir")
	ok(c.pista_contextual().get("id", "") != primera and c.jug().pistas.mostradas.has(primera), "pista vista no se repite al cargar")
	j.unir("otro", "Otro", [0, 0, 0])
	j.gestionar_pista("silenciar", "otro")
	ok(not j.jug().pistas.silenciadas and j.jug("otro").pistas.silenciadas, "preferencia personal independiente")
	var des = j.autonomia.desarrollo
	j.jug().inv.madera = 1
	des.aprender(j.actor_desarrollo(), "tec:ligera", "prueba")
	ok(not Tips.cumple(j, J.LOCAL, "saber_pendiente"), "el saber aprendido retira la pista correspondiente")
	var legado = J.nueva(123, "Legado", [0, 0, 0])
	var antes := Com.hash_estado(legado, [])
	legado.gestionar_pista("pedir")
	legado.gestionar_pista("silenciar")
	Tips.paso(legado, J.LOCAL, 100)
	ok(Com.hash_estado(legado, []) == antes, "comandos de pistas no modifican legado")
	quit(1 if fallos else 0)
