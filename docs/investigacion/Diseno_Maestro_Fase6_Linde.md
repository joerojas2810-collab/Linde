# LINDE — diseño maestro unificado de Fase 6
## Autonomía, economía y evolución de asentamientos NPC

**Tipo:** referencia de diseño para evaluación y posterior contraste técnico. No es código ni autorización de implementación.
**Fecha de referencia del proyecto:** 26/10/2026.
**Fuentes de proyecto consideradas:** `ESTADO.md`, `VISION_MUNDO_1.md`, `DECISIONES.md` adjuntos; investigaciones previas sobre autonomía, decisiones NPC, economía emergente y evolución de asentamientos.

---

## 0. Propósito y regla de lectura

Este documento unifica las cuatro investigaciones de Fase 6 en un modelo que pueda contrastarse con el proyecto sin volver a investigar desde cero. Distingue:

- **Aprobado/documentado:** aparece explícitamente como hecho verificado o decisión del usuario en los documentos recibidos.
- **Recomendación nueva:** diseño propuesto aquí; requiere aprobación antes de convertirse en contrato de implementación.
- **Pendiente de verificación técnica:** el documento no permite afirmar que exista o cómo funciona; debe contrastarse con código y contratos actuales.
- **No decidido:** cuestión de diseño que no debe resolver por intuición el agente implementador.

Regla central: **no trasladar una recomendación a la columna “existente” sin comprobarla en el repositorio**. En caso de discrepancia, manda el código verificado y se actualiza la documentación.

---

## 1. Resumen ejecutivo

### Modelo unificado recomendado

La autonomía emerge de un ciclo compartido y causal:

> **necesidad individual o colectiva** → **demanda consolidada** → **opciones factibles** → **decisión/compromiso** → **tarea reclamada** → **costes y cambios reales** → **nueva situación persistente** → **reevaluación**.

Ese ciclo debe servir para acciones pequeñas (comer, trabajar, transportar, ayudar) y decisiones de escala mayor (comerciar, migrar, fundar, ampliar, abandonar, recuperar). No hace falta un “cerebro” distinto para cada sistema: los módulos de dominio generan demandas y evalúan consecuencias, pero comparten reglas de factibilidad, asignación, compromiso, ejecución y trazabilidad.

### Cuatro escalas y responsabilidades

1. **NPC:** atiende necesidades propias y contribuye mediante capacidades/saberes, oficio, inventario, relaciones y tareas actuales.
2. **Grupo/expedición:** coordina acciones que requieren varios residentes, una carga y una ruta compartidas; existe solo con identidades y bienes reales.
3. **Asentamiento (`Asentamientos`):** consolida demandas, reservas y cobertura; compara soluciones locales, comercio, migración y fundación; mantiene estado de viabilidad y memoria del lugar.
4. **Simulación mundial:** mantiene identidad y generación persistente/determinista de lugares y caminos, progreso de regiones resumidas, viajes entre sitios, límites técnicos y replicación autoritativa.

### Recomendación de alcance

Construir el contrato común de demanda/tarea y cerrar primero causalidad, inventarios, persistencia, concurrencia y simulación resumida. Luego permitir decisiones irreversibles de población y lugar: expediciones fundadoras, migración y recuperación. No comenzar por precios dinámicos, moneda, reproducción, política, guerras ni un sistema urbano paralelo.

---

## 2. Estado del proyecto: línea base documental

### 2.1 Documentado como existente en ESTADO.md

El estado consolidado al 26/10/2026 informa:

- Juego 2D cenital en Godot 4.7.1, mundo persistente y servidor autoritativo con réplica; pruebas de red indicadas son locales, no prueban Internet real.
- Sistemas de autonomía/sociedad documentan **necesidades, producción, trueque, confianza, grupos y memoria**; el balance sigue provisional.
- Desarrollo de habitantes incluye mochila, pasivas por práctica, pericia y distribución de decisiones; conocimiento/saberes está separado de pericia, con enseñanza autónoma documentada.
- `Asentamientos` ya representa comunidades/puestos, con residentes, oficios, provisiones iniciales, tasas y consumo. Hay asentamientos regionales identificables, actividad económica resumida, recursos y evolución observable según lo descrito.
- Hay sistemas relacionados con caminos, cultivos, casas, edificios, expediciones y lugares persistentes. El documento consolida cambios de varias sesiones; alcance exacto, integración, regresiones y estado final deben verificarse en el árbol vigente antes de diseñar interfaces nuevas.
- Residentes regionales resumidos no tienen la totalidad de rutinas, combate, acuerdos y navegación de habitantes detallados.
- La transición resumido↔detallado está aplazada hasta resolver identidad, recursos y red (M1-F5).
- La Fase 6 **no se declara iniciada**: no se da por implementada la fundación autónoma, decadencia/abandono automáticos ni comercio interurbano autónomo.
- Hay advertencias sobre pruebas no repetidas tras ajustes recientes y límites de pruebas multijugador/persistencia. No se presume que una suite antigua valide una nueva funcionalidad.

### 2.2 Decisiones aprobadas de Mundo 1 (DECISIONES / VISION)

Son decisiones de diseño ya tomadas, no funcionalidades necesariamente terminadas:

- **M1-N3:** registro persistente de poblados/lugares/caminos; generación determinista independiente del orden de exploración; generación controlada se distingue de carga de regiones.
- **M1-N4:** reutilizar y generalizar `Asentamientos`; no crear un sistema paralelo de pueblos.
- **M1-N5:** topes globales y por poblado configurables y sujetos a medición.
- **M1-N6:** viabilidad = comida, camas, residentes y seguridad; umbrales pendientes de medir/aprobar.
- **M1-F5:** preexistentes con simulación resumida, residentes identificables y evolución observable; transición resumido↔detallado aplazable hasta resolver identidad, recursos y red.
- **M1-F6:** fundación autónoma depende de necesidades y condiciones reales, no de eventos programados.
- **M1-P:** pueblos no son zonas mágicamente seguras; pueden sufrir ataques, perder habitantes o desaparecer. El spawn de jugadores debe conservar una oportunidad razonable de reaccionar y no reactivar una comunidad destruida.
- El mundo compartido se genera una vez y se conserva; todos los pueblos siguen las mismas reglas, con resolución distinta por distancia.
- Construcciones, caminos, cultivos, habitantes, asentamientos y territorios deben cambiar de forma visible y persistente.
- Sin cambios de balance de XP, fabricación, daño, recompensas o progresión sin mediciones y aprobación.
- Arquitectura de edificios prioriza un catálogo limitado de vivienda/taller/depósito con objetos/piezas existentes, edificios funcionales y compatibilidad persistente/NPC/red; construcción progresiva avanzada no bloquea el ciclo inicial.

### 2.3 Separación indispensable

| Categoría | Ejemplos en este documento |
|---|---|
| Aprobado | `Asentamientos` como sistema único; F6 fundada en condiciones reales; viabilidad multidimensional con umbrales pendientes; misma causalidad en pueblos, resumido al inicio |
| Existente documentado | Necesidades, producción, trueque, confianza, grupos, memoria, saberes/enseñanza, inventarios, asentamientos, cultivos/caminos/edificios según alcance declarado |
| Recomendación nueva | Demanda colectiva consolidada, reserva explícita de tareas, selección híbrida, transacción de migración, ciclo de fundación y recuperación, libro causal por recurso |
| Pendiente | Contratos, formatos, algoritmos, offline clock, reservas, localización de bienes, detalle del registro, umbrales, seguridad y coste medido |

---

## 3. Principios de diseño integrados

1. **Una causa real precede al cambio.** Toda producción, intercambio, movimiento de residentes, edificio o fundación debe poder explicarse por una necesidad/demanda, una acción y un coste.
2. **No hay producción ni población gratuita.** Bienes e identidades cambian de lugar/estado mediante transacciones rastreables; ninguna simulación resumida inventa resultados.
3. **Lo existente es la primera opción.** Extender necesidades, producción, trueque, saberes, memoria, inventario y `Asentamientos`; no construir subsistemas duplicados.
4. **Mismas reglas causales, resolución distinta.** Lejos se agregan acciones/tiempo; no se les asigna una economía o derecho de crecimiento distinto. Esto no activa transferencia resumido↔detallado.
5. **Factibilidad precede a preferencia.** Sin ruta, saber, herramienta, insumos, estación, capacidad o permiso material, una preferencia no vuelve realizable la acción.
6. **Urgencia no es una barra universal.** Necesidades críticas pueden interrumpir; la mayoría de opciones se puntúan dentro de bandas semánticas y con compromiso para estabilidad.
7. **La escasez no funda un pueblo automáticamente.** Primero compara reasignación, producción, enseñanza, comercio y expansión del núcleo; fundar es una alternativa costosa cuando las otras no resuelven la presión.
8. **Lugar, asentamiento y población son entidades distintas.** Un sitio/ruina conserva identidad si se vacía; pueblo activo requiere personas y actividad real.
9. **No diseñar para que todo prospere.** Desaparición/abandono son posibles, y las reglas de spawn no deben restaurar poblados artificialmente.
10. **Instrumentación es parte del diseño.** Un comportamiento emergente que no permite explicar causas y consecuencias es difícil de validar y balancear.

---

## 4. Modelo unificado: de una necesidad a un mundo persistente

### 4.1 Ciclo común

#### Paso 1 — Señal
Una necesidad individual o colectiva cruza una condición de atención; un actor queda sin tarea posible; un recurso entra en déficit proyectado; una ruta falla; una construcción queda incompleta; o una comunidad pierde viabilidad. El disparador puede ser un evento o un tick económico acotado, no una comprobación por frame.

#### Paso 2 — Demanda
La señal se expresa como demanda: qué resultado hace falta, en qué cantidad/alcance, para quién, con qué urgencia, horizonte, restricciones y causa. Demandas individuales y colectivas se distinguen, pero comparten un contenedor/contrato si la implementación lo permite.

Ejemplos conceptuales: “NPC necesita comer”; “asentamiento necesita mantener reserva alimentaria”; “taller necesita material”; “grupo necesita asentarse por déficit persistente de acceso/refugio”.

#### Paso 3 — Consolidación y deducción
El sistema combina demandas equivalentes, deduce cantidades ya cubiertas, trabajos en curso, bienes reservados y bienes en tránsito. Esto previene que N NPC generen N veces la misma orden. La consolidación no borra identidades ni necesidades personales: evita duplicar la respuesta colectiva.

#### Paso 4 — Generación y filtro de opciones
Se consideran acciones existentes que puedan responder: consumo, producir/recoger, transportar, enseñar, pedir/ofrecer trueque, ayudar, reparar/construir, migrar o formar expedición. Se filtran por capacidad/saber, oficio aplicable, recursos no comprometidos, estación/herramienta, ruta, estado y reglas del mundo.

#### Paso 5 — Elección y compromiso
Una jerarquía simple protege supervivencia/amenaza y necesidades urgentes. Entre acciones factibles de la misma banda se comparan urgencia, beneficio comunitario, coste de mano de obra y viaje, especialización, continuidad de tarea y relaciones pertinentes. Una tarea sigue activa hasta completarse, bloquearse o ser superada por una urgencia real; no se abandona por una pequeña variación de utilidad.

#### Paso 6 — Reclamo y ejecución
El servidor reclama actor, tarea y materiales de manera única; consume insumos según la operación actual; aplica efectos a objetos, inventarios, caminos, cultivos, edificios, grupos o registros. El resultado no se duplica tras reintento/carga/red.

#### Paso 7 — Persistencia y reevaluación
Se guardan los efectos y la mínima información necesaria para continuidad: identidad, estado, cantidad/ubicación, causa y vínculos/compromisos vigentes. Se reevalúa la demanda. Una tarea fallida no se repite ciegamente: guarda causa y disparador para reintentar.

### 4.2 Qué significa “emergente” en Linde

No exige IA general ni que cada personaje invente planes novedosos. Significa que, a partir de reglas comunes y estados persistentes, distintas condiciones reales llevan a secuencias distintas sin script que ordene “ahora funda un pueblo”. Un sistema pasa la prueba de emergencia si:

- puede elegir **no** fundar cuando una opción local resuelve el déficit;
- el mismo patrón puede resolverse de formas diferentes según recursos, capacidad, relación, ruta y riesgo;
- no crea los bienes/actores/edificios que hacen falta para justificar el resultado;
- el jugador puede reconstruir la causa observando mundo/registro;
- la misma regla sirve a pueblos preexistentes y nuevos.

---

## 5. Responsabilidades por escala

### 5.1 NPC individual

**Responsabilidad:** resolver objetivos personales y aceptar tareas factibles.

- Aporta necesidades, disponibilidad, oficio, capacidades/pericia, saberes, mochila/inventario, relaciones/memoria y actividad actual.
- Puede elegir trabajo, atenderse, ayudar o participar en transporte según capacidades y estado.
- No decide solo la creación de un poblado ni altera directamente el registro global.
- No crea bienes ni aprende instantáneamente. Enseñanza/saber existente puede responder a déficit si hay condiciones.

### 5.2 Grupo / expedición

**Responsabilidad:** coordinar actos que requieren varias identidades y una carga/ruta común.

- Tiene miembros identificables, carga/reservas, origen, destino, razón, ruta, estado y compromisos.
- Su creación/transición se confirma una sola vez en servidor.
- No es un segundo sistema poblacional: al llegar/establecerse actualiza el registro de `Asentamientos`.
- Su función es indispensable para fundación y evacuación colectiva; no debe convertirse en ejército/facción en esta fase.

### 5.3 Asentamiento

**Responsabilidad:** agregar necesidades colectivas, recursos, cobertura funcional y alternativas.

- Consolida consumo, reservas, tareas, insumos, camas, residentes y seguridad, dentro de los datos existentes.
- Decide si una presión se resuelve localmente, por comercio/movilidad/obra o si amerita expedición.
- Evalúa viabilidad en términos aprobados (comida, camas, residentes, seguridad) con umbrales que deben medirse.
- Conserva su ID e historia si cambia de estado; no necesita una entidad paralela para “ruina”.
- No recibe un líder/política artificial como árbitro; la decisión agregada puede ser una regla del sistema comunitario.

### 5.4 Simulación mundial

**Responsabilidad:** identidad espacial, generación, tiempo, viajes, persistencia y coste de simulación.

- Mantiene registro determinista de lugares y caminos conforme M1-N3.
- Evita colisiones, genera candidatos solo cuando la regla causal los requiere y registra el resultado elegido.
- Resuelve tiempos y economía resumida de regiones lejanas con los mismos costes/materiales.
- Impone límites técnicos configurables medidos y ofrece razón/estado cuando se alcanza capacidad; no autoriza eventos o resultados gratuitos.
- Replicación de efectos persistentes es server-authoritative.

### 5.5 Fronteras que no conviene mezclar

- **NPC** no calcula economía total del mundo; propone/ejecuta tareas.
- **Asentamiento** no genera terreno; pide evaluar candidatos a capa mundial.
- **Generación mundial** no decide que una comunidad “necesita” salir; recibe decisión y comprueba persistencia/validez.
- **Simulación resumida** no sustituye economía; agrega sus operaciones.

---

## 6. Lógica de decisiones integrada

### 6.1 Roles de necesidades, profesiones, recursos y relaciones

| Factor | Papel en la decisión | Qué no debe significar |
|---|---|---|
| Necesidad personal | Produce objetivo individual e interrupción si cruza urgencia crítica | Que todo estado numérico active una tarea nueva en cada tick |
| Demanda comunitaria | Expresa déficit agregado y beneficio del próximo trabajo | Que todos ejecuten la misma tarea |
| Oficio | Aumenta adecuación/continuidad y es identidad social útil | Permiso exclusivo universal que paraliza pueblos pequeños |
| Saber/capacidad | Filtra o condiciona acciones; puede habilitar mentoría existente | Garantía de materiales, acceso o disponibilidad |
| Inventario/recurso | Precondición/coste físico, separado por titularidad/ubicación/compromiso | Stock abstracto siempre accesible |
| Prioridad | Banda de emergencia/urgencia; desempata decisiones | Un orden fijo absoluto para cada profesión |
| Relaciones/confianza | Modificador acotado para ayuda, cooperación o intercambio si ya definido | Sustituir capacidad, consentimiento, recursos o urgencia crítica |
| Distancia/ruta/amenaza | Coste, duración y factibilidad | Inutilizar la generación determinista o crear teletransporte |
| Memoria | Proporciona contexto e historia de eventos verificables | Un objetivo narrativo guionizado |

### 6.2 Regla híbrida recomendada

1. Filtro duro de factibilidad.
2. Clases semánticas de urgencia (orden conceptual, no cifras): supervivencia/peligro inmediato; ayuda crítica; continuidad de necesidades esenciales; actividad económica normal; preferencia/social opcional.
3. Comparación por beneficio neto dentro de la clase: urgencia marginal, déficit que resuelve, competencia/saber, continuidad, coste de desplazamiento, oportunidades alternativas y relaciones pertinentes.
4. Compromiso e histéresis: no cambiar por variaciones leves; interrumpir solo ante invalidez o prioridad superior clara.
5. Selección de una acción/próximo paso realizable y reevaluación al completar o cambiar condiciones.

No recomendamos prioridades numéricas de ocho niveles, utilidad pura sin filtros, ni planificador GOAP general completo. Esos modelos incrementan opacidad y oscilación sin que los documentos prueben que Linde los necesite.

### 6.3 Cuando no hay opción

“Inactivo” debe ser un resultado diagnosable, no un error oculto. Registrar razón: sin recurso, sin saber/capacidad, sin estación, sin ruta, sin espacio, tarea ya cubierta, riesgo/coste excesivo o tope de simulación. Definir el evento de reintento. No mantener una cola infinita de intentos idénticos.

---

## 7. Economía y comunidades: mecanismo compartido

### 7.1 Libro causal de recursos — recomendación nueva

Para cada recurso/ubicación/asentamiento (el nivel real debe mapearse a inventarios actuales) distinguir:

- stock físico libre;
- stock reservado para tareas/consumo;
- material en tránsito, si está representado;
- entradas/salidas comprometidas;
- uso/propiedad relevante;
- fuente de cada variación.

Balance conceptual por periodo:

> stock final = stock inicial + producción + entradas − consumo − insumos de transformación − salidas − pérdidas documentadas.

No se propone que esta fórmula requiera almacenar cada renglón para siempre; sí que sirva de invariante en pruebas y diagnóstico.

### 7.2 Producción y demanda

- La necesidad produce un objetivo y demanda agregada, no una receta nueva.
- Se reutilizan recetas, tasas/consumo, inventarios y acciones comprobadas.
- El asentamiento descuenta órdenes en curso, reservas e importaciones prometidas antes de asignar otra tarea.
- La receta determina coste/rendimiento real; tarea exige instalación/herramienta/saber/capacidad/ruta según sistema actual.
- Ofrecemos stock por bandas (activar bajo nivel y producir hasta objetivo) como estrategia inicial, pero umbrales/horizonte dependen de datos medidos.
- Recursos inaccesibles no cuentan como disponibles; si hoy inventario es comunitario abstracto, no fingir traslado físico.

### 7.3 Escasez, excedente e intercambio

Escasez: inmediata, proyectada o cuello de botella de receta. Excedente exportable: stock que permanece sobre reservas/demandas/compromisos, no simplemente “stock positivo”.

Intercambio recomendado inicialmente en especie:
1. Pueblo A tiene déficit persistente no cubierto localmente.
2. Pueblo B tiene excedente por encima de su propia necesidad proyectada.
3. Se verifica que la relación/ruta/capacidad pueda resolver el intercambio; se reserva lo ofrecido.
4. Se ejecuta transferencia con cantidades exactas, coste y tiempo soportados; no se crea suministro externo.
5. Los cambios actualizan demanda, viabilidad y decisiones de ambos pueblos.

Trueque existente no equivale automáticamente a comercio entre asentamientos: alcance y contrato son pendientes. Dinero/precios dinámicos no son requisito inicial.

### 7.4 Decisiones macro comparten el ciclo, pero requieren predicados propios

El mismo flujo de demanda→factibilidad→compromiso→ejecución sirve para fundar/migrar, pero la decisión tiene **predicados de grupo y territorio** que una tarea individual no necesita:

- suficiente grupo para sostener funciones esenciales en destino y origen;
- recursos de viaje/arranque reales;
- lugar registrado/alcanzable y no incompatible;
- ventaja sobre alternativas después de costes;
- posibilidad de recepción y persistencia sin duplicar residentes;
- criterios de campamento/pueblo funcional aún por aprobar.

No confundir lógica compartida con una sola función que intente resolver todas las escalas. Se comparte el contrato; cada dominio aporta su evaluación.

---

## 8. Fundación, crecimiento, migración y recuperación

### 8.1 Disparador de fundación

Una comunidad considera expansión solo ante presión sostenida y no resuelta por alternativas menos costosas. Señales pueden incluir déficit persistente de recursos/acceso, capacidad habitacional insuficiente o costes de trabajo/transporte que el sitio secundario reduce. Su existencia como señal debe confirmarse con sistemas actuales.

Secuencia:
1. necesidad/déficit persiste más allá de una fluctuación;
2. planificador compara reasignar, enseñar, comercio, instalar en núcleo, migración a pueblo existente y fundar;
3. solo si hay ventaja neta robusta se evalúan ubicaciones;
4. filtros geográficos, recursos, ruta, amenaza y vecinos;
5. expedición se forma con personas y carga reales;
6. viaje y consumo ocurren con identidad única;
7. destino se registra al llegar/establecer presencia real, no antes como pueblo vacío;
8. campamento adquiere actividad/construcciones persistentes y solo luego se considera funcional según reglas aprobadas.

### 8.2 Selección de territorio

**Filtros de validez:** terreno/espacio permitido; no colisión con asentamiento/lugar/construcción; generación controlada válida; acceso; posibilidad de sostener el arranque; límites técnicos.

**Factores de preferencia:** recursos documentados/regeneración real, adecuación a cultivos/instalaciones existentes, coste/distancia/ruta, seguridad relativa, caminos, comunidades y su capacidad, complementariedad económica, conocimiento disponible al grupo.

Primero descartar inviable, luego comparar beneficio/coste. Los NPC no conocen automáticamente los recursos secretos de todo el mundo; rumores/exploración/mapa actualizan información sin cambiar terreno. Semilla/hash solo ordenan empates de candidatos equivalentes.

### 8.3 Expedición y fundación

El grupo contiene residentes identificables, saber/capacidades pertinentes, herramientas/provisiones/materiales transportados, origen/destino, motivo, ruta, estado y compromisos. La cantidad mínima se deriva de tareas/recursos verificados, no se fija ahora. Debe evitar dejar el origen inviable salvo evacuación por crisis.

Registro del lugar y del movimiento se hace con operación coherente: origen → tránsito → destino. No duplicar actor, mochila, memoria o reserva. Si no hay sistema actual para campamento, no inventarlo por anticipado: probar edificio funcional de catálogo aprobado o decidir explícitamente qué estructura mínima existe.

### 8.4 Crecimiento físico

Cada obra nace de demanda identificable: camas que faltan → vivienda; capacidad productiva que falta → estación/taller ya soportado; distancia logística repetida → camino si la construcción está disponible; necesidad de alimento → cultivo si existe suelo/receta/saber. Material, trabajo y resultado espacial persisten. Debe considerarse la obra ya en curso para no construir de más.

### 8.5 Decadencia y recuperación

Decadencia = pérdida causal de capacidad para cubrir necesidades, no medidor narrativo. Primero se intentan alternativas reversibles; después puede haber migración y abandono. Poblado vacío mantiene registro, lugar y huella física conforme reglas de deterioro actuales.

Recuperación = grupo/personas/bienes reales ocupan el mismo ID desocupado, inspeccionan y reparan/reutilizan lo existente a coste; el lugar queda en recuperación hasta alcanzar requisitos. No reactivarlo por spawn, calendario o cambio de etiqueta. Conflicto/propiedad sobre un sitio ocupado requiere decisión pendiente; no asumir reclamación automática.

### 8.6 Definiciones diferentes de estado

No usar una sola etiqueta “activo/inactivo” para todo:

- **lugar existente:** registro espacial/histórico;
- **ocupación:** personas presentes o ausencia;
- **actividad:** producción/obra/rutinas;
- **viabilidad:** predicados de comida, camas, residentes y seguridad;
- **resolución:** resumido o detallado.

Es posible que lugar exista, esté abandonado, no sea viable y permanezca resumido. Esta separación simplifica y evita que “ruina” implique borrado o que “pueblo conocido” implique pueblo vivo.

---

## 9. Simulación resumida y mundo persistente

### Reglas recomendadas

- Mismo libro de balances, recetas, elegibilidad y decisiones; resumido ejecuta transacciones agregadas por intervalo.
- No representar viajes/obras como individuales si no son observables, pero conservar identidad para emigrantes/expedición y estado material del sitio.
- Producción limitada por receta/insumos/trabajo/estación/tiempo; sin recursos por población o por el simple paso del tiempo salvo producción regenerativa ya existente.
- El registro mundial persiste resultado fundado/recuperado; el orden de carga/exploración no determina su creación.
- Eventos de simulación se procesan por intervalo y condiciones, no una pasada de todos los NPC por frame.
- Guardar compromisos activos solo si pueden revalidarse; al cargar, reparar reservas huérfanas y evitar reejecución doble.
- Resolver y documentar tiempo offline/catch-up antes de activar simulación continua. Los documentos no fijan reloj.
- Transición resumido↔detallado fuera del primer núcleo, conforme M1-F5, salvo nueva aprobación y contrato atómico de identidad/recursos/red.

### Invariantes de aceptación

1. Balance material se conserva y cada entrada tiene causa.
2. Identidad de residente es única en origen, tránsito y destino.
3. Una ubicación tiene una ocupación compatible única; recuperación reusa ID.
4. Semilla + mismo estado/entradas produce igual decisión agregada bajo contrato de determinismo.
5. Simulación resumida no crea más salida que capacidad y recursos permitirían en detallado.
6. Un límite técnico detiene o aplaza operación con razón; no cambia reglas de mundo silenciosamente.

---

## 10. Qué descartar, simplificar o posponer

### Descartar como mecanismo central

- Fundación por temporizador, cuota o azar arbitrario.
- Recursos, habitantes, edificios o comercio “de fondo” sin fuente/coste.
- Sistema separado de pueblos/colonias/campamentos que duplique `Asentamientos`.
- Spawn que revive un pueblo destruido o convierte una ruina en refugio seguro mágico.
- Utilidad pura donde toda acción compite con un solo número sin filtros de factibilidad/urgencia.

### Simplificar

- Prioridades: pocas bandas semánticas + desempate contextual, no niveles numéricos extensos.
- Economía: reservas y trueque con bienes reales antes que moneda, salarios y precio dinámico.
- Movimiento poblacional: empezar con expedición fundadora y migración colectiva de crisis; aplazar movimiento individual libre si no es necesario.
- Ubicación: filtros duros + puntuación ordinal explicable; no modelo de mercado de suelo, búsqueda global cada tick ni planificación perfecta.
- Construcción: demanda de edificios/caminos/cultivos que existen; no sistema urbano libre ni progresión exhaustiva de obras.
- Historia: conservar sucesos y causalidad relevante, no simular todos los habitantes/diálogos fuera de cámara.

### Posponer explícitamente

- Transición resumido↔detallado hasta resolver M1-F5.
- Reproducción, edades, herencia y muerte natural.
- Política, líderes, facciones, tributación, guerra y conquistas.
- Mercado con moneda/precios dinámicos y arbitraje.
- Complejidad social (familias, instituciones, religión) no documentada.
- IA de planificación general/GOAP de horizonte largo.
- Nuevas recetas, efectos de herramienta o bonificaciones que cambien balance sin prueba/aprobación.

---

## 11. Decisiones pendientes de diseño

Estas decisiones deben resolverse antes de una instrucción implementable. No asignar cifras sin medir.

### Autonomía y prioridades
1. Qué necesidades individuales actuales generan acciones y qué niveles pueden interrumpir.
2. Si oficio es acceso/permisión o sesgo fuerte; recomendación: sesgo, con elegibilidad real por saber/capacidad y requisitos.
3. Qué acciones de ayuda existen realmente (salud, defensa, transporte, acompañamiento) y cuáles son deseables.
4. Qué influencia formal tienen confianza, grupos y memoria en trabajo/ayuda/intercambio.

### Economía
5. Titularidad/localización de stock: mochila, cofre, edificio, poblado, mundo; reglas de reservas y herramientas.
6. Si las tasas/consumo actuales son por actor/asentamiento y si aplican a residentes resumidos.
7. Alcance del trueque existente: actor a actor, grupos o asentamientos; costes y autoridad de servidor.
8. Horizonte y reserva de seguridad; proyectar sin fijar días/cantidades hasta línea base.
9. Si los bienes se transportan físicamente o se modelan como stock comunitario abstracto.

### Comunidades
10. Qué presión persistente justifica fundar en vez de ampliar o comerciar.
11. Criterio mínimo de campamento y pueblo funcional con edificios/objetos aprobados.
12. Tamaño/capacidades de expedición según tareas reales y viabilidad residual del origen.
13. Seguridad como filtro de fundación, factor de evaluación o condición de viabilidad posterior.
14. Abandono: qué estados/ocupación lo activan y qué se preserva de recursos/propiedad/edificios.
15. Quién puede recuperar un sitio, y qué ocurre si otro grupo lo ocupa o hay objetos de propietario.
16. Política de migración: grupo indivisible o subgrupos, destino imposible, bienes y residentes en tránsito.

### Mundo y operación
17. Reloj offline, avance cuando no hay clientes y catch-up de servidor.
18. Información de lugares conocida por NPC; cómo se usa mapa/rumores y cómo se descubre sin sesgo de orden de exploración.
19. Presupuesto de CPU/memoria y límites configurables para candidatos, expediciones, actores y poblados.
20. Política de compatibilidad de mundos/guardados y versión de reglas tras que cambie la generación controlada.
21. Qué información es pública/replicada a clientes y cómo se explica causa al jugador.

---

## 12. Secuencia de desarrollo por dependencias reales

No son cuatro proyectos separados (autonomía, economía, pueblos, migración). Son capas dependientes del mismo ciclo causal. La secuencia sugerida minimiza decisiones irreversibles antes de cerrar invariantes.

### Etapa A — Auditoría de contratos y línea base

**Necesaria antes de diseñar interfaces.** Contrastar `AUTONOMIA.md`, GDD sociedad, economía/protección, crecimiento/asentamientos, guardado, red, mundo por regiones y código. Producir matriz de: fuente de verdad, dueño, API, datos persistidos, resolución detallada/resumida, pruebas y brechas. Establecer escenarios/telemetría de la economía actual. No cambiar balance.

### Etapa B — Contrato común demanda/tarea/reserva/resultado

No reimplementar necesidades; mapearlas. Confirmar filtro de factibilidad, reclamación única, reserva/liberación, cancelación, revalidación e historial de causas en servidor. Probar NPC que trabaja, necesidad que interrumpe y fallo por insumo/ruta. Dependencia directa: inventario/recetas, saberes, autonomía, red y guardado.

### Etapa C — Ciclo de economía local

Consolidar demanda colectiva, stock libre/comprometido y tareas existentes. Probar comida/producción/consumo/cobertura de oficio en un asentamiento detallado y en uno resumido. No comercio nuevo todavía. La decisión de diseño clave aquí es titularidad/reserva de inventario.

### Etapa D — Salidas entre comunidades

Una vez que déficits/excedentes sean causales, reutilizar trueque y rutas para una transferencia interasentamiento en especie. Resolver capacidad/tiempo/propiedad/en tránsito, idempotencia, memoria y réplica. No introducir precios o caravanas de calendario.

### Etapa E — Viabilidad y respuesta reversible

Derivar estado de viabilidad de comida, camas, residentes y seguridad; umbrales requieren mediciones/aprobación. Responder con reasignación, enseñanza actual, comercio, reparación/obras compatibles y recepción en comunidades existentes. Pruebas de crisis antes de fundación.

### Etapa F — Persistencia de lugar y transacción de población

Validar generación controlada y registro `Asentamientos`, IDs de habitantes, carga/reservas y persistencia/red durante origen→tránsito→destino. Pruebas de reinicio, dos clientes, orden de exploración y reintento. Dependencia necesaria antes de exponer expediciones reales.

### Etapa G — Fundar, materializar y recuperar

Integrar evaluación de sitio, expedición, campamento/edificios reales, crecimiento por demandas, abandono y recuperación. Primero mundos de prueba/simulaciones deterministas; medir coste, diversidad de resultados y tasas observadas sin fijar valores de balance. La expansión solo se activa al cerrar contratos de fases previas.

### Etapa H — Escala y compatibilidad

Pruebas a población/regiones crecientes, guardados/versionado, simulación resumida, conectividad y carga. Definir límites técnicos configurables por evidencia. Mantener transición resumido↔detallado fuera del alcance hasta resolver M1-F5.

**Regla de dependencia:** no abrir Etapa G si un residente puede duplicarse al migrar, una receta crea recursos en resumido, las tareas no liberan reservas, o el registro de lugar depende del orden de exploración.

---

## 13. Escenarios integrados de verificación

Los plazos abajo son ilustrativos (semanas/meses lógicos), no valores de balance. Solo se activan sistemas existentes comprobados; donde no exista un mecanismo, el escenario debe adaptarse o quedar bloqueado con decisión explícita.

### Escenario 1 — necesidad individual desencadena una cadena hasta un pueblo nuevo

**Estado inicial:** A tiene residentes, cultivos/producción y saberes registrados; B está conectado o conocido. Un NPC sufre necesidad de alimento y la reserva colectiva cae. El recurso que permitiría aliviarla es distante.

- **Día/semana inicial:** la necesidad personal se atiende si hay comida realmente accesible. A la vez, el asentamiento agrega la demanda y descuenta órdenes, reservas y consumo previsto. El déficit no es un marcador: se puede rastrear a stock/producción concretos.
- **Semana siguiente:** tarea de producción local aparece si receta, trabajador, estación, insumos y ruta existen. Un residente capaz la reclama; otro no duplica la orden. Si falla por material, libera reserva y registra causa. Un aprendiz solo sustituye al experto mediante enseñanza existente y tiempo real.
- **Semanas posteriores:** A evalúa intercambio con B. B solo acepta si conserva su propia reserva; bienes y ruta quedan comprometidos. El coste/demora se compara con ampliar cultivo/taller local.
- **Mes 2:** la escasez persiste y se repite; los costes de transporte desde el núcleo hacen que una ubicación secundaria mejore el acceso. Se inicia propuesta de expedición solo tras comprobar que reasignación/comercio/ampliación no resuelven adecuadamente.
- **Mes 3:** grupo con identidades, herramientas, saber y provisiones sale; las entidades pasan a tránsito sin duplicarse. La ubicación elegida es válida y determinista; el lugar solo nace como asentamiento al llegar/establecer actividad real.
- **Mes 4:** el grupo construye/ocupa edificios permitidos y obtiene recursos; consume sus provisiones. Tras cumplir criterios aprobados, el campamento se considera funcional. El déficit original disminuye y cambia la distribución del trabajo en A; no se activa una segunda fundación por inercia.

**Pruebas:** misma secuencia con abundancia local debe evitar fundar; falta de herramienta debe detener/alternar la receta; repetir semilla/entradas produce misma ubicación/desenlace.

### Escenario 2 — migración en crisis con destino limitado

**Estado inicial:** C tiene déficit persistente, la seguridad se deteriora según sistemas reales y D tiene capacidad parcial, no ilimitada.

- **Semana 1:** C detecta déficit proyectado, prioriza necesidades esenciales y suspende producción no necesaria. Una tarea sin ruta/capacidad no se intenta indefinidamente.
- **Semana 2:** trata de comerciar o reubicar trabajo. D evalúa la petición por recursos/camas/seguridad y consumo añadido. La cercanía por sí sola no prueba viabilidad.
- **Semana 3:** al no ser sostenible quedarse, se evalúa migración colectiva. La transferencia conserva un ID único y bienes de viaje; el origen retiene solo quienes realmente quedan. Se puede evacuar en varios grupos si diseño aprobado lo permite.
- **Semana 4:** el primer grupo transita, consume recursos o queda expuesto conforme al modelo de viaje acordado; no cuenta simultáneamente como población activa en ambos sitios.
- **Mes 2:** D recibe solo lo que puede sostener. Aumenta demanda/comida/camas; su propia viabilidad puede caer y activar trabajo o una decisión adicional. C conserva camino, construcciones e historia, pero deja de producir si no tiene residentes.
- **Mes 3:** si quedan residentes, C puede reconstruir con medios reales; de lo contrario persiste abandonado. El algoritmo de spawn no lo revive. D puede devolver/redistribuir población si su carga se vuelve insostenible conforme reglas aprobadas.

**Pruebas:** fallo en mitad del viaje, guardado/carga en tránsito, reinicio del servidor, dos clientes y destino que pierde capacidad antes de llegada.

### Escenario 3 — abandono y recuperación sin borrar historia

**Estado inicial:** E pierde cobertura de oficio esencial y excedentes; edificios/caminos existentes permanecen. F vecino puede llegar y dispone de parte de lo necesario.

- **Mes 1:** el sistema busca generalista/saber/enseñanza y trueque; ninguna solución inventa insumos. Déficits repetidos bajan viabilidad.
- **Mes 2:** residentes migran gradualmente o se desplazan por crisis; reservas y consumidores bajan junto a identidades transferidas. E queda vulnerable.
- **Mes 3:** al no quedar habitantes/actividad según definición aprobada, E pasa a abandonado. Su ubicación e historia se preservan; deterioro/propiedad sigue reglas actuales.
- **Mes 5:** F necesita un nodo de producción/almacenamiento para una demanda local. Compara E frente a otro sitio: coste de reparación y amenaza contra infraestructura/ruta aprovechable. Si no hay ventaja o recursos, no recupera.
- **Mes 6:** una expedición real ocupa el mismo ID de E, inspecciona, repara con materiales y recupera estructura existente cuando es posible. El sistema evita crear otro poblado coincidente.
- **Mes 7:** si comida, camas, residentes y seguridad vuelven a criterios aprobados, E retorna a viable/activo conservando historia; de lo contrario permanece en recuperación y puede volver a abandonarse.

**Pruebas:** sitio ocupado por otro grupo, edificio parcialmente destruido, recurso saqueado, intento de duplicar ID y reactivación no permitida por spawn.

### Escenario 4 — expansión que no ocurre (control negativo)

A tiene población creciente y materiales, pero su economía cubre necesidades, camas y seguridad, y el coste de crear una ruta/sitio excede cualquier beneficio. Aunque existan terrenos libres, el asentamiento no funda. Si aparecen una nueva necesidad o escasez, el sistema vuelve a comparar alternativas. Este caso es esencial para demostrar que la expansión no está impulsada por timer/cuota.

---

## 14. Métricas y criterios de evaluación

No son metas numéricas fijadas; se deben recolectar y aprobar después de medir línea base.

### Causalidad
- Porcentaje de cambios de recursos/habitantes/edificios con causa y operación origen.
- Déficits por causa, tiempo de respuesta, alternativa elegida y resultado.
- Cantidad de tareas redundantes, bloqueadas, canceladas y razones.

### Estabilidad económica/social
- Reservas, consumo, producción, excedentes y escasez en el tiempo.
- Cobertura por oficio/saber y dependencia de persona única.
- Migraciones, fundaciones y abandonos; duración del campamento; ratio de expediciones exitosas/fallidas.
- Cambios de población, camas, seguridad y viabilidad por asentamiento.
- Oscilación: cambios repetidos de objetivo, rutas o destino sin cambios materiales suficientes.

### Persistencia/red/determinismo
- Cero duplicaciones/pérdidas de NPC, objetos, sitios, edificios o rutas en save/load y dos clientes.
- Mismo mundo con orden distinto de exploración conserva el registro de lugares y resultados ya creados.
- La misma semilla y entradas produce decisiones agregadas reproducibles bajo el contrato.
- Servidor y clientes convergen; operaciones repetidas son idempotentes.

### Rendimiento
- Tiempo/CPU por paso según habitantes, demandas, tareas, sitios y regiones.
- P95 de actualización relevante y memoria bajo carga creciente, con configuración del entorno de prueba documentada.
- Comparación resumido/detallado de balances, no solo FPS.

### Calidad de experiencia
- Un observador puede entender por qué un residente trabaja/ayuda/migra y qué cambió.
- El mundo conserva testimonio visual/material de los cambios sin requerir tutorial o misión obligatoria.
- Las comunidades no son invulnerables, pero el inicio de jugadores respeta decisiones de aparición y amenazas vigentes.

---

## 15. Contraste con las investigaciones anteriores

### Reutilizar, no duplicar

- La propuesta de decisiones individuales aporta filtros de factibilidad, urgencia, puntuación contextual, compromiso y explicación. Se convierte en el **selector compartido** para tareas, no en un segundo sistema de decisión.
- La economía aporta demandas consolidadas, balances, stock/reservas, cadenas de receta, trueque y simulación conservativa. Alimenta necesidades/viabilidad; no se convierte en un mercado independiente.
- La evolución de comunidades aporta predicados de grupo y lugar: expedición, candidatura, sitio persistente, campamento/activo/abandonado/recuperación. Estos son procesos de dominio que usan el mismo contrato de tarea y transacción.
- La autonomía/social ya documentada aporta necesidades, grupos, memoria, confianza, saberes/enseñanza y oficios; su significado exacto se audita, no se recrea.

### Contradicciones resueltas

1. **Autonomía individual vs. necesidad colectiva:** no son dos cerebros equivalentes. Necesidad individual genera objetivo del actor; el poblado agrega demanda y la distribuye. Urgencia crítica personal puede interrumpir, pero no borra la demanda colectiva.
2. **Profesión vs. flexibilidad:** recomendación de oficio como sesgo/rol, con saber/capacidad y requisitos de trabajo como filtro. No usar oficio exclusivo por defecto, salvo contrato actual o herramienta exclusiva documentada.
3. **Puntuación vs. causas:** puntuación se usa para ordenar opciones factibles; no convierte preferencia o azar en motivación. Fundación requiere necesidad previa y ventaja neta.
4. **Comercio vs. producción local:** comercio es opción, no fuente mágica; no fundar hasta comparar alternativas y costes. Se puede comerciar sin precio monetario.
5. **Misma regla vs. simulación resumida:** identidad causal y balance iguales; resolución y representación distintas. No adelantar transferencia detallado↔resumido.
6. **Recuperación vs. spawn:** recupera un grupo real mediante recursos/trabajo; spawn consulta comunidades existentes viables según política, nunca las reanima.
7. **Emergencia vs. límites:** topes técnicos pueden postergar una decisión, no tomarla artificialmente. Se documenta el motivo.
8. **Riqueza de referentes vs. alcance Linde:** no importar guerras, política, reproducción, mercado global o personajes líderes para dar una “razón dramática”. Escasez, rutas, necesidades y amenazas existentes ya pueden generar consecuencias.

---

## 16. Plantilla para el agente que contraste con el repositorio

Al pasar este documento a un agente con acceso al código, solicitar que complete primero esta matriz antes de proponer cambios:

| Área | Archivo/sistema actual | Contrato observado | Persistencia/red | Modo resumido | Pruebas | Gap respecto a diseño |
|---|---|---|---|---|---|---|
| Necesidades individuales | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Producción/recetas/consumo | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Trueque/relaciones/memoria | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Oficios/saberes/pericia | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Inventarios/reservas/propiedad | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Tareas/rutas/estaciones | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| `Asentamientos` / IDs de residentes | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Generación persistente de lugares | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Casas/cultivos/caminos/obras NPC | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Reloj offline/guardado/versionado | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Autoridad/replicación/red | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |
| Viabilidad/amenazas/spawn | Por verificar | Por verificar | Por verificar | Por verificar | Por verificar | — |

**Instrucción importante:** mapear recomendación a reutilización concreta antes de inventar nuevo modelo. Reportar evidencia/archivo y pruebas actuales; no modificar código ni balance al completar diagnóstico si la tarea es solo contraste.

---

## 17. Decisión maestra recomendada

Aprobar la **dirección** —no automáticamente cada detalle— de estos puntos:

1. Un ciclo causal común de demanda → opciones factibles → compromiso/tarea → efectos persistentes → reevaluación.
2. NPC elige acciones factibles; asentamiento agrega demandas y evalúa respuestas; grupo materializa movimiento conjunto; mundo conserva lugar/tiempo/resultado.
3. Uso obligatorio de sistemas existentes donde su contrato lo permita; sin paralelo para necesidades, habilidades, economía o pueblos.
4. Fundar solo por presión persistente y ventaja neta frente a alternativas, con personas, conocimientos, recursos y ruta reales.
5. Toda producción/intercambio/construcción/migración es material y auditable; simulación resumida conserva balances y causa.
6. El asentamiento conserva su identidad durante actividad, crisis, abandono y recuperación; spawn no revive comunidades.
7. Reglas causalmente iguales para pueblos iniciales y nuevos; transición resumido↔detallado sigue aplazada.
8. Sin umbrales de balance, precios, reproducción, política o guerras hasta decisión explícita y evidencia.
9. Antes de implementar, cerrar auditoría técnica y decisiones pendientes; después probar casos positivos y negativos, incluyendo “no fundar”.

**Definición de éxito:** Linde produce comunidades que a veces crecen, comercian, fundan, migran, decaen o se recuperan como resultado trazable de necesidades y condiciones persistentes. Ningún resultado depende de una cuota narrativa o recurso gratis; las mismas reglas pueden explicar tanto prosperidad como fracaso.

---

## Referencias de las investigaciones previas

- `Propuesta_Fase_6_Linde.md` — módulos y dependencias generales de autonomía/sociedades.
- `Investigacion_Decisiones_NPC_Linde_Fase6.md` — selección individual híbrida, factibilidad, prioridades, compromiso y casos de decisión.
- `Investigacion_Economia_Emergente_Linde_Fase6.md` — balances, producción, escasez, intercambio y simulación resumida.
- `Investigacion_Evolucion_Asentamientos_Linde_Fase6.md` — fundación, terreno, expediciones, migración, decadencia y recuperación.

## Referencias externas seleccionadas

### Juegos
- Dwarf Fortress Wiki: [Site](https://dwarffortresswiki.org/index.php/Site), [Reclaim fortress mode](https://dwarffortresswiki.org/index.php/Reclaim_fortress_mode), [World activities](https://dwarffortresswiki.org/index.php/World_activities), [Holding](https://dwarffortresswiki.org/index.php/Holding).
- Songs of Syx Wiki: [World](https://songsofsyx.com/wiki/index.php/World), [Settlement](https://songsofsyx.com/wiki/index.php/Settlement), [Citizens](https://songsofsyx.com/wiki/index.php/Citizens).
- RimWorld Wiki: [Caravan](https://rimworldwiki.com/wiki/Caravan), [Faction base](https://rimworldwiki.com/wiki/Faction_base), [Ruins](https://rimworldwiki.com/wiki/Ruins_(Abandoned_Colony)).
- WorldBox community wikis: [Villages](https://the-official-worldbox-wiki.fandom.com/wiki/Villages), [Civilizations/Kingdoms/Villages](https://worldbox-sandbox-god-simulator.fandom.com/wiki/Civilizations,_Kingdoms,_and_Villages).
- Decisiones/economía comparativa: Dwarf Fortress [Work orders](https://dwarffortresswiki.org/index.php/Work_orders); RimWorld [Bills](https://rimworldwiki.com/wiki/Bill); Songs of Syx [Trading](https://songsofsyx.com/wiki/index.php/Trading); Victoria 3 [Market](https://vic3.paradoxwikis.com/Market), [Needs](https://vic3.paradoxwikis.com/Needs).

### Modelos multiagente
- Epstein & Axtell/Sugarscape: [JASSS model description](https://jasss.soc.surrey.ac.uk/12/1/6/appendixB/EpsteinAxtell1996.html), [Mesa with traders](https://mesa.readthedocs.io/stable/examples/advanced/sugarscape_g1mt.html).
- Schelling: [NetLogo Segregation](https://ccl.northwestern.edu/netlogo/models/Segregation), [JASSS analysis](https://www.jasss.org/15/1/6.html).
- [An Agent-Based Model for Simulating Inter-Settlement Trade in Past Societies](https://www.jasss.org/23/3/10.html).
- [An agent model of urban economics: Digging into emergence](https://www.sciencedirect.com/science/article/abs/pii/S0198971514001379).

Fuentes de juegos incluyen wikis secundarias/comunitarias y pueden reflejar versiones diferentes; se citan como patrones observables y no como especificaciones internas. Las referencias multiagente son modelos analíticos simplificados, no soluciones listas para producción ni evidencia de implementación en Linde.
