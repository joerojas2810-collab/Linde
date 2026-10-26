extends SceneTree
## Mundo 1, pasos 1a/1b: el registro `mundo.poblados` y sus lectores `entrada(poblado_id)`, `esenciales(poblado_id)` y `camas(poblado_id)`.
## Deben ser transparentes para el poblado inicial (mismos valores que las constantes), exigir un poblado explícito, no mezclar
## poblados entre sí, persistir, replicarse al cliente y usar el respaldo solo si el guardado o la réplica no traen el registro.
## Uso: godot --headless --path Linde/cenital --script res://tests/prueba_poblados.gd   (código de salida = nº de fallos)
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var fallos := 0

func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1

## Segundo poblado sintético, solo para comprobar el aislamiento (no existe en el juego).
func _otro() -> Dictionary:
	return {"id": "otro", "nombre": "Otro", "estado": "activo", "centro": [100, 100], "area": [90, 90, 20, 20], "entrada": [5, 7],
		"esenciales": [[1, 1], [2, 2]], "camas": {"zoe": [3, 3]}}

func _init() -> void:
	var j = J.nueva(123, "Registrada", [0, 0, 0])
	var m = j.mundo
	var reg: Dictionary = j.d.mundo.get("poblados", {})
	ok(reg.has(M.ID_INICIAL) and reg.size() == 1, "una partida nueva trae exactamente el poblado inicial")
	var p: Dictionary = m.poblado(M.ID_INICIAL)
	ok(p.id == M.ID_INICIAL and p.estado == "activo", "el poblado inicial tiene id y estado activo")
	# Transparencia con un id válido: los lectores devuelven exactamente lo que dicen las constantes.
	ok(m.entrada(M.ID_INICIAL) == M.ENTRADA, "entrada(inicial) iguala la constante ENTRADA")
	ok(m.esenciales(M.ID_INICIAL) == M.ESENCIALES, "esenciales(inicial) iguala la constante ESENCIALES, en el mismo orden")
	ok(m.camas(M.ID_INICIAL) == M.CAMAS, "camas(inicial) iguala la constante CAMAS")
	ok(typeof(m.entrada(M.ID_INICIAL)) == TYPE_VECTOR2I and typeof(m.esenciales(M.ID_INICIAL)[0]) == TYPE_VECTOR2I, "los lectores devuelven Vector2i, no listas")
	ok(Vector2i(int(p.centro[0]), int(p.centro[1])) == M.CENTRO_INICIAL and m.tipo(M.CENTRO_INICIAL) == M.T.CAMINO, "el centro está en el cruce de caminos")
	ok(Rect2i(0, 0, M.ANCHO, M.ALTO) == Rect2i(int(p.area[0]), int(p.area[1]), int(p.area[2]), int(p.area[3])), "el área es el Valle completo")
	# Ids inexistentes (incluido el vacío): no hay unión ni poblado por defecto.
	for id in ["no_existe", ""]:
		ok(m.entrada(id) == M.SIN_CELDA and m.esenciales(id).is_empty() and m.camas(id).is_empty() and m.poblado(id).is_empty(),
			"el id «%s» no existe: celda inválida, sin esenciales ni camas" % id)
	# El registro no comparte referencias con las constantes.
	var n_esenciales: int = M.ESENCIALES.size()
	p.esenciales.append([0, 0])
	p.camas["intruso"] = [1, 1]
	ok(M.ESENCIALES.size() == n_esenciales and not M.CAMAS.has("intruso"), "modificar el registro no altera las constantes")
	p.esenciales.pop_back()
	p.camas.erase("intruso")
	# Los lectores leen del registro (no devuelven siempre la constante).
	p.entrada = [10, 11]
	ok(m.entrada(M.ID_INICIAL) == Vector2i(10, 11), "entrada(inicial) lee el valor del registro")
	p.entrada = [M.ENTRADA.x, M.ENTRADA.y]
	# Aislamiento entre poblados.
	j.d.mundo.poblados["otro"] = _otro()
	ok(m.entrada("otro") == Vector2i(5, 7) and m.esenciales("otro") == [Vector2i(1, 1), Vector2i(2, 2)] and m.camas("otro") == {"zoe": Vector2i(3, 3)},
		"un segundo poblado devuelve sus propios datos")
	ok(m.entrada(M.ID_INICIAL) == M.ENTRADA and m.esenciales(M.ID_INICIAL) == M.ESENCIALES and m.camas(M.ID_INICIAL) == M.CAMAS,
		"añadir un poblado no cambia lo que ve el inicial")
	ok(not m.esenciales(M.ID_INICIAL).has(Vector2i(1, 1)) and not m.camas(M.ID_INICIAL).has("zoe") and not m.esenciales("otro").has(Vector2i(27, 23)),
		"ningún poblado ve los esenciales ni las camas de otro")
	j.d.mundo.poblados["otro"].esenciales.append([9, 9])
	ok(m.esenciales("otro").size() == 3 and m.esenciales(M.ID_INICIAL) == M.ESENCIALES, "modificar un poblado no afecta a otro")
	# Persistencia con dos poblados: guardar y cargar conserva el registro y los lectores.
	var ruta := "/tmp/linde-poblados-%d.json" % OS.get_process_id()
	ok(j.guardar(ruta), "guarda la partida")
	var carga = J.cargar(ruta)
	ok(carga != null and carga.d.mundo.poblados.has(M.ID_INICIAL) and carga.d.mundo.poblados.has("otro"), "el registro con dos poblados sobrevive a guardar y cargar")
	ok(carga != null and carga.mundo.entrada(M.ID_INICIAL) == M.ENTRADA and carga.mundo.esenciales(M.ID_INICIAL) == M.ESENCIALES and carga.mundo.camas(M.ID_INICIAL) == M.CAMAS
		and carga.mundo.entrada("otro") == Vector2i(5, 7) and carga.mundo.camas("otro") == {"zoe": Vector2i(3, 3)},
		"los lectores dan lo mismo tras cargar (los enteros del JSON vuelven como Vector2i)")
	DirAccess.remove_absolute(ruta)
	# Réplica: el cliente recibe el registro en la bienvenida y lo lee de SU mundo.
	j.unir("amiga", "Amiga", [0, 0, 0])
	var srv = Srv.new()
	srv.j = j
	var cli = Cli.new()
	cli._bienvenida(srv.estado_para("amiga"))
	ok(cli.j.d.mundo.poblados == j.d.mundo.poblados, "la réplica recibe el mismo registro que el servidor")
	ok(cli.j.mundo.entrada(M.ID_INICIAL) == M.ENTRADA and cli.j.mundo.esenciales("otro").size() == 3, "los lectores de la réplica coinciden con el servidor")
	cli.j.d.mundo.poblados["otro"].entrada = [50, 50]
	ok(j.mundo.entrada("otro") == Vector2i(5, 7), "cada Mundo lee su propio registro (réplica y servidor no se mezclan)")
	# Respaldo y migración aditiva.
	j.d.mundo.poblados.erase("otro")
	ok(m.entrada("otro") == M.SIN_CELDA and m.camas("otro").is_empty(), "al quitar un poblado sus lectores quedan vacíos")
	j.d.mundo.poblados.erase(M.ID_INICIAL)
	ok(m.entrada(M.ID_INICIAL) == M.SIN_CELDA and m.esenciales(M.ID_INICIAL).is_empty() and m.camas(M.ID_INICIAL).is_empty(),
		"con registro pero sin poblado inicial NO se usan las constantes (un poblado desaparecido no resucita)")
	j.d.mundo.erase("poblados")
	ok(m.poblado(M.ID_INICIAL).is_empty() and m.entrada(M.ID_INICIAL) == M.ENTRADA and m.esenciales(M.ID_INICIAL) == M.ESENCIALES and m.camas(M.ID_INICIAL) == M.CAMAS,
		"sin registro, el poblado inicial usa las constantes")
	ok(m.entrada("otro") == M.SIN_CELDA and m.esenciales("otro").is_empty() and m.camas("") .is_empty(), "sin registro, ningún otro id usa el respaldo")
	m.configurar(123)
	ok(j.d.mundo.has("poblados") and j.d.mundo.poblados[M.ID_INICIAL] == M.poblado_inicial(), "configurar() añade el registro a un guardado que no lo trae")
	ok(j.d.mundo.has("generacion") and j.d.mundo.generacion.version == 2, "la generación del terreno no cambia")
	print("POBLADOS: %d fallos" % fallos)
	quit(fallos)
