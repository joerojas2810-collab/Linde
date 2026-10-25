extends RefCounted
## Producción, acuerdos con garantía, metas alternativas, confianza y grupos.
## No simula en clientes. Inventarios, compromisos y relaciones son estado persistente.
const C = preload("res://scripts/catalogos.gd")
const M = preload("res://scripts/mundo.gd")
const Inv = preload("res://scripts/inventario.gd")
var a
var j
var cfg: Dictionary
var habitat
const Habitat = preload("res://scripts/habitat.gd")

func _init(autonomia) -> void:
	a = autonomia
	j = a.j
	cfg = a.reglas.sociedad
	habitat = Habitat.new(self)

func activa() -> bool:
	return a.activa() and bool(cfg.activa) and j.d.mundo_vivo.autonomia.get("modo", "sociedad") == "sociedad"

## Migración aditiva de partidas de la primera prueba, sin borrar recuerdos ni reservas.
func restaurar() -> void:
	if not activa(): return
	var d: Dictionary = datos()
	for gid in cfg.grupos:
		if not d.grupos.has(gid): d.grupos[gid] = {"inv": {}, "reputacion": {}}
	var colonos: Dictionary = j.d.mundo_vivo.autonomia.get("colonos",{})
	for nid in colonos:
		var colono: Dictionary = colonos[nid]
		if colono.perfil.has("identidad"): continue
		_personalizar_colono(colono.npc,colono.perfil,j._rng("identidad",nid))
		colono.perfil.oficio = colono.perfil.get("oficio","habitante")
		j.habitantes.registrar_colono(nid,colono.npc)
	for nid in j.habitantes.ids:
		if not a.perfil(nid).is_empty(): a.estado(nid)

func datos() -> Dictionary:
	var mundo: Dictionary = j.d.mundo_vivo.autonomia
	if not mundo.has("sociedad"):
		mundo.sociedad = {"version": 2, "grupos": {}, "acuerdos": {}, "siguiente": 1, "sucesos": [], "estaciones": {}, "estadisticas": {}}
	if not mundo.sociedad.has("estadisticas"): mundo.sociedad.estadisticas = {}
	return mundo.sociedad

func grupo(gid: String) -> Dictionary:
	var d: Dictionary = datos()
	if not d.grupos.has(gid): d.grupos[gid] = {"inv": {}, "reputacion": {}}
	return d.grupos[gid]

func grupo_de(nid: String) -> String:
	return str(a.perfil(nid).get("grupo", ""))

## Disposición moral del habitante (honestidad, codicia, rencor; 0-100). Sin perfil usa el valor por defecto de las reglas.
func caracter(nid: String) -> Dictionary:
	var c: Dictionary = cfg.caracter.defecto.duplicate()
	c.merge(a.perfil(nid).get("caracter", {}), true)
	return c

## Azar repetible por habitante, motivo y minuto: la misma partida decide igual al repetirse.
## El valor baja con la abundancia global; pagos y bienes usan la misma escala.
func valor(item: String) -> float:
	var base := float(cfg.valor_items.get(item,1))
	if item != str(cfg.moneda_trueque): return base
	var cantidad := 0
	for nid in j.habitantes.ids: cantidad += int(a.estado(nid).inv.get(item,0))
	for cf in j.d.cofres.values(): cantidad += int(cf.inv.get(item,0))
	for gid in cfg.grupos: cantidad += int(grupo(gid).inv.get(item,0))
	var objetivo: float = float(cfg.economia.fibra_objetivo_persona) * maxi(1,j.habitantes.ids.size())
	return base * clampf(objetivo / maxf(objetivo,cantidad),float(cfg.economia.valor_minimo),1.0)

## Mantenimiento de ropa y lecho: consume fibra una vez por periodo y mejora el descanso.
func _mantener(nid: String) -> bool:
	var n: Dictionary = a.estado(nid)
	var periodo := floori(float(j.d.min) / float(cfg.economia.intervalo_mantenimiento))
	if not n.has("mantenimiento_periodo"):
		n.mantenimiento_periodo = periodo
		return false
	if int(n.mantenimiento_periodo) >= periodo: return false
	var coste := int(cfg.economia.fibra_mantenimiento)
	var cid := cofre_propio(nid)
	var ahorro: Dictionary = j.d.cofres.get(cid,{"inv":{}}).inv
	var disponible := maxi(0,int(n.inv.get("fibra",0))-int(cfg.economia.fibra_reserva))
	if disponible + int(ahorro.get("fibra",0)) < coste:
		n.mantenimiento_periodo = periodo
		return false
	var llevado := mini(coste,disponible)
	if llevado<coste and not _ir(nid,_celda_cofre(cid),"guardar","renovar mi ropa y lecho"): return true
	a._quitar(n.inv,"fibra",llevado)
	a._quitar(ahorro,"fibra",coste-llevado)
	n.mantenimiento_periodo = periodo
	j.d.npcs[nid].energia = minf(100.0,float(j.d.npcs[nid].energia)+8.0)
	a._recordar(nid,"mantenimiento","Renové mi ropa y lecho con %d fibras" % coste)
	suceso("mantenimiento","Renovó ropa y lecho con %d fibras" % coste,nid)
	return true

func _proteger(nid: String) -> bool:
	var cid := cofre_propio(nid)
	if cid == "" or bool(j.d.cofres[cid].get("candado",false)): return false
	if j.d.cofres[cid].inv.is_empty(): return false
	if a.estado(nid).inv.has("candado"): return _instalar_candado(nid,cid)
	var coste: Dictionary = cfg.proteccion.coste
	if not Inv.tiene(a.estado(nid).inv,coste): return false
	var mesa: String = a._estacion(nid,"mesa")
	if mesa == "": return _construir_estacion(nid,"mesa",[])
	if int(datos().estaciones.get(mesa,0)) >= int(cfg.desgaste_estacion_max):
		if int(a.estado(nid).inv.get(cfg.material_reparacion,0)) < int(cfg.coste_reparacion): return _obtener(nid,str(cfg.material_reparacion),int(cfg.coste_reparacion),[],"reparar la mesa")
		if not _ir(nid,_celda_cofre(mesa),"reparar","reparar la mesa"): return true
		a._quitar(a.estado(nid).inv,str(cfg.material_reparacion),int(cfg.coste_reparacion))
		datos().estaciones[mesa]=0
		suceso("reparacion","Reparó la mesa antes de hacer un candado",nid)
		return true
	if not _ir(nid,_celda_cofre(mesa),"fabricar","fabricar mi candado"): return true
	datos().estaciones[mesa]=int(datos().estaciones.get(mesa,0))+1
	if not _cerca(nid,_celda_cofre(cid)):
		# Se fabrica primero; el objeto viaja en el inventario hasta el cofre.
		if not a.estado(nid).inv.has("candado"):
			Inv.quitar(a.estado(nid).inv,coste)
			_anadir(a.estado(nid).inv,{"candado":1})
		return _instalar_candado(nid,cid)
	Inv.quitar(a.estado(nid).inv,coste)
	j.d.cofres[cid].candado=true
	j.d.cofres[cid].cerrado=true
	suceso("proteccion","Protegió su cofre con un candado",nid)
	return true

func _instalar_candado(nid: String, cid: String) -> bool:
	if not _ir(nid,_celda_cofre(cid),"guardar","colocar un candado"): return true
	a._quitar(a.estado(nid).inv,"candado",1)
	j.d.cofres[cid].candado=true
	j.d.cofres[cid].cerrado=true
	suceso("proteccion","Protegió su cofre con un candado",nid)
	return true

func _azar(nid: String, clave: String) -> float:
	return j._rng("caracter", "%s:%s:%d" % [nid, clave, int(j.d.min)]).randf()

func suceso(tipo: String, detalle: String, quien: String = "", otro: String = "") -> void:
	var d: Dictionary = datos()
	d.estadisticas[tipo] = int(d.estadisticas.get(tipo, 0)) + 1
	var lista: Array = d.sucesos
	lista.append({"min": int(j.d.min), "tipo": tipo, "detalle": detalle, "quien": quien, "otro": otro})
	while lista.size() > int(cfg.tope_sucesos): lista.pop_front()

func confianza(nid: String, otro: String) -> int:
	return int(a.estado(nid).vinculos.get("npc:" + otro, {}).get("confianza", cfg.confianza_inicial))

func _vinculo(nid: String, otro: String, delta: int) -> void:
	if delta < 0: delta = -ceili(float(-delta) * (1.0 + float(caracter(nid).rencor) / 100.0))   # quien guarda rencor pierde más confianza
	var n: Dictionary = a.estado(nid)
	var clave := "npc:" + otro
	var v: Dictionary = n.vinculos.get(clave, {})
	v["confianza"] = clampi(confianza(nid, otro) + delta, int(cfg.confianza_min), int(cfg.confianza_max))
	n.vinculos[clave] = v

func reputacion(gid: String, actor: String) -> int:
	return int(grupo(gid).reputacion.get(actor, 0))

func _reputacion(gid: String, actor: String, delta: int) -> void:
	if gid == "": return
	grupo(gid).reputacion[actor] = clampi(reputacion(gid, actor) + delta, int(cfg.confianza_min), int(cfg.confianza_max))

func _relacion_grupos(uno: String, otro: String, delta: int) -> void:
	if uno == otro or uno == "" or otro == "": return
	_reputacion(uno, "grupo:" + otro, delta)
	_reputacion(otro, "grupo:" + uno, delta)

func nombre_grupo(gid: String) -> String:
	return str(cfg.grupos.get(gid, {}).get("nombre", gid))

func _cerca(nid: String, celda: Vector2i) -> bool:
	var pos: Vector2i = M.celda_de(j.habitantes.pos(nid))
	return pos == celda or j.mundo.es_adyacente(pos, celda)

func _ir(nid: String, celda: Vector2i, actividad: String, motivo: String) -> bool:
	var plan := {"act": actividad, "celda": [celda.x, celda.y], "motivo": motivo}
	a.estado(nid).plan = plan
	return _cerca(nid, celda)

func _ancla(gid: String) -> Vector2i:
	var c: Array = cfg.grupos[gid].deposito
	return Vector2i(int(c[0]), int(c[1]))

## Reserva personal para no negociar comida indispensable o la última herramienta propia.
## Insumos destinados a un proyecto no se ofrecen en otro acuerdo mientras se reúnen.
func comprometer(nid: String, lote: Dictionary) -> void:
	var n: Dictionary = a.estado(nid)
	var reserva_actual: Dictionary = n.get("comprometido",{})
	if int(n.get("compromiso_hasta",0))<=int(j.d.min): reserva_actual={}
	for item in lote: reserva_actual[item]=maxi(int(reserva_actual.get(item,0)),int(lote[item]))
	n.comprometido=reserva_actual
	n.compromiso_hasta=int(j.d.min)+int(cfg.plazo_acuerdo_min)

func reserva_comida(nid: String) -> int:
	var identidad: Dictionary = a.perfil(nid).get("identidad",{})
	return int(a.reglas.reserva_comida) + (int(identidad.get("reserva_extra",0)) if identidad.get("preferencia","")=="alimentos" else 0)

func reserva(nid: String, item: String) -> int:
	if item == str(a.reglas.comida): return reserva_comida(nid)
	if item in a.perfil(nid).get("herramientas_necesarias", []): return 1
	var receta: Dictionary = C.RECETAS[a.perfil(nid).receta]
	var base: int = 1 if receta.sal.has(item) else int(receta.ent.get(item, 0))
	if base > 0: base += floori(float(caracter(nid).codicia) / 100.0 * float(cfg.caracter.acaparar_max))   # solo el muy codicioso acapara lo que usa
	var n: Dictionary = a.estado(nid)
	if int(n.get("compromiso_hasta",0))>int(j.d.min): base=maxi(base,int(n.get("comprometido",{}).get(item,0)))
	return base

func excedente(nid: String, item: String) -> int:
	return maxi(0, int(a.estado(nid).inv.get(item, 0)) - reserva(nid, item))

func usar_herramienta(nid: String, tag: String) -> void:
	if tag == "": return
	var n: Dictionary = a.estado(nid)
	for item in n.inv.keys():
		if C.ITEMS.get(item, {}).get("tag", "") != tag: continue
		n.durabilidad[item] = int(n.durabilidad.get(item, cfg.durabilidad_herramienta)) - 1
		if int(n.durabilidad[item]) <= 0:
			a._quitar(n.inv, item, 1)
			n.durabilidad.erase(item)
			a._recordar(nid, "herramienta_rota", C.ITEMS[item].n)
			suceso("desgaste", item, nid)
		return

func reparar_herramienta(nid: String, item: String) -> bool:
	var n: Dictionary = a.estado(nid)
	if not n.inv.has(item) or int(n.inv.get(cfg.material_reparacion, 0)) < int(cfg.coste_reparacion): return false
	if int(n.durabilidad.get(item, cfg.durabilidad_herramienta)) >= int(cfg.durabilidad_herramienta): return false
	a._quitar(n.inv, cfg.material_reparacion, int(cfg.coste_reparacion))
	n.durabilidad[item] = int(cfg.durabilidad_herramienta)
	a._recordar(nid, "reparo", C.ITEMS[item].n)
	suceso("reparacion", item + " con un lingote", nid)
	return true

func _herramienta_para(nid: String, def: Dictionary) -> String:
	var mejor := 9999
	var tag_mejor := ""
	for tag in def.golpes:
		if tag == "" and int(def.golpes[tag]) < mejor:
			mejor = int(def.golpes[tag]); tag_mejor = ""
		for item in a.estado(nid).inv:
			if C.ITEMS.get(item, {}).get("tag", "") == tag and tag != "" and int(def.golpes[tag]) < mejor:
				mejor = int(def.golpes[tag]); tag_mejor = tag
	return tag_mejor

func golpes(nid: String, def: Dictionary) -> int:
	var tag := _herramienta_para(nid, def)
	var necesarios := int(def.golpes.get(tag, 9999))
	if tag != "":
		var menos := 0
		for item in a.estado(nid).inv: if C.ITEMS.get(item, {}).get("tag", "") == tag: menos = maxi(menos, int(C.ITEMS[item].get("menos", 0)))
		necesarios = maxi(1, necesarios - menos)
	if necesarios < 9999 and a.desarrollo != null and a.desarrollo.activa():
		necesarios = maxi(1, necesarios - mini(int(a.desarrollo.cfg.bonus_recoleccion_max), a.desarrollo.rango("npc:"+nid,"recoleccion")))
	return necesarios

## Territorialidad: se protege un recurso escaso o se restringe acceso por mala relación.
func propietario_recurso(oid: String) -> String:
	if not j.mundo.objetos.has(oid): return ""
	var o: Dictionary = j.mundo.objetos[oid]
	for gid in cfg.grupos:
		var g: Dictionary = cfg.grupos[gid]
		var t: Array = g.territorio
		if o.t in g.protegidos and Rect2i(int(t[0]), int(t[1]), int(t[2]), int(t[3])).has_point(o.c): return gid
	return ""

func permite_recurso(nid: String, oid: String) -> bool:
	var gid := propietario_recurso(oid)
	if gid == "" or gid == grupo_de(nid): return true
	if reputacion(gid, "grupo:" + grupo_de(nid)) < int(cfg.confianza_minima): return false
	if aliados(gid, grupo_de(nid)): return true   # los aliados comparten recursos protegidos
	var def: Dictionary = C.OBJETOS[j.mundo.objetos[oid].t]
	for item in def.drops:
		if int(grupo(gid).inv.get(item, 0)) < int(cfg.grupos[gid].reservas.get(item, 0)): return false
	return true

## Decisión colectiva (una vez al día): el líder de cada grupo fija el objetivo compartido y los líderes
## negocian entre sí. Honestos y de buena relación pactan alianza; mala relación sin mediación pasa a disputa.
func aliados(uno: String, otro: String) -> bool:
	return datos().get("alianzas", []).has("|".join(PackedStringArray([uno, otro]) if uno < otro else PackedStringArray([otro, uno])))

func _lider(gid: String) -> String:
	var mejor := ""
	var puntos := -99999
	for nid in j.habitantes.ids:
		if grupo_de(nid) != gid: continue
		var p := 0
		for otro in j.habitantes.ids:
			if otro != nid and grupo_de(otro) == gid: p += confianza(otro, nid)
		p = p * 10 + int(caracter(nid).honestidad)   # empate: el más honesto
		if p > puntos or (p == puntos and nid < mejor): mejor = nid; puntos = p
	return mejor

func decidir_grupos() -> void:
	var d: Dictionary = datos()
	if not d.has("alianzas"): d.alianzas = []
	var lideres := {}
	for gid in cfg.grupos:
		var g: Dictionary = grupo(gid)
		var lider := _lider(gid)
		lideres[gid] = lider
		if lider != "" and lider != g.get("lider", ""):
			g.lider = lider
			suceso("liderazgo", "%s lidera %s" % [j.habitantes.fichas[lider].n, nombre_grupo(gid)], lider, gid)
		var peor := ""   # objetivo compartido: la reserva del depósito más por debajo de lo previsto
		var falta := 0
		for item in cfg.grupos[gid].reservas:
			var f: int = int(cfg.grupos[gid].reservas[item]) - int(g.inv.get(item, 0))
			if f > falta: falta = f; peor = item
		if peor != g.get("objetivo", ""):
			g.objetivo = peor
			if peor != "": suceso("objetivo", "%s busca reunir %s" % [nombre_grupo(gid), C.ITEMS.get(peor, {}).get("n", peor)], lider, gid)
	var ids: Array = cfg.grupos.keys()
	ids.sort()
	for i in ids.size():
		for k in range(i + 1, ids.size()):
			var uno: String = ids[i]
			var otro: String = ids[k]
			var clave := "|".join(PackedStringArray([uno, otro]))
			var rel: int = reputacion(uno, "grupo:" + otro)
			var l1: String = lideres[uno]
			var l2: String = lideres[otro]
			if l1 == "" or l2 == "": continue
			var honestos: bool = int(caracter(l1).honestidad) >= int(cfg.caracter.umbral_hurto) and int(caracter(l2).honestidad) >= int(cfg.caracter.umbral_hurto)
			if d.alianzas.has(clave):
				if rel < int(cfg.alianza_umbral) - 2:
					d.alianzas.erase(clave)
					suceso("disputa", "%s y %s rompen su alianza" % [nombre_grupo(uno), nombre_grupo(otro)], l1, otro)
			elif rel >= int(cfg.alianza_umbral) and honestos:
				d.alianzas.append(clave)
				suceso("alianza", "%s y %s pactan una alianza" % [nombre_grupo(uno), nombre_grupo(otro)], l1, otro)
			elif rel < int(cfg.confianza_minima) and honestos and confianza(l1, l2) >= int(cfg.confianza_minima):
				_relacion_grupos(uno, otro, 1)   # mediación: líderes honestos que aún se fían suavizan la disputa
				suceso("mediacion", "%s y %s negocian y bajan la tensión" % [j.habitantes.fichas[l1].n, j.habitantes.fichas[l2].n], l1, l2)
			elif rel >= 0 and honestos:
				_relacion_grupos(uno, otro, 1)   # trato continuo mejora la relación

## Solo testigos cercanos conocen una extracción; no se difunde conocimiento mágico.
func observar_extraccion(actor: String, oid: String) -> void:
	if not activa(): return
	var gid := propietario_recurso(oid)
	if gid == "": return
	var c: Vector2i = j.mundo.objetos[oid].c
	var visto := false
	for nid in j.habitantes.ids:
		if grupo_de(nid) != gid: continue
		var pos := M.celda_de(j.habitantes.pos(nid))
		if Vector2(pos).distance_to(Vector2(c)) <= float(cfg.radio_testigo_celdas) and a.ve(pos, c):
			a._recordar(nid, "extraccion_vista", C.OBJETOS[j.mundo.objetos[oid].t].n, actor)
			visto = true
	if visto:
		_reputacion(gid, actor, int(cfg.reputacion_extraccion))
		suceso("conflicto", "Extracción observada en " + nombre_grupo(gid), actor, gid)
		j.aviso("Vieron tu extracción en %s; tu relación empeora." % nombre_grupo(gid), actor)

func reconoce_ayuda(nid: String, jugador: String) -> void:
	_reputacion(grupo_de(nid), jugador, int(cfg.reputacion_ayuda))
	suceso("ayuda", "Aporte recibido", jugador, nid)

## Recompensa acordada por una ayuda: paga con su excedente hasta una fracción del valor recibido.
## Cuanto más codicioso, menos paga; si confía poco o no le sobra nada, solo agradece.
func recompensa(nid: String, jugador: String, item: String, cantidad: int) -> Dictionary:
	var fraccion := clampf(1.0 - float(caracter(nid).codicia) / 100.0, float(cfg.caracter.recompensa_min), 1.0)
	var presupuesto := valor(item) * cantidad * fraccion
	var inv: Dictionary = a.estado(nid).inv
	var candidatos: Array = inv.keys()
	candidatos.sort()
	for it in candidatos:
		if it == item or excedente(nid, it) <= 0 or valor(it) <= 0.0: continue
		var q := mini(excedente(nid, it), floori(presupuesto / valor(it)))
		if q <= 0: continue
		a._quitar(inv, it, q)
		_anadir(j.jug(jugador).inv, {it: q})
		suceso("recompensa", "%s pagó %s por la ayuda" % [j.habitantes.fichas[nid].n, j._txt_items({it: q})], nid, jugador)
		return {it: q}
	return {}

## Aporte voluntario al depósito, con proximidad y carencia actual verificadas.
func aportar_grupo(gid: String, jugador: String) -> Dictionary:
	if not activa() or not cfg.grupos.has(gid): return j._no("Ese grupo no existe", jugador)
	if Vector2(M.celda_de(j.pies_de(jugador))).distance_to(Vector2(_ancla(gid))) > 2.0: return j._no("Acércate al depósito del grupo", jugador)
	for item in cfg.grupos[gid].reservas:
		var falta: int = int(cfg.grupos[gid].reservas[item]) - int(grupo(gid).inv.get(item, 0))
		var cantidad: int = mini(falta, int(j.jug(jugador).inv.get(item, 0)))
		if cantidad <= 0: continue
		a._quitar(j.jug(jugador).inv, item, cantidad)
		grupo(gid).inv[item] = int(grupo(gid).inv.get(item, 0)) + cantidad
		_reputacion(gid, jugador, cantidad * int(cfg.reputacion_ayuda))
		suceso("aporte", "%d %s" % [cantidad, item], jugador, gid)
		return j._ok("Aportas %d %s a %s" % [cantidad, C.ITEMS[item].n, nombre_grupo(gid)], jugador)
	return j._no("No llevas algo que el grupo necesite ahora", jugador)

func retirar_deposito(nid: String, item: String, cantidad: int) -> bool:
	var gid := grupo_de(nid)
	if gid == "" or cantidad <= 0 or not _cerca(nid, _ancla(gid)): return false
	if int(grupo(gid).inv.get(item, 0)) < cantidad: return false
	a._quitar(grupo(gid).inv, item, cantidad)
	a.estado(nid).inv[item] = int(a.estado(nid).inv.get(item, 0)) + cantidad
	suceso("retiro", "%d %s" % [cantidad, item], nid, gid)
	return true

func _depositar(nid: String) -> bool:
	var gid := grupo_de(nid)
	var g: Dictionary = grupo(gid)
	for item in cfg.grupos[gid].reservas:
		var disponible := excedente(nid,item)
		var receta: Dictionary = C.RECETAS[a.perfil(nid).receta]
		if receta.sal.has(item): disponible = maxi(0,int(a.estado(nid).inv.get(item,0))-int(a.perfil(nid).reserva_producto))
		var cantidad: int = mini(disponible, int(cfg.grupos[gid].reservas[item]) - int(g.inv.get(item, 0)))
		if cantidad <= 0: continue
		if _ir(nid, _ancla(gid), "depositar", "abastecer " + nombre_grupo(gid)):
			a._quitar(a.estado(nid).inv, item, cantidad)
			g.inv[item] = int(g.inv.get(item, 0)) + cantidad
			a._recordar(nid, "aporte", "%d %s" % [cantidad, item])
			suceso("aporte", "%d %s" % [cantidad, item], nid, gid)
		return true
	return false

func _ocupado(nid: String) -> String:
	for cid in datos().acuerdos:
		var c: Dictionary = datos().acuerdos[cid]
		if c.estado == "activo" and nid in [c.solicitante, c.proveedor]: return cid
	return ""

## Acuerdo voluntario: protege reservas, confianza y relación entre grupos; garantías reales.
func acordar(solicitante: String, proveedor: String, item: String, cantidad: int) -> String:
	if solicitante == proveedor or cantidad <= 0 or not j.habitantes.ids.has(solicitante) or not j.habitantes.ids.has(proveedor): return ""
	if _ocupado(solicitante) != "" or _ocupado(proveedor) != "": return ""
	if excedente(proveedor, item) < cantidad: return ""
	if confianza(proveedor, solicitante) < int(cfg.confianza_minima): return ""
	if confianza(solicitante, proveedor) < int(cfg.confianza_minima): return ""   # nadie compra a quien le falló
	var uno := grupo_de(solicitante)
	var otro := grupo_de(proveedor)
	if reputacion(otro, "grupo:" + uno) < int(cfg.confianza_minima): return ""
	var pago := {}
	if uno != otro:
		var recargo: float = 1.0 + float(caracter(proveedor).codicia) / 100.0 * float(cfg.caracter.sobreprecio_max)   # el codicioso cobra de más
		var restante: int = ceili(valor(item) * cantidad * recargo * 100.0)
		var claves: Array = a.estado(solicitante).inv.keys()
		claves.sort()
		for moneda in claves:
			if moneda == item or not cfg.valor_items.has(moneda): continue
			var precio: float = valor(moneda) * 100.0
			var unidades: int = mini(excedente(solicitante, moneda), ceili(float(restante) / precio))
			if unidades <= 0: continue
			pago[moneda] = unidades
			restante -= int(unidades * precio)
			if restante <= 0: break
		if restante > 0: return ""
	# Se reservan ambas partes antes de publicar el acuerdo. Ninguna puede volver a gastarse.
	a._quitar(a.estado(proveedor).inv, item, cantidad)
	for moneda in pago: a._quitar(a.estado(solicitante).inv, moneda, int(pago[moneda]))
	var d: Dictionary = datos()
	var cid := "acuerdo:%d" % int(d.siguiente)
	d.siguiente = int(d.siguiente) + 1
	d.acuerdos[cid] = {"solicitante": solicitante, "proveedor": proveedor, "bien": {item: cantidad}, "pago": pago, "estado": "activo", "vence": int(j.d.min) + int(cfg.plazo_acuerdo_min)}
	a._recordar(solicitante, "promesa", C.ITEMS[item].n, proveedor)
	a._recordar(proveedor, "promesa", C.ITEMS[item].n, solicitante)
	suceso("acuerdo", "%s a cambio de %s" % [a.j._txt_items({item:cantidad}), "ayuda mutua" if pago.is_empty() else a.j._txt_items(pago)], solicitante, proveedor)
	return cid

func _anadir(inv: Dictionary, lote: Dictionary) -> void:
	for item in lote: inv[item] = int(inv.get(item, 0)) + int(lote[item])

func riesgo_estafa(comprador: String, vendedor: String) -> float:
	var riesgo := (1.0-float(caracter(vendedor).honestidad)/100.0)*float(cfg.caracter.prob_estafa_max)
	# Perder una relación de confianza hace menos atractivo el engaño.
	return riesgo * clampf(1.0-float(maxi(0,confianza(comprador,vendedor)))*0.08,0.2,1.0)

func entregar(cid: String) -> bool:
	var c: Dictionary = datos().acuerdos.get(cid, {})
	if c.is_empty() or c.estado != "activo" or int(j.d.min) >= int(c.vence): return false
	if not j.habitantes.ids.has(c.solicitante) or not j.habitantes.ids.has(c.proveedor): return false
	if j.habitantes.pos(c.solicitante).distance_to(j.habitantes.pos(c.proveedor)) > j.ALCANCE_NPC: return false
	if not c.pago.is_empty() and _azar(c.proveedor, cid) < riesgo_estafa(c.solicitante,c.proveedor):
		_estafar(cid, c)
		return true
	_anadir(a.estado(c.solicitante).inv, c.bien)
	var recibidos := {}
	for item in c.bien: recibidos[item]=int(a.estado(c.solicitante).inv.get(item,0))
	comprometer(c.solicitante,recibidos)
	_anadir(a.estado(c.proveedor).inv, c.pago)
	a.desarrollo.observar("npc:"+c.solicitante,c.bien)
	a.desarrollo.observar("npc:"+c.proveedor,c.pago)
	c.estado = "cumplido"
	_vinculo(c.solicitante, c.proveedor, int(cfg.ganancia_confianza))
	_vinculo(c.proveedor, c.solicitante, int(cfg.ganancia_confianza))
	_relacion_grupos(grupo_de(c.solicitante), grupo_de(c.proveedor), int(cfg.ganancia_confianza))
	for nid in [c.solicitante, c.proveedor]: a._recordar(nid, "cumplio", a.j._txt_items(c.bien), c.proveedor if nid == c.solicitante else c.solicitante)
	suceso("entrega", a.j._txt_items(c.bien), c.solicitante, c.proveedor)
	return true

## Quien promete y no entrega se queda con lo prometido y con el pago; la víctima lo recuerda y deja de comerciar con él.
func _estafar(cid: String, c: Dictionary) -> void:
	_anadir(a.estado(c.proveedor).inv, c.bien)
	_anadir(a.estado(c.proveedor).inv, c.pago)
	c.estado = "estafado"
	_vinculo(c.solicitante, c.proveedor, -int(cfg.caracter.perdida_estafa))
	_relacion_grupos(grupo_de(c.solicitante), grupo_de(c.proveedor), -int(cfg.caracter.castigo_grupo_estafa))
	a._recordar(c.solicitante, "estafado", a.j._txt_items(c.bien), c.proveedor)
	a._recordar(c.proveedor, "estafo", a.j._txt_items(c.bien), c.solicitante)
	suceso("estafa", "No entregó %s y se quedó con el pago" % a.j._txt_items(c.bien), c.proveedor, c.solicitante)

## Con poca honestidad y sin otra vía, toma de un depósito ajeno. Solo los testigos cercanos del grupo lo saben.
func _hurtar(nid: String, item: String, cantidad: int) -> bool:
	var propio := grupo_de(nid)
	if int(a.estado(nid).get("proximo_hurto",0)) > int(j.d.min): return false
	for gid in cfg.grupos:
		if gid == propio or int(grupo(gid).inv.get(item, 0)) <= 0: continue
		var ancla := _ancla(gid)
		if not _ir(nid, ancla, "hurtar", "conseguir " + str(C.ITEMS.get(item, {}).get("n", item)) + " sin pedirlo"): return true
		var n: int = mini(mini(cantidad, int(cfg.caracter.hurto_max)), int(grupo(gid).inv[item]))
		a._quitar(grupo(gid).inv, item, n)
		_anadir(a.estado(nid).inv, {item: n})
		a.estado(nid).proximo_hurto = int(j.d.min)+int(cfg.proteccion.espera_hurto_min)
		var visto := false
		for otro in j.habitantes.ids:
			if otro == nid or grupo_de(otro) != gid: continue
			if Vector2(M.celda_de(j.habitantes.pos(otro))).distance_to(Vector2(ancla)) > float(cfg.radio_testigo_celdas): continue
			a._recordar(otro, "hurto_visto", "%d %s" % [n, item], nid)
			_vinculo(otro, nid, -int(cfg.caracter.perdida_estafa))
			visto = true
		if visto:
			_relacion_grupos(gid, propio, -int(cfg.caracter.castigo_hurto))
			_reputacion(gid, nid, -int(cfg.caracter.castigo_hurto))
		a._recordar(nid, "hurto", "%d %s" % [n, item], gid)
		suceso("hurto", "%d %s del depósito de %s%s" % [n, item, nombre_grupo(gid), " (lo vieron)" if visto else ""], nid, gid)
		return true
	var cofres: Array = j.d.cofres.keys()
	cofres.sort()
	for cid in cofres:   # también de cofres ajenos (de habitantes o de jugadores) si el dueño no está cerca
		if not str(cid).begins_with("c@") or int(j.d.cofres[cid].inv.get(item, 0)) <= 0: continue
		if bool(j.d.cofres[cid].get("cerrado",false)): continue
		var dueno: String = str(j.d.mundo.constr.get(str(cid).trim_prefix("c@"), {}).get("dueno", ""))
		if dueno == "" or dueno == "npc:" + nid or dueno == "grupo:" + propio: continue
		var celda := _celda_cofre(str(cid))
		if not M.es_valle(celda):continue # No ordenar hurtos sin planificación regional.
		var guardian := dueno.trim_prefix("npc:")
		if dueno.begins_with("npc:") and j.habitantes.ids.has(guardian) and _cerca(guardian, celda): continue
		var vigilado := false
		for pid in j.rt:
			if pid == dueno and Vector2(M.celda_de(j.pies_de(pid))).distance_to(Vector2(celda)) <= float(cfg.radio_testigo_celdas): vigilado = true
		if vigilado: continue
		if not _ir(nid, celda, "hurtar", "conseguir " + str(C.ITEMS.get(item, {}).get("n", item)) + " sin pedirlo"): return true
		var tomado: int = mini(mini(cantidad, int(cfg.caracter.hurto_max)), int(j.d.cofres[cid].inv[item]))
		a._quitar(j.d.cofres[cid].inv, item, tomado)
		_anadir(a.estado(nid).inv, {item: tomado})
		a._recordar(nid, "hurto", "%d %s" % [tomado, item], dueno)
		a.estado(nid).proximo_hurto = int(j.d.min)+int(cfg.proteccion.espera_hurto_min)
		observar_hurto_cofre(nid, str(cid), item, tomado)
		return true
	return false

## Vencer devuelve las garantías exactamente una vez; conserva el resultado y su causa.
func actualizar() -> void:
	restaurar()
	var d: Dictionary = datos()
	var dia: int = floori(float(j.d.min) / 1440.0)
	if dia > int(d.get("dia_perdon", dia)):   # el rencor se perdona con los días: cuanto más rencoroso, más despacio
		for nid in j.habitantes.ids:
			if a.perfil(nid).is_empty(): continue
			var cada: int = 1 + floori(float(caracter(nid).rencor) / float(cfg.caracter.rencor_dias_por_punto))
			if dia % cada != 0: continue
			var vinculos: Dictionary = a.estado(nid).vinculos
			for clave in vinculos:
				if str(clave).begins_with("npc:") and int(vinculos[clave].get("confianza", 0)) < 0: vinculos[clave].confianza = int(vinculos[clave].confianza) + 1
		decidir_grupos()
	d.dia_perdon = dia
	for cid in d.acuerdos:
		var c: Dictionary = d.acuerdos[cid]
		if c.estado != "activo" or int(j.d.min) < int(c.vence): continue
		_anadir(a.estado(c.proveedor).inv, c.bien)
		_anadir(a.estado(c.solicitante).inv, c.pago)
		c.estado = "vencido"
		_vinculo(c.proveedor, c.solicitante, -int(cfg.perdida_incumplimiento))
		_vinculo(c.solicitante, c.proveedor, -int(cfg.perdida_incumplimiento))
		_relacion_grupos(grupo_de(c.proveedor), grupo_de(c.solicitante), -int(cfg.perdida_incumplimiento))
		a._recordar(c.proveedor, "incumplio", "El acuerdo no se concretó a tiempo", c.solicitante)
		a._recordar(c.solicitante, "plazo_vencido", a.j._txt_items(c.bien), c.proveedor)
		suceso("incumplimiento", "Plazo vencido; materiales devueltos", c.solicitante, c.proveedor)
	var cerrados: Array = []
	for cid in d.acuerdos:
		if d.acuerdos[cid].estado != "activo": cerrados.append(cid)
	cerrados.sort_custom(func(x,y): return int(d.acuerdos[x].vence) < int(d.acuerdos[y].vence))
	while cerrados.size() > int(cfg.tope_acuerdos_cerrados): d.acuerdos.erase(cerrados.pop_front())
	if int(j.d.min) - int(d.get("inmigracion_min", -99999)) >= int(cfg.inmigracion.intervalo_min):
		d.inmigracion_min = int(j.d.min)
		_inmigrar()

func _plan_acuerdo(nid: String) -> bool:
	var cid := _ocupado(nid)
	if cid == "": return false
	var c: Dictionary = datos().acuerdos[cid]
	if entregar(cid):
		a.estado(nid).plan = {}
		return true
	if c.proveedor == nid:
		a.estado(nid).plan = {"act": "esperar", "quieto": true, "motivo": "entregar un compromiso"}
	else:
		_ir(nid, M.celda_de(j.habitantes.pos(c.proveedor)), "intercambiar", "cumplir un acuerdo")
	return true

## Metas derivadas del consumo, oficio, desgaste y reservas colectivas.
func objetivos(nid: String) -> Array:
	var n: Dictionary = a.estado(nid)
	var metas: Array = []
	var comida: String = a.reglas.comida
	if int(n.inv.get(comida,0)) < reserva_comida(nid): metas.append({"item":comida,"cantidad":reserva_comida(nid)-int(n.inv.get(comida,0)),"motivo":"alimentarme"})
	for herramienta in a.perfil(nid).get("herramientas_necesarias",[]):
		if not n.inv.has(herramienta): metas.append({"item":herramienta,"cantidad":1,"motivo":"poder trabajar"})
		elif int(n.durabilidad.get(herramienta,cfg.durabilidad_herramienta)) <= int(cfg.umbral_reparar):
			var falta: int = int(cfg.coste_reparacion) - int(n.inv.get(cfg.material_reparacion, 0))
			if falta > 0: metas.append({"item":cfg.material_reparacion,"cantidad":falta,"motivo":"reparar " + C.ITEMS[herramienta].n,"reparar":herramienta})
	for rid in n.get("recetas_nuevas", []):   # una herramienta mejor que ya puede fabricar con lo que lleva
		var mejora: String = C.RECETAS[rid].sal.keys()[0]
		var tag: String = C.ITEMS.get(mejora, {}).get("tag", "")
		var tiene_tag := false
		for h in a.perfil(nid).get("herramientas_necesarias",[]): tiene_tag = tiene_tag or C.ITEMS[h].get("tag","") == tag
		var conocidos := true
		for insumo in C.RECETAS[rid].ent: conocidos = conocidos and n.vistos.has(insumo)
		if tag != "" and tiene_tag and conocidos and not n.inv.has(mejora): metas.append({"item":mejora,"cantidad":1,"motivo":"mejorar mi herramienta"})
	for rid in n.get("recetas_nuevas", []):   # fundir o transformar lo que ya trajo
		var r: Dictionary = C.RECETAS[rid]
		var prod: String = r.sal.keys()[0]
		if not C.ITEMS.get(prod, {}).has("tag") and int(n.inv.get(prod, 0)) < 2 and Inv.tiene(n.inv, r.ent): metas.append({"item":prod,"cantidad":1,"motivo":"aprovechar lo que traje"})
	var receta: Dictionary = C.RECETAS[a.perfil(nid).receta]
	var producto: String = receta.sal.keys()[0]
	if int(n.inv.get(producto,0)) < int(a.perfil(nid).reserva_producto): metas.append({"item":producto,"cantidad":int(a.perfil(nid).reserva_producto)-int(n.inv.get(producto,0)),"motivo":"mantener mi oficio"})
	var gid := grupo_de(nid)
	for item in cfg.grupos[gid].reservas:
		var falta: int = int(cfg.grupos[gid].reservas[item])-int(grupo(gid).inv.get(item,0))
		if falta>0: metas.append({"item":item,"cantidad":falta,"motivo":"abastecer " + nombre_grupo(gid)})
	var cid := cofre_propio(nid)
	if cid!="" and not bool(j.d.cofres[cid].get("candado",false)) and not j.d.cofres[cid].inv.is_empty():
		for item in cfg.proteccion.coste:
			var falta := int(cfg.proteccion.coste[item])-int(n.inv.get(item,0))
			if falta>0: metas.append({"item":item,"cantidad":falta,"motivo":"proteger mis ahorros"})
	return metas

func necesidad(nid: String) -> Dictionary:
	var n: Dictionary = a.estado(nid)
	if not n.get("peticion", {}).is_empty():
		var p: Dictionary = n.peticion.duplicate()
		var reservados := 0
		for c in datos().acuerdos.values():
			if c.estado == "activo" and c.solicitante == nid: reservados += int(c.bien.get(p.item, 0))
		p.cantidad = maxi(0, int(p.get("objetivo_total", p.cantidad)) - int(n.inv.get(p.item, 0)) - reservados)
		return p if int(p.cantidad) > 0 else {}
	var metas := objetivos(nid)
	return metas[0] if not metas.is_empty() else {}

func _posponer(nid: String, item: String, motivo: String) -> void:
	a.estado(nid).bloqueos[item] = int(j.d.min) + int(cfg.reintento_min)
	a._recordar(nid, "pospuso", C.ITEMS.get(item,{}).get("n",item) + ": " + motivo)
	suceso("alternativa", "Pospuso " + item + ": " + motivo, nid)

func decidir(nid: String) -> void:
	var n: Dictionary = a.estado(nid)
	n.peticion = {}
	if n.hambre >= float(a.reglas.umbral_comer) and _cosechar(nid): return
	if _plan_acuerdo(nid): return
	for herramienta in a.perfil(nid).get("herramientas_necesarias",[]):
		if int(n.durabilidad.get(herramienta,cfg.durabilidad_herramienta)) <= int(cfg.umbral_reparar) and reparar_herramienta(nid,herramienta): return
	var urgente: bool = n.hambre >= float(a.reglas.umbral_comer)
	if not urgente and _mantener(nid): return
	if not urgente and _cosechar(nid): return
	# Terminar una vivienda pendiente antes de ampliar talleres o abrir más obras.
	if not urgente and _casa(nid): return
	if not urgente and _refugio(nid): return
	if not urgente and _sembrar(nid): return
	if not urgente and _vivienda(nid): return
	if not urgente and a.desarrollo.decidir(nid): return
	if not urgente and _proteger(nid): return
	if not urgente and _acumular(nid): return
	for meta in objetivos(nid):
		if not urgente and str(meta.motivo).begins_with("abastecer ") and _depositar(nid): return
		var item: String = meta.item
		if int(n.bloqueos.get(item,-1)) > int(j.d.min): continue
		n.objetivo = meta.motivo
		if _obtener(nid,item,int(meta.cantidad),[],meta.motivo): return
		_posponer(nid,item,"sin ruta, existencias o acuerdo viable")
		if urgente and item == str(a.reglas.comida): break
	if not urgente and _prospectar(nid): return
	if not urgente and _depositar(nid): return
	n.plan = a._pedir(nid,"buscar otra solución")

## Campos de cultivo del grupo (celdas), en orden estable.
func _campos(gid: String) -> Array:
	var l: Array = []
	for k in j.d.mundo.constr:
		var cs: Dictionary = j.d.mundo.constr[k]
		if cs.t == "campo" and cs.get("dueno", "") == "grupo:" + gid: l.append(Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1))))
	l.sort()
	return l

## Va al campo maduro de su grupo y lo cosecha. true si ya está en ello.
func _cosechar(nid: String) -> bool:
	for c in _campos(grupo_de(nid)):
		if not j.campo_listo(c) or j.mundo.camino(M.celda_de(j.habitantes.pos(nid)), func(z): return z == c or j.mundo.es_adyacente(z, c)).is_empty(): continue
		if _ir(nid, c, "recolectar", "cosechar el campo"):
			var cosecha: Dictionary = j.cosechar(c)
			if not cosecha.is_empty():
				_anadir(a.estado(nid).inv, cosecha)
				a.desarrollo.registrar("npc:" + nid, "recoleccion", cosecha)
				a._recordar(nid, "cosecho", j._txt_items(cosecha))
		return true
	return false

## Con semilla y fibra de sobra, el grupo labra un campo junto a su depósito.
func _sembrar(nid: String) -> bool:
	var gid := grupo_de(nid)
	var miembros:=0
	for otro in j.habitantes.ids:
		if grupo_de(otro)==gid:miembros+=1
	var objetivo_campos:=maxi(int(cfg.economia.campos_por_grupo),ceili(float(miembros)/2.0))
	if _campos(gid).size() >= objetivo_campos: return false
	var n: Dictionary = a.estado(nid)
	if float(n.hambre) >= float(a.reglas.umbral_comer) * 0.5: return false
	for item in C.CONSTR.campo.coste:   # la semilla sale de su reserva de comida: es una inversión, la repondrá después
		var libre: int = int(n.inv.get(item, 0)) if item == str(a.reglas.comida) else excedente(nid, item)
		if libre < int(C.CONSTR.campo.coste[item]): return false
	return _construir_cerca(nid, "campo", [], Vector2i(-1, -1), "grupo:" + gid)

## Sin metas pendientes, prueba un recurso que nunca ha tenido (así aparecen recetas nuevas).
func _prospectar(nid: String) -> bool:
	var n: Dictionary = a.estado(nid)
	var tipos: Array = C.OBJETOS.keys()
	tipos.sort()
	for tipo in tipos:
		for item in C.OBJETOS[tipo].drops:
			if n.vistos.has(item) or int(n.bloqueos.get(item, -1)) > int(j.d.min): continue
			var oid: String = a._recurso(nid, item)
			if oid != "":
				n.objetivo = "probar un recurso nuevo"
				return _recolectar(nid, oid, "probar un recurso nuevo")
			n.bloqueos[item] = int(j.d.min) + int(cfg.reintento_min)
	return false

func _obtener(nid: String, item: String, cantidad: int, cadena: Array, motivo: String) -> bool:
	if cadena.size()>8: return false
	var n: Dictionary = a.estado(nid)
	var gid := grupo_de(nid)
	n.peticion = {"item":item,"cantidad":cantidad,"objetivo_total":int(n.inv.get(item,0))+cantidad,"motivo":motivo}
	# Compartir es una acción física; nunca una transferencia global automática.
	if motivo!="mantener mi oficio" and not motivo.begins_with("abastecer ") and int(grupo(gid).inv.get(item,0)) > 0:
		if _ir(nid,_ancla(gid),"compartir","retirar materiales del grupo"):
			retirar_deposito(nid,item,mini(cantidad,int(grupo(gid).inv[item])))
		return true
	var proveedores: Array = j.habitantes.ids.duplicate()
	proveedores.sort_custom(func(x,y):
		var gx: bool = grupo_de(x) == gid
		var gy: bool = grupo_de(y) == gid
		if gx != gy: return gx
		return confianza(nid,x)>confianza(nid,y) if confianza(nid,x)!=confianza(nid,y) else x<y)
	for otro in proveedores:
		if motivo=="mantener mi oficio" or otro==nid or excedente(otro,item)<=0 or confianza(nid,otro)<int(cfg.confianza_minima): continue
		for lote in range(mini(cantidad,excedente(otro,item)),0,-1):
			var cid := acordar(nid,otro,item,lote)
			if cid!="": _plan_acuerdo(nid);return true
	# Oficios con recetas explícitas: fabricar requiere insumos y estación reales.
	var receta_id := ""
	for rid in a.recetas_de(nid):
		if C.RECETAS[rid].sal.has(item): receta_id=rid;break
	if receta_id!="" and not cadena.has(item):
		var r: Dictionary=C.RECETAS[receta_id]
		var nueva: Array=cadena+[item]
		comprometer(nid,r.ent)
		for entrada in r.ent:
			var falta: int=int(r.ent[entrada])-int(n.inv.get(entrada,0))
			if falta>0: return _obtener(nid,entrada,falta,nueva,"fabricar " + C.ITEMS[item].n)
		if r.est!="":
			var estacion: String=a._estacion(nid,r.est)
			if estacion=="": return _construir_estacion(nid,r.est,nueva)
			var c:=Vector2i(int(estacion.get_slice(",",0)),int(estacion.get_slice(",",1)))
			if int(datos().estaciones.get(estacion,0)) >= int(cfg.desgaste_estacion_max):
				if int(n.inv.get(cfg.material_reparacion,0))<int(cfg.coste_reparacion): return _obtener(nid,cfg.material_reparacion,int(cfg.coste_reparacion),nueva,"mantener la estación")
				if _ir(nid,c,"reparar","mantener la estación"):
					a._quitar(n.inv,cfg.material_reparacion,int(cfg.coste_reparacion));datos().estaciones[estacion]=0
					suceso("reparacion","Estación con un lingote",nid)
				return true
			if not _ir(nid,c,"fabricar","fabricar " + C.ITEMS[item].n): return true
			if not Inv.tiene(n.inv,r.ent): return false
			datos().estaciones[estacion]=int(datos().estaciones.get(estacion,0))+1
		if not Inv.tiene(n.inv,r.ent): return false
		Inv.quitar(n.inv,r.ent);_anadir(n.inv,r.sal)
		n.comprometido={}
		n.peticion={}
		var materiales: Dictionary = r.ent.duplicate()
		materiales.merge(r.sal,true)
		a.desarrollo.registrar("npc:"+nid,"artesania",materiales)
		a._recordar(nid,"fabrico",j._txt_items(r.sal))
		suceso("fabricacion",j._txt_items(r.sal),nid)
		return true
	if item == str(a.reglas.comida) and _cosechar(nid): return true
	var oid: String=a._recurso(nid,item)
	if oid!="": return _recolectar(nid,oid,motivo)
	# Si necesita comprar, intenta reunir un bien de trueque en lugar de esperar indefinidamente.
	var moneda: String=cfg.moneda_trueque
	if item!=moneda and int(n.inv.get(moneda,0)) < mini(int(cfg.economia.fibra_objetivo_persona),ceili(valor(item)*(1.0+float(cfg.caracter.sobreprecio_max))/valor(moneda))+reserva(nid,moneda)):
		var recurso: String=a._recurso(nid,moneda)
		if recurso!="": return _recolectar(nid,recurso,"preparar un intercambio")
	if int(caracter(nid).honestidad)<int(cfg.caracter.umbral_hurto) and _hurtar(nid,item,cantidad): return true
	return false

func _recolectar(nid: String, oid: String, motivo: String) -> bool:
	var o: Dictionary=j.mundo.objetos[oid]
	if not permite_recurso(nid,oid): return false
	if not _ir(nid,o.c,"recolectar",motivo): return true
	var def: Dictionary=C.OBJETOS[o.t]
	var golpe: int=int(j.d.mundo.golpes.get(oid,0))+1
	var necesarios:=golpes(nid,def)
	if necesarios>=9999:return false
	usar_herramienta(nid,_herramienta_para(nid,def))
	if golpe<necesarios:
		j.d.mundo.golpes[oid]=golpe;return true
	var drops: Dictionary=def.drops.duplicate()
	var rng=j._rng("sociedad","%s:%s:%d"%[nid,oid,j.d.min])
	for prob in def.prob:
		if rng.randf()<prob.p:drops[prob.item]=int(drops.get(prob.item,0))+int(prob.q)
	if drops.has("fibra"):
		var limite := int(cfg.economia.fibra_objetivo_persona)
		var cid := cofre_propio(nid)
		var almacenado := int(a.estado(nid).inv.get("fibra",0))+int(j.d.cofres.get(cid,{"inv":{}}).inv.get("fibra",0))
		drops.fibra = mini(int(drops.fibra),maxi(0,limite-almacenado))
		if int(drops.fibra)==0: drops.erase("fibra")
	_anadir(a.estado(nid).inv,drops)
	j.mundo.romper(oid,j.d.min)
	a.desarrollo.registrar("npc:"+nid,"recoleccion",drops)
	a._recordar(nid,"recolecto",j._txt_items(drops))
	return true

func permite_estacion(nid: String, clave: String) -> bool:
	var dueno: String=j.d.mundo.constr[clave].get("dueno","")
	if not dueno.begins_with("grupo:"):return true
	var gid:=dueno.trim_prefix("grupo:")
	return gid==grupo_de(nid) or reputacion(gid,"grupo:"+grupo_de(nid))>=int(cfg.confianza_minima)

func _construir_estacion(nid: String, tipo: String, cadena: Array) -> bool:
	var pieza: String=""
	for t in C.CONSTR:
		if C.CONSTR[t].get("est","")==tipo:pieza=t;break
	if pieza=="":return false
	return _construir_cerca(nid,pieza,cadena)

## Reúne los materiales y construye la pieza junto al depósito del grupo, validando rutas. true = sigue en ello o la construyó.
func _construir_cerca(nid: String, pieza: String, cadena: Array, centro_p: Vector2i = Vector2i(-1, -1), dueno: String = "") -> bool:
	var n: Dictionary=a.estado(nid)
	comprometer(nid,C.CONSTR[pieza].coste)
	for item in C.CONSTR[pieza].coste:
		var falta: int=int(C.CONSTR[pieza].coste[item])-int(n.inv.get(item,0))
		if falta>0:return _obtener(nid,item,falta,cadena,"construir " + C.CONSTR[pieza].n)
	var centro: Vector2i=_ancla(grupo_de(nid)) if centro_p==Vector2i(-1,-1) else centro_p
	for radio in range(1,int(cfg.radio_construccion)+1):
		for y in range(centro.y-radio,centro.y+radio+1):
			for x in range(centro.x-radio,centro.x+radio+1):
				var c:=Vector2i(x,y)
				if M.ESENCIALES.has(c) or c == centro or j.mundo.puede_poner(c)!="" or j.ocupada(c) or not habitat.permite_pieza(c,pieza):continue
				if j.mundo.camino(M.celda_de(j.habitantes.pos(nid)),func(z):return j.mundo.es_adyacente(z,c)).is_empty():continue
				if not _ir(nid,c,"construir","construir " + C.CONSTR[pieza].n):return true
				if construir_pieza(nid,pieza,c,dueno):return true
	return false

## Construir valida huella, coste, ocupación y rutas de todos antes de consumir materiales.
func construir_estacion(nid: String, pieza: String, c: Vector2i) -> bool:
	if not C.CONSTR.has(pieza) or C.CONSTR[pieza].get("est","")=="": return false
	return construir_pieza(nid,pieza,c)

## También permite suelo de ampliación, con las mismas validaciones y materiales.
func construir_pieza(nid: String, pieza: String, c: Vector2i, dueno: String = "") -> bool:
	if not C.CONSTR.has(pieza) or not _cerca(nid,c) or not habitat.permite_pieza(c,pieza):return false
	var n: Dictionary=a.estado(nid)
	if pieza == "techo":   # el techo va aparte de las piezas: no bloquea ni cambia las rutas
		if not Inv.tiene(n.inv,C.CONSTR.techo.coste) or j.mundo.puede_techar(c)!="":return false
		j.mundo.techar(c,dueno if dueno!="" else "grupo:"+grupo_de(nid))
		Inv.quitar(n.inv,C.CONSTR.techo.coste)
		n.comprometido={}
		a.desarrollo.registrar("npc:"+nid,"construccion",C.CONSTR.techo.coste)
		a._recordar(nid,"construyo",C.CONSTR.techo.n)
		suceso("construccion",C.CONSTR.techo.n,nid,grupo_de(nid))
		return true
	if not Inv.tiene(n.inv,C.CONSTR[pieza].coste) or M.ESENCIALES.has(c) or j.mundo.puede_poner(c)!="" or j.ocupada(c):return false
	j.mundo.poner(c,pieza,false,dueno if dueno!="" else "grupo:"+grupo_de(nid))
	j.sembrar(c)
	var alc: Dictionary=j.mundo.alcanzables()
	var valido:=true
	for e in M.ESENCIALES:
		if not alc.has(e):valido=false
	for gid in cfg.grupos:
		if not alc.has(_ancla(gid)): valido=false
	for otro in j.habitantes.ids:
		if not alc.has(M.celda_de(j.habitantes.pos(otro))):valido=false
	for jugador in j.rt:
		if M.es_valle(M.celda_de(j.pies_de(jugador))) and not alc.has(M.celda_de(j.pies_de(jugador))):valido=false
	if not valido:j.mundo.quitar(c);return false
	Inv.quitar(n.inv,C.CONSTR[pieza].coste)
	n.comprometido={}
	if C.CONSTR[pieza].get("cofre",false): j.d.cofres["c@"+M.clave(c)]={"inv":{}}
	a.desarrollo.registrar("npc:"+nid,"construccion",C.CONSTR[pieza].coste)
	a._recordar(nid,"construyo",C.CONSTR[pieza].n)
	suceso("construccion",C.CONSTR[pieza].n,nid,grupo_de(nid))
	return true

## Nombre legible de un actor o dueño: habitante, jugador o grupo.
func _nombre(id: String) -> String:
	var k := id.trim_prefix("npc:")
	if j.habitantes.fichas.has(k): return str(j.habitantes.fichas[k].n)
	if j.d.jugadores.has(id): return str(j.d.jugadores[id].nombre)
	return nombre_grupo(id.trim_prefix("grupo:"))

func _celda_cofre(cid: String) -> Vector2i:
	var clave := cid.trim_prefix("c@")
	return Vector2i(int(clave.get_slice(",", 0)), int(clave.get_slice(",", 1)))

## Cofre que pertenece al habitante ("" si aún no tiene).
func cofre_propio(nid: String) -> String:
	var claves: Array = j.d.mundo.constr.keys()
	claves.sort()
	for k in claves:
		var cs: Dictionary = j.d.mundo.constr[k]
		if cs.t == "cofre" and cs.get("dueno", "") == "npc:" + nid: return "c@" + k
	return ""

## Propiedad: con excedente de la moneda de trueque, el habitante se hace un cofre junto a su cama y guarda en él sus ahorros.
func _acumular(nid: String) -> bool:
	var p: Dictionary = cfg.propiedad
	var moneda: String = cfg.moneda_trueque
	if not bool(p.activa): return false
	var cid := cofre_propio(nid)
	if cid == "":
		if excedente(nid, moneda) < int(p.umbral_cofre): return false
		var lecho: Vector2i = j.habitantes.cama(nid)
		if lecho == Vector2i(-1, -1): return false
		a.estado(nid).objetivo = "tener un lugar donde guardar lo mío"
		return _construir_cerca(nid, "cofre", [], lecho, "npc:" + nid)
	var sobra: int = excedente(nid, moneda) - int(p.conservar)
	if sobra < int(p.lote_min): return false
	if not _ir(nid, _celda_cofre(cid), "guardar", "guardar mis ahorros"): return true
	var cof: Dictionary = j.d.cofres[cid]
	var lote := {moneda: sobra}
	if not Inv.cabe(cof.inv, lote, j.CAP_COFRE): return false
	a._quitar(a.estado(nid).inv, moneda, sobra)
	Inv.anadir(cof.inv, lote, j.CAP_COFRE)
	suceso("ahorro", "%d %s en su cofre" % [sobra, moneda], nid)
	return true

## Tomar de un cofre ajeno es un hurto: lo notan los testigos cercanos y el dueño se entera de que faltan objetos.
func observar_hurto_cofre(actor: String, cid: String, item: String, n: int) -> void:
	if not activa() or not cid.begins_with("c@"): return
	var dueno: String = str(j.d.mundo.constr.get(cid.trim_prefix("c@"), {}).get("dueno", ""))
	if dueno == "" or dueno == actor or dueno == "npc:" + actor or dueno == "grupo:" + grupo_de(actor): return
	if j.d.cofres[cid].get("permitidos",[]).has(actor): return
	var celda := _celda_cofre(cid)
	var testigos: Array = []
	for otro in j.habitantes.ids:
		if otro != actor and Vector2(M.celda_de(j.habitantes.pos(otro))).distance_to(Vector2(celda)) <= float(cfg.radio_testigo_celdas): testigos.append(otro)
	var detalle := "%d %s" % [n, item]
	var humano: bool = j.d.jugadores.has(actor)
	var grupos_vistos: Array = []
	for w in testigos:
		a._recordar(w, "hurto_visto", detalle, actor)
		if humano:
			var gid := grupo_de(w)
			if not grupos_vistos.has(gid):
				_reputacion(gid, actor, -int(cfg.caracter.castigo_hurto))
				grupos_vistos.append(gid)
		else: _vinculo(w, actor, -int(cfg.caracter.perdida_estafa))
	var incidentes: Array = j.d.cofres[cid].get("incidentes",[])
	incidentes.append({"min":int(j.d.min),"detalle":j._txt_items({item:n}),"autor":_nombre(actor) if not testigos.is_empty() else "Alguien"})
	while incidentes.size()>8: incidentes.pop_front()
	j.d.cofres[cid].incidentes=incidentes
	var victima := dueno.trim_prefix("npc:") if dueno.begins_with("npc:") else ""
	if victima != "" and j.habitantes.ids.has(victima):
		a._recordar(victima, "robado", detalle, actor if not testigos.is_empty() else "")
		if not testigos.is_empty() and not humano and not testigos.has(victima): _vinculo(victima, actor, -int(cfg.caracter.perdida_estafa))
	elif j.rt.has(dueno):
		j.aviso("%s se llevó %s de tu cofre." % [_nombre(actor) if not testigos.is_empty() else "Alguien", j._txt_items({item: n})], dueno)
	suceso("hurto", "%s del cofre de %s%s" % [detalle, _nombre(dueno), " (lo vieron)" if not testigos.is_empty() else ""], actor, dueno)

## Vivienda: con excedente y sin camas libres, un habitante próspero construye una cama de huésped. La vivienda libre atrae a quien llegue.
func _vivienda(nid: String) -> bool:
	var v: Dictionary = cfg.vivienda
	if not bool(v.activa) or not bool(cfg.inmigracion.activa) or j.habitantes.ids.size() >= int(cfg.inmigracion.max_habitantes): return false
	if not j.vivo.camas_libres_lista().is_empty(): return false
	if int(j.d.min) - int(datos().get("vivienda_min", -99999)) < int(v.espera_min): return false
	for item in v.requiere_excedente:
		if excedente(nid, item) < int(v.requiere_excedente[item]): return false
	a.estado(nid).objetivo = "dar vivienda a quien llegue"
	var parcela: Dictionary = habitat.reservar(nid)
	if parcela.is_empty(): return false
	var c := Vector2i(int(parcela.cama[0]),int(parcela.cama[1]))
	var coste: Dictionary = C.CONSTR.cama_huesped.coste
	comprometer(nid,coste)
	for item in coste:
		if int(a.estado(nid).inv.get(item,0))<int(coste[item]): return _obtener(nid,item,int(coste[item])-int(a.estado(nid).inv.get(item,0)),[],"dar vivienda a quien llegue")
	if not _ir(nid,c,"construir","preparar una vivienda"): return true
	var hecho: bool = construir_pieza(nid,"cama_huesped",c)
	if hecho:
		habitat.estado(c,"pendiente")
		# La experiencia de levantar la vivienda abre su siguiente técnica, sin regalar insumos.
		if not "ladrillo" in a.recetas_de(nid):
			a.estado(nid).recetas_nuevas.append("ladrillo")
			a._recordar(nid,"descubrio","Aprendí a fabricar ladrillos para completar viviendas")
	if not j.vivo.camas_libres_lista().is_empty(): datos().vivienda_min = int(j.d.min)
	return hecho

## Asentamiento: un albañil cierra con ladrillo tres lados (norte, oeste, este) de cada cama de huésped; el sur queda como entrada.
## Construir exige ladrillos reales (los fabrica o los compra) y las mismas validaciones de ruta que el resto.
func _refugio(nid: String) -> bool:
	if not "ladrillo" in a.recetas_de(nid): return false
	var hechos: Dictionary = datos().get("refugios", {})
	var claves: Array = j.d.mundo.constr.keys()
	claves.sort()
	for k in claves:
		if j.d.mundo.constr[k].t != "cama_huesped": continue
		var cama := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
		for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var w: Vector2i = cama + d
			if M.ESENCIALES.has(w) or j.mundo.puede_poner(w) != "" or j.ocupada(w): continue
			a.estado(nid).objetivo = "levantar un refugio de ladrillo"
			var coste: Dictionary = C.CONSTR.muro_ladrillo.coste
			comprometer(nid, coste)
			for item in coste:
				var falta: int = int(coste[item]) - int(a.estado(nid).inv.get(item, 0))
				if falta > 0: return _obtener(nid, item, falta, [], "construir " + C.CONSTR.muro_ladrillo.n)
			if not _ir(nid, w, "construir", "levantar un refugio de ladrillo"): return true
			if not construir_pieza(nid, "muro_ladrillo", w):   # la validación de rutas lo rechazó: no insistir en esta cama
				if not datos().has("refugios"): datos().refugios = {}
				datos().refugios[k] = true
			return true
		if not datos().has("refugios"): datos().refugios = {}
		datos().refugios[k] = true   # nada más que cerrar (o ya no se puede): no se vuelve a evaluar
	return false

func _pieza_puesta(pieza: String, c: Vector2i) -> bool:
	if pieza == "techo": return j.mundo.estado.techos.has(M.clave(c))
	return j.mundo.constr_en(c).get("t", "") == pieza

func _celdas_casa(cama: Vector2i) -> Array:
	var plano: Dictionary = cfg.vivienda.casa
	var pasos: Array = []
	for e in plano.piezas: pasos.append([str(e.p), cama + Vector2i(int(e.d[0]), int(e.d[1]))])
	for d in plano.techos: pasos.append(["techo", cama + Vector2i(int(d[0]), int(d[1]))])
	return pasos

## Casa completa: tres muros de la cama, sala, puerta, mesa y techo sobre cama y sala.
func casa_completa(cama: Vector2i) -> bool:
	if j.mundo.constr_en(cama).get("t", "") not in ["cama", "cama_huesped"]: return false
	for d in cfg.vivienda.casa.base:
		if j.mundo.constr_en(cama + Vector2i(int(d[0]), int(d[1]))).get("t", "") not in ["muro", "muro_ladrillo"]: return false
	for paso in _celdas_casa(cama):
		var ok := _pieza_puesta(paso[0], paso[1])
		if paso[0] == "muro_ladrillo": ok = j.mundo.constr_en(paso[1]).get("t", "") in ["muro", "muro_ladrillo"]
		if not ok: return false
	return true

## Tras el refugio, el albañil completa la casa pieza a pieza (plano en reglas.vivienda.casa). Lo que no cabe se omite.
func _casa(nid: String) -> bool:
	if not "ladrillo" in a.recetas_de(nid): return false
	var hechas: Dictionary = datos().get("casas", {})
	var claves: Array = j.d.mundo.constr.keys()
	claves.sort()
	for k in claves:
		if j.d.mundo.constr[k].t != "cama_huesped" or not datos().get("refugios", {}).has(k): continue
		var cama := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1)))
		if casa_completa(cama):
			habitat.estado(cama,"completa")
			continue
		hechas.erase(k) # migra marcas antiguas de obras procesadas pero incompletas
		habitat.estado(cama,"pendiente")
		for paso in _celdas_casa(cama):
			var pieza: String = paso[0]
			var c: Vector2i = paso[1]
			if _pieza_puesta(pieza, c) or M.ESENCIALES.has(c) or (pieza != "techo" and j.ocupada(c)): continue   # el techo no estorba a quien está debajo
			if (j.mundo.puede_techar(c) if pieza == "techo" else j.mundo.puede_poner(c)) != "":
				habitat.estado(cama,"bloqueada","Hay un obstáculo en "+M.clave(c))
				continue
			a.estado(nid).objetivo = "completar una casa"
			var coste: Dictionary = C.CONSTR[pieza].coste
			comprometer(nid, coste)
			for item in coste:
				var falta: int = int(coste[item]) - int(a.estado(nid).inv.get(item, 0))
				if falta > 0: return _obtener(nid, item, falta, [], "construir " + C.CONSTR[pieza].n)
			if not _ir(nid, c, "construir", "completar una casa"): return true
			if not construir_pieza(nid, pieza, c): break   # la validación de rutas lo rechazó: dejar esta casa como está
			return true
		if not datos().has("casas"): datos().casas = {}
		if casa_completa(cama):
			datos().casas[k] = true
			habitat.estado(cama,"completa")
		else: habitat.estado(cama,"bloqueada","Faltan piezas o acceso; se reintentará")
	return false

## Riqueza del valle: valor de lo que guardan habitantes y depósitos. Mide si hay con qué sostener a un recién llegado.
func _valor_lote(lote: Dictionary) -> float:
	var total := 0.0
	for item in lote:
		if cfg.valor_items.has(item):
			total += valor(item)*int(lote[item])
		elif a.desarrollo.A.leer_material(item)!="":
			total += _valor_lote(a.desarrollo.A.receta_material(item).ent)*int(lote[item])
		elif item=="candado":
			total += _valor_lote(cfg.proteccion.coste)*int(lote[item])
		elif not a.desarrollo.A.leer(item).is_empty():
			# Una pieza generada vale los componentes que se pagaron por ella.
			total += _valor_lote(a.desarrollo.A.receta(item).ent)*int(lote[item])
	return total

func _riqueza() -> int:
	var total := 0.0
	for nid in j.habitantes.ids:
		total += _valor_lote(a.estado(nid).inv)
		var cid := cofre_propio(nid)
		if cid != "": total += _valor_lote(j.d.cofres[cid].inv)
	for gid in cfg.grupos: total += _valor_lote(grupo(gid).inv)
	# El taller y la vivienda son capacidad real de acogida; la fibra abundante se devalúa.
	for pieza in j.d.mundo.constr.values():
		var dueno: String = pieza.get("dueno","")
		if dueno.begins_with("npc:") or dueno.begins_with("grupo:"): total += _valor_lote(C.CONSTR[pieza.t].coste)
	for acuerdo in datos().acuerdos.values():
		if acuerdo.estado=="activo": total += _valor_lote(acuerdo.bien)+_valor_lote(acuerdo.pago)
	return floori(total)

func _personalizar_colono(npc: Dictionary, perfil: Dictionary, rng: RandomNumberGenerator) -> void:
	var identidad: Dictionary = cfg.inmigracion.identidades[rng.randi()%cfg.inmigracion.identidades.size()].duplicate(true)
	var desplazamiento: int = rng.randi_range(-2,2)*30
	var horario: Array = []
	for fr in npc.data.horario:
		var inicio := posmod(int(fr.desde_minuto)+desplazamiento,1440)
		var duracion := int(fr.hasta_minuto)-int(fr.desde_minuto)
		var fin := inicio+duracion
		var copia: Dictionary = fr.duplicate(true)
		copia.desde_minuto=inicio
		copia.hasta_minuto=mini(1440,fin)
		horario.append(copia)
		if fin>1440:
			var resto: Dictionary=fr.duplicate(true)
			resto.desde_minuto=0
			resto.hasta_minuto=fin-1440
			horario.append(resto)
	horario.sort_custom(func(x,y):return x.desde_minuto<y.desde_minuto)
	npc.data.horario=horario
	npc.data.objetivo_propio=identidad.objetivo
	for nec in npc.data.necesidades:
		if nec.id=="energia": nec.umbral_descanso=clampf(float(nec.umbral_descanso)+rng.randi_range(-5,5),10,60)
	perfil["identidad"] = identidad
	perfil.reserva_producto = int(perfil.reserva_producto)+int(identidad.reserva_extra)

## Población abierta: con cama libre, riqueza y espacio llega alguien con oficio y carácter sorteados. No hay un número objetivo.
func _inmigrar() -> void:
	var ci: Dictionary = cfg.inmigracion
	var d: Dictionary = datos()
	if not bool(ci.activa) or j.habitantes.ids.size() >= int(ci.max_habitantes): return
	if int(j.d.min) - int(d.get("llegada_min", -99999)) < int(ci.espera_min): return
	if j.vivo.camas_libres_lista().is_empty() or _riqueza() < int(ci.riqueza_minima): return
	var raiz: Dictionary = j.d.mundo_vivo.autonomia
	if not raiz.has("colonos"): raiz.colonos = {}
	var rng = j._rng("inmigracion", "%d:%d" % [int(j.d.min), raiz.colonos.size()])
	var oficios: Array = ci.oficios.keys()
	oficios.sort()
	var oficio: String = oficios[rng.randi() % oficios.size()]
	var albanil := false
	for nid in j.habitantes.ids:
		if "ladrillo" in a.perfil(nid).get("recetas",[]): albanil=true
	if not albanil and not habitat.datos().parcelas.is_empty() and ci.oficios.has("albanil"): oficio="albanil"
	var of: Dictionary = ci.oficios[oficio]
	var usados: Array = []
	for c in raiz.colonos.values(): usados.append(c.npc.name)
	var libres: Array = ci.nombres.filter(func(x): return not x in usados)
	var nombre: String = str(libres[rng.randi() % libres.size()]) if not libres.is_empty() else "Colono %d" % (raiz.colonos.size() + 1)
	var rango: Dictionary = ci.caracter_rango
	var carac := {}
	for k in rango: carac[k] = rng.randi_range(int(rango[k][0]), int(rango[k][1]))
	var id := "colono_%d" % (raiz.colonos.size() + 1)
	var molde: Dictionary = j.habitantes._paq.entidades.npc[of.molde]
	var npc := {"name": nombre, "data": {"objetivo_propio": "Hacerse un lugar en el valle", "horario": molde.data.horario.duplicate(true), "necesidades": molde.data.necesidades.duplicate(true)}}
	var perfil: Dictionary = of.duplicate(true)
	perfil.erase("molde")
	perfil["caracter"] = carac
	perfil["oficio"] = oficio
	_personalizar_colono(npc,perfil,rng)
	if j.habitantes.registrar_colono(id, npc) != "": return
	raiz.colonos[id] = {"npc": npc, "perfil": perfil}
	j.vivo.restaurar().vars[id + "_presente"] = true
	j.habitantes.reconciliar()
	d.llegada_min = int(j.d.min)
	a._recordar(id, "llego", "al valle")
	suceso("llegada", "%s, de oficio %s, llega al valle" % [nombre, oficio], id)
	j.aviso_todos("%s llega al valle." % nombre)

## Diario legible: muestra actor, acción y resultado en lugar de identificadores internos.
func texto_suceso(e: Dictionary) -> String:
	var acciones := {"acuerdo":"acordó", "entrega":"entregó", "fabricacion":"fabricó", "construccion":"construyó", "reparacion":"reparó", "desgaste":"agotó", "aporte":"aportó", "retiro":"retiró", "alternativa":"buscó otra solución", "incumplimiento":"no concretó el acuerdo", "llegada":"llegó", "estafa":"engañó en un acuerdo", "hurto":"robó", "ahorro":"ahorró", "conflicto":"tuvo un conflicto", "ayuda":"recibió ayuda", "descubrimiento":"creó", "venta":"intercambió", "material":"elaboró", "mantenimiento":"cuidó su ropa y lecho", "proteccion":"protegió sus ahorros"}
	var nombre: String = j.habitantes.fichas.get(e.quien, {}).get("n", "Alguien")
	if j.d.jugadores.has(e.quien): nombre = j.d.jugadores[e.quien].nombre
	var detalle: String = e.detalle
	var ids: Array = C.ITEMS.keys()
	ids.sort_custom(func(x,y): return x.length()>y.length())
	for item in ids: detalle = detalle.replace(item, C.ITEMS[item].n)
	return "%s %s: %s" % [nombre, acciones.get(e.tipo,e.tipo), detalle]
