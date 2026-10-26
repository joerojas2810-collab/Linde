extends SceneTree
## Evidencia reproducible A1-A3 sobre main.tscn. Fixtures QA idénticos antes/después.
## No escribe partidas habituales. --salida=<directorio> obligatorio.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var out: String
var registros: Array=[]
var ultima_maren := Vector2.ZERO
func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
 if out=="":push_error("Falta --salida=<directorio aislado>");quit(1);return
 out=ProjectSettings.globalize_path(out).trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(out);call_deferred("run")
func foto(n: String):
 # Inicializa las lecturas diferidas heredadas antes de medir estabilidad del render.
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 var antes=JSON.stringify(esc.j.d)
 # Reproduce el desplazamiento efectivo del paso QA durante el fotograma congelado.
 if esc.j.d.npcs.maren.act=="camina":esc.actores.pos_npc["maren"]=ultima_maren
 esc.queue_redraw();esc.hud.queue_redraw()
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+n+".png")
 assert(antes==JSON.stringify(esc.j.d),"El render no debe mutar la simulación")
 ultima_maren=esc.j.habitantes.pos("maren")
 registros.append({"foto":n,"npc":esc.j.d.npcs.maren.duplicate(true),"anim_pj":esc._anim.duplicate(),"herramienta":esc._herramienta_local()})
func nueva():
 esc.j=J.nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.j.combate.enemigos.clear();esc.modo="juego";esc._cerrar()
func camara(p: Vector2):
 esc.cam.position=p-Vector2(0,12);esc.cam.reset_smoothing()
func accion():
 if esc.has_method("_accion_local_visual"):return esc._accion_local_visual()
 return esc.j.accion()
func run():
 root.size=Vector2i(1280,720);esc=load("res://main.tscn").instantiate();esc.ruta=out+"partida-aislada.json";root.add_child(esc);esc.set_process(false);nueva()
 esc.j.pies=M.pies_de_celda(Vector2i(28,24));camara(esc.j.pies)
 esc.j.jug().inv={"hacha_cobre":1,"pico_cobre":1,"cobre":5,"lingote_cobre":3,"baya":6}
 esc._abrir("inv");var ks=esc.j.jug().inv.keys();ks.sort();esc.sel=11+ks.find("hacha_cobre");await foto("A1_hacha_cobre");esc.sel=11+ks.find("pico_cobre");await foto("A1_pico_cobre");esc._cerrar()
 # Posición de estaño real del generador para semilla123; despeje QA solo de vecinos para ver el agarre.
 var c:=Vector2i(-56,-128);esc.j.pies=M.pies_de_celda(c+Vector2i.LEFT);esc.j.actualizar_regiones();esc.j.combate.enemigos.clear();esc.j.mira=Vector2i.RIGHT;camara(esc.j.pies)
 for oid in esc.j.mundo.objetos:
  var o: Dictionary=esc.j.mundo.objetos[oid]
  if o.c!=c and Vector2(o.c).distance_to(Vector2(c))<3.0:esc.j.mundo.romper(oid,esc.j.d.min)
 esc.j.jug().inv={"pico_cobre":1};var r: Dictionary=accion();assert(r.ok)
 for frame in 4:
  if frame>0:esc.j.tick(0.075)
  esc._anim=esc.j.anim_pj(false,0.0);await foto("A2_estano_%02d"%frame)
 # Segundo encuadre: actor delante de la mena para revisar el pico sin la oclusión lateral del objeto.
 esc.j.pies=M.pies_de_celda(c+Vector2i.DOWN);esc.j.mira=Vector2i.UP;camara(esc.j.pies)
 esc.j.rt[J.LOCAL].cd_obj=0.0;esc.j.herr_t=0.0;r=accion();assert(r.ok)
 for frame in 3:
  if frame>0:esc.j.tick(0.11)
  esc._anim=esc.j.anim_pj(false,0.0);await foto("A2_frontal_%02d"%frame)
 esc.j.rt[J.LOCAL].cd_obj=0.0;esc.j.herr_t=0.0;esc.j.jug().inv={};r=accion();assert(not r.ok);esc._anim=esc.j.anim_pj(false,0.0);await foto("A2_sin_pico_rechazado")
 nueva();esc.j.d.min=23*60;esc.j.d.npcs.maren.energia=1.0
 var cama: Vector2i=esc.j.habitantes.cama("maren")
 var inicio:=M.pies_de_celda(cama+Vector2i(0,3));esc.j.d.npcs.maren.pos=[inicio.x,inicio.y];ultima_maren=inicio
 esc.j.pies=M.pies_de_celda(cama+Vector2i(-1,1));camara(M.pies_de_celda(cama+Vector2i(0,1)))
 for frame in 6:
  for i in 5:esc.j.habitantes.paso(0.1)
  await foto("A3_hacia_cama_%02d"%frame)
 # Conserva la orientación del último paso (preparación de las cuatro vistas, no cambio de simulación).
 for k in 4:
  var dir: Vector2i=[Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT][k]
  var p: Vector2=esc.j.habitantes.pos("maren");esc.actores.pos_npc["maren#dir"]=dir;esc.actores.pos_npc["maren"]=p
  await foto("A3_dormir_dir_%d"%k)
 if esc.material is ShaderMaterial:esc.material.set_shader_parameter("noche",1.0)
 await foto("A3_dormir_noche")
 if esc.material is ShaderMaterial:esc.material.set_shader_parameter("noche",0.0)
 esc.j.mundo.quitar(cama);esc.j.habitantes.paso(0.1);assert(esc.j.d.npcs.maren.act=="sin_cama")
 await foto("A3_sin_cama")
 # Franja QA de descanso: capacidad existente de Habitantes, sin cambiar reglas del juego.
 esc.j.habitantes.fichas.maren.franjas=[{"desde":0,"hasta":1440,"act":"descansar","lugar":""}]
 esc.j.d.min=12*60;esc.j.d.npcs.maren.energia=100.0;esc.j.habitantes.paso(0.1)
 assert(esc.j.d.npcs.maren.act=="descansar")
 await foto("A3_descansar")
 # Oclusión: sueño al raso bajo copa existente; el cuerpo mantiene su posición lógica.
 for oid in esc.j.mundo.objetos:
  var o: Dictionary=esc.j.mundo.objetos[oid]
  if o.t!="arbol" or not M.es_valle(o.c) or o.c.y<5:continue
  var p:=M.pies_de_celda(o.c)+Vector2(0,-12);esc.j.d.npcs.maren.pos=[p.x,p.y];esc.j.d.min=23*60;esc.j.d.npcs.maren.energia=1.0;esc.j.habitantes.paso(0.1)
  esc.j.pies=p+Vector2(24,12);camara(p);await foto("A3_occlusion_arbol");break
 assert(esc.arte_mundo.faltantes.is_empty() and esc.hud.ui.faltantes.is_empty())
 FileAccess.open(out+"estados.json",FileAccess.WRITE).store_string(JSON.stringify(registros,"  "))
 print("CAPTURA_VISUAL_A: %d capturas; estado persistente inalterado por render"%registros.size())
 esc.modo="creador";esc.j=null;esc.queue_free();await process_frame;quit()
