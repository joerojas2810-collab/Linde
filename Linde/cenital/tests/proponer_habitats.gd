extends SceneTree
## Comparador fuera del juego. No modifica Fauna.actualizar ni registra población.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const H=preload("res://scripts/huella.gd")
const PROPUESTA="res://../../docs/investigacion/fase7_ubicacion_propuesta.json"
const VECINOS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
var preferencias:Dictionary

func cumple(j,c:Vector2i,tipo:String) -> bool:
 var regla:Dictionary=preferencias[tipo]
 if regla.get("conservar_origen",false):return true
 var junto=false
 for v in VECINOS:
  var d:Dictionary=j.mundo.generador.datos(c+v)
  if regla.has("vecino_objeto") and str(d.objeto) in regla.vecino_objeto:junto=true
  if regla.get("vecinos_despejados",false) and (int(d.tipo)!=M.T.PASTO or str(d.objeto)!=""):return false
 return junto if regla.has("vecino_objeto") else true

func proponer(j,r:Vector2i) -> Dictionary:
 var p:Dictionary=j.combate.fauna.plan_region(r).duplicate(true)
 if p.is_empty() or cumple(j,p.celda,p.tipo):return p
 for i in 64:
  var c:Vector2i=j.combate.fauna.candidata_region(r,i)
  if M.Terreno.distancia_valle(c)<int(j.combate.fauna.cfg.distancia_valle):continue
  var habitat:Dictionary=j.combate.fauna.habitat_en(c)
  if habitat.get("tipo","")!=p.tipo or habitat.get("bioma","")!=p.bioma:continue
  if cumple(j,c,p.tipo):p.celda=c;break
 return p

func junto_camino(j,c:Vector2i) -> bool:
 return VECINOS.any(func(v):return int(j.mundo.generador.datos(c+v).tipo)==M.T.CAMINO)

func _init() -> void:
 preferencias=JSON.parse_string(FileAccess.get_file_as_string(PROPUESTA)).preferencias
 var salida=OS.get_cmdline_user_args()[0]
 var casos:Array=[];var ejemplos:Dictionary={};var fallos=0
 for seed in [123,456,789]:
  var j=J.nueva(seed,"Muestra",[0,0,0],M.MODO_POBLADO)
  var estado=H.hash_de(j.d);var cargadas=j.mundo.regiones.size();var stats:Dictionary={}
  var planes:Dictionary={};var iguales=true
  for y in range(-14,15):
   for x in range(-14,15):
    var r=Vector2i(x,y);var original:Dictionary=j.combate.fauna.plan_region(r).duplicate(true);var p=proponer(j,r)
    planes[M.clave(r)]=p
    if original.is_empty():iguales=iguales and p.is_empty();continue
    iguales=iguales and p.id==original.id and p.tipo==original.tipo and p.bioma==original.bioma and M.Terreno.region(p.celda)==r
    if not stats.has(p.tipo):stats[p.tipo]={"cantidad":0,"cumplen_antes":0,"cumplen_despues":0,"movidos":0,"junto_camino_antes":0,"junto_camino_despues":0}
    var s:Dictionary=stats[p.tipo];s.cantidad+=1
    s.cumplen_antes+=int(cumple(j,original.celda,p.tipo));s.cumplen_despues+=int(cumple(j,p.celda,p.tipo))
    s.junto_camino_antes+=int(junto_camino(j,original.celda));s.junto_camino_despues+=int(junto_camino(j,p.celda))
    if p.celda!=original.celda:
     s.movidos+=1
     if not ejemplos.has(p.tipo):
      var celdas:Array=[]
      for cy in range(r.y*16,(r.y+1)*16):
       for cx in range(r.x*16,(r.x+1)*16):celdas.append(j.mundo.generador.datos(Vector2i(cx,cy)))
      ejemplos[p.tipo]={"semilla":seed,"region":[r.x,r.y],"antes":[original.celda.x-r.x*16,original.celda.y-r.y*16],"despues":[p.celda.x-r.x*16,p.celda.y-r.y*16],"celdas":celdas}
  var inversos=true
  j.combate.fauna.planes.clear()
  for y in range(14,-15,-1):
   for x in range(14,-15,-1):
    var r=Vector2i(x,y)
    inversos=inversos and proponer(j,r)==planes[M.clave(r)]
  var puro=H.hash_de(j.d)==estado and j.mundo.regiones.size()==cargadas
  if not iguales or not inversos or not puro:fallos+=1
  casos.append({"semilla":seed,"regiones":841,"conservacion":iguales,"orden_inverso":inversos,"consulta_pura":puro,"especies":stats})
  print(("PASS " if iguales and inversos and puro else "FAIL ")+"propuesta: cantidades/especies/region, orden inverso y estado puro semilla "+str(seed))
 var f=FileAccess.open(salida,FileAccess.WRITE);f.store_string(JSON.stringify({"activada":false,"huella":H.huella(),"casos":casos,"ejemplos":ejemplos},"  "));f.close()
 quit(1 if fallos else 0)
