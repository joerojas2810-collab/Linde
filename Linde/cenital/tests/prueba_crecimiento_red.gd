extends SceneTree
## Integración real: servidor y dos clientes en procesos separados, cruzando el borde y compartiendo un cofre protegido.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Srv=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
var carpeta:=""
var puerto:=0
var cli
var error_conexion:=""
func escribir(nombre: String,datos) -> void:
 var f:=FileAccess.open(carpeta+"/"+nombre+".json",FileAccess.WRITE)
 f.store_string(JSON.stringify(datos,"  "));f.close()
func leer(nombre: String) -> Dictionary:
 var ruta:=carpeta+"/"+nombre+".json"
 if not FileAccess.file_exists(ruta):return {}
 var d=JSON.parse_string(FileAccess.get_file_as_string(ruta))
 return d if d is Dictionary else {}
func esperar(condicion: Callable,segundos: float=8.0) -> bool:
 var inicio:=Time.get_ticks_msec()
 while not condicion.call() and Time.get_ticks_msec()-inicio<segundos*1000:await create_timer(0.05).timeout
 return bool(condicion.call())
func _initialize() -> void:
 Engine.max_fps=60
 var args:=OS.get_cmdline_user_args()
 if args.is_empty():control();return
 carpeta=args[1];puerto=int(args[2])
 if args[0]=="servidor":servidor()
 else:cliente(args[0])
func servidor() -> void:
 var j=J.nueva(123,"Anfitrión",[0,0,0]);j.combate.enemigos.clear()
 j.pies=M.pies_de_celda(Vector2i(32,55));j.actualizar_regiones()
 var celda:=Vector2i.ZERO
 for y in range(52,71):
  var libre:=true
  for dy in range(-1,2):
   for dx in range(0,3):
    if j.mundo.bloquea(Vector2i(32+dx,y+dy)):libre=false
  if libre:celda=Vector2i(33,y);break
 if celda==Vector2i.ZERO:escribir("servidor",{"error":"No hay parcela"});quit(1);return
 for nombre in ["Ana","Bea"]:
  var id: String=Srv.id_de(nombre)
  j.unir(id,nombre,[0,0,0]);j.rt[id].pies=M.pies_de_celda(Vector2i(32,47))
  j.jug(id).clave={"sal":"qa","hash":Srv.hash_clave("qa","clave-terreno")}
 j.jug(Srv.id_de("Ana")).inv={"madera":5,"candado":1,"fibra":12,"baya":2}
 var srv=Srv.new();srv.name="Red";srv.j=j;srv.puerto=puerto;srv.ruta=carpeta+"/mundo.json"
 root.add_child(srv)
 if srv.error!="":escribir("servidor",{"error":srv.error});quit(1);return
 escribir("servidor",{"celda":[celda.x,celda.y],"error":""})
 var campo:=celda+Vector2i(1,-1)
 if await esperar(func():return j.mundo.constr_en(campo).get("t","")=="campo",25.0):j.d.min+=720
 await esperar(func():return FileAccess.file_exists(carpeta+"/terminar.json"),15.0)
 srv.guardar();quit()
func caminar(hasta: int) -> bool:
 var inicio:=Time.get_ticks_msec()
 while M.celda_de(cli.pos_servidor).y<hasta and Time.get_ticks_msec()-inicio<12000:
  cli.j.mover_pj(Vector2i.DOWN,0.016)
  await process_frame
 cli.j.mover_pj(Vector2i.ZERO,0.0)
 return M.celda_de(cli.pos_servidor).y>=hasta
func ir_a(c: Vector2i) -> bool:
 var inicio:=Time.get_ticks_msec()
 while M.celda_de(cli.pos_servidor)!=c and Time.get_ticks_msec()-inicio<8000:
  var actual:=M.celda_de(cli.pos_servidor)
  var d:=Vector2i(0,signi(c.y-actual.y)) if c.y!=actual.y else Vector2i(signi(c.x-actual.x),0)
  cli.j.mover_pj(d,0.016)
  await process_frame
 cli.j.mover_pj(Vector2i.ZERO,0)
 return M.celda_de(cli.pos_servidor)==c
func cliente(rol: String) -> void:
 cli=Cli.new();cli.name="Red";cli.puerto=puerto;cli.nombre="Ana" if rol=="A" else "Bea";cli.clave="clave-terreno";cli.look=[0,0,0]
 cli.fallo.connect(func(msg):error_conexion=msg)
 root.add_child(cli)
 if not await esperar(func():return cli.j!=null or error_conexion!="") or cli.j==null:
  escribir(rol,{"error":error_conexion if error_conexion!="" else "No conectó"});quit(1);return
 var meta:=leer("servidor")
 var celda:=Vector2i(int(meta.celda[0]),int(meta.celda[1]))
 var cid:="c@"+M.clave(celda)
 var resultado:={"error":"","cruzo":false,"cerrado":false,"permiso":false,"transferencia":false}
 if not await caminar(celda.y):resultado.error="No cruzó el borde";escribir(rol,resultado);quit(1);return
 resultado.cruzo=M.celda_de(cli.pos_servidor).y>=48
 if rol=="A":
  cli.j.construir("cofre",celda)
  if not await esperar(func():return cli.j.d.cofres.has(cid)):resultado.error="No construyó cofre";escribir(rol,resultado);quit(1);return
  cli.j.gestionar_cofre(cid,"instalar")
  if not await esperar(func():return cli.j.d.cofres[cid].get("cerrado",false)):resultado.error="No cerró";escribir(rol,resultado);quit(1);return
  cli.j.construir("campo",celda+Vector2i(1,-1))
  cli.j.construir("techo",celda)
  if not await esperar(func():return cli.j.mundo.constr_en(celda+Vector2i(1,-1)).get("t","")=="campo" and cli.j.d.mundo.techos.has(M.clave(celda))):print("DEBUG campo=",cli.j.mundo.constr_en(celda+Vector2i(1,-1))," techos=",cli.j.d.mundo.techos," inv=",cli.j.jug().inv," msgs=",cli.j.rt[J.LOCAL].msgs," pos=",cli.pos_servidor);resultado.error="No construyó campo y techo";escribir(rol,resultado);quit(1);return
  cli.j.mover_cofre(cid,"fibra",true)
  if not await esperar(func():return int(cli.j.d.cofres[cid].inv.get("fibra",0))==9):resultado.error="No depositó";escribir(rol,resultado);quit(1);return
  escribir("cofre",{"listo":true})
  await esperar(func():return leer("rechazo").get("listo",false))
  cli.j.gestionar_cofre(cid,"permitir",Srv.id_de("Bea"))
  resultado.permiso=await esperar(func():return cli.j.d.cofres[cid].get("permitidos",[]).has(Srv.id_de("Bea")))
  resultado.transferencia=await esperar(func():return leer("recibido").get("listo",false))
  resultado.cerrado=cli.j.d.cofres[cid].cerrado
 else:
  if not await esperar(func():return leer("cofre").get("listo",false)):resultado.error="No vio cofre";escribir(rol,resultado);quit(1);return
  cli.j.mover_cofre(cid,"fibra",false)
  await create_timer(0.5).timeout
  resultado.cerrado=bool(cli.j.d.cofres.get(cid,{}).get("cerrado",false)) and cli.j.jug().inv.get("fibra",0)==0
  escribir("rechazo",{"listo":resultado.cerrado})
  resultado.permiso=await esperar(func():return cli.j.d.cofres.get(cid,{}).get("permitidos",[]).has(Srv.id_de("Bea")))
  cli.j.mover_cofre(cid,"fibra",false)
  resultado.transferencia=await esperar(func():return int(cli.j.jug().inv.get("fibra",0))==9)
  escribir("recibido",{"listo":resultado.transferencia})
 var campo:=celda+Vector2i(1,-1)
 resultado.cultivo=await esperar(func():return cli.j.mundo.constr_en(campo).get("t","")=="campo")
 resultado.techo=await esperar(func():return cli.j.d.mundo.techos.has(M.clave(celda)))
 if rol=="A":
  if await esperar(func():return cli.j.campo_listo(campo)):
   await ir_a(campo)
   cli.j.interactuar()
  resultado.cosecha=await esperar(func():return int(cli.j.jug().inv.get("baya",0))==3)
  escribir("cosecha",{"listo":resultado.cosecha})
 else:resultado.cosecha=await esperar(func():return leer("cosecha").get("listo",false))
 resultado.huella=huella_mundo(cli.j.mundo,celda)
 resultado.regiones=cli.j.mundo.regiones.size()
 escribir(rol,resultado);cli.cerrar();await create_timer(0.2).timeout;quit()
func huella_mundo(mundo,celda: Vector2i) -> String:
 var huella: Array=[]
 for y in range(celda.y-2,celda.y+3):
  for x in range(celda.x-2,celda.x+3):
   var c:=Vector2i(x,y)
   huella.append([mundo.tipo(c),mundo.bioma(c),mundo.objeto_presente(c)])
 return JSON.stringify(huella).sha256_text()
func lanzar(rol: String) -> int:
 return OS.create_process(OS.get_executable_path(),["--headless","--log-file",carpeta+"/"+rol+".log","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/prueba_crecimiento_red.gd","--",rol,carpeta,str(puerto)])
func control() -> void:
 carpeta="/tmp/linde-crecimiento-red-%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(carpeta)
 puerto=18000+OS.get_process_id()%20000
 var servidor_pid:=lanzar("servidor")
 if not await esperar(func():return not leer("servidor").is_empty()):print("FAIL servidor no inició");quit(1);return
 var datos:=leer("servidor")
 if datos.get("error","")!="":print("FAIL ",datos);quit(1);return
 var pa:=lanzar("A");var pb:=lanzar("B")
 var terminaron: bool=await esperar(func():return not OS.is_process_running(pa) and not OS.is_process_running(pb),30.0)
 escribir("terminar",{"listo":true})
 await esperar(func():return not OS.is_process_running(servidor_pid),5.0)
 for pid in [pa,pb,servidor_pid]:
  if OS.is_process_running(pid):OS.kill(pid)
 var a:=leer("A");var b:=leer("B")
 var valido: bool=terminaron and a.get("error","sin resultado")=="" and b.get("error","sin resultado")==""
 for clave in ["cruzo","cerrado","permiso","transferencia","cultivo","techo","cosecha"]:valido=valido and a.get(clave,false) and b.get(clave,false)
 valido=valido and a.get("huella","")!="" and a.get("huella","")==b.get("huella","diferente")
 var guardado=J.cargar(carpeta+"/mundo.json")
 var cid:="c@%d,%d"%[int(datos.celda[0]),int(datos.celda[1])]
 valido=valido and guardado!=null and guardado.d.cofres.get(cid,{}).get("cerrado",false) and int(guardado.jug(Srv.id_de("Bea")).inv.get("fibra",0))==9
 if guardado!=null: valido=valido and a.get("huella","")==huella_mundo(guardado.mundo,Vector2i(int(datos.celda[0]),int(datos.celda[1])))
 var informe:={"ok":valido,"A":a,"B":b,"puerto":puerto,"registros":carpeta}
 var f:=FileAccess.open(ProjectSettings.globalize_path("res://../../production/qa/evidence/crecimiento/red-crecimiento.json"),FileAccess.WRITE)
 f.store_string(JSON.stringify(informe,"  "));f.close()
 print(("PASS " if valido else "FAIL ")+"RED_CRECIMIENTO "+JSON.stringify(informe))
 quit(0 if valido else 1)
