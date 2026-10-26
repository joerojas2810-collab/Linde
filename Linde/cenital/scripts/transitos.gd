extends RefCounted
## Operaciones del registro de Asentamientos. Bienes y residentes tienen un solo dueño.
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const Inv = preload("res://scripts/inventario.gd")
const H = preload("res://scripts/habitantes.gd")
var s
var j
func _init(asentamientos) -> void:
 s=asentamientos
 j=s.j
func datos() -> Dictionary:
 return s.datos().get_or_add("transitos",{"version":1,"operaciones":{},"politica":{"usar_valores_existentes":true,"aprobacion":"usuario_2026-10-26"}})
func puesto(id: String) -> Dictionary:
 return s.datos().puestos.get(id,{})
func _celda(k: String) -> Vector2i:
 return Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
func ruta(desde: String, hasta: String) -> Array:
 var origen := puesto(desde)
 var destino := puesto(hasta)
 if origen.is_empty() or destino.is_empty(): return []
 var inicio := Vector2i(origen.celda[0],origen.celda[1])
 var fin := Vector2i(destino.celda[0],destino.celda[1])
 # Navegación sobre terreno real, con los mismos bloqueos regionales. No genera lugares.
 var margen := int(s.cfg.radio_recursos)
 var minimo := Vector2i(mini(inicio.x,fin.x)-margen,mini(inicio.y,fin.y)-margen)
 var maximo := Vector2i(maxi(inicio.x,fin.x)+margen,maxi(inicio.y,fin.y)+margen)
 var limites := Rect2i(minimo,maximo-minimo+Vector2i.ONE)
 var abiertos: Array = []
 var distancia := {M.clave(inicio):0}
 var padres := {M.clave(inicio):""}
 _insertar(abiertos,[0,0,M.clave(inicio)])
 while not abiertos.is_empty():
  var nodo: Array=_sacar(abiertos)
  var c := _celda(nodo[2])
  var actual := int(nodo[1])
  if actual!=int(distancia.get(nodo[2],-1)): continue
  if c==fin:
   var salida: Array=[]
   var k: String=nodo[2]
   while k!="":
    var q := _celda(k)
    salida.push_front([q.x,q.y])
    k=padres[k]
   return salida
  for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   var n: Vector2i=c+v
   var k := M.clave(n)
   var coste := actual+1
   if not limites.has_point(n) or coste>=int(distancia.get(k,2147483647)) or not s._transitable(n): continue
   distancia[k]=coste;padres[k]=M.clave(c)
   var h := absi(n.x-fin.x)+absi(n.y-fin.y)
   _insertar(abiertos,[coste+h,coste,k])
 return []
func _menor(a: Array,b: Array) -> bool:
 if a[0]!=b[0]: return a[0]<b[0]
 if a[1]!=b[1]: return a[1]>b[1]
 return a[2]<b[2]
func _insertar(cola: Array,n: Array) -> void:
 cola.append(n)
 var i := cola.size()-1
 while i>0:
  var padre := floori(float(i-1)/2.0)
  if not _menor(cola[i],cola[padre]): break
  var v=cola[i];cola[i]=cola[padre];cola[padre]=v;i=padre
func _sacar(cola: Array) -> Array:
 var n: Array=cola[0]
 var ultimo=cola.pop_back()
 if cola.is_empty(): return n
 cola[0]=ultimo
 var i := 0
 while i*2+1<cola.size():
  var hijo := i*2+1
  if hijo+1<cola.size() and _menor(cola[hijo+1],cola[hijo]): hijo+=1
  if not _menor(cola[hijo],cola[i]): break
  var v=cola[i];cola[i]=cola[hijo];cola[hijo]=v;i=hijo
 return n

func reservas_plaza(id: String) -> int:
 var n := 0
 for op in datos().operaciones.values():
  if not op.estado in ["reservada","viajando","detenida"]: continue
  if op.get("tipo", "migracion")=="comercio":
   if op.estado!="reservada" and op.origen==id: n+=op.ids.size()
  elif op.destino==id: n+=op.ids.size()
 return n
func reservar(clave: String, origen: String, destino: String, ids: Array, bienes: Dictionary, provisiones: Dictionary = {}, tipo: String = "migracion") -> Dictionary:
 if not j.es_autoridad(): return {"ok":false,"motivo":"solo_servidor"}
 var firma := {"origen":origen,"destino":destino,"ids":ids,"bienes":bienes,"provisiones":provisiones,"tipo":tipo}
 if datos().operaciones.has(clave):
  var anterior: Dictionary=datos().operaciones[clave]
  if JSON.stringify(anterior.firma)!=JSON.stringify(firma): return {"ok":false,"motivo":"id_con_otro_contenido"}
  return {"ok":true,"operacion":anterior}
 var a := puesto(origen)
 var b := puesto(destino)
 if a.is_empty() or b.is_empty() or origen==destino or ids.is_empty(): return {"ok":false,"motivo":"origen_destino"}
 if not s._sostenible(b) or (tipo!="comercio" and b.residentes.size()+reservas_plaza(destino)+ids.size()>int(s.cfg.capacidad)): return {"ok":false,"motivo":"destino_sin_capacidad"}
 var miembros: Array = []
 var vistos := {}
 for id in ids:
  if vistos.has(id): return {"ok":false,"motivo":"id_repetido"}
  vistos[id]=true
  var copias := 0
  for p in s.datos().puestos.values():
   for r in p.residentes:
    if r.id==id: copias+=1
  for op in datos().operaciones.values():
   for r in op.miembros:
    if r.id==id: copias+=1
  if copias!=1 or id in j.habitantes.ids: return {"ok":false,"motivo":"identidad_no_unica"}
  var encontrado := false
  for r in a.residentes:
   if r.id==id and not r.has("reserva_viaje"):
    miembros.append(r)
    encontrado=true
  if not encontrado: return {"ok":false,"motivo":"residente_no_disponible"}
 var lote := bienes.duplicate(true)
 for item in provisiones: lote[item]=int(lote.get(item,0))+int(provisiones[item])
 for item in lote:
  if not C.ITEMS.has(item) or typeof(lote[item])!=TYPE_INT or int(lote[item])<=0: return {"ok":false,"motivo":"lote_invalido"}
 for parte in [bienes,provisiones]:
  for item in parte:
   if typeof(parte[item])!=TYPE_INT or int(parte[item])<=0: return {"ok":false,"motivo":"lote_invalido"}
 if not j.d.cofres.has(a.get("cofre", "")): return {"ok":false,"motivo":"sin_cofre_origen"}
 if not Inv.tiene(s.inventario(a),lote): return {"ok":false,"motivo":"sin_bienes"}
 var camino := ruta(origen,destino)
 if camino.is_empty(): return {"ok":false,"motivo":"sin_ruta"}
 var antes: Dictionary = s.inventario(a).duplicate(true)
 Inv.quitar(s.inventario(a),lote)
 for r in miembros: r.reserva_viaje=clave
 var op := {"firma":firma.duplicate(true),"tipo":tipo,"id":clave,"origen":origen,"destino":destino,"ids":ids.duplicate(),"miembros":[],"bienes":bienes.duplicate(true),"provisiones":provisiones.duplicate(true),"ruta":camino,"estado":"reservada","ultimo_min":int(j.d.min),"avance":0,"consumo":0,"deuda_comida":0}
 datos().operaciones[clave]=op
 s._resultado_regional(a,"reserva_viaje",{"id":clave},antes)
 return {"ok":true,"operacion":op}
func cancelar(clave: String) -> bool:
 if not j.es_autoridad(): return false
 var op: Dictionary = datos().operaciones.get(clave,{})
 if op.get("estado", "")!="reservada": return false
 var a := puesto(op.origen)
 if not j.d.cofres.has(a.get("cofre", "")): return false
 if op.has("contraoferta") and not op.contraoferta.is_empty() and not j.d.cofres.has(puesto(op.destino).get("cofre", "")): return false
 var antes: Dictionary = s.inventario(a).duplicate(true)
 for lote in [op.bienes,op.provisiones]:
  for item in lote: s.inventario(a)[item]=int(s.inventario(a).get(item,0))+int(lote[item])
 for r in a.residentes:
  if r.get("reserva_viaje", "")==clave: r.erase("reserva_viaje")
 if op.has("contraoferta") and not op.contraoferta.is_empty():
  var b := puesto(op.destino)
  if not j.d.cofres.has(b.get("cofre", "")): return false
  var antes_b: Dictionary=s.inventario(b).duplicate(true)
  for item in op.contraoferta: s.inventario(b)[item]=int(s.inventario(b).get(item,0))+int(op.contraoferta[item])
  s._resultado_regional(b,"cancelacion_intercambio",{"id":clave},antes_b)
  op.contraoferta={}
 op.bienes={};op.provisiones={};op.estado="cancelada"
 s._resultado_regional(a,"cancelacion_viaje",{"id":clave},antes)
 return true
func salir(clave: String) -> Dictionary:
 if not j.es_autoridad(): return {"ok":false,"motivo":"solo_servidor"}
 var op: Dictionary = datos().operaciones.get(clave,{})
 if op.get("estado", "")!="reservada": return {"ok":false,"motivo":"estado"}
 if not datos().politica.get("usar_valores_existentes",true): return {"ok":false,"motivo":"politica_viaje_no_aprobada"}
 var a := puesto(op.origen)
 var b := puesto(op.destino)
 if j.mundo.poblado(b.get("poblado", "")).get("estado", "") in ["abandonado","destruido"]: return {"ok":false,"motivo":"recuperacion_no_aprobada"}
 if not s._sostenible(b) or (op.tipo!="comercio" and b.residentes.size()+reservas_plaza(op.destino)>int(s.cfg.capacidad)): return {"ok":false,"motivo":"destino_sin_capacidad"}
 if int(s.balance_resumido(a).baya.vencido)>0 or int(a.get("deuda_comida",0))>0: return {"ok":false,"motivo":"consumo_origen_pendiente"}
 var camino := ruta(op.origen,op.destino)
 if camino.is_empty(): return {"ok":false,"motivo":"sin_ruta"}
 var lote: Dictionary = op.bienes.duplicate(true)
 for item in op.provisiones: lote[item]=int(lote.get(item,0))+int(op.provisiones[item])
 if Inv.slots(lote)>int(s.a.reglas.mochila_habitante)*op.ids.size(): return {"ok":false,"motivo":"sin_capacidad_carga"}
 var miembros: Array = []
 for r in a.residentes:
  if r.get("reserva_viaje", "")==clave: miembros.append(r)
 if miembros.size()!=op.ids.size(): return {"ok":false,"motivo":"identidad_cambio"}
 var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/H.VEL*C.MIN_POR_SEG))
 var necesario := 0
 for r in miembros: necesario+=maxi(0,floori(float(int(j.d.min)+duracion*(2 if op.tipo=="comercio" else 1)-int(r.get("comida_min",a.comida_min)))/float(s.cfg.comida_min)))
 if int(op.provisiones.get("baya",0))<necesario: return {"ok":false,"motivo":"sin_provisiones"}
 op.ruta=camino;op.duracion=duracion;op.ultimo_min=int(j.d.min);op.reloj=int(j.d.min)
 for r in miembros:
  if not r.has("comida_min"): r.comida_min=int(a.comida_min)
 for r in miembros:
  a.residentes.erase(r)
  r.erase("reserva_viaje")
 op.miembros=miembros;op.estado="viajando"
 _sincronizar(a)
 return {"ok":true}
func _sincronizar(p: Dictionary) -> void:
 if not p.has("poblado"): return
 var pueblo: Dictionary=j.mundo.poblado(p.poblado)
 var ids: Array = []
 for r in p.residentes: ids.append(r.id)
 pueblo.residentes=ids
 var camas: Dictionary = pueblo.get("camas",{})
 for id in camas.keys():
  if not id in ids: camas.erase(id)
func actualizar() -> void:
 if not j.es_autoridad(): return
 for op in datos().operaciones.values():
  if not op.estado in ["viajando","detenida"]: continue
  var ahora := int(j.d.min)
  var dt := maxi(0,ahora-int(op.ultimo_min))
  op.ultimo_min=ahora
  var siguiente := mini(int(op.duracion),int(op.avance)+dt)
  var indice := mini(op.ruta.size()-1,floori(float(siguiente)/float(op.duracion)*(op.ruta.size()-1)))
  var anterior := mini(op.ruta.size()-1,floori(float(op.avance)/float(op.duracion)*(op.ruta.size()-1)))
  var libre := true
  for i in range(anterior,indice+1):
   var q: Array=op.ruta[i]
   if not s._transitable(Vector2i(q[0],q[1])): libre=false;break
  var tiempo := mini(dt,int(op.duracion)-int(op.avance)) if libre and int(op.avance)<int(op.duracion) else dt
  op.reloj=int(op.reloj)+tiempo
  var coste := 0
  for r in op.miembros: coste+=maxi(0,floori(float(int(op.reloj)-int(r.comida_min))/float(s.cfg.comida_min)))
  op.deuda_comida=coste
  if int(op.provisiones.get("baya",0))<coste:
   op.estado="detenida";op.motivo="sin_comida";continue
  op.provisiones.baya=int(op.provisiones.get("baya",0))-coste
  op.consumido=int(op.get("consumido",0))+coste
  for r in op.miembros:
   var periodos := maxi(0,floori(float(int(op.reloj)-int(r.comida_min))/float(s.cfg.comida_min)))
   r.comida_min=int(r.comida_min)+periodos*int(s.cfg.comida_min)
  op.deuda_comida=0
  if not libre: op.estado="detenida";op.motivo="ruta_bloqueada";continue
  op.avance=siguiente;op.estado="viajando"
  if int(op.avance)<int(op.duracion): continue
  var b := puesto(op.destino)
  if b.is_empty() or not s._sostenible(b) or ((op.tipo!="comercio" or op.get("regresando",false)) and b.residentes.size()+op.miembros.size()>int(s.cfg.capacidad)):
   op.estado="detenida";op.motivo="destino_sin_capacidad";continue
  if op.tipo=="comercio" and not op.get("regresando",false):
   var antes_entrega: Dictionary=s.inventario(b).duplicate(true)
   for item in op.bienes: s.inventario(b)[item]=int(s.inventario(b).get(item,0))+int(op.bienes[item])
   s._resultado_regional(b,"intercambio_recibido",{"id":op.id},antes_entrega,{"actor":op.ids.duplicate()})
   op.bienes=op.contraoferta;op.contraoferta={}
   op.destino=op.origen;op.ruta.reverse();op.avance=0;op.regresando=true
   op.ultimo_min=int(op.reloj)
   continue
  var antes: Dictionary = s.inventario(b).duplicate(true)
  for lote in [op.bienes,op.provisiones]:
   for item in lote: s.inventario(b)[item]=int(s.inventario(b).get(item,0))+int(lote[item])
  for r in op.miembros:
   r.hogar=b.get("poblado",b.id)
   b.residentes.append(r)
  op.miembros=[];op.bienes={};op.provisiones={};op.estado="entregada"
  _sincronizar(b)
  if b.has("poblado"):
   var pueblo: Dictionary=j.mundo.poblado(b.poblado)
   var ocupadas: Array=pueblo.camas.values()
   for r in b.residentes:
    if pueblo.camas.has(r.id): continue
    for q in b.get("camas",[]):
     if not q in ocupadas: pueblo.camas[r.id]=q;ocupadas.append(q);break
  s._resultado_regional(b,"llegada",{"id":op.id},antes,{"residentes":op.ids.duplicate()})


func posicion(op: Dictionary) -> Vector2:
 if op.ruta.is_empty(): return Vector2.INF
 var indice := mini(op.ruta.size()-1,floori(float(op.avance)/float(op.get("duracion",1))*(op.ruta.size()-1)))
 var q: Array=op.ruta[indice]
 return M.pies_de_celda(Vector2i(q[0],q[1]))

## Cancelación en marcha: regreso por la porción realmente recorrida; nunca devolución instantánea.
func regresar(clave: String) -> bool:
 if not j.es_autoridad(): return false
 var op: Dictionary=datos().operaciones.get(clave,{})
 if not op.get("estado", "") in ["viajando","detenida"] or op.get("regresando",false): return false
 if op.tipo=="comercio" and not op.get("contraoferta",{}).is_empty():
  var b := puesto(op.destino)
  if not j.d.cofres.has(b.get("cofre", "")): return false
  var antes: Dictionary=s.inventario(b).duplicate(true)
  for item in op.contraoferta: s.inventario(b)[item]=int(s.inventario(b).get(item,0))+int(op.contraoferta[item])
  s._resultado_regional(b,"intercambio_interrumpido",{"id":clave},antes)
  op.contraoferta={}
 var indice := mini(op.ruta.size()-1,floori(float(op.avance)/float(op.duracion)*(op.ruta.size()-1)))
 var vuelta: Array=op.ruta.slice(0,indice+1)
 vuelta.reverse()
 op.ruta=vuelta;op.destino=op.origen;op.regresando=true;op.avance=0
 op.duracion=maxi(1,ceili((vuelta.size()-1)*float(M.P.CELDA)/H.VEL*C.MIN_POR_SEG))
 op.ultimo_min=int(j.d.min)
 return true


func exportable(p: Dictionary, item: String) -> int:
 var inv: Dictionary = s.inventario(p)
 var saldos: Dictionary = s.balance_resumido(p)
 var reserva := int(saldos.get(item,{}).get("reserva",0))
 if item in ["madera","piedra"]:
  reserva=maxi(0,int(saldos.materiales.reserva)-int(inv.get("piedra" if item=="madera" else "madera",0)))
 return maxi(0,int(inv.get(item,0))-reserva)

## Trueque en especie: ambos lotes quedan separados antes de enviar un residente real.
func acordar(clave: String, origen: String, destino: String, ids: Array, oferta: Dictionary, pedido: Dictionary, provisiones: Dictionary) -> Dictionary:
 if not j.es_autoridad(): return {"ok":false,"motivo":"solo_servidor"}
 var a := puesto(origen)
 var b := puesto(destino)
 if a.is_empty() or b.is_empty(): return {"ok":false,"motivo":"origen_destino"}
 var operacion: Dictionary=datos().operaciones.get(clave,{})
 if not operacion.is_empty():
  if operacion.get("pedido",{})!=pedido: return {"ok":false,"motivo":"id_con_otro_contenido"}
  return reservar(clave,origen,destino,ids,oferta,provisiones,"comercio")
 if oferta.is_empty() or pedido.is_empty(): return {"ok":false,"motivo":"lote_vacio"}
 for item in pedido:
  if not C.ITEMS.has(item) or typeof(pedido[item])!=TYPE_INT or int(pedido[item])<=0 or exportable(b,item)<int(pedido[item]): return {"ok":false,"motivo":"sin_excedente_destino"}
 for item in oferta:
  if not C.ITEMS.has(item) or typeof(oferta[item])!=TYPE_INT or int(oferta[item])<=0 or exportable(a,item)<int(oferta[item])+int(provisiones.get(item,0)): return {"ok":false,"motivo":"sin_excedente_origen"}
 for item in provisiones:
  if not C.ITEMS.has(item) or typeof(provisiones[item])!=TYPE_INT or int(provisiones[item])<=0 or exportable(a,item)<int(provisiones[item])+int(oferta.get(item,0)): return {"ok":false,"motivo":"sin_provisiones_exportables"}
 var retorno: Dictionary=pedido.duplicate(true)
 for item in provisiones: retorno[item]=int(retorno.get(item,0))+int(provisiones[item])
 if Inv.slots(retorno)>int(s.a.reglas.mochila_habitante)*ids.size(): return {"ok":false,"motivo":"sin_capacidad_retorno"}
 var resultado := reservar(clave,origen,destino,ids,oferta,provisiones,"comercio")
 if not resultado.ok: return resultado
 var antes: Dictionary=s.inventario(b).duplicate(true)
 Inv.quitar(s.inventario(b),pedido)
 resultado.operacion.contraoferta=pedido.duplicate(true)
 resultado.operacion.pedido=pedido.duplicate(true)
 s._resultado_regional(b,"reserva_intercambio",{"id":clave},antes)
 return resultado


func entrante(id: String,item: String) -> int:
 var total := 0
 for op in datos().operaciones.values():
  if not op.estado in ["reservada","viajando","detenida"]: continue
  if op.destino==id: total+=int(op.bienes.get(item,0))
  if op.tipo=="comercio" and not op.get("regresando",false) and op.origen==id: total+=int(op.get("contraoferta",{}).get(item,0))
 return total

## Reutiliza la valoración de Sociedad y reservas actuales; no crea precios ni caravanas periódicas.
func comerciar(p: Dictionary) -> bool:
 if not j.es_autoridad() or not datos().politica.get("comercio_autonomo",true): return false
 var residentes: Array=p.residentes.duplicate()
 residentes.sort_custom(func(a,b):return str(a.id)<str(b.id))
 var disponibles: Array=[]
 for r in residentes:
  if not r.has("reserva_viaje"): disponibles.append(r)
 if disponibles.is_empty(): return false
 var saldos: Dictionary=s.balance_resumido(p)
 var destinos: Array=s.datos().puestos.keys();destinos.sort()
 var items: Array=saldos.keys();items.sort()
 for item in items:
  if item=="materiales" or int(saldos[item].pendiente)<=0: continue
  for id in destinos:
   var b := puesto(id)
   if id==p.id or b.residentes.is_empty() or exportable(b,item)<1: continue
   var pagos: Array=s.inventario(p).keys();pagos.sort()
   for pago in pagos:
    if pago==item: continue
    var valor_pago: float=s.a.sociedad.valor(pago)
    if valor_pago<=0: continue
    var cantidad := ceili(s.a.sociedad.valor(item)/valor_pago)
    if cantidad<=0 or exportable(p,pago)<cantidad: continue
    var camino := ruta(p.id,id)
    if camino.is_empty(): continue
    var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/H.VEL*C.MIN_POR_SEG))
    var r: Dictionary=disponibles[0]
    var comida := floori(float(int(j.d.min)+2*duracion-int(r.get("comida_min",p.comida_min)))/float(s.cfg.comida_min))
    var provisiones := {"baya":comida} if comida>0 else {}
    var clave := "comercio:%s:%s:%s:%d" % [p.id,id,item,int(j.d.min)]
    var pedido := {item:1}
    var oferta := {pago:cantidad}
    var acuerdo := acordar(clave,p.id,id,[r.id],oferta,pedido,provisiones)
    if not acuerdo.ok: continue
    var salida := salir(clave)
    if salida.ok: return true
    cancelar(clave)
 return false


func retornos(id: String) -> Array:
 var residentes: Array=[]
 for op in datos().operaciones.values():
  if op.tipo=="comercio" and op.origen==id and op.estado in ["viajando","detenida"]: residentes.append_array(op.miembros)
 return residentes
