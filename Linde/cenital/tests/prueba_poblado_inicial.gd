extends SceneTree
## Mundo 1, paso 1d: referencias (hitos con nombre) e instalaciones comunitarias del poblado inicial, solo en modo poblado.
## Uso: godot --headless --path Linde/cenital --script res://tests/prueba_poblado_inicial.gd   (código de salida = nº de fallos)
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var fallos := 0

func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1

func _celda_dato(lugar: String) -> Vector2i:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://datos/mundo/entities/lugar/%s.json" % lugar))
	return Vector2i(int(d.data.celda.x), int(d.data.celda.y))

func _piezas(j, tipo: String) -> Array:
	var l: Array = []
	for k in j.d.mundo.constr:
		var c := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
		if M.es_valle(c) and j.d.mundo.constr[k].t == tipo: l.append(c)
	return l

func _init() -> void:
	# Modo legado: ni hitos ni instalaciones (el mundo de siempre).
	var jl = J.nueva(123, "Legado", [0, 0, 0])
	ok(not jl.d.mundo.poblados.inicial.has("hitos") and not jl.d.mundo.poblados.inicial.has("instalaciones"), "modo legado: el registro no trae hitos ni instalaciones")
	ok(_piezas(jl, "mesa").is_empty() and _piezas(jl, "horno").is_empty() and jl.mundo.hito_en(Vector2i(34, 25)) == "", "modo legado: no hay mesa ni horno iniciales ni nombres de lugares")
	# Modo poblado.
	var j = J.nueva(123, "Poblado", [0, 0, 0], M.MODO_POBLADO)
	var p: Dictionary = j.d.mundo.poblados.inicial
	ok(p.hitos.size() == 7 and p.instalaciones.size() == 2, "modo poblado: siete hitos y dos instalaciones registradas")
	ok(j.mundo.hito_en(_celda_dato("plaza")) == "La plaza", "la celda de datos de la plaza está en «La plaza»")
	ok(j.mundo.hito_en(_celda_dato("taller")) == "La casa del taller", "la celda de datos del taller está en «La casa del taller»")
	ok(j.mundo.hito_en(Vector2i(10, 9)) == "La cantera" and j.mundo.hito_en(M.ENTRADA) == "La entrada sur" and j.mundo.hito_en(Vector2i(52, 42)) == "Las ruinas", "cantera, entrada sur y ruinas tienen nombre")
	ok(j.mundo.hito_en(Vector2i(0, 40)) == "", "fuera de los hitos no hay nombre")
	# Instalaciones.
	var mesas := _piezas(j, "mesa")
	var hornos := _piezas(j, "horno")
	ok(mesas.size() == 1 and hornos.size() == 1, "hay exactamente una mesa y un horno comunitarios")
	var plaza := _celda_dato("plaza")
	ok(Vector2(mesas[0] - plaza).length() <= 6.0 and maxi(absi(mesas[0].x - hornos[0].x), absi(mesas[0].y - hornos[0].y)) == 1, "están junto a la plaza y el horno pegado a la mesa")
	ok(j.mundo.tipo(mesas[0]) == M.T.PASTO and j.mundo.tipo(hornos[0]) == M.T.PASTO and not M.ESENCIALES.has(mesas[0]) and not M.ESENCIALES.has(hornos[0]), "en hierba y fuera de las celdas esenciales")
	var alc: Dictionary = j.mundo.alcanzables()
	var todas := true
	for e in M.ESENCIALES: if not alc.has(e): todas = false
	ok(todas, "todas las celdas esenciales siguen siendo alcanzables")
	var cs: Dictionary = j.mundo.constr_en(mesas[0])
	ok(not cs.get("propia", true) and not cs.has("dueno"), "son comunitarias: sin dueño ni piezas propias de nadie")
	ok(not j.retirar(mesas[0]).ok, "un jugador no puede retirarlas")
	# Uso por un jugador: junto a ellas puede fabricar con recetas que piden mesa y horno.
	j.rt[J.LOCAL].pies = M.pies_de_celda(mesas[0] + Vector2i(0, 1))
	j.jug().inv = {"madera": 6, "fibra": 2, "mena": 2}
	ok(j.estacion_junto() != "" and j.fabricar("escudo_madera").ok, "el jugador fabrica en la mesa comunitaria (escudo de madera)")
	j.jug().hab = ["recolector", "artesano"]
	j.jug().xp = 100
	j.rt[J.LOCAL].pies = M.pies_de_celda(hornos[0] + Vector2i(0, 1))
	j.jug().inv = {"mena": 2, "madera": 1}
	ok(j.fabricar("lingote").ok, "y funde un lingote en el horno comunitario")
	# Persistencia: no reaparecen si faltan; se conservan al cargar.
	var ruta := "/tmp/linde-poblado-inicial-%d.json" % OS.get_process_id()
	j.mundo.quitar(mesas[0])
	ok(j.guardar(ruta), "guarda con la mesa derribada")
	var carga = J.cargar(ruta)
	DirAccess.remove_absolute(ruta)
	ok(carga != null and _piezas(carga, "mesa").is_empty() and _piezas(carga, "horno").size() == 1 and carga.d.mundo.poblados.inicial.instalaciones.size() == 2,
		"al cargar, lo derribado no reaparece y el resto se conserva")
	# Los habitantes las usan: no construyen otra mesa ni otro horno durante dos días.
	var j2 = J.nueva(123, "Dias", [0, 0, 0], M.MODO_POBLADO)
	j2.combate.enemigos.clear()
	for i in 2 * 2880: j2.tick(0.5)
	ok(_piezas(j2, "mesa").size() <= 1 + 1 and _piezas(j2, "horno").size() <= 1 + 1, "tras dos días hay %d mesa(s) y %d horno(s): los habitantes usan los comunitarios" % [_piezas(j2, "mesa").size(), _piezas(j2, "horno").size()])
	print("POBLADO_INICIAL: %d fallos" % fallos)
	quit(fallos)
