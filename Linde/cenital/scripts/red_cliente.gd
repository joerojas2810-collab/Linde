extends Node
# Cliente del «mundo anfitrión»: se conecta, envía INTENCIONES y mantiene una RÉPLICA de Juego que no simula:
# solo aplica la instantánea (20 Hz) y los eventos fiables del servidor. escena.gd y hud.gd leen la réplica como
# el Juego de un jugador; sus acciones (fabricar, construir...) se convierten en pedidos. El cliente no decide nada.
# Vive en /root/Red y declara los MISMOS RPC que red_servidor.gd.
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const ESPERA_S := 8.0
const SALTO_PX := 48.0          # más lejos que esto, la posición mostrada salta en vez de suavizarse

signal listo                     # bienvenida recibida: j es la réplica
signal fallo(motivo: String)     # no se pudo entrar o se perdió la conexión
signal interaccion(r: Dictionary)

var direccion := "127.0.0.1"
var puerto := Srv.PUERTO
var nombre := ""
var clave := ""
var look: Array = [0, 0, 0]
var j = null                     # Replica
var yo := ""                     # id del jugador en el servidor
var otros := {}                  # id -> {pies (mostrada), objetivo, mira, estado, cuadro, hp}
var perfiles := {}               # id -> {nombre, look}
var pos_servidor := Vector2.ZERO # posición propia según la última instantánea
var anim_propia := {"estado": "reposo", "cuadro": 0}
var instantaneas := 0
var ultima_instantanea := -1
var t_conexion_ms := -1.0
var _seq := 0
var _t0 := 0
var _terminado := false

func _ready() -> void:
	_t0 = Time.get_ticks_msec()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(direccion, puerto)
	if err != OK:
		_fallar.call_deferred("No se pudo crear la conexión (%s)" % error_string(err))
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_conectado)
	multiplayer.connection_failed.connect(func(): _fallar("No se pudo conectar con %s:%d" % [direccion, puerto]))
	multiplayer.server_disconnected.connect(func(): _fallar("Conexión perdida con el servidor"))
	get_tree().create_timer(ESPERA_S).timeout.connect(func(): if j == null: _fallar("El servidor no responde (¿lleno o apagado?)"))

func _exit_tree() -> void:
	cerrar()

func cerrar() -> void:
	_terminado = true
	if multiplayer and multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _fallar(motivo: String) -> void:
	if _terminado: return
	cerrar()
	fallo.emit(motivo)

func _conectado() -> void:
	t_conexion_ms = Time.get_ticks_msec() - _t0
	pedir.rpc_id(1, ["hola", Srv.VERSION, nombre, clave, look, Srv.Huella.huella()])

# Envía una intención: [tipo, ...argumentos] -> [tipo, seq, ...argumentos].
func enviar(a: Array) -> void:
	if _terminado or j == null: return
	_seq += 1
	pedir.rpc_id(1, [a[0], _seq] + a.slice(1))

# ---------- RPC (mismos nombres y modos que red_servidor.gd) ----------
@rpc("any_peer", "call_remote", "reliable")
func pedir(_datos) -> void:
	pass    # solo lo atiende el servidor

@rpc("authority", "call_remote", "reliable")
func evento(datos: Array) -> void:
	match datos[0]:
		"bienvenida": _bienvenida(datos[1])
		"rechazo": _fallar(str(datos[1]))
		"perfiles": perfiles = datos[1]
		"interaccion": interaccion.emit(datos[1])
		"mundo":
			if j != null: _mundo(datos[1])
		"privado":
			if j != null: _privado(datos[1])

@rpc("authority", "call_remote", "reliable")
func instantanea_fiable(datos: Array) -> void:
	instantanea(datos)

@rpc("authority", "call_remote", "unreliable_ordered")
func instantanea(datos: Array) -> void:
	if j == null: return
	if datos.size()>4:
		if int(datos[4]) <= ultima_instantanea: return
		ultima_instantanea=int(datos[4])
	instantaneas += 1
	j.d.min = datos[0]
	var jug: Dictionary = datos[1]
	for id in otros.keys(): if not jug.has(id): otros.erase(id)
	for id in jug:
		var v: Array = jug[id]
		var p := Vector2(v[0], v[1])
		if id == yo:
			pos_servidor = p
			anim_propia = {"estado": v[4], "cuadro": v[5]}
			j.jug().hp = v[6]
			var a: Dictionary = j.combate.ataque(P.LOCAL)
			a.est = v[7]
			a.inv_t = v[8]
			a.dir = j.mira
			continue
		if not otros.has(id): otros[id] = {"pies": p}
		var o: Dictionary = otros[id]
		o.objetivo = p
		o.mira = Vector2i(v[2], v[3])
		o.estado = v[4]
		o.cuadro = v[5]
		o.hp = v[6]
	var ene: Array = []
	for e in datos[2]:
		ene.append({"tipo": e[0], "pos": Vector2(e[1], e[2]), "est": e[3], "hp": e[4], "atq": e[5], "t": e[6],
			"dir": Vector2(e[7], e[8]), "tam": C.ENEMIGOS[e[0]].tam})
	j.combate.enemigos = ene
	var npcs: Dictionary = datos[3]
	for nid in npcs:
		if j.d.npcs.has(nid):
			j.d.npcs[nid].pos = [npcs[nid][0], npcs[nid][1]]
			j.d.npcs[nid].act = npcs[nid][2]

# ---------- aplicar estado ----------
func _bienvenida(e: Dictionary) -> void:
	yo = e.yo
	perfiles = e.perfiles
	var r := Replica.new()
	r.red = self
	r.d = {"semilla": e.semilla, "min": e.min, "mundo": e.mundo, "cofres": e.cofres, "jefes": e.jefes, "mundo_vivo": e.mundo_vivo, "npcs": e.npcs, "jugadores": e.jugadores}
	r.d.mundo.constr = _traducir(r.d.mundo.constr)
	var m: Array = r.d.jugadores[P.LOCAL].get("msgs", [])
	r.d.jugadores[P.LOCAL].erase("msgs")
	r._arrancar()
	r.combate.enemigos.clear()
	r.rt[P.LOCAL].msgs = m
	pos_servidor = r.pies
	j = r
	listo.emit()

func _mundo(cambios: Dictionary) -> void:
	for k in cambios:
		match k:
			"rotos", "golpes", "caminos", "techos": j.d.mundo[k] = cambios[k]
			"constr": j.d.mundo.constr = _traducir(cambios[k])
			"cofres", "jefes": j.d[k] = cambios[k]
			"mundo_vivo":
				j.d.mundo_vivo = cambios[k]
				j.habitantes.reconciliar()    # crea al recién llegado en la réplica; su posición sigue viniendo de la instantánea
	j.mundo.cambiar()

func _privado(pr: Dictionary) -> void:
	j.rt[P.LOCAL].msgs = pr.get("msgs", [])
	pr.erase("msgs")
	var jl: Dictionary = j.jug()
	for k in pr: jl[k] = pr[k]

# En la réplica el jugador propio es "local": sus piezas pasan a dueno "local"; las del anfitrión (id "local" en el
# servidor) se renombran para no confundirse con las propias.
func _traducir(constr: Dictionary) -> Dictionary:
	for k in constr:
		var cs: Dictionary = constr[k]
		if not cs.has("dueno"): continue
		if cs.dueno == yo: cs.dueno = P.LOCAL
		elif cs.dueno == P.LOCAL: cs.dueno = "anfitrion:local"
	return constr

# Suavizado de lo mostrado (no cambia lo que decide el servidor).
func _process(delta: float) -> void:
	if j == null: return
	j.rt[P.LOCAL].pies = _suave(j.pies, pos_servidor, delta)
	j.actualizar_regiones()
	for id in otros: otros[id].pies = _suave(otros[id].pies, otros[id].get("objetivo", otros[id].pies), delta)
	if j._dir_env != Vector2i.ZERO and Engine.get_process_frames() - j._frame_mov > 1:
		j.mover_pj(Vector2i.ZERO, 0.0)      # la escena dejó de pedir movimiento (panel abierto, construir...)

static func _suave(a: Vector2, b: Vector2, delta: float) -> Vector2:
	return b if a.distance_to(b) > SALTO_PX else a.lerp(b, minf(1.0, delta * 15.0))

func otros_jugadores() -> Array:
	var l: Array = []
	for id in otros:
		var o: Dictionary = otros[id]
		var pf: Dictionary = perfiles.get(id, {"nombre": "?", "look": [0, 0, 0]})
		l.append({"nombre": pf.nombre, "look": pf.look, "pies": o.pies, "mira": o.get("mira", Vector2i.DOWN),
			"estado": o.get("estado", "reposo"), "cuadro": o.get("cuadro", 0),
			"equipo": pf.get("equipo") if pf.get("equipo") is Dictionary else {}})
	return l

func estado_txt() -> String:
	return "Conectado a %s:%d · %d jugador(es)" % [direccion, puerto, otros.size() + 1]

# Réplica: mismo Juego (lecturas, estadísticas, misiones), pero sin simular y con las acciones convertidas en pedidos.
class Replica extends "res://scripts/juego.gd":
	var red
	var _dir_env := Vector2i.ZERO
	var _frame_mov := 0
	var _t_accion := -1000

	func actor_desarrollo(_id: String = LOCAL) -> String:
		return "pj:" + red.yo

	func es_autoridad() -> bool:
		return false

	func tick(_dt: float) -> void:
		pass                                   # el mundo lo avanza el servidor

	func guardar(_ruta: String) -> bool:
		return true                            # el mundo lo guarda el servidor

	func mover_pj(dir: Vector2i, _dt: float, _id: String = LOCAL) -> void:
		actualizar_regiones()
		_frame_mov = Engine.get_process_frames()
		if dir != Vector2i.ZERO: rt[LOCAL].mira = dir
		if dir != _dir_env:
			_dir_env = dir
			red.enviar(["mov", dir])

	func accion(_id: String = LOCAL) -> Dictionary:
		var t := Time.get_ticks_msec()
		if t - _t_accion >= 100:               # la escena llama cada fotograma con Espacio pulsado
			_t_accion = t
			red.enviar(["accion", mira])
		return {"ok": true, "msg": ""}

	func anim_pj(_mov: bool, _t_mov: float, _id: String = LOCAL) -> Dictionary:
		return red.anim_propia

	func interactuar(_id: String = LOCAL) -> Dictionary:
		red.enviar(["interactuar", mira])      # la respuesta llega como evento «interaccion»
		return {"ok": false}

	func refinar_material(material: String, _id: String = LOCAL) -> Dictionary:
		return _env(["refinar_material",material])

	func fabricar_artefacto(clave: String, _id: String = LOCAL) -> Dictionary:
		return _env(["fabricar_artefacto",clave])

	func comprar_artefacto(npc: String, clave: String, _id: String = LOCAL) -> Dictionary:
		return _env(["comprar_artefacto",npc,clave])

	func ensenar_saber(npc: String, saber: String, _id: String = LOCAL) -> Dictionary:
		return _env(["ensenar_saber",npc,saber])

	func pedir_saber(npc: String, saber: String, _id: String = LOCAL) -> Dictionary:
		return _env(["pedir_saber",npc,saber])

	func aportar_grupo(grupo: String, _id: String = LOCAL) -> Dictionary:
		return _env(["aportar_grupo", grupo])

	func ayudar_habitante(npc: String, rechazar: bool = false, _id: String = LOCAL) -> Dictionary:
		return _env(["ayudar_habitante", npc, rechazar])

	func construir(pieza: String, c: Vector2i, _id: String = LOCAL) -> Dictionary: return _env(["construir", pieza, c])
	func retirar(c: Vector2i, _id: String = LOCAL) -> Dictionary: return _env(["retirar", c])
	func fabricar(rid: String, _id: String = LOCAL) -> Dictionary: return _env(["fabricar", rid])
	func usar(item: String, _id: String = LOCAL) -> Dictionary: return _env(["usar", item])
	func equipar(item: String, _id: String = LOCAL) -> Dictionary: return _env(["equipar", item])
	func desequipar(ranura: String, _id: String = LOCAL) -> Dictionary: return _env(["desequipar", ranura])
	func aprender(hid: String, _id: String = LOCAL) -> Dictionary: return _env(["aprender", hid])
	func mejorar(clave: String, _id: String = LOCAL) -> Dictionary: return _env(["mejorar", clave])
	func engarzar(clave: String, variante: String, _id: String = LOCAL) -> Dictionary: return _env(["engarzar", clave, variante])
	func aceptar(mid: String, _id: String = LOCAL) -> Dictionary: return _env(["aceptar", mid])
	func entregar(mid: String, _id: String = LOCAL) -> Dictionary: return _env(["entregar", mid])
	func gestionar_cofre(cid: String, accion: String, destino: String = "", _id: String = LOCAL) -> Dictionary:
		return _env(["gestionar_cofre", cid, accion, destino])

	func mover_cofre(cid: String, item: String, hacia_cofre: bool, _id: String = LOCAL) -> Dictionary:
		return _env(["mover_cofre", cid, item, hacia_cofre])

	func _env(a: Array) -> Dictionary:
		red.enviar(a)
		return {"ok": true, "msg": ""}
