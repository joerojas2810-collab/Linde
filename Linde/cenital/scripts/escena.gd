extends Node2D
# Presentación y entrada. Toda regla vive en Juego; aquí solo se pide y se muestra.
# Args tras "--": --guardado=ruta · --nueva=SEMILLA (salta menús) · --panel=inv|forja|craft|hab|mis · --ir=x,y (celda, depuración)
# Depuración: --pantalla=creador|unirse abre esa pantalla. Del arte (con --nueva): --equipo=<familia>:<variante|sin_piedra> (set completo
# + escudo + espada) · --mira=frente|derecha|espalda|izquierda · --auto-ataque (el jugador local ataca cada
# AUTO_ATAQUE_S s, con el ciclo real de combate; muestra fase/pose sobre el PJ e imprime una línea por cuadro dibujado)
# Servidor sin ventana: --servidor [--puerto=7777] [--guardado=ruta] [--semilla=N] [--duracion=s] [--registro=ruta.json]
const Aspecto = preload("res://scripts/aspecto.gd")
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const Mundo = preload("res://scripts/mundo.gd")
const J = preload("res://scripts/juego.gd")
const Hud = preload("res://scripts/hud_vivo.gd")
const MundoArte = preload("res://scripts/arte_entornos.gd")
const ActoresArte = preload("res://scripts/actores_arte.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
const Eq = preload("res://scripts/equipo.gd")
const ArteEq = preload("res://scripts/arte_equipo.gd")
var actores = ActoresArte.new()   # E03: enemigos, residuos y efectos de combate
var arte_mundo = MundoArte.new()   # E04+E05: terreno, objetos, casa (res://arte/mundo)
var arte_eq = ArteEq.new()   # base + equipo por índices (res://arte/equipo); preferido si está completo
const MIRA := {"frente": Vector2i.DOWN, "derecha": Vector2i.RIGHT, "espalda": Vector2i.UP, "izquierda": Vector2i.LEFT}
const COLORES := {Mundo.T.PASTO: Color("5a9b4a"), Mundo.T.CAMINO: Color("c9b27a"), Mundo.T.AGUA: Color("3f7fbf"),
	Mundo.T.PARED: Color("a8794f"), Mundo.T.SUELO: Color("8a6a4a"), Mundo.T.PUERTA: Color("5b3a22"),
	Mundo.T.RUINA: Color("8c8a86"), Mundo.T.MURO_RUINA: Color("5e5c63")}
const AUTOGUARDADO_S := 30.0
const AUTO_ATAQUE_S := 0.8      # depuración (--auto-ataque): intervalo entre ataques; el ciclo dura 0,45 s
const POSES_ATAQUE := ["prep", "antic", "impac", "recup"]   # preparado, anticipación, impacto, recuperación
var auto_ataque := -1.0         # < 0: desactivado; si no, tiempo acumulado hasta el próximo ataque

var j
var modo := "menu"
var panel := ""
var lineas: Array = []
var acc: Array = []
var iconos: Array = []   # ruta de icono (res://arte/interfaz) por línea de panel; "" = sin icono
var sel := 0
var dialogo_txt := ""
var dialogo_nombre := ""
var cofre_id := ""
var forma_plano := "espada"
var build := false
var pieza_i := 0
var activa := Vector2i.ZERO
var t_anim := 0.0
var debug := false
var _anim := {"estado": "reposo", "cuadro": 0}
var pista := ""
var ayuda_visible := false
var rotulos: Array = []
var cuerpos_rotulo: Array = []
var cam := Camera2D.new()
var hud := Hud.new()
var ruta := "user://partida.json"
var auto_t := 0.0
var menu_items: Array = []
var menu_sel := 0
var menu_msg := ""
var cr := {"nombre": "Viajero", "piel": 0, "pelo": 1, "ropa": 0, "identidad": 0, "peinado": 0, "pantalon": 0, "botas": 0, "cinturon": 0, "campo": 0}
var destino_creador := "juego"
var red: Node = null          # red_servidor (alojando) o red_cliente (unido); null = un jugador sin red
var un := {"dir": "127.0.0.1:7777", "nombre": "", "clave": "", "campo": 0}   # formulario «Unirse»
const RED_CFG := "user://red.cfg"

func _ready() -> void:
	var nueva := -1
	var panel_ini := ""
	var ir := ""
	var pantalla_ini := ""
	var srv := {}
	var dbg := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--guardado="): ruta = a.substr(11)
		elif a.begins_with("--nueva="): nueva = int(a.substr(8))
		elif a.begins_with("--panel="): panel_ini = a.substr(8)
		elif a.begins_with("--ir="): ir = a.substr(5)
		elif a.begins_with("--pantalla="): pantalla_ini = a.substr(11)
		elif a.begins_with("--equipo="): dbg["equipo"] = a.substr(9)
		elif a.begins_with("--mira="): dbg["mira"] = a.substr(7)
		elif a == "--auto-ataque": dbg["auto_ataque"] = true
		elif a == "--servidor": srv["si"] = true
		elif a.begins_with("--puerto="): srv["puerto"] = int(a.substr(9))
		elif a.begins_with("--semilla="): srv["semilla"] = int(a.substr(10))
		elif a.begins_with("--duracion="): srv["duracion"] = float(a.substr(11))
		elif a.begins_with("--registro="): srv["registro"] = a.substr(11)
	if srv.has("si"): return _servidor_sin_ventana(srv)
	arte_mundo.cargar()
	var luz := load("res://arte/interfaz/nuevos/luz_ambiente.gdshader") as Shader   # E06: tinte nocturno solo del mundo; el HUD va en su CanvasLayer
	if luz == null: push_error("Arte faltante: res://arte/interfaz/nuevos/luz_ambiente.gdshader")
	else:
		var mat := ShaderMaterial.new()
		mat.shader = luz
		material = mat
	cam.zoom = Vector2(P.ZOOM, P.ZOOM)
	cam.limit_left = -Mundo.Terreno.LIMITE * P.CELDA
	cam.limit_top = -Mundo.Terreno.LIMITE * P.CELDA
	cam.limit_right = Mundo.Terreno.LIMITE * P.CELDA
	cam.limit_bottom = Mundo.Terreno.LIMITE * P.CELDA
	add_child(cam)
	var capa := CanvasLayer.new()
	hud.esc = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(hud)
	add_child(capa)
	get_tree().auto_accept_quit = false
	_menu_inicial()
	if pantalla_ini == "creador": modo = "creador"       # depuración/capturas: abre la pantalla sin teclear
	elif pantalla_ini == "unirse": _abrir_unirse()
	if nueva >= 0:
		j = J.nueva(nueva, cr.nombre, Aspecto.de_creador(cr))
		modo = "juego"
		if ir != "":
			var p := ir.split(",")
			j.pies = Mundo.pies_de_celda(Vector2i(int(p[0]), int(p[1])))
		_depurar_arte(dbg)
		if panel_ini != "": _abrir(panel_ini)

# Solo depuración/capturas: activa el arte, pone un set completo de una familia (+ escudo y espada) y la orientación.
func _depurar_arte(dbg: Dictionary) -> void:
	if dbg.has("equipo"):
		var p: PackedStringArray = str(dbg.equipo).split(":")
		var fam: String = p[0]
		var v: String = p[1] if p.size() > 1 and p[1] != "sin_piedra" else ""
		for r in Eq.datos().familias.get(fam, {}).get("piezas", []):
			var k := Eq.construir(fam, str(r), v, 0)
			if not Eq.leer(k).is_empty(): j.jug().equipo[r] = k
		j.jug().equipo["escudo"] = "escudo_madera"
		j.jug().equipo["arma"] = "espada_hierro"
	if MIRA.has(dbg.get("mira", "")): j.mira = MIRA[dbg.mira]
	if dbg.has("auto_ataque"): auto_ataque = 0.0

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
		KEY_G: _abrir("desarrollo")
		KEY_C: _abrir("craft")
		KEY_K: _abrir("hab")
		KEY_J: _abrir("mis")
		KEY_B: build = not build
		KEY_H: ayuda_visible = not ayuda_visible
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
					if g == null: menu_msg = J.mensaje_carga(J.ultimo_error)
					else:
						for id in g.rt.keys(): if id != J.LOCAL: g.salir(id)   # mundo alojado: los demás no están
						j = g
						modo = "juego"
				1:
					destino_creador = "juego"
					cr.campo = 0
					modo = "creador"
				2:
					if not FileAccess.file_exists(ruta) and not FileAccess.file_exists(ruta + ".bak"):
						destino_creador = "alojar"
						cr.campo = 0
						modo = "creador"
					else: _alojar()
				3: _abrir_unirse()
				4: get_tree().quit()

func _tecla_creador(e: InputEvent) -> void:
	var total: int = Aspecto.CAMPOS.size() + 2
	match e.keycode:
		KEY_ESCAPE:
			if destino_creador == "unirse": modo = "unirse"
			else: _menu_inicial()
			return
		KEY_UP: cr.campo = posmod(cr.campo - 1, total)
		KEY_DOWN, KEY_TAB: cr.campo = posmod(cr.campo + 1, total)
		KEY_LEFT, KEY_RIGHT:
			if cr.campo > 0 and cr.campo < total - 1:
				var i: int = cr.campo - 1
				var k: String = Aspecto.CAMPOS[i]
				cr[k] = posmod(cr[k] + (1 if e.keycode == KEY_RIGHT else -1), Aspecto.limites()[i])
		KEY_BACKSPACE: if cr.campo == 0: cr.nombre = cr.nombre.substr(0, cr.nombre.length() - 1)
		KEY_ENTER, KEY_KP_ENTER:
			if cr.campo == total - 1:
				if destino_creador == "unirse":
					un.nombre = cr.nombre
					modo = "unirse"
					return
				j = J.nueva(randi() % 100000, cr.nombre, Aspecto.de_creador(cr))
				j.guardar(ruta)
				modo = "juego"
				if destino_creador == "alojar": _alojar()
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
	if g == null and not J.ultimo_error.is_empty():     # nunca sustituir en silencio un mundo con otras reglas
		printerr("Linde: " + J.mensaje_carga(J.ultimo_error))
		get_tree().quit(1)
		return
	if g == null: g = J.nueva(o.get("semilla", 1), "Anfitrión", [0, 0, 0])
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
	if g == null and not J.ultimo_error.is_empty():
		menu_msg = J.mensaje_carga(J.ultimo_error)
		return
	if g == null:
		g = J.nueva(randi() % 100000, cr.nombre, Aspecto.de_creador(cr))
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
	if e.keycode == KEY_P and un.campo == 3:
		cr.nombre = un.nombre
		cr.campo = 0
		destino_creador = "unirse"
		modo = "creador"
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
	c.look = Aspecto.de_creador(cr)
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
	if panel=="inv" and e.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
		_navegar_inventario(e)
		return
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
		KEY_G: _cerrar()
		KEY_UP:
			sel -= 1
			_sel_valida(-1)
		KEY_DOWN:
			sel += 1
			_sel_valida(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			if sel < acc.size() and acc[sel] != null:
				var antes := sel
				var pagina := panel
				acc[sel].call()
				if panel != "":
					_armar()
					if panel == pagina: sel = mini(antes, lineas.size() - 1)
					_sel_valida(-1 if panel == pagina else 1)

func _sel_valida(paso: int) -> void:
	if lineas.is_empty(): return
	if panel in ["materiales","practica","mis"]:
		sel=clampi(sel,1,maxi(1,lineas.size()-1))
		return
	sel = clampi(sel, 0, lineas.size() - 1)
	var n := 0
	while acc[sel] == null and n < lineas.size():
		sel = (sel + paso + lineas.size()) % lineas.size()
		n += 1

func _l(t: String, f = null, ic: String = "") -> void:
	lineas.append(t)
	acc.append(f)
	iconos.append(ic)

## Icono de un ítem del inventario (piezas de set por su ranura; desconocido = sin icono, sin sustituto).
func _ic(k: String) -> String:
	var artesanal: Dictionary = Eq.Artesania.leer(k)
	if not artesanal.is_empty(): return hud.ui.ruta_icono("espada_hierro" if artesanal.forma=="espada" else "", str(Eq.info(k).equipo))
	var l: Dictionary = Eq.leer(k)
	return hud.ui.ruta_icono(k, str(l.get("ranura", "")) if not l.is_empty() else "")

## Divide explicaciones por ancho real para que el atlas no desborde el panel.
func _parrafo(texto: String) -> void:
	var linea := ""
	for palabra in texto.split(" "):
		if hud.ui.ancho_texto(linea + " " + palabra,16)>780.0:
			_l("  " + linea)
			linea=palabra
		else: linea+=(" " if linea!="" else "")+palabra
	if linea!="": _l("  "+linea)

func _cambiar_forma() -> void:
	var formas: Array=Eq.Artesania.reglas().formas.keys()
	forma_plano=formas[(formas.find(forma_plano)+1)%formas.size()]
	_abrir("planos")

func _armar() -> void:
	lineas = []
	acc = []
	iconos = []
	var st: Dictionary = j.stats()
	if panel in ["planos","practica","laminados","saberes"] and not j.autonomia.desarrollo.activa(): panel="desarrollo"
	match panel:
		"inv":
			_l("INVENTARIO  %d/%d  ·  Nv %d  Daño %d  Def %d  Vida %d  Vel x%.2f" % [Inv.slots(j.jug().inv), st.slots, j.nivel(), st.dmg, st.def, st.hp, st.vel])
			_l("Bono de set: " + _txt_bono(j.bono_set()))
			_l("— Equipado  (F: forja para mejorar o cambiar piedra) —")
			for r in C.RANURAS:
				var q: String = j.jug().equipo.get(r, "")
				_l("%s: %s" % [_n_ranura(r), (Eq.info(q).n + "  (Enter: quitar)") if q != "" else "—"], func(): j.desequipar(r), hud.ui.ruta_icono(q, r))
			_l("— Mochila —")
			var ks: Array = j.jug().inv.keys()
			ks.sort()
			for k in ks:
				var it: Dictionary = Eq.info(k)
				var cura: bool = it.has("cura")
				var eq: bool = it.has("equipo")
				_l("%s  x%d%s" % [it.n, j.jug().inv[k], "   (usar)" if cura else ("   (equipar: %s)" % _n_ranura(it.equipo) if eq else "")], func():
					if cura: j.usar(k)
					elif eq: j.equipar(k), _ic(k))
			if ks.is_empty(): _l("(vacío)")
			if not j.jug().pendientes.is_empty(): _l("Pendiente de recibir: " + Hud.J_txt(j.jug().pendientes))
		"desarrollo":
			_l("TALLER Y DESCUBRIMIENTOS")
			_l("Materiales: dónde encontrarlos y para qué sirven", func(): _abrir("materiales"))
			if not j.autonomia.desarrollo.activa():
				_parrafo("Los nuevos planos y la práctica están disponibles en la partida de prueba de autonomía.")
			else:
				_l("Planos: crear equipo con lo que aprendiste", func(): _abrir("planos"))
				_l("Materiales elaborados: experimentar con laminados",func():_abrir("laminados"))
				_l("Práctica: ver técnicas y especializaciones", func(): _abrir("practica"))
				_l("Saberes: pedir y enseñar técnicas", func(): _abrir("saberes"))
				_l("— OBRAS QUE OFRECEN LOS HABITANTES —")
				for nid in j.habitantes.ids:
					for pieza in j.autonomia.estado(nid).inv:
						if Eq.Artesania.leer(str(pieza)).is_empty(): continue
						_l(j.habitantes.fichas[nid].n + ": " + Eq.info(pieza).n)
						_parrafo("Pide: " + Hud.J_txt(Eq.Artesania.receta(pieza).ent))
						_l("  Intercambiar materiales por esta pieza (requiere cercanía)", func(): j.comprar_artefacto(nid,pieza))
			_l("Cerrar",func():_cerrar())
		"materiales":
			_l("MATERIALES DEL VALLE  ·  origen y usos")
			for mat in j.autonomia.desarrollo.materiales():
				_l("%s · llevas %d" % [mat.nombre,int(j.jug().inv.get(mat.id,0))])
				_parrafo(mat.fuente)
				_parrafo("Sirve para: " + ", ".join(mat.usos))
			_l("Volver al taller",func():_abrir("desarrollo"))
		"planos":
			_l("PLANOS  ·  el material, la técnica y la pericia definen la pieza")
			_l("Cambiar forma: " + Eq.Artesania.reglas().formas[forma_plano].nombre,func():_cambiar_forma())
			var planos: Array=j.autonomia.desarrollo.planos(j.actor_desarrollo(),forma_plano)
			if planos.is_empty(): _parrafo("Obtén materiales del valle para descubrir sus primeros planos. Las técnicas especializadas se piden a quien las conoce (Saberes) y se aplican ampliando tu taller.")
			for clave in planos:
				var it: Dictionary=Eq.info(clave)
				_l(it.n)
				_l("  Daño %d · Defensa %d · Vida %d · Velocidad %+.2f" % [it.dmg,it.def,it.hp,it.vel])
				_parrafo("Materiales: " + Hud.J_txt(Eq.Artesania.receta(clave).ent))
				_l("  Fabricar junto a una mesa de trabajo",func():j.fabricar_artefacto(clave),_ic(clave))
			_l("Volver al taller",func():_abrir("desarrollo"))
		"saberes":
			_l("SABERES  ·  técnicas y procesos que se aprenden de otros")
			var dv=j.autonomia.desarrollo
			var yo: String=j.actor_desarrollo()
			var propios: Array=[]
			for id in dv.catalogo(): if dv.tiene_saber(yo,id): propios.append(dv.catalogo()[id].nombre)
			propios.sort()
			_parrafo("Conoces: " + (", ".join(propios) if not propios.is_empty() else "solo fabricación simple"))
			var hay_lecciones := false
			for nid in j.habitantes.ids:
				var otro: String="npc:"+nid
				var quien: String=j.habitantes.fichas[nid].n
				for id in dv.catalogo():
					var saber: String=dv.catalogo()[id].nombre
					if dv.tiene_saber(otro,id) and not dv.tiene_saber(yo,id):
						hay_lecciones=true
						_l("  Pedir a %s que te enseñe: %s (requiere cercanía)" % [quien,saber],func():j.pedir_saber(nid,id))
					elif dv.tiene_saber(yo,id) and not dv.tiene_saber(otro,id):
						hay_lecciones=true
						_l("  Enseñar a %s: %s (requiere cercanía)" % [quien,saber],func():j.ensenar_saber(nid,id))
			if not hay_lecciones: _parrafo("Nadie tiene algo que enseñarte ni necesita lo que sabes.")
			_l("Volver al taller",func():_abrir("desarrollo"))
		"laminados":
			_l("MATERIALES ELABORADOS  ·  conocimiento y componentes reales")
			_parrafo("Conoce los componentes y alcanza rango 1 de artesanía del hierro. Un horno permite elaborar laminados para nuevos planos.")
			for material in Eq.Artesania.combinaciones():
				var receta: Dictionary=Eq.Artesania.receta_material(material)
				_l(receta.n)
				_parrafo("Componentes: "+Hud.J_txt(receta.ent))
				_l("  Elaborar junto a un horno",func():j.refinar_material(material))
			_l("Volver al taller",func():_abrir("desarrollo"))
		"practica":
			_l("PRÁCTICA Y TÉCNICAS  ·  se aprenden jugando")
			var d=j.autonomia.desarrollo
			var actor: String=j.actor_desarrollo()
			for disciplina in ["recoleccion","artesania","construccion","combate"]:
				_l("%s · %d acciones · rango %d" % [{"recoleccion":"Recolección","artesania":"Artesanía","construccion":"Construcción","combate":"Combate"}[disciplina],int(d.estado(actor).practica.get(disciplina,0)),d.rango(actor,disciplina)])
			for material in d.estado(actor).materiales:
				_l("Oficio de " + Eq.Artesania.material(material).nombre + " · rango %d" % d.rango(actor,"artesania",material))
				for tecnica in d.cfg.tecnicas:
					var t: Dictionary=d.cfg.tecnicas[tecnica]
					_l("  Técnica %s: rango %d y %d suelos de taller" % [t.nombre,int(t.rango),d.suelo_requerido(actor,tecnica)])
			_parrafo("La práctica mejora las piezas futuras. No altera el equipo ya fabricado ni gasta puntos del árbol de habilidades.")
			_l("Volver al taller",func():_abrir("desarrollo"))
		"forja":
			var inv: Dictionary = j.jug().inv
			var jm: Dictionary = Eq.joya_mejora()
			_l("FORJA  ·  %s: %d  ·  la mejora siempre sube; la piedra anterior se pierde" % [jm.nombre, inv.get(jm.id, 0)])
			_l("Taller: materiales, planos y técnicas (G)",func():_abrir("desarrollo"))
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
				_l("%s  (%s)" % [Eq.info(k).n, pz[1]], null, _ic(k))
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
				_l("%s %s  <-  %s%s" % ["[ok]" if listo else "[--]", r.n, Hud.J_txt(r.ent), nota], func(): j.fabricar(id), _ic(str(r.sal.keys()[0]) if not r.sal.is_empty() else ""))
		"hab":
			_l("HABILIDADES  ·  puntos libres: %d  ·  nivel %d" % [j.puntos_libres(), j.nivel()])
			if j.autonomia.desarrollo.activa(): _l("Ver práctica y técnicas aprendidas",func():_abrir("practica"))
			for id in C.HAB:
				var h: Dictionary = C.HAB[id]
				var req := ""
				for r in h.req: req += " " + C.HAB[r].n
				var e := "APRENDIDA" if j.jug().hab.has(id) else "coste %d · nv %d%s" % [h.coste, h.niv, (" · req:" + req) if req != "" else ""]
				_l("[%s] %s  (%s)" % [h.rama.substr(0, 3), h.n, e], func(): j.aprender(id))
		"mis":
			_l("SOCIEDAD DEL VALLE  ·  necesidades, acuerdos y grupos" if j.autonomia.activa() else "MISIONES  ·  las de capítulo se piden y entregan hablando con quien las da")
			if j.autonomia.activa():
				_l("— HABITANTES: necesidades reales (Enter ayuda; requiere cercanía) —")
				for nid in j.habitantes.ids:
					if j.autonomia.perfil(nid).is_empty(): continue
					var n: Dictionary = j.autonomia.estado(nid)
					var falta: Dictionary = j.autonomia.necesidad(nid)
					_l("%s · hambre %d/100 · %s" % [j.habitantes.fichas[nid].n, int(n.hambre), str(n.plan.get("act", "rutina"))])
					if j.autonomia.sociedad.activa(): _l("  " + j.autonomia.sociedad.texto_trabajo(nid))
					if j.autonomia.sociedad.activa():
						_l("  Grupo: " + j.autonomia.sociedad.nombre_grupo(j.autonomia.sociedad.grupo_de(nid)) + " · " + str(n.get("objetivo", "buscar oportunidades")))
					var identidad: Dictionary = j.autonomia.perfil(nid).get("identidad",{})
					if not identidad.is_empty(): _parrafo("Quiere " + str(identidad.objetivo))
					if j.autonomia.sociedad.activa():
						var vida: String = j.autonomia.sociedad.arraigo.resumen(nid)
						if vida != "": _parrafo(vida)
					if j.autonomia.sociedad.activa():
						for otro in j.habitantes.ids:
							if otro==nid: continue
							var confianza: int = j.autonomia.sociedad.confianza(nid,otro)
							if confianza<0: _parrafo("Desconfía de %s (%d). Los incumplimientos y robos pueden cerrar intercambios." % [j.habitantes.fichas[otro].n,confianza])
					_parrafo("Reservas: " + (Hud.J_txt(n.inv) if not n.inv.is_empty() else "vacías"))
					if j.autonomia.sociedad.activa() and not n.durabilidad.is_empty():
						var herramientas: Array = []
						for item in n.durabilidad: herramientas.append("%s %d/%d" % [C.ITEMS[item].n, n.durabilidad[item], j.autonomia.sociedad.cfg.durabilidad_herramienta])
						_l("  Usos restantes: " + ", ".join(herramientas))
					if falta.has("item"):
						_l("  Dar hasta %d %s para %s" % [falta.cantidad, C.ITEMS[falta.item].n, falta.motivo], func(): j.ayudar_habitante(nid))
						_l("  Responder que no puedo ayudar", func(): j.ayudar_habitante(nid, true))
					elif falta.has("estacion"):
						_l("  Trabajo pendiente: %s (estación %s)" % [falta.motivo, falta.estacion])
					if not n.recuerdos.is_empty():
						var recuerdo: Dictionary = n.recuerdos.back()
						_parrafo(j.autonomia.texto_recuerdo(recuerdo))
			if j.autonomia.sociedad.activa():
				var sociedad = j.autonomia.sociedad
				var observador: String = red.yo if red is Cli else J.LOCAL
				_l("— GRUPOS Y RESERVAS COMPARTIDAS —")
				for gid in sociedad.cfg.grupos:
					var g: Dictionary = sociedad.grupo(gid)
					_l("%s · relación contigo %d · %s" % [sociedad.nombre_grupo(gid), sociedad.reputacion(gid, observador), sociedad.cfg.grupos[gid].referencia])
					_l("  Aportar materiales al grupo (requiere cercanía)", func(): j.aportar_grupo(gid))
					for item in sociedad.cfg.grupos[gid].reservas:
						_l("  %s: %d / %d" % [C.ITEMS[item].n, int(g.inv.get(item, 0)), int(sociedad.cfg.grupos[gid].reservas[item])])
				_l("— VIVIENDAS Y PUESTOS —")
				for k in sociedad.habitat.datos().obras:
					var obra: Dictionary=sociedad.habitat.datos().obras[k]
					_l("Casa "+k+": "+obra.estado+(" · "+obra.motivo if obra.motivo!="" else ""))
				for puesto in j.autonomia.asentamientos.datos().puestos.values():
					_l("%s · %d residentes · %s"%[puesto.nombre,puesto.residentes.size(),puesto.estado])
					_l("  Coordenadas %s · %s"%[str(puesto.celda),Hud.J_txt(j.autonomia.asentamientos.inventario(puesto))])
				_l("— ECONOMÍA Y PROTECCIÓN —")
				_l("Valor de la fibra: %.2f · baja cuando abunda" % sociedad.valor("fibra"))
				_parrafo("Los habitantes dejan fibra sobrante al recoger bayas y usan fibra para renovar ropa y lechos. Fabrica candados en una mesa y colócalos en tus cofres.")
				_l("— ACUERDOS EN CURSO —")
				for cid in sociedad.datos().acuerdos:
					var acuerdo: Dictionary = sociedad.datos().acuerdos[cid]
					if acuerdo.estado != "activo": continue
					_l("%s y %s: %s" % [j.habitantes.fichas[acuerdo.solicitante].n, j.habitantes.fichas[acuerdo.proveedor].n, Hud.J_txt(acuerdo.bien)])
					_l("  Riesgo estimado de engaño: %.0f%% · pago %s" % [100.0*sociedad.riesgo_estafa(acuerdo.solicitante,acuerdo.proveedor) if not acuerdo.pago.is_empty() else 0.0,Hud.J_txt(acuerdo.pago)])
				_l("— LO QUE PASÓ EN EL VALLE —")
				for hecho in sociedad.datos().sucesos.slice(-6):
					_parrafo("%02d:%02d · %s" % [int(hecho.min / 60) % 24, int(hecho.min) % 60, sociedad.texto_suceso(hecho)])
				_l("Volver a los habitantes", func(): _abrir("mis"))
			for id in C.MISIONES:
				if j.autonomia.activa(): break
				var m: Dictionary = C.MISIONES[id]
				var e: String = j.estado_mision(id)
				if e == "" and not j.mision_disponible(id): continue
				var etq: String = {"": "disponible", "activa": "activa", "cumplida": "CUMPLIDA", "entregada": "entregada"}[e]
				_l("%s  [%s]  (%s)" % [m.n, etq, m.tipo], func():
					if m.da == "" and e == "": j.aceptar(id)
					elif m.da == "" and e == "cumplida": j.entregar(id))
				if e == "activa" or e == "cumplida":
					for o in m.obj: _l("      " + ("[x] " if j.objetivo_ok(o) else "[ ] ") + j.objetivo_txt(o))
			if j.vivo != null and not j.autonomia.activa():   # misiones de plantilla (story-004); el cliente de red no tiene vivo
				for mi: Dictionary in j.vivo.instancias_visibles(J.LOCAL):
					var iid: String = str(mi.iid)
					var act: bool = mi.estado == "activa"
					var ok: bool = mi.cumplida
					_l("%s  [%s]  (mundo)" % [mi.nombre, ("CUMPLIDA" if ok else "activa") if act else "disponible"], func():
						if not act: j.aceptar_mision_plantilla(iid, J.LOCAL)
						elif ok: j.entregar_mision_plantilla(iid, J.LOCAL))
					if act: _l("      " + str(mi.texto))
		"cofre":
			var info: Dictionary = j.info_cofre(cofre_id)
			_l("COFRE · " + ("cerrado con candado" if info.cerrado else "abierto"))
			_l("Dueño: " + ("tú" if info.propio else str(red.perfiles.get(info.dueno,{}).get("nombre",info.nombre)) if red is Cli else str(info.nombre)))
			if info.propio:
				for incidente in j.d.cofres.get(cofre_id,{}).get("incidentes",[]).slice(-3):
					_parrafo("Día %d: %s se llevó %s." % [int(incidente.min)/1440+1,incidente.autor,incidente.detalle])
				if not info.candado:
					_l("Instalar candado (fabrícalo con 2 lingotes y 2 fibras)", func(): j.gestionar_cofre(cofre_id,"instalar"))
				else:
					_l("Abrir para todos" if info.cerrado else "Cerrar con candado", func(): j.gestionar_cofre(cofre_id,"abrir" if info.cerrado else "cerrar"))
					_l("Retirar candado", func(): j.gestionar_cofre(cofre_id,"retirar"))
				var personas: Dictionary = (red.perfiles if red is Cli else j.d.jugadores).duplicate(true)
				for pid in info.permitidos:
					if not personas.has(pid): personas[pid]={"nombre":j.d.cofres[cofre_id].get("nombres_permitidos",{}).get(pid,"Jugador autorizado (ausente)")}
				for pid in personas:
					if pid == j.actor_desarrollo().trim_prefix("pj:"): continue
					var permitido: bool = info.permitidos.has(pid)
					_l(("Revocar acceso: " if permitido else "Permitir acceso: ") + str(personas[pid].get("nombre",pid)), func(): j.gestionar_cofre(cofre_id,"revocar" if permitido else "permitir",pid))
			if not info.acceso:
				_l("Necesitas permiso del dueño para acceder.")
			else:
				_l("— Tu inventario · Enter mueve la pila —")
				for k in j.jug().inv: _l("%s x%d → cofre" % [Eq.info(k).n, j.jug().inv[k]], func(): j.mover_cofre(cofre_id,k,true),_ic(k))
				_l("— Cofre —")
				var cf: Dictionary = j.d.cofres.get(cofre_id,{"inv":{}})
				for k in cf.inv: _l("%s x%d → inventario" % [Eq.info(k).n,cf.inv[k]],func():j.mover_cofre(cofre_id,k,false),_ic(k))
			_l("Cerrar panel",func():_cerrar())
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
			dialogo_nombre = str(j.habitantes.fichas.get(r.get("npc", ""), {}).get("n", "Habitante"))
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
	if material is ShaderMaterial: (material as ShaderMaterial).set_shader_parameter("noche", oscuridad(j.hora_dia()) / 0.5)
	actores.actualizar(delta, j.combate.enemigos, int(j.jug().hp), j.combate.centro_pj(), j.mundo, red is Cli, j.d.get("fauna", {}).get("bajas", {}))
	if panel != "":
		# En la prueba, mirar las necesidades no detiene la vida del valle. Esc sí pausa.
		if red == null and j.autonomia.activa() and panel != "pausa":
			j.tick(minf(delta, 1.0 / 30.0))
			auto_t += delta
			if auto_t >= AUTOGUARDADO_S:
				auto_t = 0.0
				j.guardar(ruta)
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
	for id in j.habitantes.ids:
		if j.habitantes.pos(id).distance_to(j.pies) <= J.ALCANCE_NPC: return "E: hablar con %s" % j.habitantes.fichas[id].n
	if j.autonomia.sociedad.activa():
		for gid in j.autonomia.sociedad.cfg.grupos:
			if Vector2(Mundo.celda_de(j.pies)).distance_to(Vector2(j.autonomia.sociedad._ancla(gid))) <= 2.0:
				return "J: aportar al depósito de " + j.autonomia.sociedad.nombre_grupo(gid)
	var base := Mundo.celda_de(j.pies)
	for c in [base + j.mira, base]:
		var oid: String = j.mundo.objeto_presente(c)
		if oid != "":
			var ot: String = j.mundo.objetos[oid].t
			if ot in Mundo.DECO: continue
			return "E: abrir cofre" if ot == "cofre_fijo" else "Espacio: golpear %s" % C.OBJETOS[ot].n
		var cs: Dictionary = j.mundo.constr_en(c)
		if cs.get("t", "") == "cofre": return "E: abrir cofre"
		if cs.get("t", "") == "cama": return "E: dormir" if cs.get("dueno", "") == J.LOCAL else ("Cama de otro jugador" if cs.propia else "Cama de un habitante")
	return ""

## Marcador visible cuando falta el arte del personaje: nunca se dibuja el arte anterior.
func _arte_faltante(origen: Vector2) -> void:
	push_error("Arte faltante: personaje (res://arte/equipo)")
	draw_rect(Rect2(origen, Vector2(P.SPRITE)), Color(1, 0, 1, 0.85))

# ---------- dibujo del mundo ----------
## Profundidad por los pies; los empates mantienen el mismo orden aunque se mueva el PJ
## o cambie la lista visible. Godot no garantiza estabilidad si solo se compara Y.
static func entrada_dibujo(pies: Vector2, tipo: String, dato, clave: String) -> Array:
	return [pies.y, tipo, dato, pies.x, tipo + ":" + clave]

static func ordenar_dibujo(a: Array, b: Array) -> bool:
	if a[0] != b[0]: return a[0] < b[0]
	if a[3] != b[3]: return a[3] < b[3]
	return a[4] < b[4]

func _draw() -> void:
	if modo != "juego" or j == null: return
	rotulos.clear()
	cuerpos_rotulo.clear()
	var s := P.CELDA
	var vp := get_viewport_rect().size / float(P.ZOOM)
	var vista := Rect2(cam.position - vp / 2.0, vp).grow(40)
	var m = j.mundo
	var x0 := floori(vista.position.x / s)
	var x1 := floori(vista.end.x / s)
	var y0 := floori(vista.position.y / s)
	var y1 := floori(vista.end.y / s)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var c := Vector2i(x, y)
			arte_mundo.suelo(self, m, c, Time.get_ticks_msec() / 1000.0)
			var cs: Dictionary = m.constr_en(c)
			if cs.get("t", "") == "suelo": arte_mundo.constr_suelo(self, c)
	arte_mundo.casa_interior(self)
	for e in j.combate.enemigos: if e.est == "aviso": _telegrafo(e)
	var dentro := Mundo.CASA.has_point(Mundo.celda_de(j.pies))
	var lista: Array = [entrada_dibujo(j.pies, "pj", null, "local"), entrada_dibujo(Vector2(Mundo.CASA.position.x * s, Mundo.CASA.end.y * s - 8.0), "fachada", null, "casa")]
	for id in j.habitantes.ids: lista.append(entrada_dibujo(j.habitantes.pos(id), "npc", id, id))
	if red != null:
		for o in red.otros_jugadores(): lista.append(entrada_dibujo(o.pies, "otro", o, str(o.nombre)))
	for e in j.combate.enemigos: lista.append(entrada_dibujo(e.pos, "enemigo", e, str(e.tipo) + ActoresArte.clave(e)))
	for r in j.autonomia.asentamientos.visibles(): lista.append(entrada_dibujo(r.pos,"regional",r,r.id))
	for id in m.objetos:
		var o: Dictionary = m.objetos[id]
		if not vista.has_point(Vector2(o.c) * s): continue
		if m.estado.rotos.has(id) and not (o.t in ["arbol", "roca", "veta", "veta_cobre", "veta_estano", "arcilla", "arbusto"]): continue
		lista.append(entrada_dibujo(Vector2(o.c) * s + Vector2(s / 2.0, s), "obj", id, id))
	for k in m.estado.constr:
		var p: PackedStringArray = k.split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		if m.estado.constr[k].t != "suelo" and vista.has_point(Vector2(c) * s): lista.append(entrada_dibujo(Vector2(c) * s + Vector2(s / 2.0, s), "constr", c, k))
	for item in lista:
		var pies_rotulo: Vector2
		match item[1]:
			"pj": pies_rotulo = j.pies
			"npc": pies_rotulo = j.habitantes.pos(item[2])
			"otro": pies_rotulo = item[2].pies
			"enemigo", "regional": pies_rotulo = item[2].pos
			_: continue
		cuerpos_rotulo.append(Rect2(pies_rotulo - Vector2(11, 46 if item[1] == "enemigo" else 29), Vector2(22, 46 if item[1] == "enemigo" else 29)))
	lista.sort_custom(ordenar_dibujo)
	for e in lista:
		match e[1]:
			"pj": _dibujar_pj()
			"npc": _dibujar_npc(e[2])
			"otro": _dibujar_otro(e[2])
			"enemigo": _dibujar_enemigo(e[2])
			"regional":
				var r: Dictionary=e[2]
				arte_eq.dibujar(self,r.pos,Vector2i.DOWN,int(Time.get_ticks_msec()/150)%4 if r.mueve else 0,[],r.look,"caminar" if r.mueve else "reposo")
				_nombre_mundo(r.nombre,r.pos)
			"obj": _dibujar_obj(e[2])
			"constr": _dibujar_constr(e[2])
			"fachada": arte_mundo.casa_fachada(self, 0.25 if dentro else 1.0, dentro or _cerca_puerta())
	actores.residuo(self)
	actores.efectos_dibujar(self)
	if pista != "":   # E06: indicador de interacción sobre el jugador cuando hay algo con lo que interactuar
		var ind: Texture2D = hud.ui.tex("reutilizados/interact_indicator.png")
		if ind != null: draw_texture_rect(ind, Rect2((j.pies - Vector2(6, 46 + 0.5 * sin(Time.get_ticks_msec() / 300.0))).round(), Vector2(12, 16)), false)
	arte_mundo.casa_tejado(self, 0.0 if dentro else 1.0)
	_dibujar_techos(vista, s)
	if j.autonomia.sociedad.activa():
		var marcador: Texture2D = hud.ui.tex("reutilizados/quest_marker.png")
		for gid in j.autonomia.sociedad.cfg.grupos:
			var pos := Mundo.pies_de_celda(j.autonomia.sociedad._ancla(gid))
			# Deposits share anchors with workshops: keep their marker above NPC heads and names.
			if marcador != null: draw_texture_rect(marcador, Rect2(pos - Vector2(6, 58), Vector2(12, 12)), false)
			_nombre_mundo(j.autonomia.sociedad.nombre_grupo(gid), pos - Vector2(0, 30), Color("f1d692"))
	if build:
		var c: Vector2i = Mundo.celda_de(j.pies) + j.mira
		var id: String = C.ORDEN_CONSTR[pieza_i]
		var libre: bool = m.puede_techar(c) == "" if id == "techo" else m.puede_poner(c) == "" and not j.ocupada(c)
		var bien: bool = libre and Inv.tiene(j.jug().inv, C.CONSTR[id].coste)
		arte_mundo.constr(self, id, c, false, Color(0.5, 1, 0.55, 0.65) if bien else Color(1, 0.4, 0.4, 0.65))
	_dibujar_rotulos()
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
	_sombra(j.pies)
	var vis := _equipo_visible(j.jug().equipo)
	if arte_eq.disponible(): arte_eq.dibujar(self, j.pies, j.mira, _cuadro_arte(_anim), vis, j.jug().look, _anim.estado, _hacha_local(), _herramienta_local())
	else: _arte_faltante(origen)
	if auto_ataque >= 0.0:
		var fase: String = j.combate.est
		var txt := fase if _anim.estado != "ataque" else "%s %d %s" % [fase, _anim.cuadro, POSES_ATAQUE[posmod(int(_anim.cuadro), 4)]]
		draw_string(hud.ui.fuente, origen + Vector2(-18, -26), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		print("AUTOATQ cuadro_proceso=%d fase=%s estado=%s cuadro=%d" % [Engine.get_process_frames(), fase, _anim.estado, _anim.cuadro])

## Sombra de pies E06 (máscara 16×8 a opacidad .25, escala entera; solo presentación, sin tocar la colisión).
func _sombra(pies: Vector2, escala: float = 1.0) -> void:
	var t: Texture2D = hud.ui.tex("nuevos/sombra_pies.svg")
	var tam := Vector2(16, 8) * (1.0 if escala <= 1.0 else float(roundi(escala)))
	var r := Rect2((pies - Vector2(tam.x / 2.0, tam.y * 0.6)).round(), tam)
	if t == null: draw_rect(r, hud.ui.MARCADOR)
	else: draw_texture_rect(t, r, false, Color(1, 1, 1, 0.25))

## Hacha visible solo al talar un árbol con hacha en el inventario (dato de presentación del jugador local; el
## protocolo no transmite la herramienta de los remotos, así que ellos no la muestran).
## Presentation only: choose the actual tool for the target, including the new regional resources.
func _herramienta_local() -> String:
	if _anim.estado != "herramienta": return ""
	var oid: String = j.mundo.por_celda.get(Mundo.celda_de(j.pies) + j.mira, "")
	if oid == "": return ""
	var tipo: String = j.mundo.objetos[oid].t
	var tag := "talar" if tipo == "arbol" else ("picar" if tipo in ["roca", "veta", "veta_cobre", "arcilla"] else "")
	if tag == "": return ""
	for it in j.jug().inv:
		if Eq.info(it).get("tag", "") == tag: return "hacha" if tag == "talar" else "pico"
	return ""

func _hacha_local() -> bool:
	if _anim.estado != "herramienta": return false
	var oid: String = j.mundo.por_celda.get(Mundo.celda_de(j.pies) + j.mira, "")
	if oid == "" or j.mundo.objetos[oid].t != "arbol": return false
	for it in j.jug().inv: if Eq.info(it).get("tag", "") == "talar": return true
	return false

## Cuadro para el arte por capas: caminata, ataque, herramienta y daño animan; el resto usa el cuadro 0.
static func _cuadro_arte(an: Dictionary) -> int:
	return int(an.cuadro) if an.estado in ["caminar", "ataque", "herramienta", "dano"] else 0

# Equipo.visible (ranura, arquetipo, familia, variante, paleta, delta); el arma equipada sale como «espada».
static func _equipo_visible(equipo: Dictionary) -> Array:
	return Eq.visible(equipo)

# Otro jugador (red): su apariencia y su equipo real (arte por capas si está activo; si no, procedural) y su nombre.
func _dibujar_otro(o: Dictionary) -> void:
	var origen: Vector2 = (o.pies - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	_sombra(o.pies)
	var cuadro: int = _cuadro_arte(o)
	if arte_eq.disponible():
		var eq: Dictionary = o.get("equipo") if o.get("equipo") is Dictionary else {}
		arte_eq.dibujar(self, o.pies, o.mira, cuadro, _equipo_visible(eq), o.look, str(o.estado))
	else: _arte_faltante(origen)
	_nombre_mundo(o.nombre, o.pies, Color("f1d692"))

func _dibujar_npc(id: String) -> void:
	var p: Vector2 = j.habitantes.pos(id)
	var origen: Vector2 = (p - Vector2(P.SPRITE.x / 2.0, P.SPRITE.y)).round()
	_sombra(p)
	var act: String = j.d.npcs[id].act
	var st: Dictionary = actores.npc_estado(id, p)
	var cuadro := int(Time.get_ticks_msec() / 120.0) % 4 if st.mueve else 0
	arte_eq.dibujar(self, p, st.dir, cuadro, [], j.habitantes.aspecto(id), "caminar" if st.mueve else "reposo")
	if p.distance_to(j.pies) <= 128.0:
		_nombre_mundo(j.habitantes.fichas[id].n + (" · zzz" if act == "dormir" else ""), p)

## Uses the current Nunito font; keep the new UI and Lora dialogue typography.
func _nombre_mundo(texto: String, pies: Vector2, color: Color = Color("f7e2aa")) -> void:
	rotulos.append({"texto": texto, "pies": pies, "color": color})

func _dibujar_rotulos() -> void:
	var fuente: Font = hud.ui.fuente
	if fuente == null: return
	var usados: Array = cuerpos_rotulo.duplicate()
	for etiqueta in rotulos:
		var ancho: float = fuente.get_string_size(etiqueta.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var r := Rect2((etiqueta.pies - Vector2(ancho / 2.0 + 2, 41)).round(), Vector2(ancho + 4, 11))
		var libre := false
		for intento in 20:
			libre = true
			for ocupado in usados:
				if r.grow(1).intersects(ocupado):
					libre = false
					break
			if libre: break
			r.position.y -= 12
		if not libre: continue
		usados.append(r)
		draw_rect(r, Color(0.09, 0.12, 0.10, 0.82))
		draw_string(fuente, r.position + Vector2(2, 8), etiqueta.texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, etiqueta.color)

func _dibujar_enemigo(e: Dictionary) -> void:
	var t: float = e.tam
	var def: Dictionary = C.ENEMIGOS[e.tipo]
	var o: Vector2 = e.pos - Vector2(t / 2.0, t)
	_sombra(e.pos, 0.6 + t / 28.0 * 0.6)
	actores.enemigo(self, e, Time.get_ticks_msec() / 1000.0)
	if def.has("conducta") and e.pos.distance_to(j.pies) < 96.0:
		_nombre_mundo(def.n, e.pos - Vector2(0, 18), Color("eee4cf"))
	if e.hp < def.hp:
		draw_rect(Rect2(o + Vector2(0, -6), Vector2(t, 3)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(o + Vector2(0, -6), Vector2(t * float(e.hp) / def.hp, 3)), Color("cf5a43"))

func _dibujar_obj(id: String) -> void:
	var o: Dictionary = j.mundo.objetos[id]
	var p := Vector2(o.c) * P.CELDA
	var roto: bool = j.mundo.estado.rotos.has(id)
	match o.t:
		"arbol", "roca", "veta", "veta_cobre", "veta_estano", "arcilla", "arbusto": arte_mundo.natural(self, o.t, o.c, roto, j.pies)
		"barril": arte_mundo.prop(self, "barrel", Vector2(o.c) * P.CELDA + Vector2(8, 16))
		"valla": arte_mundo.valla(self, j.mundo, o.c)
		"cofre_fijo": arte_mundo.cofre(self, o.c, j.d.cofres.tesoro_cantera.get("abierto", false))
	var g: int = j.mundo.estado.golpes.get(id, 0)
	if g > 0 and not roto: draw_rect(Rect2(p + Vector2(2, -2), Vector2(12, 2)), Color(1, 1, 1, 0.8))

## Los techos tapan la casa; los que están conectados al jugador (por dentro o junto a la puerta) se vuelven transparentes.
func _dibujar_techos(vista: Rect2, s: float) -> void:
	var techos: Dictionary = j.mundo.estado.techos
	if techos.is_empty(): return
	var pj := Mundo.celda_de(j.pies)
	var abiertos := {}
	var cola: Array = []
	for d in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if techos.has(Mundo.clave(pj + d)) and (d == Vector2i.ZERO or j.mundo.constr_en(pj + d).get("t", "") == "puerta"): cola.append(pj + d)
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		if abiertos.has(c): continue
		abiertos[c] = true
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if techos.has(Mundo.clave(c + d)) and not abiertos.has(c + d): cola.append(c + d)
	var visitados := {}
	for k in techos:
		var partes: PackedStringArray=k.split(",")
		var semilla:=Vector2i(int(partes[0]),int(partes[1]))
		if visitados.has(semilla):continue
		var grupo: Array=[semilla]
		var minimo:=semilla
		var maximo:=semilla
		var transparente:=false
		while not grupo.is_empty():
			var c: Vector2i=grupo.pop_back()
			if visitados.has(c):continue
			visitados[c]=true
			minimo=minimo.min(c);maximo=maximo.max(c)
			if abiertos.has(c):transparente=true
			for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
				if techos.has(Mundo.clave(c+d)) and not visitados.has(c+d):grupo.append(c+d)
		var r:=Rect2(Vector2(minimo)*s-Vector2(8,32),Vector2(maximo-minimo+Vector2i.ONE)*s+Vector2(16,32))
		if r.intersects(vista):arte_mundo.tejado_rect(self,r,0.12 if transparente else 1.0)

func _dibujar_constr(c: Vector2i) -> void:
	var cs: Dictionary = j.mundo.constr_en(c)
	var abierta: bool = cs.t == "puerta" and maxi(absi(Mundo.celda_de(j.pies).x - c.x), absi(Mundo.celda_de(j.pies).y - c.y)) <= 1
	arte_mundo.constr(self, cs.t, c, abierta, Color.WHITE, j.campo_listo(c))

## La puerta se ve abierta con el jugador a una celda o menos (solo presentación; la colisión no cambia).
func _cerca_puerta() -> bool:
	var d: Vector2i = (Mundo.celda_de(j.pies) - Mundo.PUERTA_C).abs()
	return maxi(d.x, d.y) <= 1

func _navegar_inventario(e:InputEvent)->void:
	var primero:=4+C.RANURAS.size()
	var ultimo:int=primero+j.jug().inv.size()-1
	if sel<primero:
		if e.keycode==KEY_UP:sel=3+posmod(sel-4,C.RANURAS.size())
		elif e.keycode==KEY_DOWN:sel=3+posmod(sel-2,C.RANURAS.size())
		elif e.keycode==KEY_RIGHT:
			if sel<7:sel=mini(sel+4,9)
			elif ultimo>=primero:sel=primero
		elif e.keycode==KEY_LEFT and sel>=7:sel-=4
	else:
		var columna:=posmod(sel-primero,5)
		if e.keycode==KEY_LEFT:
			sel=9 if columna==0 else sel-1
		elif e.keycode==KEY_RIGHT:sel=mini(ultimo,sel+1)
		elif e.keycode==KEY_UP:sel=maxi(primero,sel-5)
		elif e.keycode==KEY_DOWN:sel=mini(ultimo,sel+5)
