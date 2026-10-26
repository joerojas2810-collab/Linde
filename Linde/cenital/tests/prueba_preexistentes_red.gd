extends "res://tests/prueba_lugares_red.gd"
## Dos clientes reales: identidad regional, diálogo, información privada y recursos compartidos.
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()>0 and args[0]=="bot":
  carpeta=args[3]
  bot(args[1],int(args[2]))
 else:
  carpeta="/tmp/linde-preexistentes-red-"+str(OS.get_process_id())
  servidor()
func bot(nombre: String, puerto: int) -> void:
 var c=Cli.new()
 c.name="Red";c.nombre="Visitante"+nombre;c.clave="preexistentes-"+nombre;c.puerto=puerto
 var dialogo := {"ok":false}
 c.interaccion.connect(func(r):dialogo.ok=r.get("tipo","")=="regional" and str(r.get("npc","")).begins_with("regional:"))
 root.add_child(c)
 var resultado := {}
 resultado.conecto=await esperar(func():return c.j!=null)
 if resultado.conecto:
  var a=c.j.autonomia.asentamientos
  var pid: String=a.datos().preexistentes.ids[0]
  var p: Dictionary=c.j.mundo.poblado(pid)
  var puesto: Dictionary=a.datos().puestos[p.puesto]
  var nid: String=puesto.residentes[0].id
  var cid: String=puesto.cofre
  resultado.identidad=puesto.residentes.size()==2 and not c.j.habitantes.ids.has(nid) and a.residente(nid).hogar==pid
  bandera(nombre+".listo")
  resultado.situado=await esperar(func():return FileAccess.file_exists(carpeta+"/situados") and c.j.pies.distance_to(a.posicion(nid))<J.ALCANCE_NPC)
  c.j.mira=Vector2i.DOWN
  c.j.interactuar()
  resultado.dialogo=await esperar(func():return dialogo.ok)
  if nombre=="A":
   c.j.preguntar_lugares(nid)
   resultado.rumor=await esperar(func():return c.j.jug().mapa.bloques.get("800,800","")=="npc:"+nid)
   c.j.mover_cofre(cid,"madera",true)
   resultado.deposito=await esperar(func():return int(c.j.d.cofres[cid].inv.get("madera",0))==3)
   resultado.sin_duplicar=int(c.j.jug().inv.get("madera",0))==0
   bandera("deposito")
  else:
   resultado.vio_deposito=await esperar(func():return FileAccess.file_exists(carpeta+"/deposito") and int(c.j.d.cofres[cid].inv.get("madera",0))==3)
   resultado.privado=not c.j.jug().mapa.bloques.has("800,800")
   c.j.mover_cofre(cid,"madera",false)
   resultado.retiro=await esperar(func():return int(c.j.jug().inv.get("madera",0))==3)
   bandera("retiro")
  resultado.estado=await esperar(func():return c.j.mundo.poblado(pid).estado=="sin_sustento")
  resultado.residentes=a.residente(nid).id==nid and a.datos().puestos[p.puesto].residentes.size()==2
  resultado.cofre=await esperar(func():return int(c.j.d.cofres[cid].inv.get("madera",0))==0)
 FileAccess.open(carpeta+"/"+nombre+".json",FileAccess.WRITE).store_string(JSON.stringify(resultado))
 c.cerrar();quit()
func servidor() -> void:
 DirAccess.make_dir_recursive_absolute(carpeta)
 var j=J.nueva(123,"Anfitrión",[0,0,0],"poblado")
 j.combate.enemigos.clear()
 var a=j.autonomia.asentamientos
 var pid: String=a.datos().preexistentes.ids[0]
 var p: Dictionary=j.mundo.poblado(pid)
 var puesto: Dictionary=a.datos().puestos[p.puesto]
 puesto.residentes[0].bloques["800,800"]=true
 var s=S.new()
 s.name="Red";s.j=j;s.local=J.LOCAL;s.puerto=31000+OS.get_process_id()%1000
 root.add_child(s)
 var procesos: Array=[]
 for n in ["A","B"]:
  procesos.append(OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--log-file",carpeta+"/"+n+".log","--script","res://tests/prueba_preexistentes_red.gd","--","bot",n,str(s.puerto),carpeta]))
 ok(await esperar(func():return FileAccess.file_exists(carpeta+"/A.listo") and FileAccess.file_exists(carpeta+"/B.listo")),"dos clientes reciben las comunidades persistidas")
 for id in j.rt:
  if id==J.LOCAL:continue
  j.rt[id].pies=J.Mundo.pies_de_celda(Vector2i(p.centro[0],p.centro[1]-1))
  j.jug(id).inv={"madera":3} if j.jug(id).nombre=="VisitanteA" else {}
 j.actualizar_regiones()
 bandera("situados")
 ok(await esperar(func():return FileAccess.file_exists(carpeta+"/retiro")),"los dos clientes operan sobre el mismo depósito")
 j.mundo.quitar(Vector2i(puesto.camas[0][0],puesto.camas[0][1]))
 a.actualizar()
 await esperar(func():return FileAccess.file_exists(carpeta+"/A.json") and FileAccess.file_exists(carpeta+"/B.json"),240)
 for n in ["A","B"]:
  var r=JSON.parse_string(FileAccess.get_file_as_string(carpeta+"/"+n+".json"))
  ok(r is Dictionary,"cliente "+n+" terminó")
  if r is Dictionary:
   for k in r:ok(bool(r[k]),n+": "+k)
 ok(int(j.d.cofres[puesto.cofre].inv.get("madera",0))==0,"ningún recurso transferido queda duplicado en autoridad")
 j.guardar(carpeta+"/mundo.json")
 var cargado=J.cargar(carpeta+"/mundo.json")
 ok(cargado!=null and S.Huella.hash_de(cargado.d.mundo.poblados)==S.Huella.hash_de(j.d.mundo.poblados) and cargado.autonomia.asentamientos.datos().puestos[p.puesto].residentes==puesto.residentes,"reiniciar conserva identidades, memoria y estado compartido")
 for proceso in procesos:
  if OS.is_process_running(proceso):OS.kill(proceso)
 s.queue_free();await process_frame
 quit(1 if fallos else 0)
