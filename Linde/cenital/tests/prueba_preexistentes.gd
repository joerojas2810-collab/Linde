extends SceneTree
## Fase 5a: génesis, economía regional real, identidad y persistencia, sin población detallada duplicada.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const H = preload("res://scripts/huella.gd")
var fallos := 0
func ok(c: bool, t: String) -> void:
 print(("PASS " if c else "FAIL ") + t)
 if not c: fallos += 1
func resumen(j) -> String:
 return H.hash_de([j.autonomia.asentamientos.datos(),j.d.cofres,j.d.mundo.rotos,j.d.mundo.constr,j.d.mundo.poblados,j.d.mundo.registro,j.d.mundo.techos])
func avanzar(j, horas: int) -> void:
 for h in horas:
  j.d.min += 60
  j.mundo.regenerar(int(j.d.min),j.ocupada)
  j.autonomia.asentamientos.actualizar()
func _init() -> void:
 var cantidad := 20 if "--extenso" in OS.get_cmdline_user_args() or OS.get_environment("LINDE_VALIDACION_COMPLETA")=="1" else 2
 var estable := true
 var transitables := true
 var edificios_validos := true
 for semilla in cantidad:
  var j = J.nueva(semilla,"Exploradora",[0,0,0],"poblado")
  var ids: Array = j.autonomia.asentamientos.datos().preexistentes.ids
  estable = estable and ids.size() == 2
  var original: String = resumen(j)
  for pid in ids:
   var p: Dictionary = j.mundo.poblado(pid)
   var lugar: Dictionary = j.d.mundo.registro.lugares[pid]
   var puesto: Dictionary=j.autonomia.asentamientos.datos().puestos[p.puesto]
   var e: Dictionary=j.d.mundo.registro.edificios[puesto.edificios[0]]
   j.mundo.actualizar_regiones([Vector2i(p.centro[0],p.centro[1])])
   edificios_validos = edificios_validos and J.Edificios.accesible(j,e) and J.Edificios.coste(J.Edificios.faltantes(j,e)).is_empty()
   for actor in j.autonomia.asentamientos.visibles():
    edificios_validos = edificios_validos and not j.mundo.bloquea(M.celda_de(actor.pos))
   edificios_validos = edificios_validos and puesto.camas.size()==2 and puesto.campos.size()==2 and j.d.cofres[puesto.cofre].inv=={"baya":4,"hacha_piedra":1,"pico_piedra":1}
   for q in j.d.mundo.registro.rutas[lugar.ruta].celdas:
    var c := Vector2i(q[0],q[1])
    j.mundo.actualizar_regiones([c])
    if j.mundo.bloquea(c) or not j.mundo.caja_libre(M.pies_de_celda(c)): transitables=false
   estable = estable and p.residentes.size()==2 and p.residentes.all(func(n):return not j.habitantes.ids.has(n))
  j.autonomia.asentamientos.inicializar_preexistentes()
  j.mundo.actualizar_regiones([Vector2i(900,900)])
  j.actualizar_regiones()
  estable = estable and resumen(j)==original
 ok(estable,"%d semillas: dos comunidades estables, residentes propios y ninguna regeneración al volver" % cantidad)
 ok(edificios_validos,"casas comunales completas: accesos y servicios transitables, residentes fuera de colisiones y mismas reservas iniciales")
 ok(transitables,"rutas conectadas al cruce del terreno y transitables con colisión real")
 var j = J.nueva(123,"Observadora",[0,0,0],"poblado")
 var otra = J.nueva(123,"Observadora",[0,0,0],"poblado")
 j.Lugares.ampliar(j,Vector2i(3,0));j.Lugares.ampliar(j,Vector2i(-2,1))
 otra.Lugares.ampliar(otra,Vector2i(-2,1));otra.Lugares.ampliar(otra,Vector2i(3,0))
 ok(resumen(j)==resumen(otra) and H.hash_de(j.d.mundo.registro)==H.hash_de(otra.d.mundo.registro),"orden de exploración independiente: mismas identidades, recursos y lugares")
 var inv_previo: Dictionary=j.jug().inv.duplicate(true)
 ok(not j.construir("casa_regional",M.celda_de(j.pies)+Vector2i.UP).ok and j.jug().inv==inv_previo,"la variante comunal de génesis no se ofrece ni construye como plano del jugador")
 var puestos: Dictionary = j.autonomia.asentamientos.datos().puestos
 var pid: String = j.autonomia.asentamientos.datos().preexistentes.ids[0]
 var p: Dictionary = j.mundo.poblado(pid)
 var puesto: Dictionary = puestos[p.puesto]
 var identidades: Array = puesto.residentes.duplicate(true)
 j.rt.clear();otra.rt.clear()
 avanzar(j,72)
 avanzar(otra,36)
 otra.guardar("/tmp/linde-preexistentes.json")
 var cargado = J.cargar("/tmp/linde-preexistentes.json")
 ok(cargado!=null and resumen(cargado)==resumen(otra),"guardar/cargar conserva exactamente población, reservas, herramientas y mundo")
 if cargado!=null:
  cargado.rt.clear()
  avanzar(cargado,36)
  ok(resumen(j)==resumen(cargado),"tres días sin jugadores: ejecución continua y reinicio intermedio equivalentes")
 ok(puesto.producciones>0 and int(j.d.cofres[puesto.cofre].inv.get("fibra",0))>0,"cosechas y extracción cambian las reservas sin jugadores")
 ok(j.d.mundo.rotos.size()>0 and puesto.residentes[0].usos<50,"producción consume recursos naturales y usos reales de herramientas")
 ok(puesto.residentes.map(func(r):return [r.id,r.nombre,r.oficio,r.historia])==identidades.map(func(r):return [r.id,r.nombre,r.oficio,r.historia]),"la actividad y el reinicio conservan identidad e historia")
 var reg = j.autonomia.asentamientos
 j.d.cofres[puesto.cofre].inv.clear()
 avanzar(j,1)
 ok(puesto.estado.contains("comida") and j.d.cofres[puesto.cofre].inv.is_empty(),"sin provisiones se detiene: no aparecen recursos de la nada")
 var cama_retirada := Vector2i(puesto.camas[0][0],puesto.camas[0][1])
 j.mundo.quitar(cama_retirada)
 reg.inicializar_preexistentes()
 ok(j.mundo.constr_en(cama_retirada).is_empty(),"volver o inicializar no reconstruye una cama retirada")
 # El Valle puede dejar de ser elegible sin impedir una entrada en otra comunidad existente.
 var entrada = J.nueva(123,"Entrada",[0,0,0],"poblado")
 entrada.mundo.poblado(M.ID_INICIAL).estado="abandonado"
 entrada.combate.enemigos.clear()
 var ap: Dictionary = entrada.punto_aparicion("visitante")
 ok(ap.ok and ap.poblado!=M.ID_INICIAL,"aparición segura en una comunidad adicional cuando el Valle no es elegible")
 var futuro: Dictionary = j.d.duplicate(true)
 futuro.mundo_vivo.autonomia.asentamientos.preexistentes.version=999
 ok(J.Guard.migrar(futuro).is_empty(),"una versión futura de génesis se rechaza explícitamente")
 var disponibles = J.nueva(123,"Puestos",[0,0,0],"poblado")
 var regiones = disponibles.autonomia.asentamientos
 ok(regiones.validar(Vector2i(3000,3000))!="Ya hay tres puestos regionales","las comunidades preexistentes no consumen el cupo de puestos del jugador")
 var legado = J.nueva(123,"Legado",[0,0,0])
 ok(not legado.autonomia.asentamientos.datos().has("preexistentes"),"legado no recibe comunidades adicionales")
 quit(1 if fallos else 0)
