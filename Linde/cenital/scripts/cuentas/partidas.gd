extends RefCounted
## Guarda mundos locales por identidad; conserva Juego/Guardado como única fuente.
static var raiz:="user://perfiles/"
static func propietario(sesion:Dictionary) -> Dictionary:
	return {"id":sesion.get("id",""),"emisor":sesion.get("emisor","")}

static func carpeta(sesion:Dictionary) -> String:
	var clave=(str(sesion.get("emisor",""))+":"+str(sesion.get("id",""))).sha256_text()
	return raiz.trim_suffix("/")+"/"+clave+"/partidas/"

static func nueva(sesion:Dictionary) -> String:
	var dir=carpeta(sesion)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))!=OK:return ""
	return dir+Crypto.new().generate_random_bytes(16).hex_encode()+".json"

static func datos_propios(path:String,sesion:Dictionary) -> Dictionary:
	# Comprobar dueño/checksum antes de construir el Juego; no adoptar partidas ajenas.
	if ProjectSettings.globalize_path(path).get_base_dir().simplify_path()!=ProjectSettings.globalize_path(carpeta(sesion)).trim_suffix("/").simplify_path():return {}
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var wrapper=JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if not wrapper is Dictionary or not wrapper.get("cuerpo") is String:continue
		if str(wrapper.get("checksum",""))!=wrapper.cuerpo.sha256_text():continue
		var data=JSON.parse_string(wrapper.cuerpo)
		return data if data is Dictionary and data.get("propietario_cuenta",{})==propietario(sesion) and data.get("jugadores") is Dictionary and data.jugadores.get("local") is Dictionary else {}
	return {}

static func listar(sesion:Dictionary) -> Array:
	var out:Array=[];var dir=carpeta(sesion)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):return out
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):continue
		var path=dir+file;var data=datos_propios(path,sesion)
		if data.is_empty():continue
		out.append({"ruta":path,"fecha":FileAccess.get_modified_time(path),"nombre":str(data.jugadores.get("local",{}).get("nombre","Partida")),"semilla":data.get("semilla",0)})
	out.sort_custom(func(a,b):return a.fecha>b.fecha)
	return out

static func marcar(sesion:Dictionary,path:String) -> void:
	if datos_propios(path,sesion).is_empty():return
	var cfg=ConfigFile.new();cfg.set_value("partida","archivo",path.get_file());cfg.save(carpeta(sesion)+"seleccion.cfg")

static func ultima(sesion:Dictionary) -> String:
	var cfg=ConfigFile.new();cfg.load(carpeta(sesion)+"seleccion.cfg")
	var file=str(cfg.get_value("partida","archivo",""))
	if RegEx.create_from_string("^[a-f0-9]{32}\\.json$").search(file)!=null:
		var path=carpeta(sesion)+file
		if not datos_propios(path,sesion).is_empty():return path
	var lista=listar(sesion)
	return "" if lista.is_empty() else str(lista[0].ruta)
