extends RefCounted
## Prueba sistémica optativa: necesidades -> elección -> navegación -> acción real.
## Solo Juego autoritativo llama paso(). Todo estado durable vive en mundo_vivo.autonomia.
## No crea tarjetas, misiones, recursos ni recompensas de la nada.
const C = preload("res://scripts/catalogos.gd")
const Mundo = preload("res://scripts/mundo.gd")
const Inv = preload("res://scripts/inventario.gd")
const Asentamientos = preload("res://scripts/asentamientos.gd")
const Sociedad = preload("res://scripts/sociedad.gd")
const Desarrollo = preload("res://scripts/desarrollo.gd")
var desarrollo
var asentamientos
var sociedad
var j
var reglas: Dictionary

func _init(juego) -> void:
	j = juego
	reglas = JSON.parse_string(FileAccess.get_file_as_string("res://datos/autonomia/reglas.json"))
	sociedad = Sociedad.new(self)
	asentamientos = Asentamientos.new(self)
	desarrollo = Desarrollo.new(self)
	if j.es_autoridad() and not "--campana" in OS.get_cmdline_user_args(): activar()   # modo principal; --campana vuelve al director de tarjetas
	else:
		sociedad.restaurar()
		desarrollo.restaurar()

## Activa la prueba en esta partida. Las partidas normales conservan sus reglas anteriores.
func activar() -> void:
	if not j.d.mundo_vivo.has("autonomia"):
		j.d.mundo_vivo.autonomia = {"activa": true, "modo": "sociedad" if reglas.sociedad.activa else "necesidades", "ultimo_min": int(j.d.min), "npcs": {}}
	sociedad.restaurar()
	desarrollo.restaurar()

## Consulta sin modificar la réplica ni activar partidas antiguas.
func activa() -> bool:
	return j.d.get("mundo_vivo", {}).get("autonomia", {}).get("activa", false)

## Los habitantes salen a recoger al contorno del valle (reglas.expediciones).
func expediciones() -> bool:
	return activa() and bool(reglas.get("expediciones", true))

func estado(nid: String) -> Dictionary:
	var todos: Dictionary = j.d.mundo_vivo.autonomia.npcs
	if not todos.has(nid):
		todos[nid] = {"inv": {}, "hambre": 0.0, "plan": {}, "recuerdos": [], "vinculos": {}, "accion_min": -1}
	var n: Dictionary = todos[nid]
	for campo in ["durabilidad", "bloqueos", "peticion"]:
		if not n.has(campo): n[campo] = {}
	if not n.has("vistos"):   # lo que todos conocen desde el inicio no enseña recetas
		n.vistos = {"madera": true, "piedra": true, "fibra": true, "baya": true, "gelatina": true}
		n.recetas_nuevas = []
	return n

## Perfil del habitante: los de reglas.json o el de un colono llegado después (guardado en la partida).
func perfil(nid: String) -> Dictionary:
	if reglas.perfiles.has(nid): return reglas.perfiles[nid]
	return j.d.get("mundo_vivo", {}).get("autonomia", {}).get("colonos", {}).get(nid, {}).get("perfil", {})

## Recetas del perfil más las que descubrió al tener en las manos un ítem que no conocía.
func recetas_de(nid: String) -> Array:
	return perfil(nid).get("recetas", []) + estado(nid).get("recetas_nuevas", [])

## Cada ítem que lleva y no conocía le enseña las recetas que lo usan.
func descubrir_recetas(nid: String) -> void:
	var n := estado(nid)
	for item in n.inv:
		if n.vistos.has(item): continue
		n.vistos[item] = true
		for rid in C.RECETAS:
			if not C.RECETAS[rid].ent.has(item) or rid in recetas_de(nid): continue
			n.recetas_nuevas.append(rid)
			_recordar(nid, "descubrio", "receta de " + C.RECETAS[rid].n)
			if C.ITEMS.get(C.RECETAS[rid].sal.keys()[0], {}).has("tag"): sociedad.suceso("descubrimiento", "Receta de " + C.RECETAS[rid].n, nid)

func _recordar(nid: String, hecho: String, detalle: String, actor: String = "") -> void:
	var recuerdos: Array = estado(nid).recuerdos
	if not recuerdos.is_empty():
		var ult: Dictionary = recuerdos.back()
		if ult.hecho == hecho and ult.detalle == detalle and ult.actor == actor and int(j.d.min) - int(ult.min) < int(reglas.intervalo_recuerdo_min): return
	recuerdos.append({"min": int(j.d.min), "hecho": hecho, "detalle": detalle, "actor": actor})
	while recuerdos.size() > int(reglas.tope_recuerdos): recuerdos.pop_front()

## Avanza necesidades una sola vez por minuto; tras reinicio no repite consumo ni trabajo.
func paso() -> void:
	if not activa(): return
	var a: Dictionary = j.d.mundo_vivo.autonomia
	var ahora: int = j.d.min
	if ahora <= int(a.ultimo_min): return
	var transcurrido: int = ahora - int(a.ultimo_min)
	a.ultimo_min = ahora
	asentamientos.actualizar()
	if sociedad.activa(): sociedad.actualizar()
	var decididos := 0   # reparte la planificación: pocos habitantes por minuto de juego, el resto queda pendiente
	for nid in j.habitantes.ids:
		if perfil(nid).is_empty(): continue
		var n: Dictionary = estado(nid)
		_explorar(nid)
		n.hambre = minf(100.0, float(n.hambre) + float(reglas.hambre_por_hora) * transcurrido / 60.0)
		if n.hambre >= float(reglas.umbral_comer) and int(n.inv.get(reglas.comida, 0)) > 0:
			_quitar(n.inv, str(reglas.comida), 1)
			n.hambre = maxf(0.0, n.hambre - float(reglas.saciedad))
			_recordar(nid, "comio", str(reglas.comida))
		# Descanso y sueño conservan prioridad. No se fabrica caminando o desde la cama.
		var rutina: Dictionary = j.habitantes.rutina(nid)
		if rutina.act in ["dormir", "descansar"]:
			n.plan = {}
			continue
		if ahora - int(n.accion_min) < int(reglas.intervalo_accion_min): continue
		if decididos >= int(reglas.max_decisiones_por_paso): continue
		decididos += 1
		n.accion_min = ahora
		_decidir(nid)


# La memoria cambia a quién busca: prioriza ayudantes conocidos y respeta una negativa reciente.
func _pedir(nid: String, motivo: String) -> Dictionary:
	var n := estado(nid)
	var elegido := ""
	var mejor := 0
	var jugadores: Array = j.rt.keys()
	jugadores.sort()
	for id in jugadores:
		var v: Dictionary = n.vinculos.get(id, {})
		if v.has("rechazo_min") and int(j.d.min) - int(v.rechazo_min) < int(reglas.intervalo_recuerdo_min): continue
		if int(v.get("ayudas", 0)) > mejor:
			mejor = int(v.ayudas)
			elegido = id
	var p := {"act": "pedir", "motivo": motivo}
	if elegido != "":
		var c := Mundo.celda_de(j.pies_de(elegido))
		if not j.mundo.camino(Mundo.celda_de(j.habitantes.pos(nid)), func(x): return j.mundo.es_adyacente(x, c)).is_empty():
			p["celda"] = [c.x, c.y]
			p["destinatario"] = elegido
	return p

## Cuánto de `item` aún cabe en la mochila del habitante (reglas.mochila_habitante pilas).
func hueco(nid: String, item: String) -> int:
	var inv: Dictionary = estado(nid).inv
	var pila: int = int(Inv.Eq.info(item).pila)
	var resto: int = (pila - int(inv.get(item, 0)) % pila) % pila
	return maxi(0, int(reglas.mochila_habitante) - Inv.slots(inv)) * pila + resto

## Añade hasta donde quepa y devuelve lo realmente añadido.
func dar(nid: String, item: String, cantidad: int) -> int:
	var k: int = mini(cantidad, hueco(nid, item))
	if k > 0: estado(nid).inv[item] = int(estado(nid).inv.get(item, 0)) + k
	return k

func _quitar(inv: Dictionary, item: String, cantidad: int) -> void:
	inv[item] = int(inv.get(item, 0)) - cantidad
	if inv[item] == 0: inv.erase(item)

## Carencias calculadas desde reservas y receta; no hay una misión predefinida por NPC.
func necesidad(nid: String) -> Dictionary:
	if sociedad.activa(): return sociedad.necesidad(nid)
	var n: Dictionary = estado(nid)
	var p: Dictionary = perfil(nid)
	var comida: String = reglas.comida
	if int(n.inv.get(comida, 0)) < int(reglas.reserva_comida):
		return {"item": comida, "cantidad": int(reglas.reserva_comida) - int(n.inv.get(comida, 0)), "motivo": "alimentarme"}
	var receta: Dictionary = C.RECETAS[p.receta]
	var producto: String = receta.sal.keys()[0]
	if int(n.inv.get(producto, 0)) >= int(p.reserva_producto): return {}
	for item in receta.ent:
		var falta: int = int(receta.ent[item]) - int(n.inv.get(item, 0))
		if falta > 0: return {"item": item, "cantidad": falta, "motivo": "fabricar " + C.ITEMS[producto].n}
	return {"estacion": receta.est, "motivo": "fabricar " + C.ITEMS[producto].n}

func _decidir(nid: String) -> void:
	if sociedad.activa():
		sociedad.decidir(nid)
		return
	var n: Dictionary = estado(nid)
	var falta: Dictionary = necesidad(nid)
	if falta.is_empty():
		n.plan = {}
		return
	if falta.has("item"):
		var objetivo := _recurso(nid, falta.item)
		if objetivo == "":
			n.plan = _pedir(nid, falta.motivo)
			_recordar(nid, "sin_recurso", falta.item)
			return
		var celda: Vector2i = j.mundo.objetos[objetivo].c
		n.plan = {"act": "recolectar", "celda": [celda.x, celda.y], "objeto": objetivo, "motivo": falta.motivo}
		var actual := Mundo.celda_de(j.habitantes.pos(nid))
		if not j.mundo.es_adyacente(actual, celda): return
		var def: Dictionary = C.OBJETOS[j.mundo.objetos[objetivo].t]
		var golpes: int = int(j.d.mundo.golpes.get(objetivo, 0)) + 1
		if golpes < _golpes(nid, def):
			j.d.mundo.golpes[objetivo] = golpes
			return
		var drops: Dictionary = def.drops.duplicate()
		var rng = j._rng("autonomia", "%s:%s:%d" % [nid, objetivo, j.d.min])
		for prob in def.prob:
			if rng.randf() < prob.p: drops[prob.item] = int(drops.get(prob.item, 0)) + int(prob.q)
		for item in drops: dar(nid, item, int(drops[item]))
		j.mundo.romper(objetivo, j.d.min)
		_recordar(nid, "recolecto", j._txt_items(drops))
		n.plan = {}
		return
	var estacion: String = _estacion(nid, falta.estacion)
	if estacion == "":
		n.plan = {"act": "pedir", "motivo": "necesito una estación " + str(falta.estacion)}
		_recordar(nid, "sin_estacion", falta.estacion)
		return
	var celda := Vector2i(int(estacion.get_slice(",", 0)), int(estacion.get_slice(",", 1)))
	n.plan = {"act": "fabricar", "celda": [celda.x, celda.y], "motivo": falta.motivo}
	if not j.mundo.es_adyacente(Mundo.celda_de(j.habitantes.pos(nid)), celda): return
	var receta: Dictionary = C.RECETAS[perfil(nid).receta]
	if not Inv.tiene(n.inv, receta.ent): return
	for item in receta.ent: _quitar(n.inv, item, int(receta.ent[item]))
	for item in receta.sal: dar(nid, item, int(receta.sal[item]))
	_recordar(nid, "fabrico", j._txt_items(receta.sal))
	j.aviso_todos("%s fabricó %s" % [j.habitantes.fichas[nid].n, j._txt_items(receta.sal)])
	n.plan = {}

func _golpes(nid: String, def: Dictionary) -> int:
	if sociedad.activa(): return sociedad.golpes(nid, def)
	var necesarios := 9999
	for tag in def.golpes:
		if tag == "" or tag in perfil(nid).herramientas: necesarios = mini(necesarios, int(def.golpes[tag]))
	return necesarios

## Conocimiento limitado: cada habitante sabe qué bloques del mapa ha visto (se guarda como claves "bx,by").
## Parte de su entorno inicial, descubre lo que ve al moverse y se entera de lo que sabe quien se cruza con él.
func _bloque(c: Vector2i) -> String:
	var b: int = int(reglas.conocimiento.bloque)
	return "%d,%d" % [floori(float(c.x) / b), floori(float(c.y) / b)]

func conoce(nid: String, c: Vector2i) -> bool:
	if not estado(nid).has("bloques"): _explorar(nid) # También antes del primer minuto o al cargar un guardado anterior.
	return estado(nid).bloques.has(_bloque(c)) or (not Mundo.es_valle(c) and Mundo.Terreno.distancia_valle(c) <= int(reglas.conocimiento.horizonte))   # el contorno se ve desde el borde

func _ver(n: Dictionary, centro: Vector2i, radio: int) -> void:
	for dx in range(-radio, radio + 1, int(reglas.conocimiento.bloque)):
		for dy in range(-radio, radio + 1, int(reglas.conocimiento.bloque)):
			n.bloques[_bloque(centro + Vector2i(dx, dy))] = true

func _explorar(nid: String) -> void:
	var n: Dictionary = estado(nid)
	var pos := Mundo.celda_de(j.habitantes.pos(nid))
	if not n.has("bloques"):
		n.bloques = {}
		_ver(n, pos, int(reglas.conocimiento.radio_inicial))
	_ver(n, pos, int(reglas.conocimiento.radio_vision))
	for otro in j.habitantes.ids:   # rumor: al cruzarse comparten lo que conocen
		if otro == nid or perfil(otro).is_empty() or not estado(otro).has("bloques"): continue
		if Vector2(Mundo.celda_de(j.habitantes.pos(otro))).distance_to(Vector2(pos)) <= float(reglas.conocimiento.radio_rumor):
			n.bloques.merge(estado(otro).bloques)

## Línea de visión aproximada: ningún muro u objeto sólido entre ambas celdas.
func ve(desde: Vector2i, hasta: Vector2i) -> bool:
	var pasos: int = maxi(absi(hasta.x - desde.x), absi(hasta.y - desde.y))
	for i in range(1, pasos):
		var c := Vector2i(desde + (hasta - desde) * i / pasos)
		if j.mundo.bloquea(c): return false
	return true

# Orden por distancia y después ID: repetible y no dependiente del orden de un Dictionary.
func _recurso(nid: String, item: String) -> String:
	var origen := Mundo.celda_de(j.habitantes.pos(nid))
	var candidatos: Array = []
	for oid in j.mundo.objetos:
		var o: Dictionary = j.mundo.objetos[oid]
		if not expediciones() and not Mundo.es_valle(o.c): continue
		if j.mundo.objeto_presente(o.c) != oid or not C.OBJETOS.has(o.t): continue
		if sociedad.activa() and not sociedad.permite_recurso(nid, oid): continue
		if not conoce(nid, o.c): continue
		var def: Dictionary = C.OBJETOS[o.t]
		var aporta: bool = def.drops.has(item)
		for prob in def.prob: if prob.item == item and float(prob.p) > 0.0: aporta = true
		if aporta and _golpes(nid, def) < 9999: candidatos.append(oid)
	candidatos.sort_custom(func(a, b):
		var da: int = absi(origen.x - j.mundo.objetos[a].c.x) + absi(origen.y - j.mundo.objetos[a].c.y)
		var db: int = absi(origen.x - j.mundo.objetos[b].c.x) + absi(origen.y - j.mundo.objetos[b].c.y)
		return a < b if da == db else da < db)
	var alcance: Dictionary = j.mundo.alcanzables(origen, Mundo.AREA_EXPEDICION if expediciones() else Rect2i())   # una sola búsqueda, valle y contorno
	for oid in candidatos:
		var c: Vector2i = j.mundo.objetos[oid].c
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if alcance.has(c + d) and j.mundo.es_adyacente(c + d, c): return oid
	return ""

func _estacion(nid: String, tipo: String) -> String:
	var origen := Mundo.celda_de(j.habitantes.pos(nid))
	var claves: Array = j.d.mundo.constr.keys()
	claves.sort()
	for k in claves:
		var t: String = j.d.mundo.constr[k].t
		if C.CONSTR[t].get("est", "") != tipo: continue
		if sociedad.activa() and not sociedad.permite_estacion(nid, k): continue
		var c := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
		if not j.mundo.camino(origen, func(x): return j.mundo.es_adyacente(x, c)).is_empty(): return k
	return ""

## Plan consumido por Habitantes; se recalcula con el estado real, no con un guion.
func plan(nid: String) -> Dictionary:
	if not activa() or perfil(nid).is_empty(): return {}
	return estado(nid).plan

## Petición visible. Ayudar exige proximidad y transfiere solo lo que falta actualmente.
func ayudar(nid: String, jugador: String, rechazar: bool = false) -> Dictionary:
	if not activa() or not j.habitantes.ids.has(nid) or perfil(nid).is_empty(): return j._no("No hay petición", jugador)
	if j.habitantes.pos(nid).distance_to(j.pies_de(jugador)) > j.ALCANCE_NPC: return j._no("Acércate al habitante", jugador)
	var falta := necesidad(nid)
	if not falta.has("item"): return j._no("No necesita materiales ahora", jugador)
	var n := estado(nid)
	var vinculo: Dictionary = n.vinculos.get(jugador, {})
	if rechazar:
		if int(vinculo.get("rechazo_min", -9999)) + int(reglas.intervalo_recuerdo_min) > int(j.d.min): return j._no("Ya respondiste a esta petición", jugador)
		vinculo["rechazo_min"] = int(j.d.min)
		n.vinculos[jugador] = vinculo
		_recordar(nid, "rechazo", falta.item, jugador)
		return j._ok("Recordará tu respuesta y seguirá buscando.", jugador)
	var item: String = falta.item
	var cantidad: int = mini(int(falta.cantidad), int(j.jug(jugador).inv.get(item, 0)))
	if cantidad <= 0: return j._no("No llevas " + C.ITEMS[item].n, jugador)
	cantidad = mini(cantidad, hueco(nid, item))
	if cantidad <= 0: return j._no("Su mochila está llena", jugador)
	_quitar(j.jug(jugador).inv, item, cantidad)
	dar(nid, item, cantidad)
	vinculo["ayudas"] = int(vinculo.get("ayudas", 0)) + 1
	n.vinculos[jugador] = vinculo
	var pago := {}
	if sociedad.activa():
		sociedad.reconoce_ayuda(nid, jugador)
		pago = sociedad.recompensa(nid, jugador, item, cantidad)
	_recordar(nid, "ayuda", "%d %s" % [cantidad, item], jugador)
	if not pago.is_empty(): return j._ok("Entregas %d %s y recibes %s a cambio." % [cantidad, C.ITEMS[item].n, j._txt_items(pago)], jugador)
	return j._ok("Entregas %d %s; recordará tu ayuda." % [cantidad, C.ITEMS[item].n], jugador)

## Texto derivado del estado y de la relación recordada; nunca concede objetos.
func dialogo(nid: String, jugador: String) -> String:
	var n := estado(nid)
	var vinculo: Dictionary = n.vinculos.get(jugador, {})
	var texto := "Recuerdo tu ayuda. " if int(vinculo.get("ayudas", 0)) > 0 else ""
	if texto == "" and vinculo.has("rechazo_min"): texto = "La última vez no pudiste ayudarme. "
	if sociedad.activa():
		var perfil_actual := perfil(nid)
		var identidad: Dictionary = perfil_actual.get("identidad",{})
		if not identidad.is_empty(): texto = "Soy %s y quiero %s. " % [perfil_actual.get("oficio","habitante"),identidad.objetivo] + texto
		var recientes: Array = n.recuerdos.slice(-12)
		recientes.reverse()
		for recuerdo in recientes:
			if recuerdo.hecho in ["estafado","robado","descubrio","mantenimiento"]:
				texto += texto_recuerdo(recuerdo).left(110) + ". "
				break
		var cid: String = sociedad._ocupado(nid)
		if cid != "":
			var acuerdo: Dictionary = sociedad.datos().acuerdos[cid]
			var otro: String = acuerdo.proveedor if acuerdo.solicitante == nid else acuerdo.solicitante
			return texto + "Tengo un acuerdo con %s por %s. Debemos encontrarnos para entregarlo." % [j.habitantes.fichas[otro].n, j._txt_items(acuerdo.bien)]
	var falta := necesidad(nid)
	if falta.has("item"):
		return texto + "Me faltan %d %s para %s. Puedes ayudarme desde J, estando cerca." % [falta.cantidad, C.ITEMS[falta.item].n, falta.motivo]
	if falta.has("estacion") and _estacion(nid, falta.estacion) == "": return texto + "Necesito una estación: %s. Si construyes una accesible podré trabajar." % falta.estacion
	return texto + ("Tengo reservas suficientes por ahora." if falta.is_empty() else "Ya tengo los materiales; voy a trabajar.")

## Expresión legible de un recuerdo para la interfaz.
func texto_recuerdo(r: Dictionary) -> String:
	var nombres := {"sin_recurso": "No encontré el recurso", "sin_estacion": "Me faltó una estación", "recolecto": "Recolecté", "fabrico": "Fabriqué", "comio": "Comí", "ayuda": "Recibí ayuda", "rechazo": "No pudieron ayudarme", "herramienta_rota": "Se rompió mi herramienta", "reparo": "Reparé", "extraccion_vista": "Vi extraer", "aporte": "Aporté al grupo", "promesa": "Acordé entregar", "cumplio": "Cumplimos el acuerdo", "incumplio": "No cumplió el plazo", "plazo_vencido": "Venció el acuerdo", "pospuso": "Busqué otra solución", "construyo": "Construí", "cosecho": "Coseché", "descubrio": "Creé un nuevo plano", "estafado": "Me engañaron", "estafo": "Engañé", "hurto": "Robé", "hurto_visto": "Vi un robo", "llego": "Llegué", "robado": "Me robaron", "mantenimiento":"Cuidé mi ropa y lecho"}
	return str(nombres.get(r.hecho, r.hecho)) + ": " + str(r.detalle)
