extends RefCounted
## HTTPS validado compartido por acceso inicial y permisos de mundo.
static func solicitar(parent:Node,config:Dictionary,ruta:String,datos:Dictionary={}) -> Dictionary:
	var cert=X509Certificate.new()
	var path=str(config.get("cert",""))
	if path=="" or not FileAccess.file_exists(path):return {"ok":false,"motivo":"Configura el servicio de cuentas y selecciona su certificado público."}
	if cert.load(path)!=OK:return {"ok":false,"motivo":"Selecciona un certificado de cuentas válido."}
	var host=str(config.get("host",""));var port=int(config.get("puerto",0))
	if host=="" or port<1 or port>65535:return {"ok":false,"motivo":"Configura la dirección y el puerto de cuentas."}
	var req=HTTPRequest.new();parent.add_child(req);req.timeout=8;req.body_size_limit=16384;req.max_redirects=0
	req.set_tls_options(TLSOptions.client(cert,"linde.local"))
	var method=HTTPClient.METHOD_GET if ruta=="/estado" else HTTPClient.METHOD_POST
	var err=req.request("https://%s:%d%s"%[host,port,ruta],["Content-Type: application/json"],method,"" if method==HTTPClient.METHOD_GET else JSON.stringify(datos))
	if err!=OK:req.queue_free();return {"ok":false,"motivo":"No se pudo iniciar la conexión de cuentas."}
	var result=await req.request_completed;req.queue_free()
	if result[0]!=HTTPRequest.RESULT_SUCCESS:return {"ok":false,"motivo":"No se pudo validar HTTPS. Revisa el servicio, la dirección y su certificado."}
	var body=JSON.parse_string(result[3].get_string_from_utf8())
	return body if body is Dictionary else {"ok":false,"motivo":"Respuesta de cuentas inválida."}

static func huella(path:String) -> String:
	var bloques=FileAccess.get_file_as_string(path).split("-----BEGIN CERTIFICATE-----")
	if bloques.size()<2:return ""
	var pem=bloques[1].split("-----END CERTIFICATE-----")[0].replace("\n","").replace("\r","").strip_edges()
	var digest=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(Marshalls.base64_to_raw(pem));return digest.finish().hex_encode()
