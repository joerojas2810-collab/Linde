# Sociedad del valle — prueba de autonomía

Actualizada el 24 de octubre de 2026. Amplía la primera prueba con cinco capacidades conectadas. Es un modo experimental, con reglas y balance propios provisionales; no cambia la partida habitual ni establece canon.

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

Hambre no mata; los NPC no combaten ni desarrollan nuevas habilidades. Los depósitos son ubicaciones marcadas con reservas lógicas, no cofres retirables. Los inventarios no tienen capacidad ni deterioro de alimentos; pueden acumular subproductos. No hay generador de espadas, armaduras, recetas o árboles de habilidades nuevos. Las estaciones se amplían construyendo piezas conocidas; todavía no se diseñan edificios completos ni barrios. Estas son capacidades posteriores, no algo que este prototipo ya prometa.

## Verificación

Desde la raíz, usar el ejecutable local de Godot con `--headless --path Linde/cenital --script` y uno de estos scripts:

- `res://tests/prueba_sociedad.gd`: producción, desgaste, acuerdos físicos, garantías, repetición, confianza, grupos, testigos, aportes, alternativas, migración, guardado, réplica y simulación de tres días sin intervención.
- `res://tests/prueba_autonomia.gd`: regresión de la primera prueba, con el modo de necesidades aislado.
- `res://tests/prueba.gd`, `prueba_ui.gd`, `prueba_red.gd`: regresión general, interfaz y red local.

Las pruebas nuevas guardan sus partidas en `/tmp/`. `tests/captura_sociedad.gd` se ejecuta con render (sin `--headless`), simula tres días sin intervención y conserva capturas de habitantes, grupos, diario, diálogo y depósito en `production/qa/evidence/sociedad/`. La prueba visual no equivale a un playtest de diversión ni a una sesión multijugador real en Internet.
