extends SceneTree
# Genera plantillas de alineacion de sprites (PNG) del personaje compacto.
# Uso: Godot --headless --path prototypes/personaje-compacto --script /ruta/abs/herramientas/arte/plantilla_alineacion.gd
# Reutiliza armar() de prototypes/personaje-compacto/escena.gd (no lo modifica).

const SALIDA_REL := "design/art/plantilla"
const DIRS := ["frente", "derecha", "espalda", "izquierda"]
const COL_BORDE := Color("cfcfcf")
const COL_EJE := Color(0.9, 0.2, 0.9, 0.9)
const COL_SUELO := Color("2f6fe0")
const COL_SIL := Color(0.5, 0.5, 0.5, 0.5)
const COL_ANCLA := Color("e0201b")
const CRUZ: Array[Vector2i] = [Vector2i(15, 30), Vector2i(16, 30), Vector2i(17, 30), Vector2i(16, 29), Vector2i(16, 31)]


func _init() -> void:
	var raiz: String = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	var dir_salida: String = raiz.path_join(SALIDA_REL)
	DirAccess.make_dir_recursive_absolute(dir_salida)

	var escena: GDScript = load("res://escena.gd")
	var personaje = escena.new()

	var hoja32: Image = _hoja(personaje, 32)
	var hoja16: Image = _hoja(personaje, 16)
	personaje.free()

	_guardar(hoja32, dir_salida.path_join("plantilla_32.png"))
	_guardar(hoja16, dir_salida.path_join("plantilla_16.png"))
	_guardar(_ampliar(hoja32, 8), dir_salida.path_join("plantilla_32_x8.png"))
	_guardar(_ampliar(hoja16, 8), dir_salida.path_join("plantilla_16_x8.png"))
	quit(0)


func _hoja(personaje, s: int) -> Image:
	var res: int = 1 if s == 16 else 2  # armar(): res 1 = lienzo 16, res 2 = lienzo 32
	var img := Image.create(4 * s, 4 * s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for fila in DIRS.size():
		for col in 4:
			_celda(img, col * s, fila * s, s, personaje, res, DIRS[fila], col)
	return img


func _celda(img: Image, ox: int, oy: int, s: int, personaje, res: int, dir: String, frame: int) -> void:
	for i in s:
		_px(img, ox + i, oy, COL_BORDE)
		_px(img, ox + i, oy + s - 1, COL_BORDE)
		_px(img, ox, oy + i, COL_BORDE)
		_px(img, ox + s - 1, oy + i, COL_BORDE)
	# eje central punteado
	var cx: int = s / 2
	for y in range(1, s - 1, 2):
		_px(img, ox + cx, oy + y, COL_EJE)
	# suelo (baseline de los pies)
	for x in s:
		_px(img, ox + x, oy + s - 1, COL_SUELO)
	# silueta sin equipo (partes de armar(), frames 1 y 3 con pie levantado)
	var partes: Array = personaje.armar(res, dir, [], frame)
	for p in partes:
		if p[0] == "":
			continue
		var r: Rect2i = p[1]
		for y in range(r.position.y, r.position.y + r.size.y):
			for x in range(r.position.x, r.position.x + r.size.x):
				if x >= 0 and x < s and y >= 0 and y < s:
					_px(img, ox + x, oy + y, COL_SIL)
	# ancla de pies, solo en hoja de 32 px
	if s == 32:
		for p in CRUZ:
			_px(img, ox + p.x, oy + p.y, COL_ANCLA)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _ampliar(img: Image, f: int) -> Image:
	var out: Image = img.duplicate() as Image
	out.resize(img.get_width() * f, img.get_height() * f, Image.INTERPOLATE_NEAREST)
	return out


func _guardar(img: Image, ruta: String) -> void:
	var err: int = img.save_png(ruta)
	print("%s -> %s" % [ruta, "OK" if err == OK else "ERROR %d" % err])
