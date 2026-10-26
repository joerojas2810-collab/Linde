extends "res://tests/prueba_lugares_red.gd"
const P = preload("res://tests/prueba_vivienda.gd")
const E = preload("res://scripts/edificios.gd")
func _initialize()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="bot":carpeta=args[3];bot(args[1],int(args[2]))
 else:carpeta="/tmp/linde-vivienda-red-"+str(OS.get_process_id());servidor()
func bot(nombre: String,puerto: int)->void:
 var cli=Cli.new()
 cli.name="Red";cli.nombre="Vivienda"+nombre;cli.clave="vivienda-"+nombre;cli.puerto=puerto
 var panel:={"cofre":false}
 cli.interaccion.connect(func(r):panel.cofre=r.get("panel","")=="cofre")
 root.add_child(cli)
 var r:={}
 r.conecto=await esperar(func():return cli.j!=null)
 if r.conecto:
  bandera(nombre+".listo")
  r.preparado=await esperar(func():return FileAccess.file_exists(carpeta+"/preparado"))
  var datos=JSON.parse_string(FileAccess.get_file_as_string(carpeta+"/solar.json"))
  var c:=Vector2i(datos[0],datos[1])
  var eid:="edificio@"+J.Mundo.clave(c)
  if nombre=="A":
   r.recursos=await esperar(func():return int(cli.j.jug().inv.get("madera",0))==117 and cli.j.pies.distance_to(J.Mundo.pies_de_celda(c+Vector2i.DOWN))<1.0)
   cli.j.construir("vivienda",c)
  r.vivienda=await esperar(func():return cli.j.d.mundo.get("registro",{}).get("edificios",{}).has(eid))
  bandera(nombre+".vivienda")
  var cofre:=c+Vector2i(2,-4)
  var cid:="c@"+J.Mundo.clave(cofre)
  r.situado=await esperar(func():return FileAccess.file_exists(carpeta+"/situados") and cli.j.pies.distance_to(J.Mundo.pies_de_celda(cofre+Vector2i.DOWN if nombre=="A" else c+Vector2i(0,3)))<1.0)
  var e: Dictionary=cli.j.mundo.edificio_en(c)
  r.cubierta_local=E.abierto(e,cli.j.pies)==(nombre=="A")
  r.pisos=cli.j.mundo.piso_en(cofre).edificio==eid
  if nombre=="A":
   cli.j.mira=Vector2i.UP;cli.j.interactuar()
   r.interaccion=await esperar(func():return panel.cofre)
   cli.j.mover_cofre(cid,"madera",true)
   r.deposito=await esperar(func():return int(cli.j.d.cofres[cid].inv.get("madera",0))==3 and int(cli.j.jug().inv.get("madera",0))==0)
   bandera("deposito")
  r.dano=await esperar(func():return FileAccess.file_exists(carpeta+"/dano") and not cli.j.d.mundo.techos.has(J.Mundo.clave(c+Vector2i(0,-3))))
  if nombre=="A":
   r.materiales_reparacion=await esperar(func():return cli.j.jug().inv=={"madera":1,"fibra":1})
   var revision: int=cli.j.mundo.edificio_en(c).revision
   cli.j.reparar_edificio(eid,revision)
   r.reparacion=await esperar(func():return cli.j.d.mundo.techos.has(J.Mundo.clave(c+Vector2i(0,-3))) and cli.j.jug().inv.is_empty())
   cli.j.reparar_edificio(eid,revision)
   r.repeticion=await esperar(func():return cli.j.msgs.any(func(m):return str(m).contains("cambió")))
  else:
   cli.j.reparar_edificio(eid,int(cli.j.mundo.edificio_en(c).revision))
   r.permisos=await esperar(func():return cli.j.msgs.any(func(m):return str(m).contains("no es tuya")))
   r.sin_cobro=cli.j.jug().inv=={"madera":1,"fibra":1}
   r.vio_reparacion=await esperar(func():return cli.j.d.mundo.techos.has(J.Mundo.clave(c+Vector2i(0,-3))))
  r.cofre=cli.j.d.cofres[cid].inv=={"madera":3}
  r.identidad=cli.j.mundo.edificio_en(c).id==eid and cli.j.d.mundo.registro.edificios.size()==1
 FileAccess.open(carpeta+"/"+nombre+".json",FileAccess.WRITE).store_string(JSON.stringify(r))
 cli.cerrar();quit()
func servidor()->void:
 DirAccess.make_dir_recursive_absolute(carpeta)
 var j=J.nueva(123,"Anfitrión",[0,0,0],"poblado")
 j.combate.enemigos.clear()
 var c:=P.solar_preparado(j)
 FileAccess.open(carpeta+"/solar.json",FileAccess.WRITE).store_string(JSON.stringify([c.x,c.y]))
 var s=S.new();s.name="Red";s.j=j;s.local=J.LOCAL;s.puerto=32000+OS.get_process_id()%1000
 root.add_child(s)
 var procesos:Array=[]
 for n in ["A","B"]:
  procesos.append(OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--log-file",carpeta+"/"+n+".log","--script","res://tests/prueba_vivienda_red.gd","--","bot",n,str(s.puerto),carpeta]))
 ok(await esperar(func():return FileAccess.file_exists(carpeta+"/A.listo") and FileAccess.file_exists(carpeta+"/B.listo")),"dos clientes conectan con el catálogo y la misma huella")
 for id in j.rt:
  if id==J.LOCAL:continue
  var a:bool=j.jug(id).nombre=="ViviendaA"
  j.rt[id].pies=J.Mundo.pies_de_celda(c+Vector2i.DOWN if a else c+Vector2i(0,3))
  j.jug(id).inv={"madera":117,"fibra":45} if a else {"madera":1,"fibra":1}
 bandera("preparado")
 ok(await esperar(func():return FileAccess.file_exists(carpeta+"/A.vivienda") and FileAccess.file_exists(carpeta+"/B.vivienda")),"construcción remota llega a ambas réplicas")
 for id in j.rt:
  if id!=J.LOCAL and j.jug(id).nombre=="ViviendaA":j.rt[id].pies=J.Mundo.pies_de_celda(c+Vector2i(2,-3))
 j.actualizar_regiones();bandera("situados")
 ok(await esperar(func():return FileAccess.file_exists(carpeta+"/deposito")),"el propietario usa el cofre real desde dentro")
 j.mundo.destechar(c+Vector2i(0,-3))
 for id in j.rt:
  if id!=J.LOCAL and j.jug(id).nombre=="ViviendaA":j.jug(id).inv={"madera":1,"fibra":1}
 bandera("dano")
 await esperar(func():return FileAccess.file_exists(carpeta+"/A.json") and FileAccess.file_exists(carpeta+"/B.json"),240)
 for n in ["A","B"]:
  var r=JSON.parse_string(FileAccess.get_file_as_string(carpeta+"/"+n+".json"))
  ok(r is Dictionary,"cliente "+n+" terminó")
  if r is Dictionary:
   for k in r:ok(bool(r[k]),n+": "+k)
 j.guardar(carpeta+"/mundo.json")
 var carga=J.cargar(carpeta+"/mundo.json")
 ok(carga!=null and S.Huella.hash_de(carga.d.mundo.registro.edificios)==S.Huella.hash_de(j.d.mundo.registro.edificios) and carga.d.cofres==j.d.cofres,"reinicio conserva una sola instancia y sus inventarios reales")
 for pid in procesos:
  if OS.is_process_running(pid):OS.kill(pid)
 s.queue_free();await process_frame
 quit(1 if fallos else 0)
