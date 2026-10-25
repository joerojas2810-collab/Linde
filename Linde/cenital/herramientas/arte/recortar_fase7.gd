extends SceneTree
# Mechanical atlas extraction only. Approved styles 0/1/11/13 and all body/equipment files remain untouched.
var out=ProjectSettings.globalize_path("res://../documentos/FASE_07/")
func _initialize():call_deferred("run")
func run():
	var gutters=JSON.parse_string(FileAccess.get_file_as_string(out+"fuentes/gutters.json"))
	var sheets=["peinados_A.png","peinados_B.png"]
	var ids=[[2,3,4,5,6],[7,8,9,10,12]]
	for sheet in 2:
		var im=Image.load_from_file(out+"fuentes/"+sheets[sheet]);im.convert(Image.FORMAT_RGBA8)
		for y in im.get_height():
			for x in im.get_width():
				var c=im.get_pixel(x,y)
				if c.a<.5:im.set_pixel(x,y,Color(0,0,0,0))
				else:c.a=1;im.set_pixel(x,y,c)
		var edges=gutters[sheets[sheet]]
		for row in 5:
			var style=ids[sheet][row]
			for view in 4:
				var left=int(float(view)*im.get_width()/4);var right=int(float(view+1)*im.get_width()/4)
				var piece=im.get_region(Rect2i(left,int(edges[row]),right-left,int(edges[row+1])-int(edges[row])))
				piece=piece.get_region(piece.get_used_rect())
				var height=56
				if style==2:height=72
				elif style==8:height=90
				elif style==9:height=79 if view!=0 else 64
				elif style==10:height=51
				elif style==7:height=61
				var width=62 if style in [2,7,8] else 60
				piece.resize(width,height,Image.INTERPOLATE_NEAREST)
				var layer=Image.create(128,128,false,Image.FORMAT_RGBA8)
				layer.blit_rect(piece,Rect2i(Vector2i.ZERO,piece.get_size()),Vector2i((128-width)/2,20))
				if view==0:layer.fill_rect(Rect2i(51,53,26,22),Color(0,0,0,0))
				elif view==1:layer.fill_rect(Rect2i(68,51,17,23),Color(0,0,0,0))
				elif view==3:layer.fill_rect(Rect2i(43,51,17,23),Color(0,0,0,0))
				assert(layer.save_png(ProjectSettings.globalize_path("res://arte/viajero071/pelo/%d_%d.png"%[style,view]))==OK)
	print("RECORTES_072: 40 vistas extraídas usando gutters transparentes; sin generación nueva")
	quit()
