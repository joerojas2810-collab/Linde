extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
var esc
var carpeta: String
func encontrar(tipo: String) -> Dictionary:
 for y in range(-16,17):
  for x in range(-16,17):
   var p: Dictionary = esc.j.combate.fauna.plan_region(Vector2i(x,y))
   if p.is_empty() or p.tipo!=tipo: continue
   esc.j.pies=M.pies_de_celda(p.celda+Vector2i(9,0))
   esc.j.actualizar_regiones()
   esc.j.combate.fauna.actualizar()
   for e in esc.j.combate.enemigos:
    if e.get("fauna_id", "")==p.id: return e
 return {}
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/fauna")
 DirAccess.make_dir_recursive_absolute(carpeta)
 esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-captura-fauna.json"
 root.add_child(esc)
 await process_frame
 esc.j=J.nueva(123,"Exploradora",[0,0,0]);esc.modo="juego"
 for tipo in ["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]:
  var e: Dictionary=encontrar(tipo)
  if e.is_empty():push_error("Sin encuentro real de "+tipo);quit(1);return
  esc.j.pies=e.pos+Vector2(40,16)
  esc.cam.position=e.pos-Vector2(0,12)
  esc.cam.reset_smoothing()
  for i in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(carpeta+"/"+tipo+".png")
  print("CAPTURA ",tipo," ",e.fauna_id," ",e.pos)
 if not esc.actores.faltantes.is_empty():push_error("Arte de fauna faltante");quit(1);return
 print("CAPTURAS_FAUNA_OK")
 quit()
