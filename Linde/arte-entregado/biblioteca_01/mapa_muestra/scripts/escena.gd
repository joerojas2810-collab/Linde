extends Node2D
# Presentación y entrada. Toda regla vive en Juego; aquí solo se pide y se muestra.
# Args tras "--": --guardado=ruta · --nueva=SEMILLA (salta menús) · --panel=inv|craft|hab|mis · --ir=x,y (celda, depuración)
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Apar = preload("res://scripts/apariencia.gd")
const J = preload("res://scripts/juego.gd")
const Hud = preload("res://scripts/hud.gd")
const Hab = preload("res://scripts/habitantes.gd")
const Arte = preload("res://scripts/arte.gd")
const Capas = preload("res://scripts/capas_sprite.gd")
var capas_pj = Capas.new()   # personaje por capas si hay hojas en res://arte
var usar_arte := true        # Copia de muestra: F2 alterna arte y dibujo anterior.
const COLORES := {Mundo.T.PASTO: Color("5a9b4a"), Mundo.T.CAMINO: Color("c9b27a"), Mundo.T.AGUA: Color("3f7fbf"),
	Mundo.T.PARED: Color("a8794f"), Mundo.T.SUELO: Color("8a6a4a"), Mundo.T.PUERTA: Color("5b3a22"),
	Mundo.T.RUINA: Color("8c8a86"), Mundo.T.MURO_RUINA: Color("5e5c63")}
const MAREN_LOOK := [1, 0, 2]
const AUTOGUARDADO_S := 30.0

var j
var modo := "menu"
var panel := ""
var lineas: Array = []
var acc: Array = []
var sel := 0
var dialogo_txt := ""
var cofre_id := ""
var build := false
var pieza_i := 0
var activa := Vector2i.ZERO
var t_anim := 0.0
var herramienta_visual := 0.0
var debug := false
var pista := ""
var cam := Camera2D.new()
var hud := Hud.new()
var ruta := "user://partida.json"
var auto_t := 0.0
var menu_items: Array = []
var menu_sel := 0
var menu_msg := ""
var cr := {"nombre": "Viajero", "piel": 0, "pelo": 1, "ropa": 0, "origen": 1, "semilla": 1, "campo": 0}

func _ready() -> void:
	var nueva := -1
	var panel_ini := ""
	var ir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--guardado="): ruta = a.substr(11)
		elif a.begins_with("--nueva="): nueva = int(a.substr(8))
		elif a.begins_with("--panel="): panel_ini = a.substr(8)
		elif a.begins_with("--ir="): ir = a.substr(5)
	cam.zoom = Vector2(P.ZOOM, P.ZOOM)
	cam.limit_right = Mundo.ANCHO * P.CELDA
	cam.limit_bottom = Mundo.ALTO * P.CELDA
	add_child(cam)
	var capa := CanvasLayer.new()
	hud.esc = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(hud)
	add_child(capa)
	get_tree().auto_accept_quit = false
	_menu_inicial()
	if nueva >= 0:
		j = J.nueva(nueva, cr.nombre, [cr.piel, cr.pelo, cr.ropa], "viajero")
		modo = "juego"
		if ir != "":
			var p := ir.split(",")
			j.pies = Mundo.pies_de_celda(Vector2i(int(p[0]), int(p[1])))
		if panel_ini != "": _abrir(panel_ini)

func _menu_inicial() -> void:
	modo = "menu"
	menu_items = ["Continuar", "Nueva partida", "Salir"]
	menu_sel = 0 if FileAccess.file_exists(ruta) or FileAccess.file_exists(ruta + ".bak") else 1
	if ruta.begins_with("user://"): ruta = ProjectSettings.globalize_path(ruta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if j != null and modo == "juego": j.guardar(ruta)
		get_tree().quit()

# ---------- entrada ----------
func _unhandled_key_input(e: InputEvent) -> void:
	if not e.pressed or e.echo: return
	if modo == "menu": return _tecla_menu(e)
	if modo == "creador": return _tecla_creador(e)
	if panel != "": return _tecla_panel(e)
	match e.keycode:
		KEY_ESCAPE:
			if build: build = false
			else: _abrir("pausa")
		KEY_I: _abrir("inv")
		KEY_C: _abrir("craft")
		KEY_K: _abrir("hab")
		KEY_J: _abrir("mis")
		KEY_B: build = not build
		KEY_F1: debug = not debug
		KEY_F2:
			usar_arte = not usar_arte and capas_pj.disponible()
			j.aviso("Arte de prueba: " + ("sí" if usar_arte else "no (dibujo procedural)"))
		KEY_F5:
			j.aviso("Guardado." if j.guardar(ruta) else "No se pudo guardar.")
		KEY_Q: if build: pieza_i = (pieza_i + C.ORDEN_CONSTR.size() - 1) % C.ORDEN_CONSTR.size()
		KEY_E:
			if build: pieza_i = (pieza_i + 1) % C.ORDEN_CONSTR.size()
			else: _interactuar()
		KEY_SPACE:
			if build: j.construir(C.ORDEN_CONSTR[pieza_i], Mundo.celda_de(j.pies) + j.mira)
		KEY_X: if build: j.retirar(Mundo.celda_de(j.pies) + j.mira)

func _tecla_menu(e: InputEvent) -> void:
	match e.keycode:
		KEY_UP: menu_sel = (menu_sel + menu_items.size() - 1) % menu_items.size()
		KEY_DOWN: menu_sel = (menu_sel + 1) % menu_items.size()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			match menu_sel:
				0:
					var g = J.cargar(ruta)
					if g == null: menu_msg = "No hay partida legible (el archivo no se borra). Crea una nueva."
					else:
						j = g
						modo = "juego"
				1:
					cr.semilla = randi() % 100000
					cr.campo = 0
					modo = "creador"
				2: get_tree().quit()

func _tecla_creador(e: InputEvent) -> void:
	var lim := [0, 3, 4, 3, C.ORIGENES.size(), 0]
	match e.keycode:
		KEY_ESCAPE: return _menu_inicial()
		KEY_UP: cr.campo = (cr.campo + 6) % 7
		KEY_DOWN: cr.campo = (cr.campo + 1) % 7
		KEY_LEFT, KEY_RIGHT:
			var s: int = 1 if e.keycode == KEY_RIGHT else -1
			var k: String = ["", "piel", "pelo", "ropa", "origen", "semilla"][cr.campo] if cr.campo > 0 and cr.campo < 6 else ""
			if k == "semilla": cr.semilla = maxi(0, cr.semilla + s)
			elif k != "": cr[k] = (cr[k] + s + lim[cr.campo]) % lim[cr.campo]
		KEY_BACKSPACE: if cr.campo == 0: cr.nombre = cr.nombre.substr(0, cr.nombre.length() - 1)
		KEY_ENTER, KEY_KP_ENTER:
			if cr.campo == 6:
				j = J.nueva(cr.semilla, cr.nombre, [cr.piel, cr.pelo, cr.ropa], C.ORIGENES.keys()[cr.origen])
				j.guardar(ruta)
				modo = "juego"
		_:
			if cr.campo == 0 and e.unicode >= 32 and e.unicode != 127 and cr.nombre.length() < 16: cr.nombre += char(e.unicode)

func _abrir(p: String) -> void:
	panel = p
	sel = 0
	_armar()
	_sel_valida(1)

func _cerrar() -> void:
	panel = ""
	cofre_id = ""

func _tecla_panel(e: InputEvent) -> void:
	if panel == "dialogo":
		if e.keycode in [KEY_E, KEY_ENTER, KEY_ESCAPE, KEY_SPACE]: _cerrar()
		return
	match e.keycode:
		KEY_ESCAPE: _cerrar()
		KEY_I: if panel == "inv": _cerrar()
		KEY_C: if panel == "craft": _cerrar()
		KEY_K: if panel == "hab": _cerrar()
		KEY_J: if panel == "mis": _cerrar()
		KEY_UP:
			sel -= 1
			_sel_valida(-1)
		KEY_DOWN:
			sel += 1
			_sel_valida(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			if sel < acc.size() and acc[sel] != null:
				var antes := sel
				acc[sel].call()
				if panel != "":
					_armar()
					sel = mini(antes, lineas.size() - 1)
					_sel_valida(-1)

func _sel_valida(paso: int) -> void:
	if lineas.is_empty(): return
	sel = clampi(sel, 0, lineas.size() - 1)
	var n := 0
	while acc[sel] == null and n < lineas.size():
		sel = (sel + paso + lineas.size()) % lineas.size()
		n += 1

func _l(t: String, f = null) -> void:
	lineas.append(t)
	acc.append(f)

func _armar() -> void:
	lineas = []
	acc = []
	var st: Dictionary = j.stats()
	match panel:
		"inv":
			_l("INVENTARIO  %d/%d  ·  Nv %d  Daño %d  Def %d  Vel x%.2f" % [Inv.slots(j.d.inv), st.slots, j.nivel(), st.dmg, st.def, st.vel])
			_l("— Equipado —")
			for r in C.RANURAS:
				var q: String = j.d.equipo[r]
				_l("%s: %s" % [r.capitalize(), (C.ITEMS[q].n + "  (Enter: quitar)") if q != "" else "—"], func(): j.desequipar(r))
			_l("— Mochila —")
			var ks: Array = j.d.inv.keys()
			ks.sort()
			for k in ks:
				var cura: bool = C.ITEMS[k].has("cura")
				var eq: bool = C.ITEMS[k].has("equipo")
				_l("%s  x%d%s" % [C.ITEMS[k].n, j.d.inv[k], "   (usar)" if cura else ("   (equipar)" if eq else "")], func():
					if cura: j.usar(k)
					elif eq: j.equipar(k))
			if ks.is_empty(): _l("(vacío)")
			if not j.d.pendientes.is_empty(): _l("Pendiente de recibir: " + Hud.J_txt(j.d.pendientes))
		"craft":
			_l("FABRICAR  ·  estaciones: mesa y horno a ≤2 celdas")
			for id in C.RECETAS:
				var r: Dictionary = C.RECETAS[id]
				var listo: bool = Inv.tiene(j.d.inv, r.ent) and (r.hab == "" or j.d.hab.has(r.hab)) and j.estacion_cerca(r.est)
				var nota := ""
				if r.hab != "" and not j.d.hab.has(r.hab): nota += " [req. %s]" % C.HAB[r.hab].n
				if r.est != "": nota += " [%s]" % r.est
				_l("%s %s  <-  %s%s" % ["[ok]" if listo else "[--]", r.n, Hud.J_txt(r.ent), nota], func(): j.fabricar(id))
		"hab":
			_l("HABILIDADES  ·  puntos libres: %d  ·  nivel %d" % [j.puntos_libres(), j.nivel()])
			for id in C.HAB:
				var h: Dictionary = C.HAB[id]
				var req := ""
				for r in h.req: req += " " + C.HAB[r].n
				var e := "APRENDIDA" if j.d.hab.has(id) else "coste %d · nv %d%s" % [h.coste, h.niv, (" · req:" + req) if req != "" else ""]
				_l("[%s] %s  (%s)" % [h.rama.substr(0, 3), h.n, e], func(): j.aprender(id))
		"mis":
			_l("MISIONES  ·  las de capítulo se piden y entregan hablando con quien las da")
			for id in C.MISIONES:
				var m: Dictionary = C.MISIONES[id]
				var e: String = j.estado_mision(id)
				if e == "" and not j.mision_disponible(id): continue
				var etq: String = {"": "disponible", "activa": "activa", "cumplida": "CUMPLIDA", "entregada": "entregada"}[e]
				_l("%s  [%s]  (%s)" % [m.n, etq, m.tipo], func():
					if m.da == "" and e == "": j.aceptar(id)
					elif m.da == "" and e == "cumplida": j.entregar(id))
				if e == "activa" or e == "cumplida":
					for o in m.obj: _l("      " + ("[x] " if j.objetivo_ok(o) else "[ ] ") + j.objetivo_txt(o))
		"cofre":
			_l("COFRE  ·  Enter mueve la pila completa al otro lado")
			_l("— Tu inventario —")
			for k in j.d.inv: _l("%s x%d  → cofre" % [C.ITEMS[k].n, j.d.inv[k]], func(): j.mover_cofre(cofre_id, k, true))
			_l("— Cofre —")
			var cf: Dictionary = j.d.cofres.get(cofre_id, {"inv": {}})
			for k in cf.inv: _l("%s x%d  → inventario" % [C.ITEMS[k].n, cf.inv[k]], func(): j.mover_cofre(cofre_id, k, false))
		"pausa":
			_l("PAUSA")
			_l("Continuar", func(): _cerrar())
			_l("Guardar", func(): j.aviso("Guardado." if j.guardar(ruta) else "No se pudo guardar."); _cerrar())
			_l("Guardar y salir al menú", func(): j.guardar(ruta); _cerrar(); j = null; _menu_inicial())

func _interactuar() -> void:
	var r: Dictionary = j.interactuar()
	if not r.ok: return
	match r.panel:
		"dialogo":
			dialogo_txt = r.texto
			panel = "dialogo"
		"cofre":
			cofre_id = r.id
			_abrir("cofre")

# ---------- bucle ----------
func oscuridad(h: float) -> float:
	if h < 5.0 or h >= 21.0: return 0.5
	if h < 7.0: return lerpf(0.5, 0.0, (h - 5.0) / 2.0)
	if h >= 19.0: return lerpf(0.0, 0.5, (h - 19.0) / 2.0)
	return 0.0

func _held() -> Array:
	var h: Array = []
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): h.append(Vector2i.UP)
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): h.append(Vector2i.DOWN)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): h.append(Vector2i.LEFT)
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): h.append(Vector2i.RIGHT)
	return h

func _process(delta: float) -> void:
	queue_redraw()
	if modo != "juego" or j == null: return
	cam.position = j.pies - Vector2(0, 12)
	if panel != "":
		if panel != "dialogo": _armar()
		return
	herramienta_visual = maxf(0.0, herramienta_visual-delta)
	var pies_antes: Vector2 = j.pies
	delta = minf(delta, 1.0 / 30.0)    # evita saltos mayores que la caja de pies
	activa = Mundo.dir_cardinal(_held(), activa)
	if build:
		if activa != Vector2i.ZERO: j.mira = activa
		j.tick(delta)
	else:
		j.mover_pj(activa, delta)
		if Input.is_key_pressed(KEY_SPACE):
			var cd_antes: float = j.cd_obj
			var accion_res: Dictionary = j.accion()
			if j.cd_obj > cd_antes and accion_res.get("ok", false) and j.d.inv.has("hacha_piedra"):
				herramienta_visual = 0.3
		j.tick(delta)
	t_anim = t_anim + delta if j.pies.distance_squared_to(pies_antes)>0.001 else 0.0
	auto_t += delta
	if auto_t >= AUTOGUARDADO_S:
		auto_t = 0.0
		j.guardar(ruta)
	pista = _pista()

func _pista() -> String:
	for id in Hab.NPCS:
		if j.habitantes.pos(id).distance_to(j.pies) <= J.ALCANCE_NPC: return "E: hablar con %s" % Hab.NPCS[id].n
	var base := Mundo.celda_de(j.pies)
	for c in [base + j.mira, base]:
		var oid: String = j.mundo.objeto_presente(c)
		if oid != "":
			var ot: String = j.mundo.objetos[oid].t
			if ot in Mundo.DECO: continue
			return "E: abrir cofre" if ot == "cofre_fijo" else "Espacio: golpear %s" % C.OBJETOS[ot].n
		var cs: Dictionary = j.mundo.constr_en(c)
		if cs.get("t", "") == "cofre": return "E: abrir cofre"
		if cs.get("t", "") == "cama": return "E: dormir" if cs.propia else "Cama de Maren"
	return ""

func _frame() -> int:
	return 0 if t_anim == 0.0 else int(t_anim / P.PASO_S) % 4

# ---------- dibujo del mundo ----------
func _draw() -> void:
	if modo != "juego" or j == null: return
	var s := P.CELDA
	var vp := get_viewport_rect().size / float(P.ZOOM)
	var vista := Rect2(cam.position - vp / 2.0, vp).grow(40)
	var m = j.mundo
	var x0 := maxi(0, int(vista.position.x / s))
	var x1 := mini(Mundo.ANCHO - 1, int(vista.end.x / s))
	var y0 := maxi(0, int(vista.position.y / s))
	var y1 := mini(Mundo.ALTO - 1, int(vista.end.y / s))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var c := Vector2i(x, y)
			Arte.suelo(self, m, c)
			var cs: Dictionary = m.constr_en(c)
			if cs.get("t", "") == "suelo": Arte.constr(self, "suelo", Vector2(c) * s, Color(C.CONSTR.suelo.c))
	for e in j.combate.enemigos: if e.est == "aviso": _telegrafo(e)
	var lista: Array = [[j.pies.y, "pj", null], [Mundo.CASA.end.y * 16.0 - 8.0, "fachada", null]]
	for id in Hab.NPCS: lista.append([j.habitantes.pos(id).y, "npc", id])
	for e in j.combate.enemigos: lista.append([e.pos.y, "enemigo", e])
	for id in m.objetos:
		var o: Dictionary = m.objetos[id]
		if not vista.has_point(Vector2(o.c) * s): continue
		if m.estado.rotos.has(id): continue
		lista.append([(o.c.y + 1.0) * s, "obj", id])
	for k in m.estado.constr:
		var p: PackedStringArray = k.split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		if m.estado.constr[k].t != "suelo" and vista.has_point(Vector2(c) * s): lista.append([(c.y + 1.0) * s, "constr", c])
	lista.sort_custom(func(a, b): return a[0] < b[0])
	for e in lista:
		match e[1]:
			"pj": _dibujar_pj()
			"npc": _dibujar_npc(e[2])
			"enemigo": _dibujar_enemigo(e[2])
			"obj": _dibujar_obj(e[2])
			"constr": _dibujar_constr(e[2])
			"fachada": Arte.fachada(self, Mundo.CASA, Mundo.PUERTA_C, 0.25 if Mundo.CASA.has_point(Mundo.celda_de(j.pies)) else 1.0)
	var dentro := Mundo.CASA.has_point(Mundo.celda_de(j.pies))
	Arte.tejado(self, Mundo.CASA, 0.25 if Mundo.CASA.has_point(Mundo.celda_de(j.pies)) else 1.0)
	if build:
		var c: Vector2i = Mundo.celda_de(j.pies) + j.mira
		var id: String = C.ORDEN_CONSTR[pieza_i]
		var bien: bool = m.puede_poner(c) == "" and not j.ocupada(c) and Inv.tiene(j.d.inv, C.CONSTR[id].coste)
		draw_rect(Rect2(Vector2(c) * s, Vector2(s, s)), Color(0.2, 1, 0.3, 0.45) if bien else Color(1, 0.2, 0.2, 0.45))
		draw_rect(Rect2(Vector2(c) * s, Vector2(s, s)), Color(C.CONSTR[id].c, 0.6), false, 1)
	if j.combate.est == "activo":
		draw_rect(j.combate.zona_golpe(), Color(1, 1, 1, 0.35))
	if debug:
		draw_rect(Rect2(j.pies - Vector2(P.PIES.x / 2, P.PIES.y), P.PIES), Color(1, 0, 0, 0.5))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if m.bloquea(Vector2i(x, y)): draw_rect(Rect2(x * s, y * s, s, s), Color(1, 0, 0, 0.25))

func _telegrafo(e: Dictionary) -> void:
	var info: Dictionary = j.combate.info_ataque(e, e.atq)
	var prog := 1.0 - clampf(e.t / info.aviso, 0.0, 1.0)
	var col := Color(1, 0.1, 0.1, 0.18 + 0.35 * prog)
	var c: Vector2 = j.combate.centro(e)
	if info.forma == "circulo":
		draw_circle(c, info.radio, col)
	else:
		var d: Vector2 = e.dir
		var n: Vector2 = d.orthogonal() * info.ancho / 2.0
		var b: Vector2 = c + d * info.avance
		draw_colored_polygon(PackedVector2Array([c + n, b + n, b - n, c - n]), col)

func _dibujar_pj() -> void:
	if j.combate.inv_t > 0.0 and int(j.combate.inv_t * 20.0) % 2 == 0: return
	var origen: Vector2 = (j.pies - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	draw_rect(Rect2(origen + Vector2(3, 22), Vector2(10, 3)), Color(0, 0, 0, 0.3))
	if usar_arte and capas_pj.disponible():
		if j.combate.est != "libre" and j.d.inv.has("espada_hierro"):
			var cuadro_ataque: int = 1 if j.combate.est == "aviso" else (2 if j.combate.est == "activo" else 3)
			capas_pj.dibujar_accion(self,j.pies,j.combate.dir,"ataque",cuadro_ataque)
		elif herramienta_visual>0.0:
			capas_pj.dibujar_accion(self,j.pies,j.mira,"herramienta",clampi(int((0.3-herramienta_visual)/0.075),0,3))
		else: capas_pj.dibujar(self, j.pies, j.mira, _frame(), _equipo_visible())
	else: Apar.dibujar(self, origen, j.mira, _frame(), j.d.pj.look)

func _equipo_visible() -> Array:
	var v: Array = []
	for r in C.RANURAS: if j.d.equipo[r] != "": v.append(r)
	if j.d.inv.has("espada_hierro"): v.append("espada")
	return v

func _dibujar_npc(id: String) -> void:
	var p: Vector2 = j.habitantes.pos(id)
	var origen: Vector2 = (p - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	draw_rect(Rect2(origen + Vector2(3, 22), Vector2(10, 3)), Color(0, 0, 0, 0.3))
	var dir := Vector2i.DOWN
	var act: String = j.d.npcs[id].act
	Apar.dibujar(self, origen, dir, int(Time.get_ticks_msec() / 150.0) % 4 if act == "camina" else 0, MAREN_LOOK)
	var f := ThemeDB.fallback_font
	draw_string(f, origen + Vector2(-6, -4), Hab.NPCS[id].n + (" (zzz)" if act == "dormir" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _dibujar_enemigo(e: Dictionary) -> void:
	if not usar_arte:
		var tam: float = e.tam
		var color: Color = {"slime": Color("5fd0a0"), "guardian": Color("7d6b9a"), "ciervo": Color("a0784a")}[e.tipo]
		if e.est == "aviso": color = color.lightened(0.35)
		var origen: Vector2 = e.pos - Vector2(tam / 2.0, tam)
		draw_rect(Rect2(e.pos - Vector2(tam / 2.0, 3), Vector2(tam, 4)), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(origen + Vector2(0, tam * 0.3), Vector2(tam, tam * 0.7)), color)
		draw_rect(Rect2(origen + Vector2(tam * 0.1, 0), Vector2(tam * 0.8, tam * 0.4)), color)
		draw_rect(Rect2(origen + Vector2(tam * 0.25, tam * 0.35), Vector2(2, 3)), Color.BLACK)
		draw_rect(Rect2(origen + Vector2(tam * 0.65, tam * 0.35), Vector2(2, 3)), Color.BLACK)
		if e.tipo == "ciervo":
			draw_rect(Rect2(origen + Vector2(-2, -6), Vector2(3, 8)), Color("e8dcc0"))
			draw_rect(Rect2(origen + Vector2(tam - 1, -6), Vector2(3, 8)), Color("e8dcc0"))
		var definition: Dictionary = C.ENEMIGOS[e.tipo]
		if e.hp < definition.hp:
			draw_rect(Rect2(origen + Vector2(0, -6), Vector2(tam, 3)), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(origen + Vector2(0, -6), Vector2(tam * float(e.hp) / definition.hp, 3)), Color("e74c3c"))
		return
	# Solo presentación: cache local al nodo, nunca añade campos al estado de combate.
	var cache: Dictionary = get_meta("arte_enemigos_cache", {})
	var clave: String = str(e.tipo) + ":" + str(e.home)
	var ahora: float = Time.get_ticks_msec() / 1000.0
	var anterior: Dictionary = cache.get(clave, {"pos": e.pos, "dir": Vector2.DOWN, "movio": -100.0})
	var desplazamiento: Vector2 = e.pos - Vector2(anterior.pos)
	if desplazamiento.length_squared() > 0.00001:
		anterior.dir = desplazamiento.normalized()
		anterior.movio = ahora
	anterior.pos = e.pos
	var mirando: Vector2 = anterior.dir
	if e.est == "aviso" or e.est == "recupera": mirando = e.dir
	var fila := 0
	if absf(mirando.x) > absf(mirando.y): fila = 1 if mirando.x > 0.0 else 3
	else: fila = 0 if mirando.y >= 0.0 else 2
	var columna := 0
	if e.est == "aviso":
		columna = 3
	elif e.est == "recupera":
		var ataque: Dictionary = j.combate.info_ataque(e, e.atq)
		columna = 4 if float(ataque.rec) - float(e.t) < 0.18 else 0
	elif ahora - float(anterior.movio) < 0.08 and e.est in ["idle", "persigue"]:
		columna = [1, 0, 2, 0][int(ahora / 0.15) % 4]
	var textura: Texture2D = anterior.get("textura", null)
	if textura == null:
		textura = load("res://assets/enemigos/" + str(e.tipo) + ".png") as Texture2D
		anterior.textura = textura
	cache[clave] = anterior
	set_meta("arte_enemigos_cache", cache)
	var celda := 32 if e.tipo == "slime" else 48
	var pivote := Vector2(celda / 2.0, celda - 3.0)
	var destino := Rect2((e.pos - pivote).round(), Vector2(celda, celda))
	var t: float = e.tam
	draw_rect(Rect2(e.pos - Vector2(t / 2.0, 3), Vector2(t, 4)), Color(0, 0, 0, 0.25))
	if textura != null:
		draw_texture_rect_region(textura, destino, Rect2(columna * celda, fila * celda, celda, celda))
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	if e.hp < def.hp:
		var alto: float = 16.0 if e.tipo == "slime" else 38.0
		var barra: Vector2 = e.pos - Vector2(t / 2.0, alto + 6.0)
		draw_rect(Rect2(barra, Vector2(t, 3)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(barra, Vector2(t * float(e.hp) / def.hp, 3)), Color("e74c3c"))

func _dibujar_obj(id: String) -> void:
	var o: Dictionary = j.mundo.objetos[id]
	var p := Vector2(o.c) * P.CELDA
	match o.t:
		"arbol": Arte.arbol(self, p, Mundo.h(o.c.x, o.c.y, 5))
		"roca": Arte.roca(self, p, false)
		"veta": Arte.roca(self, p, true)
		"arbusto": Arte.arbusto(self, p)
		"barril": Arte.barril(self, p)
		"valla": Arte.valla(self, p)
		"cofre_fijo": Arte.cofre(self, p, Color("93602d"), j.d.cofres.tesoro_cantera.get("abierto", false))
	var g: int = j.mundo.estado.golpes.get(id, 0)
	if g > 0: draw_rect(Rect2(p + Vector2(2, -2), Vector2(12, 2)), Color(1, 1, 1, 0.8))

func _dibujar_constr(c: Vector2i) -> void:
	var cs: Dictionary = j.mundo.constr_en(c)
	Arte.constr(self, cs.t, Vector2(c) * P.CELDA, Color(C.CONSTR[cs.t].c))
