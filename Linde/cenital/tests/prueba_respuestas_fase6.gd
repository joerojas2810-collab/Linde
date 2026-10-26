extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var total:=0
var fallos:=0
func ok(v: bool,txt: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+txt)
func _init()->void:
 var j=J.nueva(123,"Locales",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 s.transitos.datos().politica.comercio_autonomo=false
 var p: Dictionary=s.datos().puestos.values()[0]
 var inv: Dictionary=s.inventario(p)
 var actor: Dictionary=p.residentes[0]
 inv.clear();inv.merge({"baya":4,"madera":2,"piedra":2,"fibra":1})
 p.produccion_min=int(j.d.min)-int(s.cfg.produccion_min)
 var antes:=JSON.stringify(inv)
 var intento: Dictionary=s.resolver_local(p)
 ok(intento.is_empty() and JSON.stringify(inv)==antes,"oficio por sí solo no inventa recetas ni fabrica una herramienta")
 # La receta explícita del escenario representa conocimiento adquirido antes de la operación.
 actor.recetas=["hacha_piedra"]
 p.local_min=-1
 var usados: Dictionary=s.resolver_local(p)
 ok(usados.has(actor.id) and int(inv.get("hacha_piedra",0))==1 and not inv.has("fibra") and not inv.has("madera") and not inv.has("piedra"),"fabricación local usa saber explícito y consume receta real exactamente")
 ok(s.economia_regional(p).resultados.back().causa=="fabricacion_local","fabricación local deja resultado causal con actor")
 ok(s.resolver_local(p).is_empty() and int(inv.get("hacha_piedra",0))==1,"mismo presupuesto de trabajo no fabrica dos veces en el minuto")
 var viabilidad: Dictionary=s.evaluar_viabilidad(p)
 ok(viabilidad.residentes==2 and viabilidad.camas==2 and viabilidad.politica_crisis=="pendiente_aprobacion","viabilidad informa hechos sin convertir umbrales no aprobados en política")
 # No hay reemplazos por calendario: se vacía el escenario sin generar habitantes nuevos.
 var retirados: Array=p.residentes.duplicate(true)
 p.residentes.clear();s.transitos._sincronizar(p)
 j.d.min+=int(s.cfg.llegada_min)+1
 s.actualizar()
 ok(p.residentes.is_empty() and retirados.size()==2 and j.mundo.poblado(p.poblado).estado=="sin_residentes","asentamiento vacío no genera colonos ni se reactiva por calendario")
 # Migración de identidad existente a una plaza real, con cursor alimentario propio.
 j=J.nueva(456,"Migracion",[0,0,0],"poblado")
 s=j.autonomia.asentamientos
 s.transitos.datos().politica.comercio_autonomo=false
 var lugares: Array=s.datos().puestos.values()
 var origen: Dictionary=lugares[0];var destino: Dictionary=lugares[1]
 # Se libera una plaza en el fixture; se conserva el registro del residente fuera de esta operación.
 var ausente: Dictionary=destino.residentes.pop_back()
 s.transitos._sincronizar(destino)
 var viajero: Dictionary=origen.residentes[0]
 var nid: String=viajero.id
 destino.comida_min=int(j.d.min)-int(s.cfg.comida_min)
 var resultado: Dictionary=s.transitos.reservar("migrar",origen.id,destino.id,[nid],{}, {"baya":1})
 ok(resultado.ok and not s.transitos.reservar("duplicar",origen.id,destino.id,[nid],{},{}).ok,"una identidad no reserva simultáneamente dos expediciones")
 ok(s.transitos.salir("migrar").ok and origen.residentes.size()==1,"migración saca la misma entidad del origen")
 var op: Dictionary=resultado.operacion
 var capacidad:=int(s.cfg.capacidad)
 s.cfg.capacidad=1
 j.d.min+=int(op.duracion)
 s.transitos.actualizar()
 ok(op.estado=="detenida" and op.miembros.size()==1 and destino.residentes.size()==1,"capacidad perdida antes de llegar mantiene la identidad en tránsito")
 s.cfg.capacidad=capacidad
 s.transitos.actualizar()
 ok(op.estado=="entregada" and destino.residentes.size()==2 and origen.residentes.size()==1 and ausente.id!=nid,"llegada mueve identidad una vez, sin reposición ficticia")
 var encontrado: Dictionary=s.residente(nid)
 ok(encontrado.id==nid and encontrado.hogar==destino.poblado and j.mundo.poblado(destino.poblado).camas.has(nid),"destino conserva ID, estado y asignación de cama real")
 var saldo: Dictionary=s.balance_resumido(destino)
 ok(int(saldo.baya.vencido)==1,"nuevo residente no paga consumo anterior a su llegada")
 s.transitos.actualizar()
 ok(destino.residentes.size()==2 and op.miembros.is_empty(),"repetir llegada no duplica al habitante")
 # Comercio autónomo causado por carencia actual, valoración y excedente reales.
 j=J.nueva(123,"Comercio",[0,0,0],"poblado")
 s=j.autonomia.asentamientos
 lugares=s.datos().puestos.values();origen=lugares[0];destino=lugares[1]
 s.inventario(origen).erase("hacha_piedra")
 s.inventario(origen).piedra=70;s.inventario(origen).baya=10
 s.inventario(destino).hacha_piedra=3
 ok(s.transitos.comerciar(origen) and s.transitos.datos().operaciones.size()==1,"carencia y excedente activan trueque con un mensajero existente")
 var demanda: Dictionary=s.balance_resumido(origen).hacha_piedra
 ok(int(demanda.en_curso)==1 and int(demanda.pendiente)==0 and int(demanda.stock)==0,"pedido comprometido cubre demanda sin convertirse en inventario")
 print("RESPUESTAS_F6: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
