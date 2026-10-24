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
