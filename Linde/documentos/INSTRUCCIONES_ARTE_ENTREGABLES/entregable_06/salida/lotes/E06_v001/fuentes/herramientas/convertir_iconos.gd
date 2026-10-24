extends SceneTree
## Convierte únicamente el atlas complementario E06; no modifica arte histórico.
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Uso: -- atlas.png carpeta_salida")
        quit(1)
        return
    var im := Image.load_from_file(args[0])
    if im == null:
        quit(2)
        return
    im.convert(Image.FORMAT_RGBA8)
    var ids := ["guantes","botas","pantalones","piedra_alma","piedra_armonia","piedra_bendicion","chispa","experiencia"]
    var palette: Array[Color] = []
    for h in ["211c21","3c2931","52382b","715035","96663e","bc854b","e3b46b","fff1c1","5c6879","8494a8","b5c8d2","e6f4f2","163951","215875","357fa3","54b8d5","97e6f3","5d326e","8551a1","b580d8","dfb5f0","a86518","e79d26","ffd65c","ffffff"]:
        palette.append(Color(h))
    DirAccess.make_dir_recursive_absolute(args[1])
    var report: Array = []
    for i in 8:
        var x0 := int(float(i%4) * im.get_width()/4)
        var y0 := int(float(i/4) * im.get_height()/2)
        var x1 := int(float(i%4+1) * im.get_width()/4)
        var y1 := int(float(i/4+1) * im.get_height()/2)
        var crop := im.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
        for y in crop.get_height():
            for x in crop.get_width():
                var c := crop.get_pixel(x,y)
                c.a = 1.0 if c.a >= 0.5 else 0.0
                crop.set_pixel(x,y,c)
        var used := crop.get_used_rect()
        var obj := crop.get_region(used)
        var factor := 28.0/maxi(obj.get_width(),obj.get_height())
        obj.resize(maxi(1,roundi(obj.get_width()*factor)),maxi(1,roundi(obj.get_height()*factor)),Image.INTERPOLATE_NEAREST)
        for y in obj.get_height():
            for x in obj.get_width():
                var c := obj.get_pixel(x,y)
                if c.a == 0: continue
                var nearest := palette[0]
                var dist := INF
                for col in palette:
                    var d := Vector3(c.r-col.r,c.g-col.g,c.b-col.b).length_squared()
                    if d < dist:
                        nearest = col
                        dist = d
                obj.set_pixel(x,y,nearest)
        var native := Image.create(32,32,false,Image.FORMAT_RGBA8)
        native.fill(Color.TRANSPARENT)
        native.blit_rect(obj,Rect2i(Vector2i.ZERO,obj.get_size()),Vector2i((32-obj.get_width())/2,(32-obj.get_height())/2))
        var file := args[1].path_join(ids[i]+".png")
        var err := native.save_png(file)
        report.append({"id":"E06_"+ids[i],"file":file.get_file(),"size":[32,32],"crop":[x0,y0,x1-x0,y1-y0],"bbox_source":[used.position.x,used.position.y,used.size.x,used.size.y],"error":err})
    var f := FileAccess.open(args[1].path_join("conversion.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(report,"  "))
    print("E06: 8 iconos32x32; paleta25; alfa binaria")
    quit()
