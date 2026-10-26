extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const S=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
const Fix=preload("res://tests/fixture_senales.gd")
var carpeta:String
var fallos=0
func _initialize():
 var args=OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="bot":carpeta=args[3];bot(args[1],int(args[2]));return
 carpeta=OS.get_cache_dir()+"/linde-senales-red-%d"%OS.get_process_id();servidor()
func escribir(n:String,d):FileAccess.open(carpeta+"/"+n+".json",FileAccess.WRITE).store_string(JSON.stringify(d))
func existe(n:String)->bool:return FileAccess.file_exists(carpeta+"/"+n+".json")
func ok(v:bool,t:String):
 if not v:fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func bot(nombre:String,puerto:int):
 var c=Cli.new();c.name="Red";c.nombre="Senal"+nombre;c.clave="fixture-senal-"+nombre;c.puerto=puerto;root.add_child(c)
 var result={"conecto":false}
 for i in 120:
  await create_timer(0.05).timeout
  if c.j!=null:break
 if c.j!=null:
  result.conecto=true
  for i in 80:
   await create_timer(0.05).timeout
   if nombre=="B" or not c.j.aviso_ecologico().is_empty():break
  if nombre=="B":await create_timer(0.5).timeout
  var memoria:Dictionary=c.j.jug().get("mapa",{}).get("avistamientos",{})
  result.senal_personal=not c.j.aviso_ecologico().is_empty() if nombre=="A" else c.j.aviso_ecologico().is_empty()
  result.memoria_personal=not memoria.is_empty() if nombre=="A" else memoria.is_empty()
  var texto=JSON.stringify(c.j.jug().get("mapa",{}))
  result.sin_identidades_ocultas=not texto.contains("fuente") and not texto.contains("ancla") and not texto.contains("fauna_v1@")
  result.sin_fuentes_globales=not c.j.d.fauna.has("territorios") and not c.j.d.fauna.has("informes_npc")
  escribir(nombre+"_listo",{})
  for i in 120:
   await create_timer(0.05).timeout
   if existe("retirado") and c.j.aviso_ecologico().is_empty():break
  result.retiro=existe("retirado") and c.j.aviso_ecologico().is_empty()
  result.historia_no_alarma=not c.j.jug().get("mapa",{}).get("avistamientos",{}).is_empty() if nombre=="A" else c.j.jug().get("mapa",{}).get("avistamientos",{}).is_empty()
 escribir(nombre,result);c.cerrar();quit()
func servidor():
 DirAccess.make_dir_recursive_absolute(carpeta)
 var j=J.nueva(123,"Servidor",[0,0,0],M.MODO_POBLADO);var fixture=Fix.preparar(j)
 if fixture.is_empty():ok(false,"no se encontró fuente regional real");quit(1);return
 var s=S.new();s.name="Red";s.j=j;s.local=J.LOCAL;s.ruta=carpeta+"/mundo_test.json";s.puerto=30000+OS.get_process_id()%1000;root.add_child(s);s.set_process(false)
 var pids=[]
 for nombre in ["A","B"]:pids.append(OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--log-file",carpeta+"/"+nombre+".log","--script",get_script().resource_path,"--","bot",nombre,str(s.puerto),carpeta]))
 var retirado=false
 for i in 240:
  for id in j.rt:
   if id==J.LOCAL:continue
   j.rt[id].pies=fixture.observador if j.jug(id).nombre=="SenalA" else M.pies_de_celda(Vector2i(32,23))
  if not retirado and existe("A_listo") and existe("B_listo"):
   j.combate._danar(fixture.enemigo,999);retirado=true;escribir("retirado",{})
  j.actualizar_mapa();s._difundir()
  await create_timer(0.05).timeout
  if existe("A") and existe("B"):break
 for nombre in ["A","B"]:
  ok(existe(nombre),"cliente "+nombre+" finalizó")
  if existe(nombre):
   var result=JSON.parse_string(FileAccess.get_file_as_string(carpeta+"/"+nombre+".json"))
   for k in result:ok(bool(result[k]),nombre+": "+k)
 for pid in pids:
  if OS.is_process_running(pid):OS.kill(pid)
 s.queue_free();await process_frame;quit(1 if fallos else 0)
