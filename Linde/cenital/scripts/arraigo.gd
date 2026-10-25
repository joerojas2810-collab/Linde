extends RefCounted
## Arraigo de los colonos: vínculo práctico entre una persona y el valle. Orienta si se queda o se marcha; no lo obliga.
## Estados: visitante -> aspirante -> residente, y ausente (fuera del valle, conserva identidad, inventario y recuerdos).
## Se evalúa una vez por día de juego desde Sociedad.actualizar(); los colonos anteriores a este sistema cuentan como residentes.
const DIMENSIONES := ["sustento", "seguridad", "relaciones", "oportunidades", "condiciones", "historia"]
const TRABAJO := ["fabricacion", "construccion", "entrega", "venta", "aporte"]
var s
var j
var a
var cfg: Dictionary

func _init(sociedad) -> void:
	s = sociedad
	j = s.j
	a = s.a
	cfg = s.cfg.arraigo

func _colonos() -> Dictionary:
	return j.d.mundo_vivo.autonomia.get("colonos", {})

## Ficha de permanencia de un colono nuevo.
func nueva() -> Dictionary:
	return {"estado": "visitante", "desde": int(j.d.min), "llegada": int(j.d.min), "descontento": 0}

func estado(nid: String) -> String:
	return str(_colonos().get(nid, {}).get("permanencia", {}).get("estado", "residente"))

## Cada dimensión en 0..1 para este habitante.
func dimensiones(nid: String) -> Dictionary:
	var n: Dictionary = a.estado(nid)
	var p: Dictionary = _colonos().get(nid, {}).get("permanencia", {})
	var d := {}
	d.sustento = clampf(float(n.inv.get(a.reglas.comida, 0)) / float(maxi(1, s.reserva_comida(nid))), 0.0, 1.0)
	d.seguridad = clampf((s.seguridad() - float(s.cfg.inmigracion.seguridad_minima)) / (1.0 - float(s.cfg.inmigracion.seguridad_minima)), 0.0, 1.0)
	var suma := 0.0
	var cuenta := 0
	for k in n.vinculos:
		var v: Dictionary = n.vinculos[k]
		if str(k).begins_with("npc:"): suma += (float(v.get("confianza", 0)) - float(s.cfg.confianza_min)) / float(int(s.cfg.confianza_max) - int(s.cfg.confianza_min))
		else: suma += 0.5 + 0.1 * minf(5.0, float(v.get("ayudas", 0)))
		cuenta += 1
	d.relaciones = suma / cuenta if cuenta > 0 else 0.5
	var hechos := 0
	for e in s.datos().sucesos:
		if e.quien == nid and e.tipo in TRABAJO and int(j.d.min) - int(e.min) < 2880: hechos += 1
	d.oportunidades = clampf(float(hechos) / 3.0, 0.2, 1.0)
	var cama: Vector2i = j.habitantes.cama(nid)
	d.condiciones = 0.35 if cama == Vector2i(-1, -1) else (1.0 if s.casa_completa(cama) else 0.7)
	d.historia = clampf(float(int(j.d.min) - int(p.get("llegada", j.d.min))) / 1440.0 / float(cfg.dias_historia), 0.0, 1.0)
	return d

## Pesos por dimensión: cada persona valora distinto; su motivación multiplica los pesos base.
func pesos(nid: String) -> Dictionary:
	var w: Dictionary = cfg.pesos.duplicate()
	var mot: String = bio(nid).get("motivacion", "")
	var def: Dictionary = s.cfg.biografia.motivaciones.get(mot, {})
	for k in def.get("pesos", {}): w[k] = float(w.get(k, 1.0)) * float(def.pesos[k])
	return w

func bio(nid: String) -> Dictionary:
	return s.a.perfil(nid).get("biografia", {})

func _sortear(rng: RandomNumberGenerator, ids: Array, pesos: Array) -> String:
	var total := 0.0
	for w in pesos: total += w
	var x := rng.randf() * total
	for i in ids.size():
		x -= float(pesos[i])
		if x <= 0.0: return ids[i]
	return ids.back()

## Biografía de un colono: ids que apuntan a los textos de reglas.sociedad.biografia. `otros`: habitantes existentes a quienes puede referirse (los antecedentes con persona solo salen si hay alguno).
func biografia(rng: RandomNumberGenerator, caracter: Dictionary, otros: Array) -> Dictionary:
	var cb: Dictionary = s.cfg.biografia
	var origenes: Array = cb.origenes.keys()
	origenes.sort()
	var ants: Array = cb.antecedentes.keys().filter(func(k): return not otros.is_empty() or not cb.antecedentes[k].get("persona", false))
	ants.sort()
	var mots: Array = cb.motivaciones.keys()
	mots.sort()
	var pesos_mot: Array = []
	for m in mots:
		var def: Dictionary = cb.motivaciones[m]
		pesos_mot.append(maxf(0.1, float(def.get("base", 1.0)) + float(caracter.get(def.get("carac", ""), 50)) / 100.0 * float(def.get("factor", 0.0))))
	var mot := _sortear(rng, mots, pesos_mot)
	var asp: Array = cb.motivaciones[mot].aspiraciones
	var bio := {"origen": origenes[rng.randi() % origenes.size()], "antecedente": ants[rng.randi() % ants.size()], "motivacion": mot, "aspiracion": asp[rng.randi() % asp.size()], "cumplidas": []}
	if cb.antecedentes[bio.antecedente].get("persona", false):
		var cand: Array = otros.duplicate()
		cand.sort()
		bio["con"] = cand[rng.randi() % cand.size()]
	return bio

## Habitantes presentes a quienes un recién llegado puede haber conocido.
func candidatos(excepto: String = "") -> Array:
	return j.habitantes.ids.filter(func(k): return k != excepto and not a.perfil(k).is_empty())

## Siembra la relación previa de un colono nuevo con la persona de su antecedente: sus efectos se ven en confianza, trato y recuerdos.
func vincular(nid: String) -> void:
	var b := bio(nid)
	var con: String = b.get("con", "")
	if con == "" or not j.habitantes.fichas.has(con): return
	var rel: String = s.cfg.biografia.antecedentes[b.antecedente].get("relacion", "")
	var def: Dictionary = s.cfg.biografia.relaciones.get(rel, {})
	if def.is_empty(): return
	s._vinculo(nid, con, int(def.yo))
	s._vinculo(con, nid, int(def.el))
	if rel == "deuda": b["deuda"] = {"item": def.item, "cantidad": int(def.cantidad)}
	a._recordar(con, "reconocio", "a " + j.habitantes.fichas[nid].n + " (" + rel + ")", nid)
	a._recordar(nid, "reconocio", "a " + j.habitantes.fichas[con].n + " (" + rel + ")", con)

## Quien debe, paga en cuanto tiene con qué: la deuda saldada devuelve parte de la confianza.
func _deuda(nid: String) -> void:
	var b := bio(nid)
	var deuda: Dictionary = b.get("deuda", {})
	var con: String = b.get("con", "")
	if deuda.is_empty() or not j.habitantes.ids.has(con): return
	var inv: Dictionary = a.estado(nid).inv
	if int(inv.get(deuda.item, 0)) < int(deuda.cantidad): return
	a._quitar(inv, deuda.item, int(deuda.cantidad))
	s._anadir(a.estado(con).inv, {deuda.item: int(deuda.cantidad)})
	var rel: Dictionary = s.cfg.biografia.relaciones.deuda
	s._vinculo(nid, con, int(rel.saldada[0]))
	s._vinculo(con, nid, int(rel.saldada[1]))
	b.erase("deuda")
	s.suceso("deuda", "saldó lo que debía", nid, con)
	a._recordar(con, "cobro", "la deuda de " + j.habitantes.fichas[nid].n, nid)

## Una línea legible: de dónde viene, qué le pasó y qué busca.
func resumen(nid: String) -> String:
	var b := bio(nid)
	if b.is_empty(): return ""
	var cb: Dictionary = s.cfg.biografia
	var ant: String = cb.antecedentes.get(b.antecedente, {}).get("texto", "")
	if "%s" in ant: ant = ant % j.habitantes.fichas.get(b.get("con", ""), {}).get("n", "alguien")
	var t: String = "%s. %s." % [cb.origenes.get(b.origen, ""), ant]
	var asp: String = cb.aspiraciones.get(b.get("aspiracion", ""), {}).get("texto", "")
	if asp != "": t += " Quiere " + asp + "."
	return t

## ¿Se cumplió la aspiración actual? Solo las que el mundo puede comprobar; las demás siguen abiertas.
func _cumplida(nid: String, id: String) -> bool:
	match str(s.cfg.biografia.aspiraciones.get(id, {}).get("cumple", "")):
		"cama": return j.habitantes.cama(nid) != Vector2i(-1, -1)
		"casa": return s.casa_completa(j.habitantes.cama(nid))
		"herramientas":
			var nec: Array = a.perfil(nid).get("herramientas_necesarias", [])
			for h in nec: if int(a.estado(nid).inv.get(h, 0)) <= 0: return false
			return not nec.is_empty()
		"confianza":
			var altos := 0
			for k in a.estado(nid).vinculos: if int(a.estado(nid).vinculos[k].get("confianza", 0)) >= int(s.cfg.biografia.umbral_confianza): altos += 1
			return altos > 0
		"seguridad": return s.seguridad() >= 1.0 and j.habitantes.cama(nid) != Vector2i(-1, -1)
	return false

## Si la aspiración se cumple, se registra y pasa a otra de su motivación: no repite el mismo objetivo.
func _aspiracion(nid: String) -> void:
	var b := bio(nid)
	if b.is_empty() or b.get("aspiracion", "") == "" or not _cumplida(nid, b.aspiracion): return
	var texto: String = s.cfg.biografia.aspiraciones[b.aspiracion].texto
	b.cumplidas.append(b.aspiracion)
	s.suceso("logro", "consiguió " + texto.replace("conseguir ", "").replace("abrir ", "").replace("reunir ", "").replace("ganarse a ", "").replace("encontrar ", ""), nid)
	a._recordar(nid, "logro", texto)
	var restantes: Array = s.cfg.biografia.motivaciones[b.motivacion].aspiraciones.filter(func(k): return not k in b.cumplidas)
	if restantes.is_empty(): restantes = s.cfg.biografia.aspiraciones.keys().filter(func(k): return not k in b.cumplidas)
	restantes.sort()
	b.aspiracion = restantes[0] if not restantes.is_empty() else ""

func valor(nid: String) -> float:
	var d := dimensiones(nid)
	var w := pesos(nid)
	var num := 0.0
	var den := 0.0
	for k in DIMENSIONES:
		num += float(w.get(k, 1.0)) * float(d[k])
		den += float(w.get(k, 1.0))
	return num / den if den > 0.0 else 0.0

## La dimensión que más pesa en la insatisfacción: el motivo que se dice al marcharse.
func motivo(nid: String) -> String:
	var d := dimensiones(nid)
	var peor := "oportunidades"
	for k in DIMENSIONES:
		if float(d[k]) < float(d[peor]): peor = k
	return peor

func _cambiar(nid: String, nuevo: String) -> void:
	var p: Dictionary = _colonos()[nid].permanencia
	p.estado = nuevo
	p.desde = int(j.d.min)
	p.descontento = 0

## Una pasada diaria sobre los colonos: orden estable, sin recalcular nada más.
func evaluar_dia() -> void:
	var colonos := _colonos()
	var claves: Array = colonos.keys()
	claves.sort()
	for nid in claves:
		if j.habitantes.ids.has(nid):
			_aspiracion(nid)
			_deuda(nid)
		var p: Dictionary = colonos[nid].get("permanencia", {})
		if p.is_empty(): continue
		var dias: int = floori(float(int(j.d.min) - int(p.desde)) / 1440.0)
		match str(p.estado):
			"visitante":
				if dias < int(cfg.dias_visita): continue
				var v := valor(nid)
				if v >= float(cfg.umbral_aspirar):
					_cambiar(nid, "aspirante")
					s.suceso("aspiracion", "piensa quedarse en el valle", nid)
				elif v < float(cfg.umbral_partir) or dias >= int(cfg.dias_max_visita): _marchar(nid)
			"aspirante", "residente":
				var v := valor(nid)
				if p.estado == "aspirante" and v >= float(cfg.umbral_residir):
					_cambiar(nid, "residente")
					s.suceso("establecimiento", "se establece en el valle", nid)
					a._recordar(nid, "establecio", "El valle es mi hogar")
				elif v < float(cfg.umbral_partir):
					p.descontento = int(p.get("descontento", 0)) + 1
					if int(p.descontento) >= int(cfg.dias_paciencia): _marchar(nid)
				else: p.descontento = 0
			"ausente": _regresar(nid, dias)

## Quién merece aviso a los jugadores: residentes, y quien tiene trato con algún jugador (ayudas) o una deuda abierta. Del resto queda solo el registro de sucesos.
func relevante(nid: String) -> bool:
	if estado(nid) == "residente" or not bio(nid).get("deuda", {}).is_empty(): return true
	for k in a.estado(nid).vinculos:
		if not str(k).begins_with("npc:") and int(a.estado(nid).vinculos[k].get("ayudas", 0)) > 0: return true
	return false

## Deja el valle sin dejar de existir: la ficha, el inventario y los recuerdos se conservan.
func _marchar(nid: String) -> void:
	if s._ocupado(nid) != "": return   # un acuerdo en curso se cumple antes de irse
	var causa := motivo(nid)
	var avisar := relevante(nid)   # se decide antes de cambiar de estado
	_cambiar(nid, "ausente")
	_colonos()[nid].permanencia.motivo = causa
	j.vivo.restaurar().vars[nid + "_presente"] = false
	j.habitantes.reconciliar()
	a._recordar(nid, "partio", causa)
	s.suceso("partida", causa, nid)
	if avisar: j.aviso_todos("%s se marcha del valle." % j.habitantes.fichas[nid].n)

func _regresar(nid: String, dias: int) -> void:
	if dias < int(cfg.dias_ausencia_min) or j.habitantes.ids.size() >= int(s.cfg.inmigracion.max_habitantes): return
	if s.presion() < float(s.cfg.inmigracion.presion_minima): return
	if j._rng("regreso", "%s:%d" % [nid, int(j.d.min)]).randf() >= float(cfg.prob_regreso): return
	_cambiar(nid, "visitante")
	j.vivo.restaurar().vars[nid + "_presente"] = true
	j.habitantes.reconciliar()
	a._recordar(nid, "regreso", "al valle")
	s.suceso("regreso", "vuelve al valle", nid)
	if relevante(nid): j.aviso_todos("%s regresa al valle." % j.habitantes.fichas[nid].n)
