extends SceneTree
const BASE = "res://"
func _initialize():
 var conf = JSON.parse_string(FileAccess.get_file_as_string(BASE+"config.json"))
 var records=[]
 for group in conf:
  var source=Image.load_from_file(BASE+group.source)
  if source==null:
   push_error("No image "+group.source)
   quit(1)
   return
  source.convert(Image.FORMAT_RGBA8)
  var cols=int(group.cols)
  var rows=int(group.rows)
  var cw=int(source.get_width()/cols)
  var ch=int(source.get_height()/rows)
  for i in group.ids.size():
   var rect=Rect2i((i%cols)*cw+1,int(i/cols)*ch+1,cw-2,ch-2)
   if group.has("rects"):
    var q=group.rects[i]
    rect=Rect2i(q[0],q[1],q[2],q[3])
   var tile=source.get_region(rect)
   if group.kind!="tile":
    var used=tile.get_used_rect()
    tile=tile.get_region(used)
    var scale_ratio=float(group.size-4)/max(tile.get_width(),tile.get_height())
    tile.resize(max(1,int(tile.get_width()*scale_ratio)),max(1,int(tile.get_height()*scale_ratio)),Image.INTERPOLATE_NEAREST)
    var padded=Image.create(int(group.size),int(group.size),false,Image.FORMAT_RGBA8)
    padded.fill(Color.TRANSPARENT)
    padded.blit_rect(tile,Rect2i(0,0,tile.get_width(),tile.get_height()),Vector2i(int((group.size-tile.get_width())/2),int(group.size)-tile.get_height()-2))
    tile=padded
   else:
    tile.resize(int(group.size),int(group.size),Image.INTERPOLATE_NEAREST)
   var solid=0
   for y in tile.get_height():
    for x in tile.get_width():
     var color=tile.get_pixel(x,y)
     color.a=1.0 if color.a>=0.5 else 0.0
     if color.a>0: solid+=1
     tile.set_pixel(x,y,color)
   var id=group.ids[i]
   var file="assets/"+id+".png"
   var err=tile.save_png(BASE+file)
   if err!=OK:
    quit(2)
    return
   records.append({"id":id,"file":file,"size":[int(group.size),int(group.size)],"pivot":[int(group.size)/2,int(group.size)*0.9],"source":group.source,"source_cell":[i%cols,int(i/cols)],"alpha_binary":true,"opaque_pixels":solid,"status":"initial_native_candidate","tileability":"not_verified" if group.kind=="tile" else "not_applicable"})
 var f=FileAccess.open(BASE+"manifest.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"assets":records,"count":records.size(),"method":"Godot nearest resize per equal atlas cell; alpha threshold 0.5; no palette normalization","collision":"author separately; pivot is provisional"},"  "))
 f.close()
 var contact=Image.create(768,768,false,Image.FORMAT_RGBA8)
 contact.fill(Color("26372e"))
 for n in records.size():
  var pic=Image.load_from_file(BASE+records[n].file)
  var zoom=6 if pic.get_width()==16 else (2 if pic.get_width()==48 else 1)
  pic.resize(pic.get_width()*zoom,pic.get_height()*zoom,Image.INTERPOLATE_NEAREST)
  contact.blend_rect(pic,Rect2i(0,0,pic.get_width(),pic.get_height()),Vector2i((n%6)*128+16,int(n/6)*128+16))
 contact.save_png(BASE+"catalogo.png")
 print("EXPORTED ",records.size()," assets")
 quit()
