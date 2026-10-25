extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var carpeta: String
func foto(nombre: String) -> void:
 for i in 4:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/proteccion")
 esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-captura-proteccion.json"
 root.add_child(esc)
 await process_frame
 esc.j=J.nueva(123,"Exploradora",[0,0,0]);esc.j.autonomia.activar();esc.j.combate.enemigos.clear();esc.modo="juego"
 esc.j.pies=M.pies_de_celda(Vector2i(32,40))
 esc.j.jug().inv={"madera":4,"candado":1,"lingote":3,"fibra":8}
 esc.j.construir("cofre",Vector2i(33,40));esc.j.gestionar_cofre("c@33,40","instalar")
 esc.j.unir("amiga","Lía",[0,0,0])
 esc.cofre_id="c@33,40";esc._abrir("cofre")
 await foto("cofre-propio")
 esc.j.mundo.constr_en(Vector2i(33,40)).dueno="npc:maren"
 esc._armar();await foto("cofre-ajeno")
 if FileAccess.file_exists("/tmp/linde-simulacion-nueva.json"):
  esc.j=J.cargar("/tmp/linde-simulacion-nueva.json")
 esc._abrir("mis");await foto("sociedad")
 for i in esc.lineas.size():
  if esc.lineas[i].contains("ECONOMÍA"):
   esc.sel=i;await foto("economia");break
 var npc: String=esc.j.habitantes.ids.back()
 esc.panel="dialogo";esc.dialogo_nombre=esc.j.habitantes.fichas[npc].n;esc.dialogo_txt=esc.j.autonomia.dialogo(npc,J.LOCAL)
 await foto("dialogo")
 print("CAPTURAS_PROTECCION_OK")
 quit()
