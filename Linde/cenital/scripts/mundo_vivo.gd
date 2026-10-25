extends RefCounted
## Variables del mundo y director de eventos (Mundo vivo).
## Implementa: design/gdd/mundo-vivo.md Core Rules 1-11 y 16; historia production/epics/mundo-vivo/story-002.
## Consume el paquete ya validado por MundoDatos (no lo revalida). Nada se evalúa como código: operadores en tabla explícita.
## Solo el servidor/anfitrión debe llamar a evaluar().
const MundoDatos = preload("res://scripts/mundo_datos.gd")
const Mundo = preload("res://scripts/mundo.gd")

const TOPE_REGISTRO := 50      # provisional: entradas del registro; la más antigua sale primero
const CADENCIA_MIN := 60       # provisional: minutos de juego entre evaluaciones (las dispara Juego._hora_en_punto)

var j                                   # Juego
var _paq: Dictionary
## Las tarjetas design_status «proposed» solo participan si es true (fixture:true o --admitir-propuestas).
var admitir_propuestas: bool = false
var _avisadas := {}                     # tarjetas proposed ya informadas (una vez por nombre)
var _derivadas := {}                    # nombre de variable derivada -> Callable() -> Variant

## `paq`: paquete ya cargado (por defecto el de la sesión). `admitir`: fuerza admitir_propuestas.
func _init(juego, paq: Dictionary = {}, admitir: bool = false) -> void:
	j = juego
	_paq = paq if not paq.is_empty() else MundoDatos.paquete()
	admitir_propuestas = admitir or _paq.get("manifiesto", {}).get("fixture", false) == true or "--admitir-propuestas" in OS.get_cmdline_user_args()
	_derivadas = {"dia": _v_dia, "camas_libres": _v_camas_libres, "presion_llegada": _v_presion, "habitantes_presentes": _v_habitantes,
		"mesa_construida": _v_mesa, "guardian_derrotado": _v_guardian}

## Estado compartido (d.mundo_vivo). Rellena los defectos que falten; las variables persistidas nuevas toman su `inicial`.
func restaurar() -> Dictionary:
	var mv: Dictionary = j.d.get_or_add("mundo_vivo", {})
	for k in ["vars", "ultimo", "instancias", "camas_asignadas"]: if not mv.has(k): mv[k] = {}
	for k in ["llegados", "registro"]: if not mv.has(k): mv[k] = []
	if not mv.has("hora_eval"): mv.hora_eval = -1
	if _paq.get("error", "x") != "": return mv
	for id in _paq.entidades.variable_mundo:
		var v: Dictionary = _paq.entidades.variable_mundo[id].data
		if v.origen == "persistida" and not mv.vars.has(id): mv.vars[id] = _norm(v.tipo_valor, v.inicial)
	return mv

## Evalúa el director una vez por minuto de juego. Devuelve el id del evento aplicado ("" si ninguno).
func evaluar() -> String:
	var mv: Dictionary = restaurar()
	var ahora: int = j.d.min
	if _paq.get("error", "x") != "" or int(mv.hora_eval) == ahora: return ""
	mv.hora_eval = ahora
	var snap: Dictionary = instantanea()
	var cand: Array = []
	var leidas: Dictionary = {}
	var eventos: Dictionary = _paq.entidades.evento
	for id in eventos.keys().duplicate():
		var f: Dictionary = eventos[id]
		var dat: Dictionary = f.data
		if float(dat.peso) <= 0.0: continue
		if f.get("design_status", "") == "proposed" and not admitir_propuestas:
			if not _avisadas.has(id):
				_avisadas[id] = true
				push_warning("Mundo vivo: tarjeta «%s» es proposed y no se admiten propuestas; no se dispara." % id)
			continue
		if mv.ultimo.has(id) and ahora - int(mv.ultimo[id]) < int(dat.enfriamiento_minutos): continue
		if mv.ultimo.get(id, -1) == ahora: continue    # enfriamiento 0: nunca dos veces en el mismo minuto
		var lei: Dictionary = {}
		var r: Variant = _cond(dat.condiciones, snap, lei, 1, [0])
		if r is String:
			_anotar(mv, ahora, "%s: %s" % [id, r])
		elif r:
			cand.append(id)
			leidas[id] = lei
	if cand.is_empty(): return ""
	cand.sort()    # orden estable -> misma semilla y minuto, misma elección
	var total: float = 0.0
	for id in cand: total += float(eventos[id].data.peso)
	var tirada: float = j._rng("evento", str(ahora)).randf() * total
	var elegido: String = cand[cand.size() - 1]
	for id in cand:
		tirada -= float(eventos[id].data.peso)
		if tirada < 0.0:
			elegido = id
			break
	var nuevas: Variant = _efectos(eventos[elegido].data.efectos, mv.vars)
	if nuevas is String:
		_anotar(mv, ahora, "%s: efecto rechazado: %s" % [elegido, nuevas])
		return ""
	var fallo: String = _llegadas_posibles(nuevas, mv.vars)
	if fallo != "":
		_anotar(mv, ahora, "%s: llegada imposible: %s" % [elegido, fallo])    # no se aplica; ultimo no cambia: se reintenta
		return ""
	mv.vars = nuevas
	mv.ultimo[elegido] = ahora
	_anotar(mv, ahora, null, {"min": ahora, "id": elegido, "vars": leidas[elegido]})
	return elegido

## Nombre de la tarjeta de un evento (para el aviso).
func nombre(id: String) -> String:
	return _paq.entidades.evento[id].name

## Claves de las camas de huésped construidas y sin asignar, en orden estable.
func camas_libres_lista() -> Array:
	var asignadas: Dictionary = j.d.mundo_vivo.camas_asignadas
	var l: Array = []
	for k in j.d.mundo.constr:
		var c:=Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
		# Los habitantes conservan por ahora su planificación del valle; no asignar camas inalcanzables del exterior.
		if Mundo.es_valle(c) and j.d.mundo.constr[k].t == "cama_huesped" and not asignadas.has(k): l.append(k)
	l.sort()
	return l

# "" si cada llegada (`<id>_presente` false -> true sin habitante) puede entrar: con cama libre exige ruta hasta su lado; sin cama llega igual y duerme al raso.
func _llegadas_posibles(nuevas: Dictionary, antes: Dictionary) -> String:
	var libres: Array = camas_libres_lista()
	for id in _paq.entidades.npc:
		var v: String = id + "_presente"
		if not nuevas.get(v, false) or antes.get(v, false) or j.d.npcs.has(id): continue
		if libres.is_empty(): continue
		var parts: PackedStringArray = libres.pop_front().split(",")
		var cama := Vector2i(int(parts[0]), int(parts[1]))
		if j.mundo.camino(Mundo.ENTRADA, func(c): return j.mundo.es_adyacente(c, cama)).is_empty(): return "%s: sin ruta desde la entrada" % id
	return ""

## Valores de todas las variables ahora: persistidas (de d.mundo_vivo.vars) y derivadas (recalculadas).
func instantanea() -> Dictionary:
	var s: Dictionary = restaurar().vars.duplicate()
	for n in _derivadas: if _paq.entidades.variable_mundo.has(n): s[n] = _derivadas[n].call()
	return s

# Valor de una condición: bool, o String con el motivo del error. `lei` acumula las variables leídas.
func _cond(n: Dictionary, snap: Dictionary, lei: Dictionary, prof: int, cuenta: Array) -> Variant:
	cuenta[0] += 1
	if prof > MundoDatos.MAX_PROFUNDIDAD or cuenta[0] > MundoDatos.MAX_NODOS: return "condición excede profundidad 16 o 256 nodos"
	if n.has("y") or n.has("o"):
		var o: bool = n.has("o")
		for hijo in n["o" if o else "y"]:
			var r: Variant = _cond(hijo, snap, lei, prof + 1, cuenta)
			if r is String: return r
			if r == o: return o      # cortocircuito: o con uno verdadero, y con uno falso
		return not o
	if not snap.has(n.variable): return "variable inexistente «%s»" % str(n.variable)
	var a: Variant = snap[n.variable]
	var b: Variant = n.valor
	lei[n.variable] = a
	var num: bool = typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]
	if not (num or typeof(a) == typeof(b)): return "tipos distintos en «%s»" % n.variable
	match n.operador:    # tabla explícita de los 6 operadores
		"eq": return a == b
		"neq": return a != b
		"gt": return a > b
		"gte": return a >= b
		"lt": return a < b
		"lte": return a <= b
	return "operador desconocido «%s»" % str(n.operador)

# Aplica los efectos sobre una COPIA de `vars`. Devuelve la copia, o String con el motivo (y no se toca nada).
func _efectos(lista: Array, vars: Dictionary) -> Variant:
	if lista.size() > MundoDatos.MAX_EFECTOS: return "más de 64 efectos"
	var copia: Dictionary = vars.duplicate()
	var defs: Dictionary = _paq.entidades.variable_mundo
	for x in lista:
		if not defs.has(x.variable): return "variable inexistente «%s»" % str(x.variable)
		var v: Dictionary = defs[x.variable].data
		if v.origen != "persistida": return "«%s» es derivada (solo lectura)" % x.variable
		var tv: String = v.tipo_valor
		if not MundoDatos._tipo_ok(tv, x.valor): return "valor de «%s» no es del tipo %s" % [x.variable, tv]
		var nuevo: Variant = _norm(tv, x.valor)
		if x.operacion == "sumar":
			if not tv in ["integer", "number"]: return "sumar exige variable numérica «%s»" % x.variable
			nuevo = _norm(tv, copia[x.variable] + nuevo)
		elif x.operacion != "asignar": return "operación desconocida «%s»" % str(x.operacion)
		if (v.has("minimo") and nuevo < v.minimo) or (v.has("maximo") and nuevo > v.maximo): return "«%s» fuera de límites" % x.variable
		if v.has("valores_permitidos") and not nuevo in v.valores_permitidos: return "«%s» fuera de valores permitidos" % x.variable
		copia[x.variable] = nuevo
	return copia

# JSON entrega los enteros como float: se devuelven como int para que el tipo sea exacto.
func _norm(tv: String, v: Variant) -> Variant:
	return int(v) if tv == "integer" else v

# Añade al registro un evento aplicado (`entrada`) o un error (`err`), acotado a TOPE_REGISTRO.
func _anotar(mv: Dictionary, minuto: int, err: Variant, entrada: Dictionary = {}) -> void:
	mv.registro.append(entrada if err == null else {"min": minuto, "error": err})
	while mv.registro.size() > TOPE_REGISTRO: mv.registro.pop_front()

# ---------- misiones por plantilla (story-004; GDD Core Rules 15) ----------
## Ofrece una instancia por plantilla cuyas condiciones_oferta se cumplen y que no tiene una no cerrada.
## repetible=false: tampoco otra tras completarla. Solo el servidor/anfitrión debe llamarla (la llama Juego._chequeos).
## ponytail: ámbito `jugador` se trata como una instancia compartida; propietario por jugador llega con la historia 005.
func evaluar_misiones() -> void:
	var mv: Dictionary = restaurar()
	if _paq.get("error", "x") != "": return
	var snap: Dictionary = instantanea()
	for pid in _paq.entidades.plantilla_mision:
		var f: Dictionary = _paq.entidades.plantilla_mision[pid]
		if f.get("design_status", "") == "proposed" and not admitir_propuestas: continue
		var previas: int = 0
		var bloquea: bool = false
		for iid in mv.instancias:
			var ins: Dictionary = mv.instancias[iid]
			if ins.plantilla != pid: continue
			previas += 1
			if ins.estado != "completada" or not f.data.repetible: bloquea = true
		if bloquea or _cond(f.data.condiciones_oferta, snap, {}, 1, [0]) != true: continue
		mv.instancias["%s#%d" % [pid, previas + 1]] = {"plantilla": pid, "revision": f.revision, "ambito": f.data.ambito, "estado": "ofrecida", "completador": ""}
		j.aviso_todos("Misión: " + f.name)

## ofrecida -> activa. Basta con que un jugador la acepte (instancia compartida).
func aceptar_plantilla(iid: String, id: String) -> Dictionary:
	var ins: Dictionary = restaurar().instancias.get(iid, {})
	if ins.is_empty() or ins.estado != "ofrecida": return j._no("Esa misión no está ofrecida", id)
	ins.estado = "activa"
	return j._ok("Misión aceptada: " + _paq.entidades.plantilla_mision[ins.plantilla].name, id)

## activa -> completada si condiciones_completar son verdaderas AHORA. Efectos y recompensa se aplican una sola vez
## (al jugador `id`); lo que no cabe va a pendientes. Repetir la petición no cambia nada.
func entregar_plantilla(iid: String, id: String) -> Dictionary:
	var mv: Dictionary = restaurar()
	var ins: Dictionary = mv.instancias.get(iid, {})
	if ins.is_empty() or ins.estado != "activa": return j._no("Esa misión no está activa", id)
	var f: Dictionary = _paq.entidades.plantilla_mision[ins.plantilla]
	if _cond(f.data.condiciones_completar, instantanea(), {}, 1, [0]) != true: return j._no("Aún no se cumple", id)
	var nuevas: Variant = _efectos(f.data.efectos_completar, mv.vars)
	if nuevas is String: return j._no("Efecto rechazado: " + nuevas, id)
	mv.vars = nuevas
	ins.estado = "completada"
	ins.completador = id
	var rec: Dictionary = f.data.recompensa
	j.jug(id).recompensas.append("plantilla:" + iid)
	j.ganar_xp(int(rec.xp), id)
	var items: Dictionary = {}
	for it in rec.items: items[it.item] = int(it.cantidad)
	if not items.is_empty(): j.dar_o_pendiente(items, id)
	return j._ok("Completada: " + f.name, id)

## Para la UI: instancias ofrecidas o activas como [{iid, nombre, texto, estado, cumplida}] (orden estable por iid).
func instancias_visibles(_id: String) -> Array:
	var mv: Dictionary = restaurar()
	var snap: Dictionary = instantanea()
	var l: Array = []
	var claves: Array = mv.instancias.keys()
	claves.sort()
	for iid in claves:
		var ins: Dictionary = mv.instancias[iid]
		if ins.estado == "completada": continue
		var f: Dictionary = _paq.entidades.plantilla_mision[ins.plantilla]
		l.append({"iid": iid, "nombre": f.name, "texto": f.data.texto, "estado": ins.estado, "cumplida": _cond(f.data.condiciones_completar, snap, {}, 1, [0]) == true})
	return l

# ---------- proveedores de variables derivadas (solo lectura) ----------
func _v_dia() -> int:
	return j.dia()

func _v_camas_libres() -> int:
	return camas_libres_lista().size()

## Presión de llegada en porcentaje (100 = alcanza para acoger a alguien): lo mayor entre el sustento y la seguridad del valle
## (autonomía) y la actividad construida por cualquiera (piezas útiles que no son camas). Las camas solas no atraen a nadie.
func _v_presion() -> int:
	var util := 0
	for k in j.d.mundo.constr:
		if not j.d.mundo.constr[k].t in ["cama", "cama_huesped", "muro", "muro_ladrillo", "suelo", "puerta", "techo"]: util += 1
	var p: int = mini(150, util * 25)
	if j.autonomia != null and j.autonomia.sociedad.activa(): p = maxi(p, floori(j.autonomia.sociedad.presion() * 100.0))
	return p

func _v_habitantes() -> int:
	var n: int = 0
	var vars: Dictionary = j.d.mundo_vivo.vars
	for id in _paq.entidades.npc: if vars.get(id + "_presente", true): n += 1    # sin variable de presencia = presente
	return n

func _v_mesa() -> bool:
	for k in j.d.mundo.constr: if j.d.mundo.constr[k].t == "mesa": return true
	return false

func _v_guardian() -> bool:
	return j.d.jefes.get("guardian", {}).get("veces", 0) > 0
