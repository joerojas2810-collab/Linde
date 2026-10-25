extends RefCounted
## Cargador y validador del paquete de datos de Mundo vivo (manifiesto + entidades JSON).
## Implementa: design/gdd/mundo-vivo.md regla 1 (paquete fijo por sesión) y el contrato del Atlas (atlas-contrato.md).
## Solo se parsea JSON (JSON.parse_string): nada se evalúa ni se ejecuta. Un solo fallo rechaza el paquete ENTERO;
## el error nombra archivo y campo ("archivo: campo: motivo"). No hay recarga en caliente: paquete() lee una vez.
const RAIZ := "res://datos/mundo/"
const TIPOS := ["npc", "lugar", "variable_mundo", "evento", "plantilla_mision"]
const COMUNES := ["schema_version", "id", "type", "name", "summary", "tags", "revision", "design_status", "implementation_status", "sources", "relations", "data"]
const ACTIVIDADES := ["dormir", "trabajar", "socializar", "descansar", "explorar"]
const OPERADORES := ["eq", "neq", "gt", "gte", "lt", "lte"]
const NUMERICOS := ["gt", "gte", "lt", "lte"]
const FRANJA := ["desde_minuto", "hasta_minuto", "actividad", "destino"]
const NECESIDAD := ["id", "minimo", "maximo", "inicial", "cambio_por_hora_activo", "cambio_por_hora_descanso", "umbral_descanso"]
const MAX_EFECTOS := 64
const MAX_PROFUNDIDAD := 16
const MAX_NODOS := 256
const ANCHO := 64    # = Mundo.ANCHO/ALTO (el contrato de entidades fija el valle inicial 64x48, no el exterior generado); no se precarga mundo.gd para evitar dependencias circulares
const ALTO := 48

static var _actual := {}

## Paquete de la sesión: {error: String, manifiesto: Dictionary, entidades: {tipo: {id: ficha}}}. error != "" = rechazado.
static func paquete() -> Dictionary:
	if _actual.is_empty(): _actual = cargar(RAIZ)
	return _actual

## Lee y valida el paquete de `raiz` (con "/" final). Sin caché; paquete() es el acceso normal.
static func cargar(raiz: String) -> Dictionary:
	var paq := {"error": "", "manifiesto": {}, "entidades": {}}
	var e := _leer_paquete(raiz, paq)
	return paq if e == "" else {"error": e, "manifiesto": {}, "entidades": {}}

static func _json(ruta: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(ruta)) if FileAccess.file_exists(ruta) else null

static func _leer_paquete(raiz: String, paq: Dictionary) -> String:
	var man = _json(raiz + "manifest.json")
	if typeof(man) != TYPE_DICTIONARY: return "manifest.json: ilegible, ausente o no es un objeto"
	if not (_ent(man.get("schema_version")) and int(man.schema_version) == 2): return "manifest.json: schema_version: debe ser 2"
	if typeof(man.get("entities")) != TYPE_ARRAY or man.entities.is_empty(): return "manifest.json: entities: lista no vacía de rutas"
	if typeof(man.get("sources")) != TYPE_STRING: return "manifest.json: sources: debe ser una ruta"
	var fuentes = _json(raiz + str(man.sources))
	if typeof(fuentes) != TYPE_DICTIONARY: return "manifest.json: sources: «%s» ilegible o no es un objeto" % man.sources
	paq.manifiesto = man
	for t in TIPOS: paq.entidades[t] = {}
	var donde := {}     # "tipo/id" -> archivo, para duplicados
	for ruta in man.entities:    # pasada 1: lectura, campos comunes e identidad
		if typeof(ruta) != TYPE_STRING or not ruta.is_relative_path() or ".." in ruta: return "manifest.json: entities: ruta no válida «%s»" % str(ruta)
		var f = _json(raiz + ruta)
		if typeof(f) != TYPE_DICTIONARY: return "%s: ilegible, ausente o no es un objeto" % ruta
		var e := _comun(f, int(man.schema_version), fuentes)
		if e != "": return "%s: %s" % [ruta, e]
		var clave := "%s/%s" % [f.type, f.id]
		if donde.has(clave): return "%s: id: «%s» duplicado (ya definido en %s)" % [ruta, clave, donde[clave]]
		donde[clave] = ruta
		paq.entidades[f.type][f.id] = f
		f["_archivo"] = ruta
	for t in TIPOS:    # pasada 2: referencias y datos de cada tipo
		for id in paq.entidades[t]:
			var f: Dictionary = paq.entidades[t][id]
			var e := _relaciones(f, paq.entidades)
			if e == "": e = _datos(t, f.data, paq.entidades)
			if e != "": return "%s: %s" % [f._archivo, e]
	return ""

# ---------- comunes ----------
static func _ent(v) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(v) and v == floorf(v)

static func _num(v) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(v)

static func _txt(v) -> bool:
	return typeof(v) == TYPE_STRING

# "" si d tiene exactamente las claves obligatorias (+ las opcionales permitidas).
static func _claves(d: Dictionary, oblig: Array, opc: Array = []) -> String:
	for k in oblig: if not d.has(k): return "falta «%s»" % k
	for k in d: if not (k in oblig or k in opc): return "campo no previsto «%s»" % k
	return ""

static func _comun(f: Dictionary, version: int, fuentes: Dictionary) -> String:
	for k in f: if not k in COMUNES: return "%s: campo no previsto" % k
	for k in ["schema_version", "id", "type", "name", "revision", "sources", "relations", "data"]:
		if not f.has(k): return "%s: obligatorio" % k
	if not _ent(f.schema_version) or int(f.schema_version) != version: return "schema_version: debe ser %d" % version
	if not _ent(f.revision) or f.revision < 1: return "revision: entero positivo"
	if not _txt(f.id) or f.id == "": return "id: texto no vacío"
	if not _txt(f.type) or not f.type in TIPOS: return "type: desconocido «%s»" % str(f.type)
	if not _txt(f.name): return "name: debe ser texto"
	if typeof(f.sources) != TYPE_ARRAY: return "sources: debe ser lista"
	for s in f.sources: if not _txt(s) or not fuentes.has(s): return "sources: clave inexistente en sources.json «%s»" % str(s)
	if typeof(f.relations) != TYPE_ARRAY: return "relations: debe ser lista"
	if typeof(f.data) != TYPE_DICTIONARY: return "data: debe ser objeto"
	return ""

static func _ref(r, tipo: String, ent: Dictionary, campo: String) -> String:
	if typeof(r) != TYPE_DICTIONARY or _claves(r, ["type", "id"]) != "": return campo + ": referencia {type, id} no válida"
	if r.type != tipo: return "%s: debe apuntar a un «%s»" % [campo, tipo]
	if not ent.get(tipo, {}).has(r.id): return "%s: referencia rota, no existe %s «%s»" % [campo, tipo, str(r.id)]
	return ""

static func _relaciones(f: Dictionary, ent: Dictionary) -> String:
	for i in f.relations.size():
		var r = f.relations[i]
		if typeof(r) != TYPE_DICTIONARY or not r.has("target") or typeof(r.target) != TYPE_DICTIONARY: return "relations[%d]: sin target" % i
		var t = r.target.get("type")
		if not (_txt(t) and t in TIPOS): return "relations[%d].target.type: desconocido" % i
		var e := _ref(r.target, t, ent, "relations[%d].target" % i)
		if e != "": return e
	return ""

static func _datos(tipo: String, d: Dictionary, ent: Dictionary) -> String:
	match tipo:
		"npc": return _npc(d, ent)
		"lugar": return _lugar(d)
		"variable_mundo": return _variable(d)
		"evento": return _evento(d, ent.variable_mundo)
		_: return _mision(d, ent.variable_mundo)

# ---------- por tipo ----------
static func _lugar(d: Dictionary) -> String:
	var e := _claves(d, ["descripcion"], ["celda"])
	if e != "": return "data: " + e
	if not _txt(d.descripcion): return "data.descripcion: debe ser texto"
	if d.has("celda"):
		var c = d.celda
		if typeof(c) != TYPE_DICTIONARY or _claves(c, ["x", "y"]) != "": return "data.celda: exactamente {x, y}"
		if not _ent(c.x) or not _ent(c.y) or c.x < 0 or c.x >= ANCHO or c.y < 0 or c.y >= ALTO: return "data.celda: enteros dentro de 64x48"
	return ""

static func _variable(d: Dictionary) -> String:
	var e := _claves(d, ["origen", "tipo_valor", "persistir", "descripcion"], ["inicial", "minimo", "maximo", "valores_permitidos"])
	if e != "": return "data: " + e
	if not (d.origen == "persistida" or d.origen == "derivada"): return "data.origen: persistida o derivada"
	var tv = d.tipo_valor
	if not (_txt(tv) and tv in ["boolean", "integer", "number", "string"]): return "data.tipo_valor: desconocido"
	if typeof(d.persistir) != TYPE_BOOL or d.persistir != (d.origen == "persistida"): return "data.persistir: true si persistida, false si derivada"
	if not _txt(d.descripcion): return "data.descripcion: debe ser texto"
	if d.origen == "derivada" and d.has("inicial"): return "data.inicial: prohibido en una derivada"
	if d.origen == "persistida" and not d.has("inicial"): return "data.inicial: obligatorio en una persistida"
	for k in ["minimo", "maximo"]:
		if d.has(k) and not (tv in ["integer", "number"] and _tipo_ok(tv, d[k])): return "data.%s: numérico del tipo declarado" % k
	if d.has("minimo") and d.has("maximo") and d.minimo > d.maximo: return "data.minimo: mayor que maximo"
	if d.has("valores_permitidos") and (typeof(d.valores_permitidos) != TYPE_ARRAY or d.valores_permitidos.is_empty()): return "data.valores_permitidos: lista no vacía"
	if d.has("inicial"):
		if not _tipo_ok(tv, d.inicial): return "data.inicial: no es del tipo %s" % tv
		if (d.has("minimo") and d.inicial < d.minimo) or (d.has("maximo") and d.inicial > d.maximo): return "data.inicial: fuera de límites"
	return ""

static func _tipo_ok(tv: String, v) -> bool:
	match tv:
		"boolean": return typeof(v) == TYPE_BOOL
		"integer": return _ent(v)
		"number": return _num(v)
	return _txt(v)

static func _npc(d: Dictionary, ent: Dictionary) -> String:
	var e := _claves(d, ["objetivo_propio", "horario", "necesidades"], ["notas"])
	if e != "": return "data: " + e
	if not _txt(d.objetivo_propio): return "data.objetivo_propio: debe ser texto"
	if typeof(d.horario) != TYPE_ARRAY or d.horario.is_empty(): return "data.horario: lista no vacía"
	var t := 0
	for i in d.horario.size():
		var c := "data.horario[%d]" % i
		var f = d.horario[i]
		if typeof(f) != TYPE_DICTIONARY: return c + ": debe ser objeto"
		e = _claves(f, FRANJA)
		if e != "": return "%s: %s" % [c, e]
		if not _ent(f.desde_minuto) or not _ent(f.hasta_minuto): return c + ": desde_minuto/hasta_minuto enteros"
		if int(f.desde_minuto) != t or f.hasta_minuto <= f.desde_minuto or f.hasta_minuto > 1440: return c + ": franjas ordenadas, sin huecos ni solapes, 0 a 1440"
		t = int(f.hasta_minuto)
		if not (_txt(f.actividad) and f.actividad in ACTIVIDADES): return c + ".actividad: desconocida «%s»" % str(f.actividad)
		if f.destino != null:
			e = _ref(f.destino, "lugar", ent, c + ".destino")
			if e != "": return e
	if t != 1440: return "data.horario: no cubre el día completo"
	if typeof(d.necesidades) != TYPE_ARRAY: return "data.necesidades: debe ser lista"
	var ids := {}
	for i in d.necesidades.size():
		var c := "data.necesidades[%d]" % i
		var n = d.necesidades[i]
		if typeof(n) != TYPE_DICTIONARY: return c + ": debe ser objeto"
		e = _claves(n, NECESIDAD)
		if e != "": return "%s: %s" % [c, e]
		if not _txt(n.id) or ids.has(n.id): return c + ".id: texto único"
		ids[n.id] = true
		for k in NECESIDAD.slice(1): if not _num(n[k]): return "%s.%s: número finito" % [c, k]
		if not (n.minimo <= n.umbral_descanso and n.umbral_descanso <= n.maximo and n.minimo <= n.inicial and n.inicial <= n.maximo): return c + ": minimo <= umbral <= maximo e inicial dentro del rango"
	return ""

static func _evento(d: Dictionary, vars: Dictionary) -> String:
	var e := _claves(d, ["condiciones", "efectos", "peso", "enfriamiento_minutos"])
	if e != "": return "data: " + e
	if not _num(d.peso) or d.peso < 0: return "data.peso: número finito >= 0"
	if not _ent(d.enfriamiento_minutos) or d.enfriamiento_minutos < 0: return "data.enfriamiento_minutos: entero >= 0"
	e = _cond(d.condiciones, "data.condiciones", vars, 1, [0])
	if e == "": e = _efectos(d.efectos, "data.efectos", vars, false)
	return e

static func _mision(d: Dictionary, vars: Dictionary) -> String:
	var e := _claves(d, ["ambito", "parametros", "condiciones_oferta", "condiciones_completar", "efectos_completar", "repetible", "recompensa", "texto"], ["notas"])
	if e != "": return "data: " + e
	if not (d.ambito == "mundo" or d.ambito == "jugador"): return "data.ambito: mundo o jugador"
	if typeof(d.parametros) != TYPE_ARRAY or not d.parametros.is_empty(): return "data.parametros: debe ser []"
	if typeof(d.repetible) != TYPE_BOOL: return "data.repetible: booleano"
	if not _txt(d.texto): return "data.texto: debe ser texto"
	for k in ["condiciones_oferta", "condiciones_completar"]:
		e = _cond(d[k], "data." + k, vars, 1, [0])
		if e != "": return e
	e = _efectos(d.efectos_completar, "data.efectos_completar", vars, true)
	if e != "": return e
	if d.ambito == "jugador" and not d.efectos_completar.is_empty(): return "data.efectos_completar: debe ser vacío con ámbito jugador"
	var r = d.recompensa
	if typeof(r) != TYPE_DICTIONARY or _claves(r, ["destinatario", "xp", "items"]) != "": return "data.recompensa: exactamente {destinatario, xp, items}"
	if r.destinatario != "completador" or not _ent(r.xp) or r.xp < 0 or typeof(r.items) != TYPE_ARRAY: return "data.recompensa: destinatario «completador», xp entero >= 0, items lista"
	var vistos := {}
	for i in r.items.size():
		var it = r.items[i]
		if typeof(it) != TYPE_DICTIONARY or _claves(it, ["item", "cantidad"]) != "" or not _txt(it.item) or vistos.has(it.item) or not _ent(it.cantidad) or it.cantidad < 1:
			return "data.recompensa.items[%d]: {item único, cantidad entero > 0}" % i
		if not load("res://scripts/catalogos.gd").ITEMS.has(it.item): return "data.recompensa.items[%d].item: «%s» no existe en el catálogo de ítems" % [i, it.item]    # load, no preload: evita ciclos
		vistos[it.item] = true
	return ""

# Condición cerrada: hoja {variable, operador, valor} o grupo {y|o: [...]}. `cuenta[0]` acumula nodos.
static func _cond(n, campo: String, vars: Dictionary, prof: int, cuenta: Array) -> String:
	cuenta[0] += 1
	if prof > MAX_PROFUNDIDAD or cuenta[0] > MAX_NODOS: return campo + ": excede profundidad 16 o 256 nodos"
	if typeof(n) != TYPE_DICTIONARY: return campo + ": debe ser objeto"
	if n.has("y") or n.has("o"):
		var g: String = "y" if n.has("y") else "o"
		if n.size() != 1 or typeof(n[g]) != TYPE_ARRAY or n[g].is_empty(): return campo + ": grupo con una sola clave y lista no vacía"
		for i in n[g].size():
			var e := _cond(n[g][i], "%s.%s[%d]" % [campo, g, i], vars, prof + 1, cuenta)
			if e != "": return e
		return ""
	var e := _claves(n, ["variable", "operador", "valor"])
	if e != "": return "%s: %s" % [campo, e]
	if not _txt(n.variable) or not vars.has(n.variable): return "%s.variable: variable desconocida «%s»" % [campo, str(n.variable)]
	if not _txt(n.operador) or not n.operador in OPERADORES: return "%s.operador: operador desconocido «%s»" % [campo, str(n.operador)]
	var tv: String = vars[n.variable].data.tipo_valor
	if n.operador in NUMERICOS and not tv in ["integer", "number"]: return "%s.operador: «%s» solo para números" % [campo, n.operador]
	if not _tipo_ok(tv, n.valor): return "%s.valor: no es del tipo %s" % [campo, tv]
	return ""

static func _efectos(l, campo: String, vars: Dictionary, puede_vacia: bool) -> String:
	if typeof(l) != TYPE_ARRAY or l.size() > MAX_EFECTOS or (l.is_empty() and not puede_vacia): return campo + ": lista (no vacía en eventos) de hasta 64"
	for i in l.size():
		var c := "%s[%d]" % [campo, i]
		var x = l[i]
		if typeof(x) != TYPE_DICTIONARY: return c + ": debe ser objeto"
		var e := _claves(x, ["operacion", "variable", "valor"])
		if e != "": return "%s: %s" % [c, e]
		if not (x.operacion == "asignar" or x.operacion == "sumar"): return "%s.operacion: desconocida «%s»" % [c, str(x.operacion)]
		if not _txt(x.variable) or not vars.has(x.variable): return "%s.variable: variable desconocida «%s»" % [c, str(x.variable)]
		var v: Dictionary = vars[x.variable].data
		if v.origen != "persistida": return "%s.variable: «%s» es derivada (solo lectura)" % [c, x.variable]
		if x.operacion == "sumar" and not v.tipo_valor in ["integer", "number"]: return c + ": sumar exige variable numérica"
		if not _tipo_ok(v.tipo_valor, x.valor): return "%s.valor: no es del tipo %s" % [c, v.tipo_valor]
	return ""
