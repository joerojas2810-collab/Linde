extends SceneTree
const OUT = "/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Equipo_Indice_01/fuentes_arquetipos/"
const ROLES = [Color8(0,255,0),Color8(255,0,0),Color8(128,128,128),Color8(0,0,255)]
func _init():
 var img = Image.load_from_file(OUT+"variantes_generadas.png")
 var data = {}
 var cells = [Rect2i(180,75,203,374),Rect2i(575,75,205,374),Rect2i(996,75,203,374),Rect2i(1392,75,202,374)]
 for arq in ["ligera","pesada"]:
  for slot in ["casco","torso"]:
   var out = Image.create(32,128,false,Image.FORMAT_RGBA8)
   var masks = []
   for d in range(4):
    var x = cells[d].position.x
    var y = 75 if arq=="ligera" else 483
    var box: Rect2i
    var target: Rect2i
    if slot=="casco":
     box=Rect2i(x,y,cells[d].size.x,145 if arq=="ligera" else 191)
     target=Rect2i(8,3,16,11 if arq=="ligera" else 14)
    else:
     box=Rect2i(x,y+203,cells[d].size.x,87) if arq=="ligera" else Rect2i(x,y+187,cells[d].size.x,92)
     target=Rect2i(10,17,12,8) if arq=="ligera" else Rect2i(8,17,16,8)
    for ty in range(target.size.y):
     for tx in range(target.size.x):
      var values=[]
      for sy in range(4):
       for sx in range(4):
        var px=box.position.x+int((tx+(sx+.5)/4.0)*box.size.x/target.size.x)
        var py=box.position.y+int((ty+(sy+.5)/4.0)*box.size.y/target.size.y)
        var c=img.get_pixel(px,py)
        if c.a<.5:continue
        var ismat = (c.r>c.g*1.2 and c.g>c.b*1.18 and c.r>0.1) if arq=="ligera" else (abs(c.r-c.g)<.08 and abs(c.g-c.b)<.12 and c.v>.12)
        if ismat:values.append(c.v)
      if values.size()<5: continue
      var avg=0.0
      for v in values:avg+=v
      avg/=values.size()
      var idx=0
      if arq=="ligera":idx=0 if avg<.25 else (1 if avg<.43 else (2 if avg<.56 else 3))
      else:idx=0 if avg<.30 else (1 if avg<.57 else (2 if avg<.76 else 3))
      out.set_pixel(target.position.x+tx,d*32+target.position.y+ty,ROLES[idx])
    masks.append({"direccion":d,"extraccion":str(box),"destino":str(target),"pivot_pies":[16,32]})
   out.save_png(OUT+arq+"_"+slot+"_quieto.png")
   data[arq+"_"+slot]=masks
 var f=FileAccess.open(OUT+"extraccion.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(data,"\t"))
 var prev=Image.create(256,256,false,Image.FORMAT_RGBA8)
 for ai in range(2):
  var a=["ligera","pesada"][ai]
  var helm=Image.load_from_file(OUT+a+"_casco_quieto.png")
  var torso=Image.load_from_file(OUT+a+"_torso_quieto.png")
  var base=Image.load_from_file("/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Biblioteca_Arte_01/personaje/caminata.png")
  for d in range(4):
   var cell=base.get_region(Rect2i(0,d*32,32,32))
   cell.blend_rect(torso,Rect2i(0,d*32,32,32),Vector2i.ZERO)
   cell.blend_rect(helm,Rect2i(0,d*32,32,32),Vector2i.ZERO)
   cell.resize(64,64,Image.INTERPOLATE_NEAREST)
   prev.blit_rect(cell,Rect2i(0,0,64,64),Vector2i(d*64,ai*128))
 prev.save_png(OUT+"encaje_indice.png")
 quit()
