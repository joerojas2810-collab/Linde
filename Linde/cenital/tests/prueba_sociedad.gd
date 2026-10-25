extends SceneTree
## Contratos y consecuencias sistémicas: sin tarjetas ni cadenas de misiones.
const J = preload("res://scripts/juego.gd")
const Cli = preload("res://scripts/red_cliente.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Mundo = preload("res://scripts/mundo.gd")
var fallos := 0
var total := 0
func ok(c: bool, texto: String) -> void:
	total += 1
	print(("PASS " if c else "FAIL ") + texto)
	if not c: fallos += 1
func nuevo():
	var j = J.nueva(123, "Observador", [0, 0, 0])
	j.combate.enemigos.clear()
	j.autonomia.desarrollo.cfg.activa = false
	j.autonomia.activar()
	return j
func sim(j, minutos: int) -> void:
	for i in minutos * 10: j.tick(0.1)
func colocar(j, nid: String, c: Vector2i) -> void:
	var p := Mundo.pies_de_celda(c)
	j.d.npcs[nid].pos = [p.x, p.y]
func _init() -> void:
	var j = nuevo()
	var s = j.autonomia.sociedad
	ok(s.activa(), "las cinco capacidades están habilitadas en el modo de prueba")
	var m: Dictionary = j.autonomia.estado("maren")
	var o: Dictionary = j.autonomia.estado("ordal")
	ok(m.inv.is_empty() and o.inv.is_empty(), "no se regalan herramientas ni materiales iniciales")
	# Producción/consumo: herramientas reales, desgaste y reparación con un producto real.
	o.inv = {"pico_piedra":1, "lingote":1}
	s.usar_herramienta("ordal", "picar")
	ok(int(o.durabilidad.pico_piedra) == int(s.cfg.durabilidad_herramienta)-1, "usar una herramienta reduce su durabilidad")
	o.durabilidad.pico_piedra = 1
	ok(s.reparar_herramienta("ordal", "pico_piedra"), "reparación usa una herramienta existente y un lingote real")
	ok(not o.inv.has("lingote") and o.durabilidad.pico_piedra == int(s.cfg.durabilidad_herramienta), "reparar consume el lingote exactamente una vez")
	for i in int(s.cfg.durabilidad_herramienta): s.usar_herramienta("ordal", "picar")
	ok(not o.inv.has("pico_piedra"), "herramienta agotada sale del inventario y genera nueva demanda")
	# Trueque con depósito en garantía, navegación, entrega y confianza.
	m.inv = {"pico_piedra":2}
	o.inv = {"fibra":10}
	var original_fibra: int = o.inv.fibra
	var acuerdo: String = s.acordar("ordal", "maren", "pico_piedra", 1)
	ok(acuerdo != "", "NPC pueden negociar excedentes sin intervención del jugador")
	ok(m.inv.pico_piedra == 1 and o.inv.fibra < original_fibra, "ambos lados reservan recursos reales al acordar")
	ok(not s.entregar(acuerdo), "el acuerdo no teletransporta materiales a distancia")
	colocar(j, "ordal", Vector2i(28,21)); colocar(j, "maren", Vector2i(28,20))
	ok(s.entregar(acuerdo), "la entrega exige encuentro físico")
	ok(o.inv.pico_piedra == 1 and m.inv.get("fibra",0) > 0, "al encontrarse reciben exactamente el trueque acordado")
	ok(not s.entregar(acuerdo), "una segunda entrega no duplica materiales")
	ok(s.confianza("maren", "ordal") > 0 and s.confianza("ordal", "maren") > 0, "cumplir genera confianza recíproca observada")
	# Incumplimiento y devolución: nunca desaparecen objetos por vencimiento o reinicio.
	m.inv.pico_piedra = 2
	o.inv.fibra = 12
	var antes_m: Dictionary = m.inv.duplicate(true)
	var antes_o: Dictionary = o.inv.duplicate(true)
	var vencido: String = s.acordar("ordal", "maren", "pico_piedra", 1)
	ok(vencido != "", "se puede concertar otro acuerdo después del anterior")
	j.d.min += int(s.cfg.plazo_acuerdo_min)+1
	s.actualizar()
	ok(m.inv == antes_m and o.inv == antes_o, "al vencer, ambas garantías vuelven a sus propietarios")
	ok(s.confianza("maren", "ordal") < 1, "incumplir cambia la confianza y futuras decisiones")
	var tras_vencer_m: Dictionary = m.inv.duplicate(true)
	var tras_vencer_o: Dictionary = o.inv.duplicate(true)
	s.actualizar()
	ok(m.inv == tras_vencer_m and o.inv == tras_vencer_o, "procesar dos veces el vencimiento no duplica las devoluciones")
	m.vinculos["npc:ordal"] = {"confianza": -3}
	ok(s.acordar("ordal", "maren", "pico_piedra", 1) == "", "la desconfianza bloquea acuerdos futuros aunque existan materiales")
	m.vinculos["npc:ordal"] = {"confianza": 0}
	s.grupo("talleres").reputacion["grupo:canteros"] = -3
	ok(s.acordar("ordal", "maren", "pico_piedra", 1) == "", "un conflicto entre grupos restringe el comercio entre sus miembros")
	s.grupo("talleres").reputacion["grupo:canteros"] = 0
	# Compartir reservas exige ir al depósito; externos no pueden apropiarse.
	var grupo: Dictionary = s.grupo("talleres")
	grupo.inv = {"madera":4}
	colocar(j,"maren",Vector2i(28,21))
	ok(s.retirar_deposito("maren", "madera", 2) and m.inv.get("madera",0)==2 and grupo.inv.madera==2, "un miembro retira existencias de su depósito estando allí")
	colocar(j,"ordal",Vector2i(28,21))
	ok(not s.retirar_deposito("ordal","madera",1), "la pertenencia protege las reservas colectivas")
	var rep := 0
	# Intereses territoriales y reputación afectan acceso; solo hechos vistos generan sanción.
	var veta := ""
	for oid in j.mundo.objetos:
		if j.mundo.objetos[oid].t == "veta" and Mundo.CANTERA.has_point(j.mundo.objetos[oid].c): veta=oid; break
	ok(veta != "", "el conflicto usa un recurso real del valle")
	if veta != "":
		var c: Vector2i = j.mundo.objetos[veta].c
		colocar(j,"ordal",c+Vector2i.DOWN)
		s.grupo("canteros").inv.clear()
		ok(not s.permite_recurso("maren",veta), "el grupo reserva recursos escasos de su territorio")
		rep = s.reputacion("canteros",J.LOCAL)
		j.jug().inv = {"pico_piedra":1}
		for i in 6: j.golpear_objeto(c)
		ok(j.d.mundo.rotos.has(veta), "la extracción del jugador usa la acción real sobre el mapa")
		ok(s.reputacion("canteros",J.LOCAL)<rep, "una extracción vista afecta reputación con el grupo")
		colocar(j,"ordal",Vector2i(28,21))
		rep=s.reputacion("canteros",J.LOCAL)
		s.observar_extraccion(J.LOCAL,veta)
		ok(s.reputacion("canteros",J.LOCAL)==rep, "un habitante distante no conoce mágicamente la extracción")
	j.pies=Mundo.pies_de_celda(Vector2i(10,10))
	j.jug().inv={"mena":2}
	ok(s.aportar_grupo("canteros",J.LOCAL).ok and j.jug().inv.is_empty(), "el jugador puede aportar recursos reales al grupo")
	ok(s.reputacion("canteros",J.LOCAL)>rep, "contribuir mejora reputación y cambia relaciones")
	var srv = Srv.new()
	srv.j = j
	ok(not srv.ejecutar(J.LOCAL, ["aportar_grupo", 1, 123]), "el servidor rechaza aportes con tipo inválido")
	var antes_aporte: Dictionary = j.jug().inv.duplicate(true)
	ok(srv.ejecutar(J.LOCAL, ["aportar_grupo", 2, "inexistente"]) and j.jug().inv == antes_aporte, "un grupo inexistente no consume recursos")
	srv.free()
	# La escasez no congela toda la IA: pospone un objetivo imposible y prueba otro.
	var alterno = nuevo()
	alterno.autonomia.reglas.expediciones = false   # sin arbustos en el valle ni fuera
	for oid in alterno.mundo.objetos:
		if alterno.mundo.objetos[oid].t=="arbusto": alterno.mundo.romper(oid,alterno.d.min)
	sim(alterno,6)
	var am: Dictionary=alterno.autonomia.estado("maren")
	ok(am.bloqueos.has("baya"), "la IA registra por qué pospuso una necesidad sin solución")
	ok(am.plan.get("act","")!="pedir" or am.plan.get("motivo","")!="alimentarme", "sin comida disponible prueba una meta alternativa mientras no hay urgencia")
	var ayuda = nuevo()
	sim(ayuda, 1)
	ayuda.pies = ayuda.habitantes.pos("maren")
	ayuda.jug().inv = {"baya":10}
	ok(ayuda.ayudar_habitante("maren").ok and ayuda.jug().inv.baya == 8, "la petición calcula la carencia desde las reservas actuales")
	ok(not ayuda.ayudar_habitante("maren").ok and ayuda.jug().inv.baya == 8, "repetir la ayuda antes de la siguiente decisión no consume recursos extra")
	# Persistencia con un acuerdo en tránsito y grupos: mismos objetos antes y después.
	var persistente=nuevo()
	var ps=persistente.autonomia.sociedad
	persistente.autonomia.estado("maren").inv={"pico_piedra":2}
	persistente.autonomia.estado("ordal").inv={"fibra":12}
	var pid: String=ps.acordar("ordal","maren","pico_piedra",1)
	ok(pid!="" and persistente.guardar("/tmp/linde-sociedad-prueba-%d.json" % OS.get_process_id()), "guarda un acuerdo con materiales en tránsito")
	var cargado=J.cargar("/tmp/linde-sociedad-prueba-%d.json" % OS.get_process_id())
	ok(cargado!=null and JSON.stringify(cargado.d.mundo_vivo.autonomia)==JSON.stringify(J._enteros(JSON.parse_string(JSON.stringify(persistente.d.mundo_vivo.autonomia)))), "carga mantiene grupos, herramientas, acuerdos, garantías y memorias")
	if cargado != null:
		colocar(cargado,"ordal",Vector2i(28,21)); colocar(cargado,"maren",Vector2i(28,20))
		ok(cargado.autonomia.sociedad.entregar(pid) and not cargado.autonomia.sociedad.entregar(pid), "un acuerdo restaurado se entrega una sola vez")
	var srv2 = Srv.new()
	srv2.j = persistente
	var cli = Cli.new()
	cli._bienvenida(srv2.estado_para(J.LOCAL))
	ok(JSON.stringify(cli.j.autonomia.sociedad.datos()) == JSON.stringify(persistente.autonomia.sociedad.datos()), "la réplica recibe compromisos, garantías y relaciones de grupo")
	var antes_tick: String = JSON.stringify(cli.j.d.mundo_vivo.autonomia)
	cli.j.tick(1000.0)
	ok(JSON.stringify(cli.j.d.mundo_vivo.autonomia) == antes_tick, "un cliente no ejecuta decisiones ni caduca acuerdos por su cuenta")
	cli.free(); srv2.free()
	var antiguo = nuevo()
	antiguo.autonomia.estado("maren").inv = {"fibra":7}
	antiguo.d.mundo_vivo.autonomia.erase("sociedad")
	antiguo.d.mundo_vivo.autonomia.erase("modo")
	ok(antiguo.guardar("/tmp/linde-sociedad-antiguo-%d.json" % OS.get_process_id()), "guarda una partida con el estado de autonomía anterior")
	var migrado = J.cargar("/tmp/linde-sociedad-antiguo-%d.json" % OS.get_process_id())
	ok(migrado != null and migrado.autonomia.sociedad.activa() and migrado.autonomia.estado("maren").inv == {"fibra":7}, "la migración añade grupos conservando los recursos de la primera prueba")
	var construir = nuevo()
	construir.autonomia.estado("ordal").inv = {"piedra":8}
	colocar(construir,"ordal",Mundo.ENTRADA+Vector2i.UP)
	ok(not construir.autonomia.sociedad.construir_estacion("ordal","horno",Mundo.ENTRADA) and construir.autonomia.estado("ordal").inv.piedra==8, "la construcción autónoma protege entradas y no consume al fallar")
	# Integración: autonomía desde cero, sin estaciones ni herramientas regaladas.
	var libre=nuevo()
	sim(libre,4320)
	var sucesos: Array=libre.autonomia.sociedad.datos().sucesos
	var tipos: Dictionary=libre.autonomia.sociedad.datos().estadisticas
	print("SUCESOS_DIA: ",JSON.stringify(tipos))
	ok(libre.d.mundo.rotos.size()>0, "tres días sin jugador modifica recursos reales")
	ok(tipos.has("fabricacion"), "sin jugador llegan a fabricar a partir de recursos del mapa")
	ok(tipos.has("acuerdo") and tipos.has("entrega"), "sin jugador negocian y completan una entrega física")
	ok(tipos.has("construccion"), "sin jugador construyen una estación consumiendo materiales")
	# La reparación depende de la secuencia (carácter, estafas, población): su mecanismo se comprueba arriba, no su aparición en la simulación libre.
	ok(tipos.has("desgaste"), "el uso desgasta las herramientas y renueva la demanda de productos fabricados")
	ok(libre.d.mundo_vivo.ultimo.is_empty() and libre.d.mundo_vivo.instancias.is_empty(), "las cinco capacidades funcionan con las tarjetas desactivadas")
	var f=FileAccess.open("/tmp/linde-sociedad-dia-%d.json" % OS.get_process_id(),FileAccess.WRITE)
	f.store_string(JSON.stringify(libre.d.mundo_vivo.autonomia,"  "));f.close()
	print("SOCIEDAD: %d comprobaciones, %d fallos"%[total,fallos])
	quit(1 if fallos else 0)
