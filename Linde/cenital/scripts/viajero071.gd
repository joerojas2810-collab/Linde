extends RefCounted
const ImgUtil = preload("res://scripts/imagen_util.gd")
# Native 128px drawing -> 32 world units. Cached 192px frames allow limbs/tools to extend beyond the body.
const A=preload("res://scripts/aspecto.gd")
const P=preload("res://scripts/params.gd")
const ART="res://arte/viajero071/"
const DIRS=[Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT]
const ZERO=Color(0,0,0,0)
var images:Dictionary={}
var bases:Dictionary={}
var cache:Dictionary={}
var generados=0

func source(path:String)->Image:
	if not images.has(path):
		var im=ImgUtil.imagen(path)
		if im==null:return null
		im.convert(Image.FORMAT_RGBA8);images[path]=im
	return images[path]

func role(c:Color,x:int,y:int,view:int)->String:
	if c.v<.20 or (c.r>.9 and c.g>.9 and c.b>.9):return "fijo"
	var skin=c.r>.50 and c.g/maxf(c.r,.01)>.64 and c.b/maxf(c.r,.01)>.43 and c.r>c.b
	if y<77:
		if c.v<.50:return "fijo"
		return "piel" if skin else "fijo"
	if skin:return "piel"
	if y>=[117,115,115,115][view]:return "botas"
	var leather=c.r>c.g*1.18 and c.g>c.b*1.10
	if leather:
		if y>=97 and y<=111 and absi(x-64)<20:return "cinturon"
		return "accesorios" if y>=94 else "chaleco"
	if y>=106:return "pantalon"
	return "tunica" if c.b>c.r*1.12 and c.b>c.g*1.08 else "fijo"

func tint(c:Color,target:Color,median:float)->Color:
	return Color.from_hsv(target.h,minf(target.s,.9),clampf(target.v+(c.v-median)*(.48 if target.v<.4 else .8),.05,1),c.a)

func base_image(look:Array,view:int)->Image:
	var key=str(look)+str(view)
	if bases.has(key):return bases[key]
	var im:Image=source(ART+"bases/%d.png"%view).duplicate()
	var targets={"piel":P.PIEL[A.indice(look,0)],"tunica":P.ROPA[A.indice(look,2)],"pantalon":A.PANTALONES[A.indice(look,5)],"botas":A.BOTAS[A.indice(look,6)],"cinturon":A.CINTURONES[A.indice(look,7)]}
	var defaults={"piel":A.indice(look,0)==0,"tunica":A.indice(look,2)==0,"pantalon":A.indice(look,5)==0,"botas":A.indice(look,6)==0,"cinturon":A.indice(look,7)==0}
	var values={}
	for r in targets:values[r]=[]
	for y in 128:
		for x in 128:
			var c=im.get_pixel(x,y)
			if c.a8==0:continue
			var r=role(c,x,y,view)
			if values.has(r):values[r].append(c.v)
	var med={}
	for r in values:
		values[r].sort();med[r]=values[r][values[r].size()/2] if not values[r].is_empty() else .5
	for y in 128:
		for x in 128:
			var c=im.get_pixel(x,y)
			if c.a8==0:continue
			var r=role(c,x,y,view)
			if targets.has(r) and not defaults[r]:im.set_pixel(x,y,tint(c,targets[r],med[r]))
	if bases.size()>=96:bases.erase(bases.keys()[0])
	bases[key]=im
	return im

func hair_image(look:Array,view:int)->Image:
	var style=A.estilo_visual(look) if look.size()==8 else 0
	var im:Image=source(ART+"pelo/%d_%d.png"%[style,view])
	if A.indice(look,1)==1:return im
	var key="hair"+str(style)+str(view)+str(A.indice(look,1))
	if images.has(key):return images[key]
	var out:Image=im.duplicate();var target:Color=P.PELO[A.indice(look,1)]
	for y in 128:
		for x in 128:
			var c=out.get_pixel(x,y)
			if c.a8>0 and c.v>.18:out.set_pixel(x,y,tint(c,target,.72))
	images[key]=out;return out

func arm_left(view:int)->Vector2:return [Vector2(47,84),Vector2(53,84),Vector2(47,84),Vector2(49,88)][view]
func arm_right(view:int)->Vector2:return [Vector2(81,84),Vector2(79,88),Vector2(81,84),Vector2(75,84)][view]
func part(x:int,y:int,view:int)->String:
	if y<77:return "head"
	if y>=110:return "leg0" if x<64 else "leg1"
	var left=x<51 if view in [0,2] else x<61 if view==1 else x<49
	var right=x>77 if view in [0,2] else x>79 if view==1 else x>67
	if y>=81 and y<110 and (left or right):return "arm0" if left else "arm1"
	if y>=106:return "leg0" if x<64 else "leg1"
	return "body"

func pose(view:int,state:String,frame:int)->Dictionary:
	var v={"head":Transform2D.IDENTITY,"body":Transform2D.IDENTITY,"arm0":Transform2D.IDENTITY,"arm1":Transform2D.IDENTITY,"leg0":Transform2D.IDENTITY,"leg1":Transform2D.IDENTITY}
	var step=[0.0,1.0,0.0,-1.0][posmod(frame,4)]
	var a0=0.0;var a1=0.0;var l0=0.0;var l1=0.0;var bob=0.0
	var weapon=1 if view in ([1,2] if state=="herramienta" else [2,3]) else 0
	if state=="caminar":
		a0=step*12;a1=-step*12;l0=-step*(16 if view in [1,3] else 9);l1=-l0;bob=-2*absf(step)
	elif state in ["ataque","herramienta"]:
		var ang=[55.0,145.0,-60.0,30.0][posmod(frame,4)] if state=="ataque" else [140.0,-60.0,25.0][posmod(frame,3)]
		if weapon==0:a0=ang;a1=-12
		else:a1=-ang;a0=12
		bob=-1.0 if frame==1 else 0.0
	elif state=="dano":
		a0=18 if frame==0 else 8;a1=-a0;bob=1 if frame==0 else 0
	for key in v:v[key]=Transform2D(0,Vector2(0,bob if key not in ["leg0","leg1"] else 0))
	for pair in [["arm0",a0,arm_left(view)],["arm1",a1,arm_right(view)],["leg0",l0,Vector2(58,107)],["leg1",l1,Vector2(70,107)]]:
		var angle=deg_to_rad(pair[1]);var pivot:Vector2=pair[2]
		v[pair[0]]=Transform2D(angle,pivot-pivot.rotated(angle)+Vector2(0,bob if str(pair[0]).begins_with("arm") else 0))
	var aims=[[45.0,-90.0,135.0,45.0],[20.0,-90.0,45.0,20.0],[-135.0,90.0,-45.0,-135.0],[-90.0,45.0,-135.0,-90.0]][view]
	if state=="herramienta" and view in [1,3]:aims=[45.0,135.0,90.0,45.0] if view==1 else [-45.0,-135.0,-90.0,-45.0]
	v._weapon_rotation=deg_to_rad(aims[posmod(frame,4)] if state=="ataque" else aims[[1,2,0][posmod(frame,3)]] if state=="herramienta" else aims[0])
	return v

# Inverse nearest sampling avoids holes when reusing articulated pixel layers.
func warp(dst:Image,src:Image,t:Transform2D,region:String,view:int,base_layer:bool=false):
	var inverse=t.affine_inverse()
	var rects={"head":Rect2i(26,18,76,59),"body":Rect2i(32,77,64,36),"arm0":Rect2i(26,80,38,30),"arm1":Rect2i(64,80,38,30),"leg0":Rect2i(30,106,34,22),"leg1":Rect2i(64,106,34,22)}
	var used:Rect2i=src.get_used_rect()
	if region!="all":used=used.intersection(rects[region])
	if not used.has_area():return
	var bounds=t*Rect2(used)
	var x0=maxi(0,floori(bounds.position.x)+32);var x1=mini(192,ceili(bounds.end.x)+32)
	var y0=maxi(0,floori(bounds.position.y)+64);var y1=mini(192,ceili(bounds.end.y)+64)
	for y in range(y0,y1):
		for x in range(x0,x1):
			var p=inverse*(Vector2(x-32,y-64)+Vector2(.5,.5));var ix=floori(p.x);var iy=floori(p.y)
			if ix<0 or ix>=128 or iy<0 or iy>=128:continue
			var c=src.get_pixel(ix,iy)
			var actual_part=part(ix,iy,view)
			if base_layer:
				var bags=[Rect2i(72,94,12,19),Rect2i(67,95,11,17),Rect2i(48,96,10,17),Rect2i(49,95,11,18)]
				var r=role(c,ix,iy,view)
				if bags[view].has_point(Vector2i(ix,iy)) and r in ["cinturon","accesorios","fijo"]:actual_part="body"
				elif Rect2i(51,98,26,8).has_point(Vector2i(ix,iy)) and r=="cinturon":actual_part="body"
			if region!="all" and actual_part!=region:continue
			if c.a8>0:dst.set_pixel(x,y,c if c.a8==255 else dst.get_pixel(x,y).blend(c))

func equipment_image(e:Dictionary,view:int)->Image:
	var path=ART+"equipo/%s_%s_%d.png"%[e.get("arquetipo","media"),e.ranura,view]
	if e.ranura!="casco" and e.get("arquetipo","") in ["ligera","pesada"]:path="res://arte/pendientes_v1/%s_%s_%d.png"%[e.arquetipo,e.ranura,view]
	var im:Image=source(path)
	if im==null:return null
	var key=path+JSON.stringify(e.get("paleta",{}))+JSON.stringify(e.get("delta",{}))
	if images.has(key):return images[key]
	var out:Image=im.duplicate();var pal:Dictionary=e.get("paleta",{});var delta:Dictionary=e.get("delta",{})
	var main=Color(str(pal.get("principal","#7d8794")))
	for y in 128:
		for x in 128:
			var c=im.get_pixel(x,y)
			if c.a8==0 or c.v<.15:continue
			var leather=c.r>c.b*1.25
			var gold=c.r>.6 and c.g>.35 and c.b<.3
			if not gold and (not leather or e.get("arquetipo","")=="ligera"):
				c=tint(c,main,.57 if e.get("arquetipo","")=="ligera" else .62)
			elif gold:c=Color(str(pal.get("acento","#c9a227")))
			c=Color.from_hsv(fposmod(c.h+float(delta.get("tono",0)),1),clampf(c.s+float(delta.get("saturacion",0)),0,1),clampf(c.v+float(delta.get("brillo",0)),0,1),c.a)
			out.set_pixel(x,y,c)
	images[key]=out;return out

func held_image(name:String,palette:Dictionary={})->Image:
	var key="held"+name+JSON.stringify(palette)
	if images.has(key):return images[key]
	var path="res://arte/interfaz/reutilizados/"+{"espada":"espada_hierro","escudo":"escudo","hacha":"hacha_piedra","pico":"pico_piedra"}[name]+".png"
	if name in ["espada","escudo"]:
		path="res://arte/pendientes_v1/"+name+"_"+str(clampi(int(palette.get("_silueta",0)),0,2))+".png"
	var src:Image=source(path).duplicate();src.resize(48 if name!="escudo" else 36,48 if name!="escudo" else 36,Image.INTERPOLATE_NEAREST)
	if palette.has("principal"):
		var target=Color(str(palette.get("principal", "#e0e4ea")))
		for y in src.get_height():
			for x in src.get_width():
				var c=src.get_pixel(x,y)
				if c.a8==0 or c.v<.20:continue
				var metal=c.s<.25 or c.b>c.r*1.08
				var wood=c.r>c.b*1.2 and c.s>.25
				if (name=="espada" and metal) or (name=="escudo" and wood):src.set_pixel(x,y,tint(c,target,.72 if name=="espada" else .52))
	images[key]=src;return src

func held(dst:Image,name:String,view:int,poses:Dictionary,weapon:bool,palette:Dictionary={}):
	var side=(1 if view in ([1,2] if name in ["pico","hacha"] else [2,3]) else 0) if weapon else (0 if view in [2,3] else 1)
	var key="arm%d"%side;var t:Transform2D=poses[key]
	var hand=(arm_left(view) if side==0 else arm_right(view))+Vector2(-2 if side==0 else 2,20)
	if weapon:
		var wrist=float(poses._weapon_rotation)-t.get_rotation()
		t=t*Transform2D(wrist,hand-hand.rotated(wrist))
	var img=held_image(name,palette);var base=Image.create(128,128,false,Image.FORMAT_RGBA8)
	var grip=Vector2i(14,33) if name=="espada" else Vector2i(18,31) if name in ["pico","hacha"] else Vector2i(18,18)
	var p=Vector2i(hand)-grip
	base.blit_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),p)
	warp(dst,base,t,"all",view)

func trail(dst:Image,view:int,poses:Dictionary):
	var source_trail=source("res://arte/equipo/ataque/E01_estela_ataque.png")
	var patch=source_trail.get_region(Rect2i(2*48,view*48,48,48))
	if not patch.get_used_rect().has_area():patch=source_trail.get_region(Rect2i(3*48,view*48,48,48))
	if not patch.get_used_rect().has_area():return
	patch=patch.get_region(patch.get_used_rect());patch.resize(12,18,Image.INTERPOLATE_NEAREST)
	var side=1 if view in [2,3] else 0
	var hand=(arm_left(view) if side==0 else arm_right(view))+Vector2(-2 if side==0 else 2,20)
	var t:Transform2D=poses["arm%d"%side]
	var wrist=float(poses._weapon_rotation)-t.get_rotation();t=t*Transform2D(wrist,hand-hand.rotated(wrist))
	var layer=Image.create(128,128,false,Image.FORMAT_RGBA8)
	layer.blit_rect(patch,Rect2i(Vector2i.ZERO,patch.get_size()),Vector2i(hand)+Vector2i(17,-30))
	warp(dst,layer,t,"all",view)

func image(look:Array,view:int,state:String,frame:int,equipment:Array=[],tool:String="")->Image:
	var poses=pose(view,state,frame)
	var base=base_image(look,view);var hair=hair_image(look,view)
	var result=Image.create(192,192,false,Image.FORMAT_RGBA8)
	var style=A.estilo_visual(look) if look.size()==8 else 0
	var front_hair:Image=hair
	if view!=2 and style in [2,8,9]:
		var back:Image=hair.duplicate();back.fill_rect(Rect2i(0,0,128,77),ZERO)
		front_hair=hair.duplicate();front_hair.fill_rect(Rect2i(0,77,128,51),ZERO)
		warp(result,back,poses.head,"all",view)
	var pieces={}
	for e in equipment:
		if e is Dictionary and str(e.get("ranura","")) in ["casco","torso","guantes","pantalones","botas"]:pieces[e.ranura]=equipment_image(e,view)
	var sword_palette:Dictionary={}
	var shield_palette:Dictionary={}
	for entry in equipment:
		if not entry is Dictionary:continue
		if entry.get("ranura", "")=="espada":sword_palette=entry.get("paleta", {}).duplicate();sword_palette._silueta=["ligera","media","pesada"].find(entry.get("arquetipo","ligera"))
		elif entry.get("ranura", "")=="escudo":shield_palette=entry.get("paleta", {}).duplicate();shield_palette._silueta=["ligera","media","pesada"].find(entry.get("arquetipo","ligera"))
	var shield=equipment.any(func(e):return e is Dictionary and e.get("ranura","")=="escudo")
	var sword=equipment.any(func(e):return e is Dictionary and e.get("ranura","")=="espada")
	var lying=state in ["caida","dormir"]
	if shield and view==1 and not lying:held(result,"escudo",view,poses,false,shield_palette)
	if sword and view in [2,3] and state!="herramienta" and not lying:held(result,"espada",view,poses,true,sword_palette)
	if state=="ataque" and sword and frame==2 and view in [2,3]:trail(result,view,poses)
	for region in ["leg0","leg1","body","head","arm0","arm1"]:
		warp(result,base,poses[region],region,view,true)
		for slot in ["botas","pantalones","torso","guantes"]:
			if pieces.has(slot):warp(result,pieces[slot],poses[region],region,view)
	# Belt remains visible over armor. No new equipment slot is introduced.
	if pieces.has("torso"):
		var belt=Image.create(128,128,false,Image.FORMAT_RGBA8)
		for y in range(98,108):
			for x in range(50,79):
				var c=base.get_pixel(x,y)
				if c.a8>0 and role(c,x,y,view)=="cinturon":belt.set_pixel(x,y,c)
		warp(result,belt,poses.body,"all",view)
	warp(result,front_hair,poses.head,"all",view)
	if pieces.has("casco"):warp(result,pieces.casco,poses.head,"all",view)
	if shield and view!=1 and not lying:held(result,"escudo",view,poses,false,shield_palette)
	if sword and view not in [2,3] and state!="herramienta" and not lying:held(result,"espada",view,poses,true,sword_palette)
	if state=="herramienta" and tool in ["hacha","pico"]:held(result,tool,view,poses,true)
	if state=="ataque" and sword and frame==2 and view not in [2,3]:trail(result,view,poses)
	if lying:
		var turned=Image.create(192,192,false,Image.FORMAT_RGBA8)
		# Reuse assembled appearance for lying presentation, without introducing game events.
		var crop=result.get_region(Rect2i(32,64,128,128));crop.rotate_90(CLOCKWISE if view in [0,1] else COUNTERCLOCKWISE)
		turned.blit_rect(crop,Rect2i(0,0,128,128),Vector2i(32,96));result=turned
	return result

func texture(look:Array,dir:Vector2i,state:String,frame:int,equipment:Array,tool:String)->Texture2D:
	var view=DIRS.find(dir);if view<0:view=0
	if state not in ["caminar","ataque","herramienta","dano","caida","dormir"]:state="reposo";frame=0
	var key=JSON.stringify([look,view,state,frame,equipment,tool])
	if not cache.has(key):
		if cache.size()>=384:cache.erase(cache.keys()[0])
		cache[key]=ImageTexture.create_from_image(image(look,view,state,frame,equipment,tool));generados+=1
	return cache[key]

## Capa reutilizada para ordenar el útil sobre su objetivo, nunca sobre todo el escenario.
func herramienta_textura(dir:Vector2i,frame:int,tool:String)->Texture2D:
	var view=DIRS.find(dir);if view<0:view=0
	var key="util:"+str([view,frame,tool])
	if not cache.has(key):
		if cache.size()>=384:cache.erase(cache.keys()[0])
		var im=Image.create(192,192,false,Image.FORMAT_RGBA8)
		held(im,tool,view,pose(view,"herramienta",frame),true)
		cache[key]=ImageTexture.create_from_image(im)
	return cache[key]
