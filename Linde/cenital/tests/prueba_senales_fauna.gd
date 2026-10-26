extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const S=preload("res://scripts/red_servidor.gd")
const Cli=preload("res://scripts/red_cliente.gd")
const Fix=preload("res://tests/fixture_senales.gd")
var total=0
var fallos=0
func ok(v:bool,t:String):
 total+=1
 if not v:fallos+=1
 print(("PASS " if v else "FAIL ")+t)
func _init():
 var j=J.nueva(123,"Observador",[0,0,0],M.MODO_POBLADO);var fixture=Fix.preparar(j)
 ok(not fixture.is_empty(),"encuentro de prueba materializado desde una fuente regional real")
 if fixture.is_empty():quit(1);return
 var e:Dictionary=fixture.enemigo;var pos:Vector2=fixture.observador
 var inicial=j.d.fauna.duplicate(true)
 var aviso=j.aviso_ecologico()
 ok(not aviso.is_empty() and aviso.has("direccion") and not aviso.has("fuente") and not aviso.has("ancla"),"aviso vigente direccional sin identidad oculta ni coordenadas")
 ok(j.d.fauna==inicial,"consultar un aviso no altera población, bajas ni fuentes")
 j.pies=e.pos;ok(j.aviso_ecologico().get("direccion","")=="aquí","una fuente superpuesta no inventa una dirección cardinal");j.pies=pos
 j.actualizar_mapa();var memoria:Dictionary=j.jug().mapa.avistamientos
 ok(memoria.size()==1 and memoria.values()[0].fuente==e.fauna_id,"avistamiento privado conserva fuente real y fecha")
 var bloque=memoria.keys()[0];var fecha=memoria[bloque].min
 j.unir("otro","Otro",[0,0,0]);j.rt.otro.pies=M.pies_de_celda(Vector2i(32,23));j.actualizar_mapa()
 ok(not j.jug("otro").mapa.has("avistamientos") and j.aviso_ecologico("otro").is_empty(),"otro jugador no hereda señal ni recuerdos personales")
 j.pies=pos+Vector2(512,0)
 ok(j.aviso_ecologico().is_empty(),"al alejarse no hay aviso vigente aunque exista historia")
 j.pies=pos
 # Barrera real en el rayo de visión; no cambia el radio de percepción.
 var mitad=M.celda_de(pos.lerp(e.pos,0.5));var key=M.clave(mitad);var anterior=j.d.mundo.constr.get(key,{}).duplicate(true)
 j.d.mundo.constr[key]={"t":"muro","dueno":J.LOCAL};j.mundo.cambiar()
 ok(j.aviso_ecologico().is_empty(),"una pared impide la señal por visión")
 if anterior.is_empty():j.d.mundo.constr.erase(key)
 else:j.d.mundo.constr[key]=anterior
 j.mundo.cambiar()
 ok(not j.aviso_ecologico().is_empty(),"restaurar visión recupera el aviso desde la misma fuente viva")
 var original_pos:Vector2=e.pos;e.pos+=Vector2(512,0)
 ok(j.aviso_ecologico().is_empty() and memoria[bloque].min==fecha,"movimiento fuera de alcance retira aviso sin actualizar una ubicación histórica")
 e.pos=original_pos;j.combate._danar(e,999)
 ok(j.aviso_ecologico().is_empty(),"muerte confirmada retira inmediatamente el aviso actual")
 var referencias:Array=j.Exploracion.hitos(j,J.LOCAL).filter(func(h):return h.get("tipo","")=="avistamiento")
 ok(referencias.size()==1 and referencias[0].bloque==bloque and referencias[0].min==fecha,"mapa conserva fecha y bloque aproximado, no presencia actual")
 var ruta=OS.get_cache_dir()+"/linde-senales-%d.json"%OS.get_process_id();j.guardar(ruta);var rec=J.cargar(ruta)
 ok(rec!=null and rec.jug().mapa.avistamientos==memoria and rec.aviso_ecologico().is_empty(),"guardar y cargar conserva memoria sin resucitar el aviso")
 # El jugador cuenta lo observado; el NPC no inventa otra amenaza ni otro tiempo.
 var npc="maren";j.pies=j.habitantes.pos(npc);j.preguntar_lugares(npc)
 ok(j.d.fauna.informes_npc[npc].has(bloque),"conversación voluntaria entrega un testimonio real al NPC")
 j.rt.otro.pies=j.habitantes.pos(npc);j.preguntar_lugares(npc,"otro")
 var contado:Dictionary=j.jug("otro").mapa.avistamientos.get(bloque,{})
 ok(not contado.is_empty() and contado.relato=="npc:"+npc and contado.min==fecha,"NPC transmite un recuerdo fechado con procedencia, incluso tras la derrota")
 ok(j.aviso_ecologico("otro").is_empty(),"un rumor histórico no se convierte en alarma de criatura viva")
 var srv=S.new();srv.j=j
 var pr:Dictionary=srv.privado(J.LOCAL);var publico=JSON.stringify(pr.mapa)
 ok(not publico.contains("fuente") and not publico.contains("ancla") and not publico.contains(e.fauna_id),"estado privado de red oculta IDs y anclas internas")
 var bienvenida=JSON.stringify(srv.estado_para("otro"))
 ok(not bienvenida.contains("informes_npc") and not bienvenida.contains(e.fauna_id) and not JSON.stringify(srv.perfiles()).contains("avistamientos"),"informes de NPC e identidades internas no se publican en bienvenida ni perfiles")
 var cli=Cli.new();cli._bienvenida(srv.estado_para("otro"))
 ok(cli.j.aviso_ecologico().is_empty() and cli.j.Exploracion.hitos(cli.j,J.LOCAL).any(func(h):return h.get("tipo","")=="avistamiento"),"réplica muestra historia privada recibida sin generar avisos por su cuenta")
 cli.free();srv.free()
 var legado=J.nueva(123,"Legado",[0,0,0]);legado.actualizar_mapa()
 ok(legado.aviso_ecologico().is_empty() and not legado.jug().has("mapa"),"modo legado sin señales ni estado nuevo")
 print("SENALES: %d comprobaciones, %d fallos"%[total,fallos]);quit(1 if fallos else 0)
