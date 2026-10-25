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
 var edited=Image.load_from_file("res://overlays_experimentales/edicion_original.png")
 var edited_size=[edited.get_width(),edited.get_height()]
 edited.resize(source.get_width(),source.get_height(),Image.INTERPOLATE_NEAREST)
 var cats=["casco","coraza","escudo","espada"];var dirs=["frente","derecha","espalda","izquierda"]
 var layers=[];var entries=[];var checks=[]
 for row in 4:
  var strip=Image.create(128,32,false,Image.FORMAT_RGBA8)
  var group=[]
  for col in 4:
   var x0=roundi(source.get_width()*col/4.0);var x1=roundi(source.get_width()*(col+1)/4.0)
   var y0=roundi(source.get_height()*row/4.0);var y1=roundi(source.get_height()*(row+1)/4.0)
   var region=Rect2i(x0,y0,x1-x0,y1-y0)
   var original=source.get_region(region)
   for y in original.get_height():
    for x in original.get_width():
     var c=original.get_pixel(x,y);original.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color.TRANSPARENT)
   largest_component(original)
   var box=original.get_used_rect()
   var body=edited.get_region(Rect2i(region.position+box.position,box.size))
   for y in body.get_height():
    for x in body.get_width():
     var c=body.get_pixel(x,y);body.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color.TRANSPARENT)
   var w=roundi(box.size.x*27.0/box.size.y)
   body.resize(w,27,Image.INTERPOLATE_NEAREST)
   var cell=Image.create(32,32,false,Image.FORMAT_RGBA8);var offset=Vector2i((32-w)/2,5)
   cell.blit_rect(body,Rect2i(0,0,w,27),offset)
   cell.save_png("res://overlays_experimentales/"+cats[row]+"_"+dirs[col]+".png")
   strip.blit_rect(cell,Rect2i(0,0,32,32),Vector2i(col*32,0));group.append(cell)
   entries.append({"id":cats[row]+"_"+dirs[col],"file":cats[row]+"_"+dirs[col]+".png","cell":[32,32],"original_source_box":[region.position.x+box.position.x,region.position.y+box.position.y,box.size.x,box.size.y],"native_size":[w,27],"native_offset":[offset.x,offset.y],"status":"experimental_unapproved_alignment"})
   var partial=0
   for y in 32:
    for x in 32:
     var a=cell.get_pixel(x,y).a
     if a>0 and a<1:partial+=1
   checks.append({"id":cats[row]+"_"+dirs[col],"partial_alpha":partial,"opaque_box":str(cell.get_used_rect()),"geometry_pass":partial==0})
  strip.save_png("res://overlays_experimentales/"+cats[row]+"_4_direcciones.png");layers.append(group)
 var base=Image.load_from_file("res://base_aprobada.png")
 var composite=Image.create(128,192,false,Image.FORMAT_RGBA8)
 composite.blit_rect(base,Rect2i(0,0,128,32),Vector2i.ZERO)
 for col in 4:
  var b=base.get_region(Rect2i(col*32,0,32,32))
  for row in 4:
   var sample=Image.create(32,32,false,Image.FORMAT_RGBA8)
   if (row==2 and col==1) or (row==3 and col==3):sample.blend_rect(layers[row][col],Rect2i(0,0,32,32),Vector2i.ZERO)
   sample.blend_rect(b,Rect2i(0,0,32,32),Vector2i.ZERO)
   if not ((row==2 and col==1) or (row==3 and col==3)):sample.blend_rect(layers[row][col],Rect2i(0,0,32,32),Vector2i.ZERO)
   composite.blit_rect(sample,Rect2i(0,0,32,32),Vector2i(col*32,(row+1)*32))
  var combined=Image.create(32,32,false,Image.FORMAT_RGBA8)
  if col==1:combined.blend_rect(layers[2][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col==3:combined.blend_rect(layers[3][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  combined.blend_rect(b,Rect2i(0,0,32,32),Vector2i.ZERO)
  combined.blend_rect(layers[1][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  combined.blend_rect(layers[0][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col!=1:combined.blend_rect(layers[2][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col!=3:combined.blend_rect(layers[3][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  composite.blit_rect(combined,Rect2i(0,0,32,32),Vector2i(col*32,160))
 composite.save_png("res://overlays_experimentales/composiciones_nativas_128x192.png")
 var bg=Image.create(128,192,false,Image.FORMAT_RGBA8);bg.fill(Color("27352e"));bg.blend_rect(composite,Rect2i(0,0,128,192),Vector2i.ZERO);bg.resize(768,1152,Image.INTERPOLATE_NEAREST);bg.save_png("res://overlays_experimentales/composiciones_ampliadas.png")
 var f=FileAccess.open("res://overlays_experimentales/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"entries":entries,"source_original_size":[source.get_width(),source.get_height()],"edit_size":edited_size,"native_cell":[32,32],"transform":"Original costume bbox and scale; equipment bbox never recentered","combination_order":"Right profile shield behind; left profile sword behind; other equipment in front","status":"EXPERIMENTAL; not production modular layers"},"  "));f.close()
 f=FileAccess.open("res://overlays_experimentales/checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"alignment_approved":false,"occlusion_approved":false},"  "));f.close();print("OVERLAY_EXPERIMENT16_OK");quit()
