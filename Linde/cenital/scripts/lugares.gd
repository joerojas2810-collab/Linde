extends RefCounted
## Génesis controlada de Mundo 1: planes puros por macrorregión y resultados durables.
## No simula poblados ni concede botín. Terreno, construcciones, cofres y caminos siguen siendo los existentes.
const M = preload("res://scripts/mundo.gd")
static var _datos: Dictionary = {}

## Configuración versionada del generador de lugares; no modifica los generadores de terreno.
static func datos() -> Dictionary:
	if _datos.is_empty(): _datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/lugares/generacion_v1.json"))
	return _datos

## Coordenadas de macrorregión, también para celdas negativas.
static func macro(c: Vector2i) -> Vector2i:
	var tam := int(datos().macro_celdas)
	return Vector2i(floori(float(c.x) / tam), floori(float(c.y) / tam))

static func _celda(m, c: Vector2i, cache: Dictionary) -> Dictionary:
	var k := M.clave(c)
	if not cache.has(k): cache[k] = m.generador.datos(c)
	return cache[k]

## Solo semilla, versión de terreno y coordenadas. Nunca consulta jugadores, diferencias ni regiones cargadas.
## AStarGrid2D del motor resuelve la ruta con costes de terreno y evita agua y muros del propio plan.
static func plan_macro(m, r: Vector2i) -> Dictionary:
	var cfg := datos()
	var tam := int(cfg.macro_celdas)
	var origen := r * tam
	var area := Rect2i(origen, Vector2i(tam, tam))
	var inicial := r == Vector2i.ZERO
	var ancla := origen + Vector2i(32, 48 if inicial else 23)
	var plan := {"version": int(cfg.version), "macro": M.clave(r), "lugares": {}, "rutas": {}, "suelos": {}, "despejes": {}, "piezas": {}}
	if m.generador == null or not m.generador.valida(ancla): return plan
	var cache := {}
	var grafo := AStarGrid2D.new()
	grafo.region = area
	grafo.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grafo.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grafo.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grafo.update()
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := Vector2i(x, y)
			var d := _celda(m, c, cache)
			grafo.set_point_solid(c, not m.generador.valida(c) or M.es_valle(c) or int(d.tipo) == M.T.AGUA)
			grafo.set_point_weight_scale(c, float(cfg.coste_sendero if int(d.tipo) == M.T.CAMINO else cfg.coste_tierra) + (float(cfg.coste_recurso) if str(d.objeto) != "" else 0.0))
	grafo.set_point_solid(ancla, false)
	var reservadas := {}
	var radio := int(cfg.radio_sitio)
	for tipo in cfg.tipos:
		var mejor := Vector2i.ZERO
		var puntuacion := 9223372036854775807
		var encontrado := false
		for y in range(int(cfg.inicio_y_min) if inicial else int(cfg.margen_sitio), tam - int(cfg.margen_sitio), int(cfg.paso_candidato)):
			for x in range(int(tipo.x_min), int(tipo.x_max), int(cfg.paso_candidato)):
				var c := origen + Vector2i(x, y)
				var d := _celda(m, c, cache)
				if not str(d.bioma) in tipo.biomas: continue
				var valor: int = M.h(c.x, c.y, int(m.estado.generacion.semilla) ^ str(tipo.id).hash())
				if tipo.id == "cueva" and str(d.bioma) == "sierra": valor -= 2147483648
				if valor >= puntuacion: continue
				var libre := true
				for dy in range(-radio, radio + 1):
					for dx in range(-radio, radio + 1):
						var q := c + Vector2i(dx, dy)
						if not m.generador.valida(q) or M.es_valle(q) or reservadas.has(M.clave(q)) or int(_celda(m, q, cache).tipo) == M.T.AGUA: libre = false
				if libre:
					mejor = c
					puntuacion = valor
					encontrado = true
		if not encontrado: continue
		var c := mejor
		var suelos := {}
		var piezas := {}
		for dy in range(-radio, radio + 1):
			for dx in range(-radio, radio + 1):
				var q := c + Vector2i(dx, dy)
				var t := M.T.PASTO
				if tipo.id == "ruinas":
					t = M.T.MURO_RUINA if (absi(dx) == radio or absi(dy) == radio) and (dx + dy) % 3 != 0 else M.T.RUINA
				elif tipo.id == "campamento":
					t = M.T.SUELO if absi(dx) <= 2 and dy <= 0 and dy >= -2 else M.T.PASTO
				else:
					t = M.T.MURO_RUINA if dy <= -2 or (absi(dx) == radio and dy <= 0) else M.T.RUINA
				if dx == 0 and dy >= 0: t = M.T.RUINA if tipo.id != "campamento" else M.T.PASTO
				suelos[M.clave(q)] = t
				grafo.set_point_solid(q, t == M.T.MURO_RUINA)
		if tipo.id == "campamento":
			for par in [[Vector2i(-2, -1), "mesa"], [Vector2i(2, -1), "cofre"]]:
				var q: Vector2i = c + par[0]
				piezas[M.clave(q)] = {"t": par[1], "propia": false}
				grafo.set_point_solid(q, true)
		var entrada := c + Vector2i(0, radio)
		var camino := grafo.get_id_path(ancla, entrada)
		if camino.is_empty():
			for k in suelos:
				var q := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
				grafo.set_point_solid(q, false)
			continue
		var lid := str(tipo.id) + "@" + M.clave(r)
		var rid := "ruta@" + lid
		var celdas: Array = [[32, 46], [32, 47]] if inicial else []
		for q in camino:
			celdas.append([q.x, q.y])
			reservadas[M.clave(q)] = true
			grafo.set_point_weight_scale(q, float(cfg.coste_sendero))
		plan.rutas[rid] = {"id": rid, "desde": "inicial" if inicial else "cruce@" + M.clave(r), "hasta": lid, "celdas": celdas}
		plan.lugares[lid] = {"id": lid, "version": int(cfg.version), "macro": M.clave(r), "tipo": tipo.id, "nombre": str(tipo.nombre) + ("" if inicial else " · " + M.clave(r)), "centro": [c.x, c.y], "entrada": [entrada.x, entrada.y], "area": [c.x-radio, c.y-radio, radio*2+1, radio*2+1], "bioma": _celda(m, c, cache).bioma, "descripcion": tipo.descripcion, "ruta": rid}
		plan.suelos.merge(suelos)
		plan.piezas.merge(piezas)
		for k in suelos:
			plan.despejes[k] = true
			reservadas[k] = true
	for ruta in plan.rutas.values():
		for q in ruta.celdas:
			if not M.es_valle(Vector2i(q[0], q[1])): plan.despejes["%d,%d" % [q[0], q[1]]] = true
	return plan

## Instala una macrorregión una sola vez en autoridad; volver a cargar nunca repone piezas retiradas o cofres vaciados.
static func ampliar(j, r: Vector2i) -> void:
	if not j.es_autoridad() or j.mundo.modo_inicio() != M.MODO_POBLADO: return
	var registro: Dictionary = j.d.mundo.get_or_add("registro", {"version": 1, "poblados": [M.ID_INICIAL], "macros": {}, "lugares": {}, "rutas": {}, "suelos": {}, "despejes": {}})
	var k := M.clave(r)
	if registro.macros.has(k): return
	var plan := plan_macro(j.mundo, r)
	# Un emplazamiento generado nunca pisa una obra posterior de un jugador/NPC: el registro conserva la decisión y omite la pieza ocupada.
	registro.macros[k] = {"version": plan.version, "lugares": plan.lugares.keys()}
	for campo in ["lugares", "rutas", "suelos", "despejes"]: registro[campo].merge(plan[campo])
	for p in plan.piezas:
		if not j.d.mundo.constr.has(p): j.d.mundo.constr[p] = plan.piezas[p]
		if plan.piezas[p].t == "cofre": j.d.cofres.get_or_add("c@" + p, {"inv": {}, "abierto": false})
	for ruta in plan.rutas.values():
		for q in ruta.celdas: j.d.mundo.caminos["%d,%d" % [q[0], q[1]]] = true
	j.mundo.aplicar_registro()

## Prepara antes de que un lugar entre en cámara; cargar terreno y generar identidad son operaciones distintas.
static func preparar(j, centros: Array) -> void:
	if not j.es_autoridad() or j.mundo.modo_inicio() != M.MODO_POBLADO: return
	var pendientes := {}
	var margen := int(datos().margen_preparacion)
	for c in centros:
		var primero := macro(c - Vector2i(margen, margen))
		var ultimo := macro(c + Vector2i(margen, margen))
		for y in range(primero.y, ultimo.y + 1):
			for x in range(primero.x, ultimo.x + 1): pendientes[M.clave(Vector2i(x, y))] = Vector2i(x, y)
	var claves: Array = pendientes.keys()
	claves.sort()
	for k in claves: ampliar(j, pendientes[k])
