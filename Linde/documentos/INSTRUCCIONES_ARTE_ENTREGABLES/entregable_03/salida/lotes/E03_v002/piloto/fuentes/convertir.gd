extends SceneTree
## Uso: -- <carpeta_piloto>. Generación de imagen por image_gen, conversión nativa en Godot.
func _cuerpo_principal(im: Image) -> Image:
    var width := im.get_width()
    var height := im.get_height()
    var seen := PackedByteArray()
    seen.resize(width*height)
    var largest: Array[Vector2i] = []
    for y in height:
        for x in width:
            var at := y*width+x
            if seen[at] != 0 or im.get_pixel(x,y).a < 0.5: continue
            var q: Array[Vector2i] = [Vector2i(x,y)]
            seen[at] = 1
            var head := 0
            while head < q.size():
                var pos := q[head]
                head += 1
                for oy in range(-1,2):
                    for ox in range(-1,2):
                        var nx := pos.x+ox
                        var ny := pos.y+oy
                        if nx<0 or ny<0 or nx>=width or ny>=height: continue
                        var index := ny*width+nx
                        if seen[index] != 0 or im.get_pixel(nx,ny).a < 0.5: continue
                        seen[index] = 1
                        q.append(Vector2i(nx,ny))
            if q.size() > largest.size(): largest = q
    var result := Image.create(width,height,false,Image.FORMAT_RGBA8)
    result.fill(Color.TRANSPARENT)
    for pos in largest:
        var color := im.get_pixelv(pos)
        color.a = 1
        result.set_pixelv(pos,color)
    return result

func _initialize() -> void:
    var root:=OS.get_cmdline_user_args()[0]
    var source:=Image.load_from_file(root.path_join("fuentes/guardian_piloto_original.png"))
    source.convert(Image.FORMAT_RGBA8)
    var pieces:Array[Image]=[]
    var maxdim:=0
    for row in 2:
        for col in 2:
            var a:=Vector2i(roundi(source.get_width()*col/2.0),roundi(source.get_height()*row/2.0))
            var b:=Vector2i(roundi(source.get_width()*(col+1)/2.0),roundi(source.get_height()*(row+1)/2.0))
            var cut:=_cuerpo_principal(source.get_region(Rect2i(a,b-a)))
            var box:=cut.get_used_rect()
            if box.size.x==0 or box.size.y==0:
                push_error("Vista vacía")
                quit(1)
                return
            var part:=cut.get_region(box)
            pieces.append(part)
            maxdim=maxi(maxdim,maxi(part.get_width(),part.get_height()))
    var palette:Array[Color]=[]
    for c in ["28262d","4c4645","72695f","988777","c7b396","ebd5af","3b4527","63713a","91934a","16474b","23797d","50bdad","a6e2c6","86612c","cca54e","f8dc85"]:palette.append(Color(c))
    var atlas:=Image.create(48,192,false,Image.FORMAT_RGBA8)
    atlas.fill(Color.TRANSPARENT)
    var factor:=34.0/maxdim
    var report:Array=[]
    for i in 4:
        var part:=pieces[i]
        var w:=maxi(1,roundi(part.get_width()*factor))
        var h:=maxi(1,roundi(part.get_height()*factor))
        part.resize(w,h,Image.INTERPOLATE_LANCZOS)
        for y in h:
            for x in w:
                var c:=part.get_pixel(x,y)
                if c.a<0.5:
                    part.set_pixel(x,y,Color.TRANSPARENT)
                    continue
                var nearest:=palette[0]
                var dist:=INF
                for color in palette:
                    var d:=Vector3(c.r-color.r,c.g-color.g,c.b-color.b).length_squared()
                    if d<dist:
                        nearest=color
                        dist=d
                part.set_pixel(x,y,nearest)
        atlas.blit_rect(part,Rect2i(0,0,w,h),Vector2i((48-w)/2,i*48+45-h))
        report.append({"fila":i,"bbox_visible":[w,h]})
    var error:=atlas.save_png(root.path_join("nativos/guardian_piloto.png"))
    var f:=FileAccess.open(root.path_join("validacion/conversion.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"atlas":[48,192],"celda":[48,48],"pivot":[24,45],"max_visible":34,"scale_common":factor,"rows":["sur","este","norte","oeste"],"views":report,"palette_max":16,"save_error":error},"  "))
    print("Piloto:4vistas,16colores máximos,escala común")
    quit(error)
