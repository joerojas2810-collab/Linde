extends Node
# Servidor autoritativo del «mundo anfitrión» (protocolo en docs/DECISIONES.md, sección «Red»).
# Tiene el Juego único del mundo, acepta hasta MAX_CLIENTES por ENet, identifica cada conexión por nombre + clave,
# ejecuta sus INTENCIONES (validadas aquí: nunca se confía en el cliente) con el id de quien las envía y difunde a 20 Hz.
# El nodo vive en /root/Red y declara los MISMOS RPC que red_cliente.gd (Godot los identifica por ruta y nombre).
const Aspecto = preload("res://scripts/aspecto.gd")
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Eq = preload("res://scripts/equipo.gd")
const Huella = preload("res://scripts/huella.gd")
const PUERTO := 7777
const MAX_CLIENTES := 15
const VERSION := 8              # versión del protocolo; el cliente la manda en «hola» (6: saberes y enseñanza; 7: huella de reglas; 8: geometría y expansión del registro de lugares)
const TICK := 0.05              # 20 Hz
const ALCANCE := 2              # celdas (Chebyshev) para construir, retirar y usar cofres
const MAX_PEDIDOS_S := 40       # pedidos por segundo y conexión; el resto se descarta
const ESPERA_HOLA_S := 10.0     # una conexión que no se identifica en este tiempo se corta
const GUARDADO_S := 30.0
const DIRS := [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const SECCIONES := ["poblados", "registro", "rotos", "golpes", "constr", "caminos", "techos", "cofres", "jefes", "mundo_vivo"]
const MAX_TEXTO := 48           # longitud máxima de un texto de pedido (las claves `eq:` más largas rondan 32)
const MAX_LOTE := 12            # entradas por lado de una oferta de intercambio

var secuencia_instantanea := 0
var j                           # Juego del mundo (único)
var puerto := PUERTO
var local := ""                 # id del jugador que juega en este proceso (anfitrión con ventana); "" sin ventana
var ruta := ""                  # guardado del mundo; "" = lo guarda quien aloja (escena.gd)
var duracion := 0.0             # > 0: se cierra (y guarda) tras esos segundos
var ruta_registro := ""         # JSON de métricas al cerrar (pruebas)
var error := ""                 # motivo si no se pudo abrir el puerto
var peers := {}                 # peer -> {id, n, t_n, t0, fuera}
var ids := {}                   # id de jugador -> peer
var intencion := {}             # id -> Vector2i (dirección que mantiene)
var ultimo_seq := {}            # id -> último número de pedido aceptado (evita duplicados y repeticiones)
var anim := {}                  # id -> {prev, t_mov, an}
var ofertas := {}               # id destino -> {de, dar, recibir}: oferta de intercambio pendiente (sesión, no se guarda)
var registro := {"rechazos": {}, "tick_ms": [], "max_jugadores": 0, "bytes": 0.0}
var _firma_mundo := {}
var _firma_priv := {}
var _firma_perf := ""
var _acum := 0.0
var _guard_t := 0.0
var _t := 0.0

func _ready() -> void:
	for id in j.rt.keys():
		if id != local: j.salir(id)     # nadie controla a los jugadores guardados hasta que se conecten
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_CLIENTES)
	if err != OK:
		error = "No se pudo abrir el puerto %d (%s)" % [puerto, error_string(err)]
		push_error(error)
		if local == "": get_tree().quit(1)
		return
	(multiplayer as SceneMultiplayer).server_relay = false   # los clientes no se hablan entre sí
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_conectado)
	multiplayer.peer_disconnected.connect(retirar_peer)

func _exit_tree() -> void:
	if ruta != "": guardar()
	if ruta_registro != "": _escribir_registro()
	if multiplayer and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func guardar() -> bool:
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	return j.guardar(ruta)

func _conectado(pid: int) -> void:
	registrar_peer(pid)
	var ep: ENetPacketPeer = (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(pid)
	ep.set_timeout(32, 1000, 3000)          # caída abrupta detectada en ~4 s (por defecto 5-30 s)
	ep.throttle_configure(5000, 2, 0)       # sin esto ENet descarta 2-3 % de instantáneas con 15 clientes (red-minima)

func registrar_peer(pid: int) -> void:
	peers[pid] = {"id": "", "n": 0, "t_n": _t, "t0": _t, "fuera": false}

func retirar_peer(pid: int) -> void:
	var p: Dictionary = peers.get(pid, {})
	peers.erase(pid)
	var id: String = p.get("id", "")
	if id == "": return
	ids.erase(id)
	intencion.erase(id)
	anim.erase(id)
	_firma_priv.erase(id)
	ofertas.erase(id)
	for k in ofertas.keys(): if ofertas[k].de == id: ofertas.erase(k)
	j.salir(id)
	j.aviso_todos("%s sale del mundo." % j.jug(id).nombre)

# ---------- identidad ----------
# "" si el nombre no vale. Solo letras, cifras, espacio, _ y -: el id derivado ("@" + minúsculas) no choca con "local".
static func nombre_valido(n) -> String:
	if typeof(n) != TYPE_STRING: return ""
	var s: String = n.strip_edges()
	if s.length() < 2 or s.length() > 16: return ""
	return s if RegEx.create_from_string("^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ _-]+$").search(s) != null else ""

static func id_de(nombre: String) -> String:
	return "@" + nombre.to_lower()

# ponytail: un SHA-256 con sal, no un KDF lento; basta para el alcance del ADR (amigos, clave = token aleatorio).
static func hash_clave(sal: String, clave: String) -> String:
	return (sal + ":" + clave).sha256_text()

# datos = [version, nombre, clave, look]. Devuelve {ok, id} o {ok: false, motivo}.
func entrar(pid: int, datos) -> Dictionary:
	if not peers.has(pid) or peers[pid].id != "": return {"ok": false, "motivo": "Conexión no válida"}
	if typeof(datos) != TYPE_ARRAY or datos.size() != 4: return {"ok": false, "motivo": "Datos de entrada no válidos"}
	if typeof(datos[0]) != TYPE_INT or datos[0] != VERSION: return {"ok": false, "motivo": "Versión distinta del servidor"}
	var nombre := nombre_valido(datos[1])
	if nombre == "": return {"ok": false, "motivo": "Nombre no válido (2-16 letras, cifras, espacio, _ o -)"}
	if typeof(datos[2]) != TYPE_STRING or datos[2].length() < 4 or datos[2].length() > 64: return {"ok": false, "motivo": "Clave no válida (4-64 caracteres)"}
	var clave: String = datos[2]
	var look := _look(datos[3])
	if look.is_empty(): return {"ok": false, "motivo": "Apariencia no válida"}
	var id := id_de(nombre)
	if j.d.jugadores.has(id):
		if ids.has(id): return {"ok": false, "motivo": "Ese jugador ya está conectado"}
		var cl: Dictionary = j.jug(id).get("clave", {})
		if cl.is_empty() or hash_clave(cl.sal, clave) != cl.hash: return {"ok": false, "motivo": "Clave incorrecta"}
		j.entrar(id)
		j.aviso("Vuelves al mundo.", id)
	else:
		var alta: Dictionary = j.unir(id, nombre, look)
		if not alta.ok: return {"ok": false, "motivo": str(alta.msg)}   # modo poblado sin posición segura: no se crea al jugador
		var sal := Crypto.new().generate_random_bytes(16).hex_encode()
		j.jug(id)["clave"] = {"sal": sal, "hash": hash_clave(sal, clave)}
	peers[pid].id = id
	ids[id] = pid
	intencion[id] = Vector2i.ZERO
	ultimo_seq[id] = -1          # el cliente numera desde 1 en cada conexión
	j.aviso_todos("%s entra al mundo." % j.jug(id).nombre)
	return {"ok": true, "id": id}

static func _look(v) -> Array:
	return v.duplicate() if Aspecto.valido(v) else []

# ---------- RPC (mismos nombres y modos que red_cliente.gd) ----------
## Cliente -> servidor: única entrada. Sin tipo a propósito: se valida en recibir().
@rpc("any_peer", "call_remote", "reliable")
func pedir(datos) -> void:
	if multiplayer.is_server(): recibir(multiplayer.get_remote_sender_id(), datos)

## Servidor -> cliente (eventos fiables). "authority": el motor descarta las llamadas de un cliente.
@rpc("authority", "call_remote", "reliable")
func evento(_datos) -> void:
	pass

## Servidor -> clientes (instantánea a 20 Hz, puede perderse).
@rpc("authority", "call_remote", "unreliable_ordered")
func instantanea(_datos) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func instantanea_fiable(_datos: Array) -> void:
	pass

# Devuelve true si el pedido pasó la validación (no si la acción de juego tuvo éxito).
func recibir(pid: int, datos) -> bool:
	var p: Dictionary = peers.get(pid, {})
	if p.is_empty() or p.fuera: return false
	if _t - p.t_n >= 1.0:
		p.t_n = _t
		p.n = 0
	p.n += 1
	if p.n > MAX_PEDIDOS_S: return _rechazo(p.id, "ritmo")
	if p.id == "":
		if typeof(datos) != TYPE_ARRAY or not datos.size() in [5, 6] or typeof(datos[0]) != TYPE_STRING or datos[0] != "hola":
			return _rechazo("", "sin identificar")
		var r := _verificar_hola(datos)
		if r.is_empty(): r = entrar(pid, datos.slice(1, 5))
		if r.ok: _enviar(pid, ["bienvenida", estado_para(r.id)])
		else:
			_enviar(pid, ["rechazo", r.motivo])
			_expulsar(pid)
		return r.ok
	return ejecutar(p.id, datos)

## «hola» = [tag, versión, nombre, clave, apariencia, huella de reglas]. Devuelve {} si versión y reglas coinciden con las del
## servidor, o el rechazo. Evita que la réplica (que calcula planos y saberes con sus propios archivos) use reglas distintas.
static func _verificar_hola(datos: Array) -> Dictionary:
	if typeof(datos[1]) != TYPE_INT or datos[1] != VERSION: return {"ok": false, "motivo": "Versión distinta del servidor"}
	if datos.size() != 6 or typeof(datos[5]) != TYPE_STRING or datos[5] != Huella.huella():
		return {"ok": false, "motivo": "Reglas distintas a las del servidor (huella de reglas)"}
	return {}

func _rechazo(id: String, motivo: String) -> bool:
	var k := id if id != "" else "?"
	registro.rechazos[k] = int(registro.rechazos.get(k, 0)) + 1
	if OS.is_debug_build() and OS.get_environment("LINDE_RED_TRAZA") == "1": print("red: rechazo %s: %s" % [k, motivo])
	return false

# datos = [tipo, seq, ...argumentos]. Ejecuta la intención con el id de quien la envía.
func ejecutar(id: String, datos) -> bool:
	if not j.rt.has(id): return _rechazo(id, "sin sesión")
	if typeof(datos) != TYPE_ARRAY or datos.size() < 2 or typeof(datos[0]) != TYPE_STRING or typeof(datos[1]) != TYPE_INT:
		return _rechazo(id, "formato")
	var seq: int = datos[1]
	if seq <= int(ultimo_seq.get(id, -1)): return _rechazo(id, "repetido")
	ultimo_seq[id] = seq
	var tipo: String = datos[0]
	var a: Array = datos.slice(2)
	match tipo:
		"mov":
			if not _sig(a, [TYPE_VECTOR2I]) or not DIRS.has(a[0]): return _rechazo(id, "mov")
			intencion[id] = a[0]
		"accion", "interactuar":
			if not _sig(a, [TYPE_VECTOR2I]) or a[0] == Vector2i.ZERO or not DIRS.has(a[0]): return _rechazo(id, tipo)
			_mirar(id, a[0])
			if tipo == "accion": j.accion(id)
			else: _enviar(ids.get(id, 0), ["interaccion", j.interactuar(id)])
		"refinar_material":
			if not _sig(a,[TYPE_STRING]): return _rechazo(id,tipo)
			j.refinar_material(a[0],id)
		"fabricar_artefacto":
			if not _sig(a, [TYPE_STRING]): return _rechazo(id,tipo)
			j.fabricar_artefacto(a[0],id)
		"comprar_artefacto":
			if not _sig(a, [TYPE_STRING,TYPE_STRING]): return _rechazo(id,tipo)
			j.comprar_artefacto(a[0],a[1],id)
		"ensenar_saber", "pedir_saber":     # [habitante, saber]: el servidor decide si hay lección; el cliente no fija éxito ni autor
			if not _sig(a, [TYPE_STRING,TYPE_STRING]) or not j.habitantes.ids.has(a[0]): return _rechazo(id,tipo)
			if tipo == "ensenar_saber": j.ensenar_saber(a[0],a[1],id)
			else: j.pedir_saber(a[0],a[1],id)
		"gestionar_pista":
			if not _sig(a, [TYPE_STRING]) or a[0] not in ["pedir", "descartar", "silenciar", "activar"]: return _rechazo(id, tipo)
			j.gestionar_pista(a[0], id)
		"preguntar_lugares":
			if not _sig(a, [TYPE_STRING]): return _rechazo(id, tipo)
			j.preguntar_lugares(a[0], id)
		"aportar_grupo":
			if not _sig(a, [TYPE_STRING]): return _rechazo(id, tipo)
			j.aportar_grupo(a[0], id)
		"ayudar_habitante":
			if not _sig(a, [TYPE_STRING, TYPE_BOOL]) or not j.habitantes.ids.has(a[0]): return _rechazo(id, tipo)
			j.ayudar_habitante(a[0], a[1], id)
		"dormir":
			if not a.is_empty(): return _rechazo(id, tipo)
			_dormir(id)
		"construir":
			if not _sig(a, [TYPE_STRING, TYPE_VECTOR2I]) or not C.CONSTR.has(a[0]) or not _cerca(id, a[1]): return _rechazo(id, tipo)
			_mirar(id, a[1] - Mundo.celda_de(j.pies_de(id)))
			j.construir(a[0], a[1], id)
		"retirar":
			if not _sig(a, [TYPE_VECTOR2I]) or not _cerca(id, a[0]): return _rechazo(id, tipo)
			j.retirar(a[0], id)
		"mejorar":
			if not _sig(a, [TYPE_STRING]) or Eq.leer(a[0]).is_empty(): return _rechazo(id, tipo)
			j.mejorar(a[0], id)
		"engarzar":
			if not _sig(a, [TYPE_STRING, TYPE_STRING]) or Eq.leer(a[0]).is_empty() or not Eq.datos().variantes.has(a[1]): return _rechazo(id, tipo)
			j.engarzar(a[0], a[1], id)
		"ofrecer":     # [destino, lo que doy, lo que pido]: queda pendiente hasta que el otro la acepte
			if not _sig(a, [TYPE_STRING, TYPE_DICTIONARY, TYPE_DICTIONARY]) or a[0] == id or not ids.has(a[0]) or not _lote(a[1]) or not _lote(a[2]):
				return _rechazo(id, tipo)
			ofertas[a[0]] = {"de": id, "dar": a[1], "recibir": a[2]}
			j.aviso("%s te ofrece %s por %s" % [j.jug(id).nombre, j._txt_items(a[1]), j._txt_items(a[2])], a[0])
		"aceptar_oferta":   # [quien ofreció]: el intercambio se valida y aplica entero en Juego.intercambiar
			if not _sig(a, [TYPE_STRING]) or ofertas.get(id, {}).get("de", "") != a[0] or not j.rt.has(a[0]): return _rechazo(id, tipo)
			var o: Dictionary = ofertas[id]
			ofertas.erase(id)
			j.intercambiar(o.de, id, o.dar, o.recibir)
		"fabricar", "usar", "equipar", "desequipar", "aprender", "aceptar", "entregar":
			if not _sig(a, [TYPE_STRING]) or not _clave_valida(tipo, a[0]): return _rechazo(id, tipo)
			match tipo:
				"fabricar": j.fabricar(a[0], id)
				"usar": j.usar(a[0], id)
				"equipar": j.equipar(a[0], id)
				"desequipar": j.desequipar(a[0], id)
				"aprender": j.aprender(a[0], id)
				"aceptar": j.aceptar(a[0], id)
				"entregar": j.entregar(a[0], id)
		"gestionar_cofre":
			if not _sig(a, [TYPE_STRING, TYPE_STRING, TYPE_STRING]) or not _cofre_cerca(id, a[0]): return _rechazo(id, tipo)
			j.gestionar_cofre(a[0], a[1], a[2], id)
		"mover_cofre":
			if not _sig(a, [TYPE_STRING, TYPE_STRING, TYPE_BOOL]) or not Eq.existe(a[1]) or not _cofre_cerca(id, a[0]):
				return _rechazo(id, tipo)
			j.mover_cofre(a[0], a[1], a[2], id)
		_:
			return _rechazo(id, "tipo desconocido")
	return true

static func _sig(a: Array, tipos: Array) -> bool:
	if a.size() != tipos.size(): return false
	for i in tipos.size():
		if typeof(a[i]) != tipos[i]: return false
		if tipos[i] == TYPE_STRING and a[i].length() > MAX_TEXTO: return false
	return true

# Las misiones con quien las da («da») se aceptan y entregan hablando; por pedido solo las de mundo (da == "").
static func _clave_valida(tipo: String, k: String) -> bool:
	match tipo:
		"fabricar": return Eq.recetas().has(k)
		"usar", "equipar": return Eq.existe(k)
		"desequipar": return k in C.RANURAS
		"aprender": return C.HAB.has(k)
		"aceptar", "entregar": return C.MISIONES.has(k) and C.MISIONES[k].da == ""
	return false

# Lote de intercambio: {clave existente: entero 1..9999}, 1..MAX_LOTE entradas.
static func _lote(v) -> bool:
	if typeof(v) != TYPE_DICTIONARY or v.is_empty() or v.size() > MAX_LOTE: return false
	for k in v:
		if typeof(k) != TYPE_STRING or k.length() > MAX_TEXTO or not Eq.existe(k): return false
		if typeof(v[k]) != TYPE_INT or v[k] < 1 or v[k] > 9999: return false
	return true

func _mirar(id: String, d: Vector2i) -> void:
	if d != Vector2i.ZERO and DIRS.has(d): j.rt[id].mira = d

func _cerca(id: String, c: Vector2i) -> bool:
	var b := Mundo.celda_de(j.pies_de(id))
	return j.mundo.valida(c) and j.mundo.region_cargada(c) and maxi(absi(c.x - b.x), absi(c.y - b.y)) <= ALCANCE

# Solo cofres construidos ("c@x,y"); el tesoro del mundo se abre con «interactuar».
func _cofre_cerca(id: String, cid: String) -> bool:
	if not cid.begins_with("c@") or not j.d.cofres.has(cid): return false
	var p := cid.substr(2).split(",")
	return p.size() == 2 and _cerca(id, Vector2i(int(p[0]), int(p[1])))

func _dormir(id: String) -> void:
	var base := Mundo.celda_de(j.pies_de(id))
	for c in [base + j.rt[id].mira, base]:
		var cs: Dictionary = j.mundo.constr_en(c)
		if cs.get("t", "") == "cama" and cs.get("dueno", "") == id:
			j.dormir(c, id)
			return
	j.aviso("No hay una cama tuya delante", id)

func _expulsar(pid: int) -> void:
	if peers.has(pid): peers[pid].fuera = true
	if not is_inside_tree(): return
	get_tree().create_timer(0.3).timeout.connect(func():      # deja salir el mensaje de rechazo antes de cortar
		if multiplayer.multiplayer_peer is ENetMultiplayerPeer and peers.has(pid): multiplayer.multiplayer_peer.disconnect_peer(pid)
		peers.erase(pid))

# ---------- bucle ----------
func _process(delta: float) -> void:
	_t += delta
	_acum += minf(delta, 0.25)
	while _acum >= TICK:
		_acum -= TICK
		paso(TICK)
	for pid in peers.keys():
		if peers[pid].id == "" and not peers[pid].fuera and _t - peers[pid].t0 > ESPERA_HOLA_S: _expulsar(pid)
	if ruta != "":
		_guard_t += delta
		if _guard_t >= GUARDADO_S:
			_guard_t = 0.0
			guardar()
	if duracion > 0.0 and _t >= duracion:
		duracion = 0.0
		get_tree().quit()

# Un tick: mueve a los jugadores remotos según su última intención, avanza el mundo y difunde.
func paso(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	for id in intencion: j.mover_pj(intencion[id], dt, id)
	j.tick(dt)
	for id in j.rt:
		var pies: Vector2 = j.rt[id].pies
		var a: Dictionary = anim.get(id, {"prev": pies, "t_mov": 0.0})
		var mov: bool = pies != a.prev
		a.t_mov = a.t_mov + dt if mov else 0.0
		a.prev = pies
		a["an"] = j.anim_pj(mov, a.t_mov, id)
		anim[id] = a
	if is_inside_tree() and multiplayer.multiplayer_peer is ENetMultiplayerPeer: _difundir()
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	if registro.tick_ms.size() < 20000: registro.tick_ms.append(ms)
	registro.max_jugadores = maxi(registro.max_jugadores, ids.size())

func _difundir() -> void:
	var dentro: Array = []
	for pid in peers: if peers[pid].id != "": dentro.append(pid)
	if dentro.is_empty(): return
	var inst := instantanea_actual()
	# ENet no debe fragmentar instantáneas grandes en el canal sin fiabilidad.
	var grande := var_to_bytes(inst).size() > 1200
	for pid in dentro:
		if grande: instantanea_fiable.rpc_id(pid,inst)
		else: instantanea.rpc_id(pid, inst)
	var cambios := {}
	for k in SECCIONES:
		var v = _seccion(k)
		var f := JSON.stringify(v)
		if f != _firma_mundo.get(k, ""):
			_firma_mundo[k] = f
			cambios[k] = v
	if not cambios.is_empty():
		for pid in dentro: _enviar(pid, ["mundo", cambios])
	var perf := perfiles()
	var fp := JSON.stringify(perf)
	if fp != _firma_perf:
		_firma_perf = fp
		for pid in dentro: _enviar(pid, ["perfiles", perf])
	for pid in dentro:
		var id: String = peers[pid].id
		var pr := privado(id)
		var f := JSON.stringify(pr)
		if f != _firma_priv.get(id, ""):
			_firma_priv[id] = f
			_enviar(pid, ["privado", pr])
	registro.bytes += (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_host().pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)

func _enviar(pid: int, datos: Array) -> void:
	if pid != 0 and is_inside_tree() and multiplayer.multiplayer_peer is ENetMultiplayerPeer: evento.rpc_id(pid, datos)

func _seccion(k: String):
	if k in ["registro", "poblados"]: return j.d.mundo.get(k, {})
	return j.d.mundo[k] if k in ["rotos", "golpes", "constr", "caminos", "techos", "registro"] else j.d[k]

# ---------- lo que ve cada cliente ----------
# [min, {id: [x, y, mira_x, mira_y, anim, cuadro, hp, ataque_est, inv_t]}, [[tipo, x, y, est, hp, atq, t, dx, dy]], {npc: [x, y, act]}]
func instantanea_actual() -> Array:
	var jug := {}
	for id in j.rt:
		var s: Dictionary = j.rt[id]
		var a: Dictionary = j.combate.ataque(id)
		var an: Dictionary = anim.get(id, {}).get("an", {"estado": "reposo", "cuadro": 0})
		jug[id] = [s.pies.x, s.pies.y, s.mira.x, s.mira.y, an.estado, an.cuadro, j.jug(id).hp, a.est, a.inv_t]
	var ene: Array = []
	for e in j.combate.enemigos:
		ene.append([e.tipo, e.pos.x, e.pos.y, e.est, e.hp, e.atq, e.t, e.dir.x, e.dir.y])
	var npcs := {}
	for nid in j.d.npcs: npcs[nid] = [j.d.npcs[nid].pos[0], j.d.npcs[nid].pos[1], j.d.npcs[nid].act]
	secuencia_instantanea += 1
	return [j.d.min, jug, ene, npcs, secuencia_instantanea]

# Nombre, aspecto y equipo visible de los presentes (fiable, solo cuando cambia).
func perfiles() -> Dictionary:
	var r := {}
	for id in j.rt: r[id] = {"nombre": j.jug(id).nombre, "look": j.jug(id).look, "equipo": j.jug(id).equipo}
	return r

# Estado privado: solo al dueño. Nunca incluye el hash de la clave.
func privado(id: String) -> Dictionary:
	var pr: Dictionary = j.jug(id).duplicate(true)
	pr.erase("clave")
	pr.erase("pos")
	pr["pista_contextual"] = j.pista_contextual(id).duplicate(true)
	pr["msgs"] = j.rt[id].msgs.duplicate() if j.rt.has(id) else []
	return pr

# Estado completo al unirse: lo compartido + lo privado del que entra (en jugadores["local"] de su réplica).
func estado_para(id: String) -> Dictionary:
	var pr := privado(id)
	var p: Vector2 = j.pies_de(id)
	pr["pos"] = [p.x, p.y]
	return {"yo": id, "semilla": j.d.semilla, "min": j.d.min, "mundo": j.d.mundo.duplicate(true), "cofres": j.d.cofres.duplicate(true),
		"jefes": j.d.jefes.duplicate(true), "mundo_vivo": j.d.mundo_vivo.duplicate(true), "npcs": j.d.npcs.duplicate(true), "jugadores": {P.LOCAL: pr}, "perfiles": perfiles()}

# Para dibujar a los demás en el anfitrión con ventana (mismo formato que red_cliente.otros_jugadores).
func otros_jugadores() -> Array:
	var l: Array = []
	for id in j.rt:
		if id == local: continue
		var an: Dictionary = anim.get(id, {}).get("an", {"estado": "reposo", "cuadro": 0})
		l.append({"nombre": j.jug(id).nombre, "look": j.jug(id).look, "pies": j.rt[id].pies, "mira": j.rt[id].mira,
			"estado": an.estado, "cuadro": an.cuadro, "equipo": j.jug(id).equipo})
	return l

func estado_txt() -> String:
	return "Alojando en el puerto %d · %d conectado(s)" % [puerto, ids.size()]

func _escribir_registro() -> void:
	var t: Array = registro.tick_ms.duplicate()
	t.sort()
	var r := {"rechazos": registro.rechazos, "max_jugadores": registro.max_jugadores, "ticks": t.size(),
		"tick_ms_p95": t[int(t.size() * 0.95)] if not t.is_empty() else -1.0, "tick_ms_max": t.back() if not t.is_empty() else -1.0,
		"bytes_enviados": registro.bytes, "segundos": _t}
	var f := FileAccess.open(ruta_registro, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(r, "  "))
