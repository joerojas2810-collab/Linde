extends RefCounted
# Habitantes: necesidades -> actividad deseada -> ruta (BFS) -> ejecución. Simulación local mientras corre el juego.
# Rutina y necesidades salen de la ficha npc del paquete de datos (mundo_datos.gd; design/gdd/mundo-vivo.md, Interactions).
# Energía: tasas, umbral y rango de la ficha (PROVISIONAL, propio; no se heredan tasas de MineWorld).
# Actividades: dormir (cama), trabajar/socializar (celda del lugar), descansar sin destino (descansa donde está).
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
const Mundo = preload("res://scripts/mundo.gd")
const MundoDatos = preload("res://scripts/mundo_datos.gd")
const VEL := 24.0     # px/s; no está en la ficha del Atlas (pendiente de decidir si pasa a datos)
const CON_LUGAR := ["trabajar", "socializar", "explorar"]    # actividades que exigen un destino con celda (explorar = trabajar)
const Aspecto = preload("res://scripts/aspecto.gd")

var j
var _paq: Dictionary
var fichas := {}      # id -> {n, cama, nec, franjas: [{desde, hasta, act, lugar}], lugares: {lugar: celda}}
var _inicial: Array = []   # ids presentes desde el inicio (no cuentan como «llegados»)
var ids: Array = []   # habitantes presentes desde el inicio, en orden estable
var errores: Array = []    # rutinas bloqueadas (o paquete rechazado): mensaje con habitante, campo y motivo
var rutas := {}

## `paq`: paquete ya cargado (por defecto el de la sesión, MundoDatos.paquete()).
func _init(juego, paq: Dictionary = {}) -> void:
	j = juego
	_paq = paq if not paq.is_empty() else MundoDatos.paquete()
	if _paq.error != "":
		_fallo("paquete rechazado: " + _paq.error)
		return
	var vars: Dictionary = _paq.entidades.variable_mundo
	for id in _paq.entidades.npc:
		var v: Dictionary = vars.get(id + "_presente", {})    # sin variable de presencia = presente (Maren)
		var e := _ficha(id, _paq.entidades.npc[id])
		if e == "":
			if v.is_empty() or v.data.inicial:
				ids.append(id)
				_inicial.append(id)
		else:
			_fallo("habitante «%s»: %s" % [id, e])

func _fallo(msg: String) -> void:
	errores.append(msg)
	push_error(msg)

# "" si la rutina es ejecutable; si no, el campo y el motivo (esa rutina queda bloqueada: el habitante no se crea).
func _ficha(id: String, npc: Dictionary) -> String:
	var d: Dictionary = npc.data
	var nec: Array = d.necesidades.filter(func(x): return x.id == "energia")
	if nec.is_empty(): return "data.necesidades: falta «energia»"
	var f := {"n": npc.name, "nec": nec[0], "franjas": [], "lugares": {}}
	for i in d.horario.size():
		var fr: Dictionary = d.horario[i]
		var act: String = fr.actividad
		var lugar: String = "" if fr.destino == null else fr.destino.id
		if act in CON_LUGAR:
			if lugar == "": return "data.horario[%d].destino: «%s» exige un lugar" % [i, act]
			var c = _paq.entidades.lugar[lugar].data.get("celda")
			if c == null: return "data.horario[%d].destino: el lugar «%s» no tiene celda" % [i, lugar]
			f.lugares[lugar] = Vector2i(int(c.x), int(c.y))
		else:
			lugar = ""
		f.franjas.append({"desde": int(fr.desde_minuto), "hasta": int(fr.hasta_minuto), "act": act, "lugar": lugar})
	if f.lugares.is_empty(): return "data.horario: ningún destino donde colocarlo"
	fichas[id] = f
	return ""

## Estado inicial de un habitante: en el primer lugar de su rutina, con la energía inicial de su ficha.
func nuevo(id: String) -> Dictionary:
	var f: Dictionary = fichas[id]
	var fr: Dictionary = f.franjas.filter(func(x): return x.lugar != "")[0]
	var p := Mundo.pies_de_celda(f.lugares[fr.lugar])
	return {"pos": [p.x, p.y], "energia": float(f.nec.inicial), "act": fr.act}   # compartido; la relación es por jugador (d.jugadores[id].relacion)

## Crea los habitantes que falten en d.npcs (partida nueva o antigua sin ellos) y, para los nuevos, su cama si la celda sigue libre.
func restaurar() -> void:
	for id in ids:
		if not j.d.npcs.has(id):
			j.d.npcs[id] = nuevo(id)
			var lecho: Vector2i = cama(id)
			if j.mundo.constr_en(lecho).is_empty() and j.mundo.puede_poner(lecho) == "": j.mundo.poner(lecho, "cama", false)
		rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}
	reconciliar()    # presentes por variable sin habitante (p. ej. partida guardada tras una llegada)

## Cama del habitante: la fija de su pueblo (hoy solo el inicial) o la de huésped que se le asignó al llegar. (-1,-1) si no tiene.
func cama(id: String) -> Vector2i:
	var fijas: Dictionary = j.mundo.camas(Mundo.ID_INICIAL)
	if fijas.has(id): return fijas[id]
	var asig: Dictionary = j.d.mundo_vivo.camas_asignadas
	for k in asig: if asig[k] == id: return Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
	return Vector2i(-1, -1)

## Mismo contrato visual que el PJ; cada habitante conserva su identidad visual.
func aspecto(id: String) -> Array:
	return Aspecto.npc(id)

## Reconcilia la presencia (design/gdd/mundo-vivo.md regla 12-14): todo `<id>_presente` true con ficha tiene habitante.
## Idempotente. Un recién llegado nace en la entrada del pueblo inicial (`Mundo.entrada(Mundo.ID_INICIAL)`) y recibe la primera cama de huésped libre (j.vivo.camas_libres_lista()).
func reconciliar() -> void:
	var mv: Dictionary = j.vivo.restaurar()
	_cargar_colonos()
	for id in ids.duplicate():   # quien se marchó deja de estar presente, pero su ficha, inventario y recuerdos se conservan
		if id.begins_with("colono_") and mv.vars.get(id + "_presente", true) == false:
			ids.erase(id)
			j.d.npcs.erase(id)
			rutas.erase(id)
			for k in mv.camas_asignadas.keys(): if mv.camas_asignadas[k] == id: mv.camas_asignadas.erase(k)
	for id in fichas:
		if not mv.vars.get(id + "_presente", id in ids): continue
		if not id in ids: ids.append(id)
		if not rutas.has(id): rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}   # también al cargar una partida con llegados
		if j.d.npcs.has(id): continue
		if cama(id) == Vector2i(-1, -1):
			var libres: Array = j.vivo.camas_libres_lista()
			if not libres.is_empty(): mv.camas_asignadas[libres[0]] = id   # sin cama libre llega igual y duerme al raso
		var n: Dictionary = nuevo(id)
		var p: Vector2 = Mundo.pies_de_celda(j.mundo.entrada(Mundo.ID_INICIAL))   # todos llegan al pueblo inicial; luego, al que reciba al colono
		n.pos = [p.x, p.y]
		j.d.npcs[id] = n
		rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}
		if not id in mv.llegados and not id in _inicial: mv.llegados.append(id)

## Reparte las camas libres entre quienes duermen al raso (orden estable). Devuelve cuántas asignó.
func asignar_camas() -> int:
	var mv: Dictionary = j.vivo.restaurar()
	var hechas := 0
	if j.autonomia != null and j.autonomia.sociedad.activa():   # primero las viviendas planificadas para alguien concreto
		for p in j.autonomia.sociedad.habitat.datos().parcelas.values():
			var antes: int = mv.camas_asignadas.size()
			j.autonomia.sociedad.reclamar_cama(p)
			hechas += mv.camas_asignadas.size() - antes
	for id in ids:
		if cama(id) != Vector2i(-1, -1): continue
		var libres: Array = j.vivo.camas_libres_lista()
		if libres.is_empty(): break
		mv.camas_asignadas[libres[0]] = id
		hechas += 1
	return hechas

## Recrea las fichas de los colonos llegados en esta partida (se guardan enteras en mundo_vivo.autonomia.colonos; el cliente también las recibe).
func _cargar_colonos() -> void:
	var colonos: Dictionary = j.d.get("mundo_vivo", {}).get("autonomia", {}).get("colonos", {})
	for id in colonos:
		if not fichas.has(id): registrar_colono(id, colonos[id].npc)

## Registra la ficha de un habitante generado en tiempo de ejecución ("" si es válida, o el motivo).
func registrar_colono(id: String, npc: Dictionary) -> String:
	var e := _ficha(id, npc)
	if e != "": _fallo("colono «%s»: %s" % [id, e])
	return e

func pos(id: String) -> Vector2:
	var a: Array = j.d.npcs[id].pos
	return Vector2(a[0], a[1])

## Franja que toca ahora: {act, lugar, desde, hasta}. Si la energía está bajo el umbral de la ficha, prevalece dormir.
func deseada(id: String) -> Dictionary:
	var base := rutina(id)
	if base.act in ["dormir", "descansar"] or j.autonomia == null: return base
	var plan: Dictionary = j.autonomia.plan(id)
	if plan.get("quieto", false): return {"act": "descansar", "lugar": ""}
	if plan.has("celda"): return {"act": plan.act, "lugar": "autonomia", "celda": plan.celda}
	return base

## Horario y energía conservan la prioridad sobre el trabajo autónomo.
func rutina(id: String) -> Dictionary:
	var f: Dictionary = fichas[id]
	if j.d.npcs[id].energia < f.nec.umbral_descanso: return {"act": "dormir", "lugar": ""}
	var m: int = int(j.d.min) % 1440
	for fr in f.franjas: if m >= fr.desde and m < fr.hasta: return fr
	return f.franjas[0]    # inalcanzable: el cargador exige que las franjas cubran el día

func cama_existe(id: String) -> bool:
	return j.mundo.constr_en(cama(id)).get("t", "") in ["cama", "cama_huesped"]

func _meta(id: String, d: Dictionary) -> Callable:
	if d.has("celda"):
		var objetivo := Vector2i(int(d.celda[0]), int(d.celda[1]))
		return func(c): return j.mundo.es_adyacente(c, objetivo)
	if d.act == "dormir":
		var lecho: Vector2i = cama(id)
		return func(c): return j.mundo.es_adyacente(c, lecho)
	var t: Vector2i = fichas[id].lugares[d.lugar]
	return func(c): return c == t

const DESCANSO_AL_RASO := 0.5   # ponytail: fijo; a datos si se afina el balance

func paso(dt: float) -> void:
	var horas: float = dt * C.MIN_POR_SEG / 60.0
	for id in ids:
		var f: Dictionary = fichas[id]
		var nec: Dictionary = f.nec
		var n: Dictionary = j.d.npcs[id]
		var r: Dictionary = rutas[id]
		var d := deseada(id)
		var act: String = d.act
		var gasto: float = nec.cambio_por_hora_activo * horas
		var recupera: float = nec.cambio_por_hora_descanso * horas
		if act == "dormir" and j.autonomia != null and j.autonomia.activa() and j.autonomia.sociedad.casa_completa(cama(id)): recupera *= float(j.autonomia.sociedad.plano(cama(id)).bono_descanso)
		if act == "dormir" and not cama_existe(id):
			n.act = "sin_cama"   # duerme al raso donde está: recupera menos que en una cama
			n.energia = clampf(n.energia + recupera * DESCANSO_AL_RASO, nec.minimo, nec.maximo)
			continue
		if act == "descansar":    # sin destino: descansa donde está
			n.act = act
			n.energia = clampf(n.energia + recupera, nec.minimo, nec.maximo)
			r.ruta = []
			r.act = ""
			continue
		var p := pos(id)
		var c := Mundo.celda_de(p)
		var meta := _meta(id, d)
		if meta.call(c):
			n.act = act
			n.energia = clampf(n.energia + (recupera if act == "dormir" else gasto), nec.minimo, nec.maximo)
			r.ruta = []
			continue
		n.energia = clampf(n.energia + gasto, nec.minimo, nec.maximo)
		var clave: String = act + ":" + d.lugar + str(d.get("celda", []))
		if r.act != clave or r.v != j.mundo.version:
			r.ruta = j.mundo.camino(c, meta, Mundo.AREA_EXPEDICION if j.autonomia != null and j.autonomia.expediciones() else Rect2i())
			r.act = clave
			r.v = j.mundo.version
			r.i = 1
			r.fallo = r.ruta.is_empty()
		if r.fallo or r.i >= r.ruta.size():
			n.act = "bloqueado"
			continue
		n.act = "camina"
		var dest := Mundo.pies_de_celda(r.ruta[r.i])
		var paso_px: float = VEL * dt
		if p.distance_to(dest) <= paso_px:
			p = dest
			r.i += 1
		else:
			p += (dest - p).normalized() * paso_px
		n.pos = [p.x, p.y]

## Coloca a cada habitante según su rutina actual (junto a su cama si toca dormir). Ya no la llama dormir():
## el reloj no salta, así que nadie debe teletransportarse. Disponible para quien salte el reloj.
func resincronizar() -> void:
	for id in ids:
		var d := deseada(id)
		var c: Vector2i = cama(id) + Vector2i(0, 1) if d.act == "dormir" else (fichas[id].lugares[d.lugar] if d.lugar != "" else Mundo.celda_de(pos(id)))
		var p := Mundo.pies_de_celda(c)
		j.d.npcs[id].pos = [p.x, p.y]
		j.d.npcs[id].energia = maxf(j.d.npcs[id].energia, 60.0)
		rutas[id] = {"act": "", "ruta": [], "v": -1, "i": 0, "fallo": false}
