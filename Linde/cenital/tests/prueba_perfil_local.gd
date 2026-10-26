extends SceneTree
## Perfil aislado: nunca usa la identidad ni los guardados del jugador.
var esc
var fallos:=0
func _initialize() -> void:call_deferred("run")
func comprobar(valor:bool,nombre:String) -> void:
	print(("PASS " if valor else "FAIL ")+nombre)
	if not valor:fallos+=1
func run() -> void:
	var salida=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="):salida=arg.trim_prefix("--salida=")
	if salida=="":printerr("Falta --salida=carpeta de prueba nueva");quit(1);return
	salida=ProjectSettings.globalize_path(salida).trim_suffix("/")+"/"
	if DirAccess.dir_exists_absolute(salida):printerr("La salida debe ser nueva");quit(1);return
	DirAccess.make_dir_recursive_absolute(salida)
	var slots=preload("res://scripts/cuentas/partidas.gd")
	slots.raiz=salida+"perfiles/"
	esc=load("res://main.tscn").instantiate();esc.forzar_acceso=true
	esc.cuentas_config_path=salida+"cuentas.cfg"
	root.add_child(esc);esc.set_process(false)
	esc.acceso_panel.perfil_path=salida+"perfil.cfg"
	esc.acceso_panel._local_privado()
	comprobar(esc.modo=="menu" and esc.sesion.get("privado",false),"perfil sin servicio de cuentas abre menú")
	var anterior:Dictionary=esc.sesion.duplicate(true)
	var evento=InputEventKey.new();evento.keycode=KEY_ENTER;evento.pressed=true
	esc.menu_sel=1;esc._tecla_menu_cuenta(evento)
	esc.cr.campo=esc.Aspecto.CAMPOS.size()+1;esc._tecla_creador(evento)
	comprobar(esc.modo=="juego","nueva partida local")
	if esc.j==null:quit(1);return
	var ruta:String=esc.ruta
	esc.j.jug().inv={"madera":9};esc.j.jug().xp=27
	comprobar(esc.j.guardar(ruta),"guardado local")
	esc.j=null;esc.sesion={};esc.acceso_panel._local_privado()
	comprobar(esc.sesion.id==anterior.id,"perfil estable al volver a entrar")
	comprobar(esc._cargar_cuenta(ruta),"carga del mundo del perfil")
	if esc.j!=null:comprobar(esc.j.jug().xp==27 and esc.j.jug().inv.get("madera")==9,"progreso local recuperado")
	var ajena=anterior.duplicate();ajena.id="local:otro"
	comprobar(slots.datos_propios(ruta,ajena).is_empty(),"no atribuye el mundo a otro perfil")
	esc.queue_free();await process_frame;quit(1 if fallos else 0)
