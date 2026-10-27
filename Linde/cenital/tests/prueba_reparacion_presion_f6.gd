extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
var total:=0
var fallos:=0
func ok(v: bool,txt: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+txt)
func _init()->void:
 var j=J.nueva(123,"Reparacion",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 s.transitos.datos().politica.comercio_autonomo=false
 var p: Dictionary=s.datos().puestos.values()[0]
 var inv: Dictionary=s.inventario(p)
 inv.madera=20;inv.fibra=20
 var cama: Array=p.camas[0]
 var k:=M.clave(Vector2i(cama[0],cama[1]))
 j.d.mundo.techos.erase(k);j.mundo.cambiar()
 ok(not s._sostenible(p),"falta real de techo impide sostener la vivienda")
 j.d.min+=int(s.cfg.produccion_min)
 var antes: Dictionary=inv.duplicate(true)
 var reparador: String=s.reparar_local(p)
 var conserva:=true
 for item in C.CONSTR.techo.coste:
  conserva=conserva and int(inv.get(item,0))==int(antes.get(item,0))-int(C.CONSTR.techo.coste[item])
 ok(reparador!="" and s._sostenible(p) and conserva,"residente repara infraestructura propia con el coste exacto existente")
 ok(s.economia_regional(p).resultados.back().causa=="reparacion_local","reparación local deja causa y gasto persistente")
 var serializado:=JSON.stringify(inv)
 ok(s.reparar_local(p)=="" and JSON.stringify(inv)==serializado,"no se repite ni cobra dos veces una reparación")
 var eid: String=p.edificios[0]
 var e: Dictionary=j.d.mundo.registro.edificios[eid]
 ok(not j.reparar_edificio(eid,int(e.revision)).ok,"jugador no puede usar la reparación común sobre propiedad ajena")
 # Fixture de propiedad del jugador para comprobar la misma vía material compartida.
 e.dueno=J.LOCAL
 j.d.mundo.techos.erase(k);j.mundo.cambiar()
 j.pies=M.pies_de_celda(Vector2i(e.entrada[0],e.entrada[1]))
 j.mundo.actualizar_regiones([Vector2i(e.entrada[0],e.entrada[1])])
 j.jug().inv=C.CONSTR.techo.coste.duplicate(true)
 ok(j.reparar_edificio(eid,int(e.revision)).ok and j.jug().inv.is_empty() and j.d.mundo.techos.has(k),"reparación del jugador conserva validación y cobra su inventario, no el del poblado")
 e.dueno=p.dueno
 inv.erase("baya")
 s.actualizar_demandas()
 ok(p.presiones.has("comida") and p.presiones.comida.duracion_min==0,"se registra una presión real sin convertirla automáticamente en crisis")
 var desde: int=p.presiones.comida.desde
 j.d.min+=int(s.cfg.comida_min)
 s.actualizar_demandas()
 ok(p.presiones.comida.desde==desde and p.presiones.comida.duracion_min==int(s.cfg.comida_min),"presión persistente conserva origen y mide su duración real")
 var archivo:="/tmp/linde-presion-f6-%d.json" % OS.get_process_id()
 ok(j.guardar(archivo),"guarda presión y reparación")
 var carga=J.cargar(archivo)
 ok(carga!=null and carga.autonomia.asentamientos.datos().puestos[p.id].presiones.comida.desde==desde,"reinicio conserva la presión sin reiniciar su reloj")
 inv.baya=int(s.balance_resumido(p).baya.reserva)
 s.actualizar_demandas()
 ok(not p.presiones.has("comida"),"cobertura material real elimina presión sin crear una crisis programada")
 # Infraestructura que faltó durante muchos periodos no habilita producción retroactiva al repararse.
 var otro=J.nueva(456,"Presupuesto",[0,0,0],"poblado")
 var sistema=otro.autonomia.asentamientos
 sistema.transitos.datos().politica.comercio_autonomo=false
 var casa: Dictionary=sistema.datos().puestos.values()[0]
 sistema.inventario(casa).madera=20;sistema.inventario(casa).fibra=20
 var q: Array=casa.camas[0]
 otro.d.mundo.techos.erase(M.clave(Vector2i(q[0],q[1])))
 otro.d.min+=24*int(sistema.cfg.produccion_min)
 sistema.actualizar()
 ok(sistema._sostenible(casa) and int(casa.producciones)<=1,"reparar ahora no crea producción de periodos sin infraestructura")
 print("REPARACION_PRESION_F6: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
