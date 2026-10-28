# §7. Arquitecturas y modpack de Linde (entregables C y D)

**Fecha: 2026-10-28.** Versiones exactas; ver [`anexos/mods_pin.sh`](anexos/mods_pin.sh) para la
descarga reproducible.

Un hallazgo estructural cambia la forma de este capítulo:

> **Con Mineclonia como base, el «modpack» es diminuto**, porque el juego *ya es* un modpack de 219
> mods. Con Minetest Game como base, el modpack es de 20 piezas y no está probado. Esa asimetría es
> el argumento más fuerte a favor de Mineclonia.

---

## 7.1 Arquitectura A — Mínima (jugable hoy, cero código)

**Objetivo:** demostrar la visión en una tarde. Supervivencia, minerales, fabricación, armas,
armaduras, enemigos, mazmorras, jefes, multijugador.

| Componente | Versión | Origen | Licencia | Notas |
|---|---|---|---|---|
| Luanti | **5.17.0** | <https://github.com/luanti-org/luanti/releases/tag/5.17.0> | LGPL-2.1+ / CC BY-SA 3.0 | Binarios Windows, macOS arm64, Android |
| Mineclonia | **0.124.1** | <https://codeberg.org/mineclonia/mineclonia> | GPL-3.0 | 219 mods internos |
| `inventory_pouches` (opcional) | HEAD 2026-06-29 | <https://github.com/JamesClarke7283/inventory_pouches> | sin licencia detectada | Solo para probar mochilas |

**Dependencias:** ninguna externa. Mineclonia exige Luanti ≥ 5.10.

**Qué cubre de la visión:** mundo abierto, biomas, cuevas, minerales, mazmorras, fortalezas,
aldeas, comercio, armas, armaduras, encantamientos, enemigos, jefes, Nether, pieles, HUD,
multijugador, persistencia, construcción, agricultura.

**Qué **no** cubre:** profesiones, niveles, requisitos, fabricación modular, misiones, clases.

**Riesgos:** bajos. El único riesgo real es la configuración inicial (dificultad, `enable_damage`,
`max_users`) y que el mundo quede con las estructuras que trae Mineclonia.

**Trabajo necesario:** descargar, descomprimir, crear mundo, ajustar `minetest.conf`. **Sin código.**

**Criterio de aceptación:** dos jugadores entran, exploran, encuentran una mazmorra, matan un mob,
craftean una espada de hierro, cierran el servidor y al reabrir conservan inventario y posición.

---

## 7.2 Arquitectura B — RPG completo (arquitectura objetivo)

**Objetivo:** la visión de Linde con el mínimo código propio.

| Componente | Versión | Licencia | Papel |
|---|---|---|---|
| Luanti | 5.17.0 | LGPL-2.1+ | Motor |
| Mineclonia | 0.124.1 | GPL-3.0 | Mundo, estructuras, mobs, jefes, armaduras, aldeas |
| `moreores` | HEAD 2025-03-15 | Zlib | Materiales extra (plata, estaño, zinc, mithril) |
| `inventory_pouches` | 2026-06-29 | ⚠️ sin licencia | Mochilas (si se aclara la licencia) |
| **`linde_core`** | 0.1.0 (propio) | GPL-3.0 (coherente con la base) | **Profesiones, XP, requisitos, fabricación modular** |
| `linde_assets` | 0.1.0 (propio) | CC BY-SA 4.0 | Texturas, nombres, iconos, menús |

**Dependencias exactas:** `linde_core` → `mcl_core`, `mcl_items`, `mcl_armor`, `mcl_mobs`,
`mcl_bossbars`, `mcl_skins`, `mcl_formspec` (todas internas de Mineclonia). Opcional `moreores`.

**Compatibilidad:** `moreores` declara soporte para `mineclonia` en su `mod.conf` [V], pero la
duplicación de cobre/estaño **no está probada** [P]. `inventory_pouches` declara soporte MineClone2
[V]; Mineclonia no está listado → **probar**.

**Riesgos:**

| Riesgo | Impacto | Mitigación |
|---|---|---|
| `linde_core` debe interceptar `can_dig`, `on_use` y `on_punchplayer` | Medio | Prueba técnica §14 antes de escribir contenido |
| Actualizar Mineclonia rompe overrides | Alto | Fijar versión; correr pruebas tras cada actualización |
| GPL-3.0 obliga a publicar el código | Legal | Asumido: Linde será abierto |
| Sin misiones | Producto | Aceptado por el propio diseño del proyecto |

**Trabajo necesario:** descargar (horas) + `linde_core` (2–4 semanas) + datos y arte (2–6 semanas).

**Criterio de aceptación:** un jugador nuevo recibe nivel 1 en 4 profesiones, sube minería a 5
minando, al llegar a minería 20 puede extraer mithril, fabrica una armadura con estadísticas según
material, y todo persiste tras reiniciar.

---

## 7.3 Arquitectura C — Linde personalizado: qué exige código propio

Partiendo de B, esto es **exactamente** lo que no se puede resolver con configuración.

| Función | ¿Existe? | Decisión | Tamaño estimado |
|---|---|---|---|
| XP por minar/talar/fabricar/combatir/pescar | Concepto en `myprogress` (MTG) | **Escribir** en `linde_core` | 150–250 líneas |
| Niveles por profesión + curva | Ídem | **Escribir** (datos en JSON→Lua) | 100 líneas |
| Persistencia por jugador | `player:get_meta` | **Escribir** (trivial) | 40 líneas |
| Requisito para extraer mineral | `groupcaps.level` + `can_dig` | **Escribir** política | 120 líneas |
| Requisito para usar arma/armadura | `register_on_punchplayer`, overrides | **Escribir** | 100 líneas |
| Fabricación modular por material | **No existe** | **Escribir** estación + datos | 300–500 líneas |
| Bonos de set / variantes / joyas | **No existe** | **Escribir** (datos ya diseñados) | 200 líneas |
| Barra de XP y panel de profesiones | HUD + formspec del motor | **Escribir** UI | 150 líneas |
| Desbloqueo global por jefe | `on_death` + `mod_storage` | **Escribir** | 50 líneas |
| Jefes | `mcl_mobs` + `mcl_bossbars` | **Configurar/registrar**, no programar IA | 100 líneas de registro |
| Misiones | Solo API sin licencia | **No hacer en v1** | — |
| Magia | No existe | **No hacer en v1** | — |
| Aldeas, comercio, mazmorras, armaduras base | Mineclonia | **No tocar** | 0 |
| Multijugador, persistencia, mundo | Luanti | **No tocar** | 0 |

**Total estimado de `linde_core`: 1.300–1.900 líneas de Lua**, de las cuales la mitad son tablas
de datos. Es un mod, no un juego.

### Estructura propuesta de `linde_core`

```
games/linde/mods/linde_core/
├── mod.conf                  name=linde_core, depends=mcl_core,mcl_mobs,mcl_armor
├── init.lua                  carga ordenada + API pública: linde.skills.*
├── api/
│   ├── skills.lua            XP, niveles, curva, persistencia
│   ├── requirements.lua      can_dig, on_use, on_punchplayer, mensajes
│   ├── materials.lua         tabla material → dureza/tenacidad/densidad
│   ├── crafting.lua          estación modular (formspec) + cálculo de stats
│   ├── sets.lua              bonos de set, variantes, joyas
│   └── bosses.lua            recompensas y flags globales
├── ui/
│   ├── hud.lua               barra de XP
│   └── panel.lua             formspec de profesiones
├── data/
│   ├── skills.lua            ← migrado de saberes_v1.json / reglas_v1.json
│   ├── materials.lua         ← migrado de reglas_v1.json
│   ├── familias.lua          ← migrado de familias.json + arquetipos.json
│   └── variantes.lua         ← migrado de variantes.json + joyas.json
└── texturas/                 linde_* (propias)
```

### Los tres patrones técnicos que hay que validar (§14)

1. **Bloquear extracción según nivel:** `minetest.override_item(nodename, {can_dig = function(pos, player) ... end})`
   sobre los minerales. *Riesgo:* `can_dig` no recibe el ítem usado; hay que leer
   `player:get_wielded_item()`. **Alternativa:** interceptar en `register_on_dignode` y devolver el
   nodo (feo). **Decisión:** probar `can_dig` primero.
2. **Escalar el daño del arma según nivel:** `minetest.register_on_punchplayer(player, hitter, ...)`
   permite **cancelar** el golpe (`return true`) y aplicar daño propio con
   `player:punch(hitter, 1.0, {damage_groups=...})`. *Riesgo:* doble daño si se olvida el `return`.
3. **Fabricación modular:** estación propia con formspec que lee los materiales del inventario y
   crea un ítem con metadata (`linde:material`, `linde:calidad`), leyendo los stats de una tabla.
   Es lo que el prototipo Godot ya hace en `artesania.gd`; se porta el concepto, no el código.

---

## 7.4 Arquitectura D — Contingencia sin código (Minetest Game + 20 mods)

Se documenta porque responde a la pregunta «¿y si no queremos escribir nada?». **No se recomienda**:
el juego base está congelado y la integración no está probada.

| # | Mod | Versión/commit | Licencia | Dependencias |
|---|---|---|---|---|
| 1 | `mobs_redo` | 2026-10-27 | MIT | — |
| 2 | `mobs_monster` | 2026-10-25 | MIT | `mobs` |
| 3 | `mobs_animal` | 2026-10-25 | MIT | `mobs` |
| 4 | `mobs_npc` | 2026-10-25 | MIT | `mobs` |
| 5 | `ethereal` | 2026-10-23 | MIT | `default` |
| 6 | `ethereal_bosses` | 2024-09-24 | ❌ sin licencia | `mobs`, `ethereal` |
| 7 | `moreores` | 2025-03-15 | Zlib | `default` |
| 8 | `3d_armor` | 2026-07-20 | LGPL-2.1 | `player_api` |
| 9 | `toolranks` | 2023-11-18 | LGPL-2.1 | `default` |
| 10 | `myprogress` | 2025-12-24 [C] | ❓ | `default` |
| 11 | `caverealms_lite` | 2026-07-27 | BSD | `default` |
| 12 | `mg_villages` | 2023-08-26 | ❌ sin licencia | `mg` |
| 13 | `cottages` | 2026-01-02 | GPL-3.0 | `default` |
| 14 | `easyvend` | 2023-04-16 | LGPL-2.1 | `default` |
| 15 | `stamina` | 2025-03-26 | ❌ sin licencia | `default` |
| 16 | `unified_inventory` | 2026-08-23 | LGPL-2.1+ | `default` |
| 17 | `areas` | 2026-09-19 | LGPL-2.1 | — |
| 18 | `travelnet` | 2023-01-09 | GPL-3.0 | `default` |
| 19 | `hudbars` + `hbhunger` | 2026-04-01 | ❌ sin licencia | `default` |
| 20 | `inventory_pouches` | 2026-06-29 | ❓ | — |

**Riesgos:** seis paquetes sin licencia (no distribuibles), `myprogress` sin repositorio
localizable, MTG congelado, `mg_villages` de 2023 y dependiente del mapgen `mg`, y **ninguna prueba
de que estos 20 mods convivan**: `myprogress` y `toolranks` ambos escuchan el minado; `stamina` y
`hudbars` compiten por el HUD; `3d_armor` y `mobs_monster` comparten daño. Es exactamente el
«mod soup» que la documentación de Luanti advierte.

**Cuándo tendría sentido:** solo si el requisito «cero líneas de código» fuera absoluto. En ese
caso, además, habría que aceptar que Linde no tendría requisitos por nivel (el corazón del diseño
RPG del proyecto).

---

## 7.5 Entregable C — Modpack recomendado, dependencia por dependencia

```yaml
# linde 0.1.0 — modpack objetivo
engine:
  luanti: "5.17.0"

game:
  name: mineclonia
  version: "0.124.1"
  source: https://codeberg.org/mineclonia/mineclonia
  commit: "7410cf18a231b4dd094bd90dc534951ef17b4275"   # 'bump version to 0.124.1', 2026-10-22
  license: GPL-3.0

mods:
  - name: moreores
    source: https://github.com/minetest-mods/moreores
    ref: HEAD-2025-03-15
    license: Zlib
    role: materiales extra
    state: por-probar

  - name: inventory_pouches
    source: https://github.com/JamesClarke7283/inventory_pouches
    ref: HEAD-2026-06-29
    license: SIN-LICENCIA
    role: mochilas
    state: bloqueado-hasta-aclarar-licencia

  - name: linde_core
    source: propio
    license: GPL-3.0
    depends: [mcl_core, mcl_items, mcl_armor, mcl_mobs, mcl_bossbars, mcl_skins, mcl_formspec]
    role: profesiones, requisitos, fabricación modular, sets, jefes
    state: a-desarrollar

  - name: linde_assets
    source: propio
    license: CC-BY-SA-4.0
    role: texturas, iconos, nombres, menú
    state: a-desarrollar
```

**Dependencias que no son mods:** `mcl_*` están dentro de Mineclonia; no se descargan aparte. No se
requiere ningún paquete de `player_api`, `default`, `sfinv` ni `hudbars`.

**Regla de oro del modpack:** **no se añade un mod a este archivo sin (a) licencia explícita y
(b) una prueba registrada de que funciona en Mineclonia.**

---

## 7.6 Entregable D — Arquitectura técnica y estructura del proyecto

### Decisión clave: cómo convive Linde con Mineclonia

No se puede «depender» de un juego desde otro juego en Luanti: un juego es una carpeta
autocontenida. Hay tres formas y **elegimos la tercera**:

| Opción | Cómo | Ventaja | Inconveniente |
|---|---|---|---|
| A. Fork de Mineclonia como `games/linde` | Copiar el repo y editar dentro | Control total | Actualizar duele; deriva inevitable |
| B. Mineclonia como juego + mods en `worlds/<mundo>/worldmods/` | Los mods de Linde viven en el mundo | **Actualizar Mineclonia es gratis**; nada se pierde | No es un «juego» distribuible como tal |
| **C. Híbrido (elegido)** | **Desarrollo en B**; **distribución con un script** que arma `games/linde/` = Mineclonia fijada + `linde_core` + `linde_assets` + `game.conf` propio | Desarrollo ágil **y** juego propio distribuible | Un script de empaquetado que hay que mantener |

### Estructura del repositorio

```
Linde/
├── luanti/                         # NO se versiona: motor descargado
│   ├── bin/luanti, luantiserver
│   ├── games/mineclonia/           # dependencia fijada (git clone + checkout)
│   └── worlds/linde/               # mundo de la beta (respaldado, no versionado)
├── juego/                          # SÍ se versiona: lo nuestro
│   ├── mods/
│   │   ├── linde_core/
│   │   └── linde_assets/
│   ├── game.conf                   # title = Linde RPG
│   ├── menu/                       # icono y cabecera propios
│   └── minetest.conf               # ajustes del juego
├── servidor/
│   ├── minetest.conf               # puerto, max_users, difficulty
│   ├── arrancar.sh / arrancar.bat
│   ├── respaldos/                  # fuera de git
│   └── systemd/linde.service
├── herramientas/
│   ├── empaquetar.sh               # arma games/linde desde mods fijados
│   ├── descargar_mods.sh           # ver anexos/mods_pin.sh
│   └── probar.sh                   # arranca servidor de prueba headless
└── docs/investigacion/luanti/      # este informe
```

**Qué se versiona y qué no:** se versiona `juego/`, `servidor/*.conf`, `herramientas/` y `docs/`.
No se versionan `luanti/` (motor), `luanti/worlds/` (mundo, pesa y cambia), `respaldos/` ni los
repos clonados de terceros. El `.gitignore` del proyecto ya excluye artefactos; hay que añadir
`luanti/` y `servidor/respaldos/`.

### Flujo de trabajo con terceros (respetando licencias)

1. Cada mod de terceros se clona en `luanti/games/mineclonia/mods/` (o `worldmods/`) **en un commit
   fijado**; nunca se edita en sitio.
2. Si hay que cambiar algo de un mod ajeno, se hace un **fork propio** con el aviso de copyright
   original intacto y se documenta el cambio (obligatorio en LGPL y GPL).
3. Los avisos de licencia de todos los paquetes se copian a `licencias/` del proyecto, que ya
   existe con esa convención.
4. `herramientas/empaquetar.sh` reconstruye el juego desde cero: si el ZIP de Linde se puede
   reconstruir desde el repositorio, la distribución es reproducible.
