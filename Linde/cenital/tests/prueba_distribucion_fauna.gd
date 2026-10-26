extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const H=preload("res://scripts/huella.gd")
const F=preload("res://scripts/fauna.gd")
const BASE="res://../../production/qa/evidence/mundo-1/fase-7/"
var total=0
var fallos=0
func ok(value:bool,text:String):
 total+=1
 if not value:fallos+=1
 print(("PASS " if value else "FAIL ")+text)
func ruta(nombre:String) -> String:return OS.get_cache_dir()+"/linde-fauna-v2-%d-%s.json"%[OS.get_process_id(),nombre]
func firma(j,inverso:bool=false) -> String:
 var planes={}
 var coords=[]
 for y in range(-14,15):
  for x in range(-14,15):coords.append(Vector2i(x,y))
 if inverso:coords.reverse()
 for r in coords:planes[M.clave(r)]=j.combate.fauna.plan_region(r)
 return H.hash_de(planes)
func viajar(j):
 j.pies=M.pies_de_celda(Vector2i(-200,-256));j.actualizar_regiones();j.combate.fauna.actualizar()
func _init():
 var aprobado=JSON.parse_string(FileAccess.get_file_as_string(BASE+"propuesta-ubicacion/resultados.json"))
 var j=J.nueva(123,"Muestra",[0,0,0],M.MODO_POBLADO,2)
 ok(j.d.fauna.distribucion.version==2 and F.distribucion_valida(j.d.fauna.distribucion),"mundo nuevo poblado activa la política aprobada v2")
 ok(not J.nueva(123,"Legado",[0,0,0]).d.fauna.has("distribucion"),"modo legado conserva generación anterior")
 var viejo=J.cargar(BASE+"habitats/guardado_previo.json")
 ok(viejo!=null and not viejo.d.fauna.has("distribucion") and viejo.jug().xp==31,"mundo previo mantiene v1 y su progreso")
 var antes=firma(viejo);viejo.guardar(ruta("anterior"));var otra=J.cargar(ruta("anterior"))
 ok(otra!=null and firma(otra,true)==antes and not otra.d.fauna.has("distribucion"),"guardar/reiniciar mundo anterior no migra sus puntos")
 for caso in aprobado.casos:
  var juego=J.nueva(int(caso.semilla),"Muestra",[0,0,0],M.MODO_POBLADO,2)
  var invariantes=true;var cuentas={};var movidos={};var estado=H.hash_de(juego.d)
  for y in range(-14,15):
   for x in range(-14,15):
    var r=Vector2i(x,y);var f=juego.combate.fauna;var base:Dictionary=f.plan_base_region(r);var p:Dictionary=f.plan_region(r)
    if base.is_empty():invariantes=invariantes and p.is_empty();continue
    invariantes=invariantes and p.id==base.id and p.tipo==base.tipo and p.bioma==base.bioma and M.Terreno.region(p.celda)==r
    cuentas[p.tipo]=int(cuentas.get(p.tipo,0))+1
    movidos[p.tipo]=int(movidos.get(p.tipo,0))+int(p.celda!=base.celda)
  for tipo in caso.especies:
   invariantes=invariantes and cuentas.get(tipo)==int(caso.especies[tipo].cantidad) and movidos.get(tipo)==int(caso.especies[tipo].movidos)
  ok(invariantes and estado==H.hash_de(juego.d),"v2 coincide con cantidades y movimientos aprobados, semilla "+str(caso.semilla))
 for ejemplo in aprobado.ejemplos.values():
  var e=J.nueva(int(ejemplo.semilla),"Ejemplo",[0,0,0],M.MODO_POBLADO,2)
  var r=Vector2i(ejemplo.region[0],ejemplo.region[1]);var p:Dictionary=e.combate.fauna.plan_region(r)
  ok(p.celda==r*16+Vector2i(ejemplo.despues[0],ejemplo.despues[1]),"posición activada coincide con la comparativa aprobada "+p.tipo)
 var f1=firma(j);j.guardar(ruta("nuevo"));var rec=J.cargar(ruta("nuevo"))
 ok(rec!=null and firma(rec,true)==f1 and H.canonico(rec.d.fauna.distribucion)==H.canonico(j.d.fauna.distribucion),"v2 persiste política y posiciones con orden inverso/reinicio")
 # La carga consume el snapshot del mundo, no el archivo por defecto del juego.
 var snapshot=j.d.fauna.distribucion.duplicate(true)
 for tipo in snapshot.preferencias:snapshot.preferencias[tipo]={"conservar_origen":true}
 j.d.fauna.distribucion=snapshot;j.guardar(ruta("snapshot"));var propio=J.cargar(ruta("snapshot"))
 var r=Vector2i(aprobado.ejemplos.espectro_bosque.region[0],aprobado.ejemplos.espectro_bosque.region[1])
 ok(propio!=null and propio.combate.fauna.plan_region(r)==propio.combate.fauna.plan_base_region(r),"cada mundo conserva sus preferencias sin depender de futuros valores por defecto")
 var invalido=j.d.duplicate(true);j.d.fauna.distribucion.version=99;j.guardar(ruta("invalido"))
 ok(J.cargar(ruta("invalido"))==null and J.ultimo_error.get("error","")=="distribucion_fauna" and J.mensaje_carga(J.ultimo_error).contains("compatible"),"política desconocida rechazada con mensaje compatible, sin volver silenciosamente a v1")
 j.d=invalido
 viajar(rec)
 var lista:Array=rec.combate.enemigos.filter(func(e):return e.has("fauna_id"))
 ok(not lista.is_empty() and lista.size()<=24,"v2 materializa fauna real bajo el techo existente")
 if not lista.is_empty():
  var e:Dictionary=lista[0];var id=e.fauna_id;rec.combate._danar(e,1);var hp=e.hp;var pos=e.pos
  rec.guardar(ruta("herido"));var herido=J.cargar(ruta("herido"));herido.combate.fauna.actualizar()
  var recuperados:Array=herido.combate.enemigos.filter(func(v):return v.get("fauna_id","")==id)
  ok(recuperados.size()==1 and recuperados[0].hp==hp and recuperados[0].pos==pos,"herida y posición v2 conservadas sin duplicación al reiniciar")
  if not recuperados.is_empty():
   herido.combate._danar(recuperados[0],999);herido.guardar(ruta("baja"));var baja=J.cargar(ruta("baja"));baja.combate.fauna.actualizar()
   ok(not baja.combate.enemigos.any(func(v):return v.get("fauna_id","")==id) and baja.d.fauna.bajas.has(id),"baja v2 no reaparece al cargar antes del plazo vigente")
 print("DISTRIBUCION: %d comprobaciones, %d fallos"%[total,fallos]);quit(1 if fallos else 0)
