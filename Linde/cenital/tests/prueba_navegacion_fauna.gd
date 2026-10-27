extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
var total=0
var fallos=0
func ok(v:bool,t:String):
 total+=1
 if not v:fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func _init():
 var j=J.nueva(123,"Navegación",[0,0,0])
 j.mundo.celdas.fill(M.T.PASTO);j.mundo.objetos.clear();j.mundo.por_celda.clear();j.d.mundo.constr.clear();j.mundo.cambiar()
 j.pies=M.pies_de_celda(Vector2i(50,40))
 var inicio=Time.get_ticks_usec();var casos=0;var atascos=0
 for tipo in ["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]:
  for giro in range(4):
   j.d.mundo.constr.clear()
   var centro=Vector2i(26,30)
   for i in range(-3,4):
    var c=centro+rotar(Vector2i(0,i),giro)
    j.d.mundo.constr[M.clave(c)]={"t":"muro"}
   j.mundo.cambiar()
   var desde=M.pies_de_celda(centro+rotar(Vector2i(-2,0),giro))
   var hasta=M.pies_de_celda(centro+rotar(Vector2i(2,0),giro))
   var e=j.combate._nuevo(tipo,desde);e.fauna_id="qa";e.home=hasta;e.est="regresa"
   var velocidad=float(C.ENEMIGOS[tipo].vel)
   # Tiempo de la ruta cardinal más margen de un trayecto, derivado del tamaño del obstáculo.
   var pasos=ceili(2.0*16.0*16.0/velocidad/0.1)
   var cajas=true;var limite=true
   for n in range(pasos):
    var anterior:Vector2=e.pos
    j.combate._paso_enemigo(e,0.1)
    cajas=cajas and j.mundo.caja_libre(e.pos,Vector2(e.tam,e.tam*0.6))
    limite=limite and anterior.distance_to(e.pos)<=velocidad*0.1+0.001
    if e.pos.distance_to(hasta)<8.0:break
   casos+=1
   if e.pos.distance_to(hasta)>=8.0:atascos+=1
   ok(e.pos.distance_to(hasta)<8.0 and cajas and limite,"regreso %s giro %d: rodea sin atravesar ni acelerar"%[tipo,giro])
 print("MEDICION regreso casos=%d atascos=%d porcentaje=%.1f tiempo_ms=%.2f"%[casos,atascos,100.0*atascos/casos,(Time.get_ticks_usec()-inicio)/1000.0])
 var perseguidores=0;var bloqueados=0
 for tipo in ["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]:
  for lado in [-1,1]:
   j.d.mundo.constr.clear();j.d.mundo.constr[M.clave(Vector2i(26,30))]={"t":"muro"};j.mundo.cambiar();j.combate.rutas.clear()
   var desde=Vector2(26*16+8+lado*(8+C.ENEMIGOS[tipo].tam/2.0+1),31*16+1)
   var hasta=Vector2(26*16+8-lado*40,31*16+1)
   var e=j.combate._nuevo(tipo,desde);e.fauna_id="qa";e.alertado=true;e.est="persigue";j.pies=hasta
   var visible=j.combate._visible(e,J.LOCAL);var cajas=true
   for n in range(ceili(256.0/C.ENEMIGOS[tipo].vel/0.1)):
    j.combate._paso_enemigo(e,0.1)
    cajas=cajas and j.mundo.caja_libre(e.pos,Vector2(e.tam,e.tam*0.6))
    if e.est=="aviso":break
   perseguidores+=1
   if e.est!="aviso":bloqueados+=1
   ok(visible and cajas and e.est=="aviso","persecución %s lado %d: esquina visible hasta aviso de ataque"%[tipo,lado])
 print("MEDICION persecucion casos=%d atascos=%d porcentaje=%.1f"%[perseguidores,bloqueados,100.0*bloqueados/perseguidores])
 # Encierro real: no atravesar muros ni buscar repetidamente; abrir invalida el fallo cacheado.
 j.d.mundo.constr.clear()
 for y in range(M.ALTO):j.d.mundo.constr[M.clave(Vector2i(26,y))]={"t":"muro"}
 j.mundo.cambiar();j.combate.rutas.clear();j.pies=M.pies_de_celda(Vector2i(50,40))
 var e=j.combate._nuevo("espectro_bosque",M.pies_de_celda(Vector2i(24,30)));e.fauna_id="qa";e.home=M.pies_de_celda(Vector2i(28,30));e.est="regresa"
 for n in range(80):j.combate._paso_enemigo(e,0.1)
 ok(j.combate.rutas.has("qa") and j.combate.rutas.qa.ruta.is_empty() and e.pos.x<26*16,"destino inaccesible cacheado sin cruzar pared")
 for y in range(28,33):j.d.mundo.constr.erase(M.clave(Vector2i(26,y)))
 j.mundo.cambiar()
 for n in range(100):j.combate._paso_enemigo(e,0.1)
 ok(e.pos.distance_to(e.home)<8.0,"abrir paso invalida caché y recupera regreso")
 # Coste del bloque de IA, no FPS del juego: techo activo actual y 600 pasos a 30 Hz.
 for carga in ["cercana_obstaculo","lejana_reposo"]:
  j.d.mundo.constr.clear()
  for y in range(27,34):j.d.mundo.constr[M.clave(Vector2i(26,y))]={"t":"muro"}
  j.mundo.cambiar();j.combate.rutas.clear()
  var lista=[]
  for n in range(int(j.combate.fauna.cfg.max_activos)):
   var actor=j.combate._nuevo("espectro_bosque",M.pies_de_celda(Vector2i(24,30)))
   actor.fauna_id="costo_%d"%n
   if carga=="cercana_obstaculo":actor.home=M.pies_de_celda(Vector2i(28,30));actor.est="regresa"
   lista.append(actor)
  var acumulado=0;var pico=0
  for n in range(600):
   var reloj=Time.get_ticks_usec()
   for actor in lista:j.combate._paso_enemigo(actor,1.0/30.0)
   var costo=Time.get_ticks_usec()-reloj;acumulado+=costo;pico=maxi(pico,costo)
  print("RENDIMIENTO %s actores=%d pasos=600 media_ms=%.3f pico_ms=%.3f"%[carga,lista.size(),acumulado/600000.0,pico/1000.0])
 print("RESULTADO %d PASS %d FAIL"%[total-fallos,fallos]);quit(1 if fallos else 0)
func rotar(v:Vector2i,giro:int)->Vector2i:
 for n in range(giro):v=Vector2i(-v.y,v.x)
 return v
