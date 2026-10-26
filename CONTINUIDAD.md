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
- **Prioridad actual — taller y casas comunales funcionales**: continuación autorizada `M1-ED2` implementada. B → E ofrece Taller terminado (mesa/horno/cofre, 115 madera + 41 fibra + 10 piedra). Las dos comunidades preexistentes de mundos nuevos usan casas comunales completas, con dos camas, taller y único cofre económico integrado, campos afuera y rutas accesibles. Depósito resuelto como anexo funcional de almacenamiento; no hay razón actual para un edificio separado. Resultados y límites actuales: ESTADO.md §3j; contrato [ARQUITECTURA_EDIFICIOS_MUNDO_1 §8](docs/investigacion/ARQUITECTURA_EDIFICIOS_MUNDO_1.md).
- **Alcance para continuar**: Vivienda y Taller construibles; variante de casa comunal solo de génesis. Se conservan mecánicas/precios/tasas y puestos económicos del jugador (sin conversión gratis ni encarecimiento). No se ha reemplazado la casa fija del Valle. Planos/etapas siguen preparados, ejecución terminada de una vez. Ampliación/demolición, personalización y construcción progresiva pendientes; no bloquean la expansión. Fases 5b/6 y cuentas/autenticación fuera del alcance. Usar mundo nuevo compatible; sin migración diseñada.
- **Commits de esta continuación**: `0a443ce` (taller) y `9afd242` (casas comunales e integración regional); documentación en commit posterior. Los seis commits anteriores de Fase 5a/vivienda ya se subieron a `origin/main`.
- **Cierre de taller/comunidades**: **45 de 46 suites sin fallos**; único fallo conocido del manifiesto de arte E04/E05 (`prueba`: 329 PASS + 1 FAIL). Taller 11/7/36 PASS en núcleo/UI/dos clientes, fabricación y entrada de NPC reales; comunidades 16/15/26 PASS, 20 semillas al cierre, tres días con reinicio equivalente, determinismo y reservas compartidas. Hashes completos de legado idénticos a vivienda (dos semillas, cuatro días). Evidencia en `production/qa/evidence/mundo-1/taller/`; capturas inspeccionadas.
- **Cierre de vivienda**: commits `c0f1fe8` (núcleo persistente) y `8483789` (jugabilidad/red). Núcleo 29 PASS, UI 8 PASS y ENet con dos clientes 33 PASS. Batería completa 42/43, solo el fallo previo de arte. Hashes completos de legado (dos semillas, cuatro días) idénticos a Fase 5a. Evidencia en `production/qa/evidence/mundo-1/vivienda/`; capturas inspeccionadas. Nueva capa de suelo y catálogo sellado en huella de reglas: usar mundo nuevo compatible, sin migración diseñada de guardados antiguos.
- **Implementado de Mundo 1**: Fase 0 (herramientas de medición y línea base), paso 1a/1b (registro `mundo.poblados` y lectores por poblado) y **Fase 1 completa (1c aparición en el pueblo, 1d hitos y estaciones comunitarias, 1e slimes fuera del núcleo)**. Detalle y limitaciones: ESTADO.md §3d.
- **Fases 2 y 3 completas** (autorizadas el 26/10): mapa personal con M, flechas, +/− e Inicio; verde = observado, ocre = contado; E → L en conversación intercambia información con NPC cercano. Catorce pistas opcionales, T para descartar y Esc para silenciar/reactivar; descubrimientos, fuentes e historial persisten por jugador y se replican solo a su dueño. Commits `8669f62` y `7fa3e74`. Pruebas y límites: ESTADO.md §§3e–3f.
- **Fase 4 completa** (autorizada el 26/10): lugares compartidos y persistentes por macrorregión, ruinas, campamentos vacíos con mesa/cofre y entradas de cuevas, rutas transitables y visibles en M al observarlas. E examina el lugar; E → L transmite referencias de NPC; Av/Re Pág pagina referencias del mapa. Commits `a2548f6` y `3634a67`; contrato y resultados en ESTADO.md §3g. Protocolo de red 8.
- **Fase 5a implementada (autorización nueva del 26/10)**: dos comunidades preexistentes en mundos nuevos de modo poblado, La Hondonada y Los Sauces. Commits `b0453de` (núcleo) y `b476dac` (integración y evidencia). Reutilizan `Asentamientos`: residentes identificables, cosechas y extracción reales a distancia, rutas de `Lugares`, mapa personal y referencias que pueden circular por encuentros cercanos entre NPC. E/L/V/J integrados; `mundo.poblados` se replica también en vivo. El Valle sigue siendo inicial provisional; hay aparición alternativa validada en otra comunidad. Detalle: ESTADO.md §3h.
- **Límite de la entrega y próximo paso**: 5b (materialización resumido↔detallado) continúa aplazada según M1-F5; no hay doble actor al acercarse. Antes de 5b hay que cerrar transferencia atómica de recursos/memoria/identidad y red. No iniciar Fase 6 ni trabajar en cuentas/autenticación, a cargo de otra IA. Fase 7 tampoco se implementó en esta entrega. Usar mundo nuevo para evaluar la génesis; no se diseñó migración de guardados anteriores. Las cuevas siguen teniendo solo entrada.
- **Cierre de 5a**: 39 de 40 suites sin fallos tras verificaciones dirigidas; único fallo previo de arte. La corrida completa fue 38/40: se adaptaron los escenarios de rechazo total de aparición a la existencia de otros pueblos y se verificó `prueba_aparicion` (32 PASS). El ajuste posterior de prioridad del cofre pasó UI 13, red 26 y lugares UI 10; no se repitieron suites no afectadas. Evidencia en `production/qa/evidence/mundo-1/fase-5/`; 14/13/26 PASS en núcleo/UI/red, 20 semillas al cerrar, tres días resumidos con reinicio exactamente equivalente y dos clientes ENet reales. Hashes completos de legado en dos semillas por cuatro días idénticos a Fase 4. Sin cambios de tasas, economía ni progresión.
- **Cierre verificado de Fase 4 (26/10)**: 36 de 37 suites sin fallos; única falla previa de arte. Núcleo: 8/8 archivos de medición idénticos en legado. Integración: hashes completos de dos semillas durante cuatro días idénticos. Tres suites nuevas (13, 10 y 19 PASS), expansión en vivo con dos clientes y capturas inspeccionadas. En ese cierre no se modificó balance ni se inició Fase 5.
- **Cierre verificado de Fases 2–3 (26/10)**: 33 de 34 suites sin fallos; única falla previa de arte. Hashes completos de legado idénticos antes/después de cada funcionalidad (dos semillas, cuatro días), batería determinista 8/8 igual. Sin cambios de balance. Evidencia y resumen final en `production/qa/evidence/mundo-1/fase-3/`.
- **Fallo de hashes E04/E05 resuelto (26/10)**: se identificaron CRLF de Windows y el hash anterior al catálogo aprobado; auditoría 96/96, general y visual sin fallos. Ver `production/qa/evidence/arte-hashes/INFORME.md`. Los fallos registrados en cierres anteriores son históricos.

## Cómo ejecutar las pruebas
Godot local: `herramientas/runtime/Godot.app/Contents/MacOS/Godot` (no está en el PATH). Detalle en ESTADO.md §4.
- Taller: `prueba_taller`, `prueba_taller_ui`, `prueba_taller_red`; `captura_taller.gd` muestra también las casas comunales. Evidencia en `production/qa/evidence/mundo-1/taller/`.
- Vivienda: `prueba_vivienda`, `prueba_vivienda_ui`, `prueba_vivienda_red`; `captura_vivienda.gd` para render. Evidencia en `production/qa/evidence/mundo-1/vivienda/`.
- Comunidades: `prueba_preexistentes`, `prueba_preexistentes_ui`, `prueba_preexistentes_red`; captura `captura_preexistentes.gd`. Desarrollo usa dos semillas; batería completa activa 20 (`LINDE_VALIDACION_COMPLETA=1`, o `--extenso` al núcleo). Evidencia en `production/qa/evidence/mundo-1/fase-5/`.
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

**Nota de cierre de validación:** Una repetición adicional de red pasó vivienda 33/33 y taller 35/36: el cliente B no alcanzó a observar el daño antes de que A reparara. La corrida completa anterior pasó 36/36; queda pendiente sincronizar esa observación en el escenario de prueba. No se modificó el juego después de la batería completa.
## Rama IA 2 — cuentas y servidor (26/10/2026)

Trabajo autorizado y separado de Fase 5 en `feature/cuentas`, base Fase 4 `6bb89f5`. Nuevo menú de servidor con puerto UDP 7777, HTTPS 7778 y contraseña opcional independiente de cada cuenta; registro/login con SQLite y Argon2id, HTTPS y DTLS con certificado validado, ID de cuenta estable y un personaje en el guardado existente. No duplica inventario/mundo ni modifica generación, economía o progresión.

Validación de esta rama: cuatro casos unitarios Python; 35 comprobaciones de integración con procesos reales; cinco de autoguardado/cierre inesperado; interfaz iniciando/cerrando en 7777/7778; regresión final **36 de 37 suites**. Permanece únicamente el fallo previo de hashes E04/E05; las adaptaciones de rutas temporales y CRLF para probar en Windows están detalladas. Localhost y conexión a la IP LAN propia ejecutados; **no otra computadora ni Internet real**. No se incorporó la skin en pausa.

Leer [CUENTAS_Y_SERVIDOR](Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md), [ADR-0002](docs/architecture/adr-0002-cuentas-locales-seguras.md) e [informe](production/qa/evidence/cuentas/INFORME.md). Iniciar desde `Iniciar-Servidor.bat` después de `Instalar-Cuentas.bat`. El comando histórico `--servidor` sigue siendo legado sin cifrado; no es la entrada nueva para Internet. Coordinar cambios compartidos de escena/HUD/red y documentación antes de integrar con IA 1; esta rama no se fusionó con main.

### Hashes de arte revisados (26/10/2026)

El fallo previo E04/E05 quedó corregido: CRLF del checkout Windows y un hash de catálogo pendiente de actualizar desde el arte aprobado `44f6f09`. Se mantienen los PNG y las entradas originales; manifiesto con procedencia y JSON fijados a LF. Auditoría 96/96, general 330/0 y visual 60/0; informe en `production/qa/evidence/arte-hashes/INFORME.md`. No asumir que se repitió toda la batería histórica. La corrección es separable de la rama de cuentas.

## Integración autorizada con main (26/10/2026)

El usuario autorizó push y merge de cuentas y hashes. Se incorporó `origin/main` `42bef50` (Fase 5a y primera vivienda funcional) sin conflictos y se verificó la versión combinada: **10/10 suites seleccionadas**, **35/35 comprobaciones de cuentas** y formularios reales de inicio/cierre. Evidencia y alcance exacto: [cuentas-main](production/qa/evidence/cuentas-main/README.md). No se repitió toda la batería de 43 suites. Continúan sin verificar otra computadora física e Internet público.

Esta nota supera el estado histórico anterior de «rama separada, sin merge». El fallo de hashes de arte está corregido; no debe seguir tratándose como pendiente. Mantener los módulos de cuentas junto con las ampliaciones de viviendas/comunidades de IA 1. La skin permanece en pausa.

## Acceso antes del menú e identidad única (26/10/2026)

El usuario pidió **iniciar sesión/registrarse antes del menú** y eligió cuenta única entre PC. Ajuste desarrollado en `feature/login-inicial` sobre `d223398`, todavía fuera de main. La autoridad de cuentas es independiente del mundo (TCP7790); después de validar se ofrece continuar, nueva/cargar partida, alojar, unirse y cerrar sesión. No se repite el registro ni la contraseña global al elegir mundo. Guardados locales propios, varias partidas y última selección; progreso de mundos compartidos en su servidor.

Ver [ADR-0003](docs/architecture/adr-0003-identidad-antes-del-menu.md), [guía actualizada](Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md) y [evidencia](production/qa/evidence/login-inicial/README.md). Validación: 8 casos unitarios, 16 comprobaciones de flujo UI/guardado, 13 de identidad con dos mundos y 7 suites de regresión, sin fallos. No se verificó otra PC física ni Internet público. Las pruebas de corrupción imprimen errores JSON esperados; ObjectDB/recursos siguen siendo avisos conocidos. Las partidas locales no se sincronizan en nube; los archivos individuales/cuentas anteriores no se migran en silencio. La skin permanece en pausa.

### Formularios alineados con el arte del juego (26/10/2026)

Pulido local de `feature/login-inicial`: reutiliza E06 y tipografías existentes para registro, acceso, alojamiento/conexión, configuración y partidas; opciones avanzadas plegables. Capturas reales y 16/16 comprobaciones del flujo aislado superadas. El usuario pidió también quitar el mínimo de contraseña; continúa obligatoria con máximo 128 y cinco casos unitarios del servicio superados. Detalle en [evidencia](production/qa/evidence/login-inicial/README.md). Galería local `outputs/Acceso_estetica/GALERIA.html`. No se publicaron estos ajustes; no tocar la skin en pausa ni el checkout original.

## Integración de taller con login y servidor (26/10/2026)

Merge autorizado de `9c0d1c4` (taller/casas comunales) y `d223398` (cuentas, servidor y hashes). Se conservan ambos trabajos; conflictos limitados a notas añadidas en documentación, resueltos manteniendo ambas. El fallo de arte mencionado en el cierre histórico del taller ya está corregido por el trabajo integrado de IA 2. No se agregan funcionalidades ni se repiten baterías extensas.

Verificación mínima del merge: `prueba_taller_ui` **7 PASS/0 FAIL** (escena combinada, plano/precio, construcción y acceso a mesa, horno y cofre). Módulos de cuentas y red idénticos a `origin/main`; núcleo de edificios y asentamientos idéntico al cierre del taller.


## Integración publicada de acceso inicial con main (26/10/2026)

El usuario autorizó subir la revisión completa. Integrado origin/main `c84b88e` mediante `cdac6e9`, conservando talleres, casas comunales y tareas de Fase 6. Esta nota supera las notas históricas de revisión sin publicar. Validación combinada: 9 casos unitarios, 16 de acceso/partidas, 13 de identidad con dos mundos, 6 suites de regresión y tareas 16/16. [Detalle y límites](production/qa/evidence/login-inicial/main-c84b88e/README.md). Sin prueba externa ni cambios a la skin.

## Continuar Fase 7: ecología territorial (26/10/2026)

Rama de trabajo `feature/fase7-ecologia` sobre main `eb022a4`; no merge/push autorizados para esta fase. Diseño obligatorio versionado: [DISENO_MAESTRO_FASE7](docs/investigacion/DISENO_MAESTRO_FASE7.md); contrato existente actualizado: [FAUNA_Y_PELIGROS](Linde/cenital/docs/FAUNA_Y_PELIGROS.md). Primer bloque: perfiles abreviados/explícitos, validación y consulta pura de hábitat integrados en Fauna, sin cambiar distribución, reglas selladas ni persistencia. Evidencia: [hábitats](production/qa/evidence/mundo-1/fase-7/habitats/README.md), con 23 comprobaciones nuevas y equivalencia exacta en 5.046 regiones; base fauna31/terreno49, regresión fauna31 y red exterior localhost1. No declarar terminada la fase ni verificados P2/señales/Internet.

Siguiente: aprobación humana de distribución/calmas/lugares antes de modificar posiciones/densidades/dificultad. No añadir reproducción, migración, simulación global o economía dependiente de Fase 6. `LINDE_Fase_7_investigacion_ecologia.md` no estaba en el repo ni junto a los adjuntos: ubicación solicitada, pendiente. Mantener la skin en pausa y el checkout original intacto.


### Investigación ecológica localizada (26/10/2026)

El usuario volvió a indicar la carpeta y ya se encontró y leyó íntegra [LINDE_Fase_7_investigacion_ecologia.md](docs/investigacion/LINDE_Fase_7_investigacion_ecologia.md). Se incorpora como referencia sin alterar el diseño maestro ni el alcance autorizado: stock, reproducción, migración y efectos económicos siguen aplazados. Esta nota supera el pendiente de localización anterior. Sin cambios de código ni repetición de pruebas en este complemento; la redistribución territorial sigue pendiente de propuesta/aprobación.

### Siguiente decisión: propuesta A de ubicaciones (26/10/2026)

Prototipo y [galería comparativa](production/qa/evidence/mundo-1/fase-7/propuesta-ubicacion/GALERIA.html) preparados, no activados en el juego. Mismas cantidades/especies por región; preferencias de vecinos cardinales con vegetación/roca o despejados, y retorno al punto original si no hay alternativa. 2.523 regiones: 2.271 apariciones, 904 puntos propuestos diferentes; conservación/orden inverso/estado puro y regresión hábitats23. Investigación complementaria ya localizada y leída (`6f78a6b`). Antes de continuar con activación se requiere decisión humana de distribución y persistencia versionada; no sustituir planes de partidas existentes. No merge/push.


### Preferencias A aprobadas y activación v2 (26/10/2026)

El usuario aprobó las preferencias de ubicación. Mundos nuevos poblados guardan `d.fauna.distribucion` v2 y una copia de los datos declarativos; los existentes permanecen v1 sin mover sus puntos, bajas o heridas. Modificar defaults no reescribe mundos guardados y una política desconocida rechaza carga con motivo explícito. Cantidades, especie, ID, bioma y región conservados; mismo generador/candidatos, reglas globales selladas intactas. No se activa migración de mundos ni cambios de balance.

Verificado: distribución **17/17**, compatibilidad/hábitats **23/23**, fauna **31/31**, cuentas/reconexión real con dos mundos locales **13/13**; los dos guardados llevan v2. [Informe y límites](production/qa/evidence/mundo-1/fase-7/activacion-v2/README.md). Sin otra PC/Internet. Avisos de recursos conocidos al salir. Siguiente: señales de fuentes reales y propuesta de calma/lugares; R/T y otros cambios territoriales no están aprobados. Rama `feature/fase7-ecologia`, sin merge/push. Esta nota supera el pendiente de aprobación A de las notas anteriores.
