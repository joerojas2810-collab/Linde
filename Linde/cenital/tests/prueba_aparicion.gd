extends SceneTree
## Mundo 1, paso 1c: `Juego.punto_aparicion` (aparición en un poblado). Seguridad estática, dispersión, estado cambiado,
## poblados inviables, determinismo y recuperación sin posición segura.
## Uso: godot --headless --path Linde/cenital --script res://tests/prueba_aparicion.gd   (código de salida = nº de fallos)
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const Comb = preload("res://scripts/combate.gd")
const Srv = preload("res://scripts/red_servidor.gd")
var fallos := 0

func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1

func _centro(j) -> Vector2i:
	var p: Dictionary = j.mundo.poblado(M.ID_INICIAL)
	return Vector2i(int(p.centro[0]), int(p.centro[1]))

## Comprobación independiente de las reglas, sin pasar por la implementación.
func _valida(j, c: Vector2i, otros: Array = []) -> bool:
	var alc: Dictionary = j.mundo.alcanzables(j.mundo.entrada(M.ID_INICIAL))
	var t: int = j.mundo.tipo(c)
	if t != M.T.PASTO and t != M.T.CAMINO or not alc.has(c): return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if j.mundo.bloquea(c + Vector2i(dx, dy)): return false
	var d := Vector2(c - _centro(j)).length()
	if d < 2.0 or d > 7.0 or j.ocupada(c): return false
	var cp := M.pies_de_celda(c) - Vector2(0, 6)
	for e in j.combate.enemigos:
		if e.est != "muerto" and Comb.centro(e).distance_to(cp) <= float(C.ENEMIGOS[e.tipo].vision): return false
	for o in otros:
		if maxi(absi(o.x - c.x), absi(o.y - c.y)) < 2: return false
	return true

## Aparece como lo hará `unir`: calcula la celda, la valida de forma independiente ANTES de ocuparla y crea la sesión.
func _unir_simulado(j, id: String, otros: Array) -> Dictionary:
	var r: Dictionary = j.punto_aparicion(id)
	if r.ok:
		r["valida"] = _valida(j, r.celda, otros)
		j.d.jugadores[id] = J.nuevo_jugador(id, [0, 0, 0], M.pies_de_celda(r.celda))
		j._sesion(id)
	return r

func _init() -> void:
	# 1. Seguridad estática y determinismo en 500 semillas.
	var invalidas := 0
	var sin_resultado := 0
	var distintas := {}
	var repetible := true
	var hashes: Array = []
	var cercanas_a_enemigo := 0
	for s in range(1, 501):
		var j = J.nueva(s, "Prueba", [0, 0, 0])
		var r: Dictionary = j.punto_aparicion("nuevo")
		if not r.ok:
			sin_resultado += 1
			continue
		if not _valida(j, r.celda): invalidas += 1
		if j.punto_aparicion("nuevo").celda != r.celda: repetible = false
		distintas[r.celda] = true
		hashes.append([r.celda.x, r.celda.y])
	ok(sin_resultado == 0, "500 semillas: siempre hay una celda de aparición")
	ok(invalidas == 0, "500 semillas: todas cumplen terreno, 3×3 libre, conectividad, no ocupada, radio 2–7 y fuera del radio de detección")
	ok(repetible, "500 semillas: la misma entrada da la misma celda")
	ok(distintas.size() >= 2, "la celda varía con la semilla (%d distintas)" % distintas.size())
	# 2. Dispersión: seis jugadores sucesivos.
	var j = J.nueva(123, "Primera", [0, 0, 0])
	var celdas: Array = [M.celda_de(j.pies_de())]   # el jugador local entró por el modo legado: se cuenta como presente
	var todos_ok := true
	var separados := true
	var motivos := {}
	for i in 6:
		var id := "amigo%d" % i
		var otros := celdas.duplicate()
		var r: Dictionary = _unir_simulado(j, id, otros)
		if not r.ok:
			todos_ok = false
			break
		motivos[r.motivo] = true
		if not r.valida: todos_ok = false
		for o in otros:
			if maxi(absi(o.x - r.celda.x), absi(o.y - r.celda.y)) < 2: separados = false
		celdas.append(r.celda)
	ok(todos_ok, "seis jugadores sucesivos obtienen una celda válida")
	var unicas := {}
	for c in celdas: unicas[c] = true
	ok(unicas.size() == celdas.size(), "seis jugadores sucesivos no coinciden en celda")
	ok(separados and not motivos.has("poblado_sin_separacion"), "separación mínima de 2 celdas entre ellos mientras hay candidatas")
	# 3. Estado cambiado: construcción, ocupación y enemigo vivo cerca.
	j = J.nueva(123, "Cambios", [0, 0, 0])
	var r0: Dictionary = j.punto_aparicion("x")
	j.mundo.poner(r0.celda, "muro", false, "mundo")
	var r1: Dictionary = j.punto_aparicion("x")
	ok(r1.ok and r1.celda != r0.celda and _valida(j, r1.celda), "una celda construida deja de ser candidata")
	j.mundo.quitar(r0.celda)
	var e: Dictionary = j.combate._nuevo("slime", M.pies_de_celda(r0.celda + Vector2i(3, 0)))
	j.combate.enemigos.append(e)
	var r2: Dictionary = j.punto_aparicion("x")
	ok(r2.ok and _valida(j, r2.celda) and Comb.centro(e).distance_to(M.pies_de_celda(r2.celda) - Vector2(0, 6)) > float(C.ENEMIGOS.slime.vision),
		"un enemigo vivo cerca excluye las celdas dentro de su radio de detección")
	j.combate.enemigos.erase(e)
	e = j.combate._nuevo("slime", M.pies_de_celda(r0.celda))
	e.est = "muerto"
	j.combate.enemigos.append(e)
	ok(j.punto_aparicion("x").ok, "un enemigo muerto no excluye celdas")
	j.combate.enemigos.erase(e)
	# 4. Sin posiciones seguras: se rechaza con motivo y sin inventar una celda.
	var enemigos_antes: Array = j.combate.enemigos.duplicate()
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var c := _centro(j) + Vector2i(dx, dy)
			if j.mundo.puede_poner(c) == "": j.mundo.poner(c, "muro", false, "mundo")
	var r3: Dictionary = j.punto_aparicion("x")
	ok(not r3.ok and r3.motivo == "sin_celda_valida" and r3.celda == M.SIN_CELDA, "sin celdas libres: no hay aparición y el motivo es explícito")
	# 5. Poblados inviables y otro poblado viable.
	j = J.nueva(123, "Poblados", [0, 0, 0])
	j.d.mundo.poblados[M.ID_INICIAL].estado = "abandonado"
	var r4: Dictionary = j.punto_aparicion("x")
	ok(not r4.ok and r4.motivo == "sin_poblado_activo", "un poblado no activo no se reactiva para dar cabida a un jugador")
	j.d.mundo.poblados.otro = {"id": "otro", "nombre": "Otro", "estado": "activo", "centro": [10, 12], "area": [0, 0, 64, 48], "entrada": [M.ENTRADA.x, M.ENTRADA.y],
		"esenciales": [], "camas": {}, "residentes": ["zoe"]}
	var r5: Dictionary = j.punto_aparicion("x")
	ok(r5.ok and r5.poblado == "otro" and Vector2(r5.celda - Vector2i(10, 12)).length() <= 7.0, "con el inicial inactivo se elige otro poblado activo y viable")
	j.d.mundo.poblados.otro.residentes = []
	ok(not j.punto_aparicion("x").ok and j.punto_aparicion("x").motivo == "sin_residentes", "un poblado sin habitantes presentes no es viable")
	j.d.mundo.poblados[M.ID_INICIAL].estado = "activo"
	j.habitantes.ids.clear()
	ok(not j.punto_aparicion("x").ok and j.punto_aparicion("x").motivo == "sin_residentes", "el inicial sin habitantes presentes tampoco es viable")
	# 6. Registro erróneo: sin datos no hay aparición.
	j = J.nueva(123, "Datos", [0, 0, 0])
	j.d.mundo.poblados[M.ID_INICIAL].erase("centro")
	ok(not j.punto_aparicion("x").ok, "un poblado sin centro no se usa")
	j.d.mundo.erase("poblados")
	ok(not j.punto_aparicion("x").ok, "sin registro de poblados no hay aparición (no se recurre a constantes)")
	# 7. Flujo real de entrada (`unir`) en modo poblado, rechazo sin posición segura y modo legado intacto.
	var jl = J.nueva(123, "Legado", [0, 0, 0])
	ok(jl.mundo.modo_inicio() == M.MODO_LEGADO and M.celda_de(jl.pies_de()) == M.new().punto_inicio(123), "modo legado: el primer jugador aparece donde dice punto_inicio al crear el mundo")
	var esperado_unir: Vector2i = jl.mundo.punto_inicio(123)   # con las regiones del contorno ya cargadas, como en Juego.unir
	jl.unir("b", "Bea", [0, 0, 0])
	ok(M.celda_de(jl.pies_de("b")) == esperado_unir, "modo legado: unir usa punto_inicio, como siempre")
	var jp = J.nueva(123, "Poblado", [0, 0, 0], M.MODO_POBLADO)
	var c_local: Vector2i = M.celda_de(jp.pies_de())
	ok(Vector2(c_local - _centro(jp)).length() >= 2.0 and Vector2(c_local - _centro(jp)).length() <= 7.0, "nueva(modo poblado): el primer jugador aparece entre 2 y 7 celdas del centro del poblado")
	ok(jp.jug().inicio == [jp.pies_de().x, jp.pies_de().y] and jp.jug().pos == jp.jug().inicio, "nueva(modo poblado): posición e inicio guardados coinciden con la celda elegida")
	ok(jp.d.mundo.inicio.ultimo.jugador == J.LOCAL and jp.d.mundo.inicio.ultimo.ok, "nueva(modo poblado): el resultado queda registrado")
	ok(jp.mundo.modo_inicio() == M.MODO_POBLADO and jp.d.mundo.inicio.modo == "poblado", "nueva(modo poblado) guarda el modo en el mundo")
	var previas: Array = [M.celda_de(jp.pies_de())]
	var union_ok := true
	var unicas2 := {}
	for i in 5:
		var id := "u%d" % i
		var r: Dictionary = jp.unir(id, "U%d" % i, [0, 0, 0])
		var c: Vector2i = M.celda_de(jp.pies_de(id))
		if not r.ok or Vector2(c - _centro(jp)).length() > 7.0 or Vector2(c - _centro(jp)).length() < 2.0: union_ok = false
		for o in previas: if maxi(absi(o.x - c.x), absi(o.y - c.y)) < 2 and o != c: union_ok = false
		unicas2[c] = true
		previas.append(c)
	ok(union_ok and unicas2.size() == 5, "unir en modo poblado: cinco jugadores, todos entre 2 y 7 celdas del centro, sin coincidir")
	ok(jp.d.mundo.inicio.ultimo.ok and jp.d.mundo.inicio.ultimo.poblado == M.ID_INICIAL and jp.d.mundo.inicio.ultimo.jugador == "u4", "el último resultado de aparición queda registrado")
	# Rechazo: se llena el círculo; no se crea al jugador y queda el motivo.
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var c2 := _centro(jp) + Vector2i(dx, dy)
			if jp.mundo.puede_poner(c2) == "" and not jp.ocupada(c2): jp.mundo.poner(c2, "muro", false, "mundo")
	var n_jug: int = jp.d.jugadores.size()
	var rr: Dictionary = jp.unir("tarde", "Tarde", [0, 0, 0])
	ok(not rr.ok and not jp.d.jugadores.has("tarde") and jp.d.jugadores.size() == n_jug and not jp.rt.has("tarde"), "sin posición segura unir rechaza y no crea al jugador")
	ok(jp.d.mundo.inicio.ultimo.ok == false and jp.d.mundo.inicio.ultimo.motivo == "sin_celda_valida", "el rechazo deja su motivo en el registro")
	# Servidor: el rechazo llega al cliente como entrada denegada y no deja un jugador a medias.
	var srv = Srv.new()
	srv.j = jp
	srv.peers[9] = {"id": ""}
	var ent: Dictionary = srv.entrar(9, [Srv.VERSION, "Tardona", "clave-larga-1", [0, 0, 0]])
	ok(not ent.ok and ent.motivo.begins_with("No hay ningún lugar seguro") and not jp.d.jugadores.has("@tardona") and srv.peers[9].id == "", "el servidor deniega la entrada con el motivo y sin crear estado")
	print("APARICION: %d fallos" % fallos)
	quit(fallos)
