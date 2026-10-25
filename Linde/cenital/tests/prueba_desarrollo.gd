extends SceneTree
const J = preload("res://scripts/juego.gd")
const A = preload("res://scripts/artesania.gd")
const Eq = preload("res://scripts/equipo.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
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
func _init() -> void:
	ok(A.validar().is_empty(),"la gramática solo utiliza materiales y costes existentes")
	var espada:=A.clave("espada","madera","simple",0)
	var armadura:=A.clave("torso","fibra","simple",0)
	ok(not A.leer(espada).is_empty() and not A.leer(armadura).is_empty(),"espada y armadura salen de combinar reglas, sin catálogo individual")
	ok(A.leer("art1:espada:fibra:simple:0").is_empty(),"no se fabrica una espada de tejido incompatible")
	for mala in ["art1:espada:madera:simple:99","art1:espada:madera:simple:01","art1:espada:madera:simple:-1","art2:espada:madera:simple:0"]:
		ok(A.leer(mala).is_empty(),"rechaza clave inválida "+mala)
	ok(Eq.existe(espada) and Eq.info(espada).equipo=="arma", "el inventario reconoce el equipo generado")
	ok(Eq.visible({"arma":espada})[0].ranura=="espada", "la pieza tiene representación con el arte existente")
	var j=nuevo()
	var d=j.autonomia.desarrollo
	var actor: String=j.actor_desarrollo()
	ok(d.planos(actor).is_empty(),"no se conocen planos de materiales nunca obtenidos")
	j.jug().inv={"madera":12,"fibra":10}
	ok(not j.fabricar_artefacto(espada).ok and j.jug().inv.madera==12,"un pedido no concede conocimiento ni consume si no se conoce el plano")
	# Acción real de recolección, no llamadas de entrenamiento desde la UI.
	var oid: String=""
	for id in j.mundo.objetos:
		if j.mundo.objetos[id].t=="arbol":oid=id;break
	var c: Vector2i=j.mundo.objetos[oid].c
	for i in 6:j.golpear_objeto(c)
	ok(d.estado(actor).materiales.has("madera") and d.planos(actor,"espada").has(espada),"recolectar un material descubre sus combinaciones iniciales")
	ok(d.estado(actor).practica.recoleccion==1,"los golpes intermedios no dan múltiples prácticas por un mismo recurso")
	j.pies=M.pies_de_celda(Vector2i(28,21))
	var stock: Dictionary=j.jug().inv.duplicate(true)
	ok(not j.fabricar_artefacto(espada).ok and j.jug().inv==stock,"fabricar exige una mesa y no pierde materiales al fallar")
	j.jug().inv.piedra=2
	j.jug().inv.madera=20
	ok(j.construir("mesa",Vector2i(29,20)).ok,"la estación de prueba se construye pagando materiales reales")
	ok(j.fabricar_artefacto(espada).ok,"se fabrica una variante conocida junto a la mesa")
	ok(j.jug().inv.has(espada) and j.jug().inv.madera==12,"la pieza consume exactamente la receta generada")
	ok(d.estado(actor).practica.artesania==1,"la fabricación exitosa aporta práctica")
	ok(j.equipar(espada).ok and j.stats().dmg>5,"una espada generada equipada cambia el combate real")
	var dano: int=j.stats().dmg
	j.desequipar("arma")
	ok(j.stats().dmg<dano,"tener la espada en la mochila no concede su daño")
	var antes_stats: Dictionary=Eq.info(espada).duplicate(true)
	j.jug().inv.madera=40
	j.fabricar_artefacto(espada);j.fabricar_artefacto(espada)
	ok(d.rango(actor,"artesania","madera")==1,"la práctica material desbloquea un rango especializado")
	var ligera:=A.clave("espada","madera","ligera",1)
	# Cambio esperado (saberes): el rango ya no desbloquea técnicas por sí solo; hay que aprenderlas.
	ok(not d.sabe(actor,ligera) and not d.conoce(actor,ligera),"el rango no concede una técnica que nadie ha enseñado")
	d.aprender(actor,"tec:ligera","prueba")
	ok(d.sabe(actor,ligera) and not d.conoce(actor,ligera),"una técnica avanzada también necesita espacio de taller")
	for suelo in [Vector2i(27,20),Vector2i(27,21)]:j.construir("suelo",suelo)
	ok(d.conoce(actor,ligera),"ampliar un taller habilita una técnica aprendida")
	ok(j.fabricar_artefacto(ligera).ok,"la variante avanzada tiene un coste y una fabricación reales")
	ok(Eq.info(espada)==antes_stats,"aprender no cambia retroactivamente las propiedades de una pieza")
	var maestra:=A.clave("espada","madera","reforzada",3)
	stock=j.jug().inv.duplicate(true)
	ok(not j.fabricar_artefacto(maestra).ok and j.jug().inv==stock,"no se puede pedir una calidad o técnica aún no aprendida")
	# Armadura: conocimiento, fabricación, equipo y estadísticas.
	d.observar(actor,{"fibra":1})
	j.jug().inv.fibra=20
	var defensa: int=j.stats().def
	ok(j.fabricar_artefacto(armadura).ok and j.equipar(armadura).ok and j.stats().def>defensa,"la armadura generada funciona en la ranura y la defensa")
	var guardada: Dictionary=j.jug().inv.duplicate(true)
	var posicion: Vector2=j.pies
	j.pies=M.pies_de_celda(Vector2i(28,21))
	j.jug().inv={"madera":50,"espada_hierro":19}
	var practica_antes: Dictionary=d.estado(actor).practica.duplicate(true)
	ok(not j.fabricar_artefacto(espada).ok and j.jug().inv=={"madera":50,"espada_hierro":19} and d.estado(actor).practica==practica_antes,"mochila llena rechaza la pieza sin consumir ni entrenar")
	j.jug().inv=guardada;j.pies=posicion
	ok(d.suelo_requerido(actor,"reforzada")<int(d.cfg.tecnicas.reforzada.suelo),"la práctica de construcción permite organizar un taller más eficiente")
	# Los materiales elaborados también nacen de reglas y se consumen como objetos reales.
	ok(Eq.existe("mat1:hierro_fibra") and not Eq.info("mat1:hierro_fibra").has("equipo"),"un laminado es material de inventario y no equipo gratuito")
	ok(A.leer_material("mat1:hierro_hierro")=="" and A.leer_material("mat1:hierro_fibra_piedra")=="","no se permiten mezclas inválidas ni cadenas de mezclas ilimitadas")
	var mezcla=nuevo()
	var md=mezcla.autonomia.desarrollo
	mezcla.jug().inv={"lingote":12,"fibra":10,"madera":10,"piedra":10}
	md.observar(mezcla.actor_desarrollo(),mezcla.jug().inv)
	ok(not mezcla.refinar_material("hierro_fibra").ok and mezcla.jug().inv.lingote==12,"tener componentes no sustituye la práctica necesaria para transformarlos")
	mezcla.pies=M.pies_de_celda(Vector2i(28,21))
	mezcla.construir("mesa",Vector2i(29,20));mezcla.construir("horno",Vector2i(29,21))
	for i in 3:mezcla.fabricar_artefacto(A.clave("espada","hierro","simple",0))
	var antes_laminar: Dictionary=mezcla.jug().inv.duplicate(true)
	ok(not mezcla.refinar_material("hierro_fibra").ok and mezcla.jug().inv==antes_laminar,"con práctica y componentes tampoco se elabora un laminado cuyo proceso no se conoce")
	md.aprender(mezcla.actor_desarrollo(),"lam:hierro_fibra","prueba")
	for i in 3:ok(mezcla.refinar_material("hierro_fibra").ok,"se transforma hierro y fibra en un laminado pagando componentes")
	ok(mezcla.jug().inv.get("mat1:hierro_fibra",0)==3 and not mezcla.jug().inv.has("lingote"),"la mezcla conserva las cantidades y consume el metal")
	var compuesta:=A.clave("torso","hierro_fibra","simple",0)
	ok(mezcla.fabricar_artefacto(compuesta).ok and mezcla.jug().inv.get("mat1:hierro_fibra",0)==1,"el material elaborado abre planos nuevos y se consume al fabricar")
	ok(mezcla.equipar(compuesta).ok and mezcla.stats().def>0,"el equipo de material elaborado tiene propiedades jugables")
	ok(mezcla.guardar("/tmp/linde-materiales-prueba-%d.json" % OS.get_process_id()),"se guardan materiales y piezas elaboradas")
	var mezcla_carga=J.cargar("/tmp/linde-materiales-prueba-%d.json" % OS.get_process_id())
	ok(mezcla_carga!=null and mezcla_carga.jug().inv.get("mat1:hierro_fibra",0)==1 and mezcla_carga.jug().equipo.torso==compuesta,"cargar conserva el material elaborado y la pieza sin perderlos")
	# Compra de una obra real, con proximidad, precio y existencias.
	j.autonomia.estado("maren").inv[espada]=1
	j.jug().inv.madera=10
	j.pies=M.pies_de_celda(M.ENTRADA)
	ok(not j.comprar_artefacto("maren",espada).ok,"no se compran obras a distancia")
	j.pies=j.habitantes.pos("maren")
	ok(j.comprar_artefacto("maren",espada).ok and j.jug().inv.madera==7,"el trueque paga con materiales y entrega una obra existente")
	ok(not j.comprar_artefacto("maren",espada).ok and j.jug().inv.madera==7,"repetir la compra de una pieza agotada no consume más")
	# Persistencia y réplica de conocimientos y piezas.
	ok(j.guardar("/tmp/linde-desarrollo-prueba-%d.json" % OS.get_process_id()),"se guarda equipo y conocimiento generado")
	var carga=J.cargar("/tmp/linde-desarrollo-prueba-%d.json" % OS.get_process_id())
	ok(carga!=null and carga.jug().equipo.torso==armadura and carga.autonomia.desarrollo.rango(actor,"artesania","madera")==d.rango(actor,"artesania","madera"),"cargar conserva las piezas y los rangos sin acumular bonus")
	ok(carga.stats()==j.stats(),"cargar no vuelve a sumar efectos de equipo o práctica")
	var srv=Srv.new();srv.j=j
	ok(not srv.ejecutar(J.LOCAL,["fabricar_artefacto",1,123]),"la red rechaza un tipo de plano inválido")
	stock=j.jug().inv.duplicate(true)
	ok(srv.ejecutar(J.LOCAL,["fabricar_artefacto",2,maestra]) and j.jug().inv==stock,"el servidor rechaza una calidad no aprendida sin confiar en el cliente")
	var cli=Cli.new()
	cli._bienvenida(srv.estado_para(J.LOCAL))
	ok(cli.j.actor_desarrollo()==actor and cli.j.autonomia.desarrollo.rango(cli.j.actor_desarrollo(),"artesania","madera")==d.rango(actor,"artesania","madera"),"la réplica consulta la identidad correcta de conocimientos del jugador")
	cli.free();srv.free()
	var materiales: Array=d.materiales()
	ok(materiales.size()==14,"el atlas explica los catorce recursos y consumibles actuales")
	var hierro: Dictionary={}
	for mat in materiales:
		if mat.id=="lingote":hierro=mat
	ok(hierro.fuente.contains("horno") and not hierro.usos.is_empty(),"el atlas conecta origen, refinado y usos del hierro")
	# Prueba integrada: sin equipamiento, experiencia ni suelo iniciales regalados.
	var libre=nuevo()
	# Se mide el desgaste máximo de la mesa DURANTE la simulación: una reparación posterior lo devuelve a 0 y el estado final no lo ve.
	var mesa_max := 0
	for hora in 72:
		sim(libre,60)
		for k in libre.autonomia.sociedad.datos().estaciones:
			if libre.d.mundo.constr.has(k) and libre.d.mundo.constr[k].t=="mesa": mesa_max=maxi(mesa_max,int(libre.autonomia.sociedad.datos().estaciones[k]))
	var ld=libre.autonomia.desarrollo
	var construidos:=0
	for pieza in libre.d.mundo.constr.values():
		if pieza.t=="suelo" and str(pieza.get("dueno","")).begins_with("grupo:"):construidos+=1
	print("DESARROLLO_LIBRE: ",JSON.stringify({"creaciones":ld.datos().creaciones.size(),"suelos":construidos,"sociedad":libre.autonomia.sociedad.datos().estadisticas}))
	ok(construidos>0,"los habitantes amplían sus talleres según práctica y necesidades")
	ok(not ld.datos().creaciones.is_empty(),"sin intervención llegan a crear piezas mediante la gramática")
	ok(mesa_max>0,"los prototipos también desgastan la mesa utilizada")
	var f=FileAccess.open("/tmp/linde-desarrollo-tres-dias-%d.json" % OS.get_process_id(),FileAccess.WRITE)
	f.store_string(JSON.stringify(libre.d.mundo_vivo.autonomia,"  "));f.close()
	ok(libre.d.mundo_vivo.ultimo.is_empty() and libre.d.mundo_vivo.instancias.is_empty(),"los descubrimientos no dependen de tarjetas o misiones preparadas")
	print("DESARROLLO: %d comprobaciones, %d fallos"%[total,fallos])
	quit(1 if fallos else 0)
