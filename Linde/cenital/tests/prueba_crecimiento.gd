extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
const G=preload("res://scripts/guardado.gd")
const Srv=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
var total:=0
var fallos:=0
func ok(c: bool,t: String) -> void:
 total+=1
 if not c:fallos+=1
 print(("PASS " if c else "FAIL ")+t)
func mover(j,c: Vector2i) -> void:
 j.pies=M.pies_de_celda(c);j.actualizar_regiones()
func sitio_puesto(j) -> Vector2i:
 for y in range(-176,-64,8):
  for x in range(-176,-64,8):
   var c:=Vector2i(x,y)
   mover(j,c+Vector2i(0,4))
   if j.autonomia.asentamientos.validar(c)=="":return c
 return Vector2i.ZERO
func _init() -> void:
 var viejo=J.nueva(123,"Anterior",[0,0,0])
 viejo.d.mundo.generacion.version=1
 viejo.d.mundo.rotos["roca@56,-299"]=viejo.d.min
 viejo.guardar("/tmp/linde-v1-roca.json")
 var carga=J.cargar("/tmp/linde-v1-roca.json");mover(carga,Vector2i(56,-299))
 ok(carga.mundo.generador.datos(Vector2i(56,-299)).objeto=="roca" and carga.mundo.objeto_presente(Vector2i(56,-299))=="","la roca extraída en v1 no reaparece como estaño al cargar")
 viejo.d.mundo.rotos.erase("roca@56,-299");viejo.d.mundo.golpes["roca@56,-299"]=1;viejo.guardar("/tmp/linde-v1-parcial.json")
 carga=J.cargar("/tmp/linde-v1-parcial.json");mover(carga,Vector2i(56,-299))
 ok(carga.mundo.objeto_presente(Vector2i(56,-299))=="roca@56,-299" and int(carga.d.mundo.golpes["roca@56,-299"])==1,"v1 conserva tipo e impactos parciales de roca")
 var nuevo=J.nueva(123,"Nueva",[0,0,0])
 ok(nuevo.d.mundo.generacion.version==2 and nuevo.mundo.generador.datos(Vector2i(56,-299)).objeto=="veta_estano","partidas nuevas usan el generador v2 con estaño")
 viejo.d.mundo.golpes.clear();viejo.d.mundo.rotos["veta_estano@56,-299"]=0;viejo.guardar("/tmp/linde-intermedio.json")
 carga=J.cargar("/tmp/linde-intermedio.json");mover(carga,Vector2i(56,-299))
 ok(carga.mundo.objeto_presente(Vector2i(56,-299))=="","se conserva también el estaño extraído en la versión intermedia sin número nuevo")
 var futuro: Dictionary=nuevo.d.duplicate(true);futuro.mundo.generacion.version=3
 ok(G.desempaquetar(G.empaquetar(futuro)).is_empty(),"no acepta un generador futuro desconocido")
 # Parcela: se reserva antes de poner cama y protege el acceso completo.
 var h=J.nueva(123,"Solar",[0,0,0]);var so=h.autonomia.sociedad
 var p: Dictionary={}
 for intento in 50:
  p=so.habitat.reservar("maren")
  if not p.is_empty():break
 ok(not p.is_empty(),"encuentra y reserva un solar real en el valle sin preparar el mapa")
 if p.is_empty():quit(1);return
 var cama:=Vector2i(p.cama[0],p.cama[1]);var puerta:=cama+Vector2i(0,2)
 ok(not so.habitat.admisible(cama+Vector2i(2,0)),"otro solar no puede invadir la reserva")
 ok(not so.habitat.permite_pieza(cama+Vector2i(0,3),"mesa"),"el acceso reservado no admite talleres ni campos")
 ok(so.habitat.permite_pieza(puerta,"puerta"),"las piezas planificadas sí caben en su posición")
 h.mundo.poner(cama,"cama_huesped",false)
 for d in so.cfg.vivienda.casa.base:h.mundo.poner(cama+Vector2i(d[0],d[1]),"muro_ladrillo",false)
 for paso in so._celdas_casa(cama):
  if paso[0]=="techo":h.mundo.techar(paso[1],"grupo:talleres")
  else:h.mundo.poner(paso[1],"cofre" if paso[0]=="puerta" else paso[0],false)
 so.datos().refugios={M.clave(cama):true};so.datos().casas={M.clave(cama):true}
 h.autonomia.perfil("maren").recetas.append("ladrillo")
 so._casa("maren")
 ok(not so.casa_completa(cama) and not so.datos().casas.has(M.clave(cama)),"una obra bloqueada pierde la marca antigua de terminada")
 h.mundo.quitar(puerta)
 h.autonomia.estado("maren").inv={"madera":3}
 var pos:=M.pies_de_celda(puerta+Vector2i.DOWN);h.d.npcs.maren.pos=[pos.x,pos.y]
 so._casa("maren")
 ok(so.casa_completa(cama),"al retirar el obstáculo se reanuda y completa la casa pagando la puerta")
 h.guardar("/tmp/linde-solares.json");var hc=J.cargar("/tmp/linde-solares.json")
 ok(hc.autonomia.sociedad.habitat.datos().parcelas.has(M.clave(cama)),"reserva y obra sobreviven a guardar y cargar")
 # Primer asentamiento exterior: acciones normales del jugador y producción resumida.
 var r=J.nueva(123,"Colona",[0,0,0]);var regional=r.autonomia.asentamientos
 var c:=sitio_puesto(r)
 ok(c!=Vector2i.ZERO,"hay solares regionales libres en el terreno generado")
 if c==Vector2i.ZERO:quit(1);return
 mover(r,c+Vector2i(0,-1));r.jug().inv=C.CONSTR.puesto.coste.duplicate(true)
 var fundar: Dictionary=r.construir("puesto",c)
 if not fundar.ok: print(fundar)
 ok(fundar.ok and r.jug().inv.is_empty(),"fundar consume el coste completo sin regalar materiales")
 if not fundar.ok:quit(1);return
 var puesto: Dictionary=regional.datos().puestos[M.clave(c)]
 ok(r.mundo.constr_en(c+Vector2i(1,0)).t=="cama_huesped" and r.d.cofres.has(puesto.cofre),"el puesto materializa camas, campos, techos y cofre")
 var antes:int=regional.inventario(puesto).baya
 r.d.min+=360;regional.actualizar()
 ok(puesto.residentes.size()==1 and regional.inventario(puesto).baya<=antes,"con cama y comida llega un residente regional")
 r.d.min+=360;regional.actualizar()
 ok(puesto.residentes.size()==2,"el puesto crece hasta sus dos camas reales")
 mover(r,Vector2i(4096,4096));var regiones:int=r.mundo.regiones.size();var rotos:int=r.d.mundo.rotos.size()
 r.d.min+=60;regional.actualizar()
 ok(int(puesto.producciones)>0 and r.d.mundo.rotos.size()>rotos,"lejos del jugador hay producción con extracción real del mapa")
 ok(r.mundo.regiones.size()==regiones and not r.mundo.region_cargada(c),"la simulación distante no mantiene cargado el asentamiento")
 r.guardar("/tmp/linde-puesto.json");var rc=J.cargar("/tmp/linde-puesto.json")
 var antes_carga:String=JSON.stringify(rc.autonomia.asentamientos.datos())
 rc.autonomia.asentamientos.actualizar()
 ok(JSON.stringify(rc.autonomia.asentamientos.datos())==antes_carga,"cargar no duplica llegada, producción ni consumo")
 var rp: Dictionary=rc.autonomia.asentamientos.datos().puestos[M.clave(c)]
 var inv: Dictionary=rc.autonomia.asentamientos.inventario(rp)
 inv.baya=0;var produccion:int=rp.producciones
 rc.d.min+=60;rc.autonomia.asentamientos.actualizar()
 ok(int(rp.producciones)==produccion,"sin comida se detiene la producción")
 mover(rc,c+Vector2i(0,3))
 ok(rc.autonomia.asentamientos.visibles().size()==2,"al volver aparecen los dos residentes persistentes")
 ok(not rc.retirar(c).ok,"no permite duplicar materiales desmontando solo el marcador del puesto")
 # Réplica, secuenciación y límite de regiones con expediciones normales activas.
 var cliente=Cli.new();cliente.yo=J.LOCAL;cliente.j=Cli.Replica.new();cliente.j.red=cliente
 cliente.j.d=rc.d.duplicate(true);cliente.j._arrancar();cliente.j.pies=rc.pies;cliente.j.actualizar_regiones()
 ok(cliente.j.autonomia.asentamientos.visibles().size()==2,"la réplica presenta la población regional desde el estado del servidor")
 var srv=Srv.new();srv.j=rc
 var snap:Array=srv.instantanea_actual();snap[4]=100
 cliente.instantanea_fiable(snap)
 var viejo_snap:Array=snap.duplicate(true);viejo_snap[0]=0;viejo_snap[4]=99
 cliente.instantanea(viejo_snap)
 ok(int(cliente.j.d.min)==int(rc.d.min),"una instantánea atrasada de otro canal no hace retroceder la partida")
 var cantidad:int=cliente.j.autonomia.asentamientos.datos().puestos[M.clave(c)].producciones
 cliente.j.autonomia.asentamientos.actualizar()
 ok(int(cliente.j.autonomia.asentamientos.datos().puestos[M.clave(c)].producciones)==cantidad,"el cliente nunca extrae recursos ni produce por su cuenta")
 cliente.free();srv.free()
 var normales=J.nueva(321,"Caché",[0,0,0]);var acotada:=true
 for i in 12:
  mover(normales,Vector2i(1000+i*80,-1000))
  if normales.mundo.regiones.size()>125:acotada=false
 ok(acotada and normales.autonomia.expediciones(),"la caché permanece acotada con las expediciones de NPC activas")
 print("CRECIMIENTO: %d comprobaciones, %d fallos"%[total,fallos])
 quit(1 if fallos else 0)
