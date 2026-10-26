# Mundo 1 — auditoría de brechas y plan incremental

> **Fecha**: 2026-10-26 · **Visión**: [VISION_MUNDO_1.md](../../design/VISION_MUNDO_1.md) · **Estado implementado (fuente de verdad)**: [ESTADO.md](../../production/epics/mundo-vivo/ESTADO.md) · **Diagnóstico previo**: [CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md](CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md) (su §6 queda sustituido por las fases de este plan).
> **Aprobado el 2026-10-26** con las precisiones de N1–N6 y de las fases 0 y 5–7; registrado como `M1-*` en la sección F de [DECISIONES.md](../../Linde/cenital/docs/DECISIONES.md). **Fases 0–4 implementadas al 26/10**; alcance verificado en ESTADO.md §§3d–3g. La Fase 5 fue autorizada después: 5a implementada; 5b sigue aplazada según M1-F5. Fase 6 iniciada posteriormente por autorización del usuario: primer bloque causal detallado, ver § Fase 6. Cuentas/autenticación fuera de este alcance. La preparación histórica de las fases 0 y 1 se conserva en la sección 8.
> **Etiquetas**: **[C]** verificado en código · **[D]** solo documentado en ESTADO/contratos · **[M]** medido · **[I]** inferencia. Contexto aplicable: «partidas viejas no importan» (sin migraciones ni compatibilidad), así que los cambios de esquema son libres.

## 1. Conclusión
Mundo Vivo ya contiene casi todos los *mecanismos* que Mundo 1 necesita (terreno determinista con diferencias persistentes, autonomía, construcción, llegada de colonos, puestos resumidos con visualización, conocimiento por bloques, rumor entre NPC, saberes, fauna determinista, red autoritativa). Lo que falta es, sobre todo, **dejar de tratar el Valle como un caso especial codificado en constantes** y **añadir la capa de mundo compartido** (registro de poblados y lugares generado una vez, mapa personal, destinos). No hace falta reescribir nada; sí tres generalizaciones:
1. «El Valle» → **un poblado más**, descrito por datos (centro, área, accesos, depósitos, camas), no por constantes.
2. **Registro de mundo** (poblados, lugares, caminos) generado una vez y guardado, extensible por macrorregión.
3. **Dos niveles de población** ya existen (resumida y detallada); falta el puente entre ambos.

## 2. Auditoría por sistema

### 2.1 Generación y persistencia del mundo
| | |
|---|---|
| **Funciona [C]** | Terreno por coordenadas globales, regiones de 16, sin orden de carga; `rotos/golpes/constr/caminos/techos` por coordenadas globales; versionado v1/v2 con huella; caché acotada de 25 regiones; servidor autoritativo; clientes reconstruyen con la misma semilla; protocolo 7 con huella de reglas |
| **Parcial** | Límite ±65.536; carga síncrona; el exterior no guarda *decisiones de generación*, solo diferencias; «no se guardan copias de regiones sin modificar» |
| **Falta** | **Registro persistente de lo generado con identidad** (qué pueblos/lugares existen, dónde, con qué historia) — hoy cambiar el generador cambiaría el mundo salvo por versión; expansión «por orden» controlada |
| **Reutilizar** | El patrón de `Fauna.plan_region` (función pura por región con hash propio, sin tocar `terreno_v1/v2`) + `estado` del guardado; `Guardado` ya versiona |
| **Riesgos** | Mantener determinismo cliente/servidor (los clientes deben llegar al mismo registro: guardarlo en `mundo.estado` y replicarlo como las diferencias); no alterar la huella de terreno |

### 2.2 Pueblo inicial y asentamientos regionales
| | |
|---|---|
| **Funciona [C]** | Valle de autor 64×48; 2 habitantes iniciales con rutinas completas; llegada por presión (`Sociedad._inmigrar`, tope técnico 12); casas por plano con solares reservados (`habitat.gd`); grupos con depósitos; puestos regionales (máx. 3, 2 residentes, producción resumida con costes reales y persistencia) |
| **Parcial** | **El Valle está codificado en constantes** (`Mundo.CASA/CAMAS/ENTRADA/ESENCIALES/CLARO/SPAWN_GUARDIAN`, grupos con depósitos fijos en `reglas.json`). `habitat.gd:45` exige que toda zona esté en el Valle. Los recién llegados nacen en `Mundo.ENTRADA`. Existen **dos regímenes**: rutinas completas solo en el Valle; resumen en puestos [C] |
| **Falta** | Un concepto de **poblado** como dato; otros pueblos preexistentes; el pueblo inicial regido por las mismas reglas que los puestos; decadencia/abandono (los puestos solo se «detienen»: `sin comida; producción detenida`) |
| **Reutilizar** | `Asentamientos.crear/validar/actualizar/visibles` (piezas, cofre, residentes, producción); `Arraigo` (visitante→aspirante→residente→ausente) como modelo de permanencia; `Habitat.reservar` |
| **Riesgos** | El Valle tiene `ESENCIALES`, jefes y slimes en su interior; sacar constantes toca `mundo.gd`, `habitantes.gd`, `habitat.gd`, `mundo_vivo.gd`, `combate.gd`, `escena.gd` y arte (`mundo_arte.gd`, `arte_entornos.gd`). Alto acoplamiento [C: referencias a esas constantes en 9 archivos] |

### 2.3 NPC autónomos y fundación de asentamientos
| | |
|---|---|
| **Funciona [C]** | Necesidades, metas con alternativas y reintentos, trueque con garantías, confianza, grupos, memoria, oficios, práctica, enseñanza de saberes, expediciones al contorno, construcción (camas, casas, talleres, campos) |
| **Parcial** | `Asentamientos.crear` **solo se llama desde la construcción del jugador** (`juego.gd:587`) [C]. Los NPC extraen recursos pero no fundan. La optimización de `_recurso` ya hecha reduce el coste de planificación (−50 % a −62 %, sin confirmar) |
| **Falta** | Decisión de fundar: criterio (excedente, presión, sitio), viaje, coste real, efecto en el poblado de origen; ampliación autónoma de puestos; migración entre poblados |
| **Reutilizar** | `Asentamientos.validar/crear` con dueño NPC; costes reales de `reglas_v1.json`; `Sociedad.presion()` y `_inmigrar` como modelo de «salir» |
| **Riesgos** | Equilibrio (no tocar sin medición, D14); persistencia de grupos en viaje; límites técnicos de población y red (`mundo_vivo` se reenvía completo: TD-007/008) |

### 2.4 Construcción y evolución territorial
| | |
|---|---|
| **Funciona [C]** | Construcción validada (huella, rutas, ocupación), retiro, cofres con candado, techos, campos que maduran, caminos por pisadas (20), regeneración de recursos, persistencia y réplica |
| **Parcial** | Las casas autónomas no se completan de forma consistente en 4–5 días simulados [D]; el exterior no evoluciona salvo puestos |
| **Falta** | Ruina/abandono; mejora de camino (sendero→camino→puente); percepción de evolución en una hora de juego real |
| **Reutilizar** | `Mundo.pisar`, `estado.caminos/techos`, `Habitat`, `Sociedad._casa/_refugio` |
| **Riesgos** | Medir antes de tocar el equilibrio de materiales (D14) |

### 2.5 Exploración, mapa y lugares de interés
| | |
|---|---|
| **Funciona [C]** | «Bioma · x, y» en el HUD. **Para NPC**: conocimiento por bloques de 8×8 (`Autonomia._explorar/conoce`), visión por radio, **rumor al cruzarse (`radio_rumor`)** y horizonte del contorno |
| **Parcial** | Los habitantes ya «conocen» partes del mundo y se las pasan entre sí |
| **Falta [C]** | Mapa del jugador; memoria de exploración del jugador; hitos con nombre; transmisión NPC→jugador de información aproximada; compartir; **lugares de interés fuera del Valle** (el contrato dice que no hay mazmorras ni ruinas exteriores) |
| **Reutilizar** | **La misma estructura `bloques` para el jugador** (clave `"bx,by"` de 8×8, ya probada con rumor); `pj` del guardado para persistir; el diálogo/ficha (`V`, `E`) como canal de información de NPC |
| **Riesgos** | Tamaño del guardado por jugador; el terreno es reconstruible por el cliente, así que el mapa es memoria/presentación, no seguridad |

### 2.6 Fauna y dificultad territorial
| | |
|---|---|
| **Funciona [C][D]** | 5 especies por bioma (el gólem de sierra ya es más duro que el espectro del bosque: la dificultad ya depende del hábitat), conductas, telegrafiado, planes deterministas por región, bajas y heridas persistentes, techo de 24, franja segura de 8 celdas alrededor del Valle |
| **Parcial** | Una criatura por región elegible (85 % de las regiones [M]); densidad casi uniforme; sin zonas de calma; sin señales previas; atascos [M: 31 % regreso, 14 % persecución en escenario sintético] |
| **Falta** | Perfiles de hábitat/actividad, amenazas ancladas a lugares (cueva, campamento), efecto de caminos/asentamientos en el peligro, acontecimientos que cambian el riesgo, señales |
| **Reutilizar** | `Fauna.plan_region` + `datos/fauna/reglas_v1.json` (ampliar por datos), `bajas`/`heridos` como deltas, `Combate._paso_enemigo` |
| **Riesgos** | No cambiar estadísticas ni botines (D14); `prueba_fauna` (31) debe seguir pasando |

### 2.7 Simulación cercana y lejana
| | |
|---|---|
| **Funciona [C]** | Servidor avanza `Autonomia.paso` por minuto de juego sin jugadores; `Asentamientos.actualizar` produce **sin cargar regiones lejanas** (terreno por coordenadas); `Asentamientos.visibles()` dibuja residentes resumidos con un vaivén cuando la región está cargada |
| **Parcial** | Tres niveles *de hecho*: (a) resumen sin cuerpo, (b) **marioneta visible** (residente resumido que se mueve entre dos celdas), (c) habitante completo con rutina, ruta y necesidades. El nivel (c) existe solo en el Valle; no hay paso de (a/b) a (c) |
| **Falta** | Transición resumido↔detallado; reglas comunes; simulación de poblados lejanos sin jugadores |
| **Reutilizar** | `Habitantes.registrar_colono` (crea habitante desde una ficha en tiempo de ejecución) como mecanismo de **materialización**; `Asentamientos.visibles` como etapa intermedia barata; `Autonomia.estado` para devolver inventario y memoria al resumen |
| **Riesgos** | Duplicar/perder recursos al pasar de un nivel a otro; red (identidad de habitante estable); `AREA_EXPEDICION` limita el pathing de NPC al Valle y su contorno |

### 2.8 Incorporación de jugadores y selección de inicio
| | |
|---|---|
| **Funciona [C]** | `Juego.unir` crea el jugador con estado propio en `punto_inicio(semilla)`; reaparición en cama o inicio con mitad de vida |
| **Parcial** | `punto_inicio` es una celda aleatoria válida del Valle (mediana a 23,8 celdas de la puerta de la casa [M]); todos los jugadores obtienen **la misma celda** |
| **Falta** | Inicio por poblado vivo y viable; cercanía con dispersión entre compañeros; fallback a otra comunidad (D13); registro del motivo; manejo de cero candidatos (hoy `rng.randi() % cand.size()` fallaría con 0) |
| **Reutilizar** | La lógica de validación de `punto_inicio`; el registro de poblados (fase 1) para elegir comunidad viable |
| **Riesgos** | Carreras al unirse varios a la vez; depender de que haya un poblado «viable» definido |

## 3. Decisiones resueltas (26/10)
| ID | Resolución del usuario |
|---|---|
| N1 | Transformar el Valle en el pueblo inicial aprovechando lo existente, **sin conservar obligatoriamente su estructura ni identidad**; el resultado es una comunidad coherente de Mundo 1 |
| N2 | Empezar con 1–2 pueblos preexistentes adicionales (alcance inicial, no límite) |
| N3 | Registro persistente de poblados, lugares y caminos; generación determinista, independiente del orden de exploración, que conserva resultados. **Generación controlada ≠ simple carga de regiones** |
| N4 | Reutilizar y generalizar `Asentamientos`; sin sistema paralelo de pueblos |
| N5 | Límites técnicos configurables por poblado y globales, sujetos a medición; no permanentes |
| N6 | Viabilidad = comida + camas + residentes + seguridad, con información existente; umbrales pendientes de medición y aprobación |

## 4. Plan incremental

Cada fase deja un ciclo jugable. Los riesgos de regresión se mitigan con las suites ya existentes (nombradas).

### Fase 0 — Línea base de ritmo (sin cambiar el juego)
- **Objetivo**: medir el ritmo actual con pruebas acotadas (sin depender de playtests humanos; si se hacen, enriquecen pero no bloquean).
- **Reutiliza**: `simular_crecimiento.gd`, `medir_i1a.gd`.
- **Mínimo**: guion automático de ruta mínima (hacha→mesa→pico→salir→volver) y playtest humano de 3–4 personas.
- **Aceptación**: tiempos por hito en 5 semillas; lista de bloqueos observados.
- **Riesgo**: ninguno.

### Fase 1 — «Entrar en un pueblo con sentido» (poblado como dato)
- **Objetivo**: aparecer junto a la gente, ver el pueblo, no perderse (D1, D2, D5, D13 parcial).
- **Reutiliza**: `Mundo` (terreno del Valle), `Habitat`, `Habitantes.reconciliar`, `punto_inicio`, `Asentamientos` (cofre, piezas).
- **Cambios mínimos**: (1) un registro `poblados` en el guardado (`id`, centro, área, accesos, camas, depósitos), con el Valle como `poblado 0` leído de constantes existentes; (2) `punto_inicio` elige dentro del área del poblado cerca de la plaza/casa con dispersión entre compañeros y fallback registrado; (3) hitos con nombre y una estación común coherente con los oficios (N1/D5) construida como parte del poblado; (4) sin tocar balance.
- **Dependencias**: N1, N5, N6.
- **Aceptación**: en 500 semillas el inicio cumple pruebas duras actuales y está a ≤X celdas de la plaza y a la vista de ≥1 habitante; dos jugadores seguidos quedan en celdas distintas y cercanas; con el poblado inutilizable el fallback usa otra comunidad o un campamento y lo registra; `prueba`, `prueba_red`, `prueba_autonomia`, `prueba_arraigo` sin regresión nueva.
- **Riesgo de regresión**: **medio-alto** por las constantes del Valle en 9 archivos; mitigar con una indirección (leer del registro, mismo valor por defecto) antes de mover contenido.

### Fase 2 — Mapa personal y orientación (D4, D9)

**Implementada y verificada 26/10/2026**: alcance, pruebas y límites en ESTADO.md §3e.
- **Objetivo**: tecla M con lo descubierto y lo sabido; NPC que orientan.
- **Reutiliza**: la estructura `bloques` y `_ver` de `Autonomia`, `pj` del guardado, el diálogo de habitante.
- **Cambios mínimos**: `pj.mapa.bloques` (mismas claves 8×8), actualizado por posición; panel M que dibuja bloques y hitos conocidos; «preguntar por lugares» devuelve un área aproximada a partir de los bloques del NPC; compartir = unir bloques con procedencia (como el rumor actual).
- **Dependencias**: Fase 1 (hitos).
- **Aceptación**: tras recorrer una ruta el mapa muestra exactamente lo visto (más el radio fijo); persiste al guardar y cargar; la réplica no recibe el mapa de otro jugador; presupuesto de bytes de guardado tras 60 min fijado antes; `prueba_ui` y `prueba_red` sin regresión.
- **Riesgo**: bajo-medio (guardado por jugador, tamaño).

### Fase 3 — Aprendizaje contextual (D7)

**Implementada y verificada 26/10/2026**: 14 pistas en datos, historial personal, descarte y silencio; pruebas y límites en ESTADO.md §3f.
- **Objetivo**: pistas que dependen de lo que pasa y se olvidan tras verse.
- **Reutiliza**: `Escena._pista()`, `Desarrollo.sabe/puede`, panel de ayuda.
- **Cambios mínimos**: reglas en datos («evento + precondición + texto + enfriamiento»), estado `pj.pistas` (mostrada/descartada), interruptor «ya conozco los sistemas». Sin misiones.
- **Dependencias**: ninguna fuerte; conviene después de Fase 1.
- **Aceptación**: ≥12 pistas, cada una sale una vez, no se repite tras guardar y cargar, nunca dos a la vez, silenciable; `prueba_ui`, `prueba_saberes` sin regresión.
- **Riesgo**: bajo.

### Fase 4 — Mundo compartido: registro de lugares y primeros destinos (D3, D10, D11)

**Implementada y verificada 26/10/2026** (`a2548f6`, `3634a67`): registro persistido por macrorregión, tres tipos de lugares, rutas con AStarGrid2D y réplica autoritativa (protocolo 8). Inspección, mapa y referencias de NPC jugables. Detalles, cifras y límites: ESTADO.md §3g.

**Precisión de alcance del usuario**: no avanzar a Fase 5. Por eso el criterio histórico de incluir un pueblo preexistente adicional se difiere a esa fase; aquí no se generan pueblos ni residentes. Los campamentos están desocupados. La entrada de cueva no contiene un interior.

- **Objetivo**: algo significativo que visitar, igual para todos los jugadores de la partida y estable.
- **Reutiliza**: patrón de `Fauna.plan_region`; `estado`/`rotos` para el estado de cada lugar; `caminos` ya persistidos.
- **Cambios mínimos**: `mundo.registro` guardado (poblados, lugares, caminos con id/versión); génesis determinista por macrorregión (N3) que decide ruinas, campamentos y cuevas (solo entrada) con restricciones (bioma, agua, distancia, accesibilidad) y los une con caminos sembrados en `estado.caminos` (A* con coste: un solo algoritmo nuevo y pequeño); lugares como datos; estado de cada lugar por deltas.
- **Dependencias**: Fase 1 (registro de poblados), N2/N3.
- **Aceptación vigente en Fase 4**: mismo registro con cualquier orden de generación de macrorregiones y tras reiniciar; ≥1 lugar a ≤128 celdas euclídeas de la salida en el 100 % de 100 semillas, con ruta continua y colisión real transitable desde el camino; ampliar a una macrorregión nueva no cambia lo ya generado; `prueba_terreno`, `prueba_terreno_red`, `prueba_fauna` sin regresión. El requisito original de otro pueblo queda para Fase 5, según la precisión anterior.
- **Riesgo**: **medio** (determinismo cliente/servidor del registro, tamaño del guardado).

### Fase 5 — Pueblos preexistentes y su transición cercana↔lejana (D3, D6)
**Estado al 26/10:** 5a implementada. Arquitectura de catálogo aprobada después de la revisión: **primera vivienda terminada funcional implementada y validada**, ver ESTADO.md §3i y [ARQUITECTURA_EDIFICIOS_MUNDO_1.md](ARQUITECTURA_EDIFICIOS_MUNDO_1.md). Planos/etapas preparados; el ejecutor progresivo completo no bloquea Fase 5. Continuación implementada: taller construible con mesa/horno/cofre y casas comunales completas en la génesis de las dos comunidades; almacenamiento integrado como anexo funcional, sin depósito independiente ni modificación del precio de puestos del jugador. Ver ESTADO.md §3j y arquitectura §8. Dos comunidades de génesis en mundos nuevos (`La Hondonada`, `Los Sauces`), con rutas, residentes resumidos identificables, cosechas/extracción reales, mapa e intercambio cercano de información. Ver ESTADO.md §3h para pruebas y límites. No se convierte todavía el resumen en NPC de rutinas completas: 5b conserva su carácter aplazable y no se declara cerrada. No hay migración diseñada de mundos previos.
- **Objetivo**: otros pueblos con habitantes identificables, actividad económica y evolución observable, sin simular detalle a distancia.
- **Reutiliza**: `Asentamientos` (puesto con más piezas/residentes), `visibles()` (nivel b), `Habitantes.registrar_colono` (nivel c).
- **Cambios mínimos, en dos etapas**: **5a** pueblos preexistentes como puestos con oficios y producción resumida, visibles por `visibles()`; **5b** (objetivo de diseño, **aplazable** hasta resolver identidad, recursos y red; no descartable) materialización a habitante completo al acercarse un jugador y reversión al alejarse, devolviendo inventario y memoria al resumen. 5a ya exige identidad estable de cada residente (id, nombre, oficio, historia) para que 5b sea posible después.
- **Dependencias**: Fase 4; contrato de transición (qué se persiste, qué identidad conservan).
- **Aceptación**: 5a: tras 3 días simulados los pueblos preexistentes cambian de forma observable (cosecha, construcción) sin jugadores y sin duplicar/perder recursos al guardar y cargar. 5b: el recorrido resumido→detallado→resumido conserva recursos y memoria (suma de inventarios idéntica) y el mismo id.
- **Riesgo**: **alto en 5b** (identidad en red, recursos); por eso se separa.

### Fase 6 — NPC fundan y los pueblos decaen (D3, D6, D13)
**26/10, autorización posterior del usuario:** primer bloque implementado: necesidades existentes → demanda/tarea individual → ejecución material → resultados persistentes, reclamo exclusivo de recursos de aprovisionamiento, interrupciones y bloqueo. [Contrato y contraste](../../Linde/cenital/docs/AUTONOMIA.md#fase-6--primer-bloque-causal-26102026); [diseño maestro de Arena](Diseno_Maestro_Fase6_Linde.md), referencia principal sin aprobar automáticamente todas sus recomendaciones. Validación: tareas 16, autonomía 33, sociedad 48, sin fallos. Próximo bloque: demanda colectiva y stock/compromisos/trabajo en curso; economía resumida después. Sin comercio nuevo, viabilidad, migración ni fundación en esta entrega. 5b sigue aplazada. La aceptación histórica de «≥1 fundación» de abajo corresponde a la fase completa; no es una cuota que deba forzarse ni la aceptación de este bloque.
**Segundo bloque, 26/10:** consolidación colectiva implementada en Sociedad, consumida por su selector/depósito y publicada por Asentamientos. Descuenta stock, reservas y compromisos, garantías reales y trabajo individual/colectivo en curso; conserva la tarea propia y evita pedidos equivalentes. Adaptador regional pasivo de deuda/consumo vencido/herramientas, sin modificar su producción. Pruebas puntuales: colectivas 50/50, tareas 16/16; [contrato](../../Linde/cenital/docs/AUTONOMIA.md#fase-6--consolidación-colectiva-26102026), [evidencia](../../production/qa/evidence/mundo-1/fase-6-colectivas/README.md). Sustituye el «próximo bloque» del párrafo anterior. Siguiente: conectar saldos con operaciones/resultados regionales conservativos. 5b, comercio entre pueblos, migración y fundación siguen fuera del bloque.
- **Objetivo**: que el mundo crezca y se contraiga por sí mismo, **por necesidades y condiciones reales** (no por eventos programados para garantizar una fundación periódica).
- **Reutiliza**: `Asentamientos.validar/crear` con dueño NPC, costes reales, `Sociedad.presion()`, `Arraigo`.
- **Cambios mínimos**: criterio de fundación basado en excedente/presión ya medidos; viaje de los fundadores; estado de poblado `activo/en declive/abandonado/recuperado` con umbrales sostenidos; el abandono conserva nombre, restos y conocimiento; la viabilidad (N6: comida, camas, residentes y seguridad; umbrales por medir) alimenta el fallback de Fase 1.
- **Dependencias**: Fases 1 y 5; mediciones de equilibrio de comida/materiales (D14).
- **Aceptación**: en 10 días simulados, ≥1 fundación en alguna semilla sin entregar materiales y sin sobrepasar el tope técnico; un poblado sin comida pasa a declive y luego a abandono; un nuevo jugador cuando el inicial está abandonado aparece en otro viable; todas las suites de autonomía y crecimiento sin regresión.
- **Riesgo**: **alto** (equilibrio, estabilidad de la población, red).

### Fase 7 — Ecología y dificultad territorial (D12)
- **Objetivo**: peligro orgánico, reconocible y cambiante.
- **Reutiliza**: `Fauna.plan_region` + datos; `bajas/heridos`; `Combate`.
- **Cambios mínimos**: perfil de hábitat por bioma en datos; zonas de calma alrededor de caminos y poblados; amenazas ligadas a lugares de Fase 4; señales (rastros) derivadas del estado real; efecto de acontecimientos (un campamento arrasado cambia la densidad local) por deltas; **arreglo del atasco** con el BFS existente (P2). Sin escalado por nivel ni cambios de estadísticas ni de balance sin medición.
- **Dependencias**: Fase 4.
- **Aceptación**: tasa de atasco <5 % en el escenario P2; en el trayecto al primer lugar, ninguna criatura hostil a <R celdas del camino; todo peligro anunciado ≥T s; `prueba_fauna` (31) sin regresión; ninguna estadística cambia.
- **Riesgo**: medio (balance indirecto: la densidad también es balance; medir).

## 5. Orden, paralelismo y primeras entregas
Orden recomendado: **0 → 1 → (2 ∥ 3) → 4 → 5a → 7 → 5b → 6**. Las fases 2 y 3 son independientes entre sí y de bajo riesgo. Primer ciclo jugable completo = fases 0–4 (pueblo con sentido, mapa, pistas, destinos). El mundo que cambia por sí mismo (5a, 6, 7) es la segunda tanda.

## 6. Reutilización frente a trabajo nuevo
- **Se reutiliza tal cual**: terreno y diferencias, red, guardado, fauna, saberes, trueque, construcción, `Asentamientos`, `Arraigo`, `Habitat`, `bloques`/rumor de NPC.
- **Trabajo nuevo, pequeño y acotado**: registro de poblados/lugares; A* de caminos con coste (el BFS actual no pondera); materialización resumido→detallado (5b); reglas de pistas en datos; panel de mapa.
- **No se necesita**: nuevas dependencias externas, `terreno_v3`, motor de IA, simulación detallada de todos los pueblos.

## 7. Qué está verificado y qué no
- **Verificado en código**: todo lo marcado [C] (leí `asentamientos.gd` completo, `autonomia.gd` de conocimiento, `habitantes.gd`, `sociedad._inmigrar`, `mundo.gd`, `juego.gd` de inicio y tick, y las referencias a constantes del Valle).
- **Solo documentado**: casas, equilibrio, comportamiento con Internet real, fauna en red, expediciones/cultivos con clientes reales.
- **No verificado**: que los pueblos «no inmortales» sean estables; costes de la materialización; tamaño del guardado con mapa; cuánto tarda un jugador en cada hito.
- Los umbrales y valores (X, N, R, T) se fijan con mediciones y con tu aprobación (D14).

## 8. Preparación de las fases 0 y 1

### 8.1 Confirmación: ¿puede la Fase 1 hacerse de forma incremental y reversible?
**Sí, con una condición**: dividirla en cinco pasos, cada uno en su propio commit, los dos primeros sin cambio de comportamiento y los demás tras un interruptor en el registro. La herramienta que lo hace comprobable ya existe: el **hash del estado completo por día** usado en la optimización de `_recurso` (idéntico antes y después = ningún comportamiento cambió).

Dependencias reales del Valle fuera del arte [C, `grep` de hoy]:
| Constante | Dónde se usa (no arte) |
|---|---|
| `ENTRADA` | `habitat.gd:78`, `habitantes.gd:114` (los colonos nacen allí), `mundo_vivo.gd:115`, `mundo.gd` (semilla de `alcanzables`, exclusiones de objetos y slimes) |
| `ESENCIALES` | `habitat.gd:51`, `desarrollo.gd:331`, `sociedad.gd:975,1006,1011,1188,1249`, `mundo.gd:394` |
| `CAMAS` | `habitantes.gd:85` |
| `CLARO`, `SPAWN_GUARDIAN` | `combate.gd:69` (jefes), `mundo.gd` (slimes, `punto_inicio`) |
| `CASA`, `PUERTA_C` | solo presentación: `arte_entornos.gd`, `escena.gd`, `mundo_arte.gd` |
Total: 6 archivos de lógica y 3 de presentación.

| Paso | Qué hace | Cambia el comportamiento | Reversión | Verificación mínima |
|---|---|---|---|---|
| **1a** Registro `poblados` | Crea `d.mundo.poblados` con el poblado inicial cuyos campos **son** las constantes actuales; valores por defecto en código si falta (así un cliente o guardado sin el registro sigue funcionando) | No | Revertir el commit | Hash de estado por día idéntico, ignorando la clave nueva; `prueba_red` (el registro viaja en `estado_para`, que copia `mundo` entero [C]) |
| **1b** Indirección | `entrada()`, `esenciales()`, `camas()` leen del registro; los 6 archivos de lógica dejan de usar las constantes directas, uno por commit | No | Revertir commits | Mismo hash por día; `prueba_autonomia`, `prueba_sociedad`, `prueba_arraigo`, `prueba_casas_arraigo` |
| **1c** Inicio por poblado | `punto_inicio` pasa a elegir cerca de la plaza o casa del poblado, con dispersión entre compañeros, registro del motivo y fallback explícito; el modo anterior se conserva como `inicio.modo = "legado"` | **Sí, solo la aparición** | Interruptor | 500 semillas: pruebas duras actuales + cercanía + dispersión; cero candidatos usa el fallback sin error; dos `unir` seguidos válidos; `prueba` y `prueba_red` sin fallos nuevos |
| **1d** Hitos y estación común | Nombres y posiciones de hitos como datos; instalación comunitaria coherente con los oficios (M1-D5) | **Sí, el mundo inicial** (los habitantes dejan de construir esa estación) | Interruptor `estacion_comun` | Alcanzable por BFS; simulación corta con y sin interruptor, comparando qué construyen; sin tocar costes |
| **1e** Contenido hostil fuera del núcleo | Parametrizar las zonas de exclusión de slimes y la ubicación del guardián respecto del poblado | **Sí, la ubicación de enemigos** | Interruptor | `prueba_fauna`, `prueba` (combate); distancias mínimas medidas |
Los pasos 1d y 1e **cambian el mundo inicial**, así que se aprueban por separado; 1a–1c pueden hacerse sin tocar el juego visible.

**Riesgos que persisten**: (1) 1b toca 6 archivos que otras sesiones también editan; (2) si el registro tomara valores de un JSON nuevo bajo `datos/`, habría que decidir si entra en la huella de reglas (`huella.gd`); se evita en 1a manteniendo los valores por defecto en código; (3) el cliente debe tener el registro antes de llamar a los getters (los valores por defecto lo cubren); (4) «partidas viejas no importan», por lo que no se necesitan migraciones.

### 8.2 Fase 0: pruebas mínimas (sin cambiar el juego)
| # | Prueba | Salida | Criterio |
|---|---|---|---|
| P0.1 | Guion de ritmo: con el mundo real, un «jugador» ejecuta por la API (`golpear`, `fabricar`, `poner`) la ruta mínima hacha→mesa→pico→salida→regreso, usando el intervalo de golpe y la velocidad reales leídos del código | golpes, pasos y minutos de juego/reales por hito, en 5 semillas | Termina en las 5 semillas; tabla de hitos |
| P0.2 | Tiempo hasta «artesano» (nivel 3) con la ruta de P0.1 y recolección repetida | minutos y acciones | Dato medido (hoy no existe) |
| P0.3 | Hash de equivalencia por día (herramienta de la optimización) fijado como línea base del Valle actual | hash por día para semillas 123 y 456, 4 días | Reproducible dos veces (control) |
| P0.4 | Inicio actual en 200 semillas (ya hecho) | distancias | Se conserva como línea base de 1c |
Todas son scripts de medición. **Decisión pendiente**: guardarlos como `tests/medir_*.gd` en el repositorio (código nuevo no de producción) o dejarlos fuera; recomiendo guardarlos, porque P0.3 es la red de seguridad de la Fase 1.

### 8.3 Pruebas mínimas de la Fase 1 (resumen)
Hash de estado por día (1a, 1b) · 500 semillas de inicio (1c) · `prueba_red` con dos `unir` (1c) · `prueba_autonomia`, `prueba_sociedad`, `prueba_arraigo`, `prueba_casas_arraigo`, `prueba_crecimiento`, `prueba_saberes`, `prueba_fauna`, `prueba_terreno` y `prueba` tras cada paso que toque lógica. No se piden corridas largas sin hipótesis.

### 8.4 Fase 0 completada (26/10) y propuesta del paso 1a
**Hecho**: herramientas `tests/medir_*.gd` y línea base en [production/qa/evidence/mundo-1/fase-0](../../production/qa/evidence/mundo-1/fase-0/README.md) (commit `9687dd2`).
**Bloqueos reales observados** (cotas inferiores, no una partida jugada):
1. **Nadie a la vista al aparecer**: 0 de 20 semillas con un habitante en el encuadre; mediana de 23,8 celdas a la puerta de la casa.
2. **El ritmo temporal no es el problema**: un jugador de referencia completa hacha, pico, mesa, horno, nivel 3, «artesano» y primer lingote en ≈2,3 min y sale del Valle a los ≈2,7 min. Lo que falta es saber qué hacer (orientación y pistas), no tiempo.
3. **Recursos finitos y escasos en el Valle**: 3 vetas, 29 rocas y 94 árboles que no regeneran; el jugador voraz agota las 3 vetas y 17–25 rocas en menos de 3 minutos. La mena de hierro obliga a salir del Valle de inmediato y compite con el oficio de cantero de los habitantes [I: no medida su producción].
4. **La estación común no se justifica por tiempo** (el jugador construye mesa y horno en ≈30–48 s); sí por coherencia del pueblo (M1-D5).

**Paso 1a (solo `scripts/mundo.gd` + una suite nueva; no cambia comportamiento)**:
- Constante `ID_INICIAL`; función estática que devuelve el poblado inicial **a partir de las constantes actuales** (`ENTRADA`, `ESENCIALES`, `CAMAS`, área del Valle y centro en el cruce de caminos), con campos: `id`, `nombre`, `centro`, `area`, `entrada`, `esenciales`, `camas`, `estado`.
- `Mundo.configurar` (donde ya se añaden `caminos/pisadas/techos`) crea `estado.poblados = {ID_INICIAL: ...}` si falta.
- Lectores `entrada()`, `esenciales()`, `camas()` que leen el registro y, si falta, devuelven las constantes (un cliente o guardado sin el registro sigue funcionando). **Ningún consumidor cambia** (eso es 1b).
- **Pruebas**: `tests/prueba_poblados.gd` (los lectores igualan las constantes en partida nueva; el registro sobrevive a guardar y cargar; llega al cliente por `estado_para`; los lectores usan el respaldo si el registro falta) + `medir_equivalencia ... ignorar=mundo.poblados` en las semillas 123 y 456 debe dar los hashes de la línea base + `prueba`, `prueba_red`, `prueba_autonomia`, `prueba_terreno` sin fallos nuevos (el fallo previo de arte persiste).
- **Reversión**: revertir el commit; nada depende del registro. **Riesgo**: bajo (solo si una suite compara el conjunto exacto de claves de `mundo.estado`).
- **Resultado (26/10)**: implementado y verificado en `2ac3f67`; ver [ESTADO.md §3d](../../production/epics/mundo-vivo/ESTADO.md).

## 9. Revisión de consumidores del paso 1b (sin implementar)

Alcance: solo `entrada()`, `esenciales()` y `camas()`. No se sustituyen otras constantes geométricas ni se eliminan los respaldos. Criterio: refactorización sin cambios de comportamiento, comprobada con los **hashes completos** del estado (sin `ignorar`) frente a una línea base tomada con 1a ya aplicado.

### 9.1 Interfaz aprobada (26/10)
Los lectores de 1a no recibían argumento y devolvían siempre el poblado inicial. Se cambian en 1b a una interfaz con contexto territorial **explícito**: ninguna operación consulta «todos los pueblos» por defecto, porque la pertenencia a cualquier pueblo no equivale a la pertenencia al pueblo relevante para una acción.
| Lector | Firma | Semántica |
|---|---|---|
| `entrada` | `entrada(poblado_id: String) -> Vector2i` | Entrada de ese pueblo; `Vector2i(-1, -1)` si el id no existe |
| `esenciales` | `esenciales(poblado_id: String) -> Array` | Celdas esenciales de ese pueblo; `[]` si no existe |
| `camas` | `camas(poblado_id: String) -> Dictionary` | Camas fijas de ese pueblo (id de habitante → celda); `{}` si no existe |
Sin valores por defecto: cada llamador nombra el pueblo. Los consumidores que todavía dependen del Valle pasan `Mundo.ID_INICIAL` de forma explícita (con comentario); la generalización posterior sustituirá ese identificador por el pueblo correspondiente. Si un consumidor necesitara de verdad una unión global, se añadirá un lector con nombre propio (`todos_los_esenciales()`, `todas_las_camas()`) con su justificación; **en 1b ninguno la necesita**. Los lectores consultan el `estado.poblados` de su propia instancia de `Mundo` (sin caché estática). Respaldo: solo para `ID_INICIAL`, si el registro falta, devuelven las constantes; para cualquier otro id inexistente devuelven vacío.

### 9.2 Tabla de consumidores
Dos tipos de uso. En 1b **todos** pasan `Mundo.ID_INICIAL`: **pertenencia** (¿esta celda es esencial en el pueblo relevante?) y **alcanzabilidad/llegada** (relación con la entrada de un pueblo concreto). Los de pertenencia podrían necesitar más adelante «el pueblo que contiene la celda» o una unión con nombre propio; se decide cuando exista un segundo pueblo.

| # | Archivo y función | Constante hoy | Lector que la reemplaza | ¿Conserva exactamente el comportamiento? | Riesgo o dependencia |
|---|---|---|---|---|---|
| 1 | `desarrollo.gd` `_ampliar` (l. 331) | `M.ESENCIALES.has(c)` | `j.mundo.esenciales(M.ID_INICIAL).has(c)` (pertenencia) | Sí: mismo contenido y orden, `has` igual | Está dentro de 3 bucles anidados: **sacar el lector fuera de los bucles** (`var ess := ...`) para no crear un `Array` por celda |
| 2 | `habitat.gd` `admisible` (l. 51) | `M.ESENCIALES.has(c)` | `j.mundo.esenciales(M.ID_INICIAL).has(c)` (pertenencia) | Sí | Recorre cada celda de la zona (≈42) y se llama hasta 64 veces por búsqueda: lector fuera del bucle. La función sigue atada al Valle por `habitat.gd:45` (`es_valle`), que **no** se toca |
| 3 | `habitat.gd` `reservar` (l. 78) | `M.ENTRADA` en `camino(M.ENTRADA, …)` | `j.mundo.entrada(M.ID_INICIAL)` (llegada) | Sí | Dependencia explícita del poblado inicial; a futuro, el poblado de la parcela |
| 4 | `habitantes.gd` `cama` (l. 85) | `Mundo.CAMAS.has(id)` / `Mundo.CAMAS[id]` | `var c := j.mundo.camas(Mundo.ID_INICIAL); c.has(id)` | Sí | **Camino caliente** (11 llamadores): un `Dictionary` por llamada. Requiere medir CPU; si hace falta, caché **por instancia** invalidada al cambiar el registro |
| 5 | `habitantes.gd` `reconciliar` (l. 114) | `Mundo.ENTRADA` en `pies_de_celda` | `j.mundo.entrada(M.ID_INICIAL)` (llegada) | Sí | Hoy todos los recién llegados nacen en la entrada del Valle: aquí está la futura decisión «¿en qué poblado llega?» (Fase 6) |
| 6 | `mundo_vivo.gd` `_llegadas_posibles` (l. 115) | `Mundo.ENTRADA` en `camino(...)` | `j.mundo.entrada(Mundo.ID_INICIAL)` (llegada) | Sí | Igual que 5 |
| 7 | `sociedad.gd` `_construir_cerca` (l. 975) | `M.ESENCIALES.has(c)` | `esenciales(M.ID_INICIAL).has(c)` (pertenencia) | Sí | Bucle por celdas: lector fuera del bucle |
| 8 | `sociedad.gd` `construir_pieza` (l. 1006) | `M.ESENCIALES.has(c)` | `esenciales(M.ID_INICIAL).has(c)` (pertenencia) | Sí | — |
| 9 | `sociedad.gd` `construir_pieza` (l. 1011) | `for e in M.ESENCIALES: if not alc.has(e)` con `alc = j.mundo.alcanzables()` | `for e in j.mundo.esenciales(M.ID_INICIAL)` (**alcanzabilidad**) | Sí | `alcanzables()` parte de la entrada del Valle; con una unión, los esenciales de otro pueblo no serían alcanzables y se prohibiría construir en todas partes. Suposición de un solo pueblo, explícita |
| 10 | `sociedad.gd` `_refugio` (l. 1188) | `M.ESENCIALES.has(w)` | `esenciales(M.ID_INICIAL).has(w)` (pertenencia) | Sí | Bucle: lector fuera |
| 11 | `sociedad.gd` `_casa` (l. 1249) | `M.ESENCIALES.has(c)` | `esenciales(M.ID_INICIAL).has(c)` (pertenencia) | Sí | Bucle: lector fuera |
| 12 | `mundo.gd` `construccion_segura` (l. 433) | `for e in ESENCIALES: if not alc.has(e)` con `alc = alcanzables()` (rama del Valle) | `for e in esenciales(ID_INICIAL)` (**alcanzabilidad**) | Sí | Mismo motivo que 9. La rama exterior no usa esenciales |

12 sustituciones en 6 archivos (`desarrollo` 1, `habitantes` 2, `habitat` 2, `mundo_vivo` 1, `sociedad` 5, `mundo` 1).

### 9.3 Usos que **no** se tocan en 1b (siguen dependiendo del Valle)
| Dónde | Constante | Motivo |
|---|---|---|
| `mundo.gd` `_init` (l. 75) | `CAMAS` al colocar las camas del Valle | Es la definición del mapa de autor; ocurre antes de que exista el registro (y el registro se deriva de ella) |
| `mundo.gd` `_libre_para_objeto` (l. 215), `_generar_slimes` (l. 245) | `ENTRADA` | Generación del mapa de autor en `_init`, antes del registro; afectaría a la ubicación de objetos y enemigos (pasos 1d/1e) |
| `mundo.gd` `alcanzables(desde = ENTRADA, …)` (l. 389) | `ENTRADA` como valor por defecto | Es un uso de la constante **fuera de los tres lectores** y es la suposición más profunda: las llamadas `alcanzables()` sin argumento (`punto_inicio`, `construccion_segura`, `sociedad` l. 1009 …) parten siempre de la entrada del Valle. GDScript permite que un valor por defecto invoque un método de la instancia (comprobado), así que se podrá resolver sin cambiar a los llamadores, pero modifica la semántica y queda fuera del alcance de 1b |
| Pruebas (`prueba.gd`, `prueba_arraigo.gd`, `prueba_sociedad.gd`, `prueba_saberes.gd`, `prueba_desarrollo.gd`, `prueba_casas.gd`, `prueba_carga_crecimiento.gd`, `medir_*.gd`) | constantes | Código de verificación: no cambia |

### 9.4 Respuesta a la preocupación estructural
- Cambiar constantes por funciones **no esconde el Valle**: los 12 sitios pasan `ID_INICIAL` explícitamente (contables con `grep`) y los lectores no tienen valor por defecto ni unión implícita.
- Lo que 1b **no** resuelve y queda a la vista: el valor por defecto de `alcanzables` (§9.3), `habitat.gd:45` (`es_valle`), las rutinas de `Habitantes` (lugares del Valle en el paquete de datos), la ubicación de colonos en `reconciliar` y las exclusiones de generación de 1e.

### 9.5 Verificación propuesta para 1b
1. **Línea base nueva con 1a ya aplicado** y **sin `ignorar`**: `medir_todo.sh production/qa/evidence/mundo-1/fase-1a` (ya generada o por generar antes de tocar nada). Después de 1b: `medir_todo.sh --comparar fase-1a <nueva>` debe dar 8 de 8 «igual» **con los hashes completos**.
2. `prueba_poblados` actualizado a la nueva firma, con casos de ids válidos, ids inexistentes, aislamiento entre dos pueblos sintéticos y respaldo del registro.
3. Suites: `prueba`, `prueba_autonomia`, `prueba_sociedad`, `prueba_arraigo`, `prueba_casas_arraigo`, `prueba_crecimiento`, `prueba_desarrollo`, `prueba_saberes`, `prueba_red`, `prueba_proteccion`, `prueba_terreno`, `prueba_fauna` y `prueba_casas`.
4. **Compuerta de CPU** (no de comportamiento): comparar `tick_medio_us` de `medir_equivalencia` con la línea base de 1a; si sube de forma apreciable, introducir caché por instancia y volver a medir (el umbral concreto se fija con la medición, no se supone).
5. Un commit por archivo de lógica (6) más uno para la firma y el test, cada uno con su comparación de hashes; cualquier diferencia detiene el paso.

**Riesgos de 1b**: rendimiento de `camas()`/`esenciales()` en bucles (§9.2 filas 1, 2, 4, 7, 10, 11); semántica de la unión mal aplicada en sitios de alcanzabilidad (filas 9 y 12); archivos que otras sesiones también editan (`sociedad.gd`, `habitantes.gd`).
- **Resultado (26/10)**: implementado y verificado; ver [ESTADO.md §3d](../../production/epics/mundo-vivo/ESTADO.md).

## 10. Paso 1c — propuesta técnica (sin implementar)

Objetivo: que quien entra aparezca en el pueblo inicial con una referencia clara de la comunidad, de forma segura, determinista y reutilizando el registro `mundo.poblados`. Proporcionado al estado actual: **un solo pueblo real**, sin sistema de reaparición general.

### 10.1 Lo que dice el código y lo que se midió (26/10, semilla 123, sin cambiar nada)
| Hallazgo | Evidencia |
|---|---|
| Se entra por un solo punto: `Juego.unir` (el servidor lo llama en `red_servidor.gd:130`) y `Juego.nueva`; ambos usan `Mundo.punto_inicio(semilla)`, que no mira a los jugadores ya presentes ni a los enemigos vivos | `juego.gd:56-69, 149-156` [C] |
| Quien cae sin cama reaparece en `pj.inicio`, la celda guardada al entrar, **sin revalidarla** (`_derrota`) | `juego.gd:340-342` [C] |
| En `Juego.nueva` la posición se calcula **antes** de crear habitantes y combate (`_arrancar`) | `juego.gd:59-68` [C] |
| La regla actual (P05) exige ≥12 celdas de cualquier *punto de aparición* de slime. **Con ella no hay ninguna celda válida a 2–7 celdas de la plaza, el cruce, la puerta de la casa, la cantera ni el taller** | [M] `cands.gd`: 0, 0, 0, 0, 0 celdas |
| Los 12 slimes se generan en cualquier lugar libre del Valle salvo cerca de la entrada sur; el más cercano al cruce está a 2,8 celdas, a la plaza 4,0, a la puerta 7,3, a la cantera 6,4, al taller 6,1 | [M] |
| El radio con que un slime detecta al jugador es su `vision` del catálogo: 80 px = 5 celdas (el guardián, 140 px = 8,75). Los enemigos en reposo vuelven a su origen y no deambulan | `catalogos.gd:116-118`, `combate.gd` `_paso_enemigo` [C] |
| Con «fuera del radio de detección» (en vez de 12 celdas) sí hay candidatas: **cruce 41, plaza 69, puerta 34, cantera 28, taller 29** celdas válidas a 2–7 celdas (con 8 celdas: cruce 4, plaza 27, puerta 1) | [M] |
| Maren duerme en la casa de 20:00 a 06:00 y el horario de datos la lleva al taller (dentro de la casa) de 06:00 a 12:00 y a la **plaza** (34,25) de 12:00 a 14:00; Ordal trabaja en la cantera (10,9). **Con la autonomía activa se desvían**: Maren salió del Valle (x < 0) a las 08:00 y 10:00 | [C] datos; [M] posiciones cada 30 min |
| Habitante fuera de edificios y dentro del encuadre de la cámara desde un ancla, en 49 muestras de 24 h: cruce 35 %, plaza 33 %, puerta 39 % (de día, 8, 7 y 10 de 29). Hay algún habitante en el Valle fuera de la casa en 35 de 49 muestras (71 %) | [M] |
| El encuadre es de ≈26,7×15 celdas, es decir ±7,5 celdas en vertical: **un radio ≤7 garantiza ver el ancla** y a quien esté a ese radio | `medir_inicio` (Fase 0) |

**Conclusión de diseño**: la referencia fiable es un **lugar** (el centro del pueblo del registro), no la presencia de los habitantes: sus rutinas son autónomas, salen del Valle y duermen en la casa. Garantizar compañía exigiría mover rutinas, que queda fuera.

### 10.2 Qué entra en 1c y qué no
| Dentro de 1c | Depende de otro paso |
|---|---|
| Elegir la celda de aparición cerca de `poblado.centro`, validada con el estado **actual** del mundo | **1d**: nombres de hitos, estación común, un lugar reconocible (plaza marcada) en vez del cruce de caminos |
| Dispersión determinista entre jugadores que entran | **1e**: sacar los slimes del núcleo del pueblo. Sin eso el pueblo sigue teniendo enemigos a 3–7 celdas del centro; 1c solo asegura que no te vean al aparecer |
| Revalidar al reaparecer sin cama (`_derrota`) con la misma función | **Fase 5/6**: que los habitantes estén en el centro (rutinas, comercio, plaza) |
| Interruptor `legado`/`poblado` | **N6**: viabilidad con umbrales de comida, camas, residentes y seguridad |
| Política explícita cuando el pueblo no es viable o no hay candidatas | **Fase 4–6**: elegir entre varios pueblos reales |

### 10.3 Alternativas
| | A. Ancla fija en `poblado.centro` (recomendada) | B. Ancla en el residente más cercano al centro | C. Mantener `punto_inicio` y solo relajar a 8 celdas |
|---|---|---|---|
| Idea | Candidatas a 2–7 celdas del centro del pueblo del registro | Igual, pero alrededor de un residente visible si lo hay; si no, el centro | Sigue eligiendo al azar en el Valle |
| Referencia de comunidad | Un lugar fijo y reconocible, mismo para todos | Compañía cuando existe, pero el sitio cambia con la hora (primer arranque a las 06:00: junto a Ordal en la cantera, a ≈28 celdas del cruce; Maren aún en la casa) | Ninguna |
| Habitante a la vista (de 24 h) | ≈33–39 % | Hasta ≈71 % (cuando hay alguien en el Valle) | 0/20 en la línea base |
| Complejidad | Baja: ≈40–60 líneas | Media: añade la selección de anclas dinámicas y casos de borde | Mínima |
| Extensible a otros pueblos | Sí: cada pueblo tiene su centro | Sí | No |
| Riesgo principal | Poca gente a la vista a ciertas horas | Aparecer lejos del núcleo y cambiar el sitio con la hora | No resuelve el problema |
**Recomendación**: **A**. Cumple el objetivo (referencia clara), es proporcionada y no toca rutinas. B es un incremento posible si, tras medir A, se decide que falta compañía; cambia solo la elección del ancla.

### 10.4 Diseño recomendado (A)
Una única función, `Juego.punto_aparicion(jugador_id) -> Dictionary` (`{celda, poblado, motivo}`), usada por `nueva`, `unir` y `_derrota` (sin cama). Sin sistema aparte: lee el registro y las validaciones existentes.
1. **Poblados candidatos**, en orden: el del jugador (hoy `ID_INICIAL`), luego los demás por id. Un poblado es elegible si `estado == "activo"`, hay al menos un habitante presente y existe alguna celda válida. Son tres condiciones booleanas; **no se usan umbrales numéricos de viabilidad** (N6 sigue pendiente de medición).
2. **Celda válida** (reglas existentes + dos nuevas, todas derivadas de datos del juego):
   - terreno `PASTO` o `CAMINO`, 3×3 sin bloqueo, alcanzable desde `entrada(poblado)` y no ocupada (`bloquea`, `alcanzables`, `ocupada`: ya existen);
   - fuera del radio de detección (`vision` del catálogo) de cada enemigo **vivo** (`combate.enemigos`, `est != "muerto"`); sustituye a «≥12 celdas de puntos de aparición». *Decisión P05 → ver 10.5*;
   - a 2–7 celdas (euclídea) de `poblado.centro`: **7** = mitad del alto del encuadre medido (±7,5); **2** = una celda libre de separación respecto al ancla (el sprite ocupa 1 celda).
3. **Selección y dispersión**: candidatas ordenadas por (distancia al centro, y, x); se descartan las que estén a menos de 2 celdas (Chebyshev) de otro jugador presente (`rt`); entre las restantes se toma `hash(semilla, jugador_id) % n`. Determinista para el mismo estado y mismo jugador, distinta para jugadores distintos mientras haya candidatas. Si la separación deja cero candidatas, se relaja a «celda no ocupada».
4. **Mundo persistente**: todo se evalúa al entrar con el estado actual; una celda construida, ocupada o con un enemigo cerca queda excluida sin tratamiento especial. Quien ya existe en `d.jugadores` conserva su posición guardada (no pasa por esta función).
5. *(Sustituido por §10.8 C4: no hay respaldo a `punto_inicio` ni a la entrada.)* **Pueblo inviable / sin candidatas**: se prueba el siguiente poblado. Si ninguno sirve: **política explícita** → `motivo = "sin_poblado_viable"`, se usa el `punto_inicio` anterior (la celda aleatoria válida del Valle); si tampoco hay, la celda `entrada(ID_INICIAL)`, que es esencial y transitable por definición. Siempre se avisa al jugador, se anota un suceso en el diario y se guarda `mundo.inicio.ultimo = {poblado, celda, motivo, min}` para auditoría. Nunca un respaldo silencioso.
6. **Interruptor**: `estado.inicio = {"modo": "poblado" | "legado"}` creado en `configurar`; con `legado` se llama exactamente a `punto_inicio(semilla)` como hoy. `medir_inicio` y `medir_equivalencia` aceptan `modo=` para comparar. Mundos sin la clave: `legado`.
7. **`Juego.nueva`**: la posición del primer jugador se calcula después de `_arrancar()` (necesita enemigos y registro) y se asigna a `rt[LOCAL].pies`, `pos` e `inicio`. Con `legado` se conserva el orden actual.
8. **`_derrota`**: sin cama, llama a la misma función en lugar de usar `pj.inicio` sin revalidar (commit propio y separable; con `legado` no cambia).

### 10.5 Decisiones que necesito *(respuestas y precisiones en §10.8)*
| ID | Decisión | Recomendación |
|---|---|---|
| C1 | La regla P05 («≥12 celdas de los puntos de aparición de slimes») hace imposible aparecer cerca del centro (0 celdas válidas). ¿Se sustituye, para la aparición en un pueblo, por «fuera del radio de detección de cada enemigo vivo» (5 celdas para el slime)? Alternativas: mantener 12 y esperar a 1e (mover slimes), o aparecer en la periferia como hoy | Sustituir, con `legado` disponible; 1e puede volver a endurecerla |
| C2 | ¿Alcance 7 celdas y separación de 2 celdas entre jugadores (derivados del encuadre y del tamaño del sprite)? | Sí |
| C3 | ¿Incluir en 1c la reaparición sin cama con la misma función (commit separado)? | Sí; evita un segundo sistema de aparición |
| C4 | ¿El interruptor es por mundo (`estado.inicio.modo`) y por defecto `poblado` en mundos nuevos? | Sí |
| C5 | Compañía: ¿A ahora y B solo si la medición lo pide? | Sí |

### 10.6 Pruebas de aceptación (medibles)
| Criterio | Medición | Aceptación |
|---|---|---|
| Seguridad | 500 semillas: tipo, 3×3 libre, alcanzable, no ocupada, distancia a cada enemigo vivo > su `vision` | 100 % válidas; ninguna dentro del radio de detección |
| Cercanía y orientación | distancia al centro; `centro` y la puerta de la casa dentro del encuadre | 100 % entre 2 y 7 celdas; `centro` siempre en el encuadre; porcentaje con la casa en el encuadre registrado como línea base nueva |
| Dispersión | 6 `unir` seguidos | 6 celdas distintas, separación ≥ 2 (Chebyshev) mientras haya candidatas, todas a ≤ 7 del centro |
| Determinismo | misma semilla y secuencia de jugadores, dos corridas | posiciones idénticas; hash de posiciones estable |
| Estado cambiado | construir sobre candidatas, colocar un slime vivo a 4 celdas, llenar el círculo | las celdas afectadas no se eligen; sin candidatas → siguiente poblado → política 5 con aviso y `inicio.ultimo.motivo` |
| Pueblo inviable | marcar `estado != "activo"` o vaciar los habitantes | usa otro poblado (sintético) o la política 5 |
| Persistencia | guardar/cargar | jugador conserva posición e `inicio`; `estado.inicio` se conserva; el siguiente `unir` es consistente |
| Red | `prueba_poblados`/`prueba_red` con dos clientes reales | ambos aparecen distintos, a ≤ 7 celdas del centro, sin errores; réplica con el mismo registro |
| Compatibilidad | `modo = legado` | hashes completos idénticos a `fase-1a` (ignorando solo `mundo.inicio`) y mismas posiciones que `punto_inicio` |
| Sin efectos laterales | `medir_equivalencia` con un jugador en modo `poblado` | hash de NPC/inventarios/construcciones igual al de `legado` salvo la posición del jugador y `mundo.inicio` (se compara por secciones) |
| Regresión | suites de autonomía, sociedad, arraigo, crecimiento, red, fauna, terreno, ui, `prueba` | sin fallos nuevos (el fallo previo de arte persiste) |

### 10.7 Riesgos
- **Pueblo con enemigos dentro**: 1c solo evita la detección inmediata; un slime puede acercarse después (hasta 1e). El jugador puede huir (velocidad 4 celdas/s frente a 1,75).
- **Reordenar `Juego.nueva`**: toca el arranque; cubierto por el interruptor y los hashes de `legado`.
- **Respawn**: cambiar `_derrota` afecta a todos los jugadores sin cama; commit aparte y con prueba propia.
- **Compañía**: A no la garantiza (≈33–39 % de las muestras con alguien a la vista); no se oculta ni se resuelve moviendo rutinas.
- **Retirada de P05 en este caso**: la protección contra «encuentro inevitable» pasa de 12 celdas a 5; si 1e mueve los slimes se puede restablecer.
- **Posición guardada de quien ya existe**: si se construyera encima de su celda, esta propuesta no la corrige (comportamiento actual).

### 10.8 Precisiones aprobadas por el usuario (26/10) — prevalecen sobre §10.4–10.6
**Principio de diseño**: los pueblos de Linde **no son zonas mágicamente seguras**; pueden sufrir ataques, perder habitantes y desaparecer. Un jugador nuevo, sin embargo, no debe aparecer junto a un enemigo sin posibilidad razonable de reaccionar. La solución definitiva es ecológica y vendrá de que un pueblo habitado mantenga las amenazas alejadas por su funcionamiento (construcciones, actividad, defensas). Por eso **1c es la solución de aparición y 1e la corrección de la ecología y distribución de amenazas del núcleo inicial**.

| ID | Resolución |
|---|---|
| A | Alternativa A aprobada: ancla estable y reconocible del poblado (`poblado.centro`). No se implementa B; no se teletransportan ni se alteran las rutinas de los NPC para garantizar compañía |
| C1 | Política provisional «fuera del radio de detección de los enemigos vivos» **solo en modo `poblado`**; no se elimina ni reemplaza P05 ni la regla de 12 celdas del modo `legado`. Transitoria hasta 1e. **Antes de confirmarla se mide qué ocurre en los primeros segundos tras aparecer** (aproximación, detección, persecución y daño). Si aparecen riesgos importantes se presentan alternativas; sin invulnerabilidad artificial ni cambios en el comportamiento de los slimes |
| C2 | Radio 2–7 celdas y separación mínima 2, **valores de prueba**, no de balance. La selección valida ocupación, construcciones, terreno, conectividad y enemigos; el hash solo ordena la búsqueda y **nunca sustituye** esas comprobaciones |
| C3 | `_derrota` sin cama usa el mismo sistema de validación, en commit separado. La reaparición con cama válida no se altera |
| C4 | Interruptor por mundo `poblado` / `legado`; el modo `legado` conserva equivalencia completa. **No hay respaldo a una entrada que no haya superado las validaciones esenciales ni a `punto_inicio`.** Recuperación explícita cuando no hay ninguna posición segura, sin inventar una celda ni crear un pueblo: **`unir` rechaza la entrada** con motivo explícito y registro (`mundo.inicio.ultimo`, suceso), sin crear al jugador, y el servidor informa al cliente; **`_derrota` deja al jugador donde cayó** (los enemigos que lo seguían lo olvidan, como ya ocurre) con aviso y registro. Una comunidad destruida (`estado != "activo"` o sin habitantes presentes) no se reactiva para dar cabida a nadie |
| C5 | Elegimos A |
El interruptor se crea en `legado`; la política `poblado` pasa a ser el valor por defecto de los mundos nuevos solo si las mediciones de C1 no muestran un riesgo relevante y tras tu aprobación de resultados.

**Pruebas añadidas**: (1) **seguridad posterior a la aparición**: tras aparecer con combate real, el jugador pasivo (peor caso) y el jugador que huye al detectar al enemigo, durante 30 s de juego, con registro de distancia mínima, primer estado de persecución, primer aviso de ataque y daño recibido, en las 500 semillas y con jugadores sucesivos; (2) las 500 semillas de seguridad estática; (3) dispersión de jugadores sucesivos; (4) persistencia; (5) red con clientes reales; (6) rechazo de entrada y reaparición sin posición segura, sin crear celda ni reactivar un pueblo no activo.
