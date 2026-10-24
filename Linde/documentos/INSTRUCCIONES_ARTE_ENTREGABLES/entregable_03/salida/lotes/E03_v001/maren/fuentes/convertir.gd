extends SceneTree

func _initialize() -> void:
	var root: String = get_script().resource_path.get_base_dir()
	var source := Image.load_from_file(root.path_join("maren_imagegen.png"))
	var regions: Array[Rect2i] = []
	var cleaned: Array[Image] = []
	var max_height := 0
	for row in 4:
		for col in 4:
			var start := Vector2i(roundi(col*source.get_width()/4.0),roundi(row*source.get_height()/4.0))
			var end := Vector2i(roundi((col+1)*source.get_width()/4.0),roundi((row+1)*source.get_height()/4.0))
			var region := source.get_region(Rect2i(start,end-start))
			for y in region.get_height():
				for x in region.get_width():
					var color := region.get_pixel(x,y)
					color.a = 1.0 if color.a >= 0.5 else 0.0
					region.set_pixel(x,y,color)
			var bounds := region.get_used_rect()
			regions.append(bounds)
			cleaned.append(region)
			max_height = maxi(max_height,bounds.size.y)
	var scale_factor := 24.0 / float(max_height)
	var atlas := Image.create(128,128,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in 16:
		var row := index / 4
		var col := index % 4
		var bounds := regions[index]
		var crop := cleaned[index].get_region(bounds)
		var width := maxi(1,roundi(bounds.size.x*scale_factor))
		var height := maxi(1,roundi(bounds.size.y*scale_factor))
		crop.resize(width,height,Image.INTERPOLATE_NEAREST)
		for y in height:
			for x in width:
				var color := crop.get_pixel(x,y)
				color.a = 1.0 if color.a >= 0.5 else 0.0
				if color.a > 0.0:
					var nearest := Color.BLACK
					var distance := INF
					for hex in ["16181c","28262a","403237","342725","49332a","604333","79523b","916448","b88257","dda375","f3bd8d","ffdbac","e9ab83","b97858","353e29","4d5633","667344","819051","a1a76a","62452c","7c5937","997045","bb8a51","443928"]:
						var candidate := Color(hex)
						var delta := Vector3(color.r-candidate.r,color.g-candidate.g,color.b-candidate.b).length_squared()
						if delta < distance:
							distance = delta
							nearest = candidate
					color = nearest
				else:
					color = Color.TRANSPARENT
				crop.set_pixel(x,y,color)
		atlas.blit_rect(crop,Rect2i(0,0,width,height),Vector2i(col*32+(32-width)/2,row*32+32-height))
	for row in 4:
		atlas.blit_rect(atlas,Rect2i(0,row*32,32,32),Vector2i(64,row*32))
	atlas.save_png(root.path_join("../assets/maren_caminata.png"))
	var background := Image.create(128,128,false,Image.FORMAT_RGBA8)
	background.fill(Color("70964f"))
	background.blend_rect(atlas,Rect2i(0,0,128,128),Vector2i.ZERO)
	atlas = background
	atlas.resize(768,768,Image.INTERPOLATE_NEAREST)
	atlas.save_png(root.path_join("../previews/maren_contacto_x6.png"))
	print("Maren: atlas128x128, común escala ",scale_factor,"; max alto24; alfa binaria; 16 celdas.")
	quit()
