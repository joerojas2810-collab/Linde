extends SceneTree
class Pintor extends Node2D:
	var vida=preload("res://herramientas/arte/vida_iconos_fuente.gd").new()
	var id="visitante"
	var ocupacion=false
	func _draw():
		if ocupacion:vida.ocupacion(self,Vector2(6,58),id,0)
		else:vida.permanencia(self,Vector2(-10,33),id)
func _initialize():call_deferred("run")
func run():
	var v=SubViewport.new();v.size=Vector2i(16,16);v.transparent_bg=true;v.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(v)
	var p=Pintor.new();v.add_child(p)
	for id in ["visitante","aspirante","residente","ausente","vigilar","explorar","comerciar"]:
		p.id=id;p.ocupacion=id in ["vigilar","explorar","comerciar"];p.queue_redraw()
		for i in 3:await process_frame
		await RenderingServer.frame_post_draw
		var im=v.get_texture().get_image();im=im.get_region(im.get_used_rect())
		assert(im.save_png("res://arte/pendientes_v1/icono_"+id+".png")==OK)
	var bayas=Image.create(16,12,false,Image.FORMAT_RGBA8);bayas.fill(Color(0,0,0,0))
	for q in [Vector2i(7,0),Vector2i(0,2),Vector2i(12,5)]:bayas.fill_rect(Rect2i(q,Vector2i(2,2)),Color("d94a35"))
	bayas.save_png("res://arte/pendientes_v1/bayas_marca.png")
	var azada=Image.create(8,24,false,Image.FORMAT_RGBA8);azada.fill(Color(0,0,0,0))
	for y in 23:azada.set_pixel(roundi(4.0-3.0*y/22.0),y,Color("80522f"))
	azada.fill_rect(Rect2i(0,0,7,2),Color("a8b2bb"));azada.save_png("res://arte/pendientes_v1/azada.png")
	print("INDICADORES: siete iconos, marcas de bayas y azada guardados como PNG")
	v.queue_free();await process_frame;quit()
