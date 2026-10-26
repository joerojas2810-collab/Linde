extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const L = preload("res://scripts/lugares.gd")
const H = preload("res://scripts/huella.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1
func _init() -> void:
	var j = J.nueva(123, "Explorador", [0, 0, 0], "poblado")
	ok(j.d.mundo.registro.version == 1 and j.d.mundo.registro.lugares.size() >= 3, "registro compartido con los tres tipos de destino")
	var antes: String = H.hash_de(j.d.mundo.registro)
	j.actualizar_regiones()
	ok(H.hash_de(j.d.mundo.registro) == antes, "cargar regiones no vuelve a generar lugares")
	var a := L.plan_macro(j.mundo, Vector2i(-1, 0))
	var b := L.plan_macro(j.mundo, Vector2i(1, 0))
	L.ampliar(j, Vector2i(-1, 0))
	L.ampliar(j, Vector2i(1, 0))
	var registro: Dictionary = j.d.mundo.registro.duplicate(true)
	var otro = J.nueva(123, "Explorador", [0, 0, 0], "poblado")
	L.ampliar(otro, Vector2i(1, 0))
	L.ampliar(otro, Vector2i(-1, 0))
	ok(H.hash_de(registro) == H.hash_de(otro.d.mundo.registro), "mismo registro ampliando macrorregiones en orden inverso")
	ok(a == L.plan_macro(j.mundo, Vector2i(-1, 0)) and b == L.plan_macro(j.mundo, Vector2i(1, 0)), "planes puros independientes de diferencias y caché")
	ok(j.d.mundo.registro.macros.has("-1,0"), "expansión negativa persistida")
	j.guardar("/tmp/linde-lugares.json")
	var c = J.cargar("/tmp/linde-lugares.json")
	ok(c != null and H.hash_de(c.d.mundo.registro) == H.hash_de(j.d.mundo.registro), "guardar/cargar conserva el resultado completo")
	var legado = J.nueva(123, "Legado", [0, 0, 0])
	ok(not legado.d.mundo.has("registro"), "legado no genera registro")
	var camp: Dictionary = j.d.mundo.registro.lugares["campamento@0,0"]
	var entrada := Vector2i(camp.entrada[0], camp.entrada[1])
	j.pies = M.pies_de_celda(entrada)
	j.actualizar_regiones()
	var alc: Dictionary = j.mundo.alcanzables(M.ENTRADA, Rect2i(0, 0, 96, 96), {entrada: true})
	ok(alc.has(entrada), "acceso real desde el camino con colisiones y recursos cargados")
	var cc := Vector2i(camp.centro[0] + 2, camp.centro[1] - 1)
	var cid := "c@" + M.clave(cc)
	j.d.cofres[cid].inv = {"madera": 3}
	j.mundo.quitar(Vector2i(camp.centro[0] - 2, camp.centro[1] - 1))
	j.pies = M.pies_de_celda(Vector2i(500, 500))
	j.actualizar_regiones()
	j.pies = M.pies_de_celda(entrada)
	j.actualizar_regiones()
	ok(j.d.cofres[cid].inv == {"madera": 3} and j.mundo.constr_en(Vector2i(camp.centro[0] - 2, camp.centro[1] - 1)).is_empty(), "volver no repone la mesa ni el contenido del cofre")
	var sin_arboles := true
	for ruta in j.d.mundo.registro.rutas.values():
		for q in ruta.celdas:
			var ce := Vector2i(q[0], q[1])
			if j.mundo.region_cargada(ce) and j.mundo.objeto_presente(ce) != "": sin_arboles = false
	ok(sin_arboles, "los recursos naturales no reaparecen bloqueando los senderos")
	var futuro: Dictionary = j.d.duplicate(true)
	futuro.mundo.registro.version = 999
	ok(J.Guard.migrar(futuro).is_empty(), "un registro futuro se rechaza explícitamente")
	var validas := 0
	var tres := 0
	var fisicas := 0
	var tiempos: Array = []
	for semilla in 100:
		var m := M.new()
		m.estado.generacion = {"version": 2, "semilla": semilla, "region": 16}
		m.configurar(semilla)
		var t0 := Time.get_ticks_usec()
		var plan := L.plan_macro(m, Vector2i.ZERO)
		tiempos.append(Time.get_ticks_usec() - t0)
		m.estado.registro = plan
		m.estado.constr.merge(plan.piezas)
		if plan.lugares.size() == 3: tres += 1
		var bien: bool = not plan.lugares.is_empty()
		var fisica := true
		for lugar in plan.lugares.values():
			var destino := Vector2i(lugar.entrada[0], lugar.entrada[1])
			var ruta: Array = plan.rutas[lugar.ruta].celdas
			bien = bien and not ruta.is_empty() and Vector2(destino).distance_to(Vector2(M.ENTRADA)) <= float(L.datos().distancia_inicial_max)
			for i in ruta.size():
				var v: Array = ruta[i]
				var celda := Vector2i(v[0], v[1])
				if not m.region_cargada(celda): m.actualizar_regiones([celda])
				if m.bloquea(celda) or not m.caja_libre(M.pies_de_celda(celda)): fisica = false
				bien = bien and m.generador.datos(celda).tipo != M.T.AGUA
				if i > 0: bien = bien and absi(v[0] - ruta[i-1][0]) + absi(v[1] - ruta[i-1][1]) == 1
		if bien: validas += 1
		if fisica: fisicas += 1
	ok(validas == 100, "100 semillas: destinos cercanos y rutas continuas sin agua")
	ok(fisicas == 100, "100 semillas: todas las rutas permiten pasar al jugador con colisión real")
	tiempos.sort()
	print("GENERACION_MACRO_US p50=%d p95=%d max=%d" % [tiempos[50], tiempos[95], tiempos[-1]])
	print("REGISTRO_BYTES %d" % JSON.stringify(j.d.mundo.registro).to_utf8_buffer().size())
	print("LUGARES_100_SEMILLAS validas=%d tres_tipos=%d" % [validas, tres])
	quit(1 if fallos else 0)
