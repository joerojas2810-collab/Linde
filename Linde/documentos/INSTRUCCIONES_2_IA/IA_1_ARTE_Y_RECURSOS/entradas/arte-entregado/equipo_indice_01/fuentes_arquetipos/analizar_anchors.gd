extends SceneTree
func _init():
 var p="/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Equipo_Indice_01/"
 var result={}
 for name in ["pelo","tunica","cinturon","piel","botas"]:
  var im=Image.load_from_file(p+"base/capas/"+name+".png")
  var rows=[]
  for d in range(4):
   var cells=[]
   for frame in range(4):
    var mn=Vector2i(32,32);var mx=Vector2i(-1,-1);var sum=Vector2.ZERO;var n=0
    for y in range(32):
     for x in range(32):
      if im.get_pixel(frame*32+x,d*32+y).a>0:
       mn=mn.min(Vector2i(x,y));mx=mx.max(Vector2i(x,y));sum+=Vector2(x,y);n+=1
    var cell=im.get_region(Rect2i(frame*32,d*32,32,32))
    cells.append({"bounds":[mn.x,mn.y,mx.x,mx.y],"center":[sum.x/maxi(1,n),sum.y/maxi(1,n)],"pixels":n,"hash":cell.get_data().hex_encode().sha256_text()})
   rows.append(cells)
  result[name]=rows
 var f=FileAccess.open(p+"fuentes_arquetipos/anchors_base.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(result,"\t"))
 for name in result:
  print(name)
  for d in range(4):
   var a=[]
   for c in result[name][d]:a.append(str(c.bounds)+" "+c.hash.substr(0,5))
   print(d,": ",a)
 quit()
