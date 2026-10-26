extends RefCounted
# Geometría y estado modificable del mundo. Celdas = Vector2i; posiciones en px = "pies" (centro-abajo).
# Valle de autor conservado; el exterior se genera por regiones con la semilla persistente de la partida.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Terreno = preload("res://scripts/terreno_v1.gd")
const Terreno2 = preload("res://scripts/terreno_v2.gd")
enum T { PASTO, CAMINO, AGUA, PARED, SUELO, PUERTA, RUINA, MURO_RUINA }
const ANCHO := 64
const ALTO := 48
const AREA_EXPEDICION := Rect2i(-32, -32, ANCHO + 64, ALTO + 64)   # el valle más dos regiones de contorno (las que juego.gd mantiene cargadas)
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
const CAMA_ORDAL := Vector2i(25, 18)     # decisión del usuario (2026-10-24); mundo-vivo story-001
const CAMAS := {"maren": CAMA_MAREN, "ordal": CAMA_ORDAL}   # cama de cada habitante (una por habitante, sin compartir)
const ESENCIALES := [Vector2i(32, 46), Vector2i(27, 23), Vector2i(27, 21), Vector2i(30, 19), Vector2i(25, 19), Vector2i(51, 37), Vector2i(52, 37),
	Vector2i(6, 7), Vector2i(50, 10)]
const N_SLIMES := 12
const DECO := ["valla", "barril"]    # decoración sólida, no rompible
const DECORADO := {"valla": [Vector2i(33, 19), Vector2i(33, 20), Vector2i(33, 21), Vector2i(22, 20), Vector2i(22, 21)],
	"barril": [Vector2i(33, 22), Vector2i(23, 22)]}

var celdas := PackedInt32Array()
var objetos := {}            # id -> {t, c}   (estático, derivado del MAPA)
var por_celda := {}          # Vector2i -> id
var spawns_slime: Array = []
var estado := {"rotos": {}, "golpes": {}, "constr": {}, "caminos": {}, "pisadas": {}, "techos": {}}   # lo único que se guarda
var generador
var regiones: Dictionary = {} # Caché descartable: nunca se guarda terreno sin modificar.
var _firma_regiones := ""
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
	for id in CAMAS: estado.constr[clave(CAMAS[id])] = {"t": "cama", "propia": false}
	_generar_slimes()

## Registro de poblados (Mundo 1, paso 1a): el Valle actual descrito como datos. Hoy solo documenta y expone las mismas
## constantes de arriba; ningún consumidor lo lee todavía (paso 1b). Un poblado nuevo sería otra entrada con su propio id.
const ID_INICIAL := "inicial"
const CENTRO_INICIAL := Vector2i(32, 23)     # cruce del camino sur con el camino este-oeste

static func poblado_inicial() -> Dictionary:
	var esenciales: Array = []
	for e in ESENCIALES: esenciales.append([e.x, e.y])
	var camas := {}
	for id in CAMAS: camas[id] = [CAMAS[id].x, CAMAS[id].y]
	return {"id": ID_INICIAL, "nombre": "Valle", "estado": "activo", "centro": [CENTRO_INICIAL.x, CENTRO_INICIAL.y],
		"area": [0, 0, ANCHO, ALTO], "entrada": [ENTRADA.x, ENTRADA.y], "esenciales": esenciales, "camas": camas}

## Modos de aparición de los jugadores (`estado.inicio.modo`). `legado`: `punto_inicio` como siempre (celda aleatoria válida del Valle).
## `poblado`: alrededor del centro del poblado inicial, validada con el estado actual (Mundo 1, paso 1c).
const MODO_LEGADO := "legado"
const MODO_POBLADO := "poblado"
## Radio del núcleo habitado sin nidos de slime: radio máximo de aparición (7 celdas) + radio de detección del slime (80 px = 5 celdas), de modo que
## ninguna celda de aparición queda dentro de la detección de un slime generado. `prueba_amenazas` comprueba que no baja de esa suma.
const NUCLEO_RADIO := 12.0
const SIN_CELDA := Vector2i(-1, -1)   # `entrada()` de un poblado que no existe

## Datos del poblado `poblado_id` ({} si no existe en el registro de este mundo).
## Modo de aparición vigente en este mundo.
func modo_inicio() -> String:
	return str(estado.get("inicio", {}).get("modo", MODO_LEGADO))

func poblado(poblado_id: String) -> Dictionary:
	return estado.get("poblados", {}).get(poblado_id, {})

## Solo cuando el guardado o la réplica no traen el registro (nunca cuando el registro existe sin ese poblado) el poblado
## inicial se describe con las constantes; cualquier otro id inexistente da vacío.
func _respaldo(poblado_id: String) -> bool:
	return poblado_id == ID_INICIAL and not estado.has("poblados")

## Entrada del poblado indicado; `SIN_CELDA` si no existe. Sin registro, el poblado inicial usa `ENTRADA`.
func entrada(poblado_id: String) -> Vector2i:
	var p: Dictionary = poblado(poblado_id)
	if p.has("entrada"): return Vector2i(int(p.entrada[0]), int(p.entrada[1]))
	return ENTRADA if _respaldo(poblado_id) else SIN_CELDA

## Celdas que la construcción no puede cerrar en el poblado indicado; [] si no existe. Sin registro, el inicial usa `ESENCIALES`.
func esenciales(poblado_id: String) -> Array:
	var p: Dictionary = poblado(poblado_id)
	if not p.has("esenciales"): return ESENCIALES if _respaldo(poblado_id) else []
	var l: Array = []
	for e in p.esenciales: l.append(Vector2i(int(e[0]), int(e[1])))
	return l

## Camas fijas del poblado indicado (id de habitante -> celda); {} si no existe. Sin registro, el inicial usa `CAMAS`.
func camas(poblado_id: String) -> Dictionary:
	var p: Dictionary = poblado(poblado_id)
	if not p.has("camas"): return CAMAS if _respaldo(poblado_id) else {}
	var d := {}
	for id in p.camas: d[id] = Vector2i(int(p.camas[id][0]), int(p.camas[id][1]))
	return d

## Hitos del poblado inicial (Mundo 1, paso 1d): lugares ya existentes en el Valle con nombre y área [x, y, ancho, alto]. La plaza y el taller son los
## «lugares» de datos/mundo/entities/lugar (celdas 34,25 y 28,20); el resto, las áreas del mapa de autor. Solo entran en el registro en modo poblado.
const HITOS_INICIALES := [
	{"id": "taller", "nombre": "La casa del taller", "area": [24, 16, 8, 7]},   # va antes que la plaza: su área tiene prioridad dentro de la casa
	{"id": "plaza", "nombre": "La plaza", "area": [25, 16, 15, 15]},   # cubre todo el círculo de aparición (2-7 celdas del cruce 32,23)
	{"id": "estanque", "nombre": "El estanque", "area": [42, 26, 10, 11]},
	{"id": "cantera", "nombre": "La cantera", "area": [4, 4, 13, 11]},
	{"id": "bosque", "nombre": "El bosque", "area": [38, 3, 24, 14]},
	{"id": "ruinas", "nombre": "Las ruinas", "area": [46, 38, 12, 9]},
	{"id": "entrada_sur", "nombre": "La entrada sur", "area": [30, 44, 5, 4]},
]
## Instalaciones comunitarias iniciales (sin dueño: «las estaciones son del mundo»): la mesa de trabajo del taller y el horno de la cantera,
## junto a la plaza, donde todos las ven. Las usan los habitantes (`permite_estacion`: sin dueño de grupo) y los jugadores.
const INSTALACIONES_INICIALES := ["mesa", "horno"]

## Nombre del hito que contiene la celda ("" si ninguno): referencia de orientación para el HUD (y, más adelante, el mapa).
func hito_en(c: Vector2i) -> String:
	for h in poblado(ID_INICIAL).get("hitos", []):
		var a: Array = h.area
		if Rect2i(int(a[0]), int(a[1]), int(a[2]), int(a[3])).has_point(c): return str(h.nombre)
	return str(lugar_en(c).get("nombre", ""))

## Primera celda libre de hierba a distancia Chebyshev rmin..rmax de `centro` (anillos crecientes, y luego y, x), fuera de las celdas esenciales.
func _celda_libre_cerca(centro: Vector2i, rmin: int, rmax: int) -> Vector2i:
	for r in range(rmin, rmax + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r: continue
				var c := centro + Vector2i(dx, dy)
				if es_valle(c) and tipo(c) == T.PASTO and puede_poner(c) == "" and not esenciales(ID_INICIAL).has(c): return c
	return SIN_CELDA

## Solo al CREAR un mundo en modo poblado: registra los hitos y coloca las instalaciones comunitarias junto a la plaza (mesa y, pegado a ella,
## el horno), comprobando que siguen siendo alcanzables todas las celdas esenciales. No se vuelve a llamar al cargar: si alguien las derriba,
## no reaparecen.
func instalar_poblado_inicial() -> void:
	var p: Dictionary = estado.get("poblados", {}).get(ID_INICIAL, {})
	if p.is_empty() or p.has("instalaciones"): return
	p["hitos"] = HITOS_INICIALES.duplicate(true)
	var puestas: Array = []
	var ancla := Vector2i(34, 25)
	var rmin := 1
	for pieza in INSTALACIONES_INICIALES:
		var c := _celda_libre_cerca(ancla, rmin, 5)
		while c != SIN_CELDA:
			poner(c, pieza, false)
			var alc: Dictionary = alcanzables()
			var ok := true
			for e in esenciales(ID_INICIAL): if not alc.has(e): ok = false
			if ok: break
			quitar(c)
			c = _celda_libre_cerca(c, 1, 5)
		if c == SIN_CELDA: continue
		puestas.append({"pieza": pieza, "celda": [c.x, c.y]})
		ancla = c
		rmin = 1
	p["instalaciones"] = puestas

## Ids de los poblados del registro: el inicial primero y el resto por orden alfabético (orden estable).
func poblados_ids() -> Array:
	var ids: Array = estado.get("poblados", {}).keys()
	ids.sort()
	if ids.has(ID_INICIAL):
		ids.erase(ID_INICIAL)
		ids.push_front(ID_INICIAL)
	return ids

## ¿Puede un jugador aparecer en `c`? Terreno transitable, 3×3 sin bloqueo (las mismas condiciones que `punto_inicio`) y conectada
## con `alc` (alcanzables desde la entrada del poblado). No mira ocupación ni enemigos: eso es de `Juego.punto_aparicion`.
func celda_apta_aparicion(c: Vector2i, alc: Dictionary) -> bool:
	var t := tipo(c)
	if t != T.PASTO and t != T.CAMINO: return false
	if not alc.has(c): return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if bloquea(c + Vector2i(dx, dy)): return false
	return true

## Migración aditiva: el valle y todas sus diferencias se mantienen.
func configurar(semilla: int) -> void:
	for campo in ["caminos", "pisadas", "techos"]:
		if not estado.has(campo): estado[campo] = {}   # guardados anteriores
	if not estado.has("poblados"): estado.poblados = {ID_INICIAL: poblado_inicial()}
	if not estado.has("inicio"): estado.inicio = {"modo": MODO_LEGADO}   # cómo aparecen los jugadores (Mundo 1, paso 1c); guardados sin la clave: legado
	if modo_inicio() == MODO_POBLADO: regenerar_amenazas_nucleo()   # sin nidos de slime en el núcleo habitado (paso 1e)
	if not estado.has("generacion"): estado.generacion={"version":1,"semilla":semilla,"region":Terreno.TAM}
	generador=Terreno2.new(int(estado.generacion.semilla)) if int(estado.generacion.version)==2 else Terreno.new(int(estado.generacion.semilla))
	_firma_regiones=""

static func es_valle(c: Vector2i) -> bool:
	return Rect2i(0,0,ANCHO,ALTO).has_point(c)

func valida(c: Vector2i) -> bool:
	return es_valle(c) or (generador!=null and generador.valida(c))

func region_cargada(c: Vector2i) -> bool:
	return es_valle(c) or regiones.has(clave(Terreno.region(c)))

## Unión de los alrededores de todos los jugadores, con descarga de regiones distantes.
## El valle permanece residente para sostener los habitantes actuales.
func actualizar_regiones(centros: Array) -> void:
	if generador==null:return
	var centros_region: Array=[]
	for c in centros:
		var r:=Terreno.region(c)
		var k:=clave(r)
		if not centros_region.has(k):centros_region.append(k)
	centros_region.sort()
	var firma: String=";".join(centros_region)
	if firma==_firma_regiones:return
	_firma_regiones=firma
	var deseadas: Dictionary={}
	for k in centros_region:
		var r:=Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
		for y in range(r.y-2,r.y+3):
			for x in range(r.x-2,r.x+3):
				var pos:=Vector2i(x,y)
				var esquina:=pos*Terreno.TAM
				if not generador.valida(esquina):continue
				if Rect2i(0,0,ANCHO,ALTO).encloses(Rect2i(esquina,Vector2i(Terreno.TAM,Terreno.TAM))):continue
				deseadas[clave(pos)]=pos
	for k in regiones.keys():
		if deseadas.has(k):continue
		for id in regiones[k].ids:
			por_celda.erase(objetos[id].c)
			objetos.erase(id)
		regiones.erase(k)
	for k in deseadas:
		if regiones.has(k):continue
		var datos: Dictionary=generador.generar_region(deseadas[k])
		var ids: Array=[]
		for recurso in datos.recursos:
			if es_valle(recurso.c) or estado.get("registro", {}).get("despejes", {}).has(clave(recurso.c)):continue
			var tipo_recurso: String = str(recurso.t)
			# Conserva diferencias de estaño de la versión intermedia que aún se guardaba como v1.
			var id_estano: String = "veta_estano@" + clave(recurso.c)
			if int(estado.generacion.version)==1 and (estado.rotos.has(id_estano) or estado.golpes.has(id_estano)): tipo_recurso="veta_estano"
			var id: String=tipo_recurso+"@"+clave(recurso.c)
			_agregar(tipo_recurso,recurso.c,id)
			ids.append(id)
		datos.ids=ids
		regiones[k]=datos
	cambiar()

func _indice_exterior(c: Vector2i) -> int:
	return posmod(c.y,Terreno.TAM)*Terreno.TAM+posmod(c.x,Terreno.TAM)

func bioma(c: Vector2i) -> String:
	if es_valle(c):return "valle"
	if generador==null:return "limite"
	var region: Dictionary=regiones.get(clave(Terreno.region(c)),{})
	return str(region.biomas[_indice_exterior(c)]) if not region.is_empty() else str(generador.datos(c).bioma)

## Datos de recursos descargados: reconstrucción pura, sin volver a cargar la región.
func datos_objeto(id: String) -> Dictionary:
	if objetos.has(id):return objetos[id]
	if generador==null or not id.contains("@"):return {}
	var partes:=id.get_slice("@",1).split(",")
	if partes.size()!=2 or not partes[0].is_valid_int() or not partes[1].is_valid_int():return {}
	var c:=Vector2i(int(partes[0]),int(partes[1]))
	if es_valle(c) or not generador.valida(c) or estado.get("registro", {}).get("despejes", {}).has(clave(c)):return {}
	var d: Dictionary=generador.datos(c)
	if int(estado.generacion.version)==1 and id=="veta_estano@"+clave(c) and (estado.rotos.has(id) or estado.golpes.has(id)): d.objeto="veta_estano"
	return {"t":str(d.objeto),"c":c} if str(d.objeto)!="" and id==str(d.objeto)+"@"+clave(c) else {}

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

## `nucleos`: centros de poblados cuyo núcleo habitado se excluye (modo poblado, Mundo 1 paso 1e); vacío = generación de siempre.
func _generar_slimes(nucleos: Array = []) -> void:
	var k := 0
	while spawns_slime.size() < N_SLIMES and k < 4000:
		var c := Vector2i(h(k, 1, MAPA) % ANCHO, h(k, 2, MAPA) % ALTO)
		k += 1
		if not _libre_para_objeto(c) or por_celda.has(c): continue
		if Vector2(c).distance_to(Vector2(ENTRADA)) < 14.0 or Vector2(c).distance_to(Vector2(CLARO)) < 8.0: continue
		var en_nucleo := false
		for n in nucleos: if Vector2(c).distance_to(Vector2(n)) < NUCLEO_RADIO: en_nucleo = true
		if en_nucleo: continue
		spawns_slime.append(c)

## Mundo 1, paso 1e: en el modo poblado los slimes no anidan en el núcleo habitado de ningún poblado del registro. Se vuelven a generar con la
## misma secuencia determinista saltando los puntos del núcleo (siguen siendo N_SLIMES y los demás conservan su lugar). Es una regla de la
## generación inicial, no una zona invulnerable: un slime que persigue a alguien puede entrar en el pueblo.
func regenerar_amenazas_nucleo() -> void:
	var centros: Array = []
	for pid in poblados_ids():
		var p: Dictionary = poblado(pid)
		if p.has("centro"): centros.append(Vector2i(int(p.centro[0]), int(p.centro[1])))
	spawns_slime.clear()
	_generar_slimes(centros)

static func clave(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]

func tipo(c: Vector2i) -> int:
	var t := _base(c)
	return T.CAMINO if t == T.PASTO and estado.get("caminos", {}).has(clave(c)) else t

func _base(c: Vector2i) -> int:
	if not piso_en(c).is_empty(): return T.SUELO
	var cambios: Dictionary = estado.get("registro", {}).get("suelos", {})
	if cambios.has(clave(c)): return int(cambios[clave(c)])
	if es_valle(c):return celdas[c.y*ANCHO+c.x]
	if generador==null or not generador.valida(c):return T.AGUA
	var region: Dictionary=regiones.get(clave(Terreno.region(c)),{})
	return int(region.terreno[_indice_exterior(c)]) if not region.is_empty() else int(generador.datos(c).tipo)

## Cada paso sobre hierba libre la gasta; al llegar al umbral queda un camino (se guarda y se replica).
func pisar(c: Vector2i) -> void:
	if _base(c) != T.PASTO or estado.caminos.has(clave(c)) or not constr_en(c).is_empty() or objeto_presente(c) != "": return
	var k := clave(c)
	estado.pisadas[k] = int(estado.pisadas.get(k, 0)) + 1
	if int(estado.pisadas[k]) >= C.PISADAS_CAMINO:
		estado.pisadas.erase(k)
		estado.caminos[k] = true
		cambiar()

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
		if es_valle(Vector2i(int(p[0]),int(p[1]))) and C.CONSTR[estado.constr[k].t].bloquea: _bloq[int(p[1]) * ANCHO + int(p[0])] = 1
	_bloq_v = version

func bloquea(c: Vector2i) -> bool:
	if not valida(c) or not region_cargada(c):return true
	if not es_valle(c):
		if tipo(c) in [T.AGUA, T.PARED, T.MURO_RUINA]:return true
		if C.CONSTR.get(constr_en(c).get("t",""),{}).get("bloquea",false):return true
		var id:=objeto_presente(c)
		return id!="" and bool(C.OBJETOS.get(objetos[id].t,{}).get("bloquea",true))
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
		var objeto:=datos_objeto(id)
		if objeto.is_empty() or not C.OBJETOS.has(objeto.t):continue
		var r: int = C.OBJETOS[objeto.t].regen_h
		if r > 0 and hora - estado.rotos[id] >= r * 60:
			var c: Vector2i = objeto.c
			if constr_en(c).is_empty() and piso_en(c).is_empty() and not ocupada.call(c):
				estado.rotos.erase(id)
				n += 1
	if n > 0: cambiar()
	return n

# Reglas estáticas de colocación (no incluye actores ni alcanzabilidad: las evalúa Juego).
func puede_poner(c: Vector2i) -> String:
	if not valida(c) or not region_cargada(c): return "fuera de las regiones cargadas"
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
	_edificio_editado(c)
	cambiar()

## Los techos van aparte de las piezas: una celda puede tener cama, mesa o muro y además techo. El valor es el dueño.
func puede_techar(c: Vector2i) -> String:
	if not valida(c) or not region_cargada(c): return "fuera de las regiones cargadas"
	var t := tipo(c)
	if t != T.PASTO and t != T.CAMINO and t != T.SUELO: return "terreno no construible"
	if objeto_presente(c) != "": return "ocupado por un objeto"
	if estado.techos.has(clave(c)): return "ya tiene techo"
	return ""

func techar(c: Vector2i, dueno: String) -> void:
	estado.techos[clave(c)] = dueno
	_edificio_editado(c)
	cambiar()

func destechar(c: Vector2i) -> void:
	estado.techos.erase(clave(c))
	_edificio_editado(c)
	cambiar()

func quitar(c: Vector2i) -> void:
	estado.constr.erase(clave(c))
	_edificio_editado(c)
	cambiar()

static func pies_de_celda(c: Vector2i) -> Vector2:
	return Vector2(c.x * P.CELDA + P.CELDA / 2.0, c.y * P.CELDA + 12)

static func celda_de(pies: Vector2) -> Vector2i:
	return Vector2i(((pies - Vector2(0, 1)) / P.CELDA).floor())   # -1 px: el borde inferior pertenece a la celda de arriba

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

## Celdas alcanzables desde `desde`. Si `hasta` (celdas como claves) no está vacío, la búsqueda se detiene al alcanzar
## cualquiera de ellas y devuelve lo visitado hasta ahí; sin `hasta` o sin alcanzar ninguna devuelve el conjunto completo.
func alcanzables(desde: Vector2i = ENTRADA, area: Rect2i = Rect2i(), hasta: Dictionary = {}) -> Dictionary:
	if area.size==Vector2i.ZERO:area=_area_ruta(desde)
	var vistas := {desde: true}
	if hasta.has(desde): return vistas
	var cola := [desde]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if area.has_point(n) and not vistas.has(n) and not bloquea(n):
				vistas[n] = true
				if hasta.has(n): return vistas
				cola.append(n)
	return vistas

# BFS 4-vecinos. Termina al llegar a una celda que cumple meta. [] si no hay ruta; [desde] si ya cumple.
func camino(desde: Vector2i, meta: Callable, area: Rect2i = Rect2i(), transitable: Callable = Callable()) -> Array:
	if area.size==Vector2i.ZERO:area=_area_ruta(desde)
	if meta.call(desde): return [desde]
	var prev := {desde: desde}
	var cola := [desde]
	var i := 0
	while i < cola.size():
		var c: Vector2i = cola[i]
		i += 1
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if not area.has_point(n) or prev.has(n) or bloquea(n): continue
			if transitable.is_valid() and not transitable.call(n): continue
			prev[n] = c
			if meta.call(n):
				var ruta := [n]
				while ruta[0] != desde: ruta.push_front(prev[ruta[0]])
				return ruta
			cola.append(n)
	return []

func _area_ruta(desde: Vector2i) -> Rect2i:
	if es_valle(desde):return Rect2i(0,0,ANCHO,ALTO)
	return Rect2i(Terreno.region(desde)*Terreno.TAM-Vector2i(Terreno.TAM,Terreno.TAM),Vector2i(Terreno.TAM*3,Terreno.TAM*3))

## Validación finita: nunca recorre un mundo ilimitado para colocar una pared.
func construccion_segura(c: Vector2i, actores: Array) -> bool:
	if es_valle(c):
		var alc:=alcanzables()
		for e in esenciales(ID_INICIAL):if not alc.has(e):return false   # alcanzabilidad desde la entrada del Valle: solo su pueblo
		for actor in actores:
			if es_valle(actor) and not (alc.has(actor) or bloquea(actor)):return false
		return true
	var vecinos: Array=[]
	for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		if not bloquea(c+d):vecinos.append(c+d)
	if vecinos.size()<2:return true
	var area:=_area_ruta(c)
	var alc:=alcanzables(vecinos[0],area)
	for vecino in vecinos:if not alc.has(vecino):return false
	return true

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

## Aplica la geometría registrada y descarga los recursos desplazados por la génesis de lugares/rutas.
## Las regiones siguen siendo caché; estas decisiones están en el guardado y vienen del servidor.
func aplicar_registro() -> void:
	var despejes: Dictionary = estado.get("registro", {}).get("despejes", {})
	for k in regiones:
		var presentes: Array = []
		for id in regiones[k].ids:
			if despejes.has(clave(objetos[id].c)):
				por_celda.erase(objetos[id].c)
				objetos.erase(id)
			else: presentes.append(id)
		regiones[k].ids = presentes
	if not estado.get("registro",{}).get("edificios",{}).is_empty():
		for id in objetos.keys():
			if es_valle(objetos[id].c) and despejes.has(clave(objetos[id].c)):
				por_celda.erase(objetos[id].c)
				objetos.erase(id)
	cambiar()

## Lugar persistente que contiene la celda, sin crear ninguno al consultar.
func lugar_en(c: Vector2i) -> Dictionary:
	for lugar in estado.get("registro", {}).get("lugares", {}).values():
		var a: Array = lugar.area
		if Rect2i(a[0], a[1], a[2], a[3]).has_point(c): return lugar
	return {}

## Suelo construido en una capa independiente: admite muebles y conserva identidad/propiedad.
func piso_en(c: Vector2i) -> Dictionary:
	return estado.get("registro",{}).get("pisos",{}).get(clave(c),{})

## Unidad persistente que contiene la celda; consultar nunca crea datos de mundo.
func edificio_en(c: Vector2i) -> Dictionary:
	for e in estado.get("registro",{}).get("edificios",{}).values():
		var a: Array = e.area
		if Rect2i(a[0],a[1],a[2],a[3]).has_point(c): return e
	return {}

func _edificio_editado(c: Vector2i) -> void:
	var e := edificio_en(c)
	if not e.is_empty(): e.revision = int(e.revision)+1
