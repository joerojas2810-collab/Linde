extends RefCounted
## Gramática de piezas; no registra un catálogo de cada combinación. Claves versionadas y canónicas.
const C = preload("res://scripts/catalogos.gd")
const PREFIJO := "art1:"
static var _reglas: Dictionary = {}

static func reglas() -> Dictionary:
	if _reglas.is_empty():
		_reglas = JSON.parse_string(FileAccess.get_file_as_string("res://datos/desarrollo/reglas_v1.json"))
	return _reglas

static func clave(forma: String, material: String, tecnica: String, calidad: int) -> String:
	return "art1:%s:%s:%s:%d" % [forma, material, tecnica, calidad]

## Rechaza formas incompatibles, índices fuera de límite y cualquier representación no canónica.
static func leer(k: String) -> Dictionary:
	if not k.begins_with(PREFIJO): return {}
	var partes := k.split(":")
	if partes.size() != 5 or not partes[4].is_valid_int(): return {}
	var r := reglas()
	var q := int(partes[4])
	if not r.formas.has(partes[1]) or not r.materiales.has(partes[2]) or not r.tecnicas.has(partes[3]): return {}
	if not partes[1] in r.materiales[partes[2]].formas or q < 0 or q > int(r.calidad_max): return {}
	if k != clave(partes[1], partes[2], partes[3], q): return {}
	return {"forma":partes[1], "material":partes[2], "tecnica":partes[3], "calidad":q}

## Propiedades estables de una pieza ya fabricada; practicar no modifica piezas anteriores.
static func info(k: String) -> Dictionary:
	var p := leer(k)
	if p.is_empty(): return {}
	var r := reglas()
	var f: Dictionary = r.formas[p.forma]
	var m: Dictionary = r.materiales[p.material]
	var t: Dictionary = r.tecnicas[p.tecnica]
	var potencia := float(m.potencia) * float(t.potencia) * (1.0 + int(p.calidad) * float(r.extra_calidad))
	return {"n":"%s de %s %s (%s)" % [f.nombre,m.nombre,t.nombre,r.calidades[int(p.calidad)]],
		"pila":1, "equipo":f.ranura, "dmg":roundi(float(f.dmg)*potencia), "def":roundi(float(f.def)*potencia),
		"hp":roundi(float(f.hp)*potencia), "vel":float(m.vel)+float(t.vel), "c":m.color, "artesania":p}

static func receta(k: String) -> Dictionary:
	var p := leer(k)
	if p.is_empty(): return {}
	var r := reglas()
	var m: Dictionary = r.materiales[p.material]
	var ent := {str(m.item):int(m.coste)*int(r.formas[p.forma].coste)}
	for item in r.tecnicas[p.tecnica].extra: ent[item] = int(ent.get(item,0)) + int(r.tecnicas[p.tecnica].extra[item])
	return {"n":info(k).n, "ent":ent, "sal":{k:1}, "est":"mesa"}

## Reutiliza geometría existente y recolorea por material; no promete siluetas nuevas.
static func visible(k: String) -> Dictionary:
	var p := leer(k)
	if p.is_empty(): return {}
	var m: Dictionary = reglas().materiales[p.material]
	var color := Color(m.color)
	return {"ranura":"espada" if p.forma=="espada" else reglas().formas[p.forma].ranura,
		"arquetipo":m.arquetipo, "familia":k, "item":k,
		"paleta":{"principal":color.to_html(),"sombra":color.darkened(0.3).to_html(),"acento":color.lightened(0.2).to_html(),"detalle":"#e4dbb8"}, "delta":{}}

## Referencias verificables de materiales; no inventa nuevos recursos.
static func validar() -> Array:
	var r := reglas()
	var errores: Array = []
	for id in r.materiales:
		var m: Dictionary = r.materiales[id]
		if not C.ITEMS.has(m.item) or int(m.coste)<=0: errores.append("material inválido: "+id)
		for f in m.formas:
			if not r.formas.has(f): errores.append("forma inexistente: "+str(f))
	for t in r.tecnicas:
		for item in r.tecnicas[t].extra:
			if not C.ITEMS.has(item) or int(r.tecnicas[t].extra[item])<=0: errores.append("coste inválido: "+str(item))
	return errores
