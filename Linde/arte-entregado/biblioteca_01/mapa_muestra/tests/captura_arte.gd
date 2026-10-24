extends SceneTree
func _initialize():
 call_deferred("capture")
func capture():
 var scene=load("res://main.tscn").instantiate()
 scene.ruta="res://.prueba_aislada_no_guardar.json"
 root.add_child(scene)
 for i in 20: await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 var err=image.save_png("res://captura_escenario_27_24.png")
 print("CAPTURE ",err," ",image.get_size())
 scene.queue_free()
 await process_frame
 preload("res://scripts/arte.gd").texturas.clear()
 await process_frame
 quit(0 if err==OK else 1)
