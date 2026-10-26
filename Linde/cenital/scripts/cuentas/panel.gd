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
var privado_ocupado := false
var destino:VBoxContainer

func _ready() -> void:
	layer=20
	raiz=Control.new();raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(raiz)
	var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);raiz.add_child(center)
	var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(860,650);center.add_child(panel)
	# Los mismos recursos E06 del menú: pergamino, madera y botones de nueve parches.
	panel.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var style=esc.hud.ui._estilo("reutilizados/panel.png",[16,32,16,32]).duplicate()
	style.set_content_margin_all(32);panel.add_theme_stylebox_override("panel",style)
	panel.theme=_tema()
	raiz.resized.connect(func():panel.custom_minimum_size=Vector2(minf(920,raiz.size.x-40),minf(672,raiz.size.y-32)))
	panel.custom_minimum_size=Vector2(minf(920,get_viewport().get_visible_rect().size.x-40),minf(672,get_viewport().get_visible_rect().size.y-32))
	var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	caja=VBoxContainer.new();caja.size_flags_horizontal=Control.SIZE_EXPAND_FILL;caja.add_theme_constant_override("separation",8);scroll.add_child(caja);destino=caja
	abrir("cliente")

func _tema() -> Theme:
	var theme=Theme.new();theme.default_font=esc.hud.ui.fuente;theme.default_font_size=18
	theme.set_color("font_color","Label",Color("30271f"))
	for state in ["normal","hover","pressed","disabled"]:
		var rel="button_hover.png" if state in ["hover","pressed"] else "button_normal.png"
		var style=esc.hud.ui._estilo("reutilizados/"+rel,[20,10,20,8]).duplicate()
		style.set_content_margin_all(12)
		style.content_margin_top=6;style.content_margin_bottom=6
		theme.set_stylebox(state,"Button",style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		theme.set_color(state,"Button",Color("fff0c7"))
	theme.set_color("font_disabled_color","Button",Color("c0aa83"))
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("e7b64e");focus.set_border_width_all(2)
	theme.set_stylebox("focus","Button",focus)
	for state in ["normal","focus","read_only"]:
		var input=StyleBoxFlat.new();input.bg_color=Color("fff2d2");input.border_color=Color("bd9a60") if state!="focus" else Color("225357")
		input.set_border_width_all(2);input.set_content_margin_all(10)
		input.content_margin_top=6;input.content_margin_bottom=6
		theme.set_stylebox(state,"LineEdit",input)
	theme.set_color("font_color","LineEdit",Color("30271f"));theme.set_color("caret_color","LineEdit",Color("12363b"))
	theme.set_color("selection_color","LineEdit",Color("307475"));theme.set_color("font_selected_color","LineEdit",Color("fff0c7"))
	theme.set_color("font_placeholder_color","LineEdit",Color("756343"))
	theme.set_color("font_color","CheckBox",Color("30271f"))
	return theme

func limpiar() -> void:
	campos.clear();destino=caja
	for c in caja.get_children():caja.remove_child(c);c.queue_free()

func texto(value:String,size:int=17) -> Label:
	if size>=28:
		var marca=Label.new();marca.text="L I N D E";marca.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marca.add_theme_font_size_override("font_size",14);marca.add_theme_color_override("font_color",Color("72512a"));destino.add_child(marca)
	var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if size>=28:
		label.add_theme_font_override("font",esc.hud.ui.fuente_dialogo);label.add_theme_color_override("font_color",Color("12363b"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif size<=15:label.add_theme_color_override("font_color",Color("695333"))
	destino.add_child(label);return label

func campo(id:String,nombre:String,valor:String="",secreto:bool=false) -> LineEdit:
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);destino.add_child(row)
	var label=Label.new();label.text=nombre;label.custom_minimum_size.x=240;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.add_child(label)
	var edit=LineEdit.new();edit.text=valor;edit.secret=secreto;edit.max_length=256;edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;edit.custom_minimum_size.y=40;row.add_child(edit);campos[id]=edit;return edit

func boton(value:String,accion:Callable) -> Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=38;b.pressed.connect(accion);destino.add_child(b)
	if value in ["Crear cuenta","Iniciar sesión","Iniciar servidor","Entrar al mundo","Usar este servicio"]:
		for state in ["normal","hover","pressed"]:
			var s=StyleBoxFlat.new();s.bg_color=Color("12363b") if state=="normal" else Color("225357");s.border_color=Color("b6883f");s.set_border_width_all(2);s.set_content_margin_all(8)
			b.add_theme_stylebox_override(state,s)
	return b

func opciones_avanzadas(titulo:String="Opciones avanzadas") -> void:
	var grupo=VBoxContainer.new();grupo.add_theme_constant_override("separation",8)
	var toggle=boton("+ "+titulo,func():grupo.visible=not grupo.visible)
	toggle.toggle_mode=true;toggle.toggled.connect(func(activo):toggle.text=("− " if activo else "+ ")+titulo)
	destino.add_child(grupo);grupo.hide();destino=grupo

func fin_opciones() -> void:
	destino=caja

func estado(value:String,size:int=15) -> Label:
	var label=texto(value,size)
	var style=StyleBoxFlat.new();style.bg_color=Color("ead09a");style.set_content_margin_all(8)
	label.add_theme_stylebox_override("normal",style);label.add_theme_color_override("font_color",Color("12363b"))
	return label

func abrir(tipo:String) -> void:
	pagina=tipo;raiz.show();esc.modo="cuentas";esc.menu_msg="";limpiar()
	var cfg=ConfigFile.new();cfg.load("user://cuentas_cliente.cfg")
	texto("CREAR SERVIDOR" if tipo=="servidor" else "UNIRSE A UN MUNDO" if not esc.sesion.is_empty() else "ENTRAR CON TU CUENTA",28)
	if tipo=="servidor":
		campo("puerto","Puerto del juego (UDP)","7777")
		campo("password","Contraseña del servidor (opcional)","",true)
		texto("Deja la contraseña vacía para un mundo abierto. Tu cuenta de Linde usa una contraseña independiente.",15)
		opciones_avanzadas("Opciones del servidor")
		campo("https","Acceso del mundo (TCP)","7778")
		campo("carpeta","Carpeta del mundo y cuentas","user://servidor")
		var py=OS.get_environment("LINDE_PYTHON")
		if py=="":py=ProjectSettings.globalize_path("res://../../.venv/"+("Scripts/python.exe" if OS.get_name()=="Windows" else "bin/python"))
		campo("python","Python del servidor",py)
		fin_opciones()
		boton("Iniciar servidor",iniciar_servidor)
		boton("Cerrar servidor y guardar",detener_servidor)
		boton("Abrir carpeta del servidor (certificado .crt)",func():
			if carpeta_servidor!="":OS.shell_open(carpeta_servidor)
			else:mensaje.text="Primero inicia el servidor para crear su certificado.")
		boton("Elegir un mundo para jugar" if not esc.sesion.is_empty() else "Ir a registro / inicio de sesión",func():abrir("cliente"))
	else:
		if esc.sesion.get("privado",false):
			_cliente_privado(cfg)
			return
		if not esc.sesion.is_empty():
			_cliente_con_sesion(cfg)
			return
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
	mensaje=estado("",15)
	boton("Volver al menú",volver)

func _cliente_con_sesion(cfg:ConfigFile) -> void:
	texto("Cuenta: "+str(esc.sesion.nombre)+" · elige el mundo al que quieres entrar.")
	campo("host","IP o dominio",str(cfg.get_value("conexion","host","127.0.0.1")))
	campo("puerto","Puerto del juego (UDP)",str(cfg.get_value("conexion","puerto","7777")))
	campo("cert","Certificado del mundo (.crt)",str(cfg.get_value("conexion","cert","")))
	boton("Seleccionar certificado del mundo…",elegir_certificado)
	campo("servidor_password","Contraseña del mundo (si tiene)","",true)
	opciones_avanzadas()
	campo("https","Acceso del mundo (TCP)",str(cfg.get_value("conexion","https","7778")))
	fin_opciones()
	conectar=boton("Entrar al mundo",entrar)
	mensaje=estado("Tu contraseña de Linde no se envía al anfitrión.",15)
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
	if esc.sesion.get("privado",false):config.privado=true
	elif not esc.sesion.is_empty():config.autoridad=esc.sesion.autoridad.cert
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
	client.servidor_password=campos.servidor_password.text;client.certificado_ruta=campos.cert.text
	if not esc.sesion.is_empty():
		client.sesion_linde=esc.sesion.duplicate(true)
	else:
		client.usuario=campos.usuario.text;client.password=campos.password.text
		client.nombre=campos.nombre.text;client.registrar=campos.registrar.button_pressed
	client.look=esc.Aspecto.de_creador(esc.cr)
	var cfg=ConfigFile.new()
	for k in ["host","puerto","https","cert"]:cfg.set_value("conexion",k,campos[k].text)
	cfg.save("user://cuentas_cliente.cfg")
	if campos.has("password"):campos.password.text=""
	campos.servidor_password.text="";conectar.disabled=true;mensaje.text="Autorizando la entrada al mundo…"
	client.listo.connect(func():esc.j=client.j;esc.panel="";esc.modo="juego";raiz.hide())
	client.fallo.connect(func(motivo):esc.j=null;esc.modo="cuentas";raiz.show();conectar.disabled=false;mensaje.text=motivo)
	client.interaccion.connect(esc._tras_interactuar)
	esc.red=client;get_tree().root.add_child(client)

func volver() -> void:
	if privado_ocupado:
		mensaje.text="Espera la conexión o cancela la verificación del certificado.";return
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

# El perfil privado no es una cuenta global ni se presenta como tal al servidor.
var privado_control
func _cliente_privado(cfg:ConfigFile) -> void:
	texto("SERVIDOR PRIVADO",28)
	campo("host","Dirección del servidor",str(cfg.get_value("conexion","host","127.0.0.1")))
	campo("puerto","Puerto del juego (UDP)",str(cfg.get_value("conexion","puerto","7777")))
	campo("nombre","Nombre visible",esc.cr.nombre)
	campo("servidor_password","Contraseña del mundo (si tiene)","",true)
	opciones_avanzadas()
	campo("https","Acceso del mundo (TCP)",str(cfg.get_value("conexion","https","7778")))
	fin_opciones()
	texto("La primera vez debes comparar la huella con el anfitrión. No se envían credenciales antes de confirmar.",14)
	conectar=boton("Conectar",func():
		if privado_control==null:privado_control=load("res://scripts/cuentas/privado.gd").new()
		privado_control.conectar(self))
	mensaje=estado("",15)
	boton("Volver al menú",volver)
