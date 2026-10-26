extends SceneTree
var esc
var out="res://../../production/qa/evidence/cuentas/"
func _initialize():call_deferred("run")
func foto(name:String):
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out+name+".png")==OK)
func run():
	root.size=Vector2i(1280,720)
	esc=load("res://main.tscn").instantiate();root.add_child(esc)
	esc._abrir_cuentas("servidor");await foto("crear_servidor")
	assert(esc.cuentas_panel.campos.puerto.text=="7777")
	assert(esc.cuentas_panel.campos.password.secret)
	esc.cuentas_panel.campos.carpeta.text="user://pruebas_linde/cuentas_ui"
	esc.cuentas_panel.iniciar_servidor()
	for i in 150:
		await create_timer(0.1).timeout
		if esc.cuentas_panel.mensaje.text.begins_with("Escuchando"):break
	assert(esc.cuentas_panel.mensaje.text.begins_with("Escuchando"))
	await foto("servidor_activo")
	esc.cuentas_panel.detener_servidor()
	for i in 100:
		await create_timer(0.1).timeout
		if not OS.is_process_running(esc.cuentas_panel.pid_servidor):break
	assert(not OS.is_process_running(esc.cuentas_panel.pid_servidor))
	await create_timer(1.2).timeout
	await foto("servidor_cerrado")
	esc.cuentas_panel.abrir("cliente");await foto("registro_login")
	assert(esc.cuentas_panel.campos.password.secret and esc.cuentas_panel.campos.servidor_password.secret)
	esc.cuentas_panel.campos.puerto.text="0";esc.cuentas_panel.entrar()
	assert(esc.cuentas_panel.mensaje.text.contains("puertos"));await foto("error_puerto")
	print("PASS UI cuentas: menús reales, campos separados, puerto predeterminado y validación")
	esc.queue_free();await process_frame;quit()
