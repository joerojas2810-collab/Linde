extends SceneTree
## Construcción efectiva de una casa individual y de una comunitaria por habitantes, sin albañil (madera de respaldo), con ticks reales.
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
func obra(plano: String, dias: int) -> Dictionary:
	var j = nuevo()
	var s = j.autonomia.sociedad
	var p: Dictionary = {}
	for _i in 60:
		p = s.habitat.reservar("maren", plano)
		if not p.is_empty(): break
	if p.is_empty(): return {"error": "sin solar"}
	var ancla := Vector2i(int(p.cama[0]), int(p.cama[1]))
	j.mundo.poner(ancla, "cama_huesped", true, "grupo:talleres")
	s.habitat.estado(ancla, "pendiente")
	for nid in ["maren", "ordal"]:
		j.autonomia.estado(nid).inv = {"madera": 150, "fibra": 80, "piedra": 30, "baya": 20}
	var hecho_en := -1
	for i in dias * 1440 * 10:
		j.tick(0.1)
		if i % 6000 == 0 and s.casa_completa(ancla):
			hecho_en = i / 600
			break
	var camas := 0
	for k in j.d.mundo.constr: if j.d.mundo.constr[k].t == "cama_huesped": camas += 1
	var piezas := 0
	var pedidas: Array = s._celdas_casa(ancla)
	for paso in pedidas:
		if s._pieza_puesta(paso[0], paso[1]) or (paso[0] == "muro_ladrillo" and j.mundo.constr_en(paso[1]).get("t", "") in ["muro", "muro_ladrillo"]): piezas += 1
	return {"completa": s.casa_completa(ancla), "horas": hecho_en, "piezas": piezas, "total": pedidas.size(), "camas": camas, "camas_libres": j.vivo.camas_libres_lista().size(), "llegados": j.d.mundo_vivo.autonomia.get("colonos", {}).size(), "estado": s.habitat.datos().obras.get(Mundo.clave(ancla), {}).get("estado", "?"), "motivo": s.habitat.datos().obras.get(Mundo.clave(ancla), {}).get("motivo", "")}
func _init() -> void:
	var c := obra("casa", 3)
	print("CASA INDIVIDUAL: ", JSON.stringify(c))
	ok(c.get("completa", false), "una casa individual se completa con ticks reales y madera de respaldo")
	var k := obra("comunitaria", 5)
	print("CASA COMUNITARIA: ", JSON.stringify(k))
	ok(k.get("completa", false), "una casa comunitaria se completa con ticks reales y madera de respaldo")
	ok(int(k.get("camas", 0)) == 3, "la comunitaria tiene sus tres camas (las plazas pueden ya estar ocupadas por recién llegados)")
	print("CASAS_ARRAIGO: %d comprobaciones, %d fallos" % [total, fallos])
	quit(1 if fallos else 0)
