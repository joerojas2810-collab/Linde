extends SceneTree
func _initialize():call_deferred("capture")
func capture():
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene)
 for i in 8:await process_frame
 scene.set_process(false)
 scene.usar_arte=true
 scene.j.d.inv["espada_hierro"]=1
 scene.j.d.equipo={"casco":"casco_hierro","coraza":"coraza_hierro","escudo":"escudo_madera"}
 for pair in [["frente",Vector2i.DOWN],["derecha",Vector2i.RIGHT],["espalda",Vector2i.UP],["izquierda",Vector2i.LEFT]]:
  scene.j.mira=pair[1]
  scene.queue_redraw()
  await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://captura_equipo_%s.png"%pair[0])==OK)
 print("EQUIPO_MAPA_OK")
 scene.queue_free()
 await process_frame
 quit()
