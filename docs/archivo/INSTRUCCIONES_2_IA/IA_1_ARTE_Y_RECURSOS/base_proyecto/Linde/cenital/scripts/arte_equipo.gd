extends RefCounted
# Personaje base + equipo por capas con las hojas de colores índice (Linde/documentos/contrato-equipo.md, PROPUESTA).
# Hojas en <dir>/manifiesto.json: celda 32, pivote [16, 32], filas frente/derecha/espalda/izquierda, 4 cuadros.
# Recoloreado por CPU (Image), sin shaders: cada color índice -> color de la paleta de la familia -> delta de la variante.
# Las texturas se cachean por (arquetipo, ranura, familia, variante); la base, por apariencia (look).
# Si falta el manifiesto, la base o cualquier hoja, disponible() es false y la escena usa el dibujo procedural.
const P = preload("res://scripts/params.gd")

## Lateralidad de los perfiles (decisión abierta 2 del contrato). false = como propone el contrato: mirando a la
## derecha el escudo queda detrás del torso y la espada delante; a la izquierda, al revés. true intercambia ambos perfiles.
const INVERTIR_PERFILES := false
const FILA := {Vector2i.DOWN: 0, Vector2i.RIGHT: 1, Vector2i.UP: 2, Vector2i.LEFT: 3}
const RANURAS_COMPARTIDAS := ["escudo", "espada"]    # una hoja para todos los arquetipos
# Capas de abajo a arriba (contrato e). b_ = capa de la base; sin prefijo = equipo. b_piel va con el cuerpo.
const ORDEN_FRENTE := ["b_cuerpo", "b_piel", "b_botas", "b_pantalon", "b_tunica", "b_cinturon",
	"botas", "pantalones", "torso", "guantes", "escudo", "espada", "b_pelo", "casco"]
const ORDEN_DERECHA := ["b_cuerpo", "b_piel", "b_botas", "b_pantalon", "escudo", "b_tunica", "b_cinturon",
	"botas", "pantalones", "torso", "guantes", "espada", "b_pelo", "casco"]
const ORDEN_IZQUIERDA := ["b_cuerpo", "b_piel", "b_botas", "b_pantalon", "espada", "b_tunica", "b_cinturon",
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
	if errores.is_empty(): _cargar_ataque(dir + "/ataque")

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
	var img: Image = (atq.hojas if conjunto == "ataque" else hojas).get("%s/%s" % [arq, ranura])
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

## Capas base con la apariencia del jugador: piel, pelo y túnica según look [piel, pelo, ropa] (params.gd); el pantalón
## con P.PANTALON. Cuerpo (contorno y ojos), botas y cinturón quedan con su color original: no hay color de apariencia.
## conjunto "ataque": las capas base de ataque (sin espada), teñidas con la media de la caminata.
func capas_base(look: Array, conjunto: String = "") -> Dictionary:
	var k := conjunto + str(look)
	if cache_base.has(k): return cache_base[k]
	var tinte := {"piel": _de(P.PIEL, look, 0), "pelo": _de(P.PELO, look, 1), "tunica": _de(P.ROPA, look, 2), "pantalon": P.PANTALON}
	var out := {}
	var fuente: Dictionary = atq.base if conjunto == "ataque" else base
	for c in fuente:
		var media := valor_medio(base[c]) if conjunto == "ataque" and base.has(c) else -1.0
		out["b_" + c] = ImageTexture.create_from_image(tenir(fuente[c], tinte[c], media) if tinte.has(c) else fuente[c])
	cache_base[k] = out
	return out

static func _de(lista: Array, look: Array, i: int) -> Color:
	var n: int = int(look[i]) if i < look.size() and (look[i] is int or look[i] is float) else 0
	return lista[n] if n >= 0 and n < lista.size() else lista[0]

# ---------- dibujo ----------
## [[capa, textura, origen, destino], ...] de abajo a arriba. cuadro = cuadro de caminata (reposo = 0).
## equipo: entradas de Equipo.visible() (+ espada). Las piezas sin hoja o paleta se omiten y no ocultan nada.
## estado "ataque" con el conjunto de ataque disponible: base y piezas en celda 48 con el cuadro = pose (0-3); una
## pieza con esa celda PENDIENTE no se dibuja ni oculta su capa base (se ve la pose de ataque.png); una pieza sin hoja
## de ataque usa su cuadro 0 de caminata. En las poses donde ataque.png pinta la espada sobre el cuerpo
## (manifiesto "espada_delante") la espada pasa delante del torso aunque el perfil la ponga detrás.
func comandos(pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, invertir: bool = INVERTIR_PERFILES, estado: String = "") -> Array:
	var out: Array = []
	if not disponible(): return out
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

func dibujar(ci: CanvasItem, pies: Vector2, dir: Vector2i, cuadro: int, equipo: Array, look: Array, estado: String = "") -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for c in comandos(pies, dir, cuadro, equipo, look, INVERTIR_PERFILES, estado): ci.draw_texture_rect_region(c[1], c[3], c[2])
