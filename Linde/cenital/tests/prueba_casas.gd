extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func _libre(j, ancho: int, alto: int) -> Vector2i:
	for y in range(6, 40):
		for x in range(6, 56):
			var bien := true
			for dy in alto:
				for dx in ancho:
					var p := Vector2i(x + dx, y + dy)
					if j.mundo.puede_poner(p) != "" or M.ESENCIALES.has(p): bien = false
			if bien: return Vector2i(x, y)
	return Vector2i(-1, -1)
func _init() -> void:
	var j = J.nueva(123, "Constructor", [0, 0, 0])
	var o := _libre(j, 5, 5)
	ok(o.x >= 0, "hay sitio para una casa")
	var cama := o + Vector2i(1, 1)
	j.jug().inv = {"madera": 30, "fibra": 10}
	ok(j.construir("puerta", cama + Vector2i(0, 2)).ok and not j.mundo.bloquea(cama + Vector2i(0, 2)), "la puerta se construye y no bloquea")
	ok(j.construir("cama_huesped", cama).ok, "la cama")
	ok(j.construir("techo", cama).ok and j.mundo.estado.techos.has(M.clave(cama)), "el techo cubre una celda que ya tiene una pieza")
	ok(not j.construir("techo", cama).ok, "no se techa dos veces")
	var antes: int = j.jug().inv.get("madera", 0)
	ok(j.retirar(cama).ok and j.jug().inv.get("madera", 0) > antes - 99 and j.mundo.estado.techos.has(M.clave(cama)), "retirar la cama deja el techo")
	ok(j.retirar(cama).ok and not j.mundo.estado.techos.has(M.clave(cama)), "retirar de nuevo quita el techo")
	# Casa completa según el plano.
	var h = J.nueva(123, "Observador", [0, 0, 0])
	h.autonomia.activar()
	var so = h.autonomia.sociedad
	var b := _libre(h, 5, 5) + Vector2i(1, 1)
	h.mundo.poner(b, "cama_huesped", false, "grupo:talleres")
	ok(not so.casa_completa(b), "una cama sola no es una casa")
	for d in so.cfg.vivienda.casa.base: h.mundo.poner(b + Vector2i(int(d[0]), int(d[1])), "muro_ladrillo", false)
	for paso in so._celdas_casa(b):
		if paso[0] == "techo": h.mundo.techar(paso[1], "grupo:talleres")
		else: h.mundo.poner(paso[1], paso[0], false)
	ok(so.casa_completa(b), "con muros, sala, puerta, mesa y techo está completa")
	h.mundo.destechar(b)
	ok(not so.casa_completa(b), "sin techo deja de estar completa")
	var ruta := "/tmp/linde-casas-%d.json" % OS.get_process_id()
	h.mundo.techar(b, "grupo:talleres")
	h.guardar(ruta)
	var carga = J.cargar(ruta)
	ok(carga != null and carga.autonomia.sociedad.casa_completa(b), "la casa completa sobrevive a guardar y cargar")
	# Un albañil con materiales levanta la casa entera por su cuenta.
	var g = J.nueva(123, "Obra", [0, 0, 0])
	g.autonomia.activar()
	var gs = g.autonomia.sociedad
	var sitio := _libre(g, 5, 5)
	var lecho := sitio + Vector2i(1, 1)
	g.mundo.poner(lecho, "cama_huesped", false, "grupo:talleres")
	var obrero := "maren"   # el oficio de albañil se le da por receta, como a los colonos que llegan
	g.autonomia.perfil(obrero).recetas.append("ladrillo")
	var e = g.autonomia.estado(obrero)
	e.inv = {"ladrillo": 40, "madera": 40, "fibra": 20, "piedra": 10, "baya": 6, "pico_piedra": 1, "hacha_piedra": 1}
	var p0 := M.pies_de_celda(lecho + Vector2i(0, 3))
	g.d.npcs[obrero].pos = [p0.x, p0.y]
	gs.datos().refugios = {M.clave(lecho): true}   # el refugio de tres muros ya está hecho: aquí se prueba la casa
	for d in gs.cfg.vivienda.casa.base: g.mundo.poner(lecho + Vector2i(int(d[0]), int(d[1])), "muro_ladrillo", false)
	var hecho := false
	for i in 12000:
		g.tick(0.1)
		if gs.casa_completa(lecho): hecho = true; break
	if not hecho:
		for paso in gs._celdas_casa(lecho): print("  ", paso, gs._pieza_puesta(paso[0], paso[1]), g.mundo.puede_poner(paso[1]) if paso[0] != "techo" else g.mundo.puede_techar(paso[1]))
		print("  plan ", e.plan, " objetivo ", e.get("objetivo", ""), " inv ", e.inv, " casas ", gs.datos().get("casas", {}))
	ok(hecho, "el albañil completa la casa (muros, sala, puerta, mesa y techo)")
	ok(g.d.mundo.techos.size() == 3 and g.mundo.constr_en(lecho + Vector2i(0, 2)).get("t", "") == "puerta", "con tres techos y la puerta al sur")
	print("CASAS: %d fallos" % fallos)
	quit(fallos)
