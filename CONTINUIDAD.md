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
- **Fase 4 completa** (autorizada el 26/10): lugares compartidos y persistentes por macrorregión, ruinas, campamentos vacíos con mesa/cofre y entradas de cuevas, rutas transitables y visibles en M al observarlas. E examina el lugar; E → L transmite referencias de NPC; Av/Re Pág pagina referencias del mapa. Commits `a2548f6` y `3634a67`; contrato y resultados en ESTADO.md §3g. Protocolo de red 8.
- **Próxima fase: Fase 5 (pueblos preexistentes y simulación), NO autorizada**. El usuario prohibió iniciarla en esta sesión. No añadas pueblos, habitantes de campamentos ni simulación lejana nueva sin autorización. Las cuevas solo tienen entrada; no hay interiores implementados.
- **Cierre verificado de Fase 4 (26/10)**: 36 de 37 suites sin fallos; única falla previa de arte. Núcleo: 8/8 archivos de medición idénticos en legado. Integración: hashes completos de dos semillas durante cuatro días idénticos. Tres suites nuevas (13, 10 y 19 PASS), expansión en vivo con dos clientes y capturas inspeccionadas. No se modifica balance ni se inicia Fase 5.
- **Cierre verificado de Fases 2–3 (26/10)**: 33 de 34 suites sin fallos; única falla previa de arte. Hashes completos de legado idénticos antes/después de cada funcionalidad (dos semillas, cuatro días), batería determinista 8/8 igual. Sin cambios de balance. Evidencia y resumen final en `production/qa/evidence/mundo-1/fase-3/`.
- **Fallo conocido, previo a Mundo 1**: `prueba` falla una comprobación sobre el hash de 96 archivos de arte (E04/E05); no lo ocultes ni lo "arregles" sin investigarlo.

## Cómo ejecutar las pruebas
Godot local: `herramientas/runtime/Godot.app/Contents/MacOS/Godot` (no está en el PATH). Detalle en ESTADO.md §4.
- Lugares: suites `prueba_lugares`, `prueba_lugares_ui` y `prueba_lugares_red`; captura con render `captura_lugares.gd`. Evidencia en `production/qa/evidence/mundo-1/fase-4/`. Para desarrollo, pruebas específicas y pocas semillas; reservar batería completa/100 semillas para cierres de funcionalidades o fase y no repetir comprobaciones no afectadas.
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

## Rama IA 2 — cuentas y servidor (26/10/2026)

Trabajo autorizado y separado de Fase 5 en `feature/cuentas`, base Fase 4 `6bb89f5`. Nuevo menú de servidor con puerto UDP 7777, HTTPS 7778 y contraseña opcional independiente de cada cuenta; registro/login con SQLite y Argon2id, HTTPS y DTLS con certificado validado, ID de cuenta estable y un personaje en el guardado existente. No duplica inventario/mundo ni modifica generación, economía o progresión.

Validación de esta rama: cuatro casos unitarios Python; 35 comprobaciones de integración con procesos reales; cinco de autoguardado/cierre inesperado; interfaz iniciando/cerrando en 7777/7778; regresión final **36 de 37 suites**. Permanece únicamente el fallo previo de hashes E04/E05; las adaptaciones de rutas temporales y CRLF para probar en Windows están detalladas. Localhost y conexión a la IP LAN propia ejecutados; **no otra computadora ni Internet real**. No se incorporó la skin en pausa.

Leer [CUENTAS_Y_SERVIDOR](Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md), [ADR-0002](docs/architecture/adr-0002-cuentas-locales-seguras.md) e [informe](production/qa/evidence/cuentas/INFORME.md). Iniciar desde `Iniciar-Servidor.bat` después de `Instalar-Cuentas.bat`. El comando histórico `--servidor` sigue siendo legado sin cifrado; no es la entrada nueva para Internet. Coordinar cambios compartidos de escena/HUD/red y documentación antes de integrar con IA 1; esta rama no se fusionó con main.

### Hashes de arte revisados (26/10/2026)

El fallo previo E04/E05 quedó corregido: CRLF del checkout Windows y un hash de catálogo pendiente de actualizar desde el arte aprobado `44f6f09`. Se mantienen los PNG y las entradas originales; manifiesto con procedencia y JSON fijados a LF. Auditoría 96/96, general 330/0 y visual 60/0; informe en `production/qa/evidence/arte-hashes/INFORME.md`. No asumir que se repitió toda la batería histórica. La corrección es separable de la rama de cuentas.
