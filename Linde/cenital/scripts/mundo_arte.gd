extends RefCounted
## Arte del mundo (E04 terreno/naturaleza + E05 casa/objetos). Sustituye al dibujo procedural: no hay vuelta atrás.
## Datos y hojas en res://arte/mundo (manifiesto.json con sha256). Si falta un recurso se registra en `faltantes`,
## se avisa con push_error una sola vez y se dibuja un marcador magenta visible; nunca el arte anterior.
const RAIZ := "res://arte/mundo/"
const Mundo = preload("res://scripts/mundo.gd")
const CELDA := 16
const ARBOLES := ["broadleaf", "pine", "fruit"]
const VECINOS := [[Vector2i.UP, 1], [Vector2i.RIGHT, 2], [Vector2i.DOWN, 4], [Vector2i.LEFT, 8], [Vector2i(1, -1), 16], [Vector2i(1, 1), 32], [Vector2i(-1, 1), 64], [Vector2i(-1, -1), 128]]
const CARDINALES := [[Vector2i.UP, 1], [Vector2i.RIGHT, 2], [Vector2i.DOWN, 4], [Vector2i.LEFT, 8]]
const MARCADOR := Color(1, 0, 1, 0.85)
const SUELOS_BIOMA := {"bosque": "bosque", "sierra": "sierra", "secano": "secano", "pradera": "pradera"}

# Las variantes forman un mosaico de 32 px; coordenadas globales, también negativas.
func _suelo_bioma(ci: CanvasItem, c: Vector2i, bioma: String, dst: Rect2, alfa: float = 1.0) -> void:
	var t := tex("biomas/" + bioma + ".png")
	if t == null:
		_tex_rect(ci, "biomas/" + bioma + ".png", dst)
		return
	var origen := Vector2(posmod(c.x, 2), posmod(c.y, 2)) * CELDA
	ci.draw_texture_rect_region(t, dst, Rect2(origen, Vector2(CELDA, CELDA)), Color(1, 1, 1, alfa))
	# Velo mineral uniforme: conserva el mosaico y sus transiciones con menos contraste.
	if bioma == "sierra": ci.draw_rect(dst, Color(0.36, 0.39, 0.37, alfa * 0.48))

var mapeo: Dictionary = {}
var objetos: Dictionary = {}
var casa: Dictionary = {}
var texturas: Dictionary = {}
var faltantes: Dictionary = {}
var cargado := false

func cargar() -> bool:
	if cargado: return true
	var cat = _json("E04_catalogo.json")
	var o4 = _json("E04_objetos.json")
	var o5 = _json("E05_objetos.json")
	var cs = _json("E05_casa_modular.json")
	if cat == null or o4 == null or o5 == null or cs == null: return false
	mapeo = cat.mapping
	objetos = o4.duplicate()
	objetos.merge(o5)
	casa = cs
	cargado = true
	return true

func _json(f: String):
	var txt := FileAccess.get_file_as_string(RAIZ + f)
	var d = JSON.parse_string(txt) if txt != "" else null
	if d == null: _falta(RAIZ + f)
	return d

func _falta(ruta: String) -> void:
	if faltantes.has(ruta): return
	faltantes[ruta] = true
	push_error("Arte faltante: " + ruta)

func tex(f: String) -> Texture2D:
	if texturas.has(f): return texturas[f]
	var t: Texture2D = null
	if ResourceLoader.exists(RAIZ + f): t = load(RAIZ + f) as Texture2D
	if t == null: _falta(RAIZ + f)
	texturas[f] = t
	return t

func _tex_rect(ci: CanvasItem, f: String, r: Rect2, tinte: Color = Color.WHITE) -> void:
	var t := tex(f)
	if t == null: ci.draw_rect(r, MARCADOR)
	else: ci.draw_texture_rect(t, r, false, tinte)

# ---------- terreno (47 conexiones por material) ----------
static func _normalizar(m: int) -> int:
	for q in [[1, 2, 16], [2, 4, 32], [4, 8, 64], [8, 1, 128]]:
		if not ((m & int(q[0])) != 0 and (m & int(q[1])) != 0): m = m & ~int(q[2])
	return m

func mascara(m, c: Vector2i, t: int) -> int:
	var v := 0
	for n in VECINOS:
		if m.tipo(c + n[0]) == t: v |= int(n[1])
	return _normalizar(v)

func suelo(ci: CanvasItem, m, c: Vector2i, tiempo: float) -> void:
	var t: int = m.tipo(c)
	var clase := "path" if t == Mundo.T.CAMINO else "water" if t == Mundo.T.AGUA else "ruins" if t == Mundo.T.RUINA else "wall" if t == Mundo.T.PARED or t == Mundo.T.MURO_RUINA else ""
	var dst := Rect2(Vector2(c) * CELDA, Vector2(CELDA, CELDA))
	if clase == "":
		var bioma: String=m.bioma(c)
		_tex_rect(ci, "E04_grass_periodica.png", dst, Color(0.96, 0.92, 0.98))
		if SUELOS_BIOMA.has(bioma):
			var mezcla := clampf(float(Mundo.Terreno.distancia_valle(c)) / 12.0, 0.0, 1.0)
			_suelo_bioma(ci, c, bioma, dst, mezcla)
			# Una franja de transición de una celda suaviza los cambios entre materiales.
			for vecino in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var otro: String = m.bioma(c + vecino)
				if otro != bioma and SUELOS_BIOMA.has(otro) and m.tipo(c + vecino) == Mundo.T.PASTO:
					_suelo_bioma(ci, c, otro, dst, mezcla * 0.12)
		return
	var p: Array = mapeo[clase][str(mascara(m, c, t))]
	var cuadro := int(tiempo / 0.15) % 4 if clase == "water" else 0
	var f := "E04_water_47_anim.png" if clase == "water" else "E04_" + clase + "_47.png"
	var tx := tex(f)
	if tx == null: ci.draw_rect(dst, MARCADOR)
	else:
		var tinte := Color(0.62, 0.72, 0.60) if clase == "water" and not Mundo.es_valle(c) else Color.WHITE
		ci.draw_texture_rect_region(tx, dst, Rect2(int(p[0]) * CELDA + cuadro * 128, int(p[1]) * CELDA, CELDA, CELDA), tinte)
	# Se conserva la orilla de 47 conexiones; el agua propia ocupa solo el interior.
	if clase == "water" and not Mundo.es_valle(c) and mascara(m, c, t) == 255:
		var agua := tex("biomas/ribera.png")
		if agua != null:
			var origen := Vector2(posmod(c.x + cuadro, 2), posmod(c.y, 2)) * CELDA
			ci.draw_texture_rect_region(agua, dst, Rect2(origen, Vector2(CELDA, CELDA)), Color(1, 1, 1, 0.55))

# Un solo arte de mena (cobre): el hierro se distingue con tinte frío y la arcilla es roca rojiza. Sustituir cuando haya arte propio.
const TINTE_MENA := {"veta": Color(0.72, 0.78, 1.0), "veta_estano": Color(0.8, 1.0, 1.05), "arcilla": Color(1.25, 0.7, 0.55)}
const RECURSOS_PROPIOS := {"veta":"hierro","veta_cobre":"cobre","veta_estano":"estano","arcilla":"arcilla"}
# ---------- naturaleza (árbol, roca, veta, arbusto) ----------
func natural(ci: CanvasItem, tipo: String, c: Vector2i, agotado: bool, jugador: Vector2) -> void:
	if RECURSOS_PROPIOS.has(tipo):
		var clave_recurso:String="mineral_"+RECURSOS_PROPIOS[tipo]+("_agotado" if agotado else "")
		var d:Dictionary=objetos[clave_recurso]
		var pies_recurso:=Vector2(c)*CELDA+Vector2(8,16)
		_tex_rect(ci,d.archivo,Rect2(pies_recurso-Vector2(d.pivote[0],d.pivote[1]),Vector2(d.canvas[0],d.canvas[1])))
		return
	var clave := ""
	if tipo == "arbol":
		var n: String = ARBOLES[posmod(c.x * 7 + c.y * 3, 3)]
		clave = "E04_stump_" + n if agotado else "E04_tree_" + n + "_64"
	elif tipo == "roca": clave = "E04_rock_depleted" if agotado else "E04_rock"
	elif tipo in ["veta", "veta_cobre", "veta_estano"]: clave = "E04_ore_depleted" if agotado else "E04_ore_copper"
	elif tipo == "arcilla": clave = "E04_rock_depleted" if agotado else "E04_rock"
	elif tipo == "arbusto": clave = "E04_bush_without_berries" if agotado else "E04_bush_berries"
	else: return
	var pies := Vector2(c) * CELDA + Vector2(8, 16)
	if clave=="E04_tree_fruit_64":
		var d: Dictionary=objetos[clave]
		var origen: Vector2=pies-Vector2(d.pivote[0],d.pivote[1])
		var tx:=tex(d.archivo)
		if tx==null: return
		var alfa:=0.4 if (c.y+1)*CELDA>=jugador.y and Rect2(origen,Vector2(64,45)).has_point(jugador-Vector2(0,14)) else 1.0
		ci.draw_texture_rect_region(tx,Rect2(origen+Vector2(0,45),Vector2(64,19)),Rect2(0,45,64,19))
		ci.draw_texture_rect_region(tx,Rect2(origen,Vector2(64,45)),Rect2(0,0,64,45),Color(1,1,1,alfa))
		return
	var partes := [clave + "_tronco", clave + "_copa"] if tipo == "arbol" and not agotado else [clave]
	for k in partes:
		var alfa := 1.0
		var d: Dictionary = objetos.get(k, {})
		if d.is_empty(): _falta(RAIZ + k); continue
		var r := Rect2((pies - Vector2(d.pivote[0], d.pivote[1])).round(), Vector2(d.canvas[0], d.canvas[1]))
		if str(k).ends_with("_copa") and (c.y + 1) * CELDA >= jugador.y and r.has_point(jugador - Vector2(0, 14)): alfa = 0.4
		_tex_rect(ci, d.archivo, r, Color(1, 1, 1, alfa) * TINTE_MENA.get(tipo, Color.WHITE))

# ---------- objetos fijos y construcciones (E05) ----------
func prop(ci: CanvasItem, nombre: String, pies: Vector2, tinte: Color = Color.WHITE) -> void:
	var d: Dictionary = objetos.get(nombre, {})
	if d.is_empty(): _falta(RAIZ + nombre); return
	_tex_rect(ci, d.archivo, Rect2(pies - Vector2(d.pivote[0], d.pivote[1]), Vector2(d.canvas[0], d.canvas[1])), tinte)

func valla(ci: CanvasItem, m, c: Vector2i) -> void:
	var v := 0
	for d in CARDINALES:
		var id: String = m.por_celda.get(c + d[0], "")
		if id != "" and m.objetos[id].t == "valla": v |= int(d[1])
	_tex_rect(ci, "E05_valla_mask_%02d.png" % v, Rect2(Vector2(c) * CELDA + Vector2(8, 16) - Vector2(24, 40), Vector2(48, 64)))

func cofre(ci: CanvasItem, c: Vector2i, abierto: bool, tinte: Color = Color.WHITE) -> void:
	var f := "E05_cofre_abierto_alineado.png" if abierto else "E05_cofre_cerrado_alineado.png"
	_tex_rect(ci, f, Rect2(Vector2(c) * CELDA + Vector2(8, 16) - Vector2(24, 44), Vector2(48, 48)), tinte)

func constr_suelo(ci: CanvasItem, c: Vector2i, tinte: Color = Color.WHITE) -> void:
	_tex_rect(ci, "E05_floor_wood.png", Rect2(Vector2(c) * CELDA, Vector2(CELDA, CELDA)), tinte)

func techo(ci: CanvasItem, c: Vector2i, alfa: float) -> void:
	_tex_rect(ci, "poblados/techo.png", Rect2(Vector2(c) * CELDA, Vector2(CELDA, CELDA)), Color(1,1,1,alfa))

func tejado_rect(ci: CanvasItem, r: Rect2, alfa: float) -> void:
	var t:=tex("poblados/techo.png")
	if t==null: _tex_rect(ci,"poblados/techo.png",r);return
	ci.draw_texture_rect(t,r,true,Color(1,1,1,alfa))

func constr(ci: CanvasItem, t: String, c: Vector2i, abierto: bool = false, tinte: Color = Color.WHITE, listo: bool = true) -> void:
	var pies := Vector2(c) * CELDA + Vector2(8, 16)
	match t:
		"muro": prop(ci, "palisade", pies, tinte)
		"muro_ladrillo": _tex_rect(ci,"poblados/muro_ladrillo.png",Rect2(pies-Vector2(12,16),Vector2(24,16)),tinte)
		"mesa": prop(ci, "workbench", pies, tinte)
		"horno": prop(ci, "furnace", pies, tinte)
		"cama": prop(ci, "bed", pies, tinte)
		"cama_huesped": prop(ci, "bed", pies, tinte * Color(0.6, 0.85, 1.3))
		"cofre": cofre(ci, c, abierto, tinte)
		"suelo": constr_suelo(ci, c, tinte)
		"puerta": _tex_rect(ci,"poblados/puerta_abierta.png" if abierto else "poblados/puerta_cerrada.png",Rect2(pies-Vector2(10,28) if abierto else pies-Vector2(8,24),Vector2(20,28) if abierto else Vector2(16,24)),tinte)
		"puesto":
			prop(ci,"workbench",pies,tinte)
			_tex_rect(ci,"poblados/techo.png",Rect2(pies-Vector2(16,32),Vector2(32,16)),tinte)
		"techo": techo(ci, c, 0.7 * tinte.a)
		"campo": _tex_rect(ci,"poblados/campo_maduro.png" if listo else "poblados/campo_creciendo.png",Rect2(Vector2(c)*CELDA,Vector2(CELDA,CELDA)),tinte)

# ---------- casa modular (canvas 160×160; origen de la casa lógica en [16,32]) ----------
func _base_casa() -> Vector2:
	return Vector2(Mundo.CASA.position) * CELDA - Vector2(16, 32)

func _capa_casa(ci: CanvasItem, parte: String, alfa: float = 1.0) -> void:
	_tex_rect(ci, str(casa.partes.get(parte, "")), Rect2(_base_casa(), Vector2(160, 160)), Color(1, 1, 1, alfa))

func casa_interior(ci: CanvasItem) -> void:
	_capa_casa(ci, "casa_interior_160")
	_capa_casa(ci, "casa_paredes_interior_160")

func casa_fachada(ci: CanvasItem, alfa: float, puerta_abierta: bool) -> void:
	_capa_casa(ci, "casa_fachada_160", alfa)
	_capa_casa(ci, "casa_puerta_abierta_160" if puerta_abierta else "casa_puerta_cerrada_160", alfa)

func casa_tejado(ci: CanvasItem, alfa: float) -> void:
	if alfa > 0.0: _capa_casa(ci, "casa_tejado_160", alfa)
