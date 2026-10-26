# Cierre de Fase 7 — Ecología y dificultad territorial

26/10/2026. Rama `feature/fase7-ecologia`, base `main eb022a4`. Sin push ni merge. Referencia principal: [diseño maestro](../../../../../../docs/investigacion/DISENO_MAESTRO_FASE7.md). Cierre del alcance autorizado: hábitats, territorio, señales, consecuencias persistentes existentes y navegación. No implica simulación ecológica global.

## Resultado funcional

- Hábitats declarativos integrados en Fauna; políticas persistidas v1/v2/v3. Nuevos mundos poblados usan las preferencias A y reglas B aprobadas: vegetación/roca/espacio libre/orilla, exclusión de nacimientos agresivos en rutas/núcleo12 y anclas compatibles a ruinas/cuevas. Sin candidato se aplaza; no se migra fauna de mundos existentes.
- Avisos de fuentes vivas realmente observables, privados por jugador; desaparecen con la fuente o la visión. Mapa histórico aproximado y fechado, testimonios NPC voluntarios. No se publica globalmente el conocimiento ecológico personal ni se añaden misiones o sonidos/rastros ficticios. Los snapshots generales de enemigos conservan su contrato anterior; no se afirma un rediseño antitrampas de toda la red.
- Bajas/heridas y deltas del mundo reutilizan su persistencia actual. Cargar/streaming no cura ni duplica. La recuperación sigue la regla existente de 720 minutos. Las anclas son lugares geográficos persistentes: extraer una roca no destruye el lugar ni provoca nuevos eventos de población.
- Corrección del atasco: movimiento directo cuando es libre; al colisionar, BFS existente con filtro de caja real de la especie. Ruta y fallo inaccesible se cachean en Combate, fuera de guardados/red. Se invalidan por destino, versión de geometría/streaming o retroceso de golpe; se descartan al descargar/morir/reiniciar.
- Se conservan velocidades, percepción, pérdida de visión, límite de persecución144, tolerancias8/2, aviso/recuperación, daño, vida, XP y botín. Slimes históricos/jefes conservan movimiento anterior. La huida no recibe una IA nueva. No hay teletransporte ni permiso para cruzar paredes.

## Comprobaciones ejecutadas al cierre

Godot4.7.1 Windows, semilla123. [Resultados originales](ejecuciones/verificacion_final/resumen.json): **97 PASS, 0 FAIL**, cuatro suites, sin batería histórica.

| Comprobación | Resultado |
|---|---|
| Navegación | 32/32: 20 regresos (cinco especies × cuatro orientaciones), 10 persecuciones con visión junto a esquinas (cinco × dos lados), destino inaccesible y apertura posterior |
| Decisiones y avisos | 18/18: fuente del escenario existente; cinco especies × acercarse/retirarse/rodear; oclusión/restauración de visión |
| Fauna | 31/31: determinismo, carga/descarga, heridas/bajas, guardado y contrato existente |
| Señales ENet | 16/16: servidor y dos procesos cliente reales, privacidad, derrota y memoria histórica |

**Antes/después:** el mismo escenario de regreso fallaba20/20 con movimiento directo y ahora resuelve20/20 sin cruzar paredes ni superar velocidad. Persecución final10/10. Tasa de atasco alcanzable observada0/30, menor que5% en esta muestra. No es una estimación estadística universal. El escenario original que reportaba31%/14% no está versionado: no se afirma haber repetido esa medición; se entrega sustituto reproducible y logs previos intactos.

La primera corrección resolvió18/20: el gólem no cabía en el centro de su celda junto al muro. Se corrigió la incorporación a la ruta respetando su caja y el deslizamiento existente. Luego aparecieron dos casos equivalentes al perseguir; ambos corregidos. La primera prueba de decisiones imprimió18 PASS pero produjo errores por limpiar también objetos de regiones externas del fixture: esa ejecución **no pasa**; el fixture ahora conserva esas cachés. Todos los fallos y resúmenes se conservan en `ejecuciones/`; ninguno se editó para convertirlo en éxito.

### Oportunidad de decidir, sin nuevos R/T

Campo de QA controlado con movimiento/combatientes reales, radio de conocimiento actual128px, paso1/30s. La fuente inicial procede del fixture existente; se ejercitan los cinco catálogos, provocados cuando su conducta lo requiere. No representa cinco encuentros naturales en esa misma ubicación.

| Especie | Primer aviso → primer daño al acercarse |
|---|---:|
| Espectro | 2,767s |
| Gólem provocado | 3,233s |
| Diablillo | 2,233s |
| Arpía provocada | 2,200s |
| Slime de ribera | 2,500s |

Retirarse y rodear conservaron la vida en los diez casos. Acercarse hasta combatir recibió daño: no se añadió inmunidad. Se verificó la preparación existente del golpe antes del impacto. Los tiempos dependen de geometría, movimiento y estado; no son un mínimo global garantizado. Según la autorización final del usuario, R/T no se rellenan con números arbitrarios: se reutilizan mecánicas actuales. Una irrupción a contacto o amenaza ya atacando puede no ofrecer el mismo margen; no se altera el combate para garantizarlo.

### Revisión jugable breve

Escena nativa1280×720, zoom3, semilla123, fuente y mapa reales del fixture previo, configuración/cuentas/guardado separados de los personales. Se movió el personaje mediante `Juego.mover_pj` y se ejecutó combate autoritativo: detectar → acercarse → retirada por nueve celdas transitables con BFS existente. Vida40/40; distancia final112,11px. La amenaza aún era visible y el aviso seguía vigente, correctamente; no se declara que hubiera desaparecido. [Log original](ejecuciones/revision_visual.log), [capturas](GALERIA.html).

Revisión automatizada del agente con inspección visual de las tres capturas, no playtest humano ni prueba de conexión desde otra computadora. Se conservó la herramienta artística anterior `revision_fase7.gd`; esta revisión usa `revision_ecologia_cierre.gd`.

### Coste focalizado

[Medición original](ejecuciones/medicion/prueba_navegacion_fauna.log): 24 actores (techo vigente), 600 pasos a30Hz, CPU local, sólo `_paso_enemigo`, sin render ni simulación de NPC. Caso cercano fuerza24 regresos simultáneos contra una barrera; lejano mantiene24 actores en reposo. No simula ecología global.

| Carga | Media/paso | Pico/paso |
|---|---:|---:|
| Cercana con obstáculo | 0,231ms | 27,056ms |
| Lejana/reposo | 0,105ms | 0,151ms |

El pico incluye construir rutas simultáneamente. No equivale a FPS del juego completo ni garantiza60FPS; queda registrado como límite de rendimiento, sin introducir un planificador nuevo ni cambiar densidades.

## Evidencia previa vigente, sin repetir suites

[Hábitats](../habitats/README.md): compatibilidad exacta en5.046 regiones. [A/v2](../activacion-v2/README.md): distribución17, compatibilidad23, fauna31 y reconexión13. [B/v3](../activacion-v3/README.md): territorios18, v2 17, compatibilidad23, amenazas12 y red/reconexión13; expansión inversa, política guardada y aplazamientos. [Señales](../senales/README.md): personales20, ENet16, exploración13 y capturas de memoria/NPC. Esos resultados corresponden a sus ejecuciones originales, no a una nueva batería hoy.

## Alcance cerrado y límites explícitos

La Fase7 autorizada queda funcionalmente cerrada en esta rama. No se implementan reproducción, migración, población dinámica, simulación ecológica global ni economía ecológica. Tampoco ataques nuevos a NPC/edificios, destrucción de asentamientos, viabilidad/Fase6, nuevas tasas ni balance: son capacidades futuras, no bloqueos de esta entrega. No se certifican Internet ni otra PC, ni reacción humana universal. Persisten avisos conocidos de ObjectDB/recursos al salir.

Integración: revisar los commits de `feature/fase7-ecologia` sobre `eb022a4`, coordinar con la rama de Fase5/6 y recién entonces integrar a main. Sin migración automática de mundos previos; usar mundo poblado nuevo para evaluar A/B. No requiere servicios, dependencias o assets nuevos. No queda otro bloque obligatorio de esta fase autorizado pendiente.

Reproducir: ejecutar `prueba_navegacion_fauna.gd`, `prueba_decisiones_fauna.gd`, `prueba_fauna.gd` y `prueba_senales_red.gd` con el runner existente. Revisión renderizada: `Godot --path Linde/cenital --script res://tests/revision_ecologia_cierre.gd -- RUTA_ABSOLUTA_DE_SALIDA`. No apunta a partidas/cuentas reales.
