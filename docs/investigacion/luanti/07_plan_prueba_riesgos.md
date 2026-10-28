# §13, §14 y K. Plan de implementación, prueba técnica y riesgos (entregable J y K)

**Fecha: 2026-10-28.**

> **Advertencia que debe leerse antes del plan:** **ninguna de estas pruebas fue ejecutada.**
> Todo lo que sigue es un diseño de prueba derivado de la documentación y del código fuente
> revisado. Las estimaciones de tiempo están marcadas como **[estimación]** o **[medición]**; hoy
> no hay ninguna medición propia.

---

# §13. Plan de implementación por fases

## Fase 1 — Base jugable

| Aspecto | Detalle |
|---|---|
| **Objetivo** | Un mundo de Linde jugable por dos personas, sin código propio |
| **Tareas** | (1) Descargar Luanti 5.17.0 para cada sistema. (2) Clonar Mineclonia 0.124.1 en `games/`. (3) Crear el mundo con la semilla elegida **antes** de decidir mods de generación. (4) Fijar `enable_damage = true`, `max_users = 10`, `port = 30000`, `motd`. (5) Conectar dos clientes en LAN. |
| **Dependencias** | Ninguna |
| **Riesgos** | Bajo. El único serio: crear el mundo y después querer cambiar mods de generación (§5.F) |
| **Sin código** | 100 % |
| **Requiere programación** | Nada |
| **Criterio de aceptación** | Dos jugadores juegan 30 min, encuentran una mazmorra, craftean hierro, matan mobs; al reiniciar el servidor conservan inventario, posición y salud |
| **Tiempo** | **2–4 horas** [estimación] |

## Fase 2 — RPG

| Aspecto | Detalle |
|---|---|
| **Objetivo** | Profesiones, XP, requisitos y fabricación por materiales funcionando |
| **Tareas** | (1) Convertir `reglas_v1.json`, `arquetipos.json`, `familias.json`, `variantes.json`, `joyas.json` a tablas Lua. (2) Implementar `linde_core/api/skills.lua` con XP por `on_dignode`, `on_craft`, `on_punchplayer`. (3) Persistir con `player:get_meta()`. (4) Implementar requisitos con `can_dig` y `on_punchplayer`. (5) Implementar la estación de fabricación modular con formspec. (6) HUD de XP y panel de profesiones. |
| **Dependencias** | Fase 1; decisión de licencia (GPL-3.0) |
| **Riesgos** | **Alto**: es la única fase con código nuevo. Riesgo específico: `can_dig` no informa el ítem usado → hay que leer el ítem en la mano; si no funciona, plan B es interceptar `on_dignode` |
| **Sin código** | La mitad: los datos ya existen; las recetas y el balance son tablas |
| **Requiere programación** | `linde_core` completo (§7.3) |
| **Criterio de aceptación** | Un jugador nuevo sube minería a 5 en 10 minutos; a nivel 20 extrae el mineral bloqueado; fabrica una armadura cuyas stats dependen del material; el panel muestra sus niveles; todo persiste tras reconectar |
| **Tiempo** | **2–4 semanas** de una persona con Lua [estimación]; la mitad si sólo se hace skills (sin fabricación modular) |

## Fase 3 — Exploración

| Aspecto | Detalle |
|---|---|
| **Objetivo** | Que el mundo tenga suficientes razones para explorar |
| **Tareas** | (1) Evaluar `moreores` en Mineclonia y verificar que no duplica cobre/estaño. (2) Añadir minerales/estructuras propias con `register_ore` y esquemáticos `.mts`. (3) Registrar 2–3 jefes con `mcl_mobs` + `mcl_bossbars` y recompensa en `on_death`. (4) Ajustar spawns por bioma con los datos de `fauna/`. (5) Probarlo en un **mundo nuevo** |
| **Dependencias** | Fase 2 (el nivel de minería debe existir para bloquear minerales) |
| **Riesgos** | Medio: los jefes y estructuras requieren construir arte/Esquemáticos; el balance de dificultad es iterativo |
| **Sin código** | Añadir minerales y estructuras es declarativo; los jefes requieren registro |
| **Requiere programación** | Registro de jefes/recompensas (~150 líneas) |
| **Criterio de aceptación** | Existe al menos una mazmorra con enemigos y un jefe con barra, recompensa única y mensaje global |
| **Tiempo** | **2–3 semanas** [estimación], dominado por el arte y los esquemáticos |

## Fase 4 — Multijugador real

| Aspecto | Detalle |
|---|---|
| **Objetivo** | 5–10 amigos jugando desde sus casas, con el mundo persistente |
| **Tareas** | (1) Montar el servidor (§9.1–9.3). (2) Tailscale o *port forwarding* (§9.4). (3) Backups automáticos (§9.6). (4) Medir rendimiento con el protocolo de §10.4. (5) Probar caída y restauración del servidor |
| **Dependencias** | Fase 1 para el servidor; Fase 2 para que haya progresión que persistir |
| **Riesgos** | Medio: CGNAT, firewall, suspensión de la PC, corrupción por apagado indebido |
| **Sin código** | 100 % |
| **Requiere programación** | Nada |
| **Criterio de aceptación** | 5 jugadores simultáneos durante 2 h con *max lag* < 0,2 s en el 95 % del tiempo; backup restaurado con éxito en una máquina distinta |
| **Tiempo** | **1 semana** [estimación] |

## Fase 5 — Personalización Linde

| Aspecto | Detalle |
|---|---|
| **Objetivo** | Que se vea y se sienta como Linde, no como Mineclonia |
| **Tareas** | (1) `games/linde/` con `game.conf`, icono y menú propios. (2) Renombrar y retexturizar lo visible (`linde_assets`). (3) Pantalla de elección de personaje con formspec. (4) Empaquetado reproducible (`herramientas/empaquetar.sh`). (5) Guía de instalación para amigos |
| **Dependencias** | Fases 1–4 |
| **Riesgos** | Medio: retexturizar cientos de nodos sin perder coherencia; GPL obliga a publicar |
| **Sin código** | Texturas, nombres, menús: sí |
| **Requiere programación** | Pantalla de personaje (~100 líneas) |
| **Criterio de aceptación** | El ZIP de Linde se reconstruye desde el repositorio en un comando y un amigo nuevo juega en < 15 min |
| **Tiempo** | **2–6 semanas** [estimación], depende del arte |

## 13.6 Resumen de tiempos

| Fase | Estimación | ¿Ejecutada? |
|---|---|---|
| 1. Base jugable | 2–4 h | ❌ |
| 2. RPG | 2–4 semanas | ❌ |
| 3. Exploración | 2–3 semanas | ❌ |
| 4. Multijugador | 1 semana | ❌ |
| 5. Personalización | 2–6 semanas | ❌ |
| **Total hasta beta** | **≈ 2–3 meses de una persona a medio tiempo** | — |

Ninguna de estas cifras es una medición. La primera medición real será la Fase 1, que además
calibrará las demás.

---

# §14. Prueba técnica mínima obligatoria

## 14.1 Diseño de la prueba

**Objetivo:** demostrar en una sola sesión que Luanti sirve para Linde, con evidencia registrada.

**Preparación:**

- 1 PC servidor (Windows 11 o macOS) + 1 PC cliente (o dos clientes en la misma máquina).
- Luanti 5.17.0 en ambos.
- Mineclonia 0.124.1 en el servidor.
- `linde_core` **solo si se está probando la Fase 2**; para la prueba mínima **no es necesario**.
- Un cronómetro y una hoja de registro (abajo).

**Guion de 12 pasos:**

| # | Paso | Quién lo cubre | ¿Existe hoy? |
|---|---|---|---|
| 1 | Crear mundo procedural con semilla fija | Mineclonia | ✅ software existente |
| 2 | Conectar 2 jugadores | Motor | ✅ existente |
| 3 | Explorar y descubrir una estructura (mazmorra o aldea) | `mcl_dungeons` / `mcl_villages` | ✅ existente |
| 4 | Encontrar varios minerales (carbón, hierro, cobre, oro) | Minerales de Mineclonia | ✅ existente |
| 5 | Fabricar un arma y una armadura | Mesa + `mcl_armor` | ✅ existente |
| 6 | Combatir enemigos | `mobs_mc` | ✅ existente |
| 7 | Derrotar un jefe | Jefes de Mineclonia | ⚠️ **requiere verificación**: hay `mcl_bossbars`, pero hay que confirmar qué jefes son accesibles en modo supervivencia (probablemente el Wither y el dragón del End) |
| 8 | Obtener recompensa | Drops / cofres | ✅ existente (los drops de jefe son del juego; recompensa «única» custom, no) |
| 9 | Subir una habilidad o profesión | **Nada existente en Mineclonia** | ❌ **requiere `linde_core`** |
| 10 | Guardar y reiniciar el servidor | Motor | ✅ existente |
| 11 | Comprobar que el mundo persiste | Motor | ✅ existente |
| 12 | Comprobar que ambos jugadores siguen jugando con su progreso | Motor + `player:get_meta` | ✅ existente para inventario/salud; ⚠️ el **progreso RPG** depende de `linde_core` |

**Puntos que requieren adaptación:** 7 (identificar y quizá registrar un jefe accesible),
8 (recompensa concreta), 9 (todo el sistema de profesiones) y 12 (persistencia de ese progreso).

**Puntos que requieren programación propia:** 9 y la parte RPG de 12.

## 14.2 Hoja de registro (para llenar en la prueba)

```
Fecha:            Versión Luanti:            Versión Mineclonia:
Semilla:          Mods extra:                Hardware servidor:
Paso 1  ✅/❌  tiempo: ___  nota:
Paso 2  ✅/❌  tiempo: ___  nota:
...
Paso 12 ✅/❌  tiempo: ___  nota:
Incidencias (log, captura, mensaje de error):
```

**Criterio de éxito:** pasos 1–6, 10–12 en verde; paso 7–8 con jefe identificado; paso 9 en rojo
**esperado** hasta que exista `linde_core` (ese rojo es el resultado que justifica el mod).

## 14.3 Resultado de esta investigación

> **La prueba NO fue ejecutada.** No hay ningún paso verificado en partida. Lo que se verificó es
> que el software que cubre cada paso **existe, está mantenido y declara la capacidad**. La
> diferencia entre ambas cosas es exactamente el trabajo de la Fase 1.

---

# §15.K Riesgos técnicos, compatibilidades no verificadas y pruebas pendientes

## K.1 Riesgos ordenados por impacto

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| **R1** | ContentDB sigue caído y no se pueden instalar mods desde el cliente | Alta (hoy es un hecho) | Medio | Clonar por Git con commits fijados (§8, `mods_pin.sh`) |
| **R2** | Un mod no funciona con Luanti 5.17 porque nadie lo probó en esa versión | Media | Medio | Probar cada mod en un mundo de prueba antes de entrar al modpack |
| **R3** | `linde_core` no logra bloquear la extracción con `can_dig` | Media | **Alto** (es el corazón del diseño) | Probar el patrón primero (§7.3); plan B con `on_dignode` |
| **R4** | Actualizar Mineclonia rompe overrides de `linde_core` | Alta si se actualiza sin cuidado | Alto | Fijar versión; suite de pruebas tras cada actualización |
| **R5** | Varios mods populares **no tienen licencia** y no se pueden distribuir | **Confirmada** para 6 paquetes | Alto (legal) | §5.J: excluirlos del ZIP o pedir permiso |
| **R6** | GPL-3.0 obliga a publicar todo el código de Linde | Confirmada | Bajo si se acepta | Decisión de proyecto, no un bug |
| **R7** | Duplicación de materiales al mezclar `moreores` con Mineclonia | Media | Bajo | Probar en Fase 2; un solo mod de minerales |
| **R8** | Rendimiento con 10 jugadores + mobs + `linde_core` por debajo de lo aceptable | Media | Medio | Protocolo de §10.4; límites de mobs |
| **R9** | Apagón/cierre indebido corrompe `map.sqlite` | Baja | **Muy alto** (pérdida de la partida) | `/shutdown`, backups automáticos, restauración probada |
| **R10** | Los amigos no logran conectarse (CGNAT, firewall, Tailscale) | Media | Medio | Tailscale por defecto; probar antes de la noche de juego |
| **R11** | El proyecto queda atado a un fork comunitario (Mineclonia) que se abandona | Baja (activo hoy) | Alto | Es GPL: se puede forkear; y VoxeLibre es alternativa |
| **R12** | Deriva de alcance: se empieza a programar misiones, magia, NPC autónomos | **Alta** (es el patrón habitual) | Alto | §1 y §7: misiones y magia **fuera de v1** por decisión del proyecto |

## K.2 Compatibilidades **no verificadas** (declaradas como tales)

1. `moreores` en Mineclonia 0.124.1 (el `mod.conf` lo declara soportado, nadie lo probó aquí).
2. `inventory_pouches` en Mineclonia (declara MineClone2, no Mineclonia).
3. `areas` en Mineclonia (usa nodos de `default`; puede requerir parche).
4. `linde_core` con `can_dig`, `on_punchplayer` y overrides de ítems.
5. Cualquier mod de la lista de contingencia (Arquitectura D) funcionando **junto a los otros 19**.
6. Jefes accesibles en modo supervivencia en Mineclonia 0.124.1.
7. `remote_media` en este proyecto.
8. Backup en caliente con `sqlite3 .backup`.
9. Servidor en macOS Apple Silicon (binario arm64 existe; guía oficial no).
10. Tailscale y playit.gg con Luanti 5.17 (reportes de comunidad, ninguno propio).

## K.3 Pruebas pendientes, en orden de ejecución

- [ ] **P1** — Fase 1 completa (§13), con la hoja de §14.2.
- [ ] **P2** — Identificar jefe accesible y derrotarlo (pasos 7–8).
- [ ] **P3** — Patrón de bloqueo de extracción (`can_dig`) en un mod de 30 líneas.
- [ ] **P4** — Patrón de escalado de daño (`on_punchplayer`).
- [ ] **P5** — `moreores` en Mineclonia: ¿duplica cobre/estaño?
- [ ] **P6** — Servidor 5 jugadores 2 h con medición de §10.4.
- [ ] **P7** — Backup + restauración en máquina distinta.
- [ ] **P8** — Port de `artesania.gd` validado contra `tests/dorados/artesania_v1.json`.
- [ ] **P9** — Conexión por Tailscale desde otra red.
- [ ] **P10** — Revisar licencias una por una antes de empaquetar el ZIP.

## K.4 Qué haría fracasar este plan (y hay que vigilar)

1. **Escribir `linde_core` antes de la prueba P3/P4.** Si el patrón de bloqueo no funciona, el
   diseño cambia y el código se tira.
2. **Añadir mods «porque están buenos».** Cada mod es una dependencia sin pruebas y, a menudo, sin
   licencia.
3. **Crear el mundo antes de decidir la generación.** Obliga a empezar de nuevo.
4. **Actualizar Mineclonia en medio de una partida.**
5. **Confundir «está en ContentDB» con «funciona en Mineclonia».**
