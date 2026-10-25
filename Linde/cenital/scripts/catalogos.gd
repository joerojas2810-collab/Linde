extends RefCounted
# Catálogos de datos. TODO valor aquí es PROVISIONAL (propio, sin balance heredado) salvo nota.
# Unidades: golpes = nº de golpes; coste/ent/sal = unidades de ítem; hp/dmg = puntos; horas = horas de juego.

const MAX_SLOTS_BASE := 20      # pilas de inventario
const NIVEL_MAX := 10
const MIN_POR_SEG := 1.0        # minutos de juego por segundo real (día = 24 min)
const HP_BASE := 40
const DMG_BASE := 5

const ITEMS := {
	"candado": {"n": "Candado", "pila": 10, "c": "#cfd3da"},
	"madera": {"n": "Madera", "pila": 50, "c": "#8a5a2b"},
	"piedra": {"n": "Piedra", "pila": 50, "c": "#8e8e96"},
	"fibra": {"n": "Fibra", "pila": 50, "c": "#7bb04a"},
	"mena": {"n": "Mena de hierro", "pila": 50, "c": "#b5651d"},
	"lingote": {"n": "Lingote", "pila": 50, "c": "#cfd3da"},
	"ladrillo": {"n": "Ladrillo", "pila": 50, "c": "#b5533c"},
	"cobre": {"n": "Mena de cobre", "pila": 50, "c": "#c8742f"},
	"lingote_cobre": {"n": "Lingote de cobre", "pila": 50, "c": "#d98a4a"},
	"arcilla": {"n": "Arcilla", "pila": 50, "c": "#a8664a"},
	"baya": {"n": "Baya", "pila": 20, "c": "#c0305a", "cura": 8},
	"gelatina": {"n": "Gelatina", "pila": 20, "c": "#5fd0a0"},
	"unguento": {"n": "Ungüento", "pila": 10, "c": "#e0e07a", "cura": 30},
	"gema": {"n": "Gema", "pila": 20, "c": "#6ad0f0"},
	"hacha_piedra": {"n": "Hacha de piedra", "pila": 1, "c": "#a0784a", "tag": "talar"},
	"pico_piedra": {"n": "Pico de piedra", "pila": 1, "c": "#9a9aa6", "tag": "picar"},
	"espada_hierro": {"n": "Espada de hierro", "pila": 1, "c": "#e0e4ea", "equipo": "arma", "def": 0, "dmg": 6, "paleta": "pal_espada_hierro"},
	# Escudo (PROVISIONAL): "equipo" = ranura, "def" plana. Las piezas de set (casco..pantalones) no están aquí: son
	# claves `eq:...` derivadas de datos/equipo/*.json y se resuelven con Equipo.info (scripts/equipo.gd).
	"escudo_madera": {"n": "Escudo de madera", "pila": 1, "c": "#9b6b3a", "equipo": "escudo", "def": 3, "paleta": "pal_escudo_madera"},
}
const RANURAS := ["casco", "torso", "guantes", "botas", "pantalones", "escudo", "arma"]   # 5 de set + escudo + arma (coraza -> torso)

# golpes por etiqueta de herramienta ("" = a mano; ausente = imposible). prob: botín probabilístico con flujo propio.
const OBJETOS := {
	"arbol": {"n": "Árbol", "golpes": {"": 6, "talar": 3}, "drops": {"madera": 3}, "prob": [], "regen_h": 0, "bloquea": true, "xp": 2},
	"roca": {"n": "Roca", "golpes": {"": 10, "picar": 4}, "drops": {"piedra": 2}, "prob": [], "regen_h": 0, "bloquea": true, "xp": 2},
	"veta": {"n": "Veta de mena", "golpes": {"picar": 6}, "drops": {"mena": 2}, "prob": [{"item": "gema", "q": 1, "p": 0.25}], "regen_h": 0, "bloquea": true, "xp": 4},
	"arbusto": {"n": "Arbusto", "golpes": {"": 1}, "drops": {"fibra": 2}, "prob": [{"item": "baya", "q": 1, "p": 0.5}], "regen_h": 24, "bloquea": false, "xp": 0},
	# Solo aparecen fuera del valle (terreno_v1): dan motivo para explorar.
	"veta_cobre": {"n": "Veta de cobre", "golpes": {"picar": 5}, "drops": {"cobre": 2}, "prob": [{"item": "gema", "q": 1, "p": 0.15}], "regen_h": 0, "bloquea": true, "xp": 3},
	"arcilla": {"n": "Pozo de arcilla", "golpes": {"": 8, "picar": 3}, "drops": {"arcilla": 3}, "prob": [], "regen_h": 0, "bloquea": true, "xp": 2},
}

# bloquea: ocupa la celda. est: estación de fabricación. propia: la pone/retira el jugador.
const CONSTR := {
	"muro": {"n": "Muro", "coste": {"madera": 2}, "bloquea": true, "c": "#a8794f"},
	"muro_ladrillo": {"n": "Muro de ladrillo", "coste": {"ladrillo": 2}, "bloquea": true, "c": "#b5533c"},
	"suelo": {"n": "Suelo de madera", "coste": {"madera": 1}, "bloquea": false, "c": "#9b7a52"},
	"mesa": {"n": "Mesa de trabajo", "coste": {"madera": 5, "piedra": 2}, "bloquea": true, "est": "mesa", "c": "#7a5530"},
	"horno": {"n": "Horno", "coste": {"piedra": 8}, "bloquea": true, "est": "horno", "c": "#6c6c74"},
	"cofre": {"n": "Cofre", "coste": {"madera": 4}, "bloquea": true, "cofre": true, "c": "#c08a2b"},
	"cama": {"n": "Cama", "coste": {"madera": 4, "fibra": 4}, "bloquea": true, "cama": true, "c": "#b84a5a"},
	"cama_huesped": {"n": "Cama de huésped", "coste": {"madera": 4, "fibra": 3}, "bloquea": true, "c": "#4a8fb8"},   # sin "cama": no sirve para dormir; la asigna Mundo vivo
}
const ORDEN_CONSTR := ["muro", "muro_ladrillo", "suelo", "mesa", "horno", "cofre", "cama", "cama_huesped"]

# est: estación cercana (≤2 celdas); herr: ítem requerido sin consumir; hab: habilidad requerida.
const RECETAS := {
	"candado": {"n": "Candado", "ent": {"lingote": 2, "fibra": 2}, "sal": {"candado": 1}, "est": "mesa", "herr": "", "hab": ""},
	"hacha_piedra": {"n": "Hacha de piedra", "ent": {"piedra": 2, "madera": 2, "fibra": 1}, "sal": {"hacha_piedra": 1}, "est": "", "herr": "", "hab": ""},
	"pico_piedra": {"n": "Pico de piedra", "ent": {"piedra": 3, "madera": 2, "fibra": 1}, "sal": {"pico_piedra": 1}, "est": "", "herr": "", "hab": ""},
	"unguento": {"n": "Ungüento", "ent": {"gelatina": 2, "fibra": 1}, "sal": {"unguento": 1}, "est": "mesa", "herr": "", "hab": ""},
	"lingote": {"n": "Lingote", "ent": {"mena": 2, "madera": 1}, "sal": {"lingote": 1}, "est": "horno", "herr": "", "hab": "artesano"},
	"ladrillo": {"n": "Ladrillo", "ent": {"piedra": 2, "fibra": 1}, "sal": {"ladrillo": 2}, "est": "horno", "herr": "", "hab": ""},
	"lingote_cobre": {"n": "Lingote de cobre", "ent": {"cobre": 2, "madera": 1}, "sal": {"lingote_cobre": 1}, "est": "horno", "herr": "", "hab": "artesano"},
	"ladrillo_arcilla": {"n": "Ladrillo de arcilla", "ent": {"arcilla": 2}, "sal": {"ladrillo": 3}, "est": "horno", "herr": "", "hab": ""},
	"espada_hierro": {"n": "Espada de hierro", "ent": {"lingote": 2, "madera": 1}, "sal": {"espada_hierro": 1}, "est": "mesa", "herr": "", "hab": "artesano"},
	# Escudo (PROVISIONAL). Las recetas de piezas de Vigía y de la Chispa se generan desde datos (Equipo.recetas()).
	"escudo_madera": {"n": "Escudo de madera", "ent": {"madera": 6, "fibra": 2}, "sal": {"escudo_madera": 1}, "est": "mesa", "herr": "", "hab": ""},
}

const HAB := {
	"recolector": {"n": "Recolector", "rama": "oficio", "req": [], "coste": 1, "niv": 2, "efe": {"golpes_menos": 1}},
	"mochila": {"n": "Mochila grande", "rama": "oficio", "req": ["recolector"], "coste": 1, "niv": 3, "efe": {"slots": 8}},
	"artesano": {"n": "Artesano", "rama": "oficio", "req": ["recolector"], "coste": 1, "niv": 3, "efe": {}},
	"pies_ligeros": {"n": "Pies ligeros", "rama": "exploracion", "req": [], "coste": 1, "niv": 2, "efe": {"vel": 0.15}},
	"explorador": {"n": "Explorador", "rama": "exploracion", "req": ["pies_ligeros"], "coste": 2, "niv": 4, "efe": {"vel": 0.10, "slots": 4}},
	"golpe_fuerte": {"n": "Golpe fuerte", "rama": "combate", "req": [], "coste": 1, "niv": 2, "efe": {"dmg": 3}},
	"vitalidad": {"n": "Vitalidad", "rama": "combate", "req": [], "coste": 1, "niv": 2, "efe": {"hp": 20}},
	"dominio": {"n": "Dominio del combate", "rama": "combate", "req": ["golpe_fuerte", "vitalidad"], "coste": 2, "niv": 4, "efe": {"dmg": 3, "hp": 20}},
}

# Combate (A01 PENDIENTE: modelo provisional en tiempo real, ver docs/DECISIONES.md).
# aviso = segundos de señal previa antes del impacto; rec = recuperación tras atacar.
const ENEMIGOS := {
	"espectro_bosque": {"n": "Espectro del bosque", "hp": 20, "vel": 24.0, "vision": 96.0, "aviso": 0.9, "rec": 1.2, "dmg": 5, "radio": 18.0, "xp": 12, "drops": {"fibra": 2}, "tam": 14, "conducta": "hostil"},
	"golem_sierra": {"n": "Gólem de la sierra", "hp": 38, "vel": 15.0, "vision": 80.0, "aviso": 1.2, "rec": 1.5, "dmg": 8, "radio": 22.0, "xp": 18, "drops": {"piedra": 3}, "tam": 18, "conducta": "defensivo"},
	"diablillo_secano": {"n": "Diablillo del secano", "hp": 16, "vel": 32.0, "vision": 104.0, "aviso": 0.65, "rec": 0.9, "dmg": 5, "radio": 16.0, "xp": 12, "drops": {"arcilla": 2}, "tam": 12, "conducta": "hostil"},
	"arpia_pradera": {"n": "Arpía de pradera", "hp": 18, "vel": 38.0, "vision": 88.0, "aviso": 0.8, "rec": 1.0, "dmg": 4, "radio": 17.0, "xp": 10, "drops": {"fibra": 2}, "tam": 12, "conducta": "huidizo"},
	"slime_ribera": {"n": "Slime de ribera", "hp": 16, "vel": 22.0, "vision": 40.0, "aviso": 0.8, "rec": 1.0, "dmg": 4, "radio": 16.0, "xp": 9, "drops": {"gelatina": 2}, "tam": 12, "conducta": "territorial"},
	"slime": {"n": "Slime", "hp": 12, "vel": 28.0, "vision": 80.0, "aviso": 0.5, "rec": 0.8, "dmg": 4, "radio": 14.0,
		"xp": 8, "drops": {"gelatina": 1}, "tam": 12},
	"guardian": {"n": "Guardián de las Ruinas", "hp": 80, "vel": 22.0, "vision": 140.0, "tipo": "capitulo", "xp": 100,
		"fases": [{"desde": 1.0, "ataques": ["embestida"]}, {"desde": 0.5, "ataques": ["embestida", "onda"]}], "tam": 28,
		"recompensa": {"gema": 3}, "reaparece_h": 0},
	"ciervo": {"n": "Gran Ciervo del Claro", "hp": 60, "vel": 26.0, "vision": 140.0, "tipo": "mundo", "xp": 80,
		"fases": [{"desde": 1.0, "ataques": ["embestida"]}, {"desde": 0.4, "ataques": ["pisoton", "embestida"]}], "tam": 26,
		"recompensa": {"gema": 2, "fibra": 10}, "reaparece_h": 72},
}
# Ataques de jefe: aviso s, rec s, dmg, forma (linea: largo/ancho px; circulo: radio px).
const ATAQUES := {
	"embestida": {"aviso": 0.8, "rec": 1.0, "dmg": 10, "forma": "linea", "largo": 70.0, "ancho": 16.0, "avance": 70.0},
	"onda": {"aviso": 1.0, "rec": 1.2, "dmg": 12, "forma": "circulo", "radio": 44.0},
	"pisoton": {"aviso": 0.9, "rec": 1.1, "dmg": 9, "forma": "circulo", "radio": 36.0},
}
# Estados de animación del jugador (PROVISIONAL: cuadros y tiempos por confirmar con el arte).
# "dur": segundos POR CUADRO en caminar; segundos TOTALES en herramienta y dano; en ataque son segundos por fase (cuadro 0/1/2).
# caida y dormir están declarados pero aún no se usan (el flujo de derrota y de dormir no cambia).
const ANIM_PJ := {
	"reposo": {"cuadros": 1},
	"caminar": {"cuadros": 4, "dur": 0.12},                       # = P.PASO_S
	"herramienta": {"cuadros": 3, "dur": 0.3},                    # total = cd_obj
	"ataque": {"cuadros": 4, "aviso": 0.10, "activo": 0.10, "rec": 0.25},  # = PJ_ATAQUE; aviso = cuadros 0 y 1 (anim_pj.gd)
	"dano": {"cuadros": 2, "dur": 0.6},                           # total = INVULN_S
	"caida": {"cuadros": 2},                                      # sin usar
	"dormir": {"cuadros": 1},                                     # sin usar
}
const PJ_ATAQUE := {"aviso": 0.10, "activo": 0.10, "rec": 0.25, "alcance": 18.0, "ancho": 20.0}  # s, px

# Misiones. objetivos: visita(evento, historico) | tener(item,n, actual) | construccion(pieza,n, actual)
# | derrotar(jefe, historico) | hablar(npc, historico) | abrir(cofre, historico). consume: ítems que se entregan.
const MISIONES := {
	"cap1_piedras": {"n": "Piedras para el taller", "tipo": "capitulo", "da": "maren", "req": [],
		"obj": [{"t": "hablar", "npc": "maren"}, {"t": "tener", "item": "piedra", "n": 6}], "consume": {"piedra": 6},
		"rec": {"xp": 20, "items": {"madera": 5}}},
	"cap1_mesa": {"n": "Una mesa para Maren", "tipo": "capitulo", "da": "maren", "req": ["cap1_piedras"],
		"obj": [{"t": "construccion", "pieza": "mesa", "n": 1}], "consume": {},
		"rec": {"xp": 30, "items": {"mena": 2}}},
	"cap1_ruinas": {"n": "Las ruinas de la cantera", "tipo": "capitulo", "da": "maren", "req": ["cap1_mesa"],
		"obj": [{"t": "visita", "evento": "visito_ruinas"}, {"t": "derrotar", "jefe": "guardian"}], "consume": {},
		"rec": {"xp": 100, "items": {"gema": 2}}},
	"mundo_tesoro": {"n": "Algo guardado en la cantera", "tipo": "mundo", "da": "", "req": [],
		"obj": [{"t": "abrir", "cofre": "tesoro_cantera"}], "consume": {}, "rec": {"xp": 15, "items": {}}},
	"mundo_ciervo": {"n": "El Gran Ciervo del claro", "tipo": "mundo", "da": "", "req": [],
		"obj": [{"t": "derrotar", "jefe": "ciervo"}], "consume": {}, "rec": {"xp": 60, "items": {}}},
}

# Validación de referencias y alcanzabilidad. Devuelve lista de errores (vacía = ok).
static func validar() -> Array:
	var e: Array = []
	for id in RECETAS:
		var r: Dictionary = RECETAS[id]
		for k in r.ent: if not ITEMS.has(k): e.append("receta %s: ent %s" % [id, k])
		for k in r.sal: if not ITEMS.has(k): e.append("receta %s: sal %s" % [id, k])
		if r.hab != "" and not HAB.has(r.hab): e.append("receta %s: hab %s" % [id, r.hab])
		if r.est != "" and not _hay_estacion(r.est): e.append("receta %s: estación %s sin pieza" % [id, r.est])
		if r.herr != "" and not ITEMS.has(r.herr): e.append("receta %s: herr %s" % [id, r.herr])
	for id in ITEMS:
		if ITEMS[id].has("equipo") and (not ITEMS[id].equipo in RANURAS or typeof(ITEMS[id].get("def")) != TYPE_INT): e.append("item %s: equipo/def" % id)
	for id in CONSTR:
		for k in CONSTR[id].coste: if not ITEMS.has(k): e.append("constr %s: %s" % [id, k])
	for id in OBJETOS:
		for k in OBJETOS[id].drops: if not ITEMS.has(k): e.append("objeto %s: drop %s" % [id, k])
		for p in OBJETOS[id].prob: if not ITEMS.has(p.item): e.append("objeto %s: prob %s" % [id, p.item])
		for tag in OBJETOS[id].golpes:
			if tag != "" and not _hay_herramienta(tag): e.append("objeto %s: sin herramienta %s" % [id, tag])
	for id in HAB:
		for q in HAB[id].req: if not HAB.has(q): e.append("hab %s: req %s" % [id, q])
	e.append_array(_ciclos_hab())
	e.append_array(_alcanzables_hab())
	for id in ENEMIGOS:
		for k in ENEMIGOS[id].get("drops", {}): if not ITEMS.has(k): e.append("enemigo %s: %s" % [id, k])
		for k in ENEMIGOS[id].get("recompensa", {}): if not ITEMS.has(k): e.append("enemigo %s: rec %s" % [id, k])
		for f in ENEMIGOS[id].get("fases", []):
			for a in f.ataques: if not ATAQUES.has(a): e.append("enemigo %s: ataque %s" % [id, a])
	for id in MISIONES:
		var m: Dictionary = MISIONES[id]
		for q in m.req: if not MISIONES.has(q): e.append("misión %s: req %s" % [id, q])
		for o in m.obj:
			if o.t == "tener" and not ITEMS.has(o.item): e.append("misión %s: item %s" % [id, o.item])
			if o.t == "construccion" and not CONSTR.has(o.pieza): e.append("misión %s: pieza %s" % [id, o.pieza])
			if o.t == "derrotar" and not ENEMIGOS.has(o.jefe): e.append("misión %s: jefe %s" % [id, o.jefe])
		for k in m.consume: if not ITEMS.has(k): e.append("misión %s: consume %s" % [id, k])
		for k in m.rec.items: if not ITEMS.has(k): e.append("misión %s: rec %s" % [id, k])
		for k in m.consume: if m.consume[k] > ITEMS[k].pila * MAX_SLOTS_BASE: e.append("misión %s: consume > capacidad" % id)
	var Eq = load("res://scripts/equipo.gd")     # load y no preload: equipo.gd ya precarga este script
	e.append_array(Eq.validar_datos(Eq.datos()))    # incluye paletas.json (Eq.validar_paletas)
	for id in Eq.recetas():
		if RECETAS.has(id) and Eq.recetas()[id] != RECETAS[id]: e.append("receta %s: id duplicado entre código y datos" % id)
	return e

static func _hay_estacion(est: String) -> bool:
	for id in CONSTR: if CONSTR[id].get("est", "") == est: return true
	return false

static func _hay_herramienta(tag: String) -> bool:
	for id in ITEMS: if ITEMS[id].get("tag", "") == tag: return true
	return false

static func _ciclos_hab() -> Array:
	var e: Array = []
	for id in HAB:
		var vistos := {}
		var pila: Array = [id]
		while not pila.is_empty():
			var x: String = pila.pop_back()
			for q in HAB[x].req:
				if q == id: e.append("ciclo en hab %s" % id)
				if not vistos.has(q) and HAB.has(q):
					vistos[q] = true
					pila.append(q)
	return e

# Cada nodo debe poder comprarse con los puntos del nivel máximo (1 punto por nivel > 1).
static func _alcanzables_hab() -> Array:
	var e: Array = []
	for id in HAB:
		var coste := 0
		var niv := 1
		var vistos := {}
		var pila: Array = [id]
		while not pila.is_empty():
			var x: String = pila.pop_back()
			if vistos.has(x) or not HAB.has(x): continue
			vistos[x] = true
			coste += HAB[x].coste
			niv = maxi(niv, HAB[x].niv)
			pila.append_array(HAB[x].req)
		if niv > NIVEL_MAX or coste > NIVEL_MAX - 1: e.append("hab %s inalcanzable (coste %d, nivel %d)" % [id, coste, niv])
	return e

static func umbral_xp(nivel: int) -> int:    # xp mínima para ese nivel; provisional
	return 25 * (nivel - 1) * (nivel - 1)

static func nivel_de(xp: int) -> int:
	var n := 1
	while n < NIVEL_MAX and xp >= umbral_xp(n + 1): n += 1
	return n

# Texto de PRUEBA para ejercitar sistemas; no es canon (A02 pendiente).
const DIALOGOS := {
	"cap1_piedras": {"oferta": "Soy Maren. El taller se quedó sin piedra para cimientos. ¿Me traes seis? Una pica o un pico de piedra ayudan.",
		"recordar": "Aún necesito esas piedras para el taller.", "gracias": "Justo lo que hacía falta. Toma, para tus primeras construcciones."},
	"cap1_mesa": {"oferta": "Sin una mesa de trabajo no puedo enseñarte nada. ¿Puedes construir una?",
		"recordar": "Sin mesa no avanzamos; constrúyela donde quieras.", "gracias": "Buena mesa. Con esto podemos trabajar el metal."},
	"cap1_ruinas": {"oferta": "La cantera saca mena rara desde que algo despertó en las ruinas del sureste. Ve a mirar y detén lo que haya allí.",
		"recordar": "Las ruinas están al sureste, tras el camino del estanque.", "gracias": "Lo lograste. El taller y la cantera vuelven a respirar."},
	"base": ["Buen día. El taller siempre tiene algo por hacer.", "Si construyes, cuida de no cerrar los caminos.", "Descansa en tu propia cama; la mía es la mía."],
	"final": "Gracias por todo. Quizá haya más que descubrir en el bosque."
}
