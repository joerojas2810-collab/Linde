extends RefCounted
## Propuesta de geometria visual. No aplica dano ni mueve entidades.
## Recibir radio/ancho/avance del catalogo vivo; no usar dimensiones del sprite.

## Centro real usado por Combate.centro(e); pos es el ancla de pies.
static func centro_enemigo(pies: Vector2, tam: float) -> Vector2:
	return pies - Vector2(0, tam / 2.0)

## Centro del objetivo usado por Combate.centro_pj(id).
static func centro_jugador(pies: Vector2) -> Vector2:
	return pies - Vector2(0, 6)

## Area base y borde exterior efectivo para el CENTRO del objetivo fijado.
static func circulo(centro: Vector2, radio: float) -> Dictionary:
	return {"forma": "circulo", "centro": centro, "radio_base": radio, "radio_efectivo": radio + 6.0}

## Predecir con una posicion temporal y el mismo mover del mundo.
## mover_pies(pos, delta, tam_colision) debe ser consulta sin efectos secundarios.
## Si no hay acceso al mover real, no declarar el extremo predicho como exacto.
static func predecir_final(pies: Vector2, direccion: Vector2, avance: float, tam: float, mover_pies: Callable) -> Vector2:
	var posicion := pies
	var restante := avance
	while restante > 0.0:
		var antes := posicion
		posicion = mover_pies.call(posicion, direccion * 2.0, Vector2(tam, tam * 0.6))
		if posicion == antes: break
		restante -= 2.0
	return posicion

## Capsula real: segmento desde el centro inicial al centro final tras colision.
## largo solo sirve al rango de inicio; NO fija el extremo del golpe.
static func linea(pies_inicial: Vector2, pies_final: Vector2, tam: float, ancho: float) -> Dictionary:
	return {"forma": "capsula", "a": centro_enemigo(pies_inicial, tam), "b": centro_enemigo(pies_final, tam), "radio_base": ancho / 2.0, "radio_efectivo": ancho / 2.0 + 6.0}

## Distancia al eje del area, incluidos extremos redondos y segmento nulo.
static func distancia_eje(p: Vector2, area: Dictionary) -> float:
	if area.forma == "circulo": return p.distance_to(area.centro)
	var ab: Vector2 = area.b - area.a
	if ab.length_squared() == 0.0: return p.distance_to(area.a)
	return p.distance_to(area.a + ab * clampf((p-area.a).dot(ab) / ab.length_squared(), 0.0, 1.0))

## Comprobacion geometrica de la presentacion, no un reemplazo de Combate.
static func contiene_centro(p: Vector2, area: Dictionary) -> bool:
	return distancia_eje(p, area) <= area.radio_efectivo
