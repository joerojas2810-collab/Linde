extends SceneTree
## Dos réplicas ENet reales: referencias, pistas y aislamiento del estado personal.
const J = preload("res://scripts/juego.gd")
const S = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var carpeta := "/tmp/linde-orientacion-red"
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0 and a[0] == "bot": bot(a[1], int(a[2])); return
	servidor()
func bot(nombre: String, puerto: int) -> void:
	var c = Cli.new()
	c.name = "Red"
	c.nombre = "Cliente" + nombre
	c.clave = "orientacion-" + nombre
	c.puerto = puerto
	root.add_child(c)
	var resultado := {"conecto": false, "rumor": false, "silencio": false, "pista": false, "privado": false}
	for i in 100:
		await create_timer(0.05).timeout
		if c.j != null: break
	if c.j != null:
		resultado.conecto = true
		await create_timer(0.5).timeout
		c.j.preguntar_lugares("maren")
		c.j.gestionar_pista("silenciar")
		await create_timer(0.5).timeout
		resultado.silencio = c.j.jug().get("pistas", {}).get("silenciadas", false)
		resultado.rumor = c.j.jug().get("mapa", {}).get("bloques", {}).get("200,200", "") == "npc:maren"
		var ajeno := "600,600" if nombre == "B" else "700,700"
		resultado.privado = not c.j.jug().get("mapa", {}).get("bloques", {}).has(ajeno) and c.j.d.jugadores.size() == 1
		c.j.gestionar_pista("activar")
		c.j.gestionar_pista("pedir")
		await create_timer(0.5).timeout
		resultado.pista = not c.j.pista_contextual().is_empty()
		c.j.gestionar_pista("descartar")
		await create_timer(0.2).timeout
		resultado["descarte"] = c.j.pista_contextual().is_empty() and not c.j.jug().pistas.descartadas.is_empty()
	FileAccess.open(carpeta + "/" + nombre + ".json", FileAccess.WRITE).store_string(JSON.stringify(resultado))
	c.cerrar()
	quit()
func servidor() -> void:
	DirAccess.make_dir_recursive_absolute(carpeta)
	for n in ["A", "B"]: DirAccess.remove_absolute(carpeta + "/" + n + ".json")
	var j = J.nueva(123, "Anfitrión", [0, 0, 0], "poblado")
	j.combate.enemigos.clear()
	var s = S.new()
	s.name = "Red"
	s.j = j
	s.local = J.LOCAL
	s.puerto = 29000 + OS.get_process_id() % 1000
	root.add_child(s)
	var pids: Array = []
	for n in ["A", "B"]:
		pids.append(OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", carpeta + "/" + n + ".log", "--script", "res://tests/prueba_orientacion_red.gd", "--", "bot", n, str(s.puerto)]))
	var preparados := {}
	for i in 200:
		for id in j.rt:
			if id == J.LOCAL: continue
			# Fixture cercano, sin depender del azar de aparición o de rutinas durante la conexión.
			j.rt[id].pies = j.habitantes.pos("maren") + Vector2(0, 12)
			if not preparados.has(id):
				j.jug(id).get_or_add("mapa", {"bloques": {}}).bloques["600,600" if j.jug(id).nombre == "ClienteA" else "700,700"] = "npc:prueba"
				j.autonomia.estado("maren").get_or_add("bloques", {})["200,200"] = true
				preparados[id] = true
		await create_timer(0.05).timeout
		if FileAccess.file_exists(carpeta + "/A.json") and FileAccess.file_exists(carpeta + "/B.json"): break
	for n in ["A", "B"]:
		var r = JSON.parse_string(FileAccess.get_file_as_string(carpeta + "/" + n + ".json"))
		ok(r is Dictionary, "cliente " + n + " terminó")
		if r is Dictionary:
			for k in r: ok(bool(r[k]), n + ": " + k)
	for pid in pids:
		if OS.is_process_running(pid): OS.kill(pid)
	s.queue_free()
	await process_frame
	quit(1 if fallos else 0)
