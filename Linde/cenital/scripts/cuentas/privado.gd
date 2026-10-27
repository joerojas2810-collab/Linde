extends RefCounted
## Confianza explícita inicial + credencial aleatoria por certificado del mundo.
## client_unsafe SOLO descarga información pública; jamás envía contraseña o token.
signal decision(aceptado:bool)

func conectar(panel) -> void:
	if not panel.puertos_validos():return
	var host=panel.campos.host.text.strip_edges()
	var nombre=panel.campos.nombre.text.strip_edges()
	if host=="" or host.contains("/") or host.contains(":") or host.contains("?") or host.contains("#") or host.contains("@"):
		panel.mensaje.text="Escribe una dirección IPv4 o dominio, sin protocolo ni puerto.";return
	if nombre.length()<2 or nombre.length()>16:
		panel.mensaje.text="El nombre debe tener entre 2 y 16 caracteres.";return
	_bloquear(panel,true)
	panel.mensaje.text="Consultando el certificado público del servidor…"
	var destino=host.to_lower()+":"+panel.campos.https.text
	var clave=destino.sha256_text()
	var dir="user://servidores_privados/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))!=OK:
		_fallo(panel,"No se pudo crear la carpeta de confianza.");return
	var cert_path=dir+clave+".crt"
	if not FileAccess.file_exists(cert_path):
		var req=HTTPRequest.new();panel.add_child(req)
		req.timeout=8;req.body_size_limit=16384;req.max_redirects=0
		req.set_tls_options(TLSOptions.client_unsafe())
		var err=req.request("https://%s:%s/certificado"%[host,panel.campos.https.text])
		if err!=OK:
			req.queue_free();_fallo(panel,"No se pudo consultar el servidor.");return
		var result=await req.request_completed;req.queue_free()
		if result[0]!=HTTPRequest.RESULT_SUCCESS or result[1]!=200:
			_fallo(panel,"No responde un servidor privado. Revisa dirección, puerto TCP y firewall.");return
		var info=JSON.parse_string(result[3].get_string_from_utf8())
		if not info is Dictionary or not info.get("certificado") is String:
			_fallo(panel,"Respuesta pública inválida.");return
		var candidato=X509Certificate.new()
		if candidato.load_from_string(info.certificado)!=OK:
			_fallo(panel,"Certificado inválido.");return
		# Canonizar PEM antes de calcular la misma huella DER que usa el backend.
		var pem=candidato.save_to_string()
		var base=pem.replace("-----BEGIN CERTIFICATE-----","").replace("-----END CERTIFICATE-----","").replace("\n","").replace("\r","")
		var hashing=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(Marshalls.base64_to_raw(base))
		var huella=hashing.finish().hex_encode()
		var dialog=ConfirmationDialog.new();panel.add_child(dialog)
		dialog.title="Verificar servidor — primera conexión"
		dialog.dialog_text="Pide esta huella SHA-256 al anfitrión por un medio de confianza.\nConfirma SOLO si coincide exactamente:\n\n"+huella+"\n\nSi no puedes compararla, cancela."
		dialog.confirmed.connect(func():decision.emit(true))
		dialog.canceled.connect(func():decision.emit(false))
		dialog.popup_centered(Vector2i(760,300))
		var aceptar=await decision;dialog.queue_free()
		if not aceptar:_fallo(panel,"Conexión cancelada. No se enviaron credenciales.");return
		if candidato.save(cert_path)!=OK:_fallo(panel,"No se pudo guardar el certificado.");return
	var cert= X509Certificate.new()
	if cert.load(cert_path)!=OK:_fallo(panel,"Certificado guardado inválido. Restaura tu respaldo.");return
	var identity_path=dir+preload("res://scripts/cuentas/https.gd").huella(cert_path)+".cfg"
	var identity=ConfigFile.new()
	var loaded=identity.load(identity_path)
	if loaded!=OK and loaded!=ERR_FILE_NOT_FOUND:
		_fallo(panel,"No se pudo leer tu identidad privada; restaura el respaldo.");return
	if loaded==ERR_FILE_NOT_FOUND:
		identity.set_value("identidad","usuario","p"+Crypto.new().generate_random_bytes(11).hex_encode())
		identity.set_value("identidad","password",Crypto.new().generate_random_bytes(32).hex_encode())
		if identity.save(identity_path)!=OK:_fallo(panel,"No se pudo guardar tu identidad privada.");return
	if OS.get_name() in ["Linux","macOS"]:
		if FileAccess.set_unix_permissions(identity_path,FileAccess.UNIX_READ_OWNER|FileAccess.UNIX_WRITE_OWNER)!=OK:
			_fallo(panel,"No se pudieron restringir los permisos de tu credencial.");return
	var client=load("res://scripts/cuentas/cliente.gd").new();client.name="Red"
	client.privado=true;client.direccion=host;client.puerto=int(panel.campos.puerto.text);client.puerto_cuentas=int(panel.campos.https.text)
	client.certificado_ruta=cert_path;client.usuario=str(identity.get_value("identidad","usuario",""));client.password=str(identity.get_value("identidad","password",""))
	client.nombre=nombre;client.servidor_password=panel.campos.servidor_password.text
	client.look=panel.esc.Aspecto.de_creador(panel.esc.cr)
	panel.campos.servidor_password.text=""
	var cfg=ConfigFile.new()
	for k in ["host","puerto","https"]:cfg.set_value("conexion",k,panel.campos[k].text)
	cfg.save("user://cuentas_cliente.cfg")
	panel.esc._cerrar_red()
	client.listo.connect(func():panel.esc.j=client.j;panel.esc.panel="";panel.esc.modo="juego";panel.raiz.hide();_bloquear(panel,false))
	client.fallo.connect(func(motivo):panel.esc.j=null;panel.esc.modo="cuentas";panel.raiz.show();_fallo(panel,motivo+" Si cambió el certificado, verifica con el anfitrión; no se reemplaza automáticamente."))
	client.interaccion.connect(panel.esc._tras_interactuar)
	panel.esc.red=client;panel.get_tree().root.add_child(client)
	panel.mensaje.text="Entrando mediante conexión verificada…"

func _fallo(panel,motivo:String) -> void:
	_bloquear(panel,false);panel.mensaje.text=motivo

func _bloquear(panel,ocupado:bool) -> void:
	panel.privado_ocupado=ocupado
	panel.conectar.disabled=ocupado
	for campo in panel.campos.values():
		if campo is LineEdit:campo.editable=not ocupado
