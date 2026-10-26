extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const E = preload("res://scripts/edificios.gd")
const P = preload("res://tests/prueba_taller.gd")
var fallos:=0
func ok(c: bool,t: String)->void:
 print(("PASS " if c else "FAIL ")+t)
 if not c:fallos+=1
func tecla(e,k: int)->void:
 var ev:=InputEventKey.new();ev.pressed=true;ev.keycode=k;e._unhandled_key_input(ev)
func _init()->void:
 var esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-taller-ui.json";root.add_child(esc)
 await process_frame
 esc.set_process(false);esc.j=J.nueva(123,"Constructora",[0,0,0],"poblado");esc.modo="juego"
 var j=esc.j;j.combate.enemigos.clear()
 var c:=P.solar_preparado(j)
 j.mira=Vector2i.UP;j.jug().inv=E.coste(E.plano("taller",c,J.LOCAL))
 tecla(esc,KEY_B);tecla(esc,KEY_E)
 ok(esc.build and esc._opciones_construccion()[esc.pieza_i]=="taller","B y E seleccionan el taller completo")
 ok(esc._info_construccion().coste==j.jug().inv,"vista previa y HUD muestran el precio del mismo plano")
 tecla(esc,KEY_SPACE);tecla(esc,KEY_B)
 var e: Dictionary=j.mundo.edificio_en(c)
 ok(not e.is_empty() and not esc.build and j.jug().inv.is_empty(),"Espacio instala la taller y B sale del modo de colocar")
 tecla(esc,KEY_E)
 ok(esc.panel=="edificio" and esc.lineas.any(func(l):return l.contains("Mesa de trabajo") and l.contains("Horno")),"E en la entrada muestra la taller como unidad funcional")
 tecla(esc,KEY_ESCAPE)
 j.pies=M.pies_de_celda(c+Vector2i(-2,-3));j.mira=Vector2i.UP
 tecla(esc,KEY_E)
 ok(esc.panel=="craft","E usa la mesa interior mediante el panel habitual")
 tecla(esc,KEY_ESCAPE)
 j.pies=M.pies_de_celda(c+Vector2i(2,-3));j.mira=Vector2i.UP
 tecla(esc,KEY_E)
 ok(esc.panel=="craft","E usa el horno interior mediante el panel habitual")
 tecla(esc,KEY_ESCAPE)
 j.pies=M.pies_de_celda(c+Vector2i(2,-1));j.mira=Vector2i.UP
 tecla(esc,KEY_E)
 ok(esc.panel=="cofre","E accede al almacenamiento del taller")
 quit(1 if fallos else 0)
