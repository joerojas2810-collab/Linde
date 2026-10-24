extends SceneTree
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Apar = preload("res://scripts/apariencia.gd")
const Guard = preload("res://scripts/guardado.gd")
const J = preload("res://scripts/juego.gd")
const Capas = preload("res://scripts/capas_sprite.gd")
var fallos := 0
var tmp := ""

func ok(cond: bool, nombre: String) -> void:
	print(("PASS " if cond else "FAIL ") + nombre)
	if not cond: fallos += 1

func g(sem: int = 1):
	var j = J.nueva(sem, "Test", [0, 0, 0], "viajero")
	j.pies = Mundo.pies_de_celda(Vector2i(32, 40))
	j.combate.enemigos.clear()
	return j

func andar(m, p: Vector2, d: Vector2i, segundos: float) -> Vector2:
	for i in int(segundos * 60): p = m.mover(p, Vector2(d) * P.VELOCIDAD / 60.0)
	return p

func objeto(j, tipo: String) -> String:
	for id in j.mundo.objetos: if j.mundo.objetos[id].t == tipo and not j.mundo.estado.rotos.has(id): return id
	return ""

func norm(x):
	return J._enteros(JSON.parse_string(JSON.stringify(x)))

func sim(j, seg: float, dt: float = 0.05) -> void:
	for i in int(seg / dt): j.tick(dt)

func _init() -> void:
	tmp = ProjectSettings.globalize_path("user://") + "pruebas_linde"
	DirAccess.make_dir_recursive_absolute(tmp)
	for f in DirAccess.get_files_at(tmp): DirAccess.remove_absolute(tmp + "/" + f)
	t_catalogos(); t_mundo(); t_apariencia(); t_inventario(); t_recoleccion(); t_fabricacion(); t_construccion()
	t_progresion(); t_flujo(); t_misiones(); t_tesoro(); t_combate(); t_habitantes(); t_persistencia(); t_regeneracion(); t_capas(); t_equipo()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos else 0)

func t_catalogos() -> void:
	var e := C.validar()
	if not e.is_empty(): print(e)
	ok(e.is_empty(), "catálogos: referencias, ciclos y alcanzabilidad de habilidades válidos")
	var roto := C.HAB.duplicate(true)
	ok(C.nivel_de(0) == 1 and C.nivel_de(25) == 2 and C.nivel_de(99999) == C.NIVEL_MAX, "niveles por xp")

func t_mundo() -> void:
	var m := Mundo.new()
	var alc := m.alcanzables()
	var todos := true
	for e in Mundo.ESENCIALES: if not alc.has(e): todos = false
	ok(todos, "lugares esenciales alcanzables desde el inicio del camino")
	ok(m.spawns_slime.size() == Mundo.N_SLIMES, "spawns de slimes generados")
	var buenos := true
	for s in range(1, 201):
		var c: Vector2i = m.punto_inicio(s)
		if not (alc.has(c) and m.caja_libre(Mundo.pies_de_celda(c))): buenos = false
		for sp in m.spawns_slime: if Vector2(c).distance_to(Vector2(sp)) < 12.0: buenos = false
		if Vector2(c).distance_to(Vector2(Mundo.CLARO)) < 14.0 or Vector2(c).distance_to(Vector2(Mundo.SPAWN_GUARDIAN)) < 14.0: buenos = false
	ok(buenos, "200 semillas: inicio libre, con salida y lejos de enemigos/jefes")
	ok(m.punto_inicio(7) == m.punto_inicio(7), "misma semilla, mismo inicio")
	var distintos := {}
	for s in range(1, 30): distintos[m.punto_inicio(s)] = true
	ok(distintos.size() > 10, "semillas distintas dan inicios distintos")
	var p0 := Mundo.pies_de_celda(Vector2i(32, 40))
	ok(absf(andar(m, p0, Vector2i.UP, 1.0).y - (p0.y - P.VELOCIDAD)) < 0.01, "velocidad = 64 px/s")
	var junto := Vector2(24 * 16 - 6, 19 * 16 + 8)
	ok(andar(m, junto, Vector2i.RIGHT, 1.0).x < 24 * 16, "pared de la casa bloquea desde fuera")
	var d := m.mover(junto, Vector2(2, 2))
	ok(d.x == junto.x and d.y > junto.y, "diagonal contra pared desliza")
	var arb := objeto_de(m, "arbol")
	ok(not m.caja_libre(Mundo.pies_de_celda(m.objetos[arb].c)), "tronco bloquea")
	ok(m.alcanzables(Vector2i(23, 19)).has(Vector2i(32, 19)), "se puede rodear la casa")
	var dentro := andar(m, Mundo.pies_de_celda(Vector2i(27, 23)), Vector2i.UP, 1.5)
	ok(Mundo.CASA.has_point(Mundo.celda_de(dentro)) and Mundo.celda_de(dentro).y < 22, "entra por la puerta bajo el techo")
	ok(Mundo.dir_cardinal([Vector2i.UP, Vector2i.LEFT], Vector2i.LEFT) == Vector2i.LEFT, "conserva dirección pulsada")
	ok(Mundo.dir_cardinal([], Vector2i.UP) == Vector2i.ZERO, "sin teclas, quieto")
	ok(m.punto_inicio(1) == Mundo.new().punto_inicio(1) and Mundo.new().objetos.size() == m.objetos.size(), "mapa de autor determinista")

func objeto_de(m, tipo: String) -> String:
	for id in m.objetos: if m.objetos[id].t == tipo: return id
	return ""

func t_apariencia() -> void:
	var anclas := true
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		for f in 4:
			var suelo := false
			var pelo := false
			for capa in Apar.capas(dir, f):
				var r: Rect2i = capa[1]
				if not Rect2i(0, 0, 16, 24).encloses(r): anclas = false
				if capa[0] == "piernas" and r.end.y == 24: suelo = true
				if capa[0] == "pelo": pelo = true
			if not (suelo and pelo): anclas = false
	ok(anclas, "apariencia: capas en 16x24, pies en y=24, pelo presente (4 dir x 4 cuadros)")

func t_inventario() -> void:
	var inv := {"madera": 1000}
	ok(Inv.slots(inv) == 20 and not Inv.cabe(inv, {"piedra": 1}, 20), "inventario lleno se detecta")
	var antes := inv.duplicate()
	ok(not Inv.cambiar(inv, {"madera": 2}, {"hacha_piedra": 1, "piedra": 60}, 20) and inv == antes, "cambio atómico: si no cabe, nada cambia")
	ok(Inv.cambiar(inv, {"madera": 50}, {"piedra": 50}, 20) and inv.madera == 950 and inv.piedra == 50, "cambio atómico válido")
	ok(not Inv.quitar(inv, {"piedra": 51}) and inv.piedra == 50, "quitar sin existencias no altera")

func t_recoleccion() -> void:
	var j = g()
	var roca := objeto(j, "roca")
	var c: Vector2i = j.mundo.objetos[roca].c
	var vt := objeto(j, "veta")
	ok(not j.golpear_objeto(j.mundo.objetos[vt].c).ok, "veta sin pico: se rechaza")
	for i in 9: j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == roca, "roca a mano: 10 golpes (arranque sin ciclo pico<->piedra)")
	j = g()
	roca = objeto(j, "roca")
	c = j.mundo.objetos[roca].c
	j.d.inv = {"pico_piedra": 1}
	var xp0: int = j.d.xp
	for i in 3: j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == roca, "roca aguanta 3 golpes")
	j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == "" and j.d.inv.piedra == 2 and j.d.xp == xp0 + 2, "4º golpe: se rompe, 2 piedra y xp, una sola vez")
	ok(not j.mundo.bloquea(c), "la celda queda libre")
	ok(not j.golpear_objeto(c).ok and j.d.inv.piedra == 2, "no se puede romper dos veces (sin duplicar)")
	var j2 = g()
	j2.d.inv = {"pico_piedra": 1}
	var veta := objeto(j2, "veta")
	var cv: Vector2i = j2.mundo.objetos[veta].c
	var j3 = g()
	j3.d.inv = {"pico_piedra": 1}
	for i in 6:
		j2.golpear_objeto(cv)
		j3.golpear_objeto(cv)
	ok(j2.d.inv == j3.d.inv and j2.d.inv.mena == 2, "botín probabilístico determinista por semilla y objeto")
	var j4 = g()
	j4.d.hab = ["recolector"]
	j4.d.inv = {"pico_piedra": 1}
	var r2 := objeto(j4, "roca")
	var cr: Vector2i = j4.mundo.objetos[r2].c
	for i in 3: j4.golpear_objeto(cr)
	ok(j4.mundo.objeto_presente(cr) == "", "habilidad Recolector: un golpe menos")
	var j5 = g()
	j5.d.inv = {"madera": 1000}
	var bus := objeto(j5, "arbusto")
	var cb: Vector2i = j5.mundo.objetos[bus].c
	var inv5: Dictionary = j5.d.inv.duplicate()
	ok(not j5.golpear_objeto(cb).ok and j5.mundo.objeto_presente(cb) == bus and j5.d.inv == inv5, "inventario lleno: el objeto no se rompe ni se pierde nada")

func t_fabricacion() -> void:
	var j = g()
	ok(not j.fabricar("hacha_piedra").ok and j.d.inv.is_empty(), "sin materiales: falla sin cambios")
	j.d.inv = {"piedra": 2, "madera": 2, "fibra": 1}
	ok(j.fabricar("hacha_piedra").ok and j.d.inv == {"hacha_piedra": 1}, "fabricar consume y entrega")
	j.d.inv = {"mena": 2, "madera": 1}
	ok(not j.fabricar("lingote").ok, "lingote exige habilidad y horno")
	j.d.hab = ["artesano"]
	ok(not j.fabricar("lingote").ok and j.d.inv == {"mena": 2, "madera": 1}, "con habilidad pero lejos del horno: falla")
	j.mundo.poner(Vector2i(33, 40), "horno", true)
	ok(j.fabricar("lingote").ok and j.d.inv == {"lingote": 1}, "junto al horno: fabrica")
	j.d.inv = {"lingote": 2, "madera": 1}
	j.mundo.poner(Vector2i(31, 40), "mesa", true)
	ok(j.fabricar("espada_hierro").ok and j.stats().dmg == C.DMG_BASE + 6, "espada: daño derivado del inventario")

func t_construccion() -> void:
	var j = g()
	j.d.inv = {"madera": 20}
	ok(j.construir("muro", Vector2i(33, 40)).ok and j.mundo.bloquea(Vector2i(33, 40)) and j.d.inv.madera == 18, "construir: coste y colisión")
	ok(not j.construir("muro", Vector2i(33, 40)).ok and j.d.inv.madera == 18, "no se construye sobre otra construcción")
	ok(not j.construir("muro", Vector2i(32, 40)).ok, "no se construye sobre el jugador")
	ok(not j.construir("muro", Vector2i(Mundo.PUERTA_C.x, Mundo.PUERTA_C.y)).ok, "no se construye en la puerta")
	var arb: String = objeto(j, "arbol")
	ok(not j.construir("muro", j.mundo.objetos[arb].c).ok, "no se construye sobre un árbol")
	var antes: Dictionary = j.d.inv.duplicate()
	ok(not j.construir("muro", Vector2i(27, 23)).ok and j.d.inv == antes and j.mundo.constr_en(Vector2i(27, 23)).is_empty(), "bloquear un lugar esencial se rechaza y revierte")
	ok(not j.construir("muro", Vector2i(30, 19)).ok, "no se encierra la cama de Maren")
	ok(j.construir("muro", Vector2i(31, 40)).ok and j.construir("muro", Vector2i(32, 39)).ok, "muros laterales válidos")
	ok(not j.construir("muro", Vector2i(32, 41)).ok, "no se puede encerrar al propio jugador")
	ok(j.retirar(Vector2i(33, 40)).ok and j.d.inv.madera == 18 - 4 + 2 and not j.mundo.bloquea(Vector2i(33, 40)), "retirar devuelve el coste")
	ok(not j.retirar(Mundo.CAMA_MAREN).ok, "no se retiran construcciones ajenas")
	j.d.inv = {"madera": 4}
	ok(j.construir("cofre", Vector2i(33, 40)).ok, "construir cofre")
	j.d.inv = {"piedra": 5}
	var cid := "c@33,40"
	ok(j.mover_cofre(cid, "piedra", true).ok and j.d.cofres[cid].inv.piedra == 5 and j.d.inv.is_empty(), "depositar en cofre")
	ok(not j.retirar(Vector2i(33, 40)).ok, "cofre con contenido no se retira (no se pierde nada)")
	ok(j.mover_cofre(cid, "piedra", false).ok and j.retirar(Vector2i(33, 40)).ok and j.d.inv.piedra == 5 and j.d.inv.madera == 4, "vaciar y retirar cofre")
	j.d.inv = {"madera": 4, "fibra": 4}
	j.d.min = 20 * 60
	j.construir("cama", Vector2i(33, 40))
	j.mira = Vector2i.RIGHT
	j.d.pj.hp = 3
	var r: Dictionary = j.interactuar()
	ok(r.panel == "dormir" and j.d.min % 1440 == 360 and j.dia() == 2 and j.d.pj.hp == j.stats().hp, "dormir en cama propia: amanece, cura, nuevo día")
	ok(j.d.pj.cama.size() == 2, "cama propia fija el punto de reaparición")

func t_progresion() -> void:
	var j = g()
	ok(not j.aprender("golpe_fuerte").ok, "nivel 1: sin puntos")
	j.d.xp = 100
	ok(j.nivel() == 3 and j.puntos_libres() == 2, "nivel 3 = 2 puntos")
	ok(not j.aprender("dominio").ok, "requisitos de rama")
	ok(j.aprender("golpe_fuerte").ok and not j.aprender("golpe_fuerte").ok, "aprender una vez")
	var s1: Dictionary = j.stats()
	ok(s1.dmg == C.DMG_BASE + 3, "efecto derivado de la habilidad")
	var ruta := tmp + "/prog.json"
	j.guardar(ruta)
	var j2 = J.cargar(ruta)
	ok(j2.stats() == s1 and j2.d.hab == ["golpe_fuerte"], "cargar no vuelve a aplicar el bonus")
	ok(j2.stats() == J.cargar(ruta).stats(), "cargas repetidas dan lo mismo")
	ok(not j.aprender("artesano").ok, "sin puntos o requisito, no se aprende")

func t_misiones() -> void:
	var j = g()
	var r: Dictionary = j.hablar("maren")
	ok(r.tipo == "mision" and j.estado_mision("cap1_piedras") == "activa" and r.texto.begins_with(C.DIALOGOS.origen.viajero), "diálogo abre misión con línea de origen")
	j.d.inv = {"piedra": 5}
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "activa", "5/6 piedras: sigue activa")
	j.d.inv.piedra = 6
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "cumplida", "6 piedras: cumplida")
	j.d.inv.piedra = 3
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "activa", "condición actual perdida: vuelve a activa")
	j.d.inv.piedra = 6
	j.evaluar_misiones()
	var rr: Dictionary = j.hablar("maren")
	ok(rr.tipo == "relacion" and j.estado_mision("cap1_piedras") == "entregada" and j.d.inv == {"madera": 5} and j.d.xp == 20, "entrega: consume, premia y sube relación")
	ok(j.d.npcs.maren.relacion == 1, "relación cambia solo con entrega")
	ok(not j.entregar("cap1_piedras").ok and j.d.xp == 20, "recompensa una sola vez")
	var ruta := tmp + "/mis.json"
	j.guardar(ruta)
	var j2 = J.cargar(ruta)
	j2.evaluar_misiones()
	ok(j2.d.xp == 20 and j2.d.inv == {"madera": 5} and not j2.entregar("cap1_piedras").ok, "recargar no repite la recompensa")
	var t: Dictionary = j.hablar("maren")
	ok(t.tipo == "mision" and j.estado_mision("cap1_mesa") == "activa", "siguiente misión tras entregar")
	j.d.inv = {"madera": 5, "piedra": 2}
	j.construir("mesa", Vector2i(33, 40))
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_mesa") == "cumplida", "construcción en pie cumple")
	j.retirar(Vector2i(33, 40))
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_mesa") == "activa", "mesa retirada: ya no se cumple")
	j.construir("mesa", Vector2i(33, 40))
	j.hablar("maren")
	ok(j.estado_mision("cap1_mesa") == "entregada" and j.d.inv.get("mena", 0) == 2, "mesa entregada y premiada")
	j.hablar("maren")
	ok(j.estado_mision("cap1_ruinas") == "activa", "misión de ruinas activa")
	j.d.eventos["visito_ruinas"] = true
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_ruinas") == "activa", "visitar sin derrotar al jefe no basta")

func t_tesoro() -> void:
	var a = g(5)
	var b = g(5)
	b.d.inv = {"pico_piedra": 1}
	ok(a.d.cofres.tesoro_cantera.inv == b.d.cofres.tesoro_cantera.inv, "tesoro: mismo resultado por semilla")
	var ruta := tmp + "/tes.json"
	a.guardar(ruta)
	ok(J.cargar(ruta).d.cofres.tesoro_cantera.inv == a.d.cofres.tesoro_cantera.inv, "tesoro: cargar no cambia el premio")
	a.d.inv = {"madera": 1000}
	var antes: Dictionary = a.d.cofres.tesoro_cantera.inv.duplicate()
	ok(not a.abrir_tesoro("tesoro_cantera").ok and a.d.cofres.tesoro_cantera.inv == antes, "inventario lleno: el cofre conserva su contenido")
	a.d.inv = {}
	ok(a.abrir_tesoro("tesoro_cantera").ok and a.d.inv.gema >= 1, "abrir entrega el contenido")
	var inv_a: Dictionary = a.d.inv.duplicate()
	ok(not a.abrir_tesoro("tesoro_cantera").ok and a.d.inv == inv_a, "no se abre dos veces")
	a.d.misiones["mundo_tesoro"] = {"estado": "activa"}
	a.evaluar_misiones()
	ok(a.estado_mision("mundo_tesoro") == "cumplida", "misión de mundo por hecho histórico (abrió el cofre)")

func t_combate() -> void:
	var j = g()
	var s: Dictionary = j.combate._nuevo("slime", j.pies + Vector2(0, -30))
	j.combate.enemigos.append(s)
	var hp0: int = j.d.pj.hp
	var t_aviso := -1.0
	var t := 0.0
	var dano_antes_aviso := false
	while t < 1.4:
		j.combate.paso(0.02)
		t += 0.02
		if s.est == "aviso" and t_aviso < 0.0: t_aviso = t
		if j.d.pj.hp < hp0 and t_aviso < 0.0: dano_antes_aviso = true
	ok(not dano_antes_aviso and t_aviso >= 0.0, "enemigo avisa antes de golpear")
	ok(j.d.pj.hp == hp0 - C.ENEMIGOS.slime.dmg, "un ataque = un impacto (invulnerabilidad evita repetir)")
	# golpes del jugador
	var k = g()
	k.mira = Vector2i.UP
	var sl: Dictionary = k.combate._nuevo("slime", k.pies + Vector2(0, -14))
	k.combate.enemigos.append(sl)
	var golpes := 0
	while sl.est != "muerto" and golpes < 6:
		sl.pos = k.pies + Vector2(0, -14)
		sl.est = "idle"
		k.combate.inv_t = 99.0
		k.combate.atacar(Vector2i.UP)
		for i in 30: k.combate.paso(0.02)
		golpes += 1
	ok(golpes == 3 and sl.est == "muerto", "slime (12 hp) cae en 3 golpes de 5")
	ok(k.d.inv.get("gelatina", 0) == 1 and k.d.xp == 8, "drop y xp una sola vez")
	k.combate.enemigos = k.combate.enemigos.filter(func(e): return e.est != "muerto")
	# jefe de capítulo
	var b = g()
	b.pies = Mundo.pies_de_celda(Vector2i(52, 40))
	b.combate._aparecer_si_toca("guardian")
	var boss: Dictionary = b.combate.enemigos[0]
	var hpb: int = b.d.pj.hp
	var aviso_t := -1.0
	t = 0.0
	while t < 3.0 and b.d.pj.hp == hpb:
		b.combate.paso(0.02)
		t += 0.02
		if boss.est == "aviso" and aviso_t < 0.0: aviso_t = t
	ok(aviso_t >= 0.0 and t - aviso_t >= C.ATAQUES.embestida.aviso - 0.05 and b.d.pj.hp == hpb - C.ATAQUES.embestida.dmg, "jefe: señal previa de 0,8 s y luego impacto")
	boss.hp = 40
	b.combate.paso(0.02)
	ok(boss.fase == 1, "jefe cambia de fase al 50%")
	var ataques := {}
	boss.n_atq = 0
	for i in 2: ataques[b.combate._siguiente(boss)] = true; boss.n_atq += 1
	ok(ataques.has("onda") and ataques.has("embestida"), "fase 2 añade un ataque distinto, no solo más vida")
	boss.hp = 1
	b.combate._danar(boss, 5)
	ok(b.estado_mision("cap1_ruinas") == "" and b.d.jefes.guardian.veces == 1 and b.d.inv.get("gema", 0) == 3, "jefe de capítulo: derrota y recompensa fija")
	var ruta := tmp + "/jefe.json"
	b.guardar(ruta)
	var b2 = J.cargar(ruta)
	var vivo := false
	for e in b2.combate.enemigos: if e.tipo == "guardian": vivo = true
	ok(not vivo and b2.d.inv.get("gema", 0) == 3 and b2.d.jefes.guardian.veces == 1, "tras cargar: sigue derrotado y sin recompensa repetida")
	# jefe de mundo reaparece
	var c = g()
	c.jefe_derrotado("ciervo")
	c.combate.reiniciar()
	var cierv := func(): return c.combate.enemigos.any(func(e): return e.tipo == "ciervo")
	ok(not cierv.call(), "jefe de mundo derrotado no está")
	c.d.min += 71 * 60
	c.combate.revisar_reaparicion()
	ok(not cierv.call(), "no reaparece antes de 72 h")
	c.d.min += 2 * 60
	c.combate.revisar_reaparicion()
	ok(cierv.call() and c.d.jefes.ciervo.veces == 1, "reaparece tras 72 h; la historia se conserva")
	# derrota del jugador
	var d = g()
	d.d.inv = {"madera": 7}
	d.danar_pj(1000)
	ok(d.d.pj.hp == d.stats().hp / 2 and d.d.inv == {"madera": 7} and d.pies == Vector2(d.d.pj.inicio[0], d.d.pj.inicio[1]), "derrota: sin perder objetos, vuelve al inicio con media vida")

func t_habitantes() -> void:
	var j = g()
	j.d.min = 12 * 60
	var meta := func(c): return c == Vector2i(34, 25)
	var largo0: int = j.mundo.camino(Vector2i(28, 20), meta).size()
	j.d.inv = {"madera": 40}
	for x in range(28, 32):
		for y in range(23, 26): j.construir("muro", Vector2i(x, y))
	var largo1: int = j.mundo.camino(Vector2i(28, 20), meta).size()
	ok(largo1 > largo0, "muros nuevos alargan la ruta (la navegación se actualiza)")
	var pared := false
	for i in 1200:
		j.habitantes.paso(0.05)
		j.d.min = 12 * 60
		var p: Vector2 = j.habitantes.pos("maren")
		if not j.mundo.caja_libre(p): pared = true
	ok(not pared, "Maren no atraviesa paredes nuevas")
	ok(Mundo.celda_de(j.habitantes.pos("maren")) == Vector2i(34, 25), "Maren llega a su destino rodeando")
	# encierro y recuperación
	var k = g()
	k.d.min = 12 * 60
	k.d.inv = {"madera": 20}
	for c in [Vector2i(27, 20), Vector2i(29, 20), Vector2i(28, 19), Vector2i(28, 21)]: k.construir("muro", c)
	for i in 20: k.habitantes.paso(0.05)
	ok(k.d.npcs.maren.act == "bloqueado", "habitante encerrado: estado bloqueado, no atraviesa")
	k.retirar(Vector2i(28, 21))
	for i in 20: k.habitantes.paso(0.05)
	ok(k.d.npcs.maren.act == "camina", "al retirar el muro retoma la ruta")
	# dormir
	var s = g()
	s.d.min = 22 * 60
	var e0: float = s.d.npcs.maren.energia
	for i in 600:
		s.habitantes.paso(0.05)
		s.d.min = 22 * 60
	ok(s.d.npcs.maren.act == "dormir" and s.d.npcs.maren.energia > e0, "de noche llega a la cama y recupera energía")
	var n = g()
	n.d.min = 22 * 60
	n.mundo.quitar(Mundo.CAMA_MAREN)
	var e1: float = n.d.npcs.maren.energia
	for i in 200: n.habitantes.paso(0.05)
	ok(n.d.npcs.maren.act == "sin_cama" and n.d.npcs.maren.energia < e1, "asignar dormir sin cama no equivale a dormir")

func t_persistencia() -> void:
	var j = g(9)
	j.d.inv = {"pico_piedra": 1, "madera": 10}
	var roca := objeto(j, "roca")
	var c: Vector2i = j.mundo.objetos[roca].c
	for i in 4: j.golpear_objeto(c)
	j.construir("muro", Vector2i(33, 40))
	j.d.xp = 120
	j.aprender("vitalidad")
	var ruta := tmp + "/p.json"
	ok(j.guardar(ruta), "guardar")
	var j2 = J.cargar(ruta)
	ok(JSON.stringify(norm(j.d), "", true) == JSON.stringify(j2.d, "", true), "guardar/cargar conserva todo el estado")
	ok(j2.mundo.objeto_presente(c) == "" and j2.mundo.bloquea(Vector2i(33, 40)), "mundo modificado se conserva")
	j2.guardar(ruta)
	ok(FileAccess.file_exists(ruta + ".bak"), "se mantiene respaldo")
	var f := FileAccess.open(ruta, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	f = FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(txt.substr(0, txt.length() / 2))
	f.close()
	var r = J.cargar(ruta)
	ok(r != null and r.d.xp == 120, "principal truncado: recupera del respaldo")
	f = FileAccess.open(ruta + ".bak", FileAccess.WRITE)
	f.store_string("basura")
	f.close()
	ok(J.cargar(ruta) == null, "ambos corruptos: no se inventa una partida")
	ok(FileAccess.file_exists(ruta), "el archivo corrupto no se borra")
	j.guardar(ruta)
	ok(FileAccess.file_exists(ruta + ".corrupta") and J.cargar(ruta) != null, "guardar sobre corrupto lo conserva aparte y deja una partida válida")
	var f2 := FileAccess.open(ruta + ".tmp", FileAccess.WRITE)
	f2.store_string("{interrumpido")
	f2.close()
	ok(J.cargar(ruta) != null and j.guardar(ruta), "restos de escritura interrumpida no afectan")
	var fut: Dictionary = j.d.duplicate(true)
	fut.formato = 99
	ok(Guard.desempaquetar(Guard.empaquetar(fut)).is_empty(), "formato futuro se rechaza")
	var viejo := {"formato": 0, "semilla": 1}
	var m := Guard.desempaquetar(Guard.empaquetar(viejo))
	ok(m.get("formato") == 1 and m.has("hab") and m.has("recompensas"), "migración v0 -> v1")
	var o = JSON.parse_string(Guard.empaquetar(j.d))
	o.checksum = "00"
	ok(Guard.desempaquetar(JSON.stringify(o)).is_empty(), "checksum erróneo se detecta")

func t_regeneracion() -> void:
	var j = g()
	var bus := objeto(j, "arbusto")
	var c: Vector2i = j.mundo.objetos[bus].c
	j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == "", "arbusto recolectado")
	j.mundo.poner(c, "suelo", true)
	j.d.min += 25 * 60
	j.mundo.regenerar(j.d.min, j.ocupada)
	ok(j.mundo.objeto_presente(c) == "", "no regenera sobre construcción del jugador")
	j.mundo.quitar(c)
	j.mundo.regenerar(j.d.min, j.ocupada)
	ok(j.mundo.objeto_presente(c) == bus, "regenera cuando la celda queda libre")
	var k = g()
	var b2 := objeto(k, "arbusto")
	var c2: Vector2i = k.mundo.objetos[b2].c
	k.golpear_objeto(c2)
	k.d.min += 10 * 60
	k.mundo.regenerar(k.d.min, k.ocupada)
	ok(k.mundo.objeto_presente(c2) == "", "no regenera antes de su plazo")

func romper(j, tipo: String, n: int) -> void:
	var hechos := 0
	for id in j.mundo.objetos:
		if hechos >= n: break
		if j.mundo.objetos[id].t != tipo or j.mundo.estado.rotos.has(id): continue
		var c: Vector2i = j.mundo.objetos[id].c
		for i in 12:
			if j.mundo.objeto_presente(c) == "": break
			j.golpear_objeto(c)
		hechos += 1

# Recorrido completo del capítulo 1 solo con acciones del juego: comprueba que es completable (sin ciclos de recursos).
func t_flujo() -> void:
	var j = g(11)
	romper(j, "arbusto", 1)
	romper(j, "arbol", 2)
	romper(j, "roca", 3)
	ok(j.d.inv.get("fibra", 0) >= 2 and j.d.inv.get("madera", 0) >= 6 and j.d.inv.get("piedra", 0) >= 6, "flujo: materiales básicos a mano")
	ok(j.fabricar("pico_piedra").ok and j.fabricar("hacha_piedra").ok, "flujo: pico y hacha")
	romper(j, "roca", 4)
	ok(j.d.inv.get("piedra", 0) >= 6, "flujo: piedra suficiente con el pico")
	j.hablar("maren")
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "cumplida", "flujo: misión 1 cumplida")
	j.hablar("maren")
	ok(j.estado_mision("cap1_piedras") == "entregada", "flujo: misión 1 entregada")
	romper(j, "arbol", 3)
	ok(j.d.inv.get("madera", 0) >= 5 and j.d.inv.get("piedra", 0) >= 2, "flujo: materiales de la mesa")
	j.hablar("maren")
	ok(j.construir("mesa", Vector2i(33, 40)).ok, "flujo: mesa construida")
	j.hablar("maren")
	ok(j.estado_mision("cap1_mesa") == "entregada", "flujo: misión 2 entregada")
	j.hablar("maren")
	j.pies = Mundo.pies_de_celda(Vector2i(52, 41))
	j.tick(0.6)
	ok(j.d.eventos.has("visito_ruinas"), "flujo: entrar a la arena registra la visita")
	j.combate.enemigos.clear()
	j.combate._aparecer_si_toca("guardian")
	var boss: Dictionary = j.combate.enemigos[0]
	var golpes := 0
	while boss.est != "muerto" and golpes < 40:
		j.combate._danar(boss, j.stats().dmg)
		golpes += 1
	ok(golpes == 16, "flujo: guardián (80 hp) cae con 16 golpes de 5")
	j.tick(0.6)
	j.hablar("maren")
	ok(j.estado_mision("cap1_ruinas") == "entregada" and j.d.inv.get("gema", 0) == 5, "flujo: capítulo 1 completo (3+2 gemas)")
	ok(j.nivel() >= 2, "flujo: el progreso da niveles (xp %d)" % j.d.xp)
	ok(j.hablar("maren").texto == C.DIALOGOS.final, "flujo: diálogo final")

# Escribe hojas sinteticas de color solido en tmp/arte_<celda>; devuelve la carpeta.
func hojas(celda: int, capas: Array, mal: String = "", manifiesto: bool = true) -> String:
	var d := tmp + "/arte_%d%s" % [celda, mal]
	DirAccess.make_dir_recursive_absolute(d)
	if manifiesto:
		var f := FileAccess.open(d + "/personaje.json", FileAccess.WRITE)
		f.store_string(JSON.stringify({"celda": celda, "capas": capas}))
		f.close()
	for i in capas.size():
		var n := celda * 4 + (1 if capas[i] == mal else 0)
		var img := Image.create(n, celda * 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.from_hsv(i / 9.0, 1, 1))
		img.save_png("%s/personaje_%s.png" % [d, capas[i]])
	return d

func t_capas() -> void:
	var todas: Array = ["cuerpo", "pelo", "tunica", "pantalon", "cinturon", "casco", "coraza", "escudo", "espada"]
	for celda in [16, 32]:
		var c = Capas.new(hojas(celda, todas))
		var pies := Vector2(100, 50)
		var cmd: Array = c.comandos(pies, Vector2i.DOWN, 2, [])
		var dst: Rect2 = cmd[0][1]
		var src: Rect2 = cmd[0][2]
		ok(c.disponible() and dst.position == Vector2(100 - celda / 2.0, 50 - celda) and dst.end == Vector2(100 + celda / 2.0, 50)
			and src.position == Vector2(2 * celda, 0), "capas: ancla de pies celda %d (centro inferior en 'pies')" % celda)
		var img: Image = c.texturas["cuerpo"].get_image()
		ok(img.get_pixel(int(src.position.x) + celda / 2, int(src.position.y) + celda - 1) == Color.from_hsv(0, 1, 1), "capas: pixel de ancla legible celda %d" % celda)
	var c2 = Capas.new(hojas(16, todas))
	var eq: Array = ["escudo", "espada", "casco"]
	var nom := func(d: Vector2i) -> Array: return c2.comandos(Vector2.ZERO, d, 0, eq).map(func(x): return x[0])
	var der: Array = nom.call(Vector2i.RIGHT)
	var izq: Array = nom.call(Vector2i.LEFT)
	ok(der.find("escudo") < der.find("tunica") and der.find("espada") > der.find("tunica"), "capas: derecha, escudo detras y espada delante")
	ok(izq.find("escudo") > izq.find("tunica") and izq.find("espada") < izq.find("tunica"), "capas: izquierda, escudo delante y espada detras")
	ok(not "coraza" in der and c2.comandos(Vector2.ZERO, Vector2i.DOWN, 0, []).size() == 5, "capas: equipo solo si se tiene")
	ok(not Capas.new(hojas(16, todas, "", false).replace("arte_16", "arte_vacio")).disponible(), "capas: sin manifiesto, disponible() es false")
	var c3 = Capas.new(hojas(16, todas, "escudo"))
	ok(not c3.disponible() and c3.errores.size() == 1 and "escudo" in c3.errores[0], "capas: hoja de tamano incorrecto rechazada con mensaje")

func t_equipo() -> void:
	var j = g(11)
	ok(C.validar() == [], "equipo: validar() vacío")
	ok(j.d.equipo == {"casco": "", "coraza": "", "escudo": ""} and j.stats().def == 0, "equipo: estado inicial")
	# fabricar recetas nuevas
	j.d.hab = ["recolector", "artesano"]
	j.d.inv = {"madera": 5, "piedra": 2}
	j.construir("mesa", Vector2i(33, 40))
	j.d.inv = {"lingote": 6, "madera": 8, "fibra": 2}
	ok(j.fabricar("casco_hierro").ok and j.fabricar("coraza_hierro").ok and j.fabricar("escudo_madera").ok, "equipo: recetas fabricables")
	ok(j.d.inv.get("casco_hierro", 0) == 1 and j.d.inv.get("coraza_hierro", 0) == 1 and j.d.inv.get("escudo_madera", 0) == 1, "equipo: salidas")
	# equipar / desequipar
	ok(j.equipar("casco_hierro").ok and j.equipar("coraza_hierro").ok and j.equipar("escudo_madera").ok, "equipar 3 ranuras")
	ok(j.stats().def == 9, "def = suma (9)")
	ok(not j.equipar("madera").ok and not j.equipar("casco_hierro").ok, "equipar rechaza no equipable / sin item")
	ok(j.desequipar("casco").ok and j.d.inv.get("casco_hierro", 0) == 1 and j.stats().def == 7, "desequipar devuelve ítem")
	ok(not j.desequipar("casco").ok, "desequipar ranura vacía falla")
	# ranura ocupada con intercambio: se devuelve el anterior
	j.d.inv = {"casco_hierro": 1}
	j.d.equipo.casco = "casco_hierro"
	j.d.inv = {"casco_hierro": 1}
	ok(j.equipar("casco_hierro").ok and j.d.inv.get("casco_hierro", 0) == 1 and j.d.equipo.casco == "casco_hierro", "intercambio en ranura ocupada")
	# inventario lleno: nada cambia
	j.d.inv = {"madera": 50 * 19, "casco_hierro": 1}
	j.d.equipo.casco = ""
	ok(Inv.slots(j.d.inv) == 20, "inventario lleno (20)")
	j.d.equipo.coraza = "coraza_hierro"
	j.d.inv = {"madera": 50 * 18, "coraza_hierro": 1, "casco_hierro": 1}   # 20 pilas
	var antes: String = JSON.stringify([j.d.inv, j.d.equipo])
	ok(j.desequipar("coraza").ok == false and JSON.stringify([j.d.inv, j.d.equipo]) == antes, "desequipar con inventario lleno: rechaza sin perder")
	j.d.inv = {"madera": 50 * 18, "casco_hierro": 1, "escudo_madera": 1}
	j.d.equipo.escudo = "escudo_madera"
	# equipar escudo_madera (pila 1) con el escudo ya puesto: intercambio neutro, cabe
	ok(j.equipar("escudo_madera").ok, "intercambio neutro con inventario lleno")
	# defensa reduce daño, mínimo 1
	var k2 = g(12)
	k2.d.equipo.coraza = "coraza_hierro"       # def 4
	k2.d.pj.hp = 40
	k2.danar_pj(10)
	ok(k2.d.pj.hp == 34, "daño 10 con def 4 = 6")
	k2.danar_pj(2)
	ok(k2.d.pj.hp == 33, "daño mínimo 1")
	# persistencia
	var m = g(13)
	m.d.inv = {"casco_hierro": 1, "escudo_madera": 1}
	m.equipar("casco_hierro"); m.equipar("escudo_madera")
	var ruta := tmp + "/eq.json"
	ok(m.guardar(ruta), "equipo: guardar")
	var d1: int = m.stats().def
	var m2 = J.cargar(ruta)
	var d2: int = m2.stats().def
	ok(m2.d.equipo == m.d.equipo and d2 == d1 and d1 == 5, "equipo: cargar conserva equipo y def")
	m2.guardar(ruta)
	var m3 = J.cargar(ruta)
	ok(m3.stats().def == d1 and m3.stats().def == m3.stats().def, "equipo: def no se acumula al recargar")
	# guardado antiguo sin clave equipo
	var viejo = g(14)
	viejo.d.erase("equipo")
	var rv := tmp + "/viejo.json"
	ok(Guard.guardar(rv, viejo.d), "equipo: guardado sin clave")
	var v2 = J.cargar(rv)
	ok(v2 != null and v2.d.equipo == {"casco": "", "coraza": "", "escudo": ""} and v2.stats().def == 0 and v2.equipar("casco_hierro").ok == false, "equipo: carga sin clave equipo usa valores por defecto")
