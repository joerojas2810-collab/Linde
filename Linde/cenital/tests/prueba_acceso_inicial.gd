extends SceneTree
var esc
var cfg:Dictionary
var checks:Array=[]
var out:String
const Slots=preload("res://scripts/cuentas/partidas.gd")
func _initialize():call_deferred("run")
func ok(value:bool,name:String):
	checks.append({"prueba":name,"ok":value});print(("PASS " if value else "FAIL ")+name)
	if not value:fin(1);return
func foto(name:String):
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")
func key()->InputEventKey:
	var e=InputEventKey.new();e.keycode=KEY_ENTER;e.pressed=true;return e
func registrar(user:String,name:String):
	var a=esc.acceso_panel;a.registro=true;a._formulario()
	a.campos.usuario.text=user;a.campos.password.text="ClaveLinde123!";a.campos.confirmar.text="ClaveLinde123!";a.campos.nombre.text=name
	await a.autenticar()
func nuevo():
	esc.menu_sel=1;esc._tecla_menu(key());esc.cr.campo=esc.Aspecto.CAMPOS.size()+1;esc._tecla_creador(key())
func run():
	var path=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--config="):path=arg.trim_prefix("--config=")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(path));out=str(cfg.salida).trim_suffix("/")+"/";DirAccess.make_dir_recursive_absolute(out)
	Slots.raiz=out+"perfiles/"
	root.size=Vector2i(1280,720);esc=load("res://main.tscn").instantiate();esc.forzar_acceso=true;esc.cuentas_config_path=out+"conexion_test.cfg";root.add_child(esc);esc.set_process(false)
	ok(esc.modo=="cuentas" and esc.sesion.is_empty(),"el arranque exige acceso antes del menú")
	await foto("01_acceso")
	esc.acceso_panel.configurar();esc.acceso_panel.campos.dir.text=cfg.identidad;esc.acceso_panel.campos.python.text=cfg.python;esc.acceso_panel.campos.puerto.text=str(int(cfg.puerto))
	await esc.acceso_panel.activar_local()
	if esc.acceso_panel.conexion.cert=="":print("CONFIG: "+esc.acceso_panel.mensaje.text)
	ok(esc.acceso_panel.conexion.cert!="","servicio independiente iniciado desde configuración de acceso")
	await registrar("rayo_ui","El Rayo")
	ok(esc.modo=="menu" and esc.sesion.id.begins_with("cuenta:"),"registro válido abre el menú, sin entrar a ningún mundo")
	ok(not esc.acceso_panel.raiz.visible,"formulario oculto después del registro")
	await foto("02_menu_cuenta")
	var owner:Dictionary=esc.sesion.duplicate(true)
	nuevo();var first:String=esc.ruta
	ok(esc.modo=="juego" and Slots.datos_propios(first,owner).has("propietario_cuenta"),"nueva partida queda vinculada a la cuenta")
	esc.j.jug().inv={"madera":9};esc.j.jug().xp=27;esc.j.guardar(first)
	esc.j=null;esc._menu_inicial();nuevo();var second:String=esc.ruta
	ok(second!=first and Slots.listar(owner).size()==2,"crear otra partida conserva la anterior")
	esc.j=null;esc._menu_inicial();esc.menu_sel=2;esc._tecla_menu(key());await foto("03_cargar_partidas")
	ok(esc._cargar_cuenta(first) and esc.j.jug().inv.get("madera")==9 and esc.j.jug().xp==27,"carga restaura el progreso de la partida elegida")
	ok(Slots.ultima(owner)==first,"Continuar recuerda la partida elegida, incluso si no es la más nueva")
	# Comprobar que la copia de respaldo sigue siendo utilizable.
	var f=FileAccess.open(first,FileAccess.WRITE);f.store_string("{");f.close()
	ok(esc._cargar_cuenta(first),"la comprobación de propiedad permite recuperar el respaldo válido")
	esc.j.guardar(first);esc.j=null;esc._menu_inicial();esc.menu_sel=5;esc._tecla_menu(key())
	ok(esc.sesion.is_empty() and esc.modo=="cuentas","cerrar sesión vuelve al acceso y bloquea el menú")
	await registrar("amigo_ui","Amigo")
	ok(Slots.listar(esc.sesion).is_empty() and not esc._cargar_cuenta(first),"otra cuenta no puede abrir ni listar las partidas de El Rayo")
	esc.menu_sel=5;esc._menu_inicial();esc.menu_sel=5;esc._tecla_menu(key())
	var a=esc.acceso_panel;a.campos.usuario.text="rayo_ui";a.campos.password.text="Incorrecta123!";await a.autenticar()
	ok(esc.modo=="cuentas" and esc.sesion.is_empty(),"contraseña incorrecta no permite entrar al menú")
	a.campos.usuario.text="rayo_ui";a.campos.password.text="ClaveLinde123!";await a.autenticar()
	ok(esc.sesion.id==owner.id and Slots.listar(esc.sesion).size()==2,"el login posterior recupera la misma cuenta y sus partidas")
	esc._abrir_cuentas("cliente");await foto("04_elegir_mundo")
	ok(not esc.cuentas_panel.campos.has("usuario") and not esc.cuentas_panel.campos.has("password"),"elegir mundo no solicita registrarse ni repetir la contraseña de Linde")
	# Otra instancia puede reiniciar el servicio local elegido sin crear otra identidad.
	esc.acceso_panel.identidad_backend.detener();await create_timer(1.5).timeout
	var segunda=load("res://main.tscn").instantiate();segunda.forzar_acceso=true;segunda.cuentas_config_path=esc.cuentas_config_path;root.add_child(segunda);segunda.set_process(false)
	await process_frame
	for i in 100:
		if not segunda.acceso_panel.ocupado:break
		await create_timer(0.1).timeout
	ok(not segunda.acceso_panel.ocupado and segunda.acceso_panel.identidad_backend.pid>0,"otra instancia reactiva el servicio configurado sin sustituir sus datos")
	segunda.acceso_panel.campos.usuario.text="rayo_ui";segunda.acceso_panel.campos.password.text="ClaveLinde123!";await segunda.acceso_panel.autenticar()
	ok(segunda.sesion.get("id","")==owner.id and Slots.listar(segunda.sesion).size()==2,"la nueva instancia conserva la cuenta y sus partidas tras reiniciar el servicio")
	segunda.queue_free();await process_frame
	fin(0)
func fin(code:int):
	if checks.any(func(item):return not item.ok):code=1
	var f=FileAccess.open(out+"resultados_ui.json",FileAccess.WRITE);f.store_string(JSON.stringify(checks));f.close()
	if esc!=null:
		esc.acceso_panel.identidad_backend.detener() # Limpieza explícita del ensayo; el juego normal no lo hace.
		await create_timer(1.3).timeout
		esc.j=null;esc.modo="cuentas";esc.queue_free()
	quit(code)
