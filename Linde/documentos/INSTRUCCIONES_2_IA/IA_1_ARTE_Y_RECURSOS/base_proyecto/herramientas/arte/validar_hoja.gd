extends SceneTree
## Validador de hojas de sprites de equipo de Linde (contrato: Linde/documentos/contrato-equipo.md).
## Uso: Godot --headless --script herramientas/arte/validar_hoja.gd -- <hoja.png> --celda=32
##        [--modo=indice|libre] [--base=<caminata.png>] [--json=<informe.json>]
## Salida: 0 = correcto (puede haber avisos), 1 = errores, 2 = argumentos invalidos. No modifica la entrada.

## Colores indice (contrato 2.d). Son PROPUESTA hasta que el contrato se cierre.
const INDICE := {
	"rojo (principal)": Color8(255, 0, 0),
	"verde (sombra)": Color8(0, 255, 0),
	"azul (acento)": Color8(0, 0, 255),
	"gris (detalle)": Color8(128, 128, 128),
}
const TOLERANCIA_SILUETA := 3   ## px de margen alrededor de la silueta de la hoja base
const OCUPACION_MAXIMA := 0.9   ## fraccion de celda opaca por encima de la cual se avisa (fondo relleno)
const COLUMNAS := 4
const FILAS := 4

func _init() -> void:
	quit(_main())

func _main() -> int:
	var ruta := ""; var celda := 0; var modo := "indice"; var ruta_base := ""; var ruta_json := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--celda="): celda = a.get_slice("=", 1).to_int()
		elif a.begins_with("--modo="): modo = a.get_slice("=", 1)
		elif a.begins_with("--base="): ruta_base = a.get_slice("=", 1)
		elif a.begins_with("--json="): ruta_json = a.get_slice("=", 1)
		elif not a.begins_with("--") and ruta == "": ruta = a
		else: return _uso("argumento no reconocido: " + a)
	if ruta == "" or celda <= 0 or not modo in ["indice", "libre"]:
		return _uso("faltan <hoja.png> o --celda=N, o --modo invalido")
	var img := Image.load_from_file(ruta)
	if img == null: print("ERROR: no se puede leer ", ruta); return 1
	var base: Image = null
	if ruta_base != "":
		base = Image.load_from_file(ruta_base)
		if base == null: return _uso("no se puede leer la base " + ruta_base)
	var r := validar(img, celda, modo, base)
	print(informe_texto(r, ruta))
	if ruta_json != "":
		var f := FileAccess.open(ruta_json, FileAccess.WRITE)
		if f == null: print("ERROR: no se puede escribir ", ruta_json); return 1
		f.store_string(JSON.stringify(r, "\t"))
	return 0 if r.errores.is_empty() else 1

func _uso(msg: String) -> int:
	print("Argumentos invalidos: ", msg)
	print("Uso: --script validar_hoja.gd -- <hoja.png> --celda=32 [--modo=indice|libre] [--base=<caminata.png>] [--json=ruta]")
	return 2

## Logica pura. Devuelve {errores, avisos, colores, comprobaciones:[{n, nombre, estado, detalle}]}.
## estado: "OK", "ERROR", "AVISO" o "NA" (no aplica).
static func validar(src: Image, celda: int, modo: String, base: Image = null) -> Dictionary:
	var r := {"errores": [], "avisos": [], "colores": 0, "comprobaciones": []}
	var reg := func(nombre: String, estado: String, detalle: String) -> void:
		var n: int = r.comprobaciones.size() + 1
		r.comprobaciones.append({"n": n, "nombre": nombre, "estado": estado, "detalle": detalle})
		if estado == "ERROR": r.errores.append("%d %s: %s" % [n, nombre, detalle])
		elif estado == "AVISO": r.avisos.append("%d %s: %s" % [n, nombre, detalle])
	# 1 legible
	reg.call("archivo legible", "OK", "%dx%d" % [src.get_width(), src.get_height()])
	# 2 tamano
	var w := 4 * celda
	if src.get_width() != w or src.get_height() != w:
		reg.call("tamano exacto", "ERROR", "mide %dx%d, se esperaba %dx%d" % [src.get_width(), src.get_height(), w, w])
		return _rellenar_na(r, reg)   # sin tamano correcto el resto no tiene sentido
	reg.call("tamano exacto", "OK", "%dx%d" % [w, w])
	var img: Image = src.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var datos: PackedByteArray = img.get_data()
	var celdas_vacias: Array = []; var celdas_borde: Array = []; var celdas_llenas: Array = []
	var parciales := 0; var fuera_indice := {}; var colores := {}
	var indice_hex := {}
	for k: String in INDICE: indice_hex[(INDICE[k] as Color).to_html(false)] = k
	var usa_rojo := false
	var cuenta: Array = []   # opacos por celda
	for c in COLUMNAS * FILAS:
		var cx: int = (c % COLUMNAS) * celda; var cy: int = (c / COLUMNAS) * celda
		var op := 0; var borde := false
		for y in celda:
			for x in celda:
				var i: int = ((cy + y) * w + cx + x) * 4
				var a: int = datos[i + 3]
				if a == 0: continue
				if a != 255: parciales += 1; continue
				op += 1
				var hx := Color8(datos[i], datos[i + 1], datos[i + 2]).to_html(false)
				colores[hx] = true
				if not indice_hex.has(hx): fuera_indice[hx] = true
				elif indice_hex[hx].begins_with("rojo"): usa_rojo = true
				if x == 0 or y == 0 or x == celda - 1 or y == celda - 1: borde = true
		cuenta.append(op)
		if op == 0: celdas_vacias.append(c)
		if borde: celdas_borde.append(c)
		if op > OCUPACION_MAXIMA * celda * celda: celdas_llenas.append(c)
	r.colores = colores.size()
	# 3 alfa
	reg.call("alfa solo 0/255", "ERROR" if parciales > 0 else "OK", "%d pixeles con alfa parcial" % parciales)
	# 4 indice
	if modo == "indice":
		reg.call("solo colores indice", "ERROR" if not fuera_indice.is_empty() else "OK",
			"%d colores fuera de indice (primeros: %s)" % [fuera_indice.size(), ", ".join(fuera_indice.keys().slice(0, 6))] if not fuera_indice.is_empty() else "ok")
	else: reg.call("solo colores indice", "NA", "modo libre")
	# 5 celdas vacias
	reg.call("16 celdas con contenido", "ERROR" if not celdas_vacias.is_empty() else "OK",
		"celdas vacias (indice fila*4+col): %s" % str(celdas_vacias) if not celdas_vacias.is_empty() else "ok")
	# 6 margen
	reg.call("contenido a >=1 px del borde", "ERROR" if not celdas_borde.is_empty() else "OK",
		"celdas con pixeles en el borde: %s" % str(celdas_borde) if not celdas_borde.is_empty() else "ok")
	# 7 pose repetida
	var repetidas: Array = []
	for f in FILAS:
		var ref: PackedByteArray = img.get_region(Rect2i(0, f * celda, celda, celda)).get_data()
		var igual := true
		for col in range(1, COLUMNAS):
			if img.get_region(Rect2i(col * celda, f * celda, celda, celda)).get_data() != ref: igual = false; break
		if igual: repetidas.append(f)
	reg.call("columnas de cada fila no identicas", "AVISO" if not repetidas.is_empty() else "OK",
		"pose repetida en las filas %s (no acompana la caminata)" % str(repetidas) if not repetidas.is_empty() else "ok")
	# 8 silueta vs base
	if base == null:
		reg.call("silueta dentro de la base +-%d px" % TOLERANCIA_SILUETA, "NA", "sin --base")
		reg.call("base compatible", "NA", "sin --base")
	else:
		if base.get_width() != w or base.get_height() != w:
			reg.call("silueta dentro de la base +-%d px" % TOLERANCIA_SILUETA, "NA", "base de otro tamano")
			reg.call("base compatible", "ERROR", "la base mide %dx%d, se esperaba %dx%d" % [base.get_width(), base.get_height(), w, w])
		else:
			var b: Image = base.duplicate(); b.convert(Image.FORMAT_RGBA8)
			var fuera := _fuera_de_silueta(datos, b.get_data(), w, celda)
			reg.call("silueta dentro de la base +-%d px" % TOLERANCIA_SILUETA, "ERROR" if not fuera.is_empty() else "OK",
				"pixeles fuera por celda {celda: n}: %s" % str(fuera) if not fuera.is_empty() else "ok")
			reg.call("base compatible", "OK", "mismo tamano")
	# 9 colores
	reg.call("numero de colores", "OK", "%d colores opacos distintos" % colores.size())
	# 10 rojo usado
	if modo == "indice": reg.call("usa el rojo principal", "OK" if usa_rojo else "AVISO", "ok" if usa_rojo else "ningun pixel rojo: la pieza no se recolorearia")
	else: reg.call("usa el rojo principal", "NA", "modo libre")
	# 11 ocupacion
	reg.call("celdas no rellenas", "AVISO" if not celdas_llenas.is_empty() else "OK",
		"celdas con >%d%% opaco (fondo relleno?): %s" % [int(OCUPACION_MAXIMA * 100), str(celdas_llenas)] if not celdas_llenas.is_empty() else "ok")
	return r

## Rellena con NA las comprobaciones restantes hasta 12 cuando se aborta pronto.
static func _rellenar_na(r: Dictionary, reg: Callable) -> Dictionary:
	var resto := ["alfa solo 0/255", "solo colores indice", "16 celdas con contenido", "contenido a >=1 px del borde",
		"columnas de cada fila no identicas", "silueta dentro de la base", "base compatible", "numero de colores",
		"usa el rojo principal", "celdas no rellenas"]
	for nombre: String in resto: reg.call(nombre, "NA", "no evaluada (tamano incorrecto)")
	return r

## Devuelve {celda: pixeles opacos fuera de la silueta de la base dilatada TOLERANCIA_SILUETA px}.
static func _fuera_de_silueta(d: PackedByteArray, bd: PackedByteArray, w: int, celda: int) -> Dictionary:
	var out := {}
	for c in COLUMNAS * FILAS:
		var cx: int = (c % COLUMNAS) * celda; var cy: int = (c / COLUMNAS) * celda
		var malos := 0
		for y in celda:
			for x in celda:
				if d[((cy + y) * w + cx + x) * 4 + 3] != 255: continue
				var dentro := false
				for yy in range(maxi(0, y - TOLERANCIA_SILUETA), mini(celda, y + TOLERANCIA_SILUETA + 1)):
					for xx in range(maxi(0, x - TOLERANCIA_SILUETA), mini(celda, x + TOLERANCIA_SILUETA + 1)):
						if bd[((cy + yy) * w + cx + xx) * 4 + 3] != 0: dentro = true; break
					if dentro: break
				if not dentro: malos += 1
		if malos > 0: out[c] = malos
	return out

static func informe_texto(r: Dictionary, ruta: String) -> String:
	var s := "Informe de %s\n" % ruta
	for c: Dictionary in r.comprobaciones:
		s += "  [%-5s] %2d %s: %s\n" % [c.estado, c.n, c.nombre, c.detalle]
	s += "Resultado: %s (%d errores, %d avisos)" % ["CORRECTO" if r.errores.is_empty() else "CON ERRORES", r.errores.size(), r.avisos.size()]
	return s
