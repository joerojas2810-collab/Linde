extends "res://scripts/cuentas/panel.gd"
## Cuenta de Linde antes del menú; configurar identidad no implica alojar un mundo.
const HTTPS=preload("res://scripts/cuentas/https.gd")
var conexion:Dictionary={}
var identidad_backend=preload("res://scripts/cuentas/backend.gd").new()
var ocupado:=false
var registro:=false
var perfil_path:="user://perfil_local.cfg"

func _ready() -> void:
	super._ready()
	var cfg=ConfigFile.new();cfg.load(esc.cuentas_config_path)
	conexion={"host":str(cfg.get_value("cuentas","host","127.0.0.1")),"puerto":int(cfg.get_value("cuentas","puerto",7790)),"cert":str(cfg.get_value("cuentas","cert",""))}
	for k in ["local","dir","python"]:
		if cfg.has_section_key("cuentas",k):conexion[k]=cfg.get_value("cuentas",k)
	mostrar_acceso()
	if conexion.get("local",false):call_deferred("_asegurar_local")

func guardar_conexion() -> void:
	var cfg=ConfigFile.new()
	for k in conexion:cfg.set_value("cuentas",k,conexion[k])
	cfg.save(esc.cuentas_config_path)

func mostrar_acceso() -> void:
	registro=false;_formulario()

func _formulario() -> void:
	if ocupado:return
	raiz.show();esc.modo="cuentas";limpiar()
	texto("CREAR CUENTA DE LINDE" if registro else "BIENVENIDO A LINDE",28)
	texto("Una cuenta para tus partidas y los mundos compartidos.")
	campo("usuario","Usuario")
	campo("password","Contraseña","",true)
	texto("Contraseña obligatoria, sin longitud mínima. Máximo 128 caracteres.",14)
	if registro:
		campo("confirmar","Repetir contraseña","",true)
		campo("nombre","Nombre visible",esc.cr.nombre)
		campos.nombre.text_submitted.connect(func(_value):autenticar())
	else:campos.password.text_submitted.connect(func(_value):autenticar())
	boton("Crear cuenta" if registro else "Iniciar sesión",autenticar)
	boton("Ya tengo una cuenta" if registro else "Registrarme",func():registro=not registro;_formulario())
	texto("Servicio de cuentas: %s:%d"%[conexion.get("host",""),int(conexion.get("puerto",7790))],14)
	boton("Jugar local / servidores privados (sin cuenta global)",_local_privado)
	boton("Configurar servicio de cuentas…",configurar)
	mensaje=estado("",15)
	if conexion.get("cert","")=="":mensaje.text="Primera vez: configura el servicio de cuentas. No necesitas crear una partida."
	boton("Salir",func():esc.get_tree().quit())
	campos.usuario.grab_focus()

func autenticar() -> void:
	if ocupado:return
	var usuario=campos.usuario.text.strip_edges().to_lower()
	var patron=RegEx.new();patron.compile("^[a-z0-9_-]{3,24}$")
	if patron.search(usuario)==null:
		mensaje.text="El usuario debe tener 3–24 letras sin acentos, cifras, _ o -.";campos.usuario.grab_focus();return
	if campos.password.text.is_empty():
		mensaje.text="Escribe una contraseña para continuar.";campos.password.grab_focus();return
	if campos.password.text.length()>128:
		mensaje.text="La contraseña supera el máximo de 128 caracteres.";campos.password.grab_focus();return
	if registro and campos.password.text!=campos.confirmar.text:mensaje.text="Las contraseñas no coinciden.";return
	if registro and (campos.nombre.text.strip_edges().length()<2 or campos.nombre.text.strip_edges().length()>16):
		mensaje.text="El nombre visible debe tener entre 2 y 16 caracteres.";campos.nombre.grab_focus();return
	ocupado=true
	var data={"usuario":usuario,"password":campos.password.text,"nombre":campos.nombre.text if registro else ""}
	campos.password.text=""
	if registro:campos.confirmar.text=""
	mensaje.text="Validando tu cuenta…"
	var health=await HTTPS.solicitar(self,conexion,"/estado")
	if not health.get("ok",false) or health.get("rol","")!="identidad":
		data.clear();ocupado=false;mensaje.text=str(health.get("motivo","Ese servidor aloja mundos, no cuentas de Linde."));return
	var result=await HTTPS.solicitar(self,conexion,"/registro" if registro else "/login",data)
	data.clear();ocupado=false
	if not result.get("ok",false):mensaje.text=str(result.get("motivo","No se pudo iniciar sesión."));return
	if not result.has("token") or not result.has("id") or not result.has("exp"):
		mensaje.text="Este servicio no ofrece cuentas únicas de Linde. Revisa su configuración.";return
	esc.menu_msg=""
	esc.sesion={"id":result.id,"nombre":result.nombre,"token":result.token,"exp":result.exp,"emisor":HTTPS.huella(conexion.cert),"autoridad":{"host":conexion.host,"puerto":conexion.puerto,"cert":conexion.cert}}
	raiz.hide();esc._menu_inicial()

func configurar() -> void:
	if ocupado:return
	raiz.show();esc.modo="cuentas";limpiar()
	texto("SERVICIO DE CUENTAS",28)
	texto("Todas las PC deben usar el mismo servicio para compartir una identidad. Esto no inicia un mundo.")
	campo("host","IP o dominio",str(conexion.get("host","127.0.0.1")))
	campo("puerto","Puerto TCP",str(conexion.get("puerto",7790)))
	campo("cert","Certificado público (.crt)",str(conexion.get("cert","")))
	boton("Elegir certificado del servicio…",elegir_certificado)
	boton("Usar este servicio",usar_servicio)
	opciones_avanzadas("Alojar las cuentas en esta PC")
	texto("Solo en la PC que aloja las cuentas:",15)
	var py=OS.get_environment("LINDE_PYTHON")
	if py=="":py=ProjectSettings.globalize_path("res://../../.venv/"+("Scripts/python.exe" if OS.get_name()=="Windows" else "bin/python"))
	campo("python","Python",str(conexion.get("python",py)))
	campo("dir","Carpeta de cuentas",str(conexion.get("dir","user://identidad_linde")))
	boton("Activar servicio de cuentas en esta PC",activar_local)
	boton("Detener servicio local",detener_local)
	fin_opciones()
	mensaje=estado("El servicio local sigue activo al cerrar una partida o el juego; la PC debe permanecer encendida.",14)
	boton("Volver al acceso",mostrar_acceso)

func usar_servicio() -> void:
	if ocupado:return
	if not campos.puerto.text.is_valid_int() or int(campos.puerto.text)<1 or int(campos.puerto.text)>65535:mensaje.text="Puerto inválido.";return
	conexion={"host":campos.host.text.strip_edges(),"puerto":int(campos.puerto.text),"cert":campos.cert.text,"local":false}
	guardar_conexion();mostrar_acceso()

func activar_local() -> void:
	if ocupado:return
	if not campos.puerto.text.is_valid_int() or int(campos.puerto.text)<1 or int(campos.puerto.text)>65535:mensaje.text="Puerto inválido.";return
	ocupado=true;mensaje.text="Preparando el servicio de cuentas…"
	var dir=ProjectSettings.globalize_path(campos.dir.text)
	var candidate={"host":"127.0.0.1","puerto":int(campos.puerto.text),"cert":dir.path_join("servidor.crt")}
	candidate.merge({"local":true,"dir":dir,"python":campos.python.text})
	var health={}
	if FileAccess.file_exists(candidate.cert):health=await HTTPS.solicitar(self,candidate,"/estado")
	if not health.get("ok",false):
		var error=await identidad_backend.iniciar(self,dir,int(campos.puerto.text),"",campos.python.text,{"rol":"identidad"})
		if error!="":ocupado=false;mensaje.text=error;return
		for i in 30:
			await get_tree().create_timer(0.1).timeout
			health=await HTTPS.solicitar(self,candidate,"/estado")
			if health.get("ok",false):break
	ocupado=false
	if not health.get("ok",false) or health.get("rol","")!="identidad":mensaje.text="Ese puerto no corresponde al servicio de identidad de Linde.";return
	conexion=candidate;guardar_conexion();mostrar_acceso()
	mensaje.text="Servicio listo. Crea tu cuenta o inicia sesión. Para otra PC, comparte solo servidor.crt de "+dir

func _asegurar_local() -> void:
	if ocupado:return
	ocupado=true;mensaje.text="Comprobando el servicio de cuentas de esta PC…"
	var dir=str(conexion.get("dir",""))
	# No reemplazar una autoridad ya configurada si se perdieron sus claves/datos.
	if not FileAccess.file_exists(conexion.cert) or not FileAccess.file_exists(dir.path_join("cuentas.sqlite3")):
		ocupado=false;mensaje.text="Faltan los datos del servicio de cuentas. Restaura su respaldo antes de continuar.";return
	var health=await HTTPS.solicitar(self,conexion,"/estado")
	if not health.get("ok",false):
		var error=await identidad_backend.iniciar(self,dir,int(conexion.puerto),"",str(conexion.get("python","python")),{"rol":"identidad"})
		if error!="":ocupado=false;mensaje.text=error;return
		for i in 30:
			await get_tree().create_timer(0.1).timeout
			health=await HTTPS.solicitar(self,conexion,"/estado")
			if health.get("ok",false):break
	ocupado=false
	mensaje.text="Inicia sesión o registra tu cuenta." if health.get("rol","")=="identidad" else "El servicio de cuentas no está disponible."

func detener_local() -> void:
	if ocupado:return
	var dir=ProjectSettings.globalize_path(campos.dir.text)
	var file=FileAccess.open(dir.path_join("detener_cuentas"),FileAccess.WRITE)
	if file!=null:file.store_string("cierre solicitado");mensaje.text="Cierre solicitado al servicio local."

func mostrar_partidas() -> void:
	raiz.show();esc.modo="cuentas";limpiar();texto("CARGAR PARTIDA",28)
	texto("Partidas guardadas en esta PC para tu cuenta.",15)
	var lista=preload("res://scripts/cuentas/partidas.gd").listar(esc.sesion)
	if lista.is_empty():texto("No hay partidas guardadas para esta cuenta.")
	for slot in lista:
		var fecha=Time.get_datetime_string_from_unix_time(int(slot.fecha)+int(Time.get_time_zone_from_system().bias)*60).replace("T"," ")
		boton("%s · %s · semilla %d"%[slot.nombre,fecha,int(slot.semilla)],func():
			if esc._cargar_cuenta(slot.ruta):raiz.hide()
			else:mensaje.text=esc.menu_msg)
	mensaje=estado("",15)
	boton("Volver",func():raiz.hide();esc._menu_inicial())

func _local_privado() -> void:
	var cfg=ConfigFile.new()
	cfg.load(perfil_path)
	var id=str(cfg.get_value("perfil","id",""))
	if id=="":
		id=Crypto.new().generate_random_bytes(16).hex_encode()
		cfg.set_value("perfil","id",id)
		if cfg.save(perfil_path)!=OK:
			mensaje.text="No se pudo guardar el perfil local.";return
	esc.sesion={"id":"local:"+id,"nombre":"Aventurero","emisor":"perfil-local","exp":253402300799.0,"privado":true}
	raiz.hide();esc._menu_inicial()
