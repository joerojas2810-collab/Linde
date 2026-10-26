extends RefCounted
## Utilidades de las herramientas de medición `tests/medir_*.gd` (no son suites: no usan PASS/FAIL).
## Formato de salida, una línea por dato: «ETIQUETA clave=valor clave=valor». Etiquetas:
##   MEDIDA_CONFIG  configuración y limitaciones de la corrida
##   MEDIDA_ESTADO  resultado determinista (reproducible con la misma semilla y configuración)
##   MEDIDA_HITO    resultado determinista de un hito de ritmo (tiempo virtual de juego, no de CPU)
##   MEDIDA_CPU     tiempos de CPU de la máquina (NO deterministas; nunca se comparan para igualdad)
## Las herramientas no guardan archivos ni modifican reglas, datos o balance: solo leen el juego.

## Argumentos de usuario `clave=valor` (tras `--`), con valores por defecto.
static func args(defecto: Dictionary) -> Dictionary:
	var r: Dictionary = defecto.duplicate()
	for a in OS.get_cmdline_user_args():
		var s: String = a.trim_prefix("--")
		if s.contains("="): r[s.get_slice("=", 0)] = s.get_slice("=", 1)
	return r

static func linea(etiqueta: String, kv: Dictionary) -> void:
	var partes: Array = [etiqueta]
	for k in kv: partes.append("%s=%s" % [k, str(kv[k])])
	print(" ".join(partes))

## Hash del estado completo guardable (JSON con claves ordenadas). `ignorar`: rutas «a.b» de claves que no cuentan, para
## comparar un cambio que añade datos nuevos sin alterar el comportamiento (p. ej. «mundo.poblados» en la Fase 1a de Mundo 1).
static func hash_estado(j, ignorar: Array = []) -> String:
	if ignorar.is_empty(): return JSON.stringify(j.d).sha256_text().substr(0, 16)
	var copia: Dictionary = j.d.duplicate(true)
	for ruta in ignorar:
		var partes: PackedStringArray = str(ruta).split(".")
		var nodo: Dictionary = copia
		for i in partes.size() - 1:
			if not nodo.has(partes[i]) or typeof(nodo[partes[i]]) != TYPE_DICTIONARY: nodo = {}
			else: nodo = nodo[partes[i]]
		nodo.erase(partes[partes.size() - 1])
	return JSON.stringify(copia).sha256_text().substr(0, 16)

## Hash de un valor cualquiera con orden estable.
static func hash_de(v) -> String:
	return JSON.stringify(v).sha256_text().substr(0, 16)

## Resultados relevantes de los habitantes: ids, ocupaciones, inventarios y obras. Todo determinista.
static func resumen_npc(j) -> Dictionary:
	var ocup := {}
	var inv_total := {}
	for nid in j.habitantes.ids:
		var n: Dictionary = j.autonomia.estado(nid)
		var o: String = str(n.get("ocupacion", ""))
		ocup[o] = int(ocup.get(o, 0)) + 1
		for it in n.inv: inv_total[it] = int(inv_total.get(it, 0)) + int(n.inv[it])
	var camas := 0
	var casas := 0
	var construcciones: int = j.d.mundo.constr.size()
	for k in j.d.mundo.constr:
		if j.d.mundo.constr[k].t == "cama_huesped":
			camas += 1
			var c := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
			if j.autonomia.sociedad.casa_completa(c): casas += 1
	var claves_inv: Array = inv_total.keys()
	claves_inv.sort()
	var inv_txt: Array = []
	for it in claves_inv: inv_txt.append("%s:%d" % [it, inv_total[it]])
	var ocup_claves: Array = ocup.keys()
	ocup_claves.sort()
	var ocup_txt: Array = []
	for o in ocup_claves: ocup_txt.append("%s:%d" % [o if o != "" else "-", ocup[o]])
	return {"habitantes": j.habitantes.ids.size(), "camas_huesped": camas, "casas_completas": casas, "construcciones": construcciones,
		"caminos": j.d.mundo.caminos.size(), "ocupaciones": ",".join(ocup_txt), "inventario_npc": ",".join(inv_txt)}

static func percentiles(v: Array) -> Dictionary:
	var a: Array = v.duplicate()
	a.sort()
	if a.is_empty(): return {}
	return {"min": a[0], "p10": a[int(a.size() * 0.10)], "p50": a[a.size() / 2], "p90": a[int(a.size() * 0.90)], "max": a[-1]}
