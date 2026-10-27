# Linde — registro de decisiones y procedencia

> **Este es el índice único de decisiones del proyecto.** Cada fila apunta al lugar donde viven los fundamentos y las alternativas; no se duplican aquí. Estado vigente del juego: [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md). Política de mantenimiento: [CLAUDE.md](../../../CLAUDE.md#documentación-qué-leer-y-cómo-mantenerla).
>
> **Al añadir una decisión**: una fila en el índice (ID, fecha, estado, enlace) y el fundamento junto a su sistema o en la iniciativa. Estados: *Propuesta* (reversible, sin aprobar), *Usuario* (decisión expresa del usuario), *Vigente*, *Reemplazada por X*.
> **Visión original** (para contrastar): [LINDE_Punto_de_Inicio](../../documentos/LINDE_Punto_de_Inicio/01_VISION_Y_DECISIONES.md) y [game-brief](../../../design/game-brief.md).
> La cabecera «23 oct 2026» del archivo anterior era el momento de su creación; las secciones de abajo son de fechas distintas, anotadas en cada una.

## Índice

### A. Decisiones técnicas del prototipo cenital (este archivo, 23–24/10)
| ID | Tema | Estado | Dónde está el fundamento |
|---|---|---|---|
| P03–P06 y sin ID | Movimiento, celda, mapa de autor, sin avance con la app cerrada; reglas de inventario, botín, construcción, misiones, habilidades, jefes | Propuesta | Sección «Decisiones» más abajo |
| A01 | Combate en tiempo real provisional | Propuesta, pendiente | «A01 — Combate» |
| — | Estado por jugador y mundo compartido (formato 2) | Propuesta, vigente | «Estado por jugador y mundo compartido» |
| — | Servidor autoritativo «mundo anfitrión» (A04) | Propuesta, vigente (protocolo hoy en versión 8) | «Red: servidor autoritativo»; [ADR-0001](../../../docs/architecture/adr-0001-multijugador-mundo-anfitrion.md) |
| RED-C1 | Cuentas SQLite/Argon2id, acceso privado opcional y HTTPS/DTLS | Usuario (26/10) | [ADR-0002](../../../docs/architecture/adr-0002-cuentas-locales-seguras.md), [guía](CUENTAS_Y_SERVIDOR.md) |
| RED-P1 | Servidor privado estilo Forge sin VPN/relay; perfil local sin cuenta global y acceso privado por dirección/contraseña; conservar flujo global como alternativa | Usuario (26/10), implementación pendiente de validación Godot | [Guía y límites](SERVIDOR_PRIVADO.md), [plan](CUENTAS_Y_SERVIDOR.md#8-servidor-dedicado-estilo-forge--implementación-sin-validación-godot-26102026) |
| RED-C2 | Cuenta única de Linde e inicio de sesión antes del menú; identidad independiente de los mundos | Usuario (26/10) | [ADR-0003](../../../docs/architecture/adr-0003-identidad-antes-del-menu.md), [guía](CUENTAS_Y_SERVIDOR.md) |
| — | Equipo v1 (familias, piedras, Chispa, sets) | Propuesta, vigente | «Equipo v1» y [sistema-de-equipo.md](../../documentos/sistema-de-equipo.md) |
| — | Arte de equipo por colores índice; ataque con celda 48 | Propuesta, vigente | Secciones «Arte de equipo…» y «Ataque con equipo» |
| — | Arte nuevo por defecto; integración estética E01–E06; dibujo procedural retirado | Usuario (24/10) | «Arte nuevo por defecto» e «Integración estética completa» |
| — | Origen retirado, semilla fuera del creador, ranura de arma | Usuario (24/10) | «Origen retirado…» |

### B. Decisiones del epic mundo-vivo (24/10, del usuario)
Servidor siempre encendido, sin congelar el mundo; crecimiento mixto (los hitos abren posibilidades y la construcción las concreta); Ordal presente desde el inicio; dormir no salta el reloj; llegada = variable `<id>_presente`; «cama de huésped» como pieza nueva; plantilla de prueba «Una cama de huésped» (15 XP + 2 fibra); clientes ven la llegada pero no el panel de misiones; agentes de implementación con Sonnet 5.5. Fundamentos: [README del epic](../../../production/epics/mundo-vivo/README.md) (§ Decisiones del usuario) y [ESTADO archivado §4](../../../docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md).

### C. Decisiones del usuario sobre dirección (24/10)
| Decisión | Estado | Dónde |
|---|---|---|
| Estilo visual de «arte vivo» aprobado **provisionalmente** (25/10, cinco capturas); 49 llamadas de dibujo por código aceptadas como excepciones específicas; la regla de usar sprites para el arte nuevo sigue vigente | Usuario (25/10, provisional) | [Excepciones de dibujo por código](#excepciones-de-dibujo-por-código-usuario-2510-provisional) |
| La autonomía es el modo principal; el juego nace de las decisiones del jugador, no de una campaña; campaña del cap. 1 retirada de la partida principal | Usuario (vigente; la activación por defecto se hizo en paralelo, ver ESTADO) | [ESTADO archivado §11](../../../docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md), [AUTONOMIA](AUTONOMIA.md) |
| La población no tiene número objetivo; `max_habitantes` es solo un techo técnico | Vigente | ESTADO archivado §13 |
| Gente buena y mala: honestidad, codicia y rencor; propiedad y hurto también para el jugador | Usuario | ESTADO archivado §13, [PROTECCION_Y_ECONOMIA](PROTECCION_Y_ECONOMIA.md) |

### D. Iniciativa «Innovación emergente» (25/10, investigación)
- 9 decisiones tomadas por el usuario para el plan: [PLAN_IMPLEMENTACION §1](../../../docs/investigacion/innovacion-emergente/PLAN_IMPLEMENTACION.md).
- D01–D12 (recomendaciones con evidencia y alternativa evaluada, todas *Propuesta*): [DECISIONES de la investigación](../../../docs/investigacion/innovacion-emergente/DECISIONES.md). Allí viven las alternativas; no se copian aquí.

### F. Mundo 1 (26/10, del usuario)
Dirección de diseño aprobada. Visión: [VISION_MUNDO_1.md](../../../design/VISION_MUNDO_1.md). Auditoría, fases y fundamentos: [PLAN_MUNDO_1.md](../../../docs/investigacion/PLAN_MUNDO_1.md). Los ID llevan el prefijo `M1-` para no chocar con D01–D12 de la investigación (sección D). **Es diseño objetivo: nada de esto está implementado** salvo lo que [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md) registre. Los valores numéricos (radios, umbrales, límites) quedan pendientes de medición y aprobación; no hay cambios de balance sin ellas (M1-D14).

| ID | Decisión | Estado |
|---|---|---|
| M1-D1 | Inicio en un pueblo habitado y coherente con Mundo 1, con aparición segura y comprensible | Usuario (26/10) |
| M1-D2 | Los jugadores de una misma partida comienzan en posiciones cercanas y válidas | Usuario (26/10) |
| M1-D3 | Mundo persistente compartido con varios asentamientos preexistentes y fundación autónoma; las semillas generan y amplían | Usuario (26/10) |
| M1-D4 | Mapa de exploración personal, compartible; los NPC transmiten información aproximada de lugares | Usuario (26/10) |
| M1-D5 | Instalaciones comunitarias coherentes con los oficios del pueblo y sujetas a las reglas del mundo | Usuario (26/10) |
| M1-D6 | Evolución visible y persistente de construcciones, caminos, cultivos, habitantes, asentamientos y territorios | Usuario (26/10) |
| M1-D7 | Aprendizaje contextual y opcional; sin tutorial obligatorio ni misiones artificiales | Usuario (26/10) |
| M1-D8 | Los hitos de 15 y 60 minutos evalúan la experiencia; no son requisitos para el jugador | Usuario (26/10) |
| M1-D9 | Mapa consultable con M; sin minimapa permanente como requisito inicial | Usuario (26/10) |
| M1-D10 | Destinos significativos y accesibles; el resultado generado del mundo compartido se conserva | Usuario (26/10) |
| M1-D11 | Ruinas, campamentos y cuevas son el alcance inicial, no un límite | Usuario (26/10) |
| M1-D12 | Dificultad territorial orgánica (ecología, amenazas, recursos, acontecimientos); sin escalado por nivel ni regiones bloqueadas | Usuario (26/10) |
| M1-D13 | Ningún pueblo es inmortal; si el inicial deja de ser viable, los nuevos jugadores aparecen en otra comunidad segura | Usuario (26/10) |
| M1-D14 | Sin cambios de balance (XP, fabricación, daño, recompensas, progresión) sin mediciones y aprobación | Usuario (26/10) |
| M1-N1 | El Valle se transforma en el pueblo inicial aprovechando lo existente, **sin conservar obligatoriamente su estructura ni identidad anterior**; el resultado es una comunidad coherente de Mundo 1 | Usuario (26/10) |
| M1-N2 | Empezar con 1–2 pueblos preexistentes adicionales; alcance inicial, no límite | Usuario (26/10) |
| M1-N3 | Registro persistente de poblados, lugares y caminos; generación determinista, independiente del orden de exploración, que conserva sus resultados; **la generación controlada se distingue de la simple carga de regiones** | Usuario (26/10) |
| M1-N4 | Reutilizar y generalizar `Asentamientos`; sin un sistema paralelo de pueblos | Usuario (26/10) |
| M1-N5 | Límites técnicos configurables por poblado y globales, sujetos a medición; no son límites permanentes del diseño | Usuario (26/10) |
| M1-N6 | Viabilidad = comida, camas, residentes y seguridad, con información ya existente; umbrales pendientes de medición y aprobación | Usuario (26/10) |
| M1-F0 | Fase 0: medir el ritmo actual con pruebas acotadas; no se bloquea el avance por falta de playtests humanos | Usuario (26/10) |
| M1-F5 | Fase 5a: pueblos preexistentes con habitantes identificables, actividad económica y evolución observable (simulación resumida al inicio). Fase 5b (transición resumido↔detallado) es objetivo de diseño, aplazable hasta resolver identidad, recursos y red | Usuario (26/10) |
| M1-AUT6-TOTAL | Completar todos los bloques de Fase 6 que permitan decisiones aprobadas, con autonomía/commits y sin rehacer bloques previos; habilita abordar comercio, migración y fundación, pero exige consultar balance/arquitectura importante/contradicciones y no aprobar automáticamente recomendaciones del diseño maestro | Usuario (26/10) |
| M1-VIA6 | Viajes con velocidad actual de NPC, mochila existente y consumo regional por viajero; rutas/distancias/tiempos reales, identidad/carga durables, consumo material, interrupción/cancelación/reinicio coherentes; sin teletransporte, pérdidas aleatorias ni bonos. [Contrato](AUTONOMIA.md#contrato-de-tránsito-y-comercio) | Usuario (26/10) |
| M1-AUT6C | Continuación autorizada: conectar saldos colectivos a producción/consumo regionales con resultados reales persistentes, reutilizando Sociedad/Autonomía/Asentamientos; sin balance nuevo, comercio entre pueblos, migración ni fundación. Pruebas puntuales, documentación y commits en rama propia. [Contrato](AUTONOMIA.md#fase-6--saldos-y-operaciones-regionales-26102026) | Usuario (26/10) |
| M1-AUT6B | Continuación autorizada: demandas colectivas con stock/reservas/compromisos y trabajo en curso; descontar atención individual; preparar conexión resumida, sin comercio entre pueblos, migración, fundación ni balance nuevo. Pruebas puntuales, documentación y commits. [Contrato](AUTONOMIA.md#fase-6--consolidación-colectiva-26102026) | Usuario (26/10) |
| M1-AUT6 | Fase 6 autorizada: comenzar por necesidades → demandas → tareas → resultados persistentes reutilizando sistemas; autonomía para implementar, validar puntualmente, documentar y confirmar. Sin modificar decisiones/balance ni ampliar alcance. [Contrato](AUTONOMIA.md#fase-6--primer-bloque-causal-26102026) | Usuario (26/10) |
| M1-F6 | Fase 6: la fundación autónoma depende de necesidades y condiciones reales, no de eventos programados | Usuario (26/10) |
| M1-F7 | Fase 7: dificultad orgánica, sin escalado por nivel ni cambios de balance sin medición | Usuario (26/10) |
| M1-F7-C | Cerrar Fase7 en esta ejecución: resolver navegación y oportunidades reales de decisión reutilizando distancias, velocidades, tiempos y combate existentes. No inventar balance ni garantías de seguridad/R/T. Si falta un parámetro, derivar de mecánicas existentes o conservar el actual y documentar. Revisión breve, pruebas focalizadas y commits; sin reproducción, migración ni economía ecológica. [Cierre](../../../production/qa/evidence/mundo-1/fase-7/cierre/README.md) | Usuario (26/10, autorización final) |
| M1-AUT7 | Iniciar Fase 7 incremental según [diseño maestro](../../../docs/investigacion/DISENO_MAESTRO_FASE7.md), empezando por hábitats; conservar compatibilidad, determinismo y autoridad. Sin densidades/dificultad nuevas ni reproducción, migración o dependencias económicas de Fase 6; consultar decisiones territoriales importantes. Commits en rama separada, sin merge a main | Usuario (26/10) |
| M1-F7-A | Aprobadas las preferencias A: mismas cantidades/especies/regiones, espectros junto a vegetación, gólems junto a roca/vetas, arpías/diablillos en espacios despejados y slimes en su orilla. Activación versionada sin mover fauna de mundos existentes; [contrato](FAUNA_Y_PELIGROS.md) | Usuario (26/10) |
| M1-F7-B | Aprobada B: evitar nacimientos agresivos sobre rutas y núcleo existente de 12 celdas; anclar algunas amenazas a ruinas/cuevas de su región; posponer sin ubicación compatible, aunque reduzca presencia local. Criaturas activas pueden entrar por persecución; activar sin migrar mundos existentes. [Contrato](FAUNA_Y_PELIGROS.md) | Usuario (26/10) |
| M1-P | Los pueblos **no son zonas mágicamente seguras** (pueden sufrir ataques, perder habitantes y desaparecer); un jugador nuevo, sin embargo, no aparece junto a un enemigo sin posibilidad razonable de reaccionar. 1c es la solución de aparición; 1e, la corrección de la ecología y distribución de amenazas del núcleo inicial | Usuario (26/10) |
| M1-C1 | Política provisional de aparición «fuera del radio de detección (`vision`) de los enemigos vivos», **solo en modo `poblado`**; no sustituye P05 ni la regla de 12 celdas del modo `legado`; sin invulnerabilidad ni cambios en los slimes; transitoria hasta 1e. Condicionada a medir los primeros segundos tras aparecer (hecho: `production/qa/evidence/mundo-1/fase-1c/`) | Usuario (26/10) |
| M1-C2 | Radio de aparición 2–7 celdas y separación mínima 2: **valores de prueba, no de balance**. Se validan ocupación, construcciones, terreno, conectividad y enemigos; el hash solo ordena la búsqueda, nunca sustituye las comprobaciones | Usuario (26/10) |
| M1-C3 | `_derrota` sin cama usa el mismo sistema de validación (commit separado); la reaparición con cama válida no cambia | Usuario (26/10) |
| M1-C4 | Interruptor por mundo `poblado` / `legado` con equivalencia completa del legado; sin respaldo a una celda no validada ni a la entrada; recuperación explícita sin posiciones seguras (`unir` rechaza con motivo registrado; `_derrota` deja al jugador donde cayó); una comunidad destruida no se reactiva para dar cabida a nadie | Usuario (26/10) |
| M1-C5 | Alternativa A: ancla estable y reconocible del poblado (`poblado.centro`); no se persigue a los NPC ni se alteran sus rutinas para garantizar compañía | Usuario (26/10) |
| M1-ED1 | Arquitectura aprobada: catálogo pequeño de vivienda, taller y depósito (no obligatorios por asentamiento), con piezas/objetos internos existentes. Planos y construcción progresiva como dirección, puertas automáticas y modificaciones por reparación/ampliaciones. Primera entrega: vivienda terminada funcional y arquitectura preparada para etapas; no bloquear Fase 5 por implementar progresión completa. Validar interior/accesibilidad/techo/NPC/persistencia/red antes de extender; trabajo autónomo con pruebas/commits, sin interferir con rama de cuentas | Usuario (26/10) |
| M1-ED2 | Continuación autorizada de Fase 5: taller funcional con estaciones/recetas existentes, evaluar depósito como anexo y adaptar puestos regionales a edificios completos cuando corresponda. Sin nuevas mecánicas, cambios de balance, construcción progresiva o personalización avanzada; pruebas con dos clientes, documentación y commits. Implementación: taller y casa comunal de génesis, almacenamiento integrado; puestos económicos del jugador conservados. [Contrato §8](../../../docs/investigacion/ARQUITECTURA_EDIFICIOS_MUNDO_1.md#8-taller-y-comunidades-con-edificios-completos-2610) | Usuario (26/10) |
| M1-ED0 | Antes de continuar ampliando Fase 5, revisar construcciones y presentar diagnóstico, alternativas, costos y decisiones. Dirección actual: catálogo limitado de edificios completos y funcionales en lugar de construcción libre por piezas; priorizar entradas claras, interiores transitables continuos, techos y compatibilidad persistente/multijugador/NPC. No implementar cambios importantes todavía ni interferir con otra IA. Tipos concretos y arquitectura de la propuesta pendientes de aprobación | Usuario (26/10) |
| M1-AUT5 | Fase 5 autorizada desde el cierre de Fase 4: pueblos preexistentes adicionales, determinismo, persistencia, rutas, mapas e información entre NPC. Mantener El Valle provisional; reutilizar sistemas, sin alterar balance/economía/progresión. Pruebas proporcionales y batería completa al cerrar, documentación y commits. No iniciar Fase 6 ni tocar cuentas/autenticación (otra IA). Se conserva la separación 5a/5b de M1-F5 | Usuario (26/10) |
| M1-F4 | Fase 4 autorizada: lugares persistentes compartidos (ruinas, campamentos y entradas de cuevas) y rutas; reutilizar generación, exploración, NPC y guardado; independencia del orden de exploración. Ejecución autónoma y commits por funcionalidad. No iniciar Fase 5; pruebas específicas durante implementación y extensas solo al cerrar | Usuario (26/10) |
| M1-F23 | Fases 2 y 3 autorizadas con autonomía para diseñar, implementar, probar y confirmar por funcionalidad; mapa personal M, descubrimientos persistentes, intercambio con NPC y pistas contextuales opcionales. Sin avanzar a Fase 4 ni cambiar balance | Usuario (26/10) |
| M1-AUT | Fase 1 (pasos 1c, 1d y 1e) autorizada con ejecución autónoma, commits separados, pruebas durante el desarrollo y batería completa al cerrar cada paso; sin cambios de balance, progresión o economía sin evidencia; sin alterar el modo legado. Detenerse solo ante decisiones que contradigan lo aprobado, regresiones irresolubles, cambios significativos de balance, dependencias que exijan reestructurar sistemas ajenos o imposibilidad de garantizar una aparición segura | Usuario (26/10) |

### E. Otros registros
[ADR-0001 multijugador](../../../docs/architecture/adr-0001-multijugador-mundo-anfitrion.md) · [canon de trabajo](../../../design/narrative/canon-de-trabajo.md) · [registro de entidades](../../../design/registry/entities.yaml) · [deuda técnica](../../../docs/tech-debt-register.md).

---

## Ejecutar
> Los recuentos de este bloque son del 23/10 y están superados; los comandos y suites vigentes están en [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md#4-cómo-verificarlo).
- Jugar: `Iniciar-Cenital.command` (args tras `--`: `--guardado=ruta`, `--nueva=SEMILLA`, `--panel=inv|craft|hab|mis`, `--ir=x,y`).
- Lógica: `Godot --headless --path Linde/cenital --script res://tests/prueba.gd` → 213 PASS, 0 FAIL (cifra del 23/10).
- UI real (menú→creador→partida→paneles→guardar→continuar): `--script res://tests/prueba_ui.gd` → 12 PASS (cifra del 23/10).
- `tests/capturas/`: fotogramas reales de la escena (casa, cantera, lago, ruinas, panel).
- Los "ERROR: Parse JSON failed" que imprime la prueba de persistencia son esperados: se corrompen archivos a propósito.

## Controles
WASD/flechas mover · Espacio golpear/atacar · E interactuar · I inventario · C fabricar · K habilidades · J misiones · B construir (Q/E pieza, Espacio colocar, X retirar) · F5 guardar · F1 cajas · Esc pausa. Autoguardado cada 30 s y al cerrar.

## Qué existe (módulos en `scripts/`)
| Módulo | Contenido |
|---|---|
| `catalogos.gd` | Ítems, objetos rompibles, construcciones, recetas, habilidades, enemigos/jefes, misiones, diálogos. `validar()` comprueba referencias, ciclos y alcanzabilidad |
| `mundo.gd` | Mapa de autor 64×48 (aldea, cantera, bosque, estanque, ruinas), objetos con ID, construcciones, colisión, BFS, inicio por semilla |
| `juego.gd` | Autoridad única: recolección, fabricación, construcción, cofres, misiones, progresión, jefes, tiempo, dormir |
| `inventario.gd` | Operaciones atómicas todo-o-nada con capacidad por pilas |
| `guardado.gd` | Formato versionado + checksum, `.tmp`→validar→`.bak`, corrupto se conserva como `.corrupta`, migraciones |
| `combate.gd` | Combate en tiempo real provisional, jefes con fases |
| `habitantes.gd` | Maren: necesidades→actividad→ruta→ejecución |
| `escena.gd`, `hud.gd`, `arte.gd`, `apariencia.gd` | Presentación, interfaz, arte procedural, PJ en capas |

> **Nota (2026-10-25)**: el título de esta sección es del 23/10. Las decisiones del usuario posteriores (secciones B y C del índice) prevalecen sobre esta tabla; `arte.gd`, `apariencia.gd` y `capas_sprite.gd` se retiraron (ver «Retirado» más abajo). Se conserva el texto original.

## Decisiones (todas Propuesta, reversibles; ninguna es decisión del usuario)
| ID | Decisión | Dónde |
|---|---|---|
| P03 | 4 direcciones sin diagonales | `Mundo.dir_cardinal` |
| P04 | Celda 16 px, PJ 16×24, ancla en pies, zoom entero 3 | `params.gd` |
| P05 | Mapa de autor fijo; la semilla solo elige un inicio exterior alcanzable, con 3×3 libre y ≥12 celdas de enemigos/jefes | `Mundo.punto_inicio` |
| P06 | Sin avance del mundo con la app cerrada; al dormir el jugador se recoloca a Maren según su rutina (no se simula el intervalo) | `Habitantes.resincronizar` |
| — | Día = 24 min reales (1 s = 1 min de juego) | `catalogos.gd MIN_POR_SEG` |
| — | Roca a mano (10 golpes) para evitar el ciclo pico↔piedra; con pico 4 | `catalogos.gd` |
| — | Inventario 20 pilas; si no cabe el botín, el objeto no se rompe; recompensas de jefe/misión que no caben quedan pendientes, nunca se pierden ni duplican | `Inventario`, `Juego` |
| — | Botín probabilístico con flujo propio por (semilla, objeto, hora): cargar no lo cambia. Contenido del tesoro fijado al crear la partida | `Juego._rng` |
| — | Construir: huella 1×1, no sobre objetos/actores, y se rechaza si cierra un lugar esencial o encierra al jugador. Retirar devuelve 100 %; solo piezas propias; cofre con contenido no se retira | `Juego.construir/retirar` |
| — | Misiones: condiciones *actuales* (tener, construcción en pie) se miden ahora y pueden perderse; *históricas* (visita, jefe, cofre abierto, hablar) usan hechos guardados. Recompensa una sola vez (`recompensas`) | `Juego.objetivo_ok/entregar` |
| — | Habilidades: puntos = nivel−1; efectos se calculan desde las aprendidas (no se acumulan al cargar). **No hay reasignación de puntos** | `Juego.stats` |
| — | Mejor arma = el ítem con más daño en el inventario (sin ranura de equipo) | `Juego.stats` |
| — | Jefe de capítulo no reaparece; jefe de mundo reaparece a las 72 h de juego. La recompensa se da por cada derrota y se registra por clave | `Combate`, `Juego.jefe_derrotado` |

## A01 — Combate (PENDIENTE, modelo provisional)
Alternativa recomendada y usada: tiempo real, cuerpo a cuerpo hacia donde mira el PJ (aviso 0,1 s, activo 0,1 s, recuperación 0,25 s). Todo ataque enemigo tiene señal previa y recuperación; los jefes cambian de fase al 50 %/40 % con un ataque nuevo (onda/pisotón), no solo más vida. Muerte provisional: sin pérdida de objetos, vuelves a tu cama (o al inicio) con media vida y el encuentro se reinicia. Todos los números en `catalogos.gd` son placeholders sin balance.

## Procedencia
- Código, datos y arte propios. **No se copió código, tablas ni valores** de Blocktest, MineWorld, Source of Mana, Cataclysm-DDA, LibColony ni Helbreath; no hay assets de Helbreath ni Pokémon. Las tasas de MineWorld (hambre/cansancio) no se usan: la energía de Maren (−4/h, +12/h) es propia y provisional.
- La estructura de recetas (entradas, estación, herramienta, salidas) sigue la idea general de Cataclysm-DDA pero no usa su formato ni datos (CC BY-SA no aplica al no copiar).
- Arte: dibujado por código, inspirado en la referencia visual (`Linde/documentos/LINDE_Punto_de_Inicio/referencias/visual_objetivo.png`) sin copiarla. Es provisional; la hoja de estilo y los sprites finales siguen pendientes.
- Textos de diálogo y misiones (Maren, taller, cantera, ruinas, Guardián, Gran Ciervo) son **contenido de prueba**, no canon (A02 abierto).

## Límites conocidos / no verificado
- No se jugó a mano: la sensación de movimiento y combate no está afinada; solo hay pruebas automáticas y capturas.
- Un único habitante (Maren). Sin comercio ni economía (A03). Sin multijugador en red (A04); el estado ya separa jugador y mundo (ver al final).
- Creador de PJ mínimo (nombre, 3 pieles, 4 pelos, 3 ropas, origen, semilla); sin equipo visible ni capas de armas.
- Sin sonido. Sin animaciones de ataque ni de herramienta específicas; la caminata sí tiene 4 cuadros.
- Enemigos no persisten posición; los slimes reaparecen al cargar (simulación local).
- La carga de la partida no valida reglas de negocio más allá del checksum y el formato.

> **Histórico**: `capas_sprite.gd` ya no existe; el arte por capas lo sustituyó el sistema de equipo (`arte_equipo.gd`). Se conserva como registro.

## Personaje por capas desde hojas PNG (`scripts/capas_sprite.gd`)
- Qué es: cargador opcional. Lee `res://arte/personaje.json` (`{"celda": 32, "capas": [...]}`) y una hoja `res://arte/personaje_<capa>.png` por capa. Si falta el manifiesto o alguna hoja, o una hoja no mide 4·celda × 4·celda, `disponible()` es false (con `errores` y aviso) y `escena.gd` sigue con el dibujo procedural (`Apariencia`).
- Formato de hoja: 4 columnas (cuadros de caminata 0..3) × 4 filas (frente, derecha, espalda, izquierda). Ancla = centro inferior de la celda, alineado con los pies del jugador; se dibuja con filtro nearest.
- Orden: constante `ORDEN_POR_DIRECCION` (capas de abajo a arriba por orientación). Casco, coraza, escudo y espada solo se dibujan si están en el `equipo` pasado a `dibujar` (hoy `[]`, el equipo aún no es visible). Espalda usa el mismo orden que frente.
- Lateralidad (sin resolver): se supone que al mirar a la derecha se ve el costado derecho (escudo detrás, espada delante). Para invertirla, intercambiar las listas de `Vector2i.RIGHT` y `Vector2i.LEFT` en esa constante.

## Equipo y defensa (PROVISIONAL; sustituido por «Equipo v1», al final)
- Ítems con `"equipo"` (ranura casco|coraza|escudo) y `"def"`; estado `d.equipo` {ranura: item|""}. Todos los valores (def 2/4/3, recetas) son propios y provisionales, sin balance heredado.
- `equipar`/`desequipar` en `juego.gd` son atómicos (usan `Inv.cambiar`/`Inv.anadir`): con inventario sin hueco no cambia nada y se avisa; equipar sobre ranura ocupada devuelve el ítem anterior en la misma operación.
- `stats().def` es la suma de `def` de lo equipado (derivada, no se acumula). `danar_pj`: daño efectivo = `max(1, n - def)`. El arma sigue siendo el mejor `dmg` del inventario.
- Guardado: `d.equipo` se guarda con el resto; partidas sin la clave la reciben por defecto en `cargar` (sin subir `FORMATO`).
- UI: panel `inv` con sección «Equipado» (Enter desequipa), «(equipar)» en equipables, Def en cabecera. Al dibujo por capas se pasan las ranuras equipadas más `"espada"` si hay `espada_hierro` en el inventario; el procedural no dibuja equipo.

## Estados de animación del jugador (PROVISIONAL)
- `C.ANIM_PJ` (catalogos.gd) declara estado -> cuadros y tiempos; `scripts/anim_pj.gd` decide estado y cuadro (función pura) con prioridad dano > ataque > herramienta > caminar > reposo. El daño solo tapa al ataque en la animación; `combate.est` no cambia. `juego.herr_t` (0.3 s al golpear un objeto) y `juego.anim_pj(mov, t_mov)` arman el contexto. F1 muestra `anim: estado #cuadro` en el HUD.
- Hojas por estado (opcionales): manifiesto `personaje.json` con `"estados": {"herramienta": {"cuadros": 3}, ...}` y archivos `personaje_<estado>_<capa>.png` (4 filas de orientación x `cuadros` columnas, mismo `celda`). Capa o estado sin hoja válida cae a la hoja base de 4x4 (como hoy); los errores van a `errores_estado` y a `push_warning` sin desactivar el personaje.
- Aún sin uso: `caida` y `dormir` (declarados; derrota y dormir no cambian). Todos los cuadros y tiempos son provisionales.

## Estado por jugador y mundo compartido (PROVISIONAL, primer paso hacia «mundo anfitrión», A04)
El juego sigue siendo de un jugador; el comportamiento observable no cambia. `Juego` sigue siendo la única autoridad.

**Modelo de estado (`d`, guardado formato 2)**
- Compartido (raíz de `d`): `semilla`, `min` (reloj), `mundo` (rotos, golpes, constr), `cofres`, `jefes` (derrotas, historial y hora de caída, que gobierna la reaparición), `npcs` (posición, energía, actividad).
- Por jugador (`d.jugadores[id]`): `nombre`, `look`, `origen`, `pos`, `hp`, `cama`, `inicio`, `inv`, `equipo`, `hab`, `xp`, `misiones`, `recompensas` (claves de misión y de jefe), `eventos` (`visito_*`, `hablo_*`, `abrio_*`), `pendientes`, `relacion` {npc: n}.
- Sesión (no se guarda salvo `pies` → `pos`): `Juego.rt[id]` = {pies, mira, cd_obj, herr_t, msgs}; `Combate.pjs[id]` = ciclo de ataque (est, t, inv_t, dir).
- Todas las acciones de `Juego` reciben `id` (último parámetro, por defecto `P.LOCAL` = "local"). `unir(id, nombre, look, origen)` añade un jugador. Compatibilidad: `j.jug(id)` devuelve el estado del jugador; `j.pies`, `j.mira`, `j.cd_obj`, `j.herr_t`, `j.msgs` y `combate.est/t/inv_t/dir` son accesores del jugador local.
- Construcciones: `{t, propia, dueno}`. Solo el `dueno` las retira y cuentan para *sus* misiones de construcción. Las estaciones (mesa, horno) y los cofres construidos los usa cualquiera. No se puede construir algo que encierre a *ningún* jugador.
- Avisos por jugador; los del mundo (jefe derrotado, cambio de postura) van a todos.

**Reglas de objetivo y botín**
- Cada enemigo persigue al jugador más cercano: empieza si está dentro de `vision`, cambia de objetivo cada paso si otro queda más cerca y abandona a más de 2×`vision`. El objetivo se fija al iniciar el aviso; el golpe se evalúa solo contra él (otro jugador en el área no recibe daño; revisar al diseñar combate en grupo).
- Daño, invulnerabilidad y derrota se aplican al jugador objetivo. Derrota con un solo jugador: igual que antes (se reinicia el encuentro). Con varios: solo el derrotado vuelve a su cama/inicio; los enemigos que lo perseguían vuelven a reposo y nada más cambia.
- Golpe final: xp, `drops` del enemigo y `recompensa` del jefe van al jugador que dio el golpe que lo mata (sin reparto). Los golpes previos de otros no dan nada. Los golpes acumulados sobre objetos del mundo (rocas, árboles) también son compartidos: quien remata recibe el botín.
- El jefe derrotado lo está para el mundo (`jefes`): no aparece para nadie y cuenta como «derrotar» en las misiones de todos los jugadores. Igual con «abrir» el tesoro (se vacía una vez para el mundo; el contenido lo recibe quien lo abre).
- Misiones, relación con habitantes, `hablo_*` y habilidades son por jugador.
- Pendiente: dormir adelanta el reloj compartido para todos (con varios jugadores habrá que exigir que duerman todos o no saltar el tiempo). La escena solo dibuja al jugador local.

**Migración**
- `Guardado.FORMATO = 2`. `Guardado.migrar` encadena v0→v1→v2. 1→2: `pj` y las claves `inv, equipo, hab, xp, misiones, eventos, recompensas, pendientes` pasan a `jugadores["local"]`; `npcs[*].relacion` pasa a `jugadores["local"].relacion`; las construcciones con `propia: true` reciben `dueno: "local"`. `Juego.cargar` sigue completando `equipo` si falta. Pruebas: `t_migracion_v1` (guardado formato 1 sintético) y `t_multi` (dos jugadores) en `tests/prueba.gd`.

## Red: servidor autoritativo «mundo anfitrión» (historia 002, PROVISIONAL)
Código: `scripts/red_servidor.gd`, `scripts/red_cliente.gd` (con la réplica `Replica`), cambios mínimos en `escena.gd`/`hud.gd` y en los bucles de `juego.gd`/`combate.gd` (recorren `rt`, los presentes, no `d.jugadores`). Base medida en `prototypes/red-minima/`. Un jugador sin red funciona igual que antes.

**Cómo alojar y unirse**
- Alojar con ventana: menú «Alojar partida». Carga la partida (`--guardado`, por defecto `user://partida.json`) o crea una nueva, y abre el puerto 7777 (UDP). El anfitrión es un jugador más (id `local`); su escena guarda como siempre (F5, pausa, cada 30 s, al cerrar).
- Servidor sin ventana: `Godot --headless --path Linde/cenital -- --servidor [--puerto=7777] [--guardado=ruta] [--semilla=N] [--duracion=s] [--registro=ruta.json]`. Sin interfaz; guarda cada 30 s y al cerrarse limpiamente (`--duracion`, cierre de la ventana o `quit`). Un `kill -9` pierde como mucho 30 s. Sin `--guardado` usa `user://mundo_servidor.json`; si el archivo no existe crea un mundo con `--semilla` (incluye un jugador «Anfitrión» inactivo).
- Unirse: menú «Unirse» → dirección `IP:puerto`, nombre y clave (se propone un token aleatorio; se recuerda en `user://red.cfg`). El aspecto es el del creador.
- Conectividad: solo IP directa (LAN, puerto abierto a mano o VPN entre amigos). **No hay relay ni NAT traversal** (ver red-minima).

**Protocolo** (ENet, nodo `/root/Red` en los dos lados, mismos 3 RPC)
- `pedir(datos)` cliente→servidor, fiable. Primero `["hola", VERSION, nombre, clave, look, origen]`; después intenciones `[tipo, seq, ...]`: `mov dir` (se mantiene hasta otra), `accion mira`, `interactuar mira`, `dormir`, `construir pieza celda`, `retirar celda`, `fabricar`, `usar`, `equipar`, `desequipar`, `aprender`, `aceptar`/`entregar` (misiones de catálogo), `aceptar_plantilla`/`entregar_plantilla` (instancias del mundo, procesadas por el servidor), `mover_cofre cid item hacia_cofre`.
- `evento(datos)` servidor→cliente, fiable: `bienvenida` (estado completo al entrar), `rechazo`, `mundo` (secciones cambiadas: rotos, golpes, constr, cofres, jefes), `privado`, `perfiles` (nombre y aspecto de los presentes), `interaccion` (respuesta a E: diálogo, cofre...).
- `instantanea(datos)` servidor→clientes, 20 Hz, `unreliable_ordered`: reloj `min`; por jugador presente posición, dirección, animación, hp, fase de ataque e invulnerabilidad; enemigos (tipo, posición, estado, hp, ataque en curso); habitantes (posición, actividad). Si el tamaño serializado supera 1200 bytes se usa el RPC fiable para no fragmentar datagramas no fiables; el protocolo aún envía la instantánea completa por cliente.
- El cotejo de secciones durables, perfiles y estado privado se ejecuta a 4 Hz (cada 250 ms); las instantáneas de movimiento siguen a 20 Hz. Así se reduce serialización repetida, con hasta 250 ms de demora para reflejar cambios durables.
- `rpc "authority"` en `evento`/`instantanea`: el motor descarta los que envíe un cliente. `server_relay = false`.

**Privado y compartido**
- El estado privado (inventario, equipo, xp, habilidades, misiones, eventos, recompensas, pendientes, relación, cama, mensajes) solo se envía a su dueño y solo cuando cambia; el servidor coteja cambios a 4 Hz. Nunca sale el hash de la clave.
- A todos: lo de la instantánea (incluido el reloj, que va ahí y no como evento: se corrige solo si se pierde una) y los eventos `mundo`/`perfiles`, cotejados a 4 Hz.
- Réplica del cliente (`Replica extends juego.gd`): no avanza la simulación; aplica instantáneas y eventos, y sus acciones (fabricar, construir...) se convierten en pedidos. El jugador propio es `local` en la réplica (las piezas propias pasan a `dueno: local`; las del anfitrión a `anfitrion:local`). La posición mostrada se suaviza hacia la del servidor; la dirección de mirada es local y viaja con cada acción.

**Identidad**: id = `@` + nombre en minúsculas (2-16 letras, cifras, espacio, `_`, `-`: nunca choca con `local`). Primer ingreso: se guarda `{sal, hash}` = SHA-256(sal:clave) en el jugador. Reentrar exige la clave; incorrecta o jugador ya conectado → rechazo y corte. Al desconectarse el personaje se retira del mundo (`Juego.salir`: guarda su posición, sin cuerpo ni sesión) y al volver reaparece ahí con todo su estado. ponytail: SHA-256 con sal, no un KDF lento; vale para el alcance del ADR (amigos), no para contraseñas reutilizadas.

**Validaciones del servidor (nunca se confía en el cliente)**: tipo exacto de cada argumento, longitud de textos ≤ 32, ids contra los catálogos, direcciones solo cardinales, celdas dentro del mapa y a ≤ 2 celdas (Chebyshev) del jugador para construir/retirar/cofres, cofres solo construidos (`c@x,y`) y cercanos, misiones con quien las da solo hablando, `seq` estrictamente creciente por conexión (un pedido repetido no se aplica dos veces), máximo 40 pedidos/s por conexión, 10 s para identificarse. El movimiento es solo dirección: el servidor integra `P.VELOCIDAD × vel × 0,05 s` por tick con la colisión de siempre. Todo pedido rechazado se cuenta (`registro.rechazos`) y no cambia el estado. Las reglas de juego (materiales, propiedad, alcance de estaciones, cooldowns) las sigue aplicando `Juego`.

**Límites**: 15 clientes (ENet; el 16º expira sin mensaje), throttle `throttle_configure(5000, 2, 0)` y timeout de caída 1-3 s por peer. Sin predicción ni compensación de latencia: con latencia alta el propio movimiento se nota retrasado. Dormir sigue adelantando el reloj de todos (pendiente). Sin cifrado ni contraseña de mundo. El dibujo de los demás es el procedural (sin capas ni equipo). Prueba de integración: `tests/prueba_red.gd` (servidor + clientes `tests/bot_red.gd` como procesos en localhost); resultados en `tests/resultados_red.txt`.

## Equipo v1: familias, piedras, Chispa y sets (implementación de `Linde/documentos/sistema-de-equipo.md`, PROVISIONAL)
**Qué hay**
- `scripts/equipo.gd`: funciones puras sobre claves `eq:<familia>:<ranura>:<variante>:<nivel>` (`leer`, `construir`, `info`, `existe`, `stats_pieza`, `stats_de`, `bono_set`, `finales`, `dano`, `mejorar`, `cambiar_variante`, `recetas`, `visible`, `validar_datos`). `leer` exige la forma canónica exacta (`02`, `+1`, mayúsculas o 6 campos no valen). Todo nombre/pila/estadística de ítem pasa por `Equipo.info` (inventario, juego, hud, escena, red); una clave desconocida es «Pieza desconocida» (pila 1, no equipable) y nunca rompe nada.
- Datos (todos PROVISIONALES) en `datos/equipo/`: `arquetipos.json` (ranuras, arquetipos y constantes: topes 25 %, VEL [0,70, 1,30], K 20, topes de bono 12/10 %, razón de potencia 1,20), `familias.json` (Vigía, Zarzal, Albor + paletas índice), `variantes.json` (Divino, Brillante, Oscuro, piedras y deltas de paleta), `joyas.json` (Chispa de Temple, `NIVEL_MAX` 5, `K_N` 0,10, costes 1-1-2-3-4). `catalogos.validar()` llama a `Equipo.validar_datos` (5 piezas distintas, referencias, ids únicos y sin `:`, no dominancia de variantes incluida «sin piedra», razón de potencia, umbrales 2..5 crecientes, topes de bono, costes de mejora y alcanzabilidad de recetas, caídas y jefe repetible).
- `C.RANURAS` = casco, torso, guantes, botas, pantalones, escudo. Fuera `casco_hierro`/`coraza_hierro` y sus recetas; `escudo_madera` se conserva (def plana 3).
- `juego.gd`: `equipar` (ranura sacada de la clave), `desequipar`, `stats()` con 3.1/3.2 (sumas sin redondeo, un solo `floor` al final con épsilon 1e-6, VEL `snappedf` 0,0001 y en [0,70, 1,30]), `bono_set()`, `danar_pj` = `max(1, round(n*20/(20+DEF)))`, `fabricar` con `Equipo.recetas()` (recetas `vigia_<ranura>` en mesa + artesano, `chispa`), `mejorar(clave)` y `engarzar(clave, variante)` sobre una pieza del inventario o equipada (atómicos), `intercambiar(a, b, de_a, de_b)` (todo o nada, ambos lados validan cabida), `caida_equipo(fuente)` (Zarzal) y botín de Albor en `jefe_derrotado`.
- Guardado `FORMATO 3`: migración 2->3 encadenada tras 1->2 (por jugador, en inventario, pendientes y equipo: `casco_hierro`->`eq:vigia:casco::0`, `coraza_hierro`->`eq:vigia:torso::0`, ranura `coraza`->`torso`, ranuras nuevas `""`). Lo desconocido se conserva. Al cargar, lo que no es equipable en su ranura pasa a `pendientes` con `push_warning` (no se pierde ni duplica).
- Red: pedidos nuevos `mejorar [clave]`, `engarzar [clave, variante]`, `ofrecer [destino, dar{}, pedir{}]` y `aceptar_oferta [origen]` (oferta en memoria del servidor; se borra al desconectarse cualquiera; `Juego.intercambiar` la aplica). `equipar`/`usar`/`mover_cofre` validan con `Equipo.existe`. Texto máximo por argumento 32 -> 48.
- UI: panel `I` con estadísticas finales (Def, Vida, Vel), bono de set activo, las 6 ranuras con nombre completo (Enter quita) y piezas de la mochila (Enter equipa); panel nuevo `F` «Forja» (Enter: mejorar o engarzar una piedra que tengas). Los paneles largos se desplazan con la selección. `_equipo_visible` pasa a `capas_sprite.gd` las entradas de `Equipo.visible` (ranura, arquetipo, silueta, paleta y delta); hoy solo se usa la ranura (`torso` muestra la hoja `coraza` existente). Capturas: `tests/capturas/equipo_inv.png`, `equipo_forja.png`.

**Decisiones de implementación (no estaban en el documento)**
- El escudo suma su `def` plana a `def_eq` (y por tanto recibe el `def_pct` del set); no cuenta para el bono.
- Piedras: caen de objetos del mundo como aproximación de su zona (Alma de arbustos 10 %, Armonía de árboles 10 %, Bendición de vetas 15 %), añadidas al final del mismo flujo de botín (no cambia lo que ya caía). Chispa: receta en horno con artesano (1 gema + 1 lingote). Números provisionales.
- Zarzal cae de los slimes (no hay enemigos por zona); la tirada es de quien da el golpe final (como el resto del botín). Flujo `_rng("eq:zarzal", "<id>:<intento>")`; tras 15 fallos seguidos la siguiente es segura (texto de la sección 4). Albor: una pieza que falte (inventario, equipo o pendientes) al que remata al Gran Ciervo; con el set completo, una cualquiera.
- `stats().hp` incluye la vida del equipo; la vida actual no se recorta al quitarse piezas (igual que antes con habilidades).

**Pruebas** (`tests/prueba.gd`): `t_equipo2` cubre los 12 criterios del documento y además obtención (recetas, farmeo, jefe), nombres y tabla 3.3; `t_red` añade pedidos con claves `eq:`, rechazos, serialización `var_to_bytes` y la oferta de intercambio. Pruebas cambiadas por el paso a 6 ranuras: `t_equipo` (mismas comprobaciones con piezas de Vigía; el daño con DEF 4 pasa de 6 a 8 por la fórmula proporcional), `t_migracion_v1` (formato 3, casco migrado, vida +3), `t_red` (la ranura inválida de prueba pasa de `botas`, ahora válida, a `alas`), `prueba_ui.gd` (abre también el panel `F`).

**Límites / pendiente**
- Intercambio: sin interfaz (solo función y pedidos de red probados); la réplica del cliente no expone `ofrecer`.
- En la regla de empate 3.5, «si ninguna tiene torso ni casco, ningún bono» es inalcanzable con 5 ranuras (un empate 2+2 sin torso ni casco necesitaría 4 de las 3 ranuras restantes); se prueba torso, casco y 1+1.
- Sin arte por arquetipo ni recoloreado por índice (solo datos); evidencia visual en `tests/capturas/`, no en `production/qa/evidence/` (fuera de `Linde/cenital/`).
- `retirada: true` de familias y la recompensa única del Guardián no se implementan (fuera de la v1).


## Arte de equipo por colores índice (lote 1, `Linde/arte-entregado/equipo_indice_01`, OPCIONAL y PROVISIONAL)
**Qué se integró**
- `arte/equipo/`: copia sin cambios de las 17 hojas (`hojas/`) y de la base (`base/caminata.png`, `base/capas/*.png`) con `manifiesto.json` propio (celda 32, pivote 16/32, filas frente/derecha/espalda/izquierda, 4 cuadros, colores índice y sha256 de cada hoja). Antes de copiar se pasó `herramientas/arte/validar_hoja.gd --modo=indice --celda=32 --base=base/caminata.png` a las 17: salida 0, 0 errores, 0 avisos (igual que `RESUMEN_VALIDACION.json`).
- `scripts/arte_equipo.gd`: render por capas. Recoloreado por CPU (`Image`, sin shaders): cada índice (#ff0000 principal, #00ff00 sombra, #0000ff acento, #808080 detalle) -> color de la paleta de la familia -> delta de la variante en HSV (tono suma con vuelta; saturación y brillo suman y se recortan). Un rol que la paleta no define no se recolorea (el gris sin «detalle», contrato d). Caché por (arquetipo, ranura, familia, variante); la base, por apariencia.
- Cada pieza usa la hoja del arquetipo de su familia (`familias.json`); escudo y espada usan las hojas compartidas (espada solo con `espada_hierro` en el inventario, como antes). Escudo de madera y espada de hierro tienen paleta propia (`"paleta"` en `C.ITEMS`).
- Orden por orientación del contrato (e); `INVERTIR_PERFILES` (en `arte_equipo.gd`, por defecto `false` = como el contrato) intercambia los perfiles también en `capas_sprite.gd`. Ocultación PROPUESTA: torso -> túnica base, pantalones -> pantalón base, botas -> botas base; cinturón, pelo y resto no se ocultan; el pelo va bajo el casco.
- Caminata con el cuadro de `anim_pj` (estado `caminar`); cualquier otro estado (reposo, herramienta, ataque, daño) usa el cuadro 0 de la caminata.
- Base con la apariencia: piel, pelo y túnica se tiñen con `look` (P.PIEL/P.PELO/P.ROPA) conservando el sombreado (valor relativo a la media de la máscara); el pantalón con `P.PANTALON`. Cuerpo residual (contorno, ojos), botas y cinturón quedan con su color original: `look` no define colores para ellos.
- Red: `perfiles()` del servidor envía también `equipo` y `espada` de cada jugador (se reenvía solo cuando cambia, como antes); los jugadores remotos se dibujan con su equipo real cuando el arte está activo.
- Escena: el procedural sigue siendo el valor por defecto; F2 alterna al arte nuevo (si falta el manifiesto, la base o cualquier hoja, `disponible()` es false: se usa la hoja antigua `arte/personaje_*` si existe y si no, el procedural, sin error). Argumentos de depuración: `--arte`, `--equipo=<familia>:<variante|sin_piedra>` (set completo + escudo + espada), `--mira=frente|derecha|espalda|izquierda`.

**Paletas (PROVISIONALES)**: `datos/equipo/paletas.json` es ahora la única fuente de paletas de familia (Vigía, Zarzal, Albor; mismos valores que antes estaban en `familias.json`) y de deltas (sin piedra = 0, Divino, Brillante, Oscuro; antes en `variantes.json`). `familias.json` y `variantes.json` solo guardan los ids. `Equipo.validar_paletas` (llamado desde `catalogos.validar()`): roles conocidos, principal/sombra/acento obligatorios, colores válidos y distintos de los índices, `sin_piedra` presente, deltas numéricos en [-1, 1], paletas de ítems existentes.

**Pruebas y capturas**: `t_arte_equipo` en `tests/prueba.gd` (recoloreado exacto y sin índice residual en las 17 hojas con 4 combinaciones, gris sin «detalle», orden por orientación e inversión, ocultación, pieza sin paleta, pivote/cuadro, caché, tinte de la base, caída sin manifiesto o sin hojas, hash de las 17 copias contra el manifiesto y contra `design/art`, validación de paletas). Capturas en el motor (movie mode, cuadro 25, reposo): `tests/capturas/arte_equipo_<zarzal|albor>_<orientación>.png` y `arte_equipo_resumen.png` (fila 1 Zarzal ligera sin piedra, fila 2 Albor pesada Oscuro).

**No logrado / pendiente**
- Sin animación de equipo para herramienta, ataque ni daño (lote 2 del contrato, celda 48): en esos estados el arte nuevo muestra el cuadro 0 de caminata; la hoja antigua de acciones no se mezcla con el equipo.
- Mano lejana de guantes y armas en perfiles sin revisar a fondo; lateralidad, ocultación del cinturón y recorte del pelo bajo el casco siguen abiertos (contrato g).
- Sin colores de apariencia para botas, cinturón y ojos; las paletas son técnicas, no aprobadas por arte.
- Evidencia visual en `tests/capturas/`, no en `production/qa/evidence/` (fuera de `Linde/cenital/`).


## Ataque con equipo (celda 48)
**Análisis de `ataque.png`** (biblioteca_01, solo lectura; copia en `arte/equipo/ataque/referencia/`). 4 poses por fila = preparado (espada baja), anticipación (espada alzada sobre el hombro), impacto (barrido con estela; en perfiles, estocada con piernas abiertas) y recuperación (espada baja con resto de estela). Cuerpo ~27 px, mismo tamaño que la caminata; pies en la fila 47 de la celda 48 = fila 31 de la celda 32: caminata -> ataque es una traslación fija (+8, +16) (pivote 16/32 -> 24/48, mismo suelo). Posiciones de mano medidas por celda en `arte/equipo/ataque/manifiesto.json` (`manos`).

**Fases -> poses** (`anim_pj.gd`, `C.ANIM_PJ.ataque.cuadros = 4`): aviso = preparado (primera mitad, 0,05 s) y anticipación (segunda mitad); activo = impacto; rec = recuperación. Duraciones de combate sin cambios.

**Derivación** (`herramientas/arte/derivar_ataque.gd`, reproducible; `-- --revision=<dir>` escribe imágenes de revisión):
- Espada fuera del cuerpo: acero/estela por color (gris azulado claro), su contorno oscuro que no toca color de cuerpo, empuñadura marrón pegada a acero y puño, e islas < 8 px junto a la espada. Los huecos que tapaba se rellenan con el color vecino mayoritario (vecinos >= 3). Resultado: `base/ataque_sin_espada.png` y 7 capas base (`base/capas/`, mismas que caminata; clasificación por color y altura relativa a cabeza/pies). La espada visible es solo la capa de equipo (si hay `espada_hierro`).
- Piezas rígidas (casco, torso, pantalones, botas, por arquetipo): para cada dirección y pose se busca el cuadro de caminata y la traslación (±10, ±8) que maximizan el IoU de la referencia (pelo, túnica, región de piernas y > 23, región de pies y > 26) entre caminata y ataque; se copia esa celda de la hoja de caminata. Aceptación: IoU >= 0,38 y <= 12 % de la pieza fuera de la silueta (1 px); si no, celda vacía y PENDIENTE (umbrales propios, elegidos revisando las imágenes: 0,33 en frente/impacto deja hombreras en el aire; 0,39-0,44 en espalda queda bien).
- Guantes: los píxeles de piel de cada mano medida (pesada: + el contorno que la rodea). Escudo: forma de caminata desplazada con la mano libre (mismo desplazamiento mano->escudo que en caminata); si la caminata no muestra esa mano o el escudo sale del cuerpo, anclado al torso. Espada: los píxeles separados, en índice (acero claro principal, resto sombra, empuñadura acento); se descartan el anillo de 1 px de la celda y las islas de estela a más de 1 px del cuerpo y de la espada (frente/rec, derecha/impacto y rec, espalda/rec, izquierda/anticipación; listadas en PENDIENTE_DE_ARTE.md: hace falta una capa de efecto).
- Validación `validar_hoja.gd --celda=48 --modo=indice --base=ataque.png`: 11 hojas sin errores; las 6 con celdas pendientes fallan solo la comprobación 5 (celda vacía), a propósito.

**Render** (`arte_equipo.gd`): conjunto opcional `arte/equipo/ataque/manifiesto.json`; en estado `ataque` base y piezas en celda 48 con el cuadro = pose, orden e `INVERTIR_PERFILES` del contrato, ocultación igual; pieza con celda pendiente -> no se dibuja ni oculta su capa base, se ve la pose de `ataque.png` (antes caía al cuadro 0 de caminata, que en las tiras quedaba suelto: torso pesada en derecha/rec, bota de contorno negro en izquierda/impacto); pieza sin hoja de ataque -> cuadro 0 de caminata. Donde `ataque.png` pinta la espada sobre el cuerpo (`espada_delante`, medido por los píxeles rellenados al quitarla) la espada pasa delante del torso aunque el perfil la ponga detrás (arregla izquierda/recuperación); caminata e `INVERTIR_PERFILES` no cambian. Sin conjunto: caminata, sin error. Jugador local y remotos (`estado`/`cuadro` ya viajaban por red). Las capas base de ataque se tiñen con la media de la caminata (sin salto de tono).

**Evidencia**: `--auto-ataque` (escena) ataca cada 0,8 s con el ciclo real y escribe fase/cuadro/pose sobre el PJ y una línea `AUTOATQ` por cuadro. Tiras de un ciclo completo (movie mode, 30 fps, `--always-on-top`: con la ventana tapada macOS no dibuja y movie mode repite el cuadro) montadas con `tests/tira_ataque.gd`: `tests/capturas/ataque_<zarzal|albor>_<dirección>.png` (Zarzal = ligera, Albor = pesada). `t_ataque_equipo` en `tests/prueba.gd` (incluye «ninguna pieza suelta»: islas de cada capa a más de 1 px del cuerpo base; falló con las estelas sueltas antes de corregir la derivación).

**Pendiente de arte** (lista exacta en `arte/equipo/ataque/PENDIENTE_DE_ARTE.md`): torso en frente/impacto (los 3 arquetipos) y pesada en derecha/impacto y recuperación; botas en derecha/impacto (ligera, media) e izquierda/impacto (ligera): la estocada abre las piernas y una traslación no la sigue; escudo en frente/impacto (no se ve la mano libre).

**Límites vistos en las tiras**: el escudo va anclado al torso (no a la mano) en izquierda (las 4 poses: la caminata no muestra esa mano) y en derecha/preparado y recuperación (anclado a la mano quedaba fuera del cuerpo); en derecha/impacto el escudo queda tapado por el cuerpo (detrás del torso, como pide el contrato); en las celdas pendientes falta esa pieza durante la pose; en espalda/anticipación queda piel visible junto a la empuñadura; torsos con partes de brazo (brazales de ligera, hombreras de pesada) siguen al torso, no al brazo. Sin hojas de herramienta ni daño. Evidencia en `tests/capturas/`, no en `production/qa/evidence/`.


## Arte nuevo por defecto (2026-10-24)
**Instrucción del usuario:** la línea de arte anterior (dibujo procedural) no debe salir más. `usar_arte` arranca en `true` en `escena.gd` y se quitó la tecla F2 que alternaba al dibujo procedural. Hoy solo el personaje y su equipo usan sprites; mundo, enemigos, habitante, efectos e interfaz siguen procedurales hasta ejecutar `Linde/documentos/PLAN_ESTETICA_2_SESIONES.md`, que los reemplaza y retira `arte.gd` y las rutas procedurales. Los argumentos `--arte` y `--equipo=` siguen disponibles solo con `--nueva=`.


## Integración estética completa (2026-10-24)
Se integraron los seis entregables de arte (E01–E06, candidatos sin aceptación artística) y se retiró el dibujo por código anterior.
- **Mundo (E04+E05):** `scripts/mundo_arte.gd`, datos en `arte/mundo/` (manifiesto con sha256). Terreno por 47 conexiones, agua animada de 4 cuadros, árboles de 64 px con copa translúcida, estados agotados (tocón, roca, veta, arbusto), vallas conectadas, cofres, barril, casa modular (interior, fachada, puerta, tejado que se oculta al entrar) y construcciones (el fantasma de construir es la misma textura tintada).
- **Actores (E03):** `scripts/actores_arte.gd`, `arte/actores/`. Slime, Guardián y Ciervo (9 columnas × 4 direcciones), residuo de derrota, efectos de impacto, daño y recolección. Los eventos se deducen de cambios confirmados; un cliente de red no deduce reacciones por enemigo (el snapshot no trae identidad estable). Maren usa la base compartida del personaje con `look` [1,0,2].
- **Personaje (E01+E02):** ataque con las 9 celdas completas y la estela como capa propia; estados herramienta, daño, caída y dormir cargados desde `arte/equipo/estados/`. Herramienta y daño están conectados; **caída y dormir están cargados pero sin disparador** (E02: no inventar eventos). El hacha solo se ve en el jugador local al talar con hacha; los remotos no la muestran (el protocolo no transmite la herramienta).
- **Interfaz (E06):** `scripts/ui_arte.gd` y `hud.gd` reescrito con paneles de 9 parches, botones, barras (la de XP usa `xp_fill.svg`), iconos por ítem y por ranura, tipografía Pixelify Sans (OFL), tinte nocturno por shader solo en el mundo, sombra de pies e indicador de interacción.
- **Retirado:** `arte.gd`, `apariencia.gd`, `capas_sprite.gd`, `arte/personaje*`, las capturas del arte anterior, la bandera `usar_arte`, F2 y `--arte`. Si falta un recurso, se registra `push_error` y se dibuja un marcador magenta.
- **Lista blanca de dibujo por código** (`t_sin_arte_procedural`): marcadores de arte faltante, selección de panel, zonas de aviso de enemigos, cajas de depuración F1, barra de vida de enemigo e indicador de golpes. Cualquier otro `draw_rect`/`draw_circle`/polígono falla la prueba.
- **Pendiente:** aceptación artística de todos los lotes; panel de habilidades con los iconos `skill_*` y `categoria_*`; `quest_marker`; barra de vida de enemigo con arte; daño de enemigo remoto; disparadores de caída y dormir (requieren autorización); revisión con dos clientes en red real.


## Origen retirado, semilla fuera del creador y ranura de arma (2026-10-24, decisión del usuario)
- **Origen:** eliminado por completo (catálogo, creador, partida, diálogo y protocolo de red; `Srv.VERSION` pasa a 2: el paquete «hola» ya no lo lleva). Los guardados antiguos con la clave `origen` se cargan igual: se ignora.
- **Semilla:** el mapa es único; la semilla solo elige dónde apareces y el botín. Ya no aparece en el creador: cada partida nueva usa una aleatoria. `--nueva=SEMILLA` sigue como argumento de depuración.
- **Ranura de arma:** `C.RANURAS` incluye `arma` (7 ranuras). La espada de hierro se equipa (Enter en la mochila), el daño sale del arma equipada (tenerla en el inventario ya no da daño) y se dibuja solo si está equipada, también en los jugadores remotos. Los guardados antiguos reciben la ranura vacía.

## Excepciones de dibujo por código (usuario, 25/10, provisional)
**Decisión.** El usuario revisó cinco capturas reales (valle, mochila y equipo; evidencia en `production/qa/evidence/arte-vivo/` y la revisión del 25/10) y **aprueba provisionalmente el estilo visual actual**: escenario, vegetación, HUD, mochila, equipo, marcos, botones y barras se conservan tal cual. Origen del dibujo: commit `88571a6` («arte vivo e interfaz pulida»), que añadió código de dibujo sin actualizar `t_sin_arte_procedural`.

**Qué se acepta.** Solo estas 49 llamadas, como excepciones **específicas** (máximo exacto por script y función, en `tests/prueba.gd` → `DIBUJOS_APROBADOS`):

| Script · función | Llamadas | Qué dibujan | Por qué se acepta |
|---|---|---|---|
| `arte_entornos.gd` · `suelo` | 15 | Velos de bioma, cantera y ruinas; sombra de la casa; motas, hierbas, piedrecillas, juncos, musgo y destello del agua | Aspecto aprobado; los velos modulan arte real. Motas, hierbas, juncos y musgo son arte que falta (ver ARTE_PENDIENTE) |
| `arte_entornos.gd` · `_flor` | 4 | Flor de pradera | Aspecto aprobado; sprite pendiente |
| `arte_entornos.gd` · `_sombra_suelo` | 2 | Sombras de contacto de objetos | Aspecto aprobado; es sombreado sobre arte real |
| `hud_vivo.gd` · `_celda` | 1 | Cuadro de color con iniciales si un ítem no tiene icono | Marcador provisional equivalente al de «arte faltante» |
| `hud_vivo.gd` · `_inventario` | 4 | Botón de cerrar y dos círculos de fondo de la ficha | Aspecto aprobado |
| `ui_viva.gd` · `marco` | 13 | Marco de madera y oro de paneles, tooltip y botones | Aspecto aprobado (sustituye a los 9-patch de `ui_arte`) |
| `ui_viva.gd` · `ranura` | 5 | Casilla de inventario | Aspecto aprobado |
| `ui_viva.gd` · `medidor` | 5 | Barras de vida y XP | Aspecto aprobado |

**Qué NO autoriza.**
- La regla general sigue siendo: **el arte nuevo se hace con sprites y recursos gráficos**.
- No autoriza generar personajes, edificios, árboles ni otros recursos con primitivas (`draw_rect`, `draw_circle`, polígonos, líneas) sin revisión.
- Una llamada nueva, una función nueva con dibujo o un script nuevo hace fallar `t_sin_arte_procedural`; añadir una excepción exige nueva aprobación del usuario y una fila aquí.
- Es **provisional**: la aceptación artística de los lotes sigue pendiente (ver [ARTE_PENDIENTE](ARTE_PENDIENTE.md)) y estas excepciones pueden retirarse sustituyéndolas por recursos.

### Actualización de implementación de las excepciones — integración local 5b87517
Los juncos nuevos, las marcas de bayas y los indicadores de oficios/permanencia/ocupación usan sprites PNG. Se reducen las llamadas permitidas de `arte_entornos.gd/suelo` de 15 a 13 al sustituir los juncos procedurales; no se autoriza ninguna función nueva de dibujo por primitivas. La azada y los indicadores conservan el aspecto del borrador revisado mediante rasterización del fuente nativo en herramientas/arte. El resto de máximos permanece igual.

### RED-C1 — Cuentas y acceso privado (26/10/2026, Usuario)

Autoriza el sistema de cuentas personales persistentes, SQLite, Argon2id mantenido y transporte autenticado/cifrado; contraseña opcional del servidor independiente de la cuenta. Conservar servidor autoritativo, personaje/guardado existentes y no modificar Fases 1–4 ni interferir con IA 1/Fase 5. Rama independiente `feature/cuentas`, sin merge no coordinado. Fundamentos y límites: [ADR-0002](../../../docs/architecture/adr-0002-cuentas-locales-seguras.md), [guía](CUENTAS_Y_SERVIDOR.md) y [validación](../../../production/qa/evidence/cuentas/INFORME.md). Sustituye el alcance previo sin cuentas/cifrado solo en los formularios nuevos; el transporte legado conserva su alcance y no debe exponerse a Internet.


### M1-AUT6-CICLO — políticas aprobadas, 26/10/2026

Usuario: déficit alimentario persistente durante un ciclo regional vigente tras intentar alternativas locales/comercio; migrar exige camas, comida, infraestructura y mejora real, nunca temporizador solo. Rutas y amenazas se evalúan individualmente; seguridad desconocida no es peligro confirmado. Fundación mínima aprobada con dos residentes existentes/oficios, vivienda de dos plazas/campos/estaciones, materiales/provisiones pagados, origen viable y ventaja territorial comprobada; inicialmente solo tras agotar alternativas y migración a pueblos existentes. Fundación sin crisis por oportunidad no se implementa. Abandono físico sin residentes ni retornos previstos, conservando identidad/infraestructura/inventarios/derechos; recuperación por originales con recursos y reparación real. Propiedad/reclamación de terceros pendiente.

Implementación del ciclo de crisis/abandono/recuperación: `63fff6f`. No aprueba por inferencia cambiar la capacidad fija regional de dos plazas ni enseñar recetas regionales automáticamente. Se consultaron capacidad física con crecimiento pagado y enseñanza mediante maestro real; pendientes de respuesta. [Contrato y dependencias](AUTONOMIA.md#fase-6--políticas-aprobadas-de-crisis-y-ciclo-físico-26102026).


### M1-AUT6-CIERRE — aprendizaje y capacidad física aprobados, 26/10/2026

El usuario aprueba conservar recetas explícitas y adquirir otras únicamente mediante maestro real conocedor, requisitos/disponibilidad/tiempos del sistema vigente y conocimiento persistente que acompaña al migrante. Aprueba reemplazar el tope regional fijo de dos residentes por camas propias funcionales, viviendas pagadas y residentes incorporados solo mediante migración de identidades existentes; alojamiento no sustituye alimentación, infraestructura o sustento de origen/destino. Fundación mantiene su contrato mínimo y nunca concede población, edificios o materiales. Autoriza completar los bloques sin nuevas consultas ordinarias, commits separados y validaciones puntuales. Implementado en `e15bfda` y `ab86408`; [contrato final](AUTONOMIA.md#fase-6--cierre-funcional-del-alcance-aprobado-26102026). No modifica tasas/costes/velocidades existentes ni aprueba 5b, derechos de terceros o fundación por oportunidad sin crisis.
