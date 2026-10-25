extends SceneTree
func _initialize():
 call_deferred("capture")
func capture():
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 await process_frame
 for pair in [["frente",Vector2i.DOWN],["derecha",Vector2i.RIGHT],["espalda",Vector2i.UP],["izquierda",Vector2i.LEFT]]:
  scene.j.mira=pair[1]
  scene.queue_redraw()
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://../mapa_%s.png" % pair[0])
 scene.queue_free()
 await process_frame
 quit()
