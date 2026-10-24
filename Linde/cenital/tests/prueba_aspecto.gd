extends SceneTree
const A = preload("res://scripts/aspecto.gd")
const Arte = preload("res://scripts/arte_equipo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const J = preload("res://scripts/juego.gd")
var fallos := 0
func ok(b: bool, msg: String) -> void:
	print(("PASS " if b else "FAIL ") + msg)
	if not b: fallos += 1
func _initialize() -> void:
	call_deferred("ejecutar")

func tecla(esc, k: int) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = k
	esc._unhandled_key_input(e)

func ejecutar() -> void:
	var nuevo := [7, 9, 9, 1, 2, 7, 5, 5]
	ok(A.valido(nuevo) and Srv._look(nuevo) == nuevo, "red admite todos los selectores ampliados")
	ok(Srv._look([1, 2, 0]) == [1, 2, 0], "red conserva formato heredado")
	for malo in [[8,0,0,0,0,0,0,0], [0,0,0,2,0,0,0,0], [0,0,0,0,10,0,0,0], [true,0,0], [0.0,0,0], [0,0,0,0]]:
		ok(Srv._look(malo).is_empty(), "red rechaza selector inválido: " + str(malo))
	ok(A.npc("maren") != A.npc("ordal") and A.npc("ordal") != A.npc("nerea") and A.valido(A.npc("habitante_nuevo")), "NPC distintos y fallback válido estable")
	var j = J.nueva(1, "Ana", nuevo)
	var ruta := ProjectSettings.globalize_path("user://pruebas_aspecto/partida.json")
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	ok(j.guardar(ruta), "guarda aspecto ampliado")
	var cargado = J.cargar(ruta)
	ok(cargado != null and cargado.jug().look == nuevo, "restaura todos los selectores sin cambiar formato del guardado")
	var srv = Srv.new()
	srv.j = j
	srv.registrar_peer(2)
	ok(srv.entrar(2, [Srv.VERSION, "Bea", "clave-aspecto", nuevo]).ok, "ingreso de red con apariencia ampliada")
	var arte = Arte.new()
	for identidad in 2:
		ok(A.peinados(identidad).size() == 10, "diez opciones por identidad")
		for estado in ["", "ataque", "herramienta", "dano", "caida", "dormir"]:
			var firmas := {}
			for estilo in 10:
				var look: Array = nuevo.duplicate()
				look[3] = identidad
				look[4] = estilo
				var capas: Dictionary = arte.capas_base(look, estado)
				firmas[capas.b_pelo.get_image().get_data().hex_encode().sha256_text()] = true
				ok(capas.size() >= 7, "capas: %s identidad %d peinado %d" % [estado, identidad, estilo])
			ok(firmas.size() == 10, "diez peinados visualmente distintos: %s identidad %d" % [estado, identidad])
	for estado in ["", "ataque", "herramienta", "dano", "caida", "dormir"]:
		var fuente: Dictionary = arte.atq.base if estado == "ataque" else (arte.estados[estado].base if arte.estados.has(estado) else arte.base)
		var original: Image = fuente.pelo
		for estilo in [1, 4]:
			var look := [4,5,5,0,estilo,3,2,1]
			var im: Image = arte.capas_base(look, estado).b_pelo.get_image()
			var cobertura := true
			for y in original.get_height():
				for x in original.get_width():
					if original.get_pixel(x,y).a8 > 0 and im.get_pixel(x,y).a8 == 0: cobertura = false
			ok(cobertura, "sustituto no descubre el cráneo: %d %s" % [estilo, estado])
	for peinado in [4, 5]:
		for estado in ["", "ataque", "herramienta", "dano", "caida", "dormir"]:
			for dir in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
				var comandos: Array = arte.comandos(Vector2.ZERO, dir, 0, [], [4,5,5,1,peinado,3,2,1], false, estado)
				var nombres: Array = comandos.map(func(c): return c[0])
				ok(nombres.find("b_pelo_fondo") < nombres.find("b_cuerpo") and nombres.has("b_pelo_fondo"), "cola detrás de cuerpo/cara: %d %s %s" % [peinado, estado, dir])
	ok(arte.capas_base([1,2,0]).b_botas.get_image().get_data() == arte.base.botas.get_data(), "apariencia antigua conserva botas originales")
	srv.free()
	var esc = load("res://main.tscn").instantiate()
	esc.ruta = ProjectSettings.globalize_path("user://pruebas_aspecto/ui.json")
	root.add_child(esc)
	await process_frame
	esc.modo = "creador"
	for i in A.CAMPOS.size():
		esc.cr.campo = i + 1
		esc.cr[A.CAMPOS[i]] = A.limites()[i] - 1
		tecla(esc, KEY_RIGHT)
		ok(esc.cr[A.CAMPOS[i]] == 0, "selector vuelve al principio: " + A.CAMPOS[i])
		tecla(esc, KEY_LEFT)
		ok(esc.cr[A.CAMPOS[i]] == A.limites()[i] - 1, "selector vuelve al final: " + A.CAMPOS[i])
	esc.modo = "unirse"
	esc.un.campo = 3
	esc.un.nombre = "Bea"
	tecla(esc, KEY_P)
	ok(esc.modo == "creador" and esc.destino_creador == "unirse", "unirse permite abrir el creador de aspecto")
	esc.cr.campo = A.CAMPOS.size() + 1
	tecla(esc, KEY_ENTER)
	ok(esc.modo == "unirse" and esc.j == null, "confirmar aspecto vuelve a unirse sin crear partida")
	esc.queue_free()
	await process_frame
	print("FALLOS_ASPECTO: %d" % fallos)
	quit(1 if fallos else 0)
