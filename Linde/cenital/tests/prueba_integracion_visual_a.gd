extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const P = preload("res://scripts/presentacion_npc.gd")
const Esc = preload("res://scripts/escena.gd")
var total := 0
var fallos := 0
func ok(c: bool, texto: String):
 total += 1
 if not c: fallos += 1
 print(("PASS " if c else "FAIL ") + texto)
func _initialize(): call_deferred("run")
func objetivo(j, tipo: String) -> Vector2i:
 for oid in j.mundo.objetos:
  var o: Dictionary = j.mundo.objetos[oid]
  if o.t == tipo and j.mundo.objeto_presente(o.c) == oid: return o.c
 for y in range(-128,129):
  for x in range(-128,129):
   var c := Vector2i(x,y)
   if not M.es_valle(c) and j.mundo.generador.datos(c).objeto == tipo:
    j.pies = M.pies_de_celda(c+Vector2i.DOWN); j.actualizar_regiones(); return c
 return Vector2i(999999,999999)
func run():
 var ui = preload("res://scripts/ui_arte.gd").new()
 for par in [["hacha_cobre","reutilizados/hacha_piedra.png"],["pico_cobre","reutilizados/pico_piedra.png"]]:
  ok(ui.ruta_icono(par[0]) == par[1] and ResourceLoader.exists("res://arte/interfaz/"+par[1]), "A1 icono reutilizado: "+par[0])
  ok(preload("res://scripts/equipo.gd").info(par[0]).n.to_lower().contains("cobre"), "A1 nombre real: "+par[0])
 var sin_icono: Array = []
 for k in preload("res://scripts/catalogos.gd").ITEMS:
  if ui.ruta_icono(k)=="": sin_icono.append(k)
 sin_icono.sort()
 ok(sin_icono == ["arcilla","candado","cobre","estano","ladrillo","lingote_bronce","lingote_cobre"], "A1 exactamente siete iconos pendientes, sin ocultar carencias")
 var f := FileAccess.open("res://arte/interfaz/ICONOS_POR_ID.json",FileAccess.READ)
 var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(f.get_buffer(f.get_length()))
 var mf = JSON.parse_string(FileAccess.get_file_as_string("res://arte/interfaz/manifiesto.json"))
 ok(hash.finish().hex_encode() == mf.archivos["ICONOS_POR_ID.json"], "A1 hash vigente del mapa en manifiesto")
 var e = Esc.new(); e.j = J.nueva(123,"Prueba visual",[0,1,0]); e.j.combate.enemigos.clear()
 for tipo in ["arbol","roca","veta","veta_cobre","veta_estano","arcilla"]:
  var c := objetivo(e.j,tipo)
  e.j.pies = M.pies_de_celda(c+Vector2i.DOWN); e.j.actualizar_regiones(); e.j.combate.enemigos.clear(); e.j.mira = Vector2i.UP
  e.j.jug().inv = {"hacha_piedra":1,"pico_piedra":1};e.j.rt[J.LOCAL].cd_obj=0.0;e.j.herr_t=0.0
  var control = J.nueva(123,"Prueba visual",[0,1,0]);control.d=e.j.d.duplicate(true);control._arrancar();control.pies=e.j.pies;control.mira=e.j.mira;control.combate.enemigos.clear()
  var r: Dictionary = e._accion_local_visual();e._anim=e.j.anim_pj(false,0.0)
  var rc: Dictionary = control.accion()
  ok(r.ok and e._herramienta_local()==("hacha" if tipo=="arbol" else "pico"), "A2 herramienta aceptada: "+tipo)
  ok(r==rc and e.j.d==control.d, "A2 misma extracción y estado persistente que acción original: "+tipo)
  e.j.mira=Vector2i.DOWN
  ok(e._herramienta_local()==("hacha" if tipo=="arbol" else "pico"), "A2 orientación posterior no cambia la herramienta del golpe: "+tipo)
  e.j.herr_t=0.0
  ok(e._herramienta_local()=="", "A2 herramienta termina con la animación: "+tipo)
 var c := objetivo(e.j,"veta_estano");e.j.pies=M.pies_de_celda(c+Vector2i.DOWN);e.j.actualizar_regiones();e.j.combate.enemigos.clear();e.j.mira=Vector2i.UP
 e.j.jug().inv={};e.j.rt[J.LOCAL].cd_obj=0.0;e.j.herr_t=0.0
 var rechazado: Dictionary=e._accion_local_visual();e._anim=e.j.anim_pj(false,0.0)
 ok(not rechazado.ok and e._herramienta_local()=="", "A2 sin pico: rechazo sin herramienta visual")
 # El objetivo en la celda propia también es una vía válida de Juego.accion.
 e.j.pies=M.pies_de_celda(c);e.j.mira=Vector2i.DOWN;e.j.jug().inv={"pico_piedra":1};e.j.rt[J.LOCAL].cd_obj=0.0;e.j.herr_t=0.0
 var propio: Dictionary=e._accion_local_visual();e._anim=e.j.anim_pj(false,0.0)
 ok(propio.ok and e._herramienta_local()=="pico", "A2 extracción bajo los pies usa el objetivo real")
 # El golpe final conserva su herramienta aunque el objeto ya esté agotado.
 var id_estano: String=e.j.mundo.objeto_presente(c)
 while e.j.mundo.objeto_presente(c)!="":
  e.j.rt[J.LOCAL].cd_obj=0.0;e.j.herr_t=0.0
  e._accion_local_visual()
 e._anim=e.j.anim_pj(false,0.0)
 ok(e._herramienta_local()=="pico" and e.j.mundo.estado.rotos.has(id_estano), "A2 último golpe mantiene pico sobre recurso agotado")
 # Inventario lleno: el intento no debe representar una extracción aceptada.
 c=objetivo(e.j,"veta_estano");e.j.pies=M.pies_de_celda(c+Vector2i.DOWN);e.j.actualizar_regiones();e.j.combate.enemigos.clear();e.j.mira=Vector2i.UP
 e.j.jug().inv={"pico_piedra":1}
 for k in preload("res://scripts/catalogos.gd").ITEMS:
  if k!="estano":e.j.jug().inv[k]=1
 var oid: String=e.j.mundo.objeto_presente(c)
 e.j.mundo.estado.golpes[oid]=99;e.j.rt[J.LOCAL].cd_obj=0.0;e.j.herr_t=0.0
 var lleno: Dictionary=e._accion_local_visual();e._anim=e.j.anim_pj(false,0.0)
 ok(not lleno.ok and e._herramienta_local()=="", "A2 inventario lleno: rechazo sin pico visual")
 var antes: Dictionary=e.j.d.duplicate(true)
 for dir in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT]:
  for act in ["dormir","sin_cama"]:
   var v: Dictionary=P.resolver(act,{"dir":dir,"mueve":true},0.24)
   ok(v.estado=="dormir" and v.dir==dir and v.cuadro==0, "A3 sueño efectivo conserva orientación: "+act+str(dir))
  ok(P.resolver("descansar",{"dir":dir,"mueve":true},0.24).estado=="reposo", "A3 descanso sin sueño: "+str(dir))
  ok(P.resolver("camina",{"dir":dir,"mueve":true},0.24).estado=="caminar", "A3 desplazamiento: "+str(dir))
  ok(P.resolver("recolectar",{"dir":dir,"mueve":false},0.24).estado=="reposo", "A3 no inventa trabajo A4: "+str(dir))
 ok(e.j.d==antes,"A3 presentación no modifica estado persistente")
 # Estados de sueño obtenidos mediante la simulación, no asignados por el dibujante.
 var j=J.nueva(123,"Sueño",[0,1,0]);j.d.min=23*60;j.d.npcs.maren.energia=1.0
 var cama: Vector2i=j.habitantes.cama("maren");j.d.npcs.maren.pos=[M.pies_de_celda(cama+Vector2i.DOWN).x,M.pies_de_celda(cama+Vector2i.DOWN).y]
 j.habitantes.paso(0.1)
 ok(j.d.npcs.maren.act=="dormir" and P.resolver(j.d.npcs.maren.act,{"dir":Vector2i.DOWN,"mueve":false},0).estado=="dormir", "A3 sueño efectivo desde Habitantes")
 j.mundo.estado.constr.erase(M.clave(cama));j.habitantes.paso(0.1)
 ok(j.d.npcs.maren.act=="sin_cama" and P.resolver(j.d.npcs.maren.act,{"dir":Vector2i.DOWN,"mueve":false},0).estado=="dormir", "A3 sin cama efectivo desde Habitantes")
 # El decodificador real de instantáneas ya transporta los estados necesarios para A3.
 var cli=preload("res://scripts/red_cliente.gd").new();cli.j=J.nueva(123,"Replica QA",[0,1,0])
 for act in ["dormir","sin_cama","descansar"]:
  cli.instantanea([1380,{},[],{"maren":[488.0,316.0,act]}])
  ok(cli.j.d.npcs.maren.act==act and P.resolver(cli.j.d.npcs.maren.act,{"dir":Vector2i.DOWN,"mueve":false},0).estado==("reposo" if act=="descansar" else "dormir"), "A3 decodificación de réplica: "+act)
 cli.j=null;cli.free()
 e.cam.free();e.hud.free();e.j=null;e.free()
 print("VISUAL_A1_A3: %d comprobaciones, %d fallos" % [total,fallos]);quit(1 if fallos else 0)
