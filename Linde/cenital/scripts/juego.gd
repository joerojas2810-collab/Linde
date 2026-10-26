extends RefCounted
# Autoridad única del estado: inventario, mundo, misiones, progresión. La UI (o un servidor) pide acciones y muestra resultados.
# Estado persistente = d (JSON): lo COMPARTIDO (semilla, min, mundo, cofres, jefes, npcs) en la raíz y lo de cada
# jugador en d.jugadores[id]. Todas las acciones reciben el id del jugador que las ejecuta (por defecto P.LOCAL).
# Rutas y temporizadores son de sesión. La fauna regional conserva heridas y bajas en d.fauna;
# los encuentros del valle se reconstruyen al cargar, respetando el estado durable de los jefes.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Guard = preload("res://scripts/guardado.gd")
const Hab = preload("res://scripts/habitantes.gd")
const Autonomia = preload("res://scripts/autonomia.gd")
const Vivo = preload("res://scripts/mundo_vivo.gd")
const Comb = preload("res://scripts/combate.gd")
const Anim = preload("res://scripts/anim_pj.gd")
const Eq = preload("res://scripts/equipo.gd")
const Lugares = preload("res://scripts/lugares.gd")
const Pistas = preload("res://scripts/pistas.gd")
const Edificios = preload("res://scripts/edificios.gd")
const Exploracion = preload("res://scripts/exploracion.gd")
const LOCAL := P.LOCAL
const CAP_COFRE := 30
const ALCANCE_ESTACION := 2     # celdas (Chebyshev)
const ALCANCE_NPC := 32.0       # px
const EQUIPO_VACIO := {"casco": "", "torso": "", "guantes": "", "botas": "", "pantalones": "", "escudo": "", "arma": ""}   # = C.RANURAS

var d := {}
var mundo := Mundo.new()
var habitantes
var autonomia
var vivo    # director de Mundo vivo (variables + eventos)
var combate
var rt := {}            # id -> {pies, mira, cd_obj, herr_t, msgs}: sesión de cada jugador (pies se vuelca a pos al guardar)
var _acum := 0.0
var _seg := 0.0

# Compatibilidad: accesos directos al jugador local (UI de un jugador y pruebas existentes).
var pies: Vector2:
	get: return rt[LOCAL].pies
	set(v): rt[LOCAL].pies = v
var mira: Vector2i:
	get: return rt[LOCAL].mira
	set(v): rt[LOCAL].mira = v
var cd_obj: float:
	get: return rt[LOCAL].cd_obj
	set(v): rt[LOCAL].cd_obj = v
var herr_t: float:       # s restantes de la animación de herramienta (solo animación)
	get: return rt[LOCAL].herr_t
	set(v): rt[LOCAL].herr_t = v
var msgs: Array:
	get: return rt[LOCAL].msgs

static func nuevo_jugador(nombre: String, look: Array, p: Vector2) -> Dictionary:
	return {"nombre": nombre.strip_edges().substr(0, 16) if nombre.strip_edges() != "" else "Viajero", "look": look.duplicate(),
		"pos": [p.x, p.y], "hp": C.HP_BASE, "cama": [], "inicio": [p.x, p.y],
		"inv": {}, "equipo": EQUIPO_VACIO.duplicate(), "hab": [], "xp": 0, "misiones": {}, "eventos": {}, "recompensas": [],
		"pendientes": {}, "relacion": {}}

## `modo_inicio`: ver `Mundo.MODO_LEGADO` / `MODO_POBLADO`. Los mundos que se juegan (escena) usan `MODO_JUEGO`; las pruebas y herramientas, `legado` salvo que lo pidan.
const MODO_JUEGO := Mundo.MODO_POBLADO   # validado con medir_aparicion (production/qa/evidence/mundo-1/fase-1c); las pruebas y herramientas siguen en legado por defecto
static func nueva(semilla: int, nombre: String, look: Array, modo_inicio: String = Mundo.MODO_LEGADO):
	var j = new()
	j.d = {"semilla": semilla}
	var p := Mundo.pies_de_celda(j.mundo.punto_inicio(semilla))
	var rt_: RandomNumberGenerator = j._rng("botin", "tesoro_cantera")
	var cont := {"gema": 1}
	if rt_.randf() < 0.5: cont["lingote"] = 1
	if rt_.randf() < 0.5: cont["mena"] = 3
	j.d = {"formato": Guard.FORMATO, "contenido": 1, "gen": 1, "semilla": semilla, "min": 6 * 60,
		"cofres": {"tesoro_cantera": {"inv": cont, "abierto": false}}, "mundo": j.mundo.estado, "jefes": {}, "npcs": {},
		"jugadores": {LOCAL: nuevo_jugador(nombre, look, p)}}
	j.d.mundo.generacion = {"version": 2, "semilla": semilla, "region": 16}
	j.d.mundo.inicio = {"modo": modo_inicio}
	j._arrancar(true)
	if modo_inicio == Mundo.MODO_POBLADO:   # necesita los habitantes y los enemigos, que existen tras _arrancar()
		j.mundo.instalar_poblado_inicial()   # hitos e instalaciones comunitarias (paso 1d), antes de elegir dónde aparece el jugador
		var ap: Dictionary = j.punto_aparicion(LOCAL)
		j._registrar_aparicion(LOCAL, ap)
		if ap.ok:
			var pies := Mundo.pies_de_celda(ap.celda)
			j.rt[LOCAL].pies = pies
			j.d.jugadores[LOCAL].pos = [pies.x, pies.y]
			j.d.jugadores[LOCAL].inicio = [pies.x, pies.y]
		else:   # mundo recién creado: su poblado inicial no puede estar destruido; se conserva la celda validada por punto_inicio y queda registrado
			push_warning("Mundo nuevo sin posición de aparición en el poblado: %s" % ap.motivo)
	j.actualizar_mapa()
	return j

## Resultado de la última `cargar` fallida ({} si no falló o no hubo archivo): `error`, `motivo`, `detalle`, `archivo` de Guardado.cargar.
static var ultimo_error: Dictionary = {}

static func cargar(ruta: String):
	var r := Guard.cargar(ruta)
	ultimo_error = r if r.has("error") else {}
	if r.d.is_empty(): return null
	var j = new()
	j.d = _enteros(r.d)
	for id in j.d.jugadores:
		_sanear_equipo(j.d.jugadores[id])
	j._arrancar()
	j.aviso("Partida cargada (%s)." % r.origen)
	return j

## Texto para el jugador de una carga fallida (`ultimo_error`). Distingue «reglas distintas» (mundo de otra versión del juego, el
## archivo no se toca) de un archivo ilegible; la unión a un servidor con reglas distintas tiene su propio mensaje en red_servidor.gd.
static func mensaje_carga(e: Dictionary) -> String:
	if str(e.get("error", "")) == "reglas_distintas":
		var d: Array = e.get("detalle", {}).get("distintos", [])
		return "Este mundo se creó con otras reglas de juego (%s). El archivo no se modifica." % ", ".join(PackedStringArray(d))
	return "No hay partida legible (el archivo no se borra). Crea una nueva."

# Equipo al cargar: ranuras que falten = ""; lo que no sea equipable en su ranura (clave desconocida, ranura vieja)
# pasa a pendientes (nunca se borra ni se duplica) y se avisa. Las claves desconocidas del inventario se quedan
# como «Pieza desconocida» (Equipo.info), no equipables.
static func _sanear_equipo(pj: Dictionary) -> void:
	var eq: Dictionary = pj.get("equipo", {})
	pj["equipo"] = eq
	if not pj.has("pendientes"): pj["pendientes"] = {}
	for r in eq.keys():
		var k := str(eq[r])
		if k == "" or (r in C.RANURAS and str(Eq.info(k).get("equipo", "")) == r): continue
		pj.pendientes[k] = int(pj.pendientes.get(k, 0)) + 1
		push_warning("equipo: «%s» en la ranura %s no es equipable; pasa a pendientes" % [k, r])
		if r in C.RANURAS: eq[r] = ""
		else: eq.erase(r)
	for r in C.RANURAS: if not eq.has(r): eq[r] = ""
	for k in pj.get("inv", {}):
		if Eq.info(k).get("desconocida", false): push_warning("inventario: clave desconocida «%s» (Pieza desconocida)" % k)

# JSON devuelve todo como float; los enteros vuelven a ser enteros.
static func _enteros(v):
	match typeof(v):
		TYPE_FLOAT: return int(v) if v == floorf(v) else v
		TYPE_DICTIONARY:
			for k in v: v[k] = _enteros(v[k])
		TYPE_ARRAY:
			for i in v.size(): v[i] = _enteros(v[i])
	return v

## Distingue la simulación autoritativa de las réplicas sin efectos locales.
## Identidad persistente para conocimientos y práctica, también en red.
func actor_desarrollo(id: String = LOCAL) -> String:
	return "pj:" + id

func es_autoridad() -> bool:
	return true

func _arrancar(nuevo: bool = false) -> void:
	mundo.estado = d.mundo
	mundo.configurar(int(d.semilla))
	mundo.cambiar()
	for id in d.jugadores: _sesion(id)
	actualizar_regiones()
	vivo = Vivo.new(self)
	vivo.restaurar()
	habitantes = Hab.new(self)
	habitantes.restaurar()
	autonomia = Autonomia.new(self)
	combate = Comb.new(self)
	combate.reiniciar()
	if nuevo: autonomia.asentamientos.inicializar_preexistentes()
	evaluar_misiones()

func _sesion(id: String) -> void:
	var pos: Array = d.jugadores[id].pos
	rt[id] = {"pies": Vector2(pos[0], pos[1]), "mira": Vector2i.DOWN, "cd_obj": 0.0, "herr_t": 0.0, "msgs": []}

## Aparición en un poblado (Mundo 1, paso 1c). Valores de PRUEBA (M1-C2), no de balance: radio de 2 a 7 celdas del centro del poblado
## (7 = mitad del alto del encuadre medido, ±7,5) y separación mínima de 2 celdas entre jugadores (el sprite ocupa 1 celda).
const APARICION_RADIO_MIN := 2.0
const APARICION_RADIO_MAX := 7.0
const APARICION_SEPARACION := 2

## Habitantes presentes del poblado. Hoy solo el inicial tiene vínculo con `habitantes`; los demás declaran `residentes` en el registro.
func _residentes_presentes(poblado_id: String) -> int:
	if poblado_id == Mundo.ID_INICIAL: return habitantes.ids.size()
	return mundo.poblado(poblado_id).get("residentes", []).size()

## Fuera del radio de detección (`vision` del catálogo) de cada enemigo vivo: no lo adquiere al aparecer. Política provisional hasta 1e.
func _a_salvo_de_enemigos(c: Vector2i) -> bool:
	var centro_pj := Mundo.pies_de_celda(c) - Vector2(0, 6)   # igual que Combate.centro_pj
	for e in combate.enemigos:
		if e.est == "muerto": continue
		if Comb.centro(e).distance_to(centro_pj) <= float(C.ENEMIGOS[e.tipo].vision): return false
	return true

## Celda donde aparecería `jugador_id`: {ok, celda, poblado, motivo}. Prueba los poblados en orden (el inicial primero) y toma el primero
## activo, con habitantes presentes y alguna celda válida. Sin ninguno: ok = false con el motivo; NO inventa una celda, NO recurre a
## `punto_inicio` ni a la entrada y NO reactiva un poblado que no está activo. El hash (`_rng`) solo escoge entre celdas ya validadas.
func punto_aparicion(jugador_id: String) -> Dictionary:
	var otros: Array = []
	for k in rt:
		if k != jugador_id: otros.append(Mundo.celda_de(rt[k].pies))
	var motivo := "sin_poblado_activo"
	for pid in mundo.poblados_ids():
		var p: Dictionary = mundo.poblado(pid)
		if str(p.get("estado", "")) != "activo": continue
		if _residentes_presentes(pid) <= 0:
			motivo = "sin_residentes"
			continue
		var entrada := mundo.entrada(pid)
		if entrada == Mundo.SIN_CELDA or not p.has("centro"):
			motivo = "poblado_sin_datos"
			continue
		var centro := Vector2i(int(p.centro[0]), int(p.centro[1]))
		if pid != Mundo.ID_INICIAL:
			var centros: Array = [centro]
			for actor in rt.values(): centros.append(Mundo.celda_de(actor.pies))
			for nid in habitantes.ids: centros.append(Mundo.celda_de(habitantes.pos(nid)))
			mundo.actualizar_regiones(centros)
		var alc: Dictionary = mundo.alcanzables(entrada)
		var validas: Array = []
		var r_max := int(ceil(APARICION_RADIO_MAX))
		for dy in range(-r_max, r_max + 1):
			for dx in range(-r_max, r_max + 1):
				var dist := Vector2(dx, dy).length()
				if dist < APARICION_RADIO_MIN or dist > APARICION_RADIO_MAX: continue
				var c := centro + Vector2i(dx, dy)
				if not mundo.celda_apta_aparicion(c, alc) or ocupada(c) or not _a_salvo_de_enemigos(c): continue
				validas.append([dist, c.y, c.x])
		validas.sort()
		if validas.is_empty():
			motivo = "sin_celda_valida"
			continue
		var separadas: Array = validas.filter(func(v): return otros.all(func(o): return maxi(absi(o.x - v[2]), absi(o.y - v[1])) >= APARICION_SEPARACION))
		var lista: Array = separadas if not separadas.is_empty() else validas
		var v: Array = lista[_rng("aparicion", jugador_id).randi() % lista.size()]
		return {"ok": true, "celda": Vector2i(v[2], v[1]), "poblado": pid, "motivo": "poblado" if not separadas.is_empty() else "poblado_sin_separacion"}
	return {"ok": false, "celda": Mundo.SIN_CELDA, "poblado": "", "motivo": motivo}

## Anota el último resultado de aparición en el mundo (auditoría). Los fallos también quedan en el diario de sucesos.
func _registrar_aparicion(jugador_id: String, ap: Dictionary) -> void:
	var inicio: Dictionary = d.mundo.get_or_add("inicio", {"modo": Mundo.MODO_LEGADO})
	var c: Vector2i = ap.celda
	inicio["ultimo"] = {"jugador": jugador_id, "poblado": ap.poblado, "celda": [c.x, c.y], "motivo": ap.motivo, "ok": ap.ok, "min": int(d.min)}
	if not ap.ok and autonomia != null and autonomia.activa():
		autonomia.sociedad.suceso("aparicion", "Sin lugar seguro para %s (%s)" % [jugador_id, ap.motivo])

# Añade un jugador al mundo (servidor/pruebas). Empieza en el inicio de la semilla (modo legado) o en su poblado (modo poblado), con estado
# propio vacío. En modo poblado, si no hay ninguna posición segura NO se crea al jugador: {ok: false, msg} y el motivo queda registrado.
func unir(id: String, nombre: String, look: Array) -> Dictionary:
	if d.jugadores.has(id): return _no("Ese jugador ya está en el mundo", id)
	var p: Vector2
	if mundo.modo_inicio() == Mundo.MODO_POBLADO:
		var ap: Dictionary = punto_aparicion(id)
		_registrar_aparicion(id, ap)
		if not ap.ok: return {"ok": false, "msg": "No hay ningún lugar seguro donde aparecer ahora mismo (%s)." % ap.motivo}
		p = Mundo.pies_de_celda(ap.celda)
	else:
		p = Mundo.pies_de_celda(mundo.punto_inicio(int(d.semilla)))
	d.jugadores[id] = nuevo_jugador(nombre, look, p)
	_sesion(id)
	Exploracion.observar(self, id)
	evaluar_misiones(id)
	return _ok("Entras al mundo.", id)

# Red: un jugador desconectado se retira del mundo (sin cuerpo ni sesión) y conserva todo su estado, pos incluida.
# Los bucles de simulación recorren rt (presentes), no d.jugadores (todos los que han entrado alguna vez).
func salir(id: String) -> void:
	if not rt.has(id): return
	var p: Vector2 = rt[id].pies
	d.jugadores[id].pos = [p.x, p.y]
	rt.erase(id)
	combate.pjs.erase(id)
	combate.olvidar(id)

func entrar(id: String) -> void:
	if d.jugadores.has(id) and not rt.has(id): _sesion(id)

func jug(id: String = LOCAL) -> Dictionary:
	return d.jugadores[id]

func pies_de(id: String = LOCAL) -> Vector2:
	return rt[id].pies

func guardar(ruta: String) -> bool:
	combate.fauna.guardar()
	for id in rt:
		var p: Vector2 = rt[id].pies
		d.jugadores[id].pos = [p.x, p.y]
	return Guard.guardar(ruta, d)

func aviso(t: String, id: String = LOCAL) -> void:
	if not rt.has(id): return
	var m: Array = rt[id].msgs
	m.append(t)
	if m.size() > 6: m.pop_front()

func aviso_todos(t: String) -> void:
	for id in rt: aviso(t, id)

func _rng(nombre: String, clave: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = Mundo.h(int(d.semilla), nombre.hash() & 0xffffff, clave.hash() & 0xffffff)
	return r

func _ok(msg: String = "", id: String = LOCAL) -> Dictionary:
	if msg != "": aviso(msg, id)
	return {"ok": true, "msg": msg}

func _no(msg: String, id: String = LOCAL) -> Dictionary:
	aviso(msg, id)
	return {"ok": false, "msg": msg}

# ---------- tiempo (reloj compartido) ----------
func hora_dia() -> float:
	return fmod(d.min / 60.0, 24.0)

func dia() -> int:
	return floori(d.min / 1440.0) + 1

## No se guarda la caché de terreno: solo semilla, versión y alteraciones.
func actualizar_regiones() -> void:
	var centros: Array=[]
	for id in rt:centros.append(Mundo.celda_de(rt[id].pies))
	Lugares.preparar(self, centros)
	if autonomia != null and autonomia.expediciones(): centros.append_array([Vector2i(8, 8), Vector2i(56, 8), Vector2i(8, 40), Vector2i(56, 40)])   # el contorno del valle, para que los habitantes salgan
	mundo.actualizar_regiones(centros)

func tick(dt: float) -> void:
	actualizar_regiones()
	_acum += dt * C.MIN_POR_SEG
	while _acum >= 1.0:
		_acum -= 1.0
		d.min += 1
		autonomia.paso()
		if d.min % 60 == 0: _hora_en_punto()
	for id in rt:
		var s: Dictionary = rt[id]
		Pistas.paso(self, id, dt)
		s.cd_obj = maxf(0.0, s.cd_obj - dt)
		s.herr_t = maxf(0.0, s.herr_t - dt)
	habitantes.paso(dt)
	if es_autoridad(): _pisadas()
	combate.paso(dt)
	_seg += dt
	if _seg >= 0.5:
		_seg = 0.0
		_chequeos()

var _ult_celda: Dictionary = {}   # última celda de cada jugador y habitante; no se guarda

## Jugadores y habitantes desgastan la hierba al cambiar de celda.
func _pisadas() -> void:
	var quienes := {}
	for id in rt: quienes["pj:" + id] = Mundo.celda_de(pies_de(id))
	for id in habitantes.ids: quienes["npc:" + id] = Mundo.celda_de(habitantes.pos(id))
	for k in quienes:
		if _ult_celda.get(k, quienes[k]) != quienes[k]:
			mundo.pisar(quienes[k])
			if k.begins_with("pj:"): practicar("pasos", 1, k.substr(3))
		_ult_celda[k] = quienes[k]

func _hora_en_punto() -> void:
	mundo.regenerar(d.min, ocupada)
	combate.revisar_reaparicion()
	var ev: String = "" if autonomia.activa() else vivo.evaluar()
	if ev != "":
		habitantes.reconciliar()
		aviso_todos(vivo.nombre(ev))

func _chequeos() -> void:
	actualizar_mapa()
	for id in rt:
		var pj: Dictionary = d.jugadores[id]
		if Mundo.ARENA.has_point(Mundo.celda_de(pies_de(id))): pj.eventos["visito_ruinas"] = true
		if not pj.pendientes.is_empty() and Inv.anadir(pj.inv, pj.pendientes, stats(id).slots):
			aviso("Recibes lo pendiente.", id)
			pj.pendientes = {}
	evaluar_misiones()
	if not autonomia.activa(): vivo.evaluar_misiones()

# ---------- estadísticas derivadas (se recalculan, nunca se acumulan) ----------
func stats(id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var s := {"hp": C.HP_BASE, "dmg": C.DMG_BASE, "vel": 1.0, "slots": C.MAX_SLOTS_BASE, "golpes_menos": 0, "def": 0}
	for h in pj.hab:
		for k in C.HAB[h].efe: s[k] += C.HAB[h].efe[k]
	var uso: Dictionary = pj.get("uso", {})
	for pid in C.PASIVAS:
		var pa: Dictionary = C.PASIVAS[pid]
		if int(uso.get(pa.uso, 0)) >= int(pa.umbral):
			for k in pa.efe: s[k] += pa.efe[k]
	if autonomia != null and autonomia.desarrollo.activa():
		var actor := actor_desarrollo(id)
		s.golpes_menos += mini(int(autonomia.desarrollo.cfg.bonus_recoleccion_max), autonomia.desarrollo.rango(actor,"recoleccion"))
		s.dmg += mini(int(autonomia.desarrollo.cfg.bonus_combate_max), autonomia.desarrollo.rango(actor,"combate"))
	var arma: String = str(pj.equipo.get("arma", ""))   # el daño de arma sale solo del arma equipada, no del inventario
	if arma != "": s.dmg += int(Eq.info(arma).get("dmg", 0))
	var f: Dictionary = Eq.finales(pj.equipo, int(s.hp) - C.HP_BASE, float(s.vel) - 1.0, C.HP_BASE)   # 3.2: redondeo único
	s.def = f.def
	s.hp = f.hp
	s.vel = f.vel
	return s

## Bono de set activo del jugador (para la interfaz).
func bono_set(id: String = LOCAL) -> Dictionary:
	return Eq.bono_set(jug(id).equipo)

func nivel(id: String = LOCAL) -> int:
	return C.nivel_de(jug(id).xp)

func puntos_libres(id: String = LOCAL) -> int:
	var g := 0
	for h in jug(id).hab: g += C.HAB[h].coste
	return nivel(id) - 1 - g

## Suma práctica; al cruzar el umbral de una pasiva avisa. Las pasivas no se guardan: salen del contador.
func practicar(clave: String, n: int = 1, id: String = LOCAL) -> void:
	var uso: Dictionary = jug(id).get_or_add("uso", {})
	var antes := int(uso.get(clave, 0))
	uso[clave] = antes + n
	for pid in C.PASIVAS:
		var pa: Dictionary = C.PASIVAS[pid]
		if pa.uso == clave and antes < int(pa.umbral) and antes + n >= int(pa.umbral):
			aviso("Por la práctica dominas «%s»." % pa.n, id)

func ganar_xp(n: int, id: String = LOCAL) -> void:
	var antes := nivel(id)
	jug(id).xp += n
	if nivel(id) > antes: aviso("¡Nivel %d! Tienes %d punto(s) de habilidad." % [nivel(id), puntos_libres(id)], id)

func aprender(hid: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	if not C.HAB.has(hid): return _no("Habilidad desconocida", id)
	if pj.hab.has(hid): return _no("Ya la tienes", id)
	var h: Dictionary = C.HAB[hid]
	if nivel(id) < h.niv: return _no("Requiere nivel %d" % h.niv, id)
	for r in h.req: if not pj.hab.has(r): return _no("Requiere %s" % C.HAB[r].n, id)
	if puntos_libres(id) < h.coste: return _no("Faltan puntos", id)
	pj.hab.append(hid)
	return _ok("Aprendes %s" % h.n, id)

func danar_pj(n: int, id: String = LOCAL) -> void:
	var pj := jug(id)
	practicar("dano", n, id)
	pj.hp -= Eq.dano(n, int(stats(id).def))   # 3.7 PROVISIONAL: max(1, round(n * 20 / (20 + DEF)))
	if pj.hp <= 0: _derrota(id)

# A01 provisional: sin pérdida de objetos; vuelves a tu cama (o al inicio) con la mitad de vida.
# Solo: el encuentro se reinicia. Con más jugadores no se toca a los demás: los enemigos que te seguían te olvidan.
func _derrota(id: String) -> void:
	var pj := jug(id)
	# Con cama válida (o en modo legado) nada cambia. En modo poblado y sin cama se revalida la aparición con el mismo sistema que al entrar.
	var revalidar: bool = pj.cama.is_empty() and mundo.modo_inicio() == Mundo.MODO_POBLADO
	if not revalidar:
		var c: Array = pj.cama if not pj.cama.is_empty() else pj.inicio
		rt[id].pies = Vector2(c[0], c[1])
	actualizar_regiones()
	pj.hp = int(stats(id).hp / 2.0)
	if rt.size() == 1: combate.reiniciar()
	else: combate.olvidar(id)
	combate.ataque(id).est = "libre"
	if revalidar:   # tras reiniciar el encuentro: los enemigos vuelven a su origen y la validación los ve donde estarán
		var ap: Dictionary = punto_aparicion(id)
		_registrar_aparicion(id, ap)
		if ap.ok:
			var pies := Mundo.pies_de_celda(ap.celda)
			rt[id].pies = pies
			pj.inicio = [pies.x, pies.y]
			actualizar_regiones()
		else:   # sin posición segura: no se inventa una celda ni se reactiva un poblado; se queda donde cayó (los que lo seguían ya lo olvidaron)
			aviso("No hay un lugar seguro donde despertar: te quedas donde caíste.", id)
			return
	aviso("Caes derrotado. Despiertas a salvo.", id)

# ---------- acciones ----------
func mover_pj(dir: Vector2i, dt: float, id: String = LOCAL) -> void:
	actualizar_regiones()
	var e: String = combate.ataque(id).est
	if dir == Vector2i.ZERO or e == "aviso" or e == "activo": return
	rt[id].mira = dir
	rt[id].pies = mundo.mover(pies_de(id), Vector2(dir) * P.VELOCIDAD * stats(id).vel * dt)
	Exploracion.observar(self, id)

func accion(id: String = LOCAL) -> Dictionary:
	var s: Dictionary = rt[id]
	var c: Vector2i = Mundo.celda_de(s.pies) + s.mira
	if not combate.hay_enemigo_cerca(24.0, id):
		for cc in [c, Mundo.celda_de(s.pies)]:
			var oid := mundo.objeto_presente(cc)
			if oid != "" and mundo.objetos[oid].t != "cofre_fijo" and not mundo.objetos[oid].t in Mundo.DECO:
				if s.cd_obj > 0.0: return {"ok": false, "msg": ""}
				s.cd_obj = 0.3
				s.herr_t = C.ANIM_PJ.herramienta.dur
				return golpear_objeto(cc, id)
	combate.atacar(s.mira, id)
	return _ok("", id)

func anim_pj(mov: bool, t_mov: float, id: String = LOCAL) -> Dictionary:
	var a: Dictionary = combate.ataque(id)
	return Anim.estado_y_cuadro({"mov": mov, "t_mov": t_mov, "herr_t": rt[id].herr_t, "ataque_est": a.est,
		"ataque_t": a.t, "inv_t": a.inv_t})

func golpear_objeto(c: Vector2i, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var oid := mundo.objeto_presente(c)
	if oid == "": return _no("No hay nada que golpear", id)
	var ot: String = mundo.objetos[oid].t
	if ot == "cofre_fijo": return _no("Se abre con E", id)
	if ot in Mundo.DECO: return _no("No se puede romper", id)
	var def: Dictionary = C.OBJETOS[ot]
	var tags := {}
	var menos := 0   # la mejor herramienta de la etiqueta recorta golpes
	for it in pj.inv:
		if Eq.info(it).has("tag"):
			tags[Eq.info(it).tag] = true
			if Eq.info(it).tag in def.golpes: menos = maxi(menos, int(Eq.info(it).get("menos", 0)))
	var necesarios := 9999
	for tag in def.golpes: if tag == "" or tags.has(tag): necesarios = mini(necesarios, def.golpes[tag])
	if necesarios == 9999: return _no("%s: necesitas una herramienta (%s)" % [def.n, ", ".join(def.golpes.keys())], id)
	necesarios = maxi(1, necesarios - stats(id).golpes_menos - menos)
	var g: int = d.mundo.golpes.get(oid, 0) + 1      # golpes acumulados: compartidos (cualquiera puede rematar)
	if g < necesarios:
		d.mundo.golpes[oid] = g
		return _ok("%s %d/%d" % [def.n, g, necesarios], id)
	var drops: Dictionary = def.drops.duplicate()
	var rng := _rng("botin", "%s:%d" % [oid, d.min / 60])
	for p in def.prob + Eq.caidas_objeto(ot): if rng.randf() < p.p: drops[p.item] = drops.get(p.item, 0) + p.q   # piedras al final: no altera el flujo previo
	if not Inv.anadir(pj.inv, drops, stats(id).slots):
		d.mundo.golpes[oid] = necesarios - 1
		return _no("Inventario lleno: %s no se rompe" % def.n, id)
	mundo.romper(oid, d.min)
	if autonomia.sociedad.activa(): autonomia.sociedad.observar_extraccion(id, oid)
	autonomia.desarrollo.registrar(actor_desarrollo(id),"recoleccion",drops)
	practicar("recolectado", 1, id)
	ganar_xp(def.xp, id)
	return _ok("Obtienes " + _txt_items(drops), id)

static func _txt_items(m: Dictionary) -> String:
	var l: Array = []
	for k in m: l.append("%d %s" % [m[k], Eq.info(k).n])
	return ", ".join(l)

# Las estaciones son del mundo: cualquiera puede usar la mesa u horno de otro.
func estacion_cerca(est: String, id: String = LOCAL) -> bool:
	if est == "": return true
	var c := Mundo.celda_de(pies_de(id))
	for k in d.mundo.constr:
		if C.CONSTR[d.mundo.constr[k].t].get("est", "") != est: continue
		var p: PackedStringArray = k.split(",")
		if maxi(absi(int(p[0]) - c.x), absi(int(p[1]) - c.y)) <= ALCANCE_ESTACION: return true
	return false

## Tipo de la estación (mesa, horno) en una celda contigua al jugador, o "". Es la puerta de E al panel de fabricar.
func estacion_junto(id: String = LOCAL) -> String:
	var c := Mundo.celda_de(pies_de(id))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cs := mundo.constr_en(c + Vector2i(dx, dy))
			if C.CONSTR.get(cs.get("t", ""), {}).get("est", "") != "": return cs.t
	return ""

func fabricar(rid: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var rs: Dictionary = Eq.recetas()      # C.RECETAS + piezas fabricables y joyas generadas desde datos
	if not rs.has(rid): return _no("Receta desconocida", id)
	var r: Dictionary = rs[rid]
	if r.hab != "" and not pj.hab.has(r.hab): return _no("Requiere habilidad %s" % C.HAB[r.hab].n, id)
	if r.herr != "" and pj.inv.get(r.herr, 0) < 1: return _no("Falta la herramienta %s" % Eq.info(r.herr).n, id)
	if not estacion_cerca(r.est, id): return _no("Necesitas estar junto a: %s" % r.est, id)
	if not Inv.tiene(pj.inv, r.ent): return _no("Faltan materiales", id)
	if not Inv.cambiar(pj.inv, r.ent, r.sal, stats(id).slots): return _no("Inventario lleno", id)
	var materiales: Dictionary = r.ent.duplicate()
	materiales.merge(r.sal, true)
	autonomia.desarrollo.registrar(actor_desarrollo(id),"artesania",materiales)
	return _ok("Fabricas %s" % r.n, id)

func usar(item: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var it: Dictionary = Eq.info(item)
	if not it.has("cura"): return _no("No se puede usar", id)
	if pj.inv.get(item, 0) < 1: return _no("No tienes", id)
	if pj.hp >= stats(id).hp: return _no("Vida completa", id)
	Inv.quitar(pj.inv, {item: 1})
	pj.hp = mini(stats(id).hp, pj.hp + it.cura)
	return _ok("Recuperas vida", id)

# Equipo: atómico (Inv.cambiar valida la capacidad con el resultado final, también en intercambios).
# La ranura sale de la clave (Equipo.info: `eq:` -> ranura de la pieza; escudo -> C.ITEMS). Desconocida: no equipable.
func equipar(item: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var it: Dictionary = Eq.info(item)
	if not it.has("equipo") or not it.equipo in C.RANURAS: return _no("No se puede equipar", id)
	if pj.inv.get(item, 0) < 1: return _no("No tienes", id)
	var r: String = it.equipo
	var prev: String = pj.equipo.get(r, "")
	if not Inv.cambiar(pj.inv, {item: 1}, {prev: 1} if prev != "" else {}, stats(id).slots): return _no("Inventario lleno", id)
	pj.equipo[r] = item
	return _ok("Equipas %s" % it.n, id)

func desequipar(ranura: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var item: String = pj.equipo.get(ranura, "")
	if item == "": return _no("Ranura vacía", id)
	if not Inv.anadir(pj.inv, {item: 1}, stats(id).slots): return _no("Inventario lleno", id)
	pj.equipo[ranura] = ""
	return _ok("Te quitas %s" % Eq.info(item).n, id)

# Pieza propia: primero la del inventario, si no la equipada. Devuelve "inv", la ranura o "".
func _donde(clave: String, id: String) -> String:
	var pj := jug(id)
	if pj.inv.get(clave, 0) > 0: return "inv"
	var p := Eq.leer(clave)
	return p.ranura if not p.is_empty() and pj.equipo.get(p.ranura, "") == clave else ""

# Sustituye una pieza propia (inventario o equipada) por `nueva` pagando `coste`; atómico.
func _transformar(clave: String, nueva: String, coste: Dictionary, id: String) -> bool:
	var pj := jug(id)
	var donde := _donde(clave, id)
	if donde == "": return false
	if donde == "inv":
		var rem := coste.duplicate()
		rem[clave] = 1
		return Inv.cambiar(pj.inv, rem, {nueva: 1}, stats(id).slots)
	if not Inv.quitar(pj.inv, coste): return false
	pj.equipo[donde] = nueva
	return true

## Chispa de Temple (3.6): sube +N -> +N+1 siempre; coste creciente; en +5 o sin joyas se rechaza sin cambios.
func mejorar(clave: String, id: String = LOCAL) -> Dictionary:
	if _donde(clave, id) == "": return _no("No tienes esa pieza", id)
	var r: Dictionary = Eq.mejorar(clave)
	if not r.ok: return _no(r.motivo, id)
	if not Inv.tiene(jug(id).inv, r.coste): return _no("Faltan joyas: " + _txt_items(r.coste), id)
	if not _transformar(clave, r.nueva, r.coste, id): return _no("No se pudo mejorar", id)
	return _ok("%s -> %s" % [Eq.info(clave).n, Eq.info(r.nueva).n], id)

## Piedra (5.4): cambia la variante conservando nivel; consume la piedra nueva y la anterior se pierde.
func engarzar(clave: String, variante: String, id: String = LOCAL) -> Dictionary:
	if _donde(clave, id) == "": return _no("No tienes esa pieza", id)
	var r: Dictionary = Eq.cambiar_variante(clave, variante)
	if not r.ok: return _no(r.motivo, id)
	if not Inv.tiene(jug(id).inv, r.coste): return _no("Falta " + _txt_items(r.coste), id)
	if not _transformar(clave, r.nueva, r.coste, id): return _no("No se pudo engarzar", id)
	return _ok("Ahora: %s" % Eq.info(r.nueva).n, id)

## Intercambio directo (5.9): `a` entrega `de_a` y recibe `de_b` del jugador `b`. Todo o nada: ambos deben tener
## lo que dan y caberles lo que reciben. Solo lo ejecuta la autoridad (servidor o partida local).
func intercambiar(a: String, b: String, de_a: Dictionary, de_b: Dictionary) -> Dictionary:
	if a == b or not d.jugadores.has(a) or not d.jugadores.has(b): return _no("Intercambio no válido", a)
	for lote in [de_a, de_b]:
		for k in lote: if not Eq.existe(str(k)) or typeof(lote[k]) != TYPE_INT or lote[k] <= 0: return _no("Intercambio no válido", a)
	var ia: Dictionary = jug(a).inv.duplicate()
	var ib: Dictionary = jug(b).inv.duplicate()
	if not Inv.cambiar(ia, de_a, de_b, stats(a).slots) or not Inv.cambiar(ib, de_b, de_a, stats(b).slots):
		aviso("Intercambio rechazado: faltan objetos o espacio", b)
		return _no("Intercambio rechazado: faltan objetos o espacio", a)
	jug(a).inv.clear()
	jug(a).inv.merge(ia)
	jug(b).inv.clear()
	jug(b).inv.merge(ib)
	aviso("Intercambio hecho con %s" % jug(a).nombre, b)
	return _ok("Intercambio hecho con %s" % jug(b).nombre, a)

# Actores (jugadores, habitantes, enemigos) como cajas de suelo.
func actores() -> Array:
	var l: Array = []
	for id in rt: l.append([rt[id].pies, P.PIES])
	for nid in habitantes.ids: l.append([habitantes.pos(nid), P.PIES])
	if autonomia!=null:
		for r in autonomia.asentamientos.visibles():l.append([r.pos,P.PIES])
	for e in combate.enemigos:
		if e.est != "muerto": l.append([e.pos, Vector2(e.tam, e.tam * 0.6)])
	return l

func ocupada(c: Vector2i) -> bool:
	var r := Rect2(Vector2(c) * P.CELDA, Vector2(P.CELDA, P.CELDA))
	for a in actores():
		if r.intersects(Rect2(a[0] - Vector2(a[1].x / 2.0, a[1].y), a[1])): return true
	return false

func construir(pieza: String, c: Vector2i, id: String = LOCAL) -> Dictionary:
	if Edificios.catalogo().planos.has(pieza): return construir_edificio(pieza,c,id)
	if not mundo.edificio_en(c).is_empty(): return _no("Usa el plano de reparación del edificio",id)
	var pj := jug(id)
	if not C.CONSTR.has(pieza): return _no("Pieza desconocida", id)
	var def: Dictionary = C.CONSTR[pieza]
	if autonomia.activa() and not autonomia.sociedad.habitat.permite_pieza(c,pieza): return _no("Solar reservado para una vivienda",id)
	if pieza=="puesto":
		var problema: String=autonomia.asentamientos.validar(c)
		if problema!="": return _no(problema,id)
	if def.get("techo", false):
		var m_techo := mundo.puede_techar(c)
		if m_techo != "": return _no("No se puede: " + m_techo, id)
		if not Inv.tiene(pj.inv, def.coste): return _no("Faltan materiales: " + _txt_items(def.coste), id)
		mundo.techar(c, id)
		Inv.quitar(pj.inv, def.coste)
		autonomia.desarrollo.registrar(actor_desarrollo(id),"construccion",def.coste)
		return _ok("Techas la celda", id)
	var motivo := mundo.puede_poner(c)
	if motivo != "": return _no("No se puede: " + motivo, id)
	if ocupada(c): return _no("Hay alguien en esa celda", id)
	if not Inv.tiene(pj.inv, def.coste): return _no("Faltan materiales: " + _txt_items(def.coste), id)
	mundo.poner(c, pieza, true, id)
	sembrar(c)
	if def.bloquea:    # no se permiten bloqueos irreversibles de lugares esenciales ni de ningún jugador
		var posiciones: Array=[]
		for k in rt: posiciones.append(Mundo.celda_de(rt[k].pies))
		for nid in habitantes.ids: posiciones.append(Mundo.celda_de(habitantes.pos(nid)))
		var ok := mundo.construccion_segura(c,posiciones)
		if not ok:
			mundo.quitar(c)
			return _no("Eso cerraría un camino esencial", id)
	Inv.quitar(pj.inv, def.coste)
	if pieza=="puesto": autonomia.asentamientos.crear(c,id)
	if def.get("cofre", false): d.cofres["c@" + Mundo.clave(c)] = {"inv": {}}
	autonomia.desarrollo.registrar(actor_desarrollo(id),"construccion",def.coste)
	return _ok("Construyes %s" % def.n, id)

## Un campo recién puesto empieza a crecer; solo se anota el minuto en que estará listo.
func sembrar(c: Vector2i) -> void:
	var cs: Dictionary = mundo.constr_en(c)
	if C.CONSTR.get(cs.get("t", ""), {}).get("campo", false): cs["listo"] = int(d.min) + C.CAMPO_CRECE_MIN

func campo_listo(c: Vector2i) -> bool:
	var cs: Dictionary = mundo.constr_en(c)
	return cs.get("t", "") == "campo" and int(d.min) >= int(cs.get("listo", 0))

## Recoge un campo maduro (jugador o habitante) y lo deja sembrado otra vez. {} si aún no está listo.
func cosechar(c: Vector2i) -> Dictionary:
	if not campo_listo(c): return {}
	sembrar(c)
	mundo.cambiar()
	return C.CAMPO_COSECHA.duplicate()

func retirar(c: Vector2i, id: String = LOCAL) -> Dictionary:
	if not mundo.edificio_en(c).is_empty(): return _no("El edificio se modifica mediante reparación o ampliación",id)
	var pj := jug(id)
	var k := Mundo.clave(c)
	var cs: Dictionary = mundo.constr_en(c)
	if cs.is_empty() and mundo.estado.techos.has(k):   # solo techo
		if mundo.estado.techos[k] != id: return _no("Ese techo no es tuyo", id)
		if not Inv.anadir(pj.inv, C.CONSTR.techo.coste, stats(id).slots): return _no("Inventario lleno", id)
		mundo.destechar(c)
		return _ok("Recuperas " + _txt_items(C.CONSTR.techo.coste), id)
	if cs.is_empty(): return _no("No hay construcción", id)
	if cs.get("dueno", "") != id: return _no("Esa construcción no es tuya", id)
	if cs.t=="puesto": return _no("El puesto regional es permanente; sus reservas y casas se gestionan por separado",id)
	var def: Dictionary = C.CONSTR[cs.t]
	var cid := "c@" + k
	if d.cofres.get(cid, {}).get("candado", false): return _no("Retira primero el candado", id)
	if d.cofres.has(cid) and not d.cofres[cid].inv.is_empty(): return _no("El cofre no está vacío", id)
	if not Inv.anadir(pj.inv, def.coste, stats(id).slots): return _no("Inventario lleno", id)
	mundo.quitar(c)
	if autonomia.sociedad.activa(): autonomia.sociedad.datos().estaciones.erase(k)
	d.cofres.erase(cid)
	return _ok("Recuperas " + _txt_items(def.coste), id)

# Cofres (compartidos): el del tesoro se vacía una vez al abrirse (para el mundo); los construidos transfieren por pila.
func abrir_tesoro(cid: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	var cf: Dictionary = d.cofres[cid]
	if cf.get("abierto", false): return _no("Está vacío", id)
	if not Inv.cambiar(pj.inv, {}, cf.inv, stats(id).slots): return _no("Inventario lleno", id)
	var txt := _txt_items(cf.inv)
	cf.inv = {}
	cf.abierto = true
	pj.eventos["abrio_" + cid] = true
	return _ok("Abres el cofre: " + txt, id)

## La autorización se comprueba en la acción, incluso si el panel ya estaba abierto.
func cofre_cerca(cid: String, id: String = LOCAL) -> bool:
	if not cid.begins_with("c@") or not d.cofres.has(cid) or not rt.has(id): return false
	var partes := cid.trim_prefix("c@").split(",")
	if partes.size() != 2 or not partes[0].is_valid_int() or not partes[1].is_valid_int(): return false
	var c := Vector2i(int(partes[0]), int(partes[1]))
	if mundo.constr_en(c).get("t", "") != "cofre": return false
	var actual := Mundo.celda_de(pies_de(id))
	return actual == c or mundo.es_adyacente(actual, c)

func info_cofre(cid: String, id: String = LOCAL) -> Dictionary:
	var dueno: String = str(d.mundo.constr.get(cid.trim_prefix("c@"), {}).get("dueno", ""))
	var cf: Dictionary = d.cofres.get(cid, {})
	var real := actor_desarrollo(id).trim_prefix("pj:")
	var propio := dueno == id or dueno == real
	var permisos: Array = cf.get("permitidos", [])
	var autorizado := propio or permisos.has(real)
	var nombre: String = str(d.jugadores.get(dueno,{}).get("nombre","Otro jugador"))
	if dueno.begins_with("npc:"): nombre = str(habitantes.fichas.get(dueno.trim_prefix("npc:"),{}).get("n","Habitante"))
	elif dueno.begins_with("grupo:"): nombre = autonomia.sociedad.nombre_grupo(dueno.trim_prefix("grupo:"))
	elif dueno.begins_with("poblado:"): nombre = str(mundo.poblado(dueno.trim_prefix("poblado:")).get("nombre", "Comunidad"))
	elif dueno=="anfitrion:local": nombre="Anfitrión"
	elif dueno=="": nombre="Compartido"
	return {"dueno": dueno, "nombre":nombre, "propio": propio, "candado": bool(cf.get("candado", false)), "cerrado": bool(cf.get("cerrado", false)), "permitidos": permisos, "acceso": not bool(cf.get("cerrado", false)) or autorizado}

func gestionar_cofre(cid: String, accion: String, destino: String = "", id: String = LOCAL) -> Dictionary:
	if not cofre_cerca(cid, id): return _no("Acércate al cofre", id)
	var info := info_cofre(cid, id)
	if not info.propio: return _no("Solo el dueño puede cambiar la protección", id)
	var cf: Dictionary = d.cofres[cid]
	match accion:
		"instalar":
			if info.candado: return _no("Ya tiene candado", id)
			if not Inv.tiene(jug(id).inv, {"candado":1}): return _no("Fabrica un candado en una mesa: 2 lingotes y 2 fibras", id)
			Inv.quitar(jug(id).inv, {"candado":1})
			cf.candado = true
			cf.cerrado = true
		"abrir", "cerrar":
			if not info.candado: return _no("No tiene candado", id)
			cf.cerrado = accion == "cerrar"
		"retirar":
			if not info.candado: return _no("No tiene candado", id)
			if not Inv.anadir(jug(id).inv, {"candado":1}, stats(id).slots): return _no("Inventario lleno", id)
			cf.candado = false
			cf.cerrado = false
		"permitir", "revocar":
			if not d.jugadores.has(destino) or destino == id: return _no("Jugador desconocido", id)
			var permisos: Array = cf.get("permitidos", []).duplicate()
			if accion == "permitir" and not permisos.has(destino): permisos.append(destino)
			if accion == "revocar": permisos.erase(destino)
			cf.permitidos = permisos
			var nombres: Dictionary = cf.get("nombres_permitidos",{})
			if accion=="permitir": nombres[destino]=str(jug(destino).nombre)
			else: nombres.erase(destino)
			cf.nombres_permitidos=nombres
		_: return _no("Acción desconocida", id)
	return _ok("Protección del cofre actualizada", id)

func mover_cofre(cid: String, item: String, hacia_cofre: bool, id: String = LOCAL) -> Dictionary:
	if not cofre_cerca(cid, id): return _no("Acércate al cofre", id)
	if not info_cofre(cid, id).acceso: return _no("Cofre cerrado con candado", id)
	var pj := jug(id)
	var cf: Dictionary = d.cofres.get(cid, {})
	if cf.is_empty(): return _no("Cofre inexistente", id)
	var n: int = pj.inv.get(item, 0) if hacia_cofre else cf.inv.get(item, 0)
	if n <= 0: return _no("No hay", id)
	var lote := {item: n}
	if hacia_cofre:
		if not Inv.cabe(cf.inv, lote, CAP_COFRE): return _no("El cofre está lleno", id)
		Inv.quitar(pj.inv, lote)
		Inv.anadir(cf.inv, lote, CAP_COFRE)
	else:
		if not Inv.cabe(pj.inv, lote, stats(id).slots): return _no("Inventario lleno", id)
		Inv.quitar(cf.inv, lote)
		Inv.anadir(pj.inv, lote, stats(id).slots)
		autonomia.sociedad.observar_hurto_cofre(id, cid, item, n)   # tomar de un cofre ajeno tiene testigos y consecuencias
	return _ok("", id)

# E: habitante cercano, cofre o cama delante.
func interactuar(id: String = LOCAL) -> Dictionary:
	var p := pies_de(id)
	for nid in habitantes.ids:
		if habitantes.pos(nid).distance_to(p) <= ALCANCE_NPC:
			var r := hablar(nid, id)
			return {"ok": true, "panel": "dialogo", "npc": nid, "texto": r.texto, "tipo": r.tipo}
	var base := Mundo.celda_de(p)
	var m: Vector2i = rt[id].mira
	for c in [base + m, base]:
		var oid := mundo.objeto_presente(c)
		if oid != "" and mundo.objetos[oid].t == "cofre_fijo": return {"ok": true, "panel": "tesoro", "id": oid, "r": abrir_tesoro(oid, id)}
		var cs := mundo.constr_en(c)
		if cs.is_empty(): continue
		if cs.t == "cofre": return {"ok": true, "panel": "cofre", "id": "c@" + Mundo.clave(c)}
		if C.CONSTR[cs.t].get("est","") != "" and not mundo.edificio_en(c).is_empty(): return {"ok":true,"panel":"craft"}
		if cs.t == "campo":
			var falta := int(cs.get("listo", 0)) - int(d.min)
			if falta > 0: return {"ok": false, "r": _no("El cultivo crece: faltan %d h" % ceili(falta / 60.0), id)}
			var cosecha := C.CAMPO_COSECHA
			if not Inv.anadir(jug(id).inv, cosecha, stats(id).slots): return {"ok": false, "r": _no("Inventario lleno", id)}
			cosechar(c)
			return {"ok": true, "r": _ok("Cosechas " + _txt_items(cosecha), id)}
		if cs.t == "cama":
			if not cs.propia: return {"ok": false, "r": _no("Es la cama de un habitante", id)}
			if cs.get("dueno", "") != id: return {"ok": false, "r": _no("Es la cama de otro jugador", id)}
			return {"ok": true, "panel": "dormir", "r": dormir(c, id)}
	for r in autonomia.asentamientos.visibles():
		if r.pos.distance_to(p) <= ALCANCE_NPC:
			return {"ok": true, "panel": "dialogo", "npc": r.id, "nombre": r.nombre, "texto": autonomia.asentamientos.dialogo(r.id), "tipo": "regional"}
	if estacion_junto(id) != "": return {"ok": true, "panel": "craft"}
	var edificio: Dictionary = mundo.edificio_en(base + m)
	if edificio.is_empty(): edificio = mundo.edificio_en(base)
	if not edificio.is_empty(): return {"ok":true,"panel":"edificio","id":edificio.id}
	var lugar: Dictionary = mundo.lugar_en(base)
	if not lugar.is_empty(): return {"ok": true, "panel": "dialogo", "nombre": lugar.nombre, "texto": lugar.descripcion, "tipo": "lugar"}
	return {"ok": false, "r": _no("Nada con qué interactuar", id)}

# Dormir NO avanza el reloj compartido (design/gdd/mundo-vivo.md regla 17): cura y fija la cama. El tiempo sigue por el tick
# normal, que ya regenera objetos cada hora y hace avanzar a los habitantes. PROVISIONAL: sin consecuencias de dormir aún.
func dormir(c: Vector2i, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	pj.hp = stats(id).hp
	var p := Mundo.pies_de_celda(c)
	pj.cama = [p.x, p.y + 16]
	return _ok("Descansas: recuperas la vida y fijas tu cama.", id)

# ---------- misiones (por jugador) ----------
func estado_mision(mid: String, id: String = LOCAL) -> String:
	return jug(id).misiones.get(mid, {}).get("estado", "")

func mision_disponible(mid: String, id: String = LOCAL) -> bool:
	if estado_mision(mid, id) != "": return false
	for r in C.MISIONES[mid].req: if estado_mision(r, id) != "entregada": return false
	return true

func aceptar(mid: String, id: String = LOCAL) -> Dictionary:
	if not mision_disponible(mid, id): return _no("No disponible", id)
	jug(id).misiones[mid] = {"estado": "activa"}
	aviso("Misión: " + C.MISIONES[mid].n, id)
	return _ok("", id)

func contar_constr(pieza: String, id: String = LOCAL) -> int:
	var n := 0
	for k in d.mundo.constr:
		if d.mundo.constr[k].t == pieza and d.mundo.constr[k].get("dueno", "") == id: n += 1
	return n

# Actuales (tener, construccion) se miden AHORA; históricos (visita, derrotar, hablar, abrir) usan hechos guardados.
# derrotar y abrir son hechos del MUNDO (el jefe cayó / el cofre se abrió, lo hiciera quien lo hiciera).
func objetivo_ok(o: Dictionary, id: String = LOCAL) -> bool:
	var pj := jug(id)
	match o.t:
		"hablar": return pj.eventos.get("hablo_" + o.npc, 0) > 0
		"tener": return pj.inv.get(o.item, 0) >= o.n
		"construccion": return contar_constr(o.pieza, id) >= o.n
		"visita": return pj.eventos.has(o.evento)
		"derrotar": return d.jefes.get(o.jefe, {}).get("veces", 0) > 0
		"abrir": return d.cofres.get(o.cofre, {}).get("abierto", false)
	return false

func objetivo_txt(o: Dictionary, id: String = LOCAL) -> String:
	match o.t:
		"hablar": return "Hablar con %s" % o.npc.capitalize()
		"tener": return "%s %d/%d" % [Eq.info(o.item).n, mini(jug(id).inv.get(o.item, 0), o.n), o.n]
		"construccion": return "Construir %s (%d/%d en pie)" % [C.CONSTR[o.pieza].n, mini(contar_constr(o.pieza, id), o.n), o.n]
		"visita": return "Visitar el lugar"
		"derrotar": return "Derrotar a %s" % C.ENEMIGOS[o.jefe].n
		"abrir": return "Abrir el cofre"
	return ""

func progreso_txt(mid: String, id: String = LOCAL) -> String:
	var l: Array = []
	for o in C.MISIONES[mid].obj: l.append(("[x] " if objetivo_ok(o, id) else "[ ] ") + objetivo_txt(o, id))
	return " ".join(l)

func _cumple(mid: String, id: String) -> bool:
	for o in C.MISIONES[mid].obj: if not objetivo_ok(o, id): return false
	return true

# Sin id: evalúa a todos los jugadores.
func evaluar_misiones(id: String = "") -> void:
	for k in ([id] if id != "" else d.jugadores.keys()):
		var ms: Dictionary = jug(k).misiones
		for mid in ms:
			var m: Dictionary = ms[mid]
			if m.estado == "activa" and _cumple(mid, k):
				m.estado = "cumplida"
				aviso("Cumplida: " + C.MISIONES[mid].n, k)
			elif m.estado == "cumplida" and not _cumple(mid, k):
				m.estado = "activa"
				aviso("Ya no se cumple: " + C.MISIONES[mid].n, k)

func entregar(mid: String, id: String = LOCAL) -> Dictionary:
	var pj := jug(id)
	evaluar_misiones(id)
	if estado_mision(mid, id) != "cumplida": return _no("Aún no se cumple", id)
	if pj.recompensas.has("mision:" + mid): return _no("Ya entregada", id)
	var m: Dictionary = C.MISIONES[mid]
	if not Inv.cambiar(pj.inv, m.consume, m.rec.items, stats(id).slots): return _no("Sin espacio para la recompensa", id)
	pj.recompensas.append("mision:" + mid)
	pj.misiones[mid].estado = "entregada"
	ganar_xp(m.rec.xp, id)
	return _ok("Entregada: " + m.n, id)

## Fachadas de misiones por plantilla (UI y red futura).
func aceptar_mision_plantilla(iid: String, id: String = LOCAL) -> Dictionary:
	return vivo.aceptar_plantilla(iid, id)

func entregar_mision_plantilla(iid: String, id: String = LOCAL) -> Dictionary:
	return vivo.entregar_plantilla(iid, id)

## Resuelve una petición nacida de una carencia real, con autoridad y proximidad.
## Piezas derivadas de reglas: el servidor valida conocimiento, calidad, coste y capacidad.
func refinar_material(material: String, id: String = LOCAL) -> Dictionary:
	return autonomia.desarrollo.refinar(material,id)

func fabricar_artefacto(clave: String, id: String = LOCAL) -> Dictionary:
	return autonomia.desarrollo.fabricar(clave,id)

func comprar_artefacto(npc: String, clave: String, id: String = LOCAL) -> Dictionary:
	return autonomia.desarrollo.comprar(npc,clave,id)

## El jugador enseña un saber suyo a un habitante cercano.
func ensenar_saber(npc: String, saber: String, id: String = LOCAL) -> Dictionary:
	return autonomia.desarrollo.leccion_jugador(npc,saber,id,false)

## El jugador pide a un habitante cercano que le enseñe un saber que este conoce.
func pedir_saber(npc: String, saber: String, id: String = LOCAL) -> Dictionary:
	return autonomia.desarrollo.leccion_jugador(npc,saber,id,true)

func aportar_grupo(grupo: String, id: String = LOCAL) -> Dictionary:
	return autonomia.sociedad.aportar_grupo(grupo, id)

func ayudar_habitante(npc: String, rechazar: bool = false, id: String = LOCAL) -> Dictionary:
	return autonomia.ayudar(npc, id, rechazar)

func hablar(npc: String, id: String = LOCAL) -> Dictionary:
	if autonomia.activa() and not autonomia.perfil(npc).is_empty():
		return {"texto": autonomia.dialogo(npc, id), "tipo": "necesidad"}
	var pj := jug(id)
	evaluar_misiones(id)
	pj.eventos["hablo_" + npc] = pj.eventos.get("hablo_" + npc, 0) + 1
	var veces: int = pj.eventos["hablo_" + npc]
	for mid in C.MISIONES:
		var m: Dictionary = C.MISIONES[mid]
		if m.da != npc: continue
		var dl: Dictionary = C.DIALOGOS[mid]
		var e := estado_mision(mid, id)
		if e == "" and mision_disponible(mid, id):
			aceptar(mid, id)
			evaluar_misiones(id)
			return {"texto": dl.oferta, "tipo": "mision"}
		if e == "activa": return {"texto": dl.recordar + "  " + progreso_txt(mid, id), "tipo": "expresivo"}
		if e == "cumplida":
			var r := entregar(mid, id)
			if r.ok:
				pj.relacion[npc] = int(pj.relacion.get(npc, 0)) + 1
				return {"texto": dl.gracias, "tipo": "relacion"}
			return {"texto": r.msg, "tipo": "expresivo"}
	var done := true
	for mid in C.MISIONES: if C.MISIONES[mid].da == npc and estado_mision(mid, id) != "entregada": done = false
	if done: return {"texto": C.DIALOGOS.final, "tipo": "expresivo"}
	return {"texto": C.DIALOGOS.base[veces % C.DIALOGOS.base.size()], "tipo": "expresivo"}

# ---------- botín y jefes ----------
# Farmeo (4, decisión 7): por cada derrota de una fuente, tirada propia del jugador por familia de zona.
# Flujo determinista por semilla, familia y jugador:intento; garantía tras `garantia` intentos sin caída.
func caida_equipo(fuente: String, id: String = LOCAL) -> void:
	var pj := jug(id)
	if not pj.has("botin_eq"): pj["botin_eq"] = {}
	for fam in Eq.familias_zona(fuente):
		var st: Dictionary = pj.botin_eq.get(fam, {"n": 0, "sin": 0})
		st.n = int(st.n) + 1
		var r: String = Eq.tirada_zona(fam, int(st.sin), _rng("eq:" + fam, "%s:%d" % [id, st.n]))
		st.sin = 0 if r != "" else int(st.sin) + 1
		pj.botin_eq[fam] = st
		if r != "": dar_o_pendiente({Eq.construir(fam, r, "", 0): 1}, id)

# Jefe repetible: una pieza de su familia que el jugador aún no tenga (inventario, equipo o pendientes);
# con el set completo, una cualquiera. Tirada propia por jugador y derrota.
func _botin_jefe(jid: String, veces: int, id: String) -> void:
	var pj := jug(id)
	for fam in Eq.familias_jefe(jid):
		var tiene := {}
		for k in pj.inv.keys() + pj.equipo.values() + pj.pendientes.keys():
			var p := Eq.leer(str(k))
			if not p.is_empty() and p.familia == fam: tiene[p.ranura] = true
		var piezas: Array = Eq.datos().familias[fam].piezas
		var faltan: Array = piezas.filter(func(r): return not tiene.has(r))
		if faltan.is_empty(): faltan = piezas
		var rng := _rng("eq:" + fam, "%s:jefe:%d" % [id, veces])
		dar_o_pendiente({Eq.construir(fam, faltan[rng.randi() % faltan.size()], "", 0): 1}, id)

func dar_o_pendiente(items: Dictionary, id: String = LOCAL) -> void:
	var pj := jug(id)
	if Inv.anadir(pj.inv, items, stats(id).slots): aviso("Obtienes " + _txt_items(items), id)
	else:
		for k in items: pj.pendientes[k] = pj.pendientes.get(k, 0) + items[k]
		aviso("Inventario lleno: la recompensa queda pendiente", id)

# La derrota es del mundo (jefes[jid]); la recompensa, del jugador que dio el golpe final (id).
func jefe_derrotado(jid: String, id: String = LOCAL) -> void:
	var st: Dictionary = d.jefes.get(jid, {"veces": 0})
	st.veces = int(st.veces) + 1
	st.derrotado = true
	st.hora = d.min
	d.jefes[jid] = st
	var clave := "jefe:%s:%d" % [jid, st.veces]
	var rec: Array = jug(id).recompensas
	if not rec.has(clave):
		rec.append(clave)
		dar_o_pendiente(C.ENEMIGOS[jid].recompensa, id)
		_botin_jefe(jid, int(st.veces), id)
	aviso_todos("¡%s derrotado!" % C.ENEMIGOS[jid].n)

## Registra solo lo observado por jugadores presentes, sin modificar la simulación.
func actualizar_mapa() -> void:
	for id in rt: Exploracion.observar(self, id)

## El servidor valida cercanía y decide qué información se intercambia.
func preguntar_lugares(npc: String, id: String = LOCAL) -> Dictionary:
	return Exploracion.intercambiar(self, npc, id)

## Pide, descarta o silencia ayuda contextual personal y opcional.
func gestionar_pista(comando: String, id: String = LOCAL) -> void:
	Pistas.accion(self, id, comando)

## Pista activa solo en sesión; las mostradas/descartadas sí persisten.
func pista_contextual(id: String = LOCAL) -> Dictionary:
	return rt[id].get("pista_actual", {})

## Nombre público de una identidad, detallada o regional, sin crear otro habitante.
func nombre_habitante(nid: String) -> String:
	if habitantes.fichas.has(nid): return str(habitantes.fichas[nid].n)
	return str(autonomia.asentamientos.residente(nid).get("nombre", "un habitante"))

## Primera entrega: paga exactamente el plano completo y lo instala terminado, sin inventario inicial.
func construir_edificio(tipo: String, entrada: Vector2i, id: String = LOCAL) -> Dictionary:
	if not es_autoridad() or not rt.has(id): return _no("Solo la autoridad construye",id)
	var c := Mundo.celda_de(pies_de(id))
	if maxi(absi(c.x-entrada.x),absi(c.y-entrada.y)) > 2: return _no("Acércate al acceso sur",id)
	if Edificios.catalogo().planos.get(tipo,{}).get("solo_generacion",false): return _no("Plano de comunidad preexistente",id)
	var e := Edificios.plano(tipo,entrada,id)
	if e.is_empty(): return _no("Plano desconocido",id)
	var coste := Edificios.coste(e)
	if not Inv.tiene(jug(id).inv,coste): return _no("Faltan materiales: "+_txt_items(coste),id)
	var motivo := Edificios.instalar(self,e)
	if motivo != "": return _no(motivo,id)
	Inv.quitar(jug(id).inv,coste)
	autonomia.desarrollo.registrar(actor_desarrollo(id),"construccion",coste)
	return _ok(e.nombre + ": obra terminada. Entra por la puerta sur; E permite consultar y reparar.",id)

## Reparación limitada, con revisión optimista y precio de los faltantes reales. No sobrescribe muebles o inventarios.
func reparar_edificio(eid: String, revision: int, id: String = LOCAL) -> Dictionary:
	if not es_autoridad() or not rt.has(id): return _no("Solo la autoridad repara",id)
	var e: Dictionary = d.mundo.get("registro",{}).get("edificios",{}).get(eid,{})
	if e.is_empty() or e.dueno != id: return _no("Esta construcción no es tuya",id)
	if int(e.revision) != revision: return _no("El edificio cambió; revisa el plano antes de reparar",id)
	var entrada := Vector2i(e.entrada[0],e.entrada[1])
	if not Edificios.abierto(e,pies_de(id)): return _no("Acércate al edificio",id)
	var f := Edificios.faltantes(self,e)
	var coste := Edificios.coste(f)
	if coste.is_empty(): return _no("El edificio está completo",id)
	if not Inv.tiene(jug(id).inv,coste): return _no("Faltan materiales: "+_txt_items(coste),id)
	for k in f.piezas:
		var c := Edificios._celda(k)
		if not mundo.constr_en(c).is_empty() or mundo.puede_poner(c) != "" or ocupada(c): return _no("Hay un obstáculo en la reparación",id)
	for k in f.techos:
		if mundo.puede_techar(Edificios._celda(k)) != "": return _no("Hay un obstáculo bajo la cubierta",id)
	for k in f.pisos:
		if not mundo.piso_en(Edificios._celda(k)).is_empty(): return _no("Hay otro suelo en la reparación",id)
	# Comprueba el resultado completo antes de consumir o cambiar una pieza.
	var anteriores: Dictionary = d.mundo.constr
	d.mundo.constr = anteriores.duplicate(true)
	d.mundo.constr.merge(f.piezas,true)
	mundo.cambiar()
	var valido := Edificios.accesible(self,e)
	d.mundo.constr = anteriores
	mundo.cambiar()
	if not valido: return _no("La reparación impediría un acceso",id)
	for k in f.piezas:
		var cs: Dictionary = f.piezas[k]
		mundo.poner(Edificios._celda(k),cs.t,true,e.dueno)
		if cs.t == "cofre": d.cofres.get_or_add("c@"+k,{"inv":{}})
	for k in f.pisos:
		d.mundo.registro.pisos[k] = {"dueno":e.dueno,"edificio":e.id}
		mundo._edificio_editado(Edificios._celda(k))
	for k in f.techos: mundo.techar(Edificios._celda(k),e.dueno)
	mundo.cambiar()
	Inv.quitar(jug(id).inv,coste)
	autonomia.desarrollo.registrar(actor_desarrollo(id),"construccion",coste)
	return _ok("Edificio reparado",id)
