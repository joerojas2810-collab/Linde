# §4. Elección del juego base (entregable A)

**Método:** se evaluaron los juegos completos disponibles para Luanti con criterios de la visión de
Linde, no de popularidad. Cada dato lleva marca **[V]** (verificado en repositorio/documentación el
2026-10-28), **[C]** (solo listado de ContentDB, servicio caído) o **[P]** (pendiente de prueba).

## 4.1 Comparativa de los cuatro candidatos reales

| Criterio | **Mineclonia** | **VoxeLibre** | **Minetest Game** | **Repixture** |
|---|---|---|---|---|
| Versión | **0.124.1** (2026-10-22) [V] | `0.93.0-SNAPSHOT` en el espejo [V] | mantenimiento [V] | **3.21.1** (2026-08-31) [V] |
| Último movimiento | upstream 2026-10-22; espejo 2026-10-27 [V] | espejo 2026-09-18 [V] | 2026-10-26 [V] | 2026-10-22 [V] |
| Repositorio | <https://codeberg.org/mineclonia/mineclonia> [V] | <https://git.minetest.land/MineClone2/MineClone2>; espejo <https://github.com/VoxeLibre/VoxeLibre> [V] | <https://github.com/luanti-org/minetest_game> [V] | <https://codeberg.org/Wuzzy/Repixture> [V] |
| Licencia | **GPL-3.0** (`LICENSE.txt`), activos en `LEGAL.md` [V] | **GPL-3.0** [V] | **LGPL-2.1+** código / **CC BY-SA 3.0** medios [V] | **AGPLv3** (relicenciado 2024) [V] |
| Tamaño del proyecto | 227 MiB, 18.706 commits, 150 etiquetas, **219 mods** [V] | juego completo, espejo parcial [V] | 34 mods, 200+ nodos [V] | 70 MiB, 6.255 commits [V] |
| Actividad declarada | «focus on stability, multiplayer performance and features» [V] | activo | **«perpetual maintenance-only mode»**: sin funciones nuevas [V] | activo |
| Requiere Luanti | **≥ 5.10** [V] | ≥ 5.10 [V] | ≥ 5.0 [V] | — |

## 4.2 Contenido frente a la visión de Linde

Leyenda: ✅ existe · 🟡 parcial · ❌ no existe

| Necesidad de Linde | Mineclonia | VoxeLibre | MTG | Repixture |
|---|---|---|---|---|
| Mundo abierto procedural persistente | ✅ | ✅ | ✅ | ✅ |
| Biomas variados | ✅ (incluye *lush caves*, *cherry grove*, *deep dark*) [V] | ✅ | ✅ (básicos) | 🟡 |
| Cuevas | ✅ | ✅ | ✅ | ✅ (*dripstone caves* desde 2026-10) [V] |
| Minerales y progresión de extracción | ✅ (8+ minerales, niveles de pico) [V] | ✅ | ✅ (7 minerales, 6 niveles) [V] | ✅ |
| Armas y armaduras | ✅ (`mcl_armor`, espadas, arcos) [V] | ✅ | ❌ (solo herramientas) | ✅ |
| Armadura visible en el personaje | ✅ (`mcl_armor`) [V] | ✅ | ❌ | ✅ |
| Fabricación | ✅ (mesa, horno, yunque, herrería, encantamientos) [V] | ✅ | 🟡 (mesa + horno) | ✅ |
| Criaturas y enemigos | ✅ (`mobs_mc`, `mcl_mobs`) [V] | ✅ | ❌ **«no built-in enemy mobs»** [V] | ✅ |
| Jefes | 🟡 barras de jefe presentes (`mcl_bossbars`) [V]; jefes concretos [P] | 🟡 ídem | ❌ | 🟡 |
| Mazmorras | ✅ (`mcl_dungeons`) [V] | ✅ | ✅ (mapgen `default`, 124 refs a `dungeon`) [V] | ✅ |
| Fortalezas / estructuras grandes | ✅ (`mcl_strongholds`, `mcl_nether_fortresses`, *ancient hermitage*) [V] | ✅ | ❌ | 🟡 |
| Aldeas | ✅ (`mcl_villages`, «improved villages») [V] | ✅ | ❌ | 🟡 |
| NPC / comercio | ✅ aldeanos + comercio + *wandering traders* [V/P] | ✅ | ❌ | 🟡 |
| Misiones | ❌ | ❌ | ❌ | ❌ |
| Profesiones / niveles RPG | ❌ | ❌ | ❌ | ❌ |
| Fabricación modular por material | ❌ | ❌ | ❌ | ❌ |
| Personalización de personaje (skins) | ✅ (`mcl_skins`) [V] | ✅ | ❌ (con `skinsdb`) | ✅ |
| API documentada para mods | ✅ `API.md`, `GROUPS.md` [V] | ✅ | ✅ (`game_api.txt`) [V] | 🟡 |
| Servidor dedicado probado por la comunidad | ✅ | ✅ | ✅ | 🟡 |
| Convertirlo en juego propio `linde` | ✅ (GPL-3.0: el derivado debe ser GPL-3.0) | ✅ (igual) | ✅ (LGPL: más permisivo) | ✅ (AGPL: el más estricto) |

## 4.3 Análisis de cada candidato

### Mineclonia — **seleccionado**

**Estado:** activo y con versiones frecuentes (150 etiquetas; 0.124.1 el 2026-10-22). [V]

**Qué aporta a Linde:** mundo, biomas, cuevas, minerales, mazmorras, fortalezas, Nether, aldeas con
aldeanos, un *End* con estructuras, armaduras visibles, encantamientos, hambre, experiencia,
pieles, barras de HUD y de jefe, guardado multijugador. Es decir, **casi todo el «mundo» de Linde y
casi todo el «contenido»**, sin integrar nada.

**Ventaja decisiva frente a VoxeLibre:** el README declara que Mineclonia nace como fork de
VoxeLibre «with focus on stability, multiplayer performance and features», con **pathfinding de
mobs reescrito**, **aldeas mejoradas** y **la mitad de tamaño** (sin música). Para un servidor
privado con 5–10 amigos, el rendimiento y el tamaño son exactamente los criterios que importan.

**Riesgos:**
- GPL-3.0: cualquier Linde distribuido derivado debe publicar su código con GPL-3.0.
- Es un clon de Minecraft: el contenido visual y de nombres es «familiar», no original. Linde
  tendría que reemplazar nombres, texturas y menús para tener identidad propia (trabajo de arte,
  no de código).
- 219 mods internos significan una superficie grande de configuración; tocar `mcl_*` sin conocer
  sus grupos rompe recetas en silencio.

### VoxeLibre — alternativa casi equivalente

**Estado:** activo; el espejo GitHub refleja 0.93.0-SNAPSHOT y se actualizó el 2026-09-18. [V]
**Licencia:** GPL-3.0. [V]
**Diferencia práctica:** es el proyecto «original» (ex MineClone2) y el que más documentación
histórica y mods de terceros tiene (`mcl_*`), pero es más pesado y su aldeas/pathfinding no están
mejorados como en Mineclonia. Elegirlo solo tendría sentido si un mod concreto que Linde necesita
solo existiera para VoxeLibre; **no encontramos ninguno así**.

### Minetest Game — referencia histórica y **base de la arquitectura de contingencia**

**Estado:** congelado. Su README dice literalmente: «Minetest Game is in perpetual maintenance-only
mode, meaning it will not see new gameplay features». [V]
**Licencia:** LGPL-2.1+ código, CC BY-SA 3.0 medios — la más permisiva del grupo. [V]
**Contenido:** 200+ nodos, 7 minerales, 6 niveles de herramienta, mazmorras en el mapgen, **sin
mobs, sin aldeas, sin armadura, sin jefes**. [V]

**Por qué sigue siendo relevante:** es el **único juego con el que funciona todo el ecosistema de
mods RPG clásico** (`mobs_redo` y familia, `3d_armor`, `moreores`, `ethereal`, `myprogress`,
`toolranks`, `mg_villages`, `caverealms_lite`, `easyvend`). Si Linde decidiera no escribir **ni una
línea** de Lua, esta es la única vía, con el costo de un juego congelado y de integrar 15–25 mods
independientes (ver §7.4).

### Repixture — descartado para Linde, pero conviene conocerlo

**Estado:** activo (3.21.1, 2026-08-31; commits de octubre de 2026). [V]
**Licencia:** **AGPLv3** desde 2024. [V]
**Contenido:** supervivencia, fabricación, construcción, mobs, cuevas con *dripstone*. Es un juego
original (no clon de Minecraft), lo que le da una identidad visual que Linde podría envidiar.
**Por qué se descarta:** AGPLv3 (obliga a liberar el código incluso a quien juega por red, y es
incompatible con mezclar mods GPL-2.0-only), menor ecosistema de mods y **sin sistema de
profesiones**. Su valor para Linde es de **referencia de diseño y de arte**, no de base técnica.

### Otros juegos: qué se sabe y qué no

| Juego | Estado de la evidencia |
|---|---|
| **Adventurelands** | Solo listado [C]: «exploration, mining, crafting, building and survival with monsters and animals», incluye `awards`. No verificado en repositorio. |
| **Regnum** | Solo listado [C]: «Fight monsters, collect XP, craft battleaxes, armor, guns and lots more». Interesante por XP, pero sin repositorio localizado. |
| **NodeCore, Mesecraft, Lord of the Test, otros** | **No auditados en esta pasada.** ContentDB caído impidió verificar versión, licencia y mantenimiento. No se recomiendan ni se descartan: se declaran pendientes. |

> Regla metodológica aplicada: **no se recomienda un juego que no se haya podido verificar en su
> repositorio.** Los listados de ContentDB no bastan porque no muestran licencia real ni actividad.

## 4.4 Puntuación contra la visión de Linde

Peso = importancia declarada en la visión. Escala 0–5. Solo cuentan capacidades verificadas.

| Criterio (peso) | Mineclonia | VoxeLibre | MTG+mods | Repixture |
|---|---|---|---|---|
| Mundo y exploración (15 %) | 5 | 5 | 4 | 4 |
| Mazmorras y estructuras (12 %) | 5 | 4 | 2 | 3 |
| Minerales y materiales (10 %) | 5 | 5 | 4 | 4 |
| Armas, armaduras, fabricación (12 %) | 4 | 4 | 4¹ | 3 |
| Enemigos y jefes (12 %) | 4 | 4 | 4¹ | 3 |
| NPC, aldeas, comercio (8 %) | 4 | 3 | 4¹ | 2 |
| Profesiones y progresión (15 %) | 0 | 0 | 3¹ | 0 |
| Mantenimiento y futuro (8 %) | 5 | 3 | 1 | 4 |
| Facilidad de modificar (8 %) | 4 | 4 | 5 | 3 |
| **Total ponderado** | **4,28** | **3,68** | **3,41** | **2,90** |

¹ Con mods de terceros, cuya integración no está probada. Ese «no probado» es precisamente el
riesgo que penaliza a MTG: su puntuación alta en profesiones depende de `myprogress`, un mod que
**solo existe para MTG** y cuya última actualización visible es de diciembre de 2025 [C].

## 4.5 Veredicto (entregable A)

> **Juego base: Mineclonia 0.124.1.**
>
> Es el que entrega **más contenido verificado y mantenido por unidad de esfuerzo**: mundo,
> mazmorras, fortalezas, aldeas, jefes, armaduras, encantamientos, skins y multijugador en un solo
> paquete. No requiere integrar nada para ser jugable hoy (§13, Fase 1), y su API documentada hace
> viable el único mod que Linde necesita escribir.
>
> **Condición:** aceptar GPL-3.0 en el código del juego derivado. Si eso fuera inaceptable, la
> alternativa es MTG (LGPL-2.1) con la arquitectura de contingencia de §7.4, asumiendo un juego
> congelado y una integración de mods no probada.

**Cómo se convierte en «Linde» sin tocar el motor:** se crea un juego derivado `linde` que
**depende** de Mineclonia (carpeta `games/linde/` con `game.conf` y un `mods/` propio), o —mejor—
se mantiene Mineclonia **como dependencia sin modificar** y se ponen los mods de Linde en
`worldmods/` del mundo. La segunda opción permite actualizar Mineclonia sin perder nada (§8.6).
