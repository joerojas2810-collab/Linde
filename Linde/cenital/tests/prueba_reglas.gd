extends SceneTree
## H0 (PLAN_MAESTRO §10): huella de reglas, versión del evaluador, guardado/carga e incompatibilidad.
## Uso:  Godot --headless --log-file <ruta> --path Linde/cenital --script res://tests/prueba_reglas.gd
## Regenerar el dorado (solo tras un cambio deliberado, con commit que lo explique):  ... -- --generar-dorado
const A = preload("res://scripts/artesania.gd")
const H = preload("res://scripts/huella.gd")
const G = preload("res://scripts/guardado.gd")
const J = preload("res://scripts/juego.gd")
const RUTA_DORADO := "res://tests/dorados/artesania_v1.json"
const TMP := "user://prueba_reglas.json"
const EXCLUIDOS := ["res://datos/equipo/paletas.json"]   # solo color; datos/mundo es narrativa del director
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
	_canonico()
	_huella()
	_dorado()
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
	ok(H.versiones().evaluador == A.EVALUADOR_VERSION and int(H.versiones().get("reglas_v1", 0)) == int(A.reglas().version), "huella: versiones legibles (evaluador y reglas de desarrollo)")
	for id in comp:
		var alterado := comp.duplicate()
		alterado[id] = "x"
		ok(H.total(alterado) != h, "huella: cambia si cambia el componente " + id)
	var alterado := comp.duplicate()
	alterado["evaluador"] = H.hash_de(A.EVALUADOR_VERSION + 1)
	ok(H.total(alterado) != h, "huella: subir EVALUADOR_VERSION cambia la huella aunque los JSON no cambien")
	var reglas: Dictionary = A.reglas().duplicate(true)
	ok(H.hash_de(reglas) == H.hash_de(A.reglas()), "huella: una copia profunda de las reglas conserva el hash")
	reglas.materiales.hierro.potencia = float(reglas.materiales.hierro.potencia) + 0.01
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

func _generar_dorado() -> void:
	var lista := _enumerar()
	var muestra: Array = []
	for i in lista.size():
		if i % 25 == 0 or str(lista[i].clave).begins_with("mat1:"): muestra.append(lista[i])
	var dorado := {"_nota": "Instantánea del comportamiento de artesania.gd. Regenerar solo tras un cambio deliberado: subir EVALUADOR_VERSION o la version de reglas_v1.json según corresponda y explicarlo en el commit.",
		"evaluador": A.EVALUADOR_VERSION, "reglas_desarrollo": A.reglas().version, "total": lista.size(), "hash": H.hash_de(lista), "muestra": muestra}
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
	var por_clave := {}
	for e in lista: por_clave[e.clave] = e
	var diferentes: Array = []
	for e in dor.muestra:
		var actual = por_clave.get(e.clave)
		if actual == null or H.canonico(e.info) != H.canonico(actual.info) or H.canonico(e.receta) != H.canonico(actual.receta): diferentes.append(e.clave)
	ok(diferentes.is_empty(), "dorado: muestra revisable por personas coincide " + str(diferentes.slice(0, 5)))

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

func _limpiar() -> void:
	for s in ["", ".tmp", ".bak", ".corrupta", ".incompatible"]:
		var ruta := ProjectSettings.globalize_path(TMP + s)
		if FileAccess.file_exists(ruta): DirAccess.remove_absolute(ruta)
