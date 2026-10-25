# Superposición estable al caminar — 2026-10-25

El usuario observó que dos árboles cercanos intercambiaban cuál quedaba delante al caminar. Causa reproducida: la lista se ordenaba solo por Y y el ordenamiento de Godot no es estable en los empates. Al cambiar la posición del jugador o los elementos visibles, cambiaba el orden relativo de objetos inmóviles.

`Escena.entrada_dibujo()` conserva los pies visuales previos de objetos y construcciones. `Escena.ordenar_dibujo()` compara profundidad Y, posición X y una clave fija de clase/identidad. Así se mantiene la profundidad del personaje y se resuelven de forma determinista los empates de árboles, objetos y construcciones. No se cambian imágenes, generación, densidad ni colisiones. También se explicitó como bool la variable de puerta abierta, que producía un error de inferencia en el estado actual de la escena.

`tests/prueba_orden_dibujo.gd`: 6 comprobaciones sin fallos; reproduce 2 intercambios con el comparador anterior y 0 con el nuevo. Incluye cambios de inserción y encuadre, profundidad del jugador y empates entre clases. `tests/prueba_ui.gd`: 13 comprobaciones, 0 fallos.

`tests/captura_orden_dibujo.gd` toma tres capturas tras mover al jugador por un corredor real junto a árboles generados. Se revisaron las tres. Viaje inicial de depuración, movimiento posterior mediante `Juego.mover_pj`; no es un playtest prolongado ni una grabación de vídeo. Se importaron los recursos de personaje presentes antes de la captura final. Persisten avisos de recursos en uso al cerrar.

No hace falta arte nuevo para resolver este intercambio. La separación de copa/tronco del frutal es un defecto artístico diferente, observado pero no modificado en esta corrección.
