# Propuesta B: calma territorial y lugares (26/10/2026)

Prototipo, no activado. La distribución v2 y los mundos existentes no cambian. Fauna.contexto_territorial consulta únicamente registro de rutas/lugares/poblados; distancia Manhattan a trazados, áreas existentes y núcleo 1e de 12 celdas solo en modo poblado. No genera geometría, no simula, no decide seguridad ni se conecta a HUD/mapa/replicación. Los clientes no reciben conocimiento nuevo.

Medición focalizada en las macrorregiones ya registradas al crear tres mundos (123/456/789): 324 regiones, 269 planes y 123 puntos hostiles. Ocho hostiles dentro de núcleos y dos sobre rutas, con un solapamiento: nueve puntos únicos. No hay hostiles dentro de las áreas de lugares/pueblos en esta muestra. Los lugares no poseen actualmente fuentes explícitas de amenaza. Son planes posibles, no conteos de enemigos activos; la materialización sigue validando colisiones/cercanía/cupo.

## Reglas propuestas, pendientes de aprobación

1. Evitar nacimientos hostiles/territoriales sobre las celdas de rutas registradas y dentro del núcleo existente de poblados. Es ampliar a fauna regional una exclusión que 1e aplica a slimes clásicos, no afirmar que ya estuviera aprobada para todas las especies. No añade radios a caminos.
2. Para un enemigo hostil cuya región contiene una ruina/cueva, preferir un candidato compatible próximo a su entrada y guardar ese ID de lugar como fuente. No añade población ni fuerza una especie distinta. No modifica campamentos para convertirlos arbitrariamente en peligrosos.
3. Mantener preferencias A cuando sea posible, especie/bioma/ID/región y población nominal. Sin candidato compatible fuera de espacios humanos, posponer la materialización. Esta excepción sí puede reducir presencia local; requiere aprobación explícita aunque no haya sucedido en las tres semillas normales.

El prototipo mueve 14 puntos y propone 6 anclas; conflictos 9→0, sin aplazamientos en las muestras. Son 4/7/3 movimientos y 1/3/2 anclas por semilla. No demuestra mejor combate o peligro justo ni constituye equilibrio aprobado. Una persecución sigue pudiendo entrar al poblado: no hay inmunidad ni daño cancelado por zona.

## Pruebas focalizadas

- Contexto: tres semillas, extremos de rutas, centros de lugares/poblados, consulta sin mutar mundo ni cargar regiones, mismo resultado después de guardar/cargar; además confirma que modo legado no recibe política de núcleos 1e.
- Prototipo B: tres semillas conservan población, identidad, especie, bioma y región; anclas referencian lugares existentes; orden inverso y estado puro. Caso sintético adicional cubre todas las candidatas con una ruta y comprueba aplazamiento. El primer intento de ese caso eligió una especie defensiva, que correctamente no se desplazaba; se corrigió el escenario para usar una especie hostil real.
- No se repitió la batería de red/combate: ninguna regla de aparición activa ni protocolo cambió. Persisten avisos conocidos al salir del motor. Sin prueba humana, externa o en otra PC.

## Activación futura

Necesita aprobación de reglas y de la excepción de aplazamiento; después política persistente por mundo, anclas estables y generación independiente del orden de expansión. No basta con consultar el registro mutable dentro de plan_region: el prototipo opera sobre un registro previamente generado para comparar, no resuelve todavía el caso de nuevas macrorregiones. Mundos existentes v1/v2 deben permanecer intactos. Se validará entrada/aparición, persistencia, orden de descubrimiento y red al activar. No se fijan R/T ni se declaran resueltos navegación, NPC/edificios o señales.

Reproducir: res://tests/medir_contexto_fauna.gd -- RUTA_CONTEXTO.json; res://tests/proponer_contexto_fauna.gd -- RUTA_PROPUESTA.json. Ambos se ejecutan con Godot --headless --path Linde/cenital. Los datos son ficticios y las figuras son diagramas de QA, no arte del juego.
