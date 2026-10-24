extends RefCounted
# Habitantes: necesidades -> actividad deseada -> ruta (BFS) -> ejecución. Simulación local mientras corre el juego.
# Energía 0..100: -4/h despierta, +12/h durmiendo (PROVISIONAL, propio; no se heredan tasas de MineWorld).
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Mundo = preload("res://scripts/mundo.gd")
const NPCS := {"maren": {"n": "Maren", "taller": Vector2i(28, 20), "plaza": Vector2i(34, 25), "cama": Mundo.CAMA_MAREN, "vel": 24.0}}
const GASTO_H := 4.0
const RECUPERA_H := 12.0
const UMBRAL_SUENO := 15.0

var j
var rutas := {}

func _init(juego) -> void:
	j = juego

func nuevo(id: String) -> Dictionary:
	var p := Mundo.pies_de_celda(NPCS[id].taller)
	return {"pos": [p.x, p.y], "energia": 80.0, "act": "taller"}   # compartido; la relación es por jugador (d.jugadores[id].relacion)

func restaurar() -> void:
	for id in NPCS:
		if not j.d.npcs.has(id): j.d.npcs[id] = nuevo(id)
		rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}

func pos(id: String) -> Vector2:
	var a: Array = j.d.npcs[id].pos
	return Vector2(a[0], a[1])

func deseada(id: String) -> String:
	var h: float = j.hora_dia()
	if j.d.npcs[id].energia < UMBRAL_SUENO or h >= 20.0 or h < 6.0: return "dormir"
	if h >= 12.0 and h < 14.0: return "plaza"
	return "taller"

func cama_existe(id: String) -> bool:
	return j.mundo.constr_en(NPCS[id].cama).get("t", "") == "cama"

func _meta(id: String, act: String) -> Callable:
	if act == "dormir":
		var cama: Vector2i = NPCS[id].cama
		return func(c): return j.mundo.es_adyacente(c, cama)
	var t: Vector2i = NPCS[id][act]
	return func(c): return c == t

func paso(dt: float) -> void:
	var horas: float = dt * C.MIN_POR_SEG / 60.0
	for id in NPCS:
		var n: Dictionary = j.d.npcs[id]
		var r: Dictionary = rutas[id]
		var act := deseada(id)
		if act == "dormir" and not cama_existe(id):
			n.act = "sin_cama"
			n.energia = maxf(0.0, n.energia - GASTO_H * horas)
			continue
		var p := pos(id)
		var c := Mundo.celda_de(p)
		var meta := _meta(id, act)
		if meta.call(c):
			n.act = act
			n.energia = clampf(n.energia + (RECUPERA_H if act == "dormir" else -GASTO_H) * horas, 0.0, 100.0)
			r.ruta = []
			continue
		n.energia = clampf(n.energia - GASTO_H * horas, 0.0, 100.0)
		if r.act != act or r.v != j.mundo.version:
			r.ruta = j.mundo.camino(c, meta)
			r.act = act
			r.v = j.mundo.version
			r.i = 1
			r.fallo = r.ruta.is_empty()
		if r.fallo or r.i >= r.ruta.size():
			n.act = "bloqueado"
			continue
		n.act = "camina"
		var dest := Mundo.pies_de_celda(r.ruta[r.i])
		var paso_px: float = NPCS[id].vel * dt
		if p.distance_to(dest) <= paso_px:
			p = dest
			r.i += 1
		else:
			p += (dest - p).normalized() * paso_px
		n.pos = [p.x, p.y]

# Tras dormir el jugador: coloca a cada habitante según su rutina actual (no se simula el intervalo).
func resincronizar() -> void:
	for id in NPCS:
		var act := deseada(id)
		var c: Vector2i = NPCS[id][act] if act != "dormir" else Vector2i(30, 19)
		var p := Mundo.pies_de_celda(c)
		j.d.npcs[id].pos = [p.x, p.y]
		j.d.npcs[id].energia = maxf(j.d.npcs[id].energia, 60.0)
		rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}
