# ADR-0001: Multijugador «mundo anfitrión» con servidor autoritativo

## Status

Proposed

> Solo el usuario (o `technical-director` con confirmación explícita del usuario) puede pasarlo a `Accepted`.

## Date

2026-10-23 (decisión de producto del usuario; redacción técnica del mismo día)

## Last Verified

2026-10-23 contra `docs/engine-reference/godot/` (VERSION.md, networking.md, breaking-changes.md) y contra el prototipo `prototypes/red-minima/` (Godot 4.7.1, localhost, procesos separados; resultados en `resultados.txt`). Lo verificado y lo que sigue sin verificar: ver «Verification Required» y el apartado 8.

## Decision Makers

- Usuario (decisión de producto: servidor «mundo anfitrión», 10–15 jugadores, A04 decidida).
- Redacción técnica: agente de documentación. Pendiente de revisión por `technical-director` / `network-programmer`.

## Summary

Linde pasa de un jugador a 10–15 jugadores simultáneos sin convertirse en MMO. Se decide un servidor autoritativo («mundo anfitrión», estilo Minecraft) que reutiliza la lógica actual (`Juego`, `Mundo`, `Combate`, `Habitantes`), separa el estado por jugador del compartido y hace avanzar el mundo solo mientras el servidor está encendido.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (instalado 4.7.1) |
| **Domain** | Networking |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH (4.7 es posterior al conocimiento del modelo; VERSION.md) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/networking.md`, `breaking-changes.md` (sección 4.6 → 4.7), `design/game-brief.md`, `Linde/cenital/docs/DECISIONES.md` |
| **Post-Cutoff APIs Used** | Ninguna distinta de la API de red de alto nivel. `ENetMultiplayerPeer`, `SceneMultiplayer` y `@rpc` se verificaron en localhost con el prototipo (verificado 2026-10-23 en localhost, Godot 4.7.1); en lo probado no cambian respecto a 4.3. |
| **Verification Required** | Sin verificar (apartado 8): red real entre máquinas distintas, NAT, UPnP (`add_port_mapping`), relay, cifrado y `auth_callback`, WebSocket y WebRTC (solo por API), carga de 15 clientes con trabajo de juego real, servidor sin ventana con la partida real. |

> Si el proyecto cambia de versión de motor, este ADR se revalida (riesgo HIGH).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | Ninguno. |
| **Enables** | Futuro ADR de formato de guardado v2 (varios personajes, estado compartido separado); futuro ADR de protocolo de red (mensajes, tasa de envío, serialización, versionado del protocolo). |
| **Blocks** | Epic `production/epics/multijugador/` (no puede empezar hasta que este ADR sea `Accepted`). |
| **Ordering Note** | La Fase 1 (estado por jugador) es un refactor local sin red y puede validarse antes de aceptar el resto, pero ningún story debe referenciar este ADR mientras sea `Proposed`. |

## Context

### Problem Statement

El plan (Build order, paso 7 de `design/game-brief.md`) incluye multijugador «mundo anfitrión» para 10–15 jugadores. Hay que decidir ahora la arquitectura de red porque condiciona el estado del juego, el guardado y la lógica, y el refactor de estado es barato hoy y caro después.

### Current State

- `Juego` es la «autoridad única del estado» (`juego.gd`): un solo diccionario `d` serializable con la semilla, el personaje (`pj`), inventario, equipo, XP, misiones, recompensas, cofres, `mundo`, `jefes`, `npcs`, `pendientes` y el reloj `min`. La interfaz solo pide acciones y muestra resultados.
- `Mundo`, `Combate` y `Habitantes` son lógica separada del dibujo (`escena.gd`, `hud.gd`, `arte.gd`).
- `Guardado` escribe un único archivo versionado con checksum, `.tmp` → validar → `.bak`.
- Hoy todo asume un único jugador (`d.pj`, `d.inv`, `Juego.pies`). Los enemigos no persisten posición; se reconstruyen al cargar.
- 130 pruebas lógicas + 12 de UI (DECISIONES.md): una base que conviene conservar.

### Constraints

- Equipo pequeño; el arte y la jugabilidad aún no se han jugado a mano (paso 1 del Build order pendiente).
- Los jugadores son amigos; el anfitrión suele ser un PC doméstico sin infraestructura.
- Decisión de producto fijada: NO MMO masivo, NO servidor 24/7 con economía de servidor, NO cuentas de seguridad de producción (brief, Out of scope A03).
- Se conserva P06: el mundo no avanza con el servidor apagado.
- Godot 4.7.1, GDScript. Pruebas lógicas ya corren en modo sin ventana (`--headless`).

### Requirements

- 10–15 jugadores simultáneos en un mismo mundo de 64×48 celdas (mapa de autor actual).
- Un jugador abre el mundo desde el menú, o se lanza un servidor sin ventana.
- Los amigos se conectan; el mundo se guarda en el anfitrión.
- Las acciones de juego (recolectar, fabricar, construir, combatir, misiones) las valida el servidor.
- Guardado con varios personajes que no corrompa el mundo.

## Decision

### 1. Modelo: servidor autoritativo único

Un proceso servidor ejecuta la lógica de juego actual (`Juego` y módulos asociados) y es la única fuente de verdad. Los clientes envían **intenciones** (mover, golpear, interactuar, construir en celda X, fabricar receta Y, intercambiar) y reciben el estado resultante y eventos. El servidor puede ser:

- **Anfitrión con ventana**: el mismo ejecutable que juega, que además acepta conexiones (menú «Abrir mundo»). Si el anfitrión cierra el juego, el mundo se guarda y se apaga.
- **Servidor sin ventana**: el mismo proyecto lanzado en modo headless con argumentos (`--servidor`, `--guardado=ruta`, puerto), sin escena de dibujo.

Un solo código para ambos: el servidor nunca dibuja; el cliente nunca decide.

### 2. Estado por jugador frente a estado compartido

Se mantiene el reparto actual del diccionario `d`, dividido en dos (nombres de campos tomados de `Juego.nueva`):

| Estado | Ámbito | Notas |
|---|---|---|
| Nombre, aspecto (`look`), origen | POR JUGADOR | |
| Posición, dirección (`pies`, `mira`), `hp` | POR JUGADOR | Posición también la usa el servidor para validar alcance. |
| Cama (`cama`) y punto de inicio (`inicio`) | POR JUGADOR | Derrota devuelve a «tu» cama. |
| Inventario (`inv`), equipo (`equipo`) | POR JUGADOR | Operaciones atómicas de `Inventario` se conservan. |
| XP, habilidades aprendidas, puntos | POR JUGADOR | Efectos derivados de lo aprendido (ya es así). |
| Misiones personales (`misiones`) y `recompensas` ya cobradas | POR JUGADOR | Una recompensa única se entiende por jugador. Decisión de diseño propuesta, sujeta a confirmar (ver Riesgos). |
| `pendientes` (recompensas que no cupieron) | POR JUGADOR | |
| Apodo de relación con habitantes (parte de `npcs` que sea afinidad) | POR JUGADOR | Pendiente de decidir qué parte de `npcs` es personal. |
| Semilla, mapa (`mundo`: objetos, construcciones, colisión) | COMPARTIDO | Una construcción cambia colisión y rutas para todos. |
| Reloj del mundo (`min`) | COMPARTIDO | Ver apartado 5. |
| Cofres (`cofres`), tesoros, objetos rotos y su reaparición | COMPARTIDO | |
| Jefes (`jefes`), enemigos activos y su estado de combate | COMPARTIDO | Jefe de capítulo no reaparece; jefe de mundo a las 72 h de juego. |
| Habitantes (`Habitantes`, rutinas) | COMPARTIDO | Un solo Maren para todos; su diálogo puede depender del jugador que habla. |
| Misiones «de mundo» (hechos que cambian el valle) | COMPARTIDO | Pendiente de clasificar cuáles lo son al diseñar la Fase 1. |

La Fase 1 formaliza esto en código: `Juego` pasa a tener `jugadores: Dictionary` (id de jugador → estado personal) y un estado compartido, sin red todavía.

### 3. Identidad del jugador y seguridad

- La identidad es **nombre + clave** (token aleatorio generado en el primer ingreso y guardado en el cliente). El servidor guarda solo el hash de la clave junto al personaje. Reentrar con el mismo nombre exige la clave; si no coincide, se rechaza.
- Opcional: contraseña de mundo que fija el anfitrión para entrar.
- **Alcance de seguridad (explícito):** protege contra que un amigo se haga pasar por otro por descuido o broma. NO es seguridad de producción: no hay cuentas, recuperación de clave, cifrado garantizado ni protección contra un atacante decidido. Si la clave se pierde, el anfitrión puede reasignar el personaje a mano. Si se necesita cifrado de transporte: sigue sin verificar (el prototipo no lo probó; ver apartado 8).

### 4. Personajes desconectados

Al desconectarse, el personaje se **retira del mundo** (no queda su cuerpo como obstáculo ni como objetivo) y se guarda su estado en la posición/cama segura más cercana (la última posición válida si no hay riesgo; si el servidor lo juzga inseguro, su cama). Al reconectar reaparece allí. No se simulan sus necesidades mientras está fuera. Un cierre brusco se trata igual que una desconexión: el último estado guardado manda (autoguardado ya existente cada 30 s).

### 5. Reloj y reaparición de jefes: tiempo del mundo

El reloj es el de juego del mundo (`min`; hoy 1 s real = 1 min de juego), un único reloj compartido que avanza **solo mientras el servidor está encendido** (P06). No depende de cuántos jugadores haya conectados ni del reloj real. Los temporizadores (reaparición del jefe de mundo a 72 h de juego, reaparición de objetos) cuentan en tiempo de juego del mundo. Con el servidor apagado no pasa nada; al encenderlo el mundo continúa donde quedó. «Dormir» deja de saltar el reloj para todos: queda como recolocación personal o requiere acuerdo de jugadores (decisión de diseño aparte, ver Riesgos).

### 6. Permisos de construcción y propiedad

- Cada pieza construida guarda su propietario (id de jugador). Solo el propietario retira su pieza (extiende la regla actual «solo piezas propias»).
- El anfitrión (administrador) puede retirar cualquier pieza.
- Cofres: tienen propietario y, por defecto, solo este los abre; el propietario puede marcarlos como compartidos. El tesoro de mundo y los cofres de mundo son comunes.
- Las reglas actuales de construcción (huella 1×1, no sobre objetos/actores, no cerrar lugares esenciales ni encerrar al jugador) las valida el servidor.
- Zonas protegidas alrededor de lugares esenciales (aldea, camas de habitantes): propuesta, a detallar en la Fase 5.

### 7. Botín y comercio simples

- Botín: el servidor lo decide con el generador determinista actual (flujo por semilla, objeto y hora); se entrega al jugador que causó el hallazgo/golpe final. Si no cabe, queda en `pendientes` (nunca se pierde ni se duplica; regla actual). El botín de jefes se otorga a cada participante que lo haya combatido (criterio exacto a fijar en Fase 5).
- Comercio: **intercambio directo entre dos jugadores**, con confirmación de ambos y ejecución atómica en el servidor (todo o nada, usando las operaciones atómicas de `Inventario`). Sin tienda de jugadores, sin subastas, sin precios ni moneda de servidor (A03 sigue fuera de alcance).

### 8. Conectividad

El anfitrión doméstico es el caso difícil. Estrategia por orden de simplicidad:

1. **LAN / IP directa + puerto abierto**: el anfitrión abre un puerto en su router a mano.
2. **VPN de terceros** (tipo red privada virtual entre amigos): sin cambios en el juego; el anfitrión comparte su IP de VPN.
3. **UPnP automático**: abrir el puerto desde el juego. Godot incluye una clase de UPnP. En el prototipo (2026-10-23) `UPNP.discover` encontró un dispositivo pero ningún gateway IGD válido, y no se ejecutó `add_port_mapping` porque modifica el router: sigue sin verificar en routers reales. Hay routers que no lo permiten; no funciona con CGNAT.
4. **Relay/retransmisión** para casos sin puerto abierto: no se decide ahora. Godot 4.7.1 no trae API de relay ni de NAT traversal (verificado en `ClassDB`). Si se hace, será un servicio externo mínimo; sigue sin verificar. Fuera de las Fases 1–3.

Estado de cada punto tras el prototipo `prototypes/red-minima/` (2026-10-23, localhost):

- Transporte: verificado 2026-10-23 en localhost. `ENetMultiplayerPeer` crea servidor y clientes; 3 clientes conectan en ~20 ms y 15 clientes a la vez (`max_clients=15`) en ~1 s desde el lanzamiento. Sin verificar entre máquinas distintas.
- Número máximo y rendimiento: verificado 2026-10-23 en localhost con 15 clientes a 20 Hz. Con el throttle por defecto de ENet se perdió 2,3–3,1 % de instantáneas; con `throttle_configure(5000, 2, 0)` en cada peer del servidor, 0 %. El cliente 16 no entra y no recibe rechazo explícito: el intento expira (~6 s). Sin verificar: carga con trabajo de juego real (los 15 procesos compartían CPU y el servidor no hacía lógica de juego).
- RPC: verificado 2026-10-23 en localhost. Modos `any_peer`/`authority` funcionan; intenciones inválidas (salto de 25 celdas, tipo incorrecto) se rechazan; una instantánea falsa enviada por un cliente es descartada por el motor.
- Desconexión: verificado 2026-10-23 en localhost. Desconexión limpia detectada en ~5 ms por el servidor. Caída abrupta detectada en ~4 s con timeout de ENet ajustado a 1000–3000 ms (por defecto, 5–30 s).
- UPnP, relay y NAT traversal: ver puntos 3 y 4. Sin verificar.
- Cifrado de transporte y autenticación personalizada (`SceneMultiplayer.auth_callback`): sigue sin verificar; el prototipo no los probó.
- Servidor sin ventana: parcial. El prototipo corrió como servidor headless (`--headless -s`) sin escena de dibujo, pero no cargó la partida del juego. Sigue sin verificar con el juego.
- Si se usarán `MultiplayerSpawner`/`MultiplayerSynchronizer` o un protocolo propio de mensajes (esta ADR no lo decide; lo decide el futuro ADR de protocolo).

### 9. Guardado con varios personajes

- El guardado sigue siendo del anfitrión, en el formato versionado con checksum y rotación `.tmp`→`.bak` ya existente.
- El **formato v2** (ADR futuro) separa: bloque de mundo compartido + bloque por jugador (clave = nombre/id, hash de clave, estado personal). Migración v1→v2: el `pj` actual pasa a ser el primer jugador.
- Guardar el mundo es atómico: no se escribe un archivo a medias aunque haya jugadores activos. Un fallo al guardar un personaje no debe invalidar el resto: el checksum se verifica por bloque. (Detalle al diseñar v2.)
- Un jugador cuyo personaje no existe en el guardado crea uno nuevo (creador actual) y es añadido.

### 10. Anti-trampas por autoridad del servidor

- El cliente nunca envía estado, solo intenciones. El servidor recalcula posición (velocidad máxima, colisiones), alcance, cooldowns, costes de inventario y daño.
- Toda operación sobre inventario usa las transacciones atómicas existentes y se ejecuta en el servidor.
- Límites por mensaje y por segundo para evitar saturación (valores a fijar en el prototipo).
- Fuera de alcance: anti-cheat contra manipulación de memoria o lectura de información oculta; con amigos, el objetivo es que nadie rompa el mundo por accidente o por broma, no una seguridad adversarial.

### 11. Modo sin ventana

El mismo proyecto Godot arrancará sin ventana mediante argumentos (por ejemplo `--servidor`, `--guardado=`, `--puerto=`; los argumentos tras `--` ya se usan hoy). El servidor carga el guardado, escucha, hace tick de `Juego` y guarda periódicamente y al apagarse. Nombres de argumentos y detalles son propuesta. Si el export tiene una característica específica de servidor dedicado en 4.7.1: sigue sin verificar (el prototipo corrió headless con `-s`, sin exportar). No se afirma aquí ninguna API de exportación.

### Diagrama

```text
 Cliente A ─┐                 ┌─ Juego (estado compartido + jugadores)
 Cliente B ─┼─ intenciones ─▶ │  Mundo · Combate · Habitantes · Inventario
 ...       ─┤  ◀─ estado ──── │  Guardado (v2: mundo + N personajes)
 Cliente N ─┘   (≤15)         └─ Servidor: anfitrión con ventana o sin ventana
```

### Implementation Guidelines

- Debe: mantener `Juego`/`Mundo`/`Combate`/`Habitantes` sin dependencia de nodos de dibujo; todo el cambio de estado pasa por métodos del servidor que devuelven resultado.
- Debe: tipar toda variable en GDScript y que las acciones por jugador reciban el id de jugador como primer argumento.
- Debe: conservar las 130 + 12 pruebas existentes verdes al terminar la Fase 1.
- Nunca: confiar en un valor enviado por un cliente (posición, daño, cantidades, recetas).
- Nunca: simular tiempo del mundo con el servidor apagado.
- Nunca: acoplar la lógica de juego a un tipo de transporte (ENet u otro); la red es una capa que entrega intenciones y recibe estado.

## Alternatives Considered

### Alternativa 1: P2P con lockstep (todos simulan lo mismo)
- **Descripción**: cada cliente ejecuta la simulación y solo se intercambian entradas por turno.
- **Pros**: sin servidor central ni coste del anfitrión; mucha menos carga de ancho de banda.
- **Contras**: exige simulación **totalmente determinista** entre máquinas (la lógica actual usa flotantes, `RandomNumberGenerator` y orden de recorrido que no se ha auditado para eso); con 10–15 pares el mundo avanza al ritmo del más lento; entrar a mitad de partida y desconexiones son complejas; trampas triviales; el guardado es difícil de reconciliar.
- **Esfuerzo estimado**: mayor que el elegido (auditoría de determinismo y reconciliación).
- **Motivo de rechazo**: el coste de garantizar determinismo y la fragilidad con 10–15 jugadores y entrada/salida libres superan la ventaja.

### Alternativa 2: Servidor MMO persistente
- **Descripción**: servidor siempre encendido con cuentas, economía y mundo que avanza 24/7.
- **Pros**: mundo vivo siempre; descubrimiento por desconocidos.
- **Contras**: contradice la decisión de producto y P06; requiere infraestructura, operación continua, cuentas seguras, economía de servidor (A03) y moderación.
- **Esfuerzo estimado**: varias veces mayor.
- **Motivo de rechazo**: fuera de alcance explícito del usuario y del brief.

### Alternativa 3: Pantalla compartida / local
- **Descripción**: varios jugadores en el mismo ordenador y pantalla.
- **Pros**: sin red, sin conectividad ni seguridad; esfuerzo mínimo.
- **Contras**: no cubre 10–15 amigos remotos ni la experiencia «mundo de amigos»; cámara compartida limita la exploración libre.
- **Esfuerzo estimado**: menor.
- **Motivo de rechazo**: no cumple el requisito de 10–15 jugadores conectados.

### Alternativa elegida: servidor autoritativo «mundo anfitrión»
- **Pros**: reutiliza la lógica separada del dibujo; una sola fuente de verdad simplifica guardado, anti-trampas y reconexión; el modo sin ventana es el mismo código; encaja con P06.
- **Contras**: el anfitrión debe estar encendido y tener conexión; la conectividad doméstica es incómoda; el tick del servidor soporta toda la simulación (carga por pares por medir).
- **Esfuerzo**: medio; el refactor de estado (Fase 1) es el grueso del riesgo y se hace sin red.

## Consequences

### Positive
- Arquitectura coherente con la decisión de producto; lógica y pruebas existentes se reaprovechan.
- Guardado y trampas se resuelven en un único punto.
- La Fase 1 mejora el diseño aunque el multijugador se cancele.

### Negative
- El mundo existe solo si el anfitrión está encendido.
- Más superficie de pruebas (concurrencia, reconexión, permisos).
- Hay que decidir qué es personal y qué compartido en misiones y habitantes.

### Neutral
- «Dormir» y la resincronización de Maren (P06) cambian de significado en multijugador y requieren decisión de diseño.

## Risks

- **Riesgo HIGH de motor:** Godot 4.7 es posterior al conocimiento del modelo. Mitigación: la API de red de alto nivel está verificada en localhost con `prototypes/red-minima/` (2026-10-23); lo no probado (apartado 8) sigue marcado como sin verificar.
- **Determinismo y tiempo:** la lógica asume un solo tick local. Mitigación: Fase 1 sin red, con pruebas.
- **Conectividad doméstica** (NAT, puertos): puede frustrar a los amigos. Sin API de relay ni NAT integrada; UPnP sin gateway IGD válido en la prueba. Mitigación: VPN como vía documentada; UPnP/relay solo tras verificar entre máquinas reales.
- **Seguridad limitada:** clave tipo «entre amigos». Mitigación: alcance declarado; sin datos personales ni pagos.
- **Diseño de misiones y recompensas únicas:** por jugador o compartidas cambia el balance. Mitigación: decisión explícita antes de Fase 1.
- **Rendimiento con 15 jugadores:** medido solo en localhost, sin trabajo de juego real; con el throttle por defecto de ENet se perdió 2,3–3,1 % de instantáneas, y el cliente 16 no recibe rechazo explícito. Mitigación: `throttle_configure(5000, 2, 0)` en cada peer del servidor y pruebas de carga con bots y lógica real (ver Validation Criteria).
- **Corrupción del guardado multi-personaje:** Mitigación: formato v2 con checksum por bloque y `.bak`.

## GDD Requirements Addressed

No hay GDDs en este nivel de proyecto. Esta ADR responde a `design/game-brief.md`:

| Documento | Requisito | Cómo lo aborda este ADR |
|---|---|---|
| `design/game-brief.md` — Build order, paso 7 | Multijugador «mundo anfitrión» para 10–15 jugadores: estado por jugador separado del compartido, servidor autoritativo, guardado con varios personajes, conectividad y modo sin ventana | Apartados 1–11 y plan de fases |
| `design/game-brief.md` — Out of scope | Sin servidor MMO masivo, cuentas de producción ni economía de servidor (A03) | Alternativa 2 rechazada; identidad limitada; comercio solo por intercambio directo |
| `design/game-brief.md` / P06 | Avance del mundo con la aplicación cerrada: no | El reloj avanza solo con el servidor encendido |

No se han creado TR-IDs; los asignará `/architecture-review` cuando existan GDDs.

## Performance Implications
- **CPU**: el servidor simula a todos los jugadores, enemigos y habitantes; carga por medir en Fase 2.
- **Memory**: estado personal × N jugadores; despreciable frente al mapa.
- **Load Time**: sin cambio relevante.
- **Network**: por medir; se recomienda tasa de envío limitada y mensajes pequeños de intención. Ancho de banda del anfitrión doméstico es el límite práctico.

## Migration Plan

Plan de fases:

1. **Estado por jugador**: separar en `Juego` el estado personal del compartido (sin red); `d.pj`/`inv`/etc. pasan a un diccionario por jugador. Pruebas existentes verdes. Mantener un jugador.
2. **Red con 2 jugadores**: servidor autoritativo mínimo; intenciones de movimiento, golpear e interactuar; movimiento e intenciones inválidas verificados en localhost con `prototypes/red-minima/`; golpear e interactuar sin probar.
3. **Guardado multi-personaje**: formato v2 con migración desde v1, identidad nombre + clave, reconexión.
4. **Conectividad y modo sin ventana**: IP directa, VPN documentada; UPnP/relay solo si se verifica; servidor sin ventana con argumentos.
5. **Permisos y botín**: propiedad de construcciones y cofres, intercambio directo, botín por participante.

Cada fase termina con captura/prueba retenida como exige `.claude/docs/coding-standards.md`.

**Rollback plan**: la Fase 1 es retrocompatible con un jugador; si el multijugador se cancela, se queda como mejora de estructura. Las Fases 2–5 viven detrás de un modo «servidor» y no tocan el modo solitario.

## Validation Criteria
- Fase 1: 130 + 12 pruebas siguen en verde; un jugador se comporta igual que hoy.
- Fase 2: dos clientes ven el mismo mundo y una acción inválida (p. ej. romper fuera de alcance) la rechaza el servidor.
- Fase 3: guardar y cargar con varios personajes sin pérdida; reconexión devuelve el mismo personaje.
- Fase 4: 10–15 conexiones simultáneas en prueba con bots sin degradar el tick (umbral a fijar); servidor sin ventana arranca y guarda. Referencia del prototipo (localhost, 15 clientes, 20 Hz): 0 % de pérdida con `throttle_configure(5000, 2, 0)` en cada peer del servidor, frente a 2,3–3,1 % con el throttle por defecto. Recomendado: ajustar el timeout de ENet a 1000–3000 ms en el servidor (caída detectada en ~4 s, frente a 5–30 s por defecto). El 16.º cliente no recibe rechazo explícito: la UI debe mostrar error por timeout. Prueba adicional: conexión entre dos máquinas reales en redes distintas (puerto directo, UPnP o VPN).
- Fase 5: un jugador no retira piezas ajenas; un intercambio es atómico.

## Related
- `design/game-brief.md` (Build order, paso 7; Out of scope)
- `Linde/cenital/docs/DECISIONES.md` (P06; reparto del estado en `Juego`)
- `Linde/documentos/LINDE_Punto_de_Inicio/06_FUENTES_Y_SUPUESTOS.md` (P06, A04)
- `docs/engine-reference/godot/modules/networking.md`
- Futuros: ADR de formato de guardado v2; ADR de protocolo de red
- Prototipo en curso: `prototypes/red-minima/`
