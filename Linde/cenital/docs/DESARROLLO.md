# Materiales, equipo y aprendizaje durante la partida

Prototipo del 24 de octubre de 2026. Amplía Sociedad del valle con reglas combinatorias, sin un catálogo escrito para cada pieza. No crea código ni mecánicas arbitrarias: combina capacidades implementadas y limitadas.

## Cómo usarlo

Abrir `Iniciar-Prueba-Autonomia.command`, crear un personaje o continuar la partida de prueba. **G** abre Taller y descubrimientos:

- **Materiales:** origen, usos y cantidad que llevas. Se puede consultar también desde una partida normal. Flechas recorren el texto.
- **Planos:** cambiar la forma, comparar propiedades y ver costes antes de fabricar. Se necesita una mesa cercana, conocimiento de los materiales y espacio en la mochila.
- **Materiales elaborados:** fabricar laminados con componentes existentes en un horno. Requiere conocer los componentes y alcanzar rango 1 de artesanía del hierro.
- **Práctica:** acciones confirmadas, especializaciones por material y técnicas aprendidas.
- **Obras de habitantes:** piezas que realmente produjeron. Se intercambian por materiales estando cerca del artesano. No se generan al comprar y una oferta agotada no vuelve a cobrarse.

F sigue mostrando mejoras del equipo anterior y ofrece acceso a G. K conserva el árbol manual y enlaza a la práctica. La nueva progresión no consume puntos del árbol.

## Qué materiales hay hoy

| Recurso | De dónde sale | Para qué se usa |
|---|---|---|
| Madera | Árboles, a mano o con hacha | Construcción, herramientas, combustible de refinado y piezas de madera |
| Piedra | Rocas, a mano o con pico | Herramientas, horno, mesa y equipo de piedra |
| Fibra | Arbustos | Camas, herramientas, tejidos y armaduras ligeras |
| Mena de hierro | Vetas; requiere pico | Refinar lingotes en un horno |
| Lingote | 2 menas + 1 madera, en horno | Equipo de hierro, reparación y materiales elaborados |
| Baya | Puede salir de arbustos | Alimentar habitantes y curar al jugador |
| Gelatina | Slimes | Fabricar ungüentos |
| Ungüento | Gelatina + fibra, en mesa | Curación |
| Gema | Puede salir de vetas; también tesoros y jefes | Recetas y mejoras de equipo existentes |

El atlas del juego consulta los catálogos actuales para mostrar usos concretos.

Fuera del valle (sierra, secano, pradera) hay tres recursos más. Un habitante puede llegar a ellos: el contorno del valle se mantiene cargado y todos lo ven desde el borde.

| Recurso | Fuente | Uso |
|---|---|---|
| Mena de cobre | Veta de cobre (pico) | 2 menas + 1 madera en horno → lingote de cobre |
| Mena de estaño | Veta de estaño (pico) | 2 lingotes de cobre + 1 estaño en horno → 2 lingotes de bronce |
| Arcilla | Pozo de arcilla (mano o pico) | 2 arcillas en horno → 3 ladrillos |

Cobre y bronce son materiales de la gramática (`reglas_v1.json`): permiten espadas, escudos y armaduras, y forman laminados como el hierro. El hacha y el pico de cobre recortan 1 golpe más que los de piedra, también para los habitantes.

## Cómo aparecen piezas nuevas

La gramática combina **forma + material + técnica + calidad**. Las formas son espada, escudo, casco, armadura de torso, guantes, botas y pantalones. La compatibilidad importa: tejido no puede producir una espada. Los materiales aportan potencia, movilidad, color y formas posibles; la técnica añade un intercambio entre potencia y movilidad y puede requerir ingredientes adicionales. La calidad procede de la práctica con ese material.

La receta también se deriva: coste base del material por tamaño de la forma, más los componentes de la técnica. No se sortea ni se cobra un resultado oculto. El plano muestra nombre, daño, defensa, vida, movilidad y costes antes de confirmar.

Las piezas funcionan como objetos normales: inventario, equipar, estadísticas, combate, cofre, guardado y red. Las armaduras usan geometrías existentes recoloreadas por material; las espadas reutilizan la hoja existente. No se han creado siluetas o animaciones nuevas. No tienen bonos de set del sistema anterior ni se mejoran mediante sus piedras: para obtener una pieza mejor se fabrica otra con la pericia y técnica disponibles.

## Materiales que se elaboran y descubren

Una segunda regla combina un núcleo de hierro con madera, piedra o fibra. Cada laminado consume **2 lingotes + 2 unidades del refuerzo** y produce **1 unidad** de material elaborado. La descripción y sus propiedades salen de sus componentes, no de tres fichas de objetos escritas por separado.

Las formas posibles son la intersección de las formas de los componentes: hierro con fibra permite armaduras, mientras que hierro con madera o piedra permite armas y escudos. La potencia mezcla el 85 % del núcleo y el 15 % del refuerzo; la movilidad promedia ambos. Son laminados de fantasía con reglas propias provisionales, no una simulación metalúrgica real.

Conocer una transformación no regala el material. Solo después de elaborarlo u obtenerlo se descubren sus planos. Las mezclas no se encadenan indefinidamente: no se aceptan componentes compuestos como nuevos núcleos o refuerzos. El material elaborado se puede guardar, transferir y consumir en otra receta.

## Aprendizaje con consecuencias

Se registra práctica una vez por acción confirmada: una rotura terminada, una fabricación pagada, una construcción válida o un impacto sobre un enemigo vivo. Golpear al aire, fallar un pedido o abrir el panel no entrena. Conservar materiales al cargar no concede experiencia.

- Cada 3 acciones se alcanza otro rango, con máximo 3; los contadores se limitan a 120. Son valores provisionales.
- **Recolección:** reduce hasta 2 golpes necesarios; se aplica al jugador y habitantes.
- **Artesanía por material:** mejora la calidad de futuras piezas y desbloquea técnicas. Sencilla requiere rango 0; ligera, rango 1; reforzada, rango 2.
- **Construcción:** reduce la superficie que necesita una técnica avanzada, con mínimo 1 suelo. La práctica muestra el requisito efectivo.
- **Combate:** añade hasta 2 de daño por práctica real.

Las técnicas ligera y reforzada requieren inicialmente 2 y 4 suelos de taller, respectivamente. La superficie se mide en un radio de 5 celdas. Las técnicas nuevas consultan conocimiento, pericia y taller al fabricar: el cliente no puede pedir calidad maestra sin haberla aprendido.

**Las piezas ya fabricadas conservan sus propiedades al aprender.** La fórmula y el contenido de la versión 1 deben conservarse para leer las claves de esa versión; cambios incompatibles necesitan una versión nueva, no editar silenciosamente `reglas_v1.json`.

## Recetas que aparecen según lo que ocurre

Cada habitante parte con las recetas de su perfil. Al tener en las manos un ítem que nunca había tenido, aprende las recetas que lo usan (queda en su memoria; las herramientas, también en el diario). Con eso aparecen metas nuevas: aprovechar lo que trajo (fundir cobre) y mejorar su herramienta (pico de cobre) cuando ya conoce todos los insumos. Sin metas pendientes, prueba un recurso que nunca ha tenido, y por eso sale a las vetas y pozos del contorno. Las recetas aprendidas se guardan en `recetas_nuevas` de cada habitante.

## Habitantes y ampliaciones

Los habitantes aprenden de sus propias acciones. Después de practicar pueden ampliar la superficie del taller según su rango y la ocupación de su inventario, hasta 8 suelos por zona. Caminan, reúnen madera, pagan cada pieza y conservan las validaciones de ocupación y rutas. Esta superficie permite aplicar técnicas nuevas; no es solo decoración.

También experimentan con excedentes y mantienen un máximo de 2 obras a la venta, escogiendo formas de interés de su grupo. Necesitan una mesa real y pueden construirla pagando materiales. Las fabricaciones y refinados de NPC desgastan las estaciones. Conocer los componentes, la técnica y tener excedentes puede permitirles elaborar materiales. No se promete que todas las combinaciones aparezcan en una sola partida.

La ampliación actual es de talleres y estaciones con piezas conocidas; no diseña casas completas, barrios ni ciudades. La prueba no implementa clases nuevas, habilidades de movimiento inventadas ni efectos sin código. Los rangos, precios y balance siguen siendo provisionales. El desgaste de estaciones es parte de la simulación de NPC; la fabricación manual anterior del jugador no se ha convertido en una simulación industrial completa.

## Guardado, red y verificación

El conocimiento, práctica, proyectos y registro de creaciones viven en `mundo_vivo.autonomia.desarrollo`. Las piezas usan claves canónicas versionadas `art1:...`; los materiales elaborados, `mat1:...`. Sus propiedades se reconstruyen con reglas de esa versión. Las partidas anteriores adquieren campos nuevos sin perder objetos; observar existencias antiguas reconoce materiales, sin conceder práctica.

Solo el servidor fabrica, refina y vende. Valida conocimiento, calidad, estación, proximidad, stock y capacidad; los costes son atómicos. La réplica consulta la identidad real del jugador del servidor. No puede entrenar ni crear un artefacto por modificar la previsualización local.

Prueba principal: `tests/prueba_desarrollo.gd`. La regresión conserva `prueba_autonomia.gd`, `prueba_sociedad.gd`, `prueba.gd`, `prueba_ui.gd` y `prueba_red.gd`. Las pruebas nuevas guardan solo en `/tmp/`. Evidencia visual y de simulación en `production/qa/evidence/desarrollo/`; `captura_desarrollo.gd` usa la escena real y acciones de recolección/fabricación para preparar sus pantallas, con posicionamiento de QA. La simulación independiente de tres días no recibe intervenciones del jugador.

## Caminos que se forman por uso

Cada paso de un jugador o habitante sobre hierba libre cuenta (`Mundo.pisar`). A las 20 pisadas (`PISADAS_CAMINO`, provisional) la celda pasa a ser camino: se guarda en `mundo.caminos`, se replica a los clientes y se dibuja con el arte de camino existente. Agua, construcciones y objetos no se gastan. Los caminos no vuelven a hierba. 

## Campos de cultivo

«Campo de cultivo» es una pieza (2 fibras y 2 bayas; la baya hace de semilla). Madura a las 12 horas de juego (`CAMPO_CRECE_MIN`) y con E se cosechan 3 bayas y 1 fibra (`CAMPO_COSECHA`); queda sembrado otra vez. El arbusto dibujado sin bayas es el cultivo creciendo. Cada grupo labra un campo junto a su depósito (`campos_por_grupo`) cuando algún miembro puede pagar la semilla sin hambre, y sus miembros lo cosechan, también cuando necesitan comida. En 4 días simulados (semilla 123) los dos grupos hicieron un campo cada uno y los cosecharon.

## Casas completas

Piezas nuevas: **Puerta** (3 madera; no bloquea, se ve abierta con alguien a una celda) y **Techo** (1 madera + 1 fibra). El techo va aparte de las piezas (`mundo.techos`): una celda puede tener cama, mesa o muro y además techo. Los techos se guardan, se replican y se dibujan sobre la casa; los conectados al jugador (por dentro o junto a la puerta) se vuelven casi transparentes.

El plano de la casa está en `datos/autonomia/reglas.json` (`vivienda.casa`), relativo a la cama de huésped: los tres muros del refugio, tres muros más para una sala de 2×1, la puerta al sur, una mesa y techo sobre cama y sala. Tras el refugio, un albañil la completa pieza a pieza; las piezas bloqueadas quedan pendientes y se reintentan. Quien duerme en una casa completa recupera la energía un 25 % más rápido (`bono_descanso`). En la partida simulada de 5 días las camas quedaron apretadas y no se completó ninguna: el plano pide unos 5×5 libres.

## Revisión de crecimiento (25/10)

Se reservan solares completos y accesos antes de ampliar vivienda. La práctica de preparar una cama permite aprender ladrillo; se consultan recetas aprendidas además del oficio inicial. Los cultivos escalan con el grupo y cosechar tiene prioridad con hambre. Ver [CRECIMIENTO_Y_ASENTAMIENTOS.md](CRECIMIENTO_Y_ASENTAMIENTOS.md) para persistencia, arte, puestos exteriores y límites medidos.
