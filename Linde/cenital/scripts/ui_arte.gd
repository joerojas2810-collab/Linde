extends RefCounted
## Recursos de interfaz de E06_v001: paneles de 9 parches, botones, barras, ranuras, iconos y tipografías Nunito Sans (interfaz) y Lora (diálogos), ambas OFL.
## Datos en res://arte/interfaz. Un recurso inexistente se registra en `faltantes` (push_error una vez) y se dibuja un marcador
## magenta visible; nunca un dibujo de reserva.
const RAIZ := "res://arte/interfaz/"
const TINTA := Color("#30271f")
const PAPEL := Color("#f7e2aa")
const FOCO := Color("#f1c75b")
const MARCADOR := Color(1, 0, 1, 0.85)
## Márgenes de los 9 parches (propuesta E06 PROPUESTAS.md): panel 8/16/8/16, botón 20/10/20/8.
const M_PANEL := [8, 16, 8, 16]
const M_BOTON := [20, 10, 20, 8]
const M_TOOLTIP := [8, 8, 8, 8]
## Iconos de ranura (E06: icono genérico por ranura; familia/variante/nivel se escriben como texto).
const ICONO_RANURA := {"casco": "reutilizados/casco.png", "torso": "reutilizados/coraza.png", "guantes": "nuevos/guantes.png",
	"botas": "nuevos/botas.png", "pantalones": "nuevos/pantalones.png", "escudo": "reutilizados/escudo.png"}

var fuente: FontVariation
var fuente_dialogo: FontVariation
var texturas: Dictionary = {}
var estilos: Dictionary = {}
var faltantes: Dictionary = {}
var iconos_items: Dictionary = {}

func _init() -> void:
	fuente = _cargar_fuente("NunitoSans.ttf")
	fuente_dialogo = _cargar_fuente("Lora.ttf")
	var js = JSON.parse_string(FileAccess.get_file_as_string(RAIZ + "ICONOS_POR_ID.json"))
	if js is Dictionary: iconos_items = js.get("items", {})
	else: _falta(RAIZ + "ICONOS_POR_ID.json")

## Fija el peso de las fuentes variables: Nunito tiene un peso inicial muy fino.
func _cargar_fuente(nombre: String) -> FontVariation:
	var ruta := RAIZ + "tipografia/" + nombre
	var base: FontFile = load(ruta) as FontFile if ResourceLoader.exists(ruta) else null
	if base == null:
		_falta(ruta)
		return null
	base.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	base.multichannel_signed_distance_field = true
	var variante := FontVariation.new()
	variante.base_font = base
	variante.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 400.0}
	return variante

func _falta(ruta: String) -> void:
	if faltantes.has(ruta): return
	faltantes[ruta] = true
	push_error("Arte faltante: " + ruta)

func tex(rel: String) -> Texture2D:
	if texturas.has(rel): return texturas[rel]
	var t: Texture2D = null
	if ResourceLoader.exists(RAIZ + rel): t = load(RAIZ + rel) as Texture2D
	if t == null: _falta(RAIZ + rel)
	texturas[rel] = t
	return t

func _estilo(rel: String, m: Array) -> StyleBoxTexture:
	var k := rel + str(m)
	if estilos.has(k): return estilos[k]
	var sb := StyleBoxTexture.new()
	sb.texture = tex(rel)
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	estilos[k] = sb
	return sb

## Ruta del icono de un ítem del inventario: ids del juego, o ranura de una pieza de set («eq:...») vía `ranura`.
func ruta_icono(id: String, ranura: String = "") -> String:
	if ranura != "" and ICONO_RANURA.has(ranura): return ICONO_RANURA[ranura]
	var nombre: String = str(iconos_items.get(id, "")).trim_prefix("E06_")
	if nombre == "": return ""
	for sub in ["reutilizados/", "nuevos/"]:
		if ResourceLoader.exists(RAIZ + sub + nombre + ".png"): return sub + nombre + ".png"
	return ""

# ---------- dibujo (ci = CanvasItem en espacio de pantalla) ----------
func panel(ci: CanvasItem, r: Rect2) -> void:
	if tex("reutilizados/panel.png") == null: ci.draw_rect(r, MARCADOR); return
	ci.draw_style_box(_estilo("reutilizados/panel.png", M_PANEL), r)

func tooltip(ci: CanvasItem, r: Rect2) -> void:
	if tex("reutilizados/tooltip_panel.png") == null: ci.draw_rect(r, MARCADOR); return
	ci.draw_style_box(_estilo("reutilizados/tooltip_panel.png", M_TOOLTIP), r)

func boton(ci: CanvasItem, r: Rect2, foco: bool) -> void:
	var rel := "reutilizados/button_hover.png" if foco else "reutilizados/button_normal.png"
	if tex(rel) == null: ci.draw_rect(r, MARCADOR); return
	ci.draw_style_box(_estilo(rel, M_BOTON), r)
	if foco: ci.draw_rect(r, FOCO, false, 2)

func icono(ci: CanvasItem, rel: String, r: Rect2) -> void:
	if rel == "": return
	var t := tex(rel)
	if t == null: ci.draw_rect(r, MARCADOR)
	else: ci.draw_texture_rect(t, r, false)

func ranura(ci: CanvasItem, r: Rect2, seleccionada: bool) -> void:
	var t := tex("reutilizados/slot_selected.png" if seleccionada else "reutilizados/slot_normal.png")
	if t == null: ci.draw_rect(r, MARCADOR)
	else: ci.draw_texture_rect(t, r, false)

## Barra de vida o de experiencia: marco fijo 64×24 a escala 3 (192×72); interior 44×5 con desfase (10,9) recortado por la fracción.
func barra(ci: CanvasItem, pos: Vector2, frac: float, xp: bool = false, esc: int = 3) -> void:
	var marco := tex("reutilizados/healthbar_frame.png")
	var relleno := tex("nuevos/xp_fill.svg" if xp else "reutilizados/healthbar_fill.png")
	if marco == null or relleno == null: ci.draw_rect(Rect2(pos, Vector2(64, 24) * esc), MARCADOR); return
	ci.draw_texture_rect(marco, Rect2(pos, Vector2(64, 24) * esc), false)
	var ancho := floorf(44.0 * esc * clampf(frac, 0.0, 1.0))
	if ancho > 0.0: ci.draw_texture_rect_region(relleno, Rect2(pos + Vector2(10, 9) * esc, Vector2(ancho, 5 * esc)), Rect2(0, 0, 44.0 * ancho / (44.0 * esc), 5))

func texto(ci: CanvasItem, txt: String, pos: Vector2, tam: int = 16, col: Color = TINTA) -> void:
	if fuente == null: ci.draw_rect(Rect2(pos - Vector2(0, tam), Vector2(maxf(8.0, txt.length() * tam * 0.5), tam)), MARCADOR); return
	ci.draw_string(fuente, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

func texto_centrado(ci: CanvasItem, txt: String, centro_x: float, y: float, tam: int = 16, col: Color = TINTA) -> void:
	if fuente == null: return
	var ancho := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	ci.draw_string(fuente, Vector2(centro_x - ancho / 2.0, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

func ancho_texto(txt: String, tam: int) -> float:
	return fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x if fuente != null else 0.0
