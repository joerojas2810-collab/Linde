extends SceneTree
const J=preload("res://scripts/juego.gd")
class SinCache extends "res://scripts/asentamientos.gd":
 func _alcance(centro:Vector2i)->Dictionary:return _calcular_alcance(centro)
func _init()->void:
 var con=J.nueva(123,"Equivalencia",[0,0,0],J.MODO_JUEGO)
 var sin=J.nueva(123,"Equivalencia",[0,0,0],J.MODO_JUEGO)
 sin.autonomia.asentamientos=SinCache.new(sin.autonomia)
 for i in 120:
  con.tick(0.1)
  sin.tick(0.1)
  if JSON.stringify(con.d)!=JSON.stringify(sin.d):
   print("FAIL estado distinto en tick ",i);quit(1);return
 print("PASS 120 ticks: estado completo idéntico con y sin caché; incluye economía y NPC")
 quit()
