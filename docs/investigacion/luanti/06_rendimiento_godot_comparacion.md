# §10, §11 y §12. Rendimiento, reutilización del prototipo Godot y comparación (H, I)

**Fecha: 2026-10-28.**

---

# §10. Rendimiento y escalabilidad

## 10.1 Lo único que está medido (por el proyecto Luanti, no por nosotros)

La documentación oficial fija el dimensionamiento para **≈10 jugadores** (§9.0): 2–4 núcleos de CPU
con buena frecuencia, 4 GB de RAM «que deberían alcanzar» (más con Mineclonia), 30 GB de SSD y
20 Mbps. **No hay *benchmarks* publicados de Mineclonia con 10 jugadores** que hayamos podido
verificar.

> **No se inventan cifras.** Lo que sigue son estimaciones cualitativas marcadas como tales y un
> método para medirlas en la Fase 4 (§13).

## 10.2 Qué escala bien y qué no

| Factor | Comportamiento esperado | Por qué |
|---|---|---|
| **5 jugadores** | Sin problema en cualquier PC de los últimos 8 años | La carga dominante es generar mapblocks alrededor de cada jugador |
| **10 jugadores** | Bien con CPU moderna; el límite es el **hilo principal** | Luanti es en gran medida monohilo |
| **Mundo grande** | RAM y disco crecen con el área explorada, no con el tiempo | Solo se mantienen cargados los bloques activos |
| **Muchas estructuras** | Costo **de generación**, no permanente | Los esquemáticos se insertan una vez por mapchunk |
| **Muchos enemigos** | **Este es el peor enemigo del rendimiento** | Cada mob activo consume *ticks* de IA y de física; `mobs_redo` y `mcl_mobs` no son gratis |
| **Mods de generación** | Costo por mapchunk generado; se nota al explorar rápido | Cada bioma/mineral/decoración añade trabajo en la generación |
| **Mods RPG con `globalstep`** | Riesgo alto si se abusa | Un `globalstep` que recorre todos los jugadores cada *tick* es el error clásico |
| **Persistencia prolongada** | Estable, con `map.sqlite` creciendo | No hay *memory leak* conocido del motor; sí de mods |

## 10.3 Cuellos de botella concretos y su mitigación

| Cuello de botella | Síntoma | Mitigación |
|---|---|---|
| Hilo principal saturado | El servidor «lag» con `/status` mostrando *max lag* alto | Menos mods con `globalstep`; subir el paso (`dedicated_server_step`), reducir entidades |
| Demasiados mobs | Tirones al acercarse a una zona | Limitar `max_mobs`/spawn de Mineclonia; `active_block_range = 3` en vez de 4 |
| Generación al explorar | Tirones al correr hacia terreno nuevo | `max_block_generate_distance` menor; pre-generar la zona del spawn |
| Transferencia de medios | Primera conexión de 5–20 minutos | `remote_media` con nginx (§9.7) |
| Disco | `map.sqlite` de gigabytes | `mapgen_limit` acotado; respaldos con retención |
| RAM | Crece con jugadores y view range | 6–8 GB para Mineclonia con 10 jugadores |
| Red doméstica | Subida saturada en la primera conexión de cada amigo | Instalar de a uno, o `remote_media` |

## 10.4 Cómo medirlo (en lugar de suponerlo)

Protocolo mínimo, ejecutable en una tarde:

1. **Instrumentar.** En `linde_core`, un `globalstep` que cada 60 s escriba en el log:
   `os.clock()` del paso, número de jugadores, entidades activas
   (`#minetest.luaentities`), bloques cargados y RAM del proceso (desde `debug.txt` o `htop`).
2. **Escenario escalonado.** Mundo de prueba fijo (misma semilla), spawn pre-generado:
   medir con **1, 3, 5 y 10** clientes conectados (se pueden usar clientes headless o varias
   instancias en la LAN) durante **10 minutos** cada uno, con un recorrido guionado
   (caminar 500 nodos, bajar a −200, combatir 5 mobs).
3. **Métricas a registrar:** *max lag* de `/status`, ping medio (`minetest.get_player_information`),
   RAM del servidor, tamaño de `map.sqlite`, y quejas de los jugadores (la métrica que importa).
4. **Comparar configuraciones:** Mineclonia solo vs. Mineclonia + `linde_core` vs. + `moreores`.
5. **Guardar los resultados** en `docs/medicion-subsistemas.md`, que ya existe en el proyecto como
   precedente metodológico.

**Criterio de aceptación de rendimiento para Linde:** con 10 jugadores y `linde_core` activo,
*max lag* < 0,2 s el 95 % del tiempo en el hardware objetivo. Si no se cumple, se recorta el número
de mobs antes que el contenido RPG.

---

# §11. Reutilización del prototipo Godot (entregable H)

## 11.1 Qué hay realmente en el prototipo (auditado en el repositorio)

No es un prototipo vacío. Verificado en `Linde/cenital/`:

| Activo | Contenido | Volumen |
|---|---|---|
| `datos/desarrollo/reglas_v1.json` | Gramática de materiales: `madera, piedra, fibra, hierro, cobre, bronce` con `dureza`, `tenacidad`, `densidad`, `arquetipo`, `formas`; más `propiedades`, `formas`, `tecnicas`, `calidades`, `laminados`, `operadores` | 8,6 KB |
| `datos/equipo/*.json` | `familias` (Vigía, Zarzal, Albor) con bonos de set; `arquetipos` (5 ranuras, 3 arquetipos); `variantes` (3 piedras); `joyas` (+0..+5); `paletas` | 5 archivos |
| `datos/desarrollo/saberes_v1.json` | Técnicas, laminados, operadores, enseñanza, saberes iniciales por NPC y oficio | 1,7 KB |
| `datos/fauna/*.json` | Reglas de spawn por bioma, hábitats, comportamiento territorial | 4 archivos |
| `datos/edificios/catalogo_v1.json` | Planos de vivienda, taller, casa comunal con etapas de construcción | 1 archivo |
| `datos/asentamientos/*.json` | Reglas de asentamientos preexistentes | 2 archivos |
| `datos/mundo/entities/**` | NPC, lugares, eventos, variables de mundo, plantillas de misión | ~25 archivos |
| `scripts/artesania.gd` | Motor de la gramática de piezas (combinaciones, laminados, evaluación versionada) | 282 líneas |
| `scripts/desarrollo.gd` | Saberes, rangos, enseñanza, fabricación, compras | 606 líneas |
| `scripts/equipo.gd` | Sets, variantes, niveles, fórmula de defensa | 428 líneas |
| `scripts/combate.gd` | Ataque, daño, muerte, IA de enemigos | 328 líneas |
| `scripts/fauna.gd` | Hábitats, territorios, planes de spawn | 362 líneas |
| `tests/dorados/artesania_v1.json` | **Casos dorados**: hash y muestra de resultados esperados de la artesanía | 1 archivo |

## 11.2 Clasificación: qué se traslada y cómo

### (1) Se traslada **como datos**, casi sin cambios

| Origen Godot | Destino Luanti | Trabajo |
|---|---|---|
| `reglas_v1.json` → `materiales`, `formas`, `tecnicas`, `calidades` | `linde_core/data/materiales.lua` | Convertir JSON a tabla Lua (script de 20 líneas) |
| `equipo/arquetipos.json` (ranuras, multiplicadores, topes) | `linde_core/data/arquetipos.lua` | Ídem |
| `equipo/familias.json` (3 familias, bonos de set, origen) | `linde_core/data/familias.lua` | Ídem; las recetas se traducen a la estación modular |
| `equipo/variantes.json` + `joyas.json` | `linde_core/data/variantes.lua` | Ídem |
| `desarrollo/saberes_v1.json` | `linde_core/data/saberes.lua` | Ídem; la parte de «enseñanza por NPC» se deja para v2 |
| `fauna/reglas_v1.json` + `habitats_v3.json` | Tabla de spawn de `linde_core` o de `mcl_mobs` | Los biomas de Godot (bosque, sierra, secano, pradera, ribera) hay que **mapearlos** a los de Mineclonia |
| `edificios/catalogo_v1.json` | Esquemáticos `.mts` o estructuras de Mineclonia | Requiere **construir el esquemático** en el juego; los planos son el diseño |
| `datos/mundo/entities/**` | Formspec de diálogo + tabla de misiones | Solo si se hacen misiones (no en v1) |

### (2) Se traslada **como lógica**, reescribiendo en Lua

| Origen | Qué hace | Dificultad de portar | Nota |
|---|---|---|---|
| `artesania.gd` | Combina materiales, calcula dureza/tenacidad/densidad, aplica técnica y calidad | **Alta-media**: es la pieza más valiosa y la más compleja | La lógica es determinista y está especificada; se puede reimplementar y **validar contra los casos dorados** |
| `equipo.gd` | Fórmula de defensa proporcional, bonos de set, variantes, mejora +N | Media | Es aritmética pura; se traduce casi línea a línea |
| `desarrollo.gd` | Saberes, rangos, requisitos de fabricación | Media | En Luanti se simplifica: los saberes se pueden expresar como niveles de profesión |
| `combate.gd` | Daño, muerte, IA | **Baja**: se descarta la IA | El daño de Luanti ya existe; solo se portan las **fórmulas** de bonus |
| `fauna.gd` | Territorios y planes de spawn | Baja | Se sustituye por `mcl_mobs` + ABM; se conservan las **preferencias de bioma** |

### (3) **No** se traslada

| Elemento | Por qué |
|---|---|
| Todo `GDScript` como código | GDScript **no corre en Luanti**. No hay transpilador. Es reescritura manual |
| `mundo.gd`, `escena.gd`, cámara, movimiento | Luanti ya lo resuelve; portarlo sería duplicar el motor |
| `red_servidor.gd`, `red_cliente.gd` (523 + 311 líneas) | **Luanti ya es autoritativo**; portar la red Godot no aporta nada |
| Guardado (`juego.gd`, `mundo_datos.gd`) | `player:get_meta()` y `mod_storage` lo sustituyen |
| `hud.gd`, `hud_vivo.gd` (escenas) | Se rehace con formspec/HUD de Luanti (más simple) |
| Arte 2D de personaje y equipo | Un mundo 3D no usa *sprites* de cuerpo completo; sirve como paleta y como iconos de inventario |
| `autonomia.gd`, `sociedad.gd` (1.592 líneas) | Sistema de sociedad emergente del prototipo; **no es requisito de Linde RPG** y no tiene equivalente en Luanti |

### (4) **No conviene portar** porque Luanti ya lo resuelve

- Movimiento, colisiones, física, cámara, iluminación.
- Generación de mundo, biomas, cuevas, minerales.
- Inventario, recetas estáticas, horno.
- Red, sincronización, persistencia, *login*.
- Menús básicos y HUD.

## 11.3 El activo más subestimado: los **casos dorados**

`tests/dorados/artesania_v1.json` guarda un **hash** del comportamiento y una **muestra** de
entradas/salidas esperadas (por ejemplo `art2:botas:bronce:ligera:0:fibra:fino` →
`def 1, hp 2, vel 0.034, color #b88a3c`).

Eso permite portar la artesanía a Lua **con verificación automática**: se implementa
`linde_core/artesania.lua` y un script de prueba que recalcula cada caso y compara con el JSON
original. Si coincide, el port es correcto; si no, se sabe exactamente en qué caso falla.

> **Es la única parte del proyecto donde se puede portar lógica con garantía de equivalencia.**
> Hay que aprovecharla: convierte «reescribir 280 líneas de GDScript» en «aprobar una suite».

## 11.4 Qué documentos y carpetas hacen falta para una auditoría exacta

Ya están en el repositorio y se auditaron: `Linde/cenital/datos/**`, `scripts/*.gd`,
`tests/dorados/`. Para completar la auditoría faltaría, si existe fuera del repositorio:

- `Linde/documentos/sistema-de-equipo.md` (está) — es la especificación de números.
- El **arte final** de personajes y equipo con sus medidas (hay `arte-entregado/biblioteca_01`).
- Los **esquemáticos** de edificios si existieran (no los hay: solo planos en JSON).
- La lista de **sonidos** si el prototipo los tenía (no se detectaron `.ogg` propios).

---

# §12. Comparación con Minecraft + mods y con Godot propio (entregable I)

Criterios del encargo. Escala cualitativa; el peso está en «cuánto de Linde se obtiene sin
programar» y en el costo real de cada camino.

| Criterio | **Luanti + Mineclonia** | **Minecraft + mods** | **Godot propio (prototipo Linde)** |
|---|---|---|---|
| **Costo inicial** | **0** (motor y juego GPL, sin cuentas) | Costo por jugador (licencia de Minecraft Java) + cuenta Microsoft | 0 en licencias, pero **alto en horas** de desarrollo |
| **Código abierto** | Sí (LGPL motor, GPL-3.0 juego) | No (mods sí, juego no) | Sí (propio) |
| **Mundo procedural** | ✅ gratis, ~61.840³ nodos | ✅ gratis, mayor variedad de biomas | ❌ **hay que programarlo** (el prototipo tiene mapa por regiones 2D, no voxel) |
| **Multijugador** | ✅ gratis y autoritativo | ✅ gratis con servidor Java | ❌ ya hay red propia en el prototipo, pero es 2D y limitada |
| **Profesiones** | ❌ **no existe** → `linde_core` | ✅✅ Project MMO / LevelZ, maduros | 🟡 parcial (`desarrollo.gd`: saberes y rangos) |
| **Minerales** | ✅ (8+ en Mineclonia; `moreores` añade 4) | ✅✅ cientos de mods | 🟡 definidos en JSON, sin mundo 3D que los contenga |
| **Fabricación modular** | ❌ **no existe** → `linde_core` | ✅✅ Silent Gear / Tinker's, exactamente lo que Linde quiere | ✅ **ya diseñada y especificada** (`artesania.gd` + `reglas_v1.json`) |
| **Jefes** | 🟡 barras y mobs del juego; jefes propios a registrar | ✅✅ Ice and Fire, Mowzie's, etc. | ❌ hay combate, no jefes |
| **Mazmorras** | ✅ (Mineclonia: dungeons, strongholds, fortresses) | ✅✅ estructuras procedurales muy superiores | 🟡 `lugares` y `edificios` en datos |
| **Personalización** | ✅ skins + armadura visible (`.b3d`) | ✅✅ skins, capas, modelos | ✅ arte propio 2D ya entregado |
| **Facilidad de modificación** | ✅✅ Lua, sin compilar, recarga en caliente | 🟡 Java/mods, dependiente de versión, ecosistema frágil | ✅ total (es nuestro código) |
| **Código propio necesario** | **1 mod** (`linde_core`, ~1.300–1.900 líneas) | **0** para mecánicas, **mucho** para empaquetar y distribuir | **Todo el juego** |
| **Facilidad de distribuir** | ✅✅ cliente oficial + servidor manda medios | ❌ **no se puede empaquetar** legalmente el juego con mods; cada amigo compra e instala | ✅ ZIP del ejecutable |
| **Mantenimiento** | 🟡 actualizar Mineclonia + probar overrides | ❌ modpacks se rompen en cada versión de MC | ✅/❌ depende de nosotros, para siempre |
| **Tiempo hasta una beta jugable** | **2–4 semanas** (1 si se acepta Mineclonia sin capa RPG) | 1 semana para jugar, **meses** para balancear y **nunca** para distribuir | **6–18 meses** |

## 12.1 Lectura honesta de la tabla

- **Minecraft + mods gana claramente en mecánicas RPG ya hechas.** Si el objetivo fuera «el mejor
  RPG posible sin importar licencias ni distribución», Project MMO + Silent Gear + un mod de
  mazmorras daría más, más rápido.
- **Pero Linde es un proyecto entre amigos, con distribución propia y sin comprar licencias.** Ahí
  Minecraft falla en dos criterios que no se pueden resolver con mods: **costo por jugador** y
  **distribución legal**. Y falla uno más: el modpack se rompe en cada actualización, lo que come
  el tiempo que se quería ahorrar.
- **Godot propio es el único camino que da control total**, y el prototipo ya tiene las reglas RPG
  mejor pensadas de los tres (materiales con propiedades, sets, variantes, joyas, saberes). Pero le
  falta **todo el mundo**: generación voxel, multijugador, persistencia, mazmorras, mobs, arte 3D.
  Eso son meses, no semanas.
- **Luanti es el punto medio correcto:** entrega el mundo y el multijugador (lo caro y aburrido) y
  deja como trabajo propio exactamente lo que el prototipo Godot ya tiene diseñado (la capa RPG).

## 12.2 La decisión, en una frase

> **Luanti + Mineclonia para el mundo; los datos del prototipo Godot para las reglas RPG; un mod
> propio para unirlos. Minecraft no se usa porque no se puede distribuir; Godot no se usa porque
> habría que reconstruir el mundo.**
