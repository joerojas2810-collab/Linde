extends SceneTree
## I1a E2: variantes art2: (operadores refuerzo y grosor). Presupuesto antes y después del redondeo, contrapartidas,
## dominancia (continua y con estadísticas enteras y consumos reales), claves canónicas y su longitud.
## Uso:  Godot --headless --path Linde/cenital --script res://tests/prueba_operadores.gd [-- --informe]
const A = preload("res://scripts/artesania.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
const Eq = preload("res://scripts/equipo.gd")
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const TMP := "user://prueba_operadores.json"
const E := 0.000000001
## REGISTROS medidos con los coeficientes iniciales de I1a (2026-10-25); no son objetivos. Si cambian, o es un cambio deliberado
## de coeficientes (actualizar y documentar en ESTADO.md) o una regresión.
## Pares (v > w) en que v tiene estadísticas enteras ≥ y consume ≤ insumo por insumo: casi siempre la pieza art1: frente a una
## variante cuya ventaja se pierde al redondear (se comparan consumos reales; no se equipara un material con otro).
const DOMINANCIAS_ENTERAS := 1646
## Variantes con ventaja nominal de potencia y ninguna estadística entera (dmg/def/hp) por encima de la pieza sin operadores.
const VENTAJAS_PERDIDAS := 631
## Clasificación de las variantes frente a la pieza sin operadores (ver _clasificacion).
const CLASES := {"mejora_entera": 497, "equivalente": 0, "dominada": 675, "contrapartida": 520}
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
	_clasificacion(informe)
	_integracion()
	_saberes_operadores()
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

## Diagnóstico del redondeo (E3). Cada variante frente a la pieza sin operadores (la art1: equivalente), con estadísticas
## finales enteras, velocidad e insumos reales. No se oculta ni se elimina nada; esto solo distingue:
##  mejora_entera: algún dmg/def/hp entero supera al de la pieza sin operadores.
##  equivalente: mismas estadísticas enteras, misma velocidad y mismos insumos (alias mecánico efectivo).
##  dominada: sin mejora entera y otra pieza del grupo es ≥ en todo y consume ≤ insumo por insumo.
##  contrapartida: sin mejora entera de potencia, no dominada: difiere en velocidad o insumos (puede tener valor por ello).
func _clasificacion(informe: bool) -> void:
	var cuenta := {"mejora_entera": 0, "equivalente": 0, "dominada": 0, "contrapartida": 0}
	var por_forma := {}
	var cuenta_dominadas_con_mejora := 0
	for g in _grupos(true).values():
		var base: Dictionary = g[0]
		for i in range(1, g.size()):
			var v: Dictionary = g[i]
			var domin := false
			for w in g: if w.clave != v.clave and _domina(w, v): domin = true
			var sube := false
			var igual_pot := true
			for st in v.est:
				if st == "vel": continue
				if v.est[st] > base.est[st] + E: sube = true
				if absf(v.est[st] - base.est[st]) > E: igual_pot = false
			var cat := "mejora_entera"
			if not sube:
				if igual_pot and absf(v.est.vel - base.est.vel) < E and v.ent == base.ent: cat = "equivalente"
				elif domin: cat = "dominada"
				else: cat = "contrapartida"
			elif domin: cuenta_dominadas_con_mejora += 1
			cuenta[cat] += 1
			var forma: String = v.clave.get_slice(":", 1)
			por_forma[forma + " " + cat] = int(por_forma.get(forma + " " + cat, 0)) + 1
	print("MEDIDA clasificacion = ", JSON.stringify(cuenta, "", true), "; con_mejora_entera_pero_dominadas = ", cuenta_dominadas_con_mejora)
	if informe: print("MEDIDA clasificacion_por_forma = ", JSON.stringify(por_forma, "", true))
	var suma := 0
	for c in cuenta: suma += int(cuenta[c])
	ok(suma == A.enumerar2().size(), "clasificación: cada variante cae en una categoría (%d)" % suma)
	ok(cuenta == CLASES, "clasificación registrada: %s (si cambia: coeficientes o registro)" % JSON.stringify(cuenta))

func _integracion() -> void:
	var k := "art2:espada:hierro:simple:0:piedra:grueso"
	var t := "art2:torso:hierro:simple:0:fibra:grueso"
	# Equipo: art2 pasa por los mismos contratos y art1 queda idéntico.
	var distinto1: Array = []
	for k1 in _claves1():
		if Eq.info(k1) != A.info(k1) or not Eq.existe(k1) or Eq.visible({"arma": k1}) != [A.visible(k1)]: distinto1.append(k1)
	ok(distinto1.is_empty(), "equipo: las %d piezas art1: siguen dando el mismo existe/info/visible " % _claves1().size() + str(distinto1.slice(0, 3)))
	ok(Eq.existe(k) and Eq.info(k) == A.info2(k) and Eq.visible({"arma": k}) == [A.visible2(k)], "equipo: existe/info/visible reconocen art2")
	ok(not Eq.existe("art2:espada:hierro:simple:03:piedra:grueso") and Eq.info("art2:espada:hierro:simple:03:piedra:grueso").get("desconocida", false), "equipo: una art2 no canónica es «Pieza desconocida»")
	ok(Eq.info("madera") == Eq.C.ITEMS["madera"], "equipo: los ítems comunes no cambian")
	# Juego: equipar, estadísticas, guardado y carga.
	var j = J.nueva(5, "Prueba", [0, 0, 0])
	var pj: Dictionary = j.jug()
	var sin_equipo: Dictionary = j.stats()
	pj.inv[k] = 1
	pj.inv[t] = 1
	ok(j.equipar(k).ok and pj.equipo.arma == k and not pj.inv.has(k), "juego: se equipa una espada art2")
	ok(j.stats().dmg == sin_equipo.dmg + int(A.info2(k).dmg), "juego: el daño de la espada art2 es el calculado por el evaluador (+%d)" % int(A.info2(k).dmg))
	ok(j.equipar(t).ok and pj.equipo.torso == t, "juego: se equipa un torso art2")
	var st: Dictionary = j.stats()
	ok(st.hp > sin_equipo.hp and st.def > sin_equipo.def, "juego: el torso art2 aporta defensa y vida (hp %d→%d, def %d→%d)" % [sin_equipo.hp, st.hp, sin_equipo.def, st.def])
	var j_antes: Dictionary = {"dmg": st.dmg, "hp": st.hp, "def": st.def, "vel": st.vel}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	ok(j.guardar(TMP), "persistencia: se guarda un mundo con piezas art2 equipadas")
	var c = J.cargar(TMP)
	ok(c != null and c.jug().equipo.arma == k and c.jug().equipo.torso == t and c.jug().pendientes.is_empty(), "persistencia: tras cargar siguen equipadas y no pasan a pendientes")
	ok(c != null and {"dmg": c.stats().dmg, "hp": c.stats().hp, "def": c.stats().def, "vel": c.stats().vel} == j_antes, "persistencia: las estadísticas tras cargar son idénticas")
	var texto := FileAccess.get_file_as_string(TMP)
	ok(k in texto and not "refuerzo de piedra" in texto, "persistencia: el guardado conserva solo la clave, no el nombre ni las estadísticas")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	# Fabricar y comprar siguen cerrados hasta que existan los saberes op: (E4): la clave art2 no se concede por la vía actual.
	var d = j.autonomia.desarrollo
	var inv_antes: Dictionary = pj.inv.duplicate()
	var f: Dictionary = d.fabricar("art2:espada:hierro:simple:0:piedra:grueso", J.LOCAL)
	ok(not f.ok and "Aún no conoces" in str(f.get("msg", f)) and not d.conoce(j.actor_desarrollo(), k) and pj.inv == inv_antes, "E4 pendiente: desarrollo.fabricar rechaza art2 sin tocar el inventario " + str(f))
	# Servidor: validación de claves y pedidos.
	var srv = Srv.new()
	srv.j = j
	ok(Srv._clave_valida("equipar", k) and Srv._lote({k: 1}) and not Srv._lote({"art2:espada:hierro:simple:03:piedra:grueso": 1}), "red: el servidor acepta claves art2 canónicas en equipar y en lotes, y rechaza las demás")
	var larga := k + ":" + "x".repeat(60)
	ok(not Srv._lote({larga: 1}) and not Srv._clave_valida("equipar", larga), "red: una clave art2 más larga que el límite no pasa")
	pj.inv[k] = 1
	ok(srv.ejecutar(J.LOCAL, ["equipar", 1, "art2:espada:hierro:simple:03:piedra:grueso"]) == false, "red: equipar con una clave no canónica se rechaza")
	ok(srv.ejecutar(J.LOCAL, ["equipar", 2, k]) == true and pj.equipo.arma == k, "red: equipar una art2 canónica por pedido")
	ok(srv.ejecutar(J.LOCAL, ["equipar", 3, "art2:espada:hierro:simple:0:piedra:grueso:dmg=99"]) == false, "red: un cliente no puede añadir parámetros a la clave")
	# Recepción: serialización por la red (var_to_bytes) y réplica del cliente.
	var e = bytes_to_var(var_to_bytes(srv.estado_para(J.LOCAL)))
	var cli = Cli.new()
	cli._bienvenida(e)
	var r = cli.j
	ok(r != null and r.jug().equipo.arma == k and Eq.info(r.jug().equipo.arma) == A.info2(k), "recepción: la réplica del cliente recibe la pieza y calcula la misma info")
	ok(r != null and r.stats().dmg == j.stats().dmg and r.stats().hp == j.stats().hp and r.stats().def == j.stats().def, "recepción: la réplica calcula las mismas estadísticas que el servidor")
	cli.free()
	srv.free()
	# Sociedad: una pieza art2 vale los insumos pagados por ella.
	var soc = j.autonomia.sociedad
	var valor: float = soc._valor_lote({k: 1})
	ok(valor > 0.0 and is_equal_approx(valor, soc._valor_lote(A.receta2(k).ent)), "sociedad: el valor de una pieza art2 es el de sus insumos (%.1f)" % valor)

func _claves1() -> Array:
	var lista: Array = []
	var r := A.reglas()
	for f in r.formas:
		for m in r.materiales.keys() + A.combinaciones():
			for tc in r.tecnicas:
				for q in int(r.calidad_max) + 1:
					var k := A.clave(f, m, tc, q)
					if not A.leer(k).is_empty(): lista.append(k)
	return lista

## E4 (contrato D5 en PLAN_MAESTRO): saberes op:, material visto, individualidad, enseñanza, guardado y réplica.
func _nuevo():
	var j = J.nueva(123, "Explorador", [0, 0, 0])
	j.combate.enemigos.clear()
	j.autonomia.activar()
	return j

func _saberes_operadores() -> void:
	var j = _nuevo()
	var d = j.autonomia.desarrollo
	var yo: String = j.actor_desarrollo()
	var k := "art2:espada:hierro:simple:0:piedra:grueso"      # exige op:refuerzo y op:grosor
	var k_ref := "art2:espada:hierro:simple:0:piedra:normal"  # solo op:refuerzo
	var k_gro := "art2:espada:hierro:simple:0:sin:grueso"     # solo op:grosor
	ok(d.validar_saberes().is_empty() and d.catalogo().has("op:refuerzo") and d.catalogo().has("op:grosor") and d.catalogo()["op:refuerzo"].tipo == "op", "catálogo: existen op:refuerzo y op:grosor y el catálogo es válido " + str(d.validar_saberes()))
	# saberes_exigidos: exactamente un op: por operador con nivel no predeterminado, en las 1.692 variantes; ninguno en art1.
	var mal: Array = []
	for c in A.enumerar2():
		var p := A.leer2(c)
		var esperado: Array = []
		if p.refuerzo != "sin": esperado.append("op:refuerzo")
		if p.grosor != "normal": esperado.append("op:grosor")
		var obtenido: Array = d.saberes_exigidos(p).filter(func(id): return id.begins_with("op:"))
		obtenido.sort()
		esperado.sort()
		if obtenido != esperado or esperado.is_empty(): mal.append(c)
	ok(mal.is_empty(), "D5: cada variante exige un op: por operador no predeterminado (y al menos uno) " + str(mal.slice(0, 3)))
	ok(d.saberes_exigidos(A.leer("art1:espada:hierro:simple:0")).is_empty() and d.saberes_exigidos(A.leer("art1:espada:hierro:ligera:0")) == ["tec:ligera"], "D5: art1 no exige ningún op:")
	ok(d.valido(k) and d.valido("art1:espada:hierro:simple:0") and not d.valido("art2:espada:hierro:simple:0:sin:normal"), "valido: reconoce art1 y art2, no las no canónicas")
	# sabe: sin saberes de operador no se puede; cada operador abre solo lo suyo.
	ok(not d.sabe(yo, k) and not d.sabe(yo, k_ref) and not d.sabe(yo, k_gro), "sabe: el jugador nuevo no sabe usar ningún operador")
	ok(d.aprender(yo, "op:refuerzo", "prueba") and d.sabe(yo, k_ref) and not d.sabe(yo, k_gro) and not d.sabe(yo, k), "sabe: op:refuerzo abre el refuerzo pero no el grosor ni la combinación")
	ok(d.aprender(yo, "op:grosor", "prueba") and d.sabe(yo, k_gro) and d.sabe(yo, k), "sabe: con ambos operadores se conoce la combinación (sin aprender cada variante)")
	# Individualidad: lo suyo no pasa a otros actores.
	d.sembrar("npc:nerea")
	ok(d.sabe("npc:maren", k) and not d.sabe("npc:nerea", k_ref) and not d.sabe("npc:ordal", k_gro) and d.sabe("npc:ordal", k_ref), "individual: Maren sabe ambos, Ordal solo el refuerzo y Nerea ninguno")
	var bea: Dictionary = j.unir("@bea", "Bea", [0, 0, 0])
	var actor_bea: String = j.actor_desarrollo("@bea")
	ok(bea.ok and actor_bea != yo and not d.sabe(actor_bea, k_ref), "individual: otro jugador no hereda lo que sabe el primero")
	# puede: material base y material de refuerzo vistos; los operadores no conceden materiales.
	ok(d.estado(yo).materiales.is_empty() and not d.puede(yo, k) and not d.puede(yo, k_gro), "puede: sin materiales vistos no se puede aunque se conozcan los operadores")
	d.observar(yo, {"lingote": 1})
	ok(d.puede(yo, k_gro) and not d.puede(yo, k_ref) and not d.puede(yo, k) and not d.conoce(yo, k), "puede: con el hierro visto se puede el grosor, pero reforzar con piedra pide haber visto la piedra")
	d.observar(yo, {"piedra": 1})
	ok(d.puede(yo, k) and d.conoce(yo, k) and d.conoce(yo, k_ref), "puede: con base y refuerzo vistos se conoce la combinación")
	d.observar(actor_bea, {"lingote": 1, "piedra": 1})
	ok(d.puede(actor_bea, k) and not d.sabe(actor_bea, k) and not d.conoce(actor_bea, k), "puede y sabe son independientes: ver los materiales no da el saber")
	# art1 intacto: una pieza art1 se conoce igual que antes.
	ok(d.conoce(yo, "art1:espada:hierro:simple:0") and d.sabe(actor_bea, "art1:espada:hierro:simple:0"), "art1: sigue sin exigir operadores")
	# Enseñanza: el rango mínimo es el único prerrequisito; nunca el material.
	var aprendiz: String = j.actor_desarrollo("@bea")
	ok(d._motivo_no_ensena("npc:maren", aprendiz, "op:refuerzo") == "Aún no está preparado para aprenderlo" and not d.prerrequisitos_ok(aprendiz, "op:refuerzo"), "enseñanza: sin el rango mínimo de artesanía no se aprende un operador")
	d.estado(aprendiz).practica["artesania"] = int(A.reglas().practica_por_rango) * int(d.catalogo()["op:refuerzo"].rango_min)
	var materiales_antes: Dictionary = d.estado(aprendiz).materiales.duplicate()
	ok(d._motivo_no_ensena("npc:maren", aprendiz, "op:refuerzo") == "" and d.aprender(aprendiz, "op:refuerzo", "ensenanza", "npc:maren"), "enseñanza: con el rango mínimo Maren le enseña op:refuerzo")
	ok(d.estado(aprendiz).materiales == materiales_antes and d.tiene_saber(aprendiz, "op:refuerzo") and not d.tiene_saber(aprendiz, "op:grosor"), "enseñanza: aprender un operador no concede materiales ni otros saberes")
	ok(d._motivo_no_ensena("npc:nerea", aprendiz, "op:grosor") == "No conoce ese saber", "enseñanza: nadie enseña un operador que no sabe")
	var ops_candidatos: Callable = func(actor: String) -> Array: return d.candidatos(actor).filter(func(id): return id.begins_with("op:"))
	ok(ops_candidatos.call("npc:nerea") == [], "enseñanza: sin rango suficiente los operadores no son candidatos")
	# Fabricación real junto a una mesa: consumo exacto de la receta y registro del saber en la autoridad.
	j.pies = M.pies_de_celda(Vector2i(28, 21))
	j.jug().inv.piedra = 5
	j.jug().inv.madera = 20
	ok(j.construir("mesa", Vector2i(29, 20)).ok, "fabricar: se construye la mesa de prueba")
	j.jug().inv.lingote = 4
	j.jug().inv.piedra = 2
	var antes: Dictionary = j.jug().inv.duplicate()
	var r: Dictionary = j.fabricar_artefacto(k)
	ok(r.ok and j.jug().inv.get(k, 0) == 1 and j.jug().inv.lingote == antes.lingote - 3 and j.jug().inv.get("piedra", 0) == antes.piedra - 2, "fabricar: la variante consume exactamente su receta (3 lingotes, 2 piedras) " + str(r))
	var dd: Dictionary = j.autonomia.desarrollo.datos()
	ok(dd.creaciones.size() >= 1 and str(dd.creaciones[dd.creaciones.size() - 1].pieza) == k, "fabricar: la creación queda registrada")
	var otro_k := "art2:espada:cobre:simple:0:piedra:normal"
	var inv_antes: Dictionary = j.jug().inv.duplicate()
	ok(not j.fabricar_artefacto(otro_k).ok and j.jug().inv == inv_antes, "fabricar: sin ver el cobre no se fabrica y no se pierde nada")
	var k_fino := "art2:espada:hierro:simple:0:sin:fino"
	d.estado(yo).saber.erase("op:grosor")
	ok(not j.fabricar_artefacto(k_fino).ok and j.jug().inv == inv_antes, "fabricar: sin op:grosor no se fabrica una variante fina")
	d.aprender(yo, "op:grosor", "prueba")
	# Servidor y red: un cliente no puede saltarse el saber.
	var srv = Srv.new()
	srv.j = j
	d.estado(yo).saber.erase("op:refuerzo")
	var inv2: Dictionary = j.jug().inv.duplicate()
	ok(srv.ejecutar(J.LOCAL, ["fabricar_artefacto", 1, k_ref]) and j.jug().inv == inv2, "red: pedir una variante sin el saber op: no fabrica ni consume (el servidor decide)")
	d.aprender(yo, "op:refuerzo", "prueba")
	# Guardado y carga: los saberes de operador persisten por actor.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	ok(j.guardar(TMP), "persistencia: se guarda con saberes de operador")
	var c = J.cargar(TMP)
	var dc = c.autonomia.desarrollo
	ok(c != null and dc.tiene_saber(yo, "op:refuerzo") and dc.tiene_saber(yo, "op:grosor") and dc.sabe(yo, k) and dc.tiene_saber(aprendiz, "op:refuerzo") and not dc.tiene_saber(aprendiz, "op:grosor"), "persistencia: cada actor conserva sus operadores tras cargar")
	# Réplica: el cliente consulta los mismos saberes sin escribir.
	var cli = Cli.new()
	cli._bienvenida(srv.estado_para(J.LOCAL))
	var dr = cli.j.autonomia.desarrollo
	ok(dr.sabe(cli.j.actor_desarrollo(), k) == d.sabe(yo, k) and dr.conoce(cli.j.actor_desarrollo(), k) == d.conoce(yo, k) and dr.tiene_saber("npc:maren", "op:grosor"), "recepción: la réplica calcula el mismo sabe/conoce y ve los saberes de operador de los habitantes")
	cli.free()
	srv.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
