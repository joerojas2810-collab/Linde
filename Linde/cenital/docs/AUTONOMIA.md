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

## Fase 6 — saldos y operaciones regionales (26/10/2026)

Tercer bloque autorizado: el [Diseño Maestro §7](../../../docs/investigacion/Diseno_Maestro_Fase6_Linde.md) exige reutilizar acciones, tasas y recursos y verificar `stock final = stock inicial + entradas − salidas`. El bloque colectivo ya publicaba obligaciones regionales, pero el ejecutor no las consumía. Ahora `Asentamientos.actualizar()` usa `balance_resumido()` para comida/deuda, asignación de herramientas y activación de extracción, conservando el orden, costes, tiempos, usos y límites anteriores. Sociedad y el aprovisionamiento individual no se rehacen; Autonomía mantiene la ejecución por minuto y publica los saldos al terminar.

- El saldo alimentario distingue deuda, consumo vencido y el requisito ya existente de **tener comida positiva para trabajar**. Este último aparece como una unidad disponible, no se consume como coste adicional. Pagar deuda y consumir vencimientos son operaciones separadas con los mismos cursores anteriores; si no alcanza el stock se conserva deuda, sin inventar comida ni gastar por segunda vez.
- El saldo de herramientas procede de residentes sin usos y del cofre real. Asignar una consume exactamente una herramienta del cofre y deja los mismos 50 usos anteriores; una extracción efectiva gasta un uso. Sin herramienta/recurso accesible no hay producto ni desgaste ficticio.
- El saldo `materiales` expresa el control previo `madera + piedra` frente a `cfg.tope_stock`. Es una vista con componentes, **no un ítem ni otro inventario**. Sin residentes no activa demanda productiva. No añade objetivos por oficio ni altera el rendimiento; se mantiene incluso el comportamiento previo de comprobar el umbral antes de extraer un lote completo.
- Se siguen cosechando solo campos maduros mediante `Juego.cosechar`, con su fecha de próxima cosecha. Extraer usa el mismo ID de objeto, ruta, regeneración y `mundo.rotos` que antes. No se prometen tasas ni cosechas futuras como stock. Los pasos regionales son síncronos: no se crean tareas pendientes artificiales ni reservas duplicadas (`en_curso/comprometido` siguen en cero en esta vista).

Cada puesto original incorpora `economia` versión 1: secuencia monotónica, resultados acotados por `sociedad.tope_sucesos` ya existente y último bloqueo. Cada resultado guarda ID, minuto, causa, demanda previa, delta **real del cofre** y detalle de campo/objeto/actor/usos según operación. No se reaplican esos deltas al cargar: son evidencia de efectos ya persistidos. El bloqueo guarda causa y demanda sin crear un resultado productivo ni una cola de reintentos. El historial es una ventana reciente, no una suma histórica completa ni un registro de aportes externos/génesis.

Guardado y réplica viajan por los datos existentes del puesto; el servidor es la única autoridad. No se cambian fórmulas ni datos de balance, contratos de trueque o generación. Sin fabricación regional nueva de herramientas, comercio entre pueblos, migración, fundación, viabilidad nueva ni 5b.

**Verificación puntual:** `prueba_economia_regional` **19/19** y `prueba_demandas_colectivas` **50/50**, sin fallos. Conservación de stock frente a todos los resultados de una ejecución, objetos reales/usos, repetición del mismo minuto, límite material, deuda y reinicio con continuación equivalente, falta de herramientas/fuentes, saldos y réplica en proceso. El escenario colectivo actualiza solo la expectativa del requisito alimentario de trabajo ahora visible. No se ejecutó batería histórica ni Internet; permanecen avisos conocidos de certificados/recursos al cerrar. [Evidencia](../../../production/qa/evidence/mundo-1/fase-6-regional/README.md).

**Siguiente bloque propuesto:** responder a carencias regionales persistentes (comida/herramientas) con alternativas locales factibles y costes/saberes existentes. Cerrar esa respuesta antes de comercio, viabilidad, migración o fundación; sin fijar umbrales nuevos sin aprobación.

## Fase 6 — respuestas, comercio y tránsito de identidades (26/10/2026)

El usuario amplió el alcance a toda Fase 6, conservando los bloques anteriores; después autorizó expresamente heredar velocidad de NPC, mochila y consumo para viajes, sin teletransportes ni pérdidas aleatorias. Fuente principal: [Diseño Maestro](../../../docs/investigacion/Diseno_Maestro_Fase6_Linde.md), §§7–12. **Fase 6 sigue abierta:** las políticas de crisis/fundación/recuperación de §11 no quedaron aprobadas por autorizar el transporte.

### Respuestas locales y viabilidad factual

- `resolver_local` atiende carencias con arbustos reales accesibles y recetas **explícitamente conocidas por el residente**; no concede recetas por oficio. Reutiliza entradas/salidas/estaciones del catálogo y registra actor/delta. Las recetas con habilidades/herramientas no representadas por el residente se excluyen; no se fingen esas capacidades. Las comunidades antiguas sin `recetas` no aprenden fabricación gratuitamente.
- La respuesta local usa una oportunidad del periodo productivo existente y excluye a su actor del primer paso extractivo del mismo periodo. Un NPC reservado para viajar tampoco trabaja en el origen. Si no actuó localmente, se considera trueque.
- Se retiró la llegada que creaba colonos por calendario. La génesis de comunidades preexistentes continúa; un puesto vacío no se repuebla ni adquiere actividad por esperar o por spawn. El lugar, nombre, cofre, construcciones y registro se preservan. `sin_residentes` es ausencia material, no una decisión política de abandono.
- La reparación regional de edificios propios comparte `Edificios.reparar` con el jugador: mismo precio, materiales y comprobación del resultado antes de cobrar. La ruta del jugador mantiene dueño, proximidad y revisión. En resumido se delega la comprobación espacial a la navegación/terreno regional existente y a la misma caja de pies, sin cargar regiones para crear recursos. Falta de cofre/materiales/alcance u ocupación ajena bloquean la operación.
- La viabilidad registra comida exigible, camas reales, residentes, infraestructura y amenazas observadas en el área registrada. Seguridad lejana es `no_observada`, nunca se declara segura por estar descargada. `presiones` conserva origen/duración de carencias reales de comida/camas y su cobertura pendiente. No fija un tiempo de crisis ni activa evacuaciones.

### Contrato de tránsito y comercio

`transitos.gd` pertenece al registro existente de Asentamientos (`transitos`, versión 1). No crea pueblos, inventarios comunitarios alternativos ni NPC. Operaciones por clave idempotente: `reservada → viajando/detenida → entregada`, o cancelación previa; una clave reutilizada con otros datos se rechaza.

1. **Reserva:** separa del cofre los bienes y provisiones reales; para trueque también separa la contraoferta del otro cofre. Marca identidades existentes y reserva plazas de destino para migración o de retorno para mensajeros. Antes de salir no clona residentes ni altera su identidad. Rechaza IDs duplicados, otra reserva del mismo actor, lotes inválidos y falta de capacidad/materiales/ruta.
2. **Ruta y tiempo:** busca determinísticamente celdas contiguas sobre terreno/construcciones reales usando los bloqueos de Asentamientos. La búsqueda está acotada al rectángulo de extremos ampliado por `radio_recursos` existente; fallar en ese ámbito no demuestra que todo el mundo sea inconexo. No genera lugares ni cruza agua/muros por autorización abstracta. Duración = distancia de celdas × tamaño de celda / velocidad de Habitantes × conversión temporal vigente. La ruta se guarda y revalida durante el avance.
3. **Salida:** tras validar carga y provisiones, mueve los mismos diccionarios de residentes del origen a la operación, actualizando el registro de población/camas. No produce ni consume además en el origen. Capacidad usa las pilas y mochila existentes; alimento usa el consumo regional vigente por viajero.
4. **Consumo:** cada residente conserva su cursor `comida_min` en el pueblo y durante el viaje. La llegada no le cobra periodos anteriores al ingreso. El residente que permanece conserva su propio vencimiento. Un recién llegado no aporta trabajo anterior a su llegada, y reparar infraestructura no habilita extracción retroactiva de periodos sin capacidad de trabajo. En tránsito se descuenta comida de provisiones, incluyendo esperas; falta de comida mantiene deuda y detiene, sin stock negativo ni raciones inventadas. Los costes ya consumidos no se revierten al cancelar.
5. **Intercambio:** dos lotes en especie con excedentes sobre reservas actuales; usa la valoración existente de Sociedad para buscar contraprestación. No añade precios, moneda o caravanas por timer. El mismo mensajero entrega en el otro cofre al llegar, carga la contraoferta y vuelve por la ruta inversa. Solo al volver se acredita esa carga al origen y regresa su identidad; la contraparte nunca recibe una población permanente por comerciar.
6. **Migración dirigida:** reserva y transporta residentes existentes a plazas reales. Si el destino pierde capacidad/infraestructura, esperan en tránsito. La llegada mantiene ID, datos, saberes, usos, hogar y cama; nunca sustituye habitantes por nuevos. Es el contrato material comprobado, **no un selector autónomo de evacuación ni una expedición fundadora**.
7. **Cancelación:** antes de salir devuelve ambas reservas una vez. Después de salir solo puede preparar regreso por el tramo recorrido, no refundir bienes/personas en el origen a distancia. Las provisiones gastadas siguen gastadas. Ruta rota/falta de comida/destino bloqueado permanecen como estados durables. No se introduce rescate o riesgo aleatorio.

El saldo regional descuenta bienes en tránsito y contraofertas comprometidas como cobertura futura; no los convierte en stock. Las provisiones se mantienen separadas. Los residentes con retorno previsto preservan su necesidad de herramientas y su plaza, sin consumir además en el origen. Se muestran en la representación regional donde su ruta está cargada. Guardado y réplica llevan las mismas operaciones; clientes no las ejecutan. No hay nuevos RPC de jugador para forzar movimientos.

### Límites que impiden declarar cerrada la fase

Pendientes de aprobación explícita, no equivalentes a decisiones técnicas menores:

| Sistema pendiente | Decisión solicitada al usuario | Estado del código |
|---|---|---|
| Crisis y migración autónoma | Duración sostenida y admisión: se propuso un ciclo de consumo tras agotar alternativas, camas/infraestructura y comida del siguiente ciclo; seguridad desconocida bloquea decisiones irreversibles | Medición de presión y traslado material listos; no evacúa por umbral inventado |
| Fundación y crecimiento de comunidades | Se propuso plantilla regional de dos plazas/oficios actuales, todos los costes/provisiones reales, origen que conserve capacidad y ventaja de acceso comprobada tras descartar alternativas | No funda, no llama al creador de génesis como si fuera construcción pagada; no crea edificios/población/provisiones gratis |
| Abandono y recuperación | Se propuso vacío sin viajeros de retorno; conservar todo el registro; recuperar solo por mismo dueño con reparación pagada y sin ocupantes ajenos | Vacío factual y reparación propia listos; no declara abandono irreversible ni reclama propiedad ajena |
| Saberes regionales | Falta contrato aprobado que justifique qué recetas conocen los residentes resumidos iniciales y cómo adquieren las que no tienen | Solo fabrica conocimiento explícito; no copia arbitrariamente saberes de otro NPC |

La transición 5b, política de reclamación por terceros y reglas nuevas de riesgo/seguridad no se introducen. Los IDs de operaciones terminadas se conservan como comprobantes de idempotencia; poda/compactación a escala queda pendiente de medición. El comercio protege obligaciones actuales; no se fija un horizonte nuevo de reservas estratégicas.

### Verificación de esta entrega

Commits funcionales `d0c2ed7` (respuestas/transporte), `6cf093a` (reparación/presión), `53c5400` (destino abandonado no se reactiva) y `cfa4c24` (conservación temporal). Pruebas puntuales: tránsito **21/21**, respuestas/migración/comercio **17/17**, reparación/presión **12/12**, integración regional afectada **19/19**: **69 comprobaciones, 0 fallos**. No es la batería histórica. Escenarios de migración liberan una plaza explícita en el fixture; eso no implementa muertes o crecimiento de población en el juego. Los recursos/recetas de fixtures son entradas declaradas, no dotaciones del ejecutor. Réplica comprobada en proceso, sin Internet ni sockets reales en esta entrega. Persisten avisos de certificados/recursos al cerrar. [Evidencia](../../../production/qa/evidence/mundo-1/fase-6-autonomia-viajes/README.md).


## Fase 6 — políticas aprobadas de crisis y ciclo físico (26/10/2026)

Actualización posterior a los límites de la entrega anterior: el usuario aprobó persistencia de déficit alimentario durante un ciclo regional, alternativas locales y comercio previos, y migración únicamente con mejora material. `63fff6f` conecta esos predicados al ciclo de demandas existente, sin otro planificador ni cambio de tasas. La cobertura física resuelve presión; entregas pendientes impiden evacuar anticipadamente. Destino necesita infraestructura, plaza física dentro de la capacidad vigente y stock que cubra obligaciones actuales más el siguiente ciclo de residentes/entrantes. La duración por sí sola no inicia una operación. Reservas, salida, consumo y llegada siguen usando Tránsitos. La deuda alimentaria vencida no se perdona para hacer viable una salida: si falta pagar el consumo o transportar provisiones, la operación permanece inviable.

Las rutas se contrastan individualmente con enemigos existentes y su visión/conducta vigentes: huidizos y defensivos no alertados no se convierten en hostiles por cercanía. No observar seguridad regional no equivale a confirmar peligro. No se agregan encuentros o riesgos aleatorios. La búsqueda de caminos conserva el ámbito acotado descrito anteriormente.

Abandono físico: ausencia de residentes y de viajeros que tengan ese destino o retorno previsto. Conserva ID, propietarios, edificios, cultivos e inventarios. No activa deterioro nuevo. La recuperación usa un tipo explícito de la misma operación de tránsito: registra la titularidad original del residente al partir, rechaza terceros y sitios ocupados, y solo tras la llegada paga reparaciones reales desde la carga. Las reparaciones quedan registradas en la operación con edificio, minuto y coste; el cofre recibe únicamente carga remanente y provisiones no consumidas. Se revalida infraestructura y comida antes de recuperar. No se implementan reclamaciones o transferencias de derechos.

El selector intenta recepción en pueblos activos antes de recuperar un sitio propio. Una recuperación materialmente imposible queda bloqueada; no reemplaza edificios, habitantes ni materiales con respaldos artificiales. Persistencia y autoridad son las de Asentamientos/Tránsitos.

### Dependencias consultadas para el cierre restante

1. **Crecimiento/fundación:** contrato mínimo aprobado (dos residentes reales, oficios, casa funcional de dos camas, campos/estaciones, materiales y provisiones pagados, origen viable y ventaja territorial; solo después de alternativas locales/comercio/migración). Hay una dependencia concreta: la capacidad regional actual está fijada en dos y las comunidades preexistentes tienen dos residentes. Despachar dos fundadores vaciaría el origen. Se consultó sustituir ese tope por capacidad física de viviendas/camas pagadas y poblar exclusivamente mediante migración de NPC existentes. **Pendiente de respuesta; no cambiado el tope ni activada fundación que viole el contrato.** Fundación por oportunidad sin crisis permanece únicamente prevista.
2. **Recetas regionales:** se propuso preservar conocimiento explícito y adquirir otras mediante maestro real conocedor, con requisitos y tiempos de enseñanza existentes. **Pendiente de aprobación.** Las recetas de fabricación simple y los saberes de Desarrollo son representaciones diferentes; no se concede conocimiento por oficio, cofre, contacto automático o paso del tiempo. Tras aprobar la política se necesita adaptar enseñanza al residente regional conservando procedencia, tiempo y presupuesto de trabajo, sin convertir el cofre en una mochila duplicada.

Verificación puntual y límites: [evidencia del ciclo](../../../production/qa/evidence/mundo-1/fase-6-ciclo/README.md). Fase 6 sigue abierta por estas dos decisiones; tampoco se implementa transición 5b o propiedad de terceros.


## Fase 6 — cierre funcional del alcance aprobado (26/10/2026)

El usuario aprobó las dos dependencias del apartado anterior: adquisición de recetas por enseñanza real y capacidad física con viviendas pagadas/migración de identidades existentes. Quedan superadas las referencias históricas a esas decisiones como pendientes. Implementación en `e15bfda` y `ab86408`, conservando aprovisionamiento individual, consolidación colectiva, economía regional, trueque/tránsito y recuperación anteriores.

### Aprendizaje regional

Desarrollo adapta su registro de lecciones y sus parámetros vigentes de enseñanza: confianza bilateral, disponibilidad, radio, minutos, avance máximo, espera máxima y enfriamiento. Maestro real con receta explícita, alumno sin ella y ambos disponibles; enseñanza ocupa su presupuesto de trabajo. Un maestro detallado solo participa si está realmente cerca, despierto, sin necesidad alimentaria prioritaria y sin otro plan/acción reciente. No se concede conocimiento por stock del cofre, oficio o rumor. Las recetas y su procedencia (maestro, minuto, fuente) quedan en el residente; la misma identidad las conserva durante la migración. Relaciones regionales residen en ese mismo NPC, sin crearle otra mochila en Autonomía. Los requisitos de habilidades/estación/herramientas de fabricación siguen vigentes; aprender una receta no los elimina.

### Crecimiento material y sustento

La capacidad se deriva de camas propias funcionales, cubiertas y accesibles; admite camas de viviendas del catálogo y camas de huéspedes. `cfg.capacidad` conserva únicamente su uso de génesis inicial: no limita el alojamiento posterior. Perder una cama reduce capacidad real y puede bloquear una llegada.

Una presión real de otra comunidad puede justificar vivienda para recibir a sus residentes; solo una obra pendiente atiende la misma demanda. El plano se elige determinísticamente dentro del alcance regional actual, con solar y accesibilidad validados por Edificios. Sus costes exactos alimentan los saldos colectivos, protegen exportaciones y orientan extracción/comercio: no se aumenta arbitrariamente el tope de stock. Un residente disponible construye, paga el cofre y registra causa/coste; el nuevo cofre queda vacío. Ni construir ni dejar camas libres generan personas. Las incorporaciones usan exclusivamente migración real.

Comida reservada: obligaciones vencidas más el siguiente ciclo vigente de los residentes, conservando el requisito previo de comida para trabajar. Esto deriva cantidades de la población real y del consumo aprobado; no cambia tasas, rendimientos o duración del ciclo. La capacidad alimentaria de campos propios accesibles se calcula con `CAMPO_COSECHA`/`CAMPO_CRECE_MIN` y el ciclo regional vigente. Es diagnóstico de sustento, nunca stock producido anticipadamente. Sin alimento silvestre disponible, una capacidad renovable insuficiente mantiene presión aunque una entrada puntual de comida cubra el presente. Los cultivos necesarios se intentan localmente antes de fundar, con suelo real, coste de campo actual, trabajador disponible y maduración normal. No se corta una salida única para plantar. La recolección alimentaria aplica las probabilidades y RNG ya existentes de Sociedad: no garantiza bayas ni agrega nuevas probabilidades.

Recepción: cama física más comida actual para obligaciones y próximo ciclo de los entrantes, infraestructura y alternativa alimentaria local; la salida protege alimento de quienes permanecen. El selector puede migrar una cohorte de NPC existentes, sin impedir una evacuación completa porque evalúe solo un actor por vez. La presión persistente por sí sola sigue sin ordenar la migración.

### Fundación por crisis y ventaja comprobable

`fundacion.gd` es un contrato de Asentamientos sobre su economía y Tránsitos, no otro planificador o registro de población. Solo se evalúa tras presión aprobada, alternativas locales/comerciales y recepción/recuperación sin solución. Busca solares conocidos por los miembros, separados conforme a la regla existente, con terreno, acceso, fuentes materiales y mejor acceso alimentario real que el origen. No acepta ventaja narrativa. Mantiene las funciones materiales/alimentarias de quienes quedan en origen; ambos fundadores son NPC existentes de los oficios requeridos.

El coste suma el plano existente de casa regional y dos campos, más herramientas necesarias y provisiones reales. Si faltan materiales, la demanda explícita se integra a los saldos; no los inventa. Carga y consumo usan mochila/velocidad/ciclo vigentes. Se reserva un solar en Tránsitos sin crear un lugar, cofre o poblado vacío en el mundo. Al llegar se revalidan terreno y fuentes, se paga la carga y se materializan casa, camas, estaciones y cultivos. Solo entonces se registra el poblado estable y se entregan los mismos residentes y la carga remanente. La reserva inicial incluye comida real para trabajar, además de comidas del viaje; el alimento posterior exige recolección y cultivos reales, sin acreditar la proyección. El nuevo sitio usa las mismas reglas de economía y ciclo que los preexistentes.

Un solar alterado o una ruta cortada detienen la operación con carga e identidades persistentes. Cancelar antes de salir libera la reserva; interrumpir después exige regreso físico y no devuelve consumo gastado. Un retorno libera el solar pendiente. Llegada repetida no repite pago, edificio ni población. El abandono conserva identidad/derechos/inventarios y la recuperación por originales continúa usando el mismo lugar y reparación pagada.

### Aceptación y pendientes reales

**Sistemas funcionales del alcance aprobado completados.** Balance material/causalidad, identidad, ocupación única, determinismo en reinicio, recursos/capacidad y bloqueo explícito contrastados con los seis invariantes del Diseño Maestro §9 en la [evidencia de cierre](../../../production/qa/evidence/mundo-1/fase-6-cierre/README.md): **104 comprobaciones puntuales, 0 fallos**, con el detalle temporal de integración allí indicado.

No quedan decisiones de diseño pendientes para estos bloques. Continúan explícitamente diferidos **5b detallado↔resumido**, **propiedad/ocupación por terceros** y **fundación por oportunidad sin crisis**. Validaciones reales aún no certificadas: dos clientes por sockets/Internet, escala, frecuencia natural de crecimiento/fundación y matriz general de orden de exploración. No se realizaron por la prioridad de comprobaciones puntuales; no se confunden con sistemas implementados ni con aprobación de balance.
