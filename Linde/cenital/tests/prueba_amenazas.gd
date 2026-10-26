extends SceneTree
## Mundo 1, paso 1e: distribución inicial de amenazas en el núcleo habitado. En modo poblado los slimes no anidan a menos de NUCLEO_RADIO del
## centro de ningún poblado; siguen siendo los mismos N, con la misma generación determinista, y el modo legado no cambia.
## Uso: godot --headless --path Linde/cenital --script res://tests/prueba_amenazas.gd   (código de salida = nº de fallos)
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var fallos := 0

func ok(c: bool, t: String) -> void:
	print(("PASS " if c else "FAIL ") + t)
	if not c: fallos += 1

func _init() -> void:
	var base = M.new()
	var j_legado = J.nueva(123, "L", [0, 0, 0])
	ok(j_legado.mundo.spawns_slime == base.spawns_slime, "modo legado: los puntos de aparición de slimes son los de siempre")
	var j = J.nueva(123, "P", [0, 0, 0], M.MODO_POBLADO)
	var sp: Array = j.mundo.spawns_slime
	ok(sp.size() == M.N_SLIMES, "modo poblado: siguen existiendo %d slimes (las amenazas no desaparecen)" % M.N_SLIMES)
	var centro := M.CENTRO_INICIAL
	var min_d := 1e9
	for c in sp: min_d = minf(min_d, Vector2(c).distance_to(Vector2(centro)))
	ok(min_d >= M.NUCLEO_RADIO, "modo poblado: ningún slime a menos de %.0f celdas del centro (más cercano: %.1f)" % [M.NUCLEO_RADIO, min_d])
	var antes_min := 1e9
	for c in base.spawns_slime: antes_min = minf(antes_min, Vector2(c).distance_to(Vector2(centro)))
	ok(antes_min < M.NUCLEO_RADIO, "antes había un slime dentro del núcleo (a %.1f celdas): la corrección es necesaria" % antes_min)
	var conservados := 0
	for c in base.spawns_slime: if sp.has(c): conservados += 1
	var fuera_antes := 0
	for c in base.spawns_slime: if Vector2(c).distance_to(Vector2(centro)) >= M.NUCLEO_RADIO: fuera_antes += 1
	ok(conservados == fuera_antes, "los slimes que ya estaban fuera del núcleo conservan su lugar (%d de %d)" % [conservados, fuera_antes])
	var validos := true
	for c in sp: if j.mundo.tipo(c) != M.T.PASTO or j.mundo.por_celda.has(c): validos = false
	ok(validos, "los puntos nuevos son hierba libre de objetos")
	ok(j.combate.enemigos.filter(func(e): return e.tipo == "slime").size() == M.N_SLIMES, "el encuentro crea los %d slimes en los puntos nuevos" % M.N_SLIMES)
	# La derivación del radio: aparición máxima (7) + detección del slime en celdas.
	var deteccion_celdas: float = float(C.ENEMIGOS.slime.vision) / 16.0
	ok(M.NUCLEO_RADIO >= J.APARICION_RADIO_MAX + deteccion_celdas, "el radio del núcleo cubre el radio de aparición más la detección del slime (%.1f ≥ %.1f)" % [M.NUCLEO_RADIO, J.APARICION_RADIO_MAX + deteccion_celdas])
	# Determinismo y persistencia.
	var j2 = J.nueva(123, "P2", [0, 0, 0], M.MODO_POBLADO)
	ok(j2.mundo.spawns_slime == sp, "la misma semilla y modo dan los mismos puntos")
	var ruta := "/tmp/linde-amenazas-%d.json" % OS.get_process_id()
	ok(j.guardar(ruta), "guarda la partida")
	var carga = J.cargar(ruta)
	DirAccess.remove_absolute(ruta)
	ok(carga != null and carga.mundo.modo_inicio() == M.MODO_POBLADO and carga.mundo.spawns_slime == sp, "al cargar, el modo se conserva y los slimes vuelven a generarse en los mismos puntos")
	# No es una zona invulnerable: el combate no sabe del núcleo; un slime que persigue puede entrar en él.
	var e: Dictionary = j.combate._nuevo("slime", M.pies_de_celda(centro + Vector2i(13, 0)))   # fuera del núcleo, a 9 celdas del jugador (< 2×detección)
	j.combate.enemigos.append(e)
	e.est = "persigue"
	e.obj = J.LOCAL
	j.rt[J.LOCAL].pies = M.pies_de_celda(centro + Vector2i(4, 0))
	for i in 100: j.combate.paso(0.1)
	ok(Vector2(M.celda_de(e.pos) - centro).length() < M.NUCLEO_RADIO, "un slime que persigue entra en el núcleo: no hay zona invulnerable")
	print("AMENAZAS: %d fallos" % fallos)
	quit(fallos)
