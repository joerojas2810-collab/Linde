# Sociedad del valle — prueba de autonomía

Actualizada el 24 de octubre de 2026. **Ampliación posterior:** el mismo modo ahora incluye equipo combinatorio, materiales elaborados, práctica y ampliación de talleres; ver `DESARROLLO.md`. La sección de límites distingue la primera rebanada histórica de esta ampliación. Amplía la primera prueba con cinco capacidades conectadas. Es un modo experimental, con reglas y balance propios provisionales; no cambia la partida habitual ni establece canon.

## Abrir y observar

Abrir `Iniciar-Prueba-Autonomia.command`, crear un personaje o continuar la partida de prueba. Guarda en `user://prueba_autonomia.json`, separada de la partida normal. También funciona `Iniciar-Cenital.command --autonomia --guardado=user://prueba_autonomia.json`; en Windows, los mismos argumentos con `Iniciar-Cenital.bat`.

- **J** abre Sociedad del valle: necesidades, reservas, usos restantes de herramientas, grupos, acuerdos y diario. Flechas recorren acciones y desplazan el panel; «Volver a los habitantes» permite llegar al final del diario.
- **E**, cerca de alguien, explica su necesidad o compromiso actual.
- Ayudar desde J transfiere solo materiales que faltan, con proximidad. Rechazar queda recordado. No se crean premios ni XP.
- Los depósitos tienen un marcador y el nombre del grupo. Talleres está en la casa del taller; Cantera, en el pasillo de la cantera. Cerca de ellos, J permite aportar recursos y mejorar la relación con el grupo.
- Una hora de juego equivale a un minuto real. La actividad continúa con el panel abierto; Esc pausa el juego local. En servidor lo avanza su propio reloj.

Las tarjetas y nuevas misiones del director anterior quedan suspendidas. La prueba usa conversaciones y panel propios; conserva el progreso de capítulo, pero la campaña se juega en la partida habitual.

## Las cinco capacidades

**1. Producción conectada al consumo.** Las herramientas son objetos fabricados a partir de recetas existentes, no capacidades gratuitas del perfil. Los golpes efectivos gastan usos; al agotarse se consume una unidad. Antes de romperse pueden repararse con un lingote. Fabricar en una estación aumenta su desgaste; mantenerla también consume un lingote. Los habitantes detectan estaciones ausentes y reúnen materiales para construirlas. Una obra valida terreno, ocupación, materiales y rutas de habitantes, jugadores, entradas y depósitos antes de cobrar. No reciben herramientas, estaciones ni materiales de inicio.

**2. Cooperación entre habitantes.** Pueden acordar un trueque de excedentes, conservando sus reservas personales. Miembros del mismo grupo pueden ayudarse sin contrapago. Ambas partes reservan existencias como garantía: no pueden gastarlas de nuevo. El solicitante va hasta el proveedor; la entrega exige proximidad real y solo ocurre una vez. Si vence, ambas garantías vuelven una sola vez a sus propietarios. También abastecen y usan su depósito de grupo, con desplazamiento físico.

**3. Objetivos y alternativas.** Se derivan metas de alimento, herramientas, reparaciones, oficio y reservas colectivas. Para conseguir un objeto consideran depósito, proveedores, fabricación y recolección. Una receta puede abrir subnecesidades de insumos o estación. Si no pueden comprar, intentan reunir un bien de intercambio; si no hay solución posponen la meta durante un intervalo y prueban otra. La necesidad urgente de alimento tiene prioridad. Las causas y reintentos quedan registrados. No es un planificador capaz de inventar acciones nuevas.

**4. Memoria con consecuencias.** Cumplir un acuerdo mejora la confianza individual y las relaciones entre grupos. No concretarlo a tiempo las reduce; no se infiere una intención de engañar. La confianza insuficiente bloquea acuerdos futuros y altera qué proveedores se priorizan. La ayuda del jugador influye en a quién buscan; una negativa reciente impide que lo sigan persiguiendo. Los recuerdos incluyen actor, hecho, detalle y minuto. Una extracción del jugador en un recurso protegido solo genera reputación negativa si la observa un miembro cercano del grupo.

**5. Grupos con intereses.** Talleres y Cantera tienen miembros, reservas, territorio, recursos protegidos y reputación. Protegen recursos escasos y pueden restringir acceso a recursos y estaciones por mala relación. Prefieren proveedores del mismo grupo; la ayuda interna puede ser gratuita. El jugador puede contribuir con objetos reales para mejorar su relación. Son dos grupos económicos provisionales con conflicto no violento; no hay todavía guerras, conquista, elecciones ni generación de nuevas facciones.

## Reglas de la prueba

Datos en `datos/autonomia/reglas.json`; ejecución en `autonomia.gd` y `sociedad.gd`. Los números son provisionales, no balance heredado ni validado:

- Una decisión cada 5 minutos de juego; reintento tras 60 minutos si no hubo solución.
- 12 usos por herramienta; umbral de reparación 3; coste 1 lingote.
- Mantenimiento tras 4 fabricaciones en una estación; coste 1 lingote.
- Acuerdos con plazo de 360 minutos de juego, como máximo uno activo por habitante.
- Valores de trueque fijos en datos. No hay moneda acuñada ni precios dinámicos.
- Hasta 32 recuerdos por habitante, 80 sucesos de diario y 24 acuerdos cerrados. Los activos no se podan. Los contadores acumulados de actividad y vínculos permanecen.
- Los oficios conocidos y recetas son configuración: Maren fabrica herramientas; Ordal produce lingotes. Sueño y descanso tienen prioridad sobre trabajo y reuniones; un compromiso puede vencer por dificultades reales.

## Persistencia, autoridad y compatibilidad

Todo vive en `d.mundo_vivo.autonomia`: reservas, hambre, durabilidad, planes, metas pospuestas, recuerdos, vínculos y sociedad. Esta última conserva grupos, reputación, acuerdos con garantías, desgaste de estaciones, diario y contadores. Al cargar no se ejecuta una entrega ni se vuelve a gastar un recurso por restaurar sus datos.

Las partidas de la primera prueba se amplían con campos nuevos conservando sus recursos y recuerdos. El modo `necesidades` se mantiene para la regresión de la primera versión; las pruebas nuevas usan `sociedad`. Una partida normal sigue sin autonomía hasta activarla. Con el servidor apagado no se simula el tiempo ausente.

Solo el servidor avanza el mundo. Los clientes reciben la sección fiable `mundo_vivo`; aportar y ayudar son intenciones validadas por tipo, destinatario, proximidad, carencias y existencias. La réplica no activa la simulación por un argumento local. Los grupos y recuerdos son estado público, no información privada.

## Límites

No hay eventos escritos para producir una historia concreta, ni un LLM inventando misiones. Sí hay acciones, recetas, prioridades y restricciones implementadas: de ellas salen las situaciones. Los habitantes conocen las fuentes del mapa y las ofertas potenciales de otros habitantes; no se simula descubrimiento o negociación hablada. Las sanciones por extracción sí requieren un testigo cercano.

Hambre no mata y los NPC no combaten. La ampliación de `DESARROLLO.md` añade pericia y técnicas aprendidas mediante acciones reales. Los depósitos son ubicaciones marcadas con reservas lógicas, no cofres retirables. Los inventarios no tienen capacidad ni deterioro de alimentos; pueden acumular subproductos. La primera rebanada no incluía generador de espadas o armaduras; la ampliación de `DESARROLLO.md` añade combinaciones y aprendizaje acotados, sin generar mecánicas o árboles arbitrarios. Las estaciones se amplían construyendo piezas conocidas; todavía no se diseñan edificios completos ni barrios. Estas son capacidades posteriores, no algo que este prototipo ya prometa.

## Verificación

Desde la raíz, usar el ejecutable local de Godot con `--headless --path Linde/cenital --script` y uno de estos scripts:

- `res://tests/prueba_sociedad.gd`: producción, desgaste, acuerdos físicos, garantías, repetición, confianza, grupos, testigos, aportes, alternativas, migración, guardado, réplica y simulación de tres días sin intervención.
- `res://tests/prueba_autonomia.gd`: regresión de la primera prueba, con el modo de necesidades aislado.
- `res://tests/prueba.gd`, `prueba_ui.gd`, `prueba_red.gd`: regresión general, interfaz y red local.

Las pruebas nuevas guardan sus partidas en `/tmp/`. `tests/captura_sociedad.gd` se ejecuta con render (sin `--headless`), simula tres días sin intervención y conserva capturas de habitantes, grupos, diario, diálogo y depósito en `production/qa/evidence/sociedad/`. La prueba visual no equivale a un playtest de diversión ni a una sesión multijugador real en Internet.

## Crecimiento y exterior (25/10)

Las obras conservan solares y accesos, reintentan piezas bloqueadas y reconocen recetas aprendidas. Los puestos regionales son una simulación resumida separada de las rutinas completas del valle. Detalles, costes y límites en [CRECIMIENTO_Y_ASENTAMIENTOS.md](CRECIMIENTO_Y_ASENTAMIENTOS.md).

## Fase 6 — primer bloque causal (26/10/2026)

Implementación autorizada por el usuario sobre el [diseño maestro de Arena](../../../docs/investigacion/Diseno_Maestro_Fase6_Linde.md). Sus recomendaciones no sustituyen decisiones aprobadas. Contraste acotado: `Autonomia.necesidad` y `Sociedad.objetivos/_obtener` ya generan carencias y cadenas de insumos; `_recurso/_estacion/_ir` comprueban acceso; `comprometer/reserva` y acuerdos ya protegen materiales privados/garantías. `Guardado` y la bienvenida/eventos fiables ya transportan `mundo_vivo`. Se amplían estos contratos, sin otro planificador, inventario, sistema de pueblos o umbral económico.

`tareas.gd` conserva `mundo_vivo.autonomia.trabajo` versión 1: secuencia monotónica, una demanda/tarea activa por actor y resultados acotados por el tope existente de recuerdos. Una demanda equivalente (actor, ítem, motivo) conserva ID; su cantidad se actualiza desde la necesidad real. Las subrecetas siguen dentro de esa tarea, sin multiplicar órdenes. Estados: reclamada o bloqueada; completar/cancelar deja resultado y retira la tarea activa.

- El aprovisionamiento de Sociedad y el modo básico de necesidades reutilizan sus ejecutores. Se registra el delta real de mochila por intento, incluida producción intermedia, y el recurso reclamado. No se vuelve a aplicar un resultado guardado.
- Un recurso reclamado por una tarea de aprovisionamiento queda fuera de la búsqueda de otros actores hasta liberar el reclamo. Se revalidan accesibilidad y existencias con el código existente en cada decisión. Descanso, otra ocupación, cambio de necesidad, bloqueo y efecto material liberan el reclamo.
- Las reservas de insumos personales conservan `comprometido/compromiso_hasta`; las garantías de acuerdos siguen bajo Sociedad. No se inventa reserva de un stock comunitario abstracto ni se cancelan garantías por interrumpir una tarea. No hay una nueva reserva material que devolver.
- Bloqueos conservan causa `sin_opcion_factible`; el ejecutor actual registra detalles en recuerdos/sucesos y decide el reintento con `bloqueos/reintento_min`. La tarea no introduce otro temporizador. El historial suprime repeticiones consecutivas del mismo bloqueo.
- Solo autoridad ejecuta/cancela. Guardados anteriores obtienen el contenedor al primer uso, sin cambiar formato ni balance. La réplica lo recibe por las vías existentes; no hay nuevos pedidos de cliente.

**Alcance:** aprovisionamiento individual detallado, incluida su cadena de receta; no todo movimiento económico. El delta de mochila puede incluir trueque/retirada, por lo que no equivale a producción neta mundial. Construcción, enseñanza, consumo automático y acuerdos conservan sus registros propios. Las demandas colectivas aún no deducen trabajo de todos los actores; los pueblos resumidos no usan este contrato todavía. No se declara cerrado el diseño completo de Fase 6 ni la etapa económica colectiva. La prioridad/continuidad sigue siendo la del selector existente.

**Verificación puntual (26/10):** `prueba_tareas.gd` 16 comprobaciones (fabricación real, reclamo exclusivo/liberación, bloqueo real, descanso, persistencia y bienvenida de réplica, autoridad); regresiones `prueba_autonomia.gd` 33 y `prueba_sociedad.gd` 48. No son pruebas con clientes conectados por sockets ni de Internet. Permanecen avisos del motor sobre certificados y recursos al cerrar.

**Siguiente bloque:** agregar demanda colectiva y descontar stock accesible, compromisos y trabajo en curso, reutilizando depósitos/grupos y `Asentamientos`; después integrar la economía resumida con balances conservativos. Sin comercio nuevo, migración ni fundación todavía.

## Fase 6 — consolidación colectiva (26/10/2026)

Segundo bloque autorizado por el usuario. Amplía el bloque individual anterior, sin sustituirlo. `Sociedad.balance_grupo()` consolida las metas personales existentes con las reservas de cada grupo del poblado inicial. No mezcla la propiedad de Talleres y Cantera. Un grupo sin miembros no genera pedidos. Se conserva el orden del selector y los valores de recetas, reservas, capacidad, costes y cadencias.

Por ítem, el saldo pendiente es:

`max(0, reserva del depósito + carencias personales − stock utilizable − excedentes aportables − garantías personales − garantías colectivas aportables − atención individual en curso − encargos colectivos en curso)`.

- Las carencias personales ya descuentan su inventario. Metas del mismo actor/ítem usan el máximo objetivo actual, no la suma de pedidos equivalentes; actores distintos sí se suman. No es una proyección de consumo futuro ni un plan completo de todas las recetas.
- `aportable()` reutiliza la reserva personal/de oficio de la entrega existente y protege además los compromisos vigentes, incluso para el producto de oficio. No cuenta cofres privados ni bienes de jugadores como bienes comunitarios. Comprueba acceso al depósito; uno inaccesible conserva su reserva física pero no cubre personas a distancia.
- Las garantías activas de trueque ya están fuera de las mochilas. Se descuentan como entradas con destinatario, una vez, después de validar plazo y ruta. Los acuerdos de una tarea colectiva conservan `grupo_destino`; solo su parte aportable tras reservas del receptor cubre al grupo. Al entregarse pasan a stock real y no adquieren una reserva personal adicional por el mero hecho de ser una entrega colectiva. Los acuerdos personales conservan su contrato anterior. La oferta a un encargo colectivo respeta el excedente realmente aportable del proveedor.
- El retiro del depósito no cuenta también como producción futura. Los insumos negociados para una receta permanecen vinculados a la tarea original, sin etiquetarse como producto colectivo. Espera y recepción conservan ese encargo. Un resultado parcial reduce la cantidad pendiente; los insumos reunidos respaldan continuidad solo mientras existan.
- La cobertura de una tarea es **trabajo asignado, no stock creado ni resultado garantizado**. Se comprueban su estado, recurso, herramienta/permisos, estación, insumos o acuerdo y ruta del paso aplicable. Bloqueo, cancelación o pérdida de precondiciones reabren la carencia. El siguiente intento sigue siendo del selector existente, sin otro temporizador.
- `objetivos()` ofrece al siguiente actor solo el saldo no cubierto. Excluye la tarea propia al consultar para permitir que su dueño continúe. `_depositar()` transporta excedentes reales también para carencias personales agregadas; nunca entrega una previsión.

`Asentamientos.demandas_colectivas()` ofrece la vista por poblado, manteniendo los grupos como dueños en el detallado. `actualizar_demandas()` guarda una instantánea versión 1 en `autonomia.asentamientos.demandas` al terminar cada minuto autoritativo, después de las decisiones. Identidades deterministas por dueño/ítem; no hay una segunda cola. La selección consulta saldos actuales; la instantánea refleja su minuto registrado y viaja con guardado y réplica existentes. Los campos añadidos a tareas son aditivos; una tarea antigua sin precondiciones se revalida en su siguiente ejecución antes de cubrir demanda.

**Conexión resumida preparada:** `balance_resumido()` adapta el cofre de cada puesto/comunidad existente. Informa deuda alimentaria más consumo ya vencido y herramientas exigidas por residentes sin usos. Descuenta el stock físico, sin inventar reservas, tareas futuras, tasas ni cosechas prometidas. El ejecutor regional continúa intacto; aún no usa el saldo para asignar producción. No se integra 5b ni se inicia comercio entre pueblos, viabilidad, migración o fundación.

**Pruebas puntuales (26/10):** `prueba_demandas_colectivas` 50/50 y `prueba_tareas` 16/16; evidencia en `production/qa/evidence/mundo-1/fase-6-colectivas/`. Incluyen conservación en entregas, compromisos, garantías/recepción, entradas de insumos, exclusión de pedidos cubiertos, invalidación de recursos/estación/ruta, efecto parcial, adaptador regional, paso real, guardado/carga/recalcular y réplica por bienvenida. Pruebas de réplica en proceso, sin sockets/Internet ni batería histórica. Persisten avisos conocidos de certificados/recursos al cerrar.

**Siguiente bloque:** conectar estos saldos con las operaciones regionales existentes y registrar sus costes/resultados con el mismo contrato, comprobando balances detallado/resumido; sin activar transición 5b ni comercio entre pueblos.
