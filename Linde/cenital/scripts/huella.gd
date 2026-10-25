extends RefCounted
## Huella canónica de las reglas (docs/investigacion/innovacion-emergente/PLAN_MAESTRO.md §7.2, fase H0).
## Resume en un SHA-256 todo lo que decide los resultados de fabricación, economía y equipo: los JSON de reglas, las
## constantes de gameplay de catalogos.gd y la versión del evaluador. Un mundo guardado lleva su sello; Guardado se
## niega a cargarlo si el sello no coincide con las reglas actuales. La lógica escrita en código (fórmulas, generadores
## de terreno) no se resume aquí: cuando cambie su interpretación se sube EVALUADOR_VERSION (artesania.gd).
const A = preload("res://scripts/artesania.gd")
const C = preload("res://scripts/catalogos.gd")

## Versión del formato de la propia huella: cambiarla cambia todas las huellas.
const VERSION_HUELLA := 1
## Argumento de usuario (tras `--`) que habilita cargar mundos con reglas distintas; solo en compilaciones de depuración.
const ARGUMENTO_EXCEPCION := "--aceptar-reglas-distintas"

## Un componente por grupo de archivos. Faltar un archivo cuenta como «ausente» (p. ej. saberes antes de existir).
## Excluido a propósito: equipo/paletas.json (solo colores) y datos/mundo (tarjetas narrativas del director).
const COMPONENTES := {
	"desarrollo": ["res://datos/desarrollo/reglas_v1.json", "res://datos/desarrollo/saberes_v1.json"],
	"autonomia": ["res://datos/autonomia/reglas.json"],
	"asentamientos": ["res://datos/asentamientos/reglas_v1.json"],
	"fauna": ["res://datos/fauna/reglas_v1.json"],
	"equipo": ["res://datos/equipo/arquetipos.json", "res://datos/equipo/familias.json",
		"res://datos/equipo/joyas.json", "res://datos/equipo/variantes.json"],
}
## Constantes de catalogos.gd con efecto jugable. Excluidas: ANIM_PJ (animación) y DIALOGOS (texto).
const CONSTANTES := ["MAX_SLOTS_BASE", "NIVEL_MAX", "MIN_POR_SEG", "HP_BASE", "DMG_BASE", "CAMPO_CRECE_MIN", "CAMPO_COSECHA",
	"PISADAS_CAMINO", "ITEMS", "RANURAS", "OBJETOS", "CONSTR", "ORDEN_CONSTR", "RECETAS", "HAB", "PASIVAS", "ENEMIGOS",
	"ATAQUES", "PJ_ATAQUE", "MISIONES"]

## Solo para pruebas automatizadas: simula el modo de desarrollo explícito.
static var excepcion_de_prueba := false
static var _cache: Dictionary = {}

## Texto canónico y determinista: claves ordenadas, números normalizados (1 y 1.0 coinciden), sin espacios.
## Un tipo no previsto se escribe con var_to_str para que quede visible en la huella en vez de ignorarse.
static func canonico(v) -> String:
	match typeof(v):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "true" if v else "false"
		TYPE_INT: return str(v)
		TYPE_FLOAT: return _numero(v)
		TYPE_STRING, TYPE_STRING_NAME: return JSON.stringify(str(v))
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			var partes: PackedStringArray = []
			for e in v: partes.append(canonico(e))
			return "[" + ",".join(partes) + "]"
		TYPE_DICTIONARY:
			var claves: Array = []
			for k in v: claves.append(str(k))
			claves.sort()
			var partes: PackedStringArray = []
			for k in claves:
				var valor = v[k] if v.has(k) else _por_texto(v, k)
				partes.append(JSON.stringify(k) + ":" + canonico(valor))
			return "{" + ",".join(partes) + "}"
	return "~" + var_to_str(v)

static func _por_texto(d: Dictionary, clave: String):
	for k in d: if str(k) == clave: return d[k]
	return null

static func _numero(f: float) -> String:
	if is_nan(f): return "NaN"
	if is_inf(f): return "Inf" if f > 0.0 else "-Inf"
	var s := "%.9f" % f
	while s.ends_with("0"): s = s.left(-1)
	if s.ends_with("."): s = s.left(-1)
	return "0" if s == "-0" else s

static func _entero(v):
	return int(v) if v is float and v == floorf(v) else v

static func hash_de(v) -> String:
	return canonico(v).sha256_text()

## Contenido canónico de un archivo de reglas: «ausente» o «ilegible» si no existe o no es JSON de objeto.
static func _archivo(ruta: String):
	if not FileAccess.file_exists(ruta): return "ausente"
	var o = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return o if typeof(o) == TYPE_DICTIONARY else "ilegible"

static func _mapa_catalogos() -> Dictionary:
	var guion: Script = C   # get_script_constant_map no es estático: se llama sobre el recurso del script
	return guion.get_script_constant_map()

static func constantes() -> Dictionary:
	var mapa: Dictionary = _mapa_catalogos()
	var r := {}
	for n in CONSTANTES: r[n] = mapa[n] if mapa.has(n) else "FALTA"
	return r

## Nombres de CONSTANTES que ya no existen en catalogos.gd (un renombrado no debe pasar desapercibido).
static func constantes_faltantes() -> Array:
	var mapa: Dictionary = _mapa_catalogos()
	return CONSTANTES.filter(func(n): return not mapa.has(n))

## Hash por componente: sirve para decir qué parte de las reglas cambió.
static func componentes() -> Dictionary:
	if _cache.has("componentes"): return _cache.componentes
	var r := {}
	for id in COMPONENTES:
		var contenido := {}
		for ruta in COMPONENTES[id]: contenido[ruta] = _archivo(ruta)
		r[id] = hash_de(contenido)
	r["catalogos"] = hash_de(constantes())
	r["evaluador"] = hash_de(A.EVALUADOR_VERSION)
	_cache["componentes"] = r
	return r

## Huella total a partir de un diccionario de componentes (separado para poder probar variaciones).
static func total(comp: Dictionary) -> String:
	return hash_de({"huella": VERSION_HUELLA, "componentes": comp})

static func huella() -> String:
	return total(componentes())

## Campo `version` de cada archivo de reglas (diagnóstico legible; la huella no depende de él).
static func versiones() -> Dictionary:
	var r := {"huella": VERSION_HUELLA, "evaluador": A.EVALUADOR_VERSION}
	for id in COMPONENTES:
		for ruta in COMPONENTES[id]:
			var o = _archivo(ruta)
			if typeof(o) == TYPE_DICTIONARY and o.has("version"): r[ruta.get_file().get_basename()] = _entero(o.version)
	return r

## Sello que se guarda con el mundo.
static func sello() -> Dictionary:
	return {"huella": huella(), "evaluador": A.EVALUADOR_VERSION, "versiones": versiones(),
		"componentes": componentes().duplicate(), "contaminado": false}

## Sello de un mundo cargado con la excepción de desarrollo: conserva el origen y queda marcado para siempre.
static func sello_contaminado(previo) -> Dictionary:
	var s := sello()
	if previo is Dictionary:
		s["huella"] = str(previo.get("huella", ""))
		s["evaluador"] = previo.get("evaluador", null)
		s["versiones"] = previo.get("versiones", {})
		s["componentes"] = previo.get("componentes", {})
	else:
		s["huella"] = ""
		s["evaluador"] = null
		s["versiones"] = {}
		s["componentes"] = {}
	s["contaminado"] = true
	s["cargado_con"] = huella()
	return s

## {compatible, motivo, distintos}. Un sello ausente o malformado nunca es compatible.
static func comparar(guardado) -> Dictionary:
	if not guardado is Dictionary or not guardado.has("huella") or str(guardado.huella) == "":
		return {"compatible": false, "motivo": "el mundo no lleva huella de reglas", "distintos": ["sin_huella"]}
	var actual := componentes()
	var distintos: Array = []
	var previos = guardado.get("componentes", {})
	if previos is Dictionary:
		for id in actual: if str(previos.get(id, "")) != str(actual[id]): distintos.append(id)
		for id in previos: if not actual.has(id): distintos.append(str(id))
	distintos.sort()
	if str(guardado.huella) == huella() and distintos.is_empty():
		return {"compatible": true, "motivo": "", "distintos": []}
	if distintos.is_empty(): distintos.append("huella")
	return {"compatible": false, "distintos": distintos,
		"motivo": "reglas distintas a las del mundo (%s)" % ", ".join(distintos)}

## Modo de desarrollo explícito: compilación de depuración Y argumento de usuario tras `--`.
static func excepcion_dev() -> bool:
	return excepcion_de_prueba or excepcion_desde(OS.get_cmdline_user_args(), OS.is_debug_build())

static func excepcion_desde(argumentos: PackedStringArray, depuracion: bool) -> bool:
	return depuracion and ARGUMENTO_EXCEPCION in argumentos

static func reiniciar() -> void:
	_cache.clear()
