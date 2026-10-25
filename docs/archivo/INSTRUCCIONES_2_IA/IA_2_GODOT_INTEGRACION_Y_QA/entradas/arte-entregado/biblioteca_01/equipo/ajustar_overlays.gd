extends SceneTree
var targets=[
 [Rect2i(8,3,16,11),Rect2i(9,3,15,11),Rect2i(8,3,16,11),Rect2i(9,3,15,11)],
 [Rect2i(10,17,12,8),Rect2i(12,17,9,8),Rect2i(10,17,12,8),Rect2i(12,17,9,8)],
 [Rect2i(19,17,10,12),Rect2i(10,17,7,11),Rect2i(2,17,11,12),Rect2i(13,17,12,12)],
 [Rect2i(5,9,8,16),Rect2i(10,9,11,16),Rect2i(20,9,8,16),Rect2i(5,11,8,16)]
]
func clean_steel(im:Image)->Image:
 var out=Image.create(im.get_width(),im.get_height(),false,Image.FORMAT_RGBA8)
 for y in im.get_height():
  for x in im.get_width():
   var c=im.get_pixel(x,y)
   if c.a>0.5 and c.s<0.3 and c.v>0.3:out.set_pixel(x,y,c)
 return out
func fit(im:Image,target:Rect2i,outline:bool)->Image:
 var result=Image.create(32,32,false,Image.FORMAT_RGBA8)
 var box=im.get_used_rect()
 if box.size.x<1:return result
 var body=im.get_region(box)
 var margin=1 if outline else 0
 var area=target.size-Vector2i(margin*2,margin*2)
 var ratio=minf(float(area.x)/box.size.x,float(area.y)/box.size.y)
 var sz=Vector2i(maxi(1,roundi(box.size.x*ratio)),maxi(1,roundi(box.size.y*ratio)))
 body.resize(sz.x,sz.y,Image.INTERPOLATE_NEAREST)
 var pos=target.position+(target.size-sz)/2
 if outline:
  for y in sz.y:
   for x in sz.x:
    if body.get_pixel(x,y).a<0.5:continue
    for n in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var p=pos+Vector2i(x,y)+n
     if p.x>=0 and p.y>=0 and p.x<32 and p.y<32:result.set_pixel(p.x,p.y,Color("16242b"))
 result.blend_rect(body,Rect2i(Vector2i.ZERO,sz),pos)
 return result
func _initialize():
 var cats=["casco","coraza","escudo","espada"];var dirs=["frente","derecha","espalda","izquierda"]
 var layers=[];var entries=[]
 for row in 4:
  var group=[];var strip=Image.create(128,32,false,Image.FORMAT_RGBA8)
  var atlas=Image.create(128,128,false,Image.FORMAT_RGBA8)
  for col in 4:
   var source=Image.load_from_file("res://overlays_experimentales/"+cats[row]+"_"+dirs[col]+".png")
   var filtered=clean_steel(source) if row<2 else source
   var layer=fit(filtered,targets[row][col],row<2)
   layer.save_png("res://overlays_ajustados/"+cats[row]+"_"+dirs[col]+".png")
   strip.blit_rect(layer,Rect2i(0,0,32,32),Vector2i(col*32,0));group.append(layer)
   for frame in 4:atlas.blit_rect(layer,Rect2i(0,0,32,32),Vector2i(frame*32,col*32))
   entries.append({"id":cats[row]+"_"+dirs[col],"target":[targets[row][col].position.x,targets[row][col].position.y,targets[row][col].size.x,targets[row][col].size.y],"actual_box":str(layer.get_used_rect()),"steel_mask":row<2})
  layers.append(group);strip.save_png("res://overlays_ajustados/"+cats[row]+"_4_direcciones.png");atlas.save_png("res://overlays_ajustados/"+cats[row]+"_atlas_128x128.png")
 var base=Image.load_from_file("res://base_aprobada.png")
 var output=Image.create(128,192,false,Image.FORMAT_RGBA8);output.blit_rect(base,Rect2i(0,0,128,32),Vector2i.ZERO)
 for col in 4:
  var b=base.get_region(Rect2i(col*32,0,32,32))
  for row in 4:
   var c=Image.create(32,32,false,Image.FORMAT_RGBA8)
   var behind=(row==2 and col==1) or (row==3 and col==3)
   if behind:c.blend_rect(layers[row][col],Rect2i(0,0,32,32),Vector2i.ZERO)
   c.blend_rect(b,Rect2i(0,0,32,32),Vector2i.ZERO)
   if not behind:c.blend_rect(layers[row][col],Rect2i(0,0,32,32),Vector2i.ZERO)
   output.blit_rect(c,Rect2i(0,0,32,32),Vector2i(col*32,(row+1)*32))
  var c=Image.create(32,32,false,Image.FORMAT_RGBA8)
  if col==1:c.blend_rect(layers[2][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col==3:c.blend_rect(layers[3][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  c.blend_rect(b,Rect2i(0,0,32,32),Vector2i.ZERO)
  for row in [1,0]:c.blend_rect(layers[row][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col!=1:c.blend_rect(layers[2][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  if col!=3:c.blend_rect(layers[3][col],Rect2i(0,0,32,32),Vector2i.ZERO)
  output.blit_rect(c,Rect2i(0,0,32,32),Vector2i(col*32,160))
 output.save_png("res://overlays_ajustados/composiciones_nativas_128x192.png")
 var preview=Image.create(128,192,false,Image.FORMAT_RGBA8);preview.fill(Color("27352e"));preview.blend_rect(output,Rect2i(0,0,128,192),Vector2i.ZERO);preview.resize(768,1152,Image.INTERPOLATE_NEAREST);preview.save_png("res://overlays_ajustados/composiciones_ampliadas.png")
 var f=FileAccess.open("res://overlays_ajustados/manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"date":"2026-10-23","entries":entries,"native_cell":[32,32],"atlas":{"size":[128,128],"rows":["frente","derecha","espalda","izquierda"],"columns":"four repeated idle poses, NOT animation"},"method":"Steel saturation<0.30,value>0.30; aspect fit into manual target; derived1px dark outline for metal","status":"technical adjustment candidate, static only"},"  "));f.close()
 var checks=[]
 for cat in cats:
  var atlas=Image.load_from_file("res://overlays_ajustados/"+cat+"_atlas_128x128.png")
  atlas.save_png("res://overlays_ajustados/personaje_"+cat+".png")
  var partial=0;var repeats=true
  for y in 128:
   for x in 128:
    var c=atlas.get_pixel(x,y)
    if c.a>0 and c.a<1:partial+=1
    if c!=atlas.get_pixel(x%32,y):repeats=false
  checks.append({"id":cat,"size":[atlas.get_width(),atlas.get_height()],"partial_alpha":partial,"four_frames_identical":repeats,"pass":partial==0 and repeats})
 f=FileAccess.open("res://overlays_ajustados/checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"static_art_review":"candidate readable, armor now torso only; no hand-occlusion or walking acceptance"},"  "));f.close()
 f=FileAccess.open("res://overlays_ajustados/personaje_equipo_fragmento.json",FileAccess.WRITE);f.store_string(JSON.stringify({"celda":32,"capas":["casco","coraza","escudo","espada"],"note":"Merge layer names into main personaje.json; this fragment contains no base body. Equipment columns are repeated static poses."},"  "));f.close();print("ADJUSTED_OK");quit()
