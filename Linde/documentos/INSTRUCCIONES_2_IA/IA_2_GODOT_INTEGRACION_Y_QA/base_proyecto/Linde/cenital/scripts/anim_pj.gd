extends RefCounted
# Estado y cuadro de animación del jugador (PROVISIONAL). Función pura, sin dibujo.
# ctx: {mov: bool, t_mov: float, herr_t: float, ataque_est: "libre"|"aviso"|"activo"|"rec", ataque_t: float, inv_t: float}
const P = preload("res://scripts/params.gd")
const C = preload("res://scripts/catalogos.gd")
## Ataque: 4 cuadros = las 4 poses de ataque.png (preparado, anticipación, impacto, recuperación). Fase -> cuadro:
## aviso = preparado (primera mitad) y anticipación (segunda mitad); activo = impacto; rec = recuperación.
const FASE := {"aviso": 0, "activo": 2, "rec": 3}

# Prioridad: dano > ataque > herramienta > caminar > reposo. Solo afecta a la animación, no a la lógica.
static func estado_y_cuadro(ctx: Dictionary) -> Dictionary:
	if ctx.get("inv_t", 0.0) > 0.0:
		var d: Dictionary = C.ANIM_PJ.dano
		return {"estado": "dano", "cuadro": int(_prog(ctx.inv_t, d.dur) * d.cuadros)}
	var ae: String = ctx.get("ataque_est", "libre")
	if ae != "libre":
		var cu: int = FASE.get(ae, 0)
		if ae == "aviso" and float(ctx.get("ataque_t", 0.0)) <= float(C.ANIM_PJ.ataque.aviso) / 2.0: cu = 1
		return {"estado": "ataque", "cuadro": cu}
	var ht: float = ctx.get("herr_t", 0.0)
	if ht > 0.0:
		var h: Dictionary = C.ANIM_PJ.herramienta
		return {"estado": "herramienta", "cuadro": int(_prog(ht, h.dur) * h.cuadros)}
	if ctx.get("mov", false):
		return {"estado": "caminar", "cuadro": int(ctx.get("t_mov", 0.0) / P.PASO_S) % C.ANIM_PJ.caminar.cuadros}
	return {"estado": "reposo", "cuadro": 0}

# Progreso 0..1 desde que empezó (queda `resta` de `total`).
static func _prog(resta: float, total: float) -> float:
	return 1.0 - clampf(resta / total, 0.0, 0.999)
