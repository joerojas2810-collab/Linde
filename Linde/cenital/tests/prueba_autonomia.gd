extends SceneTree
## Integración reproducible: sin tarjetas ni misiones escritas; archivos solo en /tmp.
const J = preload("res://scripts/juego.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var fallos := 0
var comprobaciones := 0
func ok(valor: bool, texto: String) -> void:
	comprobaciones += 1
	print(("PASS " if valor else "FAIL ") + texto)
	if not valor: fallos += 1
func juego(semilla: int = 123):
	var j = J.nueva(semilla, "Prueba", [0, 0, 0])
	j.combate.enemigos.clear()
	j.autonomia.reglas.sociedad.activa = false
	j.autonomia.reglas.perfiles.maren.receta = "unguento"
	j.autonomia.activar()
	return j
func sim(j, minutos: int) -> void:
	for i in minutos * 10: j.tick(0.1)
func cerca(j, nid: String) -> void:
	j.pies = j.habitantes.pos(nid)
func recuerdo(j, nid: String, tipo: String) -> bool:
	for r in j.autonomia.estado(nid).recuerdos:
		if r.hecho == tipo: return true
	return false
func _init() -> void:
	var normal = J.nueva(7, "Normal", [0, 0, 0])
	ok(normal.autonomia.activa(), "partida normal arranca en autonomía (modo principal)")
	var j = juego()
	var antes: int = j.d.mundo.rotos.size()
	sim(j, 180)
	ok(j.d.mundo.rotos.size() > antes, "NPC sin jugador recolectan objetos reales del mapa")
	ok(recuerdo(j, "maren", "recolecto") or recuerdo(j, "ordal", "recolecto"), "memoria registra acciones efectivamente ejecutadas")
	ok(j.d.mundo_vivo.ultimo.is_empty() and j.d.mundo_vivo.instancias.is_empty(), "la actividad no depende de tarjetas ni misiones del director")
	ok(j.autonomia.estado("maren").hambre > 0, "necesidad interna avanza con el reloj")
	var identico = juego()
	sim(identico, 180)
	ok(JSON.stringify(j.d.mundo_vivo.autonomia) == JSON.stringify(identico.d.mundo_vivo.autonomia), "misma semilla e intervención reproducen decisiones y recuerdos")
	# Mundo sin fuentes alimenticias: la carencia debe generar una petición en vez de inventar comida.
	var sin = juego()
	for oid in sin.mundo.objetos:
		if sin.mundo.objetos[oid].t == "arbusto": sin.mundo.romper(oid, sin.d.min)
	sim(sin, 6)
	var n: Dictionary = sin.autonomia.estado("maren")
	ok(n.plan.get("act", "") == "pedir" and n.inv.is_empty(), "agotamiento cambia el plan a pedir; no aparecen recursos de la nada")
	ok(recuerdo(sin, "maren", "sin_recurso"), "recuerda la carencia observada")
	sin.pies = Mundo.pies_de_celda(Vector2i(32, 46))
	sin.jug().inv = {"baya": 2}
	ok(not sin.ayudar_habitante("maren").ok and sin.jug().inv.baya == 2, "no se puede donar a distancia")
	cerca(sin, "maren")
	ok(sin.ayudar_habitante("maren").ok and not sin.jug().inv.has("baya") and n.inv.baya == 2, "ayuda transfiere existencias reales, sin duplicarlas")
	ok(sin.autonomia.dialogo("maren", J.LOCAL).contains("Recuerdo tu ayuda"), "diálogo consulta memoria individual del ayudante")
	ok(not sin.ayudar_habitante("maren").ok, "repetir una entrega no vuelve a consumir ni pagar")
	# Falta gelatina, no hay fuente recolectable: busca al ayudante conocido.
	sim(sin, 6)
	ok(n.plan.get("destinatario", "") == J.LOCAL, "memoria de ayuda modifica la decisión de a quién buscar")
	cerca(sin, "maren")
	ok(sin.ayudar_habitante("maren", true).ok, "se puede rechazar una petición sin perder objetos")
	ok(not sin.ayudar_habitante("maren", true).ok, "rechazo tiene enfriamiento y no inunda recuerdos")
	sim(sin, 6)
	ok(not n.plan.has("destinatario"), "respeta una negativa reciente: deja de perseguir al jugador")
	# Necesidad satisfecha por el jugador -> estación real -> producción con consumo.
	var fabrica = juego()
	var f: Dictionary = fabrica.autonomia.estado("ordal")
	f.inv = {"baya": 2, "mena": 2, "madera": 1}
	sim(fabrica, 6)
	ok(f.plan.act == "pedir" and recuerdo(fabrica, "ordal", "sin_estacion") and not f.inv.has("lingote"), "tener ingredientes sin horno no permite fabricar")
	var horno := Vector2i(28, 20)
	fabrica.jug().inv = {"piedra": 8}
	ok(fabrica.construir("horno", horno).ok, "el jugador construye la estación con materiales reales")
	var p := Mundo.pies_de_celda(horno + Vector2i.DOWN)
	fabrica.d.npcs.ordal.pos = [p.x, p.y]
	sim(fabrica, 6)
	ok(int(f.inv.get("lingote", 0)) == 1 and not f.inv.has("mena") and not f.inv.has("madera"), "fabricación consume exactamente entradas y crea su salida")
	ok(recuerdo(fabrica, "ordal", "fabrico"), "recuerda producción habilitada por una construcción del jugador")
	# Persistencia completa, incluida negativa y reloj: no repite acciones al restaurar.
	var ruta := "/tmp/linde-autonomia-integracion.json"
	ok(sin.guardar(ruta), "guardado real de necesidades, inventarios, planes y memoria")
	var cargado = J.cargar(ruta)
	ok(cargado != null, "carga el guardado")
	if cargado != null:
		ok(JSON.stringify(sin.d.mundo_vivo.autonomia) == JSON.stringify(cargado.d.mundo_vivo.autonomia), "reinicio conserva estado y memoria exactos")
		var serializado := JSON.stringify(cargado.d.mundo_vivo.autonomia)
		cargado.autonomia.paso()
		ok(serializado == JSON.stringify(cargado.d.mundo_vivo.autonomia), "mismo minuto tras cargar no repite consumo o trabajo")
	# Autoridad: el nuevo pedido pasa por el servidor, no por mutación de la réplica.
	var srv = Srv.new()
	srv.j = sin
	ok(not srv.ejecutar(J.LOCAL, ["ayudar_habitante", 1, "inexistente", false]), "servidor rechaza un destinatario inexistente")
	ok(not srv.ejecutar(J.LOCAL, ["ayudar_habitante", 2, "maren", "si"]), "servidor rechaza tipos de pedido inválidos")
	cerca(sin, "maren")
	sin.jug().inv = {"gelatina": 2}
	ok(srv.ejecutar(J.LOCAL, ["ayudar_habitante", 3, "maren", false]) and sin.jug().inv.is_empty() and n.inv.get("gelatina", 0) == 2, "pedido válido transfiere materiales bajo autoridad del servidor")
	ok(not srv.ejecutar(J.LOCAL, ["ayudar_habitante", 3, "maren", false]), "repetición de secuencia de red no duplica la entrega")
	var cliente = Cli.new()
	cliente._bienvenida(srv.estado_para(J.LOCAL))
	ok(cliente.j.autonomia.activa() and JSON.stringify(cliente.j.d.mundo_vivo.autonomia) == JSON.stringify(sin.d.mundo_vivo.autonomia), "cliente recibe reservas y memoria al entrar")
	var minuto_cliente: int = cliente.j.d.min
	cliente.j.tick(1000.0)
	ok(cliente.j.d.min == minuto_cliente, "réplica no simula autonomía ni adelanta el reloj")
	var cambio: Dictionary = sin.d.mundo_vivo.duplicate(true)
	cambio.autonomia.npcs.maren.hambre = 73.0
	cliente._mundo({"mundo_vivo": cambio})
	ok(cliente.j.autonomia.estado("maren").hambre == 73.0 and sin.autonomia.estado("maren").hambre != 73.0, "evento fiable actualiza la réplica sin mutar el servidor")
	cliente.free()
	srv.free()
	# Hambre y descanso: comer consume; dormir tiene prioridad sobre producir.
	f.hambre = 30.0
	f.inv.baya = 1
	fabrica.d.min = 25 * 60
	fabrica.autonomia.paso()
	ok(not f.inv.has("baya") and f.hambre < 100.0, "alimentarse consume comida real sin generar reservas")
	ok(f.plan.is_empty() and fabrica.habitantes.deseada("ordal").act == "dormir", "el descanso prevalece sobre el trabajo")
	print("AUTONOMIA: %d comprobaciones, %d fallos" % [comprobaciones, fallos])
	quit(1 if fallos else 0)
