extends Control
## Preview autónomo de recursos E06; no contiene lógica del juego.
const BG = preload("res://fondo.png")
var F = preload("res://fuentes/tipografia/PixelifySans[wght].ttf")
const INK = Color("#30271f")
const PAPER = Color("#f7e2aa")
const FOCUS = Color("#92edee")
const OLD = "res://assets/reutilizados/"
const NEW = "res://assets/nuevos/"
var pantalla := 1
var noche := false
var seleccion := 0
var fraccion := 0.65
var ui: Control
var captura := false
var fondo: TextureRect
var capturas_dir := ""

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    F.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--capturas="): capturas_dir = arg.trim_prefix("--capturas=")
    _montar()
    if not capturas_dir.is_empty(): _capturar()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed: return
    if event.keycode >= KEY_1 and event.keycode <= KEY_6:
        pantalla = event.keycode - KEY_0
        seleccion = 0
    elif event.keycode == KEY_N: noche = not noche
    elif event.keycode == KEY_RIGHT: seleccion = (seleccion + 1) % 12
    elif event.keycode == KEY_LEFT: seleccion = posmod(seleccion - 1, 12)
    elif event.keycode == KEY_UP: fraccion = clampf(fraccion + 0.25, 0, 1)
    elif event.keycode == KEY_DOWN: fraccion = clampf(fraccion - 0.25, 0, 1)
    else: return
    _montar()

func _tex(parent: Node, file: String, rect: Rect2, tint := Color.WHITE) -> TextureRect:
    var t := TextureRect.new()
    t.texture = load(file)
    t.position = rect.position
    t.size = rect.size
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_SCALE
    t.modulate = tint
    parent.add_child(t)
    return t

func _texto(parent: Node, text: String, pos: Vector2, width: float, size_px := 24, color := INK) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.size.x = width
    l.add_theme_font_override("font", F)
    l.add_theme_font_size_override("font_size", size_px)
    l.add_theme_color_override("font_color", color)
    parent.add_child(l)
    return l

func _panel(rect: Rect2) -> NinePatchRect:
    var p := NinePatchRect.new()
    p.texture = load(OLD + "panel.png")
    p.position = rect.position
    p.size = rect.size
    p.patch_margin_left = 8
    p.patch_margin_top = 16
    p.patch_margin_right = 8
    p.patch_margin_bottom = 16
    ui.add_child(p)
    return p

func _borde(rect: Rect2) -> void:
    var r := ReferenceRect.new()
    r.position = rect.position
    r.size = rect.size
    r.border_color = FOCUS
    r.border_width = 2
    r.editor_only = false
    ui.add_child(r)

func _barra(pos: Vector2, valor: float, xp := false) -> void:
    # Marco fijo64x24 a escala entera3; interior recortado132x15.
    _tex(ui, OLD + "healthbar_frame.png", Rect2(pos, Vector2(192,72)))
    var clip := Control.new()
    clip.position = pos + Vector2(30,27)
    clip.size = Vector2(floor(132 * clampf(valor,0,1)),15)
    clip.clip_contents = true
    ui.add_child(clip)
    _tex(clip, OLD + "healthbar_fill.png", Rect2(0,0,132,15),Color("#59b7ff") if xp else Color.WHITE)
    if xp:
        # Usar asset XP propio, el rojo no sirve para tintar azul.
        for child in clip.get_children(): child.queue_free()
        _tex(clip,NEW + "xp_fill.svg",Rect2(0,0,132,15))
    _texto(ui,"XP" if xp else "VIDA",pos+Vector2(12,-10),180,16,INK)

func _montar() -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    fondo = _tex(self,"res://fondo.png",Rect2(-8,-126,1448,1086))
    var mat := ShaderMaterial.new()
    mat.shader = load(NEW + "luz_ambiente.gdshader")
    mat.set_shader_parameter("noche",1.0 if noche else 0.0)
    fondo.material = mat
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(ui)
    if pantalla == 1: _hud()
    elif pantalla == 2: _inventario()
    elif pantalla == 3: _equipo()
    elif pantalla == 4: _dialogo()
    elif pantalla == 5: _menu()
    else: _validacion()
    var pie := _panel(Rect2(16,668,1248,40))
    _texto(pie,"1 HUD   2 Inventario   3 Equipo   4 Diálogo   5 Menú   6 Pruebas   |   N día/noche   ←→ foco   ↑↓ barras",Vector2(16,8),1216,16)

func _hud() -> void:
    var p := _panel(Rect2(16,16,352,172))
    _texto(p,"Viajero · Nivel 4",Vector2(16,10),320,24)
    _barra(Vector2(28,64),fraccion)
    _barra(Vector2(28,120),0.4,true)
    _texto(p,"%d / 60" % int(fraccion*60),Vector2(216,64),120,24)
    _texto(p,"40 / 100 XP",Vector2(216,120),120,16)
    var q := _panel(Rect2(936,16,328,152))
    _texto(q,"Día 3 · " + ("22:30" if noche else "09:30"),Vector2(16,10),296,24)
    _texto(q,"Las ruinas de la cantera",Vector2(16,44),296,16)
    _texto(q,"[ ] Explorar las ruinas\n[ ] Derrotar al Guardián",Vector2(16,70),296,16)
    var hot := _panel(Rect2(392,568,496,88))
    for i in 6:
        _tex(hot,OLD + ("slot_selected.png" if i == seleccion%6 else "slot_normal.png"),Rect2(12+i*78,12,64,64))
        _tex(hot,OLD + ["espada_hierro.png","hacha_piedra.png","pico_piedra.png","baya.png","unguento.png","madera.png"][i],Rect2(12+i*78,12,64,64))
        _texto(hot,str(i+1),Vector2(16+i*78,48),24,16,PAPER)
    _borde(Rect2(404+(seleccion%6)*78,580,64,64))

func _inventario() -> void:
    var p := _panel(Rect2(192,56,896,576))
    _texto(p,"Inventario",Vector2(24,16),600,32)
    _texto(p,"12 / 20 espacios",Vector2(620,24),240,16)
    var items := ["madera","piedra","fibra","mena_hierro","lingote_hierro","baya","gelatina","unguento","gema","hacha_piedra","pico_piedra","espada_hierro"]
    for i in 12:
        var at := Vector2(24+(i%4)*88,88+(i/4)*96)
        _tex(p,OLD+("slot_selected.png" if i==seleccion else "slot_normal.png"),Rect2(at,Vector2(64,64)))
        _tex(p,OLD+items[i]+".png",Rect2(at,Vector2(64,64)))
        _texto(p,"50" if i<5 else "1",at+Vector2(40,44),32,16,PAPER)
    _borde(Rect2(p.position+Vector2(24+(seleccion%4)*88,88+(seleccion/4)*96),Vector2(64,64)))
    _texto(p,"SELECCIONADO",Vector2(416,88),400,16)
    _texto(p,items[seleccion].replace("_"," ").capitalize(),Vector2(416,120),440,24)
    _texto(p,"Material / herramienta\nCantidad visible, sin depender del color.\n\n[Enter] acción disponible\n[Esc] cerrar",Vector2(416,176),440,16)
    _texto(p,"Nombre largo: Piedra de Armonía",Vector2(24,464),848,24)
    _texto(p,"El foco exterior se suma al marco: navegación por teclado visible.",Vector2(24,508),848,16)

func _equipo() -> void:
    var p := _panel(Rect2(240,48,800,592))
    _texto(p,"Equipo · Vigía",Vector2(24,16),752,32)
    var ids := ["casco","coraza","guantes","botas","pantalones","escudo"]
    for i in 6:
        var at := Vector2(24+(i%3)*248,80+(i/3)*160)
        _tex(p,OLD+"slot_normal.png",Rect2(at,Vector2(64,64)))
        var path: String = (NEW if i in [2,3,4] else OLD)+ids[i]+".png"
        if ResourceLoader.exists(path): _tex(p,path,Rect2(at,Vector2(64,64)))
        _texto(p,["Casco","Torso","Guantes","Botas","Pantalones","Escudo"][i],at+Vector2(0,72),224,24)
        _texto(p,"Vigía · Brillante · +3" if i<5 else "Madera · equipado",at+Vector2(0,108),232,16)
    _texto(p,"Familia, variante y mejora se muestran como texto;\nno requieren cientos de iconos duplicados.",Vector2(24,440),752,24)
    _texto(p,"Muestra de presentación: no concede estadísticas ni equipo.",Vector2(24,536),752,16)

func _dialogo() -> void:
    var p := _panel(Rect2(112,392,1056,256))
    _tex(p,OLD+"categoria_comunidad.png",Rect2(24,24,64,64))
    _texto(p,"Maren",Vector2(112,24),600,32)
    _texto(p,"El taller necesita materiales. ¿Me traes seis piedras?\nPuedes explorar y construir antes de regresar.",Vector2(112,88),912,24)
    _texto(p,"[E / Enter] continuar",Vector2(112,200),600,16)
    _texto(p,"Texto de muestra, no canon",Vector2(712,200),320,16)

func _menu() -> void:
    var p := _panel(Rect2(400,80,480,560))
    _texto(p,"LINDE",Vector2(128,28),320,48)
    _texto(p,"Un mundo por descubrir",Vector2(88,92),360,16)
    for i in 4:
        var pos := Vector2(48,152+i*80)
        var button := NinePatchRect.new()
        button.texture = load(OLD+("button_hover.png" if i==seleccion%4 else "button_normal.png"))
        button.position = pos
        button.size = Vector2(384,72)
        button.patch_margin_left = 20
        button.patch_margin_right = 20
        button.patch_margin_top = 10
        button.patch_margin_bottom = 8
        p.add_child(button)
        var label := _texto(p,["Continuar","Nueva partida","Unirse a un mundo","Salir"][i],pos+Vector2(48,22),288,24,PAPER)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _borde(Rect2(p.position+Vector2(48,152+(seleccion%4)*80),Vector2(384,72)))
    _texto(p,"Preview visual · acciones sin conexión",Vector2(48,504),400,16)

func _validacion() -> void:
    var p := _panel(Rect2(80,48,1120,592))
    _texto(p,"Pruebas de lectura y estados",Vector2(24,16),1000,32)
    _texto(p,"Árbol · fabricación · misión · Armonía · ¡acción! · ¿Qué? · Ññ · 999",Vector2(24,72),1060,24)
    for i in 3:
        var y := 180+i*100
        _barra(Vector2(112,y),i*0.5)
        _barra(Vector2(352,y),i*0.5,true)
        _texto(p,["0 %","50 %","100 %"][i],Vector2(520,y-40),200,24)
    for i in 3:
        _tex(p,OLD+["slot_normal.png","slot_selected.png","slot_disabled.png"][i],Rect2(760+i*100,160,64,64))
        _texto(p,["Normal","Foco","Bloq."][i],Vector2(752+i*100,236),100,16)
    _tex(p,NEW+"sombra_pies.svg",Rect2(784,336,64,32),Color(1,1,1,0.25))
    _texto(p,"Sombra propuesta x4",Vector2(744,380),312,16)
    _texto(p,"Foco = borde + selección. Rareza/variante = texto además del color.\nBarra vacía no deja restos; relleno recortado, marco fijo.\nNoche afecta al mundo; texto y paneles conservan su iluminación.",Vector2(24,468),1060,24)

func _capturar() -> void:
    DirAccess.make_dir_recursive_absolute(capturas_dir)
    for screen in range(1,7):
        pantalla = screen
        noche = false
        _montar()
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(capturas_dir.path_join("%02d_dia.png" % screen))
    pantalla = 1
    noche = true
    _montar()
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(capturas_dir.path_join("01_noche.png"))
    print("E06: siete capturas renderizadas guardadas")
    get_tree().quit()
