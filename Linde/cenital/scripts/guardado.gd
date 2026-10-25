extends RefCounted
# Guardado versionado: archivo = {formato, checksum, cuerpo(JSON como texto)}. El checksum va sobre el texto
# exacto del cuerpo (no sobre un re-serializado, que cambiaría int/float).
# Escritura: .tmp -> validar -> principal a .bak (si era válido) -> renombrar. Nunca se pisa en silencio una partida corrupta.
const FORMATO := 3     # 3: equipo de 6 ranuras con claves `eq:`; 2: estado por jugador en d.jugadores[id]; 1: un solo jugador en la raíz
# 2 -> 3 (Linde/documentos/sistema-de-equipo.md 7.3): equipo provisional heredado -> piezas de Vigía; ranura coraza -> torso.
const HEREDADO := {"casco_hierro": "eq:vigia:casco::0", "coraza_hierro": "eq:vigia:torso::0"}
const RANURAS_3 := ["casco", "torso", "guantes", "botas", "pantalones", "escudo"]
const LOCAL := "local"
# Claves de la raíz del formato 1 que pasan a ser de cada jugador (pj se aplana dentro del jugador).
const DEL_JUGADOR := ["inv", "equipo", "hab", "xp", "misiones", "eventos", "recompensas", "pendientes"]

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
	var generacion = d.get("mundo",{}).get("generacion",null)
	if generacion!=null:
		if not generacion is Dictionary:return {}
		if int(generacion.get("version",-1)) not in [1,2] or int(generacion.get("region",-1))!=16:return {}
		if not typeof(generacion.get("semilla")) in [TYPE_INT,TYPE_FLOAT]:return {}
	if f < 1:
		d["hab"] = d.get("hab", [])
		d["eventos"] = d.get("eventos", {})
		d["recompensas"] = d.get("recompensas", [])
		d["formato"] = 1
	if f < 2:   # 1 -> 2: el único jugador pasa a jugadores["local"]; la relación con habitantes y la propiedad de construcciones, también
		var pj: Dictionary = d.get("pj", {}).duplicate()
		for k in DEL_JUGADOR:
			if d.has(k): pj[k] = d[k]
			d.erase(k)
		var rel := {}
		for npc in d.get("npcs", {}):
			var n: Dictionary = d.npcs[npc]
			if n.has("relacion"): rel[npc] = n.relacion
			n.erase("relacion")
		pj["relacion"] = rel
		for c in d.get("mundo", {}).get("constr", {}).values():
			if c.get("propia", false): c["dueno"] = LOCAL
		d.erase("pj")
		d["jugadores"] = {LOCAL: pj}
		d["formato"] = 2
	if f < 3:   # 2 -> 3: por jugador, en inventario y equipo; lo desconocido se conserva tal cual (Pieza desconocida)
		for id in d.get("jugadores", {}):
			var pj: Dictionary = d.jugadores[id]
			for col in ["inv", "pendientes"]:
				var inv: Dictionary = pj.get(col, {})
				for k in inv.keys():
					if HEREDADO.has(k):
						inv[HEREDADO[k]] = inv.get(HEREDADO[k], 0) + inv[k]
						inv.erase(k)
			var eq: Dictionary = pj.get("equipo", {})
			if eq.has("coraza"):
				if str(eq.get("torso", "")) == "": eq["torso"] = eq.coraza
				elif str(eq.coraza) != "": pj["pendientes"] = _sumar(pj.get("pendientes", {}), str(eq.coraza))   # no se pierde
				eq.erase("coraza")
			for r in eq: eq[r] = HEREDADO.get(str(eq[r]), eq[r])
			for r in RANURAS_3: if not eq.has(r): eq[r] = ""
			pj["equipo"] = eq
		d["formato"] = 3
	return d

static func _sumar(m: Dictionary, k: String) -> Dictionary:
	m[k] = int(m.get(k, 0)) + 1
	return m

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
