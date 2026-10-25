extends RefCounted
# Capas del PJ como datos puros en un sprite de 16x24 (ancla en pies = y 24).
# Devuelve [[nombre_capa, Rect2i], ...] en orden de dibujo.
static func capas(dir: Vector2i, frame: int) -> Array:
	var la := 1 if frame == 1 else 0   # pierna izq. levantada
	var ra := 1 if frame == 3 else 0
	var c: Array = [["piernas", Rect2i(5, 19, 3, 5 - la)], ["piernas", Rect2i(8, 19, 3, 5 - ra)],
		["torso", Rect2i(4, 12, 8, 7)]]
	var frontal := dir.x == 0
	if frontal:
		c.append(["brazos", Rect2i(2, 12, 2, 6)]); c.append(["brazos", Rect2i(12, 12, 2, 6)])
	else:
		c.append(["brazos", Rect2i(6, 12, 4, 6)])
	c.append(["cabeza", Rect2i(4, 3, 8, 9)])
	if dir == Vector2i.UP:
		c.append(["pelo", Rect2i(4, 2, 8, 9)])
	else:
		c.append(["pelo", Rect2i(4, 2, 8, 3)])
		if dir == Vector2i.DOWN:
			c.append(["pelo", Rect2i(4, 5, 1, 3)]); c.append(["pelo", Rect2i(11, 5, 1, 3)])
		elif dir == Vector2i.LEFT:
			c.append(["pelo", Rect2i(8, 5, 4, 6)])
		else:
			c.append(["pelo", Rect2i(4, 5, 4, 6)])
	if dir == Vector2i.DOWN:
		c.append(["ojos", Rect2i(6, 8, 1, 2)]); c.append(["ojos", Rect2i(9, 8, 1, 2)])
	elif dir == Vector2i.LEFT:
		c.append(["ojos", Rect2i(5, 8, 1, 2)])
	elif dir == Vector2i.RIGHT:
		c.append(["ojos", Rect2i(10, 8, 1, 2)])
	return c

# Dibuja el PJ en un CanvasItem. origen = esquina superior izquierda del sprite 16x24.
static func dibujar(ci: CanvasItem, origen: Vector2, dir: Vector2i, frame: int, look: Array) -> void:
	var P = preload("res://scripts/params.gd")
	var paleta := {"piernas": P.PANTALON, "torso": P.ROPA[look[2]], "brazos": P.PIEL[look[0]],
		"cabeza": P.PIEL[look[0]], "pelo": P.PELO[look[1]], "ojos": P.OJOS}
	var lista := capas(dir, frame)
	for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:    # contorno oscuro
		for capa in lista:
			var q: Rect2i = capa[1]
			ci.draw_rect(Rect2(origen + off + Vector2(q.position), Vector2(q.size)), Color("1f2a1c"))
	for capa in lista:
		var r: Rect2i = capa[1]
		ci.draw_rect(Rect2(origen + Vector2(r.position), Vector2(r.size)), paleta[capa[0]])
