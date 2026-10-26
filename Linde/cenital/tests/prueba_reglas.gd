extends SceneTree
## H0 (PLAN_MAESTRO §10): huella de reglas, versión del evaluador, guardado/carga e incompatibilidad.
## Uso:  Godot --headless --log-file <ruta> --path Linde/cenital --script res://tests/prueba_reglas.gd
## Regenerar el dorado (solo tras un cambio deliberado, con commit que lo explique):  ... -- --generar-dorado
const A = preload("res://scripts/artesania.gd")
const H = preload("res://scripts/huella.gd")
const G = preload("res://scripts/guardado.gd")
const J = preload("res://scripts/juego.gd")
const RUTA_DORADO := "res://tests/dorados/artesania_v1.json"
const Srv = preload("res://scripts/red_servidor.gd")
const TMP := "user://prueba_reglas.json"
## Lo que M0 NO debe cambiar (capturado con el código de H0 antes de tocar nada): recetas y todo `info()` salvo dmg/def/hp.
const INVARIANTES_PRE_M0 := {"claves": 693, "recetas": "4df6b2a359c474565bcda98553d5d218421f960faccc946289f9f1643831cd46",
	"info_sin_estadisticas": "189d2ebc3d5f8f271a6670f160df656f13639e445e80050820ba91c6cc1d26a5"}
## Potencia y velocidad por material antes de M0 (el número exacto ES el objeto de la prueba).
const PREVIO_M0 := {"madera": [0.65, 0.01], "piedra": [0.80, -0.02], "fibra": [0.65, 0.02], "hierro": [1.20, -0.01],
	"cobre": [1.00, 0.0], "bronce": [1.35, -0.01]}
## Dominancias entre materiales de la gramática, tal como las produce el modelo actual. Es un REGISTRO, no un objetivo:
## si cambia, o es un cambio deliberado de reglas (actualizar esta lista y documentarlo) o una regresión.
const DOMINANCIAS_CONOCIDAS: Array = [
	"botas:bronce>hierro",
	"casco:bronce>hierro",
	"escudo:bronce>hierro",
	"escudo:bronce>piedra",
	"escudo:cobre>piedra",
	"escudo:hierro>piedra",
	"escudo:madera>piedra",
	"espada:bronce>hierro",
	"espada:bronce>piedra",
	"espada:cobre>piedra",
	"espada:hierro>piedra",
	"guantes:bronce>hierro",
	"pantalones:bronce>hierro",
	"torso:bronce>hierro"]
const EXCLUIDOS := ["res://datos/lugares/generacion_v1.json", # Génesis versionada del mundo: resultados persistidos por autoridad, fuera de la huella de fabricación.
	"res://datos/pistas.json", # Solo textos, condiciones de ayuda y tiempos de presentación; no decide resultados del mundo.
	"res://datos/equipo/paletas.json"]   # solo color; datos/mundo es narrativa del director
var fallos := 0
var total := 0

func ok(c: bool, texto: String) -> void:
	total += 1
	print(("PASS " if c else "FAIL ") + texto)
	if not c: fallos += 1

func _init() -> void:
	if "--generar-dorado" in OS.get_cmdline_user_args():
		_generar_dorado()
		quit(0)
		return
	if "--imprimir-dominancia" in OS.get_cmdline_user_args():
		for linea in _informe_dominancia().detalle: print("DOMINANCIA ", linea)
		print("DOMINANCIAS: ", JSON.stringify(_informe_dominancia().claves))
		quit(0)
		return
	if "--imprimir-tabla" in OS.get_cmdline_user_args():
		_tabla()
		quit(0)
		return
	if "--imprimir-invariantes" in OS.get_cmdline_user_args():
		print("INVARIANTES: ", JSON.stringify(_invariantes()))
		quit(0)
		return
	_canonico()
	_huella()
	_dorado()
	_m0()
	_guardado()
	_excepcion()
	_mundo_vivo()
	_limpiar()
	print("REGLAS: %d comprobaciones, %d fallos" % [total, fallos])
	quit(1 if fallos else 0)

# ---------- canónico ----------
func _canonico() -> void:
	ok(H.canonico({"b": 1, "a": [1.0, 2]}) == H.canonico({"a": [1, 2.0], "b": 1.0}), "canónico: orden de claves y 1 frente a 1.0 no importan")
	ok(H.canonico([1, 2]) != H.canonico([2, 1]), "canónico: el orden de un arreglo sí importa")
	ok(H.canonico(0.1 + 0.2) == H.canonico(0.3), "canónico: el ruido de coma flotante no cambia el texto")
	ok(H.canonico("1") != H.canonico(1) and H.canonico({"a": 1}) != H.canonico({"a": 2}), "canónico: distingue texto de número y valores distintos")
	ok(H.canonico(Vector2(1, 2)).begins_with("~"), "canónico: un tipo no previsto queda visible en vez de ignorarse")
	var d1 := {}
	var d2 := {}
	for i in 40: d1["k%d" % i] = {"v": i, "w": [i, i * 2]}
	for i in range(39, -1, -1): d2["k%d" % i] = {"w": [i, i * 2], "v": i}
	ok(H.hash_de(d1) == H.hash_de(d2), "canónico: dos diccionarios con distinto orden de inserción dan el mismo hash")

# ---------- huella ----------
func _huella() -> void:
	var h := H.huella()
	ok(h.length() == 64 and h.is_valid_hex_number(), "huella: SHA-256 hexadecimal")
	H.reiniciar()
	ok(H.huella() == h, "huella: determinista tras recalcular desde los archivos")
	var comp := H.componentes()
	var esperados: Array = H.COMPONENTES.keys() + ["catalogos", "evaluador"]
	esperados.sort()
	var obtenidos: Array = comp.keys()
	obtenidos.sort()
	ok(obtenidos == esperados, "huella: componentes " + ", ".join(PackedStringArray(esperados)))
	ok(H.constantes_faltantes().is_empty(), "huella: todas las constantes de catalogos.gd listadas existen " + str(H.constantes_faltantes()))
	ok(H.versiones().evaluador == A.EVALUADOR_VERSION and int(H.versiones().get("desarrollo/reglas_v1", 0)) == int(A.reglas().version) and H.versiones().has("fauna/reglas_v1") and H.versiones().has("asentamientos/reglas_v1"), "huella: versiones legibles (evaluador y reglas de desarrollo)")
	for id in comp:
		var alterado := comp.duplicate()
		alterado[id] = "x"
		ok(H.total(alterado) != h, "huella: cambia si cambia el componente " + id)
	var alterado := comp.duplicate()
	alterado["evaluador"] = H.hash_de(A.EVALUADOR_VERSION + 1)
	ok(H.total(alterado) != h, "huella: subir EVALUADOR_VERSION cambia la huella aunque los JSON no cambien")
	var reglas: Dictionary = A.reglas().duplicate(true)
	ok(H.hash_de(reglas) == H.hash_de(A.reglas()), "huella: una copia profunda de las reglas conserva el hash")
	reglas.materiales.hierro.dureza = float(reglas.materiales.hierro.dureza) + 0.01
	ok(H.hash_de(reglas) != H.hash_de(A.reglas()), "huella: un cambio de balance en un material cambia el hash")
	var items: Dictionary = H.constantes().duplicate(true)
	items.RECETAS.lingote.ent.mena = 3
	ok(H.hash_de(items) != H.hash_de(H.constantes()), "huella: un cambio de receta en catalogos.gd cambia el hash")
	# Cobertura: todo JSON de reglas bajo datos/ está listado o excluido a propósito; un archivo nuevo obliga a clasificarlo.
	var listados: Array = []
	for id in H.COMPONENTES: listados.append_array(H.COMPONENTES[id])
	var sin_clasificar: Array = []
	for ruta in _jsons("res://datos"):
		if ruta.begins_with("res://datos/mundo/") or ruta in EXCLUIDOS or ruta in listados: continue
		sin_clasificar.append(ruta)
	ok(sin_clasificar.is_empty(), "huella: ningún JSON de reglas queda sin clasificar " + str(sin_clasificar))
	var ausentes: Array = listados.filter(func(r): return not FileAccess.file_exists(r) and not r.ends_with("saberes_v1.json"))
	ok(ausentes.is_empty(), "huella: los archivos listados existen " + str(ausentes))

func _jsons(dir: String) -> Array:
	var r: Array = []
	for f in DirAccess.get_files_at(dir): if f.ends_with(".json"): r.append(dir.path_join(f))
	for sub in DirAccess.get_directories_at(dir): r.append_array(_jsons(dir.path_join(sub)))
	return r

# ---------- dorado de la gramática de fabricación ----------
func _enumerar() -> Array:
	var r := A.reglas()
	var materiales: Array = r.materiales.keys() + A.combinaciones()
	materiales.sort()
	var formas: Array = r.formas.keys()
	formas.sort()
	var tecnicas: Array = r.tecnicas.keys()
	tecnicas.sort()
	var lista: Array = []
	for f in formas:
		for m in materiales:
			for t in tecnicas:
				for q in int(r.calidad_max) + 1:
					var k := A.clave(f, m, t, q)
					if A.leer(k).is_empty(): continue
					lista.append({"clave": k, "info": A.info(k), "receta": A.receta(k)})
	for m in A.combinaciones():
		lista.append({"clave": "mat1:" + m, "info": A.info("mat1:" + m), "receta": A.receta_material(m)})
	return lista

## Informe legible: estadísticas de cada forma con cada material (técnica sencilla, calidades 0 y 3).
func _tabla() -> void:
	var r := A.reglas()
	var formas: Array = r.formas.keys()
	for f in formas:
		for q in [0, 3]:
			var fila: PackedStringArray = []
			for m in ["madera", "piedra", "fibra", "cobre", "hierro", "bronce"]:
				var k := A.clave(f, m, "simple", q)
				if A.leer(k).is_empty(): continue
				var i := A.info(k)
				fila.append("%s d%d/D%d/h%d/v%+.3f" % [m, i.dmg, i.def, i.hp, i.vel])
			print("TABLA %s q%d: %s" % [f, q, " | ".join(fila)])

## Lo que M0 no debe cambiar: recetas y todo lo de `info()` salvo dmg/def/hp (nombre, ranura, color, pila, velocidad...).
func _invariantes() -> Dictionary:
	var lista := _enumerar()
	var recetas: Array = []
	var resto: Array = []
	for e in lista:
		recetas.append({"clave": e.clave, "receta": e.receta})
		var info: Dictionary = e.info.duplicate(true)
		for k in ["dmg", "def", "hp"]: info.erase(k)
		resto.append({"clave": e.clave, "info": info})
	return {"claves": lista.size(), "recetas": H.hash_de(recetas), "info_sin_estadisticas": H.hash_de(resto)}

func _generar_dorado() -> void:
	var lista := _enumerar()
	var muestra: Array = []
	for i in lista.size():
		if i % 25 == 0 or str(lista[i].clave).begins_with("mat1:"): muestra.append(lista[i])
	var l2: Array = []
	for k in A.enumerar2(): l2.append({"clave": k, "info": A.info2(k), "receta": A.receta2(k)})
	var m2: Array = []
	for i in l2.size(): if i % 50 == 0: m2.append(l2[i])
	var dorado := {"_nota": "Instantánea del comportamiento de artesania.gd. Regenerar solo tras un cambio deliberado: subir EVALUADOR_VERSION o la version de reglas_v1.json según corresponda y explicarlo en el commit.",
		"evaluador": A.EVALUADOR_VERSION, "reglas_desarrollo": A.reglas().version, "total": lista.size(), "hash": H.hash_de(lista), "muestra": muestra,
		"art2": {"total": l2.size(), "hash": H.hash_de(l2), "muestra": m2}}
	var f := FileAccess.open(RUTA_DORADO, FileAccess.WRITE)
	f.store_string(JSON.stringify(dorado, "\t", true))
	f.close()
	print("DORADO: %d claves, hash %s" % [lista.size(), dorado.hash])

func _dorado() -> void:
	var lista := _enumerar()
	ok(H.hash_de(lista) == H.hash_de(_enumerar()), "dorado: la enumeración es reproducible dentro de la misma ejecución")
	var dor = JSON.parse_string(FileAccess.get_file_as_string(RUTA_DORADO))
	ok(typeof(dor) == TYPE_DICTIONARY, "dorado: archivo legible")
	if typeof(dor) != TYPE_DICTIONARY: return
	var meta := int(dor.evaluador) == A.EVALUADOR_VERSION and int(dor.reglas_desarrollo) == int(A.reglas().version)
	ok(meta, "dorado: EVALUADOR_VERSION y version de reglas coinciden con el dorado (si no: regenerar con --generar-dorado y explicarlo)")
	var mismo := int(dor.total) == lista.size() and str(dor.hash) == H.hash_de(lista)
	ok(mismo, "dorado: las %d claves de fabricación dan los mismos resultados" % lista.size() + ("" if mismo or not meta else " ¡CAMBIÓ EL COMPORTAMIENTO SIN SUBIR EVALUADOR_VERSION NI version!"))
	var l2: Array = []
	for k in A.enumerar2(): l2.append({"clave": k, "info": A.info2(k), "receta": A.receta2(k)})
	var a2: Dictionary = dor.get("art2", {})
	var igual2 := int(a2.get("total", -1)) == l2.size() and str(a2.get("hash", "")) == H.hash_de(l2)
	ok(igual2, "dorado art2: las %d variantes dan los mismos resultados" % l2.size() + ("" if igual2 or not meta else " ¡CAMBIÓ EL COMPORTAMIENTO SIN SUBIR EVALUADOR_VERSION NI version!"))
	var por_clave2 := {}
	for e in l2: por_clave2[e.clave] = e
	var dif2: Array = []
	for e in a2.get("muestra", []):
		var act = por_clave2.get(e.clave)
		if act == null or H.canonico(e.info) != H.canonico(act.info) or H.canonico(e.receta) != H.canonico(act.receta): dif2.append(e.clave)
	ok(dif2.is_empty() and not a2.get("muestra", []).is_empty(), "dorado art2: muestra revisable por personas coincide " + str(dif2.slice(0, 5)))
	var por_clave := {}
	for e in lista: por_clave[e.clave] = e
	var diferentes: Array = []
	for e in dor.muestra:
		var actual = por_clave.get(e.clave)
		if actual == null or H.canonico(e.info) != H.canonico(actual.info) or H.canonico(e.receta) != H.canonico(actual.receta): diferentes.append(e.clave)
	ok(diferentes.is_empty(), "dorado: muestra revisable por personas coincide " + str(diferentes.slice(0, 5)))

# ---------- M0: propiedades físicas y pesos por forma ----------
const MATERIALES_BASE := ["madera", "piedra", "fibra", "hierro", "cobre", "bronce"]
const NEUTROS := {"dureza": 0.5, "tenacidad": 0.5}

## Para cada forma y cada par de materiales que la admiten: ¿uno es al menos igual al otro en eficacia y velocidad y
## mejor en alguna? Se compara con valores continuos (sin redondear) y la técnica sencilla.
func _informe_dominancia() -> Dictionary:
	var r := A.reglas()
	var claves: Array = []
	var detalle: Array = []
	var formas: Array = r.formas.keys()
	formas.sort()
	for f in formas:
		var pesos: Dictionary = r.formas[f].pesos
		var ms: Array = MATERIALES_BASE.filter(func(m): return f in r.materiales[m].formas)
		for a in ms:
			for b in ms:
				if a == b: continue
				var ea := A.eficacia(r.materiales[a], pesos)
				var eb := A.eficacia(r.materiales[b], pesos)
				var va := A.velocidad(r.materiales[a])
				var vb := A.velocidad(r.materiales[b])
				var e := 0.000000001
				if ea >= eb - e and va >= vb - e and (ea > eb + e or va > vb + e):
					claves.append("%s:%s>%s" % [f, a, b])
					detalle.append("%s: %s domina a %s (eficacia %.3f/%.3f, vel %+.3f/%+.3f, coste %d/%d)" % [f, a, b, ea, eb, va, vb, int(r.materiales[a].coste), int(r.materiales[b].coste)])
	claves.sort()
	return {"claves": claves, "detalle": detalle}

func _m0() -> void:
	var r := A.reglas()
	ok(A.validar().is_empty(), "M0: reglas válidas (propiedades positivas, pesos por forma que suman 1) " + str(A.validar()))
	ok(int(r.version) >= 2 and A.EVALUADOR_VERSION >= 2, "M0: version de reglas y EVALUADOR_VERSION subidas al menos a 2 (I1a las subió a 3)")
	# Continuidad: con pesos neutros las propiedades reproducen la potencia y la velocidad anteriores.
	var continuidad := true
	for m in MATERIALES_BASE:
		var mat: Dictionary = r.materiales[m]
		continuidad = continuidad and absf(A.eficacia(mat, NEUTROS) - float(PREVIO_M0[m][0])) < 0.000001 and absf(A.velocidad(mat) - float(PREVIO_M0[m][1])) < 0.000001
	ok(continuidad, "M0: con pesos 0.5/0.5 cada material reproduce su potencia y velocidad de antes")
	var laminados_ok := true
	var peso: float = r.laminados.peso_nucleo
	for id in A.combinaciones():
		var p: PackedStringArray = str(id).split("_")
		var lam: Dictionary = A.material(id)
		var pot := float(PREVIO_M0[p[0]][0]) * peso + float(PREVIO_M0[p[1]][0]) * (1.0 - peso)
		var vel := (float(PREVIO_M0[p[0]][1]) + float(PREVIO_M0[p[1]][1])) / 2.0
		laminados_ok = laminados_ok and absf(A.eficacia(lam, NEUTROS) - pot) < 0.000001 and absf(A.velocidad(lam) - vel) < 0.000001
	ok(laminados_ok and A.combinaciones().size() == 9, "M0: los 9 laminados se conservan y reproducen su potencia y velocidad de antes con pesos neutros")
	# Lo único que puede cambiar es dmg/def/hp: recetas, nombres, ranuras, colores, pilas y velocidades quedan idénticos.
	var inv := _invariantes()
	ok(inv.claves == INVARIANTES_PRE_M0.claves and inv.recetas == INVARIANTES_PRE_M0.recetas, "M0: ninguna receta ni coste cambió (cambio deliberado frente a regresión)")
	ok(inv.info_sin_estadisticas == INVARIANTES_PRE_M0.info_sin_estadisticas, "M0: nombres, ranuras, colores, pilas y velocidades no cambiaron; solo dmg/def/hp pueden cambiar")
	# Estadísticas bien formadas.
	var mal: Array = []
	for e in _enumerar():
		var i: Dictionary = e.info
		if i.has("dmg") and (typeof(i.dmg) != TYPE_INT or typeof(i.def) != TYPE_INT or typeof(i.hp) != TYPE_INT or i.dmg < 0 or i.def < 0 or i.hp < 0): mal.append(e.clave)
	ok(mal.is_empty(), "M0: dmg/def/hp son enteros no negativos en todas las claves " + str(mal.slice(0, 3)))
	# Las propiedades afectan de verdad a la estadística y según la forma: la dureza empuja más a la espada que al escudo.
	var base_e: int = A.info(A.clave("espada", "hierro", "simple", 0)).dmg
	var base_s: int = A.info(A.clave("escudo", "hierro", "simple", 0)).def
	var copia := r.duplicate(true)
	copia.materiales.hierro.dureza = float(copia.materiales.hierro.dureza) * 3.0
	A._reglas = copia
	var dur_e: int = A.info(A.clave("espada", "hierro", "simple", 0)).dmg
	var dur_s: int = A.info(A.clave("escudo", "hierro", "simple", 0)).def
	var copia2 := r.duplicate(true)
	copia2.materiales.hierro.tenacidad = float(copia2.materiales.hierro.tenacidad) * 3.0
	A._reglas = copia2
	var ten_e: int = A.info(A.clave("espada", "hierro", "simple", 0)).dmg
	var ten_s: int = A.info(A.clave("escudo", "hierro", "simple", 0)).def
	var copia3 := r.duplicate(true)
	copia3.materiales.hierro.densidad = float(copia3.materiales.hierro.densidad) * 2.0
	A._reglas = copia3
	var vel_pesado: float = A.info(A.clave("espada", "hierro", "simple", 0)).vel
	A._reglas = {}
	ok(float(dur_e) / base_e > float(dur_s) / base_s, "M0: triplicar la dureza mejora más la espada (%d→%d) que el escudo (%d→%d)" % [base_e, dur_e, base_s, dur_s])
	ok(float(ten_s) / base_s > float(ten_e) / base_e, "M0: triplicar la tenacidad mejora más el escudo (%d→%d) que la espada (%d→%d)" % [base_s, ten_s, base_e, ten_e])
	ok(vel_pesado < float(A.info(A.clave("espada", "hierro", "simple", 0)).vel), "M0: un material más denso hace la pieza más lenta")
	# Diferenciación funcional: el mejor material depende de la forma (el orden cambia entre formas).
	var cambios: Array = []
	for a in MATERIALES_BASE:
		for b in MATERIALES_BASE:
			if a >= b: continue
			var antes := 0
			var despues := 0
			for f in r.formas:
				if not (f in r.materiales[a].formas and f in r.materiales[b].formas): continue
				var d := A.eficacia(r.materiales[a], r.formas[f].pesos) - A.eficacia(r.materiales[b], r.formas[f].pesos)
				if d > 0.000001: antes |= 1
				elif d < -0.000001: despues |= 1
			if antes == 1 and despues == 1: cambios.append("%s/%s" % [a, b])
	ok(not cambios.is_empty(), "M0: el orden entre materiales cambia según la forma en " + str(cambios))
	# Registro de dominancias: se imprime siempre y se compara con la lista conocida.
	var dom := _informe_dominancia()
	for linea in dom.detalle: print("INFORME dominancia: ", linea)
	ok(dom.claves == DOMINANCIAS_CONOCIDAS, "M0: el registro de dominancias coincide con el conocido (%d pares) " % dom.claves.size() + ("" if dom.claves == DOMINANCIAS_CONOCIDAS else str(dom.claves)))

# ---------- guardado, carga e incompatibilidad ----------
func _mundo_min() -> Dictionary:
	return {"formato": G.FORMATO, "semilla": 7, "jugadores": {}, "mundo": {}}

func _sobre(d: Dictionary) -> String:
	var cuerpo := JSON.stringify(d, "", true)
	return JSON.stringify({"formato": d.get("formato", G.FORMATO), "checksum": cuerpo.sha256_text(), "cuerpo": cuerpo})

func _escribir(ruta: String, txt: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(txt)
	f.close()

func _existe(ruta: String) -> bool:
	return FileAccess.file_exists(ruta)

func _guardado() -> void:
	_limpiar()
	var d := _mundo_min()
	ok(G.guardar(TMP, d) and d.reglas.huella == H.huella() and d.semilla == 7 and d.size() == 5, "guardar: escribe el mundo y lo sella con las reglas actuales sin tocar el resto")
	var r := G.cargar(TMP)
	ok(not r.d.is_empty() and r.origen == "principal" and not r.has("error") and not r.has("aviso"), "cargar: un mundo propio se carga sin aviso")
	ok(r.d.reglas.huella == H.huella() and r.d.reglas.contaminado == false and int(r.d.reglas.evaluador) == A.EVALUADOR_VERSION, "cargar: el mundo lleva el sello de las reglas actuales")
	# Mundo con reglas distintas: componente alterado y huella coherente con él.
	var sello := H.sello()
	sello.componentes["autonomia"] = "0".repeat(64)
	sello.huella = H.total(sello.componentes)
	var otro := _mundo_min()
	otro["reglas"] = sello
	_limpiar()
	_escribir(TMP, _sobre(otro))
	var antes := FileAccess.get_sha256(TMP)
	var rc := G.cargar(TMP)
	ok(rc.d.is_empty() and rc.get("error", "") == "reglas_distintas", "incompatible: se rechaza el mundo con reglas distintas")
	ok(rc.get("detalle", {}).get("distintos", []) == ["autonomia"], "incompatible: el diagnóstico indica qué componente difiere " + str(rc.get("detalle", {}).get("distintos", [])))
	ok(FileAccess.get_sha256(TMP) == antes and not _existe(TMP + ".bak") and not _existe(TMP + ".corrupta"), "incompatible: el archivo queda intacto, sin copias ni renombrados")
	ok(G.desempaquetar(_leer(TMP)).is_empty(), "incompatible: desempaquetar devuelve vacío")
	# Evaluador distinto con los mismos JSON.
	var ev := H.sello()
	ev.componentes["evaluador"] = H.hash_de(A.EVALUADOR_VERSION + 1)
	ev.huella = H.total(ev.componentes)
	var con_ev := _mundo_min()
	con_ev["reglas"] = ev
	var rev := G.inspeccionar(_sobre(con_ev))
	ok(rev.estado == "reglas_distintas" and rev.detalle.distintos == ["evaluador"], "incompatible: otra versión del evaluador se detecta aunque los JSON no cambien")
	# Sin huella (mundo anterior a H0).
	var viejo := _sobre(_mundo_min())
	var rv := G.inspeccionar(viejo)
	ok(rv.estado == "reglas_distintas" and rv.detalle.distintos == ["sin_huella"], "incompatible: un mundo sin huella se rechaza")
	# Un archivo corrupto no es lo mismo que uno incompatible.
	ok(G.inspeccionar("{no es json").estado == "ilegible" and G.inspeccionar(_sobre({"formato": G.FORMATO + 1})).estado == "invalido", "estados: ilegible e inválido siguen distinguiéndose")
	# No se cae al respaldo cuando el principal es válido pero incompatible.
	_limpiar()
	_escribir(TMP + ".bak", G.empaquetar(_mundo_min()))
	_escribir(TMP, _sobre(otro))
	var sin_caida := G.cargar(TMP)
	ok(sin_caida.d.is_empty() and sin_caida.get("error", "") == "reglas_distintas", "incompatible: no se vuelve en silencio al respaldo")
	# Sí se usa el respaldo si el principal está corrupto.
	_escribir(TMP, "{corrupto")
	var caida := G.cargar(TMP)
	ok(not caida.d.is_empty() and caida.origen == "respaldo", "respaldo: un principal corrupto sigue cayendo al .bak compatible")
	# Guardar encima de un incompatible lo conserva íntegro.
	_limpiar()
	_escribir(TMP, _sobre(otro))
	var hash_otro := FileAccess.get_sha256(TMP)
	ok(G.guardar(TMP, _mundo_min()), "guardar: sobre un mundo incompatible tiene éxito")
	ok(_existe(TMP + ".incompatible") and FileAccess.get_sha256(TMP + ".incompatible") == hash_otro and not _existe(TMP + ".bak"), "guardar: el mundo incompatible se conserva íntegro en .incompatible")
	ok(not G.cargar(TMP).d.is_empty(), "guardar: el mundo nuevo queda cargable")

func _leer(ruta: String) -> String:
	return FileAccess.get_file_as_string(ruta)

# ---------- excepción de desarrollo ----------
func _excepcion() -> void:
	ok(not H.excepcion_desde(["--aceptar-reglas-distintas"], false), "excepción: nunca en una compilación sin depuración")
	ok(not H.excepcion_desde([], true) and not H.excepcion_desde(["--otra"], true), "excepción: sin el argumento explícito no hay excepción")
	ok(H.excepcion_desde(["--aceptar-reglas-distintas"], true), "excepción: depuración y argumento explícito")
	ok(not H.excepcion_dev(), "excepción: apagada por defecto en esta ejecución")
	var sello := H.sello()
	sello.componentes["fauna"] = "0".repeat(64)
	sello.huella = H.total(sello.componentes)
	var otro := _mundo_min()
	otro["reglas"] = sello
	_limpiar()
	_escribir(TMP, _sobre(otro))
	var original := FileAccess.get_sha256(TMP)
	H.excepcion_de_prueba = true
	var r := G.cargar(TMP)
	H.excepcion_de_prueba = false
	ok(not r.d.is_empty() and r.d.reglas.contaminado == true and r.has("aviso"), "excepción: carga el mundo y lo marca como contaminado con aviso")
	ok(r.d.reglas.huella == sello.huella and r.d.reglas.cargado_con == H.huella(), "excepción: conserva la huella de origen y anota con qué reglas se cargó")
	ok(FileAccess.get_sha256(TMP) == original, "excepción: cargar no modifica el archivo")
	# El mundo contaminado, guardado, sigue rechazándose sin excepción (no se "lava").
	ok(G.guardar(TMP, r.d), "excepción: el mundo contaminado se puede guardar")
	var sin := G.cargar(TMP)
	ok(sin.d.is_empty() and sin.get("error", "") == "reglas_distintas", "excepción: sin ella, el mundo contaminado sigue rechazado")
	H.excepcion_de_prueba = true
	var otra_vez := G.cargar(TMP)
	H.excepcion_de_prueba = false
	ok(otra_vez.d.reglas.contaminado == true and otra_vez.d.reglas.huella == sello.huella, "excepción: la marca de contaminado persiste entre guardados")

# ---------- mundo vivo: reproducción y guardado/carga ----------
func _nuevo():
	var j = J.nueva(123, "Explorador", [0, 0, 0])
	j.combate.enemigos.clear()
	j.autonomia.activar()
	return j

func _sim(j, minutos: int) -> void:
	for i in minutos * 10: j.tick(0.1)

func _sin_reglas(d: Dictionary) -> Dictionary:
	var c := d.duplicate()
	c.erase("reglas")
	return c

func _mundo_vivo() -> void:
	var a = _nuevo()
	var b = _nuevo()
	_sim(a, 180)
	_sim(b, 180)
	var ha := H.hash_de(a.d)
	var hb := H.hash_de(b.d)
	var distintas: Array = []
	if ha != hb:
		for k in a.d: if H.hash_de(a.d[k]) != H.hash_de(b.d.get(k)): distintas.append(k)
	ok(ha == hb, "reproducción: misma semilla y mismos pasos dan el mismo estado canónico " + str(distintas))
	_limpiar()
	ok(a.guardar(TMP), "mundo vivo: guardar tras 3 horas simuladas")
	var r := G.cargar(TMP)
	ok(not r.d.is_empty() and not r.has("error"), "mundo vivo: se carga con las mismas reglas")
	ok(not r.d.is_empty() and H.hash_de(_sin_reglas(r.d)) == H.hash_de(_sin_reglas(a.d)), "mundo vivo: guardar y cargar conserva el estado canónico")
	var g = J.cargar(TMP)
	ok(g != null, "mundo vivo: Juego.cargar acepta el mundo sellado")
	var distinto := H.sello()
	distinto.componentes["catalogos"] = "0".repeat(64)
	distinto.huella = H.total(distinto.componentes)
	var d2: Dictionary = a.d.duplicate()
	d2["reglas"] = distinto
	_escribir(TMP, G.empaquetar(d2))
	ok(J.cargar(TMP) == null, "mundo vivo: Juego.cargar devuelve null ante reglas distintas")
	# P2: el motivo llega a la interfaz y no se confunde con un archivo ilegible ni con el rechazo de conexión.
	var msg_guardado: String = J.mensaje_carga(J.ultimo_error)
	ok(J.ultimo_error.get("error", "") == "reglas_distintas" and "catalogos" in msg_guardado and "otras reglas" in msg_guardado, "P2: carga rechazada por reglas muestra el motivo y los componentes " + msg_guardado)
	_escribir(TMP, "no es un guardado")
	var msg_ilegible: String = ""
	ok(J.cargar(TMP) == null, "P2: archivo ilegible también devuelve null")
	msg_ilegible = J.mensaje_carga(J.ultimo_error)
	ok(msg_ilegible.begins_with("No hay partida legible") and msg_ilegible != msg_guardado, "P2: archivo ilegible mantiene su mensaje propio " + msg_ilegible)
	_limpiar()
	ok(J.cargar(TMP) == null and J.ultimo_error.is_empty(), "P2: sin archivo no hay error de reglas (se podrá crear mundo nuevo)")
	var hola := ["hola", Srv.VERSION, "n", "clave", [0, 0, 0], "0".repeat(64)]
	var msg_red: String = Srv._verificar_hola(hola).get("motivo", "")
	var msg_version: String = Srv._verificar_hola(["hola", Srv.VERSION + 1, "n", "clave", [0, 0, 0], H.huella()]).get("motivo", "")
	ok("servidor" in msg_red and "huella" in msg_red and "mundo" not in msg_red, "P2: la conexión con reglas distintas dice «servidor», no «mundo» " + msg_red)
	ok("servidor" not in msg_guardado and "huella" not in msg_guardado, "P2: el guardado con reglas distintas no habla de servidor ni de conexión")
	ok(msg_version != msg_red and "Versión" in msg_version, "P2: versión de protocolo distinta es un tercer caso diferenciado " + msg_version)

func _limpiar() -> void:
	for s in ["", ".tmp", ".bak", ".corrupta", ".incompatible"]:
		var ruta := ProjectSettings.globalize_path(TMP + s)
		if FileAccess.file_exists(ruta): DirAccess.remove_absolute(ruta)
