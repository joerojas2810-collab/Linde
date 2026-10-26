extends RefCounted
## Contrato de expedición de Asentamientos; ningún solar es un pueblo antes de la llegada.
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
const E=preload("res://scripts/edificios.gd")
const Inv=preload("res://scripts/inventario.gd")
var s
var j
func _init(asentamientos) -> void:
 s=asentamientos;j=s.j

func fuentes(c: Vector2i) -> Dictionary:
 var salida := {"arbusto":0,"arbol":0,"roca":0}
 var alcance: Dictionary=s._alcance(c)
 var radio := int(s.cfg.radio_recursos)
 for y in range(c.y-radio,c.y+radio+1):
  for x in range(c.x-radio,c.x+radio+1):
   var q := Vector2i(x,y)
   var k := M.clave(q)
   var d: Dictionary=j.mundo.generador.datos(q)
   var tipo := str(d.objeto)
   if not salida.has(tipo) or not j.mundo.constr_en(q).is_empty() or j.d.mundo.registro.despejes.has(k): continue
   var id := tipo+"@"+k
   if j.d.mundo.rotos.has(id):
    var horas := int(C.OBJETOS[tipo].get("regen_h",0))
    if horas<=0 or int(j.d.min)-int(j.d.mundo.rotos[id])<horas*60: continue
   for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
    if alcance.has(q+v): salida[tipo]+=1;break
 return salida

func plano(p: Dictionary, c: Vector2i) -> Dictionary:
 var pid := "poblado_fundado@"+M.clave(c)
 var e := E.plano("casa_regional",c+Vector2i(0,2),p.dueno,pid)
 var coste := E.coste(e)
 for i in 2: E._sumar(coste,C.CONSTR.campo.coste)
 return {"origen":p.id,"centro":[c.x,c.y],"edificio":e,"coste":coste,"poblado":pid,"campos":[[c.x-2,c.y+3],[c.x+2,c.y+3]]}

func solar(plan: Dictionary) -> bool:
 var c := Vector2i(plan.centro[0],plan.centro[1])
 for p in s.datos().puestos.values():
  if Vector2(c).distance_to(Vector2(p.celda[0],p.celda[1]))<32: return false # separación vigente
 for sitio in s.transitos.datos().get("solares",{}).values():
  if sitio.id==M.clave(c): continue
  var otra: Array=sitio.fundacion.edificio.area
  var area: Array=plan.edificio.area
  if Rect2i(area[0],area[1],area[2],area[3]).intersects(Rect2i(otra[0],otra[1],otra[2],otra[3])): return false
 if E.solar(j,plan.edificio,s)!="": return false
 for q in plan.campos:
  var campo := Vector2i(q[0],q[1])
  if not s.terreno_reparacion(campo,false) or j.d.mundo.techos.has(M.clave(campo)) or j.ocupada(campo): return false
 return s.ruta_sin_amenaza_conocida([plan.centro])

func origen_viable(p: Dictionary, ids: Array) -> bool:
 if not s._sostenible(p) or int(p.get("deuda_comida",0))>0 or int(s.balance_resumido(p).baya.vencido)>0: return false
 var oficios := {}
 var restantes := 0
 for r in p.residentes:
  if r.id in ids: continue
  if r.has("reserva_viaje"): continue
  restantes+=1;oficios[r.oficio]=true
  var herramienta := "hacha_piedra" if r.oficio=="recolector" else "pico_piedra"
  if int(r.get("usos",0))<=0 and int(s.inventario(p).get(herramienta,0))<=0: return false
 if float(restantes)>s.capacidad_alimentaria(p) and int(fuentes(Vector2i(p.celda[0],p.celda[1])).arbusto)<=0: return false
 if restantes==0 or not oficios.has("recolector") or not oficios.has("cantero"): return false
 if int(s.inventario(p).get("baya",0))<restantes: return false
 # Campos productivos existentes o acceso efectivo a alimento, sin acreditar cosechas futuras.
 for q in p.get("campos",[]):
  if j.mundo.constr_en(Vector2i(q[0],q[1])).get("t","")=="campo": return true
 return int(fuentes(Vector2i(p.celda[0],p.celda[1])).arbusto)>0

func validar_salida(op: Dictionary) -> bool:
 var p: Dictionary=s.transitos.puesto(op.origen)
 var sitio: Dictionary=s.transitos.puesto(op.destino)
 if sitio.is_empty() or not sitio.has("fundacion") or op.ids.size()!=2: return false
 var plan: Dictionary=sitio.fundacion
 if plan.origen!=op.origen or not solar(plan) or not origen_viable(p,op.ids): return false
 var oficios := {}
 for r in p.residentes:
  if r.id in op.ids: oficios[r.oficio]=true
 return oficios.has("recolector") and oficios.has("cantero") and Inv.tiene(op.bienes,plan.coste)

func intentar(p: Dictionary) -> bool:
 if not j.es_autoridad() or p.residentes.size()<=2 or p.has("obra"): return false
 var presion: Dictionary=p.get("presiones",{}).get("comida",{})
 if int(presion.get("duracion_min",0))<int(s.cfg.comida_min): return false
 if int(p.get("local_min",-1))<int(presion.get("desde",0)) or int(p.get("comercio_intento_min",-1))<int(presion.get("desde",0)): return false
 if int(s.balance_resumido(p).baya.en_curso)>0: return false
 if s.deficit_sostenible(p)<=0 and int(s.balance_resumido(p).baya.pendiente)<=0: return false
 for destino in s.datos().puestos.values():
  if destino.id==p.id or destino.residentes.is_empty() or not s._sostenible(destino): continue
  if s.capacidad(destino)<=destino.residentes.size()+s.transitos.reservas_plaza(destino.id): continue
  var saldo: Dictionary=s.balance_resumido(destino)
  if int(saldo.baya.stock)<=int(saldo.baya.reserva)+s.transitos.reservas_plaza(destino.id): continue
  var ruta: Array=s.transitos.ruta(p.id,destino.id)
  if not ruta.is_empty() and s.ruta_sin_amenaza_conocida(ruta): return false
 if int(p.get("fundacion_intento_min",-1))==int(j.d.min): return false
 p.fundacion_intento_min=int(j.d.min)
 for op in s.transitos.datos().operaciones.values():
  if op.origen==p.id and op.estado in ["reservada","viajando","detenida"]: return false
 var residentes: Array=p.residentes.duplicate();residentes.sort_custom(func(x,y):return str(x.id)<str(y.id))
 var elegidos: Array=[]
 for oficio in ["recolector","cantero"]:
  for r in residentes:
   if r.oficio==oficio and not r.has("reserva_viaje"): elegidos.append(r);break
 if elegidos.size()!=2: return false
 var bloques := {}
 for r in elegidos: bloques.merge(r.get("bloques",{}))
 var conocidos: Array=bloques.keys();conocidos.sort()
 var base := fuentes(Vector2i(p.celda[0],p.celda[1]))
 var b := int(s.a.reglas.conocimiento.bloque)
 for k in conocidos:
  var c := Vector2i(int(k.get_slice(",",0))*b+b/2,int(k.get_slice(",",1))*b+b/2)
  var plan := plano(p,c)
  if not solar(plan): continue
  var recursos := fuentes(c)
  if int(recursos.arbusto)<=int(base.arbusto) or int(recursos.arbol)<=0 or int(recursos.roca)<=0: continue
  var camino: Array=s.transitos.ruta_celdas(Vector2i(p.celda[0],p.celda[1]),c+Vector2i(0,3))
  if camino.is_empty() or not s.ruta_sin_amenaza_conocida(camino): continue
  var ids: Array=[]
  var carga: Dictionary=plan.coste.duplicate(true)
  # Una unidad para trabajar: mismo requisito del ejecutor, además de las comidas reales del trayecto.
  carga.baya=int(carga.get("baya",0))+1
  var comida := 0
  var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/s.transitos.H.VEL*C.MIN_POR_SEG))
  for r in elegidos:
   ids.append(r.id)
   comida+=maxi(0,floori(float(int(j.d.min)+duracion-int(r.get("comida_min",p.comida_min)))/float(s.cfg.comida_min)))
   if int(r.get("usos",0))<=0:
    var herramienta := "hacha_piedra" if r.oficio=="recolector" else "pico_piedra"
    carga[herramienta]=int(carga.get(herramienta,0))+1
  var provisiones := {"baya":comida} if comida>0 else {}
  var comprometido: Dictionary=carga.duplicate(true)
  E._sumar(comprometido,provisiones)
  comprometido.baya=int(comprometido.get("baya",0))+p.residentes.size()-elegidos.size()
  p.expedicion={"coste":comprometido,"centro":[c.x,c.y],"desde":int(j.d.min)}
  var sid := M.clave(c)
  var sitios: Dictionary=s.transitos.datos().get_or_add("solares",{})
  if sitios.has(sid): continue
  # Reserva de destino solo en Tránsitos: no aparece lugar/población/inventario en el mundo.
  sitios[sid]={"id":sid,"celda":[c.x,c.y+3],"dueno":p.dueno,"residentes":[],"camas":[],"fundacion":plan}
  var clave := "fundacion:%s:%s:%d" % [p.id,sid,int(j.d.min)]
  var reserva: Dictionary=s.transitos.reservar(clave,p.id,sid,ids,carga,provisiones,"fundacion")
  if not reserva.ok: sitios.erase(sid);continue
  reserva.operacion.ventaja={"origen":base,"destino":recursos,"causa":"crisis_sin_solucion_local_comercial_o_recepcion"}
  if not s.transitos.salir(clave).ok: s.transitos.cancelar(clave);continue
  p.crisis.operacion=clave
  p.erase("expedicion")
  return true
 return false

func llegar(op: Dictionary) -> bool:
 if not j.es_autoridad(): return false
 if s.datos().puestos.has(op.destino): return s.datos().puestos[op.destino].get("operacion_fundadora","")==op.id
 var sitio: Dictionary=s.transitos.puesto(op.destino)
 if not sitio.has("fundacion"): return false
 var plan: Dictionary=sitio.fundacion
 if not solar(plan) or not Inv.tiene(op.bienes,plan.coste): return false
 var c := Vector2i(plan.centro[0],plan.centro[1])
 var recursos := fuentes(c)
 if int(recursos.arbusto)<=0 or int(recursos.arbol)<=0 or int(recursos.roca)<=0: return false
 if E.instalar(j,plan.edificio,s)!="": return false
 Inv.quitar(op.bienes,plan.coste)
 for q in plan.campos:
  var campo := Vector2i(q[0],q[1])
  j.mundo.poner(campo,"campo",true,sitio.dueno);j.sembrar(campo)
 var camas: Array=[[c.x-2,c.y-2],[c.x+2,c.y-2]]
 var p := {"id":op.destino,"nombre":"Comunidad "+op.destino,"celda":plan.centro.duplicate(),"dueno":sitio.dueno,"cofre":"c@"+M.clave(c+Vector2i(0,-2)),"residentes":[],"camas":camas,"campos":plan.campos.duplicate(true),"edificios":[plan.edificio.id],"poblado":plan.poblado,"ultimo_min":int(op.reloj),"fundado_min":int(op.reloj),"comida_min":int(op.reloj),"produccion_min":int(op.reloj),"estado":"activo","producciones":0,"origen":"expedicion_real","operacion_fundadora":op.id}
 s.datos().puestos[op.destino]=p
 j.d.mundo.poblados[plan.poblado]={"id":plan.poblado,"nombre":p.nombre,"estado":"activo","centro":plan.centro.duplicate(),"entrada":[c.x,c.y+3],"area":[c.x-3,c.y-3,7,7],"esenciales":[[c.x,c.y+3],[c.x,c.y+1],[c.x,c.y+2]],"camas":{},"residentes":[],"puesto":p.id}
 op.construccion={"edificio":plan.edificio.id,"coste":plan.coste.duplicate(true),"min":int(op.reloj)}
 s.transitos.datos().solares.erase(op.destino)
 return true
