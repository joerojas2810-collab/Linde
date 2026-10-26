extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const L=preload("res://scripts/lugares.gd")
const F=preload("res://scripts/fauna.gd")
const H=preload("res://scripts/huella.gd")
const BASE="res://../../production/qa/evidence/mundo-1/fase-7/"
var total=0
var fallos=0
func ok(value:bool,text:String):
 total+=1
 if not value:fallos+=1
 print(("PASS " if value else "FAIL ")+text)
func ruta(n:String)->String:return OS.get_cache_dir()+"/linde-territorios-%d-%s.json"%[OS.get_process_id(),n]
func nuevo(seed:int=123):return J.nueva(seed,"Territorio",[0,0,0],M.MODO_POBLADO)
func _init():
 var propuesta=JSON.parse_string(FileAccess.get_file_as_string(BASE+"propuesta-b/propuesta.json"))
 var j=nuevo()
 ok(j!=null and j.d.fauna.distribucion.version==3 and F.territorios_validos(j.d.fauna),"mundo nuevo activa v3 con decisiones territoriales válidas")
 for caso in propuesta.casos:
  var juego=nuevo(int(caso.semilla));var f=juego.combate.fauna;var estado=H.hash_de(juego.d);var exacto=true;var seguros=true;var anclas=0
  for anterior in caso.puntos:
   var r=M.Terreno.region(Vector2i(anterior.antes[0],anterior.antes[1]));var p:Dictionary=f.plan_region(r)
   exacto=exacto and p.id==anterior.id and p.tipo==anterior.tipo and p.celda==Vector2i(anterior.despues[0],anterior.despues[1]) and p.ancla==anterior.ancla and p.pospuesto==anterior.pospuesto
   if p.ancla!="":anclas+=1;seguros=seguros and juego.d.mundo.registro.lugares.has(p.ancla)
   if f.habitat_en(p.celda).conducta in ["hostil","territorial"] and not p.pospuesto:
    var ctx=f.contexto_territorial(p.celda);seguros=seguros and not ctx.en_ruta and ctx.nucleos_1e.is_empty() and ctx.poblados.is_empty()
  ok(exacto and anclas==int(caso.anclas),"posiciones e IDs coinciden exactamente con B aprobada, semilla "+str(caso.semilla))
  ok(seguros and estado==H.hash_de(juego.d),"fuentes reales, nacimientos fuera de espacios humanos y lectura pura, semilla "+str(caso.semilla))
 var sellado=H.hash_de(j.d.fauna.territorios)
 j.guardar(ruta("original"));var rec=J.cargar(ruta("original"))
 ok(rec!=null and H.hash_de(rec.d.fauna.territorios)==sellado,"guardar y cargar conserva posiciones, anclas y ausencias planificadas")
 # Cambiar la geometría después no regenera la fauna ya registrada.
 var id_macro=j.d.fauna.territorios.keys()[0];var t:Dictionary=j.d.fauna.territorios[id_macro]
 var clave=t.regiones.keys().filter(func(k):return not t.regiones[k].is_empty())[0];var r=Vector2i(int(clave.get_slice(",",0)),int(clave.get_slice(",",1)))
 var antes=j.combate.fauna.plan_region(r);j.d.mundo.registro.rutas["qa_nueva_ruta"]={"celdas":[[antes.celda.x,antes.celda.y]]}
 j.combate.fauna.planes.clear();j.combate.fauna.registrar_territorios()
 ok(j.combate.fauna.plan_region(r)==antes and H.hash_de(j.d.fauna.territorios)==sellado,"obras posteriores no mueven ni vuelven a sembrar una población registrada")
 var a=nuevo();var b=nuevo();var macros=[Vector2i(-1,-1),Vector2i(2,1)]
 for m in macros:L.ampliar(a,m);a.combate.fauna.registrar_territorios()
 macros.reverse()
 for m in macros:L.ampliar(b,m);b.combate.fauna.registrar_territorios()
 ok(H.hash_de(a.d.fauna.territorios)==H.hash_de(b.d.fauna.territorios),"expansión inversa de macrorregiones produce las mismas decisiones durables")
 var extra=Vector2i(-2,1);var encontrada=false;var objetivo=Vector2i.ZERO
 for y in range(extra.y*6,(extra.y+1)*6):
  for x in range(extra.x*6,(extra.x+1)*6):
   var candidato=Vector2i(x,y)
   if not encontrada and not a.combate.fauna.plan_base_region(candidato).is_empty():encontrada=true;objetivo=candidato
 ok(encontrada and a.combate.fauna.plan_region(objetivo).is_empty(),"consultar territorio desconocido no genera lugares ni población")
 L.ampliar(a,extra);a.combate.fauna.registrar_territorios()
 ok(not a.combate.fauna.plan_region(objetivo).is_empty(),"registrar un territorio invalida su anterior caché vacía")
 a.guardar(ruta("expansion"));var vuelto=J.cargar(ruta("expansion"))
 ok(vuelto!=null and H.hash_de(vuelto.d.fauna.territorios)==H.hash_de(a.d.fauna.territorios),"nuevas regiones mantienen su decisión al reiniciar")
 # Fixture v2 sin población territorial congelada: no migra al cargar.
 var v2=J.nueva(123,"Anterior v2",[0,0,0],M.MODO_POBLADO,2);v2.guardar(ruta("v2"));var viejo=J.cargar(ruta("v2"))
 ok(viejo!=null and viejo.d.fauna.distribucion.version==2 and not viejo.d.fauna.has("territorios"),"mundos v2 permanecen v2 sin añadir ni mover territorios")
 # Sin alternativa: cubrir candidatas de una especie agresiva antes de registrar.
 var borde=J.nueva(123,"Límite",[0,0,0],M.MODO_POBLADO,2)
 var hostil:Dictionary=propuesta.casos[0].puntos.filter(func(p):return p.conducta=="hostil")[0]
 var region=M.Terreno.region(Vector2i(hostil.antes[0],hostil.antes[1]));var cubiertas=[]
 for i in 64:
  var c=borde.combate.fauna.candidata_region(region,i);cubiertas.append([c.x,c.y])
 borde.d.mundo.registro.rutas["qa_cubiertas"]={"celdas":cubiertas};borde.d.fauna.distribucion=F.politica_inicial(3)
 borde.combate.fauna=F.new(borde.combate);borde.combate.fauna.registrar_territorios();var pendiente:Dictionary=borde.combate.fauna.plan_region(region)
 ok(pendiente.pospuesto and pendiente.id==hostil.id,"sin alternativa conserva la identidad nominal y pospone el nacimiento")
 borde.pies=M.pies_de_celda(pendiente.celda+Vector2i(10,0));borde.actualizar_regiones();borde.combate.fauna.actualizar()
 ok(not borde.combate.enemigos.any(func(e):return e.get("fauna_id","")==pendiente.id),"punto pospuesto no materializa una criatura ni ocupa el cupo activo")
 borde.guardar(ruta("pospuesto"));var pendiente_rec=J.cargar(ruta("pospuesto"))
 ok(pendiente_rec!=null and pendiente_rec.combate.fauna.plan_region(region).pospuesto,"reinicio no reactiva una aparición pospuesta")
 # Los datos corruptos no se reparan resembrando.
 rec.d.fauna.territorios[id_macro].regiones.erase(clave);rec.guardar(ruta("incompleto"))
 ok(J.cargar(ruta("incompleto"))==null and J.ultimo_error.get("error","")=="distribucion_fauna","territorio incompleto rechazado sin inventar reemplazos")
 print("TERRITORIOS: %d comprobaciones, %d fallos"%[total,fallos]);quit(1 if fallos else 0)
