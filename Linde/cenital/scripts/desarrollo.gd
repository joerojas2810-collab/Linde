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
var sab: Dictionary          # saberes_v1.json: catálogo complementario de conocimiento
var _cat: Dictionary = {}

func _init(autonomia) -> void:
	a = autonomia
	j = a.j
	cfg = A.reglas()
	sab = JSON.parse_string(FileAccess.get_file_as_string("res://datos/desarrollo/saberes_v1.json"))

func activa() -> bool:
	return a.sociedad.activa() and bool(cfg.activa)

func datos() -> Dictionary:
	var d: Dictionary = j.d.mundo_vivo.autonomia
	if not d.has("desarrollo"): d.desarrollo = {"version":2,"actores":{},"creaciones":[],"historia":{},"lecciones":{},"pausas":{}}
	var s: Dictionary = d.desarrollo
	if int(s.version)<2:   # 1 -> 2: saberes. La siembra de cada actor la hace sembrar(), solo en la autoridad.
		for k in ["historia","lecciones","pausas"]: if not s.has(k): s[k]={}
		s.version=2
	return s

func estado(actor: String) -> Dictionary:
	var actores: Dictionary = datos().actores
	if not actores.has(actor): actores[actor] = {"practica":{},"materiales":{},"proyecto":{},"saber":{}}
	if not actores[actor].has("saber"): actores[actor].saber = {}
	return actores[actor]

## Añade campos y reconoce existencias de partidas anteriores, sin regalar experiencia.
func restaurar() -> void:
	if not activa(): return
	for id in j.d.jugadores:
		observar(j.actor_desarrollo(id),j.d.jugadores[id].inv)
		sembrar(j.actor_desarrollo(id))
	for nid in j.habitantes.ids:
		observar("npc:"+nid,a.estado(nid).inv)
		sembrar("npc:"+nid)

# ---------- Saberes ----------
# Un saber es conocimiento de un procedimiento: «tec:<técnica>» o «lam:<laminado>». Es independiente de
# la práctica (rango), del material visto y del taller. Otros niveles (dom:, dis:, ope:, inv:) se añaden
# como ids nuevos en el mismo almacén, sin cambiar el esquema (PLAN_IMPLEMENTACION §3 y §17).

## Id → {tipo, exige, rango_min, afines, nombre}. Derivado de saberes_v1.json y de la gramática.
func catalogo() -> Dictionary:
	if _cat.is_empty():
		for t in sab.tecnicas:
			var def: Dictionary = sab.tecnicas[t]
			_cat["tec:"+t] = {"tipo":"tec","exige":def.exige,"rango_min":int(def.rango_min),"afines":def.afines,"nombre":"técnica "+str(cfg.tecnicas[t].nombre)}
		for o in sab.get("operadores",{}):
			var def: Dictionary = sab.operadores[o]
			_cat["op:"+o] = {"tipo":"op","exige":def.exige,"rango_min":int(def.rango_min),"afines":def.afines,"nombre":"operador de "+str(cfg.operadores[o].nombre).to_lower()}
		for id in A.combinaciones():
			var def: Dictionary = sab.laminados
			_cat["lam:"+id] = {"tipo":"lam","exige":def.exige,"rango_min":int(def.rango_min),"afines":def.afines,"nombre":str(A.material(id).nombre),"componentes":id.split("_")}
	return _cat

## Errores del catálogo y de la siembra inicial (vacío si es coherente).
func validar_saberes() -> Array:
	var errores: Array = []
	for t in sab.tecnicas:
		if not cfg.tecnicas.has(t) or t=="simple": errores.append("técnica inexistente o común: "+t)
	for id in catalogo():
		if not catalogo()[id].exige in ["tec","lam","op"]: errores.append("exigencia no soportada: "+id)
	for o in sab.get("operadores",{}):
		if not cfg.get("operadores",{}).has(o) or not cfg.operadores[o].has("defecto"): errores.append("operador inexistente: "+o)
	var listas: Array = sab.inicial.npc.values()+sab.inicial.oficio.values()+[sab.inicial.jugador]
	for lista in listas:
		for id in lista: if not catalogo().has(id): errores.append("saber inicial inexistente: "+str(id))
	return errores

## Ids de saber que exige fabricar la pieza `p` (descriptor de artesania.leer). La lógica de conocimiento
## solo pregunta por aquí: una gramática con parámetros añadirá ids a esta lista, no condiciones al resto.
func saberes_exigidos(p: Dictionary) -> Array:
	var ids: Array = []
	if catalogo().has("tec:"+str(p.tecnica)): ids.append("tec:"+str(p.tecnica))
	if catalogo().has("lam:"+str(p.material)): ids.append("lam:"+str(p.material))
	for id in catalogo():     # D5: un saber op: por cada operador de la pieza con nivel no predeterminado
		if catalogo()[id].tipo!="op": continue
		var o: String = id.trim_prefix("op:")
		if p.has(o) and str(p[o])!=str(cfg.operadores[o].defecto): ids.append(id)
	return ids

## Lectura pura (también en la réplica): no crea entradas.
func _saber_de(actor: String) -> Dictionary:
	return datos().actores.get(actor,{}).get("saber",{})

func tiene_saber(actor: String, id: String) -> bool:
	return _saber_de(actor).has(id)

## ¿Existe esta pieza dentro de las reglas? No depende de ningún actor.
func valido(clave: String) -> bool:
	return not _leer(clave).is_empty()

## Descriptor de una pieza fabricable: art1: o art2: ({} si ninguna).
func _leer(clave: String) -> Dictionary:
	var p := A.leer(clave)
	return p if not p.is_empty() else A.leer2(clave)

func _receta(clave: String) -> Dictionary:
	var r := A.receta(clave)
	return r if not r.is_empty() else A.receta2(clave)

## ¿Conoce el procedimiento de esta pieza? Independiente del taller, los materiales y la pericia.
func sabe(actor: String, clave: String) -> bool:
	var p := _leer(clave)
	if p.is_empty(): return false
	for id in saberes_exigidos(p): if not tiene_saber(actor,id): return false
	return true

## Preparación mínima para aprender un saber: rango general de artesanía y, en laminados, haber visto sus componentes.
func prerrequisitos_ok(actor: String, id: String) -> bool:
	if not catalogo().has(id): return false
	var def: Dictionary = catalogo()[id]
	if rango(actor,"artesania")<int(def.rango_min): return false
	if def.tipo=="lam":
		for c in def.componentes: if not datos().actores.get(actor,{}).get("materiales",{}).has(c): return false
	return true

## Saberes que el actor aún no tiene y para los que está preparado.
func candidatos(actor: String) -> Array:
	var lista: Array = []
	for id in catalogo():
		if not tiene_saber(actor,id) and prerrequisitos_ok(actor,id): lista.append(id)
	lista.sort()
	return lista

func _nombre_saber(id: String) -> String:
	return str(catalogo().get(id,{}).get("nombre",id))

## Concede un saber (solo la autoridad). `fuente`: siembra, ensenanza, descubrimiento o prueba.
## No comprueba prerrequisitos: los exige quien enseña. Registra la procedencia salvo en la siembra.
func aprender(actor: String, id: String, fuente: String, maestro: String = "") -> bool:
	if not j.es_autoridad() or not activa() or not catalogo().has(id): return false
	var n := estado(actor)
	if n.saber.has(id): return false
	n.saber[id] = {"fuente":fuente,"min":int(j.d.min),"de":maestro}
	if fuente=="siembra": return true
	var h: Dictionary = datos().historia.get_or_add(id,{"primero":{},"aprendices":[],"total":0})
	if fuente=="descubrimiento" and h.primero.is_empty(): h.primero={"actor":actor,"min":int(j.d.min)}
	h.total=int(h.total)+1
	h.aprendices.append({"actor":actor,"min":int(j.d.min),"de":maestro,"fuente":fuente})
	while h.aprendices.size()>int(sab.ensenanza.tope_aprendices): h.aprendices.pop_front()
	return true

## Conocimiento inicial: lo que el oficio y la experiencia justifican. Solo la autoridad, una vez por actor.
func sembrar(actor: String) -> void:
	if not j.es_autoridad() or not activa(): return
	var n := estado(actor)
	if n.has("sembrado"): return
	n.sembrado = true
	var ids: Array = _heredados(actor)
	if actor.begins_with("npc:"): ids+=_iniciales(actor.trim_prefix("npc:"))
	else: ids+=sab.inicial.jugador
	for id in ids: aprender(actor,str(id),"siembra")

## Quien ya practicaba conserva lo que ya hacía: técnicas y laminados que su rango le permitía usar.
func _heredados(actor: String) -> Array:
	var n := estado(actor)
	var ids: Array = []
	if int(n.practica.get("artesania",0))<=0: return ids
	var mejor := 0
	for m in n.materiales: mejor = maxi(mejor,rango(actor,"artesania",str(m)))
	for id in catalogo():
		var def: Dictionary = catalogo()[id]
		if def.tipo=="tec" and mejor>=int(cfg.tecnicas[id.trim_prefix("tec:")].rango): ids.append(id)
		elif def.tipo=="lam" and _laminado_ok(actor,id.trim_prefix("lam:")): ids.append(id)
	return ids

func _iniciales(nid: String) -> Array:
	var ids: Array = sab.inicial.npc.get(nid,[]).duplicate()
	for id in sab.inicial.oficio.get(str(a.perfil(nid).get("oficio","")),[]): if not id in ids: ids.append(id)
	return ids

func _materiales(objetos: Dictionary) -> Array:
	var encontrados: Array = []
	for item in objetos:
		if int(objetos[item])<=0: continue
		var compuesto:=A.leer_material(str(item))
		if compuesto!="" and not encontrados.has(compuesto): encontrados.append(compuesto)
		var p := _leer(str(item))
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
	for clave in j.d.mundo.get("registro",{}).get("pisos",{}):
		if j.d.mundo.constr.get(clave,{}).get("t","")=="suelo": continue
		var c := Vector2i(int(clave.get_slice(",",0)),int(clave.get_slice(",",1)))
		if maxi(absi(c.x-origen.x),absi(c.y-origen.y)) <= int(cfg.radio_taller): cantidad+=1
	return cantidad

## ¿Puede hacerla ahora? Material visto, pericia y espacio de taller. Los insumos y la estación se validan al actuar.
func puede(actor: String, clave: String) -> bool:
	var p := _leer(clave)
	if p.is_empty() or not estado(actor).materiales.has(p.material): return false
	if p.has("refuerzo") and p.refuerzo!=cfg.operadores.refuerzo.defecto and not estado(actor).materiales.has(cfg.operadores.refuerzo.niveles[p.refuerzo].material): return false   # D5: ver también el refuerzo
	var nivel := rango(actor,"artesania",p.material)
	return int(p.calidad)<=nivel and nivel>=int(cfg.tecnicas[p.tecnica].rango) and suelo(actor)>=suelo_requerido(actor,p.tecnica)

## Fabricar exige conocer el procedimiento (sabe) y poder ejecutarlo ahora (puede).
func conoce(actor: String, clave: String) -> bool:
	return sabe(actor,clave) and puede(actor,clave)

## La práctica de construcción permite organizar el mismo taller con menos superficie.
func suelo_requerido(actor: String, tecnica: String) -> int:
	var base: int=cfg.tecnicas[tecnica].suelo
	if base==0:return 0
	return maxi(1,base-rango(actor,"construccion")*int(cfg.ahorro_suelo_constructor))

## Componentes vistos y pericia suficiente para elaborar el laminado (sin comprobar si conoce el proceso).
func _laminado_ok(actor: String, id: String) -> bool:
	if not id in A.combinaciones(): return false
	var partes:=id.split("_")
	return estado(actor).materiales.has(partes[0]) and estado(actor).materiales.has(partes[1]) and rango(actor,"artesania",partes[0])>=int(cfg.laminados.rango)

func conoce_laminado(actor: String, id: String) -> bool:
	return tiene_saber(actor,"lam:"+id) and _laminado_ok(actor,id)

## Refinar también es una transacción: descubrir no regala la materia fabricada.
func refinar(id_material: String, id: String) -> Dictionary:
	if not activa() or not conoce_laminado(j.actor_desarrollo(id),id_material): return j._no("Necesitas conocer el proceso y sus componentes, y practicar con el metal",id)
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
	var r := _receta(clave)
	if not j.estacion_cerca(r.est,id): return j._no("Necesitas una mesa de trabajo cerca",id)
	if not Inv.cambiar(j.jug(id).inv,r.ent,r.sal,j.stats(id).slots): return j._no("Faltan materiales o espacio en la mochila",id)
	_creacion(actor,clave,r.ent)
	registrar(actor,"artesania",r.ent)
	return j._ok("Fabricas "+Eq.info(clave).n,id)

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
	var alcanzables: Dictionary = {}   # una sola exploración desde donde está, reutilizada para todas las candidatas
	var esenciales: Array = j.mundo.esenciales(M.ID_INICIAL)   # solo el pueblo inicial por ahora; luego, el pueblo del taller
	for radio in range(1,int(cfg.radio_taller)+1):
		for y in range(origen.y-radio,origen.y+radio+1):
			for x in range(origen.x-radio,origen.x+radio+1):
				var c := Vector2i(x,y)
				if esenciales.has(c) or c==origen or j.mundo.puede_poner(c)!="" or j.ocupada(c): continue
				if alcanzables.is_empty(): alcanzables = j.mundo.alcanzables(M.celda_de(j.habitantes.pos(nid)))
				if not a.sociedad._llega_junto_a(alcanzables,c): continue
				if not a.sociedad._ir(nid,c,"construir","ampliar el taller"): return true
				if a.sociedad.construir_pieza(nid,"suelo",c): return true
	return false

# ---------- Enseñanza ----------

## Motivo por el que `maestro` no puede enseñar `id` a `alumno` ("" si puede). No mira distancia ni voluntad.
func _motivo_no_ensena(maestro: String, alumno: String, id: String) -> String:
	if not catalogo().has(id): return "Ese saber no existe"
	if not tiene_saber(maestro,id): return "No conoce ese saber"
	if tiene_saber(alumno,id): return "Ya lo conoce"
	if not prerrequisitos_ok(alumno,id): return "Aún no está preparado para aprenderlo"
	return ""

func _celdas(nid: String) -> Vector2i:
	return M.celda_de(j.habitantes.pos(nid))

func _descansa(nid: String) -> bool:
	return j.habitantes.rutina(nid).act in ["dormir","descansar"]

## Enseñanza entre habitantes, sin intervención del jugador: acude al alumno, comparte tiempo con él
## y, al completar la lección, el alumno aprende. No hereda pericia ni recibe ninguna pieza.
func _ensenar(nid: String) -> bool:
	var maestro := "npc:"+nid
	if _saber_de(maestro).is_empty(): return false
	var ens: Dictionary = sab.ensenanza
	var ahora := int(j.d.min)
	var lecciones: Dictionary = datos().lecciones
	var leccion: Dictionary = lecciones.get(maestro,{})
	if not leccion.is_empty():
		var otro_id: String = str(leccion.alumno).trim_prefix("npc:")
		if ahora-int(leccion.ultimo)>int(ens.espera_max_min) or not j.habitantes.ids.has(otro_id) or _motivo_no_ensena(maestro,leccion.alumno,leccion.saber)!="":
			_pausar(maestro,str(leccion.alumno),str(leccion.saber))
			lecciones.erase(maestro)
			leccion = {}
	if leccion.is_empty():
		leccion = _elegir_leccion(nid)
		if leccion.is_empty(): return false
		lecciones[maestro] = leccion
	var otro: String = str(leccion.alumno).trim_prefix("npc:")
	if _descansa(otro): return false
	a.sociedad._ir(nid,_celdas(otro),"ensenar","compartir una técnica")
	if Vector2(_celdas(nid)).distance_to(Vector2(_celdas(otro)))>float(ens.radio_leccion_celdas): return true
	leccion.avance = int(leccion.avance)+mini(int(ens.paso_max_min),ahora-int(leccion.ultimo))
	leccion.ultimo = ahora
	if int(leccion.avance)<int(ens.minutos): return true
	if aprender(leccion.alumno,leccion.saber,"ensenanza",maestro):
		var nombre := _nombre_saber(leccion.saber)
		a.sociedad._vinculo(nid,otro,int(ens.ganancia_confianza))
		a.sociedad._vinculo(otro,nid,int(ens.ganancia_confianza))
		a._recordar(nid,"enseno",nombre,leccion.alumno)
		a._recordar(otro,"aprendio",nombre,maestro)
		a.sociedad.suceso("ensenanza",nombre,nid,otro)
	lecciones.erase(maestro)
	return true

## Primera lección posible con alguien cercano, despierto y de confianza; prefiere lo afín a su oficio.
func _elegir_leccion(nid: String) -> Dictionary:
	var ens: Dictionary = sab.ensenanza
	var maestro := "npc:"+nid
	var ahora := int(j.d.min)
	var ids: Array = j.habitantes.ids.duplicate()
	ids.sort()
	var saberes: Array = _saber_de(maestro).keys()
	saberes.sort()
	var mejor: Dictionary = {}
	var puntos := -1
	for otro in ids:
		if otro==nid or a.perfil(otro).is_empty() or _descansa(otro): continue
		if Vector2(_celdas(nid)).distance_to(Vector2(_celdas(otro)))>float(ens.radio_busqueda_celdas): continue
		if a.sociedad.confianza(nid,otro)<int(ens.confianza_min) or a.sociedad.confianza(otro,nid)<int(ens.confianza_min): continue
		var alumno: String = "npc:"+str(otro)
		sembrar(alumno)
		for id in saberes:
			if _motivo_no_ensena(maestro,alumno,id)!="": continue
			if ahora-int(datos().pausas.get(_clave_pausa(maestro,alumno,id),-1000000))<int(ens.enfriamiento_min): continue
			var p := 1+(2 if str(a.perfil(otro).get("oficio","")) in catalogo()[id].afines else 0)
			if p>puntos:
				puntos = p
				mejor = {"alumno":alumno,"saber":id,"avance":0,"ultimo":ahora}
	return mejor

func _clave_pausa(maestro: String, alumno: String, id: String) -> String:
	return maestro+">"+alumno+">"+id

## Una lección interrumpida no se reintenta de inmediato; las pausas caducadas se descartan.
func _pausar(maestro: String, alumno: String, id: String) -> void:
	var pausas: Dictionary = datos().pausas
	var limite := int(j.d.min)-int(sab.ensenanza.enfriamiento_min)
	for k in pausas.keys(): if int(pausas[k])<=limite: pausas.erase(k)
	pausas[_clave_pausa(maestro,alumno,id)] = int(j.d.min)

## Enseñanza directa con un jugador, instantánea: el habitante enseña al jugador (`hacia_jugador`) o aprende de él.
## Valida en el servidor cercanía, saber del maestro, preparación y voluntad del habitante.
func leccion_jugador(nid: String, saber: String, id: String, hacia_jugador: bool) -> Dictionary:
	if not activa() or not j.habitantes.ids.has(nid): return j._no("No hay nadie que pueda enseñar aquí",id)
	if j.habitantes.pos(nid).distance_to(j.pies_de(id))>j.ALCANCE_NPC: return j._no("Acércate a quien quieres enseñar o escuchar",id)
	if _descansa(nid): return j._no("Ahora descansa",id)
	var yo: String = j.actor_desarrollo(id)
	var npc := "npc:"+nid
	sembrar(npc)
	var gid: String = a.sociedad.grupo_de(nid)
	if gid!="" and a.sociedad.reputacion(gid,id)<int(sab.ensenanza.reputacion_min): return j._no("No confía lo bastante en ti",id)
	var maestro: String = npc if hacia_jugador else yo
	var alumno: String = yo if hacia_jugador else npc
	var motivo := _motivo_no_ensena(maestro,alumno,saber)
	if motivo!="": return j._no(motivo,id)
	if not aprender(alumno,saber,"ensenanza",maestro): return j._no("No se pudo completar la lección",id)
	var nombre := _nombre_saber(saber)
	a._recordar(nid,"enseno" if hacia_jugador else "aprendio",nombre,id)
	a.sociedad.suceso("ensenanza",nombre,nid if hacia_jugador else id,id if hacia_jugador else nid)
	return j._ok(("Aprendes %s" if hacia_jugador else "Enseñas %s") % nombre,id)

## Experimentación de NPC con excedentes, recetas descubiertas y mesa accesible.
func decidir(nid: String) -> bool:
	if not activa(): return false
	var actor := "npc:"+nid
	sembrar(actor)
	if _ampliar(nid): return true
	if _ensenar(nid): return true
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


## Adaptador regional de la enseñanza existente: misma confianza, disponibilidad y reloj.
## No observa cofres para aprender. Las recetas siguen en la identidad del residente.
func ensenar_regional(p: Dictionary, ocupados: Dictionary) -> void:
	if not activa() or not j.es_autoridad(): return
	var s = a.asentamientos
	if int(s.inventario(p).get("baya",0))<=0 or int(p.get("deuda_comida",0))>0: return
	var ens: Dictionary=sab.ensenanza
	var ahora := int(j.d.min)
	var alumnos: Array=p.residentes.duplicate()
	alumnos.sort_custom(func(x,y):return str(x.id)<str(y.id))
	var maestros: Array=alumnos.duplicate()
	var centro := Vector2i(p.celda[0],p.celda[1])
	for nid in j.habitantes.ids:
		var n: Dictionary=a.estado(nid)
		if float(n.hambre)>=float(a.reglas.umbral_comer) or _descansa(nid) or not n.get("plan",{}).is_empty() or ahora-int(n.accion_min)<int(a.reglas.intervalo_accion_min): continue
		if M.celda_de(j.habitantes.pos(nid)).distance_to(centro)>float(ens.radio_leccion_celdas): continue
		maestros.append({"id":nid,"recetas":a.recetas_de(nid),"detallado":true})
	maestros.sort_custom(func(x,y):return str(x.id)<str(y.id))
	for maestro in maestros:
		if ocupados.has(maestro.id) or maestro.has("reserva_viaje"): continue
		var clave := "recetas:"+str(maestro.id)
		var lecciones: Dictionary=datos().lecciones
		var leccion: Dictionary=lecciones.get(clave,{})
		if not leccion.is_empty():
			var presente := false
			for alumno in alumnos:
				if alumno.id==leccion.alumno and not alumno.has("reserva_viaje") and not ocupados.has(alumno.id) and not leccion.saber in alumno.get("recetas",[]) and a.sociedad.confianza(maestro.id,alumno.id)>=int(ens.confianza_min) and a.sociedad.confianza(alumno.id,maestro.id)>=int(ens.confianza_min): presente=true
			if not presente or ahora-int(leccion.ultimo)>int(ens.espera_max_min) or not leccion.saber in maestro.get("recetas",[]):
				_pausar(clave,str(leccion.alumno),str(leccion.saber))
				lecciones.erase(clave);leccion={}
		if leccion.is_empty():
			var recetas: Array=maestro.get("recetas",[]).duplicate();recetas.sort()
			for alumno in alumnos:
				if alumno.id==maestro.id or alumno.has("reserva_viaje") or ocupados.has(alumno.id): continue
				if a.sociedad.confianza(maestro.id,alumno.id)<int(ens.confianza_min) or a.sociedad.confianza(alumno.id,maestro.id)<int(ens.confianza_min): continue
				for rid in recetas:
					if not C.RECETAS.has(rid) or rid in alumno.get("recetas",[]): continue
					# Las exigencias de habilidades/herramientas conservan su filtro de ejecución.
					if ahora-int(datos().pausas.get(_clave_pausa(clave,alumno.id,rid),-1000000))<int(ens.enfriamiento_min): continue
					leccion={"alumno":alumno.id,"saber":rid,"avance":0,"ultimo":ahora,"puesto":p.id}
					lecciones[clave]=leccion;break
				if not leccion.is_empty(): break
		if leccion.is_empty() or leccion.get("puesto","")!=p.id: continue
		ocupados[maestro.id]=true;ocupados[leccion.alumno]=true
		if maestro.get("detallado",false):
			a.estado(maestro.id).accion_min=ahora
			a.estado(maestro.id).regional_ocupado_min=ahora
		leccion.avance=int(leccion.avance)+mini(int(ens.paso_max_min),maxi(0,ahora-int(leccion.ultimo)))
		leccion.ultimo=ahora
		if int(leccion.avance)<int(ens.minutos): continue
		for alumno in alumnos:
			if alumno.id!=leccion.alumno: continue
			alumno.get_or_add("recetas",[]).append(leccion.saber)
			alumno.get_or_add("aprendizajes",{})[leccion.saber]={"fuente":"ensenanza","maestro":maestro.id,"min":ahora}
			a.sociedad._vinculo(maestro.id,alumno.id,int(ens.ganancia_confianza))
			a.sociedad._vinculo(alumno.id,maestro.id,int(ens.ganancia_confianza))
			a.sociedad.suceso("ensenanza",str(leccion.saber),maestro.id,alumno.id)
		lecciones.erase(clave)
