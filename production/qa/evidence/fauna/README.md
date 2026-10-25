# Evidencia de fauna — 2026-10-24

Godot 4.7.1. Cinco capturas de la escena real tomadas con `tests/captura_fauna.gd`; cada criatura fue generada por el sistema de regiones antes de acercar al jugador. Se inspeccionaron las cinco. No es un recorrido manual.

`prueba_fauna.txt`: 31 comprobaciones específicas, 0 fallos. `campana.txt`: 327 PASS, 0 fallos; `interfaz.txt`: 13 PASS. `red_localhost.txt`: servidor y dos clientes reales, 0 fallos; la prueba existente recorre el valle, mientras que la nueva prueba de fauna comprueba directamente la serialización de las especies nuevas hacia la réplica.

`terreno_actual.txt` y `terreno_sin_fauna.txt`: los mismos cuatro fallos de caché en ambas ejecuciones (45/49). La copia aislada de `/tmp/linde-fauna-base` conserva todos los cambios previos del espacio de trabajo y restaura `combate.gd` desde HEAD, quitando únicamente la llamada a `combate.fauna.guardar()` en `Juego.guardar()`. Confirma que estos fallos no los introduce el sistema de fauna.

Límites y reglas completas en `Linde/cenital/docs/FAUNA_Y_PELIGROS.md`. Persisten avisos de recursos en uso al cerrar.

Verificación previa a publicar: copia aislada del índice de Git, excluyendo cambios locales ajenos. `publicacion_fauna.txt`: 31/31; `publicacion_terreno.txt`: 49/49, sin fallos.
