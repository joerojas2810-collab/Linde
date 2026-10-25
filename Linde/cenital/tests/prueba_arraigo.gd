extends SceneTree
## Arraigo y vidas en movimiento: llegada sin cama, permanencia y trayectoria. Crece por etapas.
const J = preload("res://scripts/juego.gd")
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
func rico(j) -> void:
	j.autonomia.estado("ordal").inv = {"baya": 900}
func cama_libre(j, pieza: String = "cama_huesped") -> Vector2i:
	for dy in range(-8, 0):
		for dx in range(-8, 9):
			var c: Vector2i = Mundo.ENTRADA + Vector2i(dx, dy)
			if j.mundo.puede_poner(c) == "" and not j.ocupada(c) and Mundo.es_valle(c):
				j.mundo.poner(c, pieza, true)
				return c
	return Vector2i(-1, -1)
func huella(j, id: String) -> String:
	var c: Dictionary = j.d.mundo_vivo.autonomia.colonos[id]
	return JSON.stringify([c.npc.name, c.perfil.get("oficio", ""), c.perfil.get("biografia", {}), c.get("permanencia", {}).get("estado", ""), j.autonomia.estado(id).vinculos, j.autonomia.estado(id).inv, j.autonomia.estado(id).recuerdos])
func _init() -> void:
	# Etapa 1: llegar sin cama; las camas solas no atraen a nadie.
	var j = nuevo()
	var s = j.autonomia.sociedad
	ok(j.vivo.camas_libres_lista().is_empty(), "no hay camas libres al empezar")
	var pobre: float = s.presion()
	cama_libre(j)
	ok(not j.vivo.camas_libres_lista().is_empty(), "se construye una cama libre")
	s.datos().llegada_min = -99999
	s._inmigrar()
	ok(j.d.mundo_vivo.autonomia.get("colonos", {}).is_empty(), "una cama libre sin sustento no provoca llegadas")
	var k = nuevo()
	var sk = k.autonomia.sociedad
	rico(k)
	ok(sk.presion() >= 1.0 and k.vivo.camas_libres_lista().is_empty(), "con sustento hay presión de llegada aunque no haya camas")
	sk.datos().llegada_min = -99999
	sk._inmigrar()
	var colonos: Dictionary = k.d.mundo_vivo.autonomia.get("colonos", {})
	ok(colonos.size() == 1, "llega un colono sin cama libre")
	var id: String = colonos.keys()[0] if colonos.size() else ""
	ok(id != "" and k.habitantes.ids.has(id) and k.d.npcs.has(id), "el colono existe como habitante")
	ok(id != "" and k.habitantes.cama(id) == Vector2i(-1, -1), "duerme al raso, sin cama")
	var antes: float = k.d.npcs[id].energia
	k.d.npcs[id].energia = 5.0
	k.habitantes.paso(1.0)
	var rutina_dormir: bool = k.habitantes.rutina(id).act == "dormir"
	ok(rutina_dormir and k.d.npcs[id].act == "sin_cama" and k.d.npcs[id].energia > 5.0, "sin cama recupera energía durmiendo al raso")
	var c := cama_libre(k)
	ok(k.habitantes.asignar_camas() == 1 and k.habitantes.cama(id) == c, "al construirse una cama libre, quien dormía al raso la toma")
	# Seguridad: los robos recientes reducen la presión.
	var base: float = sk.presion()
	for i in 3: sk.suceso("hurto", "prueba", id)
	ok(sk.presion() < base, "robos recientes reducen la presión de llegada")
	# Etapa 2: permanencia. Visitante -> aspirante -> residente; o se marcha y puede volver sin perder su identidad.
	var u = nuevo()
	var su = u.autonomia.sociedad
	rico(u)
	su.datos().llegada_min = -99999
	su._inmigrar()
	var uid: String = u.d.mundo_vivo.autonomia.colonos.keys()[0]
	var ar = su.arraigo
	ok(ar.estado(uid) == "visitante", "el recién llegado es visitante")
	ok(ar.valor(uid) >= 0.0 and ar.valor(uid) <= 1.0, "el arraigo es un valor entre 0 y 1")
	ar.cfg.umbral_aspirar = 0.0
	ar.cfg.umbral_residir = 0.0
	u.d.min += 1440 * 2
	ar.evaluar_dia()
	ok(ar.estado(uid) == "aspirante", "tras la visita, con arraigo suficiente aspira a quedarse")
	u.d.min += 1440
	ar.evaluar_dia()
	ok(ar.estado(uid) == "residente", "si el arraigo se sostiene se establece como residente")
	var w = nuevo()
	var sw = w.autonomia.sociedad
	rico(w)
	sw.datos().llegada_min = -99999
	sw._inmigrar()
	var wid: String = w.d.mundo_vivo.autonomia.colonos.keys()[0]
	sw.arraigo.cfg.umbral_aspirar = 2.0   # nunca arraiga: se queda de visita y luego se marcha
	w.d.min += 1440 * 5
	sw.arraigo.evaluar_dia()
	ok(sw.arraigo.estado(wid) == "ausente", "un visitante se marcha sin convertirse en residente")
	ok(not w.habitantes.ids.has(wid) and not w.d.npcs.has(wid), "el ausente deja de estar presente en el valle")
	ok(w.d.mundo_vivo.autonomia.colonos.has(wid) and w.habitantes.fichas.has(wid) and w.autonomia.estado(wid).has("inv"), "conserva identidad, ficha e inventario")
	var vuelve := false
	for i in 12:
		w.d.min += 1440
		sw.datos().sucesos.clear()
		rico(w)
		sw.arraigo.evaluar_dia()
		if sw.arraigo.estado(wid) == "visitante": vuelve = true; break
	ok(vuelve and w.habitantes.ids.has(wid) and w.d.npcs.has(wid), "con el tiempo y sustento un ausente regresa como visitante")
	var l = nuevo()
	var sl = l.autonomia.sociedad
	rico(l)
	sl.datos().llegada_min = -99999
	sl._inmigrar()
	var lid: String = l.d.mundo_vivo.autonomia.colonos.keys()[0]
	l.d.mundo_vivo.autonomia.colonos[lid].erase("permanencia")
	l.d.min += 1440 * 9
	sl.arraigo.evaluar_dia()
	ok(sl.arraigo.estado(lid) == "residente" and l.habitantes.ids.has(lid), "un colono de una partida anterior cuenta como residente y no se marcha")
	var gp = l.guardar("/tmp/linde-arraigo.json")
	var cg = J.cargar("/tmp/linde-arraigo.json")
	ok(gp and cg != null and cg.habitantes.ids.has(lid), "el guardado conserva a los colonos presentes")
	var wg = w.guardar("/tmp/linde-arraigo2.json")
	var cw = J.cargar("/tmp/linde-arraigo2.json")
	ok(wg and cw != null and cw.autonomia.sociedad.arraigo.estado(wid) == "visitante", "el estado de permanencia sobrevive al guardado")
	# Etapa 3: biografía mínima.
	var b: Dictionary = u.autonomia.perfil(uid).get("biografia", {})
	ok(b.has("origen") and b.has("antecedente") and b.has("motivacion") and b.has("aspiracion"), "el colono tiene origen, antecedente, motivación y aspiración")
	ok(ar.resumen(uid).length() > 20, "la biografía se puede leer en una línea")
	var rng := RandomNumberGenerator.new()
	var mots := {}
	var persona := false
	for i in 40:
		rng.seed = i + 1
		var bi: Dictionary = ar.biografia(rng, {"codicia": 50, "honestidad": 50, "rencor": 50}, [])
		mots[bi.motivacion] = true
		if su.cfg.biografia.antecedentes[bi.antecedente].get("persona", false): persona = true
	ok(mots.size() >= 3, "personas con el mismo carácter reciben motivaciones distintas")
	ok(not persona, "sin otros habitantes no se sortean antecedentes que nombren a alguien")
	ar.cfg.pesos.seguridad = 1.0
	u.autonomia.perfil(uid).biografia.motivacion = "seguridad"
	var ps: Dictionary = ar.pesos(uid)
	u.autonomia.perfil(uid).biografia.motivacion = "ambicion"
	ok(ps.seguridad > ar.pesos(uid).seguridad, "la motivación cambia cuánto pesa cada dimensión del arraigo")
	u.autonomia.perfil(uid).biografia.aspiracion = "hogar"
	u.autonomia.perfil(uid).biografia.cumplidas = []
	cama_libre(u)
	u.habitantes.asignar_camas()
	u.d.min += 1440
	ar.evaluar_dia()
	var bu: Dictionary = u.autonomia.perfil(uid).biografia
	ok("hogar" in bu.cumplidas and bu.aspiracion != "hogar", "al cumplirse una aspiración se registra y se pasa a otra")
	var an = nuevo()
	rico(an)
	an.autonomia.sociedad.datos().llegada_min = -99999
	an.autonomia.sociedad._inmigrar()
	var aid: String = an.d.mundo_vivo.autonomia.colonos.keys()[0]
	an.d.mundo_vivo.autonomia.colonos[aid].perfil.erase("biografia")
	an.autonomia.sociedad.restaurar()
	ok(an.autonomia.perfil(aid).has("biografia"), "un colono de una partida anterior recibe una biografía razonable")
	# Etapa 4: relaciones previas con consecuencias observables.
	var conocidos := {}
	for i in 60:
		rng.seed = 100 + i
		var bp: Dictionary = ar.biografia(rng, {"codicia": 50, "honestidad": 50, "rencor": 50}, ["ordal", "maren"])
		if su.cfg.biografia.antecedentes[bp.antecedente].get("persona", false): conocidos[bp.get("con", "")] = true
	ok(not conocidos.is_empty() and not conocidos.has("") and conocidos.keys().all(func(k): return k in ["ordal", "maren"]), "las relaciones previas apuntan solo a habitantes que existen")
	var bd: Dictionary = u.autonomia.perfil(uid).biografia
	bd.antecedente = "deuda"
	bd.con = "ordal"
	var c0: int = su.confianza(uid, "ordal")
	ar.vincular(uid)
	ok(su.confianza(uid, "ordal") < c0 and su.confianza("ordal", uid) < 0 and bd.has("deuda"), "una deuda previa resta confianza entre ambos")
	ok(ar.resumen(uid).contains("Ordal") or ar.resumen(uid).contains(u.habitantes.fichas["ordal"].n), "la biografía nombra a la persona con quien hay deuda")
	var antes_fibra: int = int(u.autonomia.estado("ordal").inv.get("fibra", 0))
	u.autonomia.estado(uid).inv = {"fibra": 5}
	var cd: int = su.confianza(uid, "ordal")
	u.d.min += 1440
	ar.evaluar_dia()
	ok(not bd.has("deuda") and su.confianza(uid, "ordal") > cd and int(u.autonomia.estado("ordal").inv.get("fibra", 0)) == antes_fibra + 3, "al saldar la deuda se transfieren bienes reales y mejora la confianza")
	bd.antecedente = "conocido"
	var ca: int = su.confianza(uid, "maren")
	bd.con = "maren"
	ar.vincular(uid)
	ok(su.confianza(uid, "maren") > ca, "un conocido previo da confianza inicial")
	# Etapa 5: el director usa la presión de llegada, no las camas.
	var h = J.nueva(123, "Observador", [0, 0, 0])
	var base_h: int = int(h.vivo.instantanea().get("presion_llegada", -1))
	ok(base_h >= 0 and base_h < 100, "sin actividad construida la presión de llegada no alcanza")
	cama_libre(h)
	cama_libre(h)
	ok(h.vivo.instantanea().camas_libres == 2 and int(h.vivo.instantanea().presion_llegada) == base_h, "las camas libres solas no crean presión de llegada")
	for i in 4: cama_libre(h, "cofre")
	ok(int(h.vivo.instantanea().presion_llegada) >= 100, "la actividad construida (no las camas) crea presión de llegada")
	ok(h.vivo._llegadas_posibles({"nerea_presente": true}, {}) == "" or h.vivo.camas_libres_lista().size() > 0, "una llegada no se rechaza por falta de cama libre")
	var g = J.nueva(123, "Observador", [0, 0, 0])
	ok(g.vivo._llegadas_posibles({"nerea_presente": true}, {}) == "", "sin ninguna cama el director permite la llegada")
	# Etapa 6: profesión, ocupación y habilidades; sin albañil, otro levanta la casa con madera.
	var o6 = nuevo()
	var s6 = o6.autonomia.sociedad
	ok(str(o6.autonomia.perfil("maren").oficio) == "artesano", "la profesión es identidad del perfil")
	var m6: Dictionary = o6.autonomia.estado("maren")
	m6.inv = {"baya": 3}
	o6.autonomia.estado("ordal").inv = {"baya": 3}
	for i in 200: o6.tick(0.5)
	ok(o6.autonomia.estado("maren").get("ocupacion", "") != "" or o6.autonomia.estado("ordal").get("ocupacion", "") != "", "la ocupación actual se registra aparte de la profesión")
	ok(s6.texto_trabajo("maren").begins_with("Artesano"), "el texto distingue profesión y ocupación")
	var cb6 := cama_libre(o6)
	ok(s6._constructor("maren") and s6._constructor("ordal"), "sin albañil en el valle cualquiera puede levantar casas")
	o6.autonomia.estado("ordal").recetas_nuevas = ["ladrillo"]
	ok(s6._constructor("ordal") and not s6._constructor("maren"), "con albañil, la obra se la queda él")
	# Etapa 7: agricultor y explorador son perfiles de datos sobre las mecánicas existentes.
	var o7 = nuevo()
	var s7 = o7.autonomia.sociedad
	ok(s7.cfg.inmigracion.oficios.has("agricultor") and s7.cfg.inmigracion.oficios.has("explorador"), "agricultor y explorador son oficios que pueden llegar")
	var lim: Dictionary = o7.autonomia.estado("maren")
	o7.autonomia.reglas.perfiles.maren["prioridad"] = ["explorar"]
	o7.d.min = 600
	o7.autonomia.estado("maren").hambre = 0.0
	var antes_b: int = o7.autonomia.estado("maren").get("bloques", {}).size()
	o7.autonomia.estado("maren").inv = {"baya": 3}
	for i in 300: o7.tick(0.5)
	ok(o7.autonomia.estado("maren").get("explora", null) != null or o7.autonomia.estado("maren").get("bloques", {}).size() > antes_b, "quien tiene la exploración como prioridad sale a lo desconocido")
	o7.autonomia.desarrollo.cfg.activa = true
	for i in 3: o7.autonomia.desarrollo.registrar("npc:maren", "exploracion")
	ok(o7.autonomia.desarrollo.rango("npc:maren", "exploracion") >= 1, "la exploración usa la progresión por práctica existente")
	# Etapa 8: mercader (intermediario por acordar) y guardia (disuade el hurto).
	var o8 = nuevo()
	var s8 = o8.autonomia.sociedad
	o8.autonomia.desarrollo.cfg.activa = true
	ok(s8.cfg.inmigracion.oficios.has("mercader") and s8.cfg.inmigracion.oficios.has("guardia"), "mercader y guardia son oficios que pueden llegar")
	o8.autonomia.reglas.perfiles.maren["prioridad"] = ["comerciar"]
	o8.autonomia.estado("maren").inv = {"baya": 12, "fibra": 8}
	o8.autonomia.estado("ordal").inv = {"fibra": 30, "madera": 10, "piedra": 10}
	o8.d.min = 480
	ok(s8.necesidad("ordal").has("item"), "ordal tiene una necesidad que otro puede cubrir")
	var vendio: bool = s8._ocupar("maren", "comerciar")
	var tratos: Array = s8.datos().acuerdos.values().filter(func(c): return c.proveedor == "maren" and c.solicitante == "ordal")
	ok(vendio and not tratos.is_empty() and o8.autonomia.estado("maren").ocupacion == "comerciar", "el mercader cubre una necesidad con un acuerdo real")
	ok(o8.autonomia.desarrollo.rango("npc:maren", "comercio") >= 0 and int(o8.autonomia.desarrollo.estado("npc:maren").practica.get("comercio", 0)) == 1, "comerciar suma práctica")
	var g8 = nuevo()
	var sg = g8.autonomia.sociedad
	g8.autonomia.reglas.perfiles.maren["prioridad"] = ["vigilar"]
	g8.d.min = 480
	var ancla: Vector2i = sg._ancla("talleres")
	var pm := Mundo.pies_de_celda(ancla)
	g8.d.npcs.maren.pos = [pm.x, pm.y]
	ok(sg._ocupar("maren", "vigilar") and sg._guardia_cerca(ancla), "el guardia de servicio vigila el depósito")
	sg.grupo("talleres").inv = {"madera": 3}
	g8.d.npcs.ordal.pos = [pm.x, pm.y]
	g8.autonomia.estado("ordal").inv = {}
	sg._hurtar("ordal", "madera", 1)
	ok(int(sg.grupo("talleres").inv.get("madera", 0)) == 3, "con un guardia de servicio nadie roba el depósito")
	g8.d.min = 700
	ok(not sg._guardia_cerca(ancla), "fuera de turno no hay disuasión")
	sg._hurtar("ordal", "madera", 1)
	ok(int(sg.grupo("talleres").inv.get("madera", 0)) < 3, "sin guardia el hurto es posible")
	# Etapa 9: las necesidades de oficio influyen en quién llega y en la presión.
	var o9 = nuevo()
	var s9 = o9.autonomia.sociedad
	var pr: Dictionary = s9.oficios_presentes()
	ok(pr.get("artesano", 0) == 1 and pr.get("cantero", 0) == 1, "se cuentan las profesiones presentes")
	ok(s9._peso_oficio("guardia", pr) > s9._peso_oficio("cantero", pr), "el oficio que falta pesa más al sortear quién llega")
	var p0: float = s9.presion()
	for i in 3: s9.suceso("hurto", "prueba", "ordal")
	ok(s9._peso_oficio("guardia", pr) > 1.5 * s9._peso_oficio("explorador", pr), "tras robos pesan más los guardias")
	var oficios_vistos := {}
	var o9b = nuevo()
	rico(o9b)
	for _k in 8:
		o9b.autonomia.sociedad.datos().llegada_min = -99999
		o9b.d.min += 1440 * 2
		o9b.autonomia.sociedad._inmigrar()
	for cid9 in o9b.d.mundo_vivo.autonomia.get("colonos", {}): oficios_vistos[o9b.d.mundo_vivo.autonomia.colonos[cid9].perfil.oficio] = true
	ok(oficios_vistos.size() >= 3, "con el tiempo llegan oficios distintos y no solo cuatro")
	# Etapa 10: la vivienda se planifica para alguien, no alrededor de una cama.
	var o10 = nuevo()
	var s10 = o10.autonomia.sociedad
	rico(o10)
	s10.datos().llegada_min = -99999
	s10._inmigrar()
	s10.datos().llegada_min = -99999
	o10.d.min += 3000
	rico(o10)
	s10._inmigrar()
	var nuevos: Array = o10.d.mundo_vivo.autonomia.colonos.keys()
	nuevos.sort()
	ok(nuevos.size() == 2 and s10._sin_cama().size() == 2, "dos recién llegados duermen al raso")
	var parcela10: Dictionary = {}
	for _i in 40:
		parcela10 = s10.habitat.reservar("maren")
		if not parcela10.is_empty(): break
	ok(not parcela10.is_empty() and o10.vivo.camas_libres_lista().is_empty(), "se reserva un solar sin que exista ninguna cama")
	parcela10["para"] = nuevos[1]
	var celda10 := Vector2i(int(parcela10.cama[0]), int(parcela10.cama[1]))
	o10.mundo.poner(celda10, "cama_huesped", true)
	o10.habitantes.asignar_camas()
	ok(o10.habitantes.cama(nuevos[1]) == celda10 and o10.habitantes.cama(nuevos[0]) == Vector2i(-1, -1), "la cama construida en el solar es de quien se planificó, no del primero de la lista")
	ok(s10.habitat.permite_pieza(celda10 + Vector2i(0, -1), "muro"), "el muro de madera de respaldo cabe en el solar de la vivienda")
	# Etapa 11: la casa comunitaria aloja a varios; su capacidad son sus camas.
	var o11 = nuevo()
	var s11 = o11.autonomia.sociedad
	var parcela11: Dictionary = {}
	for _i in 40:
		parcela11 = s11.habitat.reservar("maren", "comunitaria")
		if not parcela11.is_empty(): break
	ok(not parcela11.is_empty() and parcela11.plano == "comunitaria", "se reserva un solar para una casa comunitaria")
	var an11 := Vector2i(int(parcela11.cama[0]), int(parcela11.cama[1]))
	ok(s11.plano(an11).piezas.size() > s11.cfg.vivienda.casa.piezas.size() - 1 and s11.habitat.area(an11, "comunitaria").size.x > s11.habitat.area(an11, "casa").size.x, "el plano comunitario es mayor que el de una casa")
	var camas11 := 1
	for e in s11.plano(an11).piezas: if e.p == "cama_huesped": camas11 += 1
	ok(camas11 == 3, "la casa comunitaria tiene tres plazas")
	o11.mundo.poner(an11, "cama_huesped", true)
	for paso in s11._celdas_casa(an11):
		if paso[0] == "techo": o11.mundo.techar(paso[1], "grupo:talleres")
		elif o11.mundo.puede_poner(paso[1]) == "": o11.mundo.poner(paso[1], "muro" if paso[0] == "muro_ladrillo" else paso[0], true)
	for d in s11.plano(an11).base:
		var wc := an11 + Vector2i(int(d[0]), int(d[1]))
		if o11.mundo.puede_poner(wc) == "": o11.mundo.poner(wc, "muro", true)
	ok(s11.casa_completa(an11), "la casa comunitaria completa se reconoce con su plano")
	ok(o11.vivo.camas_libres_lista().size() == 3, "sus tres camas quedan libres para quien duerme al raso")
	var cama_extra := an11 + Vector2i(1, 0)
	ok(s11.habitat.es_pieza_ajena(cama_extra) and not s11.habitat.es_pieza_ajena(an11), "las camas extra son plazas de la casa, no viviendas propias")
	# Persistencia y regreso: la identidad, la deuda y las relaciones sobreviven a marcharse, guardar, cargar y volver.
	var q = nuevo()
	var sq = q.autonomia.sociedad
	rico(q)
	sq.datos().llegada_min = -99999
	sq._inmigrar()
	var qid: String = q.d.mundo_vivo.autonomia.colonos.keys()[0]
	var bq: Dictionary = q.autonomia.perfil(qid).biografia
	bq.antecedente = "deuda"
	bq.con = "ordal"
	sq.arraigo.vincular(qid)
	q.autonomia.estado(qid).inv = {"madera": 2}
	q.d.min += 1440 * 2
	sq.arraigo._marchar(qid)
	ok(sq.arraigo.estado(qid) == "ausente" and not q.habitantes.ids.has(qid), "el colono con deuda se marcha")
	ok(sq.arraigo.relevante(qid), "quien se marcha con una deuda abierta es relevante para el aviso")
	var antes_q := huella(q, qid)
	ok(q.guardar("/tmp/linde-arraigo-q.json"), "guarda con un ausente")
	var cq = J.cargar("/tmp/linde-arraigo-q.json")
	ok(cq != null and cq.d.size() > 0, "carga la partida con el ausente")
	if cq != null and cq.d.size() > 0:
		ok(huella(cq, qid) == antes_q, "biografía, deuda, vínculos, inventario y recuerdos del ausente son idénticos tras cargar")
		ok(cq.autonomia.sociedad.arraigo.estado(qid) == "ausente" and not cq.habitantes.ids.has(qid), "sigue ausente tras cargar")
		var nombre_q: String = cq.habitantes.fichas[qid].n
		cq.autonomia.sociedad.arraigo._cambiar(qid, "visitante")
		cq.vivo.restaurar().vars[qid + "_presente"] = true
		cq.habitantes.reconciliar()
		ok(cq.habitantes.ids.has(qid) and cq.habitantes.fichas[qid].n == nombre_q and cq.autonomia.perfil(qid).biografia.has("deuda"), "al regresar es la misma persona, con su deuda y su historia")
	var pp = nuevo()
	var sp = pp.autonomia.sociedad
	rico(pp)
	sp.datos().llegada_min = -99999
	sp._inmigrar()
	var pid: String = pp.d.mundo_vivo.autonomia.colonos.keys()[0]
	var antes_p := huella(pp, pid)
	pp.guardar("/tmp/linde-arraigo-p.json")
	var cp = J.cargar("/tmp/linde-arraigo-p.json")
	ok(cp != null and cp.d.size() > 0 and huella(cp, pid) == antes_p, "un colono presente conserva todo tras guardar y cargar")
	print("ARRAIGO: %d comprobaciones, %d fallos" % [total, fallos])
	quit(1 if fallos else 0)
