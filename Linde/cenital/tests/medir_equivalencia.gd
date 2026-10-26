extends SceneTree
## Línea base de comportamiento de Mundo Vivo: hash del estado completo y resultados de NPC al final de cada día de juego.
## Sirve para demostrar que un cambio no altera decisiones ni resultados (hashes idénticos) o para ver qué cambió.
## Uso:  Godot --headless --path Linde/cenital -s res://tests/medir_equivalencia.gd -- semilla=123 dias=4 [ignorar=mundo.poblados,otra.ruta]
## `modo=poblado` crea el mundo en modo poblado (Mundo 1: aparición, instalaciones, slimes); por defecto `legado`, que es la línea base.
## `ignorar` excluye claves del hash (para cambios que solo añaden datos nuevos); vacío por defecto = hash del estado completo.
## Predeterminado: semilla 123, 4 días (11.520 ticks de 0,5 s; el combate se desactiva para aislar la economía y la autonomía).
## Los tiempos de CPU salen en líneas MEDIDA_CPU, separadas de las comprobaciones deterministas (MEDIDA_ESTADO).
## Limitaciones: sin jugadores activos; combate desactivado; el número de habitantes crece solo con el tiempo (≈1 por día);
## no cubre multijugador ni guardado/carga (solo el estado en memoria).
const J = preload("res://scripts/juego.gd")
const Com = preload("res://tests/medir_comun.gd")

func _init() -> void:
	var a := Com.args({"semilla": "123", "dias": "4", "ignorar": "", "modo": "legado"})
	var ignorar: Array = [] if str(a.ignorar) == "" else str(a.ignorar).split(",")
	var semilla := int(a.semilla)
	var dias := int(a.dias)
	var j = J.nueva(semilla, "Observador", [0, 0, 0], a.modo)
	j.combate.enemigos.clear()
	Com.linea("MEDIDA_CONFIG", {"herramienta": "medir_equivalencia", "semilla": semilla, "dias": dias, "tick_s": 0.5, "ticks_por_dia": 2880,
		"combate": "desactivado", "jugadores_activos": 1, "ignorar": ",".join(ignorar), "godot": Engine.get_version_info().string})
	var dur: Array = []
	var dia_dur: Array = []
	for i in dias * 2880:
		var t0 := Time.get_ticks_usec()
		j.tick(0.5)
		var d := Time.get_ticks_usec() - t0
		dur.append(d)
		dia_dur.append(d)
		if i % 2880 == 2879:
			var r: Dictionary = Com.resumen_npc(j)
			var kv := {"semilla": semilla, "dia": i / 2880 + 1, "hash_estado": Com.hash_estado(j, ignorar)}
			kv.merge(r)
			Com.linea("MEDIDA_ESTADO", kv)
			var s := 0
			var m := 0
			for x in dia_dur:
				s += x
				m = maxi(m, x)
			Com.linea("MEDIDA_CPU", {"semilla": semilla, "dia": i / 2880 + 1, "tick_medio_us": snappedf(float(s) / dia_dur.size(), 1), "tick_max_us": m})
			dia_dur = []
	var orden := dur.duplicate()
	orden.sort()
	var tot := 0
	var l100 := 0
	for x in dur:
		tot += x
		if x > 100000: l100 += 1
	Com.linea("MEDIDA_ESTADO", {"semilla": semilla, "final": true, "dias": dias, "hash_estado": Com.hash_estado(j, ignorar), "habitantes": j.habitantes.ids.size()})
	Com.linea("MEDIDA_CPU", {"semilla": semilla, "final": true, "tick_total_ms": snappedf(tot / 1000.0, 0.1), "tick_medio_us": snappedf(float(tot) / dur.size(), 1),
		"p50_us": orden[orden.size() / 2], "p95_us": orden[int(orden.size() * 0.95)], "p99_us": orden[int(orden.size() * 0.99)], "max_us": orden[-1], "ticks_mayores_100ms": l100})
	quit(0)
