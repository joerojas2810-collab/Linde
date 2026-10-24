extends SceneTree
var out_path: String
func binary(img: Image) -> Image:
 var out=img.duplicate()
 for y in out.get_height():
  for x in out.get_width():
   var c=out.get_pixel(x,y)
   out.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color(0,0,0,0))
 return out
func group(c: Color, y: int) -> String:
 if c.r>0.55 and c.g>0.25 and c.b<c.r*0.92: return "piel"
 if y<17 and c.g>c.r*1.4 and c.b>c.r*1.3: return "pelo"
 if y>=16 and y<=25 and c.g>c.r*1.4 and c.g>c.b*0.80: return "tunica"
 if y>=24 and c.r>c.b*1.2 and c.r>c.g*1.1: return "botas"
 if y>=21 and y<25 and c.r>c.b*1.4 and c.r>c.g*1.1: return "cinturon"
 if y>=25 and c.b>c.r*1.15: return "pantalon"
 return "cuerpo"
func palette_reduce(img: Image, count: int):
 var samples=[]
 for y in img.get_height():
  for x in img.get_width():
   var c=img.get_pixel(x,y)
   if c.a>0.5:samples.append(Vector3(c.r,c.g,c.b))
 var centers=[]
 for k in count:centers.append(samples[int(k*samples.size()/float(count))])
 for iteration in 10:
  var sums=[];var ns=[]
  for k in count:sums.append(Vector3.ZERO);ns.append(0)
  for v in samples:
   var best=0;var distance=INF
   for k in count:
    var dd=v.distance_squared_to(centers[k])
    if dd<distance:distance=dd;best=k
   sums[best]+=v;ns[best]+=1
  for k in count:
   if ns[k]>0:centers[k]=sums[k]/ns[k]
 for y in img.get_height():
  for x in img.get_width():
   var c=img.get_pixel(x,y)
   if c.a<0.5:continue
   var v=Vector3(c.r,c.g,c.b);var best=0;var distance=INF
   for k in count:
    var dd=v.distance_squared_to(centers[k])
    if dd<distance:distance=dd;best=k
   var q=centers[best];img.set_pixel(x,y,Color(q.x,q.y,q.z,1.0))
func _initialize():
 out_path=ProjectSettings.globalize_path("res://")
 var metadata=JSON.parse_string(FileAccess.get_file_as_string("res://conversion.json"))
 var manifests=[]
 for entry in metadata:
  var source=binary(Image.load_from_file("res://originales/"+entry.id+".png"))
  var cell=int(entry.cell)
  var sheet=Image.create(cell*4,cell*4,false,Image.FORMAT_RGBA8)
  var base_heights=[]
  for row in 4:
   var v=entry.source_rects[row*4]
   var b=source.get_region(Rect2i(v[0],v[1],v[2],v[3])).get_used_rect()
   base_heights.append(b.size.y)
  base_heights.sort()
  var scale=27.0/float(base_heights[2])
  var crop_count=0
  for row in 4:
   for col in 4:
    var v=entry.source_rects[row*4+col]
    var part=source.get_region(Rect2i(v[0],v[1],v[2],v[3]))
    var b=part.get_used_rect()
    # Use the teal silhouette to anchor horizontal placement rather than extended weapons.
    var minx=part.get_width();var maxx=0
    for y in part.get_height():
     for x in part.get_width():
      var c=part.get_pixel(x,y)
      if c.a>0.5 and c.g>c.r*1.6 and c.b>c.r*1.4:
       minx=mini(minx,x);maxx=maxi(maxx,x)
    var center=(minx+maxx)/2.0 if maxx>=minx else b.get_center().x
    var body=part.get_region(b)
    var nw=maxi(1,roundi(body.get_width()*scale));var nh=maxi(1,roundi(body.get_height()*scale))
    body.resize(nw,nh,Image.INTERPOLATE_NEAREST)
    var ox=roundi(cell/2.0+(b.position.x-center)*scale)
    var oy=cell-nh
    if ox<0 or ox+nw>cell or oy<0:crop_count+=1
    sheet.blit_rect(body,Rect2i(0,0,nw,nh),Vector2i(col*cell+ox,row*cell+oy))
  palette_reduce(sheet,48 if cell==48 else 32)
  sheet.save_png("res://"+entry.native_file)
  manifests.append({"id":entry.id,"path":entry.native_file,"cell":cell,"columns":4,"rows":4,"directions":["frente","derecha","espalda","izquierda"],"pivot":[cell/2,cell],"source_grid":entry.source_rects,"clipped_cells":crop_count,"frame_duration_ms_proposed":140 if cell==32 else 110})
  if entry.id=="caminata":
   var layers={}
   for name in ["cuerpo","piel","pelo","tunica","pantalon","botas","cinturon"]:layers[name]=Image.create(128,128,false,Image.FORMAT_RGBA8)
   for y in 128:
    for x in 128:
     var c=sheet.get_pixel(x,y)
     if c.a>0.5:layers[group(c,y%32)].set_pixel(x,y,c)
   DirAccess.make_dir_recursive_absolute(out_path+"capas")
   for name in layers:layers[name].save_png("res://capas/"+name+".png")
   # Recolour previews alter existing masks, not the base silhouette or frame geometry.
   for variant in ["cobre","violeta","arena"]:
    var alt=sheet.duplicate()
    for y in 128:
     for x in 128:
      var c=sheet.get_pixel(x,y)
      if c.a<0.5:continue
      var part=group(c,y%32)
      var target=Color("cc8844") if variant=="cobre" else (Color("8060ae") if variant=="violeta" else Color("b8a16d"))
      if part in ["pelo","tunica"]:
       var val=maxf(c.r,maxf(c.g,c.b));alt.set_pixel(x,y,Color(target.r*val,target.g*val,target.b*val,1.0))
      if part=="piel" and variant=="cobre":alt.set_pixel(x,y,Color(c.r*0.72,c.g*0.65,c.b*0.62,1.0))
    alt.save_png("res://variante_"+variant+".png")
 var f=FileAccess.open("res://manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"assets":manifests,"layers":["cuerpo","piel","pelo","tunica","pantalon","botas","cinturon"],"status":"provisional"},"  "));f.close()
 print("PERSONAJE_NATIVE_OK")
 quit()
