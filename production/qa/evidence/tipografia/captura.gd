extends SceneTree
var esc
func foto(nombre: String) -> void:
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/linde-font-preview/"+nombre+".png")
func _init() -> void:
 esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-tipografia-qa.json"
 root.add_child(esc)
 await process_frame
 await foto("menu")
 esc.j=load("res://scripts/juego.gd").nueva(123,"Exploradora",[0,0,0])
 esc.modo="juego"
 esc._abrir("inv")
 await foto("inventario")
 esc.panel="dialogo"
 esc.dialogo_nombre="Nerea"
 esc.dialogo_txt="He llegado al valle buscando un lugar donde empezar de nuevo. ¿Podrías ayudarme a reunir madera para reparar el refugio?\nAquí todavía quedan historias por descubrir."
 await foto("dialogo")
 print("FUENTES: ",esc.hud.ui.fuente.get_font_name()," / ",esc.hud.ui.fuente_dialogo.get_font_name())
 quit()
