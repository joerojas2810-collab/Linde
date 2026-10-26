extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Esc=preload("res://scripts/escena.gd")
const V=preload("res://scripts/viajero071.gd")
var total:=0
var fallos:=0
func ok(c:bool,t:String):
 total+=1
 if not c:fallos+=1
 print(("PASS " if c else "FAIL ")+t)
func _initialize():call_deferred("run")
func run():
 var e=Esc.new();e.j=J.nueva(123,"QA",[0,1,0]);e.j.d.min=1380;e.j.d.npcs.maren.energia=1.0
 var cama:Vector2i=e.j.habitantes.cama("maren")
 for dir in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
  var p:=M.pies_de_celda(cama+dir);e.j.d.npcs.maren.pos=[p.x,p.y];e.j.habitantes.paso(0.05)
  var antes=JSON.stringify(e.j.d)
  ok(e._cama_visual_npc("maren"),"cama efectiva desde lado "+str(dir))
  var visual:Vector2=e._pies_visuales_npc("maren")
  ok(visual.is_equal_approx(Vector2(cama)*16+Vector2(8,16.01)),"anclaje único al lecho, independiente de llegada "+str(dir))
  ok(JSON.stringify(e.j.d)==antes and e.j.habitantes.pos("maren")==p,"proyección conserva datos y pies lógicos "+str(dir))
  ok(visual.y>Vector2(cama).y*16+16,"durmiente se ordena después de su cama "+str(dir))
 var lejos:=M.pies_de_celda(cama+Vector2i(0,5));e.j.d.npcs.maren.pos=[lejos.x,lejos.y]
 ok(not e._cama_visual_npc("maren"),"estado residual lejos de la cama no proyecta al personaje sobre ella")
 e.j.d.npcs.maren.pos=[M.pies_de_celda(cama+Vector2i.DOWN).x,M.pies_de_celda(cama+Vector2i.DOWN).y]
 e.j.d.min=360;e.j.d.npcs.maren.energia=100;e.j.habitantes.paso(0.05)
 ok(not e._cama_visual_npc("maren") and e._pies_visuales_npc("maren")==e.j.habitantes.pos("maren"),"despertar vuelve inmediatamente a pies lógicos")
 e.j.mundo.quitar(cama);e.j.d.min=1380;e.j.habitantes.paso(0.05)
 ok(e.j.d.npcs.maren.act=="sin_cama" and not e._cama_visual_npc("maren"),"ausencia real de cama produce sueño al raso")
 ok(e._pies_visuales_npc("maren")==e.j.habitantes.pos("maren"),"al raso no se desplaza al lecho desaparecido")
 var v=V.new()
 for dir in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
  var distintos:Array=[]
  for frame in 3:
   var tex:Texture2D=v.herramienta_textura(dir,frame,"pico")
   var im:Image=tex.get_image();distintos.append(hash(im.get_data()))
   ok(im.get_used_rect().has_area(),"pico visible por sí mismo: "+str(dir)+" cuadro "+str(frame))
   ok(tex==v.herramienta_textura(dir,frame,"pico"),"capa de herramienta usa caché")
  ok(distintos[0]!=distintos[1] and distintos[1]!=distintos[2],"tres poses distintas de golpe "+str(dir))
 var view=1
 var antes=v.pose(view,"ataque",1)
 ok(is_equal_approx(antes.arm0.get_rotation(),deg_to_rad(145.0)),"corrección del útil conserva pose de ataque de espada")
 e.cam.free();e.hud.free();e.j=null;e.free()
 print("CORRECCIONES_A2_A3: %d comprobaciones, %d fallos"%[total,fallos]);quit(1 if fallos else 0)
