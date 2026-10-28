extends SceneTree
## Humo del arranque: catálogo válido, mundo nuevo, reloj, combate y guardado/carga.
## Debe pasar tanto con el prototipo anterior como con el juego de campaña.
const C = preload("res://scripts/catalogos.gd")
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Guard = preload("res://scripts/guardado.gd")

var fallos := 0

func ok(cond: bool, nombre: String) -> void:
	print(("PASS " if cond else "FAIL ") + nombre)
	if not cond: fallos += 1

func _init() -> void:
	var errores: Array = C.validar()
	if not errores.is_empty(): print(errores)
	ok(errores.is_empty(), "catálogo: referencias válidas")
	var j = J.nueva(20261027, "Viajero", [0, 1, 0])
	ok(j != null, "partida nueva: se crea sin errores")
	if j == null:
		print("FALLOS: %d" % (fallos + 1))
		quit(1)
		return
	ok(int(j.d.get("formato", 0)) == Guard.FORMATO, "partida nueva: formato de guardado vigente")
	ok(j.d.jugadores.has(J.LOCAL), "partida nueva: jugador local presente")
	ok(j.mundo.celdas.size() == M.ANCHO * M.ALTO, "mundo: valle completo en memoria")
	ok(j.combate != null, "combate: inicializado")
	j.tick(0.25)
	ok(j.d.min >= 6 * 60, "reloj: avanza sin excepciones")
	var ruta: String = ProjectSettings.globalize_path("user://") + "prueba_arranque.json"
	ok(j.guardar(ruta), "guardado: escribe y valida")
	var j2 = J.cargar(ruta)
	ok(j2 != null, "guardado: recarga la partida")
	if j2 != null:
		ok(j2.d.jugadores.has(J.LOCAL), "guardado: conserva al jugador")
	print("FALLOS: %d" % fallos)
	quit(1 if fallos else 0)
