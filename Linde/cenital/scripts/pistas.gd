extends RefCounted
## Ayuda opcional por contexto real: no crea objetivos, recompensas ni altera la simulación.
const M = preload("res://scripts/mundo.gd")
const Eq = preload("res://scripts/equipo.gd")
static var _datos: Dictionary = {}

## Reglas de presentación; sus tiempos no cambian el reloj ni los sistemas del mundo.
static func datos() -> Dictionary:
	if _datos.is_empty(): _datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/pistas.json"))
	return _datos

## Predicados de solo lectura para reglas en datos. No siembran saberes ni inventan eventos.
static func cumple(j, id: String, condicion: String) -> bool:
	var pj: Dictionary = j.jug(id)
	match condicion:
		"enemigo_cerca": return j.combate.hay_enemigo_cerca(float(datos().radio_amenaza_px), id)
		"herido": return float(pj.hp) < float(j.stats(id).hp) * float(datos().proporcion_vida)
		"npc_cerca":
			for npc in j.habitantes.ids:
				if j.habitantes.pos(npc).distance_to(j.pies_de(id)) <= j.ALCANCE_NPC: return true
		"mesa", "horno": return j.estacion_junto(id) == condicion
		"rumor":
			for fuente in pj.get("mapa", {}).get("bloques", {}).values():
				if str(fuente).begins_with("npc:"): return true
		"exterior": return not M.es_valle(M.celda_de(j.pies_de(id)))
		"noche": return j.hora_dia() >= float(datos().noche_desde) or j.hora_dia() < float(datos().noche_hasta)
		"madera", "piedra": return int(pj.inv.get(condicion, 0)) > 0
		"equipable":
			for k in pj.inv:
				if str(Eq.info(k).get("equipo", "")) != "": return true
		"saber_pendiente":
			var des = j.autonomia.desarrollo
			# Técnica ligera existente: la consulta sabe es de solo lectura.
			return des.activa() and not des.sabe(j.actor_desarrollo(id), str(datos().saber_clave)) and int(pj.inv.get("madera", 0)) > 0
		"cama_propia": return not pj.cama.is_empty()
		"hito": return j.mundo.hito_en(M.celda_de(j.pies_de(id))) != ""
	return false

## Comandos autorizados sobre el jugador solicitante. Una sola pista activa por sesión.
static func accion(j, id: String, comando: String) -> void:
	if not j.es_autoridad() or j.mundo.modo_inicio() != "poblado": return
	var p: Dictionary = j.jug(id).get_or_add("pistas", {"mostradas": {}, "descartadas": {}, "silenciadas": false})
	var s: Dictionary = j.rt[id]
	if comando in ["silenciar", "activar"]:
		p.silenciadas = comando == "silenciar"
		if p.silenciadas: s["pista_actual"] = {}
		return
	if comando == "descartar":
		var actual: Dictionary = s.get("pista_actual", {})
		if not actual.is_empty(): p.descartadas[actual.id] = true
		s["pista_actual"] = {}
		return
	if comando != "pedir" or p.silenciadas or not s.get("pista_actual", {}).is_empty() or float(s.get("pista_espera", 0)) > 0: return
	for r in datos().reglas:
		if p.mostradas.has(r.id) or p.descartadas.has(r.id) or not cumple(j, id, r.precondicion): continue
		p.mostradas[r.id] = true
		s["pista_actual"] = {"id": r.id, "texto": r.texto}
		s["pista_t"] = float(datos().duracion_s)
		s["pista_espera"] = float(r.get("enfriamiento_s", datos().enfriamiento_s))
		return

## Temporizadores de sesión: ni la pista activa ni el enfriamiento se guardan.
static func paso(j, id: String, dt: float) -> void:
	var s: Dictionary = j.rt[id]
	if not s.has("pista_t"): return
	s.pista_espera = maxf(0, float(s.pista_espera) - dt)
	s.pista_t = maxf(0, float(s.pista_t) - dt)
	if s.pista_t == 0: s.pista_actual = {}
