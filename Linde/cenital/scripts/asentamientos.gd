extends RefCounted
## Puestos del jugador y comunidades preexistentes. Una sola población regional resumida, sin cargar regiones lejanas.
## Extrae recursos reales del mapa y cosecha campos reales; no hay producción gratuita al descargar.
const M=preload("res://scripts/mundo.gd")
const Lugares = preload("res://scripts/lugares.gd")
const Edificios = preload("res://scripts/edificios.gd")
const C=preload("res://scripts/catalogos.gd")
var a
var j
var cfg: Dictionary
const PIEZAS = [["cama_huesped",1,0],["cama_huesped",1,1],["campo",-1,0],["campo",-1,1],["cofre",0,2]]
func _init(autonomia) -> void:
 a=autonomia;j=a.j
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
func _extraer(p: Dictionary, oficio: String, residente_actual: Dictionary = {}) -> bool:
 if not j.es_autoridad(): return false
 var saldo: Dictionary = balance_resumido(p).materiales
 if int(saldo.pendiente) <= 0: return false
 var centro:=Vector2i(p.celda[0],p.celda[1])
 var tipos: Array=["arbol"] if oficio=="recolector" else ["roca"]
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
    if not residente_actual.is_empty(): residente_actual.usos = usos_antes-1
    _resultado_regional(p,"extraccion",saldo,antes,{"objeto":id,"actor":residente_actual.get("id", ""),"usos_antes":usos_antes,"usos_despues":residente_actual.get("usos",usos_antes)})
    return true
 return false
func actualizar() -> void:
 if not a.activa() or not j.es_autoridad():return
 for p in datos().puestos.values():
  if p.has("poblado"):
   var pueblo: Dictionary = j.mundo.poblado(p.poblado)
   if pueblo.get("estado", "") in ["abandonado", "destruido"]: continue
   pueblo.estado = "activo" if _sostenible(p) and int(inventario(p).get("baya",0)) > 0 else "sin_sustento"
   _conocimiento(p)
  if not _sostenible(p):p.estado="faltan puesto, camas, techo o cofre";continue
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
  var alimento: Dictionary = balance_resumido(p).baya
  if int(alimento.deuda)>0:
   if not _consumir_regional(p,int(alimento.deuda),alimento,"pago_deuda"):p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
   p.deuda_comida=0
  alimento = balance_resumido(p).baya
  if int(j.d.min)-int(p.comida_min)>=int(cfg.comida_min):
   var periodos:=floori(float(int(j.d.min)-int(p.comida_min))/float(cfg.comida_min))
   var coste:int=int(alimento.vencido)
   p.comida_min=int(p.comida_min)+periodos*int(cfg.comida_min)
   if not _consumir_regional(p,coste,alimento,"consumo"):p.deuda_comida=coste;p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
  if p.residentes.size()<int(cfg.capacidad) and int(inv.get("baya",0))>=2 and int(j.d.min)-int(p.llegada_min)>=int(cfg.llegada_min):
   var n:int=p.residentes.size()
   var rng=j._rng("colono_regional",p.id+":"+str(n))
   p.residentes.append({"id":p.id+":"+str(n),"nombre":cfg.nombres[rng.randi()%cfg.nombres.size()],"oficio":"recolector" if n==0 else "cantero","look":[rng.randi_range(0,2),rng.randi_range(0,2),rng.randi_range(0,2)]})
   p.llegada_min=int(j.d.min)
   j.aviso_todos("Un colono se instala en "+p.nombre)
  if int(j.d.min)-int(p.produccion_min)>=int(cfg.produccion_min):
   var periodos:=mini(24,floori(float(int(j.d.min)-int(p.produccion_min))/float(cfg.produccion_min)))
   p.produccion_min=int(p.produccion_min)+periodos*int(cfg.produccion_min)
   p.estado="activo"
   for periodo in periodos:
    for residente in p.residentes:
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
 var materiales := int(inv.get("madera",0)) + int(inv.get("piedra",0))
 var objetivo_materiales := int(cfg.tope_stock) if not p.residentes.is_empty() else 0
 # El ejecutor ya exige stock de comida > 0 para trabajar; no consume esta unidad.
 var comida_trabajo := 1 if materiales<objetivo_materiales else 0
 var objetivos := {"baya":int(p.get("deuda_comida", 0)) + periodos * p.residentes.size() + comida_trabajo}
 for r in p.residentes:
  if int(r.get("usos", 0)) > 0: continue
  var herramienta: String = "hacha_piedra" if r.oficio == "recolector" else "pico_piedra"
  objetivos[herramienta] = int(objetivos.get(herramienta, 0)) + 1
 var saldos := {}
 for item in objetivos:
  var objetivo := int(objetivos[item])
  var stock := int(inv.get(item, 0))
  saldos[item] = {"id":"%s:%s" % [p.get("poblado", "puesto:" + str(p.id)),item], "reserva":objetivo, "stock":stock, "comprometido":0, "en_curso":0, "pendiente":maxi(0, objetivo-stock)}
 saldos.baya.deuda = int(p.get("deuda_comida",0))
 saldos.baya.vencido = periodos * p.residentes.size()
 saldos.baya.trabajo = comida_trabajo
 # Bolsa de control del límite existente: no es un ítem ni un inventario nuevo.
 saldos.materiales = {"id":"%s:materiales" % p.get("poblado", "puesto:" + str(p.id)),"componentes":["madera","piedra"],"reserva":objetivo_materiales,"stock":materiales,"comprometido":0,"en_curso":0,"pendiente":maxi(0,objetivo_materiales-materiales)}
 return saldos

func actualizar_demandas() -> void:
 if not a.activa() or not j.es_autoridad(): return
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
