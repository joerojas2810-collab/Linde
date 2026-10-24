extends Control
# Dibuja la interfaz en espacio de pantalla (1280x720). Solo lee estado de la escena; no concede nada.
const C = preload("res://scripts/catalogos.gd")
const Apar = preload("res://scripts/apariencia.gd")
const Hab = preload("res://scripts/habitantes.gd")
const Eq = preload("res://scripts/equipo.gd")
var esc
var f := ThemeDB.fallback_font

func _process(_d: float) -> void:
	queue_redraw()

func _t(txt: String, pos: Vector2, tam: int = 16, col: Color = Color.WHITE) -> void:
	draw_string(f, pos + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(0, 0, 0, 0.7))
	draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

func _barra(pos: Vector2, ancho: float, frac: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(ancho, 10)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2((ancho - 2) * clampf(frac, 0, 1), 8)), col)

func _draw() -> void:
	var vs := size
	if esc == null: return
	if esc.modo == "menu": return _menu(vs)
	if esc.modo == "creador": return _creador(vs)
	if esc.modo == "unirse" or esc.modo == "conectando": return _unirse(vs)
	var j = esc.j
	var h: float = j.hora_dia()
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.04, 0.06, 0.2, esc.oscuridad(h)))
	var st: Dictionary = j.stats()
	_t("%s  Nv %d" % [j.jug().nombre, j.nivel()], Vector2(12, 22), 16)
	_barra(Vector2(12, 30), 160, float(j.jug().hp) / st.hp, Color("c0392b"))
	_t("%d/%d" % [j.jug().hp, st.hp], Vector2(178, 40), 12)
	var sig := C.umbral_xp(j.nivel() + 1) if j.nivel() < C.NIVEL_MAX else C.umbral_xp(j.nivel())
	var ant := C.umbral_xp(j.nivel())
	_barra(Vector2(12, 44), 160, float(j.jug().xp - ant) / maxf(1.0, sig - ant), Color("3498db"))
	if j.puntos_libres() > 0: _t("¡%d punto(s) de habilidad! (K)" % j.puntos_libres(), Vector2(12, 70), 13, Color("f1c40f"))
	_t("Día %d  %02d:%02d" % [j.dia(), int(h), int(fmod(h, 1.0) * 60)], Vector2(vs.x - 150, 22), 16)
	if esc.red != null: _t(esc.red.estado_txt(), Vector2(vs.x / 2 - 140, 22), 13, Color("2ecc71"))
	_t("I inv · F forja · C fabricar · K habilidades · J misiones · B construir · E interactuar · Espacio acción · Esc menú",
		Vector2(12, vs.y - 10), 12, Color(1, 1, 1, 0.7))
	var y := vs.y - 100
	for m in j.msgs.slice(-4):
		_t(m, Vector2(12, y), 14)
		y += 18
	if esc.debug: _t("anim: %s #%d" % [esc._anim.estado, esc._anim.cuadro], Vector2(vs.x - 150, 40), 12, Color("2ecc71"))
	if esc.pista != "": _t(esc.pista, Vector2(vs.x / 2 - 120, vs.y - 130), 16, Color("f1c40f"))
	_tracker(vs, j)
	if esc.build:
		var id: String = C.ORDEN_CONSTR[esc.pieza_i]
		_t("CONSTRUIR: %s  coste %s   [Q/E] cambiar · [Espacio] colocar · [X] retirar · [B] salir" % [C.CONSTR[id].n, J_txt(C.CONSTR[id].coste)],
			Vector2(12, 96), 15, Color("2ecc71"))
	if esc.panel != "": _panel(vs)

static func J_txt(m: Dictionary) -> String:
	var l: Array = []
	for k in m: l.append("%d %s" % [m[k], Eq.info(k).n])
	return ", ".join(l)

func _tracker(vs: Vector2, j) -> void:
	var y := 50.0
	for id in C.MISIONES:
		var e: String = j.estado_mision(id)
		if e != "activa" and e != "cumplida": continue
		_t(C.MISIONES[id].n + (" (¡cumplida!)" if e == "cumplida" else ""), Vector2(vs.x - 380, y), 15, Color("f39c12"))
		y += 18
		if C.MISIONES[id].da != "" and e == "cumplida": _t("   → vuelve con " + C.MISIONES[id].da.capitalize(), Vector2(vs.x - 380, y), 12); y += 16
		for o in C.MISIONES[id].obj:
			_t(("  [x] " if j.objetivo_ok(o) else "  [ ] ") + j.objetivo_txt(o), Vector2(vs.x - 380, y), 12)
			y += 16
		y += 6

func _panel(vs: Vector2) -> void:
	var r := Rect2(vs.x / 2 - 360, 110, 720, 460)
	draw_rect(r, Color(0.05, 0.05, 0.08, 0.92))
	draw_rect(r, Color(0.9, 0.8, 0.4), false, 2)
	if esc.panel == "dialogo":
		_t("Maren", r.position + Vector2(20, 34), 20, Color("f1c40f"))
		draw_multiline_string(f, r.position + Vector2(20, 70), esc.dialogo_txt, HORIZONTAL_ALIGNMENT_LEFT, 680, 17, -1, Color.WHITE)
		_t("[E / Enter] cerrar", r.position + Vector2(20, 430), 13, Color(1, 1, 1, 0.6))
		return
	var y := r.position.y + 30
	var caben := int((r.size.y - 60) / 23.0)                      # líneas visibles; la cabecera (0) siempre se ve
	var ini := maxi(1, esc.sel - caben + 2)                       # desplaza para que la selección quede a la vista
	for i in esc.lineas.size():
		if i > 0 and i < ini: continue
		if i == esc.sel and esc.acc[i] != null:
			draw_rect(Rect2(r.position.x + 8, y - 17, r.size.x - 16, 22), Color(0.3, 0.4, 0.6, 0.7))
		var col := Color.WHITE if esc.acc[i] != null or i == 0 else Color(1, 1, 1, 0.65)
		_t(esc.lineas[i], Vector2(r.position.x + 18, y), 15 if i > 0 else 18, col)
		y += 23
		if y > r.end.y - 30: break
	_t("[↑↓] mover · [Enter] elegir · [Esc] cerrar", Vector2(r.position.x + 18, r.end.y - 8), 12, Color(1, 1, 1, 0.6))

func _menu(vs: Vector2) -> void:
	_t("LINDE", Vector2(vs.x / 2 - 90, 190), 64, Color("f1c40f"))
	_t("RPG de mundo vivo  ·  prototipo cenital", Vector2(vs.x / 2 - 150, 230), 18)
	for i in esc.menu_items.size():
		var col := Color("ffffff") if i == esc.menu_sel else Color(1, 1, 1, 0.5)
		_t(("> " if i == esc.menu_sel else "  ") + esc.menu_items[i], Vector2(vs.x / 2 - 90, 320 + i * 34), 24, col)
	if esc.menu_msg != "": _t(esc.menu_msg, Vector2(vs.x / 2 - 220, 480), 15, Color("e74c3c"))

func _creador(vs: Vector2) -> void:
	var cr: Dictionary = esc.cr
	_t("CREA TU PERSONAJE", Vector2(vs.x / 2 - 150, 90), 28, Color("f1c40f"))
	var nombres: Array = ["Nombre", "Piel", "Pelo", "Ropa", "Origen", "Semilla", "Comenzar"]
	var vals: Array = [cr.nombre + ("_" if cr.campo == 0 else ""), "%d/3" % (cr.piel + 1), "%d/4" % (cr.pelo + 1), "%d/3" % (cr.ropa + 1),
		C.ORIGENES.values()[cr.origen], str(cr.semilla), "Enter"]
	for i in nombres.size():
		var col := Color.WHITE if i == cr.campo else Color(1, 1, 1, 0.55)
		_t(("> " if i == cr.campo else "  ") + "%-9s %s" % [nombres[i], vals[i]], Vector2(300, 190 + i * 34), 22, col)
	var o := Vector2(900, 260)
	for k in 4:
		var d: Vector2i = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT][k]
		draw_set_transform(o + Vector2(0, k * 0), 0, Vector2(5, 5))
		Apar.dibujar(self, Vector2(k * 18, 0), d, 0, [cr.piel, cr.pelo, cr.ropa])
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_t("↑↓ campo · ←→ cambiar · escribe el nombre · Esc volver", Vector2(300, 470), 14, Color(1, 1, 1, 0.7))
	_t("Los orígenes dan contexto de diálogo, sin ventajas numéricas.", Vector2(300, 494), 13, Color(1, 1, 1, 0.5))

func _unirse(vs: Vector2) -> void:
	var un: Dictionary = esc.un
	_t("UNIRSE A UN MUNDO", Vector2(vs.x / 2 - 150, 120), 28, Color("f1c40f"))
	var nombres: Array = ["Dirección", "Nombre", "Clave", "Conectar"]
	var vals: Array = [un.dir, un.nombre, "*".repeat(un.clave.length()), "Enter"]
	for i in nombres.size():
		var col := Color.WHITE if i == un.campo else Color(1, 1, 1, 0.55)
		_t(("> " if i == un.campo else "  ") + "%-10s %s%s" % [nombres[i], vals[i], "_" if i == un.campo and i < 3 else ""], Vector2(300, 220 + i * 40), 22, col)
	if esc.modo == "conectando": _t("Conectando… (Esc cancela)", Vector2(300, 400), 18, Color("2ecc71"))
	_t("↑↓ campo · escribe · Enter conectar · Esc volver", Vector2(300, 450), 14, Color(1, 1, 1, 0.7))
	_t("La clave identifica a tu personaje en ese mundo: guárdala (se recuerda en este equipo).", Vector2(300, 474), 13, Color(1, 1, 1, 0.5))
	if esc.menu_msg != "": _t(esc.menu_msg, Vector2(300, 510), 15, Color("e74c3c"))
