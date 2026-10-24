extends Node2D
var picture: Texture2D
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 picture=load("res://previews/E05_muestra_nativa.png") as Texture2D
 if picture==null or picture.get_size()!=Vector2(512,320):
  push_error("Muestra no cargada");get_tree().quit(1);return
 queue_redraw()
 if "--captura" in OS.get_cmdline_user_args():
  for i in range(60):await get_tree().process_frame
  await RenderingServer.frame_post_draw
  var result:=get_viewport().get_texture().get_image().save_png("res://validacion/E05_muestra_godot.png")
  print("E05: render real 60 frames; captura resultado=",result)
  get_tree().quit(0 if result==OK else 1)
func _draw() -> void:
 draw_string(ThemeDB.fallback_font,Vector2(24,35),"E05 · Casa y objetos · primer sublote",HORIZONTAL_ALIGNMENT_LEFT,-1,24)
 if picture:draw_texture_rect(picture,Rect2(24,70,1024,640),false)
 draw_string(ThemeDB.fallback_font,Vector2(24,745),"Muestra a escala nativa ×2 nearest. Sin integración de mapa ni modificación de colisiones.",HORIZONTAL_ALIGNMENT_LEFT,-1,17)
 draw_string(ThemeDB.fallback_font,Vector2(24,780),"Escala/anclas pendientes de revisión antes de la serie completa.",HORIZONTAL_ALIGNMENT_LEFT,-1,17)
