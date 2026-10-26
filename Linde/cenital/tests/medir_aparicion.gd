extends SceneTree
## Seguridad POSTERIOR a la aparición (Mundo 1, paso 1c): qué ocurre en los primeros segundos con los enemigos reales.
## Uso:  Godot --headless --path Linde/cenital -s res://tests/medir_aparicion.gd -- semillas=200 segundos=30 [modo=poblado|legado]
## Para cada semilla, el jugador aparece según `modo` (poblado: Juego.punto_aparicion; legado: punto_inicio) con el combate REAL activo y
## se simulan `segundos` de juego (ticks de 0,1 s) en tres comportamientos:
##   pasivo      no actúa (peor caso de «no reaccionar»);
##   imprudente  camina hacia el enemigo vivo más cercano sin mirar el peligro, hasta recibir daño;
##   reactivo    igual, pero al ser detectado (un enemigo pasa a persigue/aviso contra él) huye alejándose de quien lo persigue y se detiene cuando lo pierden.
## Una caída (`_derrota`) se cuenta como muerte y daño = vida inicial. Mide: distancia inicial al enemigo más cercano, instante de la primera detección, ventana entre detección y primer daño, daño total, muertes.
## Limitaciones: el reactivo es un modelo simple (huida directa por ejes), no una persona; slimes y jefes del Valle, sin fauna exterior;
## los habitantes siguen su autonomía; el modo legado coloca al jugador sin reglas de seguridad y sirve de comparación.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const Comb = preload("res://scripts/combate.gd")
const Com = preload("res://tests/medir_comun.gd")
const DT := 0.1

func _init() -> void:
	var a := Com.args({"semillas": "200", "segundos": "30", "modo": "poblado", "detalle": "no"})
	var n := int(a.semillas)
	var seg := float(a.segundos)
	Com.linea("MEDIDA_CONFIG", {"herramienta": "medir_aparicion", "semillas": n, "segundos": seg, "modo": a.modo, "tick_s": DT, "godot": Engine.get_version_info().string})
	var t0 := Time.get_ticks_usec()
	for esc in ["pasivo", "imprudente", "reactivo"]:
		var r := {"sin_aparicion": 0, "con_deteccion": 0, "con_dano": 0, "muertes": 0}
		var dist0: Array = []
		var t_det: Array = []
		var ventana: Array = []
		var dano: Array = []
		var min_dist: Array = []
		for s in range(1, n + 1):
			var j = J.nueva(s, "Medidor", [0, 0, 0])
			if a.modo == "poblado":
				var ap: Dictionary = j.punto_aparicion(J.LOCAL)
				if not ap.ok:
					r.sin_aparicion += 1
					continue
				j.rt[J.LOCAL].pies = M.pies_de_celda(ap.celda)
			var celda0: Vector2i = M.celda_de(j.pies_de())
			var res: Dictionary = _correr(j, esc, seg)
			if a.detalle == "si" and res.dano > 0: Com.linea("MEDIDA_DETALLE", {"escenario": esc, "semilla": s, "celda_inicial": "%d,%d" % [celda0.x, celda0.y], "t_muerte_o_dano_s": res.t_fin, "celda_final": "%d,%d" % [res.fin.x, res.fin.y], "perseguidores": res.perseg, "muerto": res.muerto})
			dist0.append(res.dist0)
			min_dist.append(res.min_dist)
			dano.append(res.dano)
			if res.t_det >= 0.0:
				r.con_deteccion += 1
				t_det.append(res.t_det)
			if res.dano > 0: r.con_dano += 1
			if res.muerto: r.muertes += 1
			if res.ventana >= 0.0: ventana.append(res.ventana)
		var kv := {"escenario": esc, "modo": a.modo}
		kv.merge(r)
		var pd := Com.percentiles(dist0) if not dist0.is_empty() else {}
		if not pd.is_empty(): kv.merge({"dist_inicial_min_celdas": snappedf(pd.min, 0.1), "dist_inicial_p50": snappedf(pd.p50, 0.1)})
		if not t_det.is_empty():
			var pt := Com.percentiles(t_det)
			kv.merge({"t_deteccion_min_s": snappedf(pt.min, 0.1), "t_deteccion_p50_s": snappedf(pt.p50, 0.1)})
		if not ventana.is_empty():
			var pv := Com.percentiles(ventana)
			kv.merge({"ventana_deteccion_a_dano_min_s": snappedf(pv.min, 0.1), "ventana_p50_s": snappedf(pv.p50, 0.1)})
		var pda := Com.percentiles(dano) if not dano.is_empty() else {}
		if not pda.is_empty(): kv.merge({"dano_p50": pda.p50, "dano_max": pda.max})
		Com.linea("MEDIDA_ESTADO", kv)
	Com.linea("MEDIDA_CPU", {"script_s": snappedf((Time.get_ticks_usec() - t0) / 1e6, 0.1)})
	quit(0)

func _enemigo_cercano(j) -> Dictionary:
	var mejor := {}
	var md := INF
	var cp: Vector2 = j.combate.centro_pj()
	for e in j.combate.enemigos:
		if e.est == "muerto": continue
		var d: float = Comb.centro(e).distance_to(cp)
		if d < md:
			md = d
			mejor = e
	return mejor

## Primer paso de la ruta hacia la celda más lejana del perseguidor entre las alcanzables en un cuadrado de 25×25 celdas (modelo de una
## persona que sabe huir; no es un jugador real).
func _dir_huida(j, perseguidor: Dictionary) -> Vector2i:
	var c: Vector2i = M.celda_de(j.pies_de())
	var area := Rect2i(c - Vector2i(12, 12), Vector2i(25, 25))
	var alc: Dictionary = j.mundo.alcanzables(c, area)
	var cp := Vector2(M.celda_de(Comb.centro(perseguidor)))
	var mejor := c
	var md := -1.0
	for k in alc:
		var d := Vector2(k).distance_to(cp)
		if d > md or (d == md and (k.y < mejor.y or (k.y == mejor.y and k.x < mejor.x))):
			md = d
			mejor = k
	if mejor == c: return Vector2i.ZERO
	var ruta: Array = j.mundo.camino(c, func(x): return x == mejor, area)
	if ruta.size() < 2: return Vector2i.ZERO
	return ruta[1] - ruta[0]

func _dir_hacia(desde: Vector2, hasta: Vector2, invertir: bool) -> Vector2i:
	var d := hasta - desde
	if invertir: d = -d
	if absf(d.x) >= absf(d.y): return Vector2i(int(signf(d.x)), 0)
	return Vector2i(0, int(signf(d.y)))

func _correr(j, esc: String, seg: float) -> Dictionary:
	var res := {"dist0": 0.0, "min_dist": INF, "t_det": -1.0, "ventana": -1.0, "dano": 0, "muerto": false, "t_fin": 0.0, "fin": Vector2i.ZERO, "perseg": 0}
	var hp0: int = j.jug().hp
	var e0: Dictionary = _enemigo_cercano(j)
	if not e0.is_empty(): res.dist0 = Comb.centro(e0).distance_to(j.combate.centro_pj()) / 16.0
	var t := 0.0
	var huyendo := false
	var hp_ant: int = hp0
	while t < seg:
		var e: Dictionary = _enemigo_cercano(j)
		if not e.is_empty():
			res.min_dist = minf(res.min_dist, Comb.centro(e).distance_to(j.combate.centro_pj()) / 16.0)
		var detectado := false
		var np := 0
		for x in j.combate.enemigos:
			if x.est in ["persigue", "aviso"] and str(x.obj) == J.LOCAL:
				detectado = true
				np += 1
		res.perseg = maxi(res.perseg, np)
		res.t_fin = t
		res.fin = M.celda_de(j.pies_de())
		if detectado and res.t_det < 0.0: res.t_det = t
		var dir := Vector2i.ZERO
		if esc != "pasivo" and not e.is_empty():
			if esc == "reactivo" and (detectado or huyendo):
				huyendo = true
				if detectado:   # huye solo mientras algo lo persigue; cuando lo pierden, se queda quieto
					var perseguidor: Dictionary = {}
					var dm := INF
					for x in j.combate.enemigos:
						if x.est in ["persigue", "aviso"] and str(x.obj) == J.LOCAL and Comb.centro(x).distance_to(j.combate.centro_pj()) < dm:
							dm = Comb.centro(x).distance_to(j.combate.centro_pj())
							perseguidor = x
					dir = _dir_huida(j, perseguidor)   # ruta hacia la celda alcanzable más lejana de quien lo persigue
			elif res.dano == 0 and not huyendo:
				dir = _dir_hacia(j.combate.centro_pj(), Comb.centro(e), false)
		if dir != Vector2i.ZERO: j.mover_pj(dir, DT)
		j.tick(DT)
		t += DT
		var hp: int = j.jug().hp
		if hp > hp_ant:   # `_derrota` devuelve la mitad de la vida: el jugador cayó
			res.muerto = true
			res.dano = hp0
			break
		if hp < hp0 and res.dano == 0 and res.t_det >= 0.0: res.ventana = t - res.t_det
		if hp < hp0: res.dano = hp0 - hp
		hp_ant = hp
	return res
