extends SceneTree
func _initialize():
	var raiz="res://arte/mundo/minerales_v1/"
	var im=Image.load_from_file(raiz+"fuente.png");im.convert(Image.FORMAT_RGBA8)
	var w=im.get_width();var h=im.get_height();var corte=int(h*0.595)
	var bordes=[0,460,890,1272,w]
	var ids=["hierro","cobre","estano","arcilla"]
	for fila in 2:
		for col in 4:
			var rect=Rect2i(bordes[col],0 if fila==0 else corte,bordes[col+1]-bordes[col],corte if fila==0 else h-corte)
			var pieza=im.get_region(rect);var minimo=pieza.get_size();var maximo=Vector2i.ZERO
			for y in pieza.get_height():
				for x in pieza.get_width():
					if pieza.get_pixel(x,y).a<0.20:continue
					minimo=minimo.min(Vector2i(x,y));maximo=maximo.max(Vector2i(x+1,y+1))
			assert(maximo.x>minimo.x)
			var sprite=pieza.get_region(Rect2i(minimo,maximo-minimo))
			var limite=Vector2(76,44 if col==3 else 60) if fila==0 else Vector2(76,38)
			var escala=minf(limite.x/sprite.get_width(),limite.y/sprite.get_height())
			sprite.resize(maxi(1,roundi(sprite.get_width()*escala)),maxi(1,roundi(sprite.get_height()*escala)),Image.INTERPOLATE_NEAREST)
			var canvas=Image.create(96,96,false,Image.FORMAT_RGBA8);canvas.fill(Color(0,0,0,0));canvas.blit_rect(sprite,Rect2i(Vector2i.ZERO,sprite.get_size()),Vector2i((96-sprite.get_width())/2,86-sprite.get_height()))
			assert(canvas.save_png(raiz+ids[col]+("_agotado" if fila else "")+".png")==OK)
	print("RECURSOS: 8 sprites recortados; 96px, pivote (48,86), destino 48px")
	quit()
