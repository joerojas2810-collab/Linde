extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var stage=load("res://main.tscn").instantiate();root.add_child(stage)
 await process_frame
 stage.j=load("res://scripts/juego.gd").nueva(7,"Prueba arte",[0,1,0],"viajero")
 stage.modo="juego";stage.usar_arte=true
 var out="/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Biblioteca_Arte_01/enemigos/"
 for tipo in ["slime","guardian","ciervo"]:
  for enemy in stage.j.combate.enemigos:
   if enemy.tipo==tipo:
    stage.j.pies=enemy.pos+Vector2(0,48)
    break
  await create_timer(0.25).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(out+"mapa_"+tipo+".png")
 print("Enemy map captures saved");quit()
