extends RefCounted
# Personaje base + equipo por capas con las hojas de colores índice (Linde/documentos/contrato-equipo.md, PROPUESTA).
# Hojas en <dir>/manifiesto.json: celda 32, pivote [16, 32], filas frente/derecha/espalda/izquierda, 4 cuadros.
# Recoloreado por CPU (Image), sin shaders: cada color índice -> color de la paleta de la familia -> delta de la variante.
# Las texturas se cachean por (arquetipo, ranura, familia, variante); la base, por apariencia (look).
# Si falta el manifiesto, la base o cualquier hoja, disponible() es false y la escena usa el dibujo procedural.
const Aspecto = preload("res://scripts/aspecto.gd")
const Viajero071 = preload("res://scripts/viajero071.gd")
var viajero071 = Viajero071.new()
const P = preload("res://scripts/params.gd")

## Lateralidad de los perfiles (decisión abierta 2 del contrato). false = como propone el contrato: mirando a la
## derecha el escudo queda detrás del torso y la espada delante; a la izquierda, al revés. true intercambia ambos perfiles.
const INVERTIR_PERFILES := false
const FILA := {Vector2i.DOWN: 0, Vector2i.RIGHT: 1, Vector2i.UP: 2, Vector2i.LEFT: 3}
const RANURAS_COMPARTIDAS := ["escudo", "espada"]    # una hoja para todos los arquetipos
# Capas de abajo a arriba (contrato e). b_ = capa de la base; sin prefijo = equipo. b_piel va con el cuerpo.
const ORDEN_FRENTE := ["b_pelo_fondo", "b_cuerpo", "b_piel", "b_botas", "b_pantalon", "b_tunica", "b_cinturon",
	"botas", "pantalones", "torso", "guantes", "escudo", "espada", "b_pelo", "casco"]
const ORDEN_DERECHA := ["b_pelo_fondo", "b_cuerpo", "b_piel", "b_botas", "b_pantalon", "escudo", "b_tunica", "b_cinturon",
	"botas", "pantalones", "torso", "guantes", "espada", "b_pelo", "casco"]
const ORDEN_IZQUIERDA := ["b_pelo_fondo", "b_cuerpo", "b_piel", "b_botas", "b_pantalon", "espada", "b_tunica", "b_cinturon",
	"botas", "pantalones", "torso", "guantes", "escudo", "b_pelo", "casco"]
## Capa base que oculta cada ranura equipada (PROPUESTA a confirmar en el mapa; el cinturón no se oculta).
const OCULTA := {"torso": "b_tunica", "pantalones": "b_pantalon", "botas": "b_botas"}
const ROLES := ["principal", "sombra", "acento", "detalle"]

var celda := 0
var pivote := Vector2.ZERO
var indices: Array = []          # Color de cada rol, en el orden de ROLES
var base: Dictionary = {}        # capa base (sin b_) -> Image
var hojas: Dictionary = {}       # "arquetipo/ranura" -> Image (índices)
var errores: Array = []
var cache: Dictionary = {}       # "arq|ranura|familia|variante" -> ImageTexture
var cache_base: Dictionary = {}  # str(look) -> {capa: ImageTexture}
var recoloreados := 0            # nº de texturas generadas (para comprobar la caché)
## Conjunto de ATAQUE (opcional, <dir>/ataque/manifiesto.json, derivado por herramientas/arte/derivar_ataque.gd):
## celda 48, pivote 24/48 (mismo suelo que la caminata), 4 cuadros = poses; base sin espada por capas; hojas por
## arquetipo/ranura con celdas PENDIENTES (vacías). Si falta o es inválido, el ataque usa el cuadro 0 de caminata.
var atq := {"celda": 0, "pivote": Vector2.ZERO, "base": {}, "hojas": {}, "pendientes": {}, "delante": {}, "errores": []}
var estados: Dictionary = {}     # herramienta | dano | caida | dormir -> {celda, pivote, mapa, base, hojas, hacha, errores}
## Estados de E02 y las armas que muestra cada uno (contrato: herramienta = hacha+escudo; daño = espada+escudo; caída/dormir = ninguna).
const ESTADOS_E02 := ["herramienta", "dano", "caida", "dormir"]
const ARMAS_ESTADO := {"herramienta": ["escudo"], "dano": ["espada", "escudo"], "caida": [], "dormir": []}

func _init(dir: String = "res://arte/equipo") -> void:
	var ruta := dir + "/manifiesto.json"
	var man = JSON.parse_string(FileAccess.get_file_as_string(ruta)) if FileAccess.file_exists(ruta) else null
	if not (man is Dictionary and man.get("celda") is float and man.get("pivote") is Array and man.get("indices") is Dictionary
			and man.get("base") is Dictionary and man.get("hojas") is Dictionary):
		errores.append("manifiesto ausente o inválido: " + ruta)
		return
	celda = int(man.celda)
	pivote = Vector2(float(man.pivote[0]), float(man.pivote[1]))
	for rol in ROLES: indices.append(Color(str(man.indices.get(rol, "#000000"))))
	var capas = man.base.get("capas", {})
	if not capas is Dictionary or capas.is_empty(): errores.append("manifiesto: base sin capas")
	else:
		for c in capas: _cargar(dir + "/" + str(capas[c]), func(img: Image) -> void: base[str(c)] = img)
	for arq in man.hojas:
		var por_ranura = man.hojas[arq]
		if not por_ranura is Dictionary: errores.append("manifiesto: hojas.%s" % arq); continue
		for r in por_ranura:
			var h = por_ranura[r]
			var archivo: String = str(h.get("archivo", "")) if h is Dictionary else ""
			_cargar(dir + "/" + archivo, func(img: Image) -> void: hojas["%s/%s" % [arq, r]] = img)
	for e in errores: push_warning("arte_equipo: " + e)
	if errores.is_empty():
		_cargar_ataque(dir + "/ataque")
		_cargar_estados(dir + "/estados")

## Estados de E02 (herramienta, daño, caída, dormir): cada uno con su atlas (columnas × 4 filas de celda 48, pivote 24/48),
## su base por capas y sus hojas de equipo; guantes desdoblados en cercana/lejana. <dir>/<estado>/E02_estado.json.
func _cargar_estados(dir: String) -> void:
	for nombre in ESTADOS_E02:
		var ruta := "%s/%s/E02_estado.json" % [dir, nombre]
		if not FileAccess.file_exists(ruta): continue
		var man = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		var st := {"celda": 0, "pivote": Vector2.ZERO, "mapa": [], "base": {}, "hojas": {}, "hacha": null, "errores": []}
		if not (man is Dictionary and man.get("celda") is Array and man.get("pivote") is Array and man.get("columnas") is float
				and man.get("base") is Dictionary and man.get("equipo") is Dictionary and man.get("cuadros_runtime_a_fuente") is Array):
			st.errores.append("manifiesto de estado inválido: " + ruta)
		else:
			var cel := int(man.celda[0])
			var cols := int(man.columnas)
			var base_dir := "%s/%s/" % [dir, nombre]
			var capas = man.base.get("capas", {})
			if not capas is Dictionary or capas.is_empty(): st.errores.append("%s: base sin capas" % nombre)
			else:
				for c in capas: _cargar_estado_img(base_dir + str(capas[c]), cel, cols, st.errores, func(img: Image) -> void: st.base[str(c)] = img)
			for k in man.equipo:
				_cargar_estado_img(base_dir + str(man.equipo[k]), cel, cols, st.errores, func(img: Image) -> void: st.hojas[str(k)] = img)
			if man.get("herramienta") is String:
				_cargar_estado_img(base_dir + str(man.herramienta), cel, cols, st.errores, func(img: Image) -> void: st.hacha = ImageTexture.create_from_image(img))
			st.celda = cel
			st.pivote = Vector2(float(man.pivote[0]), float(man.pivote[1]))
			st.mapa = man.cuadros_runtime_a_fuente
		for e in st.errores: push_warning("arte_equipo (%s): %s" % [nombre, e])
		estados[nombre] = st

func _cargar_estado_img(f: String, cel: int, cols: int, errs: Array, guardar: Callable) -> void:
	var img: Image = ImagenUtil.imagen(f)
	if img == null: errs.append("falta " + f); return
	if img.get_width() != cols * cel or img.get_height() != 4 * cel: errs.append("%s no mide %dx%d" % [f, cols * cel, 4 * cel]); return
	img.convert(Image.FORMAT_RGBA8)
	guardar.call(img)

func estado_disponible(nombre: String) -> bool:
	return disponible() and estados.has(nombre) and estados[nombre].errores.is_empty() and not estados[nombre].base.is_empty()

func _cargar_ataque(dir: String) -> void:
	var ruta := dir + "/manifiesto.json"
	if not FileAccess.file_exists(ruta): return
	var man = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (man is Dictionary and man.get("celda") is float and man.get("pivote") is Array and man.get("base") is Dictionary
			and man.get("hojas") is Dictionary and (man.base as Dictionary).get("capas") is Dictionary):
		atq.errores.append("manifiesto de ataque inválido: " + ruta)
	else:
		var cel := int(man.celda)
		var capas: Dictionary = man.base.capas
		for c in capas: _cargar_en(dir + "/" + str(capas[c]), cel, atq.errores, func(img: Image) -> void: atq.base[str(c)] = img)
		for arq in man.hojas:
			var por_ranura = man.hojas[arq]
			if not por_ranura is Dictionary: atq.errores.append("manifiesto de ataque: hojas.%s" % arq); continue
			for r in por_ranura:
				var h = por_ranura[r]
				if not h is Dictionary: continue
				var clave := "%s/%s" % [arq, r]
				_cargar_en(dir + "/" + str(h.get("archivo", "")), cel, atq.errores, func(img: Image) -> void: atq.hojas[clave] = img)
				var pend := {}
				for p in h.get("pendientes", []): if p is Array and p.size() == 2: pend[Vector2i(int(p[0]), int(p[1]))] = true
				atq.pendientes[clave] = pend
		for k in man.get("espada_delante", []): atq.delante[str(k)] = true
		var est = man.get("estela")
		if est is Dictionary:   # capa de efecto de la espada (E01): mismo atlas y celda que las poses; solo presentación
			_cargar_en(dir + "/" + str(est.get("archivo", "")), cel, atq.errores, func(img: Image) -> void: atq.estela = ImageTexture.create_from_image(img))
		atq.celda = cel
		atq.pivote = Vector2(float(man.pivote[0]), float(man.pivote[1]))
	for e in atq.errores: push_warning("arte_equipo (ataque): " + e)

func _cargar_en(f: String, cel: int, errs: Array, guardar: Callable) -> void:
	var img: Image = ImagenUtil.imagen(f)
	if img == null: errs.append("falta " + f); return
	if img.get_width() != 4 * cel or img.get_height() != 4 * cel: errs.append("%s no mide %dx%d" % [f, 4 * cel, 4 * cel]); return
	img.convert(Image.FORMAT_RGBA8)
	guardar.call(img)

## El conjunto de ataque está completo (base y hojas cargadas sin error).
func ataque_disponible() -> bool:
	return disponible() and atq.celda > 0 and atq.errores.is_empty() and not atq.base.is_empty()

func _cargar(f: String, guardar: Callable) -> void:
	_cargar_en(f, celda, errores, guardar)

func disponible() -> bool:
	return celda > 0 and errores.is_empty() and not base.is_empty()

## Orden de capas (abajo a arriba) para una orientación.
static func orden(dir: Vector2i, invertir: bool = INVERTIR_PERFILES) -> Array:
	var d := -dir if invertir and dir.x != 0 else dir
	if d == Vector2i.RIGHT: return ORDEN_DERECHA
	if d == Vector2i.LEFT: return ORDEN_IZQUIERDA
	return ORDEN_FRENTE

# ---------- recoloreado ----------
## Color de la paleta con el delta de la variante aplicado en HSV (paletas.json: tono suma con vuelta; saturación
## y brillo suman y se recortan a 0..1). Delta nulo: el color sin tocar.
static func color_final(c: Color, delta: Dictionary) -> Color:
	var dt := float(delta.get("tono", 0.0))
	var ds := float(delta.get("saturacion", 0.0))
	var db := float(delta.get("brillo", 0.0))
	if dt == 0.0 and ds == 0.0 and db == 0.0: return c
	return Color.from_hsv(fposmod(c.h + dt, 1.0), clampf(c.s + ds, 0.0, 1.0), clampf(c.v + db, 0.0, 1.0))

## {rgba32 del índice: Color final}. Un rol ausente en la paleta no se recolorea (el gris sin "detalle").
func mapa_indices(paleta: Dictionary, delta: Dictionary) -> Dictionary:
	var m := {}
	for i in ROLES.size():
		var col = paleta.get(ROLES[i])
		if col is String and Color.html_is_valid(col): m[(indices[i] as Color).to_rgba32()] = color_final(Color(col), delta)
	return m

static func recolorear(img: Image, mapa: Dictionary) -> Image:
	var out: Image = img.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var px := out.get_pixel(x, y)
			if px.a8 == 0: continue
			var k := px.to_rgba32()
			if mapa.has(k): out.set_pixel(x, y, mapa[k])
	return out

## Textura recoloreada de una entrada de Equipo.visible(); null si no hay hoja ni paleta (la pieza no se dibuja).
## conjunto "ataque" usa la hoja de ataque (celda 48) de esa pieza; null si no la hay.
func textura_pieza(e: Dictionary, conjunto: String = "") -> Texture2D:
	var ranura := str(e.get("ranura", ""))
	var arq := "compartido" if ranura in RANURAS_COMPARTIDAS else str(e.get("arquetipo", ""))
	var fuente_hojas: Dictionary = atq.hojas if conjunto == "ataque" else (estados[conjunto].hojas if estados.has(conjunto) else hojas)
	var img: Image = fuente_hojas.get("%s/%s" % [arq, ranura])
	var pal: Dictionary = e.get("paleta") if e.get("paleta") is Dictionary else {}
	if img == null or pal.is_empty(): return null
	var variante := str(e.get("variante", ""))
	var clave := "%s%s|%s|%s|%s" % [conjunto, arq, ranura, str(e.get("familia", e.get("item", ""))), variante if variante != "" else "sin_piedra"]
	if not cache.has(clave):
		var delta: Dictionary = e.get("delta") if e.get("delta") is Dictionary else {}
		cache[clave] = ImageTexture.create_from_image(recolorear(img, mapa_indices(pal, delta)))
		recoloreados += 1
	return cache[clave]

# ---------- base del personaje ----------
## Tiñe una máscara conservando su sombreado: tono y saturación del objetivo; valor = objetivo * (v del píxel / v medio).
## `media` > 0 fija el valor medio de referencia (el ataque usa el de la caminata para que el tono no salte).
static func tenir(img: Image, objetivo: Color, media: float = -1.0) -> Image:
	var out: Image = img.duplicate()
	if media <= 0.0: media = valor_medio(img)
	if media <= 0.0: return out
	for y in out.get_height():
		for x in out.get_width():
			var px := out.get_pixel(x, y)
			if px.a8 > 0: out.set_pixel(x, y, Color.from_hsv(objetivo.h, objetivo.s, clampf(objetivo.v * px.v / media, 0.0, 1.0), px.a))
	return out

static func valor_medio(img: Image) -> float:
	var suma := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a8 > 0:
				suma += px.v
				n += 1
	return suma / n if n > 0 else 0.0

## Apariencia ampliada aditiva; arrays antiguos de tres valores conservan exactamente el dibujo anterior.
## Las variantes de pelo son tratamientos provisionales de la máscara propia, aplicados a todas las poses.
func capas_base(look: Array, conjunto: String = "") -> Dictionary:
	var k := conjunto + str(look)
	if cache_base.has(k): return cache_base[k]
	var tinte := {"piel": _de(P.PIEL, look, 0), "pelo": _de(P.PELO, look, 1), "tunica": _de(P.ROPA, look, 2), "pantalon": P.PANTALON}
	if look.size() == 8:
		tinte.pantalon = Aspecto.PANTALONES[Aspecto.indice(look, 5)]
		tinte.botas = Aspecto.BOTAS[Aspecto.indice(look, 6)]
		tinte.cinturon = Aspecto.CINTURONES[Aspecto.indice(look, 7)]
	var out := {}
	var fuente: Dictionary = atq.base if conjunto == "ataque" else (estados[conjunto].base if estados.has(conjunto) else base)
	for c in fuente:
		var media := valor_medio(base[c]) if conjunto != "" and base.has(c) else -1.0
		var img: Image = tenir(fuente[c], tinte[c], media) if tinte.has(c) else fuente[c]
		if c == "pelo" and look.size() == 8:
			img = _peinado(img, Aspecto.estilo_visual(look), _de(P.PELO, look, 1))
			if Aspecto.estilo_visual(look) in [9, 11]:
				var extension := _cola(fuente[c], Aspecto.estilo_visual(look), _de(P.PELO, look, 1))
				var fondo: Image = extension.duplicate()
				var delante: Image = extension.duplicate()
				var cel := img.get_height() / 4
				for y in img.get_height():
					for x in img.get_width():
						if int(y / cel) == 2: fondo.set_pixel(x, y, Color.TRANSPARENT)
						else: delante.set_pixel(x, y, Color.TRANSPARENT)
				# Por detrás, cola visible sobre la espalda pero bajo el pelo de la cabeza.
				delante.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
				img = delante
				out.b_pelo_fondo = ImageTexture.create_from_image(fondo)
		out["b_" + c] = ImageTexture.create_from_image(img)
	cache_base[k] = out
	return out

# Tratamiento por celda: no invade celdas vecinas ni mueve el pivote de pies/equipo.
static func _peinado(img: Image, estilo: int, pelo: Color) -> Image:
	if estilo == 0: return img
	var out: Image = img.duplicate()
	var cel := img.get_height() / 4
	for fila in 4:
		for col in img.get_width() / cel:
			var origen := Vector2i(col * cel, fila * cel)
			var minimo := Vector2i(cel, cel)
			var maximo := Vector2i(-1, -1)
			for y in cel:
				for x in cel:
					if img.get_pixelv(origen + Vector2i(x, y)).a8 == 0: continue
					minimo = minimo.min(Vector2i(x, y))
					maximo = maximo.max(Vector2i(x, y))
			if maximo.x < 0: continue
			var cx := (minimo.x + maximo.x) / 2
			var cy := minimo.y + 1
			if estilo == 1:   # corto uniforme: conserva íntegra la cobertura y el contorno originales
				for y in range(minimo.y, maximo.y + 1):
					for x in range(minimo.x, maximo.x + 1):
						var pt := origen + Vector2i(x, y)
						var px := img.get_pixelv(pt)
						if px.a8 == 0: continue
						# Mechones muy cortos y unidos, sin mezclar el cabello con el tono de piel.
						var sombra := 0.08 + 0.18 * (y - minimo.y) / maxf(1.0, maximo.y - minimo.y)
						var tono := pelo.darkened(sombra)
						if px.v < pelo.v * 0.72: tono = pelo.darkened(0.42)
						tono.a = px.a
						out.set_pixelv(pt, tono)
			if estilo in [2, 8, 13]:   # tres longitudes; flequillo y rostro permanecen visibles
				var largo := 2 if estilo == 13 else (4 if estilo == 2 else 7)
				for y in range(maximo.y - 1, mini(cel - 1, maximo.y + largo)):
					for x in range(minimo.x + 1, maximo.x):
						if fila != 2 and x > minimo.x + 2 and x < maximo.x - 2: continue
						if estilo == 8 and y >= maximo.y + largo - 2 and (x == minimo.x + 1 or x == maximo.x - 1): continue
						out.set_pixelv(origen + Vector2i(x, y), pelo.darkened(0.12 if x % 2 == 0 else 0.25))
				# Pose acostada: prolongar lateralmente cuando la cabeza ya toca el borde inferior.
				if maximo.y + largo >= cel:
					var paso: int = 1 if maximo.x + largo < cel else -1
					var inicio: int = maximo.x if paso == 1 else minimo.x
					for d in range(1, largo + 1):
						for y in range(maximo.y - 3, maximo.y): _pixel_peinado(out, origen, Vector2i(inicio + d * paso, y), cel, pelo.darkened(0.2))
			elif estilo == 3:   # moño unido al borde posterior de la cabeza
				if fila == 1: cx = minimo.x + 1
				elif fila in [0, 3]: cx = maximo.x - 1
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if dx * dx + dy * dy <= 5: _pixel_peinado(out, origen, Vector2i(cx + dx, cy + dy), cel, pelo.lightened(0.08) if dy < 0 else pelo.darkened(0.14))
			elif estilo == 4:   # despeinado: mechones cortos que nacen del pelo existente
				for x in range(minimo.x + 3, maximo.x - 2, 4):
					var top := -1
					for y in range(minimo.y, mini(maximo.y, minimo.y + 5)):
						if img.get_pixelv(origen + Vector2i(x, y)).a8 > 0:
							top = y
							break
					if top < 0: continue
					# Raíz de dos píxeles sobre la máscara y punta inclinada, siempre conectada.
					_pixel_peinado(out, origen, Vector2i(x, top), cel, pelo)
					_pixel_peinado(out, origen, Vector2i(x + 1, top), cel, pelo.darkened(0.12))
					_pixel_peinado(out, origen, Vector2i(x, top - 1), cel, pelo)
					_pixel_peinado(out, origen, Vector2i(x + 1, top - 2), cel, pelo.lightened(0.1))
			elif estilo in [5, 6]:   # raya lateral: contraste y mechón asimétrico
				var raya: int = minimo.x + 3 if estilo == 5 else maximo.x - 3
				for y in range(minimo.y + 1, maximo.y - 1):
					_pixel_peinado(out, origen, Vector2i(raya, y), cel, pelo.darkened(0.5))
				var borde: int = minimo.x + 1 if estilo == 5 else maximo.x - 1
				for y in range(maximo.y - 1, maximo.y + 2): _pixel_peinado(out, origen, Vector2i(borde, y), cel, pelo)
			elif estilo == 7:   # rizos sobre la máscara: curvas compactas, sin púas flotantes
				for y in range(minimo.y, maximo.y + 1):
					for x in range(minimo.x, maximo.x + 1):
						var pt := origen + Vector2i(x, y)
						var px := img.get_pixelv(pt)
						if px.a8 == 0: continue
						var fase := posmod(x + 2 * (y / 3), 4)
						var tono := pelo.lightened(0.18) if fase == 0 and y % 3 == 1 else pelo.darkened(0.24 if fase == 2 else 0.04)
						out.set_pixelv(pt, tono)
				# Mechones redondos solo donde ya existe pelo y siempre conectados.
				for x in range(minimo.x + 2, maximo.x - 1, 4):
					var top := -1
					for y in range(minimo.y, minimo.y + 4):
						if img.get_pixelv(origen + Vector2i(x, y)).a8 > 0:
							top = y
							break
					if top >= 0: _pixel_peinado(out, origen, Vector2i(x, top - 1), cel, pelo.darkened(0.18))
			elif estilo == 10:   # pixie: pelo compacto, sien descubierta y sin relleno de piel sobre las orejas
				for y in range(minimo.y, maximo.y + 1):
					for x in range(minimo.x, maximo.x + 1):
						var pt := origen + Vector2i(x, y)
						if img.get_pixelv(pt).a8 == 0: continue
						var borde := x < minimo.x + 2 or x > maximo.x - 2
						if borde and y >= minimo.y + 5: out.set_pixelv(pt, Color.TRANSPARENT)
						elif y >= maximo.y - 2 and (x < cx - 3 or x > cx + 3): out.set_pixelv(pt, Color.TRANSPARENT)
						elif y == minimo.y + 2 and x >= cx: out.set_pixelv(pt, pelo.lightened(0.16))
			elif estilo == 12:   # flequillo recto sin tapar los ojos
				if fila != 2:
					for x in range(minimo.x + 2, maximo.x - 1): _pixel_peinado(out, origen, Vector2i(x, minimo.y + 4), cel, pelo.darkened(0.12))
				else:
					for x in range(minimo.x + 2, maximo.x - 1): _pixel_peinado(out, origen, Vector2i(x, maximo.y), cel, pelo)

	return out

# Cola/trenza separada de la cara y del torso: se compone detrás salvo en vista de espalda.
static func _cola(img: Image, estilo: int, pelo: Color) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var cel := img.get_height() / 4
	for fila in 4:
		for col in img.get_width() / cel:
			var origen := Vector2i(col * cel, fila * cel)
			var minimo := Vector2i(cel, cel)
			var maximo := Vector2i(-1, -1)
			for y in cel:
				for x in cel:
					if img.get_pixelv(origen + Vector2i(x, y)).a8 == 0: continue
					minimo = minimo.min(Vector2i(x, y))
					maximo = maximo.max(Vector2i(x, y))
			if maximo.x < 0: continue
			var cx := (minimo.x + maximo.x) / 2
			if fila in [0, 3]: cx = maximo.x - 1
			elif fila == 1: cx = minimo.x + 1
			var inicio := minimo.y + 5
			var fin: int = mini(cel - 2, maximo.y + 10)
			for y in range(inicio, fin):
				var curva: int = 0 if fila == 2 else (1 if fila in [0, 3] else -1)
				var x: int = cx + curva * mini(2, (y - inicio) / 3)
				if estilo == 11: x += (y / 2) % 2
				var ancho: int = 1 if y < fin - 2 else 0
				for dx in range(-ancho, ancho + 1):
					var color := pelo.darkened(0.38) if absi(dx) == ancho and ancho > 0 else pelo.lightened(0.12 if estilo == 11 and y % 3 == 0 else 0.0)
					_pixel_peinado(out, origen, Vector2i(x + dx, y), cel, color)
				if y == inicio + 2: _pixel_peinado(out, origen, Vector2i(x, y), cel, Color("af8b49"))
	return out

static func _pixel_peinado(img: Image, origen: Vector2i, pt: Vector2i, cel: int, color: Color) -> void:
	if pt.x >= 0 and pt.x < cel and pt.y >= 0 and pt.y < cel: img.set_pixelv(origen + pt, color)

static func _de(lista: Array, look: Array, i: int) -> Color:
	var n: int = int(look[i]) if i < look.size() and (look[i] is int or look[i] is float) else 0
	return lista[n] if n >= 0 and n < lista.size() else lista[0]

# ---------- estados de E02 ----------
## [[capa, textura, origen, destino], ...] para herramienta, daño, caída o dormir. Orden del contrato (abajo a arriba):
## cuerpo, piel, ropa base no oculta, guantes lejanos, escudo (perfil derecho: detrás), cinturón, botas, pantalones, torso,
## guantes cercanos, escudo (resto), espada (solo daño; perfil izquierdo: detrás), pelo, casco y hacha (solo herramienta y
## solo si `hacha`). Los guantes se dibujan desdoblados, nunca con el atlas combinado.
func _comandos_estado(pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, estado: String, hacha: bool) -> Array:
	var st: Dictionary = estados[estado]
	var cel: int = st.celda
	var col := int(st.mapa[posmod(cuadro, st.mapa.size())])
	var dst := Rect2((pies - st.pivote).round(), Vector2(cel, cel))
	var src := Rect2(Vector2(col, FILA.get(dir, 0)) * cel, Vector2(cel, cel))
	var armas: Array = ARMAS_ESTADO.get(estado, [])
	var piezas := {}
	for e in equipo:
		if not e is Dictionary: continue
		var r := str(e.ranura)
		if r in RANURAS_COMPARTIDAS and not r in armas: continue
		if r == "guantes":
			for lado in ["lejana", "cercana"]:
				var e2: Dictionary = e.duplicate()
				e2.ranura = "guantes_" + lado
				var tg := textura_pieza(e2, estado)
				if tg != null: piezas["guantes_" + lado] = tg
			continue
		var t := textura_pieza(e, estado)
		if t != null: piezas[r] = t
	var ocultas: Array = []
	for r in piezas: if OCULTA.has(r): ocultas.append(OCULTA[r])
	var b := capas_base(look, estado)
	var orden: Array = ["b_pelo_fondo", "b_cuerpo", "b_piel", "b_botas", "b_pantalon", "guantes_lejana"]
	if dir == Vector2i.RIGHT: orden.append("escudo")
	if dir == Vector2i.LEFT: orden.append("espada")
	orden += ["b_tunica", "b_cinturon", "botas", "pantalones", "torso", "guantes_cercana"]
	if dir != Vector2i.RIGHT: orden.append("escudo")
	if dir != Vector2i.LEFT: orden.append("espada")
	orden += ["b_pelo", "casco"]
	var out: Array = []
	for capa in orden:
		if capa in ocultas: continue
		if b.has(capa): out.append([capa, b[capa], src, dst])
		elif piezas.has(capa): out.append([capa, piezas[capa], src, dst])
	if hacha and estado == "herramienta" and st.hacha != null: out.append(["hacha", st.hacha, src, dst])
	return out

# ---------- dibujo ----------
## [[capa, textura, origen, destino], ...] de abajo a arriba. cuadro = cuadro de caminata (reposo = 0).
## equipo: entradas de Equipo.visible() (+ espada). Las piezas sin hoja o paleta se omiten y no ocultan nada.
## estado "ataque" con el conjunto de ataque disponible: base y piezas en celda 48 con el cuadro = pose (0-3); una
## pieza con esa celda PENDIENTE no se dibuja ni oculta su capa base (se ve la pose de ataque.png); una pieza sin hoja
## de ataque usa su cuadro 0 de caminata. En las poses donde ataque.png pinta la espada sobre el cuerpo
## (manifiesto "espada_delante") la espada pasa delante del torso aunque el perfil la ponga detrás.
func comandos(pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, invertir: bool = INVERTIR_PERFILES, estado: String = "", hacha: bool = false) -> Array:
	var out: Array = []
	if not disponible(): return out
	if estado_disponible(estado): return _comandos_estado(pies, dir, cuadro, equipo, look, estado, hacha)
	var fila: int = FILA.get(dir, 0)
	var dst := Rect2((pies - pivote).round(), Vector2(celda, celda))
	var src := Rect2(Vector2(posmod(cuadro, 4), fila) * celda, Vector2(celda, celda))
	var en_ataque := estado == "ataque" and ataque_disponible()
	var conjunto := "ataque" if en_ataque else ""
	var src_est := Rect2(Vector2(0, fila) * celda, Vector2(celda, celda))     # cuadro estático de caminata
	var dst_a := Rect2((pies - atq.pivote).round(), Vector2(atq.celda, atq.celda))
	var src_a := Rect2(Vector2(posmod(cuadro, 4), fila) * atq.celda, Vector2(atq.celda, atq.celda))
	var piezas := {}   # ranura -> [textura, origen, destino]
	for e in equipo:
		if not e is Dictionary: continue
		var r := str(e.ranura)
		if en_ataque:
			var arq := "compartido" if r in RANURAS_COMPARTIDAS else str(e.get("arquetipo", ""))
			var pend: Dictionary = atq.pendientes.get("%s/%s" % [arq, r], {})
			if pend.has(Vector2i(fila, posmod(cuadro, 4))): continue
			var ta := textura_pieza(e, "ataque")
			if ta != null: piezas[r] = [ta, src_a, dst_a]; continue
			var te := textura_pieza(e)
			if te != null: piezas[r] = [te, src_est, dst]
			continue
		var t := textura_pieza(e)
		if t != null: piezas[r] = [t, src, dst]
	var ocultas: Array = []
	for r in piezas: if OCULTA.has(r): ocultas.append(OCULTA[r])
	var b := capas_base(look, conjunto)
	var lista: Array = orden(dir, invertir)
	if en_ataque and atq.delante.has("%d,%d" % [fila, posmod(cuadro, 4)]) and lista.find("espada") < lista.find("torso"):
		lista = lista.duplicate()
		lista.erase("espada")
		lista.insert(lista.find("guantes") + 1, "espada")
	for capa in lista:
		if capa in ocultas: continue
		if b.has(capa): out.append([capa, b[capa], src_a if en_ataque else src, dst_a if en_ataque else dst])
		elif piezas.has(capa): out.append([capa, piezas[capa][0], piezas[capa][1], piezas[capa][2]])
	return out

func dibujar(ci: CanvasItem, pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, estado: String = "", hacha: bool = false, herramienta: String = "") -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tool := herramienta if herramienta != "" else ("hacha" if hacha else "")
	var textura := viajero071.texture(look, dir, estado, cuadro, equipo, tool)
	ci.draw_texture_rect(textura, Rect2((pies - Vector2(24,48)).round(), Vector2(48,48)), false)

## Retained for existing layer contracts and compatibility checks.
func dibujar_heredado(ci: CanvasItem, pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, estado: String = "", hacha: bool = false) -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for c in comandos(pies, dir, cuadro, equipo, look, INVERTIR_PERFILES, estado, hacha): ci.draw_texture_rect_region(c[1], c[3], c[2])
	if estado == "ataque" and ataque_disponible() and atq.get("estela") != null:
		var tam := Vector2(atq.celda, atq.celda)
		ci.draw_texture_rect_region(atq.estela, Rect2((pies - atq.pivote).round(), tam), Rect2(Vector2(posmod(cuadro, 4), FILA.get(dir, 0)) * atq.celda, tam))
