extends RefCounted
## Puente local al servicio Python. No conoce personajes ni simula el mundo.
var carpeta: String
var puerto: int
var python: String
var pid := -1
var certificado: X509Certificate
var control := ""
var huella := ""
var propietario := false

func iniciar(parent:Node,dir: String, port: int, password: String, py: String) -> String:
	carpeta=ProjectSettings.globalize_path(dir);puerto=port;python=py
	DirAccess.make_dir_recursive_absolute(carpeta)
	var inicio=Crypto.new().generate_random_bytes(16).hex_encode()
	var peticion=carpeta.path_join("inicio_cuentas_"+inicio+".json")
	var f=FileAccess.open(peticion,FileAccess.WRITE)
	if f==null:return "No se puede escribir en la carpeta del servidor."
	f.store_string(JSON.stringify({"password":password,"inicio":inicio}));f.close()
	var script=ProjectSettings.globalize_path("res://../../servidor/cuentas/servicio.py")
	var estado=carpeta.path_join("backend_estado_"+inicio+".json")
	DirAccess.remove_absolute(estado)
	DirAccess.remove_absolute(carpeta.path_join("detener_cuentas"))
	latido()
	pid=OS.create_process(python,[script,"--datos",carpeta,"--config",peticion,"--puerto",str(puerto)],false)
	if pid<=0:DirAccess.remove_absolute(peticion);return "No se pudo abrir Python. Ejecuta Instalar-Cuentas."
	for i in 100:
		await parent.get_tree().create_timer(0.1).timeout
		if not OS.is_process_running(pid):DirAccess.remove_absolute(peticion);return "No se pudo iniciar cuentas: revisa Python, dependencias o si ese mundo ya está abierto."
		if FileAccess.file_exists(estado):break
	if not FileAccess.file_exists(estado):detener();return "Se agotó el tiempo de inicio de cuentas."
	var info=JSON.parse_string(FileAccess.get_file_as_string(estado))
	if not info is Dictionary or not info.get("ok",false):return "El servicio de cuentas no devolvió una configuración válida."
	propietario=true;DirAccess.remove_absolute(estado)
	huella=info.huella
	certificado=X509Certificate.new()
	if certificado.load(carpeta.path_join("servidor.crt"))!=OK:return "No se pudo cargar el certificado."
	control=FileAccess.get_file_as_string(carpeta.path_join("control.key")).strip_edges()
	return "" if pid>0 else "No se pudo abrir el proceso de cuentas."

func latido() -> void:
	var f=FileAccess.open(carpeta.path_join("latido"),FileAccess.WRITE)
	if f!=null:f.store_string(str(Time.get_unix_time_from_system()))

func detener() -> void:
	if pid>0:
		if not propietario:
			if OS.is_process_running(pid):OS.kill(pid)
			return
		var f=FileAccess.open(carpeta.path_join("detener_cuentas"),FileAccess.WRITE)
		if f!=null:f.store_string("cerrar")

func tls_servidor() -> TLSOptions:
	var key=CryptoKey.new()
	if key.load(carpeta.path_join("servidor.key"))!=OK:return null
	return TLSOptions.server(key,certificado)

## Solicitud HTTPS al servicio; incluso el canal local valida el certificado.
func solicitar(parent:Node,ruta:String,datos:Dictionary={},interno:bool=false) -> Dictionary:
	var req=HTTPRequest.new();parent.add_child(req);req.timeout=5.0
	req.body_size_limit=8192;req.max_redirects=0
	req.set_tls_options(TLSOptions.client(certificado,"linde.local"))
	var headers=PackedStringArray(["Content-Type: application/json"])
	if interno:headers.append("X-Linde-Control: "+control)
	var method=HTTPClient.METHOD_GET if ruta=="/estado" else HTTPClient.METHOD_POST
	var err=req.request("https://127.0.0.1:%d%s"%[puerto,ruta],headers,method,"" if method==HTTPClient.METHOD_GET else JSON.stringify(datos))
	if err!=OK:req.queue_free();return {"ok":false,"motivo":"Servicio de cuentas no disponible."}
	var result=await req.request_completed;req.queue_free()
	var body=JSON.parse_string(result[3].get_string_from_utf8())
	return body if result[0]==HTTPRequest.RESULT_SUCCESS and body is Dictionary else {"ok":false,"motivo":"Servicio de cuentas no disponible."}
