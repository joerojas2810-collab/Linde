extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const E=preload("res://scripts/edificios.gd")
const Inv=preload("res://scripts/inventario.gd")
var total:=0
var fallos:=0
func ok(v: bool,t: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func despejar(j,c: Vector2i,radio: int)->void:
 # Fixture de terreno previamente despejado: no concede drops ni altera la geografía base.
 for y in range(c.y-radio,c.y+radio+1):
  for x in range(c.x-radio,c.x+radio+1): j.d.mundo.registro.despejes[M.clave(Vector2i(x,y))]=true
 j.mundo.cambiar()
func _init()->void:
 var j=J.nueva(123,"Expansion",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 s.transitos.datos().politica.comercio_autonomo=false
 var pueblos: Array=s.datos().puestos.values()
 var p: Dictionary=pueblos[0]
 var otro: Dictionary=pueblos[1]
 ok(not s.fundacion.intentar(p),"no funda sin crisis ni grupo suficiente")
 var inicial: Array=[]
 for b in pueblos:
  for r in b.residentes: inicial.append(r.id)
 # Recursos de entrada declarados del escenario; el ejecutor debe pagarlos, nunca crearlos.
 s.inventario(p).merge({"madera":1000,"piedra":1000,"fibra":1000,"baya":100,"hacha_piedra":10,"pico_piedra":10},true)
 var c:=Vector2i(p.celda[0],p.celda[1])
 despejar(j,c,14)
 otro.presiones={"comida":{"desde":int(j.d.min)-int(s.cfg.comida_min),"duracion_min":int(s.cfg.comida_min)}}
 otro.comercio_intento_min=int(j.d.min)
 s.inventario(otro).erase("baya")
 for i in 2:
  s.planear_crecimiento(p)
  ok(p.has("obra"),"demanda de recepción crea una obra física, no residentes")
  if not p.has("obra"): quit(1);return
  var antes: Dictionary=s.inventario(p).duplicate(true)
  var coste: Dictionary=p.obra.coste.duplicate(true)
  # La segunda recepción requiere un cultivo adicional por tasas actuales, no por camas.
  s.ampliar_cultivo(p)
  var actor: String=s.ejecutar_obra(p)
  ok(actor!="" and s.capacidad(p)==3+i and p.residentes.size()==2+i,"vivienda pagada aumenta capacidad sin crear población")
  ok(int(s.inventario(p).madera)<=int(antes.madera)-int(coste.madera),"construcción descuenta materiales reales")
  var r: Dictionary=otro.residentes[0]
  if otro.residentes.size()>1:
   Inv.quitar(s.inventario(p),{"baya":1});s.inventario(otro).baya=int(s.inventario(otro).get("baya",0))+1
  var reserva: Dictionary=s.transitos.reservar("incorporar"+str(i),otro.id,p.id,[r.id],{},{})
  # Pago de comida vencida no se sustituye por un reinicio de cursor.
  if int(s.balance_resumido(otro).baya.vencido)>0:
   s.inventario(otro).baya=10;s.actualizar()
  ok(reserva.ok and s.transitos.salir("incorporar"+str(i)).ok,"incorporación usa una identidad existente en tránsito")
  if not reserva.ok: quit(1);return
  j.d.min+=int(reserva.operacion.duracion);s.transitos.actualizar()
  otro.presiones={"comida":{"desde":int(j.d.min)-int(s.cfg.comida_min),"duracion_min":int(s.cfg.comida_min)}}
 ok(p.residentes.size()==4 and otro.residentes.is_empty(),"crecimiento conserva el total de NPC del mundo")
 # Presión renovable real: cuatro consumidores sobre los dos cultivos originales (capacidad tres).
 for q in p.campos.slice(2): j.d.mundo.constr.erase(M.clave(Vector2i(q[0],q[1])))
 p.campos=p.campos.slice(0,2)
 # Fixture de suelo ya ocupado: no cabe otro cultivo local; los pisos no bloquean el paso.
 for celda in s._alcance(c):
  if j.mundo.constr_en(celda).is_empty(): j.d.mundo.registro.get_or_add("pisos",{})[M.clave(celda)]={"dueno":p.dueno,"edificio":"solar_ocupado_fixture"}
 for r in p.residentes: r.usos=50
 # Liquida comidas vencidas con stock real antes de evaluar la expedición.
 s.actualizar()
 p.viabilidad=s.evaluar_viabilidad(p);s.registrar_presion(p)
 j.d.min+=int(s.cfg.comida_min)
 s.actualizar()
 p.viabilidad=s.evaluar_viabilidad(p);s.registrar_presion(p)
 ok(s.deficit_sostenible(p)>0 and p.presiones.comida.duracion_min>=int(s.cfg.comida_min),"déficit renovable persiste sin convertir proyección en stock")
 # Preparar un solar conocido apto; conservar árboles, piedra y bayas reales alrededor.
 var ajeno:=Vector2i(otro.celda[0],otro.celda[1])
 j.combate.enemigos.append(j.combate._nuevo("slime",M.pies_de_celda(ajeno)))
 var elegido:=Vector2i.ZERO
 var bloque:=int(j.autonomia.reglas.conocimiento.bloque)
 for dx in range(4,13):
  for dy in range(-6,7):
   var q:=Vector2i((floori(float(c.x)/bloque)+dx)*bloque+int(bloque/2),(floori(float(c.y)/bloque)+dy)*bloque+int(bloque/2))
   var previo: Dictionary=j.d.mundo.registro.despejes.duplicate()
   despejar(j,q,3)
   var plan: Dictionary=s.fundacion.plano(p,q)
   if s.fundacion.solar(plan):
    var f: Dictionary=s.fundacion.fuentes(q)
    if int(f.arbusto)>0 and int(f.arbol)>0 and int(f.roca)>0 and not s.transitos.ruta_celdas(c,q+Vector2i(0,3)).is_empty() and s.ruta_sin_amenaza_conocida(s.transitos.ruta_celdas(c,q+Vector2i(0,3))): elegido=q;break
   j.d.mundo.registro.despejes=previo;j.mundo.cambiar()
  if elegido!=Vector2i.ZERO: break
 ok(elegido!=Vector2i.ZERO,"solar tiene terreno, fuentes reales y ruta comprobable")
 if elegido==Vector2i.ZERO: quit(1);return
 for r in p.residentes: j.autonomia._ver(r,elegido,0)
 p.crisis={"causa":"comida_persistente"}
 var cantidad_pueblos: int=s.datos().puestos.size()
 var inicio: Dictionary=s.inventario(p).duplicate(true)
 s.transitos.datos().politica.comercio_autonomo=true
 s.transitos.comerciar(p) # intento real sin contraparte habitada
 s.resolver_crisis(p)
 var sale: bool=p.crisis.estado=="fundacion_en_curso"
 ok(sale and s.datos().puestos.size()==cantidad_pueblos and p.residentes.size()==2,"expedición reserva y sale sin registrar pueblo ni crear población")
 if not sale: print("BLOQUEO ",p.get("expedicion",{}));quit(1);return
 var op: Dictionary=s.transitos.datos().operaciones[p.crisis.operacion]
 var sid: String=op.destino
 ok(op.miembros.size()==2 and op.ventaja.destino.arbusto>op.ventaja.origen.arbusto,"fundadores reales y ventaja territorial trazable")
 var archivo:="/tmp/linde-expansion-%d.json" % OS.get_process_id()
 ok(j.guardar(archivo),"guarda expedición sin materializar destino")
 j=J.cargar(archivo);s=j.autonomia.asentamientos;op=s.transitos.datos().operaciones[op.id]
 j.d.min+=int(op.duracion)
 var campo_objetivo: Array=s.transitos.puesto(sid).fundacion.campos[0]
 var bloqueo:=M.clave(Vector2i(campo_objetivo[0],campo_objetivo[1]))
 j.d.mundo.constr[bloqueo]={"t":"muro","dueno":"fixture_ajeno"};j.mundo.cambiar()
 s.transitos.actualizar()
 ok(op.estado=="detenida" and s.datos().puestos.size()==cantidad_pueblos and not op.bienes.is_empty(),"solar alterado detiene la expedición sin materializar ni gastar la obra")
 ok(j.guardar(archivo),"guarda interrupción conservando viajeros y carga")
 var continuo=j
 j=J.cargar(archivo);s=j.autonomia.asentamientos;op=s.transitos.datos().operaciones[op.id]
 j.d.mundo.constr.erase(bloqueo);j.mundo.cambiar()
 j.d.min+=int(op.duracion)-int(op.avance) # reanudar exige el tiempo que aún falta recorrer
 s.transitos.actualizar()
 ok(op.estado=="entregada" and s.datos().puestos.size()==cantidad_pueblos+1,"solo la llegada funda y paga el plano existente")
 if op.estado!="entregada": print("BLOQUEO LLEGADA ",op.get("motivo",""));quit(1);return
 continuo.d.mundo.constr.erase(bloqueo);continuo.mundo.cambiar();continuo.d.min=int(j.d.min)
 continuo.autonomia.asentamientos.transitos.actualizar()
 var esperado:=JSON.stringify(JSON.parse_string(JSON.stringify(continuo.autonomia.asentamientos.datos())))
 var obtenido:=JSON.stringify(JSON.parse_string(JSON.stringify(s.datos())))
 ok(esperado==obtenido,"continuación con y sin reinicio produce exactamente el mismo registro")
 var nueva: Dictionary=s.datos().puestos[sid]
 ok(s.capacidad(nueva)==2 and nueva.residentes.size()==2 and nueva.campos.size()==2,"fundación conserva contrato mínimo físico")
 var conservado:=true
 var origen_final: Dictionary=s.inventario(s.datos().puestos[op.origen])
 for item in inicio:
  var gastado: int=int(op.construccion.coste.get(item,0))+(int(op.get("consumido",0)) if item=="baya" else 0)
  conservado=conservado and int(inicio[item])==int(origen_final.get(item,0))+int(s.inventario(nueva).get(item,0))+gastado
 ok(conservado,"origen más destino más obra y consumo conservan cada recurso exactamente")
 var actuales: Array=[]
 for b in s.datos().puestos.values():
  for r in b.residentes: actuales.append(r.id)
 inicial.sort();actuales.sort()
 ok(actuales==inicial and not op.construccion.coste.is_empty(),"no hay población inventada y la obra registra coste real")
 var Srv=load("res://scripts/red_servidor.gd")
 var Cli=load("res://scripts/red_cliente.gd")
 var servidor=Srv.new();servidor.j=j
 var cliente=Cli.new();cliente._bienvenida(servidor.estado_para(J.LOCAL))
 ok(JSON.stringify(cliente.j.autonomia.asentamientos.datos())==JSON.stringify(s.datos()),"réplica recibe fundación e identidades sin ejecutar otra obra")
 cliente.free();servidor.free()
 var final:=JSON.stringify(nueva)
 s.transitos.actualizar()
 ok(JSON.stringify(nueva)==final,"repetir llegada no duplica edificios, carga ni residentes")
 print("EXPANSION_F6: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
