extends SceneTree
## Evidencia visual de K1: panel de saberes del taller (pedir y enseñar), con una lección real de Maren al jugador.
const J = preload("res://scripts/juego.gd")
var carpeta := ""
func foto(nombre: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func linea(esc, prefijo: String) -> int:
	for i in esc.lineas.size():
		if esc.lineas[i].begins_with(prefijo): return i
	return -1
func _init() -> void:
	carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/saberes")
	DirAccess.make_dir_recursive_absolute(carpeta)
	var esc=load("res://main.tscn").instantiate()
	esc.ruta="/tmp/linde-saberes-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j=J.nueva(123,"Exploradora",[0,0,0])
	esc.j.autonomia.activar()
	esc.j.combate.enemigos.clear()
	esc.modo="juego"
	var guardia := 0
	while esc.j.autonomia.desarrollo._descansa("maren") and guardia<40:
		for i in 300: esc.j.tick(0.1)
		guardia+=1
	esc.j.pies=esc.j.habitantes.pos("maren")
	var e:=InputEventKey.new();e.pressed=true;e.keycode=KEY_G
	esc._unhandled_key_input(e)
	if esc.panel!="desarrollo" or linea(esc,"Saberes")<0:push_error("El taller no ofrece la entrada de saberes");quit(1);return
	print("PASS UI: el taller ofrece «Saberes»")
	await foto("taller")
	esc._abrir("saberes")
	var i_pedir := linea(esc,"  Pedir a Maren que te enseñe: técnica ligera")
	if i_pedir<0:push_error("No se ofrece pedir la técnica ligera a Maren");quit(1);return
	print("PASS UI: el panel ofrece pedir la técnica ligera a Maren")
	await foto("saberes_antes")
	esc.acc[i_pedir].call()
	esc._abrir("saberes")
	if not esc.j.autonomia.desarrollo.tiene_saber(esc.j.actor_desarrollo(),"tec:ligera"):push_error("La lección no se completó");quit(1);return
	if linea(esc,"  Pedir a Maren que te enseñe: técnica ligera")>=0:push_error("La técnica sigue ofreciéndose tras aprenderla");quit(1);return
	print("PASS UI: tras la lección el jugador conoce la técnica ligera y deja de ofrecerse")
	await foto("saberes_despues")
	quit(0)
