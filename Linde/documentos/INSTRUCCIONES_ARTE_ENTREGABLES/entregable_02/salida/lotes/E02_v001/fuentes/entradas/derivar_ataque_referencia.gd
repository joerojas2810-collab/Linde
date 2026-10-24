extends SceneTree
## Deriva las capas de ATAQUE (celda 48) del equipo indexado de Linde. Reproducible: misma entrada, misma salida.
## Uso (desde la raíz del repo): Godot --headless --script herramientas/arte/derivar_ataque.gd [-- --revision=<dir>]
## Entradas (SOLO LECTURA): Linde/arte-entregado/biblioteca_01/personaje/ataque.png (compuesta: cuerpo + ropa + espada,
## celda 48, pivote 24/48, filas frente/derecha/espalda/izquierda, 4 poses) y las hojas de caminata ya integradas en
## Linde/cenital/arte/equipo/ (celda 32, pivote 16/32) con su base/capas.
## Salida: Linde/cenital/arte/equipo/ataque/ (hojas índice, base sin espada por capas, manifiesto con hashes, mediciones
## y validación, PENDIENTE_DE_ARTE.md). --revision=<dir> escribe además imágenes de revisión ampliadas.
## Método y límites: Linde/cenital/docs/DECISIONES.md, sección «Ataque con equipo (celda 48)».

const ATAQUE := "Linde/arte-entregado/biblioteca_01/personaje/ataque.png"
const EQ := "Linde/cenital/arte/equipo"
const SAL := "Linde/cenital/arte/equipo/ataque"
const Validador = preload("validar_hoja.gd")
const C := 48                       # celda de ataque
const W := 32                       # celda de caminata
const OFS := Vector2i(8, 16)        # pivote 16/32 de caminata -> 24/48 de ataque (mismo suelo)
const CLASES := ["cuerpo", "piel", "pelo", "tunica", "pantalon", "botas", "cinturon"]
## pieza -> referencia que se sigue: una capa base (pelo, túnica) o una región de la silueta sin espada ni piel:
## «piernas» = todo lo que queda por debajo de la cintura (y >= 23 en coordenadas de caminata), «pies» = y >= 26.
## (En ataque.png el pantalón usa casi los mismos tonos que el contorno: por color no se separa, por región sí.)
const RIGIDAS := {"casco": "pelo", "torso": "tunica", "pantalones": "piernas", "botas": "pies"}
const REGION_Y := {"piernas": 23, "pies": 26}
const ARQ := ["ligera", "media", "pesada"]
const DIRS := ["frente", "derecha", "espalda", "izquierda"]
const POSES := ["preparado", "anticipacion", "impacto", "recuperacion"]
const ROJO := Color(1, 0, 0)
const VERDE := Color(0, 1, 0)
const AZUL := Color(0, 0, 1)
## Umbrales de aceptación del seguimiento rígido (propios; ver DECISIONES.md). Por debajo: PENDIENTE DE ARTE.
const IOU_MIN := 0.38               # solape de la capa de referencia caminata desplazada vs. ataque
const FUERA_MAX := 0.12             # fracción de píxeles de la pieza fuera de la silueta de ataque (dilatada 1 px)
const BUSCA := Vector2i(10, 8)      # rango de búsqueda de traslación (±x, ±y)

var atq: Image
var opaco := PackedByteArray()      # 192x192: 1 si ataque.png es opaco
var espada := PackedByteArray()     # 1 hoja/contorno/estela de la espada, 2 empuñadura
var cuerpo: Image                   # ataque sin espada (con huecos rellenados)
var clase := PackedByteArray()      # índice en CLASES + 1 (0 = transparente)
var caminata := {}                  # clase -> Image 128 (base/capas)
var informe := {"seguimiento": {}, "manos": {}, "pendientes": [], "huecos_rellenados": 0, "empunadura": 0, "borde_espada": 0, "tapa": {}, "estela": {}}

func _init() -> void:
	var rev := ""
	for a in OS.get_cmdline_user_args(): if a.begins_with("--revision="): rev = a.substr(11)
	atq = Image.load_from_file(ATAQUE)
	if atq == null or atq.get_width() != 4 * C: push_error("no se puede leer " + ATAQUE); quit(1); return
	atq.convert(Image.FORMAT_RGBA8)
	for k in CLASES:
		var im := Image.load_from_file(EQ + "/base/capas/%s.png" % k)
		im.convert(Image.FORMAT_RGBA8)
		caminata[k] = im
	var todo := Image.load_from_file(EQ + "/base/caminata.png")
	todo.convert(Image.FORMAT_RGBA8)
	caminata["_todo"] = todo
	DirAccess.make_dir_recursive_absolute(SAL + "/base/capas")
	DirAccess.make_dir_recursive_absolute(SAL + "/referencia")
	DirAccess.copy_absolute(ProjectSettings.globalize_path(ATAQUE) if ATAQUE.begins_with("res://") else ATAQUE, SAL + "/referencia/ataque.png")
	_separar_espada()
	_clasificar()
	var hojas := {}
	for arq in ARQ:
		for p in RIGIDAS: hojas["%s/%s" % [arq, p]] = _rigida(arq, p)
	var manos := _medir_manos()
	for arq in ARQ: hojas["%s/guantes" % arq] = _guantes(arq, manos)
	hojas["compartido/escudo"] = _escudo(manos)
	hojas["compartido/espada"] = _espada()
	_guardar(hojas, rev)
	quit(0)

# ---------------------------------------------------------------- utilidades
static func _i(x: int, y: int, w: int = 4 * C) -> int: return y * w + x

func _op(x: int, y: int) -> bool: return x >= 0 and y >= 0 and x < 4 * C and y < 4 * C and opaco[_i(x, y)] == 1

static func es_hoja(c: Color) -> bool: return c.s < 0.3 and c.v > 0.3          # acero y estela (gris azulado claro)
static func es_piel(c: Color) -> bool: return (c.h < 0.1) and c.v > 0.6 and c.s < 0.72
static func es_marron(c: Color) -> bool: return (c.h < 0.1 or c.h > 0.95) and c.v > 0.2 and c.v <= 0.6 and c.s > 0.45
static func es_teal(c: Color) -> bool: return c.g > c.r * 1.4 and c.b > c.r * 1.0 and c.v > 0.12
static func es_azul(c: Color) -> bool: return c.b > c.r * 1.15 and c.v >= 0.1 and not es_teal(c)

## Celda (fila, col) de un píxel de la hoja de 48.
static func celda_de(x: int, y: int) -> Vector2i: return Vector2i(x / C, y / C)

# ---------------------------------------------------------------- 3. espada fuera del cuerpo
## Espada = píxeles de acero/estela (es_hoja) + su contorno oscuro que no toca color de cuerpo + empuñadura marrón
## pegada al acero y al puño. Después se rellenan los huecos que la espada tapaba dentro del cuerpo (vecinos >= 3).
func _separar_espada() -> void:
	var n := 4 * C
	opaco.resize(n * n); espada.resize(n * n)
	for y in n:
		for x in n:
			var c := atq.get_pixel(x, y)
			opaco[_i(x, y)] = 1 if c.a8 == 255 else 0
			if c.a8 == 255 and es_hoja(c): espada[_i(x, y)] = 1
	var nucleo := func(x: int, y: int) -> bool:     # píxel de color de cuerpo (ni oscuro ni acero)
		if not _op(x, y) or espada[_i(x, y)] != 0: return false
		return atq.get_pixel(x, y).v >= 0.2
	var cont: Array = []
	for y in n:
		for x in n:
			if not _op(x, y) or espada[_i(x, y)] != 0 or atq.get_pixel(x, y).v >= 0.2: continue
			var junto := false
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if celda_de(q.x, q.y) == celda_de(x, y) and _op(q.x, q.y) and espada[_i(q.x, q.y)] == 1: junto = true
			if not junto: continue
			var toca := false
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if nucleo.call(x + d.x, y + d.y): toca = true
			if not toca: cont.append(Vector2i(x, y))
	for p: Vector2i in cont: espada[_i(p.x, p.y)] = 1
	# empuñadura: marrón con acero/contorno de espada al lado y piel (puño) al lado
	var emp: Array = []
	for y in n:
		for x in n:
			if not _op(x, y) or espada[_i(x, y)] != 0 or not es_marron(atq.get_pixel(x, y)): continue
			var a_espada := false; var a_piel := false
			for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if not _op(q.x, q.y) or celda_de(q.x, q.y) != celda_de(x, y): continue
				if espada[_i(q.x, q.y)] == 1: a_espada = true
				if es_piel(atq.get_pixel(q.x, q.y)): a_piel = true
			if a_espada and a_piel: emp.append(Vector2i(x, y))
	for p: Vector2i in emp: espada[_i(p.x, p.y)] = 2
	informe.empunadura = emp.size()
	# cuerpo sin espada + relleno de huecos interiores
	cuerpo = atq.duplicate()
	for y in n:
		for x in n:
			if espada[_i(x, y)] != 0: cuerpo.set_pixel(x, y, Color(0, 0, 0, 0))
	for pasada in 3:
		var nuevos: Array = []
		for y in n:
			for x in n:
				if espada[_i(x, y)] == 0 or cuerpo.get_pixel(x, y).a8 != 0: continue
				var cols := {}
				var vec := 0
				for d in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
					var q: Vector2i = Vector2i(x, y) + d
					if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n or celda_de(q.x, q.y) != celda_de(x, y): continue
					var c := cuerpo.get_pixel(q.x, q.y)
					if c.a8 == 0: continue
					vec += 1
					var k := c.to_html()
					cols[k] = cols.get(k, 0) + 1
				if vec < 3: continue
				var mejor := ""
				for k in cols: if mejor == "" or cols[k] > cols[mejor]: mejor = k
				nuevos.append([Vector2i(x, y), Color(mejor)])
		for e in nuevos:
			var pe: Vector2i = e[0]
			cuerpo.set_pixel(pe.x, pe.y, e[1])
			var kc := "%d,%d" % [pe.y / C, pe.x / C]
			informe.tapa[kc] = int(informe.tapa.get(kc, 0)) + 1
		informe.huecos_rellenados += nuevos.size()
	# restos: islas pequeñas (< 8 px, sin piel) separadas del cuerpo y a <= 2 px de la espada son contorno de la espada
	informe["restos"] = 0
	for fila in 4:
		for col in 4:
			var comps := _componentes(func(p: Vector2i) -> bool: return cuerpo.get_pixel(col * C + p.x, fila * C + p.y).a8 != 0)
			comps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.size() > b.size())
			for k in range(1, comps.size()):
				var comp: Dictionary = comps[k]
				if comp.size() >= 8: continue
				var cerca := false
				var piel := false
				for p: Vector2i in comp:
					if es_piel(cuerpo.get_pixel(col * C + p.x, fila * C + p.y)): piel = true
					for y in range(maxi(0, p.y - 2), mini(C, p.y + 3)):
						for x in range(maxi(0, p.x - 2), mini(C, p.x + 3)):
							if espada[_i(col * C + x, fila * C + y)] != 0: cerca = true
				if piel or not cerca: continue
				for p: Vector2i in comp:
					espada[_i(col * C + p.x, fila * C + p.y)] = 1
					cuerpo.set_pixel(col * C + p.x, fila * C + p.y, Color(0, 0, 0, 0))
					informe.restos += 1

## Componentes 8-conexas de la celda (coordenadas locales 0..C-1) donde `dentro` es true.
static func _componentes(dentro: Callable, cel: int = C) -> Array:
	var visto := {}
	var out: Array = []
	for y in cel:
		for x in cel:
			var p := Vector2i(x, y)
			if visto.has(p) or not dentro.call(p): continue
			var comp := {}
			var pila: Array = [p]
			visto[p] = true
			while not pila.is_empty():
				var q: Vector2i = pila.pop_back()
				comp[q] = true
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var r := q + Vector2i(dx, dy)
						if r.x < 0 or r.y < 0 or r.x >= cel or r.y >= cel or visto.has(r) or not dentro.call(r): continue
						visto[r] = true
						pila.append(r)
			out.append(comp)
	return out

# ---------------------------------------------------------------- capas base de ataque
## Clase por color con la altura relativa a la cabeza (yh: pelo/túnica/cinturón) o a los pies (yf: botas/pantalón),
## en coordenadas de caminata (celda 32). Misma partición que capas/ de la biblioteca (convertir.gd), con reglas de
## color propias de la paleta de ataque.
func _clasificar() -> void:
	var n := 4 * C
	clase.resize(n * n)
	for fila in 4:
		var pelo_cam := _tope(caminata.pelo, fila, 0, W)
		for col in 4:
			var tope := 99
			for y in C:
				for x in C:
					var c := cuerpo.get_pixel(col * C + x, fila * C + y)
					if c.a8 == 255 and es_teal(c): tope = mini(tope, y); break
				if tope < 99: break
			var corr := tope - (pelo_cam + OFS.y)
			for y in C:
				for x in C:
					var px := Vector2i(col * C + x, fila * C + y)
					var c := cuerpo.get_pixel(px.x, px.y)
					if c.a8 == 0: continue
					clase[_i(px.x, px.y)] = CLASES.find(_clase(c, y - OFS.y - corr, y - OFS.y)) + 1

static func _clase(c: Color, yh: int, yf: int) -> String:
	if es_piel(c): return "piel"
	if es_teal(c): return "pelo" if yh < 17 else "tunica"
	if es_marron(c):
		if yh >= 20 and yh <= 24: return "cinturon"
		if yf >= 24: return "botas"
		return "cuerpo"
	if es_azul(c) and yf >= 25: return "pantalon"
	return "cuerpo"

## Primera fila con píxel opaco en la celda (fila, col) de una hoja de celda `cel`.
static func _tope(im: Image, fila: int, col: int, cel: int) -> int:
	for y in cel:
		for x in cel:
			if im.get_pixel(col * cel + x, fila * cel + y).a8 != 0: return y
	return cel

## Máscara (Array de Vector2i locales) de una clase de ataque en la celda.
func _mascara_atq(k: String, fila: int, col: int) -> Dictionary:
	var m := {}
	var id := CLASES.find(k) + 1
	for y in C:
		for x in C:
			if clase[_i(col * C + x, fila * C + y)] == id: m[Vector2i(x, y)] = true
	return m

## Referencia de seguimiento en ataque (sin espada) o en caminata (cuadro f), en coordenadas locales de su celda.
func _ref_atq(ref: String, fila: int, col: int) -> Dictionary:
	if ref in CLASES: return _mascara_atq(ref, fila, col)
	var m := {}
	var idp := CLASES.find("piel") + 1
	for y in range(OFS.y + int(REGION_Y[ref]), C):
		for x in C:
			var i := _i(col * C + x, fila * C + y)
			if clase[i] != 0 and clase[i] != idp: m[Vector2i(x, y)] = true
	return m

func _ref_cam(ref: String, fila: int, f: int) -> Dictionary:
	if ref in CLASES: return _mascara_img(caminata[ref], fila, f, W)
	var m := {}
	for y in range(int(REGION_Y[ref]), W):
		for x in W:
			var p := Vector2i(f * W + x, fila * W + y)
			if (caminata._todo as Image).get_pixel(p.x, p.y).a8 != 0 and (caminata.piel as Image).get_pixel(p.x, p.y).a8 == 0: m[Vector2i(x, y)] = true
	return m

static func _mascara_img(im: Image, fila: int, col: int, cel: int) -> Dictionary:
	var m := {}
	for y in cel:
		for x in cel:
			if im.get_pixel(col * cel + x, fila * cel + y).a8 != 0: m[Vector2i(x, y)] = true
	return m

static func _iou(a: Dictionary, b: Dictionary, d: Vector2i) -> float:
	if a.is_empty() or b.is_empty(): return 0.0
	var inter := 0
	for p: Vector2i in a: if b.has(p + d): inter += 1
	return float(inter) / float(a.size() + b.size() - inter)

static func _centroide(m: Dictionary) -> Vector2:
	var s := Vector2.ZERO
	for p: Vector2i in m: s += Vector2(p)
	return s / maxf(1.0, float(m.size()))

# ---------------------------------------------------------------- 2a. piezas rígidas
## Para cada dirección y pose: elige el cuadro de caminata f y la traslación (dx, dy) que maximizan el solape (IoU)
## de la capa base de referencia (pelo, túnica, pantalón, botas) de caminata con la misma capa en ataque. La pieza de
## caminata (fila, f) se copia con esa traslación. Por debajo de IOU_MIN o con más de FUERA_MAX fuera de la silueta:
## celda vacía y PENDIENTE DE ARTE.
func _rigida(arq: String, pieza: String) -> Image:
	var hoja := Image.load_from_file(EQ + "/equipo_%s_%s_caminata.png" % [arq, pieza])
	hoja.convert(Image.FORMAT_RGBA8)
	var out := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	var ref: String = RIGIDAS[pieza]
	var seg := {}
	for fila in 4:
		for col in 4:
			var objetivo := _ref_atq(ref, fila, col)
			var mejor := {"iou": -1.0}
			for f in 4:
				var base := _ref_cam(ref, fila, f)
				for dy in range(-BUSCA.y, BUSCA.y + 1):
					for dx in range(-BUSCA.x, BUSCA.x + 1):
						var d := OFS + Vector2i(dx, dy)
						var v := _iou(base, objetivo, d)
						# desempate determinista: más solape; luego cuadro 0 y menor desplazamiento
						var coste := absi(dx) + absi(dy) + f
						if v > mejor.iou + 1e-9 or (absf(v - mejor.iou) <= 1e-9 and coste < int(mejor.coste)):
							mejor = {"iou": v, "f": f, "d": d, "coste": coste}
			var d: Vector2i = mejor.d
			var f: int = mejor.f
			var pix := _mascara_img(hoja, fila, f, W)
			var fuera := 0
			for p: Vector2i in pix: if not _cerca_opaco(col * C + p.x + d.x, fila * C + p.y + d.y, 1, fila, col): fuera += 1
			var frac := float(fuera) / maxf(1.0, float(pix.size()))
			var acepta: bool = float(mejor.iou) >= IOU_MIN and frac <= FUERA_MAX
			seg["%d,%d" % [fila, col]] = {"cuadro_caminata": f, "traslacion": [d.x - OFS.x, d.y - OFS.y], "iou": snappedf(float(mejor.iou), 0.001),
				"fuera": snappedf(frac, 0.001), "aceptada": acepta}
			if not acepta:
				informe.pendientes.append({"hoja": "%s/%s" % [arq, pieza], "fila": fila, "cuadro": col, "direccion": DIRS[fila], "pose": POSES[col],
					"motivo": "seguimiento rígido insuficiente: IoU %.2f (mín %.2f) de '%s', %.0f %% de la pieza fuera de la silueta (máx %.0f %%)"
					% [mejor.iou, IOU_MIN, ref, frac * 100.0, FUERA_MAX * 100.0]})
				continue
			for p: Vector2i in pix:
				out.set_pixel(col * C + p.x + d.x, fila * C + p.y + d.y, hoja.get_pixel(f * W + p.x, fila * W + p.y))
	informe.seguimiento["%s/%s" % [arq, pieza]] = seg
	return out

## ¿Hay opaco de ataque.png a <= r px (cuadrado) dentro de la misma celda?
func _cerca_opaco(x: int, y: int, r: int, fila: int, col: int) -> bool:
	for yy in range(y - r, y + r + 1):
		for xx in range(x - r, x + r + 1):
			if xx < col * C or yy < fila * C or xx >= (col + 1) * C or yy >= (fila + 1) * C: continue
			if opaco[_i(xx, yy)] == 1: return true
	return false

# ---------------------------------------------------------------- 2b. manos, guantes, escudo, espada
## Separa cara y manos en una máscara de piel: la cara es el componente con más píxeles por encima del cuello
## (tope del pelo + 13, en la escala del personaje, igual en celda 32 y 48); el resto son manos.
static func _manos_de(piel: Dictionary, tope_pelo: int, cel: int) -> Array:
	var comps := _componentes(func(p: Vector2i) -> bool: return piel.has(p), cel)
	var cuello := tope_pelo + 13
	var cara := -1
	var mejor := 0
	for i in comps.size():
		var alto := 0
		for p: Vector2i in comps[i]: if p.y < cuello: alto += 1
		if alto > mejor: mejor = alto; cara = i
	var out: Array = []
	for i in comps.size(): if i != cara: out.append(comps[i])
	return out

## Mano de la espada = la más cercana a la espada separada (<= 2 px); mano libre (escudo) = la mayor de las demás.
func _medir_manos() -> Dictionary:
	var out := {}
	for fila in 4:
		for col in 4:
			var tope_pelo: int = _tope_mascara(_mascara_atq("pelo", fila, col))
			var manos: Array = []
			for m: Dictionary in _manos_de(_mascara_atq("piel", fila, col), tope_pelo, C):
				var de := 99.0
				for p: Vector2i in m:
					for y in range(maxi(0, p.y - 2), mini(C, p.y + 3)):
						for x in range(maxi(0, p.x - 2), mini(C, p.x + 3)):
							if espada[_i(col * C + x, fila * C + y)] != 0: de = minf(de, Vector2(p).distance_to(Vector2(x, y)))
				manos.append({"pix": m, "c": _centroide(m), "d_espada": de})
			var arma := -1
			for i in manos.size():
				if float(manos[i].d_espada) <= 2.0 and (arma < 0 or float(manos[i].d_espada) < float(manos[arma].d_espada)): arma = i
			var libre := -1
			for i in manos.size():
				if i == arma: continue
				if libre < 0 or (manos[i].pix as Dictionary).size() > (manos[libre].pix as Dictionary).size(): libre = i
			out["%d,%d" % [fila, col]] = {"manos": manos, "espada": arma, "escudo": libre}
			informe.manos["%d,%d" % [fila, col]] = {
				"espada": [snappedf(manos[arma].c.x, 0.1), snappedf(manos[arma].c.y, 0.1)] if arma >= 0 else null,
				"escudo": [snappedf(manos[libre].c.x, 0.1), snappedf(manos[libre].c.y, 0.1)] if libre >= 0 else null,
				"otras": manos.size() - int(arma >= 0) - int(libre >= 0)}
	return out

static func _tope_mascara(m: Dictionary) -> int:
	var t := 99
	for p: Vector2i in m: t = mini(t, p.y)
	return t

## Guantes: los píxeles de las manos medidas, en índice (rojo; la fila inferior de cada mano, verde sombra).
## Pesada: además el contorno oscuro de ataque.png que rodea la mano (guantelete 1 px más grueso, dentro de la silueta).
func _guantes(arq: String, manos: Dictionary) -> Image:
	var out := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	for fila in 4:
		for col in 4:
			var mm: Dictionary = manos["%d,%d" % [fila, col]]
			if (mm.manos as Array).is_empty():
				informe.pendientes.append({"hoja": "%s/guantes" % arq, "fila": fila, "cuadro": col, "direccion": DIRS[fila], "pose": POSES[col],
					"motivo": "ninguna mano visible separada de la cara en ataque.png"})
				continue
			for m: Dictionary in mm.manos:
				var pix: Dictionary = (m.pix as Dictionary).duplicate()
				if arq == "pesada":
					for p: Vector2i in m.pix:
						for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
							var q: Vector2i = p + d
							if q.x < 1 or q.y < 1 or q.x >= C - 1 or q.y >= C - 1: continue
							var gx: int = col * C + q.x
							var gy: int = fila * C + q.y
							if opaco[_i(gx, gy)] == 1 and espada[_i(gx, gy)] == 0 and atq.get_pixel(gx, gy).v < 0.2: pix[q] = true
				var fondo := {}
				for p: Vector2i in pix: fondo[p.x] = maxi(int(fondo.get(p.x, -1)), p.y)
				for p: Vector2i in pix:
					out.set_pixel(col * C + p.x, fila * C + p.y, VERDE if p.y == int(fondo[p.x]) and (pix as Dictionary).size() > 2 else ROJO)
	return out

## Escudo: la forma de la hoja de caminata (fila, cuadro 0) se coloca respecto a la mano libre medida con el mismo
## desplazamiento mano->escudo que tiene en caminata (la mano se mueve, el escudo la acompaña). Si la caminata no
## muestra la mano del escudo, o con ella el escudo sale del cuerpo, se ancla al torso (traslación medida para la
## túnica de «media»). Si ninguno cumple la aceptación: PENDIENTE.
func _escudo(manos: Dictionary) -> Image:
	var hoja := Image.load_from_file(EQ + "/escudo_caminata.png"); hoja.convert(Image.FORMAT_RGBA8)
	var esp := Image.load_from_file(EQ + "/espada_caminata.png"); esp.convert(Image.FORMAT_RGBA8)
	var out := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	var torso: Dictionary = informe.seguimiento["media/torso"]
	var anclas := {}
	for fila in 4:
		# mano del escudo en caminata: componente de piel no cara más lejano de la espada de caminata
		var mano_cam := _mano_libre_caminata(fila, esp)
		var forma := _mascara_img(hoja, fila, 0, W)
		for col in 4:
			var mm: Dictionary = manos["%d,%d" % [fila, col]]
			# candidatos en orden: mano libre (si se ve en caminata y en ataque) y, si no vale, el torso
			var cands: Array = []
			if mano_cam != Vector2(-1, -1) and int(mm.escudo) >= 0:
				var libre: Vector2 = (mm.manos as Array)[int(mm.escudo)].c
				cands.append(["mano libre", Vector2i((libre - mano_cam).round())])
			if bool(torso["%d,%d" % [fila, col]].aceptada):
				var t: Array = torso["%d,%d" % [fila, col]].traslacion
				cands.append(["torso", OFS + Vector2i(int(t[0]), int(t[1]))])
			var elegido: Array = []
			var motivos: Array = []
			for cand: Array in cands:
				# misma aceptación que las piezas rígidas: <= FUERA_MAX fuera de la silueta (1 px) y nada a más de 3 px
				var d: Vector2i = cand[1]
				var fuera := 0
				var lejos := 0
				for p: Vector2i in forma:
					var q: Vector2i = p + d
					if not _cerca_opaco(col * C + q.x, fila * C + q.y, 1, fila, col): fuera += 1
					if not _cerca_opaco(col * C + q.x, fila * C + q.y, 3, fila, col): lejos += 1
				var frac := float(fuera) / maxf(1.0, float(forma.size()))
				if frac <= FUERA_MAX and lejos == 0: elegido = [cand[0], d, frac]; break
				motivos.append("anclado a %s: %.0f %% fuera de la silueta, %d px a más de 3 px" % [cand[0], frac * 100.0, lejos])
			if elegido.is_empty():
				informe.pendientes.append({"hoja": "compartido/escudo", "fila": fila, "cuadro": col, "direccion": DIRS[fila], "pose": POSES[col],
					"motivo": "; ".join(motivos) if not motivos.is_empty() else "sin mano libre medible en ataque.png ni torso aceptado para anclar"})
				continue
			var dd: Vector2i = elegido[1]
			anclas["%d,%d" % [fila, col]] = {"ancla": elegido[0], "traslacion": [dd.x - OFS.x, dd.y - OFS.y], "fuera": snappedf(float(elegido[2]), 0.001),
				"mano_caminata": [mano_cam.x, mano_cam.y] if mano_cam != Vector2(-1, -1) else null}
			for p: Vector2i in forma:
				var q: Vector2i = p + dd
				if q.x < 1 or q.y < 1 or q.x >= C - 1 or q.y >= C - 1: continue
				out.set_pixel(col * C + q.x, fila * C + q.y, hoja.get_pixel(p.x, fila * W + p.y))
	informe["escudo"] = anclas
	return out

## Centroide (celda 32) de la mano libre en caminata, cuadro 0 (la más lejana de la espada de caminata);
## (-1, -1) si la caminata solo muestra una mano.
func _mano_libre_caminata(fila: int, esp: Image) -> Vector2:
	var tope := _tope(caminata.pelo, fila, 0, W)
	var comps := _manos_de(_mascara_img(caminata.piel, fila, 0, W), tope, W)
	if comps.size() < 2: return Vector2(-1, -1)
	var ce := _centroide(_mascara_img(esp, fila, 0, W))
	var mejor := Vector2(-1, -1)
	for comp: Dictionary in comps:
		var c := _centroide(comp)
		if mejor == Vector2(-1, -1) or c.distance_to(ce) > mejor.distance_to(ce): mejor = c
	return mejor

## Espada: los píxeles separados de ataque.png (acero, contorno y estela) en índice: acero claro -> principal,
## acero medio y contorno -> sombra, empuñadura -> acento (paleta pal_espada_hierro: acero, gris, cuero).
## Se descartan: el anillo exterior de 1 px de la celda (contrato c) y toda isla que no quede a <= 1 px de hueco del
## cuerpo ni de otra parte de la espada ya unida a él (estelas sueltas: efecto, sin capa propia; ver PENDIENTE).
func _espada() -> Image:
	var out := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	for fila in 4:
		for col in 4:
			var o := Vector2i(col * C, fila * C)
			var dentro := func(p: Vector2i) -> bool:
				return p.x > 0 and p.y > 0 and p.x < C - 1 and p.y < C - 1 and espada[_i(o.x + p.x, o.y + p.y)] != 0
			var pend: Array = _componentes(dentro)
			var unidos := {}
			var cambio := true
			while cambio:
				cambio = false
				for comp: Dictionary in pend.duplicate():
					var toca := false
					for p: Vector2i in comp:
						for y in range(maxi(0, p.y - 2), mini(C, p.y + 3)):
							for x in range(maxi(0, p.x - 2), mini(C, p.x + 3)):
								if cuerpo.get_pixel(o.x + x, o.y + y).a8 != 0 or unidos.has(Vector2i(x, y)): toca = true
						if toca: break
					if toca:
						unidos.merge(comp)
						pend.erase(comp)
						cambio = true
			var sueltos := 0
			for comp: Dictionary in pend: sueltos += comp.size()
			if sueltos > 0: informe.estela["%d,%d" % [fila, col]] = sueltos
			for p: Vector2i in unidos:
				var e := espada[_i(o.x + p.x, o.y + p.y)]
				var c := atq.get_pixel(o.x + p.x, o.y + p.y)
				out.set_pixel(o.x + p.x, o.y + p.y, AZUL if e == 2 else (ROJO if c.v > 0.75 else VERDE))
	return out

# ---------------------------------------------------------------- salida
func _guardar(hojas: Dictionary, rev: String) -> void:
	cuerpo.save_png(SAL + "/base/ataque_sin_espada.png")
	var capas := {}
	for k in CLASES:
		var im := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
		var id := CLASES.find(k) + 1
		for y in 4 * C:
			for x in 4 * C:
				if clase[_i(x, y)] == id: im.set_pixel(x, y, cuerpo.get_pixel(x, y))
		im.save_png(SAL + "/base/capas/%s.png" % k)
		capas[k] = "base/capas/%s.png" % k
	var man := {
		"_nota": "Derivado por herramientas/arte/derivar_ataque.gd desde ataque.png (biblioteca_01, solo lectura) y las hojas de caminata de arte/equipo. PROVISIONAL. Ver PENDIENTE_DE_ARTE.md.",
		"fuente": {"ataque": ATAQUE, "sha256": FileAccess.get_sha256(ATAQUE), "derivador_sha256": FileAccess.get_sha256("herramientas/arte/derivar_ataque.gd")},
		"celda": C, "pivote": [24, 48], "filas": DIRS, "cuadros": 4, "poses": POSES,
		"fases": {"aviso": [0, 1], "activo": [2], "rec": [3]},
		"indices": {"principal": "#ff0000", "sombra": "#00ff00", "acento": "#0000ff", "detalle": "#808080"},
		"base": {"hoja": "base/ataque_sin_espada.png", "capas": capas},
		"hojas": {}, "seguimiento": informe.seguimiento, "manos": informe.manos, "escudo": informe.get("escudo", {}),
		"espada_separada": {"empunadura_px": informe.empunadura, "huecos_rellenados_px": informe.huecos_rellenados, "islas_px": informe.restos,
			"estela_suelta_descartada_px": informe.estela},
		## celdas donde la espada de ataque.png tapa el cuerpo (px rellenados al quitarla): el render la pone delante del torso
		"espada_delante": informe.tapa.keys(),
		"umbrales": {"iou_min": IOU_MIN, "fuera_max": FUERA_MAX, "busqueda": [BUSCA.x, BUSCA.y]},
		"validacion": {},
	}
	var base_val := Image.load_from_file(ATAQUE)
	for clave: String in hojas:
		var arq: String = clave.split("/")[0]
		var ran: String = clave.split("/")[1]
		var archivo := ("%s_ataque.png" % ran) if arq == "compartido" else ("equipo_%s_%s_ataque.png" % [arq, ran])
		(hojas[clave] as Image).save_png(SAL + "/" + archivo)
		var pend: Array = []
		for p: Dictionary in informe.pendientes: if p.hoja == clave: pend.append([p.fila, p.cuadro])
		if not man.hojas.has(arq): man.hojas[arq] = {}
		man.hojas[arq][ran] = {"archivo": archivo, "sha256": FileAccess.get_sha256(SAL + "/" + archivo), "pendientes": pend}
		var r: Dictionary = Validador.validar(hojas[clave], C, "indice", base_val)
		man.validacion[archivo] = {"errores": r.errores, "avisos": r.avisos}
		print("%s: %d errores, %d avisos, %d celdas pendientes %s" % [archivo, r.errores.size(), r.avisos.size(), pend.size(), str(r.errores)])
	var f := FileAccess.open(SAL + "/manifiesto.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(man, "  ", false))
	f.close()
	_pendientes_md()
	if rev != "": _revision(hojas, rev)

func _pendientes_md() -> void:
	var s := "# PENDIENTE DE ARTE: ataque con equipo (celda 48)\n\n"
	s += "Generado por `herramientas/arte/derivar_ataque.gd` (no editar a mano; volver a ejecutar). Cada línea es una celda que NO se pudo derivar con calidad aceptable de forma automática y se dejó vacía: en esa dirección y pose el juego NO dibuja esa pieza y deja visible la capa base de `ataque.png` que la pieza ocultaría (el cuadro estático de caminata quedaba suelto o desplazado sobre la pose; visto en las tiras).\n\n"
	s += "Umbrales: IoU >= %.2f de la capa de referencia, <= %.0f %% de la pieza fuera de la silueta de `ataque.png` (dilatada 1 px).\n\n" % [IOU_MIN, FUERA_MAX * 100.0]
	if informe.pendientes.is_empty(): s += "Ninguna celda pendiente.\n"
	else:
		s += "| Hoja | Dirección | Pose (columna) | Motivo |\n|---|---|---|---|\n"
		for p: Dictionary in informe.pendientes:
			s += "| %s | %s | %s (%d) | %s |\n" % [p.hoja, p.direccion, p.pose, p.cuadro, p.motivo]
	if not informe.estela.is_empty():
		s += "\n## Estela de la espada (efecto) descartada\n\nIslas de estela separadas del cuerpo y de la espada en `ataque.png`; no son equipo y quedarían flotando. Falta una capa de efecto propia (celda fila,columna: píxeles): %s\n" % str(informe.estela)
	var f := FileAccess.open(SAL + "/PENDIENTE_DE_ARTE.md", FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("pendientes: %d" % informe.pendientes.size())

## Revisión visual (solo con --revision): por arquetipo y dirección, original | base sin espada + piezas con un
## color fijo por pieza (casco oro, torso rojo, guantes magenta, pantalones violeta, botas naranja, escudo marrón,
## espada cian; la sombra índice más oscura) en el orden del contrato para esa orientación.
const COLOR_REV := {"casco": Color("f1c40f"), "torso": Color("e74c3c"), "guantes": Color("ff00ff"), "pantalones": Color("8e44ad"),
	"botas": Color("e67e22"), "escudo": Color("6e2c00"), "espada": Color("00e5ff")}
const ORDEN_REV := [["pantalones", "botas", "torso", "guantes", "escudo", "espada", "casco"],
	["pantalones", "botas", "escudo", "torso", "guantes", "espada", "casco"],
	["pantalones", "botas", "torso", "guantes", "escudo", "espada", "casco"],
	["pantalones", "botas", "espada", "torso", "guantes", "escudo", "casco"]]
func _revision(hojas: Dictionary, dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for arq in ARQ:
		for fila in 4:
			var lienzo := Image.create(4 * C * 2 + 4, C, false, Image.FORMAT_RGBA8)
			lienzo.fill(Color(0.78, 0.78, 0.78))
			var r := Rect2i(0, fila * C, 4 * C, C)
			lienzo.blend_rect(atq, r, Vector2i.ZERO)
			var comp := cuerpo.get_region(r)
			for pieza: String in ORDEN_REV[fila]:
				var k: String = ("compartido/" + pieza) if pieza in ["escudo", "espada"] else (arq + "/" + pieza)
				var im: Image = (hojas[k] as Image).get_region(r)
				var base: Color = COLOR_REV[pieza]
				for y in C:
					for x in 4 * C:
						var px := im.get_pixel(x, y)
						if px.a8 == 0: continue
						im.set_pixel(x, y, base.darkened(0.45) if px.to_rgba32() == VERDE.to_rgba32() else (base.lightened(0.4) if px.to_rgba32() == AZUL.to_rgba32() else base))
				comp.blend_rect(im, Rect2i(0, 0, 4 * C, C), Vector2i.ZERO)
			lienzo.blend_rect(comp, Rect2i(0, 0, 4 * C, C), Vector2i(4 * C + 4, 0))
			var rec := Image.create(8 * 40, 34, false, Image.FORMAT_RGBA8)   # solo la zona del cuerpo de cada celda
			for k in 8:
				var x0: int = (k % 4) * C + (0 if k < 4 else 4 * C + 4) + 4
				rec.blit_rect(lienzo, Rect2i(x0, 14, 40, 34), Vector2i(k * 40, 0))
			lienzo = rec
			lienzo.resize(lienzo.get_width() * 5, lienzo.get_height() * 5, Image.INTERPOLATE_NEAREST)
			lienzo.save_png(dir + "/revision_%s_%s.png" % [arq, DIRS[fila]])
