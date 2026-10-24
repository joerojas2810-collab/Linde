extends SceneTree
func _initialize():call_deferred("capture")
func frame(scene, path):
 scene.queue_redraw()
 await RenderingServer.frame_post_draw
 var err=root.get_texture().get_image().save_png(path)
 assert(err==OK)
func capture():
 var scene=load("res://main.tscn").instantiate()
 scene.ruta="res://.muestra_temporal.json"
 root.add_child(scene)
 for i in 8:await process_frame
 scene.set_process(false)
 scene.usar_arte=true
 scene.j.mira=Vector2i.DOWN
 await frame(scene,"res://captura_biblioteca.png")
 scene.j.d.inv["espada_hierro"]=1
 scene.j.combate.est="activo"
 scene.j.combate.dir=Vector2i.RIGHT
 scene.j.combate.inv_t=0.0
 await frame(scene,"res://captura_ataque.png")
 scene.j.combate.est="libre"
 scene.j.mira=Vector2i.RIGHT
 scene.herramienta_visual=0.14
 await frame(scene,"res://captura_herramienta.png")
 scene.herramienta_visual=0.0
 scene.panel="inv"
 scene._armar()
 await frame(scene,"res://captura_inventario.png")
 print("CAPTURAS_BIBLIOTECA_OK")
 scene.queue_free()
 await process_frame
 quit()
