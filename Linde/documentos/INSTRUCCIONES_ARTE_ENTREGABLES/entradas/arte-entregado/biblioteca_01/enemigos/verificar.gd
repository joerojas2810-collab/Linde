extends SceneTree
func _initialize():
 var base="/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Biblioteca_Arte_01/enemigos/"
 var report=[];var good=true
 for spec in [["slime",32],["guardian",48],["ciervo",48]]:
  var pic=Image.load_from_file(base+"nativos/"+spec[0]+".png");var size=spec[1];var partial=0;var empty=0;var edge=0;var counts=[]
  for y in pic.get_height():
   for x in pic.get_width():
    var a=pic.get_pixel(x,y).a
    if a>0.0 and a<1.0:partial+=1
  for row in 4:
   for col in 5:
    var tile=pic.get_region(Rect2i(col*size,row*size,size,size));var box=tile.get_used_rect();counts.append([box.position.x,box.position.y,box.size.x,box.size.y])
    if box.size.x==0:empty+=1
    if box.position.x==0 or box.position.y==0 or box.end.x==size or box.end.y==size:edge+=1
  var ok=partial==0 and empty==0 and edge==0;good=good and ok
  report.append({"id":spec[0],"partial_alpha_pixels":partial,"empty_frames":empty,"touching_cell_edge":edge,"used_rectangles":counts,"passed":ok})
 var f=FileAccess.open(base+"validacion.json",FileAccess.WRITE);f.store_string(JSON.stringify({"assets":report,"passed":good,"scope":"structural_only_not_artistic_quality"},"  "));f.close();print("Validation passed: ",good);quit(0 if good else 1)
