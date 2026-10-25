extends SceneTree
var OUT=ProjectSettings.globalize_path("res://../documentos/FASE_07")
const ART="res://arte/viajero071/"
func _initialize(): call_deferred("run")
func load_image(path:String)->Image:
	var im=Image.load_from_file(path);im.convert(Image.FORMAT_RGBA8)
	for y in im.get_height():
		for x in im.get_width():
			var p=im.get_pixel(x,y)
			if p.a<0.5:im.set_pixel(x,y,Color(0,0,0,0))
			else:p.a=1.0;im.set_pixel(x,y,p)
	return im
func blank()->Image:return Image.create(128,128,false,Image.FORMAT_RGBA8)
func save(im:Image,path:String):
	var e=im.save_png(ProjectSettings.globalize_path(path));assert(e==OK,path)
func tile(im:Image,col:int,row:int,cols:int,rows:int)->Image:
	var x0=int(float(col)*im.get_width()/cols);var x1=int(float(col+1)*im.get_width()/cols)
	var y0=int(float(row)*im.get_height()/rows);var y1=int(float(row+1)*im.get_height()/rows)
	if rows==3:
		# This sheet has uneven row heights; use its measured transparent gutters, not equal thirds.
		y0=[0,353,694][row];y1=[353,694,im.get_height()][row]
		x0=[0,420,735,1030][col];x1=[420,735,1030,im.get_width()][col]
	var part=im.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
	return part.get_region(part.get_used_rect())
func run():
	# Source0 is extracted from approved original traveler; other approved hair files are copied untouched.
	for view in 4:
		var im=load_image(ART+"bases/original_%d.png"%view);var hair=blank()
		for y in range(20,77):
			for x in 128:
				var c=im.get_pixel(x,y)
				var skin=c.r>0.5 and c.g/maxf(c.r,.01)>.64 and c.b/maxf(c.r,.01)>.43
				if c.a8>0 and not skin and (c.r>c.b*1.25 or c.v<.20):hair.set_pixel(x,y,c)
		# Reuse approved base style head opening; never copy eyes into a hair layer.
		if view==0:hair.fill_rect(Rect2i(48,50,32,25),Color(0,0,0,0))
		elif view==1:hair.fill_rect(Rect2i(66,50,19,25),Color(0,0,0,0))
		elif view==3:hair.fill_rect(Rect2i(43,50,19,25),Color(0,0,0,0))
		save(hair,ART+"pelo/0_%d.png"%view)
	var ids=[[2,3,4,5,6],[7,8,9,10,12]]
	for sheet in 2:
		var source=load_image(OUT+"/fuentes/peinados_%s.png"%["A","B"][sheet])
		for row in 5:
			var style=ids[sheet][row]
			for view in 4:
				var piece=tile(source,view,row,4,5)
				var height=56
				if style==2:height=72
				elif style==8:height=90
				elif style==9:height=79 if view!=0 else 64
				elif style==10:height=51
				elif style==7:height=61
				var width=62 if style in [2,7,8] else 60
				piece.resize(width,height,Image.INTERPOLATE_NEAREST)
				var layer=blank();layer.blit_rect(piece,Rect2i(Vector2i.ZERO,piece.get_size()),Vector2i((128-width)/2,20))
				# Match actual head apertures. Pixels above y50 retain each fringe's design.
				if view==0:layer.fill_rect(Rect2i(51,53,26,22),Color(0,0,0,0))
				elif view==1:layer.fill_rect(Rect2i(68,51,17,23),Color(0,0,0,0))
				elif view==3:layer.fill_rect(Rect2i(43,51,17,23),Color(0,0,0,0))
				save(layer,ART+"pelo/%d_%d.png"%[style,view])
	var gear=load_image(OUT+"/fuentes/equipo.png")
	for row in 3:
		for view in 4:
			var piece=tile(gear,view,row,4,3)
			var split=int(piece.get_height()*.40)
			var helmet=piece.get_region(Rect2i(0,0,piece.get_width(),split))
			var body=piece.get_region(Rect2i(0,split,piece.get_width(),piece.get_height()-split))
			helmet=helmet.get_region(helmet.get_used_rect());body=body.get_region(body.get_used_rect())
			if row==2 and view==0:
				print("DEBUG_GEAR ",piece.get_size()," split ",split," helmet ",helmet.get_size()," body ",body.get_size())
				helmet.save_png(OUT+"/fuentes/casco_recorte.png")
				piece.save_png(OUT+"/fuentes/equipo_recorte.png")
			helmet.resize(64,57,Image.INTERPOLATE_NEAREST);body.resize(54,51,Image.INTERPOLATE_NEAREST)
			var full=blank();full.blit_rect(helmet,Rect2i(0,0,64,57),Vector2i(32,20));full.blit_rect(body,Rect2i(0,0,54,51),Vector2i(37,77))
			# Retain an open helmet: eyes and hair below its rim remain visible.
			if view==0:full.fill_rect(Rect2i(49,52,30,23),Color(0,0,0,0))
			elif view==1:full.fill_rect(Rect2i(65,52,20,23),Color(0,0,0,0))
			elif view==3:full.fill_rect(Rect2i(43,52,20,23),Color(0,0,0,0))
			for slot in ["casco","torso","guantes","pantalones","botas"]:
				var layer=blank()
				for y in 128:
					for x in 128:
						var s="casco" if y<77 else "torso"
						var arm=(x<51 or x>77) if view in [0,2] else (x<61 if view==1 else x>67)
						if y>=94 and y<112 and arm:s="guantes"
						elif y>=117:s="botas"
						elif y>=106:s="pantalones"
						if s==slot:layer.set_pixel(x,y,full.get_pixel(x,y))
				save(layer,ART+"equipo/%s_%s_%d.png"%[["ligera","media","pesada"][row],slot,view])
	print("ASSETS_071: 56 hair views and 60 equipment slot views built")
	quit()
