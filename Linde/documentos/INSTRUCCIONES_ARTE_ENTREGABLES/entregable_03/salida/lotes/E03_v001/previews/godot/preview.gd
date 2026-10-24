extends Node2D
## Escena aislada de revisión a zoom3; no importa lógica ni modifica estados del juego.
const Z := 3
const CREAM := Color("f8eac2")
const NAMES := ["Slime", "Guardián", "Ciervo"]
const IDS := ["slime","guardian","ciervo"]
var fuente: FontFile = preload("res://font/PixelifySans[wght].ttf")
var textures := {}
var modo := 1
var direccion := 0
var reloj := 0.0
var pausa := false
var captura_dir := ""

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    fuente.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    for id in IDS: textures[id] = load("res://assets/enemigos/"+id+".png")
    for id in ["maren","pj"]: textures[id] = load("res://assets/personajes/"+id+".png")
    for id in ["grass","path_fill","tree_broadleaf","rock","cottage_closed"]: textures[id] = load("res://assets/escenario/"+id+".png")
    for id in ["impacto","dano","recoleccion"]: textures[id] = load("res://assets/efectos/E03_fx_"+id+".png")
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--capturas="): captura_dir = arg.trim_prefix("--capturas=")
    if not captura_dir.is_empty(): _capturar()

func _process(dt: float) -> void:
    if not pausa: reloj += dt
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed: return
    match event.keycode:
        KEY_1: modo = 1
        KEY_2: modo = 2
        KEY_3: modo = 3
        KEY_RIGHT: direccion = (direccion+1)%4
        KEY_LEFT: direccion = posmod(direccion-1,4)
        KEY_SPACE: pausa = not pausa

func _txt(text: String, at: Vector2, size := 24, color := CREAM) -> void:
    draw_string(fuente,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _sprite(id: String, pies: Vector2, col: int, row: int, cell := 48, pivot := Vector2(24,45)) -> void:
    draw_texture_rect_region(textures[id],Rect2(pies-pivot*Z,Vector2(cell,cell)*Z),Rect2(col*cell,row*cell,cell,cell))

func _enemy(id: String, at: Vector2, col: int, row: int) -> void:
    _sprite(id,at,col,row,32 if id=="slime" else 48,Vector2(16,29) if id=="slime" else Vector2(24,45))

func _fondo() -> void:
    for y in 15:
        for x in 27:
            var id := "path_fill" if y in [7,8,9] or x in [12,13] else "grass"
            draw_texture_rect(textures[id],Rect2(x*48,y*48,48,48),false)
    draw_texture_rect(textures.cottage_closed,Rect2(96,72,288,288),false)
    draw_texture_rect(textures.tree_broadleaf,Rect2(1032,104,144,144),false)
    draw_texture_rect(textures.rock,Rect2(1040,520,144,144),false)

func _draw() -> void:
    if modo == 2: _fondo()
    else: draw_rect(Rect2(0,0,1280,720),Color("233d34"))
    draw_rect(Rect2(0,0,1280,64),Color("172921"))
    _txt("LINDE · E03 · " + ["Estados y comparación", "Composición a zoom 3", "Efectos y señales"][modo-1],Vector2(24,38),28)
    if modo == 1: _comparacion()
    elif modo == 2: _campo()
    else: _fx()
    draw_rect(Rect2(0,666,1280,54),Color("172921"))
    _txt("1 Estados   2 Escenario   3 FX   ←→ Dirección: "+["sur","este","norte","oeste"][direccion]+"   Espacio pausa",Vector2(24,690),20)
    _txt("Preview independiente · recursos candidatos · lógica y mundo productivos sin modificar",Vector2(24,712),16)

func _comparacion() -> void:
    var cols := [0,6,5,7,8]
    var labels := ["Reposo anterior","Recuperación (reuso)","Daño nuevo","Derrota A","Derrota B"]
    for i in 5: _txt(labels[i],Vector2(192+i*208,100),18)
    for r in 3:
        _txt(NAMES[r],Vector2(24,180+r*154),24)
        for c in 5:
            _enemy(IDS[r],Vector2(268+c*208,220+r*154),cols[c],direccion)
            draw_line(Vector2(206+c*208,221+r*154),Vector2(330+c*208,221+r*154),Color("5d7b63"))
    _sprite("pj",Vector2(540,634),int(reloj/0.12)%4,direccion,32,Vector2(16,32))
    _sprite("maren",Vector2(684,634),int(reloj/0.12)%4,direccion,32,Vector2(16,32))
    _txt("PJ existente",Vector2(392,622),18)
    _txt("Maren",Vector2(742,622),18)

func _campo() -> void:
    # Ciclo de demostración visual; las duraciones no se escriben en combate.
    var sequence := [0,1,0,2,3,4,6,5,7,8]
    var idx := int(reloj/0.3)%sequence.size()
    var col: int = sequence[idx]
    var positions := [Vector2(470,428),Vector2(828,396),Vector2(852,596)]
    for i in 3:
        _enemy(IDS[i],positions[i],col,direccion)
        _txt(NAMES[i],positions[i]+Vector2(-64,28),20,Color("1b2b23"))
    var step: int = int(reloj/0.12)%4
    _sprite("pj",Vector2(576,548),step,direccion,32,Vector2(16,32))
    _sprite("maren",Vector2(704,548),step,direccion,32,Vector2(16,32))
    _txt("PJ",Vector2(560,580),20,Color("1b2b23"))
    _txt("Maren",Vector2(672,580),20,Color("1b2b23"))
    draw_rect(Rect2(420,80,800,44),Color("172921"))
    _txt("Muestra: "+["reposo","paso A","reposo","paso B","aviso","impacto","recuperación","daño","derrota A","derrota B"][idx],Vector2(438,110),22)

func _fx() -> void:
    var names := ["Impacto", "Daño", "Recolección"]
    var keys := ["impacto","dano","recoleccion"]
    for i in 3:
        _txt(names[i],Vector2(56,120+i*130),24)
        for c in 4: _sprite(keys[i],Vector2(320+c*200,140+i*130),c,0,32,Vector2(16,16))
    _txt("Señal de prueba: área base y tolerancia al centro del objetivo",Vector2(56,484),22)
    var center := Vector2(320,566)
    draw_circle(center,60,Color("c75b48"),false,2,false)
    draw_circle(center,42,Color("e3b44c"),false,2,false)
    _txt("Slime: radio 14 + tolerancia 6",Vector2(420,548),20)
    _txt("Embestida: cápsula del recorrido real, no PNG de alcance fijo",Vector2(420,582),20)
    _txt("Solo el objetivo fijado recibe daño; no convierte el ataque en área para todos.",Vector2(56,646),18)

func _capturar() -> void:
    pausa = true
    DirAccess.make_dir_recursive_absolute(captura_dir)
    for row in 4:
        modo = 1
        direccion = row
        reloj = 0.15
        queue_redraw()
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(captura_dir.path_join("comparacion_%d.png"%row))
    for item in [["escenario_reposo",2,0,0.0],["escenario_impacto",2,1,1.5],["escenario_derrota",2,2,2.7],["efectos",3,0,0.0]]:
        modo = item[1]
        direccion = item[2]
        reloj = item[3]
        queue_redraw()
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(captura_dir.path_join(item[0]+".png"))
    print("E03:8 capturas reales de revisión guardadas")
    get_tree().quit()
