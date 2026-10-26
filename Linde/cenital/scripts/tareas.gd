extends RefCounted
## Contrato aditivo del trabajo material. El inventario y las reservas siguen en Sociedad.
var a
var visitados := {} # marca transitoria de la decisión, nunca se serializa
func _init(autonomia) -> void:
	a = autonomia

func datos() -> Dictionary:
	var d: Dictionary = a.j.d.mundo_vivo.autonomia
	if not d.has("trabajo"): d.trabajo = {"version": 1, "secuencia": 0, "activos": {}, "resultados": []}
	return d.trabajo

func iniciar(nid: String, meta: Dictionary) -> void:
	if not a.j.es_autoridad(): return
	var d := datos()
	var t: Dictionary = d.activos.get(nid, {})
	if not t.is_empty() and (t.demanda.get("item", "") != meta.get("item", "") or t.demanda.get("motivo", "") != meta.get("motivo", "")):
		cancelar(nid, "cambio_de_necesidad")
		t = {}
	if t.is_empty():
		d.secuencia = int(d.secuencia) + 1
		t = {"id": int(d.secuencia), "actor": nid, "demanda": meta.duplicate(true), "desde": int(a.j.d.min), "estado": "reclamada", "recurso": ""}
		d.activos[nid] = t
	t.demanda = meta.duplicate(true)
	t.estado = "reclamada"
	t.recurso = ""

func disponible(nid: String, oid: String) -> bool:
	for actor in datos().activos:
		if actor != nid and datos().activos[actor].get("recurso", "") == oid: return false
	return true

func reclamar(nid: String, oid: String) -> bool:
	if not a.j.es_autoridad() or not disponible(nid, oid): return false
	if datos().activos.has(nid): datos().activos[nid].recurso = oid
	return true

func resultado(nid: String, antes: Dictionary, viable: bool) -> void:
	if not a.j.es_autoridad() or not datos().activos.has(nid): return
	var t: Dictionary = datos().activos[nid]
	var delta := {}
	var inv: Dictionary = a.estado(nid).inv
	var items := antes.keys()
	for item in inv:
		if not item in items: items.append(item)
	for item in items:
		var cambio := int(inv.get(item, 0)) - int(antes.get(item, 0))
		if cambio != 0: delta[item] = cambio
	if not delta.is_empty():
		_archivar(t, "efecto_material", delta)
		t.recurso = ""
	if not viable:
		t.estado = "bloqueada"
		t.recurso = ""
		if t.get("causa", "") != "sin_opcion_factible": _archivar(t, "sin_opcion_factible", {})
		t.causa = "sin_opcion_factible"
	else:
		t.erase("causa")
		# Una acción intermedia puede producir insumos sin satisfacer todavía el objetivo.
		var item: String = t.demanda.get("item", "")
		if item != "" and int(delta.get(item, 0)) >= int(t.demanda.get("cantidad", 1)):
			_archivar(t, "completada", {})
			datos().activos.erase(nid)

func cancelar(nid: String, causa: String) -> void:
	if not a.j.es_autoridad() or not datos().activos.has(nid): return
	_archivar(datos().activos[nid], causa, {})
	datos().activos.erase(nid) # libera el reclamo; no toca reservas de acuerdos ajenos

func _archivar(t: Dictionary, causa: String, delta: Dictionary) -> void:
	var lista: Array = datos().resultados
	lista.append({"tarea": t.id, "actor": t.actor, "demanda": t.demanda.duplicate(true), "min": int(a.j.d.min), "causa": causa, "recurso": t.get("recurso", ""), "delta": delta})
	while lista.size() > int(a.reglas.tope_recuerdos): lista.pop_front()
