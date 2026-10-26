# Cierre del mundo inicial y la exploración — diagnóstico

> **Fecha**: 2026-10-26 · **Alcance**: aparición del jugador → primera salida del Valle · **Base**: `HEAD 302c53d` + la optimización de `_recurso` sin confirmar · **No se modificó nada** de código, reglas, balance ni producción para este documento. Primero se revisa el diagnóstico y se toman las decisiones (sección 5).
> **Fuentes**: [LINDE_investigacion_tecnica.md](file:///Users/josephrojas/Downloads/LINDE_investigacion_tecnica.md) (investigación recibida), [ESTADO.md](../../production/epics/mundo-vivo/ESTADO.md), los contratos de `Linde/cenital/docs/` y el código de `Linde/cenital/scripts/`.
> **Etiquetas**: **[C]** comprobado en código o datos · **[M]** medido hoy · **[D]** documentado en ESTADO/contratos y no revisado · **[I]** inferencia · **[NV]** no verificado. Tipos de problema: **Dis**eño · **Imp**lementación · **Bal**ance · **UX**.

## 0. Resumen

**Veredicto**: el Valle ya es un sistema vivo real (habitantes con necesidades, trueque, construcción, crecimiento), pero **la primera experiencia no está resuelta**. Lo que falta no es motor de mundo; es la *puerta de entrada*: dónde aparece el jugador, cómo se orienta, cómo aprende y qué encuentra al salir.

Los cinco hallazgos que más pesan, todos [C] o [M]:
1. **El jugador aparece en una celda aleatoria del Valle**, no en un lugar con sentido. En 200 semillas medí la distancia a la puerta de la casa: mediana **23,8 celdas** (mín. 13, máx. 36) y la pantalla muestra unas 26×15 celdas [I]. Lo normal es que **no vea ni la casa ni a ningún habitante al empezar**. Nunca aparece cerca de la casa y el 10 % aparece a menos de 4 celdas de la salida sur.
2. **Empieza con las manos vacías y el Valle no tiene ni mesa ni horno.** No hay estación inicial (`Mundo._init` solo coloca dos camas); fabricar el primer hacha o pico no necesita estación, pero casi todo lo demás sí.
3. **No hay mapa, ni memoria de lo explorado, ni hitos.** El único apoyo es «Bioma · x, y» en la esquina. No hay nada guardado por jugador sobre lo que ha visto.
4. **Más allá del Valle no hay nada que ir a ver.** Terreno, recursos por bioma, una criatura por región y caminos que son **líneas rectas cada 96 celdas** (`x ≡ 32` o `y ≡ 23 mod 96`). Sin lugares de interés, sin destinos, sin ruinas fuera del Valle. El contrato lo declara así.
5. **El tutorial orgánico no existe**; hay ayuda (H), barra inferior y una pista de una línea (`_pista`) sin estado ni memoria.

Lo bueno: el telegrafiado de combate, la fauna determinista con persistencia, los caminos que se forman por uso, la construcción persistente, las llegadas de colonos y la red autoritativa **ya existen** y se pueden ampliar. Nada de lo que propongo exige rehacer sistemas.

## 1. Qué dice la investigación recibida y cuánto se puede usar

La investigación es **honesta y bien acotada**: separa lo verificado de la propuesta y no atribuye rutas que no comprobó. Verifiqué hoy sus afirmaciones comprobables:
- CDDA `doc/JSON/MAPGEN.md` línea 1181: `ZONE_START_POINT` coloca al jugador en el centro y «no additional checks» → **correcto**. `data/json/start_locations.json` existe con `om_terrain` y `om_terrain_match_type` → **correcto**.
- Veloren `CHANGELOG.md`: «Made players spawn in towns» y la cola de repoblación con tiempo mínimo → **correcto**.
- Luanti `mg_ore.h`: `clust_scarcity` y `nthresh` → **correcto**.
- Wesnoth `src/minimap.cpp` existe → **correcto**; la investigación no afirma más de lo que comprobó (correctamente).

Lo útil de verdad, por sistema, está en la sección 3. Resumen de reutilización:
| Fuente | Aporte aprovechable | Calificación para Linde |
|---|---|---|
| CDDA | Lista declarativa de ubicaciones de inicio con coincidencia por tipo; **validar físicamente después de elegir la zona** | **ADAPTAR (concepto y esquema de datos)**; sin copiar JSON (CC BY-SA) |
| Luanti | Campos de distribución de recursos por ruido y umbral (`nthresh`, escasez); decoración condicionada por sustrato | **ADAPTAR (concepto)** solo si se abre `terreno_v3` (pospuesto) |
| Veloren | Spawn en poblados; cola con espera mínima para repoblar | **Referencia de diseño**; Linde ya tiene llegada por presión |
| Wesnoth | Separar visible ahora / explorado / verdad | **Referencia de diseño** (la separación es la idea, no su código) |
| Unciv | Reglas «evento + precondición + efecto» como datos | **ADAPTAR (concepto)** para las pistas |

**Dos puntos donde la investigación no aplica tal cual a Linde**:
- *Ocultar verdad al cliente*: en Linde **los clientes reconstruyen el terreno con la misma semilla** (contrato de `MUNDO_POR_REGIONES.md`). La niebla no puede impedir que un cliente modificado conozca el terreno; solo sirve de presentación. Para lugares de interés generados por función determinista pasa lo mismo. Como es un juego privado entre amigos, **recomiendo aceptarlo y tratar el mapa como memoria del jugador**, no como seguridad (decisión D4).
- *Conservar la identidad del asentamiento inicial y mundo persistente nuevo por grupo*: ya es así (cada partida tiene su semilla y guardado; el Valle es de autor y siempre el mismo).

## 2. Qué existe hoy (evidencia común a los ocho sistemas)
- Valle de autor 64×48 celdas (1 casa de 8×7 con dos camas, cantera, bosque, estanque, ruinas con arena y guardián, tesoro, 12 puntos de aparición de slimes, vallas y barriles); 2 habitantes iniciales (Maren y Ordal); más llegan por presión [C].
- Camino sur (x=32) hasta la entrada, camino este-oeste (y=23) y camino hacia la arena (x=52); la entrada del Valle es el único acceso conocido al exterior [C].
- Inicio: `Mundo.punto_inicio(semilla)`; hora inicial 06:00; inventario y equipo vacíos; 40 PV [C].
- Todo jugador que se une (`Juego.unir`) usa el **mismo** `punto_inicio` [C].
- Exterior: terreno v2 por regiones (16×16), biomas (ribera=agua, sierra, bosque, secano, pradera), recursos por bioma (cobre y estaño solo fuera del Valle), una criatura por región elegible, franja de 8 celdas sin fauna alrededor del Valle, puestos regionales (máx. 3) [C][D].

## 3. Diagnóstico por sistema

### 3.1 Aparición segura y coherente del jugador
**Existe [C]**: `punto_inicio` elige, con hash de la semilla, una celda alcanzable desde la entrada, de pasto o camino, con 3×3 libre, ≥12 celdas de un punto de aparición de slimes y ≥14 de la zona del claro y del guardián.
**Medido [M]** (200 semillas, 2.832 celdas alcanzables, 139 posiciones distintas, 20 ms por llamada):
| Distancia (celdas) | mín. | p10 | mediana | p90 | máx. |
|---|---|---|---|---|---|
| a la puerta de la casa | 13,0 | 16,3 | **23,8** | 34,2 | 36,4 |
| a la cama de Maren | 15,5 | 17,9 | 25,5 | 32,0 | 34,9 |
| a la salida sur | 1,0 | 4,1 | 24,4 | 35,8 | 41,1 |
| al guardián | 14,0 | 14,9 | 18,2 | 27,1 | 56,4 |
| al slime más cercano (punto de aparición) | 12,0 | 12,4 | 17,0 | 22,0 | 27,1 |
| al estanque | 2,0 | 3,0 | 11,4 | 22,0 | 43,9 |

**Parcial**: es determinista, evita los peligros más cercanos y cumple «seguro» en sentido físico; **no es coherente**: no depende del poblado, el camino ni la casa. Los slimes que importan son sus *puntos de aparición*; no los vivos.
**Falta**:
- Criterio de *naturalidad* (cerca del centro social y de un camino, con vista a un hito).
- Registro de por qué se eligió, y fallback explícito: con cero candidatos, `cand[rng.randi() % cand.size()]` divide por cero (si construcciones del jugador cerraran todas las celdas válidas; improbable, no probado) [C lectura].
- Aparición de varios jugadores: todos en la misma celda; sin separación ni intención de «reunirse».
- Re-validación en la autoridad al unirse (la función sí usa el estado actual, pero no hay un chequeo posterior).
**Tipo**: Diseño (qué significa «coherente») + UX (primer minuto) + Implementación menor (fallback).
**Reutilizable**: de CDDA, el *patrón* «ubicación semántica → validación física → fallback registrado» y un archivo de datos de inicios. De la investigación §A, la lista de pruebas duras (suelo, espacio, distancia a amenaza, conexión a salida) casi toda ya está en `punto_inicio`; solo falta la puntuación de naturalidad.
**Decisiones**: D1 (dónde empieza el jugador), D2 (juntos o separados).
**Pruebas**: (a) 500 semillas: el punto cumple las pruebas duras y la nueva regla de cercanía a la casa/centro; (b) mundo con el Valle casi bloqueado por construcciones: usa el fallback y lo registra; (c) dos clientes unidos seguidos: posiciones distintas, ambas válidas, sin colisión; (d) mismo resultado tras guardar y reiniciar.

### 3.2 Valle inicial: NPC, viviendas, recursos, estaciones y caminos
**Existe [C]**: 2 habitantes con camas propias, rutinas y necesidades; cantera (4 % vetas, 14 % rocas), bosque (30 % árboles, 8 % arbustos), objetos sueltos; estanque de 6×7; camino en T; tesoro; llegada de nuevos colonos por presión, con casas (plano de 6×7 y obra pieza a pieza) y campos [D].
**Parcial**:
- **Estaciones**: ninguna mesa ni horno al comenzar [C]. Los habitantes «detectan estaciones ausentes y reúnen materiales para construirlas» [D]; el jugador debe construir la suya. No hay medición de cuánto tarda el Valle en tener una.
- **Viviendas**: «las casas no se completan de forma consistente en 4–5 días simulados» [D]. La primera experiencia de 60 minutos reales son ~2,5 días de juego (1 min real = 1 h de juego) y casi seguro no verá una casa nueva terminada.
- **Recursos**: el Valle cubre madera, piedra, fibra, bayas, hierro; **cobre, estaño y arcilla solo fuera** [C], lo que da el motivo para salir (bien) pero sin indicación de dónde.
- **Caminos**: los del Valle son fijos; los caminos de uso se forman a 20 pisadas [C].
**Falta**: identidad del poblado (nombre, plaza, hitos visibles); alimento/agua: el estanque no se usa para nada del juego [I: no vi mecánica de sed]; un espacio común.
**Tipo**: Diseño (qué hay al inicio) + Balance (tiempos de construcción y llegada) + Implementación (casas).
**Reutilizable**: la propuesta de «poblado en torno a un cruce entre arroyo y sendero» ya es casi el Valle (camino en T, estanque, casa); lo que falta son *datos* de hitos nombrados. Nada externo hace falta.
**Decisiones**: D5 (estación común inicial), D6 (qué cambios persistentes bastan para percibir evolución).
**Pruebas**: (a) simulación de 3 días (ya existe `simular_crecimiento.gd`): el Valle tiene mesa y horno utilizables al final del día 1 sin intervención; (b) al día 3, ≥1 casa completa en 5 semillas (hoy no se logra [D]); (c) los hitos nombrados existen y son alcanzables por BFS desde cualquier punto de inicio posible.

### 3.3 Tutorial orgánico mediante pistas y acciones
**Existe [C]**: ayuda (H) con controles reales; barra inferior; `Escena._pista()` que da una línea según lo que hay junto al jugador («E: hablar con X», «E: cosechar», «E: fabricar (mesa)»); `E` sobre un habitante explica su necesidad actual; panel «Saberes»; diario de sociedad.
**Falta**: estado de pistas por jugador; reglas basadas en el estado (por ejemplo «tienes madera y piedra: puedes fabricar un hacha sin estación»); frecuencia/enfriamiento; opción de silenciarlas; mensajes de bienvenida y de objetivo del mundo. **Nada recuerda lo que el jugador ya vio o aprendió** (el guardado no tiene campo de pistas) [C].
**Qué NO hace falta**: misiones; la autonomía es el modo principal y la campaña está suspendida.
**Tipo**: Diseño (qué enseñar y cuándo) + UX + Implementación (reglas y estado) — pequeña.
**Reutilizable**: Unciv/Veloren sólo como patrón (evento, precondición, efecto, enfriamiento, estados `shown/dismissed/completed`). Implementación nueva y pequeña sobre `_pista()` y el guardado; datos en un JSON versionado.
**Decisiones**: D7 (nivel de ayuda por defecto y si hay opción «ya conozco los sistemas»).
**Pruebas**: (a) lista de ≥12 pistas con su disparador; cada una sale una vez y no se repite tras guardar y cargar; (b) pista suprimida si el jugador ya hizo la acción; (c) nunca dos pistas a la vez; (d) en red, la pista de un cliente no se envía a otro; (e) playtest: porcentaje de jugadores que hacen la primera fabricación en <10 min sin ayuda externa.

### 3.4 Experiencia de los primeros 5, 15, 30 y 60 minutos
Esto es un análisis de lo que **el código permite**, no de una partida jugada: «nunca jugado a mano» sigue en ESTADO. Reloj: 1 min real = 1 h de juego, día = 24 min; comienza a las 06:00.
| Tramo | Lo que el código permite [C] | Lo que falta |
|---|---|---|
| **0–5 min** | Moverse, golpear arbustos (1 golpe, 2 fibra, 50 % baya), árboles (6 golpes a mano, 3 madera), rocas (10 golpes, 2 piedra). El **hacha de piedra** (2 piedra, 2 madera, 1 fibra) y el **pico** (3 piedra, 2 madera, 1 fibra) se hacen **sin estación**: unos 17 golpes para el hacha. Hablar con un habitante (no suele estar a la vista, 3.1) | Saber dónde ir; ver a alguien; una primera pista |
| **5–15 min** | Fabricar hacha y pico; mesa (5 madera, 2 piedra) y horno (8 piedra) con la mano o el pico; cofres y camas. Los habitantes comercian y construyen | Que algo «invite»: ningún hito ni objetivo emergente visible; ver cómo trabajan los habitantes |
| **15–30 min** | Vetas de hierro (con pico) y lingotes: **la receta del lingote exige la habilidad «artesano»**, que requiere nivel 3 y «recolector» nivel 2 (`HAB`), y una cantidad de XP que **no medí** [NV]. Primera salida al exterior por el sur | Información sobre qué hay fuera; riesgo/recompensa de salir; **potencial cuello de botella de nivel** |
| **30–60 min** | Cobre y estaño y arcilla solo fuera del Valle; puestos regionales (20 madera, 8 piedra, 12 fibra, 8 bayas, hacha y pico de piedra); fauna exterior con nombres al acercarse | Un destino exterior, un regreso con sentido; que el mundo reaccione (cambio visible persistente) |

**Hallazgos de experiencia**:
- El único contenido de «descubrimiento» fuera del Valle son recursos nuevos; **no hay lugares**.
- Dos grandes incógnitas para el diseño: *cuánto tarda en subir de nivel el jugador* y *cuánto tarda en aparecer algo notable en el Valle*. Ninguna está medida.
**Tipo**: UX y Balance (tiempos), no solo Implementación.
**Decisiones**: D8 (qué debe pasar antes del minuto 15 y del 60).
**Pruebas**: *guion automático de la ruta mínima* (recoger→hacha→mesa→pico→salir→volver) que registre golpes, acciones y minutos de juego; y playtest humano de 3–4 personas con registro de qué hacen en cada tramo. Criterio de aceptación: sección 6, AC-1 a AC-6.

### 3.5 Mapa, orientación y descubrimiento
**Existe [C]**: indicador «Bioma · x, y» (`hud.gd`, `hud_vivo.gd`); nombres de criaturas al acercarse; habitantes memoriza lo que «conoce» (`Autonomia.conoce`), pero **eso es para NPC**.
**Falta por completo [C]**: mapa o minimapa; memoria de celdas exploradas por jugador; marcadores; nombres de lugares; rumores; brújula/rumbo a la entrada; compartir lo descubierto en grupo. Nada de lo explorado se guarda por jugador.
**Tipo**: Diseño (qué es un mapa en Linde) + Implementación + UX.
**Reutilizable**: de Wesnoth y de la investigación §«Exploración», la separación `visible_now` / `explored` / `known_features` / `world_truth`. Implementación nueva y pequeña: máscara de bits por región en el guardado del jugador (≈32 bytes por región de 16×16), serializada junto con `pj`. El terreno lo reconstruye el cliente con la semilla, de modo que **el mapa no necesita red adicional salvo para compartir**.
**Decisiones**: D4 (personal o de grupo; rumores como áreas o texto), D9 (¿teclas de mapa?).
**Pruebas**: (a) tras recorrer N celdas, `explorado` incluye exactamente las vistas (distancia visible fija); (b) guardar/cargar conserva la máscara; (c) un cliente no recibe la máscara de otro salvo compartir; (d) tamaño del guardado tras 60 min de recorrido; (e) rendimiento del dibujo del mapa.

### 3.6 Generación de regiones y lugares de interés
**Existe [C]**: generación por coordenadas globales, regiones de 16, caché de 25, diferencias persistentes, versionado v1/v2 con huella, biomas por umbrales de tres ruidos, recursos por bioma con probabilidades escritas en el código, caminos en rejilla recta cada 96 celdas.
**Parcial**: biomas con transición suave en el borde del Valle; carga síncrona; límite ±65.536.
**Falta por completo**: lugares de interés (no hay ruinas, cuevas, campamentos ni mazmorras en el exterior; el contrato lo dice); destinos conectados por caminos con sentido; ríos, puentes, pasos; variaciones de entorno más allá de recursos; hitos visibles a distancia.
**Tipo**: Diseño + Implementación (capa nueva).
**Reutilizable**: *el mismo patrón que ya usa la fauna* (`Fauna.plan_region`: una función pura por región con un hash propio, que **no toca** `terreno_v1/v2`), aplicado a lugares de interés. De la investigación §C: restricciones por bioma/pendiente/distancia, accesibilidad por camino, reserva de huella; de CDDA, las plantillas de edificios/lugares como datos. **No requiere `terreno_v3`** ni cambiar la huella: los POI son una capa aparte, determinista, con estado en deltas (saqueado, explorado).
**Decisiones**: D10 (¿los POI principales existen siempre?), D11 (qué tipos de lugar caben en el primer corte).
**Pruebas**: (a) determinismo: mismo POI con cualquier orden de carga; (b) accesibilidad: BFS desde el camino hasta la entrada del POI en 100 semillas; (c) separación mínima y sin solapar el Valle ni los puestos; (d) diferencia persistente (cofre vaciado) tras guardar y cargar; (e) 1 POI alcanzable a ≤ N celdas de la salida sur en el 100 % de las semillas (N a decidir).

### 3.7 Peligros iniciales y distribución de fauna
**Existe [C][D]**: 5 especies por bioma con conducta (hostil, defensiva, huidiza, territorial), telegrafiado, correa de 144 px, botín y reaparición, techo de 24 activos, franja sin fauna de 8 celdas alrededor del Valle y distancia mínima de 96 px al jugador al aparecer; 12 slimes y 2 jefes en el Valle.
**Medido (sesión anterior, P2)**: en un escenario sintético, el 31 % de los regresos y el 14 % de las persecuciones quedan atascados (63 % y 47 % en el gólem). Es un problema de **implementación** que afecta la legibilidad del peligro.
**Parcial**:
- *Densidad*: 246 de 289 regiones (85 %) tienen una criatura [M, P2]: casi uniforme, sin zonas de calma ni de peligro.
- *Señales*: solo el nombre al acercarse y el aviso del ataque; sin rastros ni indicios de amenaza a distancia.
- *Balance*: «provisional, nunca jugado».
**Falta**: perfiles de hábitat y actividad (hora/estación), zonas de calma alrededor de caminos y del poblado, amenazas ancladas a un lugar con aviso previo, rumores.
**Tipo**: Diseño (qué peligro y a qué distancia) + Balance + Implementación (atascos).
**Reutilizable**: nada externo directo; la sección «Amenazas y oportunidades» de la investigación es un modelo de diseño, no un algoritmo. Se amplía `Fauna.plan_region` con una tabla por bioma y una zona de calma alrededor de los caminos.
**Decisiones**: D12 (nivel de amenaza aceptable en los primeros 60 min y cuánto aviso).
**Pruebas**: (a) en la ruta sur hasta el primer POI, ninguna criatura hostil a menos de R celdas del camino (R a decidir) en 100 semillas; (b) cada criatura hostil es visible/anunciada ≥ T segundos antes de poder dañar; (c) `prueba_fauna` (31) sigue pasando; (d) tasa de atasco < 5 % con el escenario P2; (e) playtest: muertes en los primeros 60 min.

### 3.8 Desarrollo persistente del territorio
**Existe [C][D]**: construcciones, cofres con candado, caminos por uso, techos, campos de cultivo, casas planificadas con solares reservados, puestos regionales con 2 residentes y producción resumida; llegadas por presión; todo persistente y replicado; cargar no duplica producción.
**Parcial**: casas autónomas sin completar; planificación lenta (mejorada con la optimización de hoy: −50 % a −62 % del coste de tick); puestos como población resumida sin rutinas; exterior sin ciudades que se fundan solas; equilibrio de comida y ladrillos.
**Falta**: abandono y ruina gradual; reocupación; ríos/puentes; comercio entre pueblos (ver `RESULTADOS_P1_P2_Y_ECONOMIA_VELOREN.md`); percepción visible de la evolución en los primeros 60 min.
**Tipo**: Balance + Diseño + Implementación.
**Reutilizable**: la propuesta de la investigación (vector compacto por asentamiento, eventos con idempotencia, ruina gradual) coincide con lo que Linde ya hace en `Asentamientos` y `Sociedad`; no hay nada que reconstruir.
**Decisiones**: D6 (qué evolución basta), D13 (política si el Valle se destruye o abandona).
**Pruebas**: (a) la simulación de 5 días completa ≥1 casa en las semillas 123 y 456 (hoy no [D]); (b) cargar un guardado no cambia el estado (ya se verifica); (c) abandono: si no hay actividad durante N días, el solar pasa a «ruina» y se conserva su historia.

## 4. Matriz síntesis

| Sistema | Existe | Parcial | Falta | Tipo dominante |
|---|---|---|---|---|
| Aparición del jugador | Punto seguro y determinista | Evita peligros pero no es coherente | Naturalidad, fallback registrado, varios jugadores | Dis/UX |
| Valle | Casa, cantera, bosque, 2 habitantes, caminos, llegadas | Casas, estaciones, alimentos | Identidad, estación común, hitos | Dis/Bal |
| Tutorial | H, barra, `_pista` | — | Pistas con estado, reglas, silencio | UX/Imp |
| Primeros 60 min | Ruta de fabricación sin estación | — | Ritmo medido, objetivo emergente, destino | UX/Bal |
| Mapa/orientación | Bioma y coordenadas | — | Mapa, exploración, hitos, rumbo | UX/Imp |
| Regiones/POI | Terreno, recursos, caminos | Caminos rectos | Lugares de interés, destinos | Dis/Imp |
| Peligros/fauna | 5 especies, telegrafiado | Densidad uniforme; atascos | Zonas de calma, señales, hábitat | Dis/Bal/Imp |
| Territorio | Construir, crecer, persistir | Casas, puestos resumidos | Abandono, comercio, evolución visible | Bal/Imp |

## 5. Decisiones que necesito de ti

| ID | Decisión | Mi recomendación |
|---|---|---|
| D1 | ¿Dónde aparece el jugador? Opciones: (a) plaza/casa del poblado, (b) camino sur a la vista de la casa, (c) como hoy (aleatorio) | (a) o (b); dentro de un radio fijo de la casa o del cruce y con vista a algún habitante |
| D2 | Varios jugadores: ¿misma zona, o dispersos con señal de reencuentro? | Misma zona con dispersión pequeña; reencuentro ya garantizado al estar juntos |
| D3 | ¿El Valle inicial es único y canónico o hay variantes por semilla? | Único (ya lo es); variar solo el exterior |
| D4 | Mapa: ¿personal, de grupo o ambos? ¿Se acepta que el terreno sea reconstruible por el cliente y el mapa solo una ayuda? | Personal por defecto, compartible por grupo; sí aceptar |
| D5 | ¿Hay mesa/horno comunes en el Valle desde el inicio o el jugador debe construir? | Una mesa común (fabricar enseña por contexto); horno a construir |
| D6 | ¿Qué cambios persistentes bastan para «ver evolución» en 60 min? | Un camino formado, una construcción de habitante, un cultivo cosechado, una llegada |
| D7 | Ayuda: ¿pistas activadas por defecto, con opción «ya conozco los sistemas»? | Sí, con ese interruptor |
| D8 | ¿Qué debe ocurrir antes del minuto 15 y del 60? | Min 15: primera herramienta + primera conversación. Min 60: haber visitado un lugar exterior y vuelto |
| D9 | ¿Tecla de mapa? ¿Minimapa permanente? | Tecla M, sin minimapa fijo |
| D10 | ¿Los lugares de interés principales existen en toda semilla? | Sí, uno garantizado cerca; el resto, ponderado |
| D11 | ¿Qué tipos de lugar en el primer corte? | Tres: ruina con cofre, campamento abandonado con recurso raro, cueva (solo entrada) |
| D12 | Amenaza aceptable en los primeros 60 min y tiempo de aviso | Ninguna criatura que mate a 40 PV en un solo golpe en el primer destino; aviso ≥ 3 s |
| D13 | Si el Valle se destruye o abandona: ¿cuál es el punto de entrada? | El poblado más cercano viable o campamento; nunca un punto arbitrario |
| D14 | ¿Autorizas tocar valores de balance (XP, costes) tras medir? | Solo con tabla de resultados antes/después |

## 6. Lista priorizada de trabajos y criterios de aceptación

Prioridad por *valor para la primera experiencia* y *dependencia*; esfuerzo y riesgo son estimaciones [I]. Ninguno reconstruye un sistema existente.

### P0 — Medir y entender (sin cambiar el juego)
| # | Trabajo | Criterio de aceptación verificable |
|---|---|---|
| T0.1 | **Guion automático del recorrido mínimo** (recoger→hacha→mesa→pico→salir→volver) y registro de golpes, acciones y minutos de juego | AC-0: el guion termina en 5 semillas y reporta tiempos por hito; se guarda como prueba de ritmo |
| T0.2 | **Playtest guiado del arranque** (3–4 personas, sin ayuda) con ficha de observación por tramo (5/15/30/60) | Lista de bloqueos con frecuencia; porcentaje que fabrica su primera herramienta antes del min 10 |
| T0.3 | Medir **tiempo y XP** hasta «artesano» (nivel 3) y hasta una mesa/horno propios | Tabla de minutos reales por hito en el guion |

### P1 — Puerta de entrada (alto valor, bajo riesgo)
| # | Trabajo | Criterios de aceptación |
|---|---|---|
| T1.1 | **Aparición con sentido** (D1/D2): ampliar `punto_inicio` con puntuación de naturalidad, registro del motivo y fallback explícito; evitar división por cero | AC-1: en 500 semillas el inicio cumple las pruebas duras actuales, está a ≤ X celdas de la casa/cruce y a la vista de ≥1 habitante o hito; sin candidatos usa el fallback y lo registra; dos jugadores seguidos no coinciden en celda |
| T1.2 | **Pistas por estado** (D7): reglas en JSON, estado por jugador en el guardado, enfriamiento, interruptor | AC-2: ≥12 pistas; cada una sale una vez; no reaparece tras guardar/cargar; ninguna con la acción ya hecha; nunca dos a la vez; `prueba_ui` y guardado sin regresión |
| T1.3 | **Mapa y memoria de exploración** (D4/D9): máscara por región por jugador, tecla M, rótulos de hitos del Valle | AC-3: tras recorrer una ruta, el mapa muestra exactamente lo visto; persiste; una réplica no recibe el mapa ajeno; tamaño de guardado tras 60 min dentro del presupuesto fijado |
| T1.4 | **Hitos nombrados del Valle** (D5): datos de nombres/posiciones y estación común si se decide | AC-4: cada hito existe, es alcanzable y aparece en el mapa; estación inicial operativa en la simulación de 1 día |

### P2 — Un motivo para salir
| # | Trabajo | Criterios de aceptación |
|---|---|---|
| T2.1 | **Capa de lugares de interés** por región (D10/D11), aparte de `terreno_v1/v2`, con restricciones y estado por deltas | AC-5: determinista con cualquier orden de carga; accesible por BFS desde el camino en 100 semillas; 1 POI garantizado a ≤ N celdas de la salida; estado persistente y réplica coherente; `prueba_terreno` (49) sigue pasando |
| T2.2 | **Peligro legible** (D12): zona de calma alrededor de los caminos, tabla de hábitat por bioma, rastros/avisos | AC-6: en el camino al primer POI no hay criatura hostil a < R celdas en 100 semillas; todo peligro está anunciado ≥ T s antes; `prueba_fauna` (31) sigue pasando |
| T2.3 | **Arreglar el atasco de criaturas** (P2): guiar con el BFS existente cuando se bloquean, manejando el ancho del gólem | AC-7: tasa de atasco < 5 % con el escenario P2 (hoy 31 % regreso, 14 % persecución); sin cambiar estadísticas |

### P3 — Vida visible
| # | Trabajo | Criterios de aceptación |
|---|---|---|
| T3.1 | **Casas autónomas completas** (pendiente declarado) | AC-8: ≥1 casa completa a los 3 días simulados en las semillas 123 y 456, sin entregar materiales |
| T3.2 | **Evolución visible en 60 min** (D6) | AC-9: en el guion de T0.1 aparecen ≥3 de los 4 cambios elegidos |
| T3.3 | Abandono y reocupación gradual (D13) | AC-10: un solar inactivo pasa a ruina tras N días; la historia se conserva; un nuevo ocupante lo reutiliza |

### P4 — Posterior
Rumores como conocimiento (D4), `terreno_v3` con biomas en datos, comercio entre pueblos (ver el documento de economía), percepción sensorial.

**Criterio global de «primera experiencia jugable completa»**: AC-0 a AC-8 cumplidos, el playtest T0.2 repetido sin bloqueos graves y las suites de regresión sin fallos nuevos.

## 7. Orden y dependencias
T0.1–T0.3 primero (no cambian el juego) → T1.1 (depende de D1/D2) → T1.2 y T1.4 (independientes) → T1.3 → T2.1 → T2.2 y T2.3 → T3.x. T1.2 y T1.3 comparten el guardado del jugador: hacerlos con un único cambio de esquema aditivo y opcional (sin subir `Guardado.FORMATO` si basta una clave nueva).

## 8. Límites
- Diagnóstico por lectura de código y 200 semillas de `punto_inicio`; **no hay una partida jugada** que lo respalde.
- Las pruebas propuestas son verificables, pero ninguna se ejecutó salvo la del punto de inicio.
- No medí XP ni tiempo hasta «artesano» ni la proporción de objetos que el jugador necesita.
- Los valores X, N, R, T de los criterios son parámetros a fijar tras tus decisiones.
