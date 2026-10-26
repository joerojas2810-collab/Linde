extends SceneTree
## Mundo 1, paso 1a: el registro `mundo.poblados` y sus lectores. Debe ser transparente: mismos valores que las constantes,
## persistente, replicado al cliente y con respaldo cuando el guardado o la réplica no lo traen.
## Uso: godot --headless --path Linde/cenital --script res://tests/prueba_poblados.gd   (código de salida = nº de fallos)
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var fallos := 0

func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1

func _init() -> void:
	var j = J.nueva(123, "Registrada", [0, 0, 0])
	var reg: Dictionary = j.d.mundo.get("poblados", {})
	ok(reg.has(M.ID_INICIAL) and reg.size() == 1, "una partida nueva trae exactamente el poblado inicial")
	var p: Dictionary = j.mundo.poblado()
	ok(p.id == M.ID_INICIAL and p.estado == "activo", "el poblado inicial tiene id y estado activo")
	# Transparencia: los lectores devuelven exactamente lo que dicen las constantes.
	ok(j.mundo.entrada() == M.ENTRADA, "entrada() iguala la constante ENTRADA")
	ok(j.mundo.esenciales() == M.ESENCIALES, "esenciales() iguala la constante ESENCIALES, en el mismo orden")
	ok(j.mundo.camas() == M.CAMAS, "camas() iguala la constante CAMAS")
	ok(typeof(j.mundo.entrada()) == TYPE_VECTOR2I and typeof(j.mundo.esenciales()[0]) == TYPE_VECTOR2I, "los lectores devuelven Vector2i, no listas")
	ok(Vector2i(int(p.centro[0]), int(p.centro[1])) == M.CENTRO_INICIAL and j.mundo.tipo(M.CENTRO_INICIAL) == M.T.CAMINO, "el centro está en el cruce de caminos")
	ok(Rect2i(0, 0, M.ANCHO, M.ALTO) == Rect2i(int(p.area[0]), int(p.area[1]), int(p.area[2]), int(p.area[3])), "el área es el Valle completo")
	# El registro no comparte referencias con las constantes.
	var n_esenciales: int = M.ESENCIALES.size()
	p.esenciales.append([0, 0])
	p.camas["intruso"] = [1, 1]
	ok(M.ESENCIALES.size() == n_esenciales and not M.CAMAS.has("intruso"), "modificar el registro no altera las constantes")
	p.esenciales.pop_back()
	p.camas.erase("intruso")
	# Los lectores leen del registro (no devuelven siempre la constante).
	p.entrada = [10, 11]
	ok(j.mundo.entrada() == Vector2i(10, 11), "entrada() lee el valor del registro")
	p.entrada = [M.ENTRADA.x, M.ENTRADA.y]
	# Persistencia: guardar y cargar conserva el registro y los lectores.
	var ruta := "/tmp/linde-poblados-%d.json" % OS.get_process_id()
	ok(j.guardar(ruta), "guarda la partida")
	var carga = J.cargar(ruta)
	ok(carga != null and carga.d.mundo.poblados.has(M.ID_INICIAL), "el registro sobrevive a guardar y cargar")
	ok(carga != null and carga.mundo.entrada() == M.ENTRADA and carga.mundo.esenciales() == M.ESENCIALES and carga.mundo.camas() == M.CAMAS,
		"los lectores dan lo mismo tras cargar (los enteros del JSON vuelven como Vector2i)")
	DirAccess.remove_absolute(ruta)
	# Réplica: el cliente recibe el registro en la bienvenida.
	j.unir("amiga", "Amiga", [0, 0, 0])
	var srv = Srv.new()
	srv.j = j
	var cli = Cli.new()
	cli._bienvenida(srv.estado_para("amiga"))
	ok(cli.j.d.mundo.poblados == j.d.mundo.poblados, "la réplica recibe el mismo registro que el servidor")
	ok(cli.j.mundo.entrada() == M.ENTRADA and cli.j.mundo.esenciales() == M.ESENCIALES, "los lectores de la réplica coinciden con el servidor")
	# Respaldo y migración aditiva: un guardado o una réplica sin registro siguen funcionando.
	j.d.mundo.erase("poblados")
	ok(j.mundo.poblado().is_empty() and j.mundo.entrada() == M.ENTRADA and j.mundo.esenciales() == M.ESENCIALES and j.mundo.camas() == M.CAMAS,
		"sin registro, los lectores usan las constantes")
	j.mundo.configurar(123)
	ok(j.d.mundo.has("poblados") and j.d.mundo.poblados[M.ID_INICIAL] == M.poblado_inicial(), "configurar() añade el registro a un guardado que no lo trae")
	# Otras claves del estado no se tocan al añadir el registro.
	ok(j.d.mundo.has("generacion") and j.d.mundo.generacion.version == 2, "la generación del terreno no cambia")
	print("POBLADOS: %d fallos" % fallos)
	quit(fallos)
