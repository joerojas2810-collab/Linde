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

const Huella = preload("res://scripts/huella.gd")

# El cuerpo lleva `reglas` (sello de huella.gd). Un mundo nuevo se sella con las reglas actuales al guardarse (el sello
# queda en `d`, así el mundo vivo y el recargado coinciden); uno ya sellado (cargado) conserva el suyo, de modo que
# cambiar las reglas nunca "lava" un mundo.
static func empaquetar(d: Dictionary) -> String:
	if not d.get("reglas") is Dictionary: d["reglas"] = Huella.sello()
	var cuerpo := JSON.stringify(d, "", true)
	return JSON.stringify({"formato": d.get("formato", FORMATO), "checksum": cuerpo.sha256_text(), "cuerpo": cuerpo})

# {estado, d, ...}. estado: "ok" | "ok_con_excepcion" (reglas distintas aceptadas en modo de desarrollo; d.reglas queda
# marcado como contaminado) | "reglas_distintas" (d vacío; detalle = Huella.comparar) | "ilegible" (JSON o checksum
# erróneos) | "invalido" (formato futuro o migración imposible). Nunca escribe nada.
static func inspeccionar(txt: String) -> Dictionary:
	var o = JSON.parse_string(txt)
	if typeof(o) != TYPE_DICTIONARY or not o.has("cuerpo") or not o.has("checksum"): return {"estado": "ilegible", "d": {}}
	if str(o.cuerpo).sha256_text() != o.checksum: return {"estado": "ilegible", "d": {}}
	var d = JSON.parse_string(o.cuerpo)
	if typeof(d) != TYPE_DICTIONARY: return {"estado": "ilegible", "d": {}}
	d = migrar(d)
	if d.is_empty(): return {"estado": "invalido", "d": {}}
	var c := Huella.comparar(d.get("reglas"))
	if c.compatible: return {"estado": "ok", "d": d}
	if Huella.excepcion_dev():
		d["reglas"] = Huella.sello_contaminado(d.get("reglas"))
		return {"estado": "ok_con_excepcion", "d": d, "detalle": c}
	return {"estado": "reglas_distintas", "d": {}, "detalle": c}

# Devuelve {} si el texto no es utilizable (checksum, JSON, formato futuro, migración imposible o reglas distintas).
static func desempaquetar(txt: String) -> Dictionary:
	return inspeccionar(txt).d

# Migraciones: v0 es un formato sintético de prueba del mecanismo (sin habilidades/eventos).
static func migrar(d: Dictionary) -> Dictionary:
	var f := int(d.get("formato", 0))
	if f > FORMATO: return {}
	var registro = d.get("mundo", {}).get("registro", null)
	if registro != null and (not registro is Dictionary or int(registro.get("version", -1)) != 1): return {}
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
	if inspeccionar(_leer(tmp)).estado in ["ilegible", "invalido"]: return false      # verificación de lectura
	if FileAccess.file_exists(ruta):
		match inspeccionar(_leer(ruta)).estado:
			"ilegible", "invalido": DirAccess.rename_absolute(ruta, ruta + ".corrupta")   # se conserva, no se borra
			"reglas_distintas": DirAccess.copy_absolute(ruta, ruta + ".incompatible")   # íntegro, fuera de la rotación de .bak
			_: DirAccess.copy_absolute(ruta, ruta + ".bak")
	return DirAccess.rename_absolute(tmp, ruta) == OK

# {d, origen} con origen "principal" | "respaldo"; d vacío si no hay nada utilizable. Si el archivo es válido pero sus reglas
# no coinciden con las actuales: d vacío, `error` = "reglas_distintas", `detalle`, `motivo` y `archivo`; no se prueba el
# respaldo (sería volver atrás en silencio) ni se modifica nada. Una carga aceptada por la excepción de desarrollo
# añade `aviso`.
static func cargar(ruta: String) -> Dictionary:
	for par in [[ruta, "principal"], [ruta + ".bak", "respaldo"]]:
		if FileAccess.file_exists(par[0]):
			var r := inspeccionar(_leer(par[0]))
			if r.estado == "reglas_distintas":
				var motivo: String = r.detalle.motivo
				push_warning("Guardado: %s rechazado, %s" % [par[0], motivo])
				return {"d": {}, "origen": "", "error": "reglas_distintas", "detalle": r.detalle, "motivo": motivo, "archivo": par[0]}
			if not r.d.is_empty():
				var res := {"d": r.d, "origen": par[1]}
				if r.d.get("reglas", {}).get("contaminado", false):
					res["aviso"] = "Mundo cargado con reglas distintas a las de su creación"
					push_warning("Guardado: " + res.aviso)
				return res
	return {"d": {}, "origen": ""}
