extends CanvasLayer
## Formularios nativos de servidor y cuentas. Las contraseñas no se recuerdan.
var esc
var campos:Dictionary={}
var caja:VBoxContainer
var raiz:Control
var mensaje:Label
var conectar:Button
var certificado:FileDialog
var pid_servidor := -1
var carpeta_servidor := ""
var _tiempo := 0.0
var pagina := ""

func _ready() -> void:
	layer=20
	raiz=Control.new();raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(raiz)
	var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);raiz.add_child(center)
	var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(860,650);center.add_child(panel)
	var style=StyleBoxFlat.new();style.bg_color=Color("183638");style.border_color=Color("d7b778");style.set_border_width_all(3);style.set_content_margin_all(24);panel.add_theme_stylebox_override("panel",style)
	var theme=Theme.new();theme.default_font=esc.hud.ui.fuente;theme.default_font_size=17;panel.theme=theme
	caja=VBoxContainer.new();caja.add_theme_constant_override("separation",8);panel.add_child(caja)
	abrir("cliente")

func limpiar() -> void:
	campos.clear()
	for c in caja.get_children():caja.remove_child(c);c.queue_free()

func texto(value:String,size:int=17) -> Label:
	var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caja.add_child(label);return label

func campo(id:String,nombre:String,valor:String="",secreto:bool=false) -> LineEdit:
	var row=HBoxContainer.new();caja.add_child(row)
	var label=Label.new();label.text=nombre;label.custom_minimum_size.x=260;row.add_child(label)
	var edit=LineEdit.new();edit.text=valor;edit.secret=secreto;edit.max_length=256;edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;edit.custom_minimum_size.y=32;row.add_child(edit);campos[id]=edit;return edit

func boton(value:String,accion:Callable) -> Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=34;b.pressed.connect(accion);caja.add_child(b);return b

func abrir(tipo:String) -> void:
	pagina=tipo;raiz.show();esc.modo="cuentas";esc.menu_msg="";limpiar()
	var cfg=ConfigFile.new();cfg.load("user://cuentas_cliente.cfg")
	texto("CREAR SERVIDOR" if tipo=="servidor" else "ENTRAR CON TU CUENTA",28)
	if tipo=="servidor":
		campo("puerto","Puerto del juego (UDP)","7777")
		campo("https","Puerto de cuentas (TCP)","7778")
		campo("password","Contraseña del servidor (opcional)","",true)
		campo("carpeta","Carpeta del mundo y cuentas","user://servidor")
		var py=OS.get_environment("LINDE_PYTHON")
		if py=="":py=ProjectSettings.globalize_path("res://../../.venv/"+("Scripts/python.exe" if OS.get_name()=="Windows" else "bin/python"))
		campo("python","Python del servidor",py)
		texto("Vacío = servidor abierto. La contraseña de acceso es independiente de cada cuenta.")
		boton("Iniciar servidor",iniciar_servidor)
		boton("Cerrar servidor y guardar",detener_servidor)
		boton("Abrir carpeta del servidor (certificado .crt)",func():
			if carpeta_servidor!="":OS.shell_open(carpeta_servidor)
			else:mensaje.text="Primero inicia el servidor para crear su certificado.")
		boton("Ir a registro / inicio de sesión",func():abrir("cliente"))
	else:
		campo("host","IP o dominio",str(cfg.get_value("conexion","host","127.0.0.1")))
		campo("puerto","Puerto del juego (UDP)",str(cfg.get_value("conexion","puerto","7777")))
		campo("https","Puerto de cuentas (TCP)",str(cfg.get_value("conexion","https","7778")))
		campo("cert","Certificado del anfitrión (.crt)",str(cfg.get_value("conexion","cert","")))
		boton("Seleccionar certificado público…",elegir_certificado)
		campo("usuario","Usuario de la cuenta",str(cfg.get_value("conexion","usuario","")))
		campo("password","Contraseña de la cuenta","",true)
		campo("servidor_password","Contraseña del servidor (si tiene)","",true)
		campo("nombre","Nombre del personaje (al registrar)",esc.cr.nombre)
		var reg=CheckBox.new();reg.text="Registrar una cuenta nueva";caja.add_child(reg);campos.registrar=reg
		conectar=boton("Conectar",entrar)
	texto("El certificado se recibe del anfitrión por un medio de confianza. No uses certificados de desconocidos.",14)
	mensaje=texto("",15)
	boton("Volver al menú",volver)

func elegir_certificado() -> void:
	certificado=FileDialog.new();certificado.file_mode=FileDialog.FILE_MODE_OPEN_FILE;certificado.access=FileDialog.ACCESS_FILESYSTEM;certificado.filters=PackedStringArray(["*.crt,*.pem ; Certificado público"])
	add_child(certificado);certificado.file_selected.connect(func(path):campos.cert.text=path;certificado.queue_free());certificado.popup_centered_ratio(0.65)

func puertos_validos() -> bool:
	for k in ["puerto","https"]:
		var value=campos[k].text
		if not value.is_valid_int() or int(value)<1 or int(value)>65535:mensaje.text="Los puertos deben estar entre 1 y 65535.";return false
	return true

func iniciar_servidor() -> void:
	if pid_servidor>0 and OS.is_process_running(pid_servidor):mensaje.text="El servidor ya está iniciado.";return
	if not puertos_validos():return
	carpeta_servidor=ProjectSettings.globalize_path(campos.carpeta.text)
	DirAccess.make_dir_recursive_absolute(carpeta_servidor)
	var config={"puerto":int(campos.puerto.text),"https":int(campos.https.text),"password":campos.password.text,"carpeta":carpeta_servidor,"python":campos.python.text}
	var path=carpeta_servidor.path_join("arranque.json")
	var f=FileAccess.open(path,FileAccess.WRITE)
	if f==null:mensaje.text="No se pudo escribir la configuración del servidor.";return
	f.store_string(JSON.stringify(config));f.close();campos.password.text=""
	DirAccess.remove_absolute(carpeta_servidor.path_join("estado.json"))
	pid_servidor=OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://scripts/cuentas/main_servidor.gd","--","--config="+path],false)
	mensaje.text="Iniciando…" if pid_servidor>0 else "No se pudo crear el proceso de servidor."

func detener_servidor() -> void:
	if carpeta_servidor=="":mensaje.text="No hay un servidor iniciado desde esta ventana.";return
	var f=FileAccess.open(carpeta_servidor.path_join("detener_servidor"),FileAccess.WRITE)
	if f!=null:f.store_string("guardar y cerrar")
	mensaje.text="Cerrando y guardando el mundo…"

func entrar() -> void:
	if not puertos_validos():return
	if esc.red!=null:esc._cerrar_red()
	var client=load("res://scripts/cuentas/cliente.gd").new();client.name="Red"
	client.direccion=campos.host.text.strip_edges();client.puerto=int(campos.puerto.text);client.puerto_cuentas=int(campos.https.text)
	client.usuario=campos.usuario.text;client.password=campos.password.text;client.servidor_password=campos.servidor_password.text
	client.nombre=campos.nombre.text;client.registrar=campos.registrar.button_pressed;client.certificado_ruta=campos.cert.text
	client.look=esc.Aspecto.de_creador(esc.cr)
	var cfg=ConfigFile.new()
	for k in ["host","puerto","https","cert","usuario"]:cfg.set_value("conexion",k,campos[k].text)
	cfg.save("user://cuentas_cliente.cfg")
	campos.password.text="";campos.servidor_password.text="";conectar.disabled=true;mensaje.text="Validando certificado y cuenta…"
	client.listo.connect(func():esc.j=client.j;esc.panel="";esc.modo="juego";raiz.hide())
	client.fallo.connect(func(motivo):esc.j=null;esc.modo="cuentas";raiz.show();conectar.disabled=false;mensaje.text=motivo)
	client.interaccion.connect(esc._tras_interactuar)
	esc.red=client;get_tree().root.add_child(client)

func volver() -> void:
	raiz.hide();esc._menu_inicial()

func _process(delta:float) -> void:
	if pagina!="servidor" or not raiz.visible or carpeta_servidor=="":return
	_tiempo+=delta
	if _tiempo<1:return
	_tiempo=0
	var path=carpeta_servidor.path_join("estado.json")
	if FileAccess.file_exists(path):
		var info=JSON.parse_string(FileAccess.get_file_as_string(path))
		if info is Dictionary:
			mensaje.text=str(info.get("motivo",info.get("estado","")))
			if info.get("estado","")=="Escuchando":mensaje.text+=" · UDP %d / TCP %d\nCertificado: %s\nSHA-256: %s"%[int(info.udp),int(info.https),info.certificado,info.huella]
	if pid_servidor>0 and not OS.is_process_running(pid_servidor) and mensaje.text.begins_with("Iniciando"):mensaje.text="El servidor no pudo iniciar. Revisa Python, las dependencias y la carpeta del mundo."

func _exit_tree() -> void:
	if pid_servidor>0 and OS.is_process_running(pid_servidor):detener_servidor()
