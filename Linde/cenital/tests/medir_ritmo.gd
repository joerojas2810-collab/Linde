extends SceneTree
## Ritmo de la experiencia inicial (Fase 0 de Mundo 1): cuánto tarda un «jugador de referencia» en cada hito.
## Uso:  Godot --headless --path Linde/cenital -s res://tests/medir_ritmo.gd -- semilla=123 limite_s=3600
## El jugador de referencia usa la API REAL de Juego (golpear_objeto, fabricar, construir, aprender), con las reglas reales,
## y avanza el mundo con `Juego.tick` mientras actúa (los habitantes compiten por los recursos). Tiempos en segundos de juego;
## 1 s real = 1 minuto de juego, así que «segundos» equivale a minutos reales de partida dividido por 60.
## Política (voraz, fija, sin elegir): recoge lo que falta con el objeto accesible más cercano.
## Limitaciones (la medición es una COTA INFERIOR de lo que tarda una persona): sin combate (se desactiva); sin tiempo de
## menús, lectura ni dudas; cada golpe cuesta 0,3 s (el enfriamiento de Juego.accion) y un desplazamiento es teletransporte
## con coste de 1/(4·vel) s por celda de la ruta más corta (VELOCIDAD 64 px/s); fabricar y construir son instantáneos.
## Los hitos son los pedidos al diagnóstico; no son objetivos para el jugador (M1-D8).
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const C = preload("res://scripts/catalogos.gd")
const P = preload("res://scripts/params.gd")
const Com = preload("res://tests/medir_comun.gd")
const GOLPE_S := 0.3
const FUENTE := {"madera": "arbol", "piedra": "roca", "fibra": "arbusto", "mena": "veta"}
var j
var t := 0.0
var _pend := 0.0
var golpes := 0
var celdas := 0
var objetos := 0
var limite := 3600.0
var semilla := 0
var estacion := {}   # tipo -> celda
var agotado := false
var ultimo := ""   # motivo del último fallo, para el informe

func _init() -> void:
	var a := Com.args({"semilla": "123", "limite_s": "3600"})
	semilla = int(a.semilla)
	limite = float(a.limite_s)
	var c0 := Time.get_ticks_usec()
	j = J.nueva(semilla, "Referencia", [0, 0, 0])
	j.combate.enemigos.clear()
	Com.linea("MEDIDA_CONFIG", {"herramienta": "medir_ritmo", "semilla": semilla, "limite_s": limite, "golpe_s": GOLPE_S, "celdas_por_s": P.VELOCIDAD / P.CELDA,
		"combate": "desactivado", "politica": "voraz_fija", "inicio": "%d,%d" % [M.celda_de(j.pies_de()).x, M.celda_de(j.pies_de()).y],
		"habitantes_iniciales": j.habitantes.ids.size(), "godot": Engine.get_version_info().string})
	_hito("inicio")
	_recursos_restantes("inicio")
	_paso("primera_fibra", _tener("fibra", 1))
	_paso("hacha_piedra", _tener_todo({"piedra": 2, "madera": 2, "fibra": 1}) and _fab("hacha_piedra"))
	_paso("pico_piedra", _tener_todo({"piedra": 3, "madera": 2, "fibra": 1}) and _fab("pico_piedra"))
	_paso("mesa", _tener_todo({"madera": 5, "piedra": 2}) and _poner("mesa"))
	_paso("horno", _tener("piedra", 8) and _poner("horno"))
	# Progresión: recoger árboles, rocas y vetas (todo da experiencia) hasta el nivel necesario para «recolector» (2) y «artesano» (3).
	var previo: int = j.nivel()
	var alterna := 0
	var motivo_bucle := ""
	var guarda := 0   # tope de iteraciones: si no queda nada accesible no se avanza el reloj y el bucle no terminaría
	var seguidos := 0   # fallos consecutivos: con 3 tipos, 6 seguidos significa que ya no queda nada accesible
	while j.nivel() < 3 and not agotado and guarda < 400 and seguidos < 6:
		guarda += 1
		if _picar(["arbol", "roca", "veta"][alterna % 3]): seguidos = 0
		else:
			motivo_bucle = ultimo
			seguidos += 1
		alterna += 1
		if j.nivel() > previo:
			previo = j.nivel()
			_hito("nivel_%d" % previo)
	if j.nivel() >= 3:
		var r1: Dictionary = j.aprender("recolector")
		var r2: Dictionary = j.aprender("artesano")
		ultimo = "%s | %s" % [r1.msg, r2.msg]
		_paso("artesano", r1.ok and r2.ok)
	else:
		ultimo = "nivel %d tras %d iteraciones; ultimo fallo: %s" % [j.nivel(), guarda, motivo_bucle]
		_paso("artesano", false)
	var mena := _tener_todo({"mena": 2, "madera": 1})
	_paso("mena_de_hierro", mena)
	_paso("lingote", mena and _volver("horno") and _fab("lingote"))
	_paso("llegada_a_la_salida", _ir_a(M.ENTRADA))
	_paso("fuera_del_valle", _ir_a(Vector2i(M.ENTRADA.x, M.ENTRADA.y + 12), Rect2i(0, 0, M.ANCHO, M.ALTO + 24)))
	_paso("regreso_a_la_casa", _ir_a(M.PUERTA_C + Vector2i(0, 1), Rect2i(0, 0, M.ANCHO, M.ALTO + 24)))
	_recursos_restantes("final")
	var r: Dictionary = Com.resumen_npc(j)
	var kv := {"semilla": semilla, "tiempo_total_s": snappedf(t, 0.1), "limite_alcanzado": agotado, "nivel": j.nivel(), "xp": j.jug().xp, "golpes": golpes,
		"celdas_recorridas": celdas, "objetos_rotos": objetos, "hash_estado": Com.hash_estado(j)}
	kv.merge(r)
	Com.linea("MEDIDA_ESTADO", kv)
	Com.linea("MEDIDA_CPU", {"semilla": semilla, "script_ms": snappedf((Time.get_ticks_usec() - c0) / 1000.0, 1)})
	quit(0)

## Registra el hito si se logró; si no, el motivo (las dependencias posteriores siguen intentándose).
func _paso(nombre: String, ok: bool) -> void:
	if ok: _hito(nombre)
	else: Com.linea("MEDIDA_FALLO", {"semilla": semilla, "hito": nombre, "t_s": snappedf(t, 0.1), "motivo": ultimo.replace(" ", "_")})

func _hito(nombre: String) -> void:
	Com.linea("MEDIDA_HITO", {"semilla": semilla, "hito": nombre, "t_s": snappedf(t, 0.1), "t_min_reales": snappedf(t / 60.0, 0.01), "golpes": golpes,
		"celdas": celdas, "objetos": objetos, "nivel": j.nivel(), "xp": j.jug().xp, "hora_juego": "%02d:%02d" % [(int(j.d.min) / 60) % 24, int(j.d.min) % 60]})

func _avanzar(dt: float) -> void:
	t += dt
	_pend += dt
	while _pend >= 0.5:
		_pend -= 0.5
		j.tick(0.5)
	if t >= limite: agotado = true

func _celda() -> Vector2i:
	return M.celda_de(j.pies_de())

func _llevar(path: Array) -> void:
	var pasos := maxi(0, path.size() - 1)
	celdas += pasos
	_avanzar(float(pasos) / (P.VELOCIDAD / P.CELDA * float(j.stats().vel)))
	j.rt[J.LOCAL].pies = M.pies_de_celda(path[-1])
	j.actualizar_regiones()

func _ir_junto(c: Vector2i) -> bool:
	var path: Array = j.mundo.camino(_celda(), func(x): return j.mundo.es_adyacente(x, c))
	if path.is_empty(): return false
	_llevar(path)
	return true

func _ir_a(c: Vector2i, area: Rect2i = Rect2i()) -> bool:
	var path: Array = j.mundo.camino(_celda(), func(x): return x == c, area)
	if path.is_empty(): return false
	_llevar(path)
	return true

## Rompe el objeto accesible más cercano del tipo dado. false si no hay o si falta herramienta.
func _picar(tipo: String) -> bool:
	if agotado: return false
	var cand: Array = []
	var origen := _celda()
	for oid in j.mundo.objetos:
		var o: Dictionary = j.mundo.objetos[oid]
		if o.t != tipo or j.mundo.objeto_presente(o.c) != oid: continue
		cand.append([absi(o.c.x - origen.x) + absi(o.c.y - origen.y), oid, o.c])
	cand.sort()
	for k in mini(60, cand.size()):
		var c: Vector2i = cand[k][2]
		if not _ir_junto(c): continue
		for i in 40:
			var r: Dictionary = j.golpear_objeto(c)
			golpes += 1
			_avanzar(GOLPE_S)
			if not r.ok:
				ultimo = "golpear %s: %s" % [tipo, r.msg]
				return false
			if j.mundo.objeto_presente(c) == "":
				objetos += 1
				return true
		ultimo = "golpes_sin_romper_%s" % tipo
		return false
	ultimo = "sin_%s_accesible" % tipo
	return false

func _tener(item: String, n: int) -> bool:
	var intentos := 0
	while int(j.jug().inv.get(item, 0)) < n:
		if agotado or intentos > 60 or not _picar(FUENTE[item]): return false
		intentos += 1
	return true

func _tener_todo(req: Dictionary) -> bool:
	for it in req:
		if not _tener(it, int(req[it])): return false
	return true

func _fab(receta: String) -> bool:
	var r: Dictionary = j.fabricar(receta)
	if not r.ok: ultimo = "fabricar %s: %s" % [receta, r.msg]
	return r.ok

## Coloca una estación en la celda libre más cercana al jugador.
func _poner(pieza: String) -> bool:
	var base := _celda()
	for radio in range(1, 4):
		for dy in range(-radio, radio + 1):
			for dx in range(-radio, radio + 1):
				if maxi(absi(dx), absi(dy)) != radio: continue
				var c := base + Vector2i(dx, dy)
				if j.mundo.puede_poner(c) != "": continue
				var r: Dictionary = j.construir(pieza, c)
				if r.ok:
					estacion[pieza] = c
					return true
	ultimo = "sin_celda_libre_para_%s" % pieza
	return false

func _volver(pieza: String) -> bool:
	return estacion.has(pieza) and _ir_junto(estacion[pieza])

## Objetos del Valle que quedan y cuántos son alcanzables desde donde está el jugador (los recursos no vuelven a crecer salvo el arbusto).
func _recursos_restantes(momento: String) -> void:
	var alc: Dictionary = j.mundo.alcanzables(_celda())
	for tipo in ["arbol", "roca", "veta", "arbusto"]:
		var presentes := 0
		var accesibles := 0
		for oid in j.mundo.objetos:
			var o: Dictionary = j.mundo.objetos[oid]
			if o.t != tipo or not M.es_valle(o.c) or j.mundo.objeto_presente(o.c) != oid: continue
			presentes += 1
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if alc.has(o.c + d):
					accesibles += 1
					break
		Com.linea("MEDIDA_ESTADO", {"semilla": semilla, "momento": momento, "recurso_valle": tipo, "presentes": presentes, "accesibles": accesibles, "regenera_h": C.OBJETOS[tipo].regen_h})
