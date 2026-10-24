extends SceneTree
var entries=[]
var checks=[]
func extract(source:Image,region:Rect2i,id:String,size:Vector2i,kind:String):
 var part=source.get_region(region)
 for y in part.get_height():
  for x in part.get_width():
   var c=part.get_pixel(x,y)
   part.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color(0,0,0,0))
 var box=part.get_used_rect()
 if box.size.x<1 or box.size.y<1:push_error(id+" empty");quit(1);return
 var body=part.get_region(box)
 var target=size-Vector2i(4,4)
 var ratio=minf(float(target.x)/body.get_width(),float(target.y)/body.get_height())
 var actual=Vector2i(maxi(1,roundi(body.get_width()*ratio)),maxi(1,roundi(body.get_height()*ratio)))
 body.resize(actual.x,actual.y,Image.INTERPOLATE_NEAREST)
 var result=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
 result.blit_rect(body,Rect2i(Vector2i.ZERO,actual),(size-actual)/2)
 var colors={};var partial=0;var opaque=0
 for y in size.y:
  for x in size.x:
   var c=result.get_pixel(x,y)
   if c.a>0 and c.a<1:partial+=1
   if c.a==1:opaque+=1;colors[c.to_html(false)]=true
 result.save_png("res://assets/"+id+".png")
 entries.append({"id":id,"file":"assets/"+id+".png","size":[size.x,size.y],"kind":kind,"source_crop":[region.position.x,region.position.y,region.size.x,region.size.y],"alpha":"binary","scale":"integer_nearest","status":"proposed_native_asset","ninepatch":false})
 checks.append({"id":id,"opaque_pixels":opaque,"partial_alpha":partial,"color_count":colors.size(),"pass":partial==0 and opaque>0})
func _initialize():
 DirAccess.make_dir_recursive_absolute("res://assets")
 var icons=Image.load_from_file("res://original_iconos.png")
 var names=["madera","piedra","fibra","mena_hierro","lingote_hierro","baya","gelatina","unguento","gema","hacha_piedra","pico_piedra","espada_hierro","casco","coraza","escudo","categoria_oficio","categoria_exploracion","categoria_combate","categoria_comunidad","mision_icono"]
 for i in 20:
  var x0=roundi(icons.get_width()*(i%4)/4.0);var x1=roundi(icons.get_width()*((i%4)+1)/4.0)
  var y0=roundi(icons.get_height()*floori(i/4.0)/5.0);var y1=roundi(icons.get_height()*(floori(i/4.0)+1)/5.0)
  extract(icons,Rect2i(x0,y0,x1-x0,y1-y0),names[i],Vector2i(32,32),"inventory_icon")
 var ui=Image.load_from_file("res://original_widgets.png")
 var specs=[
 ["panel",[0,0,0.29,0.28],[64,48]],
 ["slot_normal",[0.29,0,0.51,0.28],[32,32]],
 ["slot_selected",[0.51,0,0.75,0.28],[32,32]],
 ["slot_disabled",[0.75,0,1,0.28],[32,32]],
 ["button_normal",[0,0.3,0.27,0.47],[64,24]],
 ["button_hover",[0.27,0.3,0.51,0.47],[64,24]],
 ["button_pressed",[0.51,0.3,0.75,0.47],[64,24]],
 ["healthbar_frame",[0.75,0.3,1,0.47],[64,24]],
 ["healthbar_full",[0,0.49,0.27,0.71],[64,24]],
 ["skill_locked",[0.27,0.49,0.51,0.71],[32,32]],
 ["skill_unlocked",[0.51,0.49,0.75,0.71],[32,32]],
 ["skill_selected",[0.75,0.49,1,0.71],[32,32]],
 ["quest_marker",[0,0.72,0.26,1],[32,32]],
 ["interact_indicator",[0.26,0.72,0.42,1],[24,32]],
 ["tooltip_panel",[0.42,0.72,0.76,1],[80,48]],
 ["counter_panel",[0.76,0.72,1,1],[64,24]]]
 for s in specs:
  var r=s[1];var x0=roundi(ui.get_width()*r[0]);var y0=roundi(ui.get_height()*r[1]);var x1=roundi(ui.get_width()*r[2]);var y1=roundi(ui.get_height()*r[3])
  extract(ui,Rect2i(x0,y0,x1-x0,y1-y0),s[0],Vector2i(s[2][0],s[2][1]),"ui_widget")
 # The red interior is derived from generated full bar, no code-drawn fill.
 var full=Image.load_from_file("res://assets/healthbar_full.png")
 var fill=full.get_region(Rect2i(10,10,44,5))
 fill.save_png("res://assets/healthbar_fill.png")
 entries.append({"id":"healthbar_fill","file":"assets/healthbar_fill.png","size":[44,5],"kind":"ui_fill","source":"healthbar_full generated red interior","ninepatch":false})
 var manifest={"date":"2026-10-23","tool":"built-in image_gen + Godot 4.7.1 Image nearest crop/resize","proposed_icon_canvas":[32,32],"entries":entries,"license_note":"AI-generated original candidate art; no third-party asset import; no warranty of exclusive copyright","ninepatch_note":"No widget certified as ninepatch; fixed-size textures for this delivery."}
 var f=FileAccess.open("res://manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify(manifest,"  "));f.close()
 f=FileAccess.open("res://checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"source_icon_size":[icons.get_width(),icons.get_height()],"source_ui_size":[ui.get_width(),ui.get_height()],"count":entries.size(),"checks":checks},"  "));f.close()
 print("UI_CONVERSION_OK count=",entries.size());quit()
