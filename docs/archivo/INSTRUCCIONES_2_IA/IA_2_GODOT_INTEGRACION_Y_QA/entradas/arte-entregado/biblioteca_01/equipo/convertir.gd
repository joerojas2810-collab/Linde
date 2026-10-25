extends SceneTree
func largest_component(im:Image):
 var seen={};var best=[]
 for y in im.get_height():
  for x in im.get_width():
   var start=Vector2i(x,y)
   if seen.has(start) or im.get_pixel(x,y).a<0.5:continue
   var group=[start];seen[start]=true;var index=0
   while index<group.size():
    var pos=group[index];index+=1
    for yy in range(-1,2):
     for xx in range(-1,2):
      var n=pos+Vector2i(xx,yy)
      if n.x<0 or n.y<0 or n.x>=im.get_width() or n.y>=im.get_height() or seen.has(n):continue
      if im.get_pixel(n.x,n.y).a>=0.5:seen[n]=true;group.append(n)
   if group.size()>best.size():best=group
 var keep={}
 for pos in best:keep[pos]=true
 for y in im.get_height():
  for x in im.get_width():
   if not keep.has(Vector2i(x,y)):im.set_pixel(x,y,Color.TRANSPARENT)
func _initialize():
 var source=Image.load_from_file("res://original_equipo.png")
 var sheet=Image.create(128,128,false,Image.FORMAT_RGBA8)
 var categories=["casco","coraza","escudo","espada"]
 var dirs=["frente","derecha","espalda","izquierda"]
 var entries=[];var checks=[]
 for row in 4:
  var strip=Image.create(128,32,false,Image.FORMAT_RGBA8)
  for col in 4:
   var x0=roundi(source.get_width()*col/4.0);var x1=roundi(source.get_width()*(col+1)/4.0)
   var y0=roundi(source.get_height()*row/4.0);var y1=roundi(source.get_height()*(row+1)/4.0)
   var part=source.get_region(Rect2i(x0,y0,x1-x0,y1-y0))
   for y in part.get_height():
    for x in part.get_width():
     var c=part.get_pixel(x,y);part.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color(0,0,0,0))
   largest_component(part)
   var rect=part.get_used_rect();var body=part.get_region(rect)
   var w=roundi(body.get_width()*27.0/body.get_height());body.resize(w,27,Image.INTERPOLATE_NEAREST)
   var cell=Image.create(32,32,false,Image.FORMAT_RGBA8);cell.blit_rect(body,Rect2i(0,0,w,27),Vector2i((32-w)/2,5))
   var id=categories[row]+"_"+dirs[col]
   cell.save_png("res://assets/"+id+".png")
   strip.blit_rect(cell,Rect2i(0,0,32,32),Vector2i(col*32,0))
   sheet.blit_rect(cell,Rect2i(0,0,32,32),Vector2i(col*32,row*32))
   var partial=0;var opaque=0
   for y in 32:
    for x in 32:
     var a=cell.get_pixel(x,y).a
     if a>0 and a<1:partial+=1
     if a==1:opaque+=1
   checks.append({"id":id,"partial_alpha":partial,"opaque":opaque,"pass":partial==0 and opaque>0})
   entries.append({"id":id,"file":"assets/"+id+".png","size":[32,32],"direction":dirs[col],"equipment":categories[row],"kind":"complete_static_costume","overlay":false,"foot_anchor":[16,32],"frames":1})
  strip.save_png("res://assets/"+categories[row]+"_4_direcciones.png")
 sheet.save_png("res://equipo_estatico_128x128.png")
 var base=Image.load_from_file("res://base_aprobada.png")
 var view=Image.create(128,160,false,Image.FORMAT_RGBA8);view.fill(Color("27352e"));view.blend_rect(base,Rect2i(0,0,128,32),Vector2i.ZERO);view.blend_rect(sheet,Rect2i(0,0,128,128),Vector2i(0,32));view.resize(768,960,Image.INTERPOLATE_NEAREST);view.save_png("res://comparacion_base_y_equipo.png")
 var f=FileAccess.open("res://manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"date":"2026-10-23","entries":entries,"atlas":"equipo_estatico_128x128.png","layout":{"columns":"frente,derecha,espalda,izquierda","rows":"casco,coraza,escudo,espada","cell":[32,32]},"layer_status":"NOT modular; complete static costumes only","status":"proposed visual fallback, not integrated"},"  "));f.close()
 f=FileAccess.open("res://checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"source_size":[source.get_width(),source.get_height()],"checks":checks,"modularity_verified":false,"occlusion_verified":false},"  "));f.close();print("EQUIPO_STATIC_OK16");quit()
