extends SceneTree
## Propuesta B solo para QA: no se carga desde el juego ni cambia distribuciones guardadas.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const L=preload("res://scripts/lugares.gd")
const H=preload("res://scripts/huella.gd")
func humano(ctx:Dictionary) -> bool:return ctx.en_ruta or not ctx.nucleos_1e.is_empty() or not ctx.poblados.is_empty()
func propuesta(j,r:Vector2i) -> Dictionary:
 var f=j.combate.fauna;var base:Dictionary=f.plan_region(r);var result=base.duplicate(true)
 if base.is_empty():return result
 result.ancla="";result.sin_alternativa=false;result.pospuesto=false
 var conducta=f.habitat_en(base.celda).conducta
 if not conducta in ["hostil","territorial"]:return result
 var registro:Dictionary=j.d.mundo.registro;var ids=registro.lugares.keys();ids.sort();var ancla={}
 for id in ids:
  var lugar:Dictionary=registro.lugares[id]
  if conducta=="hostil" and lugar.tipo in ["ruinas","cueva"] and M.Terreno.region(Vector2i(lugar.centro[0],lugar.centro[1]))==r:ancla=lugar;break
 if ancla.is_empty() and not humano(f.contexto_territorial(base.celda)):return result
 var candidatos=[];var preferidos=[]
 for i in 64:
  var c:Vector2i=f.candidata_region(r,i)
  if M.Terreno.distancia_valle(c)<int(f.cfg.distancia_valle):continue
  var h:Dictionary=f.habitat_en(c)
  if h.get("tipo","")!=base.tipo or h.get("bioma","")!=base.bioma:continue
  if humano(f.contexto_territorial(c)):continue
  candidatos.append(c)
  if f.cumple_preferencia(c,base.tipo,f.distribucion.preferencias):preferidos.append(c)
 if candidatos.is_empty():result.sin_alternativa=true;result.pospuesto=true;return result
 var elegibles=preferidos if not preferidos.is_empty() else candidatos
 result.celda=elegibles[0]
 if not ancla.is_empty():
  var mejor=2147483647
  for c in elegibles:
   var d=absi(c.x-int(ancla.entrada[0]))+absi(c.y-int(ancla.entrada[1]))
   if d<mejor:result.celda=c;mejor=d
  result.ancla=ancla.id
 return result
func _init():
 var casos=[];var fallos=0;var salida=OS.get_cmdline_user_args()[0]
 for seed in [123,456,789]:
  var j=J.nueva(seed,"Propuesta B",[0,0,0],M.MODO_POBLADO);var antes=H.hash_de(j.d);var cargadas=j.mundo.regiones.size()
  var puntos=[];var macros=j.d.mundo.registro.macros.keys();macros.sort();var validos=true;var originales=0;var movidos=0;var anclas=0;var pendientes=0;var conflictos_antes=0;var conflictos_despues=0
  var tam=int(L.datos().macro_celdas)/16
  for macro in macros:
   var m=Vector2i(int(macro.get_slice(",",0)),int(macro.get_slice(",",1)))
   for y in range(m.y*tam,(m.y+1)*tam):
    for x in range(m.x*tam,(m.x+1)*tam):
     var r=Vector2i(x,y);var base:Dictionary=j.combate.fauna.plan_region(r);var p=propuesta(j,r)
     if base.is_empty():validos=validos and p.is_empty();continue
     originales+=1;movidos+=int(base.celda!=p.celda);anclas+=int(p.ancla!="");pendientes+=int(p.sin_alternativa)
     var conducta=j.combate.fauna.habitat_en(p.celda).conducta
     if conducta in ["hostil","territorial"]:
      conflictos_antes+=int(humano(j.combate.fauna.contexto_territorial(base.celda)))
      conflictos_despues+=int(humano(j.combate.fauna.contexto_territorial(p.celda)))
     validos=validos and base.id==p.id and base.tipo==p.tipo and base.bioma==p.bioma and M.Terreno.region(p.celda)==r
     if p.ancla!="":validos=validos and j.d.mundo.registro.lugares.has(p.ancla)
     puntos.append({"id":p.id,"tipo":p.tipo,"conducta":conducta,"antes":[base.celda.x,base.celda.y],"despues":[p.celda.x,p.celda.y],"ancla":p.ancla,"sin_alternativa":p.sin_alternativa,"pospuesto":p.pospuesto})
  var inversos=true
  for i in range(puntos.size()-1,-1,-1):
   var p:Dictionary=puntos[i];var r=M.Terreno.region(Vector2i(p.antes[0],p.antes[1]));var repetido=propuesta(j,r)
   inversos=inversos and repetido.celda==Vector2i(p.despues[0],p.despues[1]) and repetido.ancla==p.ancla
  var puro=antes==H.hash_de(j.d) and cargadas==j.mundo.regiones.size()
  if not validos or not inversos or not puro:fallos+=1
  casos.append({"semilla":seed,"fauna":originales,"movidos":movidos,"anclas":anclas,"sin_alternativa":pendientes,"conflictos_antes":conflictos_antes,"conflictos_despues":conflictos_despues,"invariantes":validos,"orden_inverso":inversos,"consulta_pura":puro,"puntos":puntos,"registro":{"rutas":j.d.mundo.registro.rutas,"lugares":j.d.mundo.registro.lugares,"poblados":j.d.mundo.poblados,"macros":macros}})
  print(("PASS " if validos and inversos and puro else "FAIL ")+"propuesta B conserva población/identidad y fuentes registradas, semilla "+str(seed))
 # Caso límite sintético: las 64 candidatas cubiertas por una ruta registrada.
 var borde=J.nueva(123,"Sin alternativa",[0,0,0],M.MODO_POBLADO)
 var hostil:Dictionary=casos[0].puntos.filter(func(p):return p.conducta=="hostil")[0]
 var r=M.Terreno.region(Vector2i(hostil.antes[0],hostil.antes[1]));var cubiertas=[]
 for i in 64:
  var c=borde.combate.fauna.candidata_region(r,i);cubiertas.append([c.x,c.y])
 borde.d.mundo.registro.rutas["qa_cobertura"]={"celdas":cubiertas}
 var aplazado=propuesta(borde,r);var limite=not aplazado.is_empty() and aplazado.pospuesto
 if not limite:fallos+=1
 print(("PASS " if limite else "FAIL ")+"sin ubicación compatible la propuesta pospone, no inventa población ni invade ruta")
 var f=FileAccess.open(salida,FileAccess.WRITE);f.store_string(JSON.stringify({"activada":false,"radio_propuesto":M.NUCLEO_RADIO,"sin_alternativa_verificado":limite,"casos":casos},"  "));f.close();quit(1 if fallos else 0)
