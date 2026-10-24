# Mundo vivo — estado del epic

> **Actualizado**: 2026-10-24 · **Rama**: `main` · **Epic**: 5 de 5 historias Complete · **Revisión independiente**: ninguna (modo solo)

Documento único de estado. Para el plan original y las decisiones de diseño ver [README.md](README.md); para las reglas, [design/gdd/mundo-vivo.md](../../../design/gdd/mundo-vivo.md).

> **Prueba posterior de autonomía (24/10):** se añadió un modo optativo separado de este epic. Ver §10–12 y `Linde/cenital/docs/AUTONOMIA.md`. El cierre 5/5 de arriba corresponde al director de tarjetas, no a la visión completa del juego.

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


## 10. Prueba de autonomía sin cadena narrativa preparada (2026-10-24)

**Implementada como prueba optativa**, por pedido del usuario: comprobar si aparecen situaciones sin escribir cada evento. Abrir `Iniciar-Prueba-Autonomia.command`; usa una partida separada. J muestra necesidades, inventarios y recuerdos; E permite hablar. No es todavía la economía completa ni el cumplimiento global de la visión.

- Reglas generales en `datos/autonomia/reglas.json`; ejecución en `scripts/autonomia.gd`.
- Hambre, reservas propias, recolección de objetos reales con ruta, producción con consumo de recetas y estación accesible, peticiones calculadas por carencia.
- Memoria persistente por habitante y jugador: recuerda ayuda, busca a ayudantes conocidos, respeta negativas recientes. Los recuerdos no son diálogos de una misión.
- Donar requiere proximidad, mueve objetos reales y no crea premios. Servidor autoritativo; réplica recibe el estado con `mundo_vivo`.
- Con la prueba activa no se ejecutan tarjetas ni se ofrecen nuevas plantillas del director. La campaña habitual se conserva en su partida normal.
- No se simulan facciones, mercado, descubrimiento limitado ni planificación arbitraria. Las herramientas del oficio son capacidades provisionales; los lingotes se guardan como reservas. Hambre no causa muerte.

Verificación: `tests/prueba_autonomia.gd` (33 comprobaciones, 0 fallos), suite general (326 PASS, 0 fallos), UI (13 PASS, 0 fallos), integración de red existente en localhost (0 comprobaciones fallidas). La prueba nueva verifica serialización hacia la réplica e intenciones de ayuda, no una partida de autonomía multijugador completa en Internet. Evidencia de la escena real en `production/qa/evidence/autonomia/`; documentación y límites en `Linde/cenital/docs/AUTONOMIA.md`. Persisten avisos de recursos/objetos al cerrar, también presentes en las suites anteriores.

## 11. Decisión del usuario: la autonomía pasa a ser el modo principal (2026-10-24)

- **La autonomía es el modo principal.** El director de tarjetas y las misiones de plantilla (epic mundo-vivo, historias 001–005) quedan como código suspendido mientras la autonomía esté activa; no se borran.
- **El juego se genera a partir de las decisiones del jugador**, no de una campaña escrita de principio a fin. Las misiones de capítulo ya no son el eje del juego.
- **Límites aceptados por ahora:** solo Maren y Ordal actúan, sin habitantes ni zonas nuevas, sin economía ni mercado, y con números provisionales sin balance.
- **La campaña del capítulo 1 se retira de la partida principal.** La partida nueva arranca en autonomía sin cadena de misiones; el Guardián y el Gran Ciervo siguen en el mundo como peligros, sin misión asociada. La campaña queda en el código y en las partidas antiguas.
- **Aún no hecho:** activar la autonomía por defecto en partidas nuevas, el GDD de la autonomía, y su epic de historias. Hasta entonces sigue siendo el modo optativo de `Iniciar-Prueba-Autonomia.command`.


## 11. Sociedad: cinco capacidades conectadas (2026-10-24)

La prueba optativa se amplió por pedido del usuario. `sociedad.gd` conecta producción con consumo real (herramientas y mantenimiento), cooperación mediante trueque y garantías, metas alternativas, confianza por compromisos y grupos con reservas, territorio y reputación. El mismo lanzador de prueba usa ahora esta versión; la primera prueba se conserva como regresión aislada.

- Los NPC arrancan sin herramientas ni estaciones regaladas. Fabrican desde recursos del mapa, negocian excedentes, se encuentran para entregar y construyen estaciones pagando materiales.
- Desgaste y reparación vuelven a crear demanda; los acuerdos vencidos devuelven garantías y modifican confianza.
- Talleres y Cantera tienen reservas compartidas, prioridades y protección de recursos escasos. El jugador puede contribuir. Una extracción protegida vista por un miembro cercano afecta reputación; no se atribuye conocimiento a testigos distantes.
- J muestra necesidades, usos, grupos, acuerdos y diario; los depósitos tienen marcador en el mundo. E explica el estado del habitante.
- El guardado conserva acuerdos en tránsito y sus materiales; la migración añade campos a la primera prueba. El servidor valida aportes; la réplica no simula.

Es una rebanada de economía y grupos, no la visión completa: sin guerras, facciones generadas, inventarios limitados, nuevos mapas, habilidades aprendidas ni equipo procedimental. Reglas propias provisionales; recetas conocidas. Diseño: `design/gdd/sociedad-emergente.md`. Uso y límites: `Linde/cenital/docs/AUTONOMIA.md`. Evidencia y resultados retenidos: `production/qa/evidence/sociedad/`.


Verificación de §11: 48 comprobaciones de sociedad y 33 de la primera autonomía, sin fallos; suite general 326 PASS; UI 13 PASS; integración de red existente en localhost con 0 fallos. En tres días de simulación sin intervención, semilla 123: 15 acuerdos, 14 entregas, 13 fabricaciones, 1 construcción, 1 reparación y 1 vencimiento. Los contadores representan hechos ejecutados por reglas, no un guion. Los avisos de recursos al cerrar continúan; no hay revisión independiente ni playtest de diversión. No se probó una sesión completa de sociedad multijugador en Internet.


## 12. Desarrollo: materiales, equipo y pericia (2026-10-24)

Ampliación solicitada por el usuario después de §11. El modo de prueba añade una gramática de forma/material/técnica/calidad en `artesania.gd`, progreso por acciones confirmadas y ampliación de talleres en `desarrollo.gd`. `G` abre el atlas de los 9 recursos/consumibles actuales, planos con costes/propiedades, laminados y práctica.

- Materias base existentes: madera, piedra, fibra e hierro refinado. Los laminados se derivan de hierro + refuerzo (madera/piedra/fibra), consumiendo componentes en un horno; no se añadieron minerales al mapa.
- Espadas, escudos y armaduras generados funcionan en inventario, equipo, estadísticas, combate, guardado y red. Reutilizan geometría recoloreada; no hay siluetas nuevas.
- La práctica desbloquea técnicas y calidad para piezas futuras. Recolección, construcción y combate tienen efectos acotados. Las piezas anteriores no cambian por aprender.
- Los NPC amplían superficie pagando madera, construyen mesas y producen obras con excedentes. Pueden ofrecerlas por materiales; comprar requiere proximidad y stock real.
- Claves `art1:`/`mat1:` y reglas v1 conservables; partidas anteriores reconocen recursos sin regalar práctica. El servidor valida calidad, conocimiento y costes.

No es generación ilimitada: las formas, efectos y acciones siguen implementados en código. Diseño `design/gdd/desarrollo-generativo.md`; uso y reglas `Linde/cenital/docs/DESARROLLO.md`; evidencia `production/qa/evidence/desarrollo/`. Los resultados de §11 son históricos de esa versión, sin activar esta nueva capa.


Verificación de §12: 55 comprobaciones de desarrollo sin fallos (incluyen laminados y equipo compuesto), 326 PASS generales, 13 PASS de interfaz y 0 fallos en la integración de red existente en localhost. En tres días de simulación sin intervención se produjeron 2 obras generadas y 14 suelos de taller; continuaron 16 acuerdos entregados, 10 fabricaciones de recetas anteriores y 2 reparaciones. Capturas inspeccionadas de atlas, hierro, planos, práctica, laminados, ofertas e inventario. Sigue sin revisión independiente, prueba de balance o sesión completa de desarrollo multijugador en Internet. Los avisos de recursos al cerrar permanecen.


## 13. Mundo que crece: carácter, vivienda, población y propiedad (2026-10-24)

Cambios hechos tras el aviso de «haz los cambios tuyos», sobre la sociedad de §11. Todo en datos (`datos/autonomia/reglas.json`, bloques `perfiles.*.caracter`, `sociedad.caracter`, `propiedad`, `vivienda`, `inmigracion`) y en `scripts/sociedad.gd`. Ritmo de desarrollo: pruebas mínimas, balance provisional.

- **Gente buena y mala.** Cada habitante tiene honestidad, codicia y rencor (0-100). Quien tiene poca honestidad puede **estafar** en un acuerdo (se queda con lo prometido y con el pago); el codicioso **cobra de más** y **acapara**; quien guarda rencor pierde más confianza y perdona más despacio. Nadie compra a quien le falló. Maren es honrada; Ordal, codicioso y poco honrado.
- **Hurto.** Con poca honestidad y sin otra vía, un habitante toma de un depósito de otro grupo o de un cofre ajeno si el dueño no está cerca. Solo los testigos cercanos lo saben y cambian su confianza.
- **Propiedad.** Con excedente de fibra, cada habitante se construye un **cofre propio** junto a su cama y ahorra en él. Los cofres tienen dueño (habitante, jugador o grupo). **Tomar de un cofre ajeno es un hurto** también para el jugador: hay testigos, memoria y reputación, y si el dueño es otro jugador conectado recibe un aviso.
- **Vivienda y crecimiento.** Con excedente y sin camas libres, un habitante construye una **cama de huésped**; la cama libre y la riqueza del valle atraen a un **colono** con oficio (cantero, artesano o recolector) y carácter sorteados. Se guarda entero en `mundo_vivo.autonomia.colonos` y sobrevive a guardar y cargar. **No hay número objetivo de habitantes**: `max_habitantes` (12) es solo un techo técnico por rendimiento y red.
- **Error corregido.** Al cargar una partida con habitantes llegados después, la simulación fallaba (`rutas[...]` sin preparar). Afectaba también a Nerea en el epic anterior.
- **Prueba de humo (10 días, sin jugador):** la población pasa de 2 a unos 10, con 12 a 15 construcciones, ahorros en cofres propios y entre 40 y 60 estafas; según la semilla, algunas relaciones se rompen y otras no. Con la misma semilla el resultado se repite.

**Límites y pendientes**
- Se acumula fibra sin freno (cientos por habitante): falta un sumidero real o precios que suban con la abundancia.
- Muchas estafas (alrededor del 15 % de los acuerdos): `prob_estafa_max` y las honestidades son provisionales.
- Los colonos usan los mismos tres oficios y horarios de Maren, Ordal y Nerea; sin diálogos propios (TD-005) y con aspecto derivado del id.
- No verificado: que un **cliente de red** vea a los colonos y los cofres de los habitantes (el estado viaja en `mundo_vivo`, pero solo se probó guardar y cargar); el panel J con 10 habitantes; ni una partida jugada a mano.
- Sigue sin activarse la autonomía por defecto en partidas nuevas ni retirarse la campaña del capítulo 1 (§11).
- Ajustada una comprobación de `tests/prueba_sociedad.gd`: la reparación ya no se exige en la simulación libre, porque depende de la secuencia; su mecanismo sigue comprobado aparte.
