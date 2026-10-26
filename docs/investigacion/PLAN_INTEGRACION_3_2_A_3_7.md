# Plan de integración de la investigación externa 3.2 a 3.7

> **Fecha**: 2026-10-25 · **Naturaleza**: análisis; no se modificó código de producción, balance ni reglas, y no se instaló nada. · **Estado de Linde usado**: [ESTADO.md](../../production/epics/mundo-vivo/ESTADO.md) (consolidado 25/10), contratos en `Linde/cenital/docs/`, código leído en `Linde/cenital/scripts/`.
>
> **Etiquetas**: **[C]** comprobado hoy en código o fuente externa · **[I]** inferencia · **[NV]** no verificado.

> **⚠ Parcialmente reemplazado (2026-10-25)**: este plan se hizo sobre un texto que **no era la investigación correcta**. Las secciones 0 y 1 (y los veredictos que dependen de ese texto) quedan sustituidas por [RESULTADOS_P1_P2_Y_ECONOMIA_VELOREN.md](RESULTADOS_P1_P2_Y_ECONOMIA_VELOREN.md), que verifica la investigación correcta, incluye P1/P2 y la economía de Veloren. Lo demás (estado de Linde, ausencia de física de Godot, licencias de Luanti) sigue vigente.

## 0. Hallazgo previo: qué es realmente la «investigación adjunta» (texto equivocado; ver aviso)

El texto recibido (`copy-publicacion.txt`) **no es una investigación verificable**. [C] No contiene un solo commit, licencia, ruta de archivo ni versión de los repositorios que menciona (Luanti, Cataclysm-DDA, Veloren, Godot). Sus «patrones» son fragmentos genéricos escritos para la ocasión, no código tomado de esos proyectos. Además contradice el código real de Linde:

| Afirmación del texto | Realidad en el repo [C] |
|---|---|
| `GeneradorRegionValle` con `FastNoiseLite` propone biomas por elevación/humedad | Ya existe `terreno_v1.gd`/`terreno_v2.gd`, con altitud, humedad y temperatura, regiones de 16, huella congelada y caché. Derivan de una demo MIT verificada (`terceros/infinite-generation-demo/ORIGEN.md`). |
| `DecisionNPC.elegir_accion` (argmax de 3 valores) | Linde ya tiene necesidades, metas con alternativas, memoria, confianza, grupos y trueque (`autonomia.gd`, `sociedad.gd`, `arraigo.gd`). La clase propuesta no existe y sería un retroceso. |
| «Time-slicing de 4 NPC por frame» | Ya existe: `max_decisiones_por_paso = 2` y `intervalo_accion_min = 5` en `datos/autonomia/reglas.json`; `Autonomia.paso()` lo aplica. |
| `HUDNotificaciones.mostrar_aviso`, `body.tiene_saber(...)` | No existen. La consulta real es `Desarrollo.sabe(actor, clave)`; los avisos pasan por `Juego.aviso_todos` y la pista contextual de `escena._pista()`. |
| Clave `art2:forma:material:tecnica:calidad` | Obsoleta: la vigente es `art2:forma:material:tecnica:calidad:refuerzo:grosor` (E2/E3, `artesania.gd`). |
| `NavigationAgent2D` para enemigos | Linde no tiene `NavigationRegion2D` ni mallas; el mundo es una cuadrícula dinámica (construcciones, regiones descargables). Ver 3.5. |
| `PhysicsRayQueryParameters2D`, máscara 4 «interactuables» | Linde no usa ningún cuerpo físico (ni `CharacterBody2D`, `Area2D`, `RayCast`, `PhysicsServer2D`): mundo por celdas, alcance en celdas. Ver 3.7. |
| «Persistir deltas en `region_x_y.json`» | Linde guarda un solo JSON versionado con `rotos`, `golpes`, `constr`, `caminos`, `techos` por coordenadas globales. Un archivo por región sería un retroceso. |
| Pruebas con gdUnit4 | No se usa; las suites son scripts propios (`tests/ejecutar_suites.sh`). |

Consecuencia: esta evaluación **no puede limitarse a confirmar o refutar el texto**. Cada área se evalúa contra Linde y contra fuentes externas que sí verifiqué por mi cuenta (tabla 2). El resumen honesto: **el texto aporta ideas ya presentes en Linde y casi ningún código reutilizable**.

## 1. Matriz comparativa de los seis sistemas

| Área | Qué tiene Linde hoy [C] | Qué ofrece lo externo | Veredicto | Archivos afectados si se actúa |
|---|---|---|---|---|
| **3.2 Mundo y exploración** | Valle de autor 64×48 + exterior por regiones (v1 congelada, v2 con estaño), caché de 25 regiones, diferencias persistentes, límite ±65.536, caminos ortogonales provisionales, huella de terreno, protocolo de red 5 | Texto: el mismo patrón ya adaptado. Luanti: tabla de biomas por `heat_point`/`humidity_point` (referencia) | **CONSERVAR** (+ referencia opcional ADAPTAR para un futuro `terreno_v3`) | Ninguno ahora. Futuro: nuevo `terreno_v3.gd`, `mundo.gd` (selector de versión), `huella.gd` |
| **3.3 NPC y asentamientos** | Necesidades→meta→alternativas, trueque con garantías, confianza, grupos, arraigo/llegada/marcha, oficios, casas por plano, puestos regionales resumidos; planificación repartida por minuto | CDDA: árbol de comportamiento `npc_needs` y caché de metas de necesidad. Veloren: NPC `Simulated`/`Loaded`, sentimientos por objetivo | **CONSERVAR** el núcleo; **ADAPTAR** (solo concepto) la dualidad simulado/cargado para la población regional | Futuro: `asentamientos.gd`, `sociedad.gd`, `mundo_vivo.gd` |
| **3.4 Experiencia inicial** | Valle con Maren y Ordal, ayuda (H), barra inferior, `_pista()` contextual, paneles con acciones; sin tutorial; autonomía como modo principal (sin campaña) | Texto: zonas que avisan si falta un saber. Sin evidencia externa verificada | **ADAPTAR** (código propio sobre `_pista()`; nada de afuera) | `escena.gd` (`_pista`), `desarrollo.gd` (consulta `sabe`), datos nuevos de pistas |
| **3.5 Criaturas y jefes** | Estados idle/persigue/aviso/recupera/huye/regresa, aviso visible antes del impacto, jefes con fases, 5 especies por bioma, techo de 24, correa de 144 px, botín y reaparición persistentes. Movimiento directo; límite declarado: se atasca con obstáculos | `NavigationAgent2D` (inadecuado). `AStarGrid2D` (existe en 4.7.1). Beehave / LimboAI (árboles de comportamiento) | **CONSERVAR** la IA; **ADAPTAR** `AStarGrid2D` solo para el atasco (si se mide); **DESCARTAR** Beehave/LimboAI y `NavigationAgent2D` | Futuro: `combate.gd` (`_mover`, regreso/persecución), `mundo.gd` |
| **3.6 Progresión** | Gramática forma/material/técnica/calidad (`art1:`), operadores `art2:` (refuerzo/grosor), saberes por actor, práctica con rangos, recetas aprendidas, enseñanza, huella de reglas, dorados | CDDA: proficiencias, autoaprendizaje, requisitos. Ya estudiado en `PRECEDENTES.md` (CC BY-SA 3.0, C++ acoplado) | **CONSERVAR** (Linde ya lo supera y adoptó el concepto) | Ninguno |
| **3.7 Interacción física** | Todo por celdas: `ALCANCE_ESTACION = 2` (Chebyshev), `ALCANCE_NPC = 32 px`, `estacion_junto`, `_pista()`, mouse en paneles. Sin física de Godot | Texto: raycast a la capa de interactuables | **DESCARTAR** (no encaja con una arquitectura sin cuerpos físicos) | Ninguno |

## 2. Componentes externos realmente verificados

Consulta del 25/10/2026 por la API pública de GitHub y descarga de archivos a una carpeta de trabajo fuera del repo. «Verificado» = leí el archivo o consulté el metadato citado. **No compilé ni ejecuté nada externo.**

| Proyecto | Revisión | Licencia [C] | Qué comprobé | Qué **no** comprobé |
|---|---|---|---|---|
| [Luanti](https://github.com/luanti-org/luanti) | `71e24fcbf47b…` | `LICENSE.txt`: texturas y sonidos CC BY-SA 3.0; el repositorio no declara un SPDX único (la API devolvió `NOASSERTION`). El código C++ está bajo LGPL 2.1+ según su README [NV: no abrí el texto] | `doc/lua_api.md` define `heat_point`/`humidity_point` para biomas; existen `src/mapgen/mapgen_v7.cpp` (20 KB), `mg_biome.cpp`, `cavegen.cpp`, `mg_decoration.cpp` | El algoritmo interno de selección de bioma; ríos; cualquier portabilidad |
| [Cataclysm-DDA](https://github.com/CleverRaven/Cataclysm-DDA) | `eb86dffd20…` | CC BY-SA 3.0 (`LICENSE.txt`) | `src/npcmove.cpp` (325 KB) contiene `npc::address_needs`, `npc::method_of_attack`, el nodo de árbol `npc_needs` y un caché de metas de necesidad (`npc_need_goal_cache`, `best_need_view`); `src/faction_camp.cpp` (272 KB), `faction.cpp`, `npc_attack.cpp` | Cómo se combinan las prioridades; dependencias del dominio de CDDA (inventario, calendario, mapa) |
| [Veloren](https://github.com/veloren/veloren) | `c639f81778d0…` | GPL-3.0 (API) | `rtsim/src/data/actor.rs`: `SimulationMode { Simulated, Loaded }`; `rtsim/src/data/sentiment.rs`: mapa objetivo→sentimiento; `rtsim/src/rule/simulate_npcs.rs`: reglas por evento `OnTick`, `OnHelped`, `OnHealthChange`; `world/src/site/economy/mod.rs` (57 KB) existe | **El contenido de la economía** (no lo leí); rendimiento; cómo se carga/descarga un NPC. Todo es Rust |
| [Beehave](https://github.com/bitbrain/beehave) | v2.9.3 (2026-08-18) | MIT | Activo (push 2026-09-20), GDScript | Compatibilidad con 4.7.1 (no ejecutado) |
| [LimboAI](https://github.com/limbonaut/limboai) | v1.8.1 (2026-08-20) | MIT | Hay binarios de editor para Godot 4.7.2 y un GDExtension para 4.6 | Compatibilidad con 4.7.1; peso de la dependencia nativa |
| Godot 4.7.1 (ejecutable local) | `herramientas/runtime/...` | MIT | `ClassDB` confirma `AStarGrid2D`, `FastNoiseLite` y `WorkerThreadPool` | Rendimiento de `AStarGrid2D` sobre mundo dinámico (es la prueba P2) |
| Infinite Generation Demo | `63f7400d…` | MIT | **Ya incorporada** (`terceros/`, `terreno_v1/v2.gd`) | — |

**Veredicto sobre las tres fuentes que cita el texto**: ninguna ofrece código en GDScript reutilizable. Luanti y CDDA son C++ con licencias de copyleft/CC BY-SA (permitido para uso privado, pero hay que portar, no copiar y pegar); Veloren es Rust GPL-3.0. En los tres casos lo reutilizable son **ideas de arquitectura**, y en dos de ellas Linde ya las tiene.

## 3. Clasificación y análisis por propuesta

### 3.2 Mundo y exploración → CONSERVAR
- **Qué tiene Linde**: lo descrito arriba; determinismo comprobado por `prueba_terreno` (49), red con dos clientes reales y carga de 25 regiones en ~28 ms (local, no garantizada).
- **Qué ofrece lo externo**: el texto describe un subconjunto de `terreno_v2.gd`. De Luanti solo hay un patrón útil: biomas definidos en **datos** por puntos de calor/humedad (más cercano gana). Hoy la lógica de bioma de Linde está en código.
- **Ganaríamos**: biomas editables sin tocar GDScript y más variedad. **Perderíamos**: compatibilidad, porque `terreno_v1.gd` está congelado por una huella (`huella.gd`) y un cambio incompatible exige `terreno_v3` conservando v1/v2; además toda partida nueva cambiaría de mapa.
- **Carencias reales de Linde** (ya declaradas en `MUNDO_POR_REGIONES.md`): caminos ortogonales provisionales, sin ríos/puentes, sin mazmorras ni lugares exteriores, carga síncrona. **La investigación no aporta código para ninguna.**
- **Servidor y persistencia**: ya resuelto (clientes reconstruyen con la misma semilla; el servidor no genera a pedido del cliente).
- **Acción**: ninguna ahora. Si se quiere variedad de biomas, diseñar `terreno_v3` con tabla de biomas en datos (autorización D2).

### 3.3 NPC y asentamientos → CONSERVAR + ADAPTAR (concepto)
- **El texto es inferior** al sistema existente (ver tabla 0). Descartado como código.
- **CDDA**: [C] separa «atender necesidades» de «método de ataque» y cachea metas por necesidad. Linde ya hace metas, alternativas y reintentos con causa registrada. No hay nada portable que no esté ya.
- **Veloren**: [C] sostiene dos modos por NPC, `Simulated` (sin entidad en el mundo) y `Loaded`. Es la idea que **sí** le falta a Linde: hoy los puestos regionales son «población resumida» (`CRECIMIENTO_Y_ASENTAMIENTOS.md`) y no hay camino definido para pasar de residente resumido a habitante con rutina completa cuando un jugador se acerca. **Adaptar el concepto**, no el código (GPL-3.0, Rust).
- **Pendiente real que la investigación no resuelve** [C]: casas autónomas sin completar en 4–5 días; pausas de planificación de hasta varios segundos (`324f339` bajó el peor tick de 4.382 a 354 ms en 4 días). El reparto por NPC ya existe; si siguen los picos, el coste está **dentro** de una decisión (búsqueda de rutas, validación de solares), no en cuántos NPC se evalúan [I]. Hay que perfilar antes de actuar (prototipo P1).
- **Qué ganaríamos con Simulated/Loaded**: pueblos exteriores con vida visible sin pagar la simulación completa. **Qué podríamos perder**: coherencia, si un residente «cargado» no continúa lo que hacía «resumido» (duplicar o perder recursos). Riesgo alto de persistencia y red.
- **Archivos si se hace**: `asentamientos.gd`, `sociedad.gd`, `mundo_vivo.gd`, `guardado.gd`, `red_servidor.gd`, `huella.gd`.
- Veloren `world/src/site/economy/mod.rs` podría servir de referencia para comercio entre pueblos (pendiente declarado), pero **no lo leí**; antes de proponerlo habría que estudiarlo.

### 3.4 Experiencia inicial → ADAPTAR (solo código propio)
- **Linde**: el valle ya enseña por ayuda H, barra inferior y `_pista()`, que devuelve «E: hablar», «E: cosechar», «E: fabricar (mesa)», etc. Las misiones de plantilla están suspendidas por la decisión de autonomía.
- **Lo externo**: el texto propone un `Area2D` que avisa si falta un saber; sin evidencia de Veloren sobre tutorial ambiental [NV]. Tampoco hay `Area2D` en Linde. La idea (pista condicionada por saber) sí cabe en `_pista()`.
- **Mejora concreta** (sin campaña): ampliar `_pista()` con pistas **derivadas del estado** y de `Desarrollo.sabe`/`puede` (p. ej. «te falta haber visto fibra para reforzar», «necesitas un horno cerca»), con regla de aparición única por jugador guardada por jugador. Se alinea con «el juego nace de decisiones, no de una campaña».
- **No hay evidencia** de que el jugador se pierda: ESTADO registra «nunca jugado a mano» y la sesión UX del 25/10 fue de pruebas del propio usuario. **Falta un playtest del arranque** antes de diseñar más (prototipo P3).
- **Servidor**: la pista es de presentación; solo necesita la réplica ya existente. Persistencia: un registro `pistas_vistas` por jugador (subesquema opcional, `guardado.gd`).
- **Conflicto**: con la suspensión del director de tarjetas; no reactivar misiones para esto.

### 3.5 Criaturas y jefes → CONSERVAR; ADAPTAR AStarGrid2D; DESCARTAR el resto
- **Linde ya tiene** los puntos pedidos: percepción (visión + línea de visión con obstáculos), aviso visible previo, recuperación, fases de jefe, conductas (hostil/defensivo/huidizo/territorial), botín único, aparición determinista por región y persistencia de heridas/bajas. Combate evaluado con geometría propia (`zona_golpe`, `_dist_segmento`), en el servidor. El texto no añade nada de esto.
- **`NavigationAgent2D`**: [C] requiere regiones de navegación horneadas. El mundo de Linde cambia por construcción y se carga/descarga por regiones de 16×16; hornear mallas en caliente en servidor es complejidad injustificada. **DESCARTAR**.
- **`AStarGrid2D`** [C: existe en 4.7.1]: encaja con una cuadrícula. El problema que resolvería es el declarado en `FAUNA_Y_PELIGROS.md` («el regreso puede atascarse ante obstáculos porque usa movimiento directo») y el de la persecución rodeando árboles. **ADAPTAR condicionalmente**: una cuadrícula local de ~15×15 celdas alrededor de la criatura, reconstruida al ser necesaria, sin mantener navegación global. Riesgos: coste por criatura (hasta 24) y por tick; mantener determinismo con los dorados. **Antes de implementar, medir cuánto se atasca realmente** (P2).
- **Beehave (MIT) / LimboAI (MIT)**: activos, pero Linde resuelve el comportamiento de enemigos con ~60 líneas de estados y datos. Un árbol de comportamiento añadiría dependencia (LimboAI, además, nativa) sin reducir código. **DESCARTAR**.
- **Pendientes que ninguna fuente resuelve**: balance de números (provisional), sin jefes exteriores, sin fauna lejana, sin escalado por distancia. Las «señales de peligro» a distancia (sonido, indicios, rastros) no existen; es diseño nuevo, no reutilización.
- **Prohibido**: tocar balance. Cualquier cambio aquí debe mantener estadísticas.

### 3.6 Progresión → CONSERVAR
- Linde está **por delante** de las fuentes: forma/material/técnica/calidad, operadores `art2:` con tope de presupuesto (1,30×) y verificación de dominancia, saberes `op:`, enseñanza entre actores, huella de reglas y dorado de 693 claves. CDDA ya se estudió (`PRECEDENTES.md`): C++ acoplado, CC BY-SA 3.0; la decisión vigente fue adoptar el concepto y escribir implementación propia.
- El fragmento del texto (`construir_clave_artesanal`) generaría claves **inválidas** para el servidor (`MAX_TEXTO`=48, formato distinto). Si se integrara por error, rompería `Artesania.leer2`.
- **Problema abierto real**: 804 de 1.692 variantes `art2:` están dominadas y E6 no puede presentarlas como mejoras (ESTADO §3b). **Ninguna fuente externa verificada lo resuelve**; es decisión de diseño del usuario (tabla 8).
- **Acción**: ninguna externa.

### 3.7 Interacción física → DESCARTAR
- [C] Cero uso de física de Godot en `scripts/`. El alcance es aritmética de celdas (`ALCANCE_ESTACION = 2`, `ALCANCE_NPC = 32.0`) y `Juego.estacion_junto`. Introducir `PhysicsServer2D` y capas obligaría a crear cuerpos para cada objeto, duplicaría la fuente de verdad y complicaría la autoridad del servidor.
- **Lo que sí hay por hacer** (declarado en ESTADO §3c, sin ayuda externa): probar E en estaciones con cliente de red real, mando/pantalla táctil y el creador con ratón. Son pruebas, no integraciones.

## 4. Mejoras concretas recomendadas para Linde

Ordenadas por valor y respaldo en evidencia. Ninguna requiere código externo.

1. **Perfilar la planificación** de habitantes (P1) para localizar el coste real de los picos antes de añadir cualquier IA nueva. Evidencia: ESTADO «Planificación».
2. **Pistas contextuales por estado y saber** en `_pista()` (3.4), con registro por jugador y sin misiones.
3. **Navegación local con `AStarGrid2D`** para fauna, solo si P2 demuestra atascos frecuentes.
4. **Modo simulado/cargado** para residentes regionales (3.3), tras definir el contrato (decisión D3).
5. **Biomas en datos** como `terreno_v3` (3.2), solo si se quiere más variedad (decisión D2).
6. **Playtest guiado del arranque** (3.4) como insumo, antes de diseñar tutorial.

**Qué no se recomienda**: adoptar cualquiera de los snippets del texto, instalar Beehave/LimboAI, usar `NavigationAgent2D`, o capas de física.

## 5. Dependencias y conflictos entre implementaciones

- **Terreno ↔ huella/persistencia**: cualquier cambio de 3.2 exige `terreno_v3`; interfiere con fauna (planes por región usan hash propio y conviven con v1/v2) y con asentamientos (usan terreno por coordenadas).
- **Simulated/Loaded ↔ autonomía ↔ red**: 3.3 toca `mundo_vivo` (que hoy se reenvía completo: TD-007/TD-008) y el límite del MTU de ENet; cambia el tamaño de la réplica. Hacer primero la medición de bytes (la línea base E1 de `medir_i1a.gd`).
- **AStarGrid2D ↔ determinismo**: la ruta de la fauna es del servidor; no entra en el estado guardado, pero sí en `prueba_fauna` (31). Mantener el comportamiento actual detrás de un respaldo.
- **Pistas ↔ saberes**: dependen de `Desarrollo.sabe/puede` y de la privacidad (`mundo_vivo` completo no debe transportar secretos, `BASES_TECNICAS.md`).
- **Todo ↔ `huella.gd`**: cubre datos JSON y claves, **no** fórmulas ni generadores en código. Cualquier cambio de reglas en código escapa a la huella; hay que subir versión a mano.
- **Trabajo en curso**: I1a/E6 (interfaz de operadores) y la deuda de balance de `art2:` comparten `escena.gd`, `hud.gd` y `desarrollo.gd` con 3.4. No solaparlos.
- **Licencias** (uso privado, sin descartar copyleft): Luanti LGPL 2.1+/CC BY-SA 3.0, CDDA CC BY-SA 3.0, Veloren GPL-3.0 → portar ideas en código propio no arrastra obligaciones; copiar código o datos sí (atribución y compartir igual). Beehave/LimboAI/Godot/la demo: MIT (conservar aviso).

## 6. Orden de integración por impacto, dificultad y riesgo

| # | Trabajo | Impacto | Dificultad | Riesgo | Depende de |
|---|---|---|---|---|---|
| 1 | P1: perfil de planificación (solo medir) | Alto | Baja | Nulo | — |
| 2 | P3: playtest del arranque (solo observar) | Alto | Baja | Nulo | — |
| 3 | Pistas contextuales por saber | Medio | Baja | Bajo | 2, y cerrar E6 |
| 4 | P2: medir atasco de fauna | Medio | Baja | Nulo | — |
| 5 | AStarGrid2D local en fauna | Medio | Media | Medio | 4 |
| 6 | Contrato Simulated/Loaded de residentes | Alto | Alta | Alto | 1, D3 |
| 7 | `terreno_v3` con biomas en datos | Medio | Alta | Alto | D2 |

## 7. Prototipos mínimos para validar

Todos en carpeta aparte o scripts de prueba (`tests/medir_*.gd`), sin tocar producción ni balance.

- **P1 — Perfil de planificación**: ejecutar la simulación de 4 días (semilla 123, 12 habitantes) midiendo microsegundos por función dentro de `Sociedad.decidir`, `Mundo.camino` y `habitat`. **Éxito**: lista ordenada del 90 % del tiempo del peor tick. Responde si el cuello es la búsqueda de rutas (donde `AStarGrid2D` podría ayudar) o la validación de solares.
- **P2 — Atasco de fauna**: escenario con una criatura que persigue/regresa rodeando 1–3 árboles; contar ticks hasta llegar. **Éxito**: porcentaje de casos atascados. Si <5 %, descartar AStarGrid2D. Si se continúa: comparar con `AStarGrid2D` de 15×15 reconstruida (tiempo y resultado).
- **P3 — Playtest del arranque**: partida nueva con el usuario (o amigos), sin ayuda, registrar en qué minuto hace cada primera acción (hablar, recoger, fabricar, construir) y dónde se detiene. **Éxito**: lista de bloqueos observados; solo entonces se diseñan pistas.
- **P4 — Simulated/Loaded en papel**: documentar el contrato (campos, transición, qué se persiste) y ejecutar un ensayo con 2 residentes regionales para comprobar que ni se duplican ni pierden recursos al guardar/cargar. **No codificar** hasta aprobar D3.

## 8. Decisiones que requieren su autorización

| ID | Decisión | Recomendación |
|---|---|---|
| D1 | ¿Descartar el texto adjunto como fuente (no integrar ninguno de sus fragmentos) y no instalar Beehave, LimboAI ni usar `NavigationAgent2D` / física? | Sí |
| D2 | ¿Autoriza diseñar `terreno_v3` (biomas en datos) que cambiaría mapas de partidas nuevas? | Postergar hasta que el exterior sea el cuello de botella |
| D3 | ¿Desea que el siguiente trabajo sea el contrato Simulated/Loaded para residentes regionales (aumenta autonomía visible, tocar red y guardado)? | Primero P1; luego decidir |
| D4 | ¿Se ejecutan los prototipos P1 y P2 (solo medición, sin cambios de producción)? | Sí |
| D5 | ¿Playtest P3 antes de cualquier tutorial? | Sí |
| D6 | Pendiente previo y no resuelto por esta investigación: política para las 804 variantes `art2:` dominadas (ocultar, etiquetar «sin efecto» o reequilibrar) | Su decisión; reequilibrar toca balance |
| D7 | ¿Autoriza estudiar a fondo `world/src/site/economy` de Veloren como referencia para comercio entre pueblos? | Opcional, solo lectura |

## 9. Límites de esta evaluación

- No ejecuté suites de Linde ni código externo. Las cifras de Linde son las registradas en ESTADO y en los contratos, con sus fechas.
- Veloren y CDDA se verificaron por estructura de archivos y símbolos concretos, no por lectura completa. Las afirmaciones sobre Luanti son mínimas porque no leí el algoritmo de biomas.
- La licencia de Luanti se anota con la precisión disponible (el repositorio mezcla licencias); confirmar antes de copiar nada.
- `AStarGrid2D` está confirmado en el ejecutable 4.7.1 por `ClassDB`, pero **no se probó su rendimiento ni su ajuste** en este mundo.
- Los archivos externos se descargaron en una carpeta temporal fuera del repo; no se conservan.
