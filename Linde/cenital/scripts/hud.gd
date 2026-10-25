extends Control
# Dibuja la interfaz en espacio de pantalla (1280x720) con los recursos de E06 (res://arte/interfaz).
# Solo lee estado de la escena; no concede nada. La luz de día y noche se aplica al mundo (escena), no aquí.
const Aspecto = preload("res://scripts/aspecto.gd")
const C = preload("res://scripts/catalogos.gd")
const Eq = preload("res://scripts/equipo.gd")
const UiArte = preload("res://scripts/ui_arte.gd")
var esc
var ui = UiArte.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_d: float) -> void:
	queue_redraw()

# Texto con la esquina superior izquierda en `pos` (la línea base se calcula desde el tamaño).
func _t(txt: String, pos: Vector2, tam: int = 16, col: Color = UiArte.TINTA) -> void:
	ui.texto(self, txt, pos + Vector2(0, tam * 0.85), tam, col)

func _draw() -> void:
	var vs := size
	if esc == null: return
	if esc.modo == "menu": return _menu(vs)
	if esc.modo == "creador": return _creador(vs)
	if esc.modo == "unirse" or esc.modo == "conectando": return _unirse(vs)
	var j = esc.j
	var h: float = j.hora_dia()
	var st: Dictionary = j.stats()
	# --- estado del jugador ---
	var p := Rect2(12, 12, 252, 112 if j.puntos_libres() <= 0 else 132)
	ui.panel(self, p)
	_t("%s · Nivel %d" % [j.jug().nombre, j.nivel()], Vector2(26, 20), 20)
	ui.barra(self, Vector2(18, 44), float(j.jug().hp) / st.hp, false, 2)
	_t("%d / %d" % [j.jug().hp, st.hp], Vector2(160, 58), 16)
	var sig := C.umbral_xp(j.nivel() + 1) if j.nivel() < C.NIVEL_MAX else C.umbral_xp(j.nivel())
	var ant := C.umbral_xp(j.nivel())
	ui.barra(self, Vector2(18, 78), float(j.jug().xp - ant) / maxf(1.0, sig - ant), true, 2)
	_t("XP %d / %d" % [j.jug().xp, sig], Vector2(160, 92), 14)
	if j.puntos_libres() > 0: _t("¡%d punto(s) de habilidad! (K)" % j.puntos_libres(), Vector2(26, 116), 14)
	# --- día, red y misiones ---
	_tracker(vs, j, h)
	# --- avisos, ayuda y pista ---
	var msgs: Array = []
	for aviso in j.msgs.slice(-4):
		var linea := ""
		for palabra in str(aviso).split(" "):
			if ui.ancho_texto(linea + " " + palabra,16)>480.0:
				msgs.append(linea)
				linea=palabra
			else: linea+=(" " if linea!="" else "")+palabra
		if linea!="": msgs.append(linea)
	msgs=msgs.slice(-8)
	if not msgs.is_empty():
		var alto := 20.0 + msgs.size() * 22.0
		ui.panel(self, Rect2(16, 660 - alto - 8, 520, alto))
		for i in msgs.size(): _t(str(msgs[i]), Vector2(32, 660 - alto + 4 + i * 22.0), 16)
	ui.panel(self, Rect2(vs.x / 2 - 310, 668, 620, 40))
	_t("I  Mochila     E  Interactuar     Espacio  Acción     H  Ayuda", Vector2(vs.x / 2 - 288, 678), 17)
	if esc.ayuda_visible:
		ui.panel(self, Rect2(vs.x / 2 - 310, 518, 620, 142))
		_t("CONTROLES", Vector2(vs.x / 2 - 288, 536), 20)
		_t("WASD / Flechas  Moverse     Esc  Menú", Vector2(vs.x / 2 - 288, 570), 17)
		_t("C  Fabricar     F  Forja     G  Materiales y planos", Vector2(vs.x / 2 - 288, 598), 17)
		_t("K  Habilidades     J  Valle     B  Construir     F5  Guardar", Vector2(vs.x / 2 - 288, 626), 17)
	if esc.debug: _t("anim: %s #%d" % [esc._anim.estado, esc._anim.cuadro], Vector2(vs.x - 200, 700), 16, UiArte.FOCO)
	if esc.pista != "":
		var w: float = ui.ancho_texto(esc.pista, 16) + 32.0
		ui.tooltip(self, Rect2(vs.x / 2 - w / 2, 610, w, 40))
		_t(esc.pista, Vector2(vs.x / 2 - w / 2 + 16, 620), 16)
	if esc.build:
		var id: String = C.ORDEN_CONSTR[esc.pieza_i]
		ui.panel(self, Rect2(380, 16, 540, 72))
		_t("CONSTRUIR: %s · coste %s" % [C.CONSTR[id].n, J_txt(C.CONSTR[id].coste)], Vector2(396, 26), 16)
		_t("[Q/E] cambiar · [Espacio] colocar · [X] retirar · [B] salir", Vector2(396, 52), 16)
	if esc.panel != "": _panel(vs)

static func J_txt(m: Dictionary) -> String:
	var l: Array = []
	for k in m: l.append("%d %s" % [m[k], Eq.info(k).n])
	return ", ".join(l)

func _tracker(vs: Vector2, j, h: float) -> void:
	var lineas: Array = []   # [texto, tamaño]
	for id in C.MISIONES:
		var e: String = j.estado_mision(id)
		if e != "activa" and e != "cumplida": continue
		lineas.append([C.MISIONES[id].n + (" (¡cumplida!)" if e == "cumplida" else ""), 16])
		if C.MISIONES[id].da != "" and e == "cumplida": lineas.append(["→ vuelve con " + C.MISIONES[id].da.capitalize(), 16])
		for o in C.MISIONES[id].obj: lineas.append([("[x] " if j.objetivo_ok(o) else "[ ] ") + j.objetivo_txt(o), 16])
	if j.vivo != null:   # misiones de plantilla activas (story-004)
		for mi: Dictionary in j.vivo.instancias_visibles(j.LOCAL):
			if mi.estado != "activa": continue
			lineas.append([str(mi.nombre) + (" (¡cumplida!)" if mi.cumplida else ""), 16])
			lineas.append([str(mi.texto), 16])
	var extra := 1 if esc.red != null else 0
	var celda: Vector2i=esc.j.mundo.celda_de(esc.j.pies)
	var bioma: String=esc.j.mundo.bioma(celda)
	lineas.append(["%s · %d, %d" % [bioma.capitalize(),celda.x,celda.y],16])
	var alto := 52.0 + (extra + lineas.size()) * 22.0 + (8.0 if not lineas.is_empty() else 0.0)
	var r := Rect2(vs.x - 16 - 328, 16, 328, alto)
	ui.panel(self, r)
	_t("Día %d · %02d:%02d" % [j.dia(), int(h), int(fmod(h, 1.0) * 60)], r.position + Vector2(16, 10), 24)
	var y := 48.0
	if esc.red != null:
		_t(esc.red.estado_txt(), r.position + Vector2(16, y), 16)
		y += 22.0
	for l in lineas:
		_t(str(l[0]), r.position + Vector2(16, y), int(l[1]))
		y += 22.0

func _panel(vs: Vector2) -> void:
	if esc.panel == "dialogo":
		var alto_texto: float = ui.fuente_dialogo.get_multiline_string_size(esc.dialogo_txt,HORIZONTAL_ALIGNMENT_LEFT,912,24).y if ui.fuente_dialogo != null else 100.0
		var alto: float = clampf(alto_texto+144.0,256.0,600.0)
		var d := Rect2(112,648-alto,1056,alto)
		ui.panel(self, d)
		ui.icono(self, "reutilizados/categoria_comunidad.png", Rect2(d.position + Vector2(24, 24), Vector2(64, 64)))
		_t(esc.dialogo_nombre, d.position + Vector2(112, 24), 32)
		if ui.fuente_dialogo != null:
			draw_multiline_string(ui.fuente_dialogo, d.position + Vector2(112, 100), esc.dialogo_txt, HORIZONTAL_ALIGNMENT_LEFT, 912, 24, -1, UiArte.TINTA)
		_t("[E / Enter] cerrar", d.position + Vector2(112, d.size.y-44), 16)
		return
	if esc.panel == "inv":
		_inventario(vs)
		return
	var r := Rect2(vs.x / 2 - 448, 40, 896, 600)
	ui.panel(self, r)
	var fila := 34.0
	var caben := int((r.size.y - 120.0) / fila)                    # líneas visibles; la cabecera (0) siempre se ve
	var ini := maxi(1, esc.sel - caben + 2)                        # desplaza para que la selección quede a la vista
	if esc.lineas.size() > 0: _t(esc.lineas[0], r.position + Vector2(24, 16), 24)
	var y := r.position.y + 72.0
	for i in range(1, esc.lineas.size()):
		if i < ini: continue
		var activa: bool = esc.acc[i] != null
		var rr := Rect2(r.position.x + 20, y, r.size.x - 40, fila - 2)
		if i == esc.sel and activa:
			draw_rect(rr, Color(UiArte.FOCO, 0.35))
			draw_rect(rr, UiArte.FOCO, false, 2)
		var x := r.position.x + 32
		var ic: String = esc.iconos[i] if i < esc.iconos.size() else ""
		if ic != "":
			ui.icono(self, ic, Rect2(Vector2(x, y), Vector2(32, 32)))
			x += 40
		_t(esc.lineas[i], Vector2(x, y + 6), 16, UiArte.TINTA if activa else Color(UiArte.TINTA, 0.7))
		y += fila
		if y > r.end.y - 56: break
	_t("[↑↓] mover · [Enter] elegir · [Esc] cerrar", Vector2(r.position.x + 24, r.end.y - 36), 16)

# Conserva los índices y acciones de escena: solo cambia su presentación.
func _inventario(vs: Vector2) -> void:
	var r := Rect2(vs.x / 2 - 530, 32, 1060, 612)
	ui.panel(self, r)
	var st: Dictionary = esc.j.stats()
	_t("MOCHILA Y EQUIPO", r.position + Vector2(28, 22), 28)
	_t("Nivel %d   ·   Daño %d   ·   Defensa %d   ·   Vida %d   ·   Velocidad ×%.2f" % [esc.j.nivel(), st.dmg, st.def, st.hp, st.vel], r.position + Vector2(28, 64), 17)
	var izq := r.position + Vector2(28, 108)
	var der := r.position + Vector2(540, 108)
	draw_line(r.position + Vector2(516, 108), r.position + Vector2(516, 536), Color(UiArte.TINTA, 0.22), 2)
	_t("EQUIPADO", izq, 21)
	_t("MOCHILA   %d / %d espacios" % [preload("res://scripts/inventario.gd").slots(esc.j.jug().inv), st.slots], der, 21)
	var mochila := 3 + C.RANURAS.size()
	for i in range(3, mochila):
		_fila_inventario(i, izq + Vector2(0, 36 + (i - 3) * 48), 466)
	var primero := mochila + 1
	var inicio := maxi(primero, esc.sel - 6)
	var fin := mini(esc.lineas.size(), inicio + 7)
	for i in range(inicio, fin):
		_fila_inventario(i, der + Vector2(0, 36 + (i - inicio) * 48), 480)
	if inicio > primero or fin < esc.lineas.size():
		_t("↑↓ Más objetos · %d–%d" % [inicio - primero + 1, fin - primero], der + Vector2(0, 390), 15)
	_t("Bono: " + esc._txt_bono(esc.j.bono_set()), r.position + Vector2(28, 510), 16)
	var detalle := "Selecciona una pieza u objeto con ↑↓."
	if esc.sel >= 0 and esc.sel < esc.lineas.size() and esc.acc[esc.sel] != null:
		detalle = esc.lineas[esc.sel]
	_t(detalle, r.position + Vector2(28, 544), 15)
	_t("↑↓ Seleccionar    Enter Usar / Equipar / Quitar    Esc Cerrar", r.position + Vector2(28, 578), 16)

func _fila_inventario(i: int, pos: Vector2, ancho: float) -> void:
	var activa: bool = esc.acc[i] != null
	if i == esc.sel and activa:
		draw_rect(Rect2(pos, Vector2(ancho, 44)), Color(UiArte.FOCO, 0.30))
		draw_rect(Rect2(pos, Vector2(ancho, 44)), UiArte.FOCO, false, 2)
	var icono: String = esc.iconos[i] if i < esc.iconos.size() else ""
	if icono == "" and i == 3 + C.RANURAS.find("arma"): icono = "reutilizados/espada_hierro.png"
	ui.ranura(self, Rect2(pos + Vector2(2, 2), Vector2(40, 40)), i == esc.sel and activa)
	ui.icono(self, icono, Rect2(pos + Vector2(6, 6), Vector2(32, 32)))
	var texto: String = esc.lineas[i].replace("  (Enter: quitar)", "")
	if ui.fuente != null:
		draw_string(ui.fuente, pos + Vector2(52, 27), texto, HORIZONTAL_ALIGNMENT_LEFT, ancho - 60, 16, UiArte.TINTA)

func _menu(vs: Vector2) -> void:
	var p := Rect2(vs.x / 2 - 240, 40, 480, 620)
	ui.panel(self, p)
	ui.texto_centrado(self, "LINDE", vs.x / 2, p.position.y + 82, 48)
	ui.texto_centrado(self, "RPG de mundo vivo · prototipo cenital", vs.x / 2, p.position.y + 116, 16)
	for i in esc.menu_items.size():
		var b := Rect2(p.position.x + 48, p.position.y + 150 + i * 80, 384, 64)
		ui.boton(self, b, i == esc.menu_sel)
		ui.texto_centrado(self, esc.menu_items[i], vs.x / 2, b.position.y + 40, 24, UiArte.PAPEL)
	if esc.menu_msg != "": _t(esc.menu_msg, Vector2(p.position.x + 48, p.end.y - 40), 16, Color("8a2020"))

func _creador(vs: Vector2) -> void:
	var cr: Dictionary = esc.cr
	var p := Rect2(vs.x / 2 - 540, 20, 1080, 680)
	ui.panel(self, p)
	_t("CREA TU PERSONAJE", p.position + Vector2(24, 12), 32)
	var nombres: Array = ["Nombre"] + Aspecto.ETIQUETAS + ["Usar aspecto" if esc.destino_creador == "unirse" else "Comenzar"]
	var vals: Array = [cr.nombre + ("_" if cr.campo == 0 else "")]
	for i in Aspecto.CAMPOS.size(): vals.append(Aspecto.etiqueta(i, cr[Aspecto.CAMPOS[i]], cr.identidad))
	vals.append("Enter")
	for i in nombres.size():
		var b := Rect2(p.position.x + 24, p.position.y + 60 + i * 52, 496, 48)
		ui.boton(self, b, i == cr.campo)
		_t(nombres[i], b.position + Vector2(20, 14), 20, UiArte.PAPEL)
		_t(str(vals[i]), b.position + Vector2(240, 14), 20, UiArte.PAPEL)
	var look := Aspecto.de_creador(cr)
	for k in 4:
		var d: Vector2i = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT][k]
		draw_set_transform(p.position + Vector2(560 + (k % 2) * 220, 100 + (k / 2) * 220), 0, Vector2(5, 5))
		esc.arte_eq.dibujar(self, Vector2(16, 32), d, 0, [], look, "reposo")
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_t("10 peinados para hombre y 10 para mujer.", p.position + Vector2(560, 564), 16)
	_t("↑↓ / Tab campo · ←→ cambiar · escribe el nombre · Esc volver", p.position + Vector2(24, 626), 16)

func _unirse(vs: Vector2) -> void:
	var un: Dictionary = esc.un
	var p := Rect2(vs.x / 2 - 400, 60, 800, 580)
	ui.panel(self, p)
	_t("UNIRSE A UN MUNDO", p.position + Vector2(24, 16), 32)
	var nombres: Array = ["Dirección", "Nombre", "Clave", "Conectar"]
	var vals: Array = [un.dir, un.nombre, "*".repeat(un.clave.length()), "Enter"]
	for i in nombres.size():
		var b := Rect2(p.position.x + 32, p.position.y + 84 + i * 76, 736, 64)
		ui.boton(self, b, i == un.campo)
		_t(nombres[i], b.position + Vector2(28, 20), 24, UiArte.PAPEL)
		_t("%s%s" % [vals[i], "_" if i == un.campo and i < 3 else ""], b.position + Vector2(220, 20), 24, UiArte.PAPEL)
	if esc.modo == "conectando": _t("Conectando… (Esc cancela)", p.position + Vector2(32, 400), 24)
	_t("↑↓ campo · Enter conectar · P en Conectar: aspecto · Esc volver", p.position + Vector2(32, 450), 16)
	_t("La clave identifica a tu personaje en ese mundo: guárdala (se recuerda en este equipo).", p.position + Vector2(32, 476), 16, Color(UiArte.TINTA, 0.8))
	if esc.menu_msg != "": _t(esc.menu_msg, p.position + Vector2(32, 520), 16, Color("8a2020"))
