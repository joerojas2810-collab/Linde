extends RefCounted
## Mapa personal: reutiliza la cuadrícula y el radio de visión de Autonomia.
## Solo guarda bloques y procedencia; las identidades compartidas vienen del registro del mundo.
const M = preload("res://scripts/mundo.gd")

## Actualiza lo visto desde la posición autoritativa; legado conserva su estado exacto.
static func observar(j, id: String) -> void:
	if not j.es_autoridad() or j.d.mundo.get("inicio", {}).get("modo", "legado") != "poblado": return
	var mapa: Dictionary = j.jug(id).get_or_add("mapa", {"bloques": {}})
	var vistos := {"bloques": {}}
	j.autonomia._ver(vistos, M.celda_de(j.pies_de(id)), int(j.autonomia.reglas.conocimiento.radio_vision))
	for k in vistos.bloques: mapa.bloques[k] = "visto"

## Intercambio voluntario y cercano: el NPC aporta rumores; recibe lo recorrido por el jugador.
## Un rumor conserva la primera fuente y nunca sustituye un bloque visto personalmente.
static func intercambiar(j, npc: String, id: String) -> Dictionary:
	if not j.es_autoridad() or j.mundo.modo_inicio() != "poblado":
		return j._no("El mapa personal está disponible en mundos de poblado.", id)
	var regional: Dictionary = j.autonomia.asentamientos.residente(npc)
	var detallado: bool = j.habitantes.ids.has(npc)
	var pos: Vector2 = j.habitantes.pos(npc) if detallado else j.autonomia.asentamientos.posicion(npc)
	if (not detallado and regional.is_empty()) or pos.distance_to(j.pies_de(id)) > j.ALCANCE_NPC:
		return j._no("Acércate para preguntar por lugares.", id)
	observar(j, id)
	var mapa: Dictionary = j.jug(id).get_or_add("mapa", {"bloques": {}})
	if detallado and not j.autonomia.estado(npc).has("bloques"): j.autonomia._explorar(npc)
	if not detallado and not regional.has("bloques"):
		regional.bloques = {}
		j.autonomia._ver(regional,M.celda_de(pos),int(j.autonomia.reglas.conocimiento.radio_inicial))
	var n: Dictionary = j.autonomia.estado(npc).bloques if detallado else regional.bloques
	var nuevos := 0
	for k in n:
		if not mapa.bloques.has(k):
			mapa.bloques[k] = "npc:" + npc
			nuevos += 1
	# Reutiliza también el horizonte conocido por los habitantes, sin inventar destinos ni revelar coordenadas exactas.
	for lugar in j.d.mundo.get("registro", {}).get("lugares", {}).values():
		var c := Vector2i(lugar.centro[0], lugar.centro[1])
		if (detallado and j.autonomia.conoce(npc, c)) or n.has(j.autonomia._bloque(c)):
			var k: String = j.autonomia._bloque(c)
			if not mapa.bloques.has(k):
				mapa.bloques[k] = "npc:" + npc
				nuevos += 1
	for k in mapa.bloques:
		if mapa.bloques[k] == "visto": n[k] = true
	return j._ok("Intercambiaron referencias: %d zonas nuevas en tu mapa (M). Son aproximadas; explóralas para confirmarlas." % nuevos, id)

## Hitos existentes cuyo centro cae en un bloque conocido; el rumor sigue siendo aproximado.
static func hitos(j, id: String) -> Array:
	var salida: Array = []
	var bloques: Dictionary = j.jug(id).get("mapa", {}).get("bloques", {})
	for pid in j.mundo.poblados_ids():
		for h in j.mundo.poblado(pid).get("hitos", []):
			var a: Array = h.area
			var c := Vector2i(int(a[0]) + int(a[2]) / 2, int(a[1]) + int(a[3]) / 2)
			var k: String = j.autonomia._bloque(c)
			if bloques.has(k): salida.append({"nombre": h.nombre, "bloque": k, "fuente": bloques[k]})
	var lugares: Dictionary = j.d.mundo.get("registro", {}).get("lugares", {})
	var ids: Array = lugares.keys()
	ids.sort()
	for lid in ids:
		var lugar: Dictionary = lugares[lid]
		var c := Vector2i(lugar.centro[0], lugar.centro[1])
		var k: String = j.autonomia._bloque(c)
		if bloques.has(k): salida.append({"id": lid, "nombre": lugar.nombre, "bloque": k, "fuente": bloques[k], "tipo": lugar.tipo})
	return salida
