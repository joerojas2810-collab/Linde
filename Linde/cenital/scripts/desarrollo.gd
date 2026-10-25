extends RefCounted
## Conocimiento y pericia se obtienen de acciones confirmadas, nunca de pulsar una tecla.
const A = preload("res://scripts/artesania.gd")
const C = preload("res://scripts/catalogos.gd")
const Eq = preload("res://scripts/equipo.gd")
const Inv = preload("res://scripts/inventario.gd")
const M = preload("res://scripts/mundo.gd")
var a
var j
var cfg: Dictionary

func _init(autonomia) -> void:
	a = autonomia
	j = a.j
	cfg = A.reglas()

func activa() -> bool:
	return a.sociedad.activa() and bool(cfg.activa)

func datos() -> Dictionary:
	var d: Dictionary = j.d.mundo_vivo.autonomia
	if not d.has("desarrollo"): d.desarrollo = {"version":1,"actores":{},"creaciones":[]}
	return d.desarrollo

func estado(actor: String) -> Dictionary:
	var actores: Dictionary = datos().actores
	if not actores.has(actor): actores[actor] = {"practica":{},"materiales":{},"proyecto":{}}
	return actores[actor]

## Añade campos y reconoce existencias de partidas anteriores, sin regalar experiencia.
func restaurar() -> void:
	if not activa(): return
	for id in j.d.jugadores: observar(j.actor_desarrollo(id),j.d.jugadores[id].inv)
	for nid in j.habitantes.ids: observar("npc:"+nid,a.estado(nid).inv)

func _materiales(objetos: Dictionary) -> Array:
	var encontrados: Array = []
	for item in objetos:
		if int(objetos[item])<=0: continue
		var compuesto:=A.leer_material(str(item))
		if compuesto!="" and not encontrados.has(compuesto): encontrados.append(compuesto)
		var p := A.leer(str(item))
		if not p.is_empty() and not encontrados.has(p.material): encontrados.append(p.material)
		for mat in cfg.materiales:
			if cfg.materiales[mat].item==item and not encontrados.has(mat): encontrados.append(mat)
	return encontrados

func observar(actor: String, objetos: Dictionary) -> void:
	if not activa(): return
	var n := estado(actor)
	for mat in _materiales(objetos): n.materiales[mat] = true
	if actor.begins_with("npc:"): a.descubrir_recetas(actor.trim_prefix("npc:"))

## Una acción exitosa cuenta una vez; los materiales determinan especializaciones.
func registrar(actor: String, disciplina: String, objetos: Dictionary = {}) -> void:
	if not activa(): return
	observar(actor,objetos)
	var p: Dictionary = estado(actor).practica
	p[disciplina] = mini(int(cfg.practica_max),int(p.get(disciplina,0))+1)
	for mat in _materiales(objetos):
		var clave := disciplina+":"+str(mat)
		p[clave] = mini(int(cfg.practica_max),int(p.get(clave,0))+1)

func rango(actor: String, disciplina: String, material: String = "") -> int:
	var clave := disciplina+(":"+material if material!="" else "")
	return mini(int(cfg.calidad_max),int(estado(actor).practica.get(clave,0))/int(cfg.practica_por_rango))

func centro(actor: String) -> Vector2i:
	if actor.begins_with("npc:"): return a.sociedad._ancla(a.sociedad.grupo_de(actor.trim_prefix("npc:")))
	var id := actor.trim_prefix("pj:")
	# En la réplica, la identidad del servidor se presenta como jugador local.
	if not j.rt.has(id): id = j.LOCAL
	return M.celda_de(j.pies_de(id))

func suelo(actor: String) -> int:
	var origen := centro(actor)
	var cantidad := 0
	for clave in j.d.mundo.constr:
		if j.d.mundo.constr[clave].t!="suelo": continue
		var c := Vector2i(int(clave.get_slice(",",0)),int(clave.get_slice(",",1)))
		if maxi(absi(c.x-origen.x),absi(c.y-origen.y)) <= int(cfg.radio_taller): cantidad+=1
	return cantidad

## Valida conocimiento, pericia y entorno de trabajo de la pieza solicitada.
func conoce(actor: String, clave: String) -> bool:
	var p := A.leer(clave)
	if p.is_empty() or not estado(actor).materiales.has(p.material): return false
	var nivel := rango(actor,"artesania",p.material)
	return int(p.calidad)<=nivel and nivel>=int(cfg.tecnicas[p.tecnica].rango) and suelo(actor)>=suelo_requerido(actor,p.tecnica)

## La práctica de construcción permite organizar el mismo taller con menos superficie.
func suelo_requerido(actor: String, tecnica: String) -> int:
	var base: int=cfg.tecnicas[tecnica].suelo
	if base==0:return 0
	return maxi(1,base-rango(actor,"construccion")*int(cfg.ahorro_suelo_constructor))

func conoce_laminado(actor: String, id: String) -> bool:
	if not id in A.combinaciones(): return false
	var partes:=id.split("_")
	return estado(actor).materiales.has(partes[0]) and estado(actor).materiales.has(partes[1]) and rango(actor,"artesania",partes[0])>=int(cfg.laminados.rango)

## Refinar también es una transacción: descubrir no regala la materia fabricada.
func refinar(id_material: String, id: String) -> Dictionary:
	if not activa() or not conoce_laminado(j.actor_desarrollo(id),id_material): return j._no("Necesitas conocer sus componentes y practicar con el metal",id)
	var r:=A.receta_material(id_material)
	if not j.estacion_cerca(r.est,id): return j._no("Necesitas un horno cerca",id)
	if not Inv.cambiar(j.jug(id).inv,r.ent,r.sal,j.stats(id).slots):return j._no("Faltan componentes o espacio",id)
	registrar(j.actor_desarrollo(id),"artesania",r.ent)
	observar(j.actor_desarrollo(id),r.sal)
	a.sociedad.suceso("material",r.n,id)
	return j._ok("Elaboras "+r.n,id)

func planos(actor: String, forma: String = "") -> Array:
	var lista: Array = []
	for material in estado(actor).materiales:
		for f in A.material(material).formas:
			if forma!="" and forma!=f: continue
			for tecnica in cfg.tecnicas:
				var clave := A.clave(f,material,tecnica,rango(actor,"artesania",material))
				if conoce(actor,clave): lista.append(clave)
	lista.sort()
	return lista

func _creacion(actor: String, clave: String, entradas: Dictionary) -> void:
	var lista: Array = datos().creaciones
	lista.append({"min":int(j.d.min),"actor":actor,"pieza":clave,"insumos":entradas.duplicate()})
	while lista.size()>int(cfg.tope_creaciones): lista.pop_front()

## Fabricación del jugador: valida el plano en servidor y conserva capacidad e ingredientes.
func fabricar(clave: String, id: String) -> Dictionary:
	if not activa(): return j._no("El taller experimental no está activo",id)
	var actor: String = j.actor_desarrollo(id)
	if not conoce(actor,clave): return j._no("Aún no conoces esa combinación o falta espacio de taller",id)
	var r := A.receta(clave)
	if not j.estacion_cerca(r.est,id): return j._no("Necesitas una mesa de trabajo cerca",id)
	if not Inv.cambiar(j.jug(id).inv,r.ent,r.sal,j.stats(id).slots): return j._no("Faltan materiales o espacio en la mochila",id)
	_creacion(actor,clave,r.ent)
	registrar(actor,"artesania",r.ent)
	return j._ok("Fabricas "+A.info(clave).n,id)

func comprar(nid: String, clave: String, id: String) -> Dictionary:
	if not activa() or not j.habitantes.ids.has(nid) or A.leer(clave).is_empty(): return j._no("No existe esa oferta",id)
	if j.habitantes.pos(nid).distance_to(j.pies_de(id))>j.ALCANCE_NPC: return j._no("Acércate al artesano",id)
	var inv: Dictionary = a.estado(nid).inv
	if int(inv.get(clave,0))<1: return j._no("Esa pieza ya no está disponible",id)
	var r := A.receta(clave)
	if not Inv.cambiar(j.jug(id).inv,r.ent,{clave:1},j.stats(id).slots): return j._no("Faltan materiales para el trueque o espacio",id)
	a._quitar(inv,clave,1)
	for item in r.ent: inv[item]=int(inv.get(item,0))+int(r.ent[item])
	observar(j.actor_desarrollo(id),{clave:1})
	a.sociedad.reconoce_ayuda(nid,id)
	a.sociedad.suceso("venta",A.info(clave).n,nid,id)
	return j._ok("Intercambias materiales por "+A.info(clave).n,id)

## Proyecto de taller derivado de práctica y ocupación de la mochila; cada suelo cuesta madera real.
func _ampliar(nid: String) -> bool:
	var actor := "npc:"+nid
	var nivel := rango(actor,"artesania")
	if nivel<int(cfg.rango_prototipo): return false
	var demanda: int = mini(int(cfg.suelo_max),maxi(nivel*int(cfg.suelo_por_rango),Inv.slots(a.estado(nid).inv)))
	var n := estado(actor)
	if suelo(actor)>=demanda:
		n.proyecto={}
		return false
	n.proyecto={"tipo":"taller","suelo_objetivo":demanda,"motivo":"espacio para nuevos trabajos"}
	var existencias: Dictionary = a.estado(nid).inv
	if int(existencias.get("madera",0))<1: return a.sociedad._obtener(nid,"madera",1,[],"ampliar el taller")
	var origen := centro(actor)
	for radio in range(1,int(cfg.radio_taller)+1):
		for y in range(origen.y-radio,origen.y+radio+1):
			for x in range(origen.x-radio,origen.x+radio+1):
				var c := Vector2i(x,y)
				if M.ESENCIALES.has(c) or c==origen or j.mundo.puede_poner(c)!="" or j.ocupada(c): continue
				if j.mundo.camino(M.celda_de(j.habitantes.pos(nid)),func(z):return j.mundo.es_adyacente(z,c)).is_empty(): continue
				if not a.sociedad._ir(nid,c,"construir","ampliar el taller"): return true
				if a.sociedad.construir_pieza(nid,"suelo",c): return true
	return false

## Experimentación de NPC con excedentes, recetas descubiertas y mesa accesible.
func decidir(nid: String) -> bool:
	if not activa(): return false
	var actor := "npc:"+nid
	if _ampliar(nid): return true
	if rango(actor,"artesania")<int(cfg.rango_prototipo): return false
	var n: Dictionary = a.estado(nid)
	var cantidad := 0
	for item in n.inv:
		if not A.leer(str(item)).is_empty(): cantidad+=int(n.inv[item])
	if cantidad>=int(cfg.max_artefactos_npc): return false
	# Una transformación conocida puede abrir nuevos materiales para futuros planos.
	for material in A.combinaciones():
		if not conoce_laminado(actor,material) or n.inv.has("mat1:"+material): continue
		var receta:=A.receta_material(material)
		var posible:=true
		for item in receta.ent:
			if a.sociedad.excedente(nid,item)<int(receta.ent[item]):posible=false
		if not posible:continue
		var horno: String=a._estacion(nid,receta.est)
		if horno=="" or int(a.sociedad.datos().estaciones.get(horno,0))>=int(a.sociedad.cfg.desgaste_estacion_max):continue
		var celda:=Vector2i(int(horno.get_slice(",",0)),int(horno.get_slice(",",1)))
		if not a.sociedad._ir(nid,celda,"fabricar","elaborar un material nuevo"):return true
		if not Inv.tiene(n.inv,receta.ent):return false
		Inv.quitar(n.inv,receta.ent)
		a.sociedad.datos().estaciones[horno]=int(a.sociedad.datos().estaciones.get(horno,0))+1
		for item in receta.sal:a.dar(nid,item,int(receta.sal[item]))
		registrar(actor,"artesania",receta.ent)
		observar(actor,receta.sal)
		a.sociedad.suceso("material",receta.n,nid)
		return true
	var gid: String = a.sociedad.grupo_de(nid)
	for clave in planos(actor):
		var p := A.leer(clave)
		if not p.forma in cfg.formas_por_grupo[gid] or n.inv.has(clave): continue
		var forma_cubierta := false
		for item in n.inv:
			var pieza := A.leer(str(item))
			if not pieza.is_empty() and pieza.forma==p.forma: forma_cubierta=true
		if forma_cubierta: continue
		var r := A.receta(clave)
		var sobran := true
		for item in r.ent:
			if a.sociedad.excedente(nid,item)<int(r.ent[item]): sobran=false
		if not sobran: continue
		var estacion: String = a._estacion(nid,"mesa")
		if estacion=="": return a.sociedad._construir_estacion(nid,"mesa",[])
		var c := Vector2i(int(estacion.get_slice(",",0)),int(estacion.get_slice(",",1)))
		if int(a.sociedad.datos().estaciones.get(estacion,0))>=int(a.sociedad.cfg.desgaste_estacion_max):
			var material: String=a.sociedad.cfg.material_reparacion
			var coste: int=a.sociedad.cfg.coste_reparacion
			if int(n.inv.get(material,0))<coste: return a.sociedad._obtener(nid,material,coste,[],"mantener el taller")
			if a.sociedad._ir(nid,c,"reparar","mantener el taller"):
				a._quitar(n.inv,material,coste)
				a.sociedad.datos().estaciones[estacion]=0
				a.sociedad.suceso("reparacion","Mesa de trabajo",nid)
			return true
		if not a.sociedad._ir(nid,c,"fabricar","experimentar con "+A.material(p.material).nombre): return true
		if not Inv.tiene(n.inv,r.ent): return false
		Inv.quitar(n.inv,r.ent)
		a.sociedad.datos().estaciones[estacion]=int(a.sociedad.datos().estaciones.get(estacion,0))+1
		a.dar(nid,clave,1)
		_creacion(actor,clave,r.ent)
		registrar(actor,"artesania",r.ent)
		a._recordar(nid,"descubrio",A.info(clave).n)
		a.sociedad.suceso("descubrimiento",A.info(clave).n,nid)
		return true
	return false

## Atlas de materiales del juego actual: fuentes y usos consultados en los catálogos existentes.
func materiales() -> Array:
	var lista: Array = []
	var ids := ["madera","piedra","fibra","mena","lingote","cobre","lingote_cobre","estano","lingote_bronce","arcilla","baya","gelatina","unguento","gema"]
	for item in ids:
		var fuentes: Array = []
		var usos: Array = []
		for objeto in C.OBJETOS:
			var def: Dictionary = C.OBJETOS[objeto]
			if def.drops.has(item): fuentes.append(def.n)
			for prob in def.prob:
				if prob.item==item: fuentes.append(def.n+" (puede salir)")
		for r in Eq.recetas().values():
			if r.ent.has(item) and not usos.has(r.n): usos.append(r.n)
		for pieza in C.CONSTR:
			if C.CONSTR[pieza].coste.has(item): usos.append(C.CONSTR[pieza].n)
		if C.ITEMS[item].has("cura"): usos.append("restaurar %d puntos de vida" % int(C.ITEMS[item].cura))
		var nota: String = cfg.fuentes_adicionales.get(item,"")
		for mat in cfg.materiales:
			if cfg.materiales[mat].item==item:
				if nota=="": nota=cfg.materiales[mat].fuente
				usos.append("nuevos planos de "+str(cfg.materiales[mat].nombre))
		lista.append({"id":item,"nombre":C.ITEMS[item].n,"fuente":nota if nota!="" else ", ".join(fuentes),"usos":usos})
	return lista
