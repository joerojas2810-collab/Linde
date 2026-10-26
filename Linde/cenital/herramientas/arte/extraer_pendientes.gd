extends SceneTree
var raiz="res://arte/pendientes_v1/"
var fichas={}
func core(im:Image,r:Rect2i)->Image:
	var a=r.end;var b=r.position
	for y in range(r.position.y,r.end.y):
		for x in range(r.position.x,r.end.x):
			if im.get_pixel(x,y).a<0.35:continue
			a=a.min(Vector2i(x,y));b=b.max(Vector2i(x+1,y+1))
	assert(b.x>a.x and b.y>a.y)
	return im.get_region(Rect2i(a,b-a))
func guardar(im:Image,n:String):assert(im.save_png(raiz+n+".png")==OK)
func montar(im:Image,tam:Vector2i,lim:Vector2,pie:Vector2i)->Image:
	var escala=minf(lim.x/im.get_width(),lim.y/im.get_height())
	im.resize(maxi(1,roundi(im.get_width()*escala)),maxi(1,roundi(im.get_height()*escala)),Image.INTERPOLATE_NEAREST)
	var out=Image.create(tam.x,tam.y,false,Image.FORMAT_RGBA8);out.fill(Color(0,0,0,0))
	out.blit_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),pie-Vector2i(im.get_width()/2,im.get_height()));return out
func _initialize():
	var mundo=ImagenUtil.imagen(raiz+"mundo_fuente.png");mundo.convert(Image.FORMAT_RGBA8)
	var nombres=["roca_redonda","roca_pizarra","roca_caliza","bayas_redonda","bayas_ancha","arbusto_valle","arbusto_bosque","arbusto_sierra","arbusto_secano","arbusto_pradera","arbusto_ribera","penasco","pino_ralo","arbol_seco","espinoso","arenisca","arbusto_flores","juncos","canas","helecho","tronco_caido","petate","jergon","letrero"]
	for i in 24:
		var c=i%6;var f=i/6
		var rec=Rect2i(c*256,f*256,256,256)
		if f==3 and c==4:rec=Rect2i(1024,768,276,256)
		if f==3 and c==5:rec=Rect2i(1300,768,236,256)
		var alto=i in [12,13];var tam=Vector2i(128,128) if alto else Vector2i(96,96)
		var lim=Vector2(108,120) if alto else Vector2(76,60) if i<3 or i in [11,15] else Vector2(54,62) if i==22 else Vector2(72,40) if i in [20,21] else Vector2(60,48)
		var pie=Vector2i(64,124) if alto else Vector2i(48,86)
		var im=montar(core(mundo,rec),tam,lim,pie);guardar(im,nombres[i])
		var b=im.get_used_rect();fichas[nombres[i]]={"archivo":"../pendientes_v1/"+nombres[i]+".png","canvas":[tam.x/2,tam.y/2],"pivote":[pie.x/2,pie.y/2],"bbox":[b.position.x/2,b.position.y/2,b.end.x/2,b.end.y/2],"escala_dibujada":1,"resolucion_nativa":[tam.x,tam.y]}
	FileAccess.open(raiz+"catalogo.json",FileAccess.WRITE).store_string(JSON.stringify(fichas,"  "))
	var fauna=ImagenUtil.imagen(raiz+"fauna_fuente.png");fauna.convert(Image.FORMAT_RGBA8)
	var filas=[0,395,710,1004,1368,fauna.get_height()]
	var ids=["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]
	var fuentes=["enemy_specter_normal_earth","enemy_golem_normal_earth","enemy_imp_normal_fire","enemy_harpy_normal_wind","enemy_slime_normal_water"]
	for f in 5:
		var original=ImagenUtil.imagen("res://arte/actores/fauna/"+fuentes[f]+"_idle.png");var fw=original.get_width()/4
		var bbox=original.get_region(Rect2i(0,0,fw,original.get_height())).get_used_rect()
		for c in 3:
			var rec=Rect2i(c*324,filas[f],324,filas[f+1]-filas[f])
			var base=montar(core(fauna,rec),Vector2i(140,180),Vector2(bbox.size.x*140.0/fw,bbox.size.y),Vector2i(70,180))
			for accion in ["idle","attack","hit","defeat"]:
				var cant=2 if accion=="hit" else 4
				var atlas=Image.create(140*cant,180,false,Image.FORMAT_RGBA8);atlas.fill(Color(0,0,0,0))
				for k in cant:
					var cuadro=base.duplicate()
					if accion=="defeat":
						cuadro.resize(140,180-k*26,Image.INTERPOLATE_NEAREST)
					elif accion=="attack":cuadro.resize(140+([0,4,8,0][k]),180,Image.INTERPOLATE_NEAREST)
					elif accion=="hit":cuadro.resize(136,176,Image.INTERPOLATE_NEAREST)
					var dx=0;var dy=0
					if accion=="idle":dy=[0,-2,0,1][k]
					if accion=="defeat":dy=180-cuadro.get_height()
					atlas.blit_rect(cuadro,Rect2i(0,0,mini(140,cuadro.get_width()),cuadro.get_height()),Vector2i(k*140+dx,dy))
				guardar(atlas,"fauna_"+ids[f]+"_"+accion+"_"+str(c+1))
	var equipo=ImagenUtil.imagen(raiz+"equipo_fuente.png");equipo.convert(Image.FORMAT_RGBA8)
	var ew=equipo.get_width();var eh=equipo.get_height()
	for c in 6:
		var im=core(equipo,Rect2i(c*ew/6,0,ew/6,eh/3))
		guardar(montar(im,Vector2i(48,48) if c<3 else Vector2i(36,36),Vector2(44,44) if c<3 else Vector2(32,32),Vector2i(24,46) if c<3 else Vector2i(18,34)),("espada_"+str(c)) if c<3 else "escudo_"+str(c-3))
	for indice in 8:
		var c=indice if indice<6 else indice-6;var f=1 if indice<6 else 2
		var rec=Rect2i(c*ew/6,f*eh/3,ew/6,eh/3)
		var pieza=core(equipo,rec);var arq="ligera" if indice<4 else "pesada";var vista=indice if indice<4 else indice-4
		var corte=int(pieza.get_height()*0.36)
		var cabeza=Image.create(128,128,false,Image.FORMAT_RGBA8);cabeza.fill(Color(0,0,0,0))
		var casco=pieza.get_region(Rect2i(0,0,pieza.get_width(),corte));casco.resize(64,57,Image.INTERPOLATE_NEAREST)
		cabeza.blit_rect(casco,Rect2i(0,0,64,57),Vector2i(32,20))
		var cuerpo=Image.create(128,128,false,Image.FORMAT_RGBA8);cuerpo.fill(Color(0,0,0,0))
		var traje=pieza.get_region(Rect2i(0,corte,pieza.get_width(),pieza.get_height()-corte));traje.resize(54,51,Image.INTERPOLATE_NEAREST)
		cuerpo.blit_rect(traje,Rect2i(0,0,54,51),Vector2i(37,77))
		# Preserve the approved eyes and skin through the open helmet.
		if vista!=2:
			cabeza.fill_rect([Rect2i(45,43,38,30),Rect2i(64,45,22,28),Rect2i(),Rect2i(42,45,22,28)][vista],Color(0,0,0,0))
		guardar(cabeza,arq+"_casco_"+str(vista))
		for slot in ["torso","guantes","pantalones","botas"]:
			var out=Image.create(128,128,false,Image.FORMAT_RGBA8);out.fill(Color(0,0,0,0))
			for y in range(77,128):
				for x in range(32,96):
					var rol="botas" if y>=116 else "pantalones" if y>=106 else "guantes" if y>=91 and (x<50 or x>78) else "torso"
					if rol==slot:out.set_pixel(x,y,cuerpo.get_pixel(x,y))
			guardar(out,arq+"_"+slot+"_"+str(vista))
	for c in range(2,6):
		var im=core(equipo,Rect2i(c*ew/6,2*eh/3,ew/6,eh/3))
		guardar(montar(im,Vector2i(96,96),Vector2(76,64),Vector2i(48,82)),["sombrero","mochila","bolsa","casco_guardia"][c-2])
	print("ARTE_PENDIENTES: 24 objetos; 60 tiras orientadas; 40 capas y 10 accesorios")
	quit()
