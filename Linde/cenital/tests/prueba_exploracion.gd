extends SceneTree
## Contrato M1-F2. Presupuesto previo: 4 MiB por mapa tras 60 min a velocidad actual.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const S = preload("res://scripts/red_servidor.gd")
var fallos := 0
func ok(c: bool, texto: String) -> void:
	print(("PASS " if c else "FAIL ") + texto)
	if not c: fallos += 1
func _init() -> void:
	var j = J.nueva(123, "Explorador", [0, 0, 0], "poblado")
	var esperado := {"bloques": {}}
	j.autonomia._ver(esperado, M.celda_de(j.pies), int(j.autonomia.reglas.conocimiento.radio_vision))
	ok(j.jug().mapa.bloques.keys() == esperado.bloques.keys(), "inicio contiene exactamente el radio de visión existente")
	var prev: Dictionary = j.jug().mapa.bloques.duplicate()
	for c in [Vector2i(-8, -8), Vector2i(-16, -8), Vector2i(0, -8)]:
		j.pies = M.pies_de_celda(c)
		j.autonomia._ver(esperado, c, int(j.autonomia.reglas.conocimiento.radio_vision))
		j.actualizar_mapa()
	ok(j.jug().mapa.bloques.keys() == esperado.bloques.keys(), "ruta y coordenadas negativas descubren exactamente lo observado")
	j.unir("otro", "Otro", [0, 0, 0])
	ok(not j.jug("otro").mapa.bloques.has("-2,-1"), "otro jugador no hereda descubrimientos")
	var npc: String = j.habitantes.ids[0]
	ok(not j.preguntar_lugares(npc).ok, "rechaza intercambio lejano")
	j.pies = j.habitantes.pos(npc)
	j.autonomia.estado(npc)["bloques"] = {"100,100": true}
	ok(j.preguntar_lugares(npc).ok and j.jug().mapa.bloques["100,100"] == "npc:" + npc, "rumor persiste con procedencia")
	ok(j.autonomia.estado(npc).bloques.has("-2,-1"), "NPC recibe lo explorado por el jugador")
	j.pies = M.pies_de_celda(Vector2i(800, 800))
	j.actualizar_mapa()
	ok(j.jug().mapa.bloques["100,100"] == "visto", "visitar confirma un rumor")
	var srv = S.new()
	srv.j = j
	var e: Dictionary = srv.estado_para("otro")
	ok(e.jugadores.size() == 1 and not e.jugadores.local.get("mapa", {}).get("bloques", {}).has("100,100"), "bienvenida excluye el mapa ajeno")
	ok(not JSON.stringify(srv.perfiles()).contains("mapa"), "perfiles públicos sin mapas")
	srv.free()
	var ruta := "/tmp/linde-f2-persistencia.json"
	ok(j.guardar(ruta), "guarda mapa")
	var cargado = J.cargar(ruta)
	ok(cargado != null and cargado.jug().mapa == j.jug().mapa, "carga conserva descubrimientos y fuentes")
	# Ruta máxima recta de 60 minutos reales (4 celdas/s), sin simular ni cambiar balance.
	j.jug().mapa.bloques.clear()
	for x in range(0, 14401, 8):
		j.pies = M.pies_de_celda(Vector2i(x, 0))
		j.actualizar_mapa()
	var bytes := JSON.stringify(j.jug().mapa).to_utf8_buffer().size()
	print("MAPA_60_MIN bloques=%d bytes=%d presupuesto=4194304" % [j.jug().mapa.bloques.size(), bytes])
	ok(bytes < 4194304, "mapa de 60 min dentro del presupuesto de 4 MiB")
	var legado = J.nueva(123, "Legado", [0, 0, 0])
	legado.actualizar_mapa()
	legado.pies = legado.habitantes.pos(legado.habitantes.ids[0])
	legado.preguntar_lugares(legado.habitantes.ids[0])
	ok(not legado.jug().has("mapa"), "legado no añade estado ni permite intercambio")
	quit(1 if fallos else 0)
