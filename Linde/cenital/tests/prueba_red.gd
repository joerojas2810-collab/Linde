extends SceneTree
# Integración de red en localhost con procesos separados: 1 servidor sin ventana (escena con --servidor) y clientes
# reales (tests/bot_red.gd). Escribe tests/resultados_red.txt. Uso:
#   godot --headless --path Linde/cenital --script res://tests/prueba_red.gd     (código de salida 0 = todo OK)
const Mundo = preload("res://scripts/mundo.gd")
const J = preload("res://scripts/juego.gd")
const P = preload("res://scripts/params.gd")
const PUERTO := 7791
const DURACION_S := 35.0        # el servidor se cierra solo (y guarda) a los 35 s
var dir := ""
var lineas: PackedStringArray = []
var fallos := 0

func _initialize() -> void:
	dir = ProjectSettings.globalize_path("user://").path_join("pruebas_linde/red")
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(f))
	_correr()

func _lanzar(args: Array) -> int:
	return OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://")] + args)

func _bot(rol: String, nombre: String, clave: String) -> int:
	return _lanzar(["--script", "res://tests/bot_red.gd", "--", rol, str(PUERTO), nombre, clave, dir])

func _json(n: String) -> Dictionary:
	var r = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(n))) if FileAccess.file_exists(dir.path_join(n)) else null
	return r if r is Dictionary else {}

func _bandera(n: String) -> void:
	FileAccess.open(dir.path_join(n), FileAccess.WRITE).store_string("1")

func _esperar(pids: Array, max_s: float) -> bool:
	var t := Time.get_ticks_msec()
	while pids.any(func(p): return OS.is_process_running(p)) and Time.get_ticks_msec() - t < max_s * 1000.0:
		await create_timer(0.2).timeout
	var vivos := false
	for p in pids:
		if OS.is_process_running(p):
			OS.kill(p)
			vivos = true
	return not vivos

func _check(nombre: String, cond: bool, detalle: String) -> void:
	if not cond: fallos += 1
	lineas.append("[%s] %s -- %s" % ["OK" if cond else "FALLO", nombre, detalle])

# Semilla cuyo inicio tiene una roca y un arbusto a pocos pasos, lejos de slimes y jefes (la prueba no es de combate).
func _semilla() -> int:
	var m := Mundo.new()
	var mejor := [1, 9999]
	for s in range(1, 120):
		var ini: Vector2i = m.punto_inicio(s)
		var total := 0
		var ok := true
		for tipo in ["roca", "arbusto"]:
			var r: Array = m.camino(ini, func(c: Vector2i) -> bool:
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var o: String = m.objeto_presente(c + d)
					if o != "" and m.objetos[o].t == tipo: return true
				return false)
			if r.is_empty() or r.size() > 30: ok = false
			for c in r:
				for sp in m.spawns_slime: if Vector2(c).distance_to(Vector2(sp)) < 8.0: ok = false
			total += r.size()
		if ok and total < mejor[1]: mejor = [s, total]
	return mejor[0]

func _correr() -> void:
	lineas.append("Resultados prueba_red  %s  Godot %s" % [Time.get_datetime_string_from_system(), Engine.get_version_info().string])
	var semilla := _semilla()
	lineas.append("semilla %d · puerto %d · localhost, procesos separados" % [semilla, PUERTO])
	var t0 := Time.get_ticks_msec()
	var srv := _lanzar(["--", "--servidor", "--puerto=%d" % PUERTO, "--guardado=" + dir.path_join("mundo.json"), "--semilla=%d" % semilla,
		"--duracion=%d" % DURACION_S, "--registro=" + dir.path_join("registro.json")])
	await create_timer(1.5).timeout
	var a := _bot("A", "Ana", "clave-ana")
	var b := _bot("B", "Bea", "clave-bea")
	await _esperar([b], 80)
	_bandera("B_salio")
	await create_timer(2.5).timeout
	await _esperar([_bot("Bmala", "Bea", "clave-falsa")], 15)
	var b2 := _bot("B2", "Bea", "clave-bea")
	_bandera("B2_dentro")
	await _esperar([b2], 15)
	await create_timer(1.0).timeout
	_bandera("fin")
	await _esperar([a], 15)
	lineas.append("escenario de clientes terminado a los %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var srv_cerro := await _esperar([srv], DURACION_S + 15.0 - (Time.get_ticks_msec() - t0) / 1000.0)
	lineas.append("duración total %.1f s\n" % ((Time.get_ticks_msec() - t0) / 1000.0))
	_evaluar(srv_cerro)
	lineas.append("\nTOTAL: %d comprobaciones fallidas" % fallos)
	lineas.append("""
NO comprobado aquí:
- Red real (Wi-Fi/Internet, NAT, pérdida o latencia reales): todo es 127.0.0.1 en una máquina. Sin relay ni NAT.
- 10-15 clientes con juego real (el prototipo red-minima midió 15 con ENet; aquí hay 2).
- Latencia simulada de 100 ms, 60 s de movimiento continuo y 4 clientes simultáneos (criterios de la historia 002).
- La ventana del anfitrión y del cliente (dibujo de los demás, menú Unirse): solo se comprobó que la escena carga sin errores.""")
	var f := FileAccess.open("res://tests/resultados_red.txt", FileAccess.WRITE)
	f.store_string("\n".join(lineas) + "\n")
	f.close()
	print("\n".join(lineas))
	quit(1 if fallos else 0)

func _evaluar(srv_cerro: bool) -> void:
	var A := _json("A.json")
	var B := _json("B.json")
	var M := _json("Bmala.json")
	var B2 := _json("B2.json")
	var R := _json("registro.json")
	var vel := P.VELOCIDAD * 0.05
	_check("A y B conectan", A.get("yo", "") == "@ana" and B.get("yo", "") == "@bea" and float(A.get("conexion_ms", 99999)) < 5000 and float(B.get("conexion_ms", 99999)) < 5000,
		"conexión ms A=%s B=%s · bienvenida ms A=%s B=%s" % [A.get("conexion_ms"), B.get("conexion_ms"), A.get("bienvenida_ms"), B.get("bienvenida_ms")])
	_check("ambos se ven moverse", A.get("vio_mover", {}).has("@bea") and B.get("vio_mover", {}).has("@ana"),
		"A vio %s · B vio %s" % [A.get("vio_mover", {}).keys(), B.get("vio_mover", {}).keys()])
	var roca: String = A.get("roca", "")
	_check("A rompe una roca y B la ve desaparecer", roca != "" and B.get("vio_roca_rota", "") == roca and int(A.get("inv", {}).get("piedra", 0)) >= 2,
		"roca=%s (ruta %s celdas) · B vio=%s · piedra de A=%s" % [roca, A.get("ruta_roca"), B.get("vio_roca_rota", "no"), A.get("inv", {}).get("piedra", 0)])
	var ia: Dictionary = J._enteros(A.get("inv", {}))
	var ib: Dictionary = J._enteros(B.get("inv", {}))
	_check("inventarios independientes", ia.has("piedra") and not ia.has("fibra") and ib.has("fibra") and not ib.has("piedra"),
		"A=%s · B=%s (B rompió %s)" % [ia, ib, B.get("arbusto", "")])
	var tr: Dictionary = A.get("trampas", {})
	var rech := int(R.get("rechazos", {}).get("@ana", 0))
	_check("acciones inválidas o fuera de alcance de A ignoradas", tr.get("pos_igual", false) and tr.get("inv_igual", false) and tr.get("constr_igual", false) and rech >= 9,
		"%s · rechazos del servidor para @ana=%d (9 enviados; la instantánea y el evento falsos los descarta el motor) · salto máx tras trampas=%.2f px" % [tr, rech, float(A.get("max_salto_trampas", -1))])
	_check("la posición nunca supera la velocidad por tick", float(A.get("max_salto", 99)) <= vel + 0.01 and float(B.get("max_salto", 99)) <= vel + 0.01,
		"máx px por tick A=%.2f B=%.2f (límite %.2f)" % [float(A.get("max_salto", -1)), float(B.get("max_salto", -1)), vel])
	_check("la desconexión de B no afecta a A", A.has("bea_fuera_tras") and int(A.get("inst_tras_salida_b", 0)) >= 20,
		"A dejó de ver a @bea tras %s instantáneas y recibió %s más" % [A.get("bea_fuera_tras", "nunca"), A.get("inst_tras_salida_b")])
	_check("clave incorrecta rechazada", M.get("fallo", "") == "Clave incorrecta" and M.get("yo", "") == "", "Bmala: %s" % M.get("fallo", "sin datos"))
	var pb: Array = B.get("pos", [0, 0])
	var pb2: Array = B2.get("pos", [9999, 9999])
	_check("reconectar recupera inventario y posición", B2.get("yo", "") == "@bea" and J._enteros(B2.get("inv", {})) == ib and not ib.is_empty() and Vector2(pb[0], pb[1]).distance_to(Vector2(pb2[0], pb2[1])) <= 4.0,
		"B al salir %s en %s · B2 %s en %s · A la vio volver=%s" % [ib, pb, B2.get("inv"), pb2, A.get("bea_vuelve", false)])
	var g = J.cargar(dir.path_join("mundo.json")) if srv_cerro else null
	var txt := FileAccess.get_file_as_string(dir.path_join("mundo.json"))
	_check("el servidor se cierra solo y guarda el mundo", g != null and g.d.jugadores.get("@ana", {}).get("inv", {}) == ia and g.d.jugadores.get("@bea", {}).get("inv", {}) == ib
		and g.d.mundo.rotos.has(roca) and not txt.contains("clave-ana") and not txt.contains("clave-bea"),
		"cerró solo=%s · guardado con @ana y @bea, la roca rota y sin claves en claro" % srv_cerro)
	var seg := maxf(1.0, float(R.get("segundos", 1)))
	_check("tick del servidor < 16,67 ms (p95)", float(R.get("tick_ms_p95", 99)) < 16.67,
		"p95=%.3f ms máx=%.3f ms en %s ticks · enviados %.1f KB/s en total (%.1f KB/s por jugador conectado, media de %.0f s)" % [float(R.get("tick_ms_p95", -1)),
		float(R.get("tick_ms_max", -1)), R.get("ticks"), float(R.get("bytes_enviados", 0)) / 1024.0 / seg, float(R.get("bytes_enviados", 0)) / 1024.0 / seg / 2.0, seg])
