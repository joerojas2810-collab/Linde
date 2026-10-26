extends "res://scripts/red_cliente.gd"
## Autentica por HTTPS antes de abrir la sesión del mundo autoritativo.
var usuario := ""
var password := ""
var servidor_password := ""
var registrar := false
var puerto_cuentas := 7778
var certificado_ruta := ""
var sesion_linde:Dictionary={}

func _ready() -> void:
	if not puerto in range(1,65536) or not puerto_cuentas in range(1,65536):
		_fallar.call_deferred("Puerto inválido (1–65535).");return
	certificado_tls=X509Certificate.new()
	if certificado_tls.load(certificado_ruta)!=OK:
		_fallar.call_deferred("Selecciona el certificado .crt que te entregó el anfitrión. No se enviaron credenciales.");return
	if not sesion_linde.is_empty():
		await _desde_sesion();return
	var req=HTTPRequest.new();add_child(req);req.timeout=8;req.body_size_limit=8192;req.max_redirects=0
	req.set_tls_options(TLSOptions.client(certificado_tls,"linde.local"))
	var url="https://%s:%d/%s"%[direccion,puerto_cuentas,"registro" if registrar else "login"]
	var datos={"usuario":usuario,"password":password,"servidor_password":servidor_password,"nombre":nombre}
	var err=req.request(url,["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(datos))
	password="";servidor_password="";datos.clear()
	if err!=OK:req.queue_free();_fallar("No se pudo iniciar HTTPS de cuentas.");return
	var result=await req.request_completed;req.queue_free()
	if _terminado:return
	if result[0]!=HTTPRequest.RESULT_SUCCESS:
		_fallar("No se pudo validar la conexión HTTPS. Revisa el certificado, la dirección y el puerto TCP de cuentas.");return
	var body=JSON.parse_string(result[3].get_string_from_utf8())
	if not body is Dictionary or not body.get("ok",false):
		_fallar(str(body.get("motivo","Respuesta de cuentas inválida.")) if body is Dictionary else "Respuesta de cuentas inválida.");return
	ticket=str(body.get("ticket",""))
	if ticket=="":_fallar("El servidor no emitió un ticket de acceso.");return
	super._ready()

func _desde_sesion() -> void:
	var https=preload("res://scripts/cuentas/https.gd")
	if float(sesion_linde.get("exp",0))<=Time.get_unix_time_from_system():_fallar("Tu sesión de Linde caducó. Inicia sesión de nuevo.");return
	var permiso=await https.solicitar(self,sesion_linde.autoridad,"/permiso",{"token":sesion_linde.token,"destino":https.huella(certificado_ruta)})
	if _terminado:return
	if not permiso.get("ok",false):_fallar(str(permiso.get("motivo","No se pudo autorizar la entrada.")));return
	var config={"host":direccion,"puerto":puerto_cuentas,"cert":certificado_ruta}
	var acceso=await https.solicitar(self,config,"/admitir",{"permiso":permiso.permiso,"servidor_password":servidor_password})
	servidor_password=""
	if _terminado:return
	if not acceso.get("ok",false):_fallar(str(acceso.get("motivo","No se pudo entrar al mundo.")));return
	ticket=str(acceso.get("ticket",""))
	if ticket=="":_fallar("No se recibió permiso de entrada.");return
	super._ready()
