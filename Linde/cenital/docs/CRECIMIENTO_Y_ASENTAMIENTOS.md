# Crecimiento y primeros asentamientos — 25/10/2026

## Partidas y casas

`Juego.nueva()` elige generación v2 (estaño). `Mundo.configurar()` conserva v1 para las partidas anteriores: `terreno_v1.gd` queda congelado y `terreno_v2.gd` contiene el cambio. Se reconocen también los identificadores de estaño ya extraído o dañado por la versión intermedia. No se regenera un recurso extraído al cargar. `Guardado` rechaza versiones futuras desconocidas.

`Sociedad.habitat` reserva un rectángulo de 6×7 antes de preparar una cama. Comprueba límites, caminos, otras reservas, construcciones, piezas previstas y ruta al acceso sur. Impide ocupar el acceso con talleres o campos; admite contribuciones del jugador en las posiciones del plano. Una búsqueda examina como máximo 64 candidatos por llamada y continúa en llamadas posteriores. El cursor es temporal; el solar y la obra sí se guardan.

`Sociedad._casa()` comprueba piezas reales, borra marcas antiguas de finalización incorrecta y conserva las obras bloqueadas para reintentarlas. Las camas antiguas conservan su ubicación: no se mueven edificios ni se borran obstáculos del jugador. Su remodelación puede requerir intervención. Construir una cama enseña ladrillo al constructor; terminar la casa sigue consumiendo materiales. Se consultan recetas aprendidas además de las del oficio inicial. Se priorizan las obras sobre nuevos talleres, y cosechar sobre trabajar cuando hay hambre. Los campos objetivo crecen con el grupo.

## Arte

`arte/mundo/poblados/` incluye fuente generada, prompt, manifiesto con huellas y seis sprites: ladrillo, puerta abierta/cerrada, teja y cultivo creciendo/maduro. `MundoArte` los usa en las construcciones reales. `Escena._dibujar_techos()` agrupa cubiertas; al entrar se vuelven transparentes. La copa del frutal se recorta desde su imagen completa y conserva el tronco. El orden del dibujo usa la posición del objeto en el mundo, sin alternar por proximidad a la cámara. Se integran además los cambios remotos de inventario, ayuda y etiquetas de nombres.

## Puestos regionales

En un mundo autónomo, `B` permite elegir **Puesto regional**. Se necesita un solar libre de 5×5 al menos a 32 celdas del valle y de otros puestos. Máximo tres puestos. Coste: 20 madera, 8 piedra, 12 fibra, 8 bayas, un hacha de piedra y un pico de piedra.

`Asentamientos.crear()` materializa dos camas con techo, dos campos, cofre y marcador. El coste incluye cuatro bayas y las dos herramientas depositadas; no se entrega inventario gratuito. El marcador es permanente y no admite retirada: no se puede recuperar su coste conservando las piezas del conjunto. Las piezas individuales siguen siendo construcciones del mundo. Si faltan camas, techos, cofre o marcador, la producción se pausa.

Con cama y comida llega un residente cada 360 minutos de juego, hasta dos. Consumen una baya por residente cada 360 minutos; la deuda de comida no se borra si falta alimento. El recolector y el cantero trabajan cada 60 minutos: extraen árboles/rocas reales alcanzables y dejan sus identificadores en `rotos`. No reaparecen al cargar o explorar. Cada herramienta dura 50 extracciones; sin herramienta se detiene ese oficio. Se cosechan los campos reales cuando maduran. La suma de madera y piedra almacenada se limita a 60 para la producción.

La actualización usa terreno generado por coordenadas sin mantener regiones lejanas cargadas. El guardado conserva residentes, oficios, consumo, herramientas y momentos de producción. Solo el servidor produce; cargar no duplica una actualización. El tiempo cerrado no se convierte en producción: se usa el reloj del juego, no tiempo de pared. `J` muestra estado, coordenadas y existencias.

**Alcance:** estos residentes son población regional resumida con representación visual al acercarse. No tienen todas las rutinas, acuerdos, necesidades y navegación de los habitantes del valle. Las ciudades que se fundan solas, comercio entre pueblos y migración libre de toda la población continúan pendientes.

## Red y validación

Protocolo 5: servidor y clientes deben actualizar juntos. Las instantáneas mayores de 1200 bytes viajan por un RPC fiable; una secuencia compartida impide que otro canal haga retroceder el estado. Las diferencias fiables incluyen cultivos, cubiertas y puestos.

Pruebas reproducibles: `prueba_crecimiento.gd` (migración, reservas, obra bloqueada/reanudada, costes, producción distante, guardado y réplica), `prueba_crecimiento_red.gd` (servidor y dos clientes reales, cultivo, techo, cosecha, cofre y permisos), `prueba_carga_crecimiento.gd` (12 habitantes y cuatro sesiones en el mismo proceso), `simular_crecimiento.gd` (cinco días sin entregar materiales; combate desactivado para aislar la economía), `captura_crecimiento.gd` (escena real con preparación controlada).

Las simulaciones de cinco días con semillas 123 y 456 no completaron casas: sí hubo inmigración y construcción parcial. Las pruebas de casa preparada verifican que el plano es realizable y que se reanuda una obra; no prueban una economía autónoma equilibrada. La carga conserva la caché acotada y un p95 bajo, pero presenta pausas máximas de varios segundos al planificar. Equilibrio de comida/materiales y reparto del trabajo de planificación siguen siendo próximos puntos de desarrollo, sin declararlos resueltos por las pruebas funcionales. Resultados completos y capturas en `production/qa/evidence/crecimiento/`.


## Mundo 1 — comunidades preexistentes (Fase 5a, 26/10)

En mundos **nuevos de modo poblado**, `preexistentes_v1.json` pide dos comunidades: La Hondonada y Los Sauces. La génesis elige, en prioridad fija, macrorregiones exteriores compatibles; dentro de cada una usa el mismo plan puro por semilla/coordenadas de `Lugares`. El plan incluye su huella antes de trazar senderos hasta el cruce de la malla principal. El resultado, las piezas, rutas y nombres quedan persistidos. La carga de partidas y las réplicas no ejecutan esta génesis: no se reinstalan camas, pobladores ni provisiones al volver. No se diseña una migración de mundos de fases anteriores.

Se reutiliza `Asentamientos.crear/actualizar/visibles`: dos camas techadas, dos campos, cofre y puesto, con la misma provisión inicial y las mismas tasas de producción, consumo y herramientas. Es población existente al crear el mundo; no paga un jugador ni constituye una fundación autónoma. Las comunidades adicionales no consumen el cupo existente de tres puestos construibles. Cada residente guarda un ID estable `regional:<poblado>:<índice>`, nombre, apariencia, oficio, hogar, historia y bloques conocidos. `mundo.poblados` referencia esos ID; no copia inventarios ni añade otro actor a `d.npcs`.

La producción usa recursos naturales reales, respeta los despejes persistidos de los lugares y los obstáculos del terreno modificado. Campos, comida, reservas, usos de herramientas y deuda se conservan al guardar. Sin comida, herramientas o piezas necesarias se detiene con las mismas reglas del puesto; no hay decadencia/abandono automático, reposición gratuita ni compensación por tiempo con el servidor cerrado. La entrada en otra comunidad usa el validador existente de aparición, cargando su entorno físico antes de comprobarlo.

**E** permite hablar, **L** intercambiar referencias cercanas y **V** consultar identidad/oficio/historia. **M** descubre la comunidad según el mapa personal; las fuentes conservan nombres de residentes regionales. **J** muestra reservas y habitantes de comunidades visitadas. Los residentes intercambian sus bloques con NPC que estén a distancia de rumor existente; las referencias pueden circular después a otro jugador mediante ese viajero. No se añade viaje comercial ni conocimiento global automático. La prueba de circulación prepara el encuentro; no demuestra viajes autónomos entre pueblos.

En red, bienvenida y cambios fiables conservan el mismo registro, `mundo_vivo`, cofres, construcciones y ahora `mundo.poblados`. Se mantiene protocolo 8; anfitrión y clientes deben usar esta revisión. No se modifica identificación, cuentas ni autenticación.

**Límite de 5a:** acercarse solo representa la población regional existente. Sus residentes no adquieren las rutinas completas, combate, acuerdos y navegación de los NPC detallados. La transición 5b (resumido↔detallado, transferencia atómica de recursos/memoria) sigue pendiente según el plan; Fase 6 no iniciada. La coexistencia económica de muchas comunidades, el equilibrio prolongado y la red por Internet tampoco se declaran verificados.

Pruebas: `prueba_preexistentes` (2 semillas durante desarrollo; 20 al cerrar batería, tres días resumidos, reinicio intermedio y recursos), `prueba_preexistentes_ui` (escena e información) y `prueba_preexistentes_red` (servidor y dos clientes ENet reales). Capturas con `captura_preexistentes.gd`. Evidencia: `production/qa/evidence/mundo-1/fase-5/`.
