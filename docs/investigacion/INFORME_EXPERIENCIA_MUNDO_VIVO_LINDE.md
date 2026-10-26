# Linde — convertir un mundo vivo en una experiencia jugable y duradera

**Informe práctico de diseño** · 26-10-2026  
**Base de proyecto consultada:** `VISION_MUNDO_1.md`, `DECISIONES.md`, `ESTADO.md`, `Diseno_Maestro_Fase6_Linde.md`, `DISENO_MAESTRO_FASE7.md` y `PLAN_MUNDO_1.md` adjuntos.  
**Alcance:** evaluación de experiencia y recomendaciones priorizadas; no es una fase de implementación ni una aprobación de nuevas decisiones.

## 1. Tesis

Un mundo que sigue simulándose no es, por sí mismo, un juego interesante. Persistencia, autonomía, economía y memoria son **materia prima**. Para que generen diversión, el jugador debe poder:

1. percibir una situación relevante;
2. comprender al menos parte de sus causas;
3. elegir entre acciones con costes u oportunidades distintas;
4. ver un resultado que afecte el mundo o sus relaciones;
5. conectar ese resultado con una historia que pueda recordar y compartir;
6. encontrar después nuevas decisiones, sin que una rutina automática resuelva todo por él.

El riesgo central de Linde no es tener “pocas simulaciones”. Es que la simulación opere por detrás, se traduzca en actividad repetitiva de recolección/fabricación, o produzca cambios que el jugador no perciba ni pueda atribuir. La promesa de mundo vivo exige tanto **causalidad interna** como **legibilidad y agencia externa**.

La visión aprobada —autonomía como modo principal, mundo sin campaña lineal, destinos significativos, descubrimiento, sociedades persistentes, dificultad territorial y aprendizaje opcional— define una dirección coherente. No define todavía una experiencia suficiente para retener por sí sola. Conviene tratar los sistemas emergentes como una fábrica de **situaciones** que el jugador puede leer, afectar y abandonar, no como una fábrica automática de tareas.

## 2. Qué está aprobado, qué se conoce y qué se propone

### 2.1 Decisiones aprobadas (no reinterpretar como recomendaciones)

Según `VISION_MUNDO_1.md` y `DECISIONES.md`:

- El jugador participa en un mundo compartido, reconocible, persistente; el mundo puede cambiar cuando no hay jugadores.
- Autonomía es el modo principal; no hay campaña escrita como columna vertebral de la partida.
- La exploración, civilización, supervivencia y progresión surgen de un mismo mundo simulado.
- Geografía estable; pueblos, caminos, construcciones, recursos y ecosistemas evolucionan.
- El inicio es un pueblo habitado; compañeros de partida aparecen próximos en posiciones válidas.
- Mapa personal consultable, compartible; NPC pueden dar información aproximada. No es requisito un minimapa permanente.
- Hay lugares significativos y accesibles, pueblos preexistentes y cambios territoriales observables y persistentes.
- La progresión se obtiene por lo encontrado/aprendido, no por un sistema de nivel superpuesto ni una escalera de pueblos.
- La dificultad es orgánica: biomas/hábitats, comportamiento de especies, recursos, caminos, asentamientos y acontecimientos; sin escalado automático por nivel ni regiones bloqueadas.
- Peligros reconocibles; los pueblos no son mágicamente seguros, aunque el jugador nuevo no debe aparecer ante una amenaza sin reacción razonable.
- Ayuda contextual y opcional; sin tutorial obligatorio ni misiones artificiales.
- Los hitos de 15 y 60 minutos son criterios de evaluación, no objetivos impuestos al jugador.
- Reutilizar/generalizar `Asentamientos`, sin un sistema paralelo de pueblos; la fundación autónoma requiere necesidades/condiciones reales (M1-F6).
- Viabilidad se relaciona con comida, camas, residentes y seguridad; umbrales requieren medición y aprobación.
- Simulación lejana resumida; transición de residentes resumidos a detallados es objetivo aplazable; no simular todo con detalle.
- No cambiar XP, fabricación, daño, recompensas o progresión sin medición/aprobación (M1-D14).

### 2.2 Estado reportado, no verificado de nuevo

`ESTADO.md` informa sistemas de autonomía y sociedad (necesidades, producción, trueque, confianza, grupos, memoria), saberes/enseñanza, fauna determinista, terreno por regiones, caminos, cultivos, edificios, mapa de exploración y comunidades regionales con economía resumida. Informa pruebas automatizadas y sus límites, incluyendo ausencia de playtest humano prolongado, validación de red sólo local en varios casos, asuntos pendientes de rendimiento y de transición de simulación.

Esto permite hablar de **oportunidades de experiencia** sobre lo reportado, pero no permite asegurar aquí que cada conexión ya exista en el código o que se sienta divertida. Los diseños maestros F6/F7 son contratos y propuestas; no convierten automáticamente sus recomendaciones en funcionalidades existentes.

### 2.3 Oportunidades y propuestas nuevas de este informe

- Hacer que cada sistema visible contribuya a un bucle breve de percepción → decisión → consecuencia → nueva oportunidad.
- Tratar los **proyectos del jugador** (no cadenas de misiones) como unidad de motivación: restaurar un puente, aprender un oficio, sostener una casa comunal, descubrir qué amenaza una ruta, ayudar a una familia o comerciar entre comunidades.
- Dar un registro corto de causas/eventos que facilite memoria y relato, sin convertir el mundo en un diario de logs obligatorio.
- Medir la diversión con tareas abiertas y observación humana, además de tests deterministas.
- Limitar automatización por políticas/órdenes con alcance y costes claros; mantener interrupciones y decisiones que requieren presencia/jucio del jugador.

Estas son hipótesis de diseño. Requieren prototipos y decisión humana; no son decisiones aprobadas ni una nueva fase.

## 3. Referentes: lecciones y límites

### Dwarf Fortress — simulación que produce historias, pero no prescribe una experiencia accesible

La descripción del juego enfatiza que la autonomía de los enanos y el jugador como “voluntad oficial de la fortaleza” generan narrativas emergentes; sus creadores hablan de la necesidad de equilibrar sorpresa consistente, interés y capacidad de investigar. [2](https://www.gamedeveloper.com/design/q-a-dissecting-the-development-of-i-dwarf-fortress-i-with-creator-tarn-adams) [3](https://www.gamedeveloper.com/programming/how-tarn-adams-upgraded-and-optimized-dwarf-fortress-for-its-official-steam-release)

**Lección útil:** no todo relato requiere guion; autonomía de personajes y efectos que sobreviven pueden bastar si el jugador se involucra y entiende relaciones causales. **Límite:** Dwarf Fortress acepta complejidad, opacidad y una curva de aprendizaje que Linde no debería copiar por prestigio de simulación. Una simulación legible y acotada puede ser más jugable que un mundo “más completo”. El juego es cerrado; esto es referencia de diseño, no fuente de código.

### RimWorld — personajes recordables, consecuencias conectadas y drama dosificado

RimWorld se presenta oficialmente como generador de historias. [1](https://rimworldgame.com/) El diseñador Tynan Sylvester ha descrito la prioridad de personajes y sistemas simples capaces de generar historias, y la importancia de dar al jugador un grupo suficientemente pequeño como para recordar individuos. [4](https://www.rockpapershotgun.com/how-rimworld-generates-great-stories) El análisis de Game Developer destaca cadenas de consecuencias y el balance entre agencia e imprevisibilidad. [5](https://www.gamedeveloper.com/design/rimworld-dwarf-fortress-and-procedurally-generated-story-telling)

**Lección útil:** identidad y memoria relacional pueden valer más que añadir docenas de variables psicológicas; una herida que impide un oficio y fuerza un reemplazo puede ser relato si el jugador conoce a esa persona. **Límite:** el storyteller dirige eventos para ritmo dramático; Linde busca que las amenazas procedan de ecología y territorio. No importar raids aleatorias ni “director” que ataque al jugador para llenar silencios. El juego es propietario; no es código reutilizable.

### Kenshi — libertad y consecuencias, con un coste real de orientación y ritmo

Lo-Fi describe su intención de que las situaciones resulten de fuerzas que interactúan y que el jugador pueda encontrarlas, oír de ellas o ver sus consecuencias. [6](https://lofigames.com/quests-quests/) Una entrevista explica la elección de mundo desigual, historia insinuada y viajes donde la geografía importa. [7](https://www.rockpapershotgun.com/how-kenshis-world-is-designed-not-to-care-about-you)

**Lección útil:** un problema mundial no necesita entregarse como misión si se ve, se oye o deja rastros; el jugador puede apropiárselo o ignorarlo. **Contraejemplo importante:** crítica contemporánea identifica que la libertad sin guía ni motivación clara puede volverse confusión, repetición o ennui. [8](https://tripharrison.substack.com/p/the-deconstructed-rpg) Linde no debe confundir “sin misión obligatoria” con “sin intención visible, propósito cercano ni retroalimentación”.

### Mount & Blade: Bannerlord — lugares, rutas, economía y agentes que forman el escenario

TaleWorlds explica que su objetivo es que lugares, misiones, personajes y sistemas reaccionen dinámicamente a lo que hace el jugador para crear narrativa emergente. [9](https://www.taleworlds.com/en/Games/Bannerlord/Blog/24) El diseño une poblados, producción y transporte para que el mundo tenga relaciones espaciales y económicas.

**Lección útil:** una ruta tiene valor cuando une producción, habitantes y consecuencias, no sólo porque dibuja un camino; los NPC y lugares pueden dar contexto y oportunidades. **Límite:** una economía amplia y política de facciones puede conducir a una trayectoria dominante (conquista/poder) y reducir motivaciones alternativas. Linde debería admitir papeles variados, no hacer que la progresión social o el asentamiento propio sean el destino implícito de todos.

### Valheim — exploración física y señales sobrias; costes de viaje pueden cansar

En entrevistas, Iron Gate explica que diseña biomas para ofrecer identidad, peligros y recursos distintos mediante iteración. [10](https://gamerant.com/valheim-interview-the-mistlands-creation-design-process/) La decisión sobre portales ilustra un trade-off explícito: el estudio quiso evitar que el viaje instantáneo eliminara la exploración y la necesidad de construir puestos, después de ver ese comportamiento en playtests. [11](https://www.rockpapershotgun.com/why-valheim-wants-to-stop-you-using-portals)

**Lección útil:** la navegación y los hitos pueden convertir desplazamiento en parte de la experiencia; quitar toda fricción puede borrar el mundo. **Límite:** obligar a repetir viajes logísticos para “hacer que el mundo importe” produce desgaste. Linde tiene mapa consultable y aprendizaje por rumor; debe conservar orientación suficiente sin convertir excursiones en caminata vacía.

### Project Zomboid — presión distribuida y abstracción “meta” como modelo de lectura

El juego se describe como sandbox de supervivencia con servidores persistentes; su material público sobre metagame/NPC plantea coordinar actividad fuera de la zona inmediata y hacer concretos actores al acercarse. [12](https://store.steampowered.com/app/108600/) [13](https://pzwiki.net/wiki/Frequently_Asked_Questions)

**Lección útil:** se puede hacer sentir que el mundo sigue moviéndose sin ejecutar cada personaje en detalle. También el sonido, visibilidad y percepción generan decisiones de riesgo sin una lista de objetivos. **Límite:** el PZ actual no es evidencia de un sistema público de código abierto de NPC completo; evitar depender de promesas de NPC anunciadas/planificadas. Su supervivencia de alto estrés no es necesariamente el tono deseado de Linde.

### Lectura comparada

Los referentes más convincentes ofrecen tres cosas juntas: **marco de lectura** (qué importa), **espacio de agencia** (qué puedo hacer) y **consecuencia que persiste** (qué cambió). Sólo simular agentes no garantiza las tres. Linde puede conservar mundo abierto y ausencia de misión lineal si ofrece vocabulario de posibilidades: necesidades visibles, personas reconocibles, destinos con historia, señales, decisiones y resultados.

## 4. Motivaciones sin misiones tradicionales

### El vacío que hay que resolver

“Podés hacer cualquier cosa” es libertad formal, no motivación. El jugador necesita una razón inmediata para iniciar una acción y una expectativa de resultado, aunque decida por sí mismo qué historia seguir. Las motivaciones pueden coexistir:

1. **Curiosidad:** qué hay tras una ruina, de dónde vino un rumor, por qué una especie evita una zona.
2. **Dominio:** aprender una técnica, resolver un obstáculo, preparar un viaje mejor.
3. **Cuidado/pertenencia:** ayudar a una persona/comunidad con la que ya se tiene historia.
4. **Construcción/expresión:** dejar una casa, taller, camino o señal reconocible en el mundo.
5. **Intercambio y reconocimiento:** ser conocido por una habilidad o cumplir un compromiso que cambie la confianza.
6. **Riesgo y supervivencia:** elegir cuánto exponerse por un recurso o descubrimiento.
7. **Colección/completitud:** mapa, saberes, lugares o materiales, siempre que no se convierta en una lista interminable de fetch.

No convertir todas estas motivaciones en siete subsistemas. Los sistemas existentes pueden expresarlas con combinaciones diferentes.

### Unidad recomendada: proyecto autoelegido

Un proyecto es una intención que el jugador se formula a partir del mundo (“quiero que la casa comunal vuelva a funcionar”, “voy a conocer el paso norte”, “quiero aprender de esta artesana”). El juego no necesita crear una misión formal, pero debería sostener:

- **Señal de oportunidad:** una necesidad, persona, lugar o cambio visible.
- **Primer paso comprensible:** interactuar, observar, preguntar, reunir un material o recorrer una ruta.
- **Decisiones reales:** dos o más formas compatibles, o la opción explícita de dejarlo.
- **Progreso observable:** el mundo/NPC cambia; evitar barras que no correspondan a acciones físicas.
- **Cierre o transformación:** el problema puede resolverse, quedar peor, cambiar de forma o ser retomado; no todo tiene que resolverse con recompensa.

Un proyecto no debe ser un encadenamiento obligatorio de tarjeta, marcador y premio. Puede existir en el diario/notas personales como recordatorio optativo, pero la oportunidad debe estar también en el mundo.

### Enlaces con sistemas reportados

- **Saberes:** motivación para conversar/observar/practicar; si aprender es sólo subir una cifra, se vuelve grind. Debe abrir una capacidad perceptible y aplicable a un problema cercano.
- **Fabricación/materiales:** recurso de región crea preparación, pero la receta no debe ser la única razón de viajar.
- **Asentamientos:** servicios, oficios, relaciones y transformación hacen posible pertenencia o compromiso.
- **Exploración:** lugares con nombre, rumor, ruta y vuelta dan estructura para excursión sin misión.
- **Autonomía:** acciones de NPC dan escenas e indicios; no deberían consumir continuamente todos los recursos ni resolver solas el propósito del jugador.

## 5. Consecuencias legibles: del sistema al relato del jugador

Una consecuencia necesita ser **visible, persistente, atribuible y accionable**.

- **Visible:** un cambio perceptible en lugar, persona, disponibilidad o rutina; no sólo un contador escondido.
- **Persistente:** sobrevive a abandonar y volver, según la persistencia aprobada.
- **Atribuible:** el jugador puede conectar su acción con el resultado usando señales, diálogo o memoria; no hace falta certeza omnisciente.
- **Accionable:** el resultado crea una nueva decisión u oportunidad, no sólo una notificación.

### Lo que corre el riesgo de fallar

- Confianza/reputación como número sin diferencia de trato, acceso, cooperación o memoria concreta.
- Memoria que acumula eventos pero no reaparece donde el jugador la nota.
- Pueblo que “evoluciona” sólo en métricas económicas invisibles.
- Caminos que se construyen por tránsito pero no llevan a ningún destino útil.
- Recursos que se agotan sin cambiar decisiones o señales.
- NPC que enseñan siempre al mismo jugador o repiten información sin contexto.

### Reciprocidad de consecuencias

Para que el jugador perciba la sociedad como sistema y no como servicio, la consecuencia debe circular en ambos sentidos:

- el jugador altera recursos, confianza, edificios, rutas o información;
- NPC responden según reglas existentes y relaciones/memoria;
- sus decisiones alteran a su vez el acceso/actividad del jugador;
- el jugador puede observar o preguntar qué ocurrió.

Evitar “reputación universal”: distintos NPC/grupos pueden tener memoria y relación distintas; sin embargo, la divergencia debe poder explicarse, no convertirse en un valor secreto que bloquea contenido sin aviso.

## 6. Exploración y descubrimiento con significado

### El destino debe prometer algo concreto, no un botín garantizado

La motivación para desplazarse puede ser una mezcla de: un rasgo de paisaje visible; una necesidad de material/aprendizaje; una historia parcial; una señal peligrosa; una posibilidad de ayudar a alguien; o simplemente espacio nuevo. No hace falta que cada lugar otorgue equipo/mejora. Si todos los viajes se justifican con loot, explorar se vuelve extracción repetitiva.

### Buen patrón para Linde

1. **Rumor o indicio aproximado** desde NPC, paisaje o mapa.
2. **Decisión de ruta y preparación:** el jugador elige camino, carga, compañía, hora y riesgo; no se le dicta una ruta única.
3. **Descubrimiento que verifica/modifica expectativa:** lugar real, recurso, señal, habitante, condición distinta o ausencia inesperada.
4. **Registro personal:** mapa y conocimiento retienen lo conocido, con fuente/precisión si ya existe el modelo.
5. **Consecuencia de vuelta:** el descubrimiento se puede compartir, usar, comparar o ignorar; retornar no es requisito para que toda exploración “cuente”.

### Riesgo de POI y mapa

La Fase 4 reporta destinos persistentes y caminos, pero que existan destinos no garantiza que valga la pena visitarlos. Si el mapa expone demasiadas referencias sin diferenciación, es un catálogo; si oculta todo, el jugador no tiene intención ni orientación. Ofrecer contexto selectivo: lo conocido, lo aproximado por rumores, la distancia/ruta o señales ambientales, pero no todos los recursos/amenazas exactos.

La exploración personal compartible ayuda al juego en grupo, aunque puede borrar la sorpresa si el conocimiento se vuelve global instantáneamente. Conservar procedencia/certeza y permitir que jugadores compartan voluntariamente es más expresivo que un mapa colectivo omnisciente.

## 7. Ritmo: mundo activo sin tiempos muertos ni automatización excesiva

### Qué es tiempo muerto

- esperar que una barra/cultivo/obra termine sin decisión paralela;
- recorrer terreno ya conocido sin nuevos indicios ni planificación;
- NPC “autónomos” que tardan días en completar una casa sin explicar necesidad/obstáculo;
- mirar un mundo lejano simularse sin poder intervenir ni aprender el resultado;
- automatización que recoge, fabrica y resuelve al punto de quitar motivos para jugar.

### Principios de ritmo

- **Alternar bucles cortos y largos:** interacción o fabricación breve; expedición/relación/proyecto más largo. El jugador puede parar una tarea de largo plazo para hacer otra actividad con sentido.
- **Esperas con decisión de oportunidad:** mientras algo madura, aparece un problema/opción local; no sumar ruido aleatorio sólo para ocupar tiempo.
- **No todo momento debe ser amenaza:** una calma permite observar, reparar, conocer NPC o construir; si el juego sólo produce sobresaltos, el peligro pierde significado.
- **Automatizar repetición, no juicio:** NPC pueden ejecutar tareas de rutina; las decisiones que cambian propiedad, territorio, riesgo, relaciones o destino deben mantener un punto de intervención/opacidad explicable.
- **Frentes limitados:** mostrar unas pocas situaciones relevantes, no inundar al jugador con cinco alertas de déficit, crecimiento y rumores cada minuto.
- **Tiempo persistente no equivale a urgencia constante:** una partida entre amigos debe seguir viva, pero no castigar desconexión mediante pérdidas invisibles e irreversibles que el jugador no puede conocer.

### Punto crítico para Linde

El mundo autoritativo siempre encendido y sin congelarse está documentado en decisiones del Mundo Vivo. Esto tiene valor de continuidad, pero puede convertirse en ansiedad, pérdida offline y FOMO si residentes/recursos se deterioran a la misma escala mientras nadie puede responder. La experiencia necesita que el jugador entienda qué cambia con el tiempo, pueda anticiparlo y tenga formas de recuperar/retomar. No se recomienda congelar el mundo —eso contradiría decisión—; sí evitar cambios punitivos invisibles y probar escalas de tiempo antes de promoverlas como urgencia.

## 8. Libertad y orientación: la tensión que no se resuelve con “sin misiones”

La libertad se vuelve fértil cuando hay opciones reconocibles, no cuando todo es igualmente opaco. Kenshi demuestra que un mundo indiferente puede crear relatos intensos, pero también que la ausencia de dirección puede producir desorientación. RimWorld resuelve parte del problema con personajes/situaciones y presión legible; Valheim con biomas, recursos y referencias de viaje; Linde ya tiene mapa, rumores, pistas opcionales y asentamientos.

**Recomendación:** no reintroducir campaña lineal; diseñar una “capa de oportunidades” ligera:

- información local no obligatoria (un NPC preocupado, una ruta deteriorada, falta de material, un lugar que nadie visita);
- posibilidad de preguntar/observar para comprender;
- no objetivo obligatorio, cronómetro ni recompensa prefijada;
- el jugador puede resolverlo, ignorarlo, agravarlo o descubrir otra cosa;
- el mundo registra el resultado.

La capa puede usar interacciones, rumores y datos existentes. Evitar construir un “quest engine emergente” antes de comprobar que señales y sistemas existentes no bastan.

## 9. Situaciones jugables de prueba

Son escenarios para evaluar si las conexiones son interesantes, no propuestas de misiones/canon ni afirmaciones de que el comportamiento exista.

### A. La ruta de los carros
El jugador vuelve de una ruina con material. Encuentra a dos residentes intentando mantener un paso deteriorado; uno necesita material que el jugador tiene y otro desconfía de su uso anterior del depósito. Puede aportar, vender/intercambiar si la operación existe, reparar por sí mismo, preguntar, irse o abrir otra senda. Si interviene, el camino cambia y facilita viajes; si no, el pueblo adapta su rutina y la ruta sigue en mal estado. **Prueba:** ¿hay una decisión más interesante que “entregar 5 objetos por premio”? ¿el mundo y relaciones reflejan quién hizo qué?

### B. El rumor de la cantera vacía
Un NPC habla de una zona donde “ya no se encuentra piedra buena”. El mapa señala una referencia aproximada, no coordenada exacta. El jugador puede inspeccionar, confirmar que es agotamiento, engaño o una amenaza; los datos del mundo determinan cuál. Comparte el hallazgo o lo guarda para sí. **Prueba:** el descubrimiento cambia conocimiento/confianza/decisión económica, sin que el NPC tenga diálogo guionizado de éxito.

### C. El taller que deja de producir
Una persona con oficio no puede terminar una tarea porque falta una herramienta/material/ruta. El jugador puede fabricar, enseñar un saber si el sistema lo permite, conseguir material, eliminar un obstáculo o no intervenir. El taller no se arregla instantáneamente al cargar. **Prueba:** la autonomía genera una oportunidad, pero no la resuelve toda antes de que el jugador la vea ni espera pasivamente a que el jugador la rescate.

### D. Un asentamiento en retroceso
La comida o seguridad empeora por condiciones reales; el jugador se entera mediante actividad/diálogo/mapa. Puede aportar recursos, buscar fuente, acompañar a residentes, compartir rumor o mudarse. Si la comunidad finalmente desaparece, quedan identidad/ruinas/conocimiento y consecuencias para rutas. **Prueba:** vulnerabilidad con oportunidad y legibilidad, no una derrota escondida ni un evento impuesto. Depende de Fase 6 y no debe presentarse como disponible hoy.

### E. Dos jugadores, dos relatos
Un jugador descubre un paso seguro y decide compartirlo; el otro encuentra una señal de peligro que no estaba en el mapa. Se organizan para escoltar una ruta o discrepan sobre su riesgo. **Prueba:** conocimiento personal/compartido, persistencia y multijugador crean decisiones cooperativas sin imponer roles, split quest ni marcador compartido omnisciente.

### F. El recurso que vuelve (o no)
Un grupo extrae repetidamente un recurso vegetal/faunístico; hay una señal clara del cambio local y un efecto observable en una actividad de NPC. Abandonar el área permite una recuperación gradual sólo si el modelo previsto la justifica; un mineral no se repone como planta. **Prueba:** el sistema comunica escasez y costes sin convertirse en un temporizador de espera. Depende de integración Fase 7 y validación de stocks; no afirmación actual.

## 10. Riesgos de diseño específicos

### A. “La simulación es la recompensa”
Los jugadores no ven agentes, ticks, registros o una economía correcta. Si el cambio no aparece en el mundo ni abre una decisión, su costo de CPU/desarrollo no paga una experiencia. Exigir una señal jugable por cada nueva complejidad sistémica.

### B. La rutina autónoma vuelve al jugador redundante
Si NPC producen, construyen, enseñan, comercian y resuelven riesgos solos, el jugador es espectador de un simulador. Si hacen todo sólo cuando se les pide, son herramientas y el mundo no vive. El equilibrio requiere que la autonomía mantenga vida y cree contexto, pero que el jugador aporte algo distintivo: exploración, negociación, oficio, decisión, coordinación o asumir riesgo. No se debe crear artificialmente una tarea para mantener ocupado al jugador.

### C. Costes sin agencia
Hambre, mantenimiento, rutas largas, peligro y pérdida offline sólo son interesantes cuando el jugador puede prever, decidir y recuperarse. De lo contrario son impuestos de simulación.

### D. Consecuencias aleatorias interpretadas como causales
Los jugadores atribuyen sentido a eventos (apofenia), pero si todo es azar o la simulación no conserva el estado, la confianza se rompe cuando intentan repetir/explicar. Mantener causas locales, historia y límites de azar.

### E. Opciones falsamente distintas
Si aprender una receta sólo altera una cifra sin cambiar las acciones posibles, la elección no tiene valor. Si cada bioma sólo reskinnea enemigos/recursos, la exploración es cosmética. Asegurar que cada diferencia tiene una affordance/jugada distinta antes de expandir contenido.

### F. Juego abierto que se convierte en grind
Múltiples materiales, niveles de herramienta, viajes repetidos, poblados que exigen mantenimiento y escasez pueden crear bucle de trabajo. D14 evita cambios de balance sin medición, pero la revisión debe incluir costo total de actividad y monotonía, no sólo tasa técnica de producción.

### G. Memoria/reputación sin interfaz legible
Memoria acumulada puede ser técnicamente interesante pero difícil de aprender; reputación global puede aplanar las relaciones. Proyectar en comportamiento observable (trato, diálogo, confianza para ayudar/intercambiar, conocimiento de rumor) y permitir descubrir el motivo.

### H. Mundo persistente como presión social no deseada
En multiplayer asimétrico, jugadores entran en horarios diferentes. Si uno puede consumir/construir/decidir para todos sin registro o reversibilidad, la persistencia genera fricción entre amigos. La autoría y propiedad ya importan en Linde; los cambios compartidos necesitan rastros y expectativas claras.

### I. Peligro orgánico demasiado opaco
Sin escalado de nivel no significa riesgo justo automáticamente. Un lugar puede ser letal antes de que el jugador entienda qué lo hace peligroso. La señal debe preceder y ofrecer una opción; no hace falta mostrar nivel, pero sí permitir leer el territorio.

### J. Falta de novedad humana
Las pruebas de automatización detectan regresiones, no diversión, claridad o “una cosa interesante que contar”. `ESTADO.md` declara falta de playtest humano prolongado. No compensar ese vacío con más complejidad ni usar el hito automático de 15/60 minutos como prueba suficiente.

## 11. Recomendaciones priorizadas por impacto/coste

| Prioridad | Recomendación | Impacto esperado | Coste | Por qué ahora / condición |
|---|---|---:|---:|---|
| 1 | Evaluar los bucles ya implementados mediante sesiones guiadas por situaciones abiertas, no sólo rutas automatizadas | Muy alto | Bajo | Hay una base de sistemas amplia, pero el estado advierte falta de playtest humano prolongado. Medir confusión, repetición, decisión y recuerdo antes de sumar mecánicas. |
| 2 | Asegurar que todo cambio de mundo relevante se percibe y se puede atribuir: actor/lugar/causa visible, interacción o historial breve | Muy alto | Bajo–medio | Convierte persistencia invisible en relato. Reutilizar HUD, diálogo, mapa y eventos disponibles; no crear otro quest system. |
| 3 | Crear oportunidades a partir de estados reales y locales (déficit, rumor, ruta, oficio, peligro), siempre opcionales | Alto | Bajo–medio | Apoya libertad sin dejar al jugador sin rumbo. Puede comenzar con texto/contexto/consulta; no requiere nueva economía. |
| 4 | Priorizar personajes identificables y consecuencias selectivas por NPC en vez de expandir atributos/cantidad de población | Alto | Medio | Más fácil construir apego a unas pocas personas que leer un censo. Reutilizar nombres, oficios, relaciones, memoria e historia reportados. |
| 5 | Evitar esperas vacías y repetición logística; comprobar si cada viaje ofrece nuevo riesgo, información, decisión o preparación | Alto | Medio | Viaje importa si el contenido se transforma; no hacer caminar sólo para proteger inmersión. Medir ruta conocida vs descubrimiento. |
| 6 | Dar a cada lugar un contraste funcional (uso, material, riesgo, historia o relación), y retirar POI redundantes | Alto | Medio | Calidad y diferenciación > volumen de destinos. Usar registro existente y primeras regiones. |
| 7 | Hacer explícitos costos, compromiso y límites de automatización en tareas comunitarias | Medio–alto | Medio | El jugador debe confiar en que su acción no desaparece ni se repite; prevenir NPC que hacen todo o nada. Encaja con Fase 6, pero no inventar contratos. |
| 8 | Diseñar multijugador con conocimiento personal compartible y registro de cambios, no con objetivos de party obligatorios | Medio–alto | Medio | Aprovecha estado compartido y protege agencia de jugadores con horarios distintos. |
| 9 | Añadir más simulación avanzada (reproducción, migración, política, economía dinámica) | Incierto | Alto | Aplazar hasta que las situaciones actuales demuestren un vacío de experiencia que esa simulación resolvería. |

### Heurística de prioridad

Antes de implementar un sistema, responder: **¿Qué decisión nueva puede tomar el jugador? ¿Qué puede percibir sin leer un log técnico? ¿Qué causa queda persistida? ¿Qué experiencia se arruina si el sistema falla?** Si las respuestas son sólo “el mundo es más realista” o “los NPC tienen más estados”, es una mejora de simulación aún sin caso de juego.

## 12. Cómo evaluar diversión sin diseñar una nueva fase

No se propone secuencia de implementación. Sí conviene evaluar la experiencia actual y cada hipótesis con un protocolo pequeño:

- Observación de jugadores nuevos y recurrentes sin dar instrucciones sobre “lo correcto”.
- Preguntas tras cada tramo: ¿qué quisiste hacer?, ¿qué te indicó que podías?, ¿qué resultado esperabas?, ¿qué cambió?, ¿qué harías después?, ¿qué repetirías menos?
- Registrar acciones, pausas, retornos, abandonos, consultas de ayuda, encuentros y resultados; no inferir diversión sólo de duración.
- Distinguir fallo de juego (no hay señal/acción), fallo de aprendizaje (señal existe pero no se entiende), y preferencia (el jugador vio opción y la rechazó deliberadamente).
- En test de amigos: al menos una sesión cooperativa y una con participantes que no conozcan el diseño; la familiaridad del equipo de desarrollo sesga la claridad.
- Criterio cualitativo básico: al terminar, cada participante puede narrar una situación propia y explicar al menos una decisión y una consecuencia. No hace falta que todos elijan la misma cosa.
- Comparar lo que la simulación dice que ocurrió con lo que el jugador cree que ocurrió. Una gran brecha indica falta de legibilidad o falsa causalidad.

No usar estos resultados para alterar balance por cuenta propia; sirven para proponer cambios y decidir con el equipo.

## 13. Preguntas incómodas para el equipo

1. Si el jugador no se conecta durante varios días, ¿qué pérdida le resulta interesante y qué pérdida se siente como castigo por tener vida fuera del juego?
2. ¿Qué puede hacer el jugador que un NPC no puede sustituir, sin inventar una “elegida” o una campaña obligatoria?
3. ¿Cuántas de las decisiones de un jugador actual sobreviven en el mundo de forma visible al volver?
4. ¿Puede un jugador escoger no comerciar, no fundar, no combatir y aun así tener una actividad significativa? ¿Cuál?
5. Si todos los NPC son autónomos, ¿por qué necesita el mundo a los jugadores? ¿Qué oportunidad ofrece su presencia aparte de acelerar trabajo?
6. ¿Los habitantes son personajes para conocer o agentes para observar? Si son ambas cosas, ¿qué señales comunican identidad sin crear un panel de microgestión?
7. ¿El jugador descubre destinos por curiosidad, o los visita porque una receta bloquea su progreso? ¿Cuál de ambos motores queremos priorizar?
8. ¿Puede empeorar una situación sin culpa del jugador? Si sí, ¿el mundo informa por qué? Si no, ¿la simulación se vuelve un juicio moral sobre toda inacción?
9. ¿Qué cambios en el asentamiento se notarían al mirar una captura antes/después, sin abrir un inventario estadístico?
10. ¿Qué trabajo repetitivo estamos esperando que el jugador tolere porque “así funciona el mundo”? ¿Puede abstraerse sin borrar una decisión?
11. ¿Hay suficiente contenido sistémico para permitir historias o sólo suficiente contenido para repetir una receta/combate con variaciones?
12. ¿Cómo evita el mundo compartido que un amigo borre, use o transforme algo que otro considera propio sin que la regla/autoría sea visible?

## 14. Conclusión

Linde no necesita escoger entre un mundo emergente y una experiencia dirigida. Puede prescindir de campaña y misiones tradicionales, pero necesita una **estructura ligera de oportunidades**, lectura causal y consecuencias perceptibles. La autonomía debe crear situaciones y continuidad; no sustituir al jugador. La persistencia debe hacer que las decisiones importen; no convertir toda ausencia en una sanción. La exploración debe ofrecer una promesa y una sorpresa; no sólo distancia y recursos. Las relaciones deben expresarse en conducta y memoria; no sólo en números.

La recomendación más importante es frenar la expansión de simulación hasta comprobar el ciclo jugador-sistema con situaciones reales, porque la evidencia disponible describe mucha infraestructura y test automatizado, pero también reconoce falta de playtest humano prolongado. Si jugadores pueden contar historias de decisiones propias, ver su huella y encontrar un motivo nuevo para actuar sin que el juego se los ordene, la visión empieza a traducirse en juego. Si sólo pueden enumerar sistemas, estados y recetas, el mundo está vivo técnicamente pero aún no está vivo para ellos.

## Fuentes externas consultadas

1. RimWorld, presentación oficial: https://rimworldgame.com/ — relato emergente por eventos; lenguaje promocional, no especificación interna.
2. Game Developer, entrevista sobre Dwarf Fortress y autonomía del jugador: https://www.gamedeveloper.com/design/q-a-dissecting-the-development-of-i-dwarf-fortress-i-with-creator-tarn-adams
3. Game Developer, Tarn Adams sobre simulación, interés y sorpresa consistente: https://www.gamedeveloper.com/programming/how-tarn-adams-upgraded-and-optimized-dwarf-fortress-for-its-official-steam-release
4. Rock Paper Shotgun, entrevista con Tynan Sylvester sobre personajes y diseño de RimWorld: https://www.rockpapershotgun.com/how-rimworld-generates-great-stories
5. Game Developer, análisis de agencia, cadenas de eventos y storytelling emergente: https://www.gamedeveloper.com/design/rimworld-dwarf-fortress-and-procedurally-generated-story-telling
6. Lo-Fi Games, “Quests? Quests!?!”: https://lofigames.com/quests-quests/ — postura de diseño de Kenshi (fuente primaria histórica).
7. Rock Paper Shotgun, diseño de mundo de Kenshi: https://www.rockpapershotgun.com/how-kenshis-world-is-designed-not-to-care-about-you
8. The Spieler, crítica del sandbox sin dirección de Kenshi: https://tripharrison.substack.com/p/the-deconstructed-rpg — opinión crítica, no evaluación universal.
9. TaleWorlds, blog oficial sobre narrativa emergente de Bannerlord: https://www.taleworlds.com/en/Games/Bannerlord/Blog/24
10. Game Rant, entrevista con Iron Gate sobre Mistlands y diferencia de biomas: https://gamerant.com/valheim-interview-the-mistlands-creation-design-process/
11. Rock Paper Shotgun, entrevista sobre portales y exploración física de Valheim: https://www.rockpapershotgun.com/why-valheim-wants-to-stop-you-using-portals
12. Project Zomboid, página oficial de Steam: https://store.steampowered.com/app/108600/ — descripción del juego y su objetivo de NPC/meta-game; distinguir características actuales de planes publicados.
13. PZwiki, explicación comunitaria del meta-game: https://pzwiki.net/wiki/Frequently_Asked_Questions — fuente secundaria.

> **Límites:** las referencias son análisis/entrevistas y descripciones de juego, no auditorías actuales de código. No se infiere que las implementaciones privadas funcionen de una manera concreta más allá de lo explícitamente citado. No se hizo búsqueda de nuevas dependencias ni se propone copiar código/activos.
