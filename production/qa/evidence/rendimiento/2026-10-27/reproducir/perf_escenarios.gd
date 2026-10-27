extends SceneTree
const R=preload("res://tests/perf_registro.gd")
const M=preload("res://scripts/mundo.gd")
var esc
var escenario="quieto"
var salida="/tmp/linde-perf-results/escenario.json"
var frames:Array=[]
var ultimo:int=0
var contador:=0
var origen:Vector2
var objetivo:=360
var calentamiento:=60
func _initialize()->void:
 for a in OS.get_cmdline_user_args():
  if a.begins_with("escenario="):escenario=a.get_slice("=",1)
  if a.begins_with("salida="):salida=a.get_slice("=",1)
 call_deferred("iniciar")
func iniciar()->void:
 DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
 DisplayServer.window_move_to_foreground()
 esc=load("res://scripts/escena.gd").new()
 root.add_child(esc)
 origen=esc.j.pies
 if escenario=="cargadas":
  # Ruta transitable dentro de las regiones iniciales; ida y vuelta real a pie.
  var c=M.celda_de(origen)
  var camino=esc.j.mundo.camino(c,func(q):return q.distance_to(c)>=8,Rect2i(c-Vector2i(12,12),Vector2i(25,25)))
  esc.set_meta("ruta_med",camino)
  esc.set_meta("indice_med",0)
  esc.set_meta("sentido_med",1)
 print("PERF_CONFIG ",JSON.stringify({"escenario":escenario,"renderer":RenderingServer.get_current_rendering_method(),"pantalla":DisplayServer.get_name(),"resolucion":root.size,"origen":origen,"godot":Engine.get_version_info().string,"cpu":OS.get_processor_name()}))
 RenderingServer.frame_post_draw.connect(fin_cuadro)
 process_frame.connect(antes_cuadro)
 ultimo=Time.get_ticks_usec()
 R.activo=true
func antes_cuadro()->void:
 if esc==null:return
 if escenario=="cargadas":
  var ruta:Array=esc.get_meta("ruta_med")
  if ruta.size()>1:
   var i:int=esc.get_meta("indice_med")
   var meta:Vector2=M.pies_de_celda(ruta[i])
   if esc.j.pies.distance_to(meta)<3:
    i+=int(esc.get_meta("sentido_med"))
    if i>=ruta.size():esc.set_meta("sentido_med",-1);i=ruta.size()-2
    elif i<0:esc.set_meta("sentido_med",1);i=1
    esc.set_meta("indice_med",i)
    meta=M.pies_de_celda(ruta[i])
   var dir:Vector2=(meta-esc.j.pies).normalized()
   esc.j.mover_pj(Vector2i(signi(int(round(dir.x))),signi(int(round(dir.y)))),minf(float(esc.get_process_delta_time()),1.0/30))
 if escenario=="nuevas" and contador>=calentamiento and (contador-calentamiento)%60==0:
  # Desplazamiento controlado de una región: garantiza streaming frío, no simula controles humanos.
  esc.j.pies=origen+Vector2((1+(contador-calentamiento)/60)*256,0)
func fin_cuadro()->void:
 var ahora=Time.get_ticks_usec()
 if contador%120==0:print("PERF_PROGRESS ",contador)
 if contador>=calentamiento:
  var fila=R.cuadro.duplicate()
  fila["frame_us"]=ahora-ultimo
  fila["frame"]=contador-calentamiento
  fila["fps_monitor"]=Engine.get_frames_per_second()
  fila["regiones"]=esc.j.mundo.regiones.size()
  fila["pos"]=[esc.j.pies.x,esc.j.pies.y]
  frames.append(fila)
 R.cuadro.clear()
 ultimo=ahora
 contador+=1
 if contador>=calentamiento+objetivo:
  R.activo=false
  FileAccess.open(salida,FileAccess.WRITE).store_string(JSON.stringify({"escenario":escenario,"frames":frames}))
  RenderingServer.frame_post_draw.disconnect(fin_cuadro)
  process_frame.disconnect(antes_cuadro)
  esc.set_process(false) # quit no emite solicitud de cierre de ventana ni guarda
  quit()
