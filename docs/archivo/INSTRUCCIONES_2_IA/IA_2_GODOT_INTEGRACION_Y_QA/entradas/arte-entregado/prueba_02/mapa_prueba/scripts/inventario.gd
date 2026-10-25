extends RefCounted
# Inventario = Dictionary item -> cantidad. Todas las operaciones son atómicas (todo o nada).
const C = preload("res://scripts/catalogos.gd")

static func slots(inv: Dictionary) -> int:
	var s := 0
	for k in inv: s += ceili(float(inv[k]) / C.ITEMS[k].pila)
	return s

static func cabe(inv: Dictionary, add: Dictionary, cap: int) -> bool:
	var t := inv.duplicate()
	for k in add: t[k] = t.get(k, 0) + add[k]
	return slots(t) <= cap

static func anadir(inv: Dictionary, add: Dictionary, cap: int) -> bool:
	if not cabe(inv, add, cap): return false
	for k in add: inv[k] = inv.get(k, 0) + add[k]
	return true

static func tiene(inv: Dictionary, req: Dictionary) -> bool:
	for k in req: if inv.get(k, 0) < req[k]: return false
	return true

static func quitar(inv: Dictionary, rem: Dictionary) -> bool:
	if not tiene(inv, rem): return false
	for k in rem:
		inv[k] -= rem[k]
		if inv[k] <= 0: inv.erase(k)
	return true

# Cambio neto (quitar + añadir) atómico: valida capacidad con el resultado final.
static func cambiar(inv: Dictionary, rem: Dictionary, add: Dictionary, cap: int) -> bool:
	if not tiene(inv, rem): return false
	var t := inv.duplicate()
	for k in rem:
		t[k] -= rem[k]
		if t[k] <= 0: t.erase(k)
	for k in add: t[k] = t.get(k, 0) + add[k]
	if slots(t) > cap: return false
	inv.clear()
	inv.merge(t)
	return true
