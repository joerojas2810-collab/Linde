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
