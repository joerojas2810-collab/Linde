# Propuesta — Linde: un juego con principio y final

**Fecha:** 27/10/2026 · **Rama:** `arena/359338c9-linde` · **Estado:** propuesta. Este documento es el único cambio de esta entrega; no se ha modificado código todavía.

---

## 0. La apuesta, en una frase

Conservar **todo el motor jugable que ya existe** (motor de dibujo, input, HUD, inventario, fabricación, construcción, combate, misiones, guardado y 628 sprites) y **retirar del arranque los cinco sistemas experimentales** que no sirven, sustituyéndolos por **una campaña escrita de ~40 minutos, de un jugador, con un final explícito y pantalla de créditos**.

No es un arreglo de esos sistemas. Es cambiar el juego que los rodea: de simulación sin meta a aventura finita.

---

## 1. Diagnóstico: por qué hoy no es jugable

Leí `Linde/cenital/` completo: **15.261 líneas de GDScript** en 56 scripts, **11.106 líneas de tests** en 112 suites, **628 PNG + 3 tipografías + shader** (~24 MB de arte), **una sola escena** (`main.tscn` → `escena.gd`, que lo dibuja todo por código).

| Síntoma | Dónde está | Consecuencia |
|---|---|---|
| No hay principio | `juego.gd:62` `MODO_JUEGO = MODO_POBLADO`; `nueva()` instala un poblado, calcula aparición por radio/semilla y activa `autonomia` | Apareces en un pueblo cuyo estado depende de una simulación que ya estaba corriendo. No hay "primera escena". |
| No hay objetivo siguiente | `juego.gd:334-385` `tick()` ejecuta cada frame `autonomia.paso()`, `habitantes.paso()`, `sociedad`, `mundo_vivo`, `fauna`, `exploracion`, `pistas` | Cinco simulaciones compiten por definir qué pasa; nada le dice al jugador qué hacer ahora. |
| No hay final | `catalogos.gd:147` `MISIONES` tiene 3 misiones de capítulo + 2 sueltas; `juego.gd:1036` el "final" es una línea de diálogo: *"Gracias por todo. Quizá haya más que descubrir en el bosque."* | No existe estado de victoria, ni pantalla final, ni créditos, ni cierre de partida. |
| Fricción de entrada | `escena.gd:133` `requiere_acceso = ...`: el arranque normal exige **cuenta y contraseña antes del menú**; luego creador de PJ, luego menú | Para jugar en local hay que crear una cuenta. Es el primer `no es jugable`. |
| Sobrecarga de interfaz | `escena.gd:218-255` ~15 teclas; `_armar()` (551-849) abre ~20 paneles (`desarrollo`, `planos`, `saberes`, `laminados`, `practica`, `sociedad`, `ficha`, `pistas`…) | El jugador necesita un manual para empezar. El propio `ESTADO.md` admite "sin playtest humano prolongado". |
| Mundo sin bordes narrativos | `mundo.gd` valle de autor 64×48 + `terreno_v1/v2`, `lugares`, `exploracion`: exterior infinito por regiones de 16×16 | No hay un "lugar al que ir": hay terreno indefinido. |
| Enemigos sin encuentro | `combate.gd` + `fauna.gd` (territorios, hábitats, avisos, heridas, bajas) | Los bichos existen para la ecología, no para un combate diseñado. |

Los cinco sistemas que señalas coinciden exactamente con los cinco bloques de código más grandes y más acoplados: **IA de NPC** (`sociedad.gd` 1.592 LOC, `autonomia.gd`, `arraigo`, `habitat`, `transitos`, `habitantes`), **economía generativa** (`desarrollo.gd` 606, `asentamientos.gd` 885, `artesania`, `edificios`, `fundacion`), **generación del mapa** (`terreno_v1/v2`, `lugares`, `exploracion`, `pistas`, parte de `mundo.gd`), **mobs** (`fauna.gd` 362 + acoplamiento en `combate.gd`) y **desarrollo/narrativa** (`mundo_vivo.gd`, `mundo_datos.gd`, Atlas JSON, GDDs). Juntos son ~**5.600 LOC** y copan el arranque, el `tick`, el guardado (formato 3) y la réplica de red.

Estoy de acuerdo con tu criterio: **no son aprovechables como mecánica de juego**. Lo aprovechable está en otra capa.

---

## 2. Inventario de código: qué se salva

### Se conserva (≈7.000 LOC de lógica + el 100 % del arte)

| Pieza | LOC | Uso en el juego nuevo |
|---|---|---|
| `escena.gd` | 1.399 | `_draw`, cámara, input, menús, diálogos, mapa, construcción. Se conserva ~65 %: se quitan los paneles de los sistemas retirados y la puerta de cuentas. |
| `juego.gd` | 1.141 | Acciones del jugador, inventario, extracción, fabricación, construcción, cofres, XP/habilidades, **motor de misiones** (`objetivo_ok`, `evaluar_misiones`, `entregar`, `hablar`), jefes, guardado. Se conserva ~75 %. |
| `mundo.gd` | 640 | Valle de autor 64×48 (`MAPA`), colisión, BFS `alcanzables/camino`, objetos rompibles, construcciones, regeneración. Se conserva ~75 %; se elimina el exterior por regiones. |
| `catalogos.gd` | 265 | Ítems, recetas, piezas, habilidades, enemigos, jefes, misiones, diálogos y **`validar()`** (validador de referencias: red de seguridad gratis). Se reescriben solo datos. |
| `equipo.gd` + `arte_equipo.gd` | 941 | Equipo por sets, paletas, stats. |
| `combate.gd` | 328 | Ataque con aviso/activo/recuperación, telegrafía de jefes, fases al 50 %/40 %, `knockback`, invulnerabilidad, botín. Se le quita `fauna` (6 puntos). |
| `guardado.gd` | 143 | Guardado versionado con checksum, `.bak` y migraciones. |
| `arte_entornos.gd`, `actores_arte.gd`, `mundo_arte.gd`, `viajero071.gd`, `anim_pj.gd`, `aspecto.gd`, `arte_vida.gd`, `imagen_util.gd` | ~1.000 | Sprites de personaje, fauna, biomas, objetos y efecto noche. |
| `hud.gd`, `hud_vivo.gd`, `ui_arte.gd`, `ui_viva.gd` | 877 | HUD, paneles, iconos, minimapa y **el rastreador de misiones** (`hud_vivo.gd:259`). |
| `inventario.gd`, `params.gd`, `presentacion_npc.gd` | 67 | Transacciones atómicas, constantes. |
| `arte/` | 628 PNG | Personaje con capas y estados, equipo, enemigos, jefes, terreno, pueblos, interfaz, tipografías. **Todo se reutiliza.** |
| `tests/prueba.gd` y suites de reglas/aspecto/protección/caminos | ~4.000 | Se conserva el subconjunto que prueba el núcleo. |

### Se retira (≈5.600 LOC de simulación + 846 de cuentas/red, decisión B)

| Sistema señalado | Archivos | Se sustituye por |
|---|---|---|
| IA de NPC | `sociedad.gd`, `autonomia.gd`, `arraigo.gd`, `habitat.gd`, `tareas.gd`, `transitos.gd`, `fundacion.gd`, `mundo_datos.gd`, `habitantes.gd` | 3 NPC con diálogo escrito por estado de campaña y rutina visual mínima, en `campana.gd` (~300 LOC) + `datos/campana/npcs.json`. |
| Economía generativa | `desarrollo.gd`, `asentamientos.gd`, `artesania.gd`, `edificios.gd`, `huella.gd` (parte), `datos/{autonomia,desarrollo,asentamientos,edificios}` | `catalogos.RECETAS` y `CONSTR`, que ya existen y son finitos. Sin precios dinámicos ni artesanos autónomos. |
| Generación del mapa | `terreno_v1.gd`, `terreno_v2.gd`, `lugares.gd`, `exploracion.gd`, `pistas.gd`, `datos/lugares`, `datos/mundo/*`, ramas de `mundo.gd` | El valle de autor fijo. Puntos de interés escritos a mano con coordenadas. |
| Mobs | `fauna.gd`, `datos/fauna`, `d.fauna` | Lista fija de encuentros en `datos/campana/encuentros.json`, usando la máquina de estados de `combate.gd`. |
| Desarrollo y narrativa | `mundo_vivo.gd`, Atlas (`datos/mundo/entities`), GDDs `mundo-vivo`, `sociedad-emergente`, `desarrollo-generativo`, `mundo-por-regiones` | `campana.gd` + `datos/campana/actos.json`: misiones, diálogos, waypoints, final. |
| Cuentas y multijugador (opcional, ver decisión B) | `scripts/cuentas/*`, `red_servidor.gd`, `red_cliente.gd`, `servidor/` | Fuera del camino por defecto. |

**Destino de los archivos:** se borran del árbol de trabajo (el historial de Git los conserva íntegros) y se deja `docs/archivo/RETIRO_SISTEMAS_2026-10-27.md` con el inventario, el motivo y el commit de referencia. No se dejan scripts muertos dentro de `res://`: Godot los importaría igual y ensuciarían el arranque y la CI.

---

## 3. El juego propuesto: **Linde — El fuego del valle**

- **Género:** RPG cenital de aventura y oficio, 1 jugador, sin conexión, sin cuenta.
- **Duración:** 35–45 minutos de principio a final, sin misiones de relleno.
- **Mundo:** el valle de autor de 64×48 celdas (el que ya existe, con casa, taller, plaza, cantera, ruinas/arena, bosque y claro). Sin exterior infinito.
- **Arranque:** pantalla de título → "Nueva partida" → creador de PJ (ya existe) → apareces en la entrada sur (32,46) con una tarjeta de introducción de 3 líneas y **un objetivo visible en pantalla desde el segundo 1**.
- **Final:** pantalla a pantalla completa con el cierre de la historia, estadísticas (tiempo, nivel, muertes, construcciones, jefes) y créditos; la partida queda marcada como `finalizada` y ofrece "Volver a jugar" / "Modo libre".
- **Fallo:** no hay *game over*. La derrota (ya implementada) te devuelve a tu cama con media vida, sin perder objetos, y suma una muerte al contador del final.

### Estructura de actos (todo con contenido que ya existe)

| Acto | Misiones (motor actual de `MISIONES`) | Lugar | Sistemas reutilizados | Min |
|---|---|---|---|---|
| **1 · El taller dormido** | Hablar con Maren → reunir 6 piedras → construir una mesa → construir un horno → fabricar lingote, espada de hierro y escudo | Casa/taller (24,16) y plaza | Extracción, recetas, habilidades, construcción, diálogo por estado | ~10 |
| **2 · La cantera** | Fabricar un pico → llegar a la cantera → abrir el cofre sellado (`tesoro_cantera`, ya sembrado con gema) → volver con la gema | Cantera (4,4)–(16,14) | Objetos rompibles, probabilidad de botín, cofres, `visita/abrir/tener` | ~9 |
| **3 · Las ruinas** | Llegar a la arena → derrotar al **Guardián de las Ruinas** (52,43), con sus 2 fases y ataques telegrafiados | Arena (46,38) | `combate.gd`, jefes, niveles, botín de equipo | ~12 |
| **4 · El claro** | Derrotar al **Gran Ciervo** (50,10) → volver con Maren → **final** | Bosque/claro (38,3) | Combate, relación con NPC, pantalla final | ~12 |

Cada acto tiene: **un objetivo activo**, una **marca en el minimapa** (reutilizando el marcador de misión de `escena.gd:1067`), un **NPC que dice exactamente qué falta** (reutilizando `hablar()` que ya auto-acepta y auto-entrega), y una **recompensa que abre el siguiente acto**. No hay misiones paralelas, ni director de tarjetas, ni economía que decidir por el jugador.

**NPC:** Maren (taller), Ordal (plaza) y Nerea (bosque), con sus sprites existentes. Sus diálogos salen de `actos.json`, con variantes por estado de misión (`oferta`, `recordar`, `gracias`, `base`). Se mueven con una rutina visual simple sobre el BFS de `mundo.gd` (para que el valle no parezca muerto) sin necesidades, hambre, confianza ni acuerdos.

**Progresión:** se rebalancean los números de `catalogos.gd` (XP, umbrales de habilidad, HP/daño de enemigos, costes de recetas) para que la ruta de los 4 actos sea completable **sin farmeo**. Un test de "camino dorado" verifica que cada objetivo es alcanzable con los recursos del acto anterior.

**Controles:** flechas/WASD, `E` interactuar/hablar, `Espacio` atacar, `C` fabricar, `B` construir, `I` inventario, `K` habilidades, `M` mapa, `Esc` pausa. Se elimina el resto de teclas de sistemas retirados; el HUD muestra una leyenda contextual de 3 teclas y el rastreador de objetivo permanente.

---

## 4. Arquitectura objetivo

```
main.tscn → escena.gd            (dibujo, input, HUD, menús, pantallas intro/final)
                 │
                 ├── juego.gd     (autoridad: movimiento, inventario, fabricación,
                 │                 construcción, misiones, combate, guardado)
                 │     ├── mundo.gd        (valle fijo, colisión, BFS)
                 │     ├── combate.gd      (máquina de estados + jefes)
                 │     ├── catalogos.gd   (datos del juego)
                 │     └── campana.gd     ← NUEVO: director de actos, waypoints, final
                 │            └── datos/campana/{actos,npcs,encuentros,creditos}.json
                 └── hud_vivo.gd (rastreador, minimapa, paneles)
```

1. **`campana.gd` (nuevo, ~300 LOC).** Una sola autoridad narrativa: estado en `d.campana = {acto, finalizado, muertes, t_inicio, estadisticas}`; expone `objetivo_actual()`, `waypoint()`, `dialogo(npc)`, `al_cumplir_mision()`, `al_derrotar_jefe()`, `finalizar()` y señales `cambio_acto` / `final`. Reutiliza el motor de misiones de `juego.gd` en vez de crear otro: las misiones siguen siendo datos en `catalogos.MISIONES` con los tipos `hablar/tener/construccion/visita/derrotar/abrir`.
2. **`juego.gd`.** Se eliminan ~40 llamadas a `autonomia`/`vivo`/`Exploracion`/`Pistas`/`Edificios`/`Fauna` (en `tick`, `stats`, `golpear_objeto`, `fabricar`, `construir`, `interactuar`, `hablar`, `nombre_habitante`, `cargar`…). Se añade `campana` y un guardia `finalizado`. Todo lo demás queda.
3. **`escena.gd`.** Fuera la puerta de cuentas (`requiere_acceso`), fuera los paneles `desarrollo/materiales/planos/saberes/laminados/practica/sociedad/ficha` y fuera el arranque de servidor. Se añaden `intro` y `final` como dos pantallas del mismo sistema de paneles. El `modo` pasa a ser `menu → creador → juego → final`.
4. **`combate.gd`.** Se quitan los 6 puntos de acoplamiento con `fauna` (`guardar`, `paso`, `recordar`, `baja`, `rutas`, límites de región). Los encuentros se leen de `encuentros.json` con posiciones fijas; se respeta el aviso/recuperación/fases existentes.
5. **`mundo.gd`.** Congelado el valle: `ANCHO/ALTO`, `MAPA`, `CASA`, `CANTERA`, `BOSQUE`, `ARENA`, `CLARO`, `_generar_objetos`, `spawns_slime`, `alcanzables/camino`, `poner/quitar`. Fuera `regiones`, `actualizar_regiones`, `bioma` exterior, `lugares`, generación v1/v2 y metadatos `generacion`.
6. **`guardado.gd`.** `FORMATO 4`; migración 3→4 que añade `d.campana` y descarta el estado de las simulaciones retiradas. Se conservan checksum, `.bak` y rechazo de formatos futuros; se relaja la validación de metadatos de generación. Las partidas viejas arrancan en el acto 1 con su inventario y nivel (o se rechazan con mensaje claro, según decidas).
7. **Datos y docs.** `datos/campana/*`, `Linde/cenital/docs/CAMPANA.md` (cómo jugar), `docs/archivo/RETIRO_SISTEMAS_2026-10-27.md`, actualización de `README.md`, índice de `DECISIONES.md` y `ESTADO.md`.

### Verificación (parte importante del plan)

Hoy en este sandbox **no se puede descargar el motor**: los assets de release de Godot están en `objects.githubusercontent.com` / `release-assets.githubusercontent.com`, fuera de la lista de hosts permitidos. Pero el repo **ya tiene CI que descarga Godot 4.7.1 con SHA fijado y ejecuta el import headless** (`.github/workflows/servidor-privado.yml`, `servidor/dedicado/prueba_fase7.py`). Uso ese mismo patrón:

- **Workflow nuevo `.github/workflows/jugable.yml`** en la rama de trabajo: descarga Godot 4.7.1 (Linux, SHA fijado), corre `--headless --editor --import --quit` (detecta errores de parseo en todos los scripts) y ejecuta las suites nuevas.
- **`tests/prueba_campana.gd`** — camino dorado *headless*: crear partida → recorrer los 4 actos por la API de `Juego` → matar a los dos jefes → entregar la última misión → comprobar `d.campana.finalizado == true`, que el final se dispara **una sola vez** y que no hay misión inalcanzable.
- **`tests/prueba_alcanzabilidad.gd`** — con el BFS y la caja de colisión reales: desde la aparición se puede llegar a todos los recursos, NPC, cofres y jefes de la campaña, y construir una mesa/horno no bloquea ningún camino.
- **`tests/prueba_guardado_campana.gd`** — guardar/cargar a mitad de cada acto conserva acto, misiones, inventario y jefes.
- Las ~83 suites que dependen de los sistemas retirados se archivan (o se borran con los scripts); las del núcleo siguen corriendo.
- **Playtest humano:** flag `--salto=<acto>` para que puedas abrir cada acto directamente y probarlo en tu máquina con el lanzador actual, sin tener que rejugar 40 minutos.

---

## 5. Plan por fases

| Fase | Entregable verificable |
|---|---|
| **0 · Arranque honesto** | Workflow `jugable.yml` funcionando sobre el código actual; se sabe con certeza qué compila y qué no. Definición de "jugable" firmada: un jugador nuevo, sin instrucciones externas, llega al final. |
| **1 · Cirugía** | Los cinco sistemas dejan de cargarse. El juego arranca **sin cuenta**, en el valle fijo, con 3 NPC y HUD reducido. `juego.gd`/`escena.gd` compilan y las suites del núcleo pasan. |
| **2 · Campaña** | `campana.gd` + `actos.json`: 4 actos, diálogos, waypoints, rastreador, pantalla de introducción y pantalla final con créditos. `prueba_campana.gd` pasa de principio a final. |
| **3 · Encuentros y curva** | Mobs fijos, los dos jefes como puertas de acto, números de `catalogos.gd` balanceados para 35–45 min. `prueba_alcanzabilidad.gd` y el camino dorado verifican que no hay farmeo ni soft-lock. |
| **4 · Pulido jugable** | Leyenda de controles, ayuda contextual, autoguardado, pausa con "Salir", flujo de muerte, guardado de campaña, cero teclas huérfanas. |
| **5 · Entrega** | `README.md` reescrito (un solo comando para jugar), `CAMPANA.md`, y —si lo apruebas— **export Web en GitHub Pages** desde la CI, para que puedas jugar en el navegador sin instalar Godot. El repo es público y Actions ya funciona. |

Orden de ataque recomendado: **0 → 1 → 2** de una sentada (es el cambio estructural), luego 3 y 4 con tus comentarios de playtest, y 5 al final. Cada fase se cierra con la CI en verde, no con "compila en mi máquina".

---

## 6. Riesgos y cómo los cubro

| Riesgo | Mitigación |
|---|---|
| Acoplamiento fuerte: `juego.gd`/`escena.gd` tienen ~40 llamadas a los sistemas retirados | Cambios en commits pequeños, con parseo headless tras cada uno; `campana.gd` ofrece una fachada con los nombres que ya usa el HUD (`estado_mision`, `objetivo_txt`, `progreso_txt`) para no reescribir paneles. |
| Perder arte al retirar biomas/fauna/poblados | El arte no se toca: los sprites de fauna, biomas y pueblos son genéricos y se siguen usando en los encuentros fijos y el valle. |
| Guardados antiguos incompatibles | Migración 3→4 explícita + mensaje claro en el menú; nunca se pisa un archivo (comportamiento actual de `guardado.gd`). |
| Narrativa floja por ser escrita a mano | Borrador en español con 3 voces diferenciadas, revisable en `actos.json` sin tocar código; los textos de prueba actuales se marcan como no canon y se sustituyen. |
| Balance sin playtest humano aquí | Camino dorado automático + métricas de la partida simulada (tiempo, golpes, recursos) + `--salto=<acto>` para tu prueba manual. |
| Contradecir decisiones anteriores (RED-*, "autonomía es el modo principal") | Se registra una decisión nueva en `DECISIONES.md` con estado *Usuario (27/10)* y se marcan las anteriores como *Reemplazada*. Requiere tu aprobación explícita (decisión B). |

---

## 7. Lo que necesito decidir

1. **Alcance:** campaña corta y cerrada de ~40 min (recomendado) o campaña de 2–3 h con más actos y secundarias.
2. **Multijugador y cuentas:** archivarlos y que Linde sea 100 % local (recomendado) o conservarlos como modo opcional escondido tras un flag.
3. **Narrativa:** reutilizar Maren, Ordal, Nerea y el valle (recomendado; cero arte nuevo) o escribir personajes e historia nuevos.
4. **Entrega:** lanzador local + build Web en GitHub Pages para jugar en el navegador (recomendado) o solo lanzador local.

Con tu OK empiezo por las fases 0–1 y te traigo un arranque que se pueda abrir y jugar, antes de escribir una sola línea de la campaña.

---

## 8. Criterio de éxito

> Una persona que nunca vio el repo ejecuta **un comando**, crea un personaje, entiende qué hacer sin leer documentación, juega 35–45 minutos, derrota al último jefe y ve una pantalla que dice que terminó. En CI, un test headless recorre exactamente ese mismo camino y termina en `finalizado = true`.

Eso es "con principio y final". Todo lo demás —simulación, generación infinita, economía emergente— queda fuera del juego, conservado en el historial de Git para retomarlo algún día si se quiere.
