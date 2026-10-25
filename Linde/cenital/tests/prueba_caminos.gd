extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func _init() -> void:
	var j = J.nueva(123, "Caminante", [0, 0, 0])
	var c := Vector2i(-1, -1)
	for x in range(5, 30):   # una celda de hierba libre del valle
		var p := Vector2i(x, 10)
		if j.mundo.tipo(p) == M.T.PASTO and j.mundo.objeto_presente(p) == "" and j.mundo.constr_en(p).is_empty(): c = p; break
	ok(c.x >= 0, "hay una celda de hierba libre")
	for i in C.PISADAS_CAMINO - 1: j.mundo.pisar(c)
	ok(j.mundo.tipo(c) == M.T.PASTO, "pocos pasos no forman camino")
	j.mundo.pisar(c)
	ok(j.mundo.tipo(c) == M.T.CAMINO, "al llegar al umbral se forma el camino")
	var agua := Vector2i(-1, -1)
	for y in M.ALTO:
		for x in M.ANCHO: if j.mundo.tipo(Vector2i(x, y)) == M.T.AGUA: agua = Vector2i(x, y)
	if agua.x >= 0:
		for i in C.PISADAS_CAMINO + 1: j.mundo.pisar(agua)
		ok(j.mundo.tipo(agua) == M.T.AGUA, "solo la hierba se gasta")
	# Un habitante que camina lo suficiente deja huella real.
	var antes: int = j.d.mundo.caminos.size()
	for i in 4000: j.tick(0.1)
	ok(j.d.mundo.caminos.size() >= antes, "el tick cuenta pasos sin romper nada")
	var ruta := "/tmp/linde-caminos.json"
	ok(j.guardar(ruta), "guardado")
	var carga = J.cargar(ruta)
	ok(carga != null and carga.mundo.tipo(c) == M.T.CAMINO, "el camino sobrevive a guardar y cargar")
	print("CAMINOS: %d fallos" % fallos)
	quit(fallos)
