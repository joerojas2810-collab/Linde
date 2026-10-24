extends Node2D
## Isolated world-data preview. Source World/Params/Catalogs are copied unmodified.
const DOMAIN := "05"
const HAS_HOUSE := true
const World = preload("res://scripts/mundo.gd")
const Renderer = preload("res://scripts/E04_renderer.gd")
var world = World.new()
var art
var player := Vector2.ZERO
var direction := Vector2i.DOWN
var camera := Vector2.ZERO
var clock := 0.0
var walk_time := 0.0
var capture := false
var exhausted := false
var show_collisions := false
var roof_hidden := false
var door_open := false
var catalog := false
var ghost := false
var checks := 0
var failures: Array = []
var textures: Dictionary = {}
var objects05: Dictionary = {}
var house: Dictionary = {}
var stage: Node2D
var view: SubViewport

func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label);push_error(label)

func tex(path: String) -> Texture2D:
	if not textures.has(path):textures[path]=load(path) as Texture2D
	return textures[path]

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	art=Renderer.new("res://fuentes/dependencias/E04_v002/assets" if HAS_HOUSE else "res://assets")
	if HAS_HOUSE:
		house=JSON.parse_string(FileAccess.get_file_as_string("res://assets/E05_casa_modular.json"))
		objects05=JSON.parse_string(FileAccess.get_file_as_string("res://assets/E05_objetos.json"))
	view=SubViewport.new();view.size=Vector2i(1152,672);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(view);stage=Node2D.new();view.add_child(stage);stage.draw.connect(_draw_world)
	_run_checks()
	if not failures.is_empty():get_tree().quit(1);return
	player=World.pies_de_celda(Vector2i(27,23) if HAS_HOUSE else Vector2i(45,15));camera=player
	capture="--capturas" in OS.get_cmdline_user_args()
	if capture:
		var cases: Array=["exterior","interior","puerta_abierta","catalogo","fantasmas"] if HAS_HOUSE else ["bosque_48","bosque_64","agotados","lago","camino"]
		for name in cases:
			_set_case(name)
			for i in range(60):await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var result:=get_viewport().get_texture().get_image().save_png("res://validacion/E"+DOMAIN+"_"+str(name)+".png")
			check(result==OK,"captura "+str(name))
			print("E",DOMAIN," captura ",name," resultado=",result)
		_save_results()
		get_tree().quit(0 if failures.is_empty() else 1)
	else:_save_results()

func _run_checks() -> void:
	for kind in ["path","water","ruins","wall"]:
		check(art.mapping[kind].size()==47,"47 patrones "+kind)
		for mask_value in range(256):check(art.mapping[kind].has(str(art.normalized(mask_value))),"mask sin patrón")
	for y in range(World.ALTO):
		for x in range(World.ANCHO):
			var c:=Vector2i(x,y);var t: int=world.tipo(c)
			if t in [1,2,3,6,7]:
				var kind: String="path" if t==1 else "water" if t==2 else "ruins" if t==6 else "wall"
				check(art.mapping[kind].has(str(art.neighbors(world,c,t))),"celda mapa sin tile")
	var original=World.new()
	check(original.celdas==world.celdas,"mapa inicial alterado")
	check(World.CASA==Rect2i(24,16,8,7) and World.PUERTA_C==Vector2i(27,22),"geometría casa")
	for kind in ["arbol","roca","veta","arbusto"]:
		for id in world.objetos:
			if world.objetos[id].t!=kind:continue
			var c: Vector2i=world.objetos[id].c
			check(not art.natural_commands(kind,c,false).is_empty(),"natural sin textura")
			check(not art.natural_commands(kind,c,true).is_empty(),"agotado sin textura")
			world.estado.rotos[id]=true;world.cambiar()
			check(world.objeto_presente(c)=="" and not world.bloquea(c),"agotado conserva colisión")
			world.estado.rotos.erase(id);world.cambiar();break
	check(world.celdas==original.celdas,"agotamiento cambió terreno")
	check(art.errors.is_empty(),"texturas faltantes E04")
	if HAS_HOUSE:
		var local: Vector2=World.pies_de_celda(World.PUERTA_C)-Vector2(World.CASA.position)*16
		check(local==Vector2(56,108),"pies puerta no corresponden")
		check(house.casa_logica.pies_celda_puerta_local==[56.0,108.0],"ancla contrato puerta")
		for name in house.partes:
			var t: Texture2D=tex("res://assets/"+str(house.partes[name]))
			check(t!=null and t.get_size()==Vector2(160,160),"capa casa incompatible")
		for m in range(16):
			var file: String="res://assets/E05_valla_mask_%02d.png" % m
			check(tex(file).get_size()==Vector2(48,64),"valla incompatible")
		check(tex("res://assets/E05_cofre_abierto_alineado.png").get_size()==Vector2(48,48),"cofre incompatible")
	print("E",DOMAIN," QA: ",checks," comprobaciones; ",failures.size()," fallos")

func _save_results() -> void:
	var f:=FileAccess.open("res://validacion/E"+DOMAIN+"_motor.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"motor":Engine.get_version_info(),"comprobaciones":checks,"fallos":failures,"mundo_sha256":FileAccess.get_sha256("res://scripts/mundo.gd"),"mapa_dimensiones":[World.ANCHO,World.ALTO],"mapa_celdas":Array(world.celdas),"alcance":"Preview sobre datos/collisiones existentes; no juego activo, sin red ni guardados"},"  "));f.close()

func _set_case(name: String) -> void:
	_set_exhausted(false);catalog=false;ghost=false;roof_hidden=false;door_open=false;art.trees_large=true
	match name:
		"bosque_48","bosque_64","agotados":
			player=World.pies_de_celda(Vector2i(45,15));camera=World.pies_de_celda(Vector2i(48,11));art.trees_large=name!="bosque_48"
			if name=="agotados":_set_exhausted(true)
		"lago":player=World.pies_de_celda(Vector2i(42,31));camera=World.pies_de_celda(Vector2i(46,31))
		"camino":player=World.pies_de_celda(Vector2i(32,25));camera=World.pies_de_celda(Vector2i(36,26))
		"interior":player=World.pies_de_celda(Vector2i(27,20));camera=World.pies_de_celda(Vector2i(28,19));roof_hidden=true;door_open=true
		"catalogo","fantasmas":catalog=true;ghost=name=="fantasmas"
		_:player=World.pies_de_celda(Vector2i(27,23));camera=World.pies_de_celda(Vector2i(28,19));door_open=name=="puerta_abierta"
	queue_redraw();stage.queue_redraw()

func _set_exhausted(value: bool) -> void:
	exhausted=value
	for id in world.objetos:
		if world.objetos[id].t in ["arbol","roca","veta","arbusto"]:
			if value:world.estado.rotos[id]=true
			else:world.estado.rotos.erase(id)
	world.cambiar()

func _process(dt: float) -> void:
	clock+=dt
	if stage==null:return
	if not capture and not catalog:
		var movement:=Vector2i.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):movement=Vector2i.UP
		elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):movement=Vector2i.DOWN
		elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):movement=Vector2i.LEFT
		elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):movement=Vector2i.RIGHT
		if movement!=Vector2i.ZERO:
			direction=movement;player=world.mover(player,Vector2(movement)*64*minf(dt,.033));walk_time+=dt;camera=player
		else:walk_time=0
		if HAS_HOUSE:roof_hidden=World.CASA.has_point(World.celda_de(player))
	stage.queue_redraw();queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():return
	match event.keycode:
		KEY_H:_set_exhausted(not exhausted)
		KEY_T:art.trees_large=not art.trees_large
		KEY_C:door_open=not door_open
		KEY_O:art.crown_alpha=.3 if art.crown_alpha==1 else 1.0
		KEY_F1:show_collisions=not show_collisions
		KEY_1:_set_case("exterior" if HAS_HOUSE else "bosque_64")
		KEY_2:_set_case("interior" if HAS_HOUSE else "lago")
		KEY_3:_set_case("catalogo" if HAS_HOUSE else "camino")
		KEY_4:_set_case("fantasmas" if HAS_HOUSE else "agotados")
		KEY_ESCAPE:get_tree().quit()

func _draw() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(24,34),"LINDE · E"+DOMAIN+" v002 · "+("casa modular y objetos" if HAS_HOUSE else "terreno y naturaleza"),HORIZONTAL_ALIGNMENT_LEFT,-1,24)
	if view!=null:draw_texture_rect(view.get_texture(),Rect2(24,70,1152,672),false)
	draw_string(ThemeDB.fallback_font,Vector2(24,58),"Fuentes reutilizadas · datos del mapa real · preview aislado, sin partidas ni eventos nuevos",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
	draw_string(ThemeDB.fallback_font,Vector2(24,766),"WASD mover · 1/2/3/4 vistas · H agotados · T árboles48/64 · O copas · C puerta · F1 colisiones · Esc salir",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
	draw_string(ThemeDB.fallback_font,Vector2(24,791),"Propuesta visual pendiente de recepción. El catálogo/ghost no añade construcciones al mapa.",HORIZONTAL_ALIGNMENT_LEFT,-1,14)

func _draw_world() -> void:
	if catalog:_draw_catalog();return
	var origin: Vector2=camera-Vector2(192,112)
	stage.draw_set_transform(-origin*3,0,Vector2(3,3))
	var top:=Vector2i((origin/16).floor())
	for y in range(maxi(0,top.y-1),mini(World.ALTO,top.y+16)):
		for x in range(maxi(0,top.x-1),mini(World.ANCHO,top.x+26)):art.draw_ground(stage,world,Vector2i(x,y),clock)
	var base: Vector2=Vector2(World.CASA.position)*16-Vector2(16,32)
	if HAS_HOUSE:
		stage.draw_texture_rect(tex("res://assets/E05_casa_interior_160.png"),Rect2(base,Vector2(160,160)),false)
		stage.draw_texture_rect(tex("res://assets/E05_casa_paredes_interior_160.png"),Rect2(base,Vector2(160,160)),false)
	var ordered: Array=[[player.y,"player",null]]
	for id in world.objetos:
		var o: Dictionary=world.objetos[id]
		if Rect2(origin-Vector2(80,80),Vector2(544,384)).has_point(Vector2(o.c)*16):ordered.append([(o.c.y+1)*16,"object",o,id])
	if HAS_HOUSE:ordered.append([World.CASA.end.y*16-8,"facade",null])
	ordered.sort_custom(func(a,b):return a[0]<b[0])
	for item in ordered:
		if item[1]=="player":
			var row: int=0 if direction==Vector2i.DOWN else 1 if direction==Vector2i.RIGHT else 2 if direction==Vector2i.UP else 3
			var frame: int=int(walk_time/.12)%4
			stage.draw_texture_rect_region(tex("res://fuentes/entradas/E00_personaje_escala.png"),Rect2(player-Vector2(16,32),Vector2(32,32)),Rect2(frame*32,row*32,32,32))
		elif item[1]=="facade":
			var alpha: float=.25 if roof_hidden else 1.0
			stage.draw_texture_rect(tex("res://assets/E05_casa_fachada_160.png"),Rect2(base,Vector2(160,160)),false,Color(1,1,1,alpha))
			stage.draw_texture_rect(tex("res://assets/E05_casa_puerta_"+("abierta" if door_open else "cerrada")+"_160.png"),Rect2(base,Vector2(160,160)),false,Color(1,1,1,alpha))
		else:
			var o: Dictionary=item[2]
			if o.t in ["arbol","roca","veta","arbusto"]:art.draw_natural(stage,o.t,o.c,world.estado.rotos.has(item[3]),player)
			elif HAS_HOUSE:
				var feet:=Vector2(o.c)*16+Vector2(8,16)
				if o.t=="barril":_draw_prop("barrel",feet)
				elif o.t=="cofre_fijo":stage.draw_texture_rect(tex("res://assets/E05_cofre_cerrado_alineado.png"),Rect2(feet-Vector2(24,44),Vector2(48,48)),false)
				elif o.t=="valla":
					var mask_value: int=0
					for d in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
						var key: String=world.por_celda.get(o.c+d[0],"")
						if key!="" and world.objetos[key].t=="valla":mask_value=mask_value | int(d[1])
					stage.draw_texture_rect(tex("res://assets/E05_valla_mask_%02d.png" % mask_value),Rect2(feet-Vector2(24,40),Vector2(48,64)),false)
	if HAS_HOUSE:
		_draw_prop("bed",World.pies_de_celda(World.CAMA_MAREN))
		if not roof_hidden:stage.draw_texture_rect(tex("res://assets/E05_casa_tejado_160.png"),Rect2(base,Vector2(160,160)),false)
	if show_collisions:
		for y in range(maxi(0,top.y),mini(World.ALTO,top.y+15)):
			for x in range(maxi(0,top.x),mini(World.ANCHO,top.x+25)):
				if world.bloquea(Vector2i(x,y)):stage.draw_rect(Rect2(x*16,y*16,16,16),Color(1,.1,.1,.25))
	stage.draw_set_transform(Vector2.ZERO)

func _draw_prop(name: String,feet: Vector2,tint: Color = Color.WHITE) -> void:
	var data: Dictionary=objects05[name]
	stage.draw_texture_rect(tex("res://assets/"+str(data.archivo)),Rect2(feet-Vector2(data.pivote[0],data.pivote[1]),Vector2(data.canvas[0],data.canvas[1])),false,tint)

func _draw_catalog() -> void:
	stage.draw_set_transform(Vector2.ZERO,0,Vector2(3,3))
	for y in range(14):
		for x in range(24):stage.draw_texture_rect(art.texture("E04_grass_periodica.png"),Rect2(x*16,y*16,16,16),false)
	var names: Array=["workbench","furnace","bed","palisade","floor_wood"] if ghost else ["barrel","workbench","furnace","bed","palisade"]
	for i in range(names.size()):_draw_prop(names[i],Vector2(38+i*69,75),Color(.3,1,.6,.5) if ghost else Color.WHITE)
	for i in range(16):
		var feet:=Vector2(24+(i%8)*46,128+(i/8)*61)
		stage.draw_texture_rect(tex("res://assets/E05_valla_mask_%02d.png" % i),Rect2(feet-Vector2(24,40),Vector2(48,64)),false)
	for i in range(2):stage.draw_texture_rect(tex("res://assets/E05_cofre_"+("cerrado" if i==0 else "abierto")+"_alineado.png"),Rect2(115+i*70,20,48,48),false,Color(.3,1,.6,.5) if ghost else Color.WHITE)
	stage.draw_set_transform(Vector2.ZERO)
