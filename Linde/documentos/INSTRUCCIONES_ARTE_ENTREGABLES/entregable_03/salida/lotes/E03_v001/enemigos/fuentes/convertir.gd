extends SceneTree
## Extiende los atlas originales sin cambiar sus primeras cinco columnas.
## Uso: Godot --headless --path <preview> --script <este_archivo> -- <carpeta_enemigos>
## Conserva el componente corporal principal; descarta ruido alfa aislado del generador.
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
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Falta carpeta_enemigos")
        quit(1)
        return
    var root := args[0]
    var reports: Array = []
    for spec in [["slime",32,16],["guardian",48,38],["ciervo",48,34]]:
        var id: String = spec[0]
        var cell: int = spec[1]
        var visible: int = spec[2]
        var original := Image.load_from_file(root.path_join("fuentes/linde_anterior/nativos/"+id+".png"))
        var generated := Image.load_from_file(root.path_join("fuentes/"+id+"_suplemento_original.png"))
        original.convert(Image.FORMAT_RGBA8)
        generated.convert(Image.FORMAT_RGBA8)
        var correction: Image
        var correction_file := root.path_join("fuentes/ciervo_correccion_original.png")
        if id == "ciervo" and FileAccess.file_exists(correction_file):
            correction = Image.load_from_file(correction_file)
            correction.convert(Image.FORMAT_RGBA8)
        var palette: Array[Color] = []
        var seen := {}
        for y in original.get_height():
            for x in original.get_width():
                var c := original.get_pixel(x,y)
                if c.a == 1 and not seen.has(c.to_rgba32()):
                    seen[c.to_rgba32()] = true
                    palette.append(c)
        var parts: Array[Image] = []
        var bounds: Array = []
        var max_dim := 0
        for row in 4:
            for col in 4:
                var source: Image = correction if correction != null and row == 2 and col == 3 else generated
                var row_bounds: Array = [[180,350],[410,580],[630,810],[860,1030]] if id == "slime" else ([[30,280],[295,550],[575,820],[830,1080]] if id == "guardian" else [[28,291],[291,547],[547,807],[807,1065]])
                var a := Vector2i(roundi(source.get_width()*col/4.0),int(row_bounds[row][0]))
                var b := Vector2i(roundi(source.get_width()*(col+1)/4.0),int(row_bounds[row][1]))
                var piece := source.get_region(Rect2i(a,b-a))
                for y in piece.get_height():
                    for x in piece.get_width():
                        var c := piece.get_pixel(x,y)
                        piece.set_pixel(x,y,Color(c.r,c.g,c.b,1) if c.a >= 0.5 else Color.TRANSPARENT)
                piece = _cuerpo_principal(piece)
                var used := piece.get_used_rect()
                if used.size.x == 0 or used.size.y == 0:
                    push_error("Celda vacía: "+id+str([row,col]))
                    quit(2)
                    return
                max_dim = maxi(max_dim,maxi(used.size.x,used.size.y))
                parts.append(piece.get_region(used))
                bounds.append([a.x+used.position.x,a.y+used.position.y,used.size.x,used.size.y])
        var factor := float(visible)/max_dim
        var atlas := Image.create(cell*9,cell*4,false,Image.FORMAT_RGBA8)
        atlas.fill(Color.TRANSPARENT)
        for row in 4:
            atlas.blit_rect(original,Rect2i(0,row*cell,cell*5,cell),Vector2i(0,row*cell))
        for i in 16:
            var part := parts[i]
            var w := maxi(1,roundi(part.get_width()*factor))
            var h := maxi(1,roundi(part.get_height()*factor))
            part.resize(w,h,Image.INTERPOLATE_NEAREST)
            for y in part.get_height():
                for x in part.get_width():
                    var c := part.get_pixel(x,y)
                    if c.a == 0: continue
                    var best := palette[0]
                    var distance := INF
                    for pc in palette:
                        var d := Vector3(c.r-pc.r,c.g-pc.g,c.b-pc.b).length_squared()
                        if d < distance:
                            best = pc
                            distance = d
                    part.set_pixel(x,y,best)
            atlas.blit_rect(part,Rect2i(0,0,w,h),Vector2i((5+i%4)*cell+(cell-w)/2,(i/4)*cell+cell-3-h))
        # Fin de recuperación usa el reposo ya aceptado: sin salto de escala/identidad.
        for row in 4:
            atlas.blit_rect(original,Rect2i(0,row*cell,cell,cell),Vector2i(6*cell,row*cell))
        var target := root.path_join("nativos/"+id+".png")
        var err := atlas.save_png(target)
        reports.append({"id":"E03_"+id,"file":"nativos/"+id+".png","atlas":[cell*9,cell*4],"cell":[cell,cell],"pivot":[cell/2,cell-3],"max_new_visible":visible,"scale_uniform":factor,"source_bounds":bounds,"palette_from_previous":palette.size(),"rows":["sur","este","norte","oeste"],"columns":["reposo","paso_a","paso_b","aviso","impacto","dano","recuperacion","derrota_a","derrota_b"],"old_columns_preserved":true,"recovery_reuses_original_idle":true,"save_error":err,"north_defeat_correction":correction!=null})
    var f := FileAccess.open(root.path_join("validacion/conversion.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(reports,"  "))
    print("E03:3 atlas9x4; primeras5columnas conservadas; nuevas4columnas en paleta anterior")
    quit()
