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
var cfg: Dictionary
const PIEZAS = [["cama_huesped",1,0],["cama_huesped",1,1],["campo",-1,0],["campo",-1,1],["cofre",0,2]]
func _init(autonomia) -> void:
 a=autonomia;j=a.j
 transitos=Transitos.new(self)
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
 for q in p.get("camas",[[c.x+1,c.y],[c.x+1,c.y+1]]):
  var cama := Vector2i(q[0],q[1])
  if j.mundo.constr_en(cama).get("t","")!="cama_huesped" or not j.mundo.estado.techos.has(M.clave(cama)):return false
 return true
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
    for item in def.drops:inventario(p)[item]=int(inventario(p).get(item,0))+int(def.drops[item])
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
 var objetivos := {"baya":int(p.get("deuda_comida", 0)) + vencido + comida_trabajo}
 for r in trabajadores:
  if int(r.get("usos", 0)) > 0: continue
  var herramienta: String = "hacha_piedra" if r.oficio == "recolector" else "pico_piedra"
  objetivos[herramienta] = int(objetivos.get(herramienta, 0)) + 1
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
 saldos.materiales = {"id":"%s:materiales" % p.get("poblado", "puesto:" + str(p.id)),"componentes":["madera","piedra"],"reserva":objetivo_materiales,"stock":materiales,"comprometido":0,"en_curso":0,"pendiente":maxi(0,objetivo_materiales-materiales)}
 return saldos

func actualizar_demandas() -> void:
 if not a.activa() or not j.es_autoridad(): return
 for p in datos().puestos.values():
  p.viabilidad = evaluar_viabilidad(p)
  registrar_presion(p)
 for p in datos().puestos.values(): resolver_crisis(p)
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
 var camas := 0
 for q in p.get("camas",[]):
  var c := Vector2i(q[0],q[1])
  if j.mundo.constr_en(c).get("t", "")=="cama_huesped" and j.d.mundo.techos.has(M.clave(c)): camas += 1
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
 var faltas := {"comida":maxi(0,int(saldo.baya.reserva)-int(saldo.baya.stock)),"camas":maxi(0,p.residentes.size()-int(p.viabilidad.camas))}
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
 if presion.is_empty() or int(presion.get("duracion_min",0))<int(cfg.comida_min): return
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
  var plazas: int = mini(int(v.camas),int(cfg.capacidad))-b.residentes.size()-transitos.reservas_plaza(id)
  if plazas<=0: continue
  var saldo := balance_resumido(b)
  # Reserva del próximo ciclo completo, además de obligaciones ya vencidas y trabajo.
  var comida_libre: int = int(saldo.baya.stock)-int(saldo.baya.reserva)-b.residentes.size()-transitos.reservas_plaza(id)
  if comida_libre<=0: continue
  var camino: Array=transitos.ruta(p.id,id)
  if camino.is_empty() or not ruta_sin_amenaza_conocida(camino): continue
  var duracion := maxi(1,ceili((camino.size()-1)*float(M.P.CELDA)/transitos.H.VEL*C.MIN_POR_SEG))
  for r in residentes:
   if r.has("reserva_viaje"): continue
   var comida := maxi(0,floori(float(int(j.d.min)+duracion-int(r.get("comida_min",p.comida_min)))/float(cfg.comida_min)))
   var provisiones := {"baya":comida} if comida>0 else {}
   var clave := "crisis:%s:%s:%s:%d" % [p.id,id,r.id,int(j.d.min)]
   var reserva: Dictionary=transitos.reservar(clave,p.id,id,[r.id],{},provisiones)
   if not reserva.ok: continue
   var salida: Dictionary=transitos.salir(clave)
   if not salida.ok:
    transitos.cancelar(clave)
    p.crisis.bloqueo=salida.motivo
    continue
   p.crisis.estado="migracion_en_curso"
   p.crisis.operacion=clave
   # El destino materialmente cubre la carencia que permanecer mantiene.
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
 if not _sostenible(p) or op.miembros.size()>int(cfg.capacidad): return false
 var comida: int=int(inventario(p).get("baya",0))+int(op.bienes.get("baya",0))+int(op.provisiones.get("baya",0))
 if comida<int(p.get("deuda_comida",0))+op.miembros.size(): return false
 # No devuelve inventarios perdidos: la entrega normal acredita únicamente lo transportado.
 p.estado="activo"
 p.recuperacion={"min":int(op.reloj),"operacion":op.id,"dueno":p.dueno}
 if p.has("poblado"): j.mundo.poblado(p.poblado).estado="activo"
 return true
