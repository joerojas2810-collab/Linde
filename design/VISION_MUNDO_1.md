# Visión de Mundo 1

> **Estado de este documento**: diseño objetivo, decidido por el usuario el 2026-10-26. **Nada de lo que describe se da por implementado**: lo implementado y verificado vive en [ESTADO.md](../production/epics/mundo-vivo/ESTADO.md). Auditoría y secuencia de trabajo: [PLAN_MUNDO_1.md](../docs/investigacion/PLAN_MUNDO_1.md). Diagnóstico previo: [CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md](../docs/investigacion/CIERRE_MUNDO_INICIAL_Y_EXPLORACION.md).

## Idea
Linde tiene **un mundo compartido, persistente y reconocible**, que existe y cambia con independencia de que haya jugadores conectados. La exploración, la civilización, la supervivencia y la progresión no son sistemas distintos: son consecuencias de ese mismo mundo simulado (Mundo Vivo).

## Principios
1. **El mundo se genera una vez y se conserva.** La semilla es una herramienta para generar, reproducir y ampliar; no para producir un mundo distinto en cada partida. Lo generado y lo modificado conserva su identidad e historia. El mundo puede crecer sin destruir regiones existentes. Se distingue la **generación controlada** (el registro persistente de poblados, lugares y caminos: determinista, independiente del orden de exploración, que conserva sus resultados) de la **simple carga de regiones** (terreno reconstruido desde la semilla más las diferencias).
2. **Geografía estable, civilización cambiante.** El relieve base cambia poco; pueblos, caminos, construcciones, recursos y ecosistemas evolucionan por lo que hacen NPC, jugadores y acontecimientos.
3. **Todos los pueblos siguen las mismas reglas.** El pueblo inicial es una comunidad más: habitantes autónomos con oficios, recursos, instalaciones y rutinas. Ningún pueblo es inmortal: puede prosperar, decaer, abandonarse y recuperarse; su **viabilidad** se define con comida, camas, residentes y seguridad (umbrales por medir y aprobar). El detalle de simulación varía con la cercanía, no las reglas. Los pueblos preexistentes empiezan con **simulación resumida** pero con habitantes identificables, actividad económica y evolución observable; la **transición resumida↔detallada** es un objetivo de diseño que se aplaza hasta resolver identidad, recursos y red. Los pueblos nuevos los fundan los NPC por necesidades y condiciones reales del mundo, no por eventos programados.
4. **La progresión sale del mundo.** Se avanza por lo que se encuentra y aprende: materiales de cada hábitat, oficios y saberes de las comunidades, lugares que exigen preparación. No hay un sistema de nivel superpuesto ni una escalera de pueblos.
5. **Dificultad orgánica.** Depende de biomas y hábitats, especies y su comportamiento, recursos y condiciones, presencia de caminos y asentamientos y acontecimientos locales. Sin escalado automático al nivel del jugador ni regiones bloqueadas. Una cueva peligrosa puede estar junto a un pueblo seguro. El peligro cambia con las acciones del mundo.
6. **Las amenazas se reconocen.** Señales del entorno y conducta visible permiten decidir antes de que el peligro sea inevitable.
7. **Aprender por contexto, nunca por obligación.** Ayuda opcional ligada a lo que ocurre; ni tutorial obligatorio ni misiones artificiales.
8. **Aprovechar lo existente.** Mundo 1 se construye ampliando Mundo Vivo, no reescribiéndolo.

## Experiencia buscada
- **Entrada**: el jugador (y los de su misma partida, cerca unos de otros) aparece en un pueblo habitado, coherente y comprensible, donde ve gente trabajando. El Valle actual se **transforma** en ese pueblo aprovechando lo existente, sin obligación de conservar su estructura ni su identidad anterior.
- **Orientación**: mapa personal consultable con M, que muestra lo descubierto o sabido; los NPC pueden dar información aproximada sobre lugares; los descubrimientos se pueden compartir.
- **Exploración**: hay destinos significativos y accesibles (ruinas, campamentos, cuevas como alcance inicial, no como límite) y 1–2 pueblos preexistentes adicionales al principio (alcance inicial, no límite) unidos por caminos. Los pueblos se construyen **generalizando `Asentamientos`**, sin un sistema paralelo.
- **Evolución visible**: construcciones, caminos, cultivos, habitantes y asentamientos cambian de forma persistente y observable; los NPC fundan y amplían asentamientos.
- **Edificios funcionales** (precisión del usuario, 26/10): catálogo pequeño de vivienda, taller y depósito; ningún pueblo está obligado a tener los tres. Edificios completos para jugadores/NPC, compuestos por piezas y objetos reales, con interiores continuos, entradas claras, techos que permiten ver el interior y puertas automáticas inicialmente. Planos preparados para construcción progresiva y modificaciones limitadas por reparación/ampliación; primero hacer funcionar edificios terminados, sin bloquear la expansión del mundo por implementar todas las etapas.
- **Continuidad**: si el pueblo inicial deja de ser viable, quien se une después aparece en otra comunidad segura y coherente.

## Hitos de evaluación (no son requisitos para el jugador)
A los 15 y 60 minutos se evalúa si la experiencia funciona (primera herramienta y conversación; visita a un lugar exterior y regreso). Sirven para medir el diseño, no para imponer objetivos.

## Límites
- No se modifica el balance de XP, fabricación, daño, recompensas o progresión sin mediciones y aprobación.
- No hay mundo ilimitado ni simulación detallada de todos los pueblos a toda distancia: la lejanía se simula de forma resumida.
- Contenido masivo y sistemas complejos van después de tener un ciclo jugable comprobado.
- Los topes técnicos (habitantes por poblado y globales, regiones cargadas, número de pueblos) son **configurables y se fijan por medición**; no son límites permanentes del diseño.

## Decisiones asociadas
Cerradas por el usuario el 2026-10-26: D1–D14 (inicio en pueblo habitado; jugadores cercanos; mundo compartido con varios asentamientos; mapa personal compartible; instalaciones comunitarias; evolución visible; aprendizaje contextual; hitos de evaluación; mapa con M; destinos significativos; ruinas/campamentos/cuevas; dificultad territorial orgánica; pueblos no inmortales; sin cambios de balance sin medición). Precisadas con N1–N6 y las fases 0 y 5–7. Registradas como `M1-*` con estado *Usuario* en la sección F de [DECISIONES.md](../Linde/cenital/docs/DECISIONES.md).
