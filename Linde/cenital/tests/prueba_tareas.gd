extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var fallos := 0
var total := 0
func ok(v: bool, texto: String) -> void:
	total += 1
	if not v: fallos += 1
	print(("PASS " if v else "FAIL ") + texto)
func _init() -> void:
	var j = J.nueva(123, "F6", [0,0,0])
	var a = j.autonomia
	var t = a.tareas
	var meta := {"item":"lingote", "cantidad":1, "motivo":"mantener mi oficio"}
	t.iniciar("ordal", meta)
	var id: int = t.datos().activos.ordal.id
	t.iniciar("ordal", meta)
	ok(t.datos().activos.ordal.id == id, "demanda equivalente conserva identidad y reclamo único del actor")
	t.iniciar("maren", meta)
	ok(t.reclamar("ordal", "prueba") and not t.reclamar("maren", "prueba"), "dos tareas no reclaman el mismo recurso")
	t.cancelar("ordal", "descanso")
	ok(t.reclamar("maren", "prueba"), "interrupción libera recurso")
	t.cancelar("maren", "fin_prueba")
	var n: Dictionary = a.estado("ordal")
	n.inv = {"mena":2, "madera":1, "baya":8}
	var horno := Vector2i(28,20)
	j.d.mundo.constr[M.clave(horno)] = {"t":"horno", "dueno":"local"}
	var p := M.pies_de_celda(horno + Vector2i.DOWN)
	j.d.npcs.ordal.pos = [p.x,p.y]
	ok(a.sociedad._obtener("ordal", "lingote", 1, [], "mantener mi oficio"), "tarea usa fabricación existente")
	ok(n.inv.get("lingote",0) == 1 and not n.inv.has("mena") and not n.inv.has("madera"), "resultado consume insumos reales")
	var material := false
	for r in t.datos().resultados:
		if r.actor == "ordal" and r.causa == "efecto_material" and r.delta.get("lingote",0) == 1 and r.delta.get("mena",0) == -2: material = true
	ok(material and not t.datos().activos.has("ordal"), "resultado causal y cierre de tarea satisfecho")
	t.iniciar("ordal", meta)
	t.reclamar("ordal", "prueba")
	t.resultado("ordal", n.inv.duplicate(), false)
	ok(t.datos().activos.ordal.estado == "bloqueada" and t.disponible("maren","prueba"), "fallo sin efecto libera reclamo y conserva causa")
	var cantidad: int = t.datos().resultados.size()
	t.resultado("ordal", n.inv.duplicate(), false)
	ok(t.datos().resultados.size() == cantidad, "fallo idéntico no llena historial")
	# Sin fuentes locales ni proveedores: el ejecutor real debe registrar el bloqueo.
	a.reglas.expediciones = false
	for oid in j.mundo.objetos: j.mundo.romper(oid, j.d.min)
	for actor in j.habitantes.ids:
		if not a.perfil(actor).is_empty(): a.estado(actor).inv = {}
	for g in a.sociedad.datos().grupos.values(): g.inv = {}
	ok(not a.sociedad._obtener("ordal", "gelatina", 1, [], "alimentar prueba"), "ejecutor sin fuentes no inventa una solución")
	ok(t.datos().activos.ordal.estado == "bloqueada" and n.inv.is_empty(), "bloqueo real conserva demanda sin crear bienes")
	# El descanso usa la cancelación desde el bucle autoritativo real.
	j.d.min = 25 * 60
	a.paso()
	ok(not t.datos().activos.has("ordal"), "descanso del NPC interrumpe su tarea desde paso")
	t.iniciar("ordal", meta)
	var ruta := "/tmp/linde-f6-tareas-%d.json" % OS.get_process_id()
	ok(j.guardar(ruta), "guardado real")
	var cargado = J.cargar(ruta)
	ok(cargado != null and JSON.stringify(cargado.autonomia.tareas.datos()) == JSON.stringify(t.datos()), "carga conserva IDs, demandas, tareas y resultados")
	if cargado != null:
		var antes := JSON.stringify(cargado.d.mundo_vivo.autonomia)
		cargado.autonomia.paso()
		ok(antes == JSON.stringify(cargado.d.mundo_vivo.autonomia), "mismo minuto no repite resultado")
	var srv = Srv.new()
	srv.j = j
	var cli = Cli.new()
	cli._bienvenida(srv.estado_para(J.LOCAL))
	ok(JSON.stringify(cli.j.autonomia.tareas.datos()) == JSON.stringify(t.datos()), "bienvenida replica contrato persistente")
	var replica := JSON.stringify(cli.j.d)
	cli.j.autonomia.paso()
	cli.j.autonomia.tareas.cancelar("ordal","cliente")
	ok(JSON.stringify(cli.j.d) == replica, "cliente no ejecuta ni cancela trabajo")
	cli.free()
	srv.free()
	print("TAREAS: %d comprobaciones, %d fallos" % [total,fallos])
	quit(1 if fallos else 0)
