extends "res://scripts/red_servidor.gd"
## Extensión autenticada: las reglas, RPC y difusión siguen en red_servidor.
var backend=preload("res://scripts/cuentas/backend.gd").new()
var carpeta := "user://servidor"
var python := "python"
var password := ""
var puerto_cuentas := 7778
var autoridad := ""
var privado := false
var estado_archivo := ""
var listo := false
var ultimo_guardado := true
var _latido_t := 0.0

func _ready() -> void:
	var opciones={"rol":"privado"} if privado else ({"rol":"mundo","autoridad":autoridad} if autoridad!="" else {})
	error=await backend.iniciar(self,carpeta,puerto_cuentas,password,python,opciones);password=""
	if error!="":return _fallo_inicio(error)
	var disponible=false
	for i in 30:
		await get_tree().create_timer(0.1).timeout
		var health=await backend.solicitar(self,"/estado")
		if health.get("ok",false):disponible=true;break
	if not disponible:return _fallo_inicio("No responde HTTPS de cuentas; revisa el puerto TCP %d y las dependencias."%puerto_cuentas)
	tls_options=backend.tls_servidor()
	if tls_options==null:return _fallo_inicio("No se pudo preparar DTLS.")
	super._ready()
	if error!="":return _fallo_inicio(error)
	listo=true
	_escribir_estado({"ok":true,"estado":"Escuchando","udp":puerto,"https":puerto_cuentas,"certificado":backend.carpeta.path_join("servidor.crt"),"huella":backend.huella})
	print("Huella SHA-256 para verificar con tus amigos: "+backend.huella)
	print("LINDE CUENTAS: escuchando UDP %d (DTLS) y TCP %d (HTTPS). No implica conectividad pública."%[puerto,puerto_cuentas])

func _fallo_inicio(motivo:String) -> void:
	error=motivo;backend.detener();_escribir_estado({"ok":false,"motivo":motivo})
	printerr(motivo);get_tree().quit(1)

func _escribir_estado(info:Dictionary) -> void:
	if estado_archivo=="":return
	var f=FileAccess.open(estado_archivo,FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(info))

func _process(delta:float) -> void:
	if not listo:return
	_latido_t+=delta
	if _latido_t>=1.0:
		_latido_t=0.0;backend.latido()
		if FileAccess.file_exists(backend.carpeta.path_join("detener_servidor")):get_tree().quit();return
	super._process(delta)

func _exit_tree() -> void:
	if not listo:backend.detener();return
	super._exit_tree()
	backend.detener()
	_escribir_estado({"ok":ultimo_guardado,"estado":"Cerrado; mundo guardado" if listo and ultimo_guardado else "No iniciado" if not listo else "Error al guardar; revisa el respaldo"})

func guardar() -> bool:
	ultimo_guardado=super.guardar()
	if not ultimo_guardado:
		push_error("No se pudo guardar el mundo del servidor.")
		_escribir_estado({"ok":false,"motivo":"No se pudo guardar el mundo. Revisa espacio y permisos de la carpeta."})
	return ultimo_guardado

func retirar_peer(pid:int) -> void:
	var identificado=peers.get(pid,{}).get("id","")!=""
	super.retirar_peer(pid)
	if identificado and ruta!="" and not guardar():push_error("No se pudo guardar al desconectar.")

func recibir(pid:int,datos) -> bool:
	var p:Dictionary=peers.get(pid,{})
	if p.is_empty() or p.get("fuera",false):return false
	if p.id!="":return super.recibir(pid,datos)
	if p.get("autenticando",false):return false
	# Solo un ticket aleatorio: ninguna contraseña ni ID escogido por el cliente.
	if not datos is Array or datos.size()!=5 or datos[0]!="cuenta" or datos[1]!=VERSION or datos[4]!=Huella.huella():
		_denegar(pid,"Versión o reglas distintas del servidor.");return false
	if not datos[2] is String or datos[2].length()>64 or _look(datos[3]).is_empty():
		_denegar(pid,"Datos de acceso inválidos.");return false
	p.autenticando=true
	_autenticar(pid,datos[2],datos[3])
	return true

func _autenticar(pid:int,ticket:String,look:Array) -> void:
	var sesion=peers[pid]
	var r=await backend.solicitar(self,"/consumir",{"ticket":ticket},true)
	if not peers.has(pid) or peers[pid]!=sesion or peers[pid].get("fuera",false):return
	if not r.get("ok",false):_denegar(pid,str(r.get("motivo","Acceso rechazado.")));return
	var id:String=r.id
	if ids.has(id):_denegar(pid,"Esta cuenta ya está jugando en el servidor.");return
	if j.d.jugadores.has(id):j.entrar(id)
	else:
		var union:Dictionary=j.unir(id,r.nombre,look)
		if not union.get("ok",false):_denegar(pid,union.get("msg","No hay lugar de aparición disponible."));return
	peers[pid].id=id;ids[id]=pid;intencion[id]=Vector2i.ZERO;ultimo_seq[id]=-1
	if not guardar():
		retirar_peer(pid);_denegar(pid,"No se pudo guardar el personaje. Intenta más tarde.");return
	j.aviso_todos("%s entra al mundo."%j.jug(id).nombre)
	_enviar(pid,["bienvenida",estado_para(id)])

func _denegar(pid:int,motivo:String) -> void:
	_enviar(pid,["rechazo",motivo]);_expulsar(pid)
