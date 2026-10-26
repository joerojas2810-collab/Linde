# Fauna y peligros por bioma — v1

## Cierre vigente de Fase 7 — 26/10/2026

Alcance autorizado cerrado en `feature/fase7-ecologia`, sin merge/push. [Informe, pruebas y límites](../../../production/qa/evidence/mundo-1/fase-7/cierre/README.md). Navegación regional reutiliza BFS al bloquearse, filtrando la caja real de cada especie; caché de sesión invalidada por destino, geometría/streaming y retroceso. Conserva percepción, velocidades, estados, tolerancias y combate. Destino inaccesible no se atraviesa ni se busca de nuevo cada cuadro. Movimiento histórico de slimes/jefes conservado.

Verificación final: navegación32, decisiones18, fauna31 y señales ENet16, todos sin fallos. Regreso20/20 atascado antes →0/20 después; persecución0/10 atascada. Escenario reconstruido reproducible, no repetición del P2 histórico sin fuente. Aviso antes del daño en los cinco casos controlados:2,20–3,23s; retirada/rodeo sin daño. No son tiempos mínimos universales ni un cambio de balance. R/T se resuelven operativamente reutilizando parámetros actuales según la autorización final, sin nuevos umbrales.

Revisión en escena real con retirada y vida40/40, capturas inspeccionadas. Fuera del alcance: reproducción, migración, economía ecológica, simulación global y ataques nuevos a NPC/edificios. Las notas siguientes documentan implementaciones anteriores; sus pendientes de navegación/R/T quedan superados por este cierre acotado.

## Avisos observados y memoria histórica — 26/10/2026

La fauna regional viva observada genera un aviso direccional personal en la tarjeta de entorno existente. Usa el radio de conocimiento de Autonomia y el rayo de visión de combate, sin nuevos radios/tiempos ni cambios de detección de enemigos. No consulta poblaciones latentes, no fabrica huellas o sonidos y no presenta una especie pasiva como amenaza hasta que esté provocada. Al morir, alejarse o perderse la visión de la fuente, deja de avisar. No es una garantía universal de reacción mínima; véase el cierre y sus medidas.

Exploración registra el último avistamiento por bloque personal, con fecha/categoría/procedencia e identidades internas de fuente/ancla para auditoría. El mapa muestra bloque aproximado, fecha y leyenda histórica; no sigue enemigos ocultos ni afirma que un registro antiguo siga vivo. Los NPC cercanos pueden observar una fuente real o recibir un testimonio del jugador durante el intercambio voluntario ya existente, y contarlo con su fecha original. La memoria de NPC queda en `d.fauna.informes_npc`, sin nueva simulación ni NPC duplicados.

La red envía solo el aviso del observador y su mapa; elimina IDs internos de fauna/ancla de la copia enviada, y no publica esos informes en `mundo_vivo` o perfiles. La réplica no genera avisos desde el estado global. Los guardados mantienen la historia; modo legado no recibe cambios de conocimiento. La novedad es aditiva para mundos poblados v1/v2/v3 y no migra sus distribuciones.

Verificado: señales **20/20**, dos clientes ENet reales **16/16**, regresión de fauna **31/31** y exploración **13/13**, más cuatro capturas reales inspeccionadas. [Detalle y galería](../../../production/qa/evidence/mundo-1/fase-7/senales/README.md). Son avisos y avistamientos, no nuevas huellas gráficas/audio. Sin prueba humana de margen de reacción ni nueva prueba por Internet. Siguiente bloque: reproducir los atascos y mejorar navegación con prueba acotada.


## Distribución territorial v3 — propuesta B aprobada (26/10/2026)

Los nuevos mundos poblados usan v3; los guardados existentes v1/v2 no cambian. `habitats_v3.json` contiene la política aprobada: no nacen hostiles/territoriales sobre rutas registradas, áreas de pueblos ni dentro del núcleo existente de 12 celdas; una parte de la fauna hostil se vincula a ruinas/cuevas compatibles de la misma región, conservando especie, bioma e identidad. Sin candidato válido, la aparición queda pospuesta. No se añade radio al camino ni se cambia combate: las criaturas activas pueden perseguir y entrar en los pueblos.

`d.fauna.territorios` conserva una vez las decisiones de las macrorregiones generadas por `Lugares`: 36 planes, incluidas ausencias, celdas, ID de ancla y estado pospuesto. No duplica terreno, rutas o edificios. La génesis inicial de fauna espera a que los pueblos preexistentes estén completos; las nuevas macrorregiones se registran en autoridad antes de materializar/guardar. La consulta `plan_region` de una región desconocida no genera nada. Obras posteriores no reescriben los planes ya persistidos. El aplazamiento se conserva al reiniciar y no ocupa cupo: no hay reevaluación/recuperación automática nueva.

Los datos incompletos o desconocidos se rechazan al cargar, sin resembrar. Las herramientas pueden crear explícitamente v1/v2 para verificar compatibilidad; no se convierten mundos existentes a v3. El guardado mantiene la política propia y sus decisiones; ni se cambia la huella global ni se utiliza su excepción. La evolución causal posterior de lugares/pueblos no está implementada como reubicación de fauna.

Verificación final: territorios **18/18**, v2 **17/17**, v1/hábitats **23/23**, amenazas **12/12**, integración local con dos servidores y reconexión **13/13**. Expansión en orden inverso, macrorregiones negativas, anclas B exactas en tres semillas, aplazamiento, caché negativa y persistencia. [Informe](../../../production/qa/evidence/mundo-1/fase-7/activacion-v3/README.md). Sin otra PC/Internet ni playtest R/T. Siguiente: señales causales de amenazas reales y conocimiento personal. Las notas de propuesta B sin activar quedan superadas para mundos nuevos, sin cerrar toda la Fase 7.


## Distribución v2 aprobada: activación en mundos nuevos (26/10/2026)

El usuario aprobó la propuesta A. Los mundos **nuevos en modo poblado** fijan `d.fauna.distribucion` con versión 2 y copia de las preferencias de `datos/fauna/habitats_v2.json`. Los mundos existentes sin ese campo permanecen siempre en v1, incluso en regiones no visitadas; no se migran al cargar. El modo legado sigue intacto. La API de creación admite `version_fauna=1` para herramientas que reproducen mundos anteriores; la escena/servidor normal usan v2.

Se conservan cantidad, especie, bioma, ID y región. Si el punto ya cumple se mantiene; si no, se busca entre los mismos 64 candidatos: espectros junto a árbol/arbusto, gólems junto a roca/vetas, arpías/diablillos con cuatro vecinos cardinales de pasto vacío; slimes conservan su orilla. Sin candidato adecuado se conserva el origen. No modifica conducta de combate, aparición del jugador ni reaparición de bajas.

`Fauna.plan_preferente` y `cumple_preferencia` son compartidos con el comparador. El snapshot del mundo se restaura al cargar, independientemente de futuros defaults, y queda protegido por el checksum del guardado. Es versión de generación, no una sustitución de reglas globales: no se alteran la huella ni sus excepciones. Versiones desconocidas se rechazan con un motivo legible, sin volver a v1. Usar una versión del juego que soporte v2 para estos mundos; no se verificó apertura con builds anteriores. La réplica sigue sin decidir población.

Pruebas de esta activación: distribución **17/17**, compatibilidad/hábitats **23/23**, fauna **31/31**, integración de cuentas y reconexión con dos mundos locales **13/13**; ambos guardados de servidor contienen v2. [Evidencia](../../../production/qa/evidence/mundo-1/fase-7/activacion-v2/README.md). Sin prueba externa. Este subbloque no implementa calma regional, amenazas ligadas a lugares, señales o navegación/P2. Las notas de propuesta no activada de abajo son históricas y quedan superadas para mundos nuevos por esta aprobación.


## Fase 7: primer bloque de hábitats compatibles — 26/10/2026

`Fauna.perfiles_habitat()` normaliza el bloque `biomas` del JSON existente; la cadena de especie sigue siendo la sintaxis abreviada válida. Ejemplo equivalente (todavía no se sustituye el JSON sellado):

```json
{"ribera":{"tipo":"slime_ribera","suelo":"pasto","sin_objeto":true,"agua_vecina":true}}
```

`validar_habitats()` comprueba biomas/especies y campos admitidos; no incorpora pesos, horarios ni sustratos nuevos. `habitat_en(celda)` consulta suelo vacío y vecino cardinal de agua sin cargar regiones, alterar el mundo o compartir conocimiento. Devuelve compatibilidad y la conducta del catálogo; **no demuestra que una criatura esté presente**. No usarlo como aviso al jugador sin comprobar la fuente real. La ribera conserva su prioridad sobre el bioma base. `plan_region()` reutiliza esta consulta con el mismo hash, candidatos, ID y caché.

Este primer bloque conserva exactamente la distribución anterior, las reglas selladas y el estado persistente. No añade registros por región porque el algoritmo no cambia y ya existen bajas/heridos; tampoco altera el plazo explícito de reaparición de 720 minutos. La distribución territorial no uniforme necesita aprobación antes de cambiar densidades, ubicaciones/radios o exclusiones. No se han activado nuevas zonas de calma, amenazas ancladas a lugares ni señales ambientales.

Diseño principal: [DISENO_MAESTRO_FASE7](../../../docs/investigacion/DISENO_MAESTRO_FASE7.md). Informe y pruebas actuales: [hábitats](../../../production/qa/evidence/mundo-1/fase-7/habitats/README.md): base fauna 31/terreno 49, nueva suite 23, regresión fauna 31 y red exterior localhost con dos clientes. Equivalencia en 5.046 regiones (tres semillas y dos generadores), carga real de un guardado previo sin excepción de reglas. P2, señales, reproducción/migración y economía quedan fuera de este bloque. Las secciones siguientes son el historial v1; sus cifras no sustituyen esta ejecución.

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

Se conserva el combate del juego: aviso visible antes del impacto, recuperación, daño, invulnerabilidad breve, experiencia y botín para quien remata. La fauna regional comprueba obstáculos para detectar y golpear al objetivo. La persecución termina al alejarse más de 144 px del origen; regreso y persecución utilizan ahora el BFS existente cuando el movimiento directo colisiona. Una criatura puede cruzar una frontera de bioma al perseguir o huir: el bioma determina su origen.

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
