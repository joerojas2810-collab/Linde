extends "res://tests/prueba_orientacion_red.gd"
## Reutiliza el arnés ENet: expansión en vivo, dos réplicas y cofre compartido de un lugar.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0 and a[0] == "bot":
		carpeta = a[3]
		bot(a[1], int(a[2]))
	else:
		carpeta = "/tmp/linde-lugares-red-" + str(OS.get_process_id())
		servidor()
func esperar(condicion: Callable, n: int = 100) -> bool:
	for i in n:
		if condicion.call(): return true
		await create_timer(0.05).timeout
	return false
func bandera(n: String) -> void:
	FileAccess.open(carpeta + "/" + n, FileAccess.WRITE).store_string("1")
func bot(nombre: String, puerto: int) -> void:
	var c = Cli.new()
	c.name = "Red"
	c.nombre = "Visitante" + nombre
	c.clave = "lugares-" + nombre
	c.puerto = puerto
	var inspeccion := {"ok": false}
	c.interaccion.connect(func(r): inspeccion.ok = r.get("tipo", "") == "lugar" and r.get("nombre", "") == "Campamento de la Loma")
	root.add_child(c)
	var resultado := {}
	resultado.conecto = await esperar(func(): return c.j != null)
	if resultado.conecto:
		resultado.bienvenida = c.j.d.mundo.get("registro", {}).get("lugares", {}).has("campamento@0,0")
		bandera(nombre + ".listo")
		resultado.expansion = await esperar(func(): return c.j.d.mundo.registro.macros.has("1,0"))
		await create_timer(0.3).timeout
		resultado.registro = S.Huella.hash_de(c.j.d.mundo.registro)
		var camp: Dictionary = c.j.d.mundo.registro.lugares["campamento@0,0"]
		var cc := Vector2i(camp.centro[0] + 2, camp.centro[1] - 1)
		var cid := "c@" + J.Mundo.clave(cc)
		c.j.interactuar()
		resultado.inspeccion = await esperar(func(): return inspeccion.ok)
		if nombre == "A":
			c.j.mover_cofre(cid, "madera", true)
			resultado.deposito = await esperar(func(): return int(c.j.d.cofres[cid].inv.get("madera", 0)) == 3)
			bandera("deposito")
			resultado.sin_duplicar = int(c.j.jug().inv.get("madera", 0)) == 0
		else:
			resultado.vio_deposito = await esperar(func(): return FileAccess.file_exists(carpeta + "/deposito") and int(c.j.d.cofres[cid].inv.get("madera", 0)) == 3)
			c.j.mover_cofre(cid, "madera", false)
			resultado.retiro = await esperar(func(): return int(c.j.jug().inv.get("madera", 0)) == 3)
	FileAccess.open(carpeta + "/" + nombre + ".json", FileAccess.WRITE).store_string(JSON.stringify(resultado))
	c.cerrar()
	quit()
func servidor() -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	var j = J.nueva(123, "Anfitrión", [0, 0, 0], "poblado")
	j.combate.enemigos.clear()
	var inicial: Dictionary = j.d.mundo.registro.lugares.duplicate(true)
	var s = S.new()
	s.name = "Red"
	s.j = j
	s.local = J.LOCAL
	s.puerto = 30000 + OS.get_process_id() % 1000
	root.add_child(s)
	var pids: Array = []
	for n in ["A", "B"]:
		pids.append(OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", carpeta + "/" + n + ".log", "--script", "res://tests/prueba_lugares_red.gd", "--", "bot", n, str(s.puerto), carpeta]))
	var listo := await esperar(func(): return FileAccess.file_exists(carpeta + "/A.listo") and FileAccess.file_exists(carpeta + "/B.listo"))
	ok(listo, "dos clientes recibieron el registro inicial")
	var camp: Dictionary = j.d.mundo.registro.lugares["campamento@0,0"]
	var cc := Vector2i(camp.centro[0] + 2, camp.centro[1] - 1)
	var cid := "c@" + J.Mundo.clave(cc)
	for id in j.rt:
		if id == J.LOCAL: continue
		j.rt[id].pies = J.Mundo.pies_de_celda(cc + Vector2i.DOWN)
		j.jug(id).inv = {"madera": 3} if j.jug(id).nombre == "VisitanteA" else {}
	j.Lugares.ampliar(j, Vector2i(1, 0))
	ok(inicial.keys().all(func(k): return j.d.mundo.registro.lugares[k] == inicial[k]), "ampliar no altera lugares preexistentes")
	await esperar(func(): return FileAccess.file_exists(carpeta + "/A.json") and FileAccess.file_exists(carpeta + "/B.json"), 240)
	var resultados := {}
	for n in ["A", "B"]:
		var r = JSON.parse_string(FileAccess.get_file_as_string(carpeta + "/" + n + ".json"))
		ok(r is Dictionary, "cliente " + n + " terminó")
		if r is Dictionary:
			resultados[n] = r
			for k in r:
				if k != "registro": ok(bool(r[k]), n + ": " + k)
	ok(resultados.size() == 2 and resultados.A.get("registro", "A") == resultados.B.get("registro", "B") and resultados.A.get("registro", "") == S.Huella.hash_de(j.d.mundo.registro), "servidor y dos réplicas comparten el registro ampliado exacto")
	ok(j.d.cofres[cid].inv.is_empty(), "transferencia compartida sin duplicar en autoridad")
	j.guardar(carpeta + "/mundo.json")
	var cargado = J.cargar(carpeta + "/mundo.json")
	ok(cargado != null and S.Huella.hash_de(cargado.d.mundo.registro) == S.Huella.hash_de(j.d.mundo.registro), "reiniciar conserva la expansión de red")
	for pid in pids:
		if OS.is_process_running(pid): OS.kill(pid)
	s.queue_free()
	await process_frame
	quit(1 if fallos else 0)
