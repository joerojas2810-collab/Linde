extends RefCounted
# Personaje por capas desde hojas PNG: <base>/personaje.json + <base>/personaje_<capa>.png.
# Hoja: 4 columnas (cuadros de caminata) x 4 filas (frente, derecha, espalda, izquierda), celdas de `celda` px.
# Ancla = centro inferior de la celda (pies). Si falta algo, disponible() es false y se usa Apariencia.
const EQUIPO := ["casco", "coraza", "escudo", "espada"]   # solo se dibujan si el jugador los tiene
const FILA := {Vector2i.DOWN: 0, Vector2i.RIGHT: 1, Vector2i.UP: 2, Vector2i.LEFT: 3}
# Capas de abajo a arriba por orientación. Lateralidad de perfiles (a confirmar en el mapa):
# para invertirla, intercambia los contenidos de las listas Vector2i.RIGHT y Vector2i.LEFT.
const ORDEN_POR_DIRECCION := {
	Vector2i.DOWN: ["cuerpo", "pantalon", "tunica", "cinturon", "coraza", "escudo", "espada", "pelo", "casco"],
	Vector2i.RIGHT: ["cuerpo", "pantalon", "escudo", "tunica", "cinturon", "coraza", "espada", "pelo", "casco"],
	Vector2i.UP: ["cuerpo", "pantalon", "tunica", "cinturon", "coraza", "escudo", "espada", "pelo", "casco"],
	Vector2i.LEFT: ["cuerpo", "pantalon", "espada", "tunica", "cinturon", "coraza", "escudo", "pelo", "casco"],
}
var celda := 0
var texturas := {}      # capa -> ImageTexture
var errores: Array = []

func _init(base: String = "res://arte") -> void:
	var ruta := base + "/personaje.json"
	if not FileAccess.file_exists(ruta): return
	var man = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (man is Dictionary and man.get("celda") is float and man.get("capas") is Array):
		errores.append("manifiesto invalido: " + ruta); return
	celda = int(man.celda)
	if celda <= 0: errores.append("celda invalida"); return
	for capa in man.capas:
		var f: String = "%s/personaje_%s.png" % [base, capa]
		var texture: Texture2D = null
		if f.begins_with("res://") and ResourceLoader.exists(f):
			texture = load(f) as Texture2D
		elif FileAccess.file_exists(f):
			# Recursos temporales generados en ejecucion (pruebas/mods locales).
			var dynamic_image: Image = Image.load_from_file(f)
			if dynamic_image != null: texture = ImageTexture.create_from_image(dynamic_image)
		var img: Image = texture.get_image() if texture != null else null
		if img == null: errores.append("falta la hoja " + f); continue
		if img.get_width() != 4 * celda or img.get_height() != 4 * celda:
			errores.append("%s mide %dx%d, se esperaba %dx%d" % [f, img.get_width(), img.get_height(), 4 * celda, 4 * celda]); continue
		texturas[str(capa)] = texture
	for e in errores: push_warning("capas_sprite: " + e)

func disponible() -> bool:
	return celda > 0 and errores.is_empty() and not texturas.is_empty()

# Lista [[capa, destino, origen], ...] de abajo a arriba. destino: ancla centro-inferior en `pies`.
func comandos(pies: Vector2, dir: Vector2i, frame: int, equipo: Array = []) -> Array:
	var out: Array = []
	var dst := Rect2((pies - Vector2(celda / 2.0, celda)).round(), Vector2(celda, celda))
	var src := Rect2(Vector2(frame % 4, FILA.get(dir, 0)) * celda, Vector2(celda, celda))
	for capa in ORDEN_POR_DIRECCION.get(dir, ORDEN_POR_DIRECCION[Vector2i.DOWN]):
		if texturas.has(capa) and (not capa in EQUIPO or capa in equipo): out.append([capa, dst, src])
	return out

func dibujar(ci: CanvasItem, pies: Vector2, dir: Vector2i, frame: int, equipo: Array = []) -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for c in comandos(pies, dir, frame, equipo):
		ci.draw_texture_rect_region(texturas[c[0]], c[1], c[2])

# Presentacion de acciones;	no calcula dano ni altera reglas.
var acciones: Dictionary = {}
func dibujar_accion(ci: CanvasItem, pies: Vector2, dir: Vector2i, tipo: String, cuadro: int) -> void:
	if not acciones.has(tipo):
		var ruta: String = "res://arte/%s.png" % tipo
		acciones[tipo] = load(ruta) as Texture2D
	var tex: Texture2D = acciones[tipo]
	if tex == null: return
	var dst: Rect2 = Rect2((pies-Vector2(24,48)).round(),Vector2(48,48))
	var src: Rect2 = Rect2(Vector2(clampi(cuadro,0,3),FILA.get(dir,0))*48,Vector2(48,48))
	ci.draw_texture_rect_region(tex,dst,src)
