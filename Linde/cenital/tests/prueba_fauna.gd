extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const Arte = preload("res://scripts/actores_arte.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var total := 0
var fallos := 0
func ok(condicion: bool, texto: String) -> void:
 total += 1
 if not condicion: fallos += 1
 print(("PASS " if condicion else "FAIL ") + texto)
func viajar(j, c: Vector2i) -> void:
 j.pies = M.pies_de_celda(c)
 j.actualizar_regiones()
 j.combate.fauna.actualizar()
func fauna(j) -> Array:
 return j.combate.enemigos.filter(func(e): return e.has("fauna_id"))
func _init() -> void:
 var j = J.nueva(123, "Viajera", [0,0,0])
 var f = j.combate.fauna
 ok(j.d.fauna.version == 1 and j.d.fauna.bajas.is_empty(), "partida nueva inicializa estado aditivo de fauna")
 ok(C.validar().is_empty(), "catálogo y botines usan objetos válidos")
 var tipos := {}
 var deterministas := true
 var fuera := true
 var otro = J.nueva(123, "Otra", [0,0,0])
 for y in range(-14, 15):
  for x in range(-14, 15):
   var r := Vector2i(x,y)
   var p: Dictionary = f.plan_region(r)
   if p != otro.combate.fauna.plan_region(r): deterministas = false
   if p.is_empty(): continue
   tipos[p.tipo] = true
   if M.Terreno.distancia_valle(p.celda) < 8: fuera = false
   if p.bioma == "ribera":
    var agua := false
    for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
     if int(j.mundo.generador.datos(p.celda+v).tipo)==M.T.AGUA: agua=true
    if not agua: fuera=false
 ok(deterministas, "misma semilla da encuentros idénticos independientemente del orden")
 ok(tipos.size() == 5, "los cinco biomas aportan especies distintas y la ribera usa orilla transitable")
 ok(fuera, "puntos de fauna respetan franja segura del valle y agua de ribera")
 viajar(j, Vector2i(-200,-256))
 var lista := fauna(j)
 ok(not lista.is_empty() and lista.size() <= 24, "explorar genera fauna real y respeta el techo de 24")
 if lista.is_empty(): quit(1); return
 var identidades := {}
 var seguros := true
 for e in lista:
  identidades[e.fauna_id] = true
  if not j.mundo.caja_libre(e.pos, Vector2(e.tam,e.tam*0.6)) or e.pos.distance_to(j.pies) < 96: seguros=false
 ok(identidades.size() == lista.size() and seguros, "no hay duplicados ni apariciones sobre paredes, agua o jugador")
 var e: Dictionary = lista[0]
 var sid: String = e.fauna_id
 var lugar: Vector2 = e.pos
 var tipo: String = e.tipo
 j.combate._danar(e, 1)
 var hp: int = e.hp
 ok(hp == int(C.ENEMIGOS[tipo].hp)-1 and j.d.fauna.heridos.has(sid), "daño confirmado registra herida persistente")
 ok(j.guardar((OS.get_cache_dir()+"/linde-fauna-herida-%d.json" % OS.get_process_id())), "guarda fauna herida con la partida")
 var cargado = J.cargar((OS.get_cache_dir()+"/linde-fauna-herida-%d.json" % OS.get_process_id()))
 cargado.combate.fauna.actualizar()
 var recuperados: Array = fauna(cargado).filter(func(v):return v.fauna_id==sid)
 ok(recuperados.size()==1 and int(recuperados[0].hp)==hp, "cargar restaura al herido sin curarlo ni duplicarlo")
 viajar(j,Vector2i(4096,4096))
 ok(not fauna(j).any(func(v):return v.fauna_id==sid) and j.d.fauna.heridos.has(sid), "descargar una región retira la criatura y conserva su herida")
 viajar(j,Vector2i(-200,-256))
 recuperados=fauna(j).filter(func(v):return v.fauna_id==sid)
 ok(recuperados.size()==1 and int(recuperados[0].hp)==hp, "regresar recupera la misma herida")
 if recuperados.is_empty(): quit(1); return
 e=recuperados[0]
 var xp: int=j.jug().xp
 j.combate._danar(e,999)
 var botin: int=j.jug().xp
 j.combate._danar(e,999)
 ok(botin>xp and int(j.jug().xp)==botin and j.d.fauna.bajas.has(sid), "muerte da recompensa una sola vez y activa enfriamiento")
 j.combate.enemigos=j.combate.enemigos.filter(func(v):return v.est!="muerto")
 j.guardar((OS.get_cache_dir()+"/linde-fauna-baja-%d.json" % OS.get_process_id()))
 var muerto=J.cargar((OS.get_cache_dir()+"/linde-fauna-baja-%d.json" % OS.get_process_id()))
 muerto.combate.fauna.actualizar()
 ok(not fauna(muerto).any(func(v):return v.fauna_id==sid), "guardar y cargar no permite cultivar una baja reciente")
 viajar(j,Vector2i(4096,4096));viajar(j,Vector2i(-200,-256))
 ok(not fauna(j).any(func(v):return v.fauna_id==sid), "descargar y regresar tampoco elimina el enfriamiento")
 j.d.min=int(j.d.fauna.bajas[sid])
 j.combate.fauna.actualizar()
 ok(fauna(j).any(func(v):return v.fauna_id==sid), "la especie reaparece cuando vence su enfriamiento")
 # Conductas con la misma geometría: defensa, huida, hostilidad y retorno.
 var base: Vector2=j.pies
 var g: Dictionary=j.combate._nuevo("golem_sierra",base+Vector2(32,0))
 j.combate._paso_enemigo(g,0.1)
 ok(g.est=="idle", "gólem no inicia combate por mera proximidad")
 j.combate._danar(g,1);j.combate._paso_enemigo(g,0.1)
 ok(g.est=="persigue", "gólem se defiende al recibir un golpe")
 var a: Dictionary=j.combate._nuevo("arpia_pradera",base+Vector2(32,0))
 j.combate._paso_enemigo(a,0.1)
 ok(a.est=="huye", "arpía intenta huir antes de ser atacada")
 var imp: Dictionary=j.combate._nuevo("diablillo_secano",base+Vector2(32,0))
 j.combate._paso_enemigo(imp,0.1);j.combate._paso_enemigo(imp,0.1)
 ok(imp.est=="aviso" or imp.est=="persigue", "diablillo detecta al jugador y prepara ataque con aviso")
 imp.fauna_id="prueba";imp.home=imp.pos-Vector2(180,0)
 j.combate._paso_enemigo(imp,0.1)
 ok(imp.est=="regresa" and imp.obj=="", "persecución regional tiene límite y cancela el ataque")
 # El aviso se resuelve con daño real y conserva la invulnerabilidad entre impactos.
 var atacante: Dictionary=j.combate._nuevo("slime_ribera",j.pies)
 atacante.obj=J.LOCAL;atacante.atq="golpe";atacante.est="aviso";atacante.t=0.01
 var vida: int=j.jug().hp
 j.combate.ataque(J.LOCAL).inv_t=0.0
 j.combate._paso_enemigo(atacante,0.02)
 ok(j.jug().hp<vida and atacante.est=="recupera","ataque avisado inflige daño real y entra en recuperación")
 vida=j.jug().hp
 j.combate._resolver(atacante,j.combate.info_ataque(atacante,"golpe"))
 ok(j.jug().hp==vida,"invulnerabilidad impide daño repetido inmediato")
 var barrera: Vector2i=M.celda_de(j.pies)+Vector2i(1,0)
 var clave_barrera: String=M.clave(barrera)
 var anterior: Dictionary=j.d.mundo.constr.get(clave_barrera,{}).duplicate(true)
 j.d.mundo.constr[clave_barrera]={"t":"muro","dueno":J.LOCAL};j.mundo.cambiar()
 atacante.pos=j.pies+Vector2(32,0);atacante.fauna_id="vision_prueba"
 j.combate.ataque(J.LOCAL).inv_t=0.0
 var area: Dictionary=j.combate.info_ataque(atacante,"golpe");area.radio=100.0
 j.combate._resolver(atacante,area)
 ok(j.jug().hp==vida,"fauna regional no golpea a través de un muro")
 if anterior.is_empty():j.d.mundo.constr.erase(clave_barrera)
 else:j.d.mundo.constr[clave_barrera]=anterior
 j.mundo.cambiar()
 var visual=Arte.new()
 var ef: Dictionary=j.combate._nuevo("golem_sierra",j.pies)
 ef.fauna_id="descarga";visual.actualizar(0.01,[ef],j.jug().hp,j.pies,j.mundo,false)
 visual.actualizar(0.01,[],j.jug().hp,j.pies,j.mundo,false)
 ok(visual.residuos.is_empty(),"descargar fauna no crea una falsa animación de muerte")
 # Spawn bloqueado: no mueve el punto determinista a otro lugar para saltarse una pared.
 var planeado: Dictionary=f.plan_region(Vector2i(-13,-16))
 if not planeado.is_empty():
  var ocupada: String=M.clave(planeado.celda)
  j.d.mundo.constr[ocupada]={"t":"muro","dueno":J.LOCAL};j.mundo.cambiar()
  j.combate.enemigos=j.combate.enemigos.filter(func(v):return v.get("fauna_id","")!=planeado.id)
  f.actualizar()
  ok(not fauna(j).any(func(v):return v.fauna_id==planeado.id),"construir sobre un punto aplaza la aparición")
 var limite := true
 for i in 12:
  viajar(j,Vector2i(1000+i*96,-1000))
  if fauna(j).size()>24 or f.planes.size()>j.mundo.regiones.size(): limite=false
 ok(limite,"exploración sucesiva mantiene acotadas criaturas activas y caché de planes")
 var arte=Arte.new()
 var validas := true
 for t in Arte.FAUNA:
  for accion in ["idle","attack","hit","defeat"]:
   var tx=arte.tex("fauna/"+Arte.FAUNA[t]+"_"+accion+".png")
   if tx==null or tx.get_width()%(2 if accion=="hit" else 4)!=0:validas=false
 ok(validas and arte.faltantes.is_empty(),"20 tiras de arte disponibles con dimensiones compatibles")
 # Serialización de servidor y consumo real del cliente; la réplica no genera encuentros.
 var srv=Srv.new();srv.j=j
 var cliente=Cli.new();cliente.yo=J.LOCAL;cliente.j=Cli.Replica.new();cliente.j.red=cliente
 cliente.j.d=j.d.duplicate(true);cliente.j._arrancar();cliente.j.combate.enemigos.clear()
 cliente.instantanea(srv.instantanea_actual())
 ok(cliente.j.combate.enemigos.size()==j.combate.enemigos.size(),"instantánea del servidor transmite especies y estados a la réplica")
 var antes:int=cliente.j.combate.enemigos.size()
 cliente.j.combate.fauna.actualizar()
 ok(cliente.j.combate.enemigos.size()==antes,"réplica nunca genera fauna por su cuenta")
 cliente.free();srv.free()
 var antiguo=J.nueva(123,"Anterior",[0,0,0]);antiguo.d.erase("fauna")
 var pj=antiguo.jug().duplicate(true)
 antiguo.combate.fauna.restaurar()
 ok(antiguo.d.fauna.bajas.is_empty() and antiguo.jug()==pj,"migración añade fauna sin reemplazar inventario ni progreso")
 print("FAUNA: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
