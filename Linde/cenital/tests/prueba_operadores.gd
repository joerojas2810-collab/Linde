extends SceneTree
## I1a E2: variantes art2: (operadores refuerzo y grosor). Presupuesto antes y después del redondeo, contrapartidas,
## dominancia (continua y con estadísticas enteras y consumos reales), claves canónicas y su longitud.
## Uso:  Godot --headless --path Linde/cenital --script res://tests/prueba_operadores.gd [-- --informe]
const A = preload("res://scripts/artesania.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const E := 0.000000001
## REGISTROS medidos con los coeficientes iniciales de I1a (2026-10-25); no son objetivos. Si cambian, o es un cambio deliberado
## de coeficientes (actualizar y documentar en ESTADO.md) o una regresión.
## Pares (v > w) en que v tiene estadísticas enteras ≥ y consume ≤ insumo por insumo: casi siempre la pieza art1: frente a una
## variante cuya ventaja se pierde al redondear (se comparan consumos reales; no se equipara un material con otro).
const DOMINANCIAS_ENTERAS := 1646
## Variantes con ventaja nominal de potencia y ninguna estadística entera (dmg/def/hp) por encima de la pieza sin operadores.
const VENTAJAS_PERDIDAS := 631
var total := 0
var fallos := 0

func ok(c: bool, texto: String) -> void:
	total += 1
	print(("PASS " if c else "FAIL ") + texto)
	if not c: fallos += 1

func _init() -> void:
	var informe := "--informe" in OS.get_cmdline_user_args()
	_datos()
	_canonico()
	_longitud()
	_presupuesto()
	_contrapartida()
	_dominancia(informe)
	_perdidas(informe)
	_recetas()
	_rendimiento()
	print("OPERADORES: %d comprobaciones, %d fallos" % [total, fallos])
	quit(1 if fallos else 0)

func _desc(k: String) -> Dictionary:
	return A.leer2(k)

## Pieza sin operadores con la misma forma, material, técnica y calidad.
func _base(p: Dictionary) -> Dictionary:
	var b := p.duplicate()
	b.refuerzo = A.reglas().operadores.refuerzo.defecto
	b.grosor = A.reglas().operadores.grosor.defecto
	return b

func _vel(p: Dictionary) -> float:
	var r := A.reglas()
	return A.velocidad(A.material_reforzado(A.material(p.material), p.refuerzo)) + float(r.tecnicas[p.tecnica].vel) + float(r.operadores.grosor.niveles[p.grosor].vel)

func _consumo(k: String) -> Dictionary:
	return A.receta2(k).ent

func _datos() -> void:
	ok(A.validar().is_empty(), "datos: las reglas con operadores son válidas " + str(A.validar()))
	ok(A.EVALUADOR_VERSION == 3 and int(A.reglas().version) == 3, "datos: EVALUADOR_VERSION y version de reglas subidas a 3")
	var texto := FileAccess.get_file_as_string("res://datos/desarrollo/reglas_v1.json")
	ok(not "art2:" in texto, "C1: ninguna variante art2: figura individualmente en el JSON de reglas")
	var todas := A.enumerar2()
	ok(todas.size() > 1000, "datos: el espacio de variantes (%d) no está escrito a mano" % todas.size())
	ok(todas == A.enumerar2(), "datos: la enumeración es determinista")

func _canonico() -> void:
	var todas := A.enumerar2()
	var malas: Array = []
	for k in todas:
		var p := A.leer2(k)
		if p.is_empty() or A.clave2(p.forma, p.material, p.tecnica, p.calidad, p.refuerzo, p.grosor) != k: malas.append(k)
		if not A.leer(k).is_empty() or A.info(k) != {}: malas.append("art1 lee " + k)
	ok(malas.is_empty(), "canónico: cada clave válida se lee y se reescribe idéntica, y art1 no la acepta " + str(malas.slice(0, 3)))
	ok(A.leer2("art1:espada:hierro:simple:0").is_empty(), "canónico: art2 no acepta claves art1")
	var rechazos := {
		"calidad con cero": "art2:espada:hierro:simple:03:piedra:grueso",
		"calidad fuera de rango": "art2:espada:hierro:simple:4:piedra:grueso",
		"calidad negativa": "art2:espada:hierro:simple:-1:piedra:grueso",
		"sin operadores": "art2:espada:hierro:simple:0:sin:normal",
		"faltan campos": "art2:espada:hierro:simple:0:piedra",
		"campo extra (cliente fija estadísticas)": "art2:espada:hierro:simple:0:piedra:grueso:dmg=99",
		"campo con signo": "art2:espada:hierro:simple:0:piedra:grueso:",
		"forma inexistente": "art2:lanza:hierro:simple:0:piedra:grueso",
		"material de laminado": "art2:espada:hierro_madera:simple:0:piedra:grueso",
		"técnica inexistente": "art2:espada:hierro:forjada:0:piedra:grueso",
		"refuerzo inexistente": "art2:espada:hierro:simple:0:oro:grueso",
		"grosor inexistente": "art2:espada:hierro:simple:0:piedra:enorme",
		"mayúsculas": "art2:Espada:hierro:simple:0:piedra:grueso",
		"material que no admite la forma": "art2:casco:madera:simple:0:sin:grueso",
		"refuerzo que no admite la forma": "art2:casco:hierro:simple:0:madera:grueso",
		"base sin refuerzo permitido": "art2:espada:madera:simple:0:piedra:normal",
		"refuerzo igual al material": "art2:espada:piedra:simple:0:piedra:normal",
		"operadores en otro orden": "art2:espada:hierro:simple:0:grueso:piedra",
		"espacios": "art2:espada:hierro:simple:0:piedra: grueso",
		"vacía": "art2:"}
	for motivo in rechazos: ok(A.leer2(rechazos[motivo]).is_empty() and A.info2(rechazos[motivo]).is_empty() and A.receta2(rechazos[motivo]).is_empty(), "rechazo: " + motivo)
	ok(not A.leer2("art2:espada:hierro:simple:0:piedra:grueso").is_empty(), "canónico: una variante válida de referencia se acepta")
	# El presupuesto lo impone el evaluador, no el catálogo de claves: con un tope más estricto se rechaza lo que lo supera.
	var original: Dictionary = A._reglas
	var estricta: Dictionary = original.duplicate(true)
	estricta.operadores.potencia_max = 1.05
	A._reglas = estricta
	var aceptadas := A.enumerar2().size()
	var grande := A.leer2("art2:espada:hierro:simple:0:piedra:grueso")
	A._reglas = original
	ok(grande.is_empty() and aceptadas < todas.size() and not A.leer2("art2:espada:hierro:simple:0:piedra:grueso").is_empty(), "presupuesto: con un tope de 1,05 el evaluador rechaza la variante que lo supera (%d de %d)" % [aceptadas, todas.size()])

func _longitud() -> void:
	var mayor := 0
	var peor := ""
	for k in A.enumerar2():
		if k.length() > mayor:
			mayor = k.length()
			peor = k
	print("MEDIDA longitud_maxima_art2 = %d (%s)" % [mayor, peor])
	ok(mayor <= Srv.MAX_TEXTO, "D3: todas las claves art2: válidas caben en MAX_TEXTO=%d (la más larga mide %d)" % [Srv.MAX_TEXTO, mayor])

func _presupuesto() -> void:
	var r := A.reglas()
	var tope := float(r.operadores.potencia_max)
	var max_cont := 0.0
	var max_ent := 0.0
	var excedidas: Array = []
	var excedidas_ent: Array = []
	for k in A.enumerar2():
		var p := _desc(k)
		var razon := A.razon2(p)
		max_cont = maxf(max_cont, razon)
		if razon > tope + E: excedidas.append(k)
		var f: Dictionary = r.formas[p.forma]
		var i := A.info2(k)
		var pot_base := A.potencia2(_base(p))
		for s in ["dmg", "def", "hp"]:
			if int(f[s]) == 0: continue
			# después del redondeo: nunca por encima del tope aplicado al valor base sin redondear, ni 1 punto por encima de él
			var maximo := roundi(float(f[s]) * pot_base * tope)
			max_ent = maxf(max_ent, float(i[s]) / (float(f[s]) * pot_base))
			if int(i[s]) > maximo: excedidas_ent.append("%s %s=%d>%d" % [k, s, i[s], maximo])
	print("MEDIDA razon_potencia_maxima = %.4f; razon_entera_maxima = %.4f" % [max_cont, max_ent])
	ok(excedidas.is_empty() and max_cont <= tope + E, "presupuesto continuo: ninguna variante supera %.2f× la pieza sin operadores (máx %.4f)" % [tope, max_cont])
	ok(excedidas_ent.is_empty(), "presupuesto entero: tras redondear, ninguna estadística supera el tope redondeado " + str(excedidas_ent.slice(0, 3)))

func _contrapartida() -> void:
	var r := A.reglas()
	var sin: Array = []
	for k in A.enumerar2():
		var p := _desc(k)
		var b := _base(p)
		# cada operador por separado frente a la pieza sin operadores: si mejora algo, algo debe empeorar
		for cual in ["refuerzo", "grosor"]:
			var q := b.duplicate()
			q[cual] = p[cual]
			if q[cual] == b[cual]: continue
			var kq := A.clave2(q.forma, q.material, q.tecnica, q.calidad, q.refuerzo, q.grosor)
			if A.leer2(kq).is_empty(): continue
			var mejora: bool = A.potencia2(q) > A.potencia2(b) + E or _vel(q) > _vel(b) + E
			var mejora_coste := false
			var peor := false
			var cq := _consumo(kq)
			# consumo del base sin operadores: material × forma (los insumos de la técnica no cuentan en art2)
			var cb := {str(A.material(b.material).item): int(A.material(b.material).coste) * int(r.formas[b.forma].coste)}
			for item in cq: if int(cq[item]) > int(cb.get(item, 0)): peor = true
			for item in cb: if int(cq.get(item, 0)) < int(cb[item]): mejora_coste = true
			if A.potencia2(q) < A.potencia2(b) - E or _vel(q) < _vel(b) - E: peor = true
			if (mejora or mejora_coste) and not peor: sin.append(kq)
	ok(sin.is_empty(), "contrapartida: cada nivel no predeterminado que mejora algo empeora otra cosa " + str(sin.slice(0, 3)))

## v domina a w si en todas las estadísticas es ≥, en cada insumo consume ≤ y en algo es estrictamente mejor.
func _domina(v: Dictionary, w: Dictionary) -> bool:
	var mejor := false
	for s in v.est:
		if v.est[s] < w.est[s] - E: return false
		if v.est[s] > w.est[s] + E: mejor = true
	for item in v.ent:
		if int(v.ent[item]) > int(w.ent.get(item, 0)): return false
	for item in w.ent:
		if int(v.ent.get(item, 0)) < int(w.ent[item]): mejor = true
	return mejor

## Grupo = misma forma, material, técnica y calidad: las variantes art2: más la pieza art1: equivalente (sus insumos reales
## incluyen el extra de la técnica). El consumo se compara insumo por insumo: no se equipara un material con otro por cantidad.
func _grupos(entero: bool) -> Dictionary:
	var grupos := {}
	var r := A.reglas()
	for k in A.enumerar2():
		var p := _desc(k)
		var i := A.info2(k)
		var f: Dictionary = r.formas[p.forma]
		var est := {"vel": float(i.vel)}
		for s in ["dmg", "def", "hp"]:
			if int(f[s]) > 0: est[s] = float(i[s]) if entero else float(f[s]) * A.potencia2(p)
		if not entero: est.vel = _vel(p)
		var g := "%s|%s|%s|%d" % [p.forma, p.material, p.tecnica, p.calidad]
		if not grupos.has(g):
			var k1 := A.clave(p.forma, p.material, p.tecnica, p.calidad)
			var i1 := A.info(k1)
			var est1 := {"vel": float(i1.vel)}
			for s in ["dmg", "def", "hp"]:
				if int(f[s]) > 0: est1[s] = float(i1[s]) if entero else float(f[s]) * A.potencia2(_base(p))
			grupos[g] = []
			grupos[g].append({"clave": k1, "est": est1, "ent": A.receta(k1).ent})
		grupos[g].append({"clave": k, "est": est, "ent": _consumo(k)})
	return grupos

func _pares_dominados(entero: bool) -> Array:
	var lista: Array = []
	var grupos := _grupos(entero)
	for g in grupos:
		for v in grupos[g]:
			for w in grupos[g]:
				if v.clave != w.clave and _domina(v, w): lista.append("%s > %s" % [v.clave, w.clave])
	lista.sort()
	return lista

## Comparación AUXILIAR y aproximada: suma las unidades de todos los insumos como si valieran lo mismo. No es una equivalencia
## económica (una piedra no vale un lingote); solo detecta un refuerzo estrictamente mejor que otro a igual cantidad. Limitación
## documentada: no sustituye a la comparación insumo por insumo, que es la que decide.
func _pares_por_unidades() -> Array:
	var lista: Array = []
	var grupos := _grupos(false)
	for g in grupos:
		for v in grupos[g]:
			for w in grupos[g]:
				if v.clave == w.clave: continue
				var uv := 0
				var uw := 0
				for item in v.ent: uv += int(v.ent[item])
				for item in w.ent: uw += int(w.ent[item])
				var mejor := false
				var peor := false
				for s in v.est:
					if v.est[s] > w.est[s] + E: mejor = true
					if v.est[s] < w.est[s] - E: peor = true
				if uv < uw: mejor = true
				if uv > uw: peor = true
				if mejor and not peor: lista.append("%s > %s" % [v.clave, w.clave])
	return lista

func _dominancia(informe: bool) -> void:
	var aprox := _pares_por_unidades()
	ok(aprox.is_empty(), "dominancia por unidades totales (aproximada, ver limitación): ningún refuerzo supera a otro a igual cantidad (%d) %s" % [aprox.size(), str(aprox.slice(0, 3))])
	var continua := _pares_dominados(false)
	ok(continua.is_empty(), "dominancia continua: ninguna variante supera a otra (ni a la pieza art1:) sin coste adicional (%d) %s" % [continua.size(), str(continua.slice(0, 3))])
	var entera := _pares_dominados(true)
	print("MEDIDA dominancias_con_estadisticas_enteras = ", entera.size())
	if informe: for e in entera.slice(0, 60): print("DOMINADA ", e)
	ok(entera.size() == _esperadas_enteras(), "dominancia con estadísticas enteras y consumos reales: %d pares registrados (si cambia: revisar coeficientes o registro)" % entera.size())

func _esperadas_enteras() -> int:
	return DOMINANCIAS_ENTERAS

func _perdidas(informe: bool) -> void:
	var r := A.reglas()
	var perdidas: Array = []
	for k in A.enumerar2():
		var p := _desc(k)
		var f: Dictionary = r.formas[p.forma]
		var i := A.info2(k)
		var b := A.info(A.clave(p.forma, p.material, p.tecnica, p.calidad))
		if A.potencia2(p) <= A.potencia2(_base(p)) + E: continue    # sin ventaja nominal de potencia
		var igual := true
		for s in ["dmg", "def", "hp"]: if int(i[s]) > int(b[s]): igual = false
		if igual: perdidas.append(k)
	print("MEDIDA variantes_con_ventaja_de_potencia_perdida_al_redondear = ", perdidas.size())
	var por_forma := {}
	var por_operador := {}
	for k in perdidas:
		var p := _desc(k)
		por_forma[p.forma] = int(por_forma.get(p.forma, 0)) + 1
		var op := "%s+%s" % [p.refuerzo, p.grosor]
		por_operador[op] = int(por_operador.get(op, 0)) + 1
	print("MEDIDA perdidas_por_forma = ", JSON.stringify(por_forma, "", true))
	print("MEDIDA perdidas_por_operador = ", JSON.stringify(por_operador, "", true))
	if informe: for k in perdidas.slice(0, 40): print("PERDIDA ", k)
	ok(perdidas.size() == _esperadas_perdidas(), "beneficio perdido: %d variantes con ventaja nominal de potencia sin efecto en las estadísticas enteras (registro)" % perdidas.size())

func _esperadas_perdidas() -> int:
	return VENTAJAS_PERDIDAS

func _recetas() -> void:
	var r := A.receta2("art2:espada:hierro:simple:0:piedra:grueso")
	ok(r.ent == {"lingote": 3, "piedra": 2} and r.est == "mesa" and r.sal == {"art2:espada:hierro:simple:0:piedra:grueso": 1}, "receta: espada de hierro, refuerzo de piedra y grosor grueso consume 3 lingotes y 2 piedras " + str(r.ent))
	var f := A.receta2("art2:torso:hierro:ligera:0:fibra:fino")
	ok(f.ent == {"lingote": 3, "fibra": 4}, "receta: torso fino (2×2×0,75 = 3 hacia arriba) más 4 de fibra " + str(f.ent))
	var t := A.receta2("art2:espada:hierro:reforzada:0:sin:grueso")
	ok(t.ent.size() == 1, "D1: la técnica reforzada no añade insumos en art2: " + str(t.ent))
	var a1 := A.receta("art1:espada:hierro:reforzada:0")
	ok(a1.ent == {"lingote": 2, "piedra": 1}, "art1 intacto: la técnica reforzada sigue añadiendo su piedra " + str(a1.ent))
	var i := A.info2("art2:espada:hierro:simple:0:piedra:grueso")
	ok(i.dmg > A.info("art1:espada:hierro:simple:0").dmg and i.vel < A.info("art1:espada:hierro:simple:0").vel and "refuerzo de piedra" in i.n, "info: ventaja de daño con penalización de velocidad y nombre legible " + str(i.n))
	ok(not A.visible2("art2:espada:hierro:simple:0:piedra:grueso").is_empty() and A.visible2("art2:nada").is_empty(), "visible: reutiliza la geometría del material")

func _rendimiento() -> void:
	var claves := A.enumerar2()
	var n := 2000
	var t0 := Time.get_ticks_usec()
	for j in n: A.info2(claves[j % claves.size()])
	var info_us := float(Time.get_ticks_usec() - t0) / n
	t0 = Time.get_ticks_usec()
	for j in n: A.receta2(claves[j % claves.size()])
	var receta_us := float(Time.get_ticks_usec() - t0) / n
	print("MEDIDA tiempo_info2_us = %.1f; tiempo_receta2_us = %.1f" % [info_us, receta_us])
	ok(info_us < 300.0 and receta_us < 600.0, "rendimiento: info2 y receta2 por llamada dentro del umbral (300 y 600 µs)")
