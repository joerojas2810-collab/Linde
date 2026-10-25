extends SceneTree
## Línea base de I1a (no es suite): bytes de guardado y de réplica, longitud de claves y tiempos de artesanía.
## Uso: Godot --headless --path Linde/cenital -s tests/medir_i1a.gd   (imprime «MEDIDA clave = valor»)
const J = preload("res://scripts/juego.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const A = preload("res://scripts/artesania.gd")
const RUTA := "user://medir_i1a.json"

func _t(nombre: String, veces: int, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in veces: f.call()
	print("MEDIDA tiempo_%s_us = %.1f" % [nombre, float(Time.get_ticks_usec() - t0) / veces])

func _init() -> void:
	var j = J.nueva(123, "Explorador", [0, 0, 0])
	j.combate.enemigos.clear()
	j.autonomia.activar()
	for i in 180 * 10: j.tick(0.1)
	j.guardar(RUTA)
	print("MEDIDA bytes_guardado_3h = ", FileAccess.get_file_as_bytes(RUTA).size())
	var s = Srv.new()
	s.j = j
	var inicial: Dictionary = s.estado_para(J.LOCAL)
	print("MEDIDA bytes_replica_bienvenida = ", var_to_bytes(inicial).size())
	print("MEDIDA bytes_instantanea = ", var_to_bytes(s.instantanea_actual()).size())
	var claves: Array = []
	var mayor := 0
	for f in A.reglas().formas:
		for m in A.reglas().materiales.keys() + A.combinaciones():
			for t in A.reglas().tecnicas:
				for q in range(int(A.reglas().calidad_max) + 1):
					var k: String = A.clave(f, m, t, q)
					if not A.leer(k).is_empty():
						claves.append(k)
						mayor = maxi(mayor, k.length())
	print("MEDIDA claves_art1 = %d, longitud_maxima = %d" % [claves.size(), mayor])
	_t("leer", 2000, func(): A.leer(claves[randi() % claves.size()]))
	_t("info", 2000, func(): A.info(claves[randi() % claves.size()]))
	_t("receta", 2000, func(): A.receta(claves[randi() % claves.size()]))
	_t("visible", 2000, func(): A.visible(claves[randi() % claves.size()]))
	var d: Object = j.autonomia.desarrollo
	var actor: String = j.actor_desarrollo(J.LOCAL)
	_t("planos", 50, func(): d.planos(actor))
	print("MEDIDA planos_jugador = ", d.planos(actor).size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	quit(0)
