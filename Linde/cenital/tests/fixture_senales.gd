extends RefCounted
## Selecciona una criatura nacida del plan real y una posición observadora transitable.
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
static func preparar(j) -> Dictionary:
 var candidatos=[]
 for territorio in j.d.fauna.territorios.values():
  for p in territorio.regiones.values():
   if not p.is_empty() and not p.pospuesto and C.ENEMIGOS[p.tipo].get("conducta","")=="hostil":candidatos.append(p)
 candidatos.sort_custom(func(a,b):return str(a.id)<str(b.id))
 for p in candidatos:
  var c=Vector2i(p.celda[0],p.celda[1]);j.pies=M.pies_de_celda(c+Vector2i(10,0));j.actualizar_regiones();j.combate.fauna.actualizar()
  var vivos:Array=j.combate.enemigos.filter(func(e):return e.get("fauna_id","")==p.id)
  if vivos.is_empty():continue
  var e:Dictionary=vivos[0]
  for pasos in [6,5,4]:
   for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var posicion=M.pies_de_celda(c+dir*pasos)
    if j.mundo.caja_libre(posicion,Vector2(8,6)) and j.combate.linea_visible(e.pos,posicion):
     j.combate.enemigos=[e];j.pies=posicion
     return {"enemigo":e,"observador":posicion}
 return {}
