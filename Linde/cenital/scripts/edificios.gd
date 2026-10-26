extends RefCounted
## Catálogo común a generación y construcción. El registro referencia piezas reales; nunca copia inventarios o habitantes.
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
static var _catalogo: Dictionary = {}

## Catálogo reducido: las funciones provienen de las piezas existentes, sin bonos propios.
static func catalogo() -> Dictionary:
 if _catalogo.is_empty(): _catalogo = JSON.parse_string(FileAccess.get_file_as_string("res://datos/edificios/catalogo_v1.json"))
 return _catalogo

## Plano resuelto por coordenadas globales. Ancla independiente de cama/cofre; etapas preparadas, instalación terminada inicialmente.
static func plano(tipo: String, entrada: Vector2i, dueno: String, poblado: String = "") -> Dictionary:
 if not catalogo().planos.has(tipo): return {}
 var t: Dictionary = catalogo().planos[tipo]
 var area := Rect2i(entrada + Vector2i(t.area[0],t.area[1]),Vector2i(t.area[2],t.area[3]))
 var interior := Rect2i(entrada + Vector2i(t.interior[0],t.interior[1]),Vector2i(t.interior[2],t.interior[3]))
 var e := {"id":"edificio@"+M.clave(entrada),"version":1,"plano":tipo,"nombre":t.nombre,"familia":t.familia,"dueno":dueno,"poblado":poblado,"revision":1,"area":[area.position.x,area.position.y,area.size.x,area.size.y],"entrada":[entrada.x,entrada.y],"interior":{},"piezas":{},"pisos":{},"techos":{},"etapas":t.etapas.duplicate(),"obra":"terminada"}
 for y in range(area.position.y,area.end.y):
  for x in range(area.position.x,area.end.x):
   var c := Vector2i(x,y)
   var k := M.clave(c)
   if c != entrada: e.techos[k] = true
   if interior.has_point(c):
    e.interior[k] = true
    e.pisos[k] = true
   else: e.piezas[k] = {"t":"puerta" if c == entrada else "muro", "propia":true,"dueno":dueno}
 for p in t.mobiliario:
  var c := entrada + Vector2i(p.d[0],p.d[1])
  e.piezas[M.clave(c)] = {"t":p.t,"propia":true,"dueno":dueno}
 return e

static func _celda(k: String) -> Vector2i:
 return Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))

## Precio exacto de las piezas existentes, sin multiplicadores, regalos ni nuevos bonos.
static func coste(e: Dictionary) -> Dictionary:
 var total := {}
 for cs in e.piezas.values(): _sumar(total,C.CONSTR[cs.t].coste)
 for _k in e.pisos: _sumar(total,C.CONSTR.suelo.coste)
 for _k in e.techos: _sumar(total,C.CONSTR.techo.coste)
 return total

static func _sumar(total: Dictionary, lote: Dictionary) -> void:
 for k in lote: total[k] = int(total.get(k,0)) + int(lote[k])

## Comprueba huella sin mutar el mundo. También se usa en la vista previa.
static func solar(j, e: Dictionary, regional = null) -> String:
 if e.is_empty(): return "Plano desconocido"
 var a: Array = e.area
 for y in range(a[1],a[1]+a[3]):
  for x in range(a[0],a[0]+a[2]):
   var c := Vector2i(x,y)
   if M.CASA.has_point(c) or not j.mundo.edificio_en(c).is_empty(): return "Hay otro edificio"
   var libre: bool=j.mundo.puede_poner(c)=="" if regional==null else regional.terreno_reparacion(c,false)
   if not libre or j.mundo.estado.techos.has(M.clave(c)) or not j.mundo.piso_en(c).is_empty(): return "La huella necesita terreno libre"
   if j.mundo.tipo(c) == M.T.CAMINO or j.autonomia.sociedad.habitat.reservada(c): return "Hay un camino o solar reservado"
   if j.d.cofres.has("c@"+M.clave(c)): return "Hay un depósito existente en la huella"
   if j.ocupada(c): return "Hay alguien en la huella"
 var acceso := Vector2i(e.entrada[0],e.entrada[1])+Vector2i.DOWN
 if regional==null:
  if j.mundo.bloquea(acceso) or not j.mundo.caja_libre(M.pies_de_celda(acceso)): return "La entrada sur está bloqueada"
 elif not regional._transitable(acceso) or not regional.caja_regional(M.pies_de_celda(acceso)): return "La entrada sur está bloqueada"
 return ""

## Recorrido real desde el exterior, con las mismas colisiones que jugador y NPC.
static func accesible(j, e: Dictionary) -> bool:
 var c := Vector2i(e.entrada[0],e.entrada[1])
 var a: Array = e.area
 var zona := Rect2i(a[0]-2,a[1]-2,a[2]+4,a[3]+4)
 var alc: Dictionary = j.mundo.alcanzables(c+Vector2i.DOWN,zona)
 if not alc.has(c) or not j.mundo.caja_libre(M.pies_de_celda(c)): return false
 for k in e.interior:
  var celda := _celda(k)
  if j.mundo.constr_en(celda).is_empty() and (not alc.has(celda) or not j.mundo.caja_libre(M.pies_de_celda(celda))): return false
 for k in e.piezas:
  if e.piezas[k].t not in ["cama","cama_huesped","cofre","mesa","horno"]: continue
  var junto := false
  for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if alc.has(_celda(k)+d): junto = true
  if not junto: return false
 return true

## Operación común de génesis: valida y materializa una vez, sin reponer nada durante carga o streaming.
## El llamador aporta/paga materiales; no concede contenido a cofres ni cambia la población.
static func instalar(j, e: Dictionary, regional = null) -> String:
 if not j.es_autoridad(): return "Solo la autoridad construye"
 var motivo := solar(j,e,regional)
 if motivo != "": return motivo
 var m = j.mundo
 var anteriores: Dictionary = m.estado.constr
 m.estado.constr = anteriores.duplicate(true)
 m.estado.constr.merge(e.piezas,true)
 m.cambiar()
 var actores: Array = []
 for actor in j.rt.values(): actores.append(M.celda_de(actor.pies))
 for nid in j.habitantes.ids: actores.append(M.celda_de(j.habitantes.pos(nid)))
 var valida: bool = accesible(j,e) and m.construccion_segura(Vector2i(e.entrada[0],e.entrada[1]),actores) if regional==null else regional.acceso_reparacion(e)
 if regional!=null:
  var zona := Rect2i(e.area[0]-1,e.area[1]-1,e.area[2]+2,e.area[3]+2)
  for actor in actores:
   if zona.has_point(actor): valida=valida and m.construccion_segura(Vector2i(e.entrada[0],e.entrada[1]),actores)
 m.estado.constr = anteriores
 m.cambiar()
 if not valida: return "El plano impediría un acceso o el uso del interior"
 # Guardar el plano resuelto evita depender de cambios posteriores del catálogo.
 var registro: Dictionary = m.estado.get_or_add("registro",{"version":1,"poblados":[],"macros":{},"lugares":{},"rutas":{},"suelos":{},"despejes":{}})
 for k in e.piezas:
  m.estado.constr[k] = e.piezas[k].duplicate(true)
  if e.piezas[k].t == "cofre": j.d.cofres["c@"+k] = {"inv":{}}
 for k in e.pisos: registro.get_or_add("pisos",{})[k] = {"dueno":e.dueno,"edificio":e.id}
 for y in range(e.area[1],e.area[1]+e.area[3]):
  for x in range(e.area[0],e.area[0]+e.area[2]): registro.despejes[M.clave(Vector2i(x,y))] = true
 for k in e.techos: m.estado.techos[k] = e.dueno
 registro.get_or_add("edificios",{})[e.id] = e.duplicate(true)
 m.aplicar_registro()
 return ""

## Estado derivado del mundo real. Un faltante jamás se reconstruye al consultar o cargar.
static func faltantes(j, e: Dictionary) -> Dictionary:
 var r := {"piezas":{},"pisos":{},"techos":{}}
 for k in e.piezas:
  if j.mundo.constr_en(_celda(k)).get("t","") != e.piezas[k].t: r.piezas[k] = e.piezas[k]
 for k in e.pisos:
  if j.mundo.piso_en(_celda(k)).get("edificio","") != e.id: r.pisos[k] = true
 for k in e.techos:
  if not j.mundo.estado.techos.has(k): r.techos[k] = true
 return r

## Ocultación exclusivamente local; no cambia estado físico, propiedad o reglas de otros clientes.
static func abierto(e: Dictionary, pies: Vector2) -> bool:
 var c := M.celda_de(pies)
 return e.interior.has(M.clave(c)) or c == Vector2i(e.entrada[0],e.entrada[1]) or c == Vector2i(e.entrada[0],e.entrada[1])+Vector2i.DOWN

## Puerta automática de presentación: jugadores y NPC cercanos abren la misma pieza transitable.
static func puerta_abierta(c: Vector2i, posiciones: Array) -> bool:
 for p in posiciones:
  var d: Vector2i = (M.celda_de(p)-c).abs()
  if maxi(d.x,d.y)<=1:return true
 return false

## Texto derivado del plano resuelto, también válido para variantes de generación.
static func servicios(e: Dictionary) -> PackedStringArray:
 var nombres := PackedStringArray()
 for pieza in e.piezas.values():
  if pieza.t in ["cama","cama_huesped","mesa","horno","cofre"]:
   var n: String = C.CONSTR[pieza.t].n
   if not nombres.has(n): nombres.append(n)
 return nombres


## Ejecuta la reparación material común; el llamante valida dueño y alcance.
static func reparar(j, e: Dictionary, inv: Dictionary, regional = null) -> Dictionary:
 if not j.es_autoridad(): return {"ok":false,"motivo":"Solo la autoridad repara"}
 var f := faltantes(j,e)
 var gastos := coste(f)
 if gastos.is_empty(): return {"ok":false,"motivo":"El edificio está completo"}
 if not Inv.tiene(inv,gastos): return {"ok":false,"motivo":"Faltan materiales: "+j._txt_items(gastos)}
 for k in f.piezas:
  var c := _celda(k)
  var terreno_ok: bool = j.mundo.puede_poner(c)=="" if regional==null else regional.terreno_reparacion(c,false)
  if not j.mundo.constr_en(c).is_empty() or not terreno_ok or j.ocupada(c): return {"ok":false,"motivo":"Hay un obstáculo en la reparación"}
 for k in f.techos:
  var terreno_ok: bool = j.mundo.puede_techar(_celda(k))=="" if regional==null else regional.terreno_reparacion(_celda(k),true)
  if not terreno_ok: return {"ok":false,"motivo":"Hay un obstáculo bajo la cubierta"}
 for k in f.pisos:
  if not j.mundo.piso_en(_celda(k)).is_empty(): return {"ok":false,"motivo":"Hay otro suelo en la reparación"}
 # Comprueba el resultado completo antes de consumir o cambiar una pieza.
 var anteriores: Dictionary = j.d.mundo.constr
 j.d.mundo.constr = anteriores.duplicate(true)
 j.d.mundo.constr.merge(f.piezas,true)
 j.mundo.cambiar()
 var valido: bool = accesible(j,e) if regional==null else regional.acceso_reparacion(e)
 j.d.mundo.constr = anteriores
 j.mundo.cambiar()
 if not valido: return {"ok":false,"motivo":"La reparación impediría un acceso"}
 for k in f.piezas:
  var cs: Dictionary = f.piezas[k]
  j.mundo.poner(_celda(k),cs.t,true,e.dueno)
  if cs.t == "cofre": j.d.cofres.get_or_add("c@"+k,{"inv":{}})
 for k in f.pisos:
  j.d.mundo.registro.pisos[k] = {"dueno":e.dueno,"edificio":e.id}
  j.mundo._edificio_editado(_celda(k))
 for k in f.techos: j.mundo.techar(_celda(k),e.dueno)
 j.mundo.cambiar()
 Inv.quitar(inv,gastos)
 return {"ok":true,"coste":gastos}
