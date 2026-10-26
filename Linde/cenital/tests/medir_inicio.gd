extends SceneTree
## Línea base de la aparición del jugador (insumo de la Fase 1c de Mundo 1).
## Uso:  Godot --headless --path Linde/cenital -s res://tests/medir_inicio.gd -- semillas=200 visibilidad=20
## Mide, para las semillas 1..N: distancias (en celdas) desde `Mundo.punto_inicio` a hitos del Valle y, en las primeras
## `visibilidad` semillas, si algún habitante cae dentro del encuadre de la cámara al comenzar.
## Determinista: mismas semillas → mismos valores (el hash de las posiciones lo comprueba).
## Limitaciones: encuadre calculado con la ventana 1280×720 y zoom 3 (≈26,7×15 celdas); no simula red ni varios jugadores
## (hoy todos los jugadores aparecen en la misma celda); la visibilidad ignora oclusión por la casa.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const P = preload("res://scripts/params.gd")
const Com = preload("res://tests/medir_comun.gd")

func _init() -> void:
	var a := Com.args({"semillas": "200", "visibilidad": "20"})
	var n := int(a.semillas)
	var nvis := int(a.visibilidad)
	var m = M.new()
	var d_puerta: Array = []
	var d_cama: Array = []
	var d_salida: Array = []
	var d_guardian: Array = []
	var d_slime: Array = []
	var d_agua: Array = []
	var posiciones: Array = []
	var distintas := {}
	var t0 := Time.get_ticks_usec()
	for s in range(1, n + 1):
		var c: Vector2i = m.punto_inicio(s)
		posiciones.append([c.x, c.y])
		distintas[c] = true
		d_puerta.append(Vector2(c).distance_to(Vector2(M.PUERTA_C)))
		d_cama.append(Vector2(c).distance_to(Vector2(M.CAMA_MAREN)))
		d_salida.append(Vector2(c).distance_to(Vector2(M.ENTRADA)))
		d_guardian.append(Vector2(c).distance_to(Vector2(M.SPAWN_GUARDIAN)))
		var ms := 1e9
		for q in m.spawns_slime: ms = minf(ms, Vector2(c).distance_to(Vector2(q)))
		d_slime.append(ms)
		var ma := 1e9
		for y in range(28, 35):
			for x in range(44, 50): ma = minf(ma, Vector2(c).distance_to(Vector2(x, y)))
		d_agua.append(ma)
	var us := float(Time.get_ticks_usec() - t0) / n
	var ancho := 1280.0 / P.ZOOM / P.CELDA
	var alto := 720.0 / P.ZOOM / P.CELDA
	Com.linea("MEDIDA_CONFIG", {"herramienta": "medir_inicio", "semillas": n, "visibilidad_semillas": nvis, "encuadre_celdas": "%.1fx%.1f" % [ancho, alto],
		"celdas_alcanzables": m.alcanzables().size(), "godot": Engine.get_version_info().string})
	Com.linea("MEDIDA_ESTADO", {"posiciones_distintas": distintas.size(), "hash_posiciones": Com.hash_de(posiciones)})
	for par in [["puerta_casa", d_puerta], ["cama_maren", d_cama], ["salida_sur", d_salida], ["guardian", d_guardian], ["slime_mas_cercano", d_slime], ["estanque", d_agua]]:
		var p: Dictionary = Com.percentiles(par[1])
		Com.linea("MEDIDA_ESTADO", {"distancia_celdas": par[0], "min": snappedf(p.min, 0.1), "p10": snappedf(p.p10, 0.1), "p50": snappedf(p.p50, 0.1), "p90": snappedf(p.p90, 0.1), "max": snappedf(p.max, 0.1)})
	var con_habitante := 0
	var dist_hab: Array = []
	var t1 := Time.get_ticks_usec()
	for s in range(1, nvis + 1):
		var j = J.nueva(s, "Medidor", [0, 0, 0])
		var pj: Vector2 = j.pies_de()
		var mas_cerca := 1e9
		var visible := false
		for nid in j.habitantes.ids:
			var h: Vector2 = j.habitantes.pos(nid)
			mas_cerca = minf(mas_cerca, pj.distance_to(h) / P.CELDA)
			if absf(h.x - pj.x) / P.CELDA <= ancho / 2.0 and absf(h.y - pj.y) / P.CELDA <= alto / 2.0: visible = true
		dist_hab.append(mas_cerca)
		if visible: con_habitante += 1
	if nvis > 0:
		var pd: Dictionary = Com.percentiles(dist_hab)
		Com.linea("MEDIDA_ESTADO", {"visibilidad": "habitante_en_encuadre", "semillas": nvis, "con_habitante_visible": con_habitante,
			"distancia_habitante_p50": snappedf(pd.p50, 0.1), "distancia_habitante_max": snappedf(pd.max, 0.1)})
	Com.linea("MEDIDA_CPU", {"punto_inicio_us_por_semilla": snappedf(us, 1), "nueva_ms_por_semilla": snappedf((Time.get_ticks_usec() - t1) / 1000.0 / maxi(1, nvis), 0.1)})
	quit(0)
