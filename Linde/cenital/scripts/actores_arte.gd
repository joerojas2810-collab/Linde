extends RefCounted
## Arte de enemigos y efectos de combate (E03_v001). Solo presentación: no cambia daño, tiempos, colisión ni recompensas.
## Atlas de enemigos: 9 columnas (reposo, pasoA, pasoB, aviso, impacto, daño, recuperación, derrotaA, derrotaB) × 4 filas
## (sur, este, norte, oeste). Efectos: 4 cuadros de 32×32, pivote en el centro del evento.
## Los eventos (daño, muerte, recolección) se deducen de cambios confirmados entre pasos; en clientes de red
## (sin identidad estable por enemigo) se dibuja el estado sin reacciones.
const RAIZ := "res://arte/actores/"
const ENEMIGOS := {
	"slime": {"archivo": "slime.png", "celda": 32, "pivote": Vector2(16, 29)},
	"guardian": {"archivo": "guardian.png", "celda": 48, "pivote": Vector2(24, 45)},
	"ciervo": {"archivo": "ciervo.png", "celda": 48, "pivote": Vector2(24, 45)},
}
const COL := {"reposo": 0, "paso_a": 1, "paso_b": 2, "aviso": 3, "impacto": 4, "dano": 5, "recup": 6, "der_a": 7, "der_b": 8}
const MARCHA := [1, 0, 2, 0]
const FX := {"impacto": {"archivo": "E03_fx_impacto.png", "dur": 0.16}, "dano": {"archivo": "E03_fx_dano.png", "dur": 0.20}, "recoleccion": {"archivo": "E03_fx_recoleccion.png", "dur": 0.28}}
const DUR_DANO := 0.12
const DUR_DERROTA := 0.24
const MARCADOR := Color(1, 0, 1, 0.85)

var texturas: Dictionary = {}
var faltantes: Dictionary = {}
var seguidos: Dictionary = {}      # clave de enemigo -> {pos, hp, dano_t, tipo, dir, tam, vivo}
var residuos: Array = []           # {tipo, pos, dir, t}
var efectos: Array = []            # {tipo, pos, t}
var rotos_vistos: Dictionary = {}
var hp_pj := -1
var pos_npc: Dictionary = {}       # id -> última posición (para orientar y animar al habitante)

func tex(f: String) -> Texture2D:
	if texturas.has(f): return texturas[f]
	var t: Texture2D = null
	if ResourceLoader.exists(RAIZ + f): t = load(RAIZ + f) as Texture2D
	if t == null and not faltantes.has(f):
		faltantes[f] = true
		push_error("Arte faltante: " + RAIZ + f)
	texturas[f] = t
	return t

static func cardinal(d: Vector2) -> Vector2i:
	if absf(d.x) > absf(d.y): return Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y >= 0 else Vector2i.UP

static func fila(d: Vector2i) -> int:
	return {Vector2i.DOWN: 0, Vector2i.RIGHT: 1, Vector2i.UP: 2, Vector2i.LEFT: 3}.get(d, 0)

static func clave(e: Dictionary) -> String:
	var h = e.get("home")
	return "" if h == null else "%s@%d,%d" % [e.tipo, int(h.x), int(h.y)]

## Llamar una vez por cuadro de proceso. `cliente` = juego unido a un anfitrión (sin identidad estable de enemigos).
func actualizar(delta: float, enemigos: Array, hp_local: int, centro_pj: Vector2, mundo, cliente: bool) -> void:
	for f in efectos: f.t += delta
	efectos = efectos.filter(func(f): return f.t < FX[f.tipo].dur)
	for r in residuos: r.t += delta
	residuos = residuos.filter(func(r): return r.t < DUR_DERROTA)
	if hp_pj >= 0 and hp_local < hp_pj: _fx("dano", centro_pj)
	hp_pj = hp_local
	for id in mundo.estado.rotos:
		if not rotos_vistos.has(id) and mundo.objetos.has(id):
			_fx("recoleccion", Vector2(mundo.objetos[id].c) * 16.0 + Vector2(8, 8))
		rotos_vistos[id] = true
	if cliente:
		seguidos.clear()
		return
	var presentes := {}
	for e in enemigos:
		var k := clave(e)
		if k == "": continue
		presentes[k] = true
		var s: Dictionary = seguidos.get(k, {"hp": e.hp, "dano_t": 0.0, "mov": false, "pos": e.pos})
		if e.hp < s.hp:
			s.dano_t = DUR_DANO
			_fx("impacto", e.pos - Vector2(0, e.tam / 2.0))
		s.dano_t = maxf(0.0, s.dano_t - delta)
		s.mov = e.pos.distance_to(s.pos) > 0.05
		s.hp = e.hp
		s.pos = e.pos
		s.tipo = e.tipo
		s.dir = e.dir
		s.tam = e.tam
		seguidos[k] = s
	for k in seguidos.keys():
		if presentes.has(k): continue
		var s: Dictionary = seguidos[k]
		residuos.append({"tipo": s.tipo, "pos": s.pos, "dir": s.dir, "t": 0.0})
		_fx("impacto", s.pos - Vector2(0, s.tam / 2.0))
		seguidos.erase(k)

func _fx(tipo: String, pos: Vector2) -> void:
	efectos.append({"tipo": tipo, "pos": pos, "t": 0.0})

func _celda(ci: CanvasItem, tipo: String, pos: Vector2, dir: Vector2, col: int, tinte: Color = Color.WHITE) -> void:
	var d: Dictionary = ENEMIGOS[tipo]
	var c: int = d.celda
	var t := tex(d.archivo)
	var destino := Rect2((pos - d.pivote).round(), Vector2(c, c))
	if t == null: ci.draw_rect(destino, MARCADOR); return
	ci.draw_texture_rect_region(t, destino, Rect2(col * c, fila(cardinal(dir)) * c, c, c), tinte)

func enemigo(ci: CanvasItem, e: Dictionary, tiempo: float) -> void:
	var s: Dictionary = seguidos.get(clave(e), {})
	var col: int = COL.reposo
	match e.est:
		"aviso": col = COL.aviso
		"activo": col = COL.impacto
		"rec": col = COL.recup
		_:
			if s.get("dano_t", 0.0) > 0.0: col = COL.dano
			elif s.get("mov", false): col = MARCHA[int(tiempo / 0.15) % 4]
	_celda(ci, e.tipo, e.pos, e.dir, col)

func residuo(ci: CanvasItem) -> void:
	for r in residuos: _celda(ci, r.tipo, r.pos, r.dir, COL.der_a if r.t < DUR_DERROTA / 2.0 else COL.der_b)

func efectos_dibujar(ci: CanvasItem) -> void:
	for f in efectos:
		var d: Dictionary = FX[f.tipo]
		var t := tex(d.archivo)
		var r := Rect2((f.pos - Vector2(16, 16)).round(), Vector2(32, 32))
		if t == null: ci.draw_rect(r, MARCADOR); continue
		ci.draw_texture_rect_region(t, r, Rect2(mini(3, int(f.t / d.dur * 4.0)) * 32, 0, 32, 32))

## Orientación y marcha del habitante a partir de su desplazamiento real.
func npc_estado(id: String, pos: Vector2) -> Dictionary:
	var prev: Vector2 = pos_npc.get(id, pos)
	var mueve := prev.distance_to(pos) > 0.05
	var dir: Vector2i = cardinal(pos - prev) if mueve else pos_npc.get(id + "#dir", Vector2i.DOWN)
	pos_npc[id] = pos
	pos_npc[id + "#dir"] = dir
	return {"mueve": mueve, "dir": dir}
