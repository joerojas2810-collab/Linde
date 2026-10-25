extends RefCounted
## Puestos fundados por jugadores. Población regional resumida, sin cargar regiones lejanas.
## Extrae recursos reales del mapa y cosecha campos reales; no hay producción gratuita al descargar.
const M=preload("res://scripts/mundo.gd")
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
 if datos().puestos.size()>=int(cfg.max_puestos):return "Ya hay tres puestos regionales"
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
func crear(c: Vector2i, dueno: String) -> void:
 var k:=M.clave(c)
 var cid:="c@"+M.clave(c+Vector2i(0,2))
 for pieza in PIEZAS:
  var celda:=c+Vector2i(int(pieza[1]),int(pieza[2]))
  j.mundo.poner(celda,pieza[0],true,dueno)
  j.sembrar(celda)
 j.d.cofres[cid]={"inv":{"baya":4,"hacha_piedra":1,"pico_piedra":1}}
 for dy in [0,1]:j.mundo.techar(c+Vector2i(1,dy),dueno)
 datos().puestos[k]={"id":k,"nombre":"Puesto "+str(datos().puestos.size()+1),"celda":[c.x,c.y],"dueno":dueno,"cofre":cid,"residentes":[],"ultimo_min":int(j.d.min),"fundado_min":int(j.d.min),"llegada_min":int(j.d.min),"comida_min":int(j.d.min),"produccion_min":int(j.d.min),"estado":"esperando colonos","producciones":0}
 j.aviso_todos("Se funda un puesto regional. Lleva comida a su cofre para atraer residentes.")
func _sostenible(p: Dictionary) -> bool:
 var c:=Vector2i(p.celda[0],p.celda[1])
 if j.mundo.constr_en(c).get("t","")!="puesto" or not j.d.cofres.has(p.cofre):return false
 for dy in [0,1]:
  if j.mundo.constr_en(c+Vector2i(1,dy)).get("t","")!="cama_huesped" or not j.mundo.estado.techos.has(M.clave(c+Vector2i(1,dy))):return false
 return true
func _transitable(c: Vector2i) -> bool:
 if not j.mundo.generador.valida(c):return false
 var d: Dictionary=j.mundo.generador.datos(c)
 if int(d.tipo)==M.T.AGUA:return false
 if C.CONSTR.get(j.mundo.constr_en(c).get("t",""),{}).get("bloquea",false):return false
 var id: String=str(d.objeto)+"@"+M.clave(c)
 return str(d.objeto)=="" or not C.OBJETOS.get(str(d.objeto),{}).get("bloquea",true) or j.d.mundo.rotos.has(id)
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
func _extraer(p: Dictionary, oficio: String) -> bool:
 var centro:=Vector2i(p.celda[0],p.celda[1])
 var tipos: Array=["arbol"] if oficio=="recolector" else ["roca"]
 var alcance:=_alcance(centro)
 for radio in range(2,int(cfg.radio_recursos)+1):
  for dy in range(-radio,radio+1):
   for dx in range(-radio,radio+1):
    if maxi(absi(dx),absi(dy))!=radio:continue
    var c:=centro+Vector2i(dx,dy)
    if not j.mundo.generador.valida(c) or not j.mundo.constr_en(c).is_empty():continue
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
    j.mundo.romper(id,int(j.d.min))
    j.d.mundo.golpes.erase(id)
    for item in def.drops:inventario(p)[item]=int(inventario(p).get(item,0))+int(def.drops[item])
    p.producciones=int(p.producciones)+1
    return true
 return false
func actualizar() -> void:
 if not a.activa() or not j.es_autoridad():return
 for p in datos().puestos.values():
  if not _sostenible(p):p.estado="faltan puesto, camas, techo o cofre";continue
  var inv: Dictionary=inventario(p)
  var c:=Vector2i(p.celda[0],p.celda[1])
  for dy in [0,1]:
   var campo:=c+Vector2i(-1,dy)
   if not p.residentes.is_empty() and j.campo_listo(campo):
    var cosecha: Dictionary=j.cosechar(campo)
    for item in cosecha:inv[item]=int(inv.get(item,0))+int(cosecha[item])
  # Tiempo del servidor, no tiempo de pared. Guardar/cargar no repite una cosecha o un consumo.
  if int(p.get("deuda_comida",0))>0:
   if int(inv.get("baya",0))<int(p.deuda_comida):p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
   inv.baya=int(inv.get("baya",0))-int(p.deuda_comida);p.deuda_comida=0
  if int(j.d.min)-int(p.comida_min)>=int(cfg.comida_min):
   var periodos:=floori(float(int(j.d.min)-int(p.comida_min))/float(cfg.comida_min))
   var coste:int=periodos*p.residentes.size()
   p.comida_min=int(p.comida_min)+periodos*int(cfg.comida_min)
   if int(inv.get("baya",0))<coste:p.deuda_comida=coste;p.estado="sin comida; producción detenida";p.produccion_min=int(j.d.min);continue
   inv.baya=int(inv.get("baya",0))-coste
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
     if int(residente.get("usos",0))<=0:
      if int(inv.get(herramienta,0))<=0:p.estado="faltan herramientas en el cofre";continue
      inv[herramienta]=int(inv[herramienta])-1;residente.usos=50
     if int(inv.get("baya",0))<=0:p.estado="sin comida; producción detenida";continue
     if int(inv.get("madera",0))+int(inv.get("piedra",0))>=int(cfg.tope_stock):p.estado="reservas completas";continue
     if not _extraer(p,residente.oficio):p.estado="faltan recursos cercanos"
     else:residente.usos=int(residente.usos)-1
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
   var hasta:=M.pies_de_celda(c+Vector2i(-1,i))
   resultado.append({"id":r.id,"nombre":r.nombre,"look":r.look,"pos":desde.lerp(hasta,t),"mueve":fase<2 or (fase>=30 and fase<32)})
 return resultado
