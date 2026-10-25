extends SceneTree
var asset_root="/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Biblioteca_Arte_01/enemigos"
func _initialize():
 var reports=[]
 for spec in [["slime",32,16],["guardian",48,38],["ciervo",48,34]]:
  var id=spec[0];var cell_size=spec[1];var visible=spec[2]
  var source=Image.load_from_file(asset_root+"/originales/"+id+".png")
  if source==null:continue
  var parts=[];var maxdim=0
  for row in 4:
   for col in 5:
    var a=Vector2i(roundi(source.get_width()*col/5.0),roundi(source.get_height()*row/4.0))
    var b=Vector2i(roundi(source.get_width()*(col+1)/5.0),roundi(source.get_height()*(row+1)/4.0))
    var part=source.get_region(Rect2i(a,b-a))
    for y in part.get_height():
     for x in part.get_width():
      var c=part.get_pixel(x,y)
      part.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color(0,0,0,0))
    var box=part.get_used_rect()
    if box.size.x==0 or box.size.y==0:push_error("EMPTY "+id);quit(1);return
    maxdim=maxi(maxdim,maxi(box.size.x,box.size.y));parts.append(part.get_region(box))
  var scale_factor=float(visible)/maxdim
  var atlas=Image.create(cell_size*5,cell_size*4,false,Image.FORMAT_RGBA8)
  var hashes=[];var duplicate_walk=[]
  for i in 20:
   var body=parts[i]
   var w=maxi(1,roundi(body.get_width()*scale_factor));var h=maxi(1,roundi(body.get_height()*scale_factor))
   body.resize(w,h,Image.INTERPOLATE_NEAREST)
   var cell=Image.create(cell_size,cell_size,false,Image.FORMAT_RGBA8)
   cell.blit_rect(body,Rect2i(0,0,w,h),Vector2i((cell_size-w)/2,cell_size-3-h))
   hashes.append(hash(cell.get_data()))
   atlas.blit_rect(cell,Rect2i(0,0,cell_size,cell_size),Vector2i((i%5)*cell_size,(i/5)*cell_size))
  for row in 4:
   if hashes[row*5+1]==hashes[row*5+2]:duplicate_walk.append(row)
  atlas.save_png(asset_root+"/nativos/"+id+".png")
  var preview=atlas.duplicate();preview.resize(atlas.get_width()*6,atlas.get_height()*6,Image.INTERPOLATE_NEAREST);preview.save_png(asset_root+"/"+id+"_preview.png")
  reports.append({"id":id,"cell_size":[cell_size,cell_size],"atlas_size":[cell_size*5,cell_size*4],"pivot":[cell_size/2,cell_size-3],"directions":["south","east","north","west"],"columns":["idle","walk_a","walk_b","anticipation","attack"],"walk_identical_rows":duplicate_walk,"frame_hashes":hashes,"source_size":[source.get_width(),source.get_height()],"uniform_scale":scale_factor,"alpha":"binary_threshold_0.5","license_note":"AI generated; no third party game assets; not legal clearance","content_status":"proposal_not_canon","animations":{"idle":{"frames":[0],"seconds":0.5},"walk":{"frames":[1,0,2,0],"seconds":0.15},"attack":{"frames":[3,4,0],"seconds":0.2}},"timing_status":"provisional"})
 var f=FileAccess.open(asset_root+"/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"assets":reports,"status":"prototype_library_not_game_integration"},"  "));f.close()
 print("Converted ",reports.size()," enemy sheets");quit()
