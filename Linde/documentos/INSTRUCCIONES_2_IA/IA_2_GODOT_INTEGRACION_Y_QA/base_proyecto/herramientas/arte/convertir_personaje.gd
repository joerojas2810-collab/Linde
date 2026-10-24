extends SceneTree
# Convierte una tira generada de 4 vistas (frente, derecha, espalda, izquierda; RGBA) a píxeles NATIVOS:
# detecta cada vista por alfa, divide su caja en una rejilla de ALTO_NATIVO filas, toma el color mediano del centro de cada
# casilla, binariza el alfa y fusiona colores casi iguales. No toca el original.
# Uso: Godot --headless --script herramientas/arte/convertir_personaje.gd -- <entrada.png> <dir_salida> <dir_arte_juego>
const ALTO_NATIVO := 34       # filas de píxel nativo del personaje (medido: período ≈ 15 px en la imagen original)
const CELDA := 40             # celda de la hoja (4x4); los pies tocan la fila inferior, centrado en x
const UMBRAL_ALFA := 0.75
const UMBRAL_COLOR := 0.004   # distancia² RGB para fusionar colores

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 3:
		print("uso: -- <entrada.png> <dir_salida> <dir_arte_juego>")
		quit(2)
		return
	var im := Image.load_from_file(a[0])
	if im == null:
		print("no se pudo leer ", a[0])
		quit(2)
		return
	im.convert(Image.FORMAT_RGBA8)
	var vistas := _segmentar(im)
	if vistas.size() != 4:
		print("se esperaban 4 vistas y hay ", vistas.size())
		quit(1)
		return
	var natives: Array = []
	var info: Array = []
	for r in vistas:
		var py: float = float(r.size.y) / ALTO_NATIVO
		var w := int(round(r.size.x / py))
		var px: float = float(r.size.x) / w
		var n := Image.create(w, ALTO_NATIVO, false, Image.FORMAT_RGBA8)
		for j in ALTO_NATIVO:
			for i in w:
				n.set_pixel(i, j, _muestra(im, Rect2(r.position.x + i * px + px * 0.25, r.position.y + j * py + py * 0.25, px * 0.5, py * 0.5)))
		natives.append(n)
		info.append({"caja_origen": [r.position.x, r.position.y, r.size.x, r.size.y], "nativo": [w, ALTO_NATIVO], "periodo_px": [snappedf(px, 0.01), snappedf(py, 0.01)]})
	var paleta := _fusionar(natives)
	var colores := {}
	for n in natives:
		for y in n.get_height():
			for x in n.get_width():
				var c: Color = n.get_pixel(x, y)
				if c.a > 0.0: colores["#" + c.to_html(false)] = true
	# tira nativa 1:1
	var total := 0
	for n in natives: total += n.get_width() + 2
	var tira := Image.create(total, ALTO_NATIVO, false, Image.FORMAT_RGBA8)
	var x0 := 0
	for n in natives:
		tira.blit_rect(n, Rect2i(0, 0, n.get_width(), ALTO_NATIVO), Vector2i(x0, 0))
		x0 += n.get_width() + 2
	# hoja 4x4: columnas = cuadros 0..3 (iguales: no hay caminata aún), filas = frente, derecha, espalda, izquierda
	var hoja := Image.create(CELDA * 4, CELDA * 4, false, Image.FORMAT_RGBA8)
	for fila in 4:
		var n: Image = natives[fila]
		var ox := (CELDA - n.get_width()) / 2
		for col in 4:
			hoja.blit_rect(n, Rect2i(0, 0, n.get_width(), ALTO_NATIVO), Vector2i(col * CELDA + ox, fila * CELDA + CELDA - ALTO_NATIVO))
	DirAccess.make_dir_recursive_absolute(a[1])
	DirAccess.make_dir_recursive_absolute(a[2])
	tira.save_png(a[1] + "/personaje_nativo_cuatro_vistas.png")
	hoja.save_png(a[1] + "/hoja_%d.png" % CELDA)
	hoja.save_png(a[2] + "/personaje_cuerpo.png")
	var man := FileAccess.open(a[2] + "/personaje.json", FileAccess.WRITE)
	man.store_string(JSON.stringify({"celda": CELDA, "capas": ["cuerpo"]}, "  "))
	man.close()
	var rep := {"origen": a[0], "celda": CELDA, "alto_nativo": ALTO_NATIVO, "colores": colores.keys(), "n_colores": colores.size(), "vistas": info}
	var f := FileAccess.open(a[1] + "/medidas_nativas.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rep, "  "))
	f.close()
	# comprobaciones
	var semi := 0
	for n in natives:
		for y in n.get_height():
			for x in n.get_width():
				var al: float = n.get_pixel(x, y).a
				if al != 0.0 and al != 1.0: semi += 1
	print("vistas nativas: ", info.map(func(i): return i.nativo))
	print("colores tras fusion: ", colores.size(), " (antes de fusionar: ", paleta, ")")
	print("pixeles semitransparentes: ", semi, " | hoja ", hoja.get_size())
	quit(0)

func _segmentar(im: Image) -> Array:
	var cols := PackedByteArray()
	cols.resize(im.get_width())
	for x in im.get_width():
		for y in im.get_height():
			if im.get_pixel(x, y).a > UMBRAL_ALFA:
				cols[x] = 1
				break
	var out: Array = []
	var ini := -1
	var vacias := 0
	for x in im.get_width() + 60:
		var hay := x < im.get_width() and cols[x] == 1
		if hay:
			if ini < 0: ini = x
			vacias = 0
		elif ini >= 0:
			vacias += 1
			if vacias > 40:
				out.append(_caja(im, ini, x - vacias))
				ini = -1
	return out

func _caja(im: Image, x0: int, x1: int) -> Rect2i:
	var y0 := im.get_height()
	var y1 := 0
	for x in range(x0, x1 + 1):
		for y in im.get_height():
			if im.get_pixel(x, y).a > UMBRAL_ALFA:
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

func _muestra(im: Image, r: Rect2) -> Color:
	var rs: Array = []
	var gs: Array = []
	var bs: Array = []
	var total := 0
	var opacos := 0
	for y in range(int(r.position.y), int(r.end.y) + 1):
		for x in range(int(r.position.x), int(r.end.x) + 1):
			var c := im.get_pixel(x, y)
			total += 1
			if c.a > 0.5:
				opacos += 1
				rs.append(c.r)
				gs.append(c.g)
				bs.append(c.b)
	if opacos * 2 < total: return Color(0, 0, 0, 0)
	rs.sort()
	gs.sort()
	bs.sort()
	var m := opacos / 2
	return Color(rs[m], gs[m], bs[m], 1.0)

# Fusiona colores casi iguales entre todas las imágenes; devuelve cuántos había antes.
func _fusionar(imgs: Array) -> int:
	var cuenta := {}
	for n in imgs:
		for y in n.get_height():
			for x in n.get_width():
				var c: Color = n.get_pixel(x, y)
				if c.a > 0.0:
					var k: String = c.to_html(false)
					cuenta[k] = cuenta.get(k, 0) + 1
	var antes := cuenta.size()
	var claves: Array = cuenta.keys()
	claves.sort_custom(func(p, q): return cuenta[p] > cuenta[q])
	var centros: Array = []
	var mapa := {}
	for k in claves:
		var c := Color(k)
		var asignado := ""
		for ck in centros:
			var d := Color(ck)
			if (c.r - d.r) * (c.r - d.r) + (c.g - d.g) * (c.g - d.g) + (c.b - d.b) * (c.b - d.b) < UMBRAL_COLOR:
				asignado = ck
				break
		if asignado == "":
			centros.append(k)
			asignado = k
		mapa[k] = asignado
	for n in imgs:
		for y in n.get_height():
			for x in n.get_width():
				var c: Color = n.get_pixel(x, y)
				if c.a > 0.0: n.set_pixel(x, y, Color(mapa[c.to_html(false)]))
	return antes
