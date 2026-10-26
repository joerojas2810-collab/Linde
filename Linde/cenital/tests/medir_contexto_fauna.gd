extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const H=preload("res://scripts/huella.gd")
const L=preload("res://scripts/lugares.gd")
func _init():
 var salida=OS.get_cmdline_user_args()[0];var casos=[];var errores=0
 for seed in [123,456,789]:
  var j=J.nueva(seed,"Medición",[0,0,0],M.MODO_POBLADO,2)
  var original=H.hash_de(j.d);var regiones=j.mundo.regiones.size()
  var consultas=0;var prueba_rutas=true;var prueba_lugares=true;var prueba_pueblos=true
  var f=j.combate.fauna
  for ruta in j.d.mundo.registro.rutas.values():
   for pos in [ruta.celdas[0],ruta.celdas[-1]]:
    var ctx=f.contexto_territorial(Vector2i(pos[0],pos[1]));consultas+=1
    prueba_rutas=prueba_rutas and ctx.en_ruta and ctx.distancia_ruta==0
  for lugar in j.d.mundo.registro.lugares.values():
   prueba_lugares=prueba_lugares and lugar.id in f.contexto_territorial(Vector2i(lugar.centro[0],lugar.centro[1])).lugares
  for pid in j.mundo.poblados_ids():
   var p=j.mundo.poblado(pid);var ctx=f.contexto_territorial(Vector2i(p.centro[0],p.centro[1]))
   prueba_pueblos=prueba_pueblos and pid in ctx.poblados and pid in ctx.nucleos_1e
  var puntos=[];var registros={};var hostiles=0;var sobre_ruta=0;var dentro_pueblo=0;var dentro_lugar=0;var nucleo=0
  var tam=int(L.datos().macro_celdas)/16
  var macros=j.d.mundo.registro.macros.keys();macros.sort()
  for macro in macros:
   var m=Vector2i(int(macro.get_slice(",",0)),int(macro.get_slice(",",1)))
   for y in range(m.y*tam,(m.y+1)*tam):
    for x in range(m.x*tam,(m.x+1)*tam):
     var r=Vector2i(x,y);var p:Dictionary=f.plan_region(r)
     if p.is_empty():continue
     var ctx=f.contexto_territorial(p.celda);var conducta=f.habitat_en(p.celda).conducta
     registros[M.clave(r)]=ctx
     if conducta=="hostil":
      hostiles+=1;sobre_ruta+=int(ctx.en_ruta);dentro_pueblo+=int(not ctx.poblados.is_empty());dentro_lugar+=int(not ctx.lugares.is_empty());nucleo+=int(not ctx.nucleos_1e.is_empty())
     puntos.append({"id":p.id,"celda":[p.celda.x,p.celda.y],"tipo":p.tipo,"conducta":conducta,"contexto":ctx})
  var persistencia=j.d.duplicate(true)
  # Guardar/cargar valida que el contexto provenga del registro persistente.
  var path=OS.get_cache_dir()+"/linde-contexto-%d-%d.json"%[OS.get_process_id(),seed];j.guardar(path);var rec=J.cargar(path)
  var restaurado=rec!=null
  if rec!=null:
   for k in registros:
    var p:Dictionary=f.plan_region(Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1))))
    restaurado=restaurado and H.canonico(rec.combate.fauna.contexto_territorial(p.celda))==H.canonico(registros[k])
  var puro=H.hash_de(persistencia)==original and regiones==j.mundo.regiones.size()
  var valido=prueba_rutas and prueba_lugares and prueba_pueblos and puro and restaurado
  if not valido:errores+=1
  casos.append({"semilla":seed,"macros":macros,"rutas":j.d.mundo.registro.rutas.size(),"lugares":j.d.mundo.registro.lugares.size(),"poblados":j.mundo.poblados_ids().size(),"fauna":puntos.size(),"hostiles":hostiles,"hostiles_sobre_ruta":sobre_ruta,"hostiles_dentro_poblado":dentro_pueblo,"hostiles_dentro_lugar":dentro_lugar,"hostiles_nucleo_1e":nucleo,"rutas_verificadas":prueba_rutas,"lugares_verificados":prueba_lugares,"poblados_verificados":prueba_pueblos,"consulta_pura":puro,"persistencia":restaurado,"puntos":puntos})
  print(("PASS " if valido else "FAIL ")+"contexto registrado, consulta pura y persistencia semilla "+str(seed))
 var legado=J.nueva(123,"Legado",[0,0,0]);var p:Dictionary=legado.mundo.poblado(M.ID_INICIAL)
 var sin_nucleo=legado.combate.fauna.contexto_territorial(Vector2i(p.centro[0],p.centro[1])).nucleos_1e.is_empty()
 if not sin_nucleo:errores+=1
 print(("PASS " if sin_nucleo else "FAIL ")+"contexto no atribuye política 1e al modo legado")
 var f=FileAccess.open(salida,FileAccess.WRITE);f.store_string(JSON.stringify({"activacion_nueva":false,"legado_sin_nucleo":sin_nucleo,"casos":casos},"  "));f.close();quit(1 if errores else 0)
