extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Cli=preload("res://scripts/red_cliente.gd")
const Srv=preload("res://scripts/red_servidor.gd")
var total:=0
var fallos:=0
func ok(c: bool, texto: String) -> void:
 total+=1
 print(("PASS " if c else "FAIL ")+texto)
 if not c: fallos+=1
func nuevo():
 var j=J.nueva(123,"Dueña",[0,0,0])
 j.combate.enemigos.clear()
 j.autonomia.activar()
 return j
func _init() -> void:
 var j=nuevo()
 j.pies=M.pies_de_celda(Vector2i(32,40))
 j.jug().inv={"madera":4,"candado":1,"fibra":10}
 ok(j.construir("cofre",Vector2i(33,40)).ok,"construye cofre propio")
 var cid:="c@33,40"
 ok(j.mover_cofre(cid,"fibra",true).ok,"cofre antiguo abierto conserva acceso")
 j.unir("visita","Visita",[0,0,0])
 j.rt.visita.pies=j.pies
 ok(j.gestionar_cofre(cid,"instalar").ok,"coloca candado y lo cierra")
 ok(not j.jug().inv.has("candado"),"instalar consume un candado real")
 ok(not j.gestionar_cofre(cid,"instalar").ok,"no duplica candados al repetir")
 ok(not j.mover_cofre(cid,"fibra",false,"visita").ok,"bloquea retirada ajena aunque panel estuviera abierto")
 j.jug("visita").inv={"piedra":1}
 ok(not j.mover_cofre(cid,"piedra",true,"visita").ok,"bloquea también depósito ajeno")
 ok(not j.gestionar_cofre(cid,"abrir","","visita").ok,"ajeno no abre ni cambia permisos")
 ok(j.gestionar_cofre(cid,"permitir","visita").ok,"dueño autoriza a otro jugador")
 ok(j.mover_cofre(cid,"fibra",false,"visita").ok,"autorizado accede cerrado")
 ok(j.d.cofres[cid].get("incidentes",[]).is_empty(),"acceso autorizado no se registra como robo")
 ok(j.gestionar_cofre(cid,"revocar","visita").ok,"dueño revoca acceso")
 ok(not j.mover_cofre(cid,"fibra",true,"visita").ok,"revocación se aplica a la siguiente acción")
 j.rt.visita.pies=M.pies_de_celda(Vector2i(10,40))
 ok(not j.mover_cofre(cid,"piedra",true,"visita").ok,"rechaza transferencia remota")
 ok(not j.gestionar_cofre(cid,"permitir","inventado").ok,"rechaza permisos para identidad inexistente")
 ok(not j.retirar(Vector2i(33,40)).ok,"candado instalado impide desmontar el cofre")
 ok(j.gestionar_cofre(cid,"abrir").ok,"dueño puede dejarlo abierto para todos")
 j.rt.visita.pies=j.pies
 ok(j.mover_cofre(cid,"fibra",true,"visita").ok,"abierto permite compartir")
 j.gestionar_cofre(cid,"cerrar")
 j.gestionar_cofre(cid,"permitir","visita")
 var ruta:="/tmp/linde-proteccion-test.json"
 ok(j.guardar(ruta),"guarda protección")
 var cargado=J.cargar(ruta)
 ok(cargado.d.cofres[cid].cerrado and cargado.d.cofres[cid].permitidos.has("visita"),"candado y permisos sobreviven al guardado")
 var c=Cli.new();c.yo="visita"
 var replica=Cli.Replica.new();replica.red=c;replica.d=j.d.duplicate(true)
 replica.d.mundo.constr=c._traducir(replica.d.mundo.constr)
 ok(replica.info_cofre(cid).acceso and not replica.info_cofre(cid).propio,"réplica usa la identidad real para permisos sin confundir al anfitrión")
 j.gestionar_cofre(cid,"retirar")
 ok(j.jug().inv.get("candado",0)==1 and not j.d.cofres[cid].cerrado,"retirar recupera exactamente el candado y abre")
 # NPC no atraviesa cerraduras y respeta a un dueño jugador presente.
 var s=j.autonomia.sociedad
 for gid in s.cfg.grupos:s.grupo(gid).inv={}
 j.d.cofres[cid].inv={"gema":2}
 j.d.cofres[cid].cerrado=true
 ok(not s._hurtar("ordal","gema",1),"NPC no roba de cofre cerrado")
 j.d.cofres[cid].cerrado=false
 ok(not s._hurtar("ordal","gema",1),"NPC evita robar junto al dueño jugador")
 j.pies=M.pies_de_celda(Vector2i(10,40))
 var pos:=M.pies_de_celda(Vector2i(32,40));j.d.npcs.ordal.pos=[pos.x,pos.y]
 ok(s._hurtar("ordal","gema",1) and j.d.cofres[cid].inv.gema==1,"cofre abierto sin dueño cerca sí permite hurto físico")
 ok(j.d.cofres[cid].incidentes.size()==1,"robo deja un historial persistente en el cofre")
 ok(not s._hurtar("ordal","gema",1),"hurto tiene espera y no vacía pilas en cada decisión")
 # Valor, mantenimiento pagado y reserva finita.
 var normal: float=s.valor("fibra")
 j.autonomia.estado("maren").inv={"fibra":1000}
 ok(s.valor("fibra")<normal,"abundancia baja valor de fibra")
 var n: Dictionary=j.autonomia.estado("maren")
 n.mantenimiento_periodo=0;j.d.min=1440;j.d.npcs.maren.energia=50
 ok(s._mantener("maren") and n.inv.fibra==992 and j.d.npcs.maren.energia==58,"mantenimiento consume materiales y mejora descanso")
 ok(not s._mantener("maren") and n.inv.fibra==992,"no cobra dos veces el mantenimiento del mismo periodo")
 # Ayuda gratuita no produce estafa aunque se fuerce una probabilidad imposible.
 var trade=nuevo();var st=trade.autonomia.sociedad
 trade.autonomia.reglas.perfiles.ordal.grupo="talleres"
 trade.autonomia.estado("ordal").inv={"lingote":4}
 trade.autonomia.estado("maren").inv={}
 st.cfg.caracter.prob_estafa_max=10
 var acuerdo: String=st.acordar("maren","ordal","lingote",1)
 trade.d.npcs.ordal.pos=trade.d.npcs.maren.pos.duplicate()
 ok(acuerdo!="" and st.entregar(acuerdo) and st.datos().acuerdos[acuerdo].estado=="cumplido","ayuda gratuita entre miembros no se etiqueta como estafa")
 # Instalación autónoma con objeto realmente fabricado y desplazamiento.
 var npc=nuevo();var sn=npc.autonomia.sociedad
 npc.mundo.poner(Vector2i(33,40),"cofre",true,"npc:maren")
 npc.d.cofres[cid]={"inv":{"fibra":20}}
 npc.autonomia.estado("maren").inv={"candado":1}
 var p: Vector2=M.pies_de_celda(Vector2i(32,40));npc.d.npcs.maren.pos=[p.x,p.y]
 ok(sn._proteger("maren") and npc.d.cofres[cid].cerrado and not npc.autonomia.estado("maren").inv.has("candado"),"NPC instala su candado sin crearlo gratis")
 # Fabricación autónoma paga materiales y desgasta la mesa.
 var fabrica=nuevo();var sf=fabrica.autonomia.sociedad
 fabrica.mundo.poner(Vector2i(33,40),"cofre",true,"npc:maren")
 fabrica.mundo.poner(Vector2i(32,39),"mesa",true,"npc:maren")
 fabrica.d.cofres[cid]={"inv":{"fibra":20}}
 fabrica.autonomia.estado("maren").inv={"lingote":2,"fibra":2}
 fabrica.d.npcs.maren.pos=[p.x,p.y]
 ok(sf._proteger("maren") and fabrica.d.cofres[cid].cerrado and fabrica.autonomia.estado("maren").inv.is_empty(),"NPC fabrica e instala pagando lingotes y fibra")
 ok(int(sf.datos().estaciones["32,39"])==1 and not sf._proteger("maren"),"fabricación desgasta mesa una vez y no cobra de nuevo")
 # Identidad persistente: horarios válidos, preferencias que afectan reservas y migración aditiva.
 var propio=nuevo();var sp=propio.autonomia.sociedad
 var molde: Dictionary=propio.habitantes._paq.entidades.npc.maren.duplicate(true)
 var perfil: Dictionary=propio.autonomia.perfil("maren").duplicate(true)
 sp._personalizar_colono(molde,perfil,propio._rng("prueba","identidad"))
 ok(propio.habitantes.registrar_colono("colono_prueba",molde)=="","horario desplazado sigue siendo ejecutable")
 var minutos:=0
 for fr in molde.data.horario:minutos+=int(fr.hasta_minuto)-int(fr.desde_minuto)
 ok(minutos==1440,"horario generado cubre un día completo")
 propio.d.mundo_vivo.autonomia.colonos={"colono_prueba":{"npc":molde,"perfil":perfil}}
 propio.d.npcs.colono_prueba=propio.habitantes.nuevo("colono_prueba")
 propio.habitantes.ids.append("colono_prueba")
 perfil.identidad={"objetivo":"que no falte comida","preferencia":"alimentos","reserva_extra":2}
 propio.autonomia.estado("colono_prueba").inv={}
 ok(sp.reserva_comida("colono_prueba")==4,"preferencia alimentaria cambia necesidad real")
 var frase: String=propio.autonomia.dialogo("colono_prueba",J.LOCAL)
 ok(frase.contains("que no falte comida"),"diálogo refleja objetivo propio")
 propio.guardar("/tmp/linde-identidad-test.json")
 var identidad_cargada=J.cargar("/tmp/linde-identidad-test.json")
 ok(identidad_cargada.autonomia.perfil("colono_prueba").identidad.preferencia=="alimentos","preferencias sobreviven al guardado")
 perfil.erase("identidad")
 sp.restaurar()
 var horario: String=JSON.stringify(molde.data.horario)
 sp.restaurar()
 ok(perfil.has("identidad") and JSON.stringify(molde.data.horario)==horario,"colono anterior recibe identidad una sola vez")
 # La confianza reduce riesgo, los bienes reservados no cambian al variar precios.
 ok(st.riesgo_estafa("maren","ordal")>0.0,"intercambio pagado conserva posibilidad de engaño")
 var riesgo: float=st.riesgo_estafa("maren","ordal")
 st._vinculo("maren","ordal",10)
 ok(st.riesgo_estafa("maren","ordal")<riesgo,"relación de confianza reduce riesgo de estafa")
 # Los materiales comprometidos en un proyecto no se prestan antes de usarlos.
 var pr=nuevo();var sr=pr.autonomia.sociedad
 pr.autonomia.estado("maren").inv={"madera":4}
 sr.comprometer("maren",{"madera":4})
 ok(sr.excedente("maren","madera")==0,"insumos del proyecto no aparecen como excedente negociable")
 pr.d.min+=int(sr.cfg.plazo_acuerdo_min)+1
 ok(sr.excedente("maren","madera")>0,"compromiso abandonado vence y libera recursos")
 # Recolección selectiva conserva lo existente y deja de acumular fibra por buscar bayas.
 var recolector=nuevo();var sc=recolector.autonomia.sociedad
 var arbusto: String=recolector.autonomia._recurso("maren","baya")
 var celda: Vector2i=recolector.mundo.objetos[arbusto].c
 var camino: Array=recolector.mundo.camino(M.celda_de(recolector.habitantes.pos("maren")),func(x):return recolector.mundo.es_adyacente(x,celda))
 var pie: Vector2=M.pies_de_celda(camino.back());recolector.d.npcs.maren.pos=[pie.x,pie.y]
 recolector.autonomia.estado("maren").inv={"fibra":int(sc.cfg.economia.fibra_objetivo_persona)}
 ok(sc._recolectar("maren",arbusto,"alimentarme") and recolector.autonomia.estado("maren").inv.fibra==int(sc.cfg.economia.fibra_objetivo_persona),"buscar bayas con suficiente fibra no suma ni elimina fibra acumulada")
 # Estafa pagada: conservación de bienes y resolución única, incluso con probabilidad forzada.
 var fraude=nuevo();var se=fraude.autonomia.sociedad
 fraude.autonomia.estado("maren").inv={"pico_piedra":2}
 fraude.autonomia.estado("ordal").inv={"fibra":12}
 se.cfg.caracter.prob_estafa_max=20
 var contrato: String=se.acordar("ordal","maren","pico_piedra",1)
 fraude.d.npcs.ordal.pos=fraude.d.npcs.maren.pos.duplicate()
 ok(contrato!="" and se.entregar(contrato) and se.datos().acuerdos[contrato].estado=="estafado","intercambio pagado puede terminar en estafa")
 var uno: Dictionary=fraude.autonomia.estado("maren").inv
 var dos: Dictionary=fraude.autonomia.estado("ordal").inv
 ok(uno.get("pico_piedra",0)+dos.get("pico_piedra",0)==2 and uno.get("fibra",0)+dos.get("fibra",0)==12 and not se.entregar(contrato),"estafa conserva los bienes y no se ejecuta dos veces")
 # Intenciones de red: servidor valida dueño, distancia y secuencia.
 var net=nuevo();net.pies=M.pies_de_celda(Vector2i(32,40));net.jug().inv={"madera":4,"candado":1}
 net.construir("cofre",Vector2i(33,40));net.unir("otra","Otra",[0,0,0]);net.rt.otra.pies=net.pies
 var servidor=Srv.new();servidor.j=net
 ok(servidor.ejecutar(J.LOCAL,["gestionar_cofre",1,cid,"instalar",""]) and net.d.cofres[cid].cerrado,"intención de red instala candado en autoridad")
 ok(not servidor.ejecutar(J.LOCAL,["gestionar_cofre",1,cid,"retirar",""]) and net.d.cofres[cid].cerrado,"secuencia repetida no revierte el candado")
 servidor.ejecutar("otra",["gestionar_cofre",1,cid,"abrir",""])
 ok(net.d.cofres[cid].cerrado,"servidor impide que otro jugador abra el candado")
 net.pies=M.pies_de_celda(Vector2i(10,40))
 ok(not servidor.ejecutar(J.LOCAL,["gestionar_cofre",2,cid,"retirar",""]) and net.d.cofres[cid].cerrado,"servidor rechaza manipulación remota del candado")
 servidor.free();c.free()
 print("PROTECCION: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
