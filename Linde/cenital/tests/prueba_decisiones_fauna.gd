extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const C=preload("res://scripts/catalogos.gd")
const Fix=preload("res://tests/fixture_senales.gd")
var total=0
var fallos=0
func ok(v:bool,t:String):
 total+=1
 if not v:fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func _init():
 var j=J.nueva(123,"Decisiones",[0,0,0],M.MODO_POBLADO)
 var fixture=Fix.preparar(j)
 ok(not fixture.is_empty(),"escenario mínimo existente proporciona una fuente real")
 if fixture.is_empty():quit(1);return
 var fuente:Dictionary=fixture.enemigo.duplicate(true)
 # Campo controlado de QA en el Valle: la entidad conserva su ID real; no se modifica el plan.
 j.mundo.celdas.fill(M.T.PASTO)
 for id in j.mundo.objetos.keys():
  var c:Vector2i=j.mundo.objetos[id].c
  if M.es_valle(c):j.mundo.objetos.erase(id);j.mundo.por_celda.erase(c)
 j.d.mundo.constr.clear();j.mundo.cambiar()
 var origen=M.pies_de_celda(Vector2i(26,30));var dt=1.0/30.0
 for tipo in ["espectro_bosque","golem_sierra","diablillo_secano","arpia_pradera","slime_ribera"]:
  for decision in ["acercarse","retirarse","rodear"]:
   var e=j.combate._nuevo(tipo,origen);e.fauna_id=fuente.fauna_id;e.alertado=true
   j.combate.enemigos=[e];j.combate.rutas.clear();j.combate.pjs.clear();j.jug().hp=j.stats().hp
   var hp=j.jug().hp
   var radio=float(j.autonomia.reglas.conocimiento.radio_vision)*M.P.CELDA
   j.pies=origen-Vector2(radio,0)
   var senal=-1.0;var dano=-1.0;var ataque=-1.0;var transcurrido=0.0
   # Duración derivada del recorrido al contacto y del aviso/recuperación actuales.
   var duracion=radio/float(C.ENEMIGOS[tipo].vel)+C.ENEMIGOS[tipo].aviso+C.ENEMIGOS[tipo].rec
   for n in range(ceili(duracion/dt)):
    if senal<0 and not j.aviso_ecologico().is_empty():senal=transcurrido
    var direccion=Vector2i.ZERO
    if decision=="acercarse" and j.pies.distance_to(origen)>float(C.ENEMIGOS[tipo].vision)*0.5:direccion=Vector2i.RIGHT
    elif decision=="retirarse":direccion=Vector2i.LEFT
    elif decision=="rodear":
     direccion=Vector2i.DOWN if j.pies.y<origen.y+radio else Vector2i.RIGHT
    j.mover_pj(direccion,dt);j.combate._paso_enemigo(e,dt)
    if e.est=="aviso" and ataque<0:ataque=transcurrido
    if j.jug().hp<hp:dano=transcurrido;break
    transcurrido+=dt
   if decision=="acercarse":
    ok(senal>=0 and dano>senal and ataque>=senal and dano-ataque>=float(C.ENEMIGOS[tipo].aviso)-dt,"%s: aviso perceptible y preparación antes de daño"%tipo)
    print("MEDICION %s senal_s=%.3f ataque_s=%.3f dano_s=%.3f margen_s=%.3f"%[tipo,senal,ataque,dano,dano-senal])
   else:
    ok(senal>=0 and dano<0 and j.pies.distance_to(origen)>radio,"%s: %s evita contacto mediante movimiento real"%[tipo,decision])
 # Sin línea de visión no se inventa aviso; al abrirla reaparece sin retrasar el combate.
 var e=j.combate._nuevo("espectro_bosque",origen);e.fauna_id=fuente.fauna_id;j.combate.enemigos=[e];j.pies=origen-Vector2(64,0)
 var c=M.celda_de(origen-Vector2(32,0));j.d.mundo.constr[M.clave(c)]={"t":"muro"};j.mundo.cambiar()
 ok(j.aviso_ecologico().is_empty() and not j.combate._visible(e,J.LOCAL),"pared oculta tanto la advertencia visual como la detección")
 j.d.mundo.constr.erase(M.clave(c));j.mundo.cambiar()
 ok(not j.aviso_ecologico().is_empty(),"al recuperar visión se puede decidir sin gracia artificial")
 print("RESULTADO %d PASS %d FAIL"%[total-fallos,fallos]);quit(1 if fallos else 0)
