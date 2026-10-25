extends SceneTree
func patch(src:Image,w:int,h:int,m:int)->Image:
 var out=Image.create(w,h,false,Image.FORMAT_RGBA8)
 var sx=[0,m,src.get_width()-m,src.get_width()];var sy=[0,m,src.get_height()-m,src.get_height()]
 var dx=[0,m,w-m,w];var dy=[0,m,h-m,h]
 for y in 3:
  for x in 3:
   var region=src.get_region(Rect2i(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y]))
   region.resize(dx[x+1]-dx[x],dy[y+1]-dy[y],Image.INTERPOLATE_NEAREST)
   out.blit_rect(region,Rect2i(0,0,region.get_width(),region.get_height()),Vector2i(dx[x],dy[y]))
 return out
func _initialize():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
 var sheet=Image.create(768,576,false,Image.FORMAT_RGBA8);sheet.fill(Color("27352e"))
 var i=0
 for e in data.entries:
  var im=Image.load_from_file("res://"+e.file)
  im.resize(im.get_width()*2,im.get_height()*2,Image.INTERPOLATE_NEAREST)
  sheet.blend_rect(im,Rect2i(0,0,im.get_width(),im.get_height()),Vector2i(16+(i%6)*126,16+floori(i/6.0)*76))
  i+=1
 sheet.save_png("res://galeria.png")
 var panel=Image.load_from_file("res://assets/panel.png")
 var test=Image.create(512,192,false,Image.FORMAT_RGBA8);test.fill(Color("27352e"))
 var sizes=[Vector2i(96,64),Vector2i(160,96),Vector2i(192,128)]
 var x=8;var pass_corners=true
 for size in sizes:
  var p=patch(panel,size.x,size.y,8)
  for yy in 8:
   for xx in 8:
    if p.get_pixel(xx,yy)!=panel.get_pixel(xx,yy):pass_corners=false
    if p.get_pixel(size.x-8+xx,size.y-8+yy)!=panel.get_pixel(panel.get_width()-8+xx,panel.get_height()-8+yy):pass_corners=false
  test.blend_rect(p,Rect2i(Vector2i.ZERO,size),Vector2i(x,16));x+=size.x+8
 test.save_png("res://prueba_ninepatch.png")
 var f=FileAccess.open("res://ninepatch_check.json",FileAccess.WRITE);f.store_string(JSON.stringify({"panel":"assets/panel.png","margins":[8,8,8,8],"tested_sizes":[[96,64],[160,96],[192,128]],"corners_exact":pass_corners,"method":"Godot Image 3x3 regions, nearest center stretch; visual inspection still required in final game"},"  "));f.close()
 for e in data.entries:
  if e.id=="panel":e.ninepatch=true;e.ninepatch_margins=[8,8,8,8];e.ninepatch_check="ninepatch_check.json"
 data.ninepatch_note="panel tested at three sizes with exact corners; other widgets fixed-size textures."
 f=FileAccess.open("res://manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));f.close();quit()
