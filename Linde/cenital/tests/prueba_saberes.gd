extends SceneTree
## Nivel A de conocimiento (PLAN_IMPLEMENTACION §7): saberes por actor, enseñanza entre habitantes y con el jugador,
## persistencia y validación en servidor. Incluye la primera prueba vertical (§12).
const J = preload("res://scripts/juego.gd")
const A = preload("res://scripts/artesania.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
const G = preload("res://scripts/guardado.gd")
const RUTA := "/tmp/linde-saberes-prueba.json"
const RUTA_COMPAT := "/tmp/linde-saberes-compat.json"
const RUTA_PREVIO := "/tmp/linde-saberes-previo.json"
var fallos := 0
var total := 0

func ok(c: bool, texto: String) -> void:
	total+=1
	print(("PASS " if c else "FAIL ")+texto)
	if not c: fallos+=1

func nuevo():
	var j=J.nueva(123,"Explorador",[0,0,0])
	j.combate.enemigos.clear()
	j.autonomia.activar()
	return j

func sim(j, minutos: int) -> void:
	for i in minutos*10:j.tick(0.1)

func ordenado(a) -> Array:
	var l: Array = a.duplicate()
	l.sort()
	return l

func canon(v) -> String:
	return JSON.stringify(v,"",true)

## Avanza hasta que `nid` no esté en su franja de descanso.
func despierto(j, nid: String) -> void:
	var guardia := 0
	while j.autonomia.desarrollo._descansa(nid) and guardia<40:
		sim(j,30)
		guardia+=1

## Simula hasta que `actor` conozca `id` o se agote el tiempo; devuelve los minutos usados.
func hasta_saber(j, actor: String, id: String, limite: int) -> int:
	var usados := 0
	while usados<limite and not j.autonomia.desarrollo.tiene_saber(actor,id):
		sim(j,30)
		usados+=30
	return usados

func _init() -> void:
	# --- Catálogo y siembra por oficio y experiencia ---
	var j=nuevo()
	var d=j.autonomia.desarrollo
	var yo: String=j.actor_desarrollo()
	ok(d.validar_saberes().is_empty(),"el catálogo de saberes solo referencia técnicas y laminados existentes")
	ok(d.catalogo().size()==11 and d.catalogo().has("tec:ligera") and d.catalogo().has("lam:hierro_fibra"),"el punto de partida son 11 saberes: 2 técnicas y 9 laminados")
	ok(ordenado(d._saber_de("npc:maren").keys())==["lam:bronce_fibra","lam:hierro_fibra","tec:ligera","tec:reforzada"],"Maren conoce técnicas artesanales avanzadas")
	ok(ordenado(d._saber_de("npc:ordal").keys())==["lam:hierro_piedra","tec:reforzada"],"Ordal conoce lo que su oficio de cantero justifica")
	d.sembrar("npc:nerea")
	ok(ordenado(d._saber_de("npc:nerea").keys())==["tec:ligera"],"Nerea conoce lo propio de su actividad, no el catálogo de su profesión")
	ok(d._saber_de("npc:maren").size()!=d._saber_de("npc:nerea").size() and d._saber_de("npc:maren").keys()!=d._saber_de("npc:ordal").keys(),"no todos los habitantes nacen con los mismos saberes")
	ok(d._saber_de(yo).is_empty(),"el jugador empieza sin saberes especializados")
	ok(d.datos().historia.is_empty(),"la siembra no atribuye inventor ni aprendices")
	var simple:=A.clave("espada","madera","simple",0)
	var ligera:=A.clave("espada","madera","ligera",0)
	ok(d.sabe(yo,simple),"fabricar de forma simple es conocimiento común")
	ok(d.sabe("npc:maren",ligera) and not d.sabe(yo,ligera),"conocer una técnica es propio de cada personaje")
	ok(d.sabe("npc:maren",ligera) and not d.puede("npc:maren",ligera),"saber una técnica no basta: faltan material visto, rango y taller")
	ok(d.valido(ligera) and not d.valido("art1:espada:fibra:simple:0") and not d.valido("art2:espada:madera:ligera:0"),"validez, saber, poder y preparación son cuatro consultas distintas: una pieza válida no implica que alguien la conozca")
	var antes_actores: int=d.datos().actores.size()
	ok(not d.sabe("npc:fantasma",ligera) and d.datos().actores.size()==antes_actores,"consultar el saber de un desconocido no crea estado")
	ok(d.candidatos(yo)==["tec:ligera"],"un principiante solo está preparado para la técnica ligera")

	# --- Enseñanza con el jugador: validaciones y efectos ---
	despierto(j,"maren")
	j.pies=M.pies_de_celda(M.ENTRADA)
	ok(not j.pedir_saber("maren","tec:ligera").ok and not d.tiene_saber(yo,"tec:ligera"),"no se aprende a distancia")
	j.pies=j.habitantes.pos("maren")
	ok(not j.pedir_saber("maren","tec:reforzada").ok and not d.tiene_saber(yo,"tec:reforzada"),"no se aprende una técnica sin la preparación necesaria")
	ok(not j.pedir_saber("maren","lam:cobre_madera").ok,"un habitante no enseña lo que no conoce")
	var grupo: String=j.autonomia.sociedad.grupo_de("maren")
	j.autonomia.sociedad.grupo(grupo).reputacion[J.LOCAL]=-5
	ok(not j.pedir_saber("maren","tec:ligera").ok and not d.tiene_saber(yo,"tec:ligera"),"un habitante que desconfía del jugador no enseña")
	j.autonomia.sociedad.grupo(grupo).reputacion.erase(J.LOCAL)
	var practica_antes: Dictionary=d.estado(yo).practica.duplicate(true)
	var inv_antes: Dictionary=j.jug().inv.duplicate(true)
	ok(j.pedir_saber("maren","tec:ligera").ok and d.tiene_saber(yo,"tec:ligera"),"el jugador aprende de Maren cuando está cerca y es de fiar")
	ok(d.estado(yo).practica==practica_antes and j.jug().inv==inv_antes,"aprender no concede práctica ni piezas")
	ok(d.sabe(yo,ligera) and d.tiene_saber("npc:maren","tec:ligera"),"el maestro conserva el saber")
	var h: Dictionary=d.datos().historia["tec:ligera"]
	ok(h.aprendices.size()==1 and h.aprendices[0].actor==yo and h.aprendices[0].de=="npc:maren" and h.primero.is_empty(),"queda constancia del aprendizaje sin inventar un descubridor")
	ok(not j.pedir_saber("maren","tec:ligera").ok and d.datos().historia["tec:ligera"].aprendices.size()==1,"repetir la lección no duplica el aprendizaje")
	ok(j.autonomia.estado("maren").recuerdos.any(func(r): return r.hecho=="enseno" and r.detalle.contains("ligera")),"Maren recuerda haber enseñado")
	d.estado(yo).saber.erase("tec:ligera")
	d.aprender(yo,"tec:ligera","prueba")
	ok(d.datos().historia["tec:ligera"].aprendices.size()==2,"cada aprendizaje real es un evento independiente")

	# --- A5: la autoría sobrevive al desbordamiento real de memorias y de creaciones ---
	var historia_a5: String=canon(d.datos().historia)
	for i in 40: j.autonomia._recordar("maren","prueba","detalle %d"%i)
	var recuerdos_maren: Array=j.autonomia.estado("maren").recuerdos
	ok(recuerdos_maren.size()==int(j.autonomia.reglas.tope_recuerdos) and not recuerdos_maren.any(func(r): return r.hecho=="enseno"),"la memoria de Maren se desborda y olvida la lección")
	for i in 70: d._creacion(yo,simple,{})
	ok(d.datos().creaciones.size()==int(d.cfg.tope_creaciones),"tras 70 creaciones el registro queda en el tope de 64")
	ok(canon(d.datos().historia)==historia_a5 and d.datos().historia["tec:ligera"].aprendices.size()==2,"con memoria desbordada y más de 64 creaciones, la historia de saberes no cambia")

	# --- Autoría independiente de memorias y creaciones ---
	j.autonomia.estado("maren").recuerdos.clear()
	d.datos().creaciones.clear()
	ok(d.datos().historia["tec:ligera"].total==2,"la historia de saberes no depende de recuerdos ni de las 64 creaciones")
	ok(d.aprender("npc:ordal","lam:cobre_madera","descubrimiento") and d.datos().historia["lam:cobre_madera"].primero.actor=="npc:ordal","el primer descubrimiento queda atribuido a quien lo logra")
	ok(d.aprender(yo,"lam:cobre_madera","descubrimiento") and d.datos().historia["lam:cobre_madera"].primero.actor=="npc:ordal" and d.datos().historia["lam:cobre_madera"].aprendices.size()==2,"un segundo descubridor no sustituye al primero")
	ok(not d.aprender(yo,"saber:inexistente","prueba"),"no se conceden saberes que no existen")

	# --- Servidor autoritativo y réplica ---
	var srv=Srv.new();srv.j=j
	d.estado(yo).saber.erase("tec:ligera")
	ok(not srv.ejecutar(J.LOCAL,["pedir_saber",1,5,"tec:ligera"]) and not srv.ejecutar(J.LOCAL,["pedir_saber",2,"fantasma","tec:ligera"]),"la red rechaza tipos inválidos y habitantes inexistentes")
	ok(srv.ejecutar(J.LOCAL,["pedir_saber",3,"maren","tec:reforzada"]) and not d.tiene_saber(yo,"tec:reforzada"),"el servidor decide: el cliente no obtiene un saber para el que no está preparado")
	ok(srv.ejecutar(J.LOCAL,["pedir_saber",4,"maren","tec:ligera"]) and d.tiene_saber(yo,"tec:ligera"),"una petición válida de enseñanza se resuelve en el servidor")
	ok(not srv.ejecutar(J.LOCAL,["pedir_saber",4,"maren","tec:ligera"]),"la red descarta un número de secuencia repetido")
	# A7: los pedidos mal formados o con autor/saber manipulado se rechazan, se cuentan y no cambian nada.
	var rechazos_antes: int=int(srv.registro.rechazos.get(J.LOCAL,0))
	var saber_antes: String=canon(d.estado(yo).saber)+canon(d.estado("npc:maren").saber)
	var historia_antes: String=canon(d.datos().historia)
	ok(not srv.ejecutar(J.LOCAL,["pedir_saber",5,"maren","tec:reforzada","pj:otro"]),"un pedido con un argumento extra de autor se rechaza")
	ok(not srv.ejecutar(J.LOCAL,["pedir_saber",6,"maren"]),"un pedido incompleto se rechaza")
	ok(not srv.ejecutar(J.LOCAL,["ensenar_saber",7,"maren","x".repeat(60)]),"un saber de longitud excesiva se rechaza")
	ok(not srv.ejecutar(J.LOCAL,["ensenar_saber",8,"fantasma","tec:ligera"]),"enseñar a un habitante inexistente se rechaza")
	ok(not srv.ejecutar("pj:inexistente",["pedir_saber",1,"maren","tec:ligera"]),"un remitente sin sesión se rechaza")
	ok(int(srv.registro.rechazos.get(J.LOCAL,0))==rechazos_antes+4 and int(srv.registro.rechazos.get("pj:inexistente",0))==1,"cada rechazo queda contado por remitente")
	ok(canon(d.estado(yo).saber)+canon(d.estado("npc:maren").saber)==saber_antes and canon(d.datos().historia)==historia_antes,"los pedidos rechazados no cambian el conocimiento ni la historia")
	ok(srv.ejecutar(J.LOCAL,["ensenar_saber",9,"maren","tec:reforzada"]) and int(srv.registro.rechazos.get(J.LOCAL,0))==rechazos_antes+4,"un pedido bien formado pero sin saber que enseñar no es un rechazo de red y no concede nada")
	ok(not d.tiene_saber(yo,"tec:reforzada"),"el cliente no obtiene un saber que no tiene por pedir que se enseñe")
	var cli=Cli.new()
	cli._bienvenida(srv.estado_para(J.LOCAL))
	var dc=cli.j.autonomia.desarrollo
	ok(dc.sabe(cli.j.actor_desarrollo(),ligera) and dc.tiene_saber("npc:maren","tec:reforzada"),"la réplica consulta los mismos saberes con la identidad correcta")
	dc.sembrar("npc:iria")
	ok(dc._saber_de("npc:iria").is_empty() and not dc.datos().actores.has("npc:iria"),"la réplica no siembra ni concede saberes: solo la autoridad escribe")
	cli.free();srv.free()
	ok(Srv.VERSION>=7,"el protocolo declara las nuevas intenciones y la huella en el saludo")
	# Huella de reglas en el saludo: cliente y servidor deben usar las mismas reglas.
	var hs=Srv.new();hs.j=j
	var apariencia:=[0,0,0]
	ok(Srv._verificar_hola(["hola",Srv.VERSION,"Dan","clave-d",apariencia,Srv.Huella.huella()]).is_empty(),"con versión y huella correctas el saludo pasa a la identificación")
	hs.registrar_peer(7)
	ok(not hs.recibir(7,["hola",Srv.VERSION,"Dan","clave-d",apariencia,"0000"]) and hs.peers[7].fuera and not j.d.jugadores.has(Srv.id_de("Dan")),"un saludo con huella de reglas distinta se rechaza, corta la conexión y no crea jugador")
	hs.registrar_peer(8)
	ok(not hs.recibir(8,["hola",Srv.VERSION,"Dan","clave-d",apariencia]) and hs.peers[8].fuera,"un saludo sin huella se rechaza")
	ok(Srv._verificar_hola(["hola",Srv.VERSION-1,"Dan","clave-d",apariencia,Srv.Huella.huella()]).motivo=="Versión distinta del servidor","una versión de protocolo distinta se rechaza antes que la huella")
	hs.free()

	# --- Migración y siembra por experiencia previa ---
	var viejo=nuevo()
	var vd=viejo.autonomia.desarrollo
	var vyo: String=viejo.actor_desarrollo()
	var s=vd.datos()
	s.version=1
	for k in ["historia","lecciones","pausas"]: s.erase(k)
	var e=vd.estado(vyo)
	e.erase("sembrado");e.saber.clear()
	e.practica={"artesania":6,"artesania:madera":3}
	e.materiales={"madera":true}
	vd.restaurar()
	ok(vd.datos().version==2 and vd.datos().historia.is_empty(),"una partida del subesquema anterior se amplía sin autores inventados")
	ok(vd.tiene_saber(vyo,"tec:ligera") and not vd.tiene_saber(vyo,"tec:reforzada"),"quien ya podía usar una técnica la conserva; no recibe las que no usaba")
	var antes_siembra: String=canon(vd.datos())
	vd.restaurar()
	ok(canon(vd.datos())==antes_siembra,"sembrar de nuevo no cambia nada")

	# --- A4: la pericia y el saber son independientes ---
	var p=nuevo()
	var pd=p.autonomia.desarrollo
	var pyo: String=p.actor_desarrollo()
	despierto(p,"maren");despierto(p,"ordal")
	ok(not pd.tiene_saber("npc:ordal","tec:ligera"),"punto de partida de A4: Ordal no conoce la técnica ligera")
	pd.estado("npc:maren").practica["artesania"]=30      # maestro con mucha pericia
	pd.estado("npc:maren").practica["artesania:madera"]=30
	p.d.npcs.ordal.pos=p.d.npcs.maren.pos.duplicate()
	var practica_ordal: String=canon(pd.estado("npc:ordal").practica)
	var practica_maren: String=canon(pd.estado("npc:maren").practica)
	var inv_ordal: String=canon(p.autonomia.estado("ordal").inv)
	pd.datos().lecciones["npc:maren"]={"alumno":"npc:ordal","saber":"tec:ligera","avance":19,"ultimo":int(p.d.min)-10}
	ok(pd._ensenar("maren") and pd.tiene_saber("npc:ordal","tec:ligera"),"completar la lección da el saber al alumno NPC")
	ok(canon(pd.estado("npc:ordal").practica)==practica_ordal and pd.rango("npc:ordal","artesania")<pd.rango("npc:maren","artesania"),"el alumno no hereda la práctica del maestro")
	ok(canon(pd.estado("npc:maren").practica)==practica_maren and pd.tiene_saber("npc:maren","tec:ligera"),"enseñar no cambia la práctica ni el saber del maestro")
	ok(canon(p.autonomia.estado("ordal").inv)==inv_ordal,"la lección no entrega ninguna pieza ni material")
	pd.estado(pyo).practica["artesania"]=60
	pd.estado(pyo).practica["artesania:madera"]=60
	pd.estado(pyo).materiales["madera"]=true
	ok(pd.rango(pyo,"artesania","madera")>=int(pd.cfg.tecnicas.reforzada.rango) and not pd.sabe(pyo,A.clave("espada","madera","reforzada",1)),"mucha práctica no concede un saber que nadie ha enseñado")

	# --- Compatibilidad de guardados: el contenedor no cambió y H0 rechaza lo incompatible ---
	var Hu=Srv.Huella
	var c=nuevo()
	var cyo: String=c.actor_desarrollo()
	c.autonomia.desarrollo.estado(cyo).practica={"artesania":6,"artesania:madera":3}
	c.autonomia.desarrollo.estado(cyo).materiales={"madera":true}
	ok(c.guardar(RUTA_COMPAT),"se guarda un mundo con saberes")
	var texto: String=FileAccess.get_file_as_string(RUTA_COMPAT)
	var envoltura=JSON.parse_string(texto)
	var cuerpo=JSON.parse_string(envoltura.cuerpo)
	ok(G.FORMATO==3 and int(envoltura.formato)==3 and ordenado(envoltura.keys())==["checksum","cuerpo","formato"],"el contenedor conserva el formato 3 y su envoltura")
	ok(int(cuerpo.mundo_vivo.autonomia.desarrollo.version)==2 and not cuerpo.has("saberes") and not cuerpo.has("historia"),"K1 solo añade datos dentro de mundo_vivo.autonomia.desarrollo")
	ok(G.inspeccionar(texto).estado=="ok","un mundo guardado con K1 y las reglas actuales se acepta sin excepción")
	ok(Hu.COMPONENTES["desarrollo"].any(func(ruta): return ruta.ends_with("saberes_v1.json")),"la huella de reglas incluye saberes_v1.json")
	# Un mundo sellado antes de K1: mismo contenedor, componente «desarrollo» sin saberes_v1.json y subesquema 1.
	var previo=cuerpo.duplicate(true)
	var dv=previo.mundo_vivo.autonomia.desarrollo
	dv.version=1
	for k in ["historia","lecciones","pausas"]: dv.erase(k)
	for actor in dv.actores:
		dv.actores[actor].erase("saber")
		dv.actores[actor].erase("sembrado")
	var contenido={}
	for ruta in Hu.COMPONENTES["desarrollo"]: contenido[ruta]="ausente" if ruta.ends_with("saberes_v1.json") else Hu._archivo(ruta)
	previo.reglas.componentes["desarrollo"]=Hu.hash_de(contenido)
	previo.reglas.huella=Hu.total(previo.reglas.componentes)
	var f=FileAccess.open(RUTA_PREVIO,FileAccess.WRITE)
	f.store_string(G.empaquetar(previo));f.close()
	var inspeccion=G.inspeccionar(FileAccess.get_file_as_string(RUTA_PREVIO))
	ok(inspeccion.estado=="reglas_distintas" and "desarrollo" in inspeccion.detalle.distintos,"H0 rechaza un mundo sellado antes de K1 y señala el componente «desarrollo»")
	var sha_previo: String=FileAccess.get_sha256(RUTA_PREVIO)
	ok(J.cargar(RUTA_PREVIO)==null and G.cargar(RUTA_PREVIO).get("error","")=="reglas_distintas" and FileAccess.get_sha256(RUTA_PREVIO)==sha_previo,"cargarlo falla con el motivo «reglas_distintas» y deja el archivo intacto")
	Hu.excepcion_de_prueba=true
	var carga_previa=J.cargar(RUTA_PREVIO)
	Hu.excepcion_de_prueba=false
	var dp=carga_previa.autonomia.desarrollo if carga_previa!=null else null
	ok(carga_previa!=null and carga_previa.d.reglas.contaminado,"con la excepción explícita se carga y el mundo queda marcado como contaminado")
	ok(dp!=null and int(dp.datos().version)==2 and dp.datos().historia.is_empty(),"el subesquema 1 se amplía a la versión 2 sin inventar historia")
	ok(dp!=null and dp.tiene_saber(cyo,"tec:ligera") and not dp.tiene_saber(cyo,"tec:reforzada"),"al cargar, quien ya practicaba conserva lo que usaba y nada más")

	# --- Primera prueba vertical: Maren enseña, Ordal aprende, fabrica y todo persiste ---
	var v=nuevo()
	var vd2=v.autonomia.desarrollo
	var M1:="npc:maren"
	var O1:="npc:ordal"
	ok(vd2.tiene_saber(M1,"tec:ligera") and not vd2.tiene_saber(O1,"tec:ligera") and not vd2.sabe(O1,A.clave("torso","fibra","ligera",0)),"antes: Maren conoce la técnica ligera y Ordal no")
	var conf_mo: int=v.autonomia.sociedad.confianza("maren","ordal")
	var conf_om: int=v.autonomia.sociedad.confianza("ordal","maren")
	var usados:=hasta_saber(v,O1,"tec:ligera",2880)
	print("VERTICAL: Ordal aprende tras %d minutos"%usados)
	ok(vd2.tiene_saber(O1,"tec:ligera"),"sin intervención del jugador, Maren enseña a Ordal")
	ok(vd2.tiene_saber(M1,"tec:ligera") and not vd2.tiene_saber(yo,"tec:ligera"),"el maestro conserva el saber y el conocimiento no llega a quien no estuvo")
	var hv: Dictionary=vd2.datos().historia.get("tec:ligera",{})
	ok(hv.get("total",0)==1 and hv.aprendices[0].actor==O1 and hv.aprendices[0].de==M1 and hv.primero.is_empty(),"la historia registra al alumno y al maestro sin atribuir invención")
	ok(v.autonomia.estado("ordal").recuerdos.any(func(r): return r.hecho=="aprendio" and r.detalle.contains("ligera")),"Ordal recuerda haber aprendido")
	ok(v.autonomia.sociedad.confianza("maren","ordal")>conf_mo and v.autonomia.sociedad.confianza("ordal","maren")>conf_om,"enseñar y aprender fortalece la relación")
	ok(int(v.autonomia.sociedad.datos().estadisticas.get("ensenanza",0))>=1,"la enseñanza queda en el diario de sucesos")
	ok(not (vd2.datos().lecciones.has(M1) and vd2.datos().lecciones[M1].saber=="tec:ligera"),"la lección completada no queda abierta")
	# Uso posterior: con rango, material y taller, Ordal ya puede fabricar con la técnica aprendida.
	var oe=vd2.estado(O1)
	oe.materiales["madera"]=true
	oe.practica["artesania"]=6
	oe.practica["artesania:madera"]=3
	var pieza:=A.clave("espada","madera","ligera",1)
	ok(vd2.sabe(O1,pieza),"Ordal sabe fabricar la pieza con la técnica aprendida")
	var d_otro=nuevo().autonomia.desarrollo
	var oe2=d_otro.estado(O1)
	oe2.materiales["madera"]=true
	oe2.practica["artesania"]=6
	oe2.practica["artesania:madera"]=3
	d_otro.sembrar(O1)
	ok(not d_otro.sabe(O1,pieza),"sin la lección, el mismo Ordal con la misma práctica no puede")
	# Persistencia: guardar, cargar y seguir simulando no duplica nada.
	var estado_antes: String=canon(vd2.datos())
	ok(v.guardar(RUTA),"se guarda el conocimiento adquirido")
	var carga=J.cargar(RUTA)
	ok(carga!=null and canon(carga.autonomia.desarrollo.datos())==estado_antes,"cargar restituye exactamente el estado de conocimiento")
	var cd=carga.autonomia.desarrollo
	ok(cd.tiene_saber(O1,"tec:ligera") and cd.tiene_saber(M1,"tec:ligera"),"el aprendizaje sobrevive a guardar y cargar")
	cd.restaurar()
	ok(canon(cd.datos())==estado_antes,"restaurar tras cargar no duplica ni cambia el conocimiento")
	carga.autonomia.estado("maren").recuerdos.clear()
	sim(carga,120)
	ok(cd.datos().historia["tec:ligera"].total==1 and cd.datos().historia["tec:ligera"].aprendices.size()==1,"seguir simulando tras cargar no repite el aprendizaje")
	# Repetibilidad: misma semilla, mismo desenlace.
	var r=nuevo()
	var rd=r.autonomia.desarrollo
	var usados_r:=hasta_saber(r,O1,"tec:ligera",2880)
	ok(usados_r==usados and canon(rd.datos().historia)==canon(vd2.datos().historia),"con la misma semilla el conocimiento se transmite igual")

	print("SABERES: %d comprobaciones, %d fallos"%[total,fallos])
	quit(1 if fallos else 0)
