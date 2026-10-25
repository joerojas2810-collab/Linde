extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func _init() -> void:
	var j = J.nueva(123, "Labrador", [0, 0, 0])
	var c := Vector2i(-1, -1)
	for x in range(5, 30):
		var p := Vector2i(x, 10)
		if j.mundo.puede_poner(p) == "": c = p; break
	j.jug().inv = {"fibra": 2, "baya": 2}
	ok(j.construir("campo", c).ok and j.jug().inv.is_empty(), "construir un campo cuesta fibra y bayas")
	ok(not j.campo_listo(c), "recién sembrado no está listo")
	j.pies = M.pies_de_celda(c + Vector2i.DOWN); j.rt[J.LOCAL].mira = Vector2i.UP
	ok(not j.interactuar().ok, "no se cosecha antes de tiempo")
	j.d.min += C.CAMPO_CRECE_MIN
	ok(j.campo_listo(c), "pasado el tiempo está listo")
	var r = j.interactuar()
	ok(r.ok and j.jug().inv.get("baya", 0) == 3 and j.jug().inv.get("fibra", 0) == 1, "la cosecha entrega bayas y fibra")
	ok(not j.campo_listo(c), "tras cosechar vuelve a crecer")
	var ruta := "/tmp/linde-campos-%d.json" % OS.get_process_id()
	j.guardar(ruta)
	var carga = J.cargar(ruta)
	ok(carga != null and not carga.campo_listo(c), "el estado del cultivo se guarda")
	# Un habitante del grupo cosecha un campo maduro.
	var h = J.nueva(123, "Observador", [0, 0, 0])
	h.autonomia.activar()
	var d: Vector2i = h.autonomia.sociedad._ancla("talleres")
	var campo := Vector2i(-1, -1)
	for r2 in range(1, 5):
		for dx in range(-r2, r2 + 1):
			if campo.x < 0 and h.mundo.puede_poner(d + Vector2i(dx, r2)) == "" and not h.ocupada(d + Vector2i(dx, r2)): campo = d + Vector2i(dx, r2)
	h.mundo.poner(campo, "campo", false, "grupo:talleres")
	h.d.mundo.constr[M.clave(campo)]["listo"] = 0
	var cosecho := false
	for i in 9000:
		h.tick(0.1)
		if not h.campo_listo(campo): cosecho = true; break
	ok(cosecho, "un habitante cosecha el campo maduro de su grupo")
	print("CULTIVO: %d fallos" % fallos)
	quit(fallos)
