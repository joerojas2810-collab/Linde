extends RefCounted
# Autoridad única del estado: inventario, mundo, misiones, progresión. La UI solo pide acciones y muestra resultados.
# Estado persistente = d (JSON). Todo lo demás (enemigos, rutas) es derivado y se reconstruye al cargar.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Guard = preload("res://scripts/guardado.gd")
const Hab = preload("res://scripts/habitantes.gd")
const Comb = preload("res://scripts/combate.gd")
const CAP_COFRE := 30
const ALCANCE_ESTACION := 2     # celdas (Chebyshev)
const ALCANCE_NPC := 32.0       # px

var d := {}
var mundo := Mundo.new()
var habitantes
var combate
var msgs: Array = []
var pies := Vector2.ZERO
var mira := Vector2i.DOWN
var cd_obj := 0.0
var _acum := 0.0
var _seg := 0.0

static func nueva(semilla: int, nombre: String, look: Array, origen: String = "viajero"):
	var j = new()
	j.d = {"semilla": semilla}
	var p := Mundo.pies_de_celda(j.mundo.punto_inicio(semilla))
	var rt: RandomNumberGenerator = j._rng("botin", "tesoro_cantera")
	var cont := {"gema": 1}
	if rt.randf() < 0.5: cont["lingote"] = 1
	if rt.randf() < 0.5: cont["mena"] = 3
	j.d = {"formato": Guard.FORMATO, "contenido": 1, "gen": 1, "semilla": semilla,
		"pj": {"nombre": nombre.strip_edges().substr(0, 16) if nombre.strip_edges() != "" else "Viajero", "look": look.duplicate(),
			"origen": origen, "pos": [p.x, p.y], "hp": C.HP_BASE, "cama": [], "inicio": [p.x, p.y]},
		"inv": {}, "equipo": {"casco": "", "coraza": "", "escudo": ""}, "hab": [], "xp": 0, "min": 6 * 60, "misiones": {}, "eventos": {}, "recompensas": [],
		"cofres": {"tesoro_cantera": {"inv": cont, "abierto": false}}, "mundo": j.mundo.estado, "jefes": {}, "npcs": {},
		"pendientes": {}}
	j._arrancar()
	return j

static func cargar(ruta: String):
	var r := Guard.cargar(ruta)
	if r.d.is_empty(): return null
	var j = new()
	j.d = _enteros(r.d)
	if not j.d.has("equipo"): j.d["equipo"] = {"casco": "", "coraza": "", "escudo": ""}   # partidas anteriores
	j.mundo.estado = j.d.mundo
	j.mundo.cambiar()
	j._arrancar()
	j.aviso("Partida cargada (%s)." % r.origen)
	return j

# JSON devuelve todo como float; los enteros vuelven a ser enteros.
static func _enteros(v):
	match typeof(v):
		TYPE_FLOAT: return int(v) if v == floorf(v) else v
		TYPE_DICTIONARY:
			for k in v: v[k] = _enteros(v[k])
		TYPE_ARRAY:
			for i in v.size(): v[i] = _enteros(v[i])
	return v

func _arrancar() -> void:
	mundo.estado = d.mundo
	mundo.cambiar()
	pies = Vector2(d.pj.pos[0], d.pj.pos[1])
	habitantes = Hab.new(self)
	habitantes.restaurar()
	combate = Comb.new(self)
	combate.reiniciar()
	evaluar_misiones()

func guardar(ruta: String) -> bool:
	d.pj.pos = [pies.x, pies.y]
	return Guard.guardar(ruta, d)

func aviso(t: String) -> void:
	msgs.append(t)
	if msgs.size() > 6: msgs.pop_front()

func _rng(nombre: String, clave: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = Mundo.h(int(d.semilla), nombre.hash() & 0xffffff, clave.hash() & 0xffffff)
	return r

func _ok(msg: String = "") -> Dictionary:
	if msg != "": aviso(msg)
	return {"ok": true, "msg": msg}

func _no(msg: String) -> Dictionary:
	aviso(msg)
	return {"ok": false, "msg": msg}

# ---------- tiempo ----------
func hora_dia() -> float:
	return fmod(d.min / 60.0, 24.0)

func dia() -> int:
	return floori(d.min / 1440.0) + 1

func tick(dt: float) -> void:
	_acum += dt * C.MIN_POR_SEG
	while _acum >= 1.0:
		_acum -= 1.0
		d.min += 1
		if d.min % 60 == 0: _hora_en_punto()
	cd_obj = maxf(0.0, cd_obj - dt)
	habitantes.paso(dt)
	combate.paso(dt)
	_seg += dt
	if _seg >= 0.5:
		_seg = 0.0
		_chequeos()

func _hora_en_punto() -> void:
	mundo.regenerar(d.min, ocupada)
	combate.revisar_reaparicion()

func _chequeos() -> void:
	if Mundo.ARENA.has_point(Mundo.celda_de(pies)): d.eventos["visito_ruinas"] = true
	if not d.pendientes.is_empty() and Inv.anadir(d.inv, d.pendientes, stats().slots):
		aviso("Recibes lo pendiente.")
		d.pendientes = {}
	evaluar_misiones()

# ---------- estadísticas derivadas (se recalculan, nunca se acumulan) ----------
func stats() -> Dictionary:
	var s := {"hp": C.HP_BASE, "dmg": C.DMG_BASE, "vel": 1.0, "slots": C.MAX_SLOTS_BASE, "golpes_menos": 0, "def": 0}
	for h in d.hab:
		for k in C.HAB[h].efe: s[k] += C.HAB[h].efe[k]
	var mejor := 0
	for it in d.inv: mejor = maxi(mejor, C.ITEMS[it].get("dmg", 0))
	s.dmg += mejor
	for r in d.equipo:
		if d.equipo[r] != "": s.def += C.ITEMS[d.equipo[r]].get("def", 0)   # PROVISIONAL: suma plana, derivada
	return s

func nivel() -> int:
	return C.nivel_de(d.xp)

func puntos_libres() -> int:
	var g := 0
	for h in d.hab: g += C.HAB[h].coste
	return nivel() - 1 - g

func ganar_xp(n: int) -> void:
	var antes := nivel()
	d.xp += n
	if nivel() > antes: aviso("¡Nivel %d! Tienes %d punto(s) de habilidad." % [nivel(), puntos_libres()])

func aprender(id: String) -> Dictionary:
	if not C.HAB.has(id): return _no("Habilidad desconocida")
	if d.hab.has(id): return _no("Ya la tienes")
	var h: Dictionary = C.HAB[id]
	if nivel() < h.niv: return _no("Requiere nivel %d" % h.niv)
	for r in h.req: if not d.hab.has(r): return _no("Requiere %s" % C.HAB[r].n)
	if puntos_libres() < h.coste: return _no("Faltan puntos")
	d.hab.append(id)
	return _ok("Aprendes %s" % h.n)

func danar_pj(n: int) -> void:
	d.pj.hp -= maxi(1, n - int(stats().def))   # PROVISIONAL: resta plana, mínimo 1
	if d.pj.hp <= 0: _derrota()

# A01 provisional: sin pérdida de objetos; vuelves a tu cama (o al inicio) con la mitad de vida; el encuentro se reinicia.
func _derrota() -> void:
	var c: Array = d.pj.cama if not d.pj.cama.is_empty() else d.pj.inicio
	pies = Vector2(c[0], c[1])
	d.pj.hp = int(stats().hp / 2.0)
	combate.reiniciar()
	combate.est = "libre"
	aviso("Caes derrotado. Despiertas a salvo.")

# ---------- acciones ----------
func mover_pj(dir: Vector2i, dt: float) -> void:
	if dir == Vector2i.ZERO or combate.est == "aviso" or combate.est == "activo": return
	mira = dir
	pies = mundo.mover(pies, Vector2(dir) * P.VELOCIDAD * stats().vel * dt)

func accion() -> Dictionary:
	var c := Mundo.celda_de(pies) + mira
	if not combate.hay_enemigo_cerca(24.0):
		for cc in [c, Mundo.celda_de(pies)]:
			var id := mundo.objeto_presente(cc)
			if id != "" and mundo.objetos[id].t != "cofre_fijo" and not mundo.objetos[id].t in Mundo.DECO:
				if cd_obj > 0.0: return {"ok": false, "msg": ""}
				cd_obj = 0.3
				return golpear_objeto(cc)
	combate.atacar(mira)
	return _ok()

func golpear_objeto(c: Vector2i) -> Dictionary:
	var id := mundo.objeto_presente(c)
	if id == "": return _no("No hay nada que golpear")
	var ot: String = mundo.objetos[id].t
	if ot == "cofre_fijo": return _no("Se abre con E")
	if ot in Mundo.DECO: return _no("No se puede romper")
	var def: Dictionary = C.OBJETOS[ot]
	var tags := {}
	for it in d.inv: if C.ITEMS[it].has("tag"): tags[C.ITEMS[it].tag] = true
	var necesarios := 9999
	for tag in def.golpes: if tag == "" or tags.has(tag): necesarios = mini(necesarios, def.golpes[tag])
	if necesarios == 9999: return _no("%s: necesitas una herramienta (%s)" % [def.n, ", ".join(def.golpes.keys())])
	necesarios = maxi(1, necesarios - stats().golpes_menos)
	var g: int = d.mundo.golpes.get(id, 0) + 1
	if g < necesarios:
		d.mundo.golpes[id] = g
		return _ok("%s %d/%d" % [def.n, g, necesarios])
	var drops: Dictionary = def.drops.duplicate()
	var rng := _rng("botin", "%s:%d" % [id, d.min / 60])
	for p in def.prob: if rng.randf() < p.p: drops[p.item] = drops.get(p.item, 0) + p.q
	if not Inv.anadir(d.inv, drops, stats().slots):
		d.mundo.golpes[id] = necesarios - 1
		return _no("Inventario lleno: %s no se rompe" % def.n)
	mundo.romper(id, d.min)
	ganar_xp(def.xp)
	return _ok("Obtienes " + _txt_items(drops))

static func _txt_items(m: Dictionary) -> String:
	var l: Array = []
	for k in m: l.append("%d %s" % [m[k], C.ITEMS[k].n])
	return ", ".join(l)

func estacion_cerca(est: String) -> bool:
	if est == "": return true
	var c := Mundo.celda_de(pies)
	for k in d.mundo.constr:
		if C.CONSTR[d.mundo.constr[k].t].get("est", "") != est: continue
		var p: PackedStringArray = k.split(",")
		if maxi(absi(int(p[0]) - c.x), absi(int(p[1]) - c.y)) <= ALCANCE_ESTACION: return true
	return false

func fabricar(id: String) -> Dictionary:
	if not C.RECETAS.has(id): return _no("Receta desconocida")
	var r: Dictionary = C.RECETAS[id]
	if r.hab != "" and not d.hab.has(r.hab): return _no("Requiere habilidad %s" % C.HAB[r.hab].n)
	if r.herr != "" and d.inv.get(r.herr, 0) < 1: return _no("Falta la herramienta %s" % C.ITEMS[r.herr].n)
	if not estacion_cerca(r.est): return _no("Necesitas estar junto a: %s" % r.est)
	if not Inv.tiene(d.inv, r.ent): return _no("Faltan materiales")
	if not Inv.cambiar(d.inv, r.ent, r.sal, stats().slots): return _no("Inventario lleno")
	return _ok("Fabricas %s" % r.n)

func usar(item: String) -> Dictionary:
	var it: Dictionary = C.ITEMS.get(item, {})
	if not it.has("cura"): return _no("No se puede usar")
	if d.inv.get(item, 0) < 1: return _no("No tienes")
	if d.pj.hp >= stats().hp: return _no("Vida completa")
	Inv.quitar(d.inv, {item: 1})
	d.pj.hp = mini(stats().hp, d.pj.hp + it.cura)
	return _ok("Recuperas vida")

# Equipo: atómico (Inv.cambiar valida la capacidad con el resultado final, también en intercambios).
func equipar(item: String) -> Dictionary:
	var it: Dictionary = C.ITEMS.get(item, {})
	if not it.has("equipo"): return _no("No se puede equipar")
	if d.inv.get(item, 0) < 1: return _no("No tienes")
	var r: String = it.equipo
	var prev: String = d.equipo.get(r, "")
	if not Inv.cambiar(d.inv, {item: 1}, {prev: 1} if prev != "" else {}, stats().slots): return _no("Inventario lleno")
	d.equipo[r] = item
	return _ok("Equipas %s" % it.n)

func desequipar(ranura: String) -> Dictionary:
	var item: String = d.equipo.get(ranura, "")
	if item == "": return _no("Ranura vacía")
	if not Inv.anadir(d.inv, {item: 1}, stats().slots): return _no("Inventario lleno")
	d.equipo[ranura] = ""
	return _ok("Te quitas %s" % C.ITEMS[item].n)

# Actores (jugador, habitantes, enemigos) como cajas de suelo.
func actores() -> Array:
	var l: Array = [[pies, P.PIES]]
	for id in Hab.NPCS: l.append([habitantes.pos(id), P.PIES])
	for e in combate.enemigos:
		if e.est != "muerto": l.append([e.pos, Vector2(e.tam, e.tam * 0.6)])
	return l

func ocupada(c: Vector2i) -> bool:
	var r := Rect2(Vector2(c) * P.CELDA, Vector2(P.CELDA, P.CELDA))
	for a in actores():
		if r.intersects(Rect2(a[0] - Vector2(a[1].x / 2.0, a[1].y), a[1])): return true
	return false

func construir(pieza: String, c: Vector2i) -> Dictionary:
	if not C.CONSTR.has(pieza): return _no("Pieza desconocida")
	var def: Dictionary = C.CONSTR[pieza]
	var motivo := mundo.puede_poner(c)
	if motivo != "": return _no("No se puede: " + motivo)
	if ocupada(c): return _no("Hay alguien en esa celda")
	if not Inv.tiene(d.inv, def.coste): return _no("Faltan materiales: " + _txt_items(def.coste))
	mundo.poner(c, pieza, true)
	if def.bloquea:    # no se permiten bloqueos irreversibles de lugares esenciales ni del propio jugador
		var alc := mundo.alcanzables()
		var ok := alc.has(Mundo.celda_de(pies)) or mundo.bloquea(Mundo.celda_de(pies))
		for e in Mundo.ESENCIALES: if not alc.has(e): ok = false
		if not ok:
			mundo.quitar(c)
			return _no("Eso cerraría un camino esencial")
	Inv.quitar(d.inv, def.coste)
	if def.get("cofre", false): d.cofres["c@" + Mundo.clave(c)] = {"inv": {}}
	return _ok("Construyes %s" % def.n)

func retirar(c: Vector2i) -> Dictionary:
	var k := Mundo.clave(c)
	var cs: Dictionary = mundo.constr_en(c)
	if cs.is_empty(): return _no("No hay construcción")
	if not cs.propia: return _no("Esa construcción no es tuya")
	var def: Dictionary = C.CONSTR[cs.t]
	var cid := "c@" + k
	if d.cofres.has(cid) and not d.cofres[cid].inv.is_empty(): return _no("El cofre no está vacío")
	if not Inv.anadir(d.inv, def.coste, stats().slots): return _no("Inventario lleno")
	mundo.quitar(c)
	d.cofres.erase(cid)
	return _ok("Recuperas " + _txt_items(def.coste))

# Cofres: el del tesoro se vacía una vez al abrirse; los del jugador transfieren por pila.
func abrir_tesoro(id: String) -> Dictionary:
	var cf: Dictionary = d.cofres[id]
	if cf.get("abierto", false): return _no("Está vacío")
	if not Inv.cambiar(d.inv, {}, cf.inv, stats().slots): return _no("Inventario lleno")
	var txt := _txt_items(cf.inv)
	cf.inv = {}
	cf.abierto = true
	d.eventos["abrio_" + id] = true
	return _ok("Abres el cofre: " + txt)

func mover_cofre(cid: String, item: String, hacia_cofre: bool) -> Dictionary:
	var cf: Dictionary = d.cofres.get(cid, {})
	if cf.is_empty(): return _no("Cofre inexistente")
	var n: int = d.inv.get(item, 0) if hacia_cofre else cf.inv.get(item, 0)
	if n <= 0: return _no("No hay")
	var lote := {item: n}
	if hacia_cofre:
		if not Inv.cabe(cf.inv, lote, CAP_COFRE): return _no("El cofre está lleno")
		Inv.quitar(d.inv, lote)
		Inv.anadir(cf.inv, lote, CAP_COFRE)
	else:
		if not Inv.cabe(d.inv, lote, stats().slots): return _no("Inventario lleno")
		Inv.quitar(cf.inv, lote)
		Inv.anadir(d.inv, lote, stats().slots)
	return _ok()

# E: habitante cercano, cofre o cama delante.
func interactuar() -> Dictionary:
	for id in Hab.NPCS:
		if habitantes.pos(id).distance_to(pies) <= ALCANCE_NPC:
			var r := hablar(id)
			return {"ok": true, "panel": "dialogo", "npc": id, "texto": r.texto, "tipo": r.tipo}
	var base := Mundo.celda_de(pies)
	for c in [base + mira, base]:
		var oid := mundo.objeto_presente(c)
		if oid != "" and mundo.objetos[oid].t == "cofre_fijo": return {"ok": true, "panel": "tesoro", "id": oid, "r": abrir_tesoro(oid)}
		var cs := mundo.constr_en(c)
		if cs.is_empty(): continue
		if cs.t == "cofre": return {"ok": true, "panel": "cofre", "id": "c@" + Mundo.clave(c)}
		if cs.t == "cama":
			if not cs.propia: return {"ok": false, "r": _no("Es la cama de Maren")}
			return {"ok": true, "panel": "dormir", "r": dormir(c)}
	return {"ok": false, "r": _no("Nada con qué interactuar")}

func dormir(c: Vector2i) -> Dictionary:
	var m: int = d.min % 1440
	var salto := (6 * 60 - m) if m < 6 * 60 else (1440 - m + 6 * 60)
	for i in salto:
		d.min += 1
		if d.min % 60 == 0: mundo.regenerar(d.min, func(_c): return false)
	d.pj.hp = stats().hp
	var p := Mundo.pies_de_celda(c)
	d.pj.cama = [p.x, p.y + 16]
	habitantes.resincronizar()
	combate.revisar_reaparicion()
	return _ok("Duermes hasta el amanecer. Día %d." % dia())

# ---------- misiones ----------
func estado_mision(id: String) -> String:
	return d.misiones.get(id, {}).get("estado", "")

func mision_disponible(id: String) -> bool:
	if estado_mision(id) != "": return false
	for r in C.MISIONES[id].req: if estado_mision(r) != "entregada": return false
	return true

func aceptar(id: String) -> Dictionary:
	if not mision_disponible(id): return _no("No disponible")
	d.misiones[id] = {"estado": "activa"}
	aviso("Misión: " + C.MISIONES[id].n)
	return _ok()

func contar_constr(pieza: String) -> int:
	var n := 0
	for k in d.mundo.constr:
		if d.mundo.constr[k].t == pieza and d.mundo.constr[k].propia: n += 1
	return n

# Actuales (tener, construccion) se miden AHORA; históricos (visita, derrotar, hablar, abrir) usan hechos guardados.
func objetivo_ok(o: Dictionary) -> bool:
	match o.t:
		"hablar": return d.eventos.get("hablo_" + o.npc, 0) > 0
		"tener": return d.inv.get(o.item, 0) >= o.n
		"construccion": return contar_constr(o.pieza) >= o.n
		"visita": return d.eventos.has(o.evento)
		"derrotar": return d.jefes.get(o.jefe, {}).get("veces", 0) > 0
		"abrir": return d.cofres.get(o.cofre, {}).get("abierto", false)
	return false

func objetivo_txt(o: Dictionary) -> String:
	match o.t:
		"hablar": return "Hablar con %s" % o.npc.capitalize()
		"tener": return "%s %d/%d" % [C.ITEMS[o.item].n, mini(d.inv.get(o.item, 0), o.n), o.n]
		"construccion": return "Construir %s (%d/%d en pie)" % [C.CONSTR[o.pieza].n, mini(contar_constr(o.pieza), o.n), o.n]
		"visita": return "Visitar el lugar"
		"derrotar": return "Derrotar a %s" % C.ENEMIGOS[o.jefe].n
		"abrir": return "Abrir el cofre"
	return ""

func progreso_txt(id: String) -> String:
	var l: Array = []
	for o in C.MISIONES[id].obj: l.append(("[x] " if objetivo_ok(o) else "[ ] ") + objetivo_txt(o))
	return " ".join(l)

func _cumple(id: String) -> bool:
	for o in C.MISIONES[id].obj: if not objetivo_ok(o): return false
	return true

func evaluar_misiones() -> void:
	for id in d.misiones:
		var m: Dictionary = d.misiones[id]
		if m.estado == "activa" and _cumple(id):
			m.estado = "cumplida"
			aviso("Cumplida: " + C.MISIONES[id].n)
		elif m.estado == "cumplida" and not _cumple(id):
			m.estado = "activa"
			aviso("Ya no se cumple: " + C.MISIONES[id].n)

func entregar(id: String) -> Dictionary:
	evaluar_misiones()
	if estado_mision(id) != "cumplida": return _no("Aún no se cumple")
	if d.recompensas.has("mision:" + id): return _no("Ya entregada")
	var m: Dictionary = C.MISIONES[id]
	if not Inv.cambiar(d.inv, m.consume, m.rec.items, stats().slots): return _no("Sin espacio para la recompensa")
	d.recompensas.append("mision:" + id)
	d.misiones[id].estado = "entregada"
	ganar_xp(m.rec.xp)
	return _ok("Entregada: " + m.n)

func hablar(npc: String) -> Dictionary:
	evaluar_misiones()
	d.eventos["hablo_" + npc] = d.eventos.get("hablo_" + npc, 0) + 1
	var n: Dictionary = d.npcs[npc]
	for id in C.MISIONES:
		var m: Dictionary = C.MISIONES[id]
		if m.da != npc: continue
		var dl: Dictionary = C.DIALOGOS[id]
		var e := estado_mision(id)
		if e == "" and mision_disponible(id):
			aceptar(id)
			evaluar_misiones()
			var extra: String = C.DIALOGOS.origen[d.pj.origen] + " " if d.eventos["hablo_" + npc] == 1 else ""
			return {"texto": extra + dl.oferta, "tipo": "mision"}
		if e == "activa": return {"texto": dl.recordar + "  " + progreso_txt(id), "tipo": "expresivo"}
		if e == "cumplida":
			var r := entregar(id)
			if r.ok:
				n.relacion += 1
				return {"texto": dl.gracias, "tipo": "relacion"}
			return {"texto": r.msg, "tipo": "expresivo"}
	var done := true
	for id in C.MISIONES: if C.MISIONES[id].da == npc and estado_mision(id) != "entregada": done = false
	if done: return {"texto": C.DIALOGOS.final, "tipo": "expresivo"}
	return {"texto": C.DIALOGOS.base[d.eventos["hablo_" + npc] % C.DIALOGOS.base.size()], "tipo": "expresivo"}

# ---------- botín y jefes ----------
func dar_o_pendiente(items: Dictionary) -> void:
	if Inv.anadir(d.inv, items, stats().slots): aviso("Obtienes " + _txt_items(items))
	else:
		for k in items: d.pendientes[k] = d.pendientes.get(k, 0) + items[k]
		aviso("Inventario lleno: la recompensa queda pendiente")

func jefe_derrotado(id: String) -> void:
	var st: Dictionary = d.jefes.get(id, {"veces": 0})
	st.veces = int(st.veces) + 1
	st.derrotado = true
	st.hora = d.min
	d.jefes[id] = st
	var clave := "jefe:%s:%d" % [id, st.veces]
	if not d.recompensas.has(clave):
		d.recompensas.append(clave)
		dar_o_pendiente(C.ENEMIGOS[id].recompensa)
	aviso("¡%s derrotado!" % C.ENEMIGOS[id].n)
