extends RefCounted
# Combate en tiempo real PROVISIONAL (A01 pendiente: no es una decisión del usuario).
# Todo ataque tiene señal previa (aviso), impacto evaluado en un instante y recuperación.
# Varios jugadores: cada uno tiene su propio ciclo de ataque (pjs[id]); cada enemigo persigue al jugador más cercano
# (objetivo e.obj) y su golpe se evalúa contra ese objetivo. El botín va a quien da el golpe final.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Mundo = preload("res://scripts/mundo.gd")
const JEFES := ["guardian", "ciervo"]
const INVULN_S := 0.6
const KNOCKBACK_PX := 8.0

var j
var enemigos: Array = []
var pjs := {}           # id -> {est: libre|aviso|activo|rec, t, inv_t, dir}: sesión, no se guarda

# Compatibilidad: ciclo de ataque del jugador local.
var est: String:
	get: return ataque(P.LOCAL).est
	set(v): ataque(P.LOCAL).est = v
var t: float:
	get: return ataque(P.LOCAL).t
	set(v): ataque(P.LOCAL).t = v
var inv_t: float:
	get: return ataque(P.LOCAL).inv_t
	set(v): ataque(P.LOCAL).inv_t = v
var dir: Vector2i:
	get: return ataque(P.LOCAL).dir
	set(v): ataque(P.LOCAL).dir = v

func _init(juego) -> void:
	j = juego

func ataque(id: String) -> Dictionary:
	if not pjs.has(id): pjs[id] = {"est": "libre", "t": 0.0, "inv_t": 0.0, "dir": Vector2i.DOWN}
	return pjs[id]

func centro_pj(id: String = P.LOCAL) -> Vector2:
	return j.pies_de(id) - Vector2(0, 6)

static func centro(e: Dictionary) -> Vector2:
	return e.pos - Vector2(0, e.tam / 2.0)

func reiniciar() -> void:
	enemigos.clear()
	for s in j.mundo.spawns_slime: enemigos.append(_nuevo("slime", Mundo.pies_de_celda(s)))
	for id in JEFES: _aparecer_si_toca(id)

func _nuevo(tipo: String, p: Vector2) -> Dictionary:
	return {"tipo": tipo, "pos": p, "home": p, "hp": C.ENEMIGOS[tipo].hp, "est": "idle", "t": 0.0, "atq": "",
		"dir": Vector2.DOWN, "fase": 0, "n_atq": 0, "tam": C.ENEMIGOS[tipo].tam, "obj": ""}

func _vivo(id: String) -> bool:
	for e in enemigos: if e.tipo == id and e.est != "muerto": return true
	return false

# Jefe de capítulo: no reaparece. Jefe de mundo: reaparece reaparece_h horas de juego tras caer.
func _aparecer_si_toca(id: String) -> void:
	if _vivo(id): return
	var st: Dictionary = j.d.jefes.get(id, {})
	if st.get("derrotado", false):
		var r: int = C.ENEMIGOS[id].reaparece_h
		if r <= 0 or j.d.min - st.hora < r * 60: return
		st.derrotado = false
	var c: Vector2i = Mundo.SPAWN_GUARDIAN if id == "guardian" else Mundo.CLARO
	enemigos.append(_nuevo(id, Mundo.pies_de_celda(c)))

func revisar_reaparicion() -> void:
	for id in JEFES: _aparecer_si_toca(id)

# Jugador derrotado (con más jugadores en el mundo): quien lo perseguía vuelve a reposo; el resto sigue igual.
func olvidar(id: String) -> void:
	for e in enemigos:
		if e.obj == id:
			e.obj = ""
			if e.est != "muerto": e.est = "idle"

func hay_enemigo_cerca(r: float, id: String = P.LOCAL) -> bool:
	var cp := centro_pj(id)
	for e in enemigos:
		if e.est != "muerto" and centro(e).distance_to(cp) <= r + e.tam / 2.0: return true
	return false

func atacar(d: Vector2i, id: String = P.LOCAL) -> bool:
	var a := ataque(id)
	if a.est != "libre": return false
	a.dir = d
	a.est = "aviso"
	a.t = C.PJ_ATAQUE.aviso
	return true

func paso(dt: float) -> void:
	for id in j.rt:
		var a := ataque(id)
		a.inv_t = maxf(0.0, a.inv_t - dt)
		if a.est == "libre": continue
		a.t -= dt
		if a.t <= 0.0:
			match a.est:
				"aviso":
					a.est = "activo"
					a.t = C.PJ_ATAQUE.activo
					_golpe_pj(id)
				"activo":
					a.est = "rec"
					a.t = C.PJ_ATAQUE.rec
				"rec": a.est = "libre"
	for e in enemigos: _paso_enemigo(e, dt)
	enemigos = enemigos.filter(func(e): return e.est != "muerto")

func zona_golpe(id: String = P.LOCAL) -> Rect2:
	var a: Dictionary = C.PJ_ATAQUE
	var dd: Vector2i = ataque(id).dir
	var cen: Vector2 = centro_pj(id) + Vector2(dd) * (a.alcance / 2.0 + 4.0)
	var tam := Vector2(a.alcance, a.ancho) if dd.x != 0 else Vector2(a.ancho, a.alcance)
	return Rect2(cen - tam / 2.0, tam)

func _golpe_pj(id: String) -> void:
	var r := zona_golpe(id)
	var dmg: int = j.stats(id).dmg
	for e in enemigos:
		if e.est == "muerto": continue
		var ec := centro(e)
		var cp := Vector2(clampf(ec.x, r.position.x, r.end.x), clampf(ec.y, r.position.y, r.end.y))
		if cp.distance_to(ec) <= e.tam / 2.0: _danar(e, dmg, id)

# id = jugador que golpea; si el golpe mata, el botín es suyo.
func _danar(e: Dictionary, dmg: int, id: String = P.LOCAL) -> void:
	if e.est == "muerto": return
	e.hp -= dmg
	j.autonomia.desarrollo.registrar(j.actor_desarrollo(id),"combate",{str(j.jug(id).equipo.get("arma","")):1})
	if not C.ENEMIGOS[e.tipo].has("fases"):
		e.pos = _mover(e, Vector2(ataque(id).dir) * KNOCKBACK_PX)
	if e.hp <= 0: _morir(e, id)

func _morir(e: Dictionary, id: String) -> void:
	e.est = "muerto"
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	j.ganar_xp(def.xp, id)
	if def.has("drops"): j.dar_o_pendiente(def.drops, id)
	j.caida_equipo(e.tipo, id)          # piezas de familias de zona (tirada propia de quien remata)
	if def.has("fases"): j.jefe_derrotado(e.tipo, id)

func _mover(e: Dictionary, d: Vector2) -> Vector2:
	return j.mundo.mover(e.pos, d, Vector2(e.tam, e.tam * 0.6))

func info_ataque(e: Dictionary, nombre: String) -> Dictionary:
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	if nombre == "golpe":
		return {"aviso": def.aviso, "rec": def.rec, "dmg": def.dmg, "forma": "circulo", "radio": def.radio, "rango": def.radio * 0.9}
	var a: Dictionary = C.ATAQUES[nombre].duplicate()
	a["rango"] = a.largo * 0.8 if a.forma == "linea" else a.radio * 0.8
	return a

func _siguiente(e: Dictionary) -> String:
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	if not def.has("fases"): return "golpe"
	var l: Array = def.fases[e.fase].ataques
	return l[e.n_atq % l.size()]

# Jugador presente (con sesión) más cercano al enemigo: [id, distancia] (["", INF] si no hay nadie).
func _mas_cercano(e: Dictionary) -> Array:
	var mejor: Array = ["", INF]
	var ce := centro(e)
	for id in j.rt:
		var dist := ce.distance_to(centro_pj(id))
		if dist < mejor[1]: mejor = [id, dist]
	return mejor

func _paso_enemigo(e: Dictionary, dt: float) -> void:
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	var jefe: bool = def.has("fases")
	var cerca: Array = _mas_cercano(e)
	var dist: float = cerca[1]
	if jefe:
		var f: float = float(e.hp) / def.hp
		var idx := 0
		for i in def.fases.size(): if f <= def.fases[i].desde: idx = i
		if idx != e.fase:
			e.fase = idx
			j.aviso_todos("¡%s cambia de postura!" % def.n)
	match e.est:
		"idle":
			if dist <= def.vision:
				e.est = "persigue"
				e.obj = cerca[0]
			elif e.pos.distance_to(e.home) > 2.0: e.pos = _mover(e, (e.home - e.pos).normalized() * def.vel * dt)
			if jefe and e.hp < def.hp and dist > def.vision * 2.0: e.hp = def.hp   # reinicio de encuentro
		"persigue":
			if dist > def.vision * 2.0:
				e.est = "idle"
				e.obj = ""
				return
			e.obj = cerca[0]
			var cp := centro_pj(e.obj)
			var nombre := _siguiente(e)
			var info := info_ataque(e, nombre)
			if dist <= info.rango:
				e.est = "aviso"
				e.atq = nombre
				e.t = info.aviso
				e.dir = (cp - centro(e)).normalized()
				e.n_atq += 1
			else:
				e.pos = _mover(e, (cp - centro(e)).normalized() * def.vel * dt)
		"aviso":
			e.t -= dt
			if e.t <= 0.0:
				var info := info_ataque(e, e.atq)
				_resolver(e, info)
				e.est = "recupera"
				e.t = info.rec
		"recupera":
			e.t -= dt
			if e.t <= 0.0: e.est = "persigue"

# El golpe se evalúa contra el objetivo fijado al empezar el aviso (ponytail: solo el objetivo, aunque otro
# jugador esté dentro del área; daño en área a todos cuando se diseñe el combate en grupo).
func _resolver(e: Dictionary, info: Dictionary) -> void:
	var obj: String = e.obj
	var hay: bool = j.rt.has(obj)
	var cp := centro_pj(obj) if hay else Vector2(INF, INF)
	var golpea := false
	if info.forma == "circulo":
		golpea = centro(e).distance_to(cp) <= info.radio + 6.0
	else:
		var a := centro(e)
		var restante: float = info.avance
		while restante > 0.0:
			var antes: Vector2 = e.pos
			e.pos = _mover(e, e.dir * 2.0)
			if e.pos == antes: break
			restante -= 2.0
		golpea = hay and _dist_segmento(cp, a, centro(e)) <= info.ancho / 2.0 + 6.0
	if golpea and hay and ataque(obj).inv_t <= 0.0:
		ataque(obj).inv_t = INVULN_S
		j.danar_pj(info.dmg, obj)

static func _dist_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 == 0.0: return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0))
