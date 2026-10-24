extends SceneTree
# Jugador automático para tests/prueba_red.gd: un proceso = un cliente real (red_cliente.gd + réplica).
# Uso: godot --headless --path Linde/cenital --script res://tests/bot_red.gd -- <rol> <puerto> <nombre> <clave> <dir>
# Roles: A (trampas, rompe una roca, se mueve hasta «fin») · B (rompe un arbusto, espera a ver la roca rota, sale)
#        Bmala (clave incorrecta) · B2 (reconecta y anota su estado). Escribe <dir>/<rol>.json.
const Cli = preload("res://scripts/red_cliente.gd")
const Mundo = preload("res://scripts/mundo.gd")
const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var c
var rol := ""
var dir := ""
var reg := {"vio_mover": {}, "max_salto": 0.0}
var _primera := {}
var _ult_pos := Vector2.INF
var _ult_n := 0
var _fallo := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	rol = a[0]
	dir = a[4]
	Engine.max_fps = 60
	c = Cli.new()
	c.name = "Red"
	c.puerto = int(a[1])
	c.nombre = a[2]
	c.clave = a[3]
	c.look = [1, 1, 1] if rol.begins_with("B") else [0, 2, 0]
	c.fallo.connect(func(m: String): _fallo = m)
	root.add_child(c)
	_correr()

func _fin() -> void:
	if c.j != null:
		reg["inv"] = c.j.jug().inv
		reg["pos"] = [c.pos_servidor.x, c.pos_servidor.y]
	reg["instantaneas"] = c.instantaneas
	reg["fallo"] = _fallo
	var f := FileAccess.open(dir.path_join(rol + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(reg, "  "))
	f.close()
	c.cerrar()
	await create_timer(0.3).timeout
	quit()

func _bandera(n: String) -> bool:
	return FileAccess.file_exists(dir.path_join(n))

# Un fotograma con observación: saltos de la posición propia según el servidor y movimiento de los demás.
func _frame() -> void:
	await process_frame
	if c.j == null: return
	if c.instantaneas != _ult_n:
		if _ult_pos != Vector2.INF:
			reg.max_salto = maxf(reg.max_salto, _ult_pos.distance_to(c.pos_servidor) / float(c.instantaneas - _ult_n))
		_ult_pos = c.pos_servidor
		_ult_n = c.instantaneas
	for id in c.otros:
		var p: Vector2 = c.otros[id].get("objetivo", c.otros[id].pies)
		if not _primera.has(id): _primera[id] = p
		elif p.distance_to(_primera[id]) > 4.0: reg.vio_mover[id] = true

func _esperar(s: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < s * 1000.0: await _frame()

func _conectar() -> bool:
	var t := Time.get_ticks_msec()
	while c.j == null and _fallo == "" and Time.get_ticks_msec() - t < 9000: await _frame()
	reg["conexion_ms"] = c.t_conexion_ms
	reg["bienvenida_ms"] = Time.get_ticks_msec() - t
	reg["yo"] = c.yo
	return c.j != null

func _correr() -> void:
	if not await _conectar():
		await _fin()
		return
	match rol:
		"A": await _rol_a()
		"B": await _rol_b()
		"B2": await _esperar(1.5)
	await _fin()

# Camina (solo intenciones de dirección) hasta una celda junto a un objeto del tipo pedido y lo golpea hasta romperlo.
func _romper(tipo: String) -> String:
	var m = c.j.mundo
	var meta := func(cc: Vector2i) -> bool:
		for d in DIRS:
			var o: String = m.objeto_presente(cc + d)
			if o != "" and m.objetos[o].t == tipo: return true
		return false
	var ruta: Array = m.camino(Mundo.celda_de(c.pos_servidor), meta)
	reg["ruta_" + tipo] = ruta.size()
	for i in range(1, ruta.size()):
		var dest := Mundo.pies_de_celda(ruta[i])
		var t := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t < 5000:
			var d: Vector2 = dest - c.pos_servidor
			if maxf(absf(d.x), absf(d.y)) <= 2.5: break
			c.j.mover_pj(Vector2i(signi(int(signf(d.x))), 0) if absf(d.x) >= absf(d.y) else Vector2i(0, int(signf(d.y))), 0.0)
			await _frame()
	c.j.mover_pj(Vector2i.ZERO, 0.0)
	await _esperar(0.2)
	var base := Mundo.celda_de(c.pos_servidor)
	for d in DIRS:
		var oid: String = m.objeto_presente(base + d)
		if oid == "" or m.objetos[oid].t != tipo: continue
		c.j.mira = d
		var t := Time.get_ticks_msec()
		while m.objeto_presente(base + d) != "" and Time.get_ticks_msec() - t < 20000:
			c.j.accion()
			await _frame()
		await _esperar(0.3)
		return oid if m.objeto_presente(base + d) == "" else ""
	return ""

func _vaiven(s: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < s * 1000.0:
		c.j.mover_pj(Vector2i.LEFT if int((Time.get_ticks_msec() - t) / 600.0) % 2 == 0 else Vector2i.RIGHT, 0.0)
		await _frame()
	c.j.mover_pj(Vector2i.ZERO, 0.0)

func _rol_a() -> void:
	var inv0: Dictionary = c.j.jug().inv.duplicate()
	var p0: Vector2 = c.pos_servidor
	var constr0: int = c.j.d.mundo.constr.size()
	# Trampas: nada de esto debe cambiar el estado (el servidor valida tipo, rango, alcance y repetición).
	c.enviar(["mov", Vector2(500, 500)])
	c.enviar(["mov", Vector2i(25, 25)])
	c.enviar(["construir", "muro", Vector2i(2, 2)])
	c.enviar(["fabricar", 42])
	c.enviar(["teletransporte", Vector2i(10, 10)])
	c.enviar(["mover_cofre", "tesoro_cantera", "gema", false])
	c.enviar(["accion", Vector2i(3, 3)])
	c.pedir.rpc_id(1, "basura")
	c.pedir.rpc_id(1, ["accion", 1, Vector2i.UP])                  # número de pedido ya usado
	c.instantanea.rpc_id(1, [0, {c.yo: [999.0, 999.0, 0, 1, "reposo", 0, 40, "libre", 0.0]}, [], {}])   # se hace pasar por el servidor
	c.evento.rpc_id(1, ["mundo", {"rotos": {}}])
	await _esperar(1.0)
	reg["trampas"] = {"pos_igual": c.pos_servidor == p0, "inv_igual": c.j.jug().inv == inv0,
		"constr_igual": c.j.d.mundo.constr.size() == constr0 and not c.j.d.mundo.constr.has("2,2")}
	reg["max_salto_trampas"] = reg.max_salto
	var oid := await _romper("roca")
	reg["roca"] = oid
	var f := FileAccess.open(dir.path_join("A_roca"), FileAccess.WRITE)
	f.store_string(oid)
	f.close()
	var t_fin := Time.get_ticks_msec()
	var tras := -1
	while not _bandera("fin") and Time.get_ticks_msec() - t_fin < 90000:
		await _vaiven(1.2)
		if _bandera("B_salio"):
			if tras < 0: tras = c.instantaneas
			if not c.otros.has("@bea") and not reg.has("bea_fuera_tras"): reg["bea_fuera_tras"] = c.instantaneas - tras
		if _bandera("B2_dentro") and c.otros.has("@bea"): reg["bea_vuelve"] = true
	reg["inst_tras_salida_b"] = c.instantaneas - tras if tras >= 0 else -1

func _rol_b() -> void:
	reg["arbusto"] = await _romper("arbusto")
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < 90000:
		await _vaiven(1.2)
		if _bandera("A_roca"):
			var oid := FileAccess.get_file_as_string(dir.path_join("A_roca"))
			if oid != "" and c.j.d.mundo.rotos.has(oid) and c.j.mundo.objeto_presente(c.j.mundo.objetos[oid].c) == "":
				reg["vio_roca_rota"] = oid
				break
	await _vaiven(1.5)
	await _esperar(0.4)
