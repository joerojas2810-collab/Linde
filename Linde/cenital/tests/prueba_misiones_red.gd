extends SceneTree
## Las misiones de plantilla se ejecutan en el servidor y las réplicas convierten las acciones en pedidos.
const J = preload("res://scripts/juego.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")

class RedFalsa:
	extends RefCounted
	var pedidos: Array = []
	func enviar(datos: Array) -> void:
		pedidos.append(datos)

var fallos := 0

func check(nombre: String, condicion: bool) -> void:
	print(("PASS " if condicion else "FAIL ") + nombre)
	if not condicion: fallos += 1

func _initialize() -> void:
	var j = J.nueva(123, "Prueba", [0, 0, 0], J.MODO_LEGADO)
	var iid := "cama_huesped#1"
	j.d.mundo_vivo.instancias[iid] = {
		"plantilla": "cama_huesped", "revision": 1, "ambito": "mundo",
		"estado": "ofrecida", "completador": ""
	}
	var srv = Srv.new()
	srv.j = j

	# La réplica no debe cambiar la misión localmente: debe mandar la intención.
	var falsa := RedFalsa.new()
	var replica = Cli.Replica.new()
	replica.red = falsa
	replica.aceptar_mision_plantilla(iid)
	check("cliente envía aceptación de plantilla", falsa.pedidos == [["aceptar_plantilla", iid]])
	replica.entregar_mision_plantilla(iid)
	check("cliente envía entrega de plantilla", falsa.pedidos.size() == 2 and falsa.pedidos[1] == ["entregar_plantilla", iid])
	check("cliente no muta la copia compartida", replica.d.is_empty())

	# El servidor valida el estado de la instancia y aplica las transiciones y la recompensa exactamente una vez.
	check("servidor acepta una misión ofrecida", srv.ejecutar(J.LOCAL, ["aceptar_plantilla", 1, iid]) and j.d.mundo_vivo.instancias[iid].estado == "activa")
	check("servidor no entrega antes de cumplir", srv.ejecutar(J.LOCAL, ["entregar_plantilla", 2, iid]) and j.d.mundo_vivo.instancias[iid].estado == "activa" and j.jug().xp == 0)
	j.mundo.poner(Vector2i(33, 40), "cama_huesped", false)
	check("servidor entrega al cumplir la condición", srv.ejecutar(J.LOCAL, ["entregar_plantilla", 3, iid]) and j.d.mundo_vivo.instancias[iid].estado == "completada")
	check("recompensa aplicada por la autoridad", j.jug().xp == 15 and int(j.jug().inv.get("fibra", 0)) == 2)
	srv.ejecutar(J.LOCAL, ["entregar_plantilla", 4, iid])
	check("entrega repetida no duplica la recompensa", j.jug().xp == 15 and int(j.jug().inv.get("fibra", 0)) == 2)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos else 0)
