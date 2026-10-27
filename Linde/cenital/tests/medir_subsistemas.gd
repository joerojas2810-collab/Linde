extends SceneTree
## Perfil repetible por subsistema. No cambia reglas; mide operaciones reales con una partida fija.
## Uso: godot --headless --path Linde/cenital -s res://tests/medir_subsistemas.gd -- semilla=123 muestras=100
const J = preload("res://scripts/juego.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Com = preload("res://tests/medir_comun.gd")
var j
var srv
var muestra_region := 0

func _init() -> void:
	var a := Com.args({"semilla": "123", "muestras": "100"})
	var semilla := int(a.semilla)
	var n := maxi(20, int(a.muestras))
	j = J.nueva(semilla, "Perfil", [0, 0, 0], "poblado")
	j.combate.enemigos.clear()
	j.actualizar_regiones() # estado de inicio estable; no incluir preparación en los tiempos por muestra
	srv = Srv.new()
	srv.j = j
	Com.linea("MEDIDA_CONFIG", {"herramienta": "medir_subsistemas", "semilla": semilla, "muestras": n,
		"habitantes": j.habitantes.ids.size(), "jugadores": j.rt.size(), "regiones_inicio": j.mundo.regiones.size(),
		"modo": j.mundo.modo_inicio(), "godot": Engine.get_version_info().string,
		"nota": "muestreo_CPU_por_operacion; las categorías no son sumables"})
	_medir("npc_movimiento_necesidades", Callable(self, "_npc_mover"), n)
	_medir("npc_decisiones_lote", Callable(self, "_npc_decidir"), n)
	_medir("navegacion_BFS", Callable(self, "_navegar"), n)
	_medir("fauna_actualizar", Callable(self, "_fauna"), n)
	_medir("economia_regional", Callable(self, "_economia"), n)
	_medir("regiones_streaming_frio", Callable(self, "_region"), mini(30, n))
	_medir("red_snapshot_bytes_local", Callable(self, "_serializar"), n)
	_medir("tick_completo_referencia", Callable(self, "_tick"), n)
	quit(0)

func _medir(nombre: String, accion: Callable, n: int) -> void:
	for i in 5: accion.call(i) # calentamiento no reportado
	var us: Array[int] = []
	for i in n:
		var t0 := Time.get_ticks_usec()
		accion.call(i)
		us.append(Time.get_ticks_usec() - t0)
	us.sort()
	var suma := 0
	for x in us: suma += x
	Com.linea("MEDIDA_CPU", {"subsistema": nombre, "n": n, "promedio_us": snappedf(float(suma) / n, 0.1),
		"p95_us": us[int(n * 0.95)], "max_us": us[-1]})

func _npc_mover(_i: int) -> void:
	j.habitantes.paso(0.05)

func _npc_decidir(_i: int) -> void:
	for id in j.habitantes.ids: j.autonomia.sociedad.decidir(id)

func _navegar(_i: int) -> void:
	j.mundo.camino(Vector2i(32, 23), func(c: Vector2i) -> bool: return c == Vector2i(44, 35), Rect2i(0, 0, 64, 48))

func _fauna(_i: int) -> void:
	j.combate.fauna.actualizar()

func _economia(_i: int) -> void:
	j.autonomia.asentamientos.actualizar()
	j.autonomia.sociedad.actualizar()
	j.autonomia.asentamientos.actualizar_demandas()

func _region(_i: int) -> void:
	muestra_region += 1
	j.mundo.actualizar_regiones([Vector2i(2048 + muestra_region * 96, 2048)])

func _serializar(_i: int) -> void:
	var instantanea: Array = srv.instantanea_actual()
	var bytes := var_to_bytes(instantanea)
	if bytes.is_empty(): push_error("instantánea vacía")

func _tick(_i: int) -> void:
	j.tick(0.5)
