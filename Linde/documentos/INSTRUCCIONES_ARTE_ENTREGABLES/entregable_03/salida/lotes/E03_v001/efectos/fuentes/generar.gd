extends SceneTree
## Genera propuestas de FX técnicos originales y verifica su estructura.
## Ejecutar --headless --path <efectos> --script res://fuentes/generar.gd

const N := 32
const ATLAS := Vector2i(128, 32)
const PALETA := {
	"borde": Color("3e3141"), "claro": Color("fff1b0"),
	"oro": Color("efb64d"), "rojo": Color("ce6453"),
	"crema": Color("ffe0bc"), "verde": Color("9ac96b")
}
const DURACIONES := {"impacto": 0.16, "dano": 0.20, "recoleccion": 0.28}

func _initialize() -> void:
	var fichas: Array = []
	var fallos: Array = []
	var contacto := Image.create(128, 112, false, Image.FORMAT_RGBA8)
	contacto.fill(Color("42624e"))
	var fila := 0
	for tipo in ["impacto", "dano", "recoleccion"]:
		var im := Image.create(ATLAS.x, ATLAS.y, false, Image.FORMAT_RGBA8)
		im.fill(Color.TRANSPARENT)
		for frame in 4:
			_dibujar(im, tipo, frame)
		var ruta := "res://png/E03_fx_%s.png" % tipo
		var codigo := im.save_png(ruta)
		if codigo != OK: fallos.append("No se pudo guardar: " + ruta)
		var leida := Image.load_from_file(ruta)
		var cajas: Array = []
		var colores := {}
		for frame in 4:
			var celda := leida.get_region(Rect2i(frame * N, 0, N, N))
			cajas.append(celda.get_used_rect())
			if celda.get_used_rect().has_area() == false: fallos.append("Celda vacia: %s %s" % [tipo, frame])
		for y in leida.get_height():
			for x in leida.get_width():
				var c := leida.get_pixel(x, y)
				if c.a != 0.0 and c.a != 1.0: fallos.append("Alfa no binaria")
				if c.a == 1.0: colores[c.to_html()] = true
		if leida.get_size() != ATLAS: fallos.append("Tamano incorrecto: " + tipo)
		contacto.blend_rect(im, Rect2i(0, 0, 128, 32), Vector2i(0, fila * 40))
		fila += 1
		fichas.append({"id": "E03_fx_" + tipo, "archivo": ruta.trim_prefix("res://"), "atlas": [128,32], "celda": [32,32], "pivote": [16,16], "cuadros": 4, "filas": 1, "secuencia": [0,1,2,3], "duracion_visual_s": DURACIONES[tipo], "segundos_por_cuadro": DURACIONES[tipo] / 4.0, "bucle": false, "escala_mundo": 1, "filtro": "nearest", "alfa": "binaria", "colores_opacos": colores.size(), "cajas_cuadros": cajas.map(func(r): return [r.position.x,r.position.y,r.size.x,r.size.y]), "ancla": "centro del evento; NO pies del PNG", "proveniencia": "original geometrico determinista; fuentes/generar.gd", "estado": "candidato, sin aprobacion visual del usuario"})
	contacto.resize(768, 672, Image.INTERPOLATE_NEAREST)
	contacto.save_png("res://qa/CONTACTO_FX_x6.png")
	var manifest := {"version": "E03_v001", "autor": "Codex / E03 FX", "recursos": fichas, "paleta": PALETA.keys().map(func(k): return {"nombre": k, "rgba": PALETA[k].to_html()}), "mecanicas": "Sin cambios. Tiempos exclusivamente visuales.", "licencia": "Sin fuente externa: geometria creada para este proyecto. No incorpora material de otro juego."}
	FileAccess.open("res://MANIFIESTO_FX.json", FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t") + "\n")
	var reporte := {"motor": Engine.get_version_info().string, "pruebas_estructurales": "3 PNG releidos, 12 celdas no vacias, dimensiones y alfa comprobadas", "errores": fallos, "resultado": "OK" if fallos.is_empty() else "FALLO", "limite": "No demuestra integracion ni fidelidad visual. Requiere revision en juego."}
	FileAccess.open("res://qa/VALIDACION_FX.json", FileAccess.WRITE).store_string(JSON.stringify(reporte, "\t") + "\n")
	print(JSON.stringify(reporte))
	quit(0 if fallos.is_empty() else 1)

func _pixel(im: Image, frame: int, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < N and y >= 0 and y < N: im.set_pixel(frame * N + x, y, color)

func _rect(im: Image, frame: int, pos: Vector2i, tam: Vector2i, color: Color) -> void:
	for y in range(pos.y, pos.y + tam.y):
		for x in range(pos.x, pos.x + tam.x): _pixel(im, frame, x, y, color)

func _chispa(im: Image, frame: int, p: Vector2i, r: int, color: Color) -> void:
	for d in range(-r, r + 1):
		_pixel(im, frame, p.x + d, p.y, color)
		_pixel(im, frame, p.x, p.y + d, color)
	_pixel(im, frame, p.x, p.y, PALETA.claro)

func _dibujar(im: Image, tipo: String, f: int) -> void:
	var c := Vector2i(16,16)
	if tipo == "impacto":
		if f == 0:
			_chispa(im, f, c, 2, PALETA.oro)
		elif f == 1:
			_chispa(im, f, c, 5, PALETA.claro)
			_rect(im, f, c - Vector2i(1,1), Vector2i(3,3), PALETA.crema)
		elif f == 2:
			for d in [Vector2i(-7,0), Vector2i(7,0), Vector2i(0,-7), Vector2i(0,7)]: _chispa(im, f, c+d, 1, PALETA.oro)
		else:
			for d in [Vector2i(-10,-2), Vector2i(9,2), Vector2i(-2,-10), Vector2i(2,9)]: _pixel(im,f,c.x+d.x,c.y+d.y,PALETA.crema)
	elif tipo == "dano":
		var r: int = [2,5,8,10][f]
		for dir in [Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
			var pos: Vector2i = c + dir * r
			_rect(im, f, pos, Vector2i(2,2) if f < 3 else Vector2i.ONE, PALETA.rojo)
			if f < 2: _pixel(im, f, pos.x, pos.y-1, PALETA.crema)
	else:
		var rise: int = [4,2,-1,-4][f]
		_chispa(im,f,c + Vector2i(-4,rise),2 if f < 3 else 1,PALETA.oro)
		_chispa(im,f,c + Vector2i(4,rise-4),1,PALETA.verde)
