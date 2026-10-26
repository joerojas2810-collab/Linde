# Resultados de P1, P2 y economía de Veloren

> **Fecha**: 2026-10-25 · **Base**: `HEAD 302c53d`, árbol de trabajo sin cambios de código propios · **Autorizado por el usuario** (mediciones sin tocar producción, balance ni reglas; `terreno_v3`, Simulated/Loaded y plugins siguen pospuestos).
> **Método**: las mediciones se hicieron sobre una **copia** del proyecto en una carpeta temporal fuera del repo, con temporizadores añadidos solo en la copia. No se modificó ningún archivo de `Linde/cenital/`. Nada se instaló.
> **Etiquetas**: **[M]** medido hoy · **[C]** comprobado leyendo código o metadatos · **[I]** inferencia · **[NV]** no verificado.

## 0. Corrección importante sobre el plan anterior

[PLAN_INTEGRACION_3_2_A_3_7.md](PLAN_INTEGRACION_3_2_A_3_7.md) evaluó un texto **que no era la investigación correcta** (fragmentos genéricos sin repositorios). La investigación correcta llegó después ("Texto pegado(6)", 1.073 líneas, que leí completa). Por tanto:

- Las secciones 0 y 1 de ese plan, que descartaban «la investigación» como no verificable, **no se aplican a la investigación correcta** y quedan sustituidas por la sección 1 de este documento.
- Las mediciones P1 y P2 **no dependen de ninguno de los dos textos**: miden código de Linde con los criterios del plan. Siguen siendo válidas.
- Lo que sigue vigente del plan anterior: el estado de Linde (ESTADO.md), la ausencia de física de Godot en el proyecto y los datos sobre licencias de Luanti.

## 1. Qué tan fiable es la investigación correcta (verificación contra los repositorios)

Comprobé rutas, licencias y fechas de los 14 repositorios que cita. Resultado: **el mapa general es bueno, los detalles no**. Varias rutas son inexistentes y al menos una fórmula central no está en el código citado.

| Afirmación | Resultado [C] |
|---|---|
| Veloren `world/src/sim2.rs` = «simulación macroclimática» | **Falso.** Son 7 líneas que solo llaman a `simulate_economy`. El clima y los biomas están en `world/src/sim/mod.rs` (`get_biome` por umbrales de temperatura, humedad, altitud y densidad de árboles; no una tabla de Whittaker en `land.rs`, que existe pero no leí) |
| Veloren `world/src/pathfinding.rs` = A* de carreteras | **Falso.** 36 líneas de un buscador vacío. El A* real está en `world/src/civ/mod.rs` (`find_path`, `walk_in_all_dirs`) con coste `1 + (Δaltura/5)² + coste_agua + 3 si no hay camino previo`; no es la fórmula `Distance×(1+α|Δh|+penalización)` que se cita |
| Veloren `rtsim/src/rule/trade.rs`, `rule/npc_ai.rs`, `data/npc.rs`, `server/src/rtsim/entity.rs` | **No existen** (`npc_ai` es un directorio; la economía vive en `world/src/site/economy/`) |
| Fórmula de precio `P = Base × (D/(S+ε))^γ` «en rtsim/trade.rs» | **No está en Veloren.** La real: `valor = 2^(1 − excedente/demanda)` suavizado con 0,8; precio = media de (valor de trabajo normalizado, valor normalizado) |
| «RTSim simula economía por tick en segundo plano» | **Matizado.** `simulate_economy` es una simulación **de historia en la generación del mundo** (bucle `HISTORY_DAYS`); su única conexión visible con los NPC es el inventario de los mercaderes (`trader_loadout`, que fuerza mínimos con comentarios como «economy isn't economying sometimes») |
| Veloren `voxygen/src/hud/tutorial.rs` (logros, pistas con tiempo) | **Existe** (949 líneas: `Achievement`, `add_hinted_goal` con `timeout`, `done`). Persistencia en `profile.rs` existe [contenido NV] |
| CDDA `overmap.cpp`, `mapgen.cpp`, `regional_settings.cpp`, `crafting.cpp`, `requirements.cpp`, `skill.cpp`, `monster.cpp`, `monmove.cpp`, `scenarios.json` | **Existen**. `furniture.cpp` no existe; `regional_map_settings.json` está en `data/json/region_settings/...`; las competencias están en `data/json/proficiencies/*.json`. Las cifras 180×180 y 24×24 [NV] |
| Wesnoth `shroud_map.cpp/.hpp`, `fog_of_war.cpp`, compresión RLE | **No existen con esos nombres.** Solo `src/actions/shroud_clearing_action.cpp`. La afirmación sobre RLE [NV] |
| Unciv `TutorialController.kt`, `data/json/tutorial.json` | El controlador existe en otra ruta (`ui/screens/basescreen/`); **`tutorial.json` no existe** (hay `models/ruleset/Tutorial.kt`). MPL-2.0 ✔ |
| Godot-GOAP | **Existe**, MIT, rama `main` para Godot 4 (`features 4.0`); **último cambio 2024-08-20** (sin mantenimiento reciente). Archivos citados ✔ |
| ExpressoBits | MIT, activo, **núcleo C++ GDExtension**; `craft_station.h` está en `src/craft/`; `craft_recipe.h`, `inventory_handler.h`, `nodes/craft_station.gd` **no existen** en las rutas citadas. La afirmación «multijugador nativo» ya se había marcado como no confirmada en `REFERENCIAS_INTERFAZ.md` |
| LimboAI | MIT, **v1.8.1 (2026-08-20)**, binarios para Godot 4.7.2 y GDExtension 4.6; rutas reales `bt/...`, `hsm/limbo_hsm.cpp`, no `src/bt/` |
| Flare | `StatBlock.cpp`, `PowerManager.cpp` ✔; `Enemy.cpp`, `EnemyManager.cpp` **no existen**; motor GPL-3.0, datos de `flare-game` sin SPDX único (CC BY-SA 3.0 mezclada) |
| SS14 | MIT; `SharedInteractionSystem.cs`, `DoorSystem.cs` ✔; `InteractableComponent.cs` y `ContainerManagerComponent.cs` no en esas rutas |
| GLoot | MIT; `prototree` es un directorio (`prototree/proto_tree.gd`) |
| `mg_villages` / `villagers` | **Sin licencia declarada** en GitHub (la investigación dice GPL-3.0 y WTFPL); último cambio 2023 y 2017 |

**Conclusión**: usar la investigación como **catálogo de candidatos**, no como especificación. Cada «algoritmo» debe leerse en el código antes de planificar con él.

## 2. P1 — Perfil de la planificación de habitantes [M]

**Escenario**: 4 días de juego simulados, ticks de 0,5 s (11.520), combate desactivado, sin acciones del jugador, semillas 123 y 456. La población fue de 2 a 5 habitantes (no los 12 del techo técnico). Instrumentación en la copia: temporizadores en `Sociedad.decidir/_obtener/_ocupar/_casa/_refugio/_explorar_lejos/objetivos/_plan_acuerdo`, `Autonomia.paso/_explorar`, `Asentamientos.actualizar`, `Habitat.reservar`, `Mundo.camino/alcanzables/construccion_segura`, `Juego.tick`.

| | semilla 123 | semilla 456 |
|---|---|---|
| Tick medio | 5,3 ms | 8,2 ms |
| p50 / p95 / p99 | 0,22 / 18 / 112 ms | 0,19 / 96 / 192 ms |
| Máximo | 225 ms | 296 ms |
| Ticks > 100 ms | 138 | 453 |
| Ticks > 800 ms | 0 | 0 |
| Tiempo total de ticks | 61,2 s | 93,9 s |
| `Mundo.alcanzables` (búsqueda de alcanzabilidad) | **42,7 s (70 %)**; 961 llamadas; 44 ms de media | **66,1 s (70 %)**; 1.341 llamadas; 49 ms de media |
| …de las cuales llamadas desde `Autonomia._recurso` | **96,7 %** (658 llamadas, 62,7 ms de media, máx. 95 ms) | **95,8 %** (888 llamadas, 71,3 ms de media, máx. 105 ms) |
| `Mundo.camino` (BFS entre dos puntos) | 2,2 s (3,6 %); 909 llamadas; 2,4 ms | 2,6 s (2,7 %); 1.125 llamadas; 2,3 ms |

**Hallazgos**
1. **El cuello de botella es un solo sitio.** `Autonomia._recurso` ([autonomia.gd:262](../../Linde/cenital/scripts/autonomia.gd)) elige el árbol, roca o veta más cercano; para ello hace un flood-fill completo de `AREA_EXPEDICION` (128×112 celdas, valle más contorno) en **cada llamada**, aunque solo necesita comprobar la adyacencia de unos pocos candidatos. Lo invocan `Sociedad._obtener` (reintentos y recursión por subnecesidades) y la compra de monedas de trueque.
2. **Repartir NPC por paso no ayuda a este coste.** `max_decisiones_por_paso = 2` limita cuántos deciden por minuto de juego, pero una decisión cuesta 30–45 ms de media y hasta 190 ms, y se hace dentro de un solo tick. Los picos son de **una decisión**, no de la cantidad de NPC.
3. **`AStarGrid2D` no habría resuelto P1.** El BFS punto a punto (`camino`) es menos del 4 % del tiempo. Lo caro es el flood-fill repetido.
4. **Los picos de 4–7 s citados en ARRAIGO.md no se reproducen** en `HEAD` con estas semillas (máximo 296 ms). Coincide con la hipótesis de ese documento: venían de cambios sin confirmar de otra sesión. No lo demuestro: solo digo que hoy no aparecen.
5. **Es un peor caso para poca población y solo 4 días.** Con 12 habitantes el número de llamadas crecería; no lo medí. El tiempo es de CPU de esta máquina, no un límite garantizado.

**Qué sugiere (sin implementar)**: una búsqueda de alcanzabilidad por habitante y por «versión del mundo» (cambia solo con construcciones, retiradas o caminos nuevos), o una búsqueda con parada temprana hacia el candidato más cercano. Ganancia máxima razonable: hasta ~67 % del tiempo total de tick [I; no medida tras un cambio]. Es una optimización **interna**; no requiere código externo.

## 3. P2 — Atasco de fauna [M]

**Escenario**: semilla 123, 246 regiones con plan de fauna dentro de ±8 regiones del origen. Se llamó a la IA real (`Combate._paso_enemigo`) con pasos de 0,05 s, usando el terreno y la colisión reales (caja `tam × 0,6` con deslizamiento por ejes).
- **Persecución**: jugador a 70 % de la visión en 8 direcciones con línea de visión libre; fallo = no se acerca >1 px en 4 s o no inicia el ataque en 20 s. No se evaluó la arpía (huye).
- **Regreso**: criatura desplazada 48/96/140 px en 8 direcciones y estado `regresa`; fallo = no llega al origen en 60 s.

| Especie (conducta) | Persecución: llegan / intentos | Regreso: llegan / intentos | Regreso atascado |
|---|---|---|---|
| Espectro del bosque (hostil) | 167 / 167 | 215 / 326 | 34 % |
| Gólem de la sierra (defensivo) | **68 / 128** (47 % atascada) | 82 / 220 | **63 %** |
| Diablillo del secano (hostil) | 82 / 82 | 109 / 131 | 17 % |
| Arpía de pradera (huidiza) | — | 398 / 497 | 20 % |
| Slime de ribera (territorial) | 59 / 59 | 48 / 65 | 26 % |
| **Total** | **60 atascadas de 436 (13,8 %)** | **387 atascadas de 1.239 (31,2 %)** | |

Tiempos de los casos que sí llegan: persecución p50 2,25 s, p95 2,7 s, máx. 4,1 s; regreso p50 2,65 s, p95 7,1 s, máx. 14,5 s.

**Existencia de ruta por celdas en los casos atascados**: en 446 de 447 existía un camino de celdas (4,5 a 8,9 celdas de media) y el BFS actual de Linde lo encontró en 115–618 µs.

**Interpretación y límites**
- El criterio del plan era «descartar `AStarGrid2D` si <5 %». **Se supera con holgura**, así que el atasco geométrico es real en el modelo actual: la criatura avanza en línea recta y solo desliza por ejes, y se queda trabada ante obstáculos cóncavos.
- Un atasco en estado `regresa` es **inerte** (la rama de regreso ignora al jugador) hasta que la región se descarga y se recrea [C leyendo `_paso_enemigo`; consecuencia no observada en partida].
- **Esto no mide la frecuencia en una partida real**: los desplazamientos de partida son sintéticos y no sé con qué frecuencia las criaturas superan la correa de 144 px. Es una cota del fallo geométrico, no una tasa de juego.
- **El gólem tiene 18 px de ancho y la celda mide 16**: una ruta por una sola celda libre puede ser intransitable para él. Los 446 caminos son de cuerpo de 1 celda; para el gólem hay que inflar los obstáculos. Es una limitación de esta medición.
- **Conclusión técnica**: no hace falta una clase nueva del motor. Los recorridos son cortos (4–9 celdas) y el BFS existente basta como guía de puntos de paso, recalculado solo cuando la criatura se bloquea. `AStarGrid2D` solo aportaría si se quiere ruta ponderada o coste menor por criatura (la sección 4 de este documento no lo exige).

## 4. Economía de Veloren: qué es y qué se puede reutilizar

Leí `world/src/site/economy/{mod.rs (1.424 líneas), context.rs, map_types.rs, cache.rs}`, `world/src/civ/econ.rs`, `assets/common/economy/trading_goods.ron` y `assets/common/professions.ron` (revisión `c639f81778d0`, GPL-3.0). Contenido [C]:

### 4.1 Modelo
Cada asentamiento tiene un `Economy` agregado, sin individuos:
- `pop` (población), `stocks` por bien, `labors` (**proporción** de la población en cada oficio), `yields`, `productivity`, `values` (valor local de cada bien), `labor_values`, `neighbors` (últimos valores y existencias vistos en vecinos) y pedidos/entregas.
- **24 bienes** (Food, Flour, Meat, Wood, Stone, Tools, Armor, Potions, Coin, Ingredients, Recipe, Transportation, RoadSecurity y bienes «de territorio/terreno» por bioma).
- **Oficios en datos** (`professions.ron`): cada uno declara `orders` (insumos por trabajador) y `products`. Ej.: Cocinero `(Flour 12, Meat 4, Wood 1.5, Stone 1.0) → Food 16`; Leñador `(Territory(Forest) 0.5, Tools 0.1) → Wood 0.5`; Herrero `(Ingredients 8, Wood 2) → Armor 4`.
- **Bienes con propiedades en datos** (`trading_goods.ron`): `decay_rate` (la comida pierde 20 % por ciclo, la carne 25 %), `transport_effort` (la piedra pesa 4, la moneda 0,01), `storable`.

### 4.2 Cómo se actualiza (`Economy::tick`)
1. Demanda = Σ (insumos por trabajador × trabajadores) + necesidad de toda la población.
2. Oferta = existencias + producción (`yield × proporción × pop`).
3. `excedente = oferta + existencias − demanda`.
4. **Valor** de cada bien: `2^(1 − excedente/demanda)`, suavizado `0,8·anterior + 0,2·nuevo`. Es una escasez exponencial acotada, no un precio de mercado.
5. **Reasignación de trabajo**: la proporción de cada oficio tiende a `valor del producto × productividad`, normalizada, con suavizado 0,8. Si el pan vale mucho, más gente va a cocinar.
6. **Productividad** de un oficio = la **fracción mínima de satisfacción de sus insumos** (una receta Leontief): si falta el 50 % de harina, el cocinero produce el 50 % aunque sobre carne.
7. Producción, desgaste (`decay_rate`) y población: crece a 5 %/año solo si hay excedente de comida, con muerte de 0,5 %.
8. **Comercio entre asentamientos** (`plan_trade_for_site`): ordena los bienes faltantes por valor, mira qué vecinos tienen existencias (por la última interacción recordada), calcula el coste de transporte con la capacidad de los mercaderes (`Transportation`), y propone pedidos y pagos (con monedas o con bienes de excedente). Solo hay **un oficio mercader** que transporta.
9. **Precio** (`get_site_prices`) = media del valor de trabajo y del valor de escasez, normalizados.

### 4.3 Lo que **no** es (importante para no sobrevalorarlo)
- **Es una simulación de historia en la generación del mundo**, no un sistema vivo [C]: `sim2::simulate` → `simulate_economy` ejecuta el bucle de `HISTORY_DAYS`. Veloren la usa para sembrar inventarios de mercaderes, y lo parchea a mano («economy isn't economying sometimes»: mínimos forzados de madera, ingredientes, comida y recetas).
- **No gobierna individuos.** Los NPC de rtsim no consumen ni producen contra este `Economy`; solo reflejan sus existencias en su mochila de mercader.
- **`civ/econ.rs` está marcado `#![expect(dead_code)]`**: un modelo de compradores/vendedores con creencias de precio que **no se usa**.
- Hay inconsistencias reconocidas en los comentarios del código (`TODO: Does avg/max/sum make most sense...`, `NEG STOCK` re-planificado a mano). No es un sistema pulido.

### 4.4 Comparación con la economía de Linde [C]
| Aspecto | Linde hoy | Veloren |
|---|---|---|
| Unidad | **Individuos** con inventario, hambre, plan físico (van, entregan, con garantía) | **Agregado** por asentamiento |
| Valor de los bienes | Tabla fija `valor_items`; **solo la fibra** (moneda de trueque) varía según escasez frente a un objetivo por persona | Valor dinámico por bien (`2^(1−excedente/demanda)`) |
| Oficios | `perfiles` y `oficios` en `reglas.json` con una receta principal y herramientas; prioridad de ocupaciones | Tabla de oficios con insumos por trabajador y producto |
| Reparto de gente entre oficios | La **llegada** de cada oficio sube su probabilidad cuando falta | Reasignación continua por valor × productividad |
| Escasez de insumos | Una meta nueva (buscar, fabricar o comerciar) con causa registrada | Productividad proporcional al insumo más escaso |
| Comercio entre asentamientos | **No existe**. El mercader opera solo con `acordar()` entre habitantes del valle | Planificación de pedidos con vecinos, transporte y pagos |
| Pérdida de bienes | Sin deterioro («inventarios sin deterioro de alimentos») | `decay_rate` por bien |
| Población | Llegada por presión (sustento × seguridad), techo técnico 12 | Natalidad solo con excedente de comida |
| Seguridad física/autoridad | Servidor autoritativo, garantías, entrega por proximidad, persistencia por guardado | No aplica (generación) |

### 4.5 Qué conviene reutilizar (y qué no)
Todo es **concepto o fórmula** reimplementable en GDScript. Veloren es GPL-3.0 y Rust; para uso privado no hay problema legal en reescribir las ideas, pero **copiar código obliga a la misma licencia si se distribuye**. Las fórmulas simples no se copian: se reescriben.

| Pieza | Valor para Linde | Calificación |
|---|---|---|
| **Tabla de oficios en datos** (`insumos por trabajador → producto`) | Linde tiene oficios definidos con un `receta` y listas de herramientas; una tabla homogénea permitiría derivar demanda, escasez y qué oficio falta sin código especial por oficio | **ADAPTAR** |
| **Productividad Leontief** (mínimo de satisfacción de insumos) | Mejora los **puestos regionales resumidos** (hoy producción fija cada 60 min con tope de 60 de madera/piedra) con una regla que reacciona a la falta de insumos | **ADAPTAR** (solo para población resumida) |
| **Valor por escasez** `2^(1−excedente/demanda)` suavizado | Generaliza lo que Linde ya hace con la fibra, a todos los bienes; da señales para trueque y para decidir qué producir. Riesgo: cambia el trueque actual (balance) | **ADAPTAR**, requiere autorización por tocar balance |
| **Reasignación de trabajo por valor × productividad** | Hoy las llegadas por oficio ya reaccionan a la falta; esto añadiría cambio de oficio de residentes. Riesgo de oscilaciones en población pequeña (2–12) | **ADAPTAR condicionado**; prototipo en papel antes |
| **`decay_rate` y `transport_effort` por bien** | Datos simples que añaden presión de logística y evitan acumulación infinita | **ADAPTAR** (también afecta balance) |
| **Planificación de comercio entre vecinos** (`plan_trade_for_site`) | Es la única pieza que cubre un pendiente declarado (comercio entre pueblos). Depende de que existan **varios asentamientos con economía** y de un oficio transportista | **ADAPTAR en el futuro**; hoy no hay dónde aplicarla (los puestos son resumidos y máximo 3) |
| El `Economy` entero como motor de vida | Es agregado, de generación, con parches manuales | **DESCARTAR** como núcleo; contradice el principio de entregas físicas y autoridad de Linde |
| `civ/econ.rs` (creencias de precio) | Código muerto en Veloren | **DESCARTAR** |

### 4.6 Riesgos
- **Dos economías**: usar el modelo agregado solo para población regional y la actual para el valle exige una regla de **traspaso** en ambas direcciones (lo que el plan posponía como Simulated/Loaded). No debe iniciarse antes de aprobar ese contrato.
- **Balance**: introducir valores dinámicos o deterioro cambia el trueque y las reservas; la restricción vigente es no tocar balance sin autorización.
- **Persistencia y red**: valores y flujos dinámicos añaden estado a `mundo_vivo` (ya reenviado completo, TD-007/TD-008); medir los bytes antes (hay línea base en `medir_i1a.gd`).
- **Determinismo y huella**: fórmulas con flotantes y suavizado deben ir versionadas (la huella `huella.gd` no cubre fórmulas en código).

## 5. Distinción pedida: qué implementa Linde, qué parcialmente y qué falta

Criterio: una implementación propia **no cuenta como resuelta** si hay una medición, un límite declarado o un pendiente que la contradice.

### 5.1 Implementado (con evidencia, y límites)
| Sistema | Qué lo respalda | Límite que sigue vigente |
|---|---|---|
| Terreno determinista por regiones con diferencias persistentes | `prueba_terreno` 49, huella de terreno, red con 2 clientes | ESTADO anota 4 fallos de caché en una corrida del 25/10; sin Internet real |
| Servidor autoritativo y réplica | `prueba_red`, protocolo 7 | Solo localhost; sin cifrado ni relay |
| Gramática de artesanía + operadores + saberes por actor | `prueba_operadores` 95, `prueba_saberes` 87 | 804 de 1.692 variantes `art2:` dominadas |
| Trueque con garantías, confianza, grupos, memoria | `prueba_sociedad` 48 | Valores fijos; sin comercio entre asentamientos |
| Aviso visible previo al ataque, fases de jefe | `prueba_fauna` 31, `prueba` 327 | Números sin balance |
| Alcance de estaciones por celdas | `estacion_junto`, `ALCANCE_ESTACION=2` | Sin comprobación de línea de visión en `estacion_cerca` [C]; no probado con cliente de red real |

### 5.2 Parcial (hay implementación, pero un problema medido o declarado impide darla por resuelta)
| Sistema | Qué falta, con evidencia |
|---|---|
| **Planificación de habitantes** | Reparte NPC por paso, pero **una decisión cuesta 30–190 ms** por un flood-fill repetido (P1). Con 12 habitantes no se midió |
| **Navegación de criaturas** | **31 % de regresos y 14 % de persecuciones atascados** en el escenario sintético (P2); sin ruta alrededor de obstáculos |
| **Economía y comercio** | Valores fijos salvo la fibra; sin deterioro de bienes; sin comercio entre asentamientos; mercader solo vía `acordar()` |
| **Población fuera del valle** | Puestos resumidos (máx. 3, 2 residentes) con producción fija; sin rutinas ni necesidades completas; no hay traspaso resumido↔completo |
| **Casas y crecimiento autónomo** | Las casas no se completan de forma consistente en 4–5 días simulados (ESTADO §3) |
| **Percepción de criaturas** | Distancia + línea de visión muestreada cada 4 px; sin luz, ruido ni olfato; sin señales de peligro a distancia (solo nombres al acercarse) |
| **Experiencia inicial** | Ayuda (H), barra inferior, pista contextual `_pista()`; **sin playtest del arranque**, sin pistas derivadas del estado ni persistidas por jugador |
| **Caminos** | Se forman por uso (20 pisadas) y hay red ortogonal provisional; sin ríos/puentes/rutas comerciales |
| **Progresión (interfaz de operadores)** | E6 pendiente; el balance de dominancia sin decidir |
| **Interacción en red** | Estaciones/cultivos/casas sin probar con clientes reales; mando y táctil sin probar |

### 5.3 No existe y podría mejorar sustancialmente el mundo vivo
Ordenado por apoyo en evidencia (no es un compromiso de implementar):
1. **Comercio entre asentamientos con transportistas** (Veloren `plan_trade_for_site` como referencia de concepto). Hoy el mundo exterior es una suma de puestos aislados.
2. **Contrato de traspaso resumido↔completo** para residentes regionales (pospuesto por ti).
3. **Reasignación de oficios según escasez** de residentes ya establecidos.
4. **Deterioro y logística de bienes** (decay, esfuerzo de transporte) para dar vida a la distribución.
5. **Percepción sensorial** (ruido y luz, de CDDA como idea) y **señales de peligro** más allá del aviso previo.
6. **Guía por estado** (pistas por logros, con enfriamiento y persistencia por jugador; patrón de Veloren `tutorial.rs`). Sin playtest todavía no se sabe si es necesario.
7. **Fauna lejana y ecología** (depredación, manadas, ciclos), hoy declarada ausente.
8. **Ríos, puentes y rutas trazadas con coste** (el A* de civ de Veloren como referencia).

## 6. Re-evaluación de las propuestas de la investigación correcta

Se actualizan los veredictos del plan anterior, ahora con el texto correcto. «Ahorro» es mi estimación [I].

| Propuesta (investigación correcta) | Veredicto | Motivo |
|---|---|---|
| 3.2 Overmap/Reality Bubble (CDDA) | **CONSERVAR** | Linde ya tiene regiones de 16, caché de 25 y diferencias persistentes; no hay un problema que justifique capas de 180×180 |
| 3.2 Tabla de biomas Whittaker (Veloren) | **ADAPTAR (pospuesto)** | Veloren usa umbrales en `get_biome`, no una tabla; el cambio es un `terreno_v3` ya pospuesto |
| 3.2 Niebla/velo de Wesnoth | **DESCARTAR por ahora** | Linde no tiene niebla de exploración ni la ha pedido; los archivos citados no existen |
| 3.3 RTSim + GOAP | **ADAPTAR conceptos; DESCARTAR GOAP** | Linde ya planifica metas con alternativas (`_obtener`); GOAP exige reemplazar o duplicar el planificador y el repositorio no recibe cambios desde 2024. El aporte real es la economía (sección 4) y la dualidad resumido/cargado (pospuesta) |
| 3.3 `mg_villages` | **DESCARTAR** | Sin licencia declarada, abandonado, Lua/vóxeles; Linde ya planifica solares y casas (`habitat.gd`) |
| 3.4 Tutorial declarativo (Unciv/Veloren) | **ADAPTAR** | Las ideas (logros, enfriamiento, pistas por evento, persistencia) son útiles; implementación propia sobre `_pista()` y el diario |
| 3.5 LimboAI + datos de Flare | **DESCARTAR LimboAI; datos de Flare solo como referencia** | Linde resuelve el comportamiento con ~60 líneas y datos propios; añadir dependencia nativa no reduce código. Los datos de Flare serían CC BY-SA y su balance es de otro juego. El telegrafiado ya existe |
| 3.5 Percepción sensorial (CDDA) | **ADAPTAR (futuro)** | Útil como idea, no hay urgencia medida |
| 3.6 ExpressoBits / GLoot | **DESCARTAR** | Linde ya tiene inventario atómico, fabricación autoritativa con costes atómicos y estaciones; su gramática de equipo no cabe en un inventario de prototipos genérico. Se suma una dependencia nativa (ExpressoBits) |
| 3.6 Cualidades de herramienta (CDDA `requirements.cpp`) | **ADAPTAR (concepto)** | Podría reemplazar la lista de herramientas por cualidades, pero es cambio de reglas (autorización) |
| 3.7 Interactor2D + capas de física + LoS en servidor | **DESCARTAR la física; ADAPTAR la idea de validar alcance** | Linde no usa física; sí podría añadir una comprobación de línea de visión por celdas en `estacion_cerca` si el playtest lo pide |
| 3.7 Flags semánticos de mobiliario (CDDA) | **ADAPTAR (concepto)** | `catalogos.gd` ya declara `est` y tipos; una tabla de banderas homogeneizaría E, pista y validación |

## 7. Recomendación

1. **Primer cambio justificado por medición**: sustituir el flood-fill repetido de `_recurso` (P1). Es interno, acotado y mejorable de forma verificable con las mismas semillas.
2. **Segundo**: guiar a las criaturas con el BFS existente cuando se bloquean (P2), manejando el ancho del gólem.
3. **Economía de Veloren**: no adoptar el motor; reservar tres ideas (tabla de oficios, productividad Leontief para puestos, valor por escasez) para cuando se decida el contrato de población regional y el balance.
4. **No avanzar** con LimboAI, GOAP, ExpressoBits, GLoot ni capas de física; la investigación correcta tampoco aporta datos que los justifiquen.
5. **Playtest del arranque** antes de cualquier tutorial.

## 8. Decisiones que requieren tu autorización
| ID | Decisión |
|---|---|
| E1 | ¿Autorizas corregir la búsqueda de alcanzabilidad de `_recurso` (cambio interno, sin tocar balance ni reglas) y repetir P1 como prueba de aceptación? |
| E2 | ¿Autorizas corregir el atasco de la fauna con el BFS existente, sin cambiar estadísticas, y repetir P2? |
| E3 | ¿Autorizas diseñar (solo en papel) una economía de puestos regionales con tabla de oficios y productividad por insumos, para decidir después si se implementa? |
| E4 | ¿Autorizas valores dinámicos y deterioro de bienes? Cambian el balance del trueque |
| E5 | ¿Consideras anulado el plan anterior en lo relativo a la «investigación», y que se archive o corrija su sección 0? |

## 9. Límites y reproducibilidad
- Las mediciones usan una copia del árbol (no el árbol); los scripts `p1.gd`, `p2.gd` y `prof.gd` y la copia están en la carpeta temporal de la sesión y **no se guardaron en el repo**. Si quieres conservarlos como `tests/medir_*.gd`, hay que decidirlo (sería código nuevo en el repo, no producción).
- P1 se hizo con 2 a 5 habitantes y dos semillas; no hay medición con 12 habitantes ni con jugadores conectados.
- P2 usa posiciones sintéticas; no es una tasa de partida.
- No leí `world/src/land.rs`, `rtsim/src/rule/npc_ai/mod.rs` ni `rtsim/src/data/site.rs` de Veloren; no afirmo nada sobre ellos.
- No compilé ni ejecuté código externo.
