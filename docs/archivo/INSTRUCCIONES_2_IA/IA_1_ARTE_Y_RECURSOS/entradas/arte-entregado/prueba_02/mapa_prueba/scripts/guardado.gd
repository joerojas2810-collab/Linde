extends RefCounted
# Guardado versionado: archivo = {formato, checksum, cuerpo(JSON como texto)}. El checksum va sobre el texto
# exacto del cuerpo (no sobre un re-serializado, que cambiaría int/float).
# Escritura: .tmp -> validar -> principal a .bak (si era válido) -> renombrar. Nunca se pisa en silencio una partida corrupta.
const FORMATO := 1

static func empaquetar(d: Dictionary) -> String:
	var cuerpo := JSON.stringify(d, "", true)
	return JSON.stringify({"formato": d.get("formato", FORMATO), "checksum": cuerpo.sha256_text(), "cuerpo": cuerpo})

# Devuelve {} si el texto no es válido (checksum, JSON, formato futuro o migración imposible).
static func desempaquetar(txt: String) -> Dictionary:
	var o = JSON.parse_string(txt)
	if typeof(o) != TYPE_DICTIONARY or not o.has("cuerpo") or not o.has("checksum"): return {}
	if str(o.cuerpo).sha256_text() != o.checksum: return {}
	var d = JSON.parse_string(o.cuerpo)
	if typeof(d) != TYPE_DICTIONARY: return {}
	return migrar(d)

# Migraciones: v0 es un formato sintético de prueba del mecanismo (sin habilidades/eventos).
static func migrar(d: Dictionary) -> Dictionary:
	var f := int(d.get("formato", 0))
	if f > FORMATO: return {}
	if f < 1:
		d["hab"] = d.get("hab", [])
		d["eventos"] = d.get("eventos", {})
		d["recompensas"] = d.get("recompensas", [])
		d["formato"] = 1
	return d

static func _leer(ruta: String) -> String:
	var f := FileAccess.open(ruta, FileAccess.READ)
	return f.get_as_text() if f else ""

static func guardar(ruta: String, d: Dictionary) -> bool:
	var txt := empaquetar(d)
	var tmp := ruta + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(txt)
	f.close()
	if desempaquetar(_leer(tmp)).is_empty(): return false      # verificación de lectura
	if FileAccess.file_exists(ruta):
		if desempaquetar(_leer(ruta)).is_empty():
			DirAccess.rename_absolute(ruta, ruta + ".corrupta")   # se conserva, no se borra
		else:
			DirAccess.copy_absolute(ruta, ruta + ".bak")
	return DirAccess.rename_absolute(tmp, ruta) == OK

# {d, origen} con origen "principal" | "respaldo"; d vacío si no hay nada utilizable.
static func cargar(ruta: String) -> Dictionary:
	for par in [[ruta, "principal"], [ruta + ".bak", "respaldo"]]:
		if FileAccess.file_exists(par[0]):
			var d := desempaquetar(_leer(par[0]))
			if not d.is_empty(): return {"d": d, "origen": par[1]}
	return {"d": {}, "origen": ""}
