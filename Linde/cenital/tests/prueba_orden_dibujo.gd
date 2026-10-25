extends SceneTree
const Escena = preload("res://scripts/escena.gd")
var total := 0
var fallos := 0
func ok(c: bool, texto: String) -> void:
 total+=1
 if not c: fallos+=1
 print(("PASS " if c else "FAIL ")+texto)
func orden_fila(lista: Array, comparar: Callable) -> String:
 lista.sort_custom(comparar)
 var ids: Array=[]
 for e in lista:
  if e[0]==320.0 and e[1]=="obj":ids.append(e[2])
 return ",".join(ids)
func _init() -> void:
 var anterior_viejo := ""
 var anterior_nuevo := ""
 var cambios_viejos := 0
 var cambios_nuevos := 0
 for paso in range(-6,7):
  var lista: Array=[Escena.entrada_dibujo(Vector2(80,320+paso),"pj",null,"local")]
  for i in 80:
   lista.append(Escena.entrada_dibujo(Vector2((i%20)*16,288+(i/20)*16),"obj","arbol_%02d"%i,"arbol_%02d"%i))
  var viejo:=orden_fila(lista.duplicate(),func(a,b):return a[0]<b[0])
  var nuevo:=orden_fila(lista.duplicate(),Escena.ordenar_dibujo)
  if anterior_viejo!="" and anterior_viejo!=viejo:cambios_viejos+=1
  if anterior_nuevo!="" and anterior_nuevo!=nuevo:cambios_nuevos+=1
  anterior_viejo=viejo;anterior_nuevo=nuevo
 ok(cambios_viejos>0,"reproduce el intercambio de árboles empatados al mover al personaje")
 ok(cambios_nuevos==0,"los mismos árboles conservan su orden en todos los pasos")
 var lista: Array=[]
 for i in 50:
  lista.append(Escena.entrada_dibujo(Vector2(i*16,320),"obj",str(i),str(i)))
 var esperado:=orden_fila(lista.duplicate(),Escena.ordenar_dibujo)
 lista.reverse()
 ok(orden_fila(lista,Escena.ordenar_dibujo)==esperado,"recargar regiones en otro orden no cambia la superposición")
 lista.push_front(Escena.entrada_dibujo(Vector2(-32,320),"obj","fuera_izquierda","fuera_izquierda"))
 lista.append(Escena.entrada_dibujo(Vector2(900,320),"obj","fuera_derecha","fuera_derecha"))
 lista.sort_custom(Escena.ordenar_dibujo)
 var centrales: Array=lista.filter(func(e):return not str(e[2]).begins_with("fuera_"))
 ok(orden_fila(centrales,Escena.ordenar_dibujo)==esperado,"entrar y salir elementos del encuadre no altera el orden de los restantes")
 var arbol:=Escena.entrada_dibujo(Vector2(80,320),"obj","arbol","arbol")
 var atras:=Escena.entrada_dibujo(Vector2(96,319),"pj",null,"local")
 var delante:=Escena.entrada_dibujo(Vector2(64,321),"pj",null,"local")
 ok(Escena.ordenar_dibujo(atras,arbol) and Escena.ordenar_dibujo(arbol,delante),"el personaje sigue pasando detrás o delante según la profundidad")
 var cama:=Escena.entrada_dibujo(Vector2(80,320),"constr",Vector2i(4,19),"4,19")
 ok(Escena.ordenar_dibujo(cama,arbol)!=Escena.ordenar_dibujo(arbol,cama),"objetos de distinta clase con la misma posición tienen desempate fijo")
 print("ORDEN_DIBUJO: %d comprobaciones, %d fallos; cambios antiguos=%d, nuevos=%d"%[total,fallos,cambios_viejos,cambios_nuevos])
 quit(1 if fallos else 0)
