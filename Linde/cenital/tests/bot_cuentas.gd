extends SceneTree
var cliente
var cfg:Dictionary
var terminado:=false
func _initialize():call_deferred("run")
func run():
	var path=""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--config="):path=a.trim_prefix("--config=")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(path))
	cliente=load("res://scripts/cuentas/cliente.gd").new();cliente.name="Red"
	for k in ["direccion","puerto","puerto_cuentas","usuario","password","servidor_password","registrar","nombre","certificado_ruta","sesion_linde"]:
		if cfg.has(k):cliente.set(k,cfg[k])
	cliente.look=[0,1,0,0,0,0,0,0]
	cliente.listo.connect(listo)
	cliente.fallo.connect(func(m):fin({"ok":false,"motivo":m}))
	root.add_child(cliente)
	get_tree_timeout()
func get_tree_timeout():
	await create_timer(25).timeout
	if not terminado:fin({"ok":false,"motivo":"Tiempo de prueba agotado"})
func listo():
	await create_timer(float(cfg.get("mantener",1))).timeout
	if terminado:return
	var pj:Dictionary=cliente.j.jug()
	fin({"ok":true,"id":cliente.yo,"nombre":pj.nombre,"look":pj.look,"pos":[cliente.j.pies.x,cliente.j.pies.y],"inv":pj.inv,"equipo":pj.equipo,"xp":pj.xp,"mapa":pj.get("mapa",{}),"otros":cliente.otros.size(),"tiene_clave":pj.has("clave"),"lugares":cliente.j.d.mundo.get("registro",{}).get("lugares",{}).size()})
func fin(info:Dictionary):
	if terminado:return
	terminado=true
	var f=FileAccess.open(cfg.salida,FileAccess.WRITE);f.store_string(JSON.stringify(info));f.close()
	print("PASS BOT CUENTAS" if info.ok else "RECHAZO ESPERABLE: "+str(info.get("motivo","")))
	cliente.cerrar();cliente.queue_free();await process_frame;quit()
