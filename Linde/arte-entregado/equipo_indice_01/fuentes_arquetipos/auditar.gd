extends SceneTree
func _init():
 var p="/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Equipo_Indice_01/fuentes_arquetipos/"
 var report={}
 for a in ["ligera","pesada"]:
  for s in ["casco","torso"]:
   var n=a+"_"+s+"_quieto.png"
   var im=Image.load_from_file(p+n)
   var colors={};var partial=0;var cells=[]
   for d in range(4):
    var occupied=0
    for y in range(32):
     for x in range(32):
      var c=im.get_pixel(x,d*32+y)
      if c.a>0 and c.a<1:partial+=1
      if c.a==1:
       colors[c.to_html(false)]=true
       occupied+=1
    cells.append(occupied)
   report[n]={"size":[im.get_width(),im.get_height()],"opaque_colors":colors.keys(),"partial_alpha":partial,"opaque_pixels_by_direction":cells,"final_walk_atlas":false}
 var f=FileAccess.open(p+"auditoria_fuentes.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"\t"))
 print(JSON.stringify(report))
 quit()
