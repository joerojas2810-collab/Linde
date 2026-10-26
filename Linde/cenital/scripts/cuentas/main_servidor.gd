extends SceneTree
## Entrada independiente del servidor seguro; conserva Juego y Guardado de las Fases 1–4.
func _initialize() -> void:call_deferred("iniciar")

func iniciar() -> void:
	var config_path=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--config="):config_path=arg.trim_prefix("--config=")
	var config=JSON.parse_string(FileAccess.get_file_as_string(config_path)) if config_path!="" else null
	if not config is Dictionary:printerr("Falta --config=archivo.json del servidor.");quit(1);return
	# La contraseña de acceso no permanece ni en argumentos ni en el archivo inicial.
	DirAccess.remove_absolute(config_path)
	var port=int(config.get("puerto",7777));var https=int(config.get("https",port+1))
	if port<1 or port>65535 or https<1 or https>65535:printerr("Puertos inválidos.");quit(1);return
	var dir=ProjectSettings.globalize_path(str(config.get("carpeta","user://servidor")))
	DirAccess.make_dir_recursive_absolute(dir);DirAccess.remove_absolute(dir.path_join("detener_servidor"))
	var J=load("res://scripts/juego.gd")
	var path=dir.path_join("mundo.json")
	var game=J.cargar(path)
	if game==null and not J.ultimo_error.is_empty():printerr(J.mensaje_carga(J.ultimo_error));quit(1);return
	if game==null:game=J.nueva(int(config.get("semilla",1)),"Anfitrión",[0,0,0],J.MODO_JUEGO)
	var server=load("res://scripts/cuentas/servidor.gd").new()
	server.name="Red";server.j=game;server.ruta=path;server.puerto=port;server.puerto_cuentas=https
	server.carpeta=dir;server.password=str(config.get("password",""));server.python=str(config.get("python","python"))
	server.autoridad=str(config.get("autoridad",""))
	server.estado_archivo=str(config.get("estado",dir.path_join("estado.json")))
	server.duracion=float(config.get("duracion",0))
	Engine.max_fps=60;root.add_child(server)
