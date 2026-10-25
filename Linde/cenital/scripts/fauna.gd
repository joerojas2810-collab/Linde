extends RefCounted
## Encuentros regionales v1, separados del generador de terreno congelado.
## Un punto determinista por región; bajas y heridas durables, simulación solo en autoridad.
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
var combate
var j
var cfg: Dictionary
var planes := {}
var reloj := 0.0

func _init(c) -> void:
 combate = c
 j = c.j
 cfg = JSON.parse_string(FileAccess.get_file_as_string("res://datos/fauna/reglas_v1.json"))
 restaurar()

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
func plan_region(r: Vector2i) -> Dictionary:
 var k := M.clave(r)
 if planes.has(k): return planes[k]
 var resultado := {}
 for i in 64:
  var h: int = M.Terreno.hash_celda(r * 67 + Vector2i(i, i * 31), int(j.d.semilla) ^ 0xFA017)
  var celda := r * 16 + Vector2i(h % 16, (h >> 8) % 16)
  if M.Terreno.distancia_valle(celda) < int(cfg.distancia_valle): continue
  var d: Dictionary = j.mundo.generador.datos(celda)
  if int(d.tipo) != M.T.PASTO or str(d.objeto) != "": continue
  var bioma: String = d.bioma
  for v in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
   if int(j.mundo.generador.datos(celda + v).tipo) == M.T.AGUA:
    bioma = "ribera"
    break
  if not cfg.biomas.has(bioma): continue
  resultado = {"id": "fauna_v1@" + k, "region": k, "celda": celda, "tipo": str(cfg.biomas[bioma]), "bioma": bioma}
  break
 planes[k] = resultado
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
