extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const G=preload("res://scripts/guardado.gd")
const T=preload("res://scripts/terreno_v1.gd")
const Srv=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
var total:=0
var fallos:=0
func ok(c: bool, texto: String) -> void:
 total+=1
 print(("PASS " if c else "FAIL ")+texto)
 if not c:fallos+=1
func nuevo(s: int=123):
 var j=J.nueva(s,"Exploradora",[0,0,0])
 j.combate.enemigos.clear()
 j.autonomia.reglas.expediciones=false   # estas pruebas miden el entorno del jugador, sin el contorno del valle
 return j
func viajar(j,c: Vector2i) -> void:
 j.pies=M.pies_de_celda(c)
 j.actualizar_regiones()
func parcela(j) -> Vector2i:
 for y in range(100,140):
  for x in range(110,145):
   var c:=Vector2i(x,y)
   if j.mundo.puede_poner(c)!="":continue
   var libre:=true
   for dy in range(-1,2):
    for dx in range(-1,2):
     if j.mundo.bloquea(c+Vector2i(dx,dy)):libre=false
   if libre:return c
 return Vector2i.ZERO
func _init() -> void:
 var original=M.new()
 var j=nuevo()
 ok(j.mundo.celdas==original.celdas,"el valle de autor conserva exactamente sus celdas")
 var core:=true
 for oid in original.objetos:
  if j.mundo.objetos.get(oid,{})!=original.objetos[oid]:core=false
 ok(core,"se conservan recursos y puntos de interés originales")
 ok(j.d.mundo.generacion.semilla==123 and j.d.mundo.generacion.version==2,"semilla y versión del generador se guardan en el mundo")
 ok(M.celda_de(Vector2(-0.1,12))==Vector2i(-1,0),"coordenadas negativas usan suelo matemático, no truncamiento")
 ok(T.region(Vector2i(-1,-17))==Vector2i(-1,-2),"regiones negativas no se solapan con el origen")
 var uno=T.new(123);var dos=T.new(123);var distinto=T.new(124)
 var a: Dictionary=uno.generar_region(Vector2i(8,-7))
 var b: Dictionary=dos.generar_region(Vector2i(8,-7))
 ok(a==b,"misma semilla y coordenadas producen terreno y recursos idénticos")
 ok(JSON.stringify(a).sha256_text()=="2f3f00a43b5ff545e3db73398e95eb4682aaba6afa3f1d123dc1b94f63d362bd","huella v1 impide cambiar silenciosamente el terreno de partidas existentes")
 ok(a!=distinto.generar_region(Vector2i(8,-7)),"otra semilla produce una región diferente")
 var bordes:=true
 for pos in [Vector2i(-2,-1),Vector2i(8,7)]:
  var datos: Dictionary=uno.generar_region(pos)
  for y in T.TAM:
   for x in [0,T.TAM-1]:
    var c: Vector2i=pos*T.TAM+Vector2i(x,y)
    if int(datos.terreno[y*T.TAM+x])!=int(uno.datos(c).tipo):bordes=false
 ok(bordes,"bordes de regiones consultan las mismas coordenadas globales")
 var biomas:={}
 for y in range(-512,512,16):
  for x in range(-512,512,16):biomas[uno.datos(Vector2i(x,y)).bioma]=true
 ok(biomas.size()>=4,"el exterior contiene varios biomas reales")
 var caminos:=true
 for y in range(-200,200):
  if int(uno.datos(Vector2i(32,y)).tipo)!=M.T.CAMINO:caminos=false
 ok(caminos,"los caminos atraviesan regiones sin cortes ni objetos bloqueantes")
 # Movimiento real al sur del antiguo límite, sin cambiar la posición durante el cruce.
 viajar(j,Vector2i(32,47))
 for i in 120:j.mover_pj(Vector2i.DOWN,0.05)
 ok(M.celda_de(j.pies).y>48,"el jugador cruza andando el borde antiguo del valle")
 ok(j.mundo.caja_libre(j.pies),"colisión sigue siendo válida fuera del valle")
 # Cambios y cofre cerrado en una región exterior.
 viajar(j,Vector2i(128,119))
 var celda_cache := Vector2i(128,119)
 ok(j.mundo.region_cargada(celda_cache) and j.mundo.tipo(celda_cache) == int(j.mundo.generador.datos(celda_cache).tipo), "consulta cacheada conserva el resultado determinista del generador")
 ok(posmod(T.LIMITE,T.TAM)==0, "los límites técnicos coinciden con bordes de región, así validar la esquina cubre todo el chunk")
 var c:=parcela(j)
 ok(c!=Vector2i.ZERO,"encuentra una parcela exterior construible")
 viajar(j,c+Vector2i.LEFT)
 j.jug().inv={"madera":4,"candado":1,"fibra":17}
 ok(j.construir("cofre",c).ok,"construye un cofre fuera del mapa original")
 var cid:="c@"+M.clave(c)
 ok(j.gestionar_cofre(cid,"instalar").ok and j.mover_cofre(cid,"fibra",true).ok,"candado e inventario funcionan en el exterior")
 var tipo: int=j.mundo.tipo(c)
 viajar(j,Vector2i(4096,23))
 ok(not j.mundo.region_cargada(c),"descarga la región lejana")
 ok(j.d.cofres[cid].inv.fibra==17 and j.d.cofres[cid].cerrado,"descargar no borra objetos guardados ni protección")
 ok(j.guardar("/tmp/linde-terreno-prueba-%d.json" % OS.get_process_id()),"guarda estando lejos del valle")
 var carga=J.cargar("/tmp/linde-terreno-prueba-%d.json" % OS.get_process_id())
 carga.autonomia.reglas.expediciones=false
 ok(carga!=null and M.celda_de(carga.pies)==Vector2i(4096,23),"carga restaura posición exterior y genera su entorno")
 viajar(carga,c+Vector2i.LEFT)
 ok(carga.mundo.tipo(c)==tipo and carga.d.cofres[cid].inv.fibra==17 and carga.d.cofres[cid].cerrado,"volver conserva terreno, construcción, contenido y candado")
 ok(not carga.d.mundo.has("regiones") and not carga.d.mundo.has("celdas"),"el guardado no acumula copias del terreno generado")
 # Recolección real y regeneración de un recurso descargado.
 var objetivo:=""
 for oid in carga.mundo.objetos:
  var o: Dictionary=carga.mundo.objetos[oid]
  if o.t=="arbusto" and not M.es_valle(o.c):objetivo=oid;break
 ok(objetivo!="","genera recursos cosechables fuera del valle")
 var recurso: Dictionary=carga.mundo.objetos[objetivo].duplicate(true)
 viajar(carga,recurso.c+Vector2i.LEFT)
 carga.jug().inv={}
 ok(carga.golpear_objeto(recurso.c).ok and carga.jug().inv.get("fibra",0)>0,"recolecta con la acción real y recibe materiales")
 viajar(carga,Vector2i(-4096,23))
 ok(not carga.mundo.objetos.has(objetivo) and carga.d.mundo.rotos.has(objetivo),"descarga datos del recurso pero conserva su extracción")
 viajar(carga,recurso.c+Vector2i.LEFT)
 ok(carga.mundo.objeto_presente(recurso.c)=="","volver no duplica ni repone un recurso extraído")
 viajar(carga,Vector2i(-4096,23))
 carga.mundo.regenerar(int(carga.d.min)+1441,func(_celda):return false)
 ok(not carga.d.mundo.rotos.has(objetivo),"regeneración resuelve recursos descargados sin errores ni carga global")
 viajar(carga,recurso.c+Vector2i.LEFT)
 ok(carga.mundo.objeto_presente(recurso.c)==objetivo,"recurso renovable vuelve con el mismo identificador")
 # Daño parcial también sobrevive a descarga y guardado.
 var arbol:=""
 for oid in carga.mundo.objetos:
  if carga.mundo.objetos[oid].t=="arbol" and not M.es_valle(carga.mundo.objetos[oid].c):arbol=oid;break
 var arbol_c: Vector2i=carga.mundo.objetos[arbol].c
 viajar(carga,arbol_c+Vector2i.LEFT);carga.jug().inv={"hacha_piedra":1}
 carga.golpear_objeto(arbol_c)
 ok(int(carga.d.mundo.golpes.get(arbol,0))==1,"primer golpe exterior queda como daño parcial")
 viajar(carga,Vector2i(-4096,23));carga.guardar("/tmp/linde-terreno-parcial-%d.json" % OS.get_process_id())
 var parcial=J.cargar("/tmp/linde-terreno-parcial-%d.json" % OS.get_process_id())
 parcial.autonomia.reglas.expediciones=false
 viajar(parcial,arbol_c+Vector2i.LEFT)
 ok(int(parcial.d.mundo.golpes.get(arbol,0))==1,"daño parcial persiste descargado y después de cargar partida")
 parcial.golpear_objeto(arbol_c);parcial.golpear_objeto(arbol_c)
 ok(parcial.d.mundo.rotos.has(arbol) and parcial.jug().inv.get("madera",0)==3,"rematar después de cargar entrega el botín una sola vez")
 viajar(parcial,Vector2i(-32,23))
 for i in 60:parcial.mover_pj(Vector2i.LEFT,0.05)
 ok(M.celda_de(parcial.pies).x< -32 and parcial.mundo.caja_libre(parcial.pies),"movimiento y colisión funcionan en coordenadas negativas")
 ok(not parcial.mundo.valida(Vector2i(T.LIMITE,23)) and parcial.mundo.bloquea(Vector2i(T.LIMITE,23)),"límite técnico no genera coordenadas inválidas")
 # Memoria y orden de exploración.
 var acotada:=true
 for i in range(1,30):
  viajar(carga,Vector2i(i*160,23))
  if carga.mundo.regiones.size()>25:acotada=false
 ok(acotada,"treinta desplazamientos no hacen crecer la caché sin límite")
 ok(carga.mundo.objetos.has("tesoro_cantera"),"el valle permanece residente para sus habitantes")
 viajar(carga,Vector2i(128,119))
 var firma: String=JSON.stringify(carga.mundo.regiones[M.clave(T.region(Vector2i(128,119)))])
 viajar(carga,Vector2i(-1600,-1600));viajar(carga,Vector2i(128,119))
 ok(JSON.stringify(carga.mundo.regiones[M.clave(T.region(Vector2i(128,119)))])==firma,"el orden de exploración no altera una región")
 carga.unir("lejos","Viajera",[0,0,0]);carga.rt.lejos.pies=M.pies_de_celda(Vector2i(-4096,23));carga.actualizar_regiones()
 ok(carga.mundo.regiones.size()<=50 and carga.mundo.region_cargada(Vector2i(-4096,23)),"dos jugadores distantes cargan la unión de sus entornos")
 carga.salir("lejos");carga.actualizar_regiones()
 ok(carga.mundo.regiones.size()<=25 and not carga.mundo.region_cargada(Vector2i(-4096,23)),"desconectar libera el entorno del jugador ausente")
 # Guardado anterior y formato de generación futuro.
 var viejo=nuevo();viejo.d.mundo.erase("generacion")
 viejo.jug().inv={"gema":3};viejo.guardar("/tmp/linde-terreno-anterior-%d.json" % OS.get_process_id())
 var migrado=J.cargar("/tmp/linde-terreno-anterior-%d.json" % OS.get_process_id())
 migrado.autonomia.reglas.expediciones=false
 ok(migrado!=null and migrado.jug().inv.gema==3 and migrado.mundo.celdas==original.celdas and migrado.d.mundo.has("generacion"),"partida anterior añade expansión sin reemplazar valle ni inventario")
 var futuro: Dictionary=j.d.duplicate(true);futuro.mundo.generacion.version=99
 ok(G.desempaquetar(G.empaquetar(futuro)).is_empty(),"rechaza generador futuro para no regenerar terreno incompatible")
 # Servidor y réplica: mismo terreno, permisos y alcance exterior.
 viajar(j,c+Vector2i.LEFT)
 j.unir("amiga","Amiga",[0,0,0]);j.rt.amiga.pies=j.pies
 j.gestionar_cofre(cid,"permitir","amiga")
 var srv=Srv.new();srv.j=j
 var cli=Cli.new();cli._bienvenida(srv.estado_para("amiga"))
 ok(cli.j.mundo.tipo(c)==j.mundo.tipo(c) and cli.j.d.mundo.generacion==j.d.mundo.generacion,"réplica reconstruye exterior idéntico con metadatos del servidor")
 ok(cli.j.info_cofre(cid).acceso and not cli.j.info_cofre(cid).propio,"permiso exterior funciona con identidad traducida del cliente")
 ok(srv.ejecutar("amiga",["mover_cofre",1,cid,"fibra",false]) and j.jug("amiga").inv.get("fibra",0)==17,"servidor acepta transferencia legítima en cofre exterior")
 j.jug("amiga").inv={"madera":1}
 ok(srv.ejecutar("amiga",["construir",2,"suelo",c+Vector2i.UP]) and j.mundo.constr_en(c+Vector2i.UP).get("t","")=="suelo","servidor acepta construcción exterior cercana")
 var antes: int=j.mundo.regiones.size()
 ok(not srv.ejecutar("amiga",["construir",3,"suelo",Vector2i(60000,60000)]) and j.mundo.regiones.size()==antes,"pedido remoto lejano no genera regiones ni modifica el mundo")
 cli.free();srv.free()
 # Campamento y reaparición después de descargar la cama.
 viajar(parcial,Vector2i(128,119))
 var cama_c:=parcela(parcial)
 viajar(parcial,cama_c+Vector2i.LEFT);parcial.jug().inv={"madera":4,"fibra":4}
 ok(parcial.construir("cama",cama_c).ok and parcial.dormir(cama_c).ok,"construye y fija una cama real en el exterior")
 var cama_pos: Array=parcial.jug().cama.duplicate()
 viajar(parcial,Vector2i(4096,23));parcial.danar_pj(10000)
 ok(parcial.pies==Vector2(cama_pos[0],cama_pos[1]) and parcial.mundo.region_cargada(cama_c),"reaparecer vuelve a cargar la región de la cama exterior")
 ok(parcial.mundo.caja_libre(parcial.pies),"el jugador reaparece con colisión válida en su campamento")
 parcial.mundo.poner(Vector2i(120,123),"cama_huesped",true,J.LOCAL)
 ok(not parcial.vivo.camas_libres_lista().has("120,123"),"camas exteriores no asignan colonos sin rutas regionales")
 print("TERRENO: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
