extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const E = preload("res://scripts/edificios.gd")
const P = preload("res://tests/prueba_vivienda.gd")
var fallos:=0
func ok(c: bool,t: String)->void:
 print(("PASS " if c else "FAIL ")+t)
 if not c:fallos+=1
func tecla(e,k: int)->void:
 var ev:=InputEventKey.new();ev.pressed=true;ev.keycode=k;e._unhandled_key_input(ev)
func _init()->void:
 var esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-vivienda-ui.json";root.add_child(esc)
 await process_frame
 esc.set_process(false);esc.j=J.nueva(123,"Constructora",[0,0,0],"poblado");esc.modo="juego"
 var j=esc.j;j.combate.enemigos.clear()
 var c:=P.solar_preparado(j)
 j.mira=Vector2i.UP;j.jug().inv=E.coste(E.plano("vivienda",c,J.LOCAL))
 tecla(esc,KEY_B)
 ok(esc.build and esc._opciones_construccion()[esc.pieza_i]=="vivienda","B ofrece primero el plano de vivienda completo")
 ok(esc._info_construccion().coste==j.jug().inv,"vista previa y HUD muestran el precio del mismo plano")
 tecla(esc,KEY_SPACE);tecla(esc,KEY_B)
 var e: Dictionary=j.mundo.edificio_en(c)
 ok(not e.is_empty() and not esc.build and j.jug().inv.is_empty(),"Espacio instala la vivienda y B sale del modo de colocar")
 tecla(esc,KEY_E)
 ok(esc.panel=="edificio" and esc.lineas.any(func(l):return l.contains("completa")),"E en la entrada muestra la vivienda como unidad funcional")
 tecla(esc,KEY_ESCAPE)
 j.pies=M.pies_de_celda(c+Vector2i(-2,-3));j.mira=Vector2i.UP
 tecla(esc,KEY_E)
 ok(esc.panel=="" and j.jug().cama==[j.pies.x,j.pies.y],"E usa la cama y fija el descanso con el comportamiento habitual")
 j.pies=M.pies_de_celda(c+Vector2i(2,-3));j.mira=Vector2i.UP
 tecla(esc,KEY_E)
 ok(esc.panel=="cofre" and esc.cofre_id=="c@"+M.clave(c+Vector2i(2,-4)),"el mobiliario real tiene prioridad sobre la ficha del edificio")
 tecla(esc,KEY_ESCAPE)
 j.pies=M.pies_de_celda(c+Vector2i.DOWN);j.mundo.destechar(c+Vector2i(0,-2))
 j.jug().inv={"madera":1,"fibra":1}
 tecla(esc,KEY_E)
 var indice: int=esc.lineas.find("Reparar: 1 Madera, 1 Fibra")
 if indice<0:
  for i in esc.lineas.size():
   if str(esc.lineas[i]).begins_with("Reparar:"):indice=i
 ok(esc.panel=="edificio" and indice>=0,"la unidad muestra el costo concreto de su reparación")
 if indice>=0:esc.acc[indice].call()
 ok(j.jug().inv.is_empty() and E.coste(E.faltantes(j,e)).is_empty(),"la acción de reparar del panel repone solo la teja faltante")
 quit(1 if fallos else 0)
