extends RefCounted
## Proyección de estados efectivos; no decide actividades ni modifica la simulación.
static func resolver(actividad: String, movimiento: Dictionary, reloj: float) -> Dictionary:
 var dir: Vector2i = movimiento.get("dir", Vector2i.DOWN)
 if actividad in ["dormir", "sin_cama"]:
  return {"estado": "dormir", "cuadro": 0, "dir": dir}
 if actividad == "descansar":
  return {"estado": "reposo", "cuadro": 0, "dir": dir}
 var mueve: bool = movimiento.get("mueve", false)
 return {"estado": "caminar" if mueve else "reposo", "cuadro": int(reloj / 0.12) % 4 if mueve else 0, "dir": dir}
