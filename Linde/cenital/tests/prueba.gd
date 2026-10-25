extends SceneTree
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Guard = preload("res://scripts/guardado.gd")
const J = preload("res://scripts/juego.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Eq = preload("res://scripts/equipo.gd")
const CV := "eq:vigia:casco::0"
const TV := "eq:vigia:torso::0"
var fallos := 0
var tmp := ""

func ok(cond: bool, nombre: String) -> void:
	print(("PASS " if cond else "FAIL ") + nombre)
	if not cond: fallos += 1

func g(sem: int = 1):
	var j = J.nueva(sem, "Test", [0, 0, 0])
	if j.d.mundo_vivo.has("autonomia"): j.d.mundo_vivo.autonomia.activa = false   # esta suite prueba la campaña; la autonomía es el modo por defecto
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
	t_catalogos(); t_mundo(); t_inventario(); t_recoleccion(); t_fabricacion(); t_construccion()
	t_progresion(); t_flujo(); t_misiones(); t_tesoro(); t_combate(); t_habitantes(); t_persistencia(); t_regeneracion(); t_anim(); t_equipo(); t_equipo2(); t_migracion_v1(); t_multi(); t_red(); t_arte_equipo(); t_ataque_equipo(); t_estados_e02(); t_mundo_arte(); t_actores_arte(); t_sin_arte_procedural(); t_imagen_util()
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
	j.jug().inv = {"pico_piedra": 1}
	var xp0: int = j.jug().xp
	for i in 3: j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == roca, "roca aguanta 3 golpes")
	j.golpear_objeto(c)
	ok(j.mundo.objeto_presente(c) == "" and j.jug().inv.piedra == 2 and j.jug().xp == xp0 + 2, "4º golpe: se rompe, 2 piedra y xp, una sola vez")
	ok(not j.mundo.bloquea(c), "la celda queda libre")
	ok(not j.golpear_objeto(c).ok and j.jug().inv.piedra == 2, "no se puede romper dos veces (sin duplicar)")
	var j2 = g()
	j2.jug().inv = {"pico_piedra": 1}
	var veta := objeto(j2, "veta")
	var cv: Vector2i = j2.mundo.objetos[veta].c
	var j3 = g()
	j3.jug().inv = {"pico_piedra": 1}
	for i in 6:
		j2.golpear_objeto(cv)
		j3.golpear_objeto(cv)
	ok(j2.jug().inv == j3.jug().inv and j2.jug().inv.mena == 2, "botín probabilístico determinista por semilla y objeto")
	var j4 = g()
	j4.jug().hab = ["recolector"]
	j4.jug().inv = {"pico_piedra": 1}
	var r2 := objeto(j4, "roca")
	var cr: Vector2i = j4.mundo.objetos[r2].c
	for i in 3: j4.golpear_objeto(cr)
	ok(j4.mundo.objeto_presente(cr) == "", "habilidad Recolector: un golpe menos")
	var j5 = g()
	j5.jug().inv = {"madera": 1000}
	var bus := objeto(j5, "arbusto")
	var cb: Vector2i = j5.mundo.objetos[bus].c
	var inv5: Dictionary = j5.jug().inv.duplicate()
	ok(not j5.golpear_objeto(cb).ok and j5.mundo.objeto_presente(cb) == bus and j5.jug().inv == inv5, "inventario lleno: el objeto no se rompe ni se pierde nada")

func t_fabricacion() -> void:
	var j = g()
	ok(not j.fabricar("hacha_piedra").ok and j.jug().inv.is_empty(), "sin materiales: falla sin cambios")
	j.jug().inv = {"piedra": 2, "madera": 2, "fibra": 1}
	ok(j.fabricar("hacha_piedra").ok and j.jug().inv == {"hacha_piedra": 1}, "fabricar consume y entrega")
	j.jug().inv = {"mena": 2, "madera": 1}
	ok(not j.fabricar("lingote").ok, "lingote exige habilidad y horno")
	j.jug().hab = ["artesano"]
	ok(not j.fabricar("lingote").ok and j.jug().inv == {"mena": 2, "madera": 1}, "con habilidad pero lejos del horno: falla")
	j.mundo.poner(Vector2i(33, 40), "horno", true)
	ok(j.fabricar("lingote").ok and j.jug().inv == {"lingote": 1}, "junto al horno: fabrica")
	j.jug().inv = {"lingote": 2, "madera": 1}
	j.mundo.poner(Vector2i(31, 40), "mesa", true)
	ok(j.fabricar("espada_hierro").ok and j.stats().dmg == C.DMG_BASE, "espada: tenerla en el inventario no da daño")
	ok(j.equipar("espada_hierro").ok and j.stats().dmg == C.DMG_BASE + 6 and j.jug().equipo.arma == "espada_hierro", "espada: el daño sale del arma equipada en la ranura arma")
	ok(j.desequipar("arma").ok and j.stats().dmg == C.DMG_BASE and j.jug().inv.get("espada_hierro", 0) == 1, "espada: desequipar el arma devuelve la espada al inventario y quita el daño")

func t_construccion() -> void:
	var j = g()
	j.jug().inv = {"madera": 20}
	ok(j.construir("muro", Vector2i(33, 40)).ok and j.mundo.bloquea(Vector2i(33, 40)) and j.jug().inv.madera == 18, "construir: coste y colisión")
	ok(not j.construir("muro", Vector2i(33, 40)).ok and j.jug().inv.madera == 18, "no se construye sobre otra construcción")
	ok(not j.construir("muro", Vector2i(32, 40)).ok, "no se construye sobre el jugador")
	ok(not j.construir("muro", Vector2i(Mundo.PUERTA_C.x, Mundo.PUERTA_C.y)).ok, "no se construye en la puerta")
	var arb: String = objeto(j, "arbol")
	ok(not j.construir("muro", j.mundo.objetos[arb].c).ok, "no se construye sobre un árbol")
	var antes: Dictionary = j.jug().inv.duplicate()
	ok(not j.construir("muro", Vector2i(27, 23)).ok and j.jug().inv == antes and j.mundo.constr_en(Vector2i(27, 23)).is_empty(), "bloquear un lugar esencial se rechaza y revierte")
	ok(not j.construir("muro", Vector2i(30, 19)).ok, "no se encierra la cama de Maren")
	ok(j.construir("muro", Vector2i(31, 40)).ok and j.construir("muro", Vector2i(32, 39)).ok, "muros laterales válidos")
	ok(not j.construir("muro", Vector2i(32, 41)).ok, "no se puede encerrar al propio jugador")
	ok(j.retirar(Vector2i(33, 40)).ok and j.jug().inv.madera == 18 - 4 + 2 and not j.mundo.bloquea(Vector2i(33, 40)), "retirar devuelve el coste")
	ok(not j.retirar(Mundo.CAMA_MAREN).ok, "no se retiran construcciones ajenas")
	j.jug().inv = {"madera": 4}
	ok(j.construir("cofre", Vector2i(33, 40)).ok, "construir cofre")
	j.jug().inv = {"piedra": 5}
	var cid := "c@33,40"
	ok(j.mover_cofre(cid, "piedra", true).ok and j.d.cofres[cid].inv.piedra == 5 and j.jug().inv.is_empty(), "depositar en cofre")
	ok(not j.retirar(Vector2i(33, 40)).ok, "cofre con contenido no se retira (no se pierde nada)")
	ok(j.mover_cofre(cid, "piedra", false).ok and j.retirar(Vector2i(33, 40)).ok and j.jug().inv.piedra == 5 and j.jug().inv.madera == 4, "vaciar y retirar cofre")
	j.jug().inv = {"madera": 4, "fibra": 4}
	j.d.min = 20 * 60
	j.construir("cama", Vector2i(33, 40))
	j.mira = Vector2i.RIGHT
	j.jug().hp = 3
	var r: Dictionary = j.interactuar()
	ok(r.panel == "dormir" and j.d.min == 20 * 60 and j.dia() == 1 and j.jug().hp == j.stats().hp, "dormir en cama propia: cura sin avanzar el reloj")
	ok(j.jug().cama.size() == 2, "cama propia fija el punto de reaparición")

func t_progresion() -> void:
	var j = g()
	ok(not j.aprender("golpe_fuerte").ok, "nivel 1: sin puntos")
	j.jug().xp = 100
	ok(j.nivel() == 3 and j.puntos_libres() == 2, "nivel 3 = 2 puntos")
	ok(not j.aprender("dominio").ok, "requisitos de rama")
	ok(j.aprender("golpe_fuerte").ok and not j.aprender("golpe_fuerte").ok, "aprender una vez")
	var s1: Dictionary = j.stats()
	ok(s1.dmg == C.DMG_BASE + 3, "efecto derivado de la habilidad")
	var ruta := tmp + "/prog.json"
	j.guardar(ruta)
	var j2 = J.cargar(ruta)
	ok(j2.stats() == s1 and j2.jug().hab == ["golpe_fuerte"], "cargar no vuelve a aplicar el bonus")
	ok(j2.stats() == J.cargar(ruta).stats(), "cargas repetidas dan lo mismo")
	ok(not j.aprender("artesano").ok, "sin puntos o requisito, no se aprende")

func t_misiones() -> void:
	var j = g()
	var r: Dictionary = j.hablar("maren")
	ok(r.tipo == "mision" and j.estado_mision("cap1_piedras") == "activa" and r.texto == C.DIALOGOS.cap1_piedras.oferta, "diálogo abre misión con línea de origen")
	j.jug().inv = {"piedra": 5}
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "activa", "5/6 piedras: sigue activa")
	j.jug().inv.piedra = 6
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "cumplida", "6 piedras: cumplida")
	j.jug().inv.piedra = 3
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "activa", "condición actual perdida: vuelve a activa")
	j.jug().inv.piedra = 6
	j.evaluar_misiones()
	var rr: Dictionary = j.hablar("maren")
	ok(rr.tipo == "relacion" and j.estado_mision("cap1_piedras") == "entregada" and j.jug().inv == {"madera": 5} and j.jug().xp == 20, "entrega: consume, premia y sube relación")
	ok(j.jug().relacion.maren == 1, "relación cambia solo con entrega")
	ok(not j.entregar("cap1_piedras").ok and j.jug().xp == 20, "recompensa una sola vez")
	var ruta := tmp + "/mis.json"
	j.guardar(ruta)
	var j2 = J.cargar(ruta)
	j2.evaluar_misiones()
	ok(j2.jug().xp == 20 and j2.jug().inv == {"madera": 5} and not j2.entregar("cap1_piedras").ok, "recargar no repite la recompensa")
	var t: Dictionary = j.hablar("maren")
	ok(t.tipo == "mision" and j.estado_mision("cap1_mesa") == "activa", "siguiente misión tras entregar")
	j.jug().inv = {"madera": 5, "piedra": 2}
	j.construir("mesa", Vector2i(33, 40))
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_mesa") == "cumplida", "construcción en pie cumple")
	j.retirar(Vector2i(33, 40))
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_mesa") == "activa", "mesa retirada: ya no se cumple")
	j.construir("mesa", Vector2i(33, 40))
	j.hablar("maren")
	ok(j.estado_mision("cap1_mesa") == "entregada" and j.jug().inv.get("mena", 0) == 2, "mesa entregada y premiada")
	j.hablar("maren")
	ok(j.estado_mision("cap1_ruinas") == "activa", "misión de ruinas activa")
	j.jug().eventos["visito_ruinas"] = true
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_ruinas") == "activa", "visitar sin derrotar al jefe no basta")

func t_tesoro() -> void:
	var a = g(5)
	var b = g(5)
	b.jug().inv = {"pico_piedra": 1}
	ok(a.d.cofres.tesoro_cantera.inv == b.d.cofres.tesoro_cantera.inv, "tesoro: mismo resultado por semilla")
	var ruta := tmp + "/tes.json"
	a.guardar(ruta)
	ok(J.cargar(ruta).d.cofres.tesoro_cantera.inv == a.d.cofres.tesoro_cantera.inv, "tesoro: cargar no cambia el premio")
	a.jug().inv = {"madera": 1000}
	var antes: Dictionary = a.d.cofres.tesoro_cantera.inv.duplicate()
	ok(not a.abrir_tesoro("tesoro_cantera").ok and a.d.cofres.tesoro_cantera.inv == antes, "inventario lleno: el cofre conserva su contenido")
	a.jug().inv = {}
	ok(a.abrir_tesoro("tesoro_cantera").ok and a.jug().inv.gema >= 1, "abrir entrega el contenido")
	var inv_a: Dictionary = a.jug().inv.duplicate()
	ok(not a.abrir_tesoro("tesoro_cantera").ok and a.jug().inv == inv_a, "no se abre dos veces")
	a.jug().misiones["mundo_tesoro"] = {"estado": "activa"}
	a.evaluar_misiones()
	ok(a.estado_mision("mundo_tesoro") == "cumplida", "misión de mundo por hecho histórico (abrió el cofre)")

func t_combate() -> void:
	var j = g()
	var s: Dictionary = j.combate._nuevo("slime", j.pies + Vector2(0, -30))
	j.combate.enemigos.append(s)
	var hp0: int = j.jug().hp
	var t_aviso := -1.0
	var t := 0.0
	var dano_antes_aviso := false
	while t < 1.4:
		j.combate.paso(0.02)
		t += 0.02
		if s.est == "aviso" and t_aviso < 0.0: t_aviso = t
		if j.jug().hp < hp0 and t_aviso < 0.0: dano_antes_aviso = true
	ok(not dano_antes_aviso and t_aviso >= 0.0, "enemigo avisa antes de golpear")
	ok(j.jug().hp == hp0 - C.ENEMIGOS.slime.dmg, "un ataque = un impacto (invulnerabilidad evita repetir)")
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
	ok(k.jug().inv.get("gelatina", 0) == 1 and k.jug().xp == 8, "drop y xp una sola vez")
	k.combate.enemigos = k.combate.enemigos.filter(func(e): return e.est != "muerto")
	# jefe de capítulo
	var b = g()
	b.pies = Mundo.pies_de_celda(Vector2i(52, 40))
	b.combate._aparecer_si_toca("guardian")
	var boss: Dictionary = b.combate.enemigos[0]
	var hpb: int = b.jug().hp
	var aviso_t := -1.0
	t = 0.0
	while t < 3.0 and b.jug().hp == hpb:
		b.combate.paso(0.02)
		t += 0.02
		if boss.est == "aviso" and aviso_t < 0.0: aviso_t = t
	ok(aviso_t >= 0.0 and t - aviso_t >= C.ATAQUES.embestida.aviso - 0.05 and b.jug().hp == hpb - C.ATAQUES.embestida.dmg, "jefe: señal previa de 0,8 s y luego impacto")
	boss.hp = 40
	b.combate.paso(0.02)
	ok(boss.fase == 1, "jefe cambia de fase al 50%")
	var ataques := {}
	boss.n_atq = 0
	for i in 2: ataques[b.combate._siguiente(boss)] = true; boss.n_atq += 1
	ok(ataques.has("onda") and ataques.has("embestida"), "fase 2 añade un ataque distinto, no solo más vida")
	boss.hp = 1
	b.combate._danar(boss, 5)
	ok(b.estado_mision("cap1_ruinas") == "" and b.d.jefes.guardian.veces == 1 and b.jug().inv.get("gema", 0) == 3, "jefe de capítulo: derrota y recompensa fija")
	var ruta := tmp + "/jefe.json"
	b.guardar(ruta)
	var b2 = J.cargar(ruta)
	var vivo := false
	for e in b2.combate.enemigos: if e.tipo == "guardian": vivo = true
	ok(not vivo and b2.jug().inv.get("gema", 0) == 3 and b2.d.jefes.guardian.veces == 1, "tras cargar: sigue derrotado y sin recompensa repetida")
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
	d.jug().inv = {"madera": 7}
	d.danar_pj(1000)
	ok(d.jug().hp == d.stats().hp / 2 and d.jug().inv == {"madera": 7} and d.pies == Vector2(d.jug().inicio[0], d.jug().inicio[1]), "derrota: sin perder objetos, vuelve al inicio con media vida")

func t_habitantes() -> void:
	var j = g()
	j.d.min = 12 * 60
	var meta := func(c): return c == Vector2i(34, 25)
	var largo0: int = j.mundo.camino(Vector2i(28, 20), meta).size()
	j.jug().inv = {"madera": 40}
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
	k.jug().inv = {"madera": 20}
	for c in [Vector2i(27, 20), Vector2i(29, 20), Vector2i(28, 19)]: k.construir("muro", c)
	ok(not k.construir("muro",Vector2i(28,21)).ok,"construir rechaza encerrar a un habitante")
	k.mundo.poner(Vector2i(28,21),"muro",true,J.LOCAL) # Estado malformado de QA para probar recuperación de navegación.
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
	ok(n.d.npcs.maren.act == "sin_cama" and n.d.npcs.maren.energia > e1 and n.d.npcs.maren.energia - e1 < s.d.npcs.maren.energia - e0, "sin cama duerme al raso: recupera, pero menos que en una cama")

func t_persistencia() -> void:
	var j = g(9)
	j.jug().inv = {"pico_piedra": 1, "madera": 10}
	var roca := objeto(j, "roca")
	var c: Vector2i = j.mundo.objetos[roca].c
	for i in 4: j.golpear_objeto(c)
	j.construir("muro", Vector2i(33, 40))
	j.jug().xp = 120
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
	ok(r != null and r.jug().xp == 120, "principal truncado: recupera del respaldo")
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
	ok(m.get("formato") == Guard.FORMATO and m.jugadores.local.has("hab") and m.jugadores.local.has("recompensas") and m.jugadores.local.has("eventos"), "migración v0 -> v1 -> v2")
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
	ok(j.jug().inv.get("fibra", 0) >= 2 and j.jug().inv.get("madera", 0) >= 6 and j.jug().inv.get("piedra", 0) >= 6, "flujo: materiales básicos a mano")
	ok(j.fabricar("pico_piedra").ok and j.fabricar("hacha_piedra").ok, "flujo: pico y hacha")
	romper(j, "roca", 4)
	ok(j.jug().inv.get("piedra", 0) >= 6, "flujo: piedra suficiente con el pico")
	j.hablar("maren")
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras") == "cumplida", "flujo: misión 1 cumplida")
	j.hablar("maren")
	ok(j.estado_mision("cap1_piedras") == "entregada", "flujo: misión 1 entregada")
	romper(j, "arbol", 3)
	ok(j.jug().inv.get("madera", 0) >= 5 and j.jug().inv.get("piedra", 0) >= 2, "flujo: materiales de la mesa")
	j.hablar("maren")
	ok(j.construir("mesa", Vector2i(33, 40)).ok, "flujo: mesa construida")
	j.hablar("maren")
	ok(j.estado_mision("cap1_mesa") == "entregada", "flujo: misión 2 entregada")
	j.hablar("maren")
	j.pies = Mundo.pies_de_celda(Vector2i(52, 41))
	j.tick(0.6)
	ok(j.jug().eventos.has("visito_ruinas"), "flujo: entrar a la arena registra la visita")
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
	ok(j.estado_mision("cap1_ruinas") == "entregada" and j.jug().inv.get("gema", 0) == 5, "flujo: capítulo 1 completo (3+2 gemas)")
	ok(j.nivel() >= 2, "flujo: el progreso da niveles (xp %d)" % j.jug().xp)
	ok(j.hablar("maren").texto == C.DIALOGOS.final, "flujo: diálogo final")

func t_anim() -> void:
	var A = preload("res://scripts/anim_pj.gd")
	var base := {"mov": false, "t_mov": 0.0, "herr_t": 0.0, "ataque_est": "libre", "ataque_t": 0.0, "inv_t": 0.0}
	var ev := func(o: Dictionary) -> Dictionary:
		var c := base.duplicate()
		c.merge(o, true)
		return A.estado_y_cuadro(c)
	ok(ev.call({}).estado == "reposo", "anim: reposo por defecto")
	ok(ev.call({"mov": true}).estado == "caminar", "anim: caminar")
	ok(ev.call({"mov": true, "herr_t": 0.2}).estado == "herramienta", "anim: herramienta > caminar")
	ok(ev.call({"herr_t": 0.2, "ataque_est": "aviso"}).estado == "ataque", "anim: ataque > herramienta")
	ok(ev.call({"ataque_est": "rec", "inv_t": 0.3}).estado == "dano", "anim: dano > ataque")
	var cs: Array = [0.0, 0.12, 0.24, 0.36, 0.48].map(func(t): return ev.call({"mov": true, "t_mov": t}).cuadro)
	ok(cs == [0, 1, 2, 3, 0], "anim: cuadro de caminar avanza con t_mov")
	var ca: Array = [["aviso", 0.10], ["aviso", 0.04], ["activo", 0.1], ["rec", 0.25]].map(func(e): return ev.call({"ataque_est": e[0], "ataque_t": e[1]}).cuadro)
	ok(ca == [0, 1, 2, 0] and C.ANIM_PJ.ataque.cuadros == 4, "anim: cuadros de ataque 0/1 (aviso), 2 (activo), 0 (rec: vuelve al preparado, ciclo 1-2-3-1)")
	ok(ev.call({"herr_t": 0.29}).cuadro == 0 and ev.call({"herr_t": 0.01}).cuadro == 2, "anim: cuadro de herramienta por progreso")
	var j = g(12)
	var ad: Vector2i = Mundo.celda_de(j.pies)
	ok(j.herr_t == 0.0 and j.anim_pj(false, 0.0).estado == "reposo", "anim: juego en reposo")
	var arb := objeto_de(j.mundo, "arbol")
	j.pies = Mundo.pies_de_celda(j.mundo.objetos[arb].c + Vector2i.DOWN)
	j.mira = Vector2i.UP
	j.accion()
	ok(j.herr_t > 0.0 and j.anim_pj(false, 0.0).estado == "herramienta", "anim: herr_t aparece al golpear un objeto")
	j.tick(0.31)
	ok(j.herr_t == 0.0 and j.anim_pj(false, 0.0).estado == "reposo", "anim: herr_t expira con tick")
	j.combate.inv_t = 0.5
	j.combate.est = "activo"
	ok(j.anim_pj(false, 0.0).estado == "dano" and j.combate.est == "activo", "anim: dano no oculta el ataque para la logica")

# Equipo base (antes casco_hierro/coraza_hierro de 3 ranuras): mismas comprobaciones con piezas de Vigía y 6 ranuras.
func t_equipo() -> void:
	var j = g(11)
	ok(C.validar() == [], "equipo: validar() vacío")
	ok(j.jug().equipo == J.EQUIPO_VACIO and j.jug().equipo.size() == 7 and j.stats().def == 0, "equipo: estado inicial (7 ranuras vacías: set, escudo y arma)")
	# fabricar recetas nuevas
	j.jug().hab = ["recolector", "artesano"]
	j.jug().inv = {"madera": 5, "piedra": 2}
	j.construir("mesa", Vector2i(33, 40))
	j.jug().inv = {"lingote": 6, "madera": 8, "fibra": 2}
	ok(j.fabricar("vigia_casco").ok and j.fabricar("vigia_torso").ok and j.fabricar("escudo_madera").ok, "equipo: recetas fabricables (casco y torso de Vigía, escudo)")
	ok(j.jug().inv == {CV: 1, TV: 1, "escudo_madera": 1}, "equipo: salidas (y materiales consumidos)")
	# equipar / desequipar
	ok(j.equipar(CV).ok and j.equipar(TV).ok and j.equipar("escudo_madera").ok, "equipar 3 ranuras")
	ok(j.stats().def == 9, "def = floor((2 + 4 + 3) * 1,05 de bono de 2 piezas) = 9")
	ok(not j.equipar("madera").ok and not j.equipar(CV).ok, "equipar rechaza no equipable / sin item")
	ok(j.desequipar("casco").ok and j.jug().inv.get(CV, 0) == 1 and j.stats().def == 7, "desequipar devuelve ítem (sin bono: 4 + 3)")
	ok(not j.desequipar("casco").ok, "desequipar ranura vacía falla")
	# ranura ocupada con intercambio: se devuelve el anterior
	j.jug().equipo.casco = CV
	j.jug().inv = {CV: 1}
	ok(j.equipar(CV).ok and j.jug().inv.get(CV, 0) == 1 and j.jug().equipo.casco == CV, "intercambio en ranura ocupada")
	# inventario lleno: nada cambia
	j.jug().inv = {"madera": 50 * 19, CV: 1}
	j.jug().equipo.casco = ""
	ok(Inv.slots(j.jug().inv) == 20, "inventario lleno (20)")
	j.jug().equipo.torso = TV
	j.jug().inv = {"madera": 50 * 18, TV: 1, CV: 1}   # 20 pilas
	var antes: String = JSON.stringify([j.jug().inv, j.jug().equipo])
	ok(j.desequipar("torso").ok == false and JSON.stringify([j.jug().inv, j.jug().equipo]) == antes, "desequipar con inventario lleno: rechaza sin perder")
	j.jug().inv = {"madera": 50 * 18, CV: 1, "escudo_madera": 1}
	j.jug().equipo.escudo = "escudo_madera"
	ok(j.equipar("escudo_madera").ok, "intercambio neutro con inventario lleno")
	# defensa proporcional (3.7), mínimo 1
	var k2 = g(12)
	k2.jug().equipo.torso = TV       # def 4
	k2.jug().hp = 40
	k2.danar_pj(10)
	ok(k2.jug().hp == 32, "daño 10 con def 4 = round(10*20/24) = 8")
	k2.danar_pj(1)
	ok(k2.jug().hp == 31, "daño mínimo 1")
	# persistencia
	var m = g(13)
	m.jug().inv = {CV: 1, "escudo_madera": 1}
	m.equipar(CV); m.equipar("escudo_madera")
	var ruta := tmp + "/eq.json"
	ok(m.guardar(ruta), "equipo: guardar")
	var d1: int = m.stats().def
	var m2 = J.cargar(ruta)
	var d2: int = m2.stats().def
	ok(m2.jug().equipo == m.jug().equipo and d2 == d1 and d1 == 5, "equipo: cargar conserva equipo y def")
	m2.guardar(ruta)
	var m3 = J.cargar(ruta)
	ok(m3.stats().def == d1 and m3.stats().def == m3.stats().def, "equipo: def no se acumula al recargar")
	# guardado antiguo sin clave equipo
	var viejo = g(14)
	viejo.jug().erase("equipo")
	var rv := tmp + "/viejo.json"
	ok(Guard.guardar(rv, viejo.d), "equipo: guardado sin clave")
	var v2 = J.cargar(rv)
	ok(v2 != null and v2.jug().equipo == J.EQUIPO_VACIO and v2.stats().def == 0 and v2.equipar(CV).ok == false, "equipo: carga sin clave equipo usa valores por defecto")

# Cuenta de objetos de un jugador: inventario + ranuras ocupadas + pendientes.
func total_obj(pj: Dictionary) -> int:
	var n := 0
	for k in pj.inv: n += int(pj.inv[k])
	for k in pj.get("pendientes", {}): n += int(pj.pendientes[k])
	for r in pj.equipo: if str(pj.equipo[r]) != "": n += 1
	return n

func set_de(fam: String, variante: String = "", nivel: int = 0) -> Dictionary:
	var e: Dictionary = J.EQUIPO_VACIO.duplicate()
	for r in ["casco", "torso", "guantes", "botas", "pantalones"]: e[r] = Eq.construir(fam, r, variante, nivel)
	return e

# Criterios de aceptación de Linde/documentos/sistema-de-equipo.md (13), uno o más ok() por criterio.
func t_equipo2() -> void:
	var dd: Dictionary = Eq.datos()
	var orden: Array = dd.orden.duplicate()
	orden.sort()
	# 1. 5 piezas por familia; validar() rechaza 4, 6 o una repetida
	var cinco := true
	for f in dd.familias:
		var pz: Array = dd.familias[f].piezas.duplicate()
		pz.sort()
		if pz != orden: cinco = false
	ok(cinco and dd.familias.size() == 3 and Eq.validar_datos(dd).is_empty(), "eq1: cada familia tiene exactamente las 5 ranuras de set")
	var malas := [["casco", "torso", "guantes", "botas"], ["casco", "torso", "guantes", "botas", "pantalones", "escudo"], ["casco", "casco", "guantes", "botas", "pantalones"]]
	var rech := 0
	for pz in malas:
		var x: Dictionary = dd.duplicate(true)
		x.familias.vigia.piezas = pz
		if Eq.validar_datos(x).any(func(e): return "vigia" in e and "5 piezas" in e): rech += 1
	ok(rech == 3, "eq1: validar() rechaza una familia con 4, con 6 o con una ranura repetida")
	# 2. ninguna variante domina; validar() rechaza una dominante
	var ms: Array = [{"id": "", "def": 1.0, "hp": 1.0, "vel": 0.0}]
	for v in dd.variantes: ms.append({"id": v, "def": float(dd.variantes[v].mult.def), "hp": float(dd.variantes[v].mult.hp), "vel": float(dd.variantes[v].vel_pct_delta)})
	var dom := 0
	for a in ms:
		for b in ms: if a.id != b.id and Eq._domina(a, b): dom += 1
	ok(ms.size() == 4 and dom == 0, "eq2: ninguno de los 6 pares {sin piedra, Divino, Brillante, Oscuro} domina")
	var xv: Dictionary = dd.duplicate(true)
	xv.variantes["suprema"] = {"id": "suprema", "nombre": "Suprema", "piedra": "piedra_alma", "paleta_delta": "delta_divino", "mult": {"def": 1.20, "hp": 1.15}, "vel_pct_delta": 0.01}
	var ev: Array = Eq.validar_datos(xv)
	ok(ev.any(func(e): return "suprema domina" in e), "eq2: validar() rechaza una variante dominante")
	# 3. determinismo de stats(), también tras guardar y cargar
	var j = g(41)
	j.jug().equipo = {"casco": "eq:vigia:casco:oscuro:3", "torso": "eq:zarzal:torso:divino:1", "guantes": "eq:albor:guantes::5",
		"botas": "eq:vigia:botas:brillante:0", "pantalones": "eq:zarzal:pantalones::2", "escudo": "escudo_madera"}
	j.jug().hab = ["vitalidad", "pies_ligeros"]
	var s1: Dictionary = j.stats()
	var ruta := tmp + "/eq2.json"
	j.guardar(ruta)
	var j2 = J.cargar(ruta)
	ok(s1 == j.stats() and s1 == j2.stats() and j2.stats() == J.cargar(ruta).stats(), "eq3: stats() idénticos en llamadas seguidas y tras guardar/cargar")
	# 4. mejora: +0 -> +5 gastando 1, 1, 2, 3, 4; +5 y joyas insuficientes se rechazan sin cambios
	var m = g(42)
	m.jug().inv = {CV: 1, "chispa": 11}
	var k := CV
	var costes: Array = []
	var un_nivel := true
	for i in 5:
		var ch: int = m.jug().inv.get("chispa", 0)
		var r: Dictionary = m.mejorar(k)
		var nk: String = Eq.construir("vigia", "casco", "", i + 1)
		if not r.ok or m.jug().inv.get(nk, 0) != 1 or m.jug().inv.has(k): un_nivel = false
		costes.append(ch - int(m.jug().inv.get("chispa", 0)))
		k = nk
	ok(un_nivel and costes == [1, 1, 2, 3, 4] and not m.jug().inv.has("chispa") and m.jug().inv == {"eq:vigia:casco::5": 1}, "eq4: de +0 a +5 con 11 joyas: 1, 1, 2, 3 y 4, un nivel por intento")
	m.jug().inv["chispa"] = 5
	var a5: Dictionary = m.jug().inv.duplicate()
	ok(not m.mejorar("eq:vigia:casco::5").ok and m.jug().inv == a5, "eq4: en +5 se rechaza sin gastar la joya")
	m.jug().inv = {"eq:vigia:torso:oscuro:2": 1, "chispa": 1}
	var a2: Dictionary = m.jug().inv.duplicate()
	ok(not m.mejorar("eq:vigia:torso:oscuro:2").ok and m.jug().inv == a2, "eq4: joyas insuficientes: rechazo sin cambios")
	m.jug().inv = {"chispa": 2}
	m.jug().equipo.torso = "eq:vigia:torso:oscuro:2"
	ok(m.mejorar("eq:vigia:torso:oscuro:2").ok and m.jug().equipo.torso == "eq:vigia:torso:oscuro:3" and m.jug().inv.is_empty(), "eq4: también mejora la pieza equipada")
	# cambiar de piedra conserva el nivel y consume la piedra; la anterior se pierde (5.4)
	m.jug().inv = {"piedra_alma": 1}
	ok(m.engarzar("eq:vigia:torso:oscuro:3", "divino").ok and m.jug().equipo.torso == "eq:vigia:torso:divino:3" and m.jug().inv.is_empty(), "piedra: Oscuro +3 -> Divino +3, consume la Piedra de Alma y no devuelve la de Bendición")
	ok(not m.engarzar("eq:vigia:torso:divino:3", "oscuro").ok and m.jug().equipo.torso == "eq:vigia:torso:divino:3", "piedra: sin la piedra se rechaza sin cambios")
	m.jug().inv = {"piedra_alma": 1}
	ok(not m.engarzar("eq:vigia:torso:divino:3", "divino").ok and m.jug().inv == {"piedra_alma": 1}, "piedra: la misma variante se rechaza sin gastar")
	# 5. equipar/desequipar atómicos; cambiar la pieza puesta no pierde ni duplica
	var e5 = g(43)
	e5.jug().equipo.casco = "eq:zarzal:casco::0"
	e5.jug().inv = {"madera": 50 * 19, "eq:albor:torso::0": 1}
	var ant5: String = JSON.stringify([e5.jug().inv, e5.jug().equipo])
	ok(not e5.desequipar("casco").ok and JSON.stringify([e5.jug().inv, e5.jug().equipo]) == ant5, "eq5: con el inventario lleno, desequipar se rechaza y deja todo igual")
	e5.jug().inv = {"madera": 50 * 19, CV: 1}
	var t5 := total_obj(e5.jug())
	ok(e5.equipar(CV).ok and e5.jug().equipo.casco == CV and e5.jug().inv.get("eq:zarzal:casco::0", 0) == 1 and not e5.jug().inv.has(CV) and total_obj(e5.jug()) == t5, "eq5: cambiar la pieza puesta por una del inventario no pierde ni duplica")
	# 6. bono único y determinista
	var b = g(44)
	var eq6: Dictionary = set_de("vigia")
	eq6.botas = "eq:zarzal:botas::0"
	eq6.pantalones = "eq:zarzal:pantalones:oscuro:4"
	var bs: Dictionary = Eq.bono_set(eq6)
	ok(bs.familia == "vigia" and bs.piezas == 3 and is_equal_approx(bs.def_pct, 0.05) and is_equal_approx(bs.hp_pct, 0.05) and bs.vel_pct == 0.0, "eq6: 3 Vigía + 2 Zarzal: solo el bono de Vigía (2 y 3 piezas)")
	var em := {"casco": "eq:zarzal:casco::0", "torso": "eq:vigia:torso::0", "guantes": "eq:vigia:guantes::0", "botas": "eq:zarzal:botas::0", "pantalones": ""}
	var em2 := {"casco": "eq:vigia:casco::0", "torso": "", "guantes": "eq:vigia:guantes::0", "botas": "eq:zarzal:botas::0", "pantalones": "eq:zarzal:pantalones::0"}
	var em3 := {"casco": "eq:albor:casco::0", "torso": "eq:albor:torso::0", "guantes": "eq:vigia:guantes::0", "botas": "eq:vigia:botas::0", "pantalones": "eq:zarzal:pantalones::0"}
	ok(Eq.bono_set(em).familia == "vigia" and Eq.bono_set(em2).familia == "vigia" and Eq.bono_set(em3).familia == "albor"
		and Eq.bono_set({"casco": CV, "torso": "eq:zarzal:torso::0"}).familia == "", "eq6: empate 2+2 gana la del torso, si no la del casco; 1+1 sin bono")
	var pzs: Array = eq6.values().filter(func(x): return x != "")
	var perms: Array = [[]]
	for i in pzs.size():
		var nuevas: Array = []
		for pp in perms:
			for x in pzs: if not x in pp: nuevas.append(pp + [x])
		perms = nuevas
	var mismas := true
	var ref = null
	for pp in perms:
		b.jug().equipo = J.EQUIPO_VACIO.duplicate()
		b.jug().inv = {}
		for x in pp: b.jug().inv[x] = 1
		for x in pp: b.equipar(x)
		var r6 := [b.stats(), b.bono_set()]
		if ref == null: ref = r6
		elif r6 != ref: mismas = false
	ok(perms.size() == 120 and mismas and ref[1].familia == "vigia", "eq6: mismo resultado en las 120 permutaciones del orden de equipar")
	# 7. límites
	var lim := true
	for f in dd.familias:
		var bf: Dictionary = Eq.bono_set(set_de(f))
		if bf.def_pct > 0.12 + 1e-9 or bf.hp_pct > 0.10 + 1e-9: lim = false
	ok(lim, "eq7: bono acumulado de cada familia <= 12 % def y <= 10 % vida")
	var z = g(45)
	z.jug().equipo = set_de("zarzal", "brillante")
	z.jug().hab = ["pies_ligeros", "explorador"]
	ok(is_equal_approx(z.stats().vel, 1.30), "eq7: Zarzal Brillante completo + pies_ligeros + explorador = VEL 1,30 (tope)")
	var vok := true
	for f in dd.familias:
		for v in [""] + dd.variantes.keys():
			for hb in [[], ["pies_ligeros"], ["pies_ligeros", "explorador"]]:
				for niv in [0, 5]:
					z.jug().equipo = set_de(f, v, niv)
					z.jug().hab = hb
					var vv: float = z.stats().vel
					if vv < 0.70 or vv > 1.30: vok = false
	var orig: Dictionary = Eq._d
	var exag: Dictionary = orig.duplicate(true)
	exag.familias.vigia.bono_set = [{"piezas": 2, "efecto": {"def_pct": 0.40, "hp_pct": 0.40, "vel_pct": -0.90}}]
	Eq._d = exag
	var fx: Dictionary = Eq.finales(set_de("vigia"), 0, 0.0, C.HP_BASE)
	Eq._d = orig
	ok(vok and fx.def == 12 and fx.hp == 68 and fx.vel == 0.70, "eq7: VEL siempre en [0,70, 1,30]; un bono de +40 % se recorta a +25 % en DEF y HP")
	# 8. migración 2 -> 3 (y 1 -> 2 -> 3)
	var p := Mundo.pies_de_celda(Vector2i(32, 40))
	var base2: Dictionary = g(46).d.duplicate(true)
	base2.formato = 2
	var pj2: Dictionary = base2.jugadores.local
	pj2.equipo = {"casco": "casco_hierro", "coraza": "coraza_hierro", "escudo": "escudo_madera"}
	pj2.inv = {"casco_hierro": 2, "coraza_hierro": 1, "escudo_madera": 1, "madera": 3}
	var tot2 := total_obj(pj2)
	var r2 := tmp + "/v2.json"
	for f in [r2, r2 + ".bak"]: if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
	ok(Guard.guardar(r2, base2), "eq8: se escribe un guardado de formato 2")
	var j8 = J.cargar(r2)
	var q: Dictionary = j8.jug()
	ok(j8.d.formato == 3 and total_obj(q) == tot2 and q.equipo == {"casco": CV, "torso": TV, "guantes": "", "botas": "", "pantalones": "", "escudo": "escudo_madera", "arma": ""}
		and q.inv == {CV: 2, TV: 1, "escudo_madera": 1, "madera": 3}, "eq8: 2 -> 3: mismo total, coraza -> torso, ranuras nuevas vacías (incluida el arma)")
	ok(j8.guardar(r2) and FileAccess.file_exists(r2 + ".bak") and int(JSON.parse_string(FileAccess.get_file_as_string(r2 + ".bak")).formato) == 2, "eq8: el .bak conserva la partida previa a migrar (formato 2)")
	var v1 := {"formato": 1, "semilla": 3, "min": 600, "pj": {"nombre": "Vieja", "look": [0, 0, 0], "origen": "viajero", "pos": [p.x, p.y], "hp": 20, "cama": [], "inicio": [p.x, p.y]},
		"inv": {"casco_hierro": 1, "coraza_hierro": 2}, "equipo": {"casco": "casco_hierro", "coraza": "coraza_hierro", "escudo": "escudo_madera"},
		"hab": [], "xp": 0, "misiones": {}, "eventos": {}, "recompensas": [], "pendientes": {},
		"cofres": {"tesoro_cantera": {"inv": {}, "abierto": true}}, "mundo": {"rotos": {}, "golpes": {}, "constr": {}}, "jefes": {}, "npcs": {}}
	var r1 := tmp + "/v1b.json"
	Guard.guardar(r1, v1)
	var j1 = J.cargar(r1)
	ok(j1 != null and j1.d.formato == 3 and total_obj(j1.jug()) == 6 and j1.jug().equipo.torso == TV and j1.jug().inv == {CV: 1, TV: 2} and j1.jug().equipo.pantalones == "", "eq8: formato 1 recorre 1 -> 2 -> 3 sin perder objetos")
	# 9. intercambio atómico
	var t = g(47)
	t.unir("b", "Bea", [0, 0, 0])
	t.jug().inv = {CV: 1, "madera": 3}
	t.jug("b").inv = {"chispa": 3, "madera": 50 * 20}
	var ia: Dictionary = t.jug().inv.duplicate()
	var ib: Dictionary = t.jug("b").inv.duplicate()
	ok(not t.intercambiar("local", "b", {CV: 1}, {"chispa": 3}).ok and t.jug().inv == ia and t.jug("b").inv == ib, "eq9: sin cabida en un lado, ninguno cambia")
	ok(not t.intercambiar("local", "b", {CV: 2}, {"chispa": 1}).ok and t.jug().inv == ia and t.jug("b").inv == ib, "eq9: sin los objetos que se dan, ninguno cambia")
	t.jug("b").inv = {"chispa": 3}
	var tt: int = total_obj(t.jug()) + total_obj(t.jug("b"))
	ok(t.intercambiar("local", "b", {CV: 1}, {"chispa": 3}).ok and t.jug().inv == {"madera": 3, "chispa": 3} and t.jug("b").inv == {CV: 1}
		and total_obj(t.jug()) + total_obj(t.jug("b")) == tt, "eq9: con cabida, ambos cambian y el total se conserva")
	# 10. defensa proporcional
	var dok := true
	for n in range(1, 51):
		var prev := 1 << 30
		for df in range(0, 61):
			var x := Eq.dano(n, df)
			if x < 1 or x > prev or (df == 0 and x != n) or x != maxi(1, roundi(n * 20.0 / (20.0 + df))): dok = false
			prev = x
	ok(dok and Eq.dano(4, 13) == 2 and Eq.dano(12, 13) == 7, "eq10: max(1, round(n*20/(20+DEF))) nunca 0, = n con DEF 0, no crece con DEF (slime 2, jefe 7 con DEF 13)")
	# 11. claves inválidas desde un guardado
	var malas11 := ["eq:nada:casco::0", "eq:vigia:escudo::0", "eq:vigia:casco:rojo:0", "eq:vigia:casco::6", "eq:vigia:casco",
		"eq:vigia:casco::0:x", "eq:vigia:casco::02", "eq:vigia:casco::-1", "eq::::", "eq:VIGIA:casco::0"]
	var c11 = g(48)
	c11.jug().inv = {"madera": 2}
	for x in malas11: c11.jug().inv[x] = 1
	c11.jug().equipo.casco = "eq:vigia:casco::6"   # inválida también en una ranura
	c11.jug().inv.erase("eq:vigia:casco::6")
	var t11 := total_obj(c11.jug())
	var r11 := tmp + "/malas.json"
	Guard.guardar(r11, c11.d)
	var l11 = J.cargar(r11)
	var q11: Dictionary = l11.jug()
	var desc := true
	for x in malas11:
		if Eq.info(x).n != Eq.DESCONOCIDA or not Eq.leer(x).is_empty() or l11.equipar(x).ok: desc = false
	var todas := true
	for x in malas11: if q11.inv.get(x, 0) + q11.pendientes.get(x, 0) != 1: todas = false
	ok(malas11.size() == 10 and desc and todas and total_obj(q11) == t11 and q11.equipo.casco == "", "eq11: 10 claves malformadas quedan como «Pieza desconocida», no equipables, sin perderse ni duplicarse")
	ok(Inv.slots(q11.inv) > 0 and l11.stats().def == 0, "eq11: claves desconocidas no rompen inventario ni estadísticas")
	# 12. cifras de referencia
	var r12 = g(49)
	r12.jug().equipo = set_de("vigia", "oscuro")
	var s12: Dictionary = r12.stats()
	var pmin := INF
	var pmax := 0.0
	for f in dd.familias:
		pmin = minf(pmin, float(dd.familias[f].potencia))
		pmax = maxf(pmax, float(dd.familias[f].potencia))
	ok(s12.def == 13 and s12.hp == 57 and is_equal_approx(s12.vel, 0.97) and pmax / pmin <= 1.20 + 1e-9, "eq12: Vigía Oscuro completa +0: DEF 13, HP 57, VEL 0,97; potencia max/min <= 1,20")
	var t33 := [["vigia", 0, 10.0, 15.0, 0.0], ["vigia", 5, 15.0, 22.5, 0.0], ["zarzal", 0, 7.7, 19.8, 0.05], ["zarzal", 5, 11.55, 29.7, 0.05], ["albor", 0, 16.8, 18.0, -0.075], ["albor", 5, 25.2, 27.0, -0.075]]
	var t33ok := true
	for row in t33:
		var se: Dictionary = Eq.stats_de(set_de(row[0], "", row[1]))
		var vb: float = se.vel_eq - se.bono.vel_pct
		if not (is_equal_approx(se.def_eq, row[2]) and is_equal_approx(se.hp_eq, row[3]) and is_equal_approx(vb, row[4])): t33ok = false
	ok(t33ok, "cifras de la tabla 3.3 (def_eq, hp_eq, vel_eq sin bono)")
	ok(Eq.info("eq:vigia:casco:divino:2").n == "Casco de Vigía Divino +2" and Eq.info(CV).n == "Casco de Vigía" and Eq.info("eq:vigia:casco:oscuro:0").n == "Casco de Vigía Oscuro"
		and Eq.info(CV).pila == 1 and Eq.leer("eq:vigia:casco:divino:2") == {"familia": "vigia", "ranura": "casco", "variante": "divino", "nivel": 2}, "nombres y lectura de claves")
	# obtención: recetas de Vigía, farmeo de Zarzal y jefe Gran Ciervo
	var o = g(50)
	o.jug().inv = {"madera": 5, "piedra": 2}
	o.construir("mesa", Vector2i(33, 40))
	o.jug().inv = {"lingote": 11, "madera": 2, "fibra": 4}
	ok(not o.fabricar("vigia_guantes").ok and o.jug().inv == {"lingote": 11, "madera": 2, "fibra": 4}, "Vigía: sin artesano no se fabrica")
	o.jug().hab = ["artesano"]
	var fab := true
	for r in ["casco", "torso", "guantes", "botas", "pantalones"]: if not o.fabricar("vigia_" + r).ok: fab = false
	ok(fab and o.jug().inv.size() == 5 and o.jug().inv.has("eq:vigia:pantalones::0"), "Vigía: las 5 piezas con sus recetas (mesa + artesano) consumen exactamente los materiales")
	var fz = g(51)
	var fz2 = g(51)
	fz.unir("b", "Bea", [0, 0, 0])
	var maxsin := 0
	var caidas := 0
	var seq_a: Array = []
	var seq_b: Array = []
	for i in 400:
		var n0 := total_obj(fz.jug())
		fz.caida_equipo("slime")
		fz2.caida_equipo("slime")
		fz.caida_equipo("slime", "b")
		if total_obj(fz.jug()) > n0: caidas += 1
		maxsin = maxi(maxsin, int(fz.jug().botin_eq.zarzal.sin))
		seq_a.append(total_obj(fz.jug()))
		seq_b.append(total_obj(fz.jug("b")))
	var solo_zarzal: bool = fz.jug().inv.keys().all(func(x): return Eq.leer(x).familia == "zarzal" and Eq.leer(x).nivel == 0)
	ok(maxsin <= 15 and caidas >= 400 / 16 and caidas <= 400 * 0.12 and solo_zarzal, "Zarzal: ~6 % por derrota con garantía (nunca más de 15 fallos seguidos), piezas sueltas +0")
	ok(fz.jug().inv == fz2.jug().inv and fz.jug().botin_eq == fz2.jug().botin_eq and seq_a != seq_b, "Zarzal: flujo determinista por semilla y propio de cada jugador")
	var cv = g(52)
	var vistas := {}
	for i in 5:
		cv.jefe_derrotado("ciervo")
		for x in cv.jug().inv: if Eq.es_pieza(x): vistas[Eq.leer(x).ranura] = true
	var n_albor := 0
	for x in cv.jug().inv: if Eq.es_pieza(x): n_albor += int(cv.jug().inv[x])
	cv.jefe_derrotado("ciervo")
	var n6 := 0
	for x in cv.jug().inv: if Eq.es_pieza(x): n6 += int(cv.jug().inv[x])
	ok(vistas.size() == 5 and n_albor == 5 and n6 == 6, "Gran Ciervo: una pieza de Albor que falta por derrota (5 distintas en 5); con el set completo, una más")
	ok(not Eq.caidas_objeto("arbusto").is_empty() and not Eq.caidas_objeto("arbol").is_empty() and not Eq.caidas_objeto("veta").is_empty() and Eq.recetas().has("chispa"), "piedras y Chispa tienen origen (alcanzables)")
	var vis: Array = Eq.visible(set_de("albor", "oscuro"))
	ok(vis.size() == 5 and vis[0].arquetipo == "pesada" and vis[0].paleta.has("principal") and vis[0].delta.has("brillo"), "capas: el equipo visible lleva ranura, arquetipo y paleta/variante como datos")

# Guardado sintético de formato 1 (un jugador en la raíz) -> formato 2 con el jugador en jugadores["local"].
func t_migracion_v1() -> void:
	var p := Mundo.pies_de_celda(Vector2i(32, 40))
	var v1 := {"formato": 1, "contenido": 1, "gen": 1, "semilla": 3,
		"pj": {"nombre": "Vieja", "look": [1, 2, 0], "origen": "viajero", "pos": [p.x, p.y], "hp": 17, "cama": [], "inicio": [p.x, p.y]},
		"inv": {"madera": 7}, "equipo": {"casco": "casco_hierro", "coraza": "", "escudo": ""}, "hab": ["vitalidad"], "xp": 120, "min": 600,
		"misiones": {"cap1_piedras": {"estado": "entregada"}}, "eventos": {"hablo_maren": 2}, "recompensas": ["mision:cap1_piedras"],
		"cofres": {"tesoro_cantera": {"inv": {"gema": 1}, "abierto": false}},
		"mundo": {"rotos": {}, "golpes": {}, "constr": {"30,18": {"t": "cama", "propia": false}, "33,40": {"t": "muro", "propia": true}}},
		"jefes": {}, "npcs": {"maren": {"pos": [456.0, 332.0], "energia": 80.0, "act": "taller", "relacion": 1}}, "pendientes": {"gema": 2}}
	var ruta := tmp + "/v1.json"
	ok(Guard.guardar(ruta, v1), "migración v1: se escribe un guardado de formato 1")
	var j = J.cargar(ruta)
	ok(j != null and j.d.formato == Guard.FORMATO and j.d.jugadores.keys() == ["local"], "migración v1: carga como formato actual (3) con jugadores[local]")
	var pj: Dictionary = j.jug()
	ok(pj.nombre == "Vieja" and pj.look == [1, 2, 0] and pj.hp == 17 and pj.inv == {"madera": 7} and pj.xp == 120 and pj.hab == ["vitalidad"]
		and pj.equipo.casco == CV and pj.misiones.cap1_piedras.estado == "entregada" and pj.eventos.hablo_maren == 2
		and pj.recompensas == ["mision:cap1_piedras"] and pj.pendientes == {"gema": 2}, "migración v1: todo lo del jugador pasa a jugadores[local]")
	var raiz := true
	for k in ["pj", "inv", "equipo", "hab", "xp", "misiones", "eventos", "recompensas", "pendientes"]: if j.d.has(k): raiz = false
	ok(raiz and j.d.min == 600 and j.d.semilla == 3 and j.d.cofres.tesoro_cantera.inv == {"gema": 1}, "migración v1: la raíz solo guarda lo compartido")
	ok(pj.relacion == {"maren": 1} and not j.d.npcs.maren.has("relacion"), "migración v1: la relación con Maren pasa al jugador")
	ok(j.pies == p and j.stats().def == 2 and j.stats().hp == C.HP_BASE + 20 + 3, "migración v1: posición y estadísticas derivadas (casco de Vigía: def 2, vida 3)")
	ok(j.estado_mision("cap1_mesa") == "" and j.mision_disponible("cap1_mesa"), "migración v1: misiones siguen encadenando")
	ok(not j.retirar(Mundo.CAMA_MAREN).ok and j.retirar(Vector2i(33, 40)).ok and j.jug().inv.madera == 9, "migración v1: construcción propia pasa a ser del jugador local")
	ok(j.guardar(ruta) and JSON.stringify(norm(j.d), "", true) == JSON.stringify(J.cargar(ruta).d, "", true), "migración v1: se vuelve a guardar en formato 3 sin pérdidas")

func t_multi() -> void:
	var j = g(21)
	ok(j.unir("b", "Bea", [1, 1, 1]).ok and not j.unir("b", "Otra", [0, 0, 0]).ok and j.jug("b").nombre == "Bea", "multi: unir un segundo jugador (id único)")
	j.rt.b.pies = Mundo.pies_de_celda(Vector2i(32, 38))
	j.jug().inv = {"madera": 3}
	j.jug("b").inv = {"piedra": 4}
	ok(j.jug().inv == {"madera": 3} and j.jug("b").inv == {"piedra": 4}, "multi: inventarios independientes")
	# recolectar
	var roca := objeto(j, "roca")
	var c: Vector2i = j.mundo.objetos[roca].c
	j.jug("b").inv = {"pico_piedra": 1}
	for i in 4: j.golpear_objeto(c, "b")
	ok(j.mundo.objeto_presente(c) == "" and j.jug("b").inv.piedra == 2 and j.jug("b").xp == 2 and j.jug().inv == {"madera": 3} and j.jug().xp == 0, "multi: recolectar da botín y xp solo a quien rompe")
	ok(not j.golpear_objeto(c).ok and j.jug().inv == {"madera": 3}, "multi: lo roto por uno está roto para el otro (mundo compartido)")
	# construir
	j.jug().inv = {"madera": 2}
	j.jug("b").inv = {"madera": 5, "piedra": 2}
	ok(j.construir("muro", Vector2i(33, 40)).ok and j.jug().inv.is_empty() and j.jug("b").inv == {"madera": 5, "piedra": 2}, "multi: construir paga del que construye")
	ok(j.construir("mesa", Vector2i(31, 38), "b").ok and j.jug("b").inv.is_empty(), "multi: el segundo jugador construye")
	ok(j.mundo.bloquea(Vector2i(33, 40)) and j.mundo.constr_en(Vector2i(31, 38)).t == "mesa" and j.d.mundo.constr.size() == 4, "multi: el mundo compartido refleja las construcciones de ambos")
	ok(not j.retirar(Vector2i(33, 40), "b").ok and not j.retirar(Vector2i(31, 38)).ok, "multi: solo el dueño retira")
	ok(j.contar_constr("mesa", "b") == 1 and j.contar_constr("mesa") == 0 and j.contar_constr("muro") == 1, "multi: las construcciones cuentan para su dueño")
	# fabricar (estación de otro jugador) y habilidades
	j.jug().hab = ["artesano"]
	j.jug().inv = {"lingote": 2, "madera": 1}
	j.jug("b").inv = {"lingote": 2, "madera": 1}
	ok(j.fabricar("espada_hierro").ok and j.jug().inv == {"espada_hierro": 1}, "multi: fabricar con la mesa de otro jugador")
	ok(not j.fabricar("espada_hierro", "b").ok and j.jug("b").inv == {"lingote": 2, "madera": 1}, "multi: la habilidad de uno no habilita al otro")
	ok(j.equipar("espada_hierro").ok and j.stats().dmg == C.DMG_BASE + 6 and j.stats("b").dmg == C.DMG_BASE, "multi: estadísticas por jugador (el arma equipada de uno no afecta al otro)")
	j.jug("b").xp = 100
	ok(j.aprender("golpe_fuerte", "b").ok and not j.aprender("golpe_fuerte").ok and j.puntos_libres("b") == 1 and not j.jug().hab.has("golpe_fuerte"), "multi: habilidades y puntos independientes")
	# misiones y relación
	var r: Dictionary = j.hablar("maren", "b")
	ok(r.tipo == "mision" and j.estado_mision("cap1_piedras", "b") == "activa" and j.estado_mision("cap1_piedras") == "", "multi: la misión la recibe solo quien habla")
	j.jug("b").inv = {"piedra": 6}
	j.jug().inv = {"piedra": 6}
	j.evaluar_misiones()
	ok(j.estado_mision("cap1_piedras", "b") == "cumplida" and j.estado_mision("cap1_piedras") == "", "multi: el progreso se mide con el inventario de cada uno")
	ok(j.hablar("maren", "b").tipo == "relacion" and j.jug("b").relacion.maren == 1 and j.jug().relacion.is_empty() and j.jug().inv == {"piedra": 6}, "multi: entrega y relación por jugador")
	ok(j.hablar("maren").tipo == "mision" and j.estado_mision("cap1_piedras") == "cumplida" and j.jug().eventos.hablo_maren == 1 and j.jug("b").eventos.hablo_maren == 2, "multi: el otro empieza su propia cadena")
	# combate: el enemigo elige al más cercano
	j.combate.enemigos.clear()
	var hpa: int = j.jug().hp
	var hpb: int = j.jug("b").hp
	var s: Dictionary = j.combate._nuevo("slime", j.pies_de("b") + Vector2(0, -30))
	j.combate.enemigos.append(s)
	for i in 70: j.combate.paso(0.02)
	ok(s.obj == "b" and j.jug("b").hp == hpb - C.ENEMIGOS.slime.dmg and j.jug().hp == hpa, "multi: el enemigo ataca al jugador más cercano")
	j.combate.atacar(Vector2i.UP, "b")
	ok(j.combate.ataque("b").est == "aviso" and j.combate.est == "libre", "multi: ciclos de ataque independientes")
	# derrota de uno no afecta al otro
	j.combate.enemigos.clear()
	var sa: Dictionary = j.combate._nuevo("slime", j.pies + Vector2(0, 40))
	sa.est = "persigue"
	sa.obj = "local"
	sa.hp = 7
	j.combate.enemigos.append(sa)
	j.combate.enemigos.append(s)
	var pa: Vector2 = j.pies
	j.danar_pj(1000, "b")
	ok(j.jug("b").hp == j.stats("b").hp / 2 and j.pies_de("b") == Vector2(j.jug("b").inicio[0], j.jug("b").inicio[1]), "multi: el derrotado vuelve a su inicio con media vida")
	ok(j.jug().hp == hpa and j.pies == pa and j.combate.enemigos.size() == 2 and sa.hp == 7 and sa.obj == "local" and s.obj == "", "multi: la derrota de uno no reinicia el combate del otro")
	# jefe: derrota del mundo, botín para el golpe final
	j.combate.enemigos.clear()
	j.combate._aparecer_si_toca("guardian")
	var boss: Dictionary = j.combate.enemigos[0]
	j.jug().inv = {}
	j.jug("b").inv = {}
	var xpa: int = j.jug().xp
	var xpb: int = j.jug("b").xp
	while boss.hp > 5: j.combate._danar(boss, 5)
	j.combate._danar(boss, 5, "b")
	ok(boss.est == "muerto" and j.d.jefes.guardian.veces == 1, "multi: el jefe derrotado lo está para el mundo")
	ok(j.jug("b").inv.get("gema", 0) == 3 and j.jug().inv.get("gema", 0) == 0 and j.jug("b").xp == xpb + C.ENEMIGOS.guardian.xp and j.jug().xp == xpa, "multi: el botín y la xp del jefe van al golpe final")
	ok(j.jug("b").recompensas.has("jefe:guardian:1") and not j.jug().recompensas.has("jefe:guardian:1"), "multi: recompensa registrada solo en quien remató")
	ok(j.objetivo_ok({"t": "derrotar", "jefe": "guardian"}) and j.objetivo_ok({"t": "derrotar", "jefe": "guardian"}, "b"), "multi: la derrota del jefe cuenta para las misiones de todos")
	# guardar/cargar 2 jugadores
	j.rt.b.pies = Mundo.pies_de_celda(Vector2i(20, 30))
	j.rt.b.mira = Vector2i.LEFT
	j.evaluar_misiones()   # el estado derivado de las misiones queda al día antes de comparar (cargar también evalúa)
	var ruta := tmp + "/multi.json"
	ok(j.guardar(ruta), "multi: guardar")
	var j2 = J.cargar(ruta)
	ok(JSON.stringify(norm(j.d), "", true) == JSON.stringify(j2.d, "", true), "multi: guardar/cargar conserva todo el estado de ambos")
	ok(j2.pies_de("b") == j.pies_de("b") and j2.pies == j.pies and j2.jug("b").inv == j.jug("b").inv and j2.jug().inv == j.jug().inv
		and j2.stats("b") == j.stats("b") and j2.stats() == j.stats() and j2.estado_mision("cap1_piedras", "b") == "entregada", "multi: tras cargar, posiciones, inventarios, stats y misiones por jugador")
	ok(not j2.combate.enemigos.any(func(e): return e.tipo == "guardian") and j2.jug("b").inv.get("gema", 0) == 3, "multi: tras cargar el jefe sigue derrotado y sin botín repetido")

# Red: identidad y validación del protocolo en el servidor, sin sockets (el nodo no está en el árbol).
func t_red() -> void:
	var j = g(31)
	var s = Srv.new()
	s.j = j
	s.local = J.LOCAL
	var V: int = Srv.VERSION
	var look := [1, 2, 0]
	s.registrar_peer(2)
	var r: Dictionary = s.entrar(2, [V, "Bea", "clave-b", look])
	var b := "@bea"
	ok(r.ok and r.id == b and j.rt.has(b) and j.jug(b).nombre == "Bea" and j.jug(b).look == look and j.jug().nombre == "Test", "red: entrar crea un jugador propio sin tocar al local")
	var cl: Dictionary = j.jug(b).clave
	ok(cl.hash == Srv.hash_clave(cl.sal, "clave-b") and cl.sal.length() == 32 and not JSON.stringify(j.d).contains("clave-b"), "red: se guarda solo un hash con sal de la clave")
	var est: Dictionary = s.estado_para(b)
	ok(not s.privado(b).has("clave") and not JSON.stringify(est).contains(cl.hash) and est.jugadores.size() == 1 and est.jugadores.local.nombre == "Bea", "red: el estado enviado no lleva el hash ni datos privados de otros")
	ok(Srv.nombre_valido("  Ana ") == "Ana" and Srv.nombre_valido("a") == "" and Srv.nombre_valido("Ana;drop") == "" and Srv.nombre_valido(7) == "", "red: validación de nombres")
	s.registrar_peer(3)
	var malos := [null, "hola", [], [V + 1, "Cai", "clave", look], [V, "x", "clave", look], [V, 42, "clave", look],
		[V, "Cai", "abc", look], [V, "Cai", "clave", [9, 0, 0]], [V, "Cai", "clave", [0, 0]], [V, "Cai", "clave", look, "extra"],
		[V, "Cai", "clave", ["0", 0, 0]], [str(V), "Cai", "clave", look]]
	var todos := true
	for m in malos: if s.entrar(3, m).ok: todos = false
	ok(todos and j.d.jugadores.size() == 2, "red: entrar rechaza versión, nombre, clave, apariencia y campos de más")
	ok(s.entrar(3, [V, "Bea", "clave-b", look]).motivo == "Ese jugador ya está conectado", "red: no se entra dos veces con el mismo jugador")
	var loc: Dictionary = s.entrar(3, [V, "local", "clave", look])
	ok(loc.ok and loc.id == "@local" and j.jug().nombre == "Test", "red: un nombre remoto nunca suplanta al jugador local")
	s.retirar_peer(3)
	# desconexión y reconexión
	j.jug(b).inv = {"madera": 7}
	var donde := Mundo.pies_de_celda(Vector2i(30, 40))
	j.rt[b].pies = donde
	s.retirar_peer(2)
	ok(not j.rt.has(b) and j.d.jugadores.has(b) and not s.ids.has(b) and j.jug(b).pos == [donde.x, donde.y], "red: al desconectarse sale del mundo y conserva su estado")
	s.registrar_peer(4)
	ok(s.entrar(4, [V, "bea", "otra", look]).motivo == "Clave incorrecta" and not j.rt.has(b), "red: clave incorrecta se rechaza")
	ok(s.entrar(4, [V, "Bea", "clave-b", look]).ok and j.jug(b).inv == {"madera": 7} and s.ids[b] == 4 and j.pies_de(b) == donde, "red: reconectar con nombre y clave recupera al mismo jugador (inventario y posición)")
	# intenciones inválidas: tipos, rangos, desconocidas, fuera de alcance, repetidas
	j.rt[b].pies = Mundo.pies_de_celda(Vector2i(32, 40))
	var p0: Vector2 = j.pies_de(b)
	var antes := JSON.stringify(norm([j.d.jugadores, j.d.mundo, j.d.cofres]))
	var inval := [null, "accion", [], ["mov"], ["mov", 1, Vector2(1, 0)], ["mov", 2, Vector2i(25, 25)], ["mov", 3, "arriba"], ["teletransporte", 4, Vector2i(1, 1)],
		["construir", 5, "muro", Vector2i(2, 2)], ["construir", 6, "castillo", Vector2i(33, 40)], ["construir", 7, 3, Vector2i(33, 40)],
		["fabricar", 8, 42], ["fabricar", 9, "nada"], ["usar", 10, "x".repeat(100)], ["aceptar", 11, "cap1_piedras"],
		["mover_cofre", 12, "tesoro_cantera", "gema", false], ["mover_cofre", 13, "c@2,2", "madera", true], ["accion", 14, Vector2i.ZERO],
		["accion", 15, Vector2i(1, 1)], ["retirar", 16, Vector2i(60, 5)], ["desequipar", 17, "alas"], ["mov", 1.5, Vector2i.UP], ["mov", 18, Vector2i.UP, 1],
		["construir", 19, "muro", Vector2i(-1, 40)]]
	var rech := true
	for m in inval: if s.ejecutar(b, m): rech = false
	s.paso(Srv.TICK)
	ok(rech and JSON.stringify(norm([j.d.jugadores, j.d.mundo, j.d.cofres])) == antes and j.pies_de(b) == p0, "red: intenciones inválidas, desconocidas o fuera de alcance se ignoran sin cambiar el estado")
	ok(int(s.registro.rechazos.get(b, 0)) == inval.size(), "red: cada pedido rechazado queda registrado")
	j.jug(b).inv = {"madera": 4}
	ok(s.ejecutar(b, ["construir", 20, "muro", Vector2i(33, 40)]) and j.mundo.constr_en(Vector2i(33, 40)).get("dueno", "") == b and j.jug(b).inv == {"madera": 2}, "red: construir junto al jugador se ejecuta con su id")
	ok(not s.ejecutar(b, ["construir", 20, "muro", Vector2i(31, 40)]) and j.mundo.constr_en(Vector2i(31, 40)).is_empty() and j.jug(b).inv == {"madera": 2}, "red: el mismo pedido (mismo seq) no se aplica dos veces")
	ok(s.ejecutar(b, ["mov", 21, Vector2i.UP]), "red: intención de movimiento válida")
	var maxp := 0.0
	for i in 20:
		var a: Vector2 = j.pies_de(b)
		s.paso(Srv.TICK)
		maxp = maxf(maxp, a.distance_to(j.pies_de(b)))
	ok(j.pies_de(b).y < p0.y and maxp <= P.VELOCIDAD * j.stats(b).vel * Srv.TICK + 0.001, "red: el servidor mueve según la intención sin superar la velocidad por tick")
	s.ejecutar(b, ["mov", 22, Vector2i.ZERO])
	var inst: Array = s.instantanea_actual()
	ok(inst[1].has(b) and inst[1].has(J.LOCAL) and inst[1][b].size() == 9 and inst[0] == j.d.min, "red: la instantánea lleva a todos los presentes")
	var n := 0
	for i in 50: if s.recibir(4, ["mov", 100 + i, Vector2i.ZERO]): n += 1
	ok(n == Srv.MAX_PEDIDOS_S, "red: límite de pedidos por segundo y conexión")
	s.registrar_peer(5)
	ok(not s.recibir(5, ["accion", 1, Vector2i.UP]) and not s.recibir(5, ["hola", V, "Bea", "mala", look, Srv.Huella.huella()]) and s.peers[5].fuera
		and not s.recibir(5, ["hola", V, "Bea", "clave-b", look, Srv.Huella.huella()]), "red: sin identificarse no se actúa; tras un rechazo la conexión queda fuera")
	# equipo por red: claves `eq:` en pedidos y en el estado privado
	j.jug(b).inv = {CV: 1, "chispa": 1, "piedra_alma": 1}
	var r0 := int(s.registro.rechazos.get(b, 0))
	ok(s.ejecutar(b, ["equipar", 1000, CV]) and j.jug(b).equipo.casco == CV and s.ejecutar(b, ["mejorar", 1001, CV]) and j.jug(b).equipo.casco == "eq:vigia:casco::1"
		and s.ejecutar(b, ["engarzar", 1002, "eq:vigia:casco::1", "divino"]) and j.jug(b).equipo.casco == "eq:vigia:casco:divino:1" and j.jug(b).inv.is_empty(), "red: equipar, mejorar y engarzar con claves eq: se ejecutan en el servidor")
	var malos_eq := [["equipar", 1003, "eq:vigia:casco::9"], ["mejorar", 1004, "eq:nada:casco::0"], ["engarzar", 1005, "eq:vigia:casco:divino:1", "rojo"],
		["mejorar", 1006, 7], ["ofrecer", 1007, b, {CV: 1}, {}], ["ofrecer", 1008, "@nadie", {CV: 1}, {"madera": 1}], ["aceptar_oferta", 1009, "@nadie"]]
	var todos_eq := true
	for m in malos_eq: if s.ejecutar(b, m): todos_eq = false
	ok(todos_eq and int(s.registro.rechazos.get(b, 0)) == r0 + malos_eq.size() and j.jug(b).equipo.casco == "eq:vigia:casco:divino:1", "red: claves eq: inválidas y ofertas mal formadas se rechazan")
	var pr: Dictionary = s.privado(b)
	var vuelta = bytes_to_var(var_to_bytes(pr))
	var ped = bytes_to_var(var_to_bytes(["equipar", 1, "eq:zarzal:pantalones:brillante:5"]))
	ok(vuelta == pr and vuelta.equipo.casco == "eq:vigia:casco:divino:1" and ped[2] == "eq:zarzal:pantalones:brillante:5" and Srv._sig([ped[2]], [TYPE_STRING]), "red: estado privado y pedidos con claves eq: viajan intactos (serialización del RPC)")
	s.registrar_peer(6)
	ok(s.entrar(6, [V, "Cai", "clave-c", look]).ok, "red: segundo jugador remoto para intercambiar")
	j.jug("@cai").inv = {"chispa": 2}
	j.jug(b).inv = {"eq:albor:botas::0": 1}
	ok(s.ejecutar(b, ["ofrecer", 1010, "@cai", {"eq:albor:botas::0": 1}, {"chispa": 2}]) and j.jug(b).inv == {"eq:albor:botas::0": 1}
		and not s.ejecutar("@cai", ["aceptar_oferta", 1, "@otro"]) and s.ejecutar("@cai", ["aceptar_oferta", 2, b])
		and j.jug(b).inv == {"chispa": 2} and j.jug("@cai").inv == {"eq:albor:botas::0": 1} and s.ofertas.is_empty(), "red: ofrecer + aceptar_oferta intercambia de forma atómica en el servidor")
	s.free()

# Color tal como queda guardado en una imagen RGBA8 (para comparar exacto).
func q(c: Color) -> int:
	var i := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	i.set_pixel(0, 0, c)
	return i.get_pixel(0, 0).to_rgba32()

func t_arte_equipo() -> void:
	var AE = preload("res://scripts/arte_equipo.gd")
	var a = AE.new()
	ok(a.disponible() and a.hojas.size() == 17 and a.base.size() == 7, "arte equipo: 17 hojas y 7 capas base cargadas")
	var dd := Eq.datos()
	var idx := {}
	for c in a.indices: idx[(c as Color).to_rgba32()] = true
	# recoloreado exacto: cada píxel índice pasa al color de su rol (paleta + delta) y no queda ningún índice
	var exacto := true
	var residuo := 0
	var combos := [["vigia", ""], ["zarzal", "brillante"], ["albor", "oscuro"], ["vigia", "divino"]]
	for clave in a.hojas:
		var img: Image = a.hojas[clave]
		var arq: String = clave.split("/")[0]
		var ran: String = clave.split("/")[1]
		for cb in combos:
			var pal: Dictionary = dd.paletas[dd.familias[cb[0]].paleta]
			var dl: Dictionary = dd.deltas[dd.variantes[cb[1]].paleta_delta if cb[1] != "" else "sin_piedra"]
			var out: Image = AE.recolorear(img, a.mapa_indices(pal, dl))
			for y in img.get_height():
				for x in img.get_width():
					var px := img.get_pixel(x, y)
					if px.a8 == 0: continue
					var o := out.get_pixel(x, y).to_rgba32()
					if idx.has(o): residuo += 1
					var rol: String = AE.ROLES[a.indices.find(px)]
					if o != q(AE.color_final(Color(pal[rol]), dl)): exacto = false
	ok(exacto, "arte equipo: el recoloreado da exactamente paleta de familia + delta de variante en las 17 hojas")
	ok(residuo == 0, "arte equipo: ningún píxel índice residual tras recolorear")
	var sin_gris: Image = AE.recolorear(a.hojas["pesada/casco"], a.mapa_indices({"principal": "#112233", "sombra": "#223344", "acento": "#334455"}, {}))
	var gris := false
	for y in 128: for x in 128: if sin_gris.get_pixel(x, y).to_rgba32() == Color("#808080").to_rgba32(): gris = true
	ok(gris, "arte equipo: sin 'detalle' en la paleta el gris índice no se recolorea (contrato d)")
	ok(AE.color_final(Color("#7d8794"), dd.deltas.sin_piedra) == Color("#7d8794") and AE.color_final(Color("#7d8794"), dd.deltas.delta_oscuro).v < Color("#7d8794").v, "arte equipo: sin piedra no cambia el color; Oscuro lo oscurece")
	# orden de capas por orientación e INVERTIR_PERFILES
	var der: Array = AE.orden(Vector2i.RIGHT, false)
	var izq: Array = AE.orden(Vector2i.LEFT, false)
	ok(der.find("escudo") < der.find("torso") and der.find("espada") > der.find("torso") and izq.find("escudo") > izq.find("torso") and izq.find("espada") < izq.find("torso"),
		"arte equipo: derecha escudo detrás del torso y espada delante; izquierda al revés")
	ok(AE.orden(Vector2i.RIGHT, true) == izq and AE.orden(Vector2i.LEFT, true) == der and AE.orden(Vector2i.UP, true) == AE.orden(Vector2i.UP, false) and AE.INVERTIR_PERFILES == false,
		"arte equipo: INVERTIR_PERFILES intercambia solo los perfiles (por defecto false, como el contrato)")
	var set_l := set_de("zarzal")
	set_l["escudo"] = "escudo_madera"
	var vis: Array = Eq.visible(set_l)
	vis.append({"ranura": "espada", "item": "espada_hierro", "paleta": dd.paletas[C.ITEMS.espada_hierro.paleta]})
	var nom := func(d: Vector2i, inv: bool, eq: Array) -> Array: return a.comandos(Vector2.ZERO, d, 0, eq, [0, 0, 0], inv).map(func(x): return x[0])
	var cd: Array = nom.call(Vector2i.RIGHT, false, vis)
	var ci: Array = nom.call(Vector2i.RIGHT, true, vis)
	ok(cd.find("escudo") < cd.find("torso") and cd.find("espada") > cd.find("torso") and ci.find("escudo") > ci.find("torso") and ci.find("espada") < ci.find("torso"),
		"arte equipo: comandos respetan el orden y la inversión de perfiles")
	# ocultación de capas base
	var desnudo: Array = nom.call(Vector2i.DOWN, false, [])
	var vestido: Array = nom.call(Vector2i.DOWN, false, vis)
	ok(desnudo.has("b_tunica") and desnudo.has("b_pantalon") and desnudo.has("b_botas") and not vestido.has("b_tunica") and not vestido.has("b_pantalon")
		and not vestido.has("b_botas") and vestido.has("b_cinturon") and vestido.has("casco") and vestido.has("guantes"), "arte equipo: torso/pantalones/botas ocultan túnica/pantalón/botas base; el cinturón queda")
	var solo_casco: Array = nom.call(Vector2i.DOWN, false, Eq.visible({"casco": CV}))
	ok(solo_casco.has("b_tunica") and solo_casco.has("casco") and solo_casco.find("casco") > solo_casco.find("b_pelo"), "arte equipo: el casco no oculta nada y va sobre el pelo")
	ok(not nom.call(Vector2i.DOWN, false, [{"ranura": "torso", "arquetipo": "media"}]).has("torso") and nom.call(Vector2i.DOWN, false, [{"ranura": "torso", "arquetipo": "media"}]).has("b_tunica"),
		"arte equipo: pieza sin paleta no se dibuja ni oculta la base")
	var cmd: Array = a.comandos(Vector2(100, 50), Vector2i.LEFT, 6, [], [0, 0, 0])
	ok((cmd[0][3] as Rect2) == Rect2(84, 18, 32, 32) and (cmd[0][2] as Rect2) == Rect2(64, 96, 32, 32), "arte equipo: pivote 16/32 en los pies, fila izquierda y cuadro de caminata (mód. 4)")
	# caché
	var t1 = a.textura_pieza(vis[1])
	var n: int = a.recoloreados
	ok(a.textura_pieza(vis[1]) == t1 and a.recoloreados == n and a.capas_base([1, 2, 0]) == a.capas_base([1, 2, 0]), "arte equipo: caché estable por (arquetipo, ranura, familia, variante) y por apariencia")
	var vo: Array = Eq.visible(set_de("zarzal", "oscuro"))
	ok(a.textura_pieza(vo[1]) != t1 and a.recoloreados == n + 1 and vo[1].familia == "zarzal" and vo[1].variante == "oscuro", "arte equipo: otra variante genera otra textura")
	# base con la apariencia
	var piel: Image = a.capas_base([2, 0, 0]).b_piel.get_image()
	var tono_ok := true
	for y in 128: for x in 128:
		var px := piel.get_pixel(x, y)
		if px.a8 > 0 and px.v > 0.05 and absf(px.h - P.PIEL[2].h) > 0.03: tono_ok = false
	ok(tono_ok and a.capas_base([2, 0, 0]).b_cuerpo.get_image().get_data() == a.base.cuerpo.get_data(), "arte equipo: la piel toma el tono del look; el cuerpo residual no se toca")
	# caída al procedural
	var vacio = AE.new(tmp + "/sin_arte")
	ok(not vacio.disponible() and vacio.comandos(Vector2.ZERO, Vector2i.DOWN, 0, vis, [0, 0, 0]).is_empty(), "arte equipo: sin manifiesto no está disponible (la escena dibuja procedural)")
	DirAccess.make_dir_recursive_absolute(tmp + "/arte_incompleto")
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://arte/equipo/manifiesto.json"), tmp + "/arte_incompleto/manifiesto.json")
	var inc = AE.new(tmp + "/arte_incompleto")
	ok(not inc.disponible() and not inc.errores.is_empty() and "falta" in str(inc.errores[0]), "arte equipo: faltan hojas o base -> no disponible, con mensaje y sin error")
	# hashes de las hojas copiadas
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://arte/equipo/manifiesto.json"))
	var orig := ProjectSettings.globalize_path("res://").path_join("../arte-entregado/equipo_indice_01/hojas/").simplify_path()
	var iguales := 0
	var con_original := 0
	for arq in man.hojas:
		for r in man.hojas[arq]:
			var h: Dictionary = man.hojas[arq][r]
			var sha := FileAccess.get_sha256("res://arte/equipo/" + str(h.archivo))
			var o := orig.path_join(str(h.archivo))
			if FileAccess.file_exists(o):
				con_original += 1
				if FileAccess.get_sha256(o) != sha: continue
			if sha == str(h.sha256): iguales += 1
	ok(iguales == 17, "arte equipo: las 17 hojas copiadas conservan el hash del original (%d comparadas con design/art)" % con_original)
	# validación de paletas
	var malo := dd.duplicate(true)
	malo.paletas["pal_vigia"]["principal"] = "#ff0000"
	malo.deltas.erase("sin_piedra")
	malo.deltas["delta_oscuro"]["brillo"] = 3.0
	var ep: Array = Eq.validar_paletas(malo)
	ok(Eq.validar_paletas(dd).is_empty() and ep.size() == 3, "arte equipo: paletas.json validado (color índice, falta sin_piedra, delta fuera de rango)")

# Ataque con equipo (celda 48, arte/equipo/ataque, derivado por herramientas/arte/derivar_ataque.gd).
func _pix(img: Image, fila: int, col: int, cel: int) -> Array:
	var out: Array = []
	for y in cel: for x in cel: if img.get_pixel(col * cel + x, fila * cel + y).a8 != 0: out.append(Vector2i(x, y))
	return out

func _caja(pts: Array) -> Rect2:
	if pts.is_empty(): return Rect2()
	var r := Rect2(Vector2(pts[0]), Vector2.ZERO)
	for p: Vector2i in pts: r = r.expand(Vector2(p))
	return r

func _centro(pts: Array) -> Vector2:
	var s := Vector2.ZERO
	for p: Vector2i in pts: s += Vector2(p)
	return s / maxf(1.0, float(pts.size()))

## Componentes 8-conexas de una lista de píxeles.
func _islas(pts: Array) -> Array:
	var resto := {}
	for p in pts: resto[p] = true
	var out: Array = []
	while not resto.is_empty():
		var ini: Vector2i = resto.keys()[0]
		var comp: Array = []
		var pila: Array = [ini]
		resto.erase(ini)
		while not pila.is_empty():
			var q: Vector2i = pila.pop_back()
			comp.append(q)
			for dy in [-1, 0, 1]: for dx in [-1, 0, 1]:
				var r: Vector2i = q + Vector2i(dx, dy)
				if resto.has(r): resto.erase(r); pila.append(r)
		out.append(comp)
	return out

func t_ataque_equipo() -> void:
	var AE = preload("res://scripts/arte_equipo.gd")
	var a = AE.new()
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://arte/equipo/ataque/manifiesto.json"))
	ok(a.ataque_disponible() and a.atq.celda == 48 and a.atq.pivote == Vector2(24, 48) and a.atq.hojas.size() == 17 and a.atq.base.size() == 7,
		"ataque equipo: conjunto de ataque cargado (celda 48, pivote 24/48, 17 hojas, 7 capas base)")
	var hash_ok := true
	for arq in man.hojas: for r in man.hojas[arq]:
		if FileAccess.get_sha256("res://arte/equipo/ataque/" + str(man.hojas[arq][r].archivo)) != str(man.hojas[arq][r].sha256): hash_ok = false
	ok(hash_ok, "ataque equipo: las 17 hojas conservan el sha256 del manifiesto")
	# regiones esperadas del cuerpo en ataque.png (base sin espada): cabeza = pelo, torso = túnica, piernas = y >= 39 sin piel
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path("res://arte/equipo/ataque/referencia/ataque.png"))
	ref.convert(Image.FORMAT_RGBA8)
	var region := func(pieza: String, fila: int, col: int) -> Rect2:
		if pieza == "casco": return _caja(_pix(a.atq.base.pelo, fila, col, 48)).grow(1)
		if pieza == "torso": return _caja(_pix(a.atq.base.tunica, fila, col, 48)).grow(1)
		var pts: Array = []
		for k in a.atq.base:
			if k == "piel": continue
			for p: Vector2i in _pix(a.atq.base[k], fila, col, 48): if p.y >= 39: pts.append(p)
		return _caja(pts).grow(1)
	var centro_ok := true
	var malos: Array = []
	var dentro_ok := true
	var celdas := 0
	for clave in a.atq.hojas:
		var img: Image = a.atq.hojas[clave]
		var pieza: String = clave.split("/")[1]
		for fila in 4: for col in 4:
			var pts := _pix(img, fila, col, 48)
			if a.atq.pendientes[clave].has(Vector2i(fila, col)):
				if not pts.is_empty(): dentro_ok = false
				continue
			celdas += 1
			if pieza in ["casco", "torso", "pantalones", "botas"] and not (region.call(pieza, fila, col) as Rect2).has_point(_centro(pts)):
				centro_ok = false; malos.append("%s %d,%d" % [clave, fila, col])
			for p: Vector2i in pts:   # capas dentro del cuerpo (ataque.png) +3 px
				var cerca := false
				for yy in range(maxi(0, p.y - 3), mini(48, p.y + 4)):
					for xx in range(maxi(0, p.x - 3), mini(48, p.x + 4)):
						if ref.get_pixel(col * 48 + xx, fila * 48 + yy).a8 != 0: cerca = true
				if not cerca: dentro_ok = false
	# ninguna isla de una capa separada del cuerpo base (ataque sin espada) por un hueco de más de 1 px
	var cuerpo_a: Image = Image.load_from_file(ProjectSettings.globalize_path("res://arte/equipo/ataque/base/ataque_sin_espada.png"))
	cuerpo_a.convert(Image.FORMAT_RGBA8)
	var sueltas: Array = []
	for clave in a.atq.hojas:
		for fila in 4: for col in 4:
			for comp: Array in _islas(_pix(a.atq.hojas[clave], fila, col, 48)):
				var toca := false
				for p: Vector2i in comp:
					for yy in range(maxi(0, p.y - 2), mini(48, p.y + 3)):
						for xx in range(maxi(0, p.x - 2), mini(48, p.x + 3)):
							if cuerpo_a.get_pixel(col * 48 + xx, fila * 48 + yy).a8 != 0: toca = true
					if toca: break
				if not toca: sueltas.append("%s %s/%d" % [clave, ["frente", "derecha", "espalda", "izquierda"][fila], col])
	ok(sueltas.is_empty(), "ataque equipo: ninguna pieza suelta (isla a más de 1 px del cuerpo) %s" % str(sueltas))
	ok(centro_ok, "ataque equipo: por dirección y pose, el centroide de casco/torso/pantalones/botas cae en su región del cuerpo %s" % str(malos))
	ok(dentro_ok and celdas > 0, "ataque equipo: ninguna capa sale del cuerpo de ataque.png +3 px y las celdas pendientes están vacías (%d celdas)" % celdas)
	# manos medidas en perfiles: espada pegada a la mano de la espada, guante sobre cada mano, escudo con la mano libre
	var esp: Image = a.atq.hojas["compartido/espada"]
	var esc: Image = a.atq.hojas["compartido/escudo"]
	var esc_cam: Image = a.hojas["compartido/escudo"]
	var manos_ok := true
	var detalle: Array = []
	for fila in [1, 3]: for col in 4:
		var m: Dictionary = man.manos["%d,%d" % [fila, col]]
		if m.espada is Array:
			var h := Vector2(float(m.espada[0]), float(m.espada[1]))
			var d := 99.0
			for p: Vector2i in _pix(esp, fila, col, 48): d = minf(d, Vector2(p).distance_to(h))
			if d > 3.0: manos_ok = false; detalle.append("espada %d,%d a %.1f px" % [fila, col, d])
			for arq in ["ligera", "media", "pesada"]:
				if not _pix(a.atq.hojas[arq + "/guantes"], fila, col, 48).has(Vector2i(h.round())): manos_ok = false; detalle.append("guante %s %d,%d" % [arq, fila, col])
		var anc: Dictionary = man.escudo.get("%d,%d" % [fila, col], {})
		if anc.get("ancla", "") == "mano libre" and m.escudo is Array:
			var mc: Array = anc.mano_caminata
			var esperado := _centro(_pix(esc_cam, fila, 0, 32)) - Vector2(float(mc[0]), float(mc[1]))
			var real := _centro(_pix(esc, fila, col, 48)) - Vector2(float(m.escudo[0]), float(m.escudo[1]))
			if real.distance_to(esperado) > 1.0: manos_ok = false; detalle.append("escudo %d,%d" % [fila, col])
	ok(manos_ok, "ataque equipo: en perfil, espada y guantes en la mano de la espada medida y escudo con la mano libre %s" % str(detalle))
	# las 3 fases cambian de cuadro en orden: aviso (0, 1), activo (2), rec (3)
	var j = g(5)
	j.combate.atacar(Vector2i.RIGHT)
	var seq: Array = []
	for i in 30:
		var an: Dictionary = j.anim_pj(false, 0.0)
		if an.estado == "ataque" and (seq.is_empty() or seq[-1][1] != an.cuadro): seq.append([j.combate.est, an.cuadro])
		j.combate.paso(1.0 / 30.0)
	ok(seq == [["aviso", 0], ["aviso", 1], ["activo", 2], ["rec", 0]], "ataque equipo: las fases dan los cuadros 0,1 (aviso) 2 (activo) y vuelven a 0 (rec): ciclo 1-2-3-1 %s" % str(seq))
	# render: celda 48 en ataque; pieza pendiente cae a su cuadro 0 de caminata (celda 32); sin conjunto, caminata
	var vis: Array = Eq.visible(set_de("zarzal"))
	vis.append({"ranura": "espada", "item": "espada_hierro", "paleta": Eq.datos().paletas[C.ITEMS.espada_hierro.paleta]})
	var cm: Array = a.comandos(Vector2(100, 50), Vector2i.DOWN, 2, vis, [0, 0, 0], false, "ataque")
	var por := {}
	for c in cm: por[c[0]] = c
	ok((por.b_cuerpo[3] as Rect2) == Rect2(76, 2, 48, 48) and (por.b_cuerpo[2] as Rect2) == Rect2(96, 0, 48, 48) and (por.casco[2] as Rect2).size == Vector2(48, 48),
		"ataque equipo: en ataque la base y las piezas usan celda 48, pivote en los pies y el cuadro = pose")
	ok(a.atq.pendientes["ligera/torso"].is_empty() and por.has("torso") and not por.has("b_tunica") and por.has("casco"),
		"ataque equipo (E01): torso completo en frente/impacto -> sin celdas pendientes y la pieza se dibuja")
	ok(a.atq.get("estela") != null, "ataque equipo (E01): la estela de la espada se carga como capa propia")
	a.atq.pendientes["ligera/torso"][Vector2i(0, 2)] = true   # mecanismo: una celda marcada pendiente ni se dibuja ni oculta la base
	var por_pend := {}
	for c in a.comandos(Vector2(100, 50), Vector2i.DOWN, 2, vis, [0, 0, 0], false, "ataque"): por_pend[c[0]] = c
	ok(not por_pend.has("torso") and por_pend.has("b_tunica") and por_pend.has("casco"),
		"ataque equipo: una celda PENDIENTE no se dibuja y deja ver la túnica base de la pose (el resto sí)")
	a.atq.pendientes["ligera/torso"].erase(Vector2i(0, 2))
	var der: Array = a.comandos(Vector2.ZERO, Vector2i.RIGHT, 1, vis, [0, 0, 0], false, "ataque").map(func(x): return x[0])
	ok(der.find("escudo") < der.find("torso") and der.find("espada") > der.find("torso"), "ataque equipo: orden de capas por orientación del contrato también en ataque")
	var iz_d: Array = a.comandos(Vector2.ZERO, Vector2i.LEFT, 3, vis, [0, 0, 0], false, "ataque").map(func(x): return x[0])
	var iz_c: Array = a.comandos(Vector2.ZERO, Vector2i.LEFT, 3, vis, [0, 0, 0], false).map(func(x): return x[0])
	var de_d: Array = a.comandos(Vector2.ZERO, Vector2i.RIGHT, 3, vis, [0, 0, 0], true, "ataque").map(func(x): return x[0])
	ok(a.atq.delante.has("3,3") and iz_d.find("espada") > iz_d.find("torso") and iz_c.find("espada") < iz_c.find("torso") and de_d.find("espada") > de_d.find("torso"),
		"ataque equipo: izquierda/recuperación (espada sobre el cuerpo en ataque.png) la pone delante del torso; caminata e INVERTIR_PERFILES intactos")
	var sin = AE.new()
	sin.atq.celda = 0
	var cs: Array = sin.comandos(Vector2(100, 50), Vector2i.DOWN, 2, vis, [0, 0, 0], false, "ataque")
	ok(not sin.ataque_disponible() and not cs.is_empty() and (cs[0][3] as Rect2).size == Vector2(32, 32) and (cs[0][2] as Rect2).position == Vector2(64, 0),
		"ataque equipo: sin conjunto de ataque cae a la caminata sin error")

func t_imagen_util() -> void:
	var im: Image = ImagenUtil.imagen("res://arte/equipo/base/capas/cuerpo.png")
	ok(im != null and im.get_width() > 0 and im.get_width() % 4 == 0 and im.get_width() == im.get_height(), "imagen_util: res:// importado devuelve imagen cuadrada de 4 celdas")
	var f: String = tmp + "/iu.png"
	Image.create(8, 4, false, Image.FORMAT_RGBA8).save_png(f)
	var t: Image = ImagenUtil.imagen(f)
	ok(t != null and t.get_width() == 8 and t.get_height() == 4 and ImagenUtil.existe(f), "imagen_util: PNG temporal en user:// sigue funcionando")
	ok(ImagenUtil.imagen("res://arte/no_existe.png") == null and not ImagenUtil.existe("res://arte/no_existe.png"), "imagen_util: ruta inexistente devuelve null")


# ---------- E02: herramienta, daño, caída y dormir ----------
func t_estados_e02() -> void:
	var AE = preload("res://scripts/arte_equipo.gd")
	var a = AE.new()
	var esperado := {"herramienta": [3, 4], "dano": [2, 2], "caida": [2, 2], "dormir": [1, 1]}
	var cargados := true
	for n in esperado:
		var st: Dictionary = a.estados.get(n, {})
		if not (a.estado_disponible(n) and st.celda == 48 and st.pivote == Vector2(24, 48) and st.mapa.size() == esperado[n][0] and st.base.size() == 7 and st.hojas.size() == 23): cargados = false
	ok(cargados, "estados E02: herramienta, daño, caída y dormir cargan (celda 48, pivote 24/48, 7 capas base y 23 hojas)")
	var vis: Array = Eq.visible(set_de("zarzal"))
	vis.append({"ranura": "espada", "item": "espada_hierro", "paleta": Eq.datos().paletas[C.ITEMS.espada_hierro.paleta]})
	vis.append({"ranura": "escudo", "item": "escudo_madera", "paleta": Eq.datos().paletas[C.ITEMS.escudo_madera.paleta]})
	var nombres := func(estado: String, dir: Vector2i, cuadro: int, hacha: bool) -> Array:
		return a.comandos(Vector2(100, 50), dir, cuadro, vis, [0, 0, 0], false, estado, hacha).map(func(x): return x[0])
	var h: Array = nombres.call("herramienta", Vector2i.DOWN, 0, true)
	ok(h.has("guantes_lejana") and h.has("guantes_cercana") and not h.has("guantes"), "estados E02: los guantes se dibujan desdoblados y nunca con el atlas combinado")
	ok(h[-1] == "hacha" and not nombres.call("herramienta", Vector2i.DOWN, 0, false).has("hacha"), "estados E02: el hacha va encima solo cuando se pide (talar con hacha)")
	ok(h.has("escudo") and not h.has("espada") and not nombres.call("dano", Vector2i.DOWN, 0, true).has("hacha"), "estados E02: herramienta muestra escudo sin espada; el hacha no aparece fuera de herramienta")
	var d: Array = nombres.call("dano", Vector2i.DOWN, 0, false)
	ok(d.has("espada") and d.has("escudo"), "estados E02: daño muestra espada y escudo")
	ok(not nombres.call("caida", Vector2i.DOWN, 0, false).has("escudo") and not nombres.call("dormir", Vector2i.DOWN, 0, false).has("espada"), "estados E02: caída y dormir no muestran armas")
	var cm: Array = a.comandos(Vector2(100, 50), Vector2i.RIGHT, 2, vis, [0, 0, 0], false, "herramienta", false)
	var col2: float = (cm[0][2] as Rect2).position.x / 48.0
	var fila_d: float = (cm[0][2] as Rect2).position.y / 48.0
	ok(col2 == 3.0 and fila_d == 1.0 and (cm[0][3] as Rect2) == Rect2(76, 2, 48, 48), "estados E02: cuadro lógico 2 de herramienta usa la columna 3 y la fila de la derecha; pies en el pivote")
	var cm_d: Array = a.comandos(Vector2.ZERO, Vector2i.DOWN, 5, vis, [0, 0, 0], false, "dano", false)
	ok((cm_d[0][2] as Rect2).position.x / 48.0 == 1.0, "estados E02: el cuadro de daño se reduce a sus 2 columnas (cuadro 5 -> columna 1)")
	var der: Array = nombres.call("herramienta", Vector2i.RIGHT, 0, false)
	var fre: Array = nombres.call("herramienta", Vector2i.DOWN, 0, false)
	ok(der.find("escudo") >= 0 and der.find("escudo") < der.find("torso") and fre.find("escudo") > fre.find("torso"), "estados E02: escudo detrás del torso en perfil derecho y delante en frente")
	var sin_estado: Array = nombres.call("estado_inexistente", Vector2i.DOWN, 0, false)
	ok(sin_estado.size() > 0 and not sin_estado.has("guantes_lejana"), "estados E02: un estado sin hoja cae al render de caminata sin error")

# ---------- E04/E05: terreno, naturaleza, casa y objetos ----------
func t_mundo_arte() -> void:
	var MA = preload("res://scripts/mundo_arte.gd")
	var ma = MA.new()
	ok(ma.cargar() and ma.mapeo.has("path") and ma.mapeo.has("water") and ma.mapeo.has("ruins") and ma.mapeo.has("wall"), "mundo arte: catálogos E04/E05 cargan y definen camino, agua, ruinas y muro")
	var m := Mundo.new()
	var sin_mapeo := 0
	for y in Mundo.ALTO:
		for x in Mundo.ANCHO:
			var c := Vector2i(x, y)
			var t: int = m.tipo(c)
			var clase := "path" if t == Mundo.T.CAMINO else "water" if t == Mundo.T.AGUA else "ruins" if t == Mundo.T.RUINA else "wall" if t == Mundo.T.PARED or t == Mundo.T.MURO_RUINA else ""
			if clase != "" and not ma.mapeo[clase].has(str(ma.mascara(m, c, t))): sin_mapeo += 1
	ok(sin_mapeo == 0, "mundo arte: toda celda de camino, agua, ruina y muro del mapa tiene su conexión de 47 (%d sin mapeo)" % sin_mapeo)
	ok(MA._normalizar(0xFF) == 255 and MA._normalizar(16) == 0 and MA._normalizar(1 | 2 | 16) == 19, "mundo arte: la diagonal solo cuenta si sus dos vecinos cardinales coinciden")
	var texturas_ok := true
	for k in ["E04_grass_periodica.png", "E04_path_47.png", "E04_water_47_anim.png", "E04_wall_47.png", "E04_ruins_47.png", "E05_casa_tejado_160.png", "E05_casa_fachada_160.png", "E05_valla_mask_15.png", "E05_cofre_cerrado_alineado.png", "E05_barrel.png"]:
		if ma.tex(k) == null: texturas_ok = false
	ok(texturas_ok and ma.faltantes.is_empty(), "mundo arte: las texturas de terreno, casa, valla, cofre y barril cargan sin faltantes")
	var rutas_ok := true
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://arte/mundo/manifiesto.json"))
	for f in man.archivos: if FileAccess.get_sha256("res://arte/mundo/" + f) != str(man.archivos[f]): rutas_ok = false
	ok(rutas_ok, "mundo arte: los %d archivos copiados de E04/E05 conservan el sha256 del manifiesto" % man.archivos.size())
	ok(ma.tex("no_existe.png") == null and ma.faltantes.has(MA.RAIZ + "no_existe.png"), "mundo arte: un recurso inexistente se registra como faltante, sin dibujar arte anterior")

# ---------- E03: enemigos y efectos ----------
func t_actores_arte() -> void:
	var AA = preload("res://scripts/actores_arte.gd")
	var aa = AA.new()
	var m := Mundo.new()
	var e := {"tipo": "slime", "pos": Vector2(100, 100), "home": Vector2(100, 100), "hp": 12, "est": "idle", "dir": Vector2.DOWN, "tam": 12}
	aa.actualizar(0.016, [e], 40, Vector2(0, 0), m, false)
	e.hp = 6
	e.pos = Vector2(101, 100)
	aa.actualizar(0.016, [e], 40, Vector2(0, 0), m, false)
	ok(aa.efectos.any(func(f): return f.tipo == "impacto") and aa.seguidos[AA.clave(e)].dano_t > 0.0 and aa.seguidos[AA.clave(e)].mov, "actores arte: un golpe confirmado crea el efecto de impacto, la reacción de daño y la marcha")
	aa.actualizar(0.016, [], 40, Vector2(0, 0), m, false)
	ok(aa.residuos.size() == 1 and aa.seguidos.is_empty(), "actores arte: al morir el enemigo queda un residuo gráfico sin colisión")
	aa.actualizar(0.5, [], 40, Vector2(0, 0), m, false)
	ok(aa.residuos.is_empty() and aa.efectos.is_empty(), "actores arte: residuo y efectos terminan por duración y no se acumulan")
	aa.actualizar(0.016, [], 30, Vector2(5, 5), m, false)
	ok(aa.efectos.any(func(f): return f.tipo == "dano"), "actores arte: perder vida el jugador local crea el efecto de daño")
	var otro = AA.new()
	otro.actualizar(0.016, [e], 40, Vector2.ZERO, m, true)
	e.hp = 1
	otro.actualizar(0.016, [e], 40, Vector2.ZERO, m, true)
	ok(otro.seguidos.is_empty() and not otro.efectos.any(func(f): return f.tipo == "impacto"), "actores arte: un cliente de red no deduce eventos por enemigo (sin identidad estable)")
	ok(AA.cardinal(Vector2(5, 1)) == Vector2i.RIGHT and AA.cardinal(Vector2(-1, -5)) == Vector2i.UP and AA.fila(Vector2i.LEFT) == 3, "actores arte: la dirección se reduce a las 4 filas sur/este/norte/oeste")

# ---------- Regla maestra: el arte procedural anterior no vuelve ----------
## Recorre scripts/ y falla si aparece dibujo por código fuera de la lista blanca aprobada. Cada entrada es un máximo exacto:
## marcadores magenta de «arte faltante» (ui_arte 8, mundo_arte 2, actores_arte 2, escena 2), selección de panel (hud 2),
## zonas de aviso técnicas de enemigos (escena 2), cajas de depuración F1 (escena 2), barra de vida de enemigo (escena 2) e
## indicador de golpes (escena 1), fondo de etiquetas (escena 1), foco/bordes de inventario (hud 3) y
## superposición de mineral (mundo_arte 1). Un dibujo nuevo obliga a revisar esta lista.
## EXCEPCIONES APROBADAS (usuario, 25/10, «arte vivo» 88571a6; ver DECISIONES.md «Excepciones de dibujo por código»):
## solo estos tres scripts y solo estas funciones, con máximo exacto por función (49 llamadas). No es una excepción general:
## una llamada nueva, un script nuevo o una función nueva con dibujo hace fallar la prueba.
##  arte_entornos.gd  suelo 15 (velos de bioma/cantera/ruinas, sombra de la casa, motas, hierbas, piedrecillas, juncos, musgo, destello del agua),
##                    _flor 4, _sombra_suelo 2 (sombras de contacto)
##  hud_vivo.gd       _celda 1 (cuadro de color cuando un ítem no tiene icono), _inventario 4 (botón cerrar y dos círculos de fondo)
##  ui_viva.gd        marco 13 (marcos de panel, tooltip y botón), ranura 5 (casilla de inventario), medidor 5 (barras de vida y XP)
const DIBUJOS_APROBADOS := {
	"arte_entornos.gd": {"suelo": 15, "_flor": 4, "_sombra_suelo": 2},
	"hud_vivo.gd": {"_celda": 1, "_inventario": 4},
	"ui_viva.gd": {"marco": 13, "ranura": 5, "medidor": 5},
}
## Cuenta las llamadas de dibujo por función del código fuente `src`.
func _dibujos_por_funcion(src: String, re: RegEx) -> Dictionary:
	var re_func := RegEx.new()
	re_func.compile("^(?:static\\s+)?func\\s+(\\w+)")
	var cuentas := {}
	var actual := ""
	for linea in src.split("\n"):
		var m := re_func.search(linea)
		if m: actual = m.get_string(1)
		var n := re.search_all(linea).size()
		if n > 0: cuentas[actual] = int(cuentas.get(actual, 0)) + n
	return cuentas

func t_sin_arte_procedural() -> void:
	var lista := {"ui_arte.gd": 8, "mundo_arte.gd": 3, "actores_arte.gd": 2, "hud.gd": 5, "escena.gd": 10}
	var re := RegEx.new()
	re.compile("draw_(rect|circle|colored_polygon|polygon|line|arc|polyline)\\(")
	var fuera := []
	for f in DirAccess.get_files_at("res://scripts"):
		if not f.ends_with(".gd"): continue
		var fuente := FileAccess.get_file_as_string("res://scripts/" + f)
		if DIBUJOS_APROBADOS.has(f):
			var por_funcion := _dibujos_por_funcion(fuente, re)
			if JSON.stringify(por_funcion, "", true) != JSON.stringify(DIBUJOS_APROBADOS[f], "", true):
				fuera.append("%s=%s (aprobado %s)" % [f, str(por_funcion), str(DIBUJOS_APROBADOS[f])])
			continue
		var n := re.search_all(fuente).size()
		if n != int(lista.get(f, 0)): fuera.append("%s=%d (permitido %d)" % [f, n, int(lista.get(f, 0))])
	ok(fuera.is_empty(), "sin arte procedural: ningún script dibuja con primitivas fuera de la lista blanca %s" % str(fuera))
	# La comprobación por función detecta un dibujo nuevo aunque el script ya tenga excepciones.
	var base := "func suelo(ci):\n\tci.draw_rect(a)\nfunc _flor(ci):\n\tci.draw_line(a)\n"
	var aprobado := {"suelo": 1, "_flor": 1}
	ok(JSON.stringify(_dibujos_por_funcion(base, re), "", true) == JSON.stringify(aprobado, "", true), "sin arte procedural: el recuento por función coincide con lo aprobado")
	ok(JSON.stringify(_dibujos_por_funcion(base + "func nueva(ci):\n\tci.draw_circle(a)\n", re), "", true) != JSON.stringify(aprobado, "", true), "sin arte procedural: una función nueva con dibujo se detecta")
	ok(JSON.stringify(_dibujos_por_funcion(base.replace("draw_rect(a)", "draw_rect(a)\n\tci.draw_rect(b)"), re), "", true) != JSON.stringify(aprobado, "", true), "sin arte procedural: una llamada extra en una función aprobada se detecta")
	ok(not FileAccess.file_exists("res://scripts/arte.gd") and not FileAccess.file_exists("res://scripts/apariencia.gd") and not FileAccess.file_exists("res://scripts/capas_sprite.gd") and not FileAccess.file_exists("res://arte/personaje_cuerpo.png"),
		"sin arte procedural: los módulos y hojas del arte anterior ya no existen")
	var esc_src := FileAccess.get_file_as_string("res://scripts/escena.gd")
	ok(not esc_src.contains("usar_arte") and not esc_src.contains("Arte.suelo") and not esc_src.contains("Apar."), "sin arte procedural: la escena no tiene interruptor ni llamadas al dibujo anterior")
