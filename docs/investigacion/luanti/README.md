# Luanti como plataforma para Linde RPG — investigación integral

**Fecha de verificación de datos: 2026-10-28.** Todos los datos de repositorios, versiones y
licencias fueron consultados ese día contra GitHub API, Codeberg, la documentación oficial de
Luanti y el blog oficial. Los datos que solo provienen de listados de ContentDB están marcados
como tales porque **ContentDB estuvo caído durante toda la investigación** (ver §0.3).

> **Alcance y honestidad metodológica.** Este documento es una investigación documental y de
> código fuente. **No se ejecutó Luanti, ni se instaló ningún juego o mod, ni se levantó un
> servidor.** Por lo tanto, ninguna afirmación de este informe constituye una prueba de
> funcionamiento: lo que está verificado es la *existencia, versión, licencia y dependencias
> declaradas* de cada pieza, no su comportamiento en partida. El protocolo para convertir cada
> afirmación en evidencia ejecutada está en [`07_plan_prueba_riesgos.md`](07_plan_prueba_riesgos.md).

---

## 0. Respuesta directa a la pregunta principal

### 0.1 ¿Podemos construir Linde RPG sobre Luanti sin desarrollar un videojuego desde cero?

**Sí, con una salvedad concreta y medible.**

Luanti entrega, ya resuelto y sin escribir código: mundo procedural de ~61.840 nodos por eje,
chunks con generación diferida, persistencia de mundo y jugadores, multijugador autoritativo,
inventarios, fabricación, minería con niveles de herramienta por grupo, combate con daño y
armaduras por grupos, entidades, API Lua completa, menús (formspec), servidor dedicado,
transferencia automática de recursos al cliente y distribución de un juego propio.

Un juego base como **Mineclonia** entrega además, ya hecho: biomas, cuevas, minerales, mazmorras,
fortalezas, aldeas con aldeanos que comercian, Nether, jefes con barra de vida, armaduras,
encantamientos, hambre, experiencia, skins, HUD y guardado multijugador. Son **219 mods** dentro
del juego, no 219 piezas a integrar.

Lo que **no existe hoy** en el ecosistema Luanti, verificado por búsqueda y no por suposición, es:

1. Un sistema de **profesiones/niveles con requisitos** (equivalente a Project MMO / LevelZ).
2. Un sistema de **fabricación modular por materiales** (equivalente a Silent Gear / Tinker's).
3. Un sistema de **misiones** maduro y mantenido para Luanti.

Eso es todo el código propio que Linde necesita para su capa RPG, y es **una cantidad acotada**:
un mod (`linde_core`) de aproximadamente 700–1.400 líneas de Lua para los puntos 1 y 2, más
contenido de datos. El punto 3 es opcional en la primera versión (así lo definió el propio
proyecto: la narrativa y las misiones no son requisito del MVP).

**Cifra honesta de reutilización:** del contenido que pide la visión de Linde (§2 del encargo),
entre el **80 % y el 90 %** se obtiene descargando software existente (motor + Mineclonia + 3–6
mods de calidad de vida). El 10–20 % restante es la capa RPG diferenciadora, y es la única que
justifica programar.

### 0.2 ¿Qué descargamos hoy, qué adaptamos y qué programamos?

| Categoría | Qué es | Esfuerzo |
|---|---|---|
| **Descargar y usar tal cual** | Luanti 5.17.0, Mineclonia 0.124.1, `inventory_pouches`, `moreores`, `skinsdb`, `areas`, `travelnet`, `mob_core` (si se usa API de mobs propia) | Horas |
| **Descargar, configurar y ajustar** | Ajustes de `minetest.conf`, balance de Mineclonia (`mcl_*` settings), nombres y textos, recursos gráficos propios, empaquetado como juego `linde` | Días |
| **Adaptar (código de terceros)** | `myprogress` (solo existe para Minetest Game), `ethereal_bosses` (sin licencia declarada), `3d_armor` (depende de `player_api`, no de `mcl`) | Días-semanas, con riesgo |
| **Programar** | `linde_core`: profesiones, XP por actividad, requisitos de uso/extracción, estadísticas por material y fabricación modular, integración con jefes y cofres | 2–4 semanas de una persona con Lua |

### 0.3 Advertencia de coyuntura: ContentDB está caído

El 2026-10-27 el equipo de Luanti publicó [«URGENT: ContentDB security incident: 22–26 October
2026»](https://blog.luanti.org/2026/10/27/contentdb-security-incident/). Un atacante obtuvo acceso
a la base de datos, secretos y *uploads* de ContentDB entre el 22 y el 26 de octubre; el servicio
se apagó el 26 a las 09:00 y el propio comunicado estima **«una semana o más»** de interrupción.
Hoy `content.luanti.org` responde «Down for maintenance».

Consecuencias prácticas, que condicionan todo el plan:

- **No se puede instalar nada desde el cliente Luanti ni desde ContentDB** mientras dure la caída.
  La vía correcta hoy es **clonar repositorios Git** (ver §8 y `anexos/mods_pin.sh`).
- El incidente **no invalida Luanti como plataforma**, pero sí demuestra que depender de un único
  repositorio central es un riesgo de proyecto. Linde debe **fijar versiones por commit** y
  mantener su propio árbol de mods, no confiar en «lo que haya hoy en ContentDB».
- Cualquier paquete descargado entre el 22 y el 26 de octubre debe compararse con el repositorio
  upstream antes de usarse (recomendación del propio comunicado).

---

## 1. Índice de la investigación

| Documento | Cubre |
|---|---|
| [`01_motor.md`](01_motor.md) | §3. Capacidades reales del motor; qué da el motor y qué debe dar un juego o un mod |
| [`02_juegos_base.md`](02_juegos_base.md) | §4 y entregable **A**. Mineclonia, VoxeLibre, Minetest Game, Repixture y otros |
| [`03_mods_catalogo.md`](03_mods_catalogo.md) | §5 y §6 y entregable **B**. Catálogo por categorías con fichas técnicas |
| [`04_arquitecturas.md`](04_arquitecturas.md) | §7 y entregables **C** y **D**. Arquitecturas A/B/C, dependencias exactas y estructura del proyecto |
| [`05_codigo_y_servidor.md`](05_codigo_y_servidor.md) | §8 y §9 y entregables **E**, **F**, **G**. Descarga de fuentes, servidor Windows/macOS/Linux, Internet, distribución |
| [`06_rendimiento_godot_comparacion.md`](06_rendimiento_godot_comparacion.md) | §10, §11 y §12 y entregables **H** e **I**. Rendimiento, reutilización del prototipo Godot, comparación con Minecraft y Godot |
| [`07_plan_prueba_riesgos.md`](07_plan_prueba_riesgos.md) | §13, §14 y entregable **K**. Plan por fases, prueba técnica mínima, riesgos y pendientes |
| [`anexos/catalogo_mods.csv`](anexos/catalogo_mods.csv) | Tabla plana del catálogo, para filtrar u ordenar |
| [`anexos/mods_pin.sh`](anexos/mods_pin.sh) | Script de descarga reproducible con commits fijados |

---

## 2. Recomendación en una página

**Juego base: Mineclonia** (0.124.1, GPL-3.0, Codeberg). Motivos, en orden de peso:

1. **Es el único juego de Luanti que hoy combina mundo, mazmorras, estructuras, aldeas con
   comercio, Nether, jefes, armaduras, encantamientos y skins** en un solo paquete mantenido
   (219 mods internos, 18.706 commits, 150 etiquetas, versión 0.124.1 del 2026-10-22).
2. **Está activo**: último commit del upstream el 2026-10-22; el espejo GitHub se actualizó el
   2026-10-27. Minetest Game, en cambio, está declarado en **«perpetual maintenance-only mode»**
   por sus propios mantenedores: no recibirá funciones nuevas.
3. **Está pensado para multijugador y rendimiento**, que es explícitamente la diferencia que
   declara frente a VoxeLibre (README de Mineclonia).
4. **Documenta su API** (`API.md`, `GROUPS.md`), lo que hace viable el mod propio de la capa RPG.

**Arquitectura objetivo:** Mineclonia + 4 mods de calidad de vida + un mod propio `linde_core`
que aporta exactamente lo que no existe: profesiones, XP, requisitos y fabricación por materiales.
Los datos de ese mod **se migran desde el prototipo Godot** (que ya tiene `familias.json`,
`arquetipos.json`, `variantes.json`, `joyas.json`, `reglas_v1.json`, `saberes_v1.json`), no se
inventan de cero.

**Arquitectura de contingencia (cero Lua):** Minetest Game + `myprogress` + `toolranks` +
`3d_armor` + `mobs_redo`/`mobs_monster` + `ethereal` + `ethereal_bosses` + `moreores` + `mg_villages`
+ `easyvend`. Da profesiones sin programar, pero sobre un juego congelado y con una integración de
mods frágil y no probada (§7.4).

**Servidor:** PC propia (Windows 11 o macOS Apple Silicon, ambos con binario oficial) con
**Tailscale** para los 5–10 amigos, sin abrir puertos. Alternativa permanente gratuita 24/7:
**Oracle Cloud Always Free** (hoy 2 OCPU / 12 GB ARM, 200 GB de disco, 10 TB de egreso), que sigue
siendo gratis de forma indefinida y sobra para 10 jugadores según los requisitos oficiales del
propio Luanti.

**Distribución a amigos:** no hay que distribuir nada. El cliente oficial de Luanti descarga del
servidor texturas, sonidos y modelos (`remote media`). Los amigos instalan Luanti 5.17.0,
escriben la dirección del servidor y juegan. Linde puede publicarse además como juego propio en un
ZIP y, cuando ContentDB vuelva, en ContentDB.

---

## 3. Conclusión explícita (entregable L)

> **Sí conviene usar Luanti como base definitiva de Linde RPG**, con dos condiciones:
>
> 1. **Aceptar GPL-3.0** en el código del juego si se deriva de Mineclonia (o VoxeLibre), porque
>    ambos son GPL-3.0 y un juego derivado distribuido debe seguir siéndolo. Si Linde necesitara
>    cerrar parte del código, la base correcta es Minetest Game (LGPL-2.1), a cambio de perder
>    todo el contenido ya hecho.
> 2. **Aceptar que la capa RPG es código propio.** No existe hoy en Luanti un Project MMO ni un
>    Silent Gear. La investigación encontró sistemas parciales (`myprogress` para XP y niveles,
>    `toolranks` para progresión de herramientas, `3d_armor` para armaduras visibles), pero
>    **ninguno combinado, mantenido y compatible con Mineclonia**. Escribir `linde_core` no es
>    «desarrollar un videojuego desde cero»: es escribir un mod sobre una API estable, con los
>    datos ya diseñados en el prototipo Godot.
>
> **No conviene** intentar reproducir la visión de Linde sobre Godot sin reutilizar nada: el
> prototipo Godot ya resolvió reglas, datos y arte de personaje, pero **no** resuelve mundo
> voxel, multijugador autoritativo, persistencia ni generación procedural, que es justo lo que
> Luanti regala.
>
> **No conviene** usar Minecraft + mods como base: el costo inicial, la licencia y la
> distribución a amigos son estrictamente peores, y la ventaja de ecosistema (Project MMO, Silent
> Gear) se paga con la imposibilidad legal de empaquetar y distribuir el juego.

---

## 4. Cómo leer las marcas de evidencia

| Marca | Significado |
|---|---|
| **[V]** | Verificado contra repositorio, API de GitHub/Codeberg o documentación oficial el 2026-10-28 |
| **[C]** | Solo disponible como listado de ContentDB (servicio caído) o mención de terceros; no verificado en origen |
| **[P]** | Pendiente de prueba de ejecución: existe, pero su funcionamiento en partida no está demostrado |

Ninguna recomendación de este informe se apoya únicamente en popularidad. Donde no hubo
evidencia, se dice.
