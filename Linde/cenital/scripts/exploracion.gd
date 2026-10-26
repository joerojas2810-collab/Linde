extends RefCounted
## Mapa personal: reutiliza la cuadrícula y el radio de visión de Autonomia.
## Solo guarda bloques y procedencia, nunca copias del terreno ni destinos nuevos.
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
	if not j.habitantes.ids.has(npc) or j.habitantes.pos(npc).distance_to(j.pies_de(id)) > j.ALCANCE_NPC:
		return j._no("Acércate para preguntar por lugares.", id)
	observar(j, id)
	var mapa: Dictionary = j.jug(id).get_or_add("mapa", {"bloques": {}})
	if not j.autonomia.estado(npc).has("bloques"): j.autonomia._explorar(npc)
	var n: Dictionary = j.autonomia.estado(npc).bloques
	var nuevos := 0
	for k in n:
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
	return salida
