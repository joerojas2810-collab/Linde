extends RefCounted
## Read-only E04 preview renderer. Uses existing world data, not replacement rules.
var base_path: String
var mapping: Dictionary
var objects: Dictionary
var textures: Dictionary = {}
var errors: Array = []
var trees_large := true
var crown_alpha := 1.0

func _init(path: String = "res://assets") -> void:
	base_path=path
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"/E04_catalogo.json"))
	mapping=catalog.mapping
	objects=JSON.parse_string(FileAccess.get_file_as_string(path+"/E04_objetos.json"))

func texture(file: String) -> Texture2D:
	if not textures.has(file):
		var path: String=base_path+"/"+file
		if not ResourceLoader.exists(path):errors.append(path);return null
		textures[file]=load(path) as Texture2D
	return textures[file]

func normalized(mask_value: int) -> int:
	var m: int=mask_value
	for q in [[1,2,16],[2,4,32],[4,8,64],[8,1,128]]:
		if not ((m & int(q[0]))!=0 and (m & int(q[1]))!=0):m=m & ~int(q[2])
	return m

func neighbors(world,c: Vector2i,t: int) -> int:
	var value: int=0
	var ns: Array=[[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8],[Vector2i(1,-1),16],[Vector2i(1,1),32],[Vector2i(-1,1),64],[Vector2i(-1,-1),128]]
	for n in ns:
		if world.tipo(c+n[0])==t:value=value | int(n[1])
	return normalized(value)

func draw_ground(ci: CanvasItem,world,c: Vector2i,time: float) -> void:
	var t: int=world.tipo(c)
	var kind: String="path" if t==1 else "water" if t==2 else "ruins" if t==6 else "wall" if t in [3,7] else ""
	var dst:=Rect2(Vector2(c)*16,Vector2(16,16))
	if kind=="":ci.draw_texture_rect(texture("E04_grass_periodica.png"),dst,false);return
	var m: int=neighbors(world,c,t)
	var p: Array=mapping[kind][str(m)]
	var frame: int=int(time/.15)%4 if kind=="water" else 0
	var file: String="E04_water_47_anim.png" if kind=="water" else "E04_"+kind+"_47.png"
	ci.draw_texture_rect_region(texture(file),dst,Rect2(int(p[0])*16+frame*128,int(p[1])*16,16,16))

func natural_commands(kind: String,c: Vector2i,exhausted: bool) -> Array:
	var key: String
	if kind=="arbol":
		var names: Array=["broadleaf","pine","fruit"]
		var name: String=names[posmod(c.x*7+c.y*3,3)]
		key="E04_stump_"+name if exhausted else "E04_tree_"+name+("_64" if trees_large else "")
	elif kind=="roca":key="E04_rock_depleted" if exhausted else "E04_rock"
	elif kind=="veta":key="E04_ore_depleted" if exhausted else "E04_ore_copper"
	elif kind=="arbusto":key="E04_bush_without_berries" if exhausted else "E04_bush_berries"
	else:return []
	var feet:=Vector2(c)*16+Vector2(8,16)
	var keys: Array=[key+"_tronco",key+"_copa"] if kind=="arbol" and not exhausted else [key]
	var commands: Array=[]
	for k in keys:
		var data: Dictionary=objects[k]
		var pivot:=Vector2(float(data.pivote[0]),float(data.pivote[1]))
		var size:=Vector2(float(data.canvas[0]),float(data.canvas[1]))
		commands.append([texture(data.archivo),Rect2((feet-pivot).round(),size),crown_alpha if str(k).ends_with("_copa") else 1.0,k])
	return commands

func draw_natural(ci: CanvasItem,kind: String,c: Vector2i,exhausted: bool,player: Vector2 = Vector2.INF) -> void:
	for cmd in natural_commands(kind,c,exhausted):
		var alpha: float=cmd[2]
		# Presentation only: make an obscuring crown translucent, keeping trunk/depth.
		if str(cmd[3]).ends_with("_copa") and (c.y+1)*16>=player.y and (cmd[1] as Rect2).has_point(player-Vector2(0,14)):alpha=minf(alpha,.4)
		ci.draw_texture_rect(cmd[0],cmd[1],false,Color(1,1,1,alpha))
