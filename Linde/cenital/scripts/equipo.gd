extends RefCounted
# Equipo v1 (Linde/documentos/sistema-de-equipo.md). Funciones puras sobre claves de ítem
# `eq:<familia>:<ranura>:<variante>:<nivel>`: el estado de la pieza vive en la clave y el inventario atómico no cambia.
# Datos en res://datos/equipo/*.json (TODOS los números son PROVISIONALES); se cargan una vez.
# Regla: todo acceso a nombre, pila o estadísticas de un ítem que pueda ser `eq:` pasa por info(clave).
const Artesania = preload("res://scripts/artesania.gd")
const C = preload("res://scripts/catalogos.gd")
const DIR := "res://datos/equipo/"
const DESCONOCIDA := "Pieza desconocida"
const EPS := 0.000001          # floor de valores que en aritmética exacta son enteros (12.0 * 1.10 = 13.2...)
const EFECTOS := ["def_pct", "hp_pct", "vel_pct"]
static var _d: Dictionary = {}
static var _info: Dictionary = {}      # caché de info() solo para claves `eq:` válidas
static var _recetas: Dictionary = {}

## Datos normalizados (listas con id -> diccionarios por id). Se cargan la primera vez.
static func datos() -> Dictionary:
	if _d.is_empty(): _d = cargar_datos(DIR)
	return _d

static func _json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta): return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return v if v is Dictionary else {}

## Lee los 5 JSON de `dir`. Archivos ilegibles e ids repetidos quedan en "errores" (los informa validar_datos).
static func cargar_datos(dir: String) -> Dictionary:
	var e: Array = []
	var a := _json(dir + "arquetipos.json")
	var f := _json(dir + "familias.json")
	var v := _json(dir + "variantes.json")
	var jo := _json(dir + "joyas.json")
	var pa := _json(dir + "paletas.json")
	for par in [["arquetipos.json", a], ["familias.json", f], ["variantes.json", v], ["joyas.json", jo], ["paletas.json", pa]]:
		if (par[1] as Dictionary).is_empty(): e.append("equipo: no se pudo leer %s" % par[0])
	var orden: Array = []
	for r in a.get("ranuras", []): orden.append(str(r.get("id", "")) if r is Dictionary else "")
	return {"constantes": a.get("constantes", {}), "orden": orden, "ranuras": _por_id(a.get("ranuras", []), "ranura", e),
		"arquetipos": _por_id(a.get("arquetipos", []), "arquetipo", e), "familias": _por_id(f.get("familias", []), "familia", e),
		"paletas": pa.get("paletas", {}), "variantes": _por_id(v.get("variantes", []), "variante", e), "deltas": pa.get("deltas", {}),
		"piedras": _por_id(v.get("piedras", []), "piedra", e), "joyas": _por_id(jo.get("joyas", []), "joya", e),
		"nivel_max": int(jo.get("nivel_max", 0)), "k_n": float(jo.get("k_n", 0.0)), "errores": e}

static func _por_id(lista, tipo: String, e: Array) -> Dictionary:
	var out := {}
	if not lista is Array:
		e.append("equipo: %s debe ser una lista" % tipo)
		return out
	for x in lista:
		if not x is Dictionary or not x.has("id"):
			e.append("equipo: %s sin id" % tipo)
			continue
		var id := str(x.id)
		if out.has(id): e.append("equipo: id de %s duplicado: %s" % [tipo, id])
		out[id] = x
	return out

static func _enteros(m: Dictionary) -> Dictionary:
	var o := {}
	for k in m: o[str(k)] = int(m[k])
	return o

# ---------- claves ----------
static func construir(familia: String, ranura: String, variante: String, nivel: int) -> String:
	return "eq:%s:%s:%s:%d" % [familia, ranura, variante, nivel]

static func es_pieza(clave: String) -> bool:
	return clave.begins_with("eq:")

## {familia, ranura, variante, nivel} o {} si la clave no es una pieza válida (familia, ranura de la familia,
## variante existente, 0 <= nivel <= NIVEL_MAX y forma canónica exacta: "02", "+1" o espacios no valen).
static func leer(clave: String) -> Dictionary:
	if not es_pieza(clave): return {}
	var p := clave.split(":")
	if p.size() != 5 or not p[4].is_valid_int(): return {}
	var dd := datos()
	var fam: Dictionary = dd.familias.get(p[1], {})
	var n := int(p[4])
	if fam.is_empty() or not p[2] in fam.get("piezas", []) or (p[3] != "" and not dd.variantes.has(p[3])) or n < 0 or n > int(dd.nivel_max): return {}
	if construir(p[1], p[2], p[3], n) != clave: return {}
	return {"familia": p[1], "ranura": p[2], "variante": p[3], "nivel": n}

## «Casco de Vigía Divino +2»; sin piedra «Casco de Vigía +2»; en +0 sin sufijo.
static func nombre(p: Dictionary) -> String:
	var dd := datos()
	var t := "%s de %s" % [dd.ranuras[p.ranura].n, dd.familias[p.familia].nombre]
	if p.variante != "": t += " " + str(dd.variantes[p.variante].nombre)
	if int(p.nivel) > 0: t += " +%d" % int(p.nivel)
	return t

static func existe(clave: String) -> bool:
	var dd := datos()
	return not Artesania.info(clave).is_empty() or C.ITEMS.has(clave) or dd.piedras.has(clave) or dd.joyas.has(clave) or not leer(clave).is_empty()

## Lo mismo que una entrada de C.ITEMS (n, pila, c, y equipo/def/hp/vel en piezas) para cualquier clave.
## Clave desconocida o `eq:` inválida: «Pieza desconocida», pila 1, no equipable (nunca falla ni se pierde).
static func info(clave: String) -> Dictionary:
	var artesanal := Artesania.info(clave)
	if not artesanal.is_empty(): return artesanal
	if C.ITEMS.has(clave): return C.ITEMS[clave]
	if _info.has(clave): return _info[clave]
	var dd := datos()
	if dd.piedras.has(clave):
		var x: Dictionary = dd.piedras[clave]
		return {"n": str(x.n), "pila": int(x.pila), "c": str(x.c), "piedra": true}
	if dd.joyas.has(clave):
		var x: Dictionary = dd.joyas[clave]
		return {"n": str(x.nombre), "pila": int(x.pila), "c": str(x.c), "joya": str(x.funcion)}
	var p := leer(clave)
	if p.is_empty(): return {"n": DESCONOCIDA, "pila": 1, "c": "#808080", "desconocida": true}
	var fam: Dictionary = dd.familias[p.familia]
	var s := stats_pieza(p)
	var r := {"n": nombre(p), "pila": 1, "c": str(dd.paletas.get(fam.paleta, {}).get("principal", "#808080")), "equipo": p.ranura,
		"pieza": p, "def": s.def, "hp": s.hp, "vel": s.vel, "rareza": str(fam.get("rareza", ""))}
	_info[clave] = r
	return r

# ---------- estadísticas (3.1 y 3.2) ----------
static func _mult_variante(v: String) -> Dictionary:
	if v == "": return {"def": 1.0, "hp": 1.0, "vel": 0.0}
	var x: Dictionary = datos().variantes[v]
	return {"def": float(x.mult.def), "hp": float(x.mult.hp), "vel": float(x.vel_pct_delta)}

## Estadísticas de una pieza leída, sin redondear.
static func stats_pieza(p: Dictionary) -> Dictionary:
	var dd := datos()
	var r: Dictionary = dd.ranuras[p.ranura]
	var fam: Dictionary = dd.familias[p.familia]
	var a: Dictionary = dd.arquetipos[fam.arquetipo]
	var v := _mult_variante(p.variante)
	var mejora := 1.0 + float(dd.k_n) * int(p.nivel)
	var pot := float(fam.potencia)
	return {"def": float(r.def_base) * float(a.mult.def) * pot * v.def * mejora,
		"hp": float(r.hp_base) * float(a.mult.hp) * pot * v.hp * mejora,
		"vel": float(r.peso) * (float(a.vel_pct) + v.vel)}

## Bono de set único (3.5): familia con más piezas de set puestas (>= 2); empate -> la del torso, si no la del casco,
## si no ninguna. Suma los umbrales alcanzados de esa familia. Escudo y arma no cuentan.
static func bono_set(equipo: Dictionary) -> Dictionary:
	var dd := datos()
	var b := {"familia": "", "piezas": 0, "def_pct": 0.0, "hp_pct": 0.0, "vel_pct": 0.0}
	var c := {}
	var de := {}
	for r in dd.orden:
		var p := leer(str(equipo.get(r, "")))
		if p.is_empty() or p.ranura != r: continue
		c[p.familia] = int(c.get(p.familia, 0)) + 1
		de[r] = p.familia
	var mx := 0
	for f in c: mx = maxi(mx, c[f])
	if mx < 2: return b
	var emp: Array = c.keys().filter(func(f): return c[f] == mx)
	var gan := ""
	if emp.size() == 1: gan = emp[0]
	elif de.get("torso", "") in emp: gan = de.torso
	elif de.get("casco", "") in emp: gan = de.casco
	if gan == "": return b
	b.familia = gan
	b.piezas = mx
	for u in dd.familias[gan].bono_set:
		if int(u.piezas) > mx: continue
		for k in u.efecto: b[k] += float(u.efecto[k])
	return b

## Sumas sin redondeo de todo lo equipado (piezas y escudo plano) más el bono: {def_eq, hp_eq, vel_eq, bono}.
static func stats_de(equipo: Dictionary) -> Dictionary:
	var s := {"def_eq": 0.0, "hp_eq": 0.0, "vel_eq": 0.0}
	for r in equipo:
		var k := str(equipo[r])
		if k == "": continue
		var p := leer(k)
		if not p.is_empty():
			if p.ranura != r: continue
			var ps := stats_pieza(p)
			s.def_eq += ps.def
			s.hp_eq += ps.hp
			s.vel_eq += ps.vel
		elif str(info(k).get("equipo", "")) == r:
			s.def_eq += float(info(k).get("def", 0))
			if not Artesania.leer(k).is_empty():
				s.hp_eq += float(info(k).get("hp", 0))
				s.vel_eq += float(info(k).get("vel", 0))
	var b := bono_set(equipo)
	s.vel_eq += b.vel_pct
	s["bono"] = b
	return s

## DEF, HP y VEL finales (3.2): redondeo único al final; topes de bono y VEL en [vel_min, vel_max].
static func finales(equipo: Dictionary, hab_hp: int, hab_vel: float, hp_base: int) -> Dictionary:
	var k: Dictionary = datos().constantes
	var s := stats_de(equipo)
	var b: Dictionary = s.bono
	var dpct := minf(b.def_pct, float(k.tope_def_pct))
	var hpct := minf(b.hp_pct, float(k.tope_hp_pct))
	return {"def": floori(s.def_eq * (1.0 + dpct) + EPS), "hp": floori((hp_base + hab_hp + s.hp_eq) * (1.0 + hpct) + EPS),
		"vel": clampf(snappedf(1.0 + hab_vel + s.vel_eq, 0.0001), float(k.vel_min), float(k.vel_max)), "bono": b}

## Daño recibido (3.7): max(1, round(n * K / (K + DEF))).
static func dano(n: int, def: int) -> int:
	var k := float(datos().constantes.k_def)
	return maxi(1, roundi(n * k / (k + maxi(0, def))))

# ---------- mejora y piedras (3.6, 5.4) ----------
static func joya_mejora() -> Dictionary:
	for id in datos().joyas:
		if datos().joyas[id].funcion == "mejorar": return datos().joyas[id]
	return {}

## {ok, nueva, coste {joya: n}, motivo}. Sin azar; en NIVEL_MAX se rechaza.
static func mejorar(clave: String) -> Dictionary:
	var p := leer(clave)
	if p.is_empty(): return {"ok": false, "motivo": "No es una pieza válida"}
	if int(p.nivel) >= int(datos().nivel_max): return {"ok": false, "motivo": "La pieza ya está en +%d" % int(p.nivel)}
	var j := joya_mejora()
	var n := int(p.nivel) + 1
	return {"ok": true, "nueva": construir(p.familia, p.ranura, p.variante, n), "coste": {str(j.id): int(j.coste_por_nivel[str(n)])}, "motivo": ""}

## {ok, nueva, coste {piedra: 1}, motivo}. Conserva familia, ranura y nivel; la piedra anterior se pierde.
static func cambiar_variante(clave: String, variante: String) -> Dictionary:
	var p := leer(clave)
	if p.is_empty(): return {"ok": false, "motivo": "No es una pieza válida"}
	if not datos().variantes.has(variante): return {"ok": false, "motivo": "Piedra desconocida"}
	if p.variante == variante: return {"ok": false, "motivo": "Ya lleva esa piedra"}
	return {"ok": true, "nueva": construir(p.familia, p.ranura, variante, int(p.nivel)),
		"coste": {str(datos().variantes[variante].piedra): 1}, "motivo": ""}

# ---------- obtención ----------
## C.RECETAS más las generadas por datos: piezas de familias fabricables («<familia>_<ranura>») y joyas con receta.
static func recetas() -> Dictionary:
	if not _recetas.is_empty(): return _recetas
	var r: Dictionary = C.RECETAS.duplicate(true)
	var dd := datos()
	for f in dd.familias:
		var o: Dictionary = dd.familias[f].origen
		if o.tipo != "fabricable": continue
		for ran in o.get("recetas", {}):
			var k := construir(f, ran, "", 0)
			r["%s_%s" % [f, ran]] = {"n": info(k).n, "ent": _enteros(o.recetas[ran]), "sal": {k: 1}, "est": str(o.estacion), "herr": "", "hab": str(o.habilidad)}
	for id in dd.joyas:
		var re: Dictionary = dd.joyas[id].get("receta", {})
		if not re.is_empty():
			r[id] = {"n": str(dd.joyas[id].nombre), "ent": _enteros(re.ent), "sal": {id: 1}, "est": str(re.est), "herr": "", "hab": str(re.hab)}
	_recetas = r
	return r

## Botín probabilístico extra de un objeto del mundo (piedras): [{item, q, p}].
static func caidas_objeto(objeto: String) -> Array:
	var l: Array = []
	for id in datos().piedras:
		for c in datos().piedras[id].get("caida", []):
			if c.objeto == objeto: l.append({"item": id, "q": 1, "p": float(c.p)})
	return l

## Familias de zona que caen de esta fuente (enemigo).
static func familias_zona(fuente: String) -> Array:
	var l: Array = []
	for f in datos().familias:
		var o: Dictionary = datos().familias[f].origen
		if o.tipo == "zona" and fuente in o.get("fuentes", []): l.append(f)
	return l

static func familias_jefe(jefe: String) -> Array:
	var l: Array = []
	for f in datos().familias:
		var o: Dictionary = datos().familias[f].origen
		if o.tipo == "jefe" and str(o.get("jefe", "")) == jefe: l.append(f)
	return l

## Una tirada de farmeo: `sin` = intentos seguidos sin caída. Tras `garantia` fallos la siguiente es segura.
## Devuelve la ranura que cae o "".
static func tirada_zona(familia: String, sin: int, rng: RandomNumberGenerator) -> String:
	var fam: Dictionary = datos().familias[familia]
	var cae: bool = rng.randf() < float(fam.origen.prob) or sin >= int(fam.origen.garantia)
	var r: String = fam.piezas[rng.randi() % fam.piezas.size()]
	return r if cae else ""

## Datos para el dibujo por capas (scripts/arte_equipo.gd): una entrada por ranura equipada. Piezas `eq:`:
## {ranura, arquetipo, silueta, familia, variante ("" = sin piedra), paleta, delta}; otros ítems: {ranura, item, paleta}.
static func visible(equipo: Dictionary) -> Array:
	var dd := datos()
	var l: Array = []
	for r in equipo:
		var k := str(equipo[r])
		if k == "": continue
		var artesanal := Artesania.visible(k)
		if not artesanal.is_empty():
			l.append(artesanal)
			continue
		var p := leer(k)
		if p.is_empty():
			l.append({"ranura": "espada" if r == "arma" else r, "item": k, "paleta": dd.paletas.get(str(info(k).get("paleta", "")), {})})
			continue
		var fam: Dictionary = dd.familias[p.familia]
		var a: Dictionary = dd.arquetipos[fam.arquetipo]
		var delta: Dictionary = dd.deltas.get(dd.variantes[p.variante].paleta_delta if p.variante != "" else "sin_piedra", {})
		l.append({"ranura": r, "arquetipo": str(fam.arquetipo), "silueta": str(a.silueta), "familia": p.familia, "variante": p.variante,
			"paleta": dd.paletas.get(fam.paleta, {}), "delta": delta})
	return l

# ---------- validación (2.5) ----------
static func _domina(a: Dictionary, b: Dictionary) -> bool:
	return a.def >= b.def and a.hp >= b.hp and a.vel >= b.vel and (a.def > b.def or a.hp > b.hp or a.vel > b.vel)

## Errores del catálogo de equipo `dd` (vacío = válido). Comprueba referencias, forma y alcanzabilidad contra C.
static func validar_datos(dd: Dictionary) -> Array:
	var e: Array = dd.get("errores", []).duplicate()
	var id_ok := RegEx.create_from_string("^[a-z0-9_]+$")
	var k: Dictionary = dd.get("constantes", {})
	for c in ["tope_def_pct", "tope_hp_pct", "vel_min", "vel_max", "k_def", "bono_max_def", "bono_max_hp", "potencia_razon_max"]:
		if not k.has(c): e.append("equipo: falta la constante %s" % c)
	if not e.is_empty(): return e
	var orden: Array = dd.orden
	for r in orden:
		if not r in C.RANURAS: e.append("equipo: ranura %s no está en C.RANURAS" % r)
		if not dd.ranuras.has(r): e.append("equipo: ranura sin datos %s" % r)
	var pmin := INF
	var pmax := 0.0
	for f in dd.familias:
		var fam: Dictionary = dd.familias[f]
		if id_ok.search(f) == null: e.append("familia %s: id no válido" % f)
		var pz: Array = fam.get("piezas", [])
		var distintas := {}
		for r in pz: distintas[r] = true
		if pz.size() != 5 or distintas.size() != 5 or orden.any(func(r): return not distintas.has(r)):
			e.append("familia %s: debe tener exactamente 5 piezas distintas, una por ranura" % f)
		if not dd.arquetipos.has(fam.get("arquetipo", "")): e.append("familia %s: arquetipo %s" % [f, fam.get("arquetipo")])
		if not dd.paletas.has(fam.get("paleta", "")): e.append("familia %s: paleta %s" % [f, fam.get("paleta")])
		var pot := float(fam.get("potencia", 0.0))
		if pot <= 0.0: e.append("familia %s: potencia" % f)
		pmin = minf(pmin, pot)
		pmax = maxf(pmax, pot)
		var prev := 1
		var tot := {"def_pct": 0.0, "hp_pct": 0.0, "vel_pct": 0.0}
		for u in fam.get("bono_set", []):
			var n := int(u.get("piezas", 0))
			if n < 2 or n > 5 or n <= prev: e.append("familia %s: umbral de bono %d fuera de 2..5 o no creciente" % [f, n])
			prev = n
			for ef in u.get("efecto", {}):
				if not ef in EFECTOS: e.append("familia %s: efecto de bono %s no permitido" % [f, ef])
				else: tot[ef] += float(u.efecto[ef])
		if tot.def_pct > float(k.bono_max_def) + EPS or tot.hp_pct > float(k.bono_max_hp) + EPS: e.append("familia %s: bono de set por encima del tope" % f)
		var o: Dictionary = fam.get("origen", {})
		match o.get("tipo", ""):
			"fabricable":
				var rec: Dictionary = o.get("recetas", {})
				for r in pz:
					if not rec.has(r): e.append("familia %s: %s sin receta (inalcanzable)" % [f, r]); continue
					for it in rec[r]: if not existe(it): e.append("familia %s: receta %s usa %s" % [f, r, it])
				if not C._hay_estacion(str(o.get("estacion", ""))): e.append("familia %s: estación %s" % [f, o.get("estacion")])
				if str(o.get("habilidad", "")) != "" and not C.HAB.has(o.habilidad): e.append("familia %s: habilidad %s" % [f, o.habilidad])
			"zona":
				var fu: Array = o.get("fuentes", [])
				if fu.is_empty(): e.append("familia %s: sin fuentes de caída (inalcanzable)" % f)
				for s in fu: if not C.ENEMIGOS.has(s): e.append("familia %s: fuente %s" % [f, s])
				if float(o.get("prob", 0.0)) <= 0.0 or float(o.get("prob", 0.0)) > 1.0 or int(o.get("garantia", 0)) < 1: e.append("familia %s: prob/garantía" % f)
			"jefe":
				var jf: Dictionary = C.ENEMIGOS.get(str(o.get("jefe", "")), {})
				if jf.get("tipo", "") != "mundo" or int(jf.get("reaparece_h", 0)) <= 0: e.append("familia %s: el jefe %s no existe o no es repetible" % [f, o.get("jefe")])
			_: e.append("familia %s: origen %s" % [f, o.get("tipo")])
	if pmin != INF and pmax / pmin > float(k.potencia_razon_max) + EPS: e.append("equipo: potencia_max / potencia_min > %s" % k.potencia_razon_max)
	var mults: Array = [{"id": "sin piedra", "def": 1.0, "hp": 1.0, "vel": 0.0}]
	for v in dd.variantes:
		var x: Dictionary = dd.variantes[v]
		if id_ok.search(v) == null: e.append("variante %s: id no válido" % v)
		if not dd.piedras.has(x.get("piedra", "")): e.append("variante %s: piedra %s" % [v, x.get("piedra")])
		if not dd.deltas.has(x.get("paleta_delta", "")): e.append("variante %s: paleta %s" % [v, x.get("paleta_delta")])
		mults.append({"id": v, "def": float(x.mult.def), "hp": float(x.mult.hp), "vel": float(x.vel_pct_delta)})
	for a in mults:
		for b in mults:
			if a.id != b.id and _domina(a, b): e.append("variante %s domina a %s" % [a.id, b.id])
	for id in dd.piedras:
		if C.ITEMS.has(id) or dd.joyas.has(id): e.append("piedra %s: id duplicado con otro ítem" % id)
		var ca: Array = dd.piedras[id].get("caida", [])
		if ca.is_empty(): e.append("piedra %s: sin origen (inalcanzable)" % id)
		for c in ca: if not C.OBJETOS.has(c.get("objeto", "")) or float(c.get("p", 0.0)) <= 0.0: e.append("piedra %s: caída %s" % [id, c])
	var jm := false
	for id in dd.joyas:
		var j: Dictionary = dd.joyas[id]
		if C.ITEMS.has(id): e.append("joya %s: id duplicado con otro ítem" % id)
		if j.get("funcion", "") == "mejorar":
			jm = true
			for n in range(1, int(dd.nivel_max) + 1):
				if int(j.get("coste_por_nivel", {}).get(str(n), 0)) < 1: e.append("joya %s: sin coste para +%d" % [id, n])
		var re: Dictionary = j.get("receta", {})
		if re.is_empty(): e.append("joya %s: sin origen (inalcanzable)" % id)
		else:
			for it in re.get("ent", {}): if not existe(it): e.append("joya %s: receta usa %s" % [id, it])
			if not C._hay_estacion(str(re.get("est", ""))): e.append("joya %s: estación %s" % [id, re.get("est")])
			if str(re.get("hab", "")) != "" and not C.HAB.has(re.hab): e.append("joya %s: habilidad %s" % [id, re.hab])
	if not jm: e.append("equipo: falta una joya con funcion mejorar")
	e.append_array(validar_paletas(dd))
	if int(dd.nivel_max) < 1 or float(dd.k_n) <= 0.0: e.append("equipo: nivel_max / k_n")
	return e

## Paletas y deltas del recoloreado (paletas.json). Cada paleta: principal, sombra y acento obligatorios, detalle opcional,
## colores HTML válidos y distintos de los colores índice del contrato. Cada delta: brillo, saturacion y tono en [-1, 1];
## «sin_piedra» debe existir. Los ítems con "paleta" en C.ITEMS deben apuntar a una paleta existente.
const ROLES := ["principal", "sombra", "acento", "detalle"]
const INDICES := ["#ff0000", "#00ff00", "#0000ff", "#808080"]
static func validar_paletas(dd: Dictionary) -> Array:
	var e: Array = []
	var pals = dd.get("paletas", {})
	var dels = dd.get("deltas", {})
	if not pals is Dictionary or not dels is Dictionary: return ["paletas: 'paletas' y 'deltas' deben ser objetos"]
	for id in pals:
		var p = pals[id]
		if not p is Dictionary: e.append("paleta %s: no es un objeto" % id); continue
		for rol in p:
			if not rol in ROLES: e.append("paleta %s: rol %s desconocido" % [id, rol])
			elif not (p[rol] is String and Color.html_is_valid(p[rol])): e.append("paleta %s: %s no es un color" % [id, rol])
			elif ("#" + Color(p[rol]).to_html(false)) in INDICES: e.append("paleta %s: %s usa un color índice" % [id, rol])
		for rol in ["principal", "sombra", "acento"]:
			if not p.has(rol): e.append("paleta %s: falta %s" % [id, rol])
	if not dels.has("sin_piedra"): e.append("paletas: falta el delta sin_piedra")
	for id in dels:
		var d = dels[id]
		for k in ["brillo", "saturacion", "tono"]:
			var x = d.get(k) if d is Dictionary else null
			if not (x is float or x is int) or absf(float(x)) > 1.0: e.append("delta %s: %s debe ser un número en [-1, 1]" % [id, k])
	for id in C.ITEMS:
		if C.ITEMS[id].has("paleta") and not pals.has(C.ITEMS[id].paleta): e.append("item %s: paleta %s" % [id, C.ITEMS[id].paleta])
	return e
