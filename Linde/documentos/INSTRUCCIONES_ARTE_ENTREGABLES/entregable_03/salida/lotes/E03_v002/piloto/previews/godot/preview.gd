extends Node2D
## Comparación a zoom3; no se carga la lógica del juego.
var f: FontFile = preload("res://font/PixelifySans[wght].ttf")
var old: Texture2D = preload("res://assets/guardian_v001.png")
var candidate: Texture2D = preload("res://assets/guardian_v002.png")
var house: Texture2D = preload("res://assets/cottage_closed.png")
var grass: Texture2D = preload("res://assets/grass.png")
var path: Texture2D = preload("res://assets/path_fill.png")
var pj: Texture2D = preload("res://assets/pj.png")
var capturas := ""
func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--capturas="): capturas=arg.trim_prefix("--capturas=")
    if not capturas.is_empty(): _capture()
func _txt(text: String, at: Vector2, sz:=22, color:=Color("f6e8c0")) -> void:
    draw_string(f,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _sprite(tex:Texture2D,at:Vector2,row:int,col:=0,cell:=48,pivot:=Vector2(24,45)) -> void:
    draw_texture_rect_region(tex,Rect2(at-pivot*3,Vector2(cell,cell)*3),Rect2(col*cell,row*cell,cell,cell))
func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("243d33"))
    draw_rect(Rect2(0,0,1280,64),Color("172921"))
    _txt("LINDE · E03 v002 · Piloto de acabado del Guardián",Vector2(24,39),28)
    _txt("v001",Vector2(172,100),22)
    _txt("v002 candidato",Vector2(370,100),22)
    for row in 4:
        var y := 240+row*128
        _txt(["Sur","Este","Norte","Oeste"][row],Vector2(24,y-46),20)
        _sprite(old,Vector2(208,y),row)
        _sprite(candidate,Vector2(440,y),row)
        draw_line(Vector2(136,y+1),Vector2(512,y+1),Color("5b7761"))
    for y in 12:
        for x in 13:
            draw_texture_rect(path if y>6 else grass,Rect2(656+x*48,80+y*48,48,48),false)
    draw_texture_rect(house,Rect2(788,104,288,288),false)
    _sprite(candidate,Vector2(856,530),0)
    _sprite(pj,Vector2(1072,530),0,0,32,Vector2(16,32))
    draw_rect(Rect2(680,566,568,80),Color("172921"))
    _txt("Casa y PJ existentes, sin cambios",Vector2(696,594),20)
    _txt("Celda48 · pivote24,45 · zoom3",Vector2(696,624),20)
    draw_rect(Rect2(0,670,1280,50),Color("172921"))
    _txt("Muestra de dirección artística: no es una hoja completa ni integración al juego",Vector2(24,702),20)
func _capture() -> void:
    DirAccess.make_dir_recursive_absolute(capturas)
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(capturas.path_join("comparacion_guardian_v002.png"))
    print("Piloto E03 v002 renderizado")
    get_tree().quit()
