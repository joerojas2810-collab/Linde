extends RefCounted
## Gramática de piezas; no registra un catálogo de cada combinación. Claves versionadas y canónicas.
const C = preload("res://scripts/catalogos.gd")
const PREFIJO := "art1:"
## Interpretación de las reglas (fórmulas, redondeos, orden de operaciones, canonicalización). Subirla SIEMPRE que cambie
## cómo se calcula una pieza aunque los JSON no cambien; forma parte de la huella de reglas (huella.gd) y del test dorado.
const PREFIJO2 := "art2:"
const EVALUADOR_VERSION := 3   # 3 (I1a): variantes art2: con operadores; 2 (M0): estadísticas por propiedades del material y pesos de la forma; 1: potencia única por material
static var _reglas: Dictionary = {}

static func reglas() -> Dictionary:
	if _reglas.is_empty():
		_reglas = JSON.parse_string(FileAccess.get_file_as_string("res://datos/desarrollo/reglas_v1.json"))
	return _reglas

## Materiales elaborados por una regla de núcleo + refuerzo; no admite cadenas recursivas.
static func combinaciones() -> Array:
	var lista: Array=[]
	for nucleo in reglas().laminados.nucleos:
		for refuerzo in reglas().laminados.refuerzos:
			if nucleo!=refuerzo: lista.append(str(nucleo)+"_"+str(refuerzo))
	return lista

static func material(id: String) -> Dictionary:
	var r:=reglas()
	if r.materiales.has(id): return r.materiales[id]
	if not id in combinaciones(): return {}
	var p:=id.split("_")
	var uno: Dictionary=r.materiales[p[0]]
	var dos: Dictionary=r.materiales[p[1]]
	var formas: Array=[]
	for forma in uno.formas:
		if forma in dos.formas: formas.append(forma)
	var peso: float=r.laminados.peso_nucleo
	var peso_densidad: float=r.laminados.peso_densidad
	return {"nombre":"laminado de "+str(uno.nombre)+" y "+str(dos.nombre),"item":"mat1:"+id,"coste":1,
		"dureza":float(uno.dureza)*peso+float(dos.dureza)*(1.0-peso),"tenacidad":float(uno.tenacidad)*peso+float(dos.tenacidad)*(1.0-peso),
		"densidad":float(uno.densidad)*peso_densidad+float(dos.densidad)*(1.0-peso_densidad),
		"arquetipo":uno.arquetipo,"color":Color(uno.color).lerp(Color(dos.color),float(r.laminados.mezcla_color)).to_html(),"formas":formas,
		"fuente":"Fabricar en un horno con "+str(uno.nombre)+" y "+str(dos.nombre)}

static func leer_material(k: String) -> String:
	if not k.begins_with("mat1:"): return ""
	var id:=k.trim_prefix("mat1:")
	return id if id in combinaciones() and k=="mat1:"+id else ""

static func receta_material(id: String) -> Dictionary:
	if not id in combinaciones(): return {}
	var r:=reglas()
	var p:=id.split("_")
	var ent: Dictionary={}
	ent[str(r.materiales[p[0]].item)]=int(r.laminados.coste_nucleo)
	ent[str(r.materiales[p[1]].item)]=int(r.laminados.coste_refuerzo)
	return {"n":material(id).nombre.capitalize(),"ent":ent,"sal":{"mat1:"+id:1},"est":r.laminados.estacion}

## Eficacia de un material en una forma: media ponderada de dureza y tenacidad con los pesos de esa forma.
static func eficacia(m: Dictionary, pesos: Dictionary) -> float:
	return float(pesos.dureza)*float(m.dureza)+float(pesos.tenacidad)*float(m.tenacidad)

## Velocidad que aporta el material: más denso que la referencia resta, más ligero suma.
static func velocidad(m: Dictionary) -> float:
	var pr: Dictionary=reglas().propiedades
	return (float(pr.referencia_densidad)-float(m.densidad))*float(pr.vel_por_densidad)

static func clave(forma: String, material: String, tecnica: String, calidad: int) -> String:
	return "art1:%s:%s:%s:%d" % [forma, material, tecnica, calidad]

## Rechaza formas incompatibles, índices fuera de límite y cualquier representación no canónica.
static func leer(k: String) -> Dictionary:
	if not k.begins_with(PREFIJO): return {}
	var partes := k.split(":")
	if partes.size() != 5 or not partes[4].is_valid_int(): return {}
	var r := reglas()
	var q := int(partes[4])
	if not r.formas.has(partes[1]) or material(partes[2]).is_empty() or not r.tecnicas.has(partes[3]): return {}
	if not partes[1] in material(partes[2]).formas or q < 0 or q > int(r.calidad_max): return {}
	if k != clave(partes[1], partes[2], partes[3], q): return {}
	return {"forma":partes[1], "material":partes[2], "tecnica":partes[3], "calidad":q}

## «Espada de hierro reforzada (experta)»: concuerda género y número de la técnica y la calidad con la forma.
static func _nombre(forma: String, f: Dictionary, m: Dictionary, t: Dictionary, calidad: int) -> String:
	var tecnica: String = t.nombre
	var cal: String = reglas().calidades[calidad]
	var masculino: bool = forma in ["casco","escudo","guantes","pantalones"]
	var plural: bool = forma in ["guantes","botas","pantalones"]
	if masculino:
		if tecnica.ends_with("a"): tecnica=tecnica.left(-1)+"o"
		if cal.ends_with("a"): cal=cal.left(-1)+"o"
	if plural:
		tecnica+="s"
		cal="comunes" if cal=="común" else cal+"s"
	return "%s de %s %s (%s)" % [f.nombre,m.nombre,tecnica,cal]

## Propiedades estables de una pieza ya fabricada; practicar no modifica piezas anteriores.
static func info(k: String) -> Dictionary:
	var mat:=leer_material(k)
	if mat!="": return {"n":material(mat).nombre.capitalize(),"pila":int(reglas().laminados.pila),"c":material(mat).color,"material":mat}
	var p := leer(k)
	if p.is_empty(): return {}
	var r := reglas()
	var f: Dictionary = r.formas[p.forma]
	var m: Dictionary = material(p.material)
	var t: Dictionary = r.tecnicas[p.tecnica]
	var potencia := eficacia(m, f.pesos) * float(t.potencia) * (1.0 + int(p.calidad) * float(r.extra_calidad))
	return {"n":_nombre(p.forma, f, m, t, int(p.calidad)),
		"pila":1, "equipo":f.ranura, "dmg":roundi(float(f.dmg)*potencia), "def":roundi(float(f.def)*potencia),
		"hp":roundi(float(f.hp)*potencia), "vel":velocidad(m)+float(t.vel), "c":m.color, "artesania":p}

static func receta(k: String) -> Dictionary:
	var p := leer(k)
	if p.is_empty(): return {}
	var r := reglas()
	var m: Dictionary = material(p.material)
	var ent := {str(m.item):int(m.coste)*int(r.formas[p.forma].coste)}
	for item in r.tecnicas[p.tecnica].extra: ent[item] = int(ent.get(item,0)) + int(r.tecnicas[p.tecnica].extra[item])
	return {"n":info(k).n, "ent":ent, "sal":{k:1}, "est":"mesa"}

## Reutiliza geometría existente y recolorea por material; no promete siluetas nuevas.
static func visible(k: String) -> Dictionary:
	var p := leer(k)
	if p.is_empty(): return {}
	return _visible(k, p)

static func _visible(k: String, p: Dictionary) -> Dictionary:
	var m: Dictionary = material(p.material)
	var color := Color(m.color)
	return {"ranura":"espada" if p.forma=="espada" else reglas().formas[p.forma].ranura,
		"arquetipo":m.arquetipo, "familia":k, "item":k,
		"paleta":{"principal":color.to_html(),"sombra":color.darkened(0.3).to_html(),"acento":color.lightened(0.2).to_html(),"detalle":"#e4dbb8"}, "delta":{}}

# ---------- art2: variantes con operadores (I1a) ----------
# Clave canónica «art2:forma:material:tecnica:calidad:refuerzo:grosor». Siempre lleva ambos operadores y al menos uno no
# predeterminado (sin operadores la pieza es art1:, así no hay dos identidades para lo mismo). Las estadísticas se CALCULAN
# con las propiedades del catálogo y los coeficientes de reglas.operadores; ninguna variante figura en un JSON. Las técnicas
# no añaden insumos en art2: el insumo lo aporta el refuerzo. Aún no se integra en equipo/inventario/red (E3).

static func clave2(forma: String, material: String, tecnica: String, calidad: int, refuerzo: String, grosor: String) -> String:
	return "art2:%s:%s:%s:%d:%s:%s" % [forma, material, tecnica, calidad, refuerzo, grosor]

## ¿Es un refuerzo posible para esta forma y este material? Solo depende de los datos de operadores y del catálogo de materiales.
static func refuerzo_admitido(forma: String, material: String, refuerzo: String) -> bool:
	var op: Dictionary = reglas().operadores.refuerzo
	if refuerzo == op.defecto: return true
	if not op.niveles.has(refuerzo) or not material in op.base: return false
	var rm: String = op.niveles[refuerzo].material
	return rm != material and reglas().materiales.has(rm) and forma in reglas().materiales[rm].formas

## Propiedades del material tras aplicar el refuerzo: suma k·propiedad del refuerzo; la densidad también sube.
static func material_reforzado(m: Dictionary, refuerzo: String) -> Dictionary:
	var op: Dictionary = reglas().operadores.refuerzo
	if refuerzo == op.defecto: return m
	var n: Dictionary = op.niveles[refuerzo]
	var rm: Dictionary = reglas().materiales[n.material]
	var k := float(n.k)
	var r := m.duplicate()
	r.dureza = float(m.dureza) + k * float(rm.dureza)
	r.tenacidad = float(m.tenacidad) + k * float(rm.tenacidad)
	r.densidad = float(m.densidad) + float(op.k_densidad) * k * float(rm.densidad)
	return r

## Potencia sin redondear de una pieza descrita por `leer2` (o con operadores cambiados por el llamador).
static func potencia2(p: Dictionary) -> float:
	var r := reglas()
	var m := material_reforzado(material(p.material), p.refuerzo)
	return eficacia(m, r.formas[p.forma].pesos) * float(r.operadores.grosor.niveles[p.grosor].potencia) \
		* float(r.tecnicas[p.tecnica].potencia) * (1.0 + int(p.calidad) * float(r.extra_calidad))

## Beneficio de potencia de los operadores sobre la misma pieza sin ellos (técnica y calidad se cancelan).
static func razon2(p: Dictionary) -> float:
	var base := p.duplicate()
	base.refuerzo = reglas().operadores.refuerzo.defecto
	base.grosor = reglas().operadores.grosor.defecto
	return potencia2(p) / potencia2(base)

## Rechaza lo no canónico, combinaciones imposibles, ambos operadores predeterminados y lo que supere el presupuesto.
static func leer2(k: String) -> Dictionary:
	if not k.begins_with(PREFIJO2): return {}
	var partes := k.split(":")
	if partes.size() != 7 or not partes[4].is_valid_int(): return {}
	var r := reglas()
	var q := int(partes[4])
	var op: Dictionary = r.operadores
	if not r.formas.has(partes[1]) or not r.materiales.has(partes[2]) or not r.tecnicas.has(partes[3]): return {}
	if not partes[1] in r.materiales[partes[2]].formas or q < 0 or q > int(r.calidad_max): return {}
	if not op.refuerzo.niveles.has(partes[5]) or not op.grosor.niveles.has(partes[6]): return {}
	if partes[5] == op.refuerzo.defecto and partes[6] == op.grosor.defecto: return {}
	if not refuerzo_admitido(partes[1], partes[2], partes[5]): return {}
	if k != clave2(partes[1], partes[2], partes[3], q, partes[5], partes[6]): return {}
	var p := {"forma":partes[1], "material":partes[2], "tecnica":partes[3], "calidad":q, "refuerzo":partes[5], "grosor":partes[6]}
	if razon2(p) > float(op.potencia_max) + 0.000001: return {}
	return p

static func info2(k: String) -> Dictionary:
	var p := leer2(k)
	if p.is_empty(): return {}
	var r := reglas()
	var f: Dictionary = r.formas[p.forma]
	var m: Dictionary = material(p.material)
	var mr := material_reforzado(m, p.refuerzo)
	var t: Dictionary = r.tecnicas[p.tecnica]
	var g: Dictionary = r.operadores.grosor.niveles[p.grosor]
	var potencia := potencia2(p)
	var nombre := _nombre(p.forma, f, m, t, int(p.calidad))
	if p.refuerzo != r.operadores.refuerzo.defecto: nombre += " · refuerzo de " + str(r.materiales[r.operadores.refuerzo.niveles[p.refuerzo].material].nombre)
	if p.grosor != r.operadores.grosor.defecto: nombre += " · grosor " + str(p.grosor)
	return {"n":nombre, "pila":1, "equipo":f.ranura, "dmg":roundi(float(f.dmg)*potencia), "def":roundi(float(f.def)*potencia),
		"hp":roundi(float(f.hp)*potencia), "vel":velocidad(mr)+float(t.vel)+float(g.vel), "c":m.color, "artesania":p}

## Insumos reales: material base (× coste de la forma × coste del grosor, hacia arriba) más el insumo del refuerzo.
static func receta2(k: String) -> Dictionary:
	var p := leer2(k)
	if p.is_empty(): return {}
	var r := reglas()
	var m: Dictionary = material(p.material)
	var f: Dictionary = r.formas[p.forma]
	var ent := {str(m.item): ceili(float(m.coste) * int(f.coste) * float(r.operadores.grosor.niveles[p.grosor].coste) - 0.000001)}
	if p.refuerzo != r.operadores.refuerzo.defecto:
		var item := str(r.materiales[r.operadores.refuerzo.niveles[p.refuerzo].material].item)
		ent[item] = int(ent.get(item, 0)) + int(r.operadores.refuerzo.coste_por_forma) * int(f.coste)
	return {"n":info2(k).n, "ent":ent, "sal":{k:1}, "est":"mesa"}

static func visible2(k: String) -> Dictionary:
	var p := leer2(k)
	return {} if p.is_empty() else _visible(k, p)

## Todas las claves art2: válidas, ordenadas. SOLO para pruebas e informes: recorre el espacio completo y no debe llamarse
## desde ticks, `planos` ni búsquedas de NPC (PLAN_MAESTRO, línea base de coste de artesanía).
static func enumerar2() -> Array:
	var r := reglas()
	var formas: Array = r.formas.keys()
	var materiales: Array = r.materiales.keys()
	var tecnicas: Array = r.tecnicas.keys()
	var refuerzos: Array = r.operadores.refuerzo.niveles.keys()
	var grosores: Array = r.operadores.grosor.niveles.keys()
	for lista in [formas, materiales, tecnicas, refuerzos, grosores]: lista.sort()
	var lista: Array = []
	for f in formas:
		for m in materiales:
			for t in tecnicas:
				for q in int(r.calidad_max) + 1:
					for rf in refuerzos:
						for g in grosores:
							var k := clave2(f, m, t, q, rf, g)
							if not leer2(k).is_empty(): lista.append(k)
	return lista

## Referencias verificables de materiales; no inventa nuevos recursos.
static func validar() -> Array:
	var r := reglas()
	var errores: Array = []
	for id in r.materiales:
		var m: Dictionary = r.materiales[id]
		if not C.ITEMS.has(m.item) or int(m.coste)<=0: errores.append("material inválido: "+id)
		for prop in ["dureza","tenacidad","densidad"]:
			if not m.has(prop) or float(m[prop])<=0.0: errores.append("propiedad inválida: %s.%s" % [id, prop])
		for f in m.formas:
			if not r.formas.has(f): errores.append("forma inexistente: "+str(f))
	for f in r.formas:
		var pesos: Dictionary=r.formas[f].get("pesos",{})
		if not pesos.has("dureza") or not pesos.has("tenacidad") or absf(float(pesos.get("dureza",0))+float(pesos.get("tenacidad",0))-1.0)>0.000001 or float(pesos.get("dureza",0))<0.0 or float(pesos.get("tenacidad",0))<0.0:
			errores.append("pesos de forma inválidos: "+f)
	for t in r.tecnicas:
		for item in r.tecnicas[t].extra:
			if not C.ITEMS.has(item) or int(r.tecnicas[t].extra[item])<=0: errores.append("coste inválido: "+str(item))
	var op: Dictionary = r.get("operadores", {})
	if op.is_empty(): errores.append("faltan los operadores")
	else:
		if float(op.get("potencia_max", 0.0)) < 1.0: errores.append("potencia_max de operadores inválida")
		var ref: Dictionary = op.get("refuerzo", {})
		if not ref.get("niveles", {}).has(ref.get("defecto", "?")): errores.append("refuerzo sin nivel predeterminado")
		for b in ref.get("base", []): if not r.materiales.has(b): errores.append("refuerzo: material base inexistente " + str(b))
		for n in ref.get("niveles", {}):
			if n == ref.get("defecto", ""): continue
			var d: Dictionary = ref.niveles[n]
			if not r.materiales.has(d.get("material", "")) or float(d.get("k", 0.0)) <= 0.0: errores.append("refuerzo inválido: " + str(n))
		if int(ref.get("coste_por_forma", 0)) <= 0 or float(ref.get("k_densidad", -1.0)) < 0.0: errores.append("refuerzo: coste o densidad inválidos")
		var gro: Dictionary = op.get("grosor", {})
		if not gro.get("niveles", {}).has(gro.get("defecto", "?")): errores.append("grosor sin nivel predeterminado")
		for n in gro.get("niveles", {}):
			var d: Dictionary = gro.niveles[n]
			if float(d.get("potencia", 0.0)) <= 0.0 or float(d.get("coste", 0.0)) <= 0.0 or not d.has("vel"): errores.append("grosor inválido: " + str(n))
	return errores
