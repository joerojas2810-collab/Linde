# §5 y §6. Mods: investigación por categoría y fichas técnicas (entregable B)

**Verificado el 2026-10-28.** Marcas: **[V]** repositorio/API consultado · **[C]** solo listado de
ContentDB (caído) · **[P]** pendiente de prueba en partida.

> **Nota sobre repositorios.** Una parte importante del ecosistema Luanti vive en
> **Codeberg** y **git.minetest.land**, no en GitHub. Muchos repos de GitHub que aparecen en guías
> antiguas devuelven 404 porque el autor migró. En este documento se indica el repositorio que
> **existe hoy**, y cuando el original no se localizó se dice explícitamente.

---

## 5.A Profesiones, habilidades y niveles

### Qué existe

| Paquete | Qué hace | Base | Licencia | Estado | Evidencia |
|---|---|---|---|---|---|
| **My Progress** (`myprogress`) | 6 habilidades (Minería, Excavación, Tala, Agricultura, Construcción, Combate), XP con curva exponencial, barras visuales, ajuste `myprogress_difficulty` (Hard/Easy) | Minetest Game (`default`) | — | actualizado 2025-12-24 | [C] <https://content.luanti.org/packages/Don/myprogress/> |
| **SkillsFramework** | Solo **API** para crear habilidades; no añade ninguna | cualquiera | Unlicense (DomtronVox, 2015) / MIT (fork Jimmmmmies, 2026-03-13) | original abandonado; fork reciente | [V] <https://github.com/DomtronVox/minetest-SkillsFramework> · <https://github.com/Jimmmmmies/SkillsFramework> |
| **Skills & States API** | API de habilidades y estados | cualquiera | — | listado | [C] ContentDB, etiqueta `library` |
| **toolranks** | Las herramientas suben de nivel al minar; más nivel = más durabilidad | MTG (`default`) | LGPL-2.1 | 2023-11-18 | [V] <https://github.com/lisacvuk/minetest-toolranks> |
| **awards** | Logros/estadísticas de actividad, «rpg-like tracking» | MTG | — | — | [C] |

### Qué **no** existe (verificado por búsqueda, no supuesto)

Buscamos en GitHub (búsquedas `myprogress`, `skillsframework`, `toolranks`, `rpg minetest`,
`quests minetest`) y en el índice de ContentDB accesible por buscador. **No se encontró**:

1. Un equivalente a **Project MMO**: XP por actividad + niveles por profesión + **requisitos que
   bloquean** extraer un mineral o empuñar un arma.
2. **Árboles de habilidades** ni puntos de habilidad.
3. **Clases** de personaje con bonificaciones.
4. Un sistema de niveles **compatible con Mineclonia/VoxeLibre**. `myprogress` declara como
   dependencia obligatoria `default`, que **no existe** en los juegos `mcl_*`.

> **Afirmación prudente:** puede existir algún mod no publicado o no indexado. Lo que está
> demostrado es que **no hay ninguno mantenido, con licencia clara y compatible con Mineclonia**
> que hayamos podido verificar. Eso basta para planificar `linde_core`.

### Consecuencia para Linde

La capa de profesiones es **el único bloque grande de código propio**. Es además el bloque más
barato de escribir, porque el motor ya ofrece los tres ganchos que hacen falta:

- `minetest.register_on_dignode(pos, oldnode, digger)` → XP de minería y comprobación del requisito.
- `minetest.register_on_craft(itemstack, player, old_craft_grid, craft_inv)` → XP de fabricación.
- `minetest.register_on_punchplayer(player, hitter, ...)` y `on_dieplayer` → XP de combate.
- `groupcaps` con `level` en cada herramienta → requisito de extracción (el motor ya bloquea
  minerales por nivel de pico; solo hay que **subir o bajar ese nivel según la profesión**).
- `player:get_meta()` → persistencia por jugador, sin base de datos externa.

Es decir: **no hay que programar un sistema de bloqueo, hay que programar la política**.

---

## 5.B Minerales y materiales

| Paquete | Aporta | Base | Licencia | Última act. | Evidencia |
|---|---|---|---|---|---|
| **moreores** | Plata, estaño, zinc, mithril + herramientas y armaduras | **MTG y Mineclonia y MineClone2** (declarado en `mod.conf`) | **Zlib** | 2025-03-15 | [V] <https://github.com/minetest-mods/moreores> |
| **moreblocks** | Bloques de construcción y algunos nodos | MTG | Zlib | 2026-07-21 | [V] <https://github.com/minetest-mods/moreblocks> |
| **technic** | Cadena industrial completa: minerales, aleaciones, máquinas, energía | MTG | LGPL-2.1 (repo sin SPDX) | 2026-08-08 | [V] <https://github.com/minetest-mods/technic> |
| **new minerals** | «mineral abysmal, cobalto, adamantita, tungsteno, clorofita, titanio» | MTG | — | — | [C] |

**Duplicaciones:** el riesgo real es **estaño y cobre**. Mineclonia ya registra cobre; `moreores`
registra estaño y —según su `mod.conf`— soporta `mineclone2`/`mineclonia`, lo que indica que
adapta nombres para no colisionar. **Esto está declarado por el autor, no probado** [P]. Con
`technic` el riesgo es mayor: trae su propio estaño, zinc, cobre y aleaciones, pensadas para MTG.

**Regla para Linde:** un solo mod de minerales. Si la base es Mineclonia, usar **solo `moreores`**
(y comprobar en partida que no hay dos «cobre» distintos). Si se quiere progresión de extracción
(madera → piedra → hierro → acero → mithril), eso ya lo da el sistema de `groupcaps` del juego,
no hace falta un mod.

---

## 5.C Armas, armaduras y fabricación modular

### Lo que existe

| Paquete | Qué aporta | Base | Licencia | Última act. | Evidencia |
|---|---|---|---|---|---|
| **3d_armor** (modpack) | Armadura **visible** en 5 piezas, `shields`, `wieldview` (ver el ítem en la mano), `armor_stand`, variantes: `armor_wood`, `armor_cactus`, `armor_steel`, `armor_bronze`, `armor_diamond`, `armor_gold`, `armor_mithril`, `armor_nether`, `armor_crystal` | MTG (depende `player_api`) | **LGPL-2.1** (código) | 2026-07-20 | [V] <https://github.com/minetest-mods/3d_armor> |
| **mcl_armor** (interno de Mineclonia) | Armadura visible + yunque + encantamientos + *trims* | Mineclonia | GPL-3.0 | 2026-10 | [V] |
| **rangedweapons** | Arcos, ballestas, armas de fuego y arrojadizas | **solo MTG** (depende `default`, `tnt`) | medio: **CC BY-SA 4.0**; licencia de código no declarada | 2026-07-05 | [V] <https://github.com/lhofhansl/rangedweapons> |
| **x_enchanting** | Encantamientos por mesa encantada, estilo MC | `mcl_*` | LGPL-3.0 | 2023-12-07 | [V] <https://github.com/MoNTE47/x_enchanting> |
| **castle_shields** | Escudos heráldicos (decorativos, no de combate) | MTG | MIT | 2024-11-22 | [V] |

### Fabricación modular: el hueco más grande

Buscamos explícitamente un equivalente a **Silent Gear / Tinker's Construct** (el resultado depende
de los materiales, con estadísticas por material, componentes intercambiables y calidad). **No hay
ninguno verificado.** Lo que hay es:

- **Fabricación tradicional** (recetas fijas) → todo el ecosistema.
- **Mejora de objetos** → `toolranks` (sube nivel por uso), `x_enchanting` (añade encantamientos),
  `mcl_enchanting` y yunque en Mineclonia.
- **Variantes por material** → `3d_armor` tiene sets separados por material, pero son objetos
  distintos, no un sistema paramétrico.

**Consecuencia:** la fabricación modular de Linde es **código propio**. Pero el prototipo Godot ya
tiene el modelo de datos terminado (`reglas_v1.json` con `dureza`, `tenacidad`, `densidad` por
material y `formas` por material; `arquetipos.json` con ranuras y multiplicadores;
`familias.json` con bonos de set; `variantes.json` con piedras; `joyas.json` con niveles +0..+5).
**Eso es una especificación, no una idea**: se traduce a tablas Lua casi literalmente (§11).

---

## 5.D Combate y magia

| Capacidad | Estado en el ecosistema | Evidencia |
|---|---|---|
| Cuerpo a cuerpo con estadísticas | **Motor + juego**: `damage_groups`, `tool_capabilities` | [V] |
| Arcos y proyectiles | Mineclonia los trae; `rangedweapons` en MTG | [V] |
| Escudos que bloquean | `3d_armor` incluye `shields` (MTG); Mineclonia tiene escudo | [V] |
| Encantamientos y mejoras | `mcl_enchanting` (juego), `x_enchanting`, yunque | [V] |
| Efectos de estado | Parcial: pociones en Mineclonia (`mcl_potions`); **no hay API genérica de estados** verificada | [V]/[P] |
| Magia (hechizos, maná) | **Nada verificado.** No se localizó un sistema de magia mantenido | — |
| Críticos, esquiva, bloqueo porcentual | **No existe**: es capa propia | — |
| Dificultad progresiva | Parcial: Mineclonia escala con profundidad y dificultad del mundo | [P] |

**Convivencia:** `rangedweapons` **reemplaza** el sistema de proyectiles y depende de `tnt`, por lo
que no se lleva bien con un juego `mcl_*`. `x_enchanting` y `mcl_enchanting` **compiten**: dos
mesas de encantar distintas. Regla: **un solo sistema por mecánica**, y en Mineclonia casi todas
las mecánicas ya están ocupadas por el propio juego.

---

## 5.E Criaturas, enemigos y jefes

| Paquete | Qué aporta | Base | Licencia | Última act. | Evidencia |
|---|---|---|---|---|---|
| **mobs_redo** (mod `mobs`) | API de mobs con IA, cría, domesticación, daño, drops | MTG | **MIT** | 2026-10-27 | [V] espejo `minetest-mirrors/mobs_redo` |
| **mobs_monster** | ~20 monstruos (oerkki, dungeon master, mummy, sand/stone/tree monster, land guard, lava flan, spider…) | MTG | **MIT** | 2026-10-25 | [V] |
| **mobs_animal** | Animales domesticables | MTG | MIT (modelos de K Pavel) | 2026-10-25 | [V] |
| **mobs_npc** | NPC humanoides con órdenes | MTG | **MIT** | 2026-10-25 | [V] |
| **mob_core** | API de mobs moderna sobre `mobkit`, con pathfinding | MTG | **GPL-3.0** | 2022-01-04 | [V] <https://github.com/ElCeejo/mob_core> |
| **ethereal_bosses** | Jefes asociados a los biomas de `ethereal` | MTG + `ethereal` | **sin licencia declarada** | 2024-09-24 | [V] repo <https://github.com/adikalon/ethereal_bosses> |
| **mobs_mc / mcl_mobs** | Todos los mobs del juego, incluidos jefes | Mineclonia | GPL-3.0 | 2026-10 | [V] |
| **mcl_bossbars** | Barra de vida de jefe | Mineclonia | GPL-3.0 | 2026-10 | [V] |

**Advertencias verificadas:**
- **`mobs_redo` y `mcl_mobs` no se mezclan.** Son dos universos de entidades con daño, drops y
  grupos de armadura distintos. Meter `mobs_monster` en Mineclonia no funciona: sus monstruos
  dependen de `default`.
- `ethereal_bosses` **no declara licencia**: se puede probar, pero **no se puede redistribuir
  legalmente** dentro de un Linde empaquetado sin permiso del autor.
- **Multijugador:** `mobs_redo` se usa en servidores públicos desde años, pero **nosotros no lo
  probamos**. Declarado sí, verificado no [P].

---

## 5.F Biomas, estructuras y mazmorras

| Paquete | Aporta | Base | Licencia | Última act. | Evidencia |
|---|---|---|---|---|---|
| **ethereal** | ~30 biomas nuevos, árboles, hongos, cristales, mecanismos | MTG | **MIT** | 2026-10-23 | [V] |
| **caverealms_lite** | Cavernas gigantes con hongos y cristales | MTG | BSD (archivo `LICENSE.txt`) | espejo 2026-07-27 | [V] |
| **mg_villages** | Aldeas procedurales para todos los mapgens | MTG (requiere `mg`) | **sin licencia declarada** | 2023-08-26 | [V] <https://github.com/Sokomine/mg_villages> |
| **cottages** | Casas medievales y aldeas | MTG | **GPL-3.0** | 2026-01-02 | [V] |
| **mcl_dungeons / mcl_structures / mcl_villages / mcl_strongholds / mcl_nether_fortresses** | Mazmorras, estructuras, aldeas, fortalezas, fortalezas del Nether | Mineclonia | GPL-3.0 | 2026-10 | [V] |

### Cómo se generan las estructuras (y qué pasa al añadir mods a un mundo existente)

1. **Esquemáticos**: se guardan como `.mts` y se insertan con `minetest.place_schematic` desde un
   *decoration* (superficie, cueva) o desde un LBM/ABM.
2. **Decoraciones**: `minetest.register_decoration` coloca el esquemático durante la generación del
   *mapchunk*; admite `biomes`, `y_min/y_max`, `place_offset_y`, `flags`.
3. **Generación diferida**: las estructuras solo aparecen en **terreno nuevo**. Un mundo ya
   explorado **no se regenera**.
4. **Instalar un mod de estructuras en un mundo existente**: las estructuras nuevas aparecerán
   **lejos**, en zonas nunca generadas. Cerca del spawn no aparecerán, porque esos mapblocks ya
   están escritos en `map.sqlite`.
5. **Mazmorras de Mineclonia**: se generan en la creación del mundo; añadir mods de mazmorras
   después no las sustituye, se suman donde el terreno esté virgen.
6. **LBMs** (`minetest.register_lbm`) permiten «retro-decorar» bloques ya generados al cargarse,
   pero **no** pueden insertar estructuras grandes de forma segura.

> **Consecuencia operativa para Linde:** el orden correcto es **decidir los mods de generación
> antes de crear el mundo de la beta**. Cambiarlos después obliga a empezar un mundo nuevo (o a
> viajar lejísimos). Esto entra como criterio de aceptación en la Fase 1 (§13).

---

## 5.G NPC, comercio y misiones

| Paquete | Qué aporta | Base | Licencia | Última act. | Evidencia |
|---|---|---|---|---|---|
| **mobs_npc** | NPC humanoides, con diálogo simple y órdenes | MTG | MIT | 2026-10-25 | [V] |
| **mcl_villages** + aldeanos | Aldeas con aldeanos que **comercian**, *wandering traders* y llamas | Mineclonia | GPL-3.0 | 2026-10 | [V] |
| **easyvend** | Máquinas expendedoras / tiendas automáticas | MTG | **LGPL-2.1** | 2023-04-16 | [V] espejo `minetest-mirrors/easyvend` |
| **quests_api** | API de misiones | MTG | **sin licencia declarada** | 2024-03-27 | [V] <https://github.com/C-C-Minetest-Server/quests_api> |
| **Folks** | NPC personalizables | — | — | — | [C] |
| **currency**, **yl_speak_up** (Sokomine) | Moneda y diálogos/quests | MTG | — | **no localizados** en esta pasada | — |

**Estado real:** el comercio **sí** está resuelto en Mineclonia (aldeanos). Las **misiones** no:
solo hay una API sin licencia y de 2024, sin juego que la use de forma verificable. Para Linde, la
decisión ya tomada en el proyecto («la narrativa y las misiones son opcionales en la v1») coincide
con la realidad del ecosistema: **no hay que programarlas ahora**.

---

## 5.H Personajes y personalización

| Capacidad | Cómo se hace sin tocar el motor | Evidencia |
|---|---|---|
| Pieles | `mcl_skins` (Mineclonia) o `skinsdb` (MTG, **sin licencia declarada**) | [V] |
| Armadura visible | `mcl_armor` (Mineclonia) / `3d_armor` (MTG) | [V] |
| Animaciones | `PlayerAnimationLibrary` (MIT, 2026-10-25), `playeranim` (BSD-2, 2025) | [V] |
| Modelos propios | `.b3d` / `.obj` / `.gltf` enviados como *media* | [V] |
| Selección de personaje / clase | **Formspec al entrar** (`register_on_joinplayer` + `show_formspec`) — no existe paquete hecho | [P] |
| Ropa / cosméticos | Igual que armadura visible: piezas sin estadísticas | [P] |

**Límite duro:** el **arte 2D del prototipo Godot no se reutiliza** en un mundo 3D. Sus hojas de
personaje y equipo sirven como referencia de paleta y silueta, y quizá como *sprites* de HUD e
inventario, no como modelo del jugador.

---

## 5.I Calidad de vida

| Necesidad | Paquete | Licencia | Estado | Evidencia |
|---|---|---|---|---|
| Inventario con búsqueda y **guía de recetas** | **unified_inventory** | LGPL-2.1+ | 2026-08-23 | [V] |
| Guía de recetas alternativa | `CraftGuide` (Uristqwerty) | MIT | 2020 (viejo) | [V] |
| Barras de vida/hambre/aire | `hudbars` + `hbhunger` (Mineclonia ya las trae) | **sin licencia** | 2026-04-01 | [V] |
| Mochila | `inventory_pouches` (MTG y MCL) | **sin licencia detectada** | 2026-06-29 | [V] |
| Viaje rápido | `travelnet` | GPL-3.0 | 2023-01-09 | [V] |
| Protección de construcciones | `areas` | LGPL-2.1 | 2026-09-19 | [V] |
| Minimapa | **del motor** (tecla F9), desactivable por el juego | — | — | [V] |
| Mapas de papel | `mcl_maps` (Mineclonia) | GPL-3.0 | 2026-10 | [V] |
| Logros | `awards` | — | [C] | — |
| Respaldos | **del servidor**, no de un mod (§9.6) | — | — | [V] |

---

## §6. Fichas técnicas de los mods decisivos

Formato completo de 15 campos. El catálogo íntegro, con los mismos campos para **32 paquetes**,
está en [`anexos/catalogo_mods.csv`](anexos/catalogo_mods.csv).

### Ficha 1 — Mineclonia (juego base)

| Campo | Información |
|---|---|
| Nombre | Mineclonia (`mineclonia`) |
| Función | Juego completo: mundo, mazmorras, aldeas, mobs, jefes, armaduras, encantamientos |
| URL | <https://content.luanti.org/packages/ryvnf/mineclonia/> · <https://codeberg.org/mineclonia/mineclonia> |
| Licencia | GPL-3.0 (`LICENSE.txt`); activos detallados en `LEGAL.md` |
| Última actualización | 2026-10-22 (versión 0.124.1); espejo GitHub 2026-10-27 |
| Versión investigada | **0.124.1** |
| Dependencias | Luanti ≥ 5.10; nada externo |
| Juego base compatible | Es el juego base |
| Multijugador | Declarado y con foco explícito en rendimiento multijugador; **no probado aquí** [P] |
| Estado | Activo |
| Conflictos | No admite mods que dependan de `default`; no admite mapgen `v6` |
| Configuración sin programar | `minetest.conf` del juego, ajustes `mcl_*`, dificultad, generación |
| Código reutilizable | API `mcl_*`, estructuras, mobs, aldeanos, HUD |
| Recomendación | **Instalar** (base elegida) |

### Ficha 2 — My Progress

| Campo | Información |
|---|---|
| Nombre | My Progress (`myprogress`), autor «Don» |
| Función | 6 habilidades con XP exponencial y barras; «master machines» |
| URL | <https://content.luanti.org/packages/Don/myprogress/> (ContentDB **caído** al verificar) |
| Licencia | **no determinada** (no se pudo abrir la ficha completa) |
| Última actualización | 2025-12-24 (fecha de la ficha indexada) [C] |
| Versión investigada | no determinada |
| Dependencias | **`default`** obligatorio; opcionales `ethereal`, `farming`, `mobs`, `mobs_animal`, `mobs_monster`, `mobs_redo`, `moretrees`, `myores`, `stairs` |
| Juego base compatible | **Minetest Game** (por la dependencia `default`) |
| Multijugador | No verificado |
| Estado | Activo según listado; sin repositorio localizado |
| Conflictos | Incompatible con Mineclonia/VoxeLibre sin reescritura |
| Configuración sin programar | `myprogress_difficulty` (Hard/Easy) |
| Código reutilizable | **Concepto y curva de XP**; el código no se puede reutilizar sin licencia clara |
| Recomendación | **Probar/adaptar solo en la arquitectura de contingencia (MTG)**; **descartar** para Mineclonia |

### Ficha 3 — 3d_armor

| Campo | Información |
|---|---|
| Nombre | 3D Armor (modpack: `3d_armor`, `shields`, `wieldview`, `armor_stand`, `armor_*`) |
| Función | Armadura visible por piezas, escudos, ver el ítem en la mano |
| URL | <https://content.luanti.org/packages/stu/3d_armor/> · <https://github.com/minetest-mods/3d_armor> |
| Licencia | **LGPL-2.1** (código, `LICENSE.md`); medios CC BY-SA 3.0 |
| Última actualización | 2026-07-20 |
| Versión investigada | HEAD de `master` |
| Dependencias | `player_api` (obligatoria); opcionales `default`, `player_monoids`, `armor_monoid`, `pova`, `moreores` |
| Juego base compatible | Minetest Game (por `player_api`) |
| Multijugador | Usado en servidores; no verificado aquí [P] |
| Estado | Activo |
| Conflictos | **No funciona en Mineclonia** sin adaptar `player_api` |
| Configuración sin programar | `settingtypes.txt`: daño, durabilidad, niveles de material |
| Código reutilizable | Fórmulas de reducción de daño y registro de piezas |
| Recomendación | **Instalar** si la base es MTG; **descartar** con Mineclonia |

### Ficha 4 — mobs_redo + mobs_monster

| Campo | Información |
|---|---|
| Nombre | Mobs Redo (`mobs`), Mobs Monster (`mobs_monster`), Mobs Animal, Mobs NPC |
| Función | API de criaturas + monstruos + animales + NPC |
| URL | Espejo verificado: <https://github.com/minetest-mirrors/mobs_redo> (upstream de TenPlus1) |
| Licencia | **MIT** (`license.txt`) en `mobs_redo`, `mobs_monster`, `mobs_npc`, `farming`, `ethereal` |
| Última actualización | 2026-10-27 (`mobs_redo`); 2026-10-25 (los demás) |
| Versión investigada | HEAD del espejo |
| Dependencias | `mobs`; opcionales `default`, `tnt`, `toolranks`, `player_api`, `mcl_sounds` |
| Juego base compatible | Minetest Game |
| Multijugador | Declarado, usado en servidores públicos; **no probado aquí** [P] |
| Estado | Activo (mantenido por TenPlus1) |
| Conflictos | **Incompatible con `mcl_mobs`**; no usar en Mineclonia |
| Configuración sin programar | `mobs.conf`/settings: daño, spawn, límites |
| Código reutilizable | API completa de mobs (la mejor documentada del ecosistema) |
| Recomendación | **Instalar** en MTG; **descartar** en Mineclonia |

### Ficha 5 — ethereal_bosses

| Campo | Información |
|---|---|
| Nombre | Ethereal Bosses (ContentDB: «Mobs Ethereal Bosses») |
| Función | Jefes por bioma sobre `ethereal` |
| URL | <https://github.com/adikalon/ethereal_bosses> (repo); ficha ContentDB no accesible |
| Licencia | **NINGUNA declarada** en el repositorio |
| Última actualización | 2024-09-24 (hay un fork «reworked» de 2026-10-11) |
| Versión investigada | HEAD |
| Dependencias | `mobs` (mobs_redo) + `ethereal` |
| Juego base compatible | Minetest Game |
| Multijugador | No verificado |
| Estado | Semi-abandonado (2 años sin commits en el original) |
| Conflictos | Requiere `ethereal`; sin licencia no se puede empaquetar legalmente |
| Configuración sin programar | Escaso |
| Código reutilizable | **Ilegal sin permiso**; sirve como referencia de diseño |
| Recomendación | **Probar** en un mundo de prueba, **no distribuir** hasta aclarar licencia |

### Ficha 6 — moreores

| Campo | Información |
|---|---|
| Nombre | More Ores (`moreores`) |
| Función | Plata, estaño, zinc, mithril + herramientas y armaduras |
| URL | <https://content.luanti.org/packages/?q=moreores> · <https://github.com/minetest-mods/moreores> |
| Licencia | **Zlib** |
| Última actualización | 2025-03-15 |
| Versión investigada | HEAD |
| Dependencias | opcionales `carts`, `farming`, `frame`, `mg`, `toolranks`, `mcl_core`, `mcl_sounds` |
| Juego base compatible | **declara `mineclone2`, `mineclonia`, `minetest_game`** en `mod.conf` |
| Multijugador | No verificado |
| Estado | Activo (bajo) |
| Conflictos | Posible duplicación de cobre/estaño con Mineclonia o `technic` (no probado) |
| Configuración sin programar | Frecuencia y altura de minerales en `init.lua` |
| Código reutilizable | Registro de minerales y herramientas (Zlib: muy permisiva) |
| Recomendación | **Instalar y probar** duplicaciones en la Fase 2 |

### Ficha 7 — areas

| Campo | Información |
|---|---|
| Nombre | Areas (`areas`) |
| Función | Protección de terrenos por jugador, con gestión de propietarios |
| URL | <https://content.luanti.org/packages/ShadowNinja/areas/> · <https://github.com/minetest-mods/areas> |
| Licencia | **LGPL-2.1** |
| Última actualización | 2026-09-19 |
| Versión investigada | HEAD |
| Dependencias | opcional `playerfactions` |
| Juego base compatible | Cualquiera con `default`/`mcl` (usa `default:stick` para la herramienta; verificar en MCL) [P] |
| Multijugador | Sí, es su propósito |
| Estado | Activo |
| Conflictos | Ninguno conocido |
| Configuración sin programar | Límites de área por jugador en `settings` |
| Código reutilizable | API de protección |
| Recomendación | **Instalar** (imprescindible con amigos) |

### Ficha 8 — unified_inventory

| Campo | Información |
|---|---|
| Nombre | Unified Inventory (`unified_inventory`) |
| Función | Inventario con búsqueda, **guía de recetas**, hogar, protección |
| URL | <https://content.luanti.org/packages/?q=unified+inventory> · <https://github.com/minetest-mods/unified_inventory> |
| Licencia | **LGPL-2.1+** (código, `LICENSE.txt`) |
| Última actualización | 2026-08-23 |
| Versión investigada | HEAD |
| Dependencias | opcionales `default`, `creative`, `sfinv`, `datastorage`; `min_minetest_version = 5.4.0` |
| Juego base compatible | Minetest Game (usa `sfinv`/`default`) |
| Multijugador | Sí |
| Estado | Activo |
| Conflictos | Sustituye el inventario del juego; en Mineclonia **no aplica** (ya tiene el suyo) |
| Configuración sin programar | `minetest.conf` de la UI |
| Código reutilizable | Guía de recetas |
| Recomendación | **Instalar solo en MTG** |

### Ficha 9 — inventory_pouches

| Campo | Información |
|---|---|
| Nombre | Inventory Pouches (`inventory_pouches`) |
| Función | Mochilas portátiles (+27 espacios) |
| URL | <https://content.luanti.org/packages/?q=inventory_pouches> · <https://github.com/JamesClarke7283/inventory_pouches> |
| Licencia | **no detectada por la API** (revisar `LICENSE` a mano) |
| Última actualización | 2026-06-29 |
| Versión investigada | HEAD |
| Dependencias | ninguna declarada en la API |
| Juego base compatible | **declara Minetest Game y MineClone2** |
| Multijugador | No verificado |
| Estado | Activo |
| Conflictos | Posible solapamiento con el inventario del juego |
| Configuración sin programar | Tamaño de la mochila |
| Código reutilizable | Patrón de inventario extra por jugador |
| Recomendación | **Probar**; resolver licencia antes de distribuir |

### Ficha 10 — mob_core

| Campo | Información |
|---|---|
| Nombre | Mob Core (`mob_core`) |
| Función | API de mobs moderna sobre `mobkit`, con pathfinding y utilidades |
| URL | <https://content.luanti.org/packages/?q=mob+core> · <https://github.com/ElCeejo/mob_core> |
| Licencia | **GPL-3.0** |
| Última actualización | 2022-01-04 |
| Versión investigada | HEAD |
| Dependencias | `mobkit` |
| Juego base compatible | MTG (y otros que tengan `default`) |
| Multijugador | No verificado |
| Estado | Estancado (2022) |
| Conflictos | No mezclar con `mobs_redo` |
| Configuración sin programar | Poca |
| Código reutilizable | IA/pathfinding (GPL-3.0, compatible con Linde si Linde es GPL) |
| Recomendación | **Descartar** salvo necesidad concreta de pathfinding |

---

## 5.J Tabla de licencias: lo que **no** se puede empaquetar sin permiso

Hallazgo relevante para la distribución: varios mods populares **no declaran licencia**. Sin
licencia, el código está «todos los derechos reservados» y **no se puede redistribuir** dentro de un
ZIP de Linde, aunque se pueda probar localmente.

| Paquete | Licencia | ¿Redistribuible en Linde? |
|---|---|---|
| `skinsdb` | sin licencia declarada | ❌ pedir permiso |
| `stamina` | sin licencia declarada | ❌ |
| `mg_villages` | sin licencia declarada | ❌ |
| `hudbars`, `hbhunger` | sin licencia declarada | ❌ |
| `ethereal_bosses` | sin licencia declarada | ❌ |
| `inventory_pouches` | sin licencia detectada | ⚠️ revisar antes |
| `quests_api` | sin licencia declarada | ❌ |
| `rangedweapons` | CC BY-SA 4.0 (medios); código sin declarar | ⚠️ |
| `mobs_redo`, `mobs_monster`, `mobs_npc`, `ethereal`, `farming` | **MIT** | ✅ |
| `moreores`, `moreblocks` | **Zlib** | ✅ |
| `3d_armor`, `areas`, `unified_inventory`, `easyvend`, `toolranks` | **LGPL-2.1** | ✅ (con aviso y código disponible) |
| `travelnet`, `cottages`, `mob_core` | **GPL-3.0** | ✅ si Linde es GPL-3.0 |
| `caverealms_lite` | BSD | ✅ |
| Mineclonia, VoxeLibre | **GPL-3.0** | ✅ si Linde es GPL-3.0 |

**Regla para el proyecto:** ningún paquete entra al modpack de distribución sin una licencia
explícita. Los que no la tengan se usan solo en pruebas locales, o se sustituyen.
