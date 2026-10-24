# Linde — documento de inicio para construcción

Visión y contratos de trabajo. No define una beta.

# Linde — punto de inicio del proyecto

Documento de trabajo · 23 de octubre de 2026 · revisión 1

Este paquete describe el juego que queremos empezar a construir. **No define una beta, un producto mínimo, una fecha de entrega ni un alcance cerrado.** Organiza la visión completa en sistemas y dependencias para poder implementarla por etapas sin perder el rumbo.

Linde es un nombre de trabajo. El objetivo es un RPG 2D de mundo vivo, con personaje creado por el jugador, exploración, recolección, construcción, progresión y aventuras de capítulos y de mundo. La vista es cenital oblicua, con desplazamiento arriba, abajo, izquierda y derecha.

## Cómo leer el paquete

1. [Visión y decisiones](LINDE_Punto_de_Inicio/01_VISION_Y_DECISIONES.md).
2. [Sistemas del juego](LINDE_Punto_de_Inicio/02_SISTEMAS_DEL_JUEGO.md).
3. [Narrativa](LINDE_Punto_de_Inicio/03_NARRATIVA.md).
4. [Arte y animación](LINDE_Punto_de_Inicio/04_ARTE_Y_ANIMACION.md).
5. [Arquitectura y construcción](LINDE_Punto_de_Inicio/05_ARQUITECTURA_Y_CONSTRUCCION.md).
6. [Fuentes, licencias y supuestos](LINDE_Punto_de_Inicio/06_FUENTES_Y_SUPUESTOS.md).
7. [Instrucción para Claude](LINDE_Punto_de_Inicio/PROMPT_PARA_CLAUDE.md).

Las etiquetas **Acordado**, **Propuesta** y **Pendiente** distinguen la intención expresada por el usuario, las decisiones sugeridas para poder trabajar y los asuntos todavía abiertos. Una propuesta puede implementarse de forma reversible y registrarse como tal; no debe presentarse después como una decisión del usuario.

## Qué existe y qué queremos construir

Existe un prototipo lateral en Godot, incluido como archivo histórico de código. Su cámara, gravedad, salto y terreno por columnas no representan la dirección actual. No contiene todavía todos los sistemas descritos aquí. La referencia visual cenital es una imagen conceptual, no una captura de un juego implementado ni un conjunto de sprites listo para usar.

Los documentos antiguos incluidos en evidencia describen una investigación o implementación anterior. **Estos documentos nuevos tienen prioridad para la dirección del proyecto.** Los archivos antiguos mantienen su título original para no falsear su historia.

## Contenido transportable

- `referencias/visual_objetivo.png`: referencia conceptual de estilo.
- `referencias/prototipo_lateral_actual.png`: estado anterior, para distinguirlo del objetivo.
- `codigo_base/prototipo_lateral_fuentes.zip`: código existente y sus avisos.
- `evidencia/`: inventario y verificaciones previas; sus conclusiones tienen el alcance indicado en cada archivo.

La biblioteca completa de repositorios permanece en el equipo original, en `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/fuentes`. No está duplicada en este paquete. Un constructor en otro equipo puede obtener las revisiones indicadas en la matriz; la disponibilidad futura de los remotos no se garantiza.


---

# Visión y decisiones

## Experiencia que buscamos

**Acordado.** Crear un personaje propio y comenzar en una zona aleatoria del mundo. Explorar, romper objetos del entorno, conseguir materiales, construir, desarrollar un árbol de habilidades, descubrir tesoros y afrontar misiones y jefes de capítulos o del mundo. Las acciones deben poder cambiar el lugar donde se juega.

El mundo vivo debe expresarse en comportamientos y consecuencias observables: habitantes que se desplazan y realizan actividades, recursos que cambian, encuentros que tienen condiciones y un estado que se conserva. No basta con llamar «vivo» a un mapa con NPC inmóviles.

## Perspectiva y navegación

**Acordado.** Vista superior oblicua comparable en legibilidad a los escenarios de Pokémon HeartGold: se ven tejados y fachadas, y el jugador puede rodear objetos y elegir rutas. Movimiento en dos ejes: arriba, abajo, izquierda y derecha. No es un juego de plataformas lateral.

**Propuesta.** Empezar con cuatro direcciones sin diagonales. Si se permiten diagonales después, normalizar su velocidad y resolver cómo se orientan las animaciones. El control puede ser continuo sobre un mapa de celdas; caminar por turnos o casillas no está exigido por la referencia.

## Identidad del personaje

**Acordado.** No hay un protagonista fijo: el jugador arma su PJ.

**Propuesta.** Nombre, tono de piel, pelo y vestimenta inicial, con apariencia compuesta por capas compatibles. Los orígenes personales pueden aportar contexto y diálogo. No adjudicarles ventajas numéricas hasta documentar sus reglas y consecuencias.

## Inspiraciones narrativas

**Acordado.** Overgeared, Shangri-La Frontier, la obra del slime mencionada por el usuario y SAO son referencias de experiencia.

| Referencia | Pilar que tomamos como orientación |
|---|---|
| Overgeared | Oficios, creación de equipo y progreso por especialización |
| Shangri-La Frontier | Exploración, descubrimientos y encuentros singulares |
| Slime | Evolución personal, vínculos y desarrollo de comunidad |
| SAO | Aventura, habilidades y enfrentamientos importantes |

No se transfieren personajes, nombres, mapas, imágenes ni argumentos de esas obras. Esta tabla es una interpretación de diseño de las referencias, no una investigación de sus reglas.

## Dirección narrativa sugerida

**Propuesta.** Un mundo de fantasía que existe por sí mismo, con progresión de RPG. El PJ se define por sus acciones y relaciones. No necesita ser un elegido ni estar atrapado dentro de un videojuego. La condición de mundo real, virtual o de reencarnación sigue abierta y no debe bloquear los sistemas comunes.

## Principio de reutilización

**Acordado.** Aprovechar código, reglas y definiciones de fuentes públicas verificadas, evitando inventar balance y atribuirlo a los donantes.

Reutilizar significa verificar licencia, comportamiento, unidades y dependencias. No significa unir motores y servidores completos. Una cifra copiada de otro juego no garantiza equilibrio en este proyecto. Toda regla nueva debe identificarse como provisional y mantenerse centralizada para poder revisarla.

## Decisiones que no están tomadas

Multijugador; plataformas finales; combate por turnos o en tiempo real; muerte y penalizaciones; escala del mundo; generación completa o mapas de autor; economía; clases fijas o progresión libre; canon del mundo y conflicto central. No presentar ninguna como aprobada.


---

# Sistemas del juego

Este documento describe capacidades del proyecto y sus contratos. No exige implementarlas todas simultáneamente ni fija cantidades finales de contenido.

## Bucle de experiencia

Explorar → encontrar necesidades, recursos o desafíos → elegir cómo actuar → reunir o fabricar medios → construir, relacionarse o combatir → obtener recompensas y habilidades → abrir nuevas posibilidades. Las actividades deben conectarse: el oficio puede facilitar una expedición, y sus hallazgos pueden cambiar una construcción o una relación.

## Mundo e inicio aleatorio

**Acordado:** el comienzo ocurre en una zona aleatoria. **Propuesta técnica:** seleccionar una región y un punto de aparición válidos mediante una semilla. Aleatorio no significa aparecer dentro de una pared, sin salida o junto a un enemigo inevitable.

Guardar semilla, versión del generador, región, posición inicial y cambios posteriores. Validar suelo transitable, espacio corporal, ruta de salida y acceso a las primeras interacciones. Usar flujos de azar separados para mapa, botín y encuentros: abrir un cofre no debe alterar el mapa futuro. La generación procedural completa es una decisión pendiente; zonas creadas a mano con puntos de inicio elegibles también satisfacen un inicio aleatorio.

## Objetos rompibles y recolección

Cada definición necesita ID estable, categoría, herramienta o condición requerida, resistencia si corresponde, resultados y política de regeneración. Cada instancia conserva su estado. Separar decoración de objeto interactuable.

Resolver una rotura una sola vez: retirar o transformar el objeto y entregar sus recursos en una transacción. Definir qué ocurre con inventario lleno; nunca perder ni duplicar recursos silenciosamente. La regeneración no debe restaurar un árbol dentro de una casa del jugador.

## Inventario, fabricación y equipo

Un catálogo compartido define objetos, pilas, etiquetas y usos. Las recetas referencian IDs existentes y explicitan entradas, herramientas, condiciones y salidas. No inferir pesos, precios o tiempos de fabricación a partir de nombres.

Fabricar comprueba requisitos y consume/entrega de forma atómica. Cancelación, guardado y repetición de comandos no duplican resultados. La relación entre calidad de oficio, equipo y combate requiere un modelo completo; evitar copiar coeficientes aislados.

## Construcción

Construir coloca una instancia con huella en el suelo, orientación, coste y reglas de ubicación. Mostrar previsualización válida o inválida antes de confirmar. Comprobar colisiones, ocupantes, agua, entradas y espacios protegidos. Separar suelo, paredes, cubiertas y mobiliario; un tejado no bloquea la navegación por estar dibujado encima.

Retirar, mover y reparar requieren políticas explícitas de devolución y propiedad. Prevenir bloqueos irreversibles de objetivos esenciales o proporcionar una recuperación. La adyacencia usada por el prototipo lateral no se hereda automáticamente a esta vista.

## Árbol de habilidades

**Acordado:** existe un árbol. **Propuesta:** habilidades y requisitos definidos como datos, con ramas de oficio, exploración, combate y comunidad según se construyan sus sistemas.

Cada nodo declara requisitos, coste, efecto y regla de desbloqueo. Validar referencias, ciclos no permitidos y caminos alcanzables. Guardar habilidades adquiridas; calcular efectos desde ellas, evitando acumular el mismo bonus cada vez que se carga. Puntos, experiencia, límites y posibilidad de redistribuir siguen pendientes. No inventar una tabla definitiva para completar el documento.

## Misiones de capítulos y de mundo

Las misiones de capítulo articulan una progresión narrativa. Las de mundo nacen de lugares, personajes o estados del entorno y pueden ser opcionales. No asumir que todas son repetibles ni que todas bloquean la campaña.

Modelo sugerido: disponible → activa → cumplida → recompensa entregada; fallida o cancelada solo cuando el diseño lo permita. Condiciones y recompensas se apoyan en eventos persistentes e IDs únicos. Distinguir «visité un lugar» de «tengo el objeto ahora» o «la construcción sigue en pie». No completar una condición actual con un evento histórico que ya dejó de ser cierto.

## Jefes, combate y recompensas

**Acordado:** jefes de capítulo y jefes de mundo. El primero sirve a un hito narrativo; el segundo pertenece al entorno y puede descubrirse fuera de ese hilo. No implica multijugador ni competición global.

**Pendiente:** modelo de combate. Resolverlo antes de diseñar animaciones y estadísticas definitivas. Cada jefe necesita estados legibles, señales previas, áreas de impacto, respuesta al daño, victoria/derrota y política de reaparición. Evitar jefes que solo tengan más vida.

Guardar identidad del encuentro, estado de derrota y entrega de recompensas. La recompensa de capítulo no se vuelve a dar al recargar. Si un jefe de mundo reaparece, documentar el reloj y las condiciones que lo permiten.

Los tesoros necesitan tabla de contenido o recompensa fija, condiciones de acceso e identidad persistente. Guardar el resultado aleatorio al generarlo, evitando que cargar repetidamente cambie el premio. Separar recompensa garantizada y probabilística y registrar la procedencia de cada valor.

## Habitantes y mundo vivo

Separar necesidades, objetivos, selección de actividad, navegación y ejecución. Una rutina debe considerar accesibilidad y ocupación: asignar «dormir» no equivale a llegar a una cama. Las decisiones pueden basarse en reglas sencillas antes de incorporar optimizadores.

**Propuesta inicial:** simulación local mientras el juego está abierto. El avance sin conexión y la simulación lejana son decisiones posteriores que requieren reglas de recuperación. No prometer habitantes simulados permanentemente fuera de la sesión.

## Persistencia y consistencia

Guardar personaje, apariencia, inventario, habilidades, posición, mundo modificado, construcciones, tiempo, NPC, misiones, cofres y jefes. Versionar el formato y definir migraciones. Escritura temporal, validación y copia de respaldo deben proteger frente a interrupciones.

La política de muerte, recuperación de objetos, reinicio de encuentros y abandono de misiones está pendiente; debe ser explícita antes de conectar combate y guardado.


---

# Narrativa: pilares y espacio de autoría

## Lo definido

Personaje personalizable, fantasía de progreso, oficios y equipo, exploración de secretos, relaciones y comunidad, habilidades y grandes enfrentamientos. La aventura debe convivir con la libertad de reunir recursos y construir.

No hay todavía un argumento principal aprobado, antagonista definitivo, cosmología ni final. Los mensajes originales recuperados de la conversación referenciada no aportaron una historia detallada verificable. Las referencias de anime fueron aportadas expresamente por el usuario después.

## Propuesta de premisa abierta

«Llegas a una región que todavía no conoces. Puedes abrirte camino por lo que descubres, lo que fabricas y las personas con las que decides colaborar. Los lugares guardan desafíos que pueden cambiar tu oficio, tu comunidad y tu posición en el mundo».

Es una premisa de trabajo, no canon cerrado. Funciona con distintos orígenes del PJ y puntos iniciales. La región debe ofrecer oportunidades además de peligros; el jugador no necesita recibir inmediatamente una misión de salvación mundial.

## Forma de desarrollar capítulos

Cada capítulo debería definir una pregunta dramática, personajes con objetivos propios, lugares, condiciones de entrada, varias actividades útiles, un conflicto y sus consecuencias. El jefe debe tener relación con ese conflicto, no aparecer únicamente para cerrar una barra de progreso.

Las acciones libres pueden ayudar al capítulo sin convertirse todas en tareas obligatorias. Un oficio aporta una solución o preparación; no debe exigir dominar todos los oficios para seguir la historia.

## Ejemplo de contenido, enteramente propuesto

Un taller local necesita investigar por qué los materiales de una cantera muestran propiedades extrañas. El PJ puede colaborar mediante exploración, suministro o fabricación. Los hallazgos abren un encuentro de capítulo en las ruinas próximas y dejan una mejora o conocimiento útil para el taller. Un gran ser del bosque puede existir como jefe de mundo independiente, con su propia condición de aparición.

Este ejemplo sirve para probar la conexión entre sistemas. Nombres, criaturas, conflicto, recompensas y resolución deben escribirse y revisarse antes de convertirse en contenido final. No establece que restaurar pueblos sea el argumento central.

## Personajes y diálogos

Guardar vínculos y hechos relevantes mediante estados concretos. Los diálogos consultan esos estados y no contradicen lo que ya ocurrió. Una respuesta debe indicar si cambia una relación, abre una misión o es solo expresiva. Los NPC no deben conocer automáticamente hechos que no pudieron observar, salvo que exista una regla de difusión.

Ada, el refugio y el cuaderno del prototipo anterior son contenido de prueba, no la campaña aprobada. Pueden conservarse como ejemplo técnico separado.

## Ficha para escribir contenido

ID estable; estado editorial; propósito; requisitos; personajes; lugares; eventos observados; pasos; condiciones actuales frente a hechos históricos; alternativas; consecuencias; recompensa; repetibilidad; recuperación ante bloqueo; referencias y autoría.

No se requiere generación narrativa con modelos de lenguaje. Si se plantea después, debe respetar los estados del mundo y no conceder objetos o resolver misiones al margen de la lógica del juego.


---

# Dirección visual, arte y animación

![Referencia conceptual objetivo](LINDE_Punto_de_Inicio/referencias/visual_objetivo.png)

## Dirección acordada

Pixel art sencillo y legible, vista superior oblicua, personajes pequeños y escenarios que permiten navegar en ambos ejes. Tejados, fachadas, caminos, vegetación y entradas deben entenderse rápidamente. Reducir textura ornamental y sombras complejas respecto de los primeros conceptos demasiado detallados.

La imagen es una referencia conceptual generada, no una captura implementada. Sus caminos ilustran la intención, pero el mapa jugable debe diseñarse y comprobarse por separado. No convertir toda la imagen en un fondo con colisiones improvisadas.

## Qué requiere arte y qué requiere código

| Arte | Código y datos |
|---|---|
| Tiles de suelo, bordes, agua y edificios | Composición del mapa, colisiones, navegación y cambios |
| Cuerpo, pelo, ropa y equipo del PJ | Personalización, capas, orientación y guardado |
| Animaciones de acciones y enemigos | Estados, tiempos, impactos y cancelaciones |
| Iconos, retratos, efectos y UI | Interacción, inventarios, diálogos y accesibilidad |

La generación de imágenes puede ayudar a explorar diseños. Un conjunto jugable requiere recorte, alineación, transparencia, coherencia entre cuadros y revisión manual. La imagen de referencia no sustituye ese trabajo.

## Especificación técnica propuesta, modificable

Probar una cuadrícula base de 16 × 16 píxeles y personajes de 16 × 24 o 16 × 32 antes de producir todo el catálogo. Elegir una sola escala tras comprobar proporciones, equipo y legibilidad. No mezclar estas propuestas con los 24 píxeles por celda del prototipo lateral.

Usar filtrado nearest y escalado entero cuando sea posible. Mantener anclaje en los pies. La colisión representa la parte que ocupa suelo y no toda la altura del dibujo. Ordenar por profundidad desde los pies; separar copas y tejados cuando el PJ pase detrás o debajo. Definir reglas de ocultación para interiores.

## Personaje y animaciones

Preparar y validar primero una muestra de cuerpo, pelo y ropa combinables en cuatro orientaciones. Alinear todos los cuadros y las capas con el mismo origen. Evitar que accesorios desaparezcan o cambien de lado accidentalmente.

Estados necesarios a medida que se implementan sus acciones: reposo, caminar, usar herramienta, atacar, recibir daño y caer o quedar incapacitado. Las cuatro direcciones deben ser coherentes. La cantidad de cuadros y la duración se deciden con una prueba en motor; no están verificadas ni fijadas por un donante. No producir un catálogo de combate antes de decidir su modelo.

## Mapa y objetos

Suelo con variaciones limitadas; transiciones entre materiales; agua y orillas; vegetación; objetos recolectables con estados; piezas de construcción; entradas legibles; cofres cerrados/abiertos; indicadores de interacción. Los objetos que se rompen o construyen requieren variantes de estado, no solo una ilustración estática.

Definir paleta, escala, luz y contorno en una hoja de estilo. Identificar zonas transitables sin depender exclusivamente del color. Las señales de ataques necesitan suficiente contraste sobre el escenario.

## Registro de recursos

Cada recurso lleva ID, autor, origen, licencia, modificaciones, escala, tamaño, pivote, estados y ubicación. Distinguir provisional y final. No reutilizar sprites, edificios o mapas de Pokémon ni recursos propietarios de Helbreath. Conservar atribuciones y condiciones por archivo para cualquier recurso externo.


---

# Arquitectura y guía de construcción

## Estado real del código

El archivo incluido contiene un prototipo **lateral** en Godot. Implementa movimiento y salto, edición de bloques, necesidades, una rutina simple de Ada, una pequeña misión y guardado local. La entrega anterior registró 31 comprobaciones automatizadas aprobadas. Es evidencia histórica de ese código, no validación del juego cenital ni de una migración futura.

No están implementados en esa base el creador de PJ, el combate RPG, el árbol de habilidades, los jefes, la campaña ni la navegación cenital. No confundir tener repositorios descargados con tener sus módulos integrados.

## Base técnica propuesta

Continuar con Godot y GDScript para aprovechar el trabajo local. La instalación usada en el equipo original es Godot 4.7.1; verificar compatibilidad en el entorno de construcción. Empezar como aplicación local para un jugador, una propuesta técnica reversible mientras se decide si habrá red.

Conservar el prototipo anterior y crear un proyecto o carpeta independiente, por ejemplo `Linde/cenital`. No reemplazar el lanzador existente hasta disponer de una ejecución comprobada. Si el constructor tiene solo el paquete, extraer el archivo de código en una carpeta de referencia y crear el nuevo proyecto a su lado.

## Responsabilidades

| Módulo propuesto | Responsabilidad |
|---|---|
| Catálogos | Definiciones de objetos, recetas, habilidades, misiones y encuentros |
| Estado de mundo | IDs, regiones, objetos, construcciones y cambios persistentes |
| Generación | Semilla, versión y validación de puntos iniciales |
| Actor | Entrada, desplazamiento, colisiones y acciones |
| Apariencia | Capas del PJ y animación, sin decidir recompensas |
| Inventario y fabricación | Transacciones y requisitos |
| Construcción | Validación de huella y modificación del mundo |
| Progresión | Desbloqueos y aplicación derivada de efectos |
| Misiones | Condiciones, estados y entregas únicas |
| Encuentros y combate | Estados de enemigos, daño y resolución |
| Habitantes | Objetivos, actividades, navegación y horarios |
| Persistencia | Validación, versiones, migración y respaldo |
| Presentación | Cámara, UI, sonido y efectos |

Son límites de responsabilidad, no una obligación de crear un archivo por fila. Mantener una autoridad única sobre inventario y mundo. La UI solicita acciones y muestra resultados; no concede recursos por su cuenta.

## Modelo espacial

Separar coordenadas de celda y posición en píxeles con conversiones explícitas. Separar suelo, colisión, objetos interactuables y elementos dibujados por encima. Para navegación, utilizar una representación actualizable de celdas transitables o una alternativa equivalente verificada en Godot.

La construcción y destrucción actualizan navegación y colisión coherentemente. Las entradas a interiores o cuevas necesitan destinos válidos y retorno seguro. No trasladar gravedad, impulso de salto ni generación por columnas del lateral.

## Contratos de datos

Todas las entidades persistentes tienen IDs estables; los catálogos usan referencias verificables. Cada partida declara versión de formato y de contenido. Separar definición de un árbol de sus instancias y de sus cambios. Conservar resultados de botín, recompensas otorgadas y desbloqueos para evitar duplicaciones.

Centralizar parámetros con unidad, procedencia y estado: heredado sin cambios, adaptado, provisional o validado localmente. Un cambio de escala temporal obliga a revisar consumo de necesidades, regeneración y horarios de manera conjunta.

## Orden de construcción por dependencias

1. Inspeccionar código y fuentes disponibles; registrar qué se reutiliza y bajo qué condiciones.
2. Probar escala visual, cuatro direcciones, colisiones y apariencia compuesta en una escena pequeña.
3. Conectar estado de mundo, inicio aleatorio seguro y guardado versionado.
4. Conectar recolección, inventario y construcción con persistencia.
5. Añadir fabricación y progresión a partir de contratos y reglas documentadas.
6. Resolver combate; integrar enemigos y encuentros con estados y recompensas.
7. Conectar misiones, capítulos y habitantes a eventos y condiciones reales.
8. Expandir contenido y comportamiento a partir de lo comprobado.

Este orden expresa dependencias, no un límite de contenido ni una definición de beta. No establece duración ni cifras de producción.

## Comprobaciones que deben acompañar las funciones

- Las cuatro direcciones permiten rodear edificios; tejados y sprites no crean colisiones falsas.
- Un conjunto documentado de semillas produce puntos iniciales transitables con salida; guardar y cargar conserva el mismo mundo modificado.
- Recoger, fabricar, construir y retirar conservan recursos según sus reglas; el inventario lleno tiene una respuesta definida.
- Cambiar una construcción actualiza las rutas; un NPC no atraviesa una pared nueva.
- Una habilidad no se aplica dos veces al cargar y los requisitos no forman bloqueos involuntarios.
- Una misión distingue condiciones actuales de hechos pasados y entrega cada recompensa una sola vez.
- Un cofre conserva su resultado; un jefe derrotado conserva el estado y respeta su política de reaparición.
- Un guardado interrumpido o inválido tiene recuperación comprobada.
- Las combinaciones de apariencia mantienen anclajes y orientación en las animaciones disponibles.

Añadir pruebas cuando exista comportamiento concreto y riesgo real. No escribir comprobaciones que solo repitan constantes sin verificar su efecto.


---

# Fuentes, licencias, procedencia y supuestos

La matriz siguiente resume la investigación previa de las revisiones descargadas. No constituye una auditoría jurídica completa ni una nueva verificación en línea. El manifiesto incluido permite identificar las capturas originales. Antes de incorporar un archivo hay que revisar su licencia y excepciones concretas.

## Matriz de fuentes

| Repositorio | Revisión fijada | Utilidad y límites | Licencia observada |
|---|---|---|---|
| [yuema137/MineWorld](https://github.com/yuema137/MineWorld) | `af5c27e78b76d4fbb64a2f845f604ffa47ad0f64` | Necesidades y configuración de objetos; arquitectura de referencia. No es el MineWorld de Microsoft. No está integrado su servidor ni persistencia. | MIT general; NOTICE con excepciones, incluidos recursos Blender GPL y tipografía OFL |
| [ErkoKnoll/helbreath-base-game](https://github.com/ErkoKnoll/helbreath-base-game) | `734f95cf506d666f3a39dbce5bb292f43d162c47` | Referencia cliente/servidor y combate; revisar dependencias y seguridad antes de trasladar. No integrado. | MIT con exclusión de recursos propietarios de Helbreath; no usar esos assets |
| [sourceofmana/sourceofmana](https://github.com/sourceofmana/sourceofmana) | `ebb0335f1ac438a883f1d70e27cdfe92f811ed28` | Estadísticas, experiencia e inventarios Godot; fórmulas acopladas a actores, modificadores y datos. No integrado su combate/progresión. | Código mayormente MIT; arte/diseño CC BY-SA 4.0 y excepciones por archivo |
| [CleverRaven/Cataclysm-DDA](https://github.com/CleverRaven/Cataclysm-DDA) | `24937c383aad78d2d83866a29e6899f4cc054440` | Estructura de recetas y fabricación; unidades y dependencias requieren estudio. No integrado. | CC BY-SA 3.0 general y excepciones de componentes |
| [blocktest-game/blocktest](https://github.com/blocktest-game/blocktest) | `ce515c28e84765cc561b41fc3a211a2f8f4cd168` | Edición de bloques y parámetros del prototipo lateral. Su física de plataformas no sirve directamente para movimiento cenital. | MIT |
| [blocktest-game/Blocktest-MonoGame](https://github.com/blocktest-game/Blocktest-MonoGame) | `d7f92fedf52e444870abf1ffbd4ed8be929ce368` | Organización de cuadrícula y capas. No atribuirle un controlador de plataformas verificado. | MIT |
| [mafik/libcolony](https://github.com/mafik/libcolony) | `7406bd9fbb00e53273ea9da84eeba5aa26af382f` | Asignación de tareas según costes; no aporta por sí sola necesidades, economía o balance. Opcional. | MIT |

Una licencia abierta no implica que todas las fuentes puedan mezclarse sin condiciones. Mantener avisos; revisar atribución, distribución y posibles obligaciones sobre adaptaciones antes de integrar código o datos con condiciones diferentes. La mera presencia en `fuentes/` no autoriza su uso indiscriminado.

## Reutilización ya documentada en el prototipo lateral

Blocktest aporta adaptación de movimiento lateral, gravedad, capas, dimensiones y cinco texturas. MineWorld aporta tasas de hambre/cansancio y efecto del pan. El guardado y la misión son locales. La procedencia detallada se incluye como evidencia y en el archivo del prototipo.

Las tasas documentadas de MineWorld son hambre +120/h despierto y +30/h dormido; cansancio +60/h despierto y −125/h dormido; escala 0–1000 y pan que reduce hambre en 500. Son valores heredados del escenario inspeccionado, **no balance aprobado para este juego**. Antes de usarlos revisar escala temporal, descanso, disponibilidad de alimento y significado de los límites.

El refugio, Ada, cuaderno, regalo, alcance de herramientas, duración del día y otras reglas del prototipo son decisiones locales sin balance validado. No convertirlas en canon o valores definitivos por estar implementadas.

## Ficha obligatoria de procedencia para nuevas integraciones

Sistema; archivo y símbolo original; URL y commit; licencia y avisos; dependencias; unidades; comportamiento original; adaptación; motivo; pruebas; limitaciones. Si falta una dependencia importante, completar el análisis o tratar la implementación nueva como provisional.

No copiar una tabla de experiencia sin comprobar índices, límites y consumidores. No copiar daño sin estadísticas, defensa, equipo y ritmo de combate que le dan sentido. No llamar «validado» a un valor solo porque aparece en un repositorio público.

## Registro de supuestos y decisiones pendientes

| ID | Estado | Decisión de trabajo | Cuándo revisarla |
|---|---|---|---|
| D01 | Acordado | Vista cenital oblicua, movimiento en dos ejes | Mantener como dirección del proyecto |
| D02 | Acordado | PJ personalizable | Antes de producir sprites finales |
| D03 | Acordado | Inicio aleatorio, romper y construir, habilidades, misiones, jefes y tesoros | Al conectar cada sistema |
| P01 | Propuesta | Mundo de fantasía independiente de una ficción de videojuego | Antes de cerrar canon |
| P02 | Propuesta | Godot, juego local para un jugador como base técnica | Antes de diseñar requisitos de red |
| P03 | Propuesta | Cuatro direcciones sin diagonales | Durante prueba de movimiento |
| P04 | Propuesta | Celdas de 16 px; personaje 16×24 o 16×32 | Antes de producción de arte |
| P05 | Propuesta | Semilla y selección de aparición segura; generación total no exigida | Al elegir estructura de mundo |
| P06 | Propuesta | Sin avance del mundo mientras la aplicación está cerrada | Antes de economía o eventos temporales |
| A01 | Pendiente | Combate, muerte, recuperación y reaparición | Antes de estadísticas y encuentros definitivos |
| A02 | Pendiente | Conflicto principal, capítulos y final | Durante escritura de contenido |
| A03 | Pendiente | Economía, progresión numérica y recetas finales | Tras analizar grupos completos de reglas |
| A04 | Pendiente | Tamaño de mundo, plataformas y multijugador | Cuando condicionen arquitectura o producción |

Las propuestas permiten empezar y son reversibles. Las decisiones que cambian contratos importantes deben quedar registradas antes de extender contenido dependiente.


---

# Instrucción para Claude

Quiero que empieces a construir un RPG 2D de mundo vivo a partir de este paquete. Es un **punto de inicio del proyecto**, no una especificación de beta ni un alcance cerrado. No conviertas este encargo en una planificación de beta.

Lee primero `00_LEEME.md` y después los documentos numerados. Distingue Acordado, Propuesta y Pendiente. Utiliza las propuestas reversibles para avanzar y registra las decisiones nuevas; no las atribuyas al usuario ni afirmes que existe una historia definitiva.

El objetivo es vista cenital oblicua, pixel art sencillo y navegación arriba/abajo/izquierda/derecha. PJ personalizable; inicio aleatorio seguro; recolección y objetos rompibles; construcción; árbol de habilidades; misiones de capítulos y de mundo; tesoros, recompensas y jefes de ambos tipos. Narrativa original inspirada en oficios/progresión, exploración, comunidad y aventura de las referencias descritas, sin copiar sus universos.

La referencia en `referencias/visual_objetivo.png` es conceptual. La base de código adjunta es lateral y debe conservarse como referencia; no digas que ya implementa el juego cenital. Extrae `codigo_base/prototipo_lateral_fuentes.zip` e inspecciónalo antes de reutilizar. En el equipo original hay más fuentes en `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/fuentes`; si esa ruta no existe, usa la matriz de commits para localizar lo necesario. El paquete no incluye la biblioteca completa ni un motor instalado transportable.

Construye en una carpeta nueva. Comprueba el motor disponible y empieza por una escena ejecutable que demuestre movimiento cenital, colisiones, escala y apariencia. Después conecta estado, persistencia e interacciones siguiendo dependencias. Implementa y verifica trabajo concreto en cada etapa; no te limites a devolver otro plan. El orden de trabajo no limita la visión del proyecto.

Prioriza reutilizar reglas y código verificables. Revisa licencia por archivo y conserva avisos. No utilices assets propietarios de Helbreath ni recursos de Pokémon. No combines servidores completos ni copies fórmulas sin sus dependencias. Los valores nuevos deben centralizarse y marcarse como provisionales con unidades y motivo. Los valores heredados no equivalen a balance probado para este juego.

No inventes credenciales, pruebas ejecutadas, sistemas implementados, fechas de entrega ni aprobaciones del usuario. Si una decisión pendiente bloquea un contrato esencial —por ejemplo, el modelo de combate— explica brevemente la alternativa recomendada y sigue con trabajo independiente mientras se decide. No cierres canon narrativo para poder probar movimiento o inventario.

Entrega código ejecutable, instrucciones reales para abrirlo, registro de decisiones/procedencia y una explicación breve de lo construido, lo probado y lo pendiente. Comprueba las funciones relevantes indicadas en `05_ARQUITECTURA_Y_CONSTRUCCION.md` cuando existan. Mantén los documentos actualizados conforme cambie el proyecto.
