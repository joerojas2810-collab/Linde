extends SceneTree
func _initialize():
 var source=Image.load_from_file("/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Arte_Prueba_02/original_limpieza_generada.png")
 if source==null:
  push_error("Fuente no encontrada"); quit(1); return
 var sheet=Image.create(128,128,false,Image.FORMAT_RGBA8)
 var strip=Image.create(128,32,false,Image.FORMAT_RGBA8)
 var cells=[]
 for i in range(4):
  var x0=int(source.get_width()*i/4.0)
  var x1=int(source.get_width()*(i+1)/4.0)
  var part=source.get_region(Rect2i(x0,0,x1-x0,source.get_height()))
  for y in part.get_height():
   for x in part.get_width():
    var c=part.get_pixel(x,y)
    part.set_pixel(x,y,Color(c.r,c.g,c.b,1.0) if c.a>=0.5 else Color(0,0,0,0))
  var box=part.get_used_rect()
  var body=part.get_region(box)
  var nw=maxi(1,roundi(body.get_width()*27.0/body.get_height()))
  body.resize(nw,27,Image.INTERPOLATE_NEAREST)
  var cell=Image.create(32,32,false,Image.FORMAT_RGBA8)
  cell.blit_rect(body,Rect2i(0,0,nw,27),Vector2i((32-nw)/2,5))
  cells.append(cell)
 # Common palette from all native samples, deterministic k-means, 32 provisional colours.
 var samples=[]
 for cell in cells:
  for y in 32:
   for x in 32:
    var c=cell.get_pixel(x,y)
    if c.a>0.5: samples.append(Vector3(c.r,c.g,c.b))
 var palette=[]
 for k in 32: palette.append(samples[int(k*samples.size()/32.0)])
 for iteration in 12:
  var sums=[];var counts=[]
  for k in 32: sums.append(Vector3.ZERO);counts.append(0)
  for v in samples:
   var best=0;var distance=INF
   for k in 32:
    var q=v.distance_squared_to(palette[k])
    if q<distance: distance=q;best=k
   sums[best]+=v;counts[best]+=1
  for k in 32:
   if counts[k]>0: palette[k]=sums[k]/counts[k]
 for i in 4:
  var cell=cells[i]
  for y in 32:
   for x in 32:
    var c=cell.get_pixel(x,y)
    if c.a<0.5: continue
    var v=Vector3(c.r,c.g,c.b);var best=0;var distance=INF
    for k in 32:
     var q=v.distance_squared_to(palette[k])
     if q<distance:distance=q;best=k
    var col=palette[best]
    cell.set_pixel(x,y,Color(col.x,col.y,col.z,1.0))
  strip.blit_rect(cell,Rect2i(0,0,32,32),Vector2i(i*32,0))
  for frame in 4:sheet.blit_rect(cell,Rect2i(0,0,32,32),Vector2i(frame*32,i*32))
 DirAccess.make_dir_recursive_absolute("res://arte")
 sheet.save_png("res://arte/personaje_cuerpo.png")
 strip.save_png("/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Arte_Prueba_02/personaje_quieto_128x32.png")
 var f=FileAccess.open("res://arte/personaje.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"celda":32,"capas":["cuerpo"]},"  "));f.close()
 print("ATLAS_OK 128x128; cuatro vistas; cuadros repetidos, sin animacion")
 quit()
