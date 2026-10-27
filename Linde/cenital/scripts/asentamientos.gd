extends RefCounted
## Puestos del jugador y comunidades preexistentes. Una sola población regional resumida, sin cargar regiones lejanas.
## Extrae recursos reales del mapa y cosecha campos reales; no hay producción gratuita al descargar.
const M=preload("res://scripts/mundo.gd")
const Lugares = preload("res://scripts/lugares.gd")
const Edificios = preload("res://scripts/edificios.gd")
const Inv = preload("res://scripts/inventario.gd")
const C=preload("res://scripts/catalogos.gd")
var a
var j
const Transitos = preload("res://scripts/transitos.gd")
var transitos
const Fundacion = preload("res://scripts/fundacion.gd")
var fundacion
var cfg: Dictionary
const PIEZAS = [["cama_huesped",1,0],["cama_huesped",1,1],["campo",-1,0],["campo",-1,1],["cofre",0,2]]
func _init(autonomia) -> void:
 a=autonomia;j=a.j
 transitos=Transitos.new(self)
 fundacion=Fundacion.new(self)
 cfg=JSON.parse_string(FileAccess.get_file_as_string("res://datos/asentamientos/reglas_v1.json"))
func datos() -> Dictionary:
 if not a.activa():return {}
 var raiz: Dictionary=j.d.mundo_vivo.autonomia
 if not raiz.has("asentamientos"):raiz.asentamientos={"version":1,"puestos":{}}
 return raiz.asentamientos
func inventario(p: Dictionary) -> Dictionary:
 return j.d.cofres[p.cofre].inv
func validar(c: Vector2i) -> String:
 if not a.activa():return "El puesto requiere un mundo autónomo"
 if M.Terreno.distancia_valle(c)<32:return "Busca un lugar a 32 celdas del valle"
 if datos().puestos.values().filter(func(p): return not p.has("poblado")).size()>=int(cfg.max_puestos):return "Ya hay tres puestos regionales"
 for p in datos().puestos.values():
  if Vector2(c).distance_to(Vector2(p.celda[0],p.celda[1]))<32:return "Demasiado cerca de otro puesto"
 for dy in range(-1,4):
  for dx in range(-2,3):
   var celda:=c+Vector2i(dx,dy)
   if j.mundo.puede_poner(celda)!="":return "El puesto necesita un solar libre de 5 por 5"
   var construida: bool=celda==c
   for pieza in PIEZAS:
    if celda==c+Vector2i(int(pieza[1]),int(pieza[2])):construida=true
   if construida and j.ocupada(celda):return "Hay alguien donde irá una pieza del puesto"
 return ""
func crear(c: Vector2i, dueno: String, poblado_id: String = "", nombre: String = "") -> bool:
 var k:=M.clave(c)
 var cid:="c@"+M.clave(c+Vector2i(0,2))
 var camas: Array = [[c.x+1,c.y],[c.x+1,c.y+1]]
 var campos: Array = [[c.x-1,c.y],[c.x-1,c.y+1]]
 if poblado_id != "":
  var e := Edificios.plano("casa_regional",c+Vector2i(0,2),dueno,poblado_id)
  var motivo := Edificios.instalar(j,e)
  if motivo != "":
   return false
  camas = [[c.x-2,c.y-2],[c.x+2,c.y-2]]
  campos = [[c.x-2,c.y+3],[c.x+2,c.y+3]]
  cid = "c@"+M.clave(c+Vector2i(0,-2))
  for q in campos:
   var campo := Vector2i(q[0],q[1])
   j.mundo.poner(campo,"campo",true,dueno)
   j.sembrar(campo)
 else:
  for pieza in PIEZAS:
   var celda:=c+Vector2i(int(pieza[1]),int(pieza[2]))
   j.mundo.poner(celda,pieza[0],true,dueno)
   j.sembrar(celda)
  for dy in [0,1]:j.mundo.techar(c+Vector2i(1,dy),dueno)
 j.d.cofres[cid]={"inv":{"baya":4,"hacha_piedra":1,"pico_piedra":1}}
 datos().puestos[k]={"id":k,"nombre":"Puesto "+str(datos().puestos.size()+1),"celda":[c.x,c.y],"dueno":dueno,"cofre":cid,"residentes":[],"ultimo_min":int(j.d.min),"fundado_min":int(j.d.min),"llegada_min":int(j.d.min),"comida_min":int(j.d.min),"produccion_min":int(j.d.min),"estado":"esperando colonos","producciones":0}
 if poblado_id != "":
  var p: Dictionary = datos().puestos[k]
  p.camas = camas
  p.campos = campos
  p.edificios = ["edificio@"+M.clave(c+Vector2i(0,2))]
  p.poblado = poblado_id
  p.nombre = nombre
  p.estado = "activo"
  p.origen = "preexistente"
  var nombres = j._rng("nombres_preexistentes",poblado_id)
  var primero: int = nombres.randi() % cfg.nombres.size()
  for i in int(cfg.capacidad):
   var rng = j._rng("residente_preexistente", poblado_id + ":" + str(i))
   var nid := "regional:" + poblado_id + ":" + str(i)
   var r := {"id": nid, "nombre": cfg.nombres[(primero + i) % cfg.nombres.size()], "oficio": "recolector" if i == 0 else "cantero", "look": [rng.randi_range(0,2),rng.randi_range(0,2),rng.randi_range(0,2)], "hogar": poblado_id, "historia": "Trabaja en " + nombre + " desde antes de tu llegada.", "bloques": {}}
   a._ver(r, c, int(a.reglas.conocimiento.radio_inicial))
   p.residentes.append(r)
  var asignaciones := {}
  var ids: Array = []
  for i in p.residentes.size():
   ids.append(p.residentes[i].id)
   asignaciones[p.residentes[i].id] = camas[i]
  j.d.mundo.poblados[poblado_id] = {"id": poblado_id, "nombre": nombre, "estado": "activo", "centro": [c.x,c.y], "entrada": [c.x,c.y+3], "area": [c.x-3,c.y-3,7,7], "esenciales": [[c.x,c.y+3],[c.x,c.y+1],[c.x,c.y+2]], "camas": asignaciones, "residentes": ids, "puesto": k}
 else:
  j.aviso_todos("Se funda un puesto regional. Lleva comida a su cofre para atraer residentes.")
 return true
func _sostenible(p: Dictionary) -> bool:
 var c:=Vector2i(p.celda[0],p.celda[1])
 if j.mundo.constr_en(c).get("t","")!="puesto" or not j.d.cofres.has(p.cofre):return false
 return capacidad(p)>0 and capacidad(p)>=p.residentes.size()

func camas_funcionales(p: Dictionary) -> Array:
 var c:=Vector2i(p.celda[0],p.celda[1])
 var alcance := _alcance(c)
 var salida: Array=[]
 for q in p.get("camas",[[c.x+1,c.y],[c.x+1,c.y+1]]):
  if q in salida: continue
  var cama := Vector2i(q[0],q[1])
  var pieza: Dictionary=j.mundo.constr_en(cama)
  if not pieza.get("t","") in ["cama","cama_huesped"] or not j.d.mundo.techos.has(M.clave(cama)): continue
  if pieza.get("dueno",p.dueno)!=p.dueno: continue
  for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   if alcance.has(cama+v): salida.append(q);break
 return salida

func capacidad(p: Dictionary) -> int:
 return camas_funcionales(p).size()

func _transitable(c: Vector2i) -> bool:
 if not j.mundo.generador.valida(c):return false
 var d: Dictionary=j.mundo.generador.datos(c)
 if int(d.tipo)==M.T.AGUA or j.mundo.tipo(c) in [M.T.AGUA,M.T.PARED,M.T.MURO_RUINA]:return false
 if C.CONSTR.get(j.mundo.constr_en(c).get("t",""),{}).get("bloquea",false):return false
 var id: String=str(d.objeto)+"@"+M.clave(c)
 return j.mundo.estado.get("registro",{}).get("despejes",{}).has(M.clave(c)) or str(d.objeto)=="" or not C.OBJETOS.get(str(d.objeto),{}).get("bloquea",true) or j.d.mundo.rotos.has(id)
func _alcance(centro: Vector2i) -> Dictionary:
 var vistos: Dictionary={centro:true}
 var cola: Array=[centro]
 var i:=0
 var r:=int(cfg.radio_recursos)+1
 while i<cola.size():
  var c: Vector2i=cola[i];i+=1
  for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   var n: Vector2i=c+v
   if maxi(absi(n.x-centro.x),absi(n.y-centro.y))>r or vistos.has(n) or not _transitable(n):continue
   vistos[n]=true;cola.append(n)
 return vistos
func _extraer(p: Dictionary, oficio: String, residente_actual: Dictionary = {}, objetivo: String = "materiales") -> bool:
 if not j.es_autoridad(): return false
 var saldo: Dictionary = balance_resumido(p)[objetivo]
 if int(saldo.pendiente) <= 0: return false
 var coste: Dictionary=p.get("obra",p.get("expedicion",{})).get("coste",{})
 var producto := "madera" if oficio=="recolector" else "piedra"
 if objetivo=="materiales" and not coste.is_empty() and int(inventario(p).get(producto,0))>=int(coste.get(producto,0)):
  var otro := "piedra" if producto=="madera" else "madera"
  if int(inventario(p).get(otro,0))<int(coste.get(otro,0)): return false
 var centro:=Vector2i(p.celda[0],p.celda[1])
 var tipos: Array = ["arbusto"] if objetivo == "baya" else (["arbol"] if oficio=="recolector" else ["roca"])
 var alcance:=_alcance(centro)
 for radio in range(2,int(cfg.radio_recursos)+1):
  for dy in range(-radio,radio+1):
   for dx in range(-radio,radio+1):
    if maxi(absi(dx),absi(dy))!=radio:continue
    var c:=centro+Vector2i(dx,dy)
    if not j.mundo.generador.valida(c) or not j.mundo.constr_en(c).is_empty() or j.mundo.estado.get("registro",{}).get("despejes",{}).has(M.clave(c)):continue
    var d: Dictionary=j.mundo.generador.datos(c)
    if not d.objeto in tipos:continue
    var accesible:=false
    for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
     if alcance.has(c+v):accesible=true
    if not accesible:continue
    var id: String=str(d.objeto)+"@"+M.clave(c)
    var def: Dictionary=C.OBJETOS[d.objeto]
    if j.d.mundo.rotos.has(id):
     var regeneracion:int=int(def.regen_h)*60
     if regeneracion<=0 or int(j.d.min)-int(j.d.mundo.rotos[id])<regeneracion:continue
    # Un paso productivo es una extracción completa real, anotada con el mismo ID que el jugador.
    var antes := inventario(p).duplicate(true)
    var usos_antes := int(residente_actual.get("usos",0))
    j.mundo.romper(id,int(j.d.min))
    j.d.mundo.golpes.erase(id)
    var drops: Dictionary=def.drops.duplicate()
    if objetivo=="baya":
     var rng=j._rng("sociedad","%s:%s:%d" % [residente_actual.get("id",""),id,int(j.d.min)])
     for prob in def.prob:
      if rng.randf()<float(prob.p): drops[prob.item]=int(drops.get(prob.item,0))+int(prob.q)
    for item in drops:inventario(p)[item]=int(inventario(p).get(item,0))+int(drops[item])
    p.producciones=int(p.producciones)+1
    if not residente_actual.is_empty() and objetivo == "materiales": residente_actual.usos = usos_antes-1
    _resultado_regional(p,"recoleccion_alimento" if objetivo == "baya" else "extraccion",saldo,antes,{"objeto":id,"actor":residente_actual.get("id", ""),"usos_antes":usos_antes,"usos_despues":residente_actual.get("usos",usos_antes)})
    return true
 return false
func actualizar() -> void:
 if not a.activa() or not j.es_autoridad():return
 transitos.actualizar()
 for p in datos().puestos.values():
  if p.has("poblado"):
   var pueblo: Dictionary = j.mundo.poblado(p.poblado)
   if pueblo.get("estado", "") in ["abandonado", "destruido"]: continue
   pueblo.estado = "sin_residentes" if p.residentes.is_empty() else ("activo" if _sostenible(p) and int(inventario(p).get("baya",0)) > 0 else "sin_sustento")
   _conocimiento(p)
  var reparador := reparar_local(p) if not _sostenible(p) else ""
  if not _sostenible(p):
   p.estado="faltan puesto, camas, techo o cofre"
   p.produccion_min=int(j.d.min)
   continue
  if reparador!="": p.produccion_min=int(j.d.min)-int(cfg.produccion_min)
  var inv: Dictionary=inventario(p)
  var c:=Vector2i(p.celda[0],p.celda[1])
  for q in p.get("campos",[[c.x-1,c.y],[c.x-1,c.y+1]]):
   var campo:=Vector2i(q[0],q[1])
   if not p.residentes.is_empty() and j.campo_listo(campo):
    var saldo: Dictionary = balance_resumido(p).baya
    var antes := inv.duplicate(true)
    var cosecha: Dictionary=j.cosechar(campo)
    for item in cosecha:inv[item]=int(inv.get(item,0))+int(cosecha[item])
    _resultado_regional(p,"cosecha",saldo,antes,{"campo":M.clave(campo)})
  # Tiempo del servidor, no tiempo de pared. Guardar/cargar no repite una cosecha o un consumo.
  var ocupados := resolver_local(p,{reparador:true} if reparador!="" else {})
  var alimento: Dictionary = balance_resumido(p).baya
  if int(alimento.deuda)>0:
   if not _consumir_regional(p,int(alimento.deuda),alimento,"pago_deuda"):p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
   p.deuda_comida=0
  alimento = balance_resumido(p).baya
  if int(j.d.min)-int(p.comida_min)>=int(cfg.comida_min):
   var base := int(p.comida_min)
   var periodos:=floori(float(int(j.d.min)-base)/float(cfg.comida_min))
   var coste:int=int(alimento.vencido)
   for r in p.residentes:
    var ultimo := int(r.get("comida_min",base))
    r.comida_min=ultimo+maxi(0,floori(float(int(j.d.min)-ultimo)/float(cfg.comida_min)))*int(cfg.comida_min)
   p.comida_min=base+periodos*int(cfg.comida_min)
   if not _consumir_regional(p,coste,alimento,"consumo"):p.deuda_comida=coste;p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
  # La llegada requiere transferencia de una identidad existente, no población por calendario.
  if p.residentes.is_empty():
   p.estado="sin residentes"
   p.produccion_min=int(j.d.min)
   continue
  if int(j.d.min)-int(p.produccion_min)>=int(cfg.produccion_min):
   var periodos:=mini(24,floori(float(int(j.d.min)-int(p.produccion_min))/float(cfg.produccion_min)))
   p.produccion_min=int(p.produccion_min)+periodos*int(cfg.produccion_min)
   p.estado="activo"
   for periodo in periodos:
    var turno_min := int(p.produccion_min)-(periodos-periodo-1)*int(cfg.produccion_min)
    for residente in p.residentes:
     if int(residente.get("trabajo_min",p.get("fundado_min",0)))>turno_min: continue
     if residente.has("reserva_viaje"): continue
     if periodo == 0 and ocupados.has(residente.id): continue
     var herramienta: String="hacha_piedra" if residente.oficio=="recolector" else "pico_piedra"
     var saldo_herramienta: Dictionary = balance_resumido(p)[herramienta] if int(residente.get("usos",0))<=0 else {}
     if int(residente.get("usos",0))<=0:
      if int(saldo_herramienta.stock)<=0:
       p.estado="faltan herramientas en el cofre"
       _bloqueo_regional(p,"sin_herramienta",saldo_herramienta)
       continue
      var antes := inv.duplicate(true)
      var usos_antes := int(residente.get("usos",0))
      inv[herramienta]=int(inv[herramienta])-1;residente.usos=50
      _resultado_regional(p,"asignar_herramienta",saldo_herramienta,antes,{"actor":residente.id,"usos_antes":usos_antes,"usos_despues":50})
     if int(inv.get("baya",0))<=0:
      p.estado="sin comida; producción detenida"
      _bloqueo_regional(p,"sin_comida_para_trabajar",balance_resumido(p).baya)
      continue
     var saldo_materiales: Dictionary = balance_resumido(p).materiales
     if int(saldo_materiales.pendiente)<=0:p.estado="reservas completas";continue
     if not _extraer(p,residente.oficio,residente):
      p.estado="faltan recursos cercanos"
      _bloqueo_regional(p,"sin_recurso_accesible",saldo_materiales)
  p.ultimo_min=int(j.d.min)
func visibles() -> Array:
 var resultado: Array=[]
 if not a.activa():return resultado
 for p in datos().puestos.values():
  var c:=Vector2i(p.celda[0],p.celda[1])
  if not j.mundo.region_cargada(c):continue
  for i in p.residentes.size():
   var r: Dictionary=p.residentes[i]
   var fase:=posmod(int(j.d.min),60)
   var t:=clampf(float(fase)/2.0,0,1) if fase<30 else 1.0-clampf(float(fase-30)/2.0,0,1)
   var desde:=M.pies_de_celda(c+Vector2i(0,i))
   var hasta:=M.pies_de_celda(c+Vector2i(1 if p.has("edificios") else -1,i))
   resultado.append({"id":r.id,"nombre":r.nombre,"look":r.look,"pos":desde.lerp(hasta,t),"mueve":fase<2 or (fase>=30 and fase<32)})
 for op in transitos.datos().operaciones.values():
  if not op.estado in ["viajando","detenida"]: continue
  var pos: Vector2 = transitos.posicion(op)
  if not j.mundo.region_cargada(M.celda_de(pos)): continue
  for r in op.miembros: resultado.append({"id":r.id,"nombre":r.nombre,"look":r.look,"pos":pos,"mueve":op.estado=="viajando"})
 return resultado


## Génesis de 1–2 comunidades adicionales. Reutiliza el plan de lugares y crear(), sin recursos extra ni simulación paralela.
## Se ejecuta una vez por mundo y solo en autoridad; no es fundación autónoma (Fase 6).
func inicializar_preexistentes() -> void:
 if not a.activa() or not j.es_autoridad() or j.mundo.modo_inicio() != M.MODO_POBLADO: return
 var d := datos()
 if d.has("preexistentes"): return
 var generacion: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://datos/asentamientos/preexistentes_v1.json"))
 var huella: Array = []
 var plantilla := Edificios.plano("casa_regional",Vector2i(0,2),"generacion")
 for k in plantilla.piezas:
  if C.CONSTR[plantilla.piezas[k].t].get("bloquea",false):
   var q := Edificios._celda(k)
   huella.append([q.x,q.y])
 generacion.emplazamiento.huella = huella
 var elegidos: Array = []
 for dato in generacion.macros_candidatas:
  if elegidos.size() >= int(generacion.cantidad): break
  var r := Vector2i(dato[0],dato[1])
  var plan := Lugares.plan_macro(j.mundo, r, generacion.emplazamiento)
  var id := "poblado@" + M.clave(r)
  if not plan.lugares.has(id): continue
  if j.d.mundo.get("registro",{}).get("macros",{}).has(M.clave(r)): continue
  var lugar: Dictionary = plan.lugares[id]
  lugar.nombre = generacion.nombres[elegidos.size()]
  lugar.poblado = id
  var mundo_anterior: Dictionary=j.d.mundo.duplicate(true)
  var cofres_anteriores: Dictionary=j.d.cofres.duplicate(true)
  Lugares.ampliar(j, r, plan)
  var c := Vector2i(lugar.centro[0],lugar.centro[1])
  j.mundo.actualizar_regiones([c])
  if not crear(c,"poblado:"+id,id,lugar.nombre):
   # Una candidata rechazada no deja rutas, cofres o edificios huérfanos.
   j.d.mundo.clear();j.d.mundo.merge(mundo_anterior,true)
   j.d.cofres=cofres_anteriores
   j.mundo.configurar(int(j.d.semilla))
   j.mundo.actualizar_regiones([c])
   continue
  j.d.mundo.registro.poblados.append(id)
  elegidos.append(id)
 d.preexistentes = {"version": generacion.version, "ids": elegidos}
 j.actualizar_regiones()

## La identidad y los recuerdos permanecen en el residente resumido; nunca se añade otro actor detallado al acercarse.
func residente(nid: String) -> Dictionary:
 for p in j.d.get("mundo_vivo",{}).get("autonomia",{}).get("asentamientos",{}).get("puestos",{}).values():
  for r in p.residentes:
   if r.id == nid: return r
 for op in transitos.datos().operaciones.values():
  for r in op.miembros:
   if r.id==nid: return r
 return {}

## Posición de la representación actual, solo donde el mundo está cargado.
func posicion(nid: String) -> Vector2:
 for r in visibles():
  if r.id == nid: return r.pos
 return Vector2.INF

func _conocimiento(p: Dictionary) -> void:
 var c := Vector2i(p.celda[0],p.celda[1])
 for r in p.residentes:
  if not r.has("bloques"): r.bloques = {}
  a._ver(r,c,int(a.reglas.conocimiento.radio_vision))
  for otro in p.residentes:
   r.bloques.merge(otro.get("bloques",{}))
  for nid in j.habitantes.ids:
   if Vector2(M.celda_de(j.habitantes.pos(nid))).distance_to(Vector2(c)) <= float(a.reglas.conocimiento.radio_rumor):
    var n: Dictionary = a.estado(nid)
    r.bloques.merge(n.get("bloques",{}))
    n.get_or_add("bloques",{}).merge(r.bloques)

## Bloques que cuentan los residentes cercanos, con el mismo radio de rumor de Autonomia.
func rumores_cerca(c: Vector2i) -> Dictionary:
 var bloques := {}
 for p in j.d.get("mundo_vivo",{}).get("autonomia",{}).get("asentamientos",{}).get("puestos",{}).values():
  if not p.has("poblado"): continue
  if Vector2(c).distance_to(Vector2(p.celda[0],p.celda[1])) > float(a.reglas.conocimiento.radio_rumor): continue
  for r in p.residentes: bloques.merge(r.get("bloques",{}))
 return bloques

## Saludo basado en identidad y estado económico real, sin misión ni recompensa.
func dialogo(nid: String) -> String:
 var r := residente(nid)
 if r.is_empty(): return ""
 var pueblo: Dictionary = j.mundo.poblado(r.get("hogar",""))
 var p: Dictionary = datos().puestos.get(pueblo.get("puesto",""),{})
 return "Soy %s de %s. Aquí trabajo como %s. Situación de la comunidad: %s. Puedes preguntar por lugares con L o consultar las reservas del pueblo en J." % [r.nombre, pueblo.get("nombre", "este puesto"), r.oficio, p.get("estado", "sin información")]

## Vista persistible, sin otro inventario ni simulador. Los grupos conservan su titularidad.
func demandas_colectivas() -> Dictionary:
 var resultado := {}
 if a.sociedad.activa():
  var grupos := {}
  for gid in a.sociedad.cfg.grupos: grupos[gid] = a.sociedad.balance_grupo(gid)
  resultado[M.ID_INICIAL] = {"modo":"detallado", "grupos":grupos}
 for p in datos().puestos.values():
  var pid: String = p.get("poblado", "puesto:" + str(p.id))
  resultado[pid] = {"modo":"resumido", "items":balance_resumido(p), "ejecucion":"saldos_conectados"}
 return resultado

## Adaptador de contabilidad: solo deuda/consumo vencido y herramientas ya exigidas.
## Comparte obligaciones y límite con el ejecutor; nunca promete tasas futuras ni cosechas sin ejecutar.
func balance_resumido(p: Dictionary) -> Dictionary:
 var inv: Dictionary = j.d.cofres.get(p.cofre, {}).get("inv", {})
 var periodos := maxi(0, floori(float(int(j.d.min) - int(p.comida_min)) / float(cfg.comida_min)))
 var vencido := 0
 for r in p.residentes: vencido+=maxi(0,floori(float(int(j.d.min)-int(r.get("comida_min",p.comida_min)))/float(cfg.comida_min)))
 var materiales := int(inv.get("madera",0)) + int(inv.get("piedra",0))
 var trabajadores: Array=p.residentes.duplicate()
 trabajadores.append_array(transitos.retornos(str(p.id)))
 var objetivo_materiales := int(cfg.tope_stock) if not trabajadores.is_empty() else 0
 # El ejecutor ya exige stock de comida > 0 para trabajar; no consume esta unidad.
 var comida_trabajo := 1 if materiales<objetivo_materiales else 0
 var objetivos := {"baya":int(p.get("deuda_comida", 0)) + vencido + maxi(comida_trabajo,p.residentes.size())}
 for r in trabajadores:
  if int(r.get("usos", 0)) > 0: continue
  var herramienta: String = "hacha_piedra" if r.oficio == "recolector" else "pico_piedra"
  objetivos[herramienta] = int(objetivos.get(herramienta, 0)) + 1
 var obra: Dictionary=p.get("obra",p.get("expedicion",{})).duplicate(true)
 if p.has("cultivo_pendiente"):
  obra.get_or_add("coste",{})
  Edificios._sumar(obra.coste,p.cultivo_pendiente.coste)
 if not obra.is_empty():
  for item in obra.coste: objetivos[item]=maxi(int(objetivos.get(item,0)),int(obra.coste[item]))
  objetivo_materiales=maxi(objetivo_materiales,int(obra.coste.get("madera",0))+int(obra.coste.get("piedra",0)))
 var saldos := {}
 for item in objetivos:
  var objetivo := int(objetivos[item])
  var stock := int(inv.get(item, 0))
  var entrante: int = transitos.entrante(str(p.id),str(item))
  saldos[item] = {"id":"%s:%s" % [p.get("poblado", "puesto:" + str(p.id)),item], "reserva":objetivo, "stock":stock, "comprometido":0, "en_curso":entrante, "pendiente":maxi(0, objetivo-stock-entrante)}
 saldos.baya.deuda = int(p.get("deuda_comida",0))
 saldos.baya.vencido = vencido
 saldos.baya.trabajo = comida_trabajo
 # Bolsa de control del límite existente: no es un ítem ni un inventario nuevo.
 var faltante_obra := 0
 for item in ["madera","piedra"]: faltante_obra+=maxi(0,int(obra.get("coste",{}).get(item,0))-int(inv.get(item,0)))
 saldos.materiales = {"id":"%s:materiales" % p.get("poblado", "puesto:" + str(p.id)),"componentes":["madera","piedra"],"reserva":objetivo_materiales,"stock":materiales,"comprometido":0,"en_curso":0,"pendiente":maxi(faltante_obra,objetivo_materiales-materiales)}
 return saldos

func actualizar_demandas() -> void:
 if not a.activa() or not j.es_autoridad(): return
 for p in datos().puestos.values():
  p.viabilidad = evaluar_viabilidad(p)
  registrar_presion(p)
 for p in datos().puestos.values(): resolver_crisis(p)
 for p in datos().puestos.values(): planear_crecimiento(p)
 datos().demandas = {"version":1, "min":int(j.d.min), "poblados":demandas_colectivas()}


## Contabilidad aditiva en el puesto original; solo registra operaciones ya aplicadas.
func economia_regional(p: Dictionary) -> Dictionary:
 if not p.has("economia"): p.economia = {"version":1,"secuencia":0,"resultados":[],"bloqueo":{}}
 return p.economia

func _resultado_regional(p: Dictionary, causa: String, demanda: Dictionary, antes: Dictionary, detalle: Dictionary = {}) -> void:
 if not j.es_autoridad(): return
 var delta := {}
 var despues := inventario(p)
 var items := antes.keys()
 for item in despues:
  if not item in items: items.append(item)
 for item in items:
  var cantidad := int(despues.get(item,0))-int(antes.get(item,0))
  if cantidad != 0: delta[item] = cantidad
 if delta.is_empty(): return
 var e := economia_regional(p)
 e.secuencia = int(e.secuencia)+1
 e.resultados.append({"id":"%s:%d" % [p.id,int(e.secuencia)],"min":int(j.d.min),"causa":causa,"demanda":demanda.duplicate(true),"delta":delta,"detalle":detalle.duplicate(true)})
 while e.resultados.size()>int(a.reglas.sociedad.tope_sucesos): e.resultados.pop_front()
 e.bloqueo = {}

func _bloqueo_regional(p: Dictionary, causa: String, demanda: Dictionary) -> void:
 if not j.es_autoridad(): return
 var e := economia_regional(p)
 # Estado actual, no una cola de reintentos ni una sucesión de resultados sin efecto.
 if e.bloqueo.get("causa", "") == causa and e.bloqueo.get("demanda", "") == demanda.id: return
 e.bloqueo = {"min":int(j.d.min),"causa":causa,"demanda":demanda.id}

func _consumir_regional(p: Dictionary, cantidad: int, saldo: Dictionary, causa: String) -> bool:
 if not j.es_autoridad(): return false
 if int(saldo.stock)<cantidad:
  _bloqueo_regional(p,"sin_comida",saldo)
  return false
 if cantidad<=0: return true
 var inv := inventario(p)
 var antes := inv.duplicate(true)
 inv.baya=int(inv.get("baya",0))-cantidad
 _resultado_regional(p,causa,saldo,antes)
 return true


## Alternativas materiales dentro del mismo presupuesto de trabajo regional.
func resolver_local(p: Dictionary, previos: Dictionary = {}) -> Dictionary:
 var usados := previos.duplicate()
 if not j.es_autoridad() or int(j.d.min)-int(p.produccion_min)<int(cfg.produccion_min): return usados
 if int(p.get("local_min",-1)) == int(j.d.min): return usados
 p.local_min = int(j.d.min)
 var residentes: Array = p.residentes.duplicate()
 residentes.sort_custom(func(x,y): return str(x.id)<str(y.id))
 for r in residentes:
  if r.has("reserva_viaje") or usados.has(r.id): continue
  var saldos := balance_resumido(p)
  if int(saldos.baya.pendiente)>0 and _extraer(p,r.oficio,r,"baya"):
   usados[r.id] = true
   continue
  var recetas: Array = r.get("recetas",[]).duplicate()
  recetas.sort()
  for rid in recetas:
   if not C.RECETAS.has(rid): continue
   var receta: Dictionary = C.RECETAS[rid]
   if receta.get("hab", "") != "" or receta.get("herr", "") != "": continue
   var responde := false
   var demanda := {}
   for item in receta.sal:
    if saldos.has(item) and int(saldos[item].pendiente)>0:
     responde = true
     demanda = saldos[item]
   if not responde or not Inv.tiene(inventario(p),receta.ent): continue
   if str(receta.est)!="" and not estacion_regional(p,str(receta.est)): continue
   var antes := inventario(p).duplicate(true)
   Inv.quitar(inventario(p),receta.ent)
   for item in receta.sal: inventario(p)[item]=int(inventario(p).get(item,0))+int(receta.sal[item])
   _resultado_regional(p,"fabricacion_local",demanda,antes,{"actor":r.id,"receta":rid})
   a.desarrollo.registrar("npc:"+str(r.id),"artesania",receta.ent)
   usados[r.id] = true
   break
 if usados.is_empty():
  var agricultor := ampliar_cultivo(p)
  if agricultor!="": usados[agricultor]=true
 if usados.is_empty():
  var constructor := ejecutar_obra(p)
  if constructor!="": usados[constructor]=true
 a.desarrollo.ensenar_regional(p,usados)
 if usados.is_empty(): transitos.comerciar(p)
 return usados

func estacion_regional(p: Dictionary, tipo: String) -> bool:
 var alcance := _alcance(Vector2i(p.celda[0],p.celda[1]))
 for k in j.d.mundo.constr:
  if C.CONSTR.get(j.d.mundo.constr[k].t,{}).get("est", "")!=tipo: continue
  var c := Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
  for v in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if alcance.has(c+v): return true
 return false

## Observación factual; no inventa umbrales de crisis ni seguridad lejana.
func evaluar_viabilidad(p: Dictionary) -> Dictionary:
 var saldo := balance_resumido(p)
 var camas := capacidad(p)
 var amenazas: Array = []
 var pueblo: Dictionary = j.mundo.poblado(p.get("poblado", ""))
 var area: Array = pueblo.get("area", [])
 if area.size()==4:
  var rect := Rect2i(area[0],area[1],area[2],area[3])
  for enemigo in j.combate.enemigos:
   if enemigo.get("est", "")!="muerto" and rect.has_point(M.celda_de(enemigo.pos)): amenazas.append(str(enemigo.get("fauna_id",str(enemigo.tipo)+"@"+M.clave(M.celda_de(enemigo.pos)))))
 amenazas.sort()
 var observada: bool = j.mundo.region_cargada(Vector2i(p.celda[0],p.celda[1]))
 return {"min":int(j.d.min),"residentes":p.residentes.size(),"camas":camas,"deficit_comida":int(saldo.baya.pendiente),"infraestructura":_sostenible(p),"amenazas_observadas":amenazas,"seguridad":"no_observada" if not observada else ("amenazas_observadas" if not amenazas.is_empty() else "sin_amenazas_observadas"),"politica_crisis":"ciclo_y_mejora_material_aprobados"}


## Reparar la infraestructura propia usa las mismas validaciones y costes que el jugador.
func reparar_local(p: Dictionary) -> String:
 if not j.es_autoridad() or p.residentes.is_empty() or not j.d.cofres.has(p.cofre): return ""
 if int(j.d.min)-int(p.produccion_min)<int(cfg.produccion_min) or int(p.get("reparacion_min",-1))==int(j.d.min): return ""
 var actor := ""
 for r in p.residentes:
  if not r.has("reserva_viaje") and (actor=="" or str(r.id)<actor): actor=r.id
 if actor=="": return ""
 var alcance := _alcance(Vector2i(p.celda[0],p.celda[1]))
 for id in p.get("edificios",[]):
  var e: Dictionary=j.d.mundo.registro.edificios.get(id,{})
  if e.is_empty() or e.dueno!=p.dueno: continue
  var entrada := Vector2i(e.entrada[0],e.entrada[1])
  if not alcance.has(entrada+Vector2i.DOWN): continue
  var antes := inventario(p).duplicate(true)
  var resultado := Edificios.reparar(j,e,inventario(p),self)
  if not resultado.ok: continue
  p.reparacion_min=int(j.d.min)
  _resultado_regional(p,"reparacion_local",{"id":id},antes,{"actor":actor})
  a.desarrollo.registrar("npc:"+actor,"construccion",resultado.coste)
  return actor
 return ""

## Medición de persistencia de carencias, sin convertir duración en umbral de crisis.
func registrar_presion(p: Dictionary) -> void:
 if not j.es_autoridad(): return
 var saldo := balance_resumido(p)
 var faltas := {"comida":maxi(deficit_sostenible(p),maxi(0,int(saldo.baya.deuda)+int(saldo.baya.vencido)+maxi(int(saldo.baya.trabajo),p.residentes.size())-int(saldo.baya.stock))),"camas":maxi(0,p.residentes.size()-int(p.viabilidad.camas))}
 if not p.has("presiones"): p.presiones={}
 for causa in faltas:
  if int(faltas[causa])<=0:
   p.presiones.erase(causa)
   continue
  var presion: Dictionary=p.presiones.get_or_add(causa,{"desde":int(j.d.min)})
  presion.ultimo_min=int(j.d.min)
  presion.duracion_min=int(j.d.min)-int(presion.desde)
  presion.deficit=int(faltas[causa])
  presion.alternativa_local_min=int(p.get("local_min",-1))
  presion.cobertura_en_curso=int(saldo.baya.en_curso) if causa=="comida" else 0


func terreno_reparacion(c: Vector2i, techo: bool) -> bool:
 if not j.mundo.generador.valida(c) or not j.mundo.tipo(c) in [M.T.PASTO,M.T.CAMINO,M.T.SUELO]: return false
 var d: Dictionary=j.mundo.generador.datos(c)
 var despejada: bool=j.d.mundo.registro.get("despejes",{}).has(M.clave(c))
 if not despejada and str(d.objeto)!="":
  var oid := str(d.objeto)+"@"+M.clave(c)
  if not j.d.mundo.rotos.has(oid): return false
  var horas := int(C.OBJETOS.get(str(d.objeto),{}).get("regen_h",0))
  if horas>0 and int(j.d.min)-int(j.d.mundo.rotos[oid])>=horas*60: return false
 return not j.d.mundo.techos.has(M.clave(c)) if techo else j.mundo.constr_en(c).is_empty()

func caja_regional(pies: Vector2) -> bool:
 var a := Vector2i(((pies-Vector2(M.P.PIES.x/2,M.P.PIES.y))/M.P.CELDA).floor())
 var b := Vector2i(((pies+Vector2(M.P.PIES.x/2,0)-Vector2(0.001,0.001))/M.P.CELDA).floor())
 for y in range(a.y,b.y+1):
  for x in range(a.x,b.x+1):
   if not _transitable(Vector2i(x,y)): return false
 return true

func acceso_reparacion(e: Dictionary) -> bool:
 var entrada := Vector2i(e.entrada[0],e.entrada[1])
 var alcance := _alcance(entrada+Vector2i.DOWN)
 if not alcance.has(entrada) or not caja_regional(M.pies_de_celda(entrada)): return false
 for k in e.interior:
  var c := Edificios._celda(k)
  if j.mundo.constr_en(c).is_empty() and (not alcance.has(c) or not caja_regional(M.pies_de_celda(c))): return false
 for k in e.piezas:
  if not e.piezas[k].t in ["cama","cama_huesped","cofre","mesa","horno"]: continue
  var accesible := false
  for v in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if alcance.has(Edificios._celda(k)+v): accesible=true
  if not accesible: return false
 return true

## Ciclo aprobado: duración necesaria, nunca suficiente. Conserva el mismo registro físico.
func abandono_fisico(p: Dictionary) -> bool:
 if not p.residentes.is_empty(): return false
 for op in transitos.datos().operaciones.values():
  if not op.estado in ["reservada","viajando","detenida"]: continue
  if op.destino==p.id or (op.origen==p.id and (op.tipo=="comercio" or op.get("regresando",false))): return false
 return true

func ruta_sin_amenaza_conocida(camino: Array) -> bool:
 for q in camino:
  var c := Vector2i(q[0],q[1])
  for enemigo in j.combate.enemigos:
   if enemigo.get("est", "")=="muerto": continue
   var def: Dictionary=C.ENEMIGOS.get(enemigo.tipo,{})
   var conducta: String=def.get("conducta","hostil")
   if conducta=="huidizo" or (conducta=="defensivo" and not enemigo.get("alertado",false)): continue
   if Vector2(enemigo.pos).distance_to(M.pies_de_celda(c))<=float(def.get("vision",0)): return false
 return true

func resolver_crisis(p: Dictionary) -> void:
 if not j.es_autoridad(): return
 if abandono_fisico(p):
  if p.has("poblado"):
   var pueblo: Dictionary=j.mundo.poblado(p.poblado)
   if pueblo.get("estado", "")!="destruido": pueblo.estado="abandonado"
  p.estado="abandonado"
  return
 var presion: Dictionary=p.get("presiones",{}).get("comida",{})
 if presion.is_empty():
  p.erase("expedicion");return
 if int(presion.get("duracion_min",0))<int(cfg.comida_min): return
 # Una alternativa real ya ejecutada o una entrega pendiente prevalecen sobre evacuar.
 if int(p.get("local_min",-1))<int(presion.desde) or int(p.get("comercio_intento_min",-1))<int(presion.desde): return
 if int(balance_resumido(p).baya.en_curso)>0: return
 var ids: Array=datos().puestos.keys();ids.sort()
 var residentes: Array=p.residentes.duplicate()
 residentes.sort_custom(func(x,y):return str(x.id)<str(y.id))
 p.crisis={"min":int(j.d.min),"causa":"comida_persistente","estado":"sin_alternativa_viable"}
 for id in ids:
  var b: Dictionary=datos().puestos[id]
  if id==p.id or b.residentes.is_empty() or not _sostenible(b): continue
  var v := evaluar_viabilidad(b)
  if not v.amenazas_observadas.is_empty(): continue
  var plazas: int = capacidad(b)-b.residentes.size()-transitos.reservas_plaza(id)
  if plazas<=0: continue
  var saldo := balance_resumido(b)
  # Reserva del próximo ciclo completo, además de obligaciones ya vencidas y trabajo.
  var comida_libre: int = int(saldo.baya.stock)-int(saldo.baya.reserva)-transitos.reservas_plaza(id)
  if comida_libre<=0: continue
  var camino: Array=transitos.ruta(p.id,id)
  if camino.is_empty() or not ruta_sin_amenaza_conocida(camino): continue
  var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/transitos.H.VEL*C.MIN_POR_SEG))
  var disponibles: Array=[]
  for r in residentes:
   if not r.has("reserva_viaje"): disponibles.append(r)
  for cantidad in range(mini(plazas,mini(comida_libre,disponibles.size())),0,-1):
   var miembros: Array=disponibles.slice(0,cantidad)
   var elegidos: Array=[]
   var comida := 0
   for r in miembros:
    elegidos.append(r.id)
    comida+=maxi(0,floori(float(int(j.d.min)+duracion-int(r.get("comida_min",p.comida_min)))/float(cfg.comida_min)))
   var provisiones := {"baya":comida} if comida>0 else {}
   var clave := "crisis:%s:%s:%s:%d" % [p.id,id,":".join(elegidos),int(j.d.min)]
   var reserva: Dictionary=transitos.reservar(clave,p.id,id,elegidos,{},provisiones)
   if not reserva.ok: continue
   var salida: Dictionary=transitos.salir(clave)
   if not salida.ok:
    transitos.cancelar(clave)
    p.crisis.bloqueo=salida.motivo
    continue
   p.crisis.estado="migracion_en_curso"
   p.crisis.operacion=clave
   p.crisis.mejora={"comida_ciclo":true,"cama":true,"infraestructura":true,"destino":id}
   return

 # Tras descartar recepción en comunidades activas, considera recuperar propiedad original.
 for id in ids:
  var b: Dictionary=datos().puestos[id]
  if id==p.id or not abandono_fisico(b) or not j.d.cofres.has(b.cofre): continue
  var camino: Array=transitos.ruta(p.id,id)
  if camino.is_empty() or not ruta_sin_amenaza_conocida(camino): continue
  var v := evaluar_viabilidad(b)
  if not v.amenazas_observadas.is_empty(): continue
  var gastos := {}
  var propietario := true
  for eid in b.get("edificios",[]):
   var e: Dictionary=j.d.mundo.registro.edificios.get(eid,{})
   if e.is_empty() or e.dueno!=b.dueno: propietario=false;break
   Edificios._sumar(gastos,Edificios.coste(Edificios.faltantes(j,e)))
  if not propietario: continue
  var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/transitos.H.VEL*C.MIN_POR_SEG))
  for r in residentes:
   if r.has("reserva_viaje") or str(r.get("propietario_original",p.dueno))!=str(b.dueno): continue
   # Transporta también la alimentación del siguiente ciclo; jamás la presupone.
   var comida := maxi(0,floori(float(int(j.d.min)+duracion-int(r.get("comida_min",p.comida_min)))/float(cfg.comida_min)))+1
   var clave := "recuperacion:%s:%s:%s:%d" % [p.id,id,r.id,int(j.d.min)]
   var reserva: Dictionary=transitos.reservar(clave,p.id,id,[r.id],gastos,{"baya":comida},"recuperacion")
   if not reserva.ok: continue
   var salida: Dictionary=transitos.salir(clave)
   if not salida.ok: transitos.cancelar(clave);continue
   p.crisis.estado="recuperacion_en_curso";p.crisis.operacion=clave
   return

 if fundacion.intentar(p):
  p.crisis.estado="fundacion_en_curso"

## Recuperación explícita por titulares originales, en llegada física; paga desde carga real.
func recuperar_llegada(p: Dictionary, op: Dictionary) -> bool:
 if not j.es_autoridad() or p.is_empty() or not p.residentes.is_empty(): return false
 for r in op.miembros:
  if str(r.get("propietario_original",""))!=str(p.dueno): return false
 for id in p.get("edificios",[]):
  var e: Dictionary=j.d.mundo.registro.edificios.get(id,{})
  if e.is_empty() or e.dueno!=p.dueno: return false
  if not Edificios.coste(Edificios.faltantes(j,e)).is_empty():
   var resultado := Edificios.reparar(j,e,op.bienes,self)
   if not resultado.ok: return false
   op.get_or_add("reparaciones",[]).append({"edificio":id,"min":int(op.reloj),"coste":resultado.coste.duplicate(true)})
 if not _sostenible(p) or op.miembros.size()>capacidad(p): return false
 var comida: int=int(inventario(p).get("baya",0))+int(op.bienes.get("baya",0))+int(op.provisiones.get("baya",0))
 if comida<int(p.get("deuda_comida",0))+op.miembros.size(): return false
 # No devuelve inventarios perdidos: la entrega normal acredita únicamente lo transportado.
 p.estado="activo"
 p.recuperacion={"min":int(op.reloj),"operacion":op.id,"dueno":p.dueno}
 if p.has("poblado"): j.mundo.poblado(p.poblado).estado="activo"
 return true


## Obras dentro de la misma economía: una demanda espacial, su coste exacto y un ejecutor real.
func solar_vivienda(p: Dictionary) -> Dictionary:
 var centro := Vector2i(p.celda[0],p.celda[1])
 var alcance := _alcance(centro)
 var entradas: Array=alcance.keys()
 entradas.sort_custom(func(x,y):
  var dx: int=absi(x.x-centro.x)+absi(x.y-centro.y)
  var dy: int=absi(y.x-centro.x)+absi(y.y-centro.y)
  return dx<dy if dx!=dy else (x.x<y.x if x.x!=y.x else x.y<y.y))
 for entrada in entradas:
  if not alcance.has(entrada+Vector2i.DOWN): continue
  var e := Edificios.plano("vivienda",entrada,p.dueno,p.get("poblado",""))
  if Edificios.solar(j,e,self)=="": return e
 return {}

func planear_crecimiento(p: Dictionary) -> void:
 if not j.es_autoridad() or p.residentes.is_empty() or not _sostenible(p): return
 var obra: Dictionary=p.get("obra",{})
 if not obra.is_empty():
  var causa: Dictionary=datos().puestos.get(obra.get("origen_demanda",""),{})
  if causa.is_empty() or not causa.get("presiones",{}).has("comida"): p.erase("obra")
  return
 if capacidad(p)>p.residentes.size()+transitos.reservas_plaza(p.id): return
 var saldo := balance_resumido(p)
 if int(saldo.baya.stock)-int(saldo.baya.reserva)<1: return
 var ids: Array=datos().puestos.keys();ids.sort()
 for id in ids:
  var otro: Dictionary=datos().puestos[id]
  var presion: Dictionary=otro.get("presiones",{}).get("comida",{})
  if id==p.id or otro.residentes.is_empty() or int(presion.get("duracion_min",0))<int(cfg.comida_min): continue
  if int(otro.get("comercio_intento_min",-1))<int(presion.get("desde",0)): continue
  var pendiente := false
  for b in datos().puestos.values():
   if b.get("obra",{}).get("origen_demanda","")==id: pendiente=true
  if pendiente: continue
  var camino: Array=transitos.ruta(id,p.id)
  if camino.is_empty() or not ruta_sin_amenaza_conocida(camino): continue
  var e := solar_vivienda(p)
  if e.is_empty(): return
  p.obra={"id":e.id,"plano":e,"coste":Edificios.coste(e),"causa":"alojar_migracion_real","origen_demanda":id,"desde":int(j.d.min)}
  return

func ejecutar_obra(p: Dictionary) -> String:
 var obra: Dictionary=p.get("obra",{})
 if obra.is_empty() or not j.es_autoridad() or not Inv.tiene(inventario(p),obra.coste): return ""
 var causa: Dictionary=datos().puestos.get(obra.origen_demanda,{})
 if causa.is_empty() or not causa.get("presiones",{}).has("comida"):
  p.erase("obra");return ""
 if capacidad_alimentaria(p)<p.residentes.size()+1 and int(fundacion.fuentes(Vector2i(p.celda[0],p.celda[1])).arbusto)<=0: return ""
 var saldo := balance_resumido(p)
 if int(inventario(p).get("baya",0))-int(obra.coste.get("baya",0))<int(saldo.baya.deuda)+int(saldo.baya.vencido)+p.residentes.size()+1: return ""
 var actores: Array=p.residentes.duplicate();actores.sort_custom(func(x,y):return str(x.id)<str(y.id))
 for r in actores:
  if r.has("reserva_viaje"): continue
  var antes := inventario(p).duplicate(true)
  if Edificios.instalar(j,obra.plano,self)!="": return ""
  Inv.quitar(inventario(p),obra.coste)
  p.get_or_add("edificios",[]).append(obra.id)
  for k in obra.plano.piezas:
   if obra.plano.piezas[k].t in ["cama","cama_huesped"]:
    var c := Edificios._celda(k)
    p.get_or_add("camas",[]).append([c.x,c.y])
  if p.has("poblado"):
   var pueblo: Dictionary=j.mundo.poblado(p.poblado)
   var area: Array=pueblo.area
   var union := Rect2i(area[0],area[1],area[2],area[3]).merge(Rect2i(obra.plano.area[0],obra.plano.area[1],obra.plano.area[2],obra.plano.area[3]))
   pueblo.area=[union.position.x,union.position.y,union.size.x,union.size.y]
  _resultado_regional(p,"vivienda_pagada",{"id":obra.id},antes,{"actor":r.id,"demanda":obra.origen_demanda})
  a.desarrollo.registrar("npc:"+str(r.id),"construccion",obra.coste)
  p.erase("obra")
  return r.id
 return ""


## Capacidad material observada, sin acreditar ni prometer cosechas al inventario.
## El horizonte y rendimientos proceden de los ciclos ya vigentes.
func capacidad_alimentaria(p: Dictionary) -> float:
 var capacidad_ciclo := 0.0
 var c := Vector2i(p.celda[0],p.celda[1])
 var alcance := _alcance(c)
 for q in p.get("campos",[]):
  var campo := Vector2i(q[0],q[1])
  if j.mundo.constr_en(campo).get("t","")!="campo": continue
  for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   if alcance.has(campo+v):
    capacidad_ciclo+=float(C.CAMPO_COSECHA.get("baya",0))*float(cfg.comida_min)/float(C.CAMPO_CRECE_MIN)
    break
 return capacidad_ciclo

func deficit_sostenible(p: Dictionary) -> int:
 if p.residentes.is_empty(): return 0
 # Alimento silvestre actualmente alcanzable permite la alternativa local, no una crisis prevista.
 if int(fundacion.fuentes(Vector2i(p.celda[0],p.celda[1])).arbusto)>0: return 0
 return maxi(0,ceili(float(p.residentes.size())-capacidad_alimentaria(p)))

func ampliar_cultivo(p: Dictionary) -> String:
 var entrantes := 1 if p.has("obra") else 0
 if deficit_sostenible(p)<=0 and (entrantes==0 or capacidad_alimentaria(p)>=p.residentes.size()+entrantes):
  p.erase("cultivo_pendiente");return ""
 var centro := Vector2i(p.celda[0],p.celda[1])
 var alcance := _alcance(centro)
 var candidatos: Array=alcance.keys()
 candidatos.sort_custom(func(x,y):return M.clave(x)<M.clave(y))
 for c in candidatos:
  if not terreno_reparacion(c,false) or j.mundo.tipo(c)!=M.T.PASTO or j.d.mundo.techos.has(M.clave(c)) or j.ocupada(c): continue
  if not j.mundo.piso_en(c).is_empty() or a.sociedad.habitat.reservada(c): continue
  var seguro := true
  for v in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
   if not alcance.has(c+v): seguro=false
  if not seguro: continue # un campo sólido no puede cortar la única salida
  p.cultivo_pendiente={"celda":[c.x,c.y],"coste":C.CONSTR.campo.coste.duplicate(true)}
  if not Inv.tiene(inventario(p),C.CONSTR.campo.coste): return ""
  for r in p.residentes:
   if r.has("reserva_viaje"): continue
   var antes := inventario(p).duplicate(true)
   Inv.quitar(inventario(p),C.CONSTR.campo.coste)
   j.mundo.poner(c,"campo",true,p.dueno);j.sembrar(c)
   p.get_or_add("campos",[]).append([c.x,c.y])
   p.erase("cultivo_pendiente")
   _resultado_regional(p,"cultivo_pagado",{"id":p.id+":comida"},antes,{"actor":r.id,"campo":M.clave(c)})
   return r.id
 return ""


func recepcion_viable(p: Dictionary, entrantes: int, bienes: Dictionary = {}, provisiones: Dictionary = {}) -> bool:
 if not _sostenible(p) or capacidad(p)<p.residentes.size()+entrantes: return false
 var saldo := balance_resumido(p)
 var comida: int=int(saldo.baya.stock)+int(bienes.get("baya",0))+int(provisiones.get("baya",0))
 if comida<int(saldo.baya.reserva)+entrantes: return false
 return capacidad_alimentaria(p)>=p.residentes.size()+entrantes or int(fundacion.fuentes(Vector2i(p.celda[0],p.celda[1])).arbusto)>0
