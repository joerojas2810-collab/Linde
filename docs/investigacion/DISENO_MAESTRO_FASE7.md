# DISENO_MAESTRO_FASE7.md

## Propósito y estado

Diseño implementable para la **Fase 7: Ecología y dificultad territorial** de Mundo 1. Convierte la investigación existente en una especificación incremental; no repite la investigación ni aprueba balance o implementación.

**Autoridad de proyecto:** `ESTADO.md`, `DECISIONES.md`, `VISION_MUNDO_1.md` y `PLAN_MUNDO_1.md` adjuntos. La investigación `LINDE_Fase_7_investigacion_ecologia.md` es fundamento, no autoridad sobre el código actual. El repositorio no está disponible en esta tarea: los componentes y pruebas nombrados aquí son reutilización reportada por los documentos, pendientes de confirmar en el checkout antes de modificar.

**Estado conocido al 26-10-2026:** Fase 7 no está implementada como sistema ecológico. `ESTADO.md` informa cinco criaturas exteriores, aparición determinista, bajas/heridas persistentes, fauna basada en bioma, y pruebas de fauna registradas; informa también distribución casi uniforme, una criatura por región elegible (85 % en la medición reportada), sin simulación lejana, sin perfiles de actividad/hábitat suficientes ni señales previas, y atascos de fauna. La implementación exacta debe verificarse. El estado registrado considera `Fauna.plan_region`, reglas de fauna en datos, bajas/heridos y `Combate` candidatos a reutilizar.

## 1. Principios no negociables

1. **Dificultad territorial, no escalado de nivel:** el peligro depende de hábitat, especie, lugar, actividad, recursos y acontecimientos. Sin regiones bloqueadas ni ajuste automático al nivel del personaje (M1-D12).
2. **Causalidad y persistencia:** fauna y amenazas proceden de regiones/lugares/condiciones y de la historia del mundo; no aparecen junto al jugador como respuesta arbitraria.
3. **Legibilidad:** señales deben corresponder al estado real y dejar margen razonable de decisión. El mapa puede mostrar conocimiento aproximado; no revelar verdad no descubierta.
4. **No invulnerabilidad territorial:** los pueblos pueden sufrir ataques y desaparecer. La aparición de un jugador nuevo debe conservar una oportunidad razonable de reacción (M1-P; política de aparición vigente es explícita y separada).
5. **Mundo compartido y autoritativo:** servidor decide cambios; clientes representan y conocen lo que corresponda. Generación determinista no debe confundirse con regeneración ecológica.
6. **Geografía estable, ecología/civilización cambiante:** preservar semillas, identidad y cambios guardados. Carga de región no vuelve a generar el estado inicial.
7. **Reutilizar antes de ampliar:** extender datos y sistemas existentes de `Fauna`, terreno/regiones, deltas, combate, caminos, lugares, autonomía y asentamientos; no crear un sistema paralelo de biomas/pueblos/fauna.
8. **Balance protegido:** no cambiar daño, vida, velocidad, recompensas, XP, recetas, costes, tasas ni progresión sin mediciones y aprobación expresa (M1-D14). El tamaño de población y densidad también afectan balance, aunque no cambien estadísticas.
9. **Simulación reducida:** fuera de las regiones activas basta con estados agregados/eventos si se demuestra que permiten la experiencia buscada. No exigir reproducción, migración o ecología científica para considerar cumplida Fase 7.

## 2. Alcance priorizado

### 2.1 Necesario para cumplir la Fase 7 original

- Perfiles declarativos de hábitat/actividad por bioma para fauna ya existente.
- Distribución espacial no uniforme e intencional: zonas de calma asociadas a caminos/poblados según reglas comprobadas, zonas de transición y peligros vinculados a lugares. No cambiar reglas de aparición sin preservar la política M1-C1/1e y medir resultados.
- Señales previas de peligro generadas desde fuentes/amenazas reales y persistentes, legibles en ambiente o información de NPC.
- Persistencia de la causa ecológica y sus efectos relevantes: una región/lugar ya generado no se vuelve a sembrar al cargar; una baja o perturbación no se deshace de manera arbitraria.
- Interacciones compatibles con IA y asentamientos existentes: amenazas reales pueden alcanzar NPC/actividad/asentamiento conforme a capacidades verificadas; nada de inmunidad invisible ni consecuencias sociales inventadas.
- Resolver/mejorar la navegación que origina los atascos medidos, si el diagnóstico de código confirma que es el mismo caso descrito en plan; conservar prueba de regresión.
- Medición de peligro en el primer trayecto, tiempos/señales de aviso, distribución por semillas y rendimiento.

### 2.2 Mejoras ecológicas opcionales

- Stock resumido de recursos vegetales/faunísticos por región o lugar, con extracción y recuperación condicionada.
- Presión local por caza, tala, construcción o tránsito y respuesta de distribución de fauna.
- Desplazamiento entre regiones vecinas como transición abstracta, no navegación individual lejana.
- Estacionalidad para especies o recursos cuando reloj/datos actuales la soporten.
- Efecto económico sobre oficios/recursos de NPC y asentamientos, usando inventarios, producción y necesidades existentes.
- Diversidad intra-bioma mediante microhábitats si el costo de contenido/QA es bajo.

Estas mejoras no deben bloquear la entrega mínima de Fase 7. Se incorporan por evidencia: un patrón jugable que la capa mínima no resuelve, rendimiento aceptable y una prueba que detecte duplicación/agotamiento.

### 2.3 Aplazar

- Reproducción silvestre individual, genealogías, edades y genética.
- Simulación individuo a individuo fuera de regiones activas.
- Cadena trófica completa, enfermedad, nutrientes, hidrología/clima detallado o sucesión ecológica por celda.
- Migración autónoma de largo alcance si no hay necesidad jugable demostrada.
- Ataques dirigidos a jugadores por “director” o spawn por proximidad como sustituto de ecología.
- Integración con fundación, abandono y viabilidad avanzada de poblados (Fase 6), salvo una interfaz de datos/eventos sin efectos hasta que esa fase exista.

## 3. Modelo conceptual y fronteras de estado

Mantener separados cuatro conceptos:

1. **Hábitat base:** región/coordenadas, bioma actual, terreno y condiciones existentes. Es reproducible por semilla/versión del terreno; no es el estado ecológico dinámico.
2. **Estado ecológico persistente:** entidades/huellas locales, bajas/heridas, stock/agotamiento si se aprueba, eventos recientes y presiones persistentes. Lo actualiza el servidor; sobreviven guardar, cargar y streaming.
3. **Representación activa:** criaturas individuales que el servidor necesita mover/combate dentro de regiones activas. La política y el límite técnico existentes se conservan hasta medir cualquier cambio.
4. **Conocimiento/presentación:** señales vistas, rumores y símbolos del mapa personal. No confundirlo con verdad del mundo ni replicar automáticamente amenazas ocultas a todos.

La región es la unidad de generación/ecología resumida inicial por coherencia con `Fauna.plan_region`; los lugares persistentes (ruina, campamento, cueva y poblado) son anclas semánticas para guaridas o peligros. No crear un registro paralelo: aprovechar el registro actual de lugares/poblados si la revisión confirma los datos y contrato indicados en ESTADO.

## 4. Biomas y reglas de hábitat

### Contrato de diseño

Cada bioma aporta un **perfil de compatibilidad**, no un nivel de dificultad. Debe distinguir lo que es: (a) visual, (b) condición de terreno/recursos, (c) hábitat de fauna, (d) condición de peligro. Un perfil identifica especies y actividades compatibles, restricciones ya disponibles en el terreno y posibles recursos; no fuerza que cada tipo aparezca en cada región.

### Entrega mínima

- Revisar los biomas existentes y enlazar reglas de fauna actuales a esos ids, preferentemente ampliando datos existentes.
- Reemplazar la distribución casi uniforme reportada por selección de regiones/lugares elegibles de acuerdo con perfiles, con probabilidades/ponderaciones que **no se fijan en este documento**.
- Proteger invariantes: una región no cambia de contenido por orden de exploración; introducir datos nuevos no debe modificar aleatoriamente streams de otros sistemas; la carga ordinaria no genera una segunda población.
- No modificar texturas, crear un mapa climático nuevo ni rehacer `terreno_v1/v2` como parte de esta fase.

### Opcional

Subhábitats con rasgos ya representables (ribera, claro, bosque denso, cueva). Añadirlos sólo cuando una regla de especie o recurso necesite una diferencia espacial visible y testeable. No convertir cada combinación de suelo/bioma en un nuevo bioma.

### Evaluación crítica

Los perfiles ofrecen alto valor por bajo costo y son necesarios para que la dificultad sea territorial. Una simulación de humedad, nutrientes o temperatura por celda añadiría estados, sincronización y balance sin ser requisito para distinguir hábitats en la primera entrega. Antes de codificar, validar que bioma no sea hoy sólo presentación y cómo obtenerlo sin generar regiones nuevas.

## 5. Fauna y población

### Núcleo requerido: poblaciones no añadidas al azar junto al jugador

La generación de fauna tiene dos etapas conceptuales: **elegibilidad espacial** (región/lugar, hábitat, estado del mundo, exclusiones existentes) y **materialización/actividad** (sólo si la región y el presupuesto de entidades lo permiten). La cercanía del jugador puede activar mayor detalle o visibilidad, pero no crear población sin fuente. En el arranque de Fase 7, conservar la política actual de cantidad/techo salvo cambios aprobados.

Cada criatura ya existente debe utilizar su perfil de hábitat y las reglas/estados que el repo confirme. Reutilizar bajas/heridas persistentes si se verifica que representan la pérdida real y no sólo una excepción de spawn. Un animal no muerto ni desplazado no debe desaparecer al cargar por una condición local accidental.

### ¿Hace falta reproducción?

No para la Fase 7 original. La distribución puede ser determinista, persistente y variada sin reproducción: población inicial creada una vez + muertes/perturbaciones persistidas + posible recuperación agregada opcional. Reproducción individual implica pareja/sexos o regla simplificada, edades/tiempo, competencia, topes, control de extinción/explosión y migración de instancia; beneficio jugable aún no demostrado. **Aplazar** hasta que la caza/agotamiento y recuperación no puedan modelarse con stock regional ni reglas existentes.

### ¿Hace falta migración?

No para la primera entrega. La redistribución espacial puede realizarse en generación y eventos/lugares anclados. Desplazamiento entre regiones tiene valor si el jugador puede alterar hábitat y observar fauna migrar; cuesta transición de individuos, identidad, rutas y estados de regiones descargadas. **Opcional posterior** como transferencia agregada entre regiones vecinas, con suma de población conservada y sin teletransporte cerca del jugador.

### ¿Hace falta dinámica depredador-presa?

Sólo la relación mínima necesaria para explicar comportamientos existentes (p. ej., una criatura caza otra si la IA ya lo soporta). No construir una red trófica global. Si la presa es un recurso real, debe descontarse del stock/individuo y quedar en persistencia; si no, la interacción sería cosmética y no debe presentarse como mecanismo ecológico completo.

## 6. Peligros territoriales, zonas de calma y asentamientos

### Distribución

Clasificar espacios funcionalmente, sin una barrera de nivel:
- **Entorno de actividad humana:** caminos/poblados; menor probabilidad de especies que evitan presencia si se justifica por comportamiento/hábitat.
- **Territorio ordinario:** especies compatibles y riesgo legible.
- **Lugar de peligro:** guarida/cueva/campamento u otra ancla con amenaza específica y condición/origen persistente.

Esas categorías no son niveles ni “zonas seguras mágicas”. La regla 1e existente del núcleo (slimes no anidan en radio de centro al generar) no debe expandirse a inmunidad absoluta; un enemigo puede entrar por persecución. Revisar que perfil y selección de spawn respeten ambos: distinción poblado/naturaleza y política de nueva aparición.

### Amenazas ligadas a lugares

Prioridad a amenazas existentes colocadas/representadas por reglas del lugar, no nuevo catálogo. Un lugar peligroso debe tener fuente, área y señal. Su amenaza no debe reaparecer al abrir región si fue derrotada; si puede recuperarse, esa recuperación necesita regla explícita y estado persistente, no “se regeneró por carga”. Fase 4 ya dispone de lugares persistentes; no añadir cuevas transitables ni jefes como requisito.

### Peligro para NPC y comunidad

- Primero verificar qué combate, target selection y daño a NPC/estructuras existe. No afirmar que una amenaza pueda atacar pobladores por la sola existencia de fauna.
- Necesario si está soportado: fauna/peligro no debe tratar a los asentamientos como invulnerables por flag; si la amenaza alcanza un NPC, evaluar la interacción mediante reglas actuales de combate/vida y persistir la consecuencia.
- Si NPC o edificios no tienen contrato de daño/defensa, el alcance mínimo es **presión y aviso**: residentes identifican/evitan un peligro según rutinas existentes; no fingir muertes, asedios ni pérdida de edificios. Registrar como limitación y dependencia técnica, no implementar un sistema paralelo de combate de asentamientos.
- El efecto sobre viabilidad, abandono, migración o aparición alternativa depende de Fase 6 y sus umbrales aprobados; Fase 7 no inventa ni cambia esos umbrales.

## 7. Señales ambientales y conocimiento

### Contrato

Toda señal ambiental tiene origen que puede auditarse: entidad viva, evento de daño/extracción, ubicación de guarida o condición ambiental persistente. Debe describir dirección/categoría/antigüedad razonable; no proporcionar coordenada exacta si el personaje sólo observa una huella o recibe un rumor aproximado.

### Canales a reutilizar

- Presentación ambiental próxima (rastros, restos, sonido/animación si los assets actuales lo permiten).
- Conversación/rumores de NPC existentes y mapa personal/exploración de Fase 2.
- Pistas contextuales opcionales de Fase 3, si el evento satisface sus condiciones; no convertir pistas en misión ni duplicar señales.

### Reglas imprescindibles

- Una huella desaparece o envejece de acuerdo con estado/tiempo, nunca se re-sortea en cada carga.
- Una señal no debe indicar una amenaza inexistente; una amenaza que se mueve puede dejar rastro, pero no se conserva una indicación exacta falsa.
- La señal ofrece una opción de respuesta razonable: evitar, acercarse con cautela, observar o retirarse. La aceptación se mide; no se fijan segundos nuevos en este diseño.
- Sólo el jugador que ve/recibe la señal incorpora ese conocimiento a su mapa personal; compartirlo sigue el mecanismo actual de conocimiento, si la auditoría confirma el contrato.

## 8. Persistencia, determinismo y simulación distante

### Primera versión recomendada

No introducir una simulación poblacional global. Reutilizar `Fauna.plan_region`, estado persistente y deltas ya informados, tras inspeccionar el repo. Guardar una vez la decisión inicial de fauna por región y aplicar después bajas/cambios causales. Si el sistema actual ya recalcula por semilla sin registrar generación, añadir persistencia sólo donde haga falta para no reinstalar una criatura muerta o reponer población sin regla.

### Simulación distante

Para cumplir Fase 7 no se requiere procesar cada fauna lejana. Mantener el modelo actual si no hay evidencia de población lejana; no agregar ticks. Si una mejora opcional de recuperación/migración se aprueba, representarla como stock/presión/evento regional con actualización en un intervalo controlado, bajo reglas deterministas y eventos idempotentes. No materializar agentes al cambiar de región sin reconciliar población/ids.

### Determinismo compartido

- La autoridad decide ubicación, resolución y persistencia; clientes no ejecutan decisiones ecológicas propias.
- Decisiones nuevas deben ser estables respecto del orden de carga/exploración y reinicio, y no alterar generadores existentes ni resultados previos de regiones registradas.
- Antes de elegir fórmula/semilla, auditar stream actual. Evitar que añadir una especie o regla consuma números de una secuencia global utilizada por otros subsistemas.
- Carga/regeneración de terreno y avance ecológico son operaciones distintas; ninguna lectura debe restaurar fauna, recursos o señales sin un evento/regla aprobado.

## 9. Consecuencias sobre recursos, economía y vida social

### Requerido mínimo

La ecología debe permitir al menos que explotación/actividad y peligros tengan consecuencias territoriales persistentes y observables. Para la primera entrega basta registrar y presentar las consecuencias que los sistemas existentes pueden sostener: fauna baja/herida, zona/lugar afectado y actividad humana asociada. No prometer escasez económica si el stock no se conecta a producción real.

### Opcional, tras verificar inventarios y consumo

Conectar un stock vegetal/faunístico a recursos de oficio/caza y a producción de `Asentamientos`, sin cambiar recetas/tasas. Consecuencia posible: menor disponibilidad local obliga a desplazarse o a comerciar usando sistemas existentes. Necesita conservar contabilidad: recurso cosechado no puede ser a la vez stock silvestre, producción automática y botín.

### No en esta fase

La nueva fundación, abandono/recuperación automática y efectos en viabilidad de pueblo pertenecen a Fase 6 (no iniciada según `PLAN_MUNDO_1.md`). No condicionar su implementación ni alterar fallback a otro poblado ahora. Diseñar el registro de eventos de forma que Fase 6 pueda consumirlo después, sin acoplar Fase 7 a decisiones futuras.

## 10. Dependencias y relación con Fase 6

**Fase 6 no es dependencia para la entrega mínima de Fase 7.** El orden del plan es `… → 5a → 7 → 5b → 6`; el objetivo de Fase 7 se puede validar con terreno, fauna, lugares y caminos existentes. La Fase 6 depende de condiciones y viabilidad de asentamientos; por tanto:

- **No bloquear Fase 7** por fundación/abandono autónomos, migración entre pueblos o transición de NPC resumido↔detallado.
- **Preparar compatibilidad:** los eventos de peligro/escasez pueden alimentar más adelante la seguridad/viabilidad, pero sólo mediante un contrato de datos estable y sin modificar comportamiento antes de Fase 6.
- **No asumir viabilidad calculada:** comida, camas, residentes y seguridad son criterios de diseño con umbrales aún pendientes de aprobación/medición. No usar una nueva métrica ecológica para declarar un pueblo inviable.
- **Si antes de Fase 7 se inicia Fase 6**, congelar interfaces y comprobar que el criterio de seguridad no contradiga 1e, M1-P y aparición. Que asentamiento sea vulnerable no elimina protección de incorporación razonable.
- **Fase 5b tampoco es dependencia:** fauna individual/regional y residente resumido/detallado son problemas separados; no resolver ambos en un mismo hito.

## 11. Secuencia incremental de implementación

Cada paso debe conservar la línea base, tener cambios acotados y detenerse si contradice estado/código. No se asignan valores de balance.

### Paso 0 — Auditoría de código y línea base (sin cambios)
**Objetivo:** confirmar `ESTADO.md` contra checkout y cerrar lagunas del contrato.  
**Examinar:** `Fauna.plan_region`, catálogo/reglas de fauna, regiones/terreno, bajadas/heridas, aparición, combate, lugar/poblado, autonomía/asentamientos, señales/mapa, guardado/réplica y BFS/pathfinding. Confirmar formato de datos, RNG, límites y autoridad.  
**Pruebas mínimas:** ejecutar/revisar la suite `prueba_fauna` y pruebas actuales de terreno/red; documentar resultados de la ejecución, no reutilizar históricos. Repetir medición P2 de atasco y fijar escenarios/semillas. Hashes de mundo/generación y costo de región como línea base.  
**Salida/gate:** mapa de funciones/rutas reales, diferenciar hecho/código de documentado, no-go si no se puede reproducir estado de generación/persistencia.

### Paso 1 — Hábitat declarativo (sin cambiar combate)
**Objetivo:** reducir uniformidad asignando elegibilidad/ubicaciones por perfiles de hábitat. Extender datos existentes, no arquitectura paralela.  
**Dependencias:** Paso 0.  
**Aceptación:** resultados consistentes para la misma semilla y versión; lugares/caminos/populado no mutan por orden de exploración; perfiles no seleccionan hábitat incompatible; ningún cambio de stats, daño, botín, ritmo o XP; diversidad y exclusiones inspeccionables en un reporte de semillas.  
**Pruebas mínimas:** determinismo de región en orden inverso/reinicio; `prueba_fauna`; `prueba_terreno`; validación JSON; cobertura de bioma×especie y exclusiones.  
**Criterio humano:** aprobar las zonas, especies y distribución visual antes de activar en mundo nuevo.

### Paso 2 — Distribución territorial, lugares y reglas de calma
**Objetivo:** representar el contraste entre caminos/poblados, terreno ordinario y lugares de peligro. Reutilizar registro persistente y política 1e existente, no inmunidad general.  
**Dependencias:** Paso 1; Fase 4.  
**Aceptación:** sin amenaza aleatoria creada por proximidad de jugador; amenazas ancladas a lugares tienen fuente persistente; el nuevo contenido no genera hostiles dentro de política de incorporación existente; una amenaza puede entrar por persecución conforme reglas de combate; no cambia el mundo legado fuera del alcance habilitado.  
**Pruebas mínimas:** semillas múltiples de spawn; distancia al camino/lugar; generación y carga/reinicio sin duplicación; entrada jugador posterior a cambiar el estado del poblado; pruebas de Fase 1 de aparición/amenazas, terreno y red. Los radios/umbrales permanecen los aprobados/medidos, no se fijan aquí.

### Paso 3 — Señales previas derivadas de estado real
**Objetivo:** colocar rastros/avisos de manera causal y persistente, con conocimiento personal.  
**Dependencias:** Paso 2; datos de pistas/mapa/NPC auditados.  
**Aceptación:** cada señal puede rastrearse a fuente/fecha/estado; no revela entidad desconocida exacta; no persiste engañosamente tras desaparición sin indicar antigüedad; una amenaza tiene una señal previa suficiente según métrica aprobada.  
**Pruebas mínimas:** señal con amenaza presente/ausente, movimiento/derrota, guardado y carga, visibilidad personal y compartir rumor; UI/red con dos clientes; capturas en terreno representativo.

### Paso 4 — Atascos, navegación y justicia del encuentro
**Objetivo:** corregir el caso reproducible de atasco. El plan menciona BFS existente como solución P2; comprobar si el error pertenece a ruta, recuperación o límites del escenario.  
**Dependencias:** Paso 0; paralelizable con Paso 3 si afecta archivos distintos.  
**Aceptación:** objetivo del PLAN: tasa de atasco <5 % en escenario P2 medido; ningún camino al primer destino con hostil por debajo de R y aviso ≥T sólo cuando R/T estén definidos y aprobados. No ajustar IA/estadísticas a ciegas; documentar escenario y calidad de la muestra.  
**Pruebas mínimas:** suite P2 reproducible y contrapruebas con obstáculos/bordes; `prueba_fauna`; pathfinding/reachability; medición antes/después.

### Paso 5 — Consecuencias ecológicas persistentes (mínimo acotado)
**Objetivo:** conservar causa/efecto de explotación y perturbaciones relevantes que ya soportan sistemas existentes. No implementar población dinámica sin necesidad.  
**Dependencias:** Pasos 1–4; inspección de deltas/stock.  
**Alcance inicial:** persistir bajas/heridas, sitio afectado y eventos necesarios; integrar destrucción/perturbación de lugar con regla de fauna sólo si un lugar se utiliza ya como fuente. No regenerar fauna/recurso por cargar.
**Aceptación:** guardado/carga y exploración inversa conservan el resultado; ningún evento doble por retry del cliente; recuperación no aparece hasta que exista regla explícita; economía, recetas y balance sin cambios.  
**Pruebas mínimas:** ida/vuelta de región, reinicio, carga de mundo, mutaciones por cliente repetidas, evento de fauna/lugar; pruebas de crecimiento/terreno/red relevantes.

### Paso 6 — Integración opcional de stock/recuperación con NPC
**Objetivo:** demostrar una cadena causal única desde explotación a efecto en disponibilidad social, si el Paso 5 deja evidencia de que resulta jugable.  
**Dependencias:** Paso 5; verificar economía y cosecha de `Asentamientos`. Fase 6 no requerida, pero sus umbrales no deben anticiparse.  
**Aceptación:** recursos no duplicados; extracción de jugador/NPC reduce el mismo stock; producción no inventa entradas; actividad/cambio visible en comunidad; medidas antes/después en varias semillas/días. Sin alterar precios/tasas/recetas sin D14.  
**Pruebas mínimas:** contabilidad de stock, economía regional sin jugadores, guardado/reinicio y prueba ENet con dos recolectores; regresiones autonomía/sociedad/crecimiento.

### Paso 7 — Decidir si se necesita dinámica de población
Sólo iniciar si mediciones/jugabilidad muestran que el modelo estático con bajas/deltas falla en un objetivo aprobado. Prototipo separado con entidad o stock; comparar costos y patrones. Reproducción y migración no entran automáticamente por ser “ecología”. Requerir prueba de equilibrio/extinción/duplicación y aceptación humana independiente.

## 12. Criterios de cierre de Fase 7

Fase 7 puede considerarse funcional cuando, en el alcance acordado:

- Reglas de hábitat hacen que la fauna y los peligros se distribuyan por territorio/lugar de manera reproducible, no casi uniforme por defecto.
- Caminos/poblados y lugares peligrosos tienen consecuencias espaciales definidas sin declarar pueblos invulnerables ni escalar por nivel.
- Las señales que se presentan están vinculadas a amenazas/estados reales y el jugador puede tomar una decisión razonable antes del peligro inevitable.
- Atascos del escenario acordado cumplen el objetivo del plan; R/T se resuelven con medición y decisión humana, no se rellenan aquí.
- Muertes, daños y cambios ambientales elegidos sobreviven a guardado/carga y a distinto orden de exploración; no se restablecen por streaming.
- El servidor decide cambios y dos clientes no duplican fauna/recursos; pruebas de red ejecutadas de nuevo.
- No aparecen cambios no aprobados en daño, vida, botín, XP, crafting, economía o progresión.
- Rendimiento medido en carga cercana/lejana y reportado bajo configuración reproducible.
- Se registra explícitamente qué interacciones NPC/asentamientos quedan pendientes por capacidades no existentes o Fase 6.

## 13. Decisiones humanas que siguen abiertas

No decidir por anticipado; cerrar con prototipo y medidas:

1. ¿Qué biomas y especies actuales entran en el primer perfil, y qué contenido visual señala cada hábitat?
2. ¿Se quiere “calma alrededor de caminos” como distribución probabilística de fauna o sólo menor actividad de especies concretas? ¿Qué causa física/social la explica?
3. ¿Qué unidad de persistencia necesita el juego: criatura individual, baja/huella por región o población agregada? Recomendación inicial: no ir más allá de lo que los datos de Fase 7 necesitan.
4. ¿Qué recursos realmente renovables cuentan para la experiencia actual, frente a materiales finitos? No seleccionar ni asignar tasas hasta revisar catálogo/recetas y mediciones de Fase 0.
5. ¿Qué sucesos pueden afectar a NPC/edificios con reglas ya existentes? Si no hay daño/defensa de asentamiento, aceptar el alcance de presión/aviso o autorizar más adelante una ampliación explícita.
6. ¿Qué señal se considera suficiente y cómo se medirá el tiempo real de reacción? R y T del plan continúan abiertos.
7. ¿Se permite recuperación natural de fauna/recurso? Si sí, qué condiciones y límites la justifican; si no, qué hará que la pérdida sea significativa y no un recurso bloqueado permanentemente.
8. ¿Cuándo Fase 6 definirá interfaz de seguridad/viabilidad? Evitar que Fase 7 introduzca una definición provisional de pueblo “seguro”.
9. ¿Qué métricas y semillas serán obligatorias para aprobar distribución/densidad, y qué evidencia permitiría cambiar el techo técnico actual?

## 14. Referencias internas y externas

- Internas: `LINDE_Fase_7_investigacion_ecologia.md`; `ESTADO.md` §§2, 3d–3j; `VISION_MUNDO_1.md` principios 1–8; `DECISIONES.md` M1-D12, M1-D14, M1-P, M1-C1/C2 y estado de Fase 7; `PLAN_MUNDO_1.md` §§2.6, 4 Fase 7, 5 y 7.
- Externas ya evaluadas en la investigación: tModLoader para predicados de spawn contextual/server-side; NetLogo/Mesa Wolf-Sheep para contabilidad simple de energía/recurso (no números de balance); ODD para documentar alcance y patrón. Don't Starve, Dwarf Fortress, RimWorld y Songs of Syx sólo como referencias de diseño, no fuente de código abierto verificable. No se realizó búsqueda nueva ni se introdujeron cifras de esos juegos.

---

**Aviso de implementación:** este documento no demuestra que el repo actual coincida con el estado adjunto. El Paso 0 es obligatorio antes de tocar código. Todo dato marcado como “reportado” requiere contraste con el checkout; todo valor de balance requiere medición y aprobación humana.
