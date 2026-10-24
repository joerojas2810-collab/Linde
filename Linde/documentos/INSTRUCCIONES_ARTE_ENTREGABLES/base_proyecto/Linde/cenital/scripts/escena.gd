extends Node2D
# Presentación y entrada. Toda regla vive en Juego; aquí solo se pide y se muestra.
# Args tras "--": --guardado=ruta · --nueva=SEMILLA (salta menús) · --panel=inv|forja|craft|hab|mis · --ir=x,y (celda, depuración)
# Depuración del arte (con --nueva): --arte (activa usar_arte) · --equipo=<familia>:<variante|sin_piedra> (set completo
# + escudo + espada) · --mira=frente|derecha|espalda|izquierda · --auto-ataque (el jugador local ataca cada
# AUTO_ATAQUE_S s, con el ciclo real de combate; muestra fase/pose sobre el PJ e imprime una línea por cuadro dibujado)
# Servidor sin ventana: --servidor [--puerto=7777] [--guardado=ruta] [--semilla=N] [--duracion=s] [--registro=ruta.json]
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
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
const Eq = preload("res://scripts/equipo.gd")
const ArteEq = preload("res://scripts/arte_equipo.gd")
var capas_pj = Capas.new()   # personaje por capas si hay hojas en res://arte (arte anterior, reserva)
var arte_eq = ArteEq.new()   # base + equipo por índices (res://arte/equipo); preferido si está completo
var usar_arte := true        # arte nuevo siempre activo; la línea procedural anterior ya no se muestra (se retira por completo en el plan de estética)
const MIRA := {"frente": Vector2i.DOWN, "derecha": Vector2i.RIGHT, "espalda": Vector2i.UP, "izquierda": Vector2i.LEFT}
const COLORES := {Mundo.T.PASTO: Color("5a9b4a"), Mundo.T.CAMINO: Color("c9b27a"), Mundo.T.AGUA: Color("3f7fbf"),
	Mundo.T.PARED: Color("a8794f"), Mundo.T.SUELO: Color("8a6a4a"), Mundo.T.PUERTA: Color("5b3a22"),
	Mundo.T.RUINA: Color("8c8a86"), Mundo.T.MURO_RUINA: Color("5e5c63")}
const MAREN_LOOK := [1, 0, 2]
const AUTOGUARDADO_S := 30.0
const AUTO_ATAQUE_S := 0.8      # depuración (--auto-ataque): intervalo entre ataques; el ciclo dura 0,45 s
const POSES_ATAQUE := ["prep", "antic", "impac", "recup"]   # preparado, anticipación, impacto, recuperación
var auto_ataque := -1.0         # < 0: desactivado; si no, tiempo acumulado hasta el próximo ataque

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
var debug := false
var _anim := {"estado": "reposo", "cuadro": 0}
var pista := ""
var cam := Camera2D.new()
var hud := Hud.new()
var ruta := "user://partida.json"
var auto_t := 0.0
var menu_items: Array = []
var menu_sel := 0
var menu_msg := ""
var cr := {"nombre": "Viajero", "piel": 0, "pelo": 1, "ropa": 0, "origen": 1, "semilla": 1, "campo": 0}
var red: Node = null          # red_servidor (alojando) o red_cliente (unido); null = un jugador sin red
var un := {"dir": "127.0.0.1:7777", "nombre": "", "clave": "", "campo": 0}   # formulario «Unirse»
const RED_CFG := "user://red.cfg"

func _ready() -> void:
	var nueva := -1
	var panel_ini := ""
	var ir := ""
	var srv := {}
	var dbg := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--guardado="): ruta = a.substr(11)
		elif a.begins_with("--nueva="): nueva = int(a.substr(8))
		elif a.begins_with("--panel="): panel_ini = a.substr(8)
		elif a.begins_with("--ir="): ir = a.substr(5)
		elif a == "--arte": dbg["arte"] = true
		elif a.begins_with("--equipo="): dbg["equipo"] = a.substr(9)
		elif a.begins_with("--mira="): dbg["mira"] = a.substr(7)
		elif a == "--auto-ataque": dbg["auto_ataque"] = true
		elif a == "--servidor": srv["si"] = true
		elif a.begins_with("--puerto="): srv["puerto"] = int(a.substr(9))
		elif a.begins_with("--semilla="): srv["semilla"] = int(a.substr(10))
		elif a.begins_with("--duracion="): srv["duracion"] = float(a.substr(11))
		elif a.begins_with("--registro="): srv["registro"] = a.substr(11)
	if srv.has("si"): return _servidor_sin_ventana(srv)
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
		_depurar_arte(dbg)
		if panel_ini != "": _abrir(panel_ini)

# Solo depuración/capturas: activa el arte, pone un set completo de una familia (+ escudo y espada) y la orientación.
func _depurar_arte(dbg: Dictionary) -> void:
	if dbg.has("arte"): usar_arte = _hay_arte()
	if dbg.has("equipo"):
		var p: PackedStringArray = str(dbg.equipo).split(":")
		var fam: String = p[0]
		var v: String = p[1] if p.size() > 1 and p[1] != "sin_piedra" else ""
		for r in Eq.datos().familias.get(fam, {}).get("piezas", []):
			var k := Eq.construir(fam, str(r), v, 0)
			if not Eq.leer(k).is_empty(): j.jug().equipo[r] = k
		j.jug().equipo["escudo"] = "escudo_madera"
		j.jug().inv["espada_hierro"] = 1
	if MIRA.has(dbg.get("mira", "")): j.mira = MIRA[dbg.mira]
	if dbg.has("auto_ataque"): auto_ataque = 0.0

func _hay_arte() -> bool:
	return arte_eq.disponible() or capas_pj.disponible()

func _menu_inicial() -> void:
	_cerrar_red()
	modo = "menu"
	menu_items = ["Continuar", "Nueva partida", "Alojar partida", "Unirse", "Salir"]
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
	if modo == "unirse" or modo == "conectando": return _tecla_unirse(e)
	if panel != "": return _tecla_panel(e)
	match e.keycode:
		KEY_ESCAPE:
			if build: build = false
			else: _abrir("pausa")
		KEY_I: _abrir("inv")
		KEY_F: _abrir("forja")
		KEY_C: _abrir("craft")
		KEY_K: _abrir("hab")
		KEY_J: _abrir("mis")
		KEY_B: build = not build
		KEY_F1: debug = not debug
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
						for id in g.rt.keys(): if id != J.LOCAL: g.salir(id)   # mundo alojado: los demás no están
						j = g
						modo = "juego"
				1:
					cr.semilla = randi() % 100000
					cr.campo = 0
					modo = "creador"
				2: _alojar()
				3: _abrir_unirse()
				4: get_tree().quit()

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

# ---------- red ----------
func _cerrar_red() -> void:
	if red != null: red.queue_free()
	red = null

func _servidor_sin_ventana(o: Dictionary) -> void:
	Engine.max_fps = 60             # sin ventana no hay vsync: no girar al 100 % de CPU
	modo = "servidor"
	if ruta == "user://partida.json": ruta = ProjectSettings.globalize_path("user://mundo_servidor.json")   # sin --guardado
	var g = J.cargar(ruta)
	if g == null: g = J.nueva(o.get("semilla", 1), "Anfitrión", [0, 0, 0], "viajero")
	var s = Srv.new()
	s.name = "Red"
	s.j = g
	s.ruta = ruta
	s.puerto = o.get("puerto", Srv.PUERTO)
	s.duracion = o.get("duracion", 0.0)
	s.ruta_registro = o.get("registro", "")
	red = s
	get_tree().root.add_child.call_deferred(s)
	print("Linde: servidor sin ventana en el puerto %d · mundo %s" % [s.puerto, ruta])

func _alojar() -> void:
	var g = J.cargar(ruta)
	if g == null:
		g = J.nueva(randi() % 100000, cr.nombre, [cr.piel, cr.pelo, cr.ropa], "viajero")
		g.guardar(ruta)
	var s = Srv.new()
	s.name = "Red"
	s.j = g
	s.local = J.LOCAL
	get_tree().root.add_child(s)
	if s.error != "":
		s.queue_free()
		menu_msg = s.error
		return
	red = s
	j = g
	modo = "juego"
	j.aviso("Alojando el mundo en el puerto %d." % s.puerto)

func _abrir_unirse() -> void:
	var cfg := ConfigFile.new()
	cfg.load(RED_CFG)
	un.dir = cfg.get_value("red", "dir", "127.0.0.1:%d" % Srv.PUERTO)
	un.nombre = cfg.get_value("red", "nombre", cr.nombre)
	un.clave = cfg.get_value("red", "clave", Crypto.new().generate_random_bytes(9).hex_encode())   # token del primer ingreso
	un.campo = 0
	modo = "unirse"

func _tecla_unirse(e: InputEvent) -> void:
	if modo == "conectando":
		if e.keycode == KEY_ESCAPE: _menu_inicial()
		return
	var k: String = ["dir", "nombre", "clave", ""][un.campo]
	match e.keycode:
		KEY_ESCAPE: _menu_inicial()
		KEY_UP: un.campo = (un.campo + 3) % 4
		KEY_DOWN, KEY_TAB: un.campo = (un.campo + 1) % 4
		KEY_BACKSPACE: if k != "": un[k] = un[k].substr(0, un[k].length() - 1)
		KEY_ENTER, KEY_KP_ENTER: _unirse()
		_:
			if k != "" and e.unicode >= 32 and e.unicode != 127 and un[k].length() < 64: un[k] += char(e.unicode)

func _unirse() -> void:
	var partes: PackedStringArray = un.dir.strip_edges().rsplit(":", true, 1)
	var c = Cli.new()
	c.name = "Red"
	c.direccion = partes[0] if partes[0] != "" else "127.0.0.1"
	c.puerto = int(partes[1]) if partes.size() > 1 and partes[1].is_valid_int() else Srv.PUERTO
	c.nombre = un.nombre.strip_edges()
	c.clave = un.clave
	c.look = [cr.piel, cr.pelo, cr.ropa]
	var cfg := ConfigFile.new()
	for kk in ["dir", "nombre", "clave"]: cfg.set_value("red", kk, un[kk])
	cfg.save(RED_CFG)
	c.listo.connect(func():
		j = c.j
		panel = ""
		modo = "juego")
	c.fallo.connect(func(motivo: String):
		j = null
		_menu_inicial()
		menu_msg = motivo)
	c.interaccion.connect(_tras_interactuar)
	red = c
	modo = "conectando"
	menu_msg = ""
	get_tree().root.add_child(c)

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
		KEY_F: if panel == "forja": _cerrar()
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
			_l("INVENTARIO  %d/%d  ·  Nv %d  Daño %d  Def %d  Vida %d  Vel x%.2f" % [Inv.slots(j.jug().inv), st.slots, j.nivel(), st.dmg, st.def, st.hp, st.vel])
			_l("Bono de set: " + _txt_bono(j.bono_set()))
			_l("— Equipado  (F: forja para mejorar o cambiar piedra) —")
			for r in C.RANURAS:
				var q: String = j.jug().equipo.get(r, "")
				_l("%s: %s" % [_n_ranura(r), (Eq.info(q).n + "  (Enter: quitar)") if q != "" else "—"], func(): j.desequipar(r))
			_l("— Mochila —")
			var ks: Array = j.jug().inv.keys()
			ks.sort()
			for k in ks:
				var it: Dictionary = Eq.info(k)
				var cura: bool = it.has("cura")
				var eq: bool = it.has("equipo")
				_l("%s  x%d%s" % [it.n, j.jug().inv[k], "   (usar)" if cura else ("   (equipar: %s)" % _n_ranura(it.equipo) if eq else "")], func():
					if cura: j.usar(k)
					elif eq: j.equipar(k))
			if ks.is_empty(): _l("(vacío)")
			if not j.jug().pendientes.is_empty(): _l("Pendiente de recibir: " + Hud.J_txt(j.jug().pendientes))
		"forja":
			var inv: Dictionary = j.jug().inv
			var jm: Dictionary = Eq.joya_mejora()
			_l("FORJA  ·  %s: %d  ·  la mejora siempre sube; la piedra anterior se pierde" % [jm.nombre, inv.get(jm.id, 0)])
			var piezas: Array = []
			for r in C.RANURAS:
				var q: String = j.jug().equipo.get(r, "")
				if not Eq.leer(q).is_empty(): piezas.append([q, "puesta"])
			var ks: Array = inv.keys()
			ks.sort()
			for k in ks: if not Eq.leer(k).is_empty(): piezas.append([k, "mochila"])
			if piezas.is_empty(): _l("(no tienes piezas de set)")
			for pz in piezas:
				var k: String = pz[0]
				_l("%s  (%s)" % [Eq.info(k).n, pz[1]])
				var m: Dictionary = Eq.mejorar(k)
				if m.ok: _l("    Mejorar a +%d  (cuesta %s)" % [Eq.leer(m.nueva).nivel, Hud.J_txt(m.coste)], func(): j.mejorar(k))
				for v in Eq.datos().variantes:
					var c: Dictionary = Eq.cambiar_variante(k, v)
					if not c.ok: continue
					var pid: String = c.coste.keys()[0]
					if inv.get(pid, 0) < 1: continue          # solo las piedras que tienes
					_l("    Engarzar %s -> %s  (tienes %d)" % [Eq.info(pid).n, Eq.datos().variantes[v].nombre, inv.get(pid, 0)], func(): j.engarzar(k, v))
		"craft":
			_l("FABRICAR  ·  estaciones: mesa y horno a ≤2 celdas")
			var rs: Dictionary = Eq.recetas()
			for id in rs:
				var r: Dictionary = rs[id]
				var listo: bool = Inv.tiene(j.jug().inv, r.ent) and (r.hab == "" or j.jug().hab.has(r.hab)) and j.estacion_cerca(r.est)
				var nota := ""
				if r.hab != "" and not j.jug().hab.has(r.hab): nota += " [req. %s]" % C.HAB[r.hab].n
				if r.est != "": nota += " [%s]" % r.est
				_l("%s %s  <-  %s%s" % ["[ok]" if listo else "[--]", r.n, Hud.J_txt(r.ent), nota], func(): j.fabricar(id))
		"hab":
			_l("HABILIDADES  ·  puntos libres: %d  ·  nivel %d" % [j.puntos_libres(), j.nivel()])
			for id in C.HAB:
				var h: Dictionary = C.HAB[id]
				var req := ""
				for r in h.req: req += " " + C.HAB[r].n
				var e := "APRENDIDA" if j.jug().hab.has(id) else "coste %d · nv %d%s" % [h.coste, h.niv, (" · req:" + req) if req != "" else ""]
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
			for k in j.jug().inv: _l("%s x%d  → cofre" % [Eq.info(k).n, j.jug().inv[k]], func(): j.mover_cofre(cofre_id, k, true))
			_l("— Cofre —")
			var cf: Dictionary = j.d.cofres.get(cofre_id, {"inv": {}})
			for k in cf.inv: _l("%s x%d  → inventario" % [Eq.info(k).n, cf.inv[k]], func(): j.mover_cofre(cofre_id, k, false))
		"pausa":
			_l("PAUSA")
			_l("Continuar", func(): _cerrar())
			_l("Guardar", func(): j.aviso("Guardado." if j.guardar(ruta) else "No se pudo guardar."); _cerrar())
			_l("Guardar y salir al menú", func(): j.guardar(ruta); _cerrar(); j = null; _menu_inicial())

func _n_ranura(r: String) -> String:
	return str(Eq.datos().ranuras.get(r, {}).get("n", r.capitalize()))

func _txt_bono(b: Dictionary) -> String:
	if b.familia == "": return "ninguno (2+ piezas de una familia)"
	var l: Array = []
	for k in [["def_pct", "def"], ["hp_pct", "vida"], ["vel_pct", "vel"]]:
		if b[k[0]] > 0.0: l.append("+%d %% %s" % [roundi(b[k[0]] * 100.0), k[1]])
	return "%s (%d piezas): %s" % [Eq.datos().familias[b.familia].nombre, b.piezas, ", ".join(l)]

func _interactuar() -> void:
	_tras_interactuar(j.interactuar())

# También lo llama red_cliente cuando llega la respuesta del servidor.
func _tras_interactuar(r: Dictionary) -> void:
	if not r.ok or j == null or panel != "": return
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
	delta = minf(delta, 1.0 / 30.0)    # evita saltos mayores que la caja de pies
	activa = Mundo.dir_cardinal(_held(), activa)
	if build:
		if activa != Vector2i.ZERO: j.mira = activa
	else:
		j.mover_pj(activa, delta)
		if Input.is_key_pressed(KEY_SPACE): j.accion()
	if auto_ataque >= 0.0:
		auto_ataque += delta
		if auto_ataque >= AUTO_ATAQUE_S and j.combate.atacar(j.mira): auto_ataque = 0.0
	if red == null: j.tick(delta)    # con red, el mundo lo avanza red_servidor (también con paneles abiertos)
	t_anim = t_anim + delta if activa != Vector2i.ZERO else 0.0
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
		if cs.get("t", "") == "cama": return "E: dormir" if cs.get("dueno", "") == J.LOCAL else ("Cama de otro jugador" if cs.propia else "Cama de Maren")
	return ""

func _frame() -> int:
	return 0 if activa == Vector2i.ZERO else int(t_anim / P.PASO_S) % 4

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
	if red != null:
		for o in red.otros_jugadores(): lista.append([o.pies.y, "otro", o])
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
			"otro": _dibujar_otro(e[2])
			"enemigo": _dibujar_enemigo(e[2])
			"obj": _dibujar_obj(e[2])
			"constr": _dibujar_constr(e[2])
			"fachada": Arte.fachada(self, Mundo.CASA, Mundo.PUERTA_C, 0.25 if Mundo.CASA.has_point(Mundo.celda_de(j.pies)) else 1.0)
	var dentro := Mundo.CASA.has_point(Mundo.celda_de(j.pies))
	Arte.tejado(self, Mundo.CASA, 0.25 if Mundo.CASA.has_point(Mundo.celda_de(j.pies)) else 1.0)
	if build:
		var c: Vector2i = Mundo.celda_de(j.pies) + j.mira
		var id: String = C.ORDEN_CONSTR[pieza_i]
		var bien: bool = m.puede_poner(c) == "" and not j.ocupada(c) and Inv.tiene(j.jug().inv, C.CONSTR[id].coste)
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
	_anim = j.anim_pj(activa != Vector2i.ZERO, t_anim)
	if j.combate.inv_t > 0.0 and int(j.combate.inv_t * 20.0) % 2 == 0: return
	var origen: Vector2 = (j.pies - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	draw_rect(Rect2(origen + Vector2(3, 22), Vector2(10, 3)), Color(0, 0, 0, 0.3))
	var vis := _equipo_visible(j.jug().equipo, j.jug().inv.has("espada_hierro"))
	if usar_arte and arte_eq.disponible(): arte_eq.dibujar(self, j.pies, j.mira, _cuadro_arte(_anim), vis, j.jug().look, _anim.estado)
	elif usar_arte and capas_pj.disponible(): capas_pj.dibujar(self, j.pies, j.mira, _frame(), vis, _anim.estado, _anim.cuadro)
	else: Apar.dibujar(self, origen, j.mira, _frame(), j.jug().look)
	if auto_ataque >= 0.0:
		var fase: String = j.combate.est
		var txt := fase if _anim.estado != "ataque" else "%s %d %s" % [fase, _anim.cuadro, POSES_ATAQUE[posmod(int(_anim.cuadro), 4)]]
		draw_string(ThemeDB.fallback_font, origen + Vector2(-18, -26), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		print("AUTOATQ cuadro_proceso=%d fase=%s estado=%s cuadro=%d" % [Engine.get_process_frames(), fase, _anim.estado, _anim.cuadro])

## Cuadro para el arte por capas: caminata y ataque animan; el resto usa el cuadro 0.
static func _cuadro_arte(an: Dictionary) -> int:
	return int(an.cuadro) if an.estado in ["caminar", "ataque"] else 0

# Equipo.visible (ranura, arquetipo, familia, variante, paleta, delta) + la espada si se lleva en el inventario.
static func _equipo_visible(equipo: Dictionary, espada: bool) -> Array:
	var v: Array = Eq.visible(equipo)
	if espada: v.append({"ranura": "espada", "item": "espada_hierro", "paleta": Eq.datos().paletas.get(str(C.ITEMS.espada_hierro.get("paleta", "")), {})})
	return v

# Otro jugador (red): su apariencia y su equipo real (arte por capas si está activo; si no, procedural) y su nombre.
func _dibujar_otro(o: Dictionary) -> void:
	var origen: Vector2 = (o.pies - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	draw_rect(Rect2(origen + Vector2(3, 22), Vector2(10, 3)), Color(0, 0, 0, 0.3))
	var cuadro: int = _cuadro_arte(o)
	if usar_arte and arte_eq.disponible():
		var eq: Dictionary = o.get("equipo") if o.get("equipo") is Dictionary else {}
		arte_eq.dibujar(self, o.pies, o.mira, cuadro, _equipo_visible(eq, o.get("espada", false) == true), o.look, str(o.estado))
	else: Apar.dibujar(self, origen, o.mira, int(o.cuadro) if o.estado == "caminar" else 0, o.look)
	draw_string(ThemeDB.fallback_font, origen + Vector2(-6, -4), o.nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f1c40f"))

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
	var t: float = e.tam
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	var col: Color = {"slime": Color("5fd0a0"), "guardian": Color("7d6b9a"), "ciervo": Color("a0784a")}[e.tipo]
	if e.est == "aviso": col = col.lightened(0.35)
	var o: Vector2 = e.pos - Vector2(t / 2.0, t)
	draw_rect(Rect2(e.pos - Vector2(t / 2.0, 3), Vector2(t, 4)), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(o + Vector2(0, t * 0.3), Vector2(t, t * 0.7)), col)
	draw_rect(Rect2(o + Vector2(t * 0.1, 0), Vector2(t * 0.8, t * 0.4)), col)
	draw_rect(Rect2(o + Vector2(t * 0.25, t * 0.35), Vector2(2, 3)), Color.BLACK)
	draw_rect(Rect2(o + Vector2(t * 0.65, t * 0.35), Vector2(2, 3)), Color.BLACK)
	if e.tipo == "ciervo":
		draw_rect(Rect2(o + Vector2(-2, -6), Vector2(3, 8)), Color("e8dcc0"))
		draw_rect(Rect2(o + Vector2(t - 1, -6), Vector2(3, 8)), Color("e8dcc0"))
	if e.hp < def.hp:
		draw_rect(Rect2(o + Vector2(0, -6), Vector2(t, 3)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(o + Vector2(0, -6), Vector2(t * float(e.hp) / def.hp, 3)), Color("e74c3c"))

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
