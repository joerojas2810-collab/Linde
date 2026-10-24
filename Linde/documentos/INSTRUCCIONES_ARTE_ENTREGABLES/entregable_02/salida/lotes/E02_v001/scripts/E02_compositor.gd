extends RefCounted
## Prototype loader for E02 candidate state atlases. Does not alter the game.
const INDICES = [Color8(255,0,0),Color8(0,255,0),Color8(0,0,255),Color8(128,128,128)]
const ROLES = ["principal","sombra","acento","detalle"]
const STATES = ["herramienta","dano","caida","dormir"]
var manifests: Dictionary = {}
var images: Dictionary = {}
var textures: Dictionary = {}
var palettes: Dictionary
var errors: Array = []

func _init() -> void:
	palettes = JSON.parse_string(FileAccess.get_file_as_string("res://fuentes/entradas/paletas.json")).paletas
	for state in STATES:
		var root: String = "res://assets/"+state+"/"
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root+"E02_estado.json"))
		manifests[state] = m
		for layer in m.base.capas:
			_load(state+"/b_"+str(layer),root+str(m.base.capas[layer]),m)
		for key in m.equipo:
			_load(state+"/"+str(key),root+str(m.equipo[key]),m)
		if m.herramienta is String:
			_load(state+"/hacha",root+str(m.herramienta),m)

func _load(key: String,path: String,m: Dictionary) -> void:
	var img: Image = ImagenUtil.imagen(path)
	if img == null or img.get_size() != Vector2i(int(m.atlas[0]),int(m.atlas[1])):
		errors.append(path)
		return
	images[key] = img

func texture(key: String,palette: String = "") -> ImageTexture:
	var cache_key := key+"|"+palette
	if textures.has(cache_key): return textures[cache_key]
	var a: Image = images[key].duplicate()
	if palette != "":
		for y in a.get_height():
			for x in a.get_width():
				var px := a.get_pixel(x,y)
				if px.a8 == 0: continue
				for i in range(4):
					if px == INDICES[i]:
						a.set_pixel(x,y,Color(palettes[palette].get(ROLES[i],"#808080")))
						break
	textures[cache_key] = ImageTexture.create_from_image(a)
	return textures[cache_key]

func commands(state: String,row: int,logical: int,arq: String,variant: String = "baseline",palette: String = "pal_vigia") -> Array:
	var m: Dictionary = manifests[state]
	var frame: int = int(m.cuadros_runtime_a_fuente[logical])
	var src := Rect2(frame*48,row*48,48,48)
	var out: Array = []
	var bare := variant == "base"
	var order: Array = ["b_cuerpo","b_piel","b_botas","b_pantalon","guantes_lejana","b_tunica","b_cinturon","botas","pantalones","torso","guantes_cercana"]
	if row == 1 and state in ["herramienta","dano"]: order.insert(4,"escudo")
	elif state in ["herramienta","dano"]: order.append("escudo")
	if state == "dano": order.append("espada")
	if variant == "sin_cinturon": order.erase("b_cinturon")
	order.append_array(["casco","b_pelo"] if variant == "pelo_sobre_casco" else ["b_pelo","casco"])
	if state == "herramienta": order.append("hacha")
	for layer in order:
		var key: String
		var pal := ""
		if str(layer).begins_with("b_"):
			if not bare and layer in ["b_tunica","b_pantalon","b_botas"]: continue
			key = state+"/"+str(layer)
		elif layer == "hacha": key=state+"/hacha"
		else:
			if bare: continue
			key=state+"/"+("compartido" if layer in ["escudo","espada"] else arq)+"/"+str(layer)
			pal="pal_escudo_madera" if layer=="escudo" else ("pal_espada_hierro" if layer=="espada" else palette)
		out.append([layer,texture(key,pal),src,Rect2(0,0,48,48)])
	return out
