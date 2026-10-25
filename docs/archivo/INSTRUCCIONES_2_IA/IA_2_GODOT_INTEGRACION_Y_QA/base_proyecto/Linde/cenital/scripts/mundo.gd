extends RefCounted
# Geometría y estado modificable del mundo. Celdas = Vector2i; posiciones en px = "pies" (centro-abajo).
# Mapa de autor FIJO (semilla MAPA); la semilla de partida solo elige el punto de inicio.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
enum T { PASTO, CAMINO, AGUA, PARED, SUELO, PUERTA, RUINA, MURO_RUINA }
const ANCHO := 64
const ALTO := 48
const MAPA := 20261023
const CASA := Rect2i(24, 16, 8, 7)           # x 24..31, y 16..22
const PUERTA_C := Vector2i(27, 22)
const ENTRADA := Vector2i(32, 46)            # extremo sur del camino; semilla de alcanzabilidad
const ARENA := Rect2i(46, 38, 12, 9)
const CANTERA := Rect2i(4, 4, 13, 11)
const BOSQUE := Rect2i(38, 3, 24, 14)
const CLARO := Vector2i(50, 10)
const SPAWN_GUARDIAN := Vector2i(52, 43)
const COFRE_TESORO := Vector2i(6, 6)
const CAMA_MAREN := Vector2i(30, 18)
const ESENCIALES := [Vector2i(32, 46), Vector2i(27, 23), Vector2i(27, 21), Vector2i(30, 19), Vector2i(51, 37), Vector2i(52, 37),
	Vector2i(6, 7), Vector2i(50, 10)]
const N_SLIMES := 12
const DECO := ["valla", "barril"]    # decoración sólida, no rompible
const DECORADO := {"valla": [Vector2i(33, 19), Vector2i(33, 20), Vector2i(33, 21), Vector2i(22, 20), Vector2i(22, 21)],
	"barril": [Vector2i(33, 22), Vector2i(23, 22)]}

var celdas := PackedInt32Array()
var objetos := {}            # id -> {t, c}   (estático, derivado del MAPA)
var por_celda := {}          # Vector2i -> id
var spawns_slime: Array = []
var estado := {"rotos": {}, "golpes": {}, "constr": {}}   # lo único que se guarda
var version := 0
var _bloq := PackedByteArray()
var _bloq_v := -1

static func h(x: int, y: int, s: int) -> int:
	var v := x * 374761393 + y * 668265263 + s * 2147483629
	v = (v ^ (v >> 13)) * 1274126177
	v ^= v >> 16
	return v & 0x7fffffff

static func frac(x: int, y: int, s: int) -> float:
	return float(h(x, y, s) % 10000) / 10000.0

func _init() -> void:
	celdas.resize(ANCHO * ALTO)
	celdas.fill(T.PASTO)
	for x in range(44, 50):
		for y in range(28, 35): _poner(x, y, T.AGUA)
	for y in range(23, ALTO): _poner(32, y, T.CAMINO)
	for x in range(12, 53): _poner(x, 23, T.CAMINO)
	for y in range(24, 38): _poner(52, y, T.CAMINO)
	for x in range(CASA.position.x, CASA.end.x):
		for y in range(CASA.position.y, CASA.end.y):
			var borde := x == CASA.position.x or x == CASA.end.x - 1 or y == CASA.position.y or y == CASA.end.y - 1
			_poner(x, y, T.PARED if borde else T.SUELO)
	_poner(PUERTA_C.x, PUERTA_C.y, T.PUERTA)
	for x in range(ARENA.position.x, ARENA.end.x):
		for y in range(ARENA.position.y, ARENA.end.y):
			var borde := x == ARENA.position.x or x == ARENA.end.x - 1 or y == ARENA.position.y or y == ARENA.end.y - 1
			_poner(x, y, T.MURO_RUINA if borde else T.RUINA)
	_poner(51, 38, T.RUINA)
	_poner(52, 38, T.RUINA)
	_generar_objetos()
	_agregar("cofre_fijo", COFRE_TESORO, "tesoro_cantera")
	for t in DECORADO: for c in DECORADO[t]: _agregar(t, c)
	estado.constr[clave(CAMA_MAREN)] = {"t": "cama", "propia": false}
	_generar_slimes()

func _poner(x: int, y: int, t: int) -> void:
	celdas[y * ANCHO + x] = t

func _agregar(t: String, c: Vector2i, id: String = "") -> void:
	if id == "": id = "%s@%d,%d" % [t, c.x, c.y]
	objetos[id] = {"t": t, "c": c}
	por_celda[c] = id

func _libre_para_objeto(c: Vector2i) -> bool:
	if tipo(c) != T.PASTO: return false
	if CASA.grow(2).has_point(c) or ARENA.grow(1).has_point(c): return false
	if absi(c.x - 32) <= 1 and c.y >= 22: return false
	if absi(c.y - 23) <= 1 and c.x >= 11 and c.x <= 53: return false
	if absi(c.x - 52) <= 1 and c.y >= 22 and c.y <= 38: return false
	if Vector2(c).distance_to(Vector2(ENTRADA)) < 5.0: return false
	if Vector2(c).distance_to(Vector2(CLARO)) < 5.5: return false
	if Rect2i(COFRE_TESORO - Vector2i(1, 1), Vector2i(3, 4)).has_point(c): return false
	return true

func _generar_objetos() -> void:
	for y in ALTO:
		for x in ANCHO:
			var c := Vector2i(x, y)
			if not _libre_para_objeto(c): continue
			var f := frac(x, y, MAPA)
			if CANTERA.has_point(c):
				if x == 10 or y == 9: continue     # pasillos garantizados
				if f < 0.04: _agregar("veta", c)
				elif f < 0.18: _agregar("roca", c)
			elif BOSQUE.has_point(c):
				if x % 5 == 0 or y % 5 == 0: continue
				if f < 0.30: _agregar("arbol", c)
				elif f < 0.38: _agregar("arbusto", c)
			else:
				if f < 0.025: _agregar("arbol", c)
				elif f < 0.045: _agregar("arbusto", c)
				elif f < 0.050 and not (x % 6 == 0 or y % 6 == 0): _agregar("roca", c)

func _generar_slimes() -> void:
	var k := 0
	while spawns_slime.size() < N_SLIMES and k < 4000:
		var c := Vector2i(h(k, 1, MAPA) % ANCHO, h(k, 2, MAPA) % ALTO)
		k += 1
		if not _libre_para_objeto(c) or por_celda.has(c): continue
		if Vector2(c).distance_to(Vector2(ENTRADA)) < 14.0 or Vector2(c).distance_to(Vector2(CLARO)) < 8.0: continue
		spawns_slime.append(c)

static func clave(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]

func tipo(c: Vector2i) -> int:
	return T.AGUA if not Rect2i(0, 0, ANCHO, ALTO).has_point(c) else celdas[c.y * ANCHO + c.x]

func objeto_presente(c: Vector2i) -> String:
	var id: String = por_celda.get(c, "")
	return "" if id == "" or estado.rotos.has(id) else id

func constr_en(c: Vector2i) -> Dictionary:
	return estado.constr.get(clave(c), {})

func _reconstruir() -> void:
	_bloq.resize(ANCHO * ALTO)
	for y in ALTO:
		for x in ANCHO:
			var c := Vector2i(x, y)
			var t := celdas[y * ANCHO + x]
			var b := t == T.AGUA or t == T.PARED or t == T.MURO_RUINA
			if not b:
				var id := objeto_presente(c)
				if id != "":
					var ot: String = objetos[id].t
					b = ot == "cofre_fijo" or ot in DECO or C.OBJETOS[ot].bloquea
			_bloq[y * ANCHO + x] = 1 if b else 0
	for k in estado.constr:
		var p: PackedStringArray = k.split(",")
		if C.CONSTR[estado.constr[k].t].bloquea: _bloq[int(p[1]) * ANCHO + int(p[0])] = 1
	_bloq_v = version

func bloquea(c: Vector2i) -> bool:
	if not Rect2i(0, 0, ANCHO, ALTO).has_point(c): return true
	if _bloq_v != version: _reconstruir()
	return _bloq[c.y * ANCHO + c.x] == 1

func cambiar() -> void:
	version += 1

func romper(id: String, hora: int) -> void:
	estado.rotos[id] = hora
	estado.golpes.erase(id)
	cambiar()

# Regenera objetos cuyo plazo venció, salvo si la celda está ocupada por una construcción o por alguien.
func regenerar(hora: int, ocupada: Callable) -> int:
	var n := 0
	for id in estado.rotos.keys():
		var r: int = C.OBJETOS[objetos[id].t].regen_h
		if r > 0 and hora - estado.rotos[id] >= r * 60:
			var c: Vector2i = objetos[id].c
			if constr_en(c).is_empty() and not ocupada.call(c):
				estado.rotos.erase(id)
				n += 1
	if n > 0: cambiar()
	return n

# Reglas estáticas de colocación (no incluye actores ni alcanzabilidad: las evalúa Juego).
func puede_poner(c: Vector2i) -> String:
	if not Rect2i(0, 0, ANCHO, ALTO).has_point(c): return "fuera del mapa"
	var t := tipo(c)
	if t != T.PASTO and t != T.CAMINO and t != T.SUELO: return "terreno no construible"
	if objeto_presente(c) != "": return "ocupado por un objeto"
	if not constr_en(c).is_empty(): return "ya hay una construcción"
	return ""

# propia: la puso un jugador (no es del mapa de autor). dueno: id del jugador que puede retirarla.
func poner(c: Vector2i, pieza: String, propia: bool, dueno: String = "") -> void:
	var cs := {"t": pieza, "propia": propia}
	if dueno != "": cs["dueno"] = dueno
	estado.constr[clave(c)] = cs
	cambiar()

func quitar(c: Vector2i) -> void:
	estado.constr.erase(clave(c))
	cambiar()

static func pies_de_celda(c: Vector2i) -> Vector2:
	return Vector2(c.x * P.CELDA + P.CELDA / 2.0, c.y * P.CELDA + 12)

static func celda_de(pies: Vector2) -> Vector2i:
	return Vector2i((pies - Vector2(0, 1)) / P.CELDA)   # -1 px: el borde inferior pertenece a la celda de arriba

func caja_libre(pies: Vector2, medio: Vector2 = P.PIES) -> bool:
	var a := Vector2i(((pies - Vector2(medio.x / 2, medio.y)) / P.CELDA).floor())
	var b := Vector2i(((pies + Vector2(medio.x / 2, 0) - Vector2(0.001, 0.001)) / P.CELDA).floor())
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			if bloquea(Vector2i(x, y)): return false
	return true

# Ejes por separado: permite deslizar contra paredes y rodear objetos.
func mover(pies: Vector2, d: Vector2, medio: Vector2 = P.PIES) -> Vector2:
	var p := pies
	if d.x != 0.0 and caja_libre(p + Vector2(d.x, 0), medio): p.x += d.x
	if d.y != 0.0 and caja_libre(p + Vector2(0, d.y), medio): p.y += d.y
	return p

func alcanzables(desde: Vector2i = ENTRADA) -> Dictionary:
	var vistas := {desde: true}
	var cola := [desde]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if not vistas.has(n) and not bloquea(n):
				vistas[n] = true
				cola.append(n)
	return vistas

# BFS 4-vecinos. Termina al llegar a una celda que cumple meta. [] si no hay ruta; [desde] si ya cumple.
func camino(desde: Vector2i, meta: Callable) -> Array:
	if meta.call(desde): return [desde]
	var prev := {desde: desde}
	var cola := [desde]
	var i := 0
	while i < cola.size():
		var c: Vector2i = cola[i]
		i += 1
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if prev.has(n) or bloquea(n): continue
			prev[n] = c
			if meta.call(n):
				var ruta := [n]
				while ruta[0] != desde: ruta.push_front(prev[ruta[0]])
				return ruta
			cola.append(n)
	return []

func es_adyacente(c: Vector2i, objetivo: Vector2i) -> bool:
	return absi(c.x - objetivo.x) + absi(c.y - objetivo.y) == 1

# Inicio por semilla: exterior alcanzable, 3x3 libre y lejos de enemigos y jefes (sin encuentro inevitable).
func punto_inicio(semilla: int) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = h(semilla, 7, 11)
	var cand: Array = []
	for c in alcanzables():
		var t := tipo(c)
		if t != T.PASTO and t != T.CAMINO: continue
		var ok := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if bloquea(c + Vector2i(dx, dy)): ok = false
		if not ok: continue
		for s in spawns_slime: if Vector2(c).distance_to(Vector2(s)) < 12.0: ok = false
		if Vector2(c).distance_to(Vector2(CLARO)) < 14.0 or Vector2(c).distance_to(Vector2(SPAWN_GUARDIAN)) < 14.0: ok = false
		if ok: cand.append(c)
	cand.sort_custom(func(a, b): return a.y * ANCHO + a.x < b.y * ANCHO + b.x)
	return cand[rng.randi() % cand.size()]

# Cuatro direcciones sin diagonales: conserva la actual si sigue pulsada.
static func dir_cardinal(sostenidas: Array, previa: Vector2i) -> Vector2i:
	if sostenidas.is_empty(): return Vector2i.ZERO
	return previa if previa in sostenidas else sostenidas[0]
