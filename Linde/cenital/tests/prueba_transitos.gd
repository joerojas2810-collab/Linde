extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Srv=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
var total:=0
var fallos:=0
func ok(v: bool,texto: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+texto)
func cantidades(s)->Dictionary:
 var resultado: Dictionary={}
 for p in s.datos().puestos.values():
  for item in s.inventario(p): resultado[item]=int(resultado.get(item,0))+int(s.inventario(p)[item])
 for op in s.transitos.datos().operaciones.values():
  for lote in [op.bienes,op.provisiones,op.get("contraoferta",{})]:
   for item in lote: resultado[item]=int(resultado.get(item,0))+int(lote[item])
  resultado.baya=int(resultado.get("baya",0))+int(op.get("consumido",0))
 return resultado
func identidades(s)->Dictionary:
 var ids: Dictionary={}
 for p in s.datos().puestos.values():
  for r in p.residentes: ids[r.id]=int(ids.get(r.id,0))+1
 for op in s.transitos.datos().operaciones.values():
  for r in op.miembros: ids[r.id]=int(ids.get(r.id,0))+1
 return ids
func iguales(a,b)->bool:
 return JSON.stringify(JSON.parse_string(JSON.stringify(a)))==JSON.stringify(JSON.parse_string(JSON.stringify(b)))
func _init()->void:
 var j=J.nueva(123,"Viajes",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 var t=s.transitos
 var p: Array=s.datos().puestos.values()
 var a: Dictionary=p[0];var b: Dictionary=p[1]
 s.inventario(a).piedra=65;s.inventario(b).madera=65
 s.inventario(a).baya=20
 var bienes=cantidades(s);var ids=identidades(s)
 var viajero: String=a.residentes[0].id
 var ruta: Array=t.ruta(a.id,b.id)
 var continua:=ruta.size()>1
 for i in range(1,ruta.size()):
  var x: Array=ruta[i-1];var y: Array=ruta[i]
  continua=continua and absi(x[0]-y[0])+absi(x[1]-y[1])==1 and s._transitable(Vector2i(y[0],y[1]))
 ok(continua,"ruta determinista recorre celdas reales contiguas y transitables")
 ok(ruta==t.ruta(a.id,b.id),"repetir búsqueda conserva la ruta")
 var r: Dictionary=t.acordar("trueque",a.id,b.id,[viajero],{"piedra":2},{"madera":2},{"baya":2})
 ok(r.ok and iguales(bienes,cantidades(s)),"reserva ambos lotes y provisiones sin modificar el total de recursos")
 ok(t.acordar("trueque",a.id,b.id,[viajero],{"piedra":2},{"madera":2},{"baya":2}).ok and iguales(bienes,cantidades(s)),"reintento del acuerdo no reserva dos veces")
 ok(not t.acordar("trueque",a.id,b.id,[viajero],{"piedra":3},{"madera":2},{"baya":2}).ok,"misma clave con otra carga se rechaza")
 ok(t.salir("trueque").ok and iguales(ids,identidades(s)) and a.residentes.size()==1,"salir mueve al NPC original a tránsito y retira su actividad del origen")
 var op: Dictionary=t.datos().operaciones.trueque
 var salida:=int(j.d.min)
 var duracion:=int(op.duracion)
 ok(duracion==ceili(float(ruta.size()-1)*M.P.CELDA/24.0),"tiempo deriva de distancia y velocidad vigente, sin bonificaciones")
 j.d.min=salida+maxi(1,duracion/2)
 t.actualizar()
 ok(op.estado=="viajando" and not op.get("regresando",false) and int(s.inventario(b).get("piedra",0))==0,"antes de llegar no se acredita la carga")
 var archivo:="/tmp/linde-transito-%d.json" % OS.get_process_id()
 ok(j.guardar(archivo),"guarda durante el trayecto")
 var carga=J.cargar(archivo)
 ok(carga!=null and iguales(carga.autonomia.asentamientos.transitos.datos(),t.datos()),"reinicio conserva identidad, ruta, carga y progreso")
 j.d.min=salida+duracion
 t.actualizar()
 ok(op.get("regresando",false) and int(s.inventario(b).piedra)==2 and iguales(ids,identidades(s)),"intercambio ocurre en destino y el mismo mensajero inicia regreso")
 t.actualizar()
 ok(int(s.inventario(b).piedra)==2 and iguales(bienes,cantidades(s)),"repetir la llegada no duplica el intercambio")
 if carga!=null:
  carga.d.min=int(j.d.min)
  carga.autonomia.asentamientos.transitos.actualizar()
  ok(iguales(carga.autonomia.asentamientos.transitos.datos(),t.datos()),"continuación del guardado en tránsito coincide con la ejecución original")
 j.d.min+=duracion
 t.actualizar()
 ok(op.estado=="entregada" and iguales(ids,identidades(s)) and a.residentes.size()==2 and iguales(bienes,cantidades(s)),"regreso físico devuelve NPC y provisiones y entrega el pedido exactamente una vez")
 # Cancelación previa al viaje y devolución de ambas reservas.
 ok(t.acordar("cancelar",a.id,b.id,[viajero],{"piedra":1},{"madera":1},{"baya":2}).ok,"prepara cancelación con garantías reales")
 ok(t.cancelar("cancelar") and not t.cancelar("cancelar") and iguales(bienes,cantidades(s)),"cancelar antes de partir devuelve ambas reservas una vez")
 # Bloqueo de ruta y consumo real durante la espera.
 a.comida_min=int(j.d.min)
 for persona in a.residentes: persona.comida_min=int(j.d.min)
 ok(t.acordar("interrumpir",a.id,b.id,[viajero],{"piedra":1},{"madera":1},{"baya":2}).ok and t.salir("interrumpir").ok,"inicia segundo viaje con provisiones reales")
 var o: Dictionary=t.datos().operaciones.interrumpir
 var q: Array=o.ruta[1]
 var k:=M.clave(Vector2i(q[0],q[1]))
 var previo: Dictionary=j.d.mundo.constr.get(k,{}).duplicate(true)
 j.d.mundo.constr[k]={"t":"muro","dueno":"prueba"}
 j.d.min+=int(s.cfg.comida_min)
 t.actualizar()
 ok(o.estado=="detenida" and o.avance==0 and int(o.consumido)==1 and iguales(bienes,cantidades(s)),"ruta interrumpida detiene avance y descuenta comida de las provisiones")
 if previo.is_empty(): j.d.mundo.constr.erase(k)
 else: j.d.mundo.constr[k]=previo
 ok(t.regresar("interrumpir") and o.estado!="entregada" and iguales(ids,identidades(s)),"cancelar en ruta prepara regreso; no teletransporta personas ni bienes")
 j.d.min+=int(o.duracion)
 t.actualizar()
 ok(o.estado=="entregada" and iguales(bienes,cantidades(s)) and iguales(ids,identidades(s)),"regreso tras interrupción devuelve garantías y mantiene consumo irreversible")
 var srv=Srv.new();srv.j=j
 var cli=Cli.new();cli._bienvenida(srv.estado_para(J.LOCAL))
 var replica:=JSON.stringify(cli.j.d)
 cli.j.autonomia.asentamientos.transitos.actualizar()
 ok(replica==JSON.stringify(cli.j.d) and iguales(cli.j.autonomia.asentamientos.transitos.datos(),t.datos()),"réplica recibe tránsito e historial sin ejecutar viajes")
 cli.free();srv.free()
 print("TRANSITOS: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
