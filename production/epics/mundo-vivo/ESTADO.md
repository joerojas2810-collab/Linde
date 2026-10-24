# Mundo vivo — estado del epic

> **Actualizado**: 2026-10-24 · **Rama**: `main` · **Epic**: 5 de 5 historias Complete · **Revisión independiente**: ninguna (modo solo)

Documento único de estado. Para el plan original y las decisiones de diseño ver [README.md](README.md); para las reglas, [design/gdd/mundo-vivo.md](../../../design/gdd/mundo-vivo.md).

## 1. Qué hace hoy el sistema

El valle cambia solo mientras el servidor está encendido, sin historia fija. Un **director** evalúa cada hora de juego (60 s reales) unas tarjetas de datos, elige una con azar sembrado y aplica su efecto.

Ciclo jugable ya verificado de punta a punta:
1. El jugador **acepta la misión** «Una cama de huésped» (se ofrece mientras no hay camas libres ni ha llegado Nerea).
2. **Construye una cama de huésped.**
3. En la siguiente hora de juego, el director hace **llegar a Nerea por el sur** (celda 32,46), le asigna esa cama y avisa a todos: «Llegada de Nerea».
4. El jugador **entrega la misión** y cobra 15 XP y 2 fibra, una sola vez.

Además: Maren y Ordal viven de datos (Ordal presente desde el inicio, cama en 25,18), dormir ya no salta el reloj, y los clientes de red ven llegar a Nerea y reciben el aviso.

## 2. Estado por historia

| # | Historia | Estado | Cómo se comprobó | Notas |
|---|---|---|---|---|
| 001 | Paquete de datos, habitantes desde datos y Ordal | Complete | Rutina de Maren idéntica hora a hora (0 diferencias en 52.800 pasos), rechazo de paquetes rotos, capturas | Dormir sin avanzar el reloj |
| 002 | Variables del mundo y director | Complete | 36 casos con script temporal, capturas de la cama de huésped | `CADENCIA_MIN` está definida pero no se usa |
| 003 | Llegadas de habitantes y avisos | Complete **con AC-9 sin cumplir** | 14 casos, capturas de la llegada | Se puede construir un muro en la entrada (TD-001) |
| 004 | Misiones por plantilla y recompensas | Complete | 20 casos, `repetible: true` comprobado aparte, 4 capturas del panel | Texto largo del rastreador desborda |
| 005 | Guardado, servidor y red | Complete | Guardado y reinicio, servidor vacío 75 s, 3 clientes (11 PASS), 4 clientes p95 2,73 ms, 2 capturas | Aviso de MTU (TD-007) |

## 3. Cómo probarlo

- **Un jugador**: abrir `Linde/cenital` en Godot 4.7.1 (`Iniciar-Cenital.command`), partida nueva, `B` para construir (la cama de huésped sale con `Q`/`E`), `J` para misiones. Hay que esperar hasta un minuto real tras construir la cama.
- **El paquete de datos actual es una copia de prueba** de las tarjetas de GPT (`Linde/cenital/datos/mundo/`, `fixture: true`). Con ese marcador el director admite tarjetas `proposed`; con un paquete real harían falta `--admitir-propuestas` o tarjetas aprobadas.
- **Servidor**: `Godot --headless --path Linde/cenital -- --servidor --guardado=<ruta> --duracion=<s>`.
- **Comprobaciones** (desde la raíz del repo, con `herramientas/runtime/Godot.app/Contents/MacOS/Godot`):
  - `--headless --path Linde/cenital --import`
  - `--headless --path Linde/cenital --script res://tests/prueba.gd` → 326 PASS
  - `--headless --path Linde/cenital --script res://tests/prueba_ui.gd` → 13 PASS
  - `--headless --path Linde/cenital --script res://tests/prueba_aspecto.gd` → 225 PASS (sistema de aspectos de otra sesión)
  - `--headless --path Linde/cenital --script res://tests/prueba_red.gd` → 0 comprobaciones fallidas

## 4. Decisiones tomadas (2026-10-24)

- Servidor siempre encendido en un hosting; el mundo **no se congela** sin jugadores (como Minecraft).
- Crecimiento mixto (C): los hitos abren posibilidades y la construcción las concreta; sin guion fijo.
- Ordal presente desde el inicio; los habitantes que llegan aparecen en el sur.
- Dormir no salta el reloj compartido.
- La llegada de un habitante es una variable `<id>_presente`; el motor reacciona al cambio.
- «Cama de huésped» es una pieza nueva; `camas_libres` cuenta solo esas.
- Plantilla de prueba «Una cama de huésped» (oferta sin camas libres, 15 XP + 2 fibra). Cobra quien entrega, una vez para todo el mundo.
- Clientes de red: ven llegar a Nerea y reciben el aviso; el panel de misiones en clientes queda fuera.
- Los agentes de implementación siguen con Sonnet 5.5.
- Aspecto propio por habitante, en una tabla del juego (hoy reemplazada por el sistema de aspectos de la otra sesión).

## 5. Qué se verificó y qué no

- Todo se repitió con Godot 4.7.1 y se vieron las capturas (`production/qa/evidence/story-00X-…/`, con sello de los archivos).
- **No hay tests del epic en el repo** (exentos en `qa.level: minimal`). La verificación vive en **scripts temporales fuera del repo** (carpeta de scratchpad de la sesión): se pierden si se limpia esa carpeta. Si el epic debe poder revalidarse, hay que pasarlos a `tests/`.
- **Sin revisión independiente**: el GDD no pasó por `/design-review` y el código no pasó por `/code-review`.
- El GDD aún afirma, en Casos límite, que la entrada ya está protegida (TD-006).
- Sin latencia simulada ni red real; solo localhost.

## 6. Deuda técnica

Registrada en [docs/tech-debt-register.md](../../../docs/tech-debt-register.md): TD-001 a TD-009.

| ID | Resumen |
|---|---|
| TD-001 | La entrada se puede tapar y la llegada sale sobre el muro (incumple AC-9) |
| TD-002 | Tabla de aspecto y `VEL` en código, no en datos |
| TD-003 | `camas_asignadas` conserva la clave de una cama retirada |
| TD-004 | El aviso de llegada es solo el nombre de la tarjeta |
| TD-005 | Ordal y Nerea responden la misma frase genérica |
| TD-006 | El GDD afirma una protección de la entrada que no existe |
| TD-007 | La instantánea (1.783 bytes con 4 jugadores) supera el MTU de ENet |
| TD-008 | `mundo_vivo` se reenvía completo cada hora |
| TD-009 | Sin panel de misiones de plantilla en clientes |

**No registradas** (se cerraron las historias sin registrar): `CADENCIA_MIN` sin usar y constantes de ritmo en código (002); rastreador que desborda, progreso del panel solo por estado y ámbito jugador tratado como compartido (004).

## 7. Pendiente de decisión tuya

1. **TD-001**: ¿arreglar que la entrada se pueda tapar, o corregir el criterio y el GDD?
2. **Aprobar las tarjetas** del Atlas (hoy `proposed`) y el canon de Ordal y Nerea (A02 sigue abierto).
3. **Variable inexistente**: el contrato de GPT dice «bloquea la evaluación»; el código descarta solo esa tarjeta.
4. **`/design-review` del GDD** en una sesión nueva, y una revisión de código del epic.
5. **Contenido**: diálogos propios de Ordal y Nerea, más tarjetas y habitantes. Con 3 tarjetas y 2 habitantes el valle se repetirá enseguida.
6. **Hosting**: elegir dónde alojar el servidor siempre encendido (ver la comparativa de opciones gratuitas) y añadir la pantalla de conexión.

## 8. Dependencias fuera del epic

- **Atlas de GPT** (fuera del repo): `/Users/josephrojas/Documents/ChatGPT/Linde/docs/atlas-contrato.md` y `world/`. El paquete de prueba es una copia modificada de sus 15 tarjetas más las nuestras (`llegada_nerea`, `cama_huesped`, variables derivadas y celdas de lugares). No se modificó el original.
- **Sistema de aspectos** (otra sesión): `scripts/aspecto.gd`, `docs/ASPECTOS.md` y cambios en `escena.gd`, `hud.gd`, `params.gd`, `arte_equipo.gd`, `red_servidor.gd` y `tests/prueba_ui.gd`. Subió `VERSION` del protocolo de red de 2 a 3. Mi script de la 003 que comprobaba el formato antiguo de aspecto ya no es válido.

## 9. Mapa de archivos

- **Código nuevo**: `scripts/mundo_datos.gd` (cargador y validación del paquete), `scripts/mundo_vivo.gd` (variables, condiciones, efectos, director, misiones de plantilla).
- **Código modificado**: `habitantes.gd`, `juego.gd`, `mundo.gd`, `catalogos.gd`, `mundo_arte.gd`, `escena.gd`, `hud.gd`, `red_servidor.gd`, `red_cliente.gd`, `tests/prueba.gd`.
- **Datos**: `Linde/cenital/datos/mundo/` (manifiesto y entidades JSON).
- **Documentos**: `design/gdd/mundo-vivo.md`, este epic (`EPIC.md`, `README.md`, `story-001…005`), `docs/tech-debt-register.md`.
- **Evidencia**: `production/qa/evidence/story-001…005-*/`.
