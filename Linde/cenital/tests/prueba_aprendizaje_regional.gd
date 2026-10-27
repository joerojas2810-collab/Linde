extends SceneTree
const J=preload("res://scripts/juego.gd")
var total:=0
var fallos:=0
func ok(v: bool,t: String)->void:
 total+=1
 if not v: fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func _init()->void:
 var j=J.nueva(123,"Aprender",[0,0,0],"poblado")
 var s=j.autonomia.asentamientos
 var p: Dictionary=s.datos().puestos.values()[0]
 var d=j.autonomia.desarrollo
 var maestro: Dictionary=p.residentes[0]
 var alumno: Dictionary=p.residentes[1]
 s.inventario(p).baya=10
 d.ensenar_regional(p,{})
 ok(alumno.get("recetas",[]).is_empty(),"oficio y cofre no conceden conocimiento")
 maestro.recetas=["pico_piedra"]
 var usados: Dictionary={}
 d.ensenar_regional(p,usados)
 ok(usados.has(maestro.id) and usados.has(alumno.id) and alumno.get("recetas",[]).is_empty(),"lección ocupa maestro y alumno sin aprendizaje instantáneo")
 d.ensenar_regional(p,{})
 ok(alumno.get("recetas",[]).is_empty(),"repetir minuto no adelanta enseñanza")
 j.d.min+=int(d.sab.ensenanza.paso_max_min)
 d.ensenar_regional(p,{})
 var ruta:="/tmp/linde-aprendizaje-%d.json" % OS.get_process_id()
 ok(j.guardar(ruta),"guarda avance parcial")
 j=J.cargar(ruta);s=j.autonomia.asentamientos;d=j.autonomia.desarrollo;p=s.datos().puestos[p.id]
 alumno=p.residentes[1];maestro=p.residentes[0]
 j.d.min+=int(d.sab.ensenanza.minutos)-int(d.sab.ensenanza.paso_max_min)
 d.ensenar_regional(p,{})
 ok(alumno.recetas==["pico_piedra"] and alumno.aprendizajes.pico_piedra.maestro==maestro.id,"enseñanza real persiste tiempo, receta y procedencia")
 d.ensenar_regional(p,{})
 ok(alumno.recetas.size()==1,"no duplica receta aprendida")
 var destino: Dictionary=s.datos().puestos.values()[1]
 var retirado: Dictionary=destino.residentes.pop_back()
 var r: Dictionary=s.transitos.reservar("aprendiz",p.id,destino.id,[alumno.id],{},{"baya":1})
 ok(r.ok and s.transitos.salir("aprendiz").ok and r.operacion.miembros[0].recetas==["pico_piedra"],"migración transporta el conocimiento en la misma identidad")
 j.d.min+=int(r.operacion.duracion);s.transitos.actualizar()
 ok(destino.residentes.back().aprendizajes.pico_piedra.maestro==maestro.id and retirado.id!=alumno.id,"destino conserva procedencia sin crear otro aprendiz")
 print("APRENDIZAJE_REGIONAL: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
