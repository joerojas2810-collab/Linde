extends RefCounted
## Solares y accesos persistentes; las obras bloqueadas se conservan para reintentarlas.
const M = preload("res://scripts/mundo.gd")
var s
var j
var busquedas: Dictionary={}
const CANDIDATOS_POR_TURNO=64
func _init(sociedad) -> void:
 s=sociedad
 j=s.j
func datos() -> Dictionary:
 var d: Dictionary=s.datos()
 if not d.has("parcelas"):d.parcelas={}
 if not d.has("obras"):d.obras={}
 return d
func plano_de(k: String) -> Dictionary:
 return s.cfg.vivienda[str(datos().parcelas.get(k,{}).get("plano","casa"))]
func area(cama: Vector2i, plano: String="casa") -> Rect2i:
 var a: Array=s.cfg.vivienda[plano].get("area",[-2,-2,6,7])
 return Rect2i(cama+Vector2i(int(a[0]),int(a[1])),Vector2i(int(a[2]),int(a[3])))
func _area_de(k: String) -> Rect2i:
 return area(Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1))),str(datos().parcelas.get(k,{}).get("plano","casa")))
## Las otras camas de una casa comunitaria son piezas de su plano, no anclas de una vivienda propia.
func es_pieza_ajena(cama: Vector2i) -> bool:
 for k in datos().parcelas:
  var ancla:=Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
  if ancla==cama:continue
  for e in plano_de(k).piezas:
   if str(e.p)=="cama_huesped" and ancla+Vector2i(int(e.d[0]),int(e.d[1]))==cama:return true
 return false
func necesarias(cama: Vector2i, plano: String="casa") -> Array:
 var celdas: Array=[cama,cama+Vector2i(0,1),cama+Vector2i(0,2),cama+Vector2i(0,3),cama+Vector2i(0,4)]
 for d in s.cfg.vivienda[plano].base:
  var c:=cama+Vector2i(int(d[0]),int(d[1]))
  if not c in celdas:celdas.append(c)
 for paso in s._celdas_casa(cama,plano):
  if not paso[1] in celdas:celdas.append(paso[1])
 return celdas
func reservada(c: Vector2i, excepto: String="") -> bool:
 for k in datos().parcelas:
  if k!=excepto and _area_de(k).has_point(c):return true
 return false
func admisible(cama: Vector2i, plano: String="casa") -> bool:
 var zona:=area(cama,plano)
 if not M.es_valle(zona.position) or not M.es_valle(zona.end-Vector2i.ONE):return false
 for k in datos().parcelas:
  if zona.intersects(_area_de(k)):return false
 for y in range(zona.position.y,zona.end.y):
  for x in range(zona.position.x,zona.end.x):
   var c:=Vector2i(x,y)
   if M.ESENCIALES.has(c) or j.mundo.tipo(c)==M.T.CAMINO or not j.mundo.constr_en(c).is_empty():return false
 for c in necesarias(cama,plano):
  if j.mundo.puede_poner(c)!="" or j.ocupada(c):return false
 return true
func reservar(nid: String, plano: String="casa") -> Dictionary:
 for p in datos().parcelas.values():
  if j.mundo.constr_en(Vector2i(p.cama[0],p.cama[1])).is_empty():return p # una obra nueva compartida, sin acaparar solares vacíos
 if int(j.d.min)-int(datos().get("sin_solar_min",-99999))<60:return {}
 var gid: String=s.grupo_de(nid)
 var centro: Vector2i=s._ancla(gid)
 if not busquedas.has(gid):
  var candidatos: Array=[]
  for radio in range(3,27):
   for y in range(centro.y-radio,centro.y+radio+1):
    for x in range(centro.x-radio,centro.x+radio+1):
     if maxi(absi(x-centro.x),absi(y-centro.y))==radio:candidatos.append(Vector2i(x,y))
  busquedas[gid]={"candidatos":candidatos,"indice":0}
 var busqueda: Dictionary=busquedas[gid]
 for intento in CANDIDATOS_POR_TURNO:
  if int(busqueda.indice)>=busqueda.candidatos.size():
   busquedas.erase(gid)
   datos().sin_solar_min=int(j.d.min)
   return {}
  var cama: Vector2i=busqueda.candidatos[int(busqueda.indice)]
  busqueda.indice+=1
  if not admisible(cama,plano):continue
  var entrada:=cama+Vector2i(0,4)
  if j.mundo.camino(M.ENTRADA,func(c):return c==entrada).is_empty():continue
  var p: Dictionary={"cama":[cama.x,cama.y],"dueno":nid,"estado":"reservada","plano":plano}
  datos().parcelas[M.clave(cama)]=p
  busquedas.erase(gid)
  return p
 return {}

func estado(cama: Vector2i, fase: String, motivo: String="") -> void:
 var k:=M.clave(cama)
 var obra: Dictionary=datos().obras.get(k,{})
 obra.estado=fase;obra.motivo=motivo
 if not obra.has("desde"):obra.desde=int(j.d.min)
 datos().obras[k]=obra
 if datos().parcelas.has(k):datos().parcelas[k].estado=fase
func permite_pieza(c: Vector2i, pieza: String) -> bool:
 for k in datos().parcelas:
  var cama:=Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
  if not _area_de(k).has_point(c):continue
  if c==cama and pieza=="cama_huesped":return true
  for d in plano_de(k).base:
   if c==cama+Vector2i(int(d[0]),int(d[1])) and pieza in ["muro_ladrillo","muro"]:return true   # el muro de madera es el respaldo si no hay ladrillos
  for paso in s._celdas_casa(cama):
   if (paso[0]==pieza or (paso[0]=="muro_ladrillo" and pieza=="muro")) and paso[1]==c:return true
  return false
 return true
