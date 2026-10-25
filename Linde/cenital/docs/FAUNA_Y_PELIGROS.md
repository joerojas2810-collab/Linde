# Fauna y peligros por bioma — v1

Implementado el 24/10/2026. Funciona al explorar tanto en partidas nuevas como anteriores. El valle conserva sus slimes y sus dos jefes; se añaden encuentros en el exterior sin cambiar la huella del generador de terreno.

| Bioma de origen | Criatura | Conducta | Vida / daño | Botín |
|---|---|---|---|---|
| Bosque | Espectro del bosque | Hostil; detecta hasta 96 px | 20 / 5 | 2 fibras |
| Sierra | Gólem de la sierra | Defensivo; responde si recibe daño | 38 / 8 | 3 piedras |
| Secano | Diablillo del secano | Hostil y rápido; detecta hasta 104 px | 16 / 5 | 2 arcillas |
| Pradera | Arpía de pradera | Huye al acercarse; se defiende si se la ataca | 18 / 4 | 2 fibras |
| Orilla transitable junto al agua | Slime de ribera | Territorial; detecta a 40 px | 16 / 4 | 2 gelatinas |

Son criaturas fantásticas reutilizadas de `Nuevo Juego/public/art/enemies-px`, no animales nuevos dibujados para esta entrega. Se copiaron 20 tiras intactas, con sus hashes y procedencia en `arte/actores/fauna/manifiesto.json`. No se genera ni recolorea arte. Hay reposo, ataque, golpe y derrota. Las tiras solo contienen una orientación frontal; el juego no inventa vistas adicionales. Los nombres se muestran al acercarse.

## Aparición y comportamiento

`Fauna.plan_region()` obtiene un punto y una especie por región de 16×16, mediante la semilla de partida y un hash propio. No altera `terreno_v1.gd`. La ribera se reconoce por un vecino de agua y la criatura nace en tierra firme. Los planes son estables con coordenadas negativas y no dependen de construcciones ni del orden de exploración.

Cada segundo `Fauna.actualizar()` considera las regiones cargadas alrededor de jugadores presentes. Prioriza las más cercanas, con límite global de 24 criaturas regionales activas, adicional a los enemigos del valle. Un punto bloqueado queda aplazado, sin trasladarlo a través de la pared. Hay una franja sin puntos de fauna de 8 celdas alrededor del valle y las apariciones nuevas deben distar 96 px de los jugadores. No hay encuentros regionales nuevos sin jugadores.

Se conserva el combate del juego: aviso visible antes del impacto, recuperación, daño, invulnerabilidad breve, experiencia y botín para quien remata. La fauna regional comprueba obstáculos para detectar y golpear al objetivo. La persecución termina al alejarse más de 144 px del origen; el regreso puede atascarse ante obstáculos porque todavía usa movimiento directo, sin navegación de combate alrededor de árboles. Una criatura puede cruzar una frontera de bioma al perseguir o huir: el bioma determina su origen.

## Guardado, descarga y red

`d.fauna` se añade a partidas anteriores sin reemplazar inventario, terreno o progreso. `bajas` guarda la fecha de reaparición de cada punto estable; `heridos` conserva vida, posición y si fue provocado. Se registra al recibir daño, al guardar y al descargar. Las criaturas sanas descargadas vuelven posteriormente al origen; las heridas no se curan por cargar o alejarse. La baja reaparece tras 720 minutos del juego, equivalentes a 12 minutos reales con el ritmo actual. El tiempo de apagado del servidor no se simula.

La caché de planes acompaña a las regiones cargadas. Los estados persistentes solo retienen diferencias (heridas y bajas todavía vigentes), no copias del terreno. La posición guardada de un herido bloqueada por una construcción aplaza su retorno. No hay simulación de fauna lejana.

Solo la autoridad genera y simula encuentros. Las especies y estados viajan en la instantánea de enemigos ya existente, sin cambiar su formato. El cliente no genera encuentros. Como antes, la réplica no deduce efectos de daño/muerte por enemigo, porque el protocolo no aporta identidad estable individual; sí reproduce las animaciones de estado. La descarga regional local no dibuja una falsa muerte.

## Archivos y verificación

- `scripts/fauna.gd`: planes, aparición, descarga y persistencia.
- `datos/fauna/reglas_v1.json`: distribución, cadencia, techo y reaparición.
- `scripts/catalogos.gd`: estadísticas y botines.
- `scripts/combate.gd`: conductas, visión, impacto y conexión con fauna.
- `scripts/actores_arte.gd`, `scripts/escena.gd`: tiras animadas y nombres.
- `scripts/juego.gd`: captura de heridas al guardar.
- `tests/prueba_fauna.gd`: 31 comprobaciones, 0 fallos. Incluye determinismo, las cinco especies, colisión, heridas, bajas, recompensas únicas, reaparición, conductas, daño real, barreras, techo/caché, arte y serialización servidor/réplica.
- Campaña histórica `tests/prueba.gd -- --campana`: 327 PASS, 0 fallos. Interfaz: 13 PASS. Integración existente con un servidor y dos clientes reales localhost: 0 fallos.
- `tests/captura_fauna.gd`: capturas de los cinco encuentros realmente generados. Viaje por depuración, no playtest manual. Imágenes inspeccionadas en `production/qa/evidence/fauna/`.

La suite `prueba_terreno.gd` da 45/49: cuatro comprobaciones de descarga/tamaño de caché fallan también en una copia aislada sin los cambios de fauna. El cambio previo de `Juego.actualizar_regiones()` mantiene dos centros adicionales junto al valle para los NPC. Se conserva sin modificarlo; no se ocultan estos fallos ni se ajustan las expectativas del test en esta tarea. Los logs de ambas ejecuciones están en la evidencia.

Límites: balance provisional, sin cría, depredación, hambre animal, manadas, animales domésticos, peligros climáticos ni jefes nuevos. Falta playtest prolongado y prueba de fauna en Internet. Persisten avisos previos de recursos en uso al cerrar Godot.

## Verificación de la versión preparada para publicar

Antes del commit se extrajo exclusivamente el contenido preparado en Git a `/tmp/linde-publicar/Linde/cenital`, sin los cambios locales pendientes de minerales y autonomía. Esa versión importó correctamente y aprobó 31/31 pruebas de fauna y 49/49 de terreno. Los cuatro fallos descritos arriba pertenecen a la combinación de cambios locales, no a esta versión publicada. Logs en `production/qa/evidence/fauna/publicacion_fauna.txt` y `publicacion_terreno.txt`.
