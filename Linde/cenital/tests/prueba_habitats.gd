extends SceneTree
const J=preload("res://scripts/juego.gd")
const F=preload("res://scripts/fauna.gd")
const H=preload("res://scripts/huella.gd")
const G=preload("res://scripts/guardado.gd")
const Med=preload("res://tests/medir_habitats.gd")
const BASE="res://../../production/qa/evidence/mundo-1/fase-7/habitats/"
var total=0
var fallos=0
func ok(condicion:bool,nombre:String) -> void:
 total+=1
 if not condicion:fallos+=1
 print(("PASS " if condicion else "FAIL ")+nombre)
func _init() -> void:
 var reglas=JSON.parse_string(FileAccess.get_file_as_string("res://datos/fauna/reglas_v1.json"))
 var antes=H.hash_de(reglas.biomas)
 var perfiles=F.perfiles_habitat(reglas.biomas)
 ok(perfiles.size()==5 and F.validar_habitats(reglas.biomas).is_empty(),"cinco perfiles válidos desde las reglas existentes")
 ok(F.validar_habitats(perfiles).is_empty() and F.perfiles_habitat(perfiles)==perfiles,"sintaxis abreviada y explícita equivalentes")
 ok(antes==H.hash_de(reglas.biomas),"normalizar no modifica el catálogo de origen")
 ok(not F.validar_habitats({"desconocido":"slime"}).is_empty(),"rechaza biomas no definidos")
 ok(not F.validar_habitats({"bosque":"inventado"}).is_empty(),"rechaza especies inexistentes")
 ok(not F.validar_habitats({"bosque":{"tipo":"espectro_bosque","suelo":"agua"}}).is_empty(),"no incorpora nuevos sustratos sin decisión territorial")
 ok(not F.validar_habitats({"bosque":{"tipo":"espectro_bosque","peso":0.1}}).is_empty(),"no acepta ponderaciones ni condiciones silenciosamente ignoradas")
 var base=JSON.parse_string(FileAccess.get_file_as_string(BASE+"base_distribucion.json"))
 ok(H.huella()==base.huella,"huella de reglas idéntica: no evade el sello de guardados/red")
 for previo in base.casos:
  var normal=Med.caso(int(previo.semilla),int(previo.generador))
  var inverso=Med.caso(int(previo.semilla),int(previo.generador),true)
  var iguales=true
  # El fixture precede a la economía regional integrada desde main (asentamientos,
  # transitos, sociedad). Su hash de TODO j.d no es un contrato de hábitats.
  # Conservamos exactos terreno, planes, ocupación y especies; exigimos además
  # igualdad del estado actual entre órdenes y consulta sin efectos secundarios.
  for k in ["planes_sha256","terreno_sha256","ocupadas","especies"]:
   # JSON lee cantidades como float; el canon de reglas equipara 1 y 1.0.
   var base_igual=H.canonico(normal[k])==H.canonico(previo[k])
   var orden_igual=H.canonico(normal[k])==H.canonico(inverso[k])
   if not base_igual or not orden_igual:
    print("DIFERENCIA semilla=%d generador=%d campo=%s base=%s normal=%s inverso=%s"%[int(previo.semilla),int(previo.generador),k,H.canonico(previo[k]),H.canonico(normal[k]),H.canonico(inverso[k])])
   iguales=iguales and base_igual and orden_igual
  ok(iguales,"semilla %d/v%d: distribución exacta anterior, reinicio y orden inverso"%[int(previo.semilla),int(previo.generador)])
  ok(normal.estado_sha256==inverso.estado_sha256,"estado completo actual reproducible con orden inverso %d/v%d"%[int(previo.semilla),int(previo.generador)])
  ok(normal.compatibles and inverso.compatibles and normal.consulta_pura and inverso.consulta_pura,"hábitats compatibles y lectura pura %d/v%d"%[int(previo.semilla),int(previo.generador)])
 var cargado=J.cargar(BASE+"guardado_previo.json")
 ok(cargado!=null,"carga guardado creado antes del cambio sin excepción de reglas")
 if cargado!=null:
  ok(cargado.jug().inv.get("madera")==7 and cargado.jug().xp==31 and cargado.d.fauna.bajas.get("fauna_v1@-13,-16")==1080,"conserva inventario, progreso y baja preexistentes")
  var ruta=OS.get_cache_dir()+"/linde-habitats-%d.json"%OS.get_process_id()
  ok(cargado.guardar(ruta) and not G.cargar(ruta).d.get("reglas",{}).get("contaminado",false),"nuevo guardado mantiene sello limpio")
 print("HABITATS: %d comprobaciones, %d fallos"%[total,fallos]);quit(1 if fallos else 0)
