extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const E = preload("res://scripts/edificios.gd")
const H = preload("res://scripts/huella.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
 print(("PASS " if c else "FAIL ")+t)
 if not c: fallos+=1

## Solar preparado: solo limpia recursos del escenario; no construye paredes, muebles ni cubierta.
static func solar_preparado(j, inicio: Vector2i = Vector2i(414,400)) -> Vector2i:
 for dy in range(0,96,8):
  for dx in range(0,96,8):
   var entrada := inicio+Vector2i(dx,dy)
   j.pies=M.pies_de_celda(entrada+Vector2i.DOWN)
   j.actualizar_regiones()
   var e := E.plano("vivienda",entrada,J.LOCAL)
   var agua := false
   for y in range(entrada.y-7,entrada.y+3):
    for x in range(entrada.x-5,entrada.x+6):
     if j.mundo.tipo(Vector2i(x,y))==M.T.AGUA: agua=true
   if agua: continue
   for y in range(entrada.y-7,entrada.y+3):
    for x in range(entrada.x-5,entrada.x+6):
     var oid: String=j.mundo.objeto_presente(Vector2i(x,y))
     if oid!="":j.mundo.romper(oid,int(j.d.min))
   if E.solar(j,e)=="": return entrada
 return M.SIN_CELDA

func _init() -> void:
 var j=J.nueva(123,"Constructora",[0,0,0],"poblado")
 j.combate.enemigos.clear()
 var c:=solar_preparado(j)
 ok(c!=M.SIN_CELDA,"hay solar de prueba con huella y acceso en el exterior")
 if c==M.SIN_CELDA:quit(1);return
 var plan:=E.plano("vivienda",c,J.LOCAL)
 var coste:=E.coste(plan)
 ok(coste=={"madera":114,"fibra":45},"el precio es la suma exacta de 21 muros, puerta, cama, cofre, 20 suelos y 41 techos")
 var antes: String=H.hash_de([j.d.mundo,j.d.cofres,j.jug().inv])
 ok(not j.construir("vivienda",c).ok and H.hash_de([j.d.mundo,j.d.cofres,j.jug().inv])==antes,"sin materiales no se crea nada ni se pierde inventario")
 j.jug().inv=coste.duplicate()
 var obstaculo:=c+Vector2i.DOWN
 var p_antes: String=H.hash_de([j.d.mundo,j.d.cofres,j.jug().inv])
 j.mundo.poner(obstaculo,"muro",false)
 ok(not j.construir("vivienda",c).ok and j.jug().inv==coste,"entrada bloqueada: rechazo sin consumir materiales")
 j.mundo.quitar(obstaculo)
 var resto: String="c@"+M.clave(c+Vector2i(2,-4))
 j.d.cofres[resto]={"inv":{"madera":9}}
 ok(not j.construir("vivienda",c).ok and j.d.cofres[resto].inv=={"madera":9} and j.jug().inv==coste,"un depósito previo nunca se borra para instalar el edificio")
 j.d.cofres.erase(resto)
 ok(H.hash_de([j.d.mundo,j.d.cofres,j.jug().inv])==p_antes,"los intentos rechazados no dejan piezas ni un edificio parcial")
 var resultado: Dictionary=j.construir("vivienda",c)
 if not resultado.ok:print("MOTIVO ",resultado)
 ok(resultado.ok and j.jug().inv.is_empty(),"construcción completa, sin doble cobro ni materiales gratuitos")
 var e: Dictionary=j.mundo.edificio_en(c)
 if e.is_empty():quit(1);return
 ok(e.id==plan.id and e.etapas.size()==4 and e.obra=="terminada","identidad estable y plano preparado para etapas futuras")
 ok(E.puerta_abierta(c,[M.pies_de_celda(c+Vector2i.DOWN)]) and not E.puerta_abierta(c,[M.pies_de_celda(c+Vector2i(0,3))]),"puerta automática por proximidad, sin cambiar su colisión transitable")
 ok(E.accesible(j,e),"interior y uso de cama/cofre alcanzables desde el exterior")
 var cama:=c+Vector2i(-2,-4)
 var cofre:=c+Vector2i(2,-4)
 ok(j.autonomia.sociedad.casa_completa(cama),"los servicios de vivienda reconocen el plano con el bono de descanso existente")
 ok(not j.autonomia.sociedad.habitat.permite_pieza(c+Vector2i(0,-2),"mesa"),"los NPC tampoco modifican libremente el interior del plano")
 ok(j.mundo.piso_en(cama).edificio==e.id and j.mundo.constr_en(cama).t=="cama","suelo y mobiliario coexisten sin ocupar dos veces la misma capa")
 # Recorrido continuo por el pasillo y salida, usando el movimiento normal.
 var ruta: Array=[Vector2i.UP,Vector2i.UP,Vector2i.UP,Vector2i.UP,Vector2i.DOWN,Vector2i.DOWN,Vector2i.DOWN,Vector2i.DOWN]
 var valido:=true
 for dir in ruta:
  var anterior: Vector2=j.pies
  for i in 4:j.mover_pj(dir,0.0625)
  if j.pies.distance_to(anterior+Vector2(dir)*16)>0.1:valido=false
 ok(valido and M.celda_de(j.pies)==c+Vector2i.DOWN,"entrar, circular y salir sin transición de escena ni teletransporte")
 j.pies=M.pies_de_celda(cama+Vector2i.DOWN);j.mira=Vector2i.UP
 ok(j.interactuar().get("panel","")=="dormir" and j.jug().cama==[j.pies.x,j.pies.y],"la cama real conserva descanso y punto de retorno existentes")
 j.pies=M.pies_de_celda(cofre+Vector2i.DOWN);j.mira=Vector2i.UP
 ok(j.interactuar().get("panel","")=="cofre","el cofre interior se abre con la interacción habitual")
 j.jug().inv={"madera":3}
 var cid: String="c@"+M.clave(cofre)
 ok(j.mover_cofre(cid,"madera",true).ok and j.d.cofres[cid].inv=={"madera":3},"almacenamiento real sin inventario paralelo del edificio")
 ok(not j.retirar(cofre).ok and not j.construir("muro",c+Vector2i(0,-1)).ok,"el edificio no se desarma ni modifica mediante construcción libre")
 var hash_mundo: String=H.hash_de(j.d.mundo)
 ok(E.abierto(e,M.pies_de_celda(c+Vector2i(0,-2))) and not E.abierto(e,M.pies_de_celda(c+Vector2i(0,4))) and H.hash_de(j.d.mundo)==hash_mundo,"ocultación distinta dentro/fuera, sin cambiar el estado compartido")
 j.pies=M.pies_de_celda(c+Vector2i(0,-2))
 var suelo_antes: int=j.autonomia.desarrollo.suelo(j.actor_desarrollo())
 ok(suelo_antes==20,"los suelos pagados conservan la superficie útil de las técnicas existentes")
 # Uso real por NPC detallado, sin crear población ni inventarios extra.
 var nid := "maren"
 j.d.mundo.poblados.inicial.camas[nid]=[cama.x,cama.y]
 var p0:=M.pies_de_celda(c+Vector2i.DOWN)
 j.d.npcs[nid].pos=[p0.x,p0.y];j.d.npcs[nid].energia=20.0;j.d.min=23*60
 for i in 180:j.habitantes.paso(0.1)
 ok(j.mundo.es_adyacente(M.celda_de(j.habitantes.pos(nid)),cama) and j.d.npcs[nid].act=="dormir" and float(j.d.npcs[nid].energia)>20.0,"el NPC entra por la puerta, alcanza su cama asignada y descansa")
 var pared:=c+Vector2i(-3,-3)
 j.mundo.quitar(pared);j.mundo.destechar(c+Vector2i(0,-3))
 ok(not j.autonomia.sociedad.casa_completa(cama),"una vivienda con faltantes deja de cumplir el contrato de casa completa")
 var revision: int=e.revision
 j.guardar("/tmp/linde-vivienda.json")
 var carga=J.cargar("/tmp/linde-vivienda.json")
 ok(carga!=null and carga.mundo.constr_en(pared).is_empty() and carga.d.cofres[cid].inv=={"madera":3},"reiniciar conserva faltantes, identidad e inventario sin regenerarlos")
 carga.pies=M.pies_de_celda(c+Vector2i.DOWN);carga.actualizar_regiones()
 var ec: Dictionary=carga.mundo.edificio_en(c)
 ok(ec==e and carga.habitantes.cama(nid)==cama,"plano y asignación de NPC persistidos exactamente")
 carga.jug().inv={"madera":3,"fibra":1}
 ok(carga.reparar_edificio(e.id,revision).ok and carga.jug().inv.is_empty() and E.coste(E.faltantes(carga,ec)).is_empty(),"reparar paga solo muro y teja faltantes, conservando los demás objetos")
 carga.unir("ajena","Ajena",[0,0,0])
 carga.rt.ajena.pies=M.pies_de_celda(c+Vector2i.DOWN)
 carga.jug("ajena").inv={"madera":100,"fibra":100}
 ok(not carga.reparar_edificio(e.id,int(ec.revision),"ajena").ok and carga.jug("ajena").inv=={"madera":100,"fibra":100},"la reparación respeta propiedad sin tocar cuentas o credenciales")
 ok(not carga.reparar_edificio(e.id,revision).ok and carga.d.cofres[cid].inv=={"madera":3},"una revisión vieja no duplica reparación, cobros ni contenido")
 var almacen: String=H.hash_de([ec,carga.d.cofres[cid]])
 carga.pies=M.pies_de_celda(Vector2i(900,900));carga.actualizar_regiones()
 carga.pies=M.pies_de_celda(c+Vector2i.DOWN);carga.actualizar_regiones()
 ok(H.hash_de([carga.mundo.edificio_en(c),carga.d.cofres[cid]])==almacen,"descargar y volver conserva una vivienda única que cruza regiones")
 var futuro: Dictionary=carga.d.duplicate(true)
 futuro.mundo.registro.edificios[e.id].version=999
 ok(J.Guard.migrar(futuro).is_empty(),"versiones futuras de edificios se rechazan explícitamente")
 quit(1 if fallos else 0)
