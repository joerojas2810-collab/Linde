extends SceneTree
const M=preload("res://scripts/mundo.gd")
const J=preload("res://scripts/juego.gd")
var total:=0
var fallos:=0
func ok(v: bool,t: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func _init()->void:
 var j=J.nueva(123,"Crisis",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 s.transitos.datos().politica.comercio_autonomo=false
 var puestos: Array=s.datos().puestos.values()
 var p: Dictionary=puestos[0]
 var b: Dictionary=puestos[1]
 var ausente: Dictionary=b.residentes.pop_back()
 s.transitos._sincronizar(b)
 s.inventario(b).baya=20
 s.inventario(p).erase("baya")
 s.actualizar_demandas()
 j.d.min+=int(s.cfg.comida_min)
 # Fixture de consumo ya ejecutado, sin deuda: la presión por falta de alimento de trabajo persiste.
 p.comida_min=int(j.d.min)
 for r in p.residentes: r.comida_min=int(j.d.min)
 s.actualizar_demandas()
 ok(not p.has("crisis") and p.residentes.size()==2,"temporizador por sí solo no ordena migración")
 p.local_min=int(j.d.min);p.comercio_intento_min=int(j.d.min)
 var camino: Array=s.transitos.ruta(p.id,b.id)
 ok(not camino.is_empty() and s.ruta_sin_amenaza_conocida(camino),"ruta real sin amenaza confirmada admite seguridad desconocida")
 var enemigos: Array=j.combate.enemigos.duplicate()
 var punto: Array=camino[0]
 j.combate.enemigos=[{"tipo":"slime","est":"libre","pos":M.pies_de_celda(Vector2i(punto[0],punto[1]))}]
 ok(not s.ruta_sin_amenaza_conocida(camino),"amenaza hostil conocida usa alcance vigente y bloquea esa ruta")
 j.combate.enemigos[0].tipo="arpia_pradera"
 ok(s.ruta_sin_amenaza_conocida(camino),"criatura huidiza no se confunde con amenaza hostil")
 j.combate.enemigos=enemigos
 var cantidad: int =p.residentes.size()+b.residentes.size()
 s.resolver_crisis(p)
 ok(p.crisis.estado=="migracion_en_curso" and p.residentes.size()==1,"crisis elige una plaza viable con mejora material")
 var op: Dictionary=s.transitos.datos().operaciones[p.crisis.operacion]
 ok(p.residentes.size()+b.residentes.size()+op.miembros.size()==cantidad and ausente.id not in op.ids,"conserva identidades existentes sin población de reemplazo")
 ok(not s.abandono_fisico(b),"destino con viajeros no se abandona")
 var archivo:="/tmp/linde-crisis-%d.json" % OS.get_process_id()
 ok(j.guardar(archivo),"guarda decisión y trayecto")
 var carga=J.cargar(archivo)
 ok(carga.autonomia.asentamientos.datos().puestos[p.id].crisis.operacion==op.id,"reinicio conserva causalidad y operación única")
 j.d.min+=int(op.duracion)
 s.transitos.actualizar()
 ok(op.estado=="entregada" and b.residentes.size()==2,"llegada real ocupa cama sin duplicar residentes")
 # Vaciar solo el fixture conserva fuera del sistema a los sujetos retirados.
 var retirados: Array=p.residentes.duplicate();p.residentes.clear()
 var antes:=JSON.stringify(s.inventario(p))
 s.resolver_crisis(p)
 ok(p.estado=="abandonado" and j.mundo.poblado(p.poblado).estado=="abandonado" and JSON.stringify(s.inventario(p))==antes and not retirados.is_empty(),"abandono conserva inventario, propiedad y registro")
 # El mismo residente retorna con sus derechos originales; no se concede propiedad al poblado receptor.
 var titular: Dictionary=b.residentes.back()
 var cama: Array=p.camas[0]
 var C=load("res://scripts/catalogos.gd")
 var techo: String=M.clave(Vector2i(cama[0],cama[1]))
 j.d.mundo.techos.erase(techo);j.mundo.cambiar()
 var pago: Dictionary=C.CONSTR.techo.coste.duplicate(true)
 for item in pago: s.inventario(b)[item]=int(s.inventario(b).get(item,0))+int(pago[item])
 var denegada: Dictionary=s.transitos.reservar("ajeno",b.id,p.id,[b.residentes[0].id],pago,{},"recuperacion")
 ok(not denegada.ok and denegada.motivo=="sin_derechos_originales","terceros no adquieren derechos de un sitio abandonado")
 s.actualizar() # Liquida el consumo vencido real del origen antes de reservar otro viaje.
 var retorno: Dictionary=s.transitos.reservar("recuperar",b.id,p.id,[titular.id],pago,{"baya":2},"recuperacion")
 ok(retorno.ok and s.transitos.salir("recuperar").ok and not j.d.mundo.techos.has(techo),"recuperación reserva materiales sin reparar a distancia")
 var viaje: Dictionary=retorno.operacion
 j.d.min+=int(viaje.duracion)
 s.transitos.actualizar()
 ok(viaje.estado=="entregada" and p.residentes[0].id==titular.id and s._sostenible(p) and viaje.bienes.is_empty(),"propietario original llega y paga reparación real antes de recuperar el sitio")
 var final: String=JSON.stringify(s.inventario(p))
 s.transitos.actualizar()
 ok(JSON.stringify(s.inventario(p))==final and p.residentes.size()==1,"repetición no duplica reparación, carga ni identidad")
 print("CRISIS_F6: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
