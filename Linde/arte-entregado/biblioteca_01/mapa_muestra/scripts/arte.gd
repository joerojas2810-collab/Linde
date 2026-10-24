extends RefCounted
# Arte procedural en píxeles (sin archivos externos) hacia la referencia visual: vista oblicua, contornos oscuros,
# tejados de tejas con fachada, copas redondas, caminos con borde de hierba, agua con orilla de piedra.
# Provisional: sirve para legibilidad; la hoja de estilo/sprites finales están pendientes (ver DECISIONES.md).
const Mundo = preload("res://scripts/mundo.gd")
const OUT := Color("1f2a1c")
const D4 := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const COPA := [[8, 10], [5, 16], [3, 20], [2, 22], [1, 24], [0, 26], [0, 26], [0, 26], [0, 26], [0, 26], [1, 24], [1, 24], [2, 22], [3, 20], [5, 16], [8, 10]]
const ROCA := [[3, 8], [1, 12], [0, 14], [0, 14], [0, 14], [1, 12]]
const MATA := [[4, 8], [2, 12], [1, 14], [0, 16], [0, 16], [1, 14], [2, 12]]

static func r(ci: CanvasItem, x: float, y: float, w: float, h: float, col: Color) -> void:
	ci.draw_rect(Rect2(x, y, w, h), col)

# Rectángulo con contorno de 1 px.
static func rc(ci: CanvasItem, x: float, y: float, w: float, h: float, col: Color, a: float = 1.0) -> void:
	r(ci, x - 1, y - 1, w + 2, h + 2, Color(OUT, a))
	r(ci, x, y, w, h, Color(col, a))

# Mancha redondeada por filas [desplazamiento, ancho] con contorno, luz arriba-izquierda y sombra abajo-derecha.
static func blob(ci: CanvasItem, o: Vector2, filas: Array, col: Color) -> void:
	for i in filas.size():
		r(ci, o.x + filas[i][0] - 1, o.y + i, filas[i][1] + 2, 1, OUT)
	r(ci, o.x + filas[0][0], o.y - 1, filas[0][1], 1, OUT)
	r(ci, o.x + filas[-1][0], o.y + filas.size(), filas[-1][1], 1, OUT)
	var n := filas.size()
	for i in n:
		var xo: float = filas[i][0]
		var w: float = filas[i][1]
		r(ci, o.x + xo, o.y + i, w, 1, col)
		if i < n * 0.4: r(ci, o.x + xo + 1, o.y + i, w * 0.4, 1, col.lightened(0.18))
		if i > n * 0.6: r(ci, o.x + xo + w * 0.5, o.y + i, w * 0.5, 1, col.darkened(0.22))

static func legacy_suelo(ci: CanvasItem, m, c: Vector2i) -> void:
	var x := c.x * 16.0
	var y := c.y * 16.0
	var hh := Mundo.h(c.x, c.y, 3)
	var t: int = m.tipo(c)
	match t:
		Mundo.T.PASTO:
			r(ci, x, y, 16, 16, Color("5da83f") if hh % 7 != 0 else Color("56a03a"))
			if hh % 3 == 0:
				r(ci, x + 3 + hh % 8, y + 4 + (hh >> 3) % 8, 1, 2, Color("3f8a2e"))
				r(ci, x + 5 + hh % 8, y + 5 + (hh >> 3) % 8, 1, 2, Color("3f8a2e"))
			if hh % 29 == 0: r(ci, x + 6, y + 9, 2, 2, Color("f4e85e"))
			elif hh % 31 == 0: r(ci, x + 9, y + 6, 2, 2, Color("f4f4f4"))
		Mundo.T.CAMINO:
			r(ci, x, y, 16, 16, Color("d8ba7a"))
			if hh % 5 == 0: r(ci, x + 4 + hh % 7, y + 5 + (hh >> 3) % 7, 2, 1, Color("bf9f5f"))
			for d in D4:
				if m.tipo(c + d) == Mundo.T.PASTO:
					var g := Color("7fb84a")
					if d == Vector2i.UP: r(ci, x, y, 16, 2, g)
					elif d == Vector2i.DOWN: r(ci, x, y + 14, 16, 2, g)
					elif d == Vector2i.LEFT: r(ci, x, y, 2, 16, g)
					else: r(ci, x + 14, y, 2, 16, g)
		Mundo.T.AGUA:
			r(ci, x, y, 16, 16, Color("3d88d9"))
			if hh % 4 == 0: r(ci, x + 2 + hh % 6, y + 4 + (hh >> 2) % 8, 6, 1, Color("86bdf2"))
			for d in D4:
				if m.tipo(c + d) != Mundo.T.AGUA:
					var b := Rect2(x, y, 16, 5) if d == Vector2i.UP else (Rect2(x, y + 11, 16, 5) if d == Vector2i.DOWN else (Rect2(x, y, 5, 16) if d == Vector2i.LEFT else Rect2(x + 11, y, 5, 16)))
					ci.draw_rect(b, Color("8d8d95"))
					ci.draw_rect(b, Color("5c5c66"), false, 1)
		Mundo.T.PARED:
			r(ci, x, y, 16, 16, Color("b98e5a"))
			for k in range(0, 16, 4): r(ci, x + k, y, 1, 16, Color("9a7344"))
		Mundo.T.SUELO:
			r(ci, x, y, 16, 16, Color("a67c52"))
			r(ci, x, y + 7, 16, 1, Color("8d6540"))
			r(ci, x + (hh % 12), y, 1, 7, Color("8d6540"))
		Mundo.T.PUERTA:
			r(ci, x, y, 16, 16, Color("5b3a22"))
		Mundo.T.RUINA:
			r(ci, x, y, 16, 16, Color("bdb08e"))
			if hh % 4 == 0:
				r(ci, x + 3, y + 4, 6, 1, Color("8f8466"))
				r(ci, x + 8, y + 5, 1, 5, Color("8f8466"))
			if c.y == 38 and (c.x == 51 or c.x == 52):
				for k in range(0, 16, 4): r(ci, x, y + k, 16, 1, Color("8f8466"))
		Mundo.T.MURO_RUINA:
			r(ci, x, y, 16, 16, Color("7b7a84"))
			r(ci, x, y + 7, 16, 1, Color("5a5962"))
			r(ci, x, y + 15, 16, 1, Color("5a5962"))
			r(ci, x + (8 if (c.y + c.x) % 2 == 0 else 0), y, 1, 7, Color("5a5962"))
			r(ci, x + (0 if (c.y + c.x) % 2 == 0 else 8), y + 8, 1, 7, Color("5a5962"))
			if m.tipo(c + Vector2i.UP) != Mundo.T.MURO_RUINA: r(ci, x, y, 16, 2, Color("a4a3ad"))

static func legacy_arbol(ci: CanvasItem, p: Vector2, hh: int) -> void:
	r(ci, p.x + 2, p.y + 13, 14, 3, Color(0, 0, 0, 0.18))
	rc(ci, p.x + 5, p.y, 6, 16, Color("7a4a25"))
	r(ci, p.x + 9, p.y + 1, 2, 15, Color("5e3719"))
	r(ci, p.x + 4, p.y + 13, 8, 3, Color("7a4a25"))
	var verdes := [Color("2f9a3c"), Color("38a845"), Color("2b8a38")]
	var col: Color = verdes[hh % 3]
	var o := p + Vector2(-5, -14)
	blob(ci, o, COPA, col)
	for k in 4:
		var q := (hh >> (k * 3)) % 9
		r(ci, o.x + 5 + q * 2, o.y + 3 + (k * 3) % 8, 2, 2, col.lightened(0.3))

static func legacy_roca(ci: CanvasItem, p: Vector2, veta: bool) -> void:
	r(ci, p.x + 1, p.y + 13, 14, 3, Color(0, 0, 0, 0.18))
	blob(ci, p + Vector2(1, 9), ROCA, Color("6f6f79") if veta else Color("8d8d95"))
	if veta:
		for q in [Vector2(4, 11), Vector2(9, 12), Vector2(11, 10)]:
			r(ci, p.x + q.x, p.y + q.y, 2, 2, Color("e08a2e"))
			r(ci, p.x + q.x, p.y + q.y, 1, 1, Color("f7cf7e"))

static func legacy_arbusto(ci: CanvasItem, p: Vector2) -> void:
	r(ci, p.x + 1, p.y + 13, 14, 3, Color(0, 0, 0, 0.15))
	blob(ci, p + Vector2(0, 8), MATA, Color("3f9a3a"))
	for q in [Vector2(4, 11), Vector2(10, 10), Vector2(7, 13)]: r(ci, p.x + q.x, p.y + q.y, 2, 2, Color("d6334f"))

static func legacy_barril(ci: CanvasItem, p: Vector2) -> void:
	rc(ci, p.x + 3, p.y + 3, 10, 12, Color("93602d"))
	r(ci, p.x + 3, p.y + 6, 10, 2, Color("5a3a1a"))
	r(ci, p.x + 3, p.y + 11, 10, 2, Color("5a3a1a"))
	r(ci, p.x + 4, p.y + 4, 2, 10, Color("b07b43"))

static func legacy_valla(ci: CanvasItem, p: Vector2) -> void:
	rc(ci, p.x, p.y + 5, 16, 3, Color("a8743f"))
	rc(ci, p.x, p.y + 10, 16, 3, Color("a8743f"))
	rc(ci, p.x + 1, p.y + 2, 4, 14, Color("8a5a2b"))
	rc(ci, p.x + 11, p.y + 2, 4, 14, Color("8a5a2b"))

static func legacy_cofre(ci: CanvasItem, p: Vector2, col: Color, abierto: bool = false) -> void:
	r(ci, p.x + 1, p.y + 13, 14, 3, Color(0, 0, 0, 0.18))
	rc(ci, p.x + 2, p.y + 6, 12, 9, col.darkened(0.25) if abierto else col)
	rc(ci, p.x + 2, p.y + 4 if not abierto else p.y + 2, 12, 4, col.lightened(0.2))
	r(ci, p.x + 7, p.y + 8, 2, 3, Color("f1c40f"))

static func legacy_constr(ci: CanvasItem, t: String, p: Vector2, col: Color) -> void:
	match t:
		"muro":
			rc(ci, p.x, p.y - 4, 16, 20, col)
			for k in range(0, 16, 4): r(ci, p.x + k, p.y - 4, 1, 20, col.darkened(0.2))
			r(ci, p.x, p.y - 4, 16, 3, col.lightened(0.25))
		"mesa":
			rc(ci, p.x, p.y + 4, 16, 6, col.lightened(0.15))
			rc(ci, p.x + 1, p.y + 10, 3, 6, col)
			rc(ci, p.x + 12, p.y + 10, 3, 6, col)
			r(ci, p.x + 3, p.y + 2, 4, 2, Color("9a9aa6"))
		"horno":
			rc(ci, p.x, p.y + 1, 16, 15, col)
			r(ci, p.x + 4, p.y + 7, 8, 8, Color("262626"))
			r(ci, p.x + 6, p.y + 10, 4, 4, Color("e67e22"))
			r(ci, p.x + 7, p.y + 11, 2, 2, Color("f7d774"))
			rc(ci, p.x + 11, p.y - 5, 4, 7, col.darkened(0.15))
		"cofre": cofre(ci, p, col)
		"cama":
			rc(ci, p.x + 1, p.y + 2, 14, 13, Color("7a4a25"))
			r(ci, p.x + 2, p.y + 3, 12, 4, Color("f2e8dc"))
			r(ci, p.x + 2, p.y + 7, 12, 7, col)
		"suelo":
			r(ci, p.x, p.y, 16, 16, col)
			r(ci, p.x, p.y + 7, 16, 1, col.darkened(0.2))

# Casa: tejado de tejas (rows 0..roof_h) y fachada con puerta y ventanas. a = opacidad (atenuada al entrar).
static func legacy_tejado(ci: CanvasItem, casa: Rect2i, a: float) -> void:
	var ox := casa.position.x * 16.0
	var oy := casa.position.y * 16.0
	var w := casa.size.x * 16.0
	var h := (casa.size.y - 2) * 16.0     # filas de tejado; las 2 últimas son fachada
	var rx := ox - 8
	var rw := w + 16
	r(ci, rx - 1, oy - 13, rw + 2, h + 14, Color(OUT, a))
	r(ci, rx, oy - 12, rw, h + 12, Color("a9532f", a))
	for yy in range(0, int(h + 12), 6):
		r(ci, rx, oy - 12 + yy + 5, rw, 1, Color("7d3b20", a))
		var off := 4 if (yy / 6) % 2 == 0 else 0
		for xx in range(off, int(rw), 8): r(ci, rx + xx, oy - 12 + yy, 1, 5, Color("7d3b20", a))
	r(ci, rx, oy - 12, rw, 4, Color("c8693a", a))
	r(ci, rx, oy + h - 4, rw, 4, Color("6b3018", a))
	r(ci, rx, oy - 12, 5, h + 12, Color("c8693a", a * 0.6))
	rc(ci, ox + w * 0.62, oy - 24, 10, 16, Color("8d8d95"), a)
	r(ci, ox + w * 0.62 - 1, oy - 25, 12, 3, Color("b0b0b8", a))

static func legacy_fachada(ci: CanvasItem, casa: Rect2i, puerta: Vector2i, a: float) -> void:
	var ox := casa.position.x * 16.0
	var fy := (casa.end.y - 2) * 16.0
	var w := casa.size.x * 16.0
	r(ci, ox - 1, fy - 1, w + 2, 34, Color(OUT, a))
	r(ci, ox, fy, w, 32, Color("d2b27a", a))
	for xx in range(0, int(w), 8): r(ci, ox + xx, fy, 1, 32, Color("b8965c", a))
	r(ci, ox, fy, w, 3, Color("6e4524", a))
	r(ci, ox, fy, 4, 32, Color("6e4524", a))
	r(ci, ox + w - 4, fy, 4, 32, Color("6e4524", a))
	r(ci, ox, fy + 28, w, 4, Color("8d8d95", a))
	for wx in [ox + 14.0, ox + w - 38.0]:
		rc(ci, wx, fy + 8, 20, 12, Color("5a3a1e"), a)
		r(ci, wx + 2, fy + 10, 16, 8, Color("55a8ee", a))
		r(ci, wx + 9, fy + 10, 2, 8, Color("5a3a1e", a))
		r(ci, wx + 3, fy + 11, 4, 2, Color("b9defa", a))
	var dx := puerta.x * 16.0
	rc(ci, dx - 1, fy + 6, 18, 26, Color("5a3a1e"), a)
	r(ci, dx + 1, fy + 8, 14, 24, Color("8a5a2b", a))
	r(ci, dx + 7, fy + 8, 1, 24, Color("5a3a1e", a))
	r(ci, dx + 11, fy + 20, 2, 2, Color("f1c40f", a))

# Biblioteca nueva: representación únicamente. Ninguna regla del mundo cambia.
static var texturas: Dictionary = {}
static func tex(id: String) -> Texture2D:
	if not texturas.has(id):
		texturas[id]=load("res://assets/escenario/"+id+".png") as Texture2D
	return texturas[id]
static func sprite(ci: CanvasItem,id:String,p:Vector2,size:float) -> void:
	ci.draw_texture_rect(tex(id),Rect2(p+Vector2(8-size/2,16-size),Vector2(size,size)),false)
static func suelo(ci:CanvasItem,m,c:Vector2i) -> void:
	var id="grass"
	var t:int=m.tipo(c)
	# Exterior: no dejar el antiguo muro rectangular visible detrás de la casa completa.
	if Mundo.CASA.has_point(c) and not Mundo.CASA.has_point(Mundo.celda_de(ci.j.pies)):
		ci.draw_texture_rect(tex("path_fill" if c==Mundo.PUERTA_C else "grass"),Rect2(Vector2(c)*16,Vector2(16,16)),false)
		return
	match t:
		Mundo.T.PASTO: id="grass_flecks" if Mundo.h(c.x,c.y,3)%11==0 else "grass"
		Mundo.T.CAMINO: id="path_fill"
		Mundo.T.AGUA: id="water_fill"
		Mundo.T.PARED: id="wall_stone"
		Mundo.T.SUELO: id="floor_wood"
		Mundo.T.RUINA: id="floor_ruins"
		Mundo.T.MURO_RUINA: id="wall_stone"
		_:
			legacy_suelo(ci,m,c)
			return
	ci.draw_texture_rect(tex(id),Rect2(Vector2(c)*16,Vector2(16,16)),false)
	# Bordes: solo una arista simple. Esquinas múltiples conservan el relleno.
	var edges=[]
	for d in D4:
		if (t==Mundo.T.CAMINO and m.tipo(c+d)==Mundo.T.PASTO) or (t==Mundo.T.AGUA and m.tipo(c+d)!=Mundo.T.AGUA): edges.append(d)
	if edges.size()==1:
		var d:Vector2i=edges[0]
		var suffix="n" if d==Vector2i.UP else ("s" if d==Vector2i.DOWN else ("w" if d==Vector2i.LEFT else "e"))
		id=("path_grass_" if t==Mundo.T.CAMINO else "water_shore_")+suffix
		ci.draw_texture_rect(tex(id),Rect2(Vector2(c)*16,Vector2(16,16)),false)
static func arbol(ci:CanvasItem,p:Vector2,hh:int) -> void:
	sprite(ci,["tree_broadleaf","tree_pine","tree_fruit"][hh%3],p,48)
static func roca(ci:CanvasItem,p:Vector2,veta:bool) -> void:
	sprite(ci,"ore_copper" if veta else "rock",p,16)
static func arbusto(ci:CanvasItem,p:Vector2) -> void: sprite(ci,"bush_berries",p,16)
static func barril(ci:CanvasItem,p:Vector2) -> void: sprite(ci,"barrel",p,16)
static func valla(ci:CanvasItem,p:Vector2) -> void: sprite(ci,"fence_horizontal",p,16)
static func cofre(ci:CanvasItem,p:Vector2,_col:Color,abierto:bool=false) -> void:
	sprite(ci,"chest_open" if abierto else "chest_closed",p,24)
static func constr(ci:CanvasItem,t:String,p:Vector2,col:Color) -> void:
	match t:
		"mesa": sprite(ci,"workbench",p,24)
		"horno": sprite(ci,"furnace",p,24)
		"cofre": cofre(ci,p,col)
		"cama": sprite(ci,"bed",p,24)
		"suelo": ci.draw_texture_rect(tex("floor_wood"),Rect2(p,Vector2(16,16)),false)
		_: legacy_constr(ci,t,p,col)
static func fachada(ci:CanvasItem,casa:Rect2i,puerta:Vector2i,a:float) -> void:
	if a<1:
		legacy_fachada(ci,casa,puerta,a)
		return
	# Edificio completo dentro del orden por profundidad; no se dibuja otra fachada.
	var size=Vector2(casa.size.x*16+16,casa.size.x*16+16)
	var bottom=Vector2(casa.position.x*16-8,casa.end.y*16)
	ci.draw_texture_rect(tex("cottage_closed"),Rect2(bottom-Vector2(0,size.y),size),false)
static func tejado(ci:CanvasItem,casa:Rect2i,a:float) -> void:
	if a<1: legacy_tejado(ci,casa,a)
