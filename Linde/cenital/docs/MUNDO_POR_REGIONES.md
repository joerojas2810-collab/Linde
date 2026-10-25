# Mundo por regiones · generaciones v1 y v2

## Uso

El valle inicial de 64 × 48 celdas se conserva. Ahora puedes salir de sus bordes: el exterior se genera con la semilla de tu partida. Sigue el camino hacia el sur para cruzar el antiguo límite; también puedes explorar en las otras direcciones. El indicador de la esquina superior derecha muestra bioma y coordenadas.

Funciona en partidas nuevas y anteriores, con autonomía o campaña. No hace falta crear otra partida para ampliar el mapa: al cargar se añade la configuración del generador sin reemplazar el valle, los recursos ya extraídos ni las construcciones.

Hay praderas, bosques, sierras, secanos y zonas de agua. Se reutilizan las imágenes y los materiales actuales: árboles, arbustos, rocas y vetas. Los caminos principales continúan entre regiones. Puedes recolectar, construir, guardar objetos en cofres con candado, fijar una cama y regresar después de alejarte o cerrar el juego.

## Qué se reutilizó

Base: [Infinite Generation Demo](https://github.com/mearnest-dev/infinite-generation-demo), revisión `63f7400d58f5bdc1bba5fdb33e01016389ff46e4`, licencia MIT. Código original y aviso en `terceros/infinite-generation-demo/`.

Se adaptaron la generación por coordenadas globales, el cálculo de regiones y los campos FastNoiseLite. La revisión del código mostró que la demo usaba semillas aleatorias, regiones grandes y no descargaba regiones. Linde usa semillas persistentes y regiones pequeñas, descarga su caché y conserva sus diferencias. Se mantuvieron el dibujo, las colisiones y las acciones de Linde; no se sustituyó el juego por la demo ni se copió código de Minecraft.

## Contrato persistente

- `d.mundo.generacion`: versión 1 para partidas anteriores, versión 2 para partidas nuevas (estaño), semilla y tamaño de región 16. v1 permanece congelada. Las diferencias guardadas de estaño de la versión intermedia se conservan.
- El valle sigue usando su geometría de autor y su semilla histórica. La semilla de partida determina el exterior.
- Cada región contiene 16 × 16 celdas. Se calcula con coordenadas globales: el orden de exploración no cambia el resultado ni crea cortes entre regiones.
- `rotos`, `golpes` y `constr` conservan extracciones, daño parcial y construcciones por coordenadas globales. Los cofres conservan contenido, dueño, permisos y candado.
- No se guardan copias de las regiones sin modificar. Se reconstruyen desde la semilla al volver.
- Se rechazan metadatos de un generador futuro incompatible. No se debe modificar silenciosamente `terreno_v1.gd`: hay una huella de terreno que lo comprueba; un cambio incompatible requiere otra versión conservando la anterior.

El terreno no es matemáticamente infinito: esta versión tiene un límite técnico de ±65.536 celdas por eje. No se genera esa superficie completa. El límite evita salir del rango de coordenadas elegido para esta primera implementación.

## Memoria, navegación y red

Se mantiene en memoria la unión de los entornos de los jugadores conectados: hasta 25 regiones exteriores por jugador. El valle permanece residente para sus habitantes. Al alejarse o desconectarse se descartan las regiones que nadie necesita; sus modificaciones persistentes permanecen.

La carga es síncrona y por regiones pequeñas. No se declara generación en segundo plano. Una medición local de carga de 25 regiones, incluida la creación del valle, dio unos 28 ms; no representa un límite garantizado ni una prueba de rendimiento en todas las máquinas.

Las rutinas completas se mantienen en el valle; las expediciones usan rutas regionales acotadas y caché limitada. La validación de construcciones usa recorridos acotados para no intentar recorrer un mundo sin límite: conserva las rutas esenciales del valle y comprueba conexiones locales en el exterior. Esta comprobación puede ser conservadora cuando un desvío queda fuera del área local.

El servidor sigue siendo la autoridad sobre movimientos y cambios. Los clientes reciben la semilla/configuración y las diferencias, y reconstruyen el terreno con el mismo generador. El protocolo pasa a versión 5 para evitar mezclar clientes anteriores con otra geometría. Los pedidos lejanos no provocan generación de regiones a voluntad del cliente.

## Alcance de esta entrega

Los habitantes pueden hacer expediciones. Los puestos fundados por el jugador incorporan hasta dos residentes regionales resumidos; ver [CRECIMIENTO_Y_ASENTAMIENTOS.md](CRECIMIENTO_Y_ASENTAMIENTOS.md). Las camas de huésped de afuera no se asignan a colonos que aún tienen rutinas del valle. Tampoco se les ordenan hurtos a cofres exteriores sin rutas regionales. Sí puedes usar tus propias camas y cofres fuera del valle.

Los enemigos, jefes, ruinas y lugares de la campaña conservan sus posiciones del valle. El exterior añade terreno, recursos, cinco especies de fauna por bioma y puestos regionales; no añade mazmorras. Los caminos son una red ortogonal provisional; no hay todavía un modelo de ríos, erosión, puentes o rutas comerciales. Las ciudades autónomas, el comercio entre pueblos y las rutinas completas para toda la población exterior siguen pendientes.

## Verificación

`tests/prueba_terreno.gd` comprueba determinismo, huella v1, bordes, biomas, movimiento al exterior y en negativo, colisión, extracción, daño parcial, regeneración descargada, construcción, cofres/candados, guardado/carga, cama/reaparición, límite de caché, varios jugadores, migración y servidor/réplica.

`tests/prueba_terreno_red.gd` usa un servidor y dos clientes reales en procesos separados. Ambos cruzan el borde del valle; uno construye y cierra un cofre, el otro no puede retirar objetos sin permiso, y después recibe acceso. Se comparan sus huellas del terreno y se verifica el guardado del servidor.

`tests/captura_terreno.gd` muestra la escena real en valle, salida y biomas; posiciona al jugador para QA. Las capturas no son un recorrido jugado. Evidencia en `production/qa/evidence/terreno/`.
