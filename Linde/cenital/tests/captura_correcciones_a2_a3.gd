extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var out:String
var registros:Array=[]
const DT=0.05
func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
 assert(out!="");DirAccess.make_dir_recursive_absolute(out);call_deferred("run")
func nueva():
 esc.j=J.nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.j.combate.enemigos.clear();esc.modo="juego";esc._cerrar()
func camara(p:Vector2):
 esc.cam.position=p-Vector2(0,12);esc.cam.reset_smoothing()
func frame(clip:String,i:int):
 var antes=JSON.stringify(esc.j.d)
 esc.queue_redraw();esc.hud.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+clip+"/%04d.png"%i)
 assert(antes==JSON.stringify(esc.j.d))
 var p:Vector2=esc.j.habitantes.pos("maren")
 var v:Vector2=esc._pies_visuales_npc("maren") if esc.has_method("_pies_visuales_npc") else p
 registros.append({"clip":clip,"frame":i,"segundo":i*DT,"minuto":esc.j.d.min,"npc":esc.j.d.npcs.maren.duplicate(true),"logica":[p.x,p.y],"visual":[v.x,v.y],"herramienta":esc._herramienta_local(),"animacion":esc._anim.duplicate(true)})
func preparar(clip:String):
 DirAccess.make_dir_recursive_absolute(out+"/"+clip)
 # Primera lectura del mundo carga datos diferidos heredados; queda fuera de la secuencia.
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
func run():
 root.size=Vector2i(1280,720);esc=load("res://main.tscn").instantiate();esc.ruta=out+"/partida-QA.json";root.add_child(esc);esc.set_process(false)
 nueva();var cama:Vector2i=esc.j.habitantes.cama("maren")
 var p:=M.pies_de_celda(cama+Vector2i(0,3));esc.j.d.npcs.maren.pos=[p.x,p.y];esc.j.d.min=357;esc.j.d.npcs.maren.energia=100.0
 esc.j.pies=M.pies_de_celda(cama+Vector2i(-2,2));camara(M.pies_de_celda(cama+Vector2i(0,1)))
 await preparar("cama_ciclo")
 for i in 140:
  esc.j.tick(DT);await frame("cama_ciclo",i)
 nueva();cama=esc.j.habitantes.cama("maren");esc.j.mundo.quitar(cama);esc.j.d.min=1380;esc.j.d.npcs.maren.energia=1.0
 p=M.pies_de_celda(cama+Vector2i.DOWN);esc.j.d.npcs.maren.pos=[p.x,p.y];esc.j.pies=p+Vector2(-32,0);camara(p)
 await preparar("sueno_raso")
 for i in 40:
  esc.j.tick(DT);assert(esc.j.d.npcs.maren.act=="sin_cama");await frame("sueno_raso",i)
 for k in 5:
  nueva();var c:=Vector2i(62,-128) if k<4 else Vector2i(-56,-128);var dir:Vector2i=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][k%4] if k<4 else Vector2i.UP
  esc.j.pies=M.pies_de_celda(c-dir);esc.j.mira=dir;esc.j.actualizar_regiones();esc.j.combate.enemigos.clear();esc.j.jug().inv={"pico_cobre":1};assert(not esc.j.mundo.bloquea(c-dir));camara(M.pies_de_celda(c))
  var oid:String=esc.j.mundo.objeto_presente(c);assert(esc.j.mundo.objetos[oid].t=="veta_estano")
  var clip:="estano_"+str(k) if k<4 else "estano_vegetacion";await preparar(clip)
  for i in 60:
   esc.j.tick(DT)
   if esc.j.mundo.objeto_presente(c)!="" and esc.j.rt[J.LOCAL].cd_obj<=0.0:
    var r:Dictionary=esc._accion_local_visual();assert(r.ok)
   await frame(clip,i)
  assert(esc.j.mundo.estado.rotos.has(oid))
 # Oclusiones reales: casa, otros personajes y cubierta. Solo cambia la colocación QA del observador.
 nueva();cama=esc.j.habitantes.cama("maren");p=M.pies_de_celda(cama+Vector2i.DOWN);esc.j.d.npcs.maren.pos=[p.x,p.y];esc.j.d.min=1380;esc.j.d.npcs.maren.energia=1.0
 esc.j.pies=p+Vector2(0,8);camara(p);await preparar("superposicion")
 for i in 40:
  esc.j.tick(DT);await frame("superposicion",i)
 esc.j.pies=M.pies_de_celda(M.CASA.end+Vector2i(0,2));await preparar("tejado_exterior")
 for i in 20:
  esc.j.tick(DT);await frame("tejado_exterior",i)
 FileAccess.open(out+"/estados.json",FileAccess.WRITE).store_string(JSON.stringify(registros,"  "))
 print("SECUENCIAS_CONTINUAS: ",registros.size()," fotogramas reales a 20 fps; 9 clips")
 esc.modo="creador";esc.j=null;esc.queue_free();await process_frame;quit()
