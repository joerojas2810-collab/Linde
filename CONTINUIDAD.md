# Continuidad: cómo retomar Linde

## Qué es
Linde es un RPG 2D cenital de **mundo vivo** en Godot 4.7.1 (`Linde/cenital`, GDScript): servidor autoritativo con réplica en clientes, habitantes autónomos (necesidades, trueque, construcción, llegada, oficios, saberes), fabricación por gramática, exterior generado por regiones y fauna. La **autonomía es el modo principal**; no hay campaña obligatoria. El objetivo actual es **Mundo 1**: un mundo compartido y persistente, con pueblos que prosperan o decaen, donde exploración, civilización y progresión salgan de un mismo mundo simulado (sin escalado de enemigos al nivel del jugador).

## Qué leer, en este orden
1. [`CLAUDE.md`](CLAUDE.md): reglas del estudio y política de documentación (léelo antes de tocar nada).
2. [`production/epics/mundo-vivo/ESTADO.md`](production/epics/mundo-vivo/ESTADO.md): **fuente de verdad de lo implementado**, con fecha y alcance de cada prueba. Si el código lo contradice, manda el código.
3. [`Linde/cenital/docs/DECISIONES.md`](Linde/cenital/docs/DECISIONES.md): índice único de decisiones (las de Mundo 1 son `M1-*`, sección F).
4. [`design/VISION_MUNDO_1.md`](design/VISION_MUNDO_1.md): hacia dónde va el juego (diseño objetivo, no implementado).
5. [`docs/investigacion/PLAN_MUNDO_1.md`](docs/investigacion/PLAN_MUNDO_1.md): auditoría de brechas y fases 0–7.
6. `production/session-state/active.md`: checkpoint de la sesión anterior, si existe.
Solo si la tarea lo pide: el contrato del sistema en `Linde/cenital/docs/` y `design/gdd/`; [`docs/investigacion/CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md`](docs/investigacion/CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md) (diagnóstico del mundo inicial) y [`RESULTADOS_P1_P2_Y_ECONOMIA_VELOREN.md`](docs/investigacion/RESULTADOS_P1_P2_Y_ECONOMIA_VELOREN.md) (economía regional).

## Estado y próxima fase
- **Implementado de Mundo 1**: Fase 0 (herramientas de medición y línea base), paso 1a/1b (registro `mundo.poblados` y lectores por poblado) y **Fase 1 completa (1c aparición en el pueblo, 1d hitos y estaciones comunitarias, 1e slimes fuera del núcleo)**. Detalle y limitaciones: ESTADO.md §3d.
- **Fases 2 y 3 completas** (autorizadas el 26/10): mapa personal con M, flechas, +/− e Inicio; verde = observado, ocre = contado; E → L en conversación intercambia información con NPC cercano. Catorce pistas opcionales, T para descartar y Esc para silenciar/reactivar; descubrimientos, fuentes e historial persisten por jugador y se replican solo a su dueño. Commits `8669f62` y `7fa3e74`. Pruebas y límites: ESTADO.md §§3e–3f.
- **Próxima fase: Fase 4 (registro de lugares y destinos), NO autorizada**. El usuario prohibió avanzar a ella en esta sesión. No generes nuevos lugares, caminos o pueblos sin nueva autorización.
- **Cierre verificado de Fases 2–3 (26/10)**: 33 de 34 suites sin fallos; única falla previa de arte. Hashes completos de legado idénticos antes/después de cada funcionalidad (dos semillas, cuatro días), batería determinista 8/8 igual. Sin cambios de balance. Evidencia y resumen final en `production/qa/evidence/mundo-1/fase-3/`.
- **Fallo conocido, previo a Mundo 1**: `prueba` falla una comprobación sobre el hash de 96 archivos de arte (E04/E05); no lo ocultes ni lo "arregles" sin investigarlo.

## Cómo ejecutar las pruebas
Godot local: `herramientas/runtime/Godot.app/Contents/MacOS/Godot` (no está en el PATH). Detalle en ESTADO.md §4.
- Orientación: suites `prueba_exploracion`, `prueba_exploracion_ui`, `prueba_pistas`, `prueba_pistas_ui` y `prueba_orientacion_red`; capturas `captura_exploracion.gd` y `captura_pistas.gd`. Evidencia en `production/qa/evidence/mundo-1/fase-2/` y `fase-3/`.
- Una suite: `Godot --headless --path Linde/cenital --script res://tests/<suite>.gd`.
- Todas: `Linde/cenital/tests/ejecutar_suites.sh [suite ...]` (las `*_red` reescriben JSON de evidencia versionados: restáuralos si no son tu cambio).
- Medición y equivalencia: `Linde/cenital/tests/medir_todo.sh <carpeta>` y `--comparar <base> <nueva>` (líneas base en `production/qa/evidence/mundo-1/`; `IGNORAR=<ruta>` excluye solo las claves nuevas que añadas).
- Cambios visibles: captura con render, p. ej. `tests/captura_mundo1.gd`, guardada en `production/qa/evidence/`.

## Reglas para continuar
- Respeta `DECISIONES.md` y la visión; ante una contradicción, **pregunta**, no decidas.
- **Modo `legado`**: `estado.inicio.modo`; debe seguir idéntico (hashes completos de estado). Las pruebas y herramientas crean mundos en `legado` por defecto; los mundos jugados usan `poblado`.
- No cambies balance, XP, fabricación, daño, recompensas ni economía sin medición y aprobación. Los valores marcados «de prueba» no son definitivos.
- Reutiliza lo que existe (registro de poblados, `Asentamientos`, `Autonomia`, validaciones); no crees sistemas paralelos. Los pueblos siguen las mismas reglas que cualquier comunidad y **ninguno es invulnerable ni inmortal**.
- Un commit por cambio funcional, con hashes de estado comparados antes y después; los guardados antiguos no importan (sin migraciones).
- Tras implementar y probar algo, registra el resultado verificado (con fecha, alcance y limitaciones) en ESTADO.md; las cifras se registran, no se asumen.
