extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
var fallos:=0
func comprobar(v:bool,texto:String)->void:
 print(("PASS " if v else "FAIL ")+texto)
 if not v:fallos+=1
func _init()->void:
 var j=J.nueva(123,"Cache",[0,0,0],J.MODO_JUEGO)
 var a=j.autonomia.asentamientos
 # Área cerrada conocida: retirar y construir obstáculos.
 var c=Vector2i(24,24)
 for y in range(22,27):
  for x in range(22,27):
   j.mundo.celdas[y*M.ANCHO+x]=M.T.PASTO
   j.mundo.por_celda.erase(Vector2i(x,y))
   j.d.mundo.constr[M.clave(Vector2i(x,y))]={"t":"muro"}
 j.d.mundo.constr.erase(M.clave(c))
 j.d.mundo.constr[M.clave(c+Vector2i.RIGHT)]={"t":"puerta","abierta":false}
 j.mundo.cambiar()
 var primero:Dictionary=a._alcance(c)
 comprobar(primero==a._calcular_alcance(c),"caché coincide con BFS sin caché")
 var copia:Dictionary=a._alcance(c)
 copia.clear()
 comprobar(a._alcance(c)==primero,"modificar el resultado no contamina la caché")
 # _transitable trata puertas con las reglas vigentes; usar muro/retirada garantiza un cambio real.
 j.mundo.quitar(c+Vector2i.RIGHT)
 var abierto:Dictionary=a._alcance(c)
 comprobar(abierto==a._calcular_alcance(c) and abierto.has(c+Vector2i.RIGHT),"retirar muro/puerta invalida inmediatamente")
 j.mundo.poner(c+Vector2i.RIGHT,"muro",false,"local")
 comprobar(a._alcance(c)==a._calcular_alcance(c) and not a._alcance(c).has(c+Vector2i.RIGHT),"construir muro invalida inmediatamente")
 var p:Dictionary={}
 for v in j.d.mundo_vivo.autonomia.asentamientos.puestos.values():p=v;break
 if not p.is_empty():
  var centro=Vector2i(p.celda[0],p.celda[1])
  comprobar(a._alcance(centro)==a._calcular_alcance(centro),"alcance real de poblado mantiene celdas y orden")
  comprobar(a._alcance(centro).keys()==a._calcular_alcance(centro).keys(),"orden BFS conservado para elecciones de recursos")
 # No se serializa ni se comparte entre sesiones.
 comprobar(not JSON.stringify(j.d).contains("_alcances"),"caché fuera del guardado")
 print("RESULTADO ",fallos," fallos")
 quit(1 if fallos else 0)
