# §3. El motor Luanti: qué resuelve y qué no

**Verificado el 2026-10-28.** Fuentes: [documentación oficial](https://docs.luanti.org/),
[repositorio del motor](https://github.com/luanti-org/luanti) (13.779 ★, último push
2026-10-25), [`minetest.conf.example`](https://github.com/luanti-org/luanti/blob/master/minetest.conf.example).

## 3.0 Versión y licencia [V]

| Dato | Valor |
|---|---|
| Nombre actual | **Luanti** (renombrado desde Minetest en 2024) |
| Última versión estable | **5.17.0**, publicada 2026-08-20 |
| Última versión de prueba | **5.18.0-rc1**, 2026-10-18 |
| Repositorio | <https://github.com/luanti-org/luanti> (espejo; upstream en GitHub) |
| Licencia del código | **LGPL-2.1-or-later** (`COPYING.LESSER`) |
| Licencia de medios del motor | **CC BY-SA 3.0** (`LICENSE.txt`) |
| Binarios oficiales 5.17.0 | Windows x64/x86 ZIP, instalador `.exe`, **macOS 12.3 arm64** y x86_64, Android (4 APK) |
| Requisito del juego base | Mineclonia exige **Luanti ≥ 5.10**; VoxeLibre, ≥ 5.10 |

**Consecuencia para Linde:** el motor se distribuye tal cual, sin modificarlo. La licencia LGPL
del motor permite distribuir Linde como juego propio sobre él, incluso con componentes de
licencia distinta, siempre que se respeten las licencias de los juegos y mods usados (GPL-3.0
en el caso de Mineclonia: ver §2.3 de `02_juegos_base.md`).

---

## 3.1 Generación procedural y semillas [V]

- Cada mundo tiene una **semilla** (`seed`) almacenada en `map_meta.txt`; el mismo juego con la
  misma semilla genera el mismo terreno. Mineclonia declara un generador propio en Lua
  «compatible con semillas de Minecraft».
- Los generadores incluidos en el motor son `v5`, `v6`, `v7`, `valleys`, `carpathian`, `flat`,
  `fractal` y `singlenode` (este último para que un juego genere todo por Lua).
- Mineclonia y VoxeLibre **deshabilitan `v6`** (`disallowed_mapgens = v6` en su `game.conf`) y usan
  generación por Lua sobre `singlenode`.
- El juego declara sus biomas con `minetest.register_biome`, sus minerales con
  `minetest.register_ore`, su decoración con `minetest.register_decoration` y sus estructuras
  con esquemáticos (`.mts`) y `minetest.place_schematic`.

**Lo que esto significa para Linde:** la generación procedural del mundo es **gratis**. No hay que
escribir un generador. Si se quiere una región o un bioma propio, se añade un mod que registre un
bioma y sus minerales; no se toca el motor.

## 3.2 Tamaño y límites del mundo [V]

Texto oficial de [World Boundaries](https://docs.luanti.org/for-players/world-boundaries/):

> «Luanti's world is a huge cube with a side length of ca. 60000 nodes and the dimensions (X, Y
> and Z) ranges from −30912 to 30927 by default.»

Y la página [About Luanti](https://docs.luanti.org/about/luanti/) habla de **61.840 nodos por
dimensión**. Es un mundo finito pero prácticamente inagotable para 5–10 jugadores.

- El límite se ajusta con el *setting* de mapa `mapgen_limit` (guardado en `map_meta.txt` del
  mundo), redondeado al *mapchunk*, y solo afecta a la generación nueva.
- Hay un límite vertical práctico por el costo de generación y de memoria, no por el motor.

**Consecuencia para Linde:** no hace falta «mundo infinito». Un mundo de 5.000 × 5.000 nodos ya
excede lo que 10 jugadores explorarán en meses, y limita el tamaño del respaldo (ver §9.6).

## 3.3 Chunks y generación diferida [V]

- El mundo se guarda y genera en **bloques de mapa** (*mapblocks*) de **16 × 16 × 16 nodos**; el
  jugador ve la generación por proximidad.
- Parámetros verificados en `minetest.conf.example`:

| Ajuste | Valor por defecto | Efecto |
|---|---|---|
| `max_block_generate_distance` | `10` | Radio (en mapblocks) de generación alrededor del jugador |
| `active_block_range` | `4` | Radio de bloques «activos» (ABM, entidades) alrededor del jugador |
| `max_forceloaded_blocks` | `16` | Bloques que un mod puede mantener cargados (útil para granjas/jefes) |
| `server_map_save_interval` | `5.3` s | Frecuencia de guardado del mapa |

**Consecuencia para Linde:** la generación diferida es un hecho del motor; el costo real está en
cuántos mods de generación se añaden (ver §10). Las estructuras grandes consumen más generación
inicial pero no más RAM permanente, salvo que se fuercen cargas.

## 3.4 Biomas, estructuras y minerales [V]

| Elemento | ¿Motor? | ¿Juego base? | ¿Mod? |
|---|---|---|---|
| Biomas | API de registro (`register_biome`) | Mineclonia trae decenas de biomas | `ethereal` añade más (solo MTG) |
| Minerales | API de registro (`register_ore`) | Mineclonia: carbón, hierro, cobre, oro, redstone, lapislázuli, diamante, esmeralda, netherita… | `moreores` añade plata, estaño, zinc, mithril |
| Cuevas | Algoritmos del generador | Mineclonia: cuevas, *lush caves*, *deep dark* | `caverealms_lite` (cavernas gigantes, MTG) |
| Mazmorras | Esquemáticos + `place_schematic` | **Mineclonia: `mcl_dungeons`** | — |
| Fortalezas / ciudades del End / ruinas del Nether | Esquemáticos | **Mineclonia: `mcl_strongholds`, `mcl_nether_fortresses`, `ancient hermitage`** | — |
| Aldeas | Esquemáticos + entidades | **Mineclonia: `mcl_villages`** | `mg_villages`, `cottages` (MTG) |

Un detalle importante que suele confundirse: **Minetest Game también genera mazmorras** (el
`mapgen.lua` de su mod `default` contiene 124 referencias a `dungeon`, con salas de adoquín,
ladrillo musgoso y cofres). Lo que Minetest Game **no** trae es nada que las habite: su propio
README dice «no built-in enemy mobs».

## 3.5 Persistencia del mundo y de los jugadores [V]

- El mundo es un directorio con `map.sqlite` (o PostgreSQL/Redis si se configura), `players.sqlite`,
  `map_meta.txt`, `world.mt` y los datos de mods (`mod_storage.sqlite`).
- La API expone tres niveles de persistencia:
  1. **Metadata de jugador**: `player:get_meta():set_string(...)` → sobrevive a reconexiones.
  2. **Almacenamiento de mod**: `minetest.get_mod_storage()` → persiste por mundo.
  3. **Nodos y entidades**: el propio mundo guarda el estado de las entidades estáticas.
- El guardado es automático cada `server_map_save_interval` (5,3 s por defecto) y al apagar.
- `enable_rollback_recording = true` activa el registro de acciones por jugador (verificado en la
  [guía de servidor](https://docs.luanti.org/for-server-hosts/setup/)), útil contra griefing.

**Consecuencia para Linde:** la persistencia de mundo y jugadores es gratis. Lo que hay que
diseñar es **qué** se guarda de la capa RPG (niveles, XP, profesiones): se hace con
`player:get_meta()` y `mod_storage`, no con base de datos externa.

## 3.6 Inventarios y fabricación [V]

- El motor no impone un inventario concreto: da `player:get_inventory()`, listas, pilas, y
  `minetest.register_craft` / `register_craftitem` / `register_tool` / `register_node`.
- **La fabricación es del juego o del mod.** Mineclonia implementa mesa de trabajo, horno,
  yunque, mesa de herrería, encantamientos, recetas con formas y sin forma.
- La *receta* es código declarativo en Lua: añadir recetas **no requiere programar lógica**, solo
  declarar tablas.
- **La fabricación modular real (que el resultado dependa de los materiales) no existe en el
  motor.** Se implementa con `register_craft` dinámico o con un ítem que se transforma al
  fabricarse. Ver §5.C y §7.3.

## 3.7 Entidades, criaturas y comportamiento [V]

- `minetest.register_entity` da una entidad con modelo, texturas, animaciones, colisión,
  física (`object:set_velocity`), vida (`object:set_hp`), grupos de armadura
  (`object:set_armor_groups`) y `on_punch`/`on_rightclick`.
- La IA **no** viene en el motor: viene en APIs de mobs. En el ecosistema hay tres familias:
  - **`mobs_redo`** (TenPlus1, MIT): la más usada en Minetest Game; `mobs_monster`, `mobs_animal`,
    `mobs_npc`, `mobs_water` cuelgan de ella.
  - **`mobkit` / `mob_core`** (ElCeejo, GPL-3.0): API más moderna para mobs con pathfinding.
  - **`mobs_mc` / `mcl_mobs`** de Mineclonia y VoxeLibre: la propia del juego, con pathfinding
    reescrito según Mineclonia.

**Consecuencia para Linde:** no se escribe IA. Los jefes se hacen con la API de mobs del juego
base más un `on_death` que da recompensa y una barra (`mcl_bossbars` ya existe en Mineclonia).

## 3.8 Combate, daño, armaduras y estadísticas [V]

| Capacidad | Dónde vive |
|---|---|
| Vida, daño, `punch`, knockback | **Motor** (`object:punch`, `on_punchplayer`) |
| Grupos de armadura (`fleshy`, `crumbly`…) | **Motor** (`set_armor_groups`) |
| Reducción de daño por armadura equipada | **Mod** (`3d_armor` en MTG; `mcl_armor` en Mineclonia) |
| Armas con daño y durabilidad | **Juego base** (`register_tool` con `tool_capabilities.damage_groups`) |
| Niveles de minería (qué pico rompe qué) | **Motor**: `groupcaps` con `level` y `max_drop_level` |
| Estadísticas RPG (fuerza, defensa, crítico) | **Nada**: es la capa que hay que escribir |
| Estados alterados (veneno, fuego, lentitud) | Parcial en Mineclonia (`mcl_potions`); no genérico |

El punto clave, y el que hace viable `linde_core`: **`groupcaps` con `level` es exactamente el
mecanismo que Project MMO usa para bloquear minerales**, y en Luanti ya está en el motor. Un mod
puede, al equipar una herramienta, modificar su `groupcaps` según el nivel del jugador: no hace
falta inventar un sistema de bloqueo.

## 3.9 API de mods en Lua [V]

- Todos los juegos y mods se escriben en **Lua 5.1 / LuaJIT**; no hay compilación ni toolchain.
  Un mod es una carpeta con `mod.conf`, `init.lua` y recursos.
- El motor expone más de 300 funciones: registro de nodos, ítems, herramientas, entidades, biomas,
  minerales, esquemáticos, recetas, comandos, privilegios, HUD, *formspec*, temporizadores (`after`,
  `globalstep`), almacenamiento y hooks de eventos (`on_dignode`, `on_placenode`, `on_craft`,
  `on_punchplayer`, `on_joinplayer`, `on_dieplayer`, `on_player_hpchange`, `on_mods_loaded`).
- **Todos los hooks que `linde_core` necesita existen.** En concreto: `register_on_dignode` (XP de
  minería y verificación de requisito), `register_on_craft` (XP de fabricación),
  `register_on_punchplayer` (XP de combate y armadura), `register_on_joinplayer` (cargar nivel),
  `on_use` de herramientas (bloquear uso por nivel).

## 3.10 Interfaz gráfica y menús [V]

- **Formspec**: lenguaje declarativo de formularios (versión actual 6) para menús, inventarios,
  diálogos de NPC, tiendas y pantallas de personaje. Se define con una cadena de texto; no hay que
  dibujar nada.
- HUD: `player:hud_add` permite barras, textos e imágenes por jugador. Mineclonia ya usa
  `hudbars` para vida, hambre y aire, y `mcl_bossbars` para jefes.
- **Consecuencia:** una barra de XP y un panel de profesiones se hacen **sin modificar el motor**,
  con un formspec y un HUD. El límite es estético, no técnico.

## 3.11 Animaciones y modelos de personaje [V]

- El motor soporta modelos **`.b3d`, `.obj` y `.gltf`**, con animaciones por hueso, y los envía al
  cliente como *media*.
- El jugador es una entidad especial: su malla se define en el juego con
  `player_api`/`mcl_player`, y la animación de caminar/atacar se controla por código.
- Librerías verificadas: [`PlayerAnimationLibrary`](https://github.com/PlayerAnimationLibrary/PlayerAnimationLibrary)
  (MIT, push 2026-10-25) y [`minetest-mods/playeranim`](https://github.com/minetest-mods/playeranim)
  (BSD-2-Clause, 2025-02-21).
- **Armadura visible**: `3d_armor` (LGPL-2.1, incluye `wieldview` y `shields`) lo hace en MTG;
  Mineclonia trae armadura visible propia (`mcl_armor`).
- **Pieles**: `skinsdb` (MTG, sin licencia declarada) o `mcl_skins` (Mineclonia, GPL-3.0).

**Consecuencia para Linde:** personalización de personaje sin tocar el motor es posible: skins +
armadura visible + modelos `.b3d` propios. El arte del prototipo Godot (hojas de personaje y
equipo) **no es directamente usable** como malla 3D: son sprites 2D. Ver §11.4.

## 3.12 Servidores dedicados [V]

- Binario `luantiserver` (headless) en Linux; `luanti.exe --server` en Windows; `luanti --server`
  en macOS.
- **Desde 5.8.0 el motor no incluye juego por defecto**; hay que poner un juego en `games/`.
- Puerto **30000/UDP** por defecto; `max_users = 15` por defecto.
- El servidor es **autoritativo**: el cliente no simula el mundo, solo lo dibuja. Es la propiedad
  que hace que Luanti sea confiable para un servidor privado de amigos.

## 3.13 Sincronización multijugador [V]

- El servidor envía al cliente los nodos, las entidades, las definiciones de ítems y **todos los
  recursos** (texturas, sonidos, modelos) por *media*; si hay mucho, se puede servir por HTTP con
  `remote_media` ([guía oficial](https://docs.luanti.org/for-server-hosts/remote-media/)).
- **El cliente no necesita tener el juego instalado.** Esto es determinante para Linde: los amigos
  instalan Luanti y se conectan; no instalan mods.
- Los *client-side mods* existen pero están restringidos y no son la vía para contenido de juego.
- La sincronización de entidades y jugadores está resuelta; los problemas aparecen con mal
  `active_block_range` o con mods que asumen un solo jugador (ver §5.E y §10).

## 3.14 Rendimiento y límites prácticos [V]

La documentación oficial da una referencia explícita **para ~10 jugadores**:

| Recurso | Recomendación oficial |
|---|---|
| CPU | ≥ 2 núcleos (preferible 4), **mucha frecuencia por núcleo**: Luanti es en gran medida monohilo |
| RAM | 4 GB «debería ser suficiente»; escalar con juegos pesados como Mineclonia/VoxeLibre |
| Disco | 30 GB SSD/NVMe, crece con la exploración; se puede limitar con `mapgen_limit` |
| Red | 20 Mbps |

Es la única cifra de rendimiento oficial y no es un *benchmark*: es una recomendación de
dimensionamiento. No existen *benchmarks* publicados de Mineclonia con 10 jugadores que hayamos
podido verificar; §10 propone cómo medirlo en lugar de inventarlo.

## 3.15 Compatibilidad entre versiones [V]

- Luanti sigue versiones 5.x; los juegos declaran `min_minetest_version`. Mineclonia exige ≥ 5.10.
- Los mods declaran `min_minetest_version` en `mod.conf`; por ejemplo `unified_inventory` exige
  5.4.0, `areas` 5.0, `rangedweapons` 5.8, `3d_armor` 5.4.
- **Los mundos se pueden migrar hacia adelante**, no hacia atrás. Actualizar el motor con un mundo
  viejo es seguro; volver a una versión anterior con un mundo ya migrado, no.
- Los mods **no declaran un rango máximo**, así que la compatibilidad con 5.17 hay que probarla,
  no suponerla: es el riesgo R2 de §7 del plan.

## 3.16 Distribuir un juego propio basado en Luanti [V]

Sí. Un «juego» de Luanti es una carpeta en `games/` con `game.conf` y un `mods/` (o `worldmods/`
por mundo). Se puede:

- Distribuir el juego como **ZIP** para que se descomprima en `games/`.
- Publicarlo en **ContentDB** (cuando vuelva) como paquete tipo `game`.
- Distribuirlo **fuera de ContentDB** ([guía oficial para creadores](https://docs.luanti.org/for-creators/)).
- No se puede (ni conviene) empaquetar el motor dentro del juego: el motor se instala aparte.

---

## 3.17 Motor vs. juego base vs. mod: la tabla que evita confusiones

| Función de Linde | Motor | Juego base (Mineclonia) | Mod |
|---|---|---|---|
| Mundo procedural, semilla, chunks | ✅ | ✅ (generador propio) | — |
| Biomas, minerales, cuevas | API | ✅ | amplía (`moreores`, `ethereal`) |
| Mazmorras, fortalezas, aldeas | API de esquemáticos | ✅ | amplía (`mg_villages`) |
| Inventario, fabricación | API | ✅ | amplía |
| Combate, daño, vida | ✅ | ✅ | amplía (armas nuevas) |
| Armadura equipable y visible | ❌ | ✅ (`mcl_armor`) | `3d_armor` (MTG) |
| Criaturas y enemigos | ❌ (solo entidades) | ✅ (`mobs_mc`) | `mobs_redo` (MTG), `mob_core` |
| Jefes y barras de jefe | ❌ | ✅ (`mcl_bossbars`) | `ethereal_bosses` (MTG) |
| NPC, aldeanos, comercio | ❌ | ✅ (`mcl_villages`, aldeanos) | `mobs_npc`, `easyvend` |
| Pieles y personaje | ❌ | ✅ (`mcl_skins`) | `skinsdb` (MTG) |
| HUD y menús | ✅ (formspec/HUD) | ✅ | ✅ |
| Multijugador, persistencia, *media* | ✅ | ✅ | — |
| **Profesiones y niveles** | ❌ | ❌ | `myprogress` (solo MTG), `SkillsFramework` (API, 2015) |
| **Requisitos por nivel** | ❌ | ❌ | **nada verificado** |
| **Fabricación modular por material** | ❌ | ❌ | **nada verificado** |
| **Misiones** | ❌ | ❌ | `quests_api` (MTG, 2024, sin licencia declarada) |

Esta tabla es el resumen de la investigación: **dos filas son el trabajo real de Linde**, y las dos
están en la zona «programar», no en la zona «descargar».
