> **ARCHIVO HISTÓRICO — no describe necesariamente el código actual.**
> Copia íntegra de `production/epics/mundo-vivo/ESTADO.md` tal como estaba el 2026-10-25 antes de la consolidación documental. Las cifras de pruebas (326 PASS, 301 PASS, etc.), las frases sobre «autonomía optativa» y las deudas son de la fecha de cada sección. El estado vigente está en [ESTADO.md](../../production/epics/mundo-vivo/ESTADO.md).
>
> Enlaces relativos de este archivo reescritos a esta ubicación; el texto no se ha modificado.

---

# Mundo vivo — estado del epic

> **Actualizado**: 2026-10-25 · **Rama**: `main` · **Epic original**: 5 de 5 historias Complete (histórico) · **Revisión independiente**: ninguna (modo solo)

Documento único de estado. Para el plan original y las decisiones de diseño ver [README.md](../../production/epics/mundo-vivo/README.md); para las reglas, [design/gdd/mundo-vivo.md](../../design/gdd/mundo-vivo.md).

> **Prueba posterior de autonomía (24/10):** se añadió un modo optativo separado de este epic. Ver §10–12 y `Linde/cenital/docs/AUTONOMIA.md`. El cierre 5/5 de arriba corresponde al director de tarjetas, no a la visión completa del juego.

## Revisión actual — 25/10

Se implementaron compatibilidad de terreno v1/v2, solares completos con acceso reservado, reintento de casas bloqueadas, arte propio de construcciones/cultivos, orden estable de objetos y primeros puestos regionales persistentes. El protocolo 5 evita instantáneas grandes por el canal no fiable y descarta actualizaciones atrasadas. Se integraron los cambios remotos de presentación.

Contrato y límites: [Crecimiento y asentamientos](../../Linde/cenital/docs/CRECIMIENTO_Y_ASENTAMIENTOS.md). Evidencia: [pruebas y capturas](../../production/qa/evidence/crecimiento/README.md).

**Pendientes comprobados:** en cinco días de economía autónoma todavía no se completan casas de forma consistente; las obras preparadas sí se completan y reanudan. La prueba de 12 habitantes mantiene la caché acotada, pero muestra pausas de planificación de varios segundos. Los puestos son población resumida fundada por jugadores; no son ciudades autónomas con rutinas completas. La certificación en Internet con latencia real sigue pendiente.

Lo siguiente es equilibrar abastecimiento de comida y ladrillos, distribuir la planificación entre fotogramas y ampliar las rutinas de la población regional. Las secciones siguientes conservan la historia del epic y sus verificaciones originales; sus cifras y deudas no sustituyen esta revisión.

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

Registrada en [docs/tech-debt-register.md](../../docs/tech-debt-register.md): TD-001 a TD-009.

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

## 14. Protección de cofres, economía e identidad (2026-10-24)

Se añadieron candados fabricables (2 lingotes + 2 fibras, mesa), permisos por jugador, revocación, recuperación del candado, historial de robos y validación de acceso/cercanía en la transferencia y en el servidor. Los habitantes fabrican protección pagando materiales y usando una mesa; no pueden robar de cofres cerrados y respetan la cercanía del dueño jugador. Los cofres anteriores mantienen acceso abierto hasta instalar protección.

La recolección de fibra se limita según las reservas del habitante; ropa y lechos consumen fibra diariamente a cambio de recuperación de energía. La abundancia reduce su valor en el trueque. Se protegen materiales comprometidos en proyectos y recién recibidos; se corrigieron prioridades que provocaban retirar/depositar o prestar/devolver repetidamente los mismos insumos. La riqueza de acogida incluye infraestructura y piezas realmente fabricadas.

Las ayudas gratuitas no producen estafas; los acuerdos pagados consideran honestidad y confianza. Los colonos reciben preferencias, objetivos, variaciones de horario y reservas con efectos en su conducta. Los guardados anteriores se migran de forma aditiva. El diálogo refleja identidad, necesidad y memoria. J permite consultar y recorrer explicaciones, reservas, confianza y riesgo.

Detalle de uso, reglas y límites: `Linde/cenital/docs/PROTECCION_Y_ECONOMIA.md`. Evidencia: `production/qa/evidence/proteccion/`. Los pendientes de §13 sobre fibra, estafas e identidad tienen ahora estas medidas; el balance sigue siendo provisional. Continúan las tres familias de oficio y la autonomía opcional, sin retirar la campaña del capítulo 1. No se añadieron ganzúas ni rotura de candados.

Verificación de §14: 51 comprobaciones nuevas sin fallos; regresiones de sociedad 48, autonomía 33, desarrollo 55, general 326 e interfaz 13, sin fallos; integración de red existente con dos clientes localhost sin fallos. Simulación final de diez días sin intervención, semilla 123: 9 habitantes, 201 fibras en inventarios/cofres/depósitos (antes de estos ajustes: 804), 263 acuerdos, 258 entregas, 27 construcciones, 23 mantenimientos y un cofre protegido por un NPC. Esta semilla no produjo estafas; no implica una tasa general. Continúan faltando playtest y balance de varias partidas completas.

## 15. Exterior generado por regiones (2026-10-24)

El valle de autor se conserva y ahora tiene un exterior explorable, generado con la semilla de partida. Se adaptó código MIT de `mearnest-dev/infinite-generation-demo` (revisión `63f7400d58f5bdc1bba5fdb33e01016389ff46e4`); fuente y licencia están en `Linde/cenital/terceros/infinite-generation-demo/`. La demo no implementaba descarga ni semilla persistente; esas partes y la integración son propias de Linde.

- Regiones de 16 × 16, coordenadas globales positivas y negativas, biomas, caminos y recursos actuales. Cámara y colisión funcionan fuera del antiguo rectángulo.
- Caché de hasta 25 regiones exteriores por jugador, con descarga; el valle sigue residente. No se serializa el terreno sin modificar.
- Semilla y versión persistentes, diferencias de extracción/daño/construcción, cofres con candado y camas de jugador. Guardar lejos, regresar y reaparecer en una cama exterior conservan el estado. Partidas anteriores añaden los metadatos sin reemplazar el valle.
- Servidor autoritativo y réplica con el mismo terreno; protocolo 4. Navegación y validación de rutas acotadas, sin inundar el mundo entero al colocar una pared.
- Se conserva la activación de autonomía por defecto incorporada en paralelo. La campaña histórica se verifica usando `--campana`.

**Límites:** rango técnico ±65.536 celdas por eje, carga síncrona en regiones pequeñas, caminos ortogonales provisionales y arte/materiales existentes. No hay generación de nuevos enemigos, pueblos o mazmorras fuera del valle. Los habitantes siguen planificando dentro del valle; sus camas de huésped y objetivos no se trasladan todavía al exterior. La colonización y simulación resumida de asentamientos lejanos quedan para otra etapa.

Guía y contrato: `Linde/cenital/docs/MUNDO_POR_REGIONES.md`. Evidencia: `production/qa/evidence/terreno/`.

Verificación de §15: 49 comprobaciones específicas de terreno; regresiones de protección 51, autonomía 33, sociedad 48, desarrollo 55, campaña histórica 327 (`--campana`) e interfaz 13, sin fallos ni errores de script. Dos clientes y un servidor reales cruzaron el antiguo borde, coincidieron en terreno/bioma/recursos y validaron construcción, candado, rechazo sin permiso, autorización, transferencia y guardado exterior. La integración de red anterior también pasó sus 11 comprobaciones. Capturas de la escena real inspeccionadas. Continúan pendientes Internet, grupos grandes, playtest de exploración y colonización regional de NPC; persisten los avisos previos de recursos al cerrar.


## 16. Arte de superficies por bioma (2026-10-24)

Se integraron texturas propias para suelo de bosque, sierra, secano y pradera y agua de ribera, generadas con image_gen para Linde. El valle conserva su arte; hay transición gradual hacia el exterior y mezcla entre suelos vecinos. Las orillas reutilizan las conexiones y animación existentes con tinte armonizado. No se modifica el generador ni las partidas. Árboles, arbustos, rocas y menas siguen con sprites anteriores; no se entrega todavía un paquete completo de vegetación ni orillas propias.

Fuente, prompt y hashes en `Linde/cenital/arte/mundo/biomas/`; contrato en `Linde/cenital/docs/ARTE_BIOMAS.md`. Capturas reales de los cinco biomas, valle y salida en `production/qa/evidence/biomas/`, reproducibles con `tests/captura_biomas.gd`. Importación sin errores de script y regresión de terreno: 49 comprobaciones, 0 fallos. Persisten los avisos previos de recursos al cerrar.


## 17. Fauna y peligros regionales (2026-10-24)

Se añaden cinco criaturas exteriores: espectro de bosque, gólem defensivo de sierra, diablillo hostil de secano, arpía huidiza de pradera y slime territorial de ribera (en tierra junto al agua). Arte reutilizado por indicación del usuario de `Nuevo Juego/public/art/enemies-px`: 20 tiras con reposo, ataque, golpe y derrota. Slimes y dos jefes originales permanecen en el valle.

Aparición determinista por región, sin modificar el generador v1, franja de seguridad, validación de colisión y distancia, techo global de 24 regionales activos. Ataques con aviso, visión limitada por obstáculos, daño y botín reales; persecución acotada. Guardado aditivo de heridas y bajas; reaparición tras 720 minutos del juego. Réplica autoritativa mediante la instantánea existente. Sin simulación lejana ni ecosistema de reproducción/depredación. Balance provisional y tiras con una sola orientación.

Contrato: `Linde/cenital/docs/FAUNA_Y_PELIGROS.md`. Verificación: 31 comprobaciones nuevas sin fallos; campaña histórica 327 PASS; interfaz 13 PASS; integración existente con servidor y dos clientes localhost sin fallos. Capturas reales de las cinco especies inspeccionadas en `production/qa/evidence/fauna/`. La regresión de terreno tiene 4 fallos de caché sobre 49, reproducidos también en una copia sin fauna: el contorno mantenido para los NPC se añadió antes de esta tarea. No se modificó ese cambio. Persisten los avisos previos al cerrar; faltan playtest prolongado y fauna en Internet.


## Superposición estable al caminar (2026-10-25)

Corregido el intercambio de orden entre árboles cercanos: el ordenamiento por Y no resolvía los empates y podía cambiar cuando se movía el personaje. La escena desempata ahora por X e identidad fija, conservando las alturas de dibujo previas y el paso del jugador delante/detrás. No requiere arte nuevo. Verificación: 6 comprobaciones específicas sin fallos (2 intercambios con el comparador anterior, 0 con el nuevo), interfaz 13 PASS y tres capturas de movimiento inspeccionadas en `production/qa/evidence/orden-dibujo/`. La separación de copa/tronco del frutal sigue siendo una mejora artística aparte.


## Inspección consolidada (2026-10-25)

HEAD local `720f6e9` añade minerales, recetas aprendidas, expediciones al contorno, caminos por uso, cultivos y casas de plano fijo. La referencia local `origin/main` está en `4697591`; la corrección del orden de dibujo sigue sin commit. Los apartados anteriores son históricos: sus frases sobre autonomía optativa, ausencia de fauna y ausencia total de expediciones ya no describen el código actual.

Se repitieron 10 suites: 301 PASS, 0 fallos. La suite de terreno desactiva expediciones; queda verificar caché y red con el modo normal completo. Se reprodujeron dos casos fuera de las suites: una roca extraída puede reaparecer como estaño porque se cambió el generador v1 sin migración, y una casa bloqueada se marca como procesada y no vuelve a intentarse tras liberar el espacio. Prioridad: compatibilidad de partidas y reintento de casas; después reservar parcelas antes de colocar camas, arte propio de piezas nuevas y verificación de expediciones/cultivos/casas en multijugador. Informe y logs en `production/qa/evidence/inspeccion-2026-10-25/INFORME.md`. No se corrigió la lógica durante esta inspección.
