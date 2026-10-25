# Plan de estética de Linde — completo, en dos sesiones

> **Estado:** PROPUESTA para aprobación. Fecha: 2026-10-24. Redactado con las reglas del proyecto (`CLAUDE.md`, `.claude/docs/coordination-rules.md`, `coding-standards.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`) y los criterios de `instrucciones-recursos-arte.md`.
> **Regla maestra (instrucción del usuario, 2026-10-24):** *la línea de arte anterior (dibujo procedural) no debe salir más.* Al cerrar la sesión 2 no queda en el juego ningún elemento dibujado por código con `draw_rect`/`draw_circle`/polígonos como sustituto de arte, ni existe forma de volver a verlo.

## 1. Qué cubre y qué no

**Cubre todo lo visible:** mundo, objetos, construcciones, edificios, personaje, equipo, enemigos y jefes, habitantes, efectos de combate, indicadores, interfaz completa (menús, HUD, paneles, diálogos), iluminación día/noche y la paleta global.

**No cubre:** audio, mecánicas, equilibrio, guion ni nuevas reglas. Los sprites nuevos no cambian reglas, colisiones ni progresión.

**Límite honesto:** el código integra y valida arte; no lo dibuja. Dos sesiones alcanzan solo si el arte que aún no existe (sección 4, columna «Falta arte») llega a tiempo. Se pide con los prompts de la sección 9 y lo produce GPT o una artista, como fija `instrucciones-recursos-arte.md`.

## 2. Reglas de trabajo (aplican a las dos sesiones)

1. **Protocolo:** Pregunta → Opciones → Decisión → Borrador → Aprobación. Ningún agente escribe en un archivo sin preguntar «¿Puedo escribir esto en [ruta]?», salvo lo que el skill orquestador nombre. Los cambios en varios archivos se aprueban como conjunto.
2. **Delegación vertical:** `art-director` dirige; `technical-artist` y `godot-gdscript-specialist` implementan; `ui-programmer` y `ux-designer` la interfaz; `qa-tester` verifica; `creative-director` desempata. Nadie toca archivos fuera de su dominio sin delegación. Los conflictos suben al padre común.
3. **Datos, no constantes:** colores, tamaños, tiempos y rutas de arte van en `datos/` o en manifiestos, nunca fijos en el código.
4. **Evidencia de «terminado»:** una captura **retenida** en `production/qa/evidence/estetica/` por cada pantalla o estado tocado. Una verificación de sintaxis no es una ejecución. La captura se hace con el juego real (movie mode, `--always-on-top`; con la ventana tapada macOS no dibuja).
5. **Pruebas:** cada integración añade su prueba a `tests/prueba.gd` (convención `t_<tema>`, con nombre que dice escenario y resultado esperado). Una prueba de regresión se ve **fallar** contra el código sin arreglar antes de confiar en ella. La suite debe cerrar con 0 fallos.
6. **Procedencia:** cada recurso nuevo se registra con id, origen, herramienta, fecha, prompt, licencia, escala, tamaño, pivote y estado (provisional o final) en `Linde/cenital/arte/REGISTRO.json`. Sin assets de Pokémon ni propietarios de Helbreath.
7. **Sin commits** salvo instrucción del usuario. **Nada hacia repos externos.** Las decisiones de estilo se anotan como Propuesta en `Linde/cenital/docs/DECISIONES.md` hasta que el usuario las apruebe.
8. **Originales intactos:** `Linde/arte-entregado/` no se edita; se copia con manifiesto y hash, como se hizo con el equipo.
9. **Escala:** celda 16 px, PJ 16×24 (lienzo 32, y 48 en ataque), zoom entero 3, filtrado *nearest*, anclaje en los pies. No se mezcla con los 24 px del prototipo lateral.

## 3. Meta visual (criterio de aceptación)

Referencia: `Linde/documentos/LINDE_Punto_de_Inicio/referencias/visual_objetivo.png`. «Exactamente como la necesitamos» se mide comparando la captura contra la referencia a igual escala:

- Pixel art sencillo y legible, vista oblicua con tejados y fachadas visibles; contorno oscuro, 2–3 tonos por color; sin degradados ni antialiasing.
- Caminos de arena con borde de hierba, ríos con orilla de piedra y puente de madera, árboles de copa redonda, cuevas con escalones, casas con tejas, chimenea y puerta.
- Un único tamaño de píxel en toda la imagen (mundo, personaje, enemigos e interfaz).
- Zonas transitables identificables sin depender solo del color; avisos de ataque con contraste suficiente.
- Una **paleta global** aprobada (decisión D1, sección 8) que usan todos los recursos.

## 4. Inventario: qué hay, qué falta y qué hacer

Estado verificado el 2026-10-24. «Procedural» = dibujado por código (`arte.gd`, `escena.gd`, `hud.gd`). «Entregado» = existe en `Linde/arte-entregado/biblioteca_01/` pero **no está conectado** al juego.

| # | Elemento | Hoy | Fuente | Falta arte | Sesión |
|---|---|---|---|---|---|
| M1 | Hierba (variantes y motas) | procedural | `escenario/assets` (grass, grass_flecks) | variantes extra y esquinas | 1 |
| M2 | Camino de arena y bordes | procedural | path_fill, path_grass_n/e/s/w | esquinas internas y externas, cruces | 1 |
| M3 | Agua y orillas | procedural | water_fill, water_shore_* | esquinas, animación suave de agua | 1 |
| M4 | Puente | no existe | bridge_vertical | puente horizontal | 1 |
| M5 | Acantilado / muro de roca | procedural | wall_stone | bordes y esquinas | 1 |
| M6 | Ruinas (suelo y muro) | procedural | floor_ruins, wall_stone | muro de ruina distinto, escalones laterales | 1 |
| M7 | Suelo y pared de madera, puerta | procedural | floor_wood, cottage_open/closed | interior de la casa | 1 |
| O1 | Árboles (3 variantes) | procedural | tree_broadleaf, tree_fruit, tree_pine | estado «talado» y tocón | 1 |
| O2 | Roca y veta de mena | procedural | rock, ore_copper | estados «golpeada» y «agotada» | 1 |
| O3 | Arbusto con y sin bayas | procedural | bush_berries | estado sin bayas | 1 |
| O4 | Valla, barril, cofres | procedural | fence_horizontal, barrel, chest_* | valla vertical y esquinas | 1 |
| O5 | Edificios (casa, cobertizo, cueva) | procedural | cottage_*, crafting_shed, cave_entrance | tejado que se oculta al entrar | 1 |
| C1 | Construcciones del jugador (muro, suelo, mesa, horno, cofre, cama) | procedural | palisade, floor_wood, workbench, furnace, chest_closed, bed | vista de «fantasma» al construir | 1 |
| P1 | Personaje base y caminata | **nuevo** (sprites) | `cenital/arte/equipo/base` | — | hecho |
| P2 | Equipo en caminata (17 hojas) | **nuevo** | `cenital/arte/equipo` | — | hecho |
| P3 | Ataque con equipo | **nuevo, incompleto** | `arte/equipo/ataque` | 9 celdas de `PENDIENTE_DE_ARTE.md` y capa de estela | 1 |
| P4 | Reposo, herramienta, daño, caída, dormir | procedural o cuadro 0 | `personaje/herramienta.png` (solo herramienta) | daño, caída, dormir, herramienta con equipo | 1 |
| P5 | Variantes de pelo y ropa del creador | colores planos | `personaje/capas`, variante_* | geometrías de pelo y ropa | 2 |
| E1 | Slime | procedural | `enemigos/nativos/slime.png` | — | 2 |
| E2 | Guardián de las Ruinas | procedural | `enemigos/nativos/guardian.png` | cuadro de aviso reforzado | 2 |
| E3 | Gran Ciervo del Claro | procedural | `enemigos/nativos/ciervo.png` | — | 2 |
| H1 | Habitante Maren | procedural | recoloreo del base (propuesta) | sprite propio si el director de arte no aprueba el recoloreo | 2 |
| F1 | Efectos: estela, impacto, daño, avisos de zona | procedural | — | hojas de efecto | 2 |
| F2 | Indicadores: interacción y misión | procedural | interact_indicator, quest_marker | — | 2 |
| F3 | Luz día/noche y sombras | rectángulo azul | — | tinte por datos y sombras de pie | 2 |
| U1 | HUD: barra de vida, XP, hora, aviso | texto y rectángulos | healthbar_*, counter_panel | barra de XP | 2 |
| U2 | Iconos de ítems (12) y equipo | cuadrados de color | `interfaz/assets` (20 iconos) | iconos de las 17 piezas de equipo y del escudo | 2 |
| U3 | Paneles: inventario, fabricación, habilidades, misiones, diálogo | texto sobre fondo oscuro | panel, button_*, skill_*, categoria_* | marco de diálogo, retrato | 2 |
| U4 | Menú principal, creador de personaje, unirse y alojar | texto | button_* | fondo y título | 2 |
| U5 | Tipografía | fuente por defecto de Godot | — | fuente pixel (licencia verificada) | 2 |

## 5. Sesión 1 — Fundación y mundo

**Objetivo:** que el mundo, los objetos, las construcciones y el personaje (todos sus estados) se vean con el arte nuevo, y que la paleta global quede fijada.

**Antes de empezar:** decisiones D1–D5 resueltas (sección 8) y entregado el arte marcado sesión 1 en la columna «Falta arte» (o aprobado su uso provisional).

| Paso | Responsable | Entregable |
|---|---|---|
| 1.1 Fijar paleta global y hoja de estilo (contorno, luz, escala) | `art-director`, con aprobación del usuario | `design/art/hoja-de-estilo.md` y `datos/arte/paleta.json` |
| 1.2 Registro de recursos y validador de lote (tamaño múltiplo de 16, alfa, un solo tamaño de píxel, ancla, nombres) | `technical-artist` | `arte/REGISTRO.json` y `herramientas/arte/validar_lote.gd` |
| 1.3 Copiar a `cenital/arte/mundo/` tiles y objetos con manifiesto y hash | `technical-artist` | manifiesto y 36 PNG validados |
| 1.4 Autotile de terreno (hierba, camino, agua, roca, ruina) con esquinas y transiciones | `godot-gdscript-specialist` | `scripts/terreno.gd` y `datos/arte/terreno.json` (reglas por vecino, sin constantes en el código) |
| 1.5 Objetos con estados (árbol a tocón, roca, veta, arbusto, cofre abierto y cerrado), construcciones y fantasma de construir | `gameplay-programmer` y `technical-artist` | `scripts/objetos_arte.gd` |
| 1.6 Edificios, ocultación del tejado al entrar, interior de la casa y puertas alineadas con la colisión | `godot-gdscript-specialist` | casa, cobertizo y cueva integrados |
| 1.7 Orden de dibujo por profundidad desde los pies y copas separadas | `engine-programmer` | prueba de oclusión |
| 1.8 Personaje: cerrar celdas pendientes de ataque, estela, herramienta con equipo, daño, caída y dormir | `technical-artist` | `PENDIENTE_DE_ARTE.md` vacío o con excepciones aprobadas |
| 1.9 Verificación | `qa-tester` | suite en 0 fallos; capturas de casa, cantera, lago, ruinas, bosque, interior y construcción |
| 1.10 Revisión de aspecto contra la referencia | `art-director` y `creative-director` | acta de aprobación o lista de correcciones |

**Condición de cierre:** recorriendo el mapa 64×48 de punta a punta no aparece ningún tile ni objeto procedural. Los enemigos y la interfaz aún pueden ser provisionales y se listan como pendientes de la sesión 2.

## 6. Sesión 2 — Vida, interfaz y cierre

**Objetivo:** enemigos, habitantes, efectos, luz, interfaz completa y retirada del arte anterior.

| Paso | Responsable | Entregable |
|---|---|---|
| 2.1 Enemigos y jefes: 4 direcciones × 5 poses, aviso de ataque legible, hitboxes sin cambios | `ai-programmer` y `technical-artist` | slime, guardián y ciervo con sprites |
| 2.2 Maren y futuros habitantes con el sistema de capas y paleta | `gameplay-programmer` | habitante con arte y rutina visible |
| 2.3 Efectos: estela de espada, impacto, daño, zonas de aviso, partículas de recolección | `technical-artist` | `arte/efectos/` y manifiesto |
| 2.4 Luz día/noche, sombras y tinte por datos | `godot-shader-specialist` | `datos/arte/luz.json`; sin rectángulo azul |
| 2.5 Interfaz: HUD, paneles, diálogo, menús, creador y unirse, con marcos e iconos del arte entregado | `ui-programmer` y `ux-designer` | `hud.gd` sin rellenos dibujados por código |
| 2.6 Iconos de las 17 piezas de equipo y del escudo | `technical-artist` | `arte/iconos/` |
| 2.7 Tipografía pixel con licencia verificada y escala de texto | `ui-programmer` y `accessibility-specialist` | fuente y opción de escala |
| 2.8 Accesibilidad visual: contraste de avisos, no depender solo del color, zona transitable identificable | `accessibility-specialist` | informe y correcciones |
| 2.9 **Retirada del arte anterior** (sección 7) | `lead-programmer` | `arte.gd` y rutas procedurales eliminadas |
| 2.10 Verificación final: suite completa, recorrido completo, capturas de **todas** las pantallas, prueba en red con dos clientes | `qa-lead` y `qa-tester` | `production/qa/evidence/estetica/` completo |
| 2.11 Revisión final y cierre | `creative-director` | aprobación anotada en `DECISIONES.md` |

## 7. Retirada del arte anterior (regla maestra)

**Ya hecho el 2026-10-24:** `usar_arte` arranca en `true` y se quitó la tecla F2 que devolvía al dibujo procedural. Hoy eso solo afecta al personaje y su equipo, porque lo demás aún no tiene arte conectado.

**Pendiente:**
- **Sesión 1:** eliminar de `escena.gd` el dibujo de terreno, objetos, edificios y construcciones, y quitar `arte.gd` (copas, rocas, matas) cuando nada lo llame.
- **Sesión 2:** eliminar el dibujo procedural de enemigos, habitante, avisos y la luz por rectángulo; quitar de `hud.gd` los rellenos y botones hechos por código; quitar `capas_sprite.gd` y `apariencia.gd` si el sistema nuevo los reemplaza por completo.
- **Sin vuelta atrás:** el juego no tendrá interruptor ni argumento para volver al dibujo anterior. Si falta un recurso, **falla con un error claro** (`push_error` y un marcador de «arte faltante» visible) en lugar de dibujar el procedural.
- **Prueba de que no queda nada:** `t_sin_arte_procedural` recorre `scripts/` y falla si encuentra `draw_rect`, `draw_circle` o `draw_colored_polygon` fuera de una lista blanca aprobada (selección, depuración con F1, cajas de colisión).

## 8. Decisiones del usuario antes de la sesión 1

| ID | Decisión | Recomendación |
|---|---|---|
| D1 | Aprobar la **paleta global** tras verla aplicada a mundo y personaje | Se propone en 1.1 con muestras reales, no en abstracto |
| D2 | Quién produce el arte que falta (GPT o artista) y plazo | Pedir todo el lote 1 antes de empezar y el lote 2 durante la sesión 1 |
| D3 | Maren: ¿recoloreo del personaje base o sprite propio? | Recoloreo (no requiere arte nuevo); se revisa en 2.2 |
| D4 | Tipografía: ¿pixel propia con licencia libre o fuente del sistema? | Pixel libre (OFL); si no, se registra la excepción |
| D5 | Interior de la casa: ¿techo que se oculta al entrar o corte de pared? | Techo que se oculta, como en la referencia |

## 9. Prompts de arte para lo que falta

Siguen las reglas comunes de `instrucciones-recursos-arte.md`: *original pixel art, overhead oblique camera, readable dark outline, 2–3 tones per colour, one pixel size, hard edges, no blur, no antialiasing, no gradients, transparent background, no text, no licensed assets.* Cada pedido incluye lienzo, ancla, nombre de archivo y estados.

- **Lote 1 (antes de la sesión 1):** esquinas de terreno, puente horizontal, valla vertical, estados de árbol, roca y arbusto, interior de la casa, las 9 celdas de ataque pendientes, hojas de daño, caída y dormir.
- **Lote 2 (durante la sesión 1):** efectos, barra de XP, marcos de diálogo, iconos de equipo, fondo de menú.

La lista exacta de nombres y medidas se genera en el paso 1.2 a partir del registro.

## 10. Riesgos

- **El arte llega tarde:** la sesión 1 solo cierra con arte entregado. Mitigación: pedir el lote 1 ya y marcar cada recurso como provisional o final.
- **Sesiones largas:** el estado vive en `production/session-state/active.md`, no en la conversación, así que un `/clear` o una compactación no pierde el hilo.
- **Autotile con huecos:** se valida con un mapa de prueba que contiene todas las combinaciones antes de aplicarlo al mundo.
- **Rendimiento:** presupuesto de 60 fps con el mapa completo; se mide en 1.9 y 2.10.
- **Red:** los jugadores remotos dibujan con el mismo arte; la prueba de dos clientes cubre equipo y enemigos.
- **Procedencia:** el arte generado no tiene certificación jurídica de exclusividad (así lo declara `biblioteca_01`); se mantiene el registro por recurso.

## 11. Prompts de arranque

**Sesión 1:** «Lee `Linde/documentos/PLAN_ESTETICA_2_SESIONES.md` (secciones 2, 5, 7 y 8) y `production/session-state/active.md`. Empieza por el paso 1.1: propón la paleta global con muestras aplicadas. Pregunta antes de escribir cualquier archivo.»

**Sesión 2:** «Lee el mismo plan (secciones 2, 6 y 7) y el acta de cierre de la sesión 1 en `DECISIONES.md`. Empieza por 2.1. No cierres hasta que `t_sin_arte_procedural` pase y todas las capturas estén en `production/qa/evidence/estetica/`.»

## 12. Lista de comprobación de cierre

- [ ] Suite de pruebas con 0 fallos, incluida `t_sin_arte_procedural`.
- [ ] Capturas retenidas de: menú, creador, casa exterior, interior, cantera, lago, puente, bosque, ruinas, cueva, construcción, combate con los 3 enemigos, noche, inventario, fabricación, habilidades, misiones, diálogo y unirse.
- [ ] Prueba con dos clientes en red sin diferencias visuales.
- [ ] `PENDIENTE_DE_ARTE.md` vacío o con excepciones aprobadas.
- [ ] `REGISTRO.json` completo (procedencia por recurso).
- [ ] Sin `draw_rect`, `draw_circle` ni polígonos como sustituto de arte.
- [ ] Aprobación de `art-director` y `creative-director` anotada en `DECISIONES.md`.
