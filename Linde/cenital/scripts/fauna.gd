extends RefCounted
## Encuentros regionales v1, separados del generador de terreno congelado.
## Un punto determinista por región; bajas y heridas durables, simulación solo en autoridad.
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var combate
var j
var cfg: Dictionary
var habitats: Dictionary
var distribucion: Dictionary
var planes := {}
var reloj := 0.0

func _init(c) -> void:
 combate = c
 j = c.j
 cfg = JSON.parse_string(FileAccess.get_file_as_string("res://datos/fauna/reglas_v1.json"))
 habitats = perfiles_habitat(cfg.biomas)
 for error in validar_habitats(cfg.biomas): push_error(error)
 restaurar()
 distribucion = j.d.fauna.get("distribucion", {}).duplicate(true)

## Política de generación copiada al mundo nuevo, no reglas globales de combate.
## Un guardado sin este campo conserva siempre la distribución v1.
static func politica_inicial() -> Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string("res://datos/fauna/habitats_v2.json"))

static func distribucion_valida(p) -> bool:
 if not p is Dictionary:return false
 if p.is_empty():return true
 if p.get("version",0)==1:return p.size()==1
 if p.get("version",0)!=2 or not p.get("preferencias") is Dictionary:return false
 var tipos=["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]
 if p.size()!=2 or p.preferencias.size()!=tipos.size():return false
 for tipo in tipos:
  var regla=p.preferencias.get(tipo)
  if not regla is Dictionary or regla.size()!=1:return false
  if regla.has("vecino_objeto"):
   if not regla.vecino_objeto is Array or regla.vecino_objeto.is_empty():return false
   for objeto in regla.vecino_objeto:
    if not objeto is String or not C.OBJETOS.has(objeto):return false
  elif regla.get("vecinos_despejados",false)!=true and regla.get("conservar_origen",false)!=true:return false
 return true

func cumple_preferencia(celda:Vector2i,tipo:String,preferencias:Dictionary) -> bool:
 var regla:Dictionary=preferencias[tipo]
 if regla.get("conservar_origen",false):return true
 var junto=false
 for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
  var d:Dictionary=j.mundo.generador.datos(celda+v)
  if regla.has("vecino_objeto") and str(d.objeto) in regla.vecino_objeto:junto=true
  if regla.get("vecinos_despejados",false) and (int(d.tipo)!=M.T.PASTO or str(d.objeto)!=""):return false
 return junto if regla.has("vecino_objeto") else true

## Misma población, especie, bioma y región; sin candidato preferido conserva el origen.
func plan_preferente(r:Vector2i,base:Dictionary,preferencias:Dictionary) -> Dictionary:
 var p=base.duplicate(true)
 if p.is_empty() or cumple_preferencia(p.celda,p.tipo,preferencias):return p
 for i in 64:
  var celda=candidata_region(r,i)
  if M.Terreno.distancia_valle(celda)<int(cfg.distancia_valle):continue
  var habitat=habitat_en(celda)
  if habitat.get("tipo","")!=p.tipo or habitat.get("bioma","")!=p.bioma:continue
  if cumple_preferencia(celda,p.tipo,preferencias):p.celda=celda;break
 return p

## Las cadenas v1 son la forma abreviada del perfil; no se cambia el archivo sellado.
static func perfiles_habitat(biomas: Dictionary) -> Dictionary:
 var resultado := {}
 for bioma in biomas:
  var valor = biomas[bioma]
  var perfil: Dictionary = {"tipo": valor} if valor is String else valor.duplicate(true) if valor is Dictionary else {}
  perfil.merge({"suelo": "pasto", "sin_objeto": true, "agua_vecina": bioma == "ribera"}, false)
  resultado[bioma] = perfil
 return resultado

static func validar_habitats(biomas: Dictionary) -> Array:
 var errores := []
 var perfiles := perfiles_habitat(biomas)
 for bioma in perfiles:
  var p: Dictionary = perfiles[bioma]
  if not bioma in ["bosque", "sierra", "secano", "pradera", "ribera"]: errores.append("Bioma desconocido: " + str(bioma))
  if not p.get("tipo", null) is String or not C.ENEMIGOS.has(p.get("tipo", "")): errores.append("Especie desconocida: " + str(bioma))
  # Ampliar el sustrato vigente exige una decisión territorial; nada de pesos nuevos.
  if p.suelo != "pasto" or p.sin_objeto != true or not p.agua_vecina is bool: errores.append("Condición de hábitat no admitida: " + str(bioma))
  for clave in p:
   if not clave in ["tipo", "suelo", "sin_objeto", "agua_vecina"]: errores.append("Campo no admitido: " + str(clave))
 return errores

## Consulta pura del terreno base. No carga regiones ni revela conocimiento al jugador.
## La ribera conserva la prioridad v1 sobre el bioma de la celda.
func habitat_en(celda: Vector2i) -> Dictionary:
 if j.mundo.generador == null: return {}
 var d: Dictionary = j.mundo.generador.datos(celda)
 if int(d.tipo) != M.T.PASTO or str(d.objeto) != "": return {}
 var bioma: String = d.bioma
 var agua := false
 for v in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
  if int(j.mundo.generador.datos(celda + v).tipo) == M.T.AGUA:
   agua = true;bioma = "ribera";break
 if not habitats.has(bioma): return {}
 var p: Dictionary = habitats[bioma]
 if bool(p.agua_vecina) and not agua: return {}
 return {"bioma": bioma, "tipo": p.tipo, "conducta": C.ENEMIGOS[p.tipo].get("conducta", "hostil"), "agua_vecina": agua}

## Lectura territorial del registro existente, no regla de aparición ni conocimiento del jugador.
## No genera lugares, rutas o regiones. Distancias sin radio de seguridad implícito.
func contexto_territorial(celda:Vector2i) -> Dictionary:
 var registro:Dictionary=j.d.mundo.get("registro",{})
 var result={"ruta":"","distancia_ruta":-1,"en_ruta":false,"lugares":[],"poblados":[],"nucleos_1e":[]}
 var rutas:Dictionary=registro.get("rutas",{});var ids=rutas.keys();ids.sort()
 for id in ids:
  for pos in rutas[id].celdas:
   var distancia=absi(celda.x-int(pos[0]))+absi(celda.y-int(pos[1]))
   if result.distancia_ruta<0 or distancia<int(result.distancia_ruta):result.ruta=id;result.distancia_ruta=distancia
 result.en_ruta=result.distancia_ruta==0
 var lugares:Dictionary=registro.get("lugares",{});ids=lugares.keys();ids.sort()
 for id in ids:
  var a:Array=lugares[id].area
  if Rect2i(a[0],a[1],a[2],a[3]).has_point(celda):result.lugares.append(id)
 for id in j.mundo.poblados_ids():
  var p:Dictionary=j.mundo.poblado(id)
  if p.has("area"):
   var a:Array=p.area
   if Rect2i(a[0],a[1],a[2],a[3]).has_point(celda):result.poblados.append(id)
  if j.mundo.modo_inicio()==M.MODO_POBLADO and p.has("centro") and Vector2(celda).distance_to(Vector2(p.centro[0],p.centro[1]))<M.NUCLEO_RADIO:result.nucleos_1e.append(id)
 return result

func restaurar() -> Dictionary:
 var d: Dictionary = j.d.get_or_add("fauna", {})
 if not d.has("version"): d.version = 1
 if not d.has("bajas"): d.bajas = {}
 if not d.has("heridos"): d.heridos = {}
 return d

func paso(dt: float) -> void:
 reloj += dt
 if reloj < float(cfg.intervalo_s): return
 reloj = 0.0
 actualizar()

## Plan puro: no depende de construcciones, orden de carga o jugadores presentes.
func candidata_region(r: Vector2i, intento: int) -> Vector2i:
 var h: int = M.Terreno.hash_celda(r * 67 + Vector2i(intento, intento * 31), int(j.d.semilla) ^ 0xFA017)
 return r * 16 + Vector2i(h % 16, (h >> 8) % 16)

func plan_region(r: Vector2i) -> Dictionary:
 var k := M.clave(r)
 if planes.has(k): return planes[k]
 if not distribucion_valida(distribucion):
  push_error("Distribución de fauna no soportada");return {}
 var resultado=plan_base_region(r)
 if int(distribucion.get("version",1))==2:resultado=plan_preferente(r,resultado,distribucion.preferencias)
 planes[k]=resultado
 return resultado

func plan_base_region(r:Vector2i) -> Dictionary:
 var k=M.clave(r)
 var resultado := {}
 for i in 64:
  var celda := candidata_region(r, i)
  if M.Terreno.distancia_valle(celda) < int(cfg.distancia_valle): continue
  var habitat := habitat_en(celda)
  if habitat.is_empty(): continue
  resultado = {"id": "fauna_v1@" + k, "region": k, "celda": celda, "tipo": str(habitat.tipo), "bioma": str(habitat.bioma)}
  break
 return resultado

func _distancia_region(r: Vector2i, centros: Array) -> int:
 var mejor := 2147483647
 for c in centros:
  var d: Vector2i = r - c
  mejor = mini(mejor, d.x * d.x + d.y * d.y)
 return mejor

func actualizar() -> void:
 if not j.es_autoridad() or j.mundo.generador == null: return
 var estado := restaurar()
 for sid in estado.bajas.keys():
  if int(j.d.min) >= int(estado.bajas[sid]): estado.bajas.erase(sid)
 var centros: Array = []
 for id in j.rt: centros.append(M.Terreno.region(M.celda_de(j.pies_de(id))))
 var regiones: Array = []
 for k in j.mundo.regiones:
  var r := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
  var cerca := false
  for centro in centros:
   var delta: Vector2i = r - centro
   if maxi(absi(delta.x), absi(delta.y)) <= int(cfg.radio_regiones): cerca = true
  if cerca: regiones.append(r)
 regiones.sort_custom(func(a, b):
  var da := _distancia_region(a, centros)
  var db := _distancia_region(b, centros)
  return M.clave(a) < M.clave(b) if da == db else da < db)
 var deseados := {}
 for r in regiones:
  if deseados.size() >= int(cfg.max_activos): break
  var p := plan_region(r)
  if not p.is_empty(): deseados[p.id] = p
 for e in combate.enemigos.duplicate():
  if not e.has("fauna_id"): continue
  if not deseados.has(e.fauna_id) or not j.mundo.region_cargada(M.celda_de(e.pos)):
   recordar(e)
   combate.enemigos.erase(e)
 var vivos := {}
 for e in combate.enemigos:
  if e.has("fauna_id"): vivos[e.fauna_id] = true
 for sid in deseados:
  if vivos.has(sid) or estado.bajas.has(sid): continue
  var p: Dictionary = deseados[sid]
  var home := M.pies_de_celda(p.celda)
  var herida: Dictionary = estado.heridos.get(sid, {})
  var posicion: Vector2 = Vector2(herida.pos[0], herida.pos[1]) if herida.has("pos") else home
  var tam: float = C.ENEMIGOS[p.tipo].tam
  # Si se construyó sobre el punto, se pospone; no nace en agua, pared ni encima de un jugador.
  if not j.mundo.caja_libre(posicion, Vector2(tam, tam * 0.6)): continue
  var distancia_segura := 16.0 if not herida.is_empty() else float(cfg.distancia_jugador_px)
  if j.rt.keys().any(func(id): return j.pies_de(id).distance_to(posicion) < distancia_segura): continue
  var e: Dictionary = combate._nuevo(p.tipo, home)
  e.fauna_id = sid
  e.region = p.region
  e.pos = posicion
  e.hp = int(herida.get("hp", e.hp))
  e.alertado = bool(herida.get("alertado", false))
  combate.enemigos.append(e)
 # La caché de planes sigue a las regiones, no crece con toda la exploración.
 for k in planes.keys():
  if not j.mundo.regiones.has(k): planes.erase(k)

func recordar(e: Dictionary) -> void:
 if not e.has("fauna_id") or e.est == "muerto": return
 var d := restaurar()
 if int(e.hp) < int(C.ENEMIGOS[e.tipo].hp):
  d.heridos[e.fauna_id] = {"hp": int(e.hp), "pos": [e.pos.x, e.pos.y], "alertado": e.get("alertado", false)}
 else: d.heridos.erase(e.fauna_id)

func guardar() -> void:
 for e in combate.enemigos: recordar(e)

func baja(e: Dictionary) -> void:
 if not e.has("fauna_id"): return
 var d := restaurar()
 d.heridos.erase(e.fauna_id)
 d.bajas[e.fauna_id] = int(j.d.min) + int(cfg.reaparicion_min)
