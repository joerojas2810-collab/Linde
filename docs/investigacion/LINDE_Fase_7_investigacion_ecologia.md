# Linde — Investigación inicial de Fase 7: ecología, biomas y peligros

**Fecha:** 26-10-2026 · **Objeto:** investigación y alternativas, no especificación aprobada ni implementación.  
**Fuente de verdad de Linde:** adjuntos `ESTADO.md`, `DECISIONES.md`, `VISION_MUNDO_1.md`, `PLAN_MUNDO_1.md`.  
**Regla de lectura:** donde el adjunto declara «implementado/verificado» se informa como estado registrado, no como nueva inspección de código. No se tuvo acceso al repositorio de Linde en esta conversación. Las rutas/funciones internas de Linde requieren confirmar contra el checkout actual antes de diseñar cambios.

## 1. Síntesis ejecutiva

La dirección ya decidida para Linde favorece una ecología **causal, local y legible**, no una tabla de dificultad por nivel ni un sistema de aparición de enemigos alrededor de cada jugador. La dificultad debe surgir del hábitat, especie, recursos, condiciones, asentamientos/caminos y acontecimientos. El relieve es estable; la vida, la explotación y la civilización cambian. La simulación lejana debe ser resumida y los valores de balance no deben alterarse sin medición y aprobación.

La oportunidad técnica más fuerte es extender lo reportado como existente en `ESTADO.md`: generación determinista de fauna por región, datos de especies, bajas/heridas persistentes, biomas, diferencias del terreno, registros persistentes de lugares/caminos y asentamientos con producción resumida. Pero el documento de estado también dice expresamente que no hay simulación ecológica lejana, que la fauna está casi uniformemente distribuida, que falta señalización previa, que no hay perfiles de hábitat/actividad y que el atasco de fauna está medido. Por eso la propuesta de menor riesgo es **subir primero de “una criatura por región elegible” a presión ecológica por hábitat/área, manteniendo agentes individuales cerca de jugadores**, y no simular cada árbol/animal del mundo.

**No hay valores de balance propuestos aquí.** La única cifra cuantitativa que se conserva como antecedente es el dato documentado de estado: fauna exterior de cinco criaturas, aparición determinista, techo de 24; «una criatura por región elegible (85 % de regiones)», densidad casi uniforme; pruebas de fauna registradas: 31; atasco en escenario sintético: 31 % regreso y 14 % persecución. Esos porcentajes se citan como medidas históricas reportadas, no como reproducción independiente ni como valores de objetivo de Fase 7.

## 2. Estado actual relevante según adjuntos

### Ya existe o está reportado como implementado

| Mecanismo | Evidencia en `ESTADO.md` / visión | Lectura prudente para Fase 7 |
|---|---|---|
| Terreno exterior por regiones, generado por semilla; caché acotada y diferencias persistentes | ESTADO §2, “Exterior por regiones”; PLAN §2.1 | No hace falta proponer otro generador base. Confirmar en el repo versión, límites, API de carga y persistencia de cada entidad. |
| Cinco criaturas exteriores y aparición determinista | ESTADO §2, “Fauna regional”; PLAN §2.6 | Hay un sistema sobre el que extender; no asumir que cada criatura tiene ciclo de vida completo. |
| `Fauna.plan_region` y reglas de fauna en datos; bajas/heridas persistentes; techo de 24 | PLAN §2.6; ESTADO historial enlazado | Buen punto de extensión reportado. Falta inspeccionar algoritmo, hash/streams, catálogo, contrato de persistencia y si el límite es global o por ámbito. |
| Biomas en terreno y arte de biomas | ESTADO §2, “Arte de biomas y fase 7” | Verificar qué significa “bioma” mecánicamente: atributo de terreno, reglas de recursos y/o sólo visual. No afirmar que hoy hay biomas ecológicos completos. |
| Recolección/extracción, cultivos, caminos por pisadas, construcción y diferencias persistentes | ESTADO §§2, 3d–3j; PLAN §2.4 | Pueden ser señales de presión humana y modificar hábitat, pero la causalidad ecológica no está documentada como implementada. |
| Asentamientos regionales con producción resumida persistente y dos comunidades preexistentes | ESTADO §§3h–3j; PLAN §2.7 | Fuente potencial de demanda de alimento, madera, espacio y seguridad. No existe transición resumido↔detallado (5b aplazada), ni fundación/decadencia autónomas de Fase 6. |
| Registro compartido de lugares/caminos y caminos persistentes; generación controlada separada de carga | ESTADO §3g | Permite anclar guaridas, zonas de riesgo y señales con identidad persistente, si se decide. |
| Aparición en poblado, con validación y regla temporal de 1e | ESTADO §3d y `DECISIONES` M1-P/C1 | En el núcleo poblado se evita generar slimes en radio 12 alrededor de centros de poblado al generar; no es invulnerabilidad: una amenaza puede perseguir y entrar. Política de aparición segura es provisional y se midió. No cambiarla indirectamente sin repetir pruebas. |
| Mapa personal, rumor e intercambio con NPC; pistas opcionales | ESTADO §§3e–3f | Reutilizable para avisos ambientales y rumores, sin revelar automáticamente la verdad del mundo. Confirmar formato/datos de pistas antes de integrarlo con ecología. |
| Servidor autoritativo, guardado versionado y replicación | ESTADO §§1–2 | Las decisiones de aparición, movimiento, muerte, reproducción y deltas ecológicos deben tener una autoridad y un orden inequívocos. |

### Requiere verificación del repositorio antes de diseñar cambios

1. Implementación exacta y contrato de `Fauna.plan_region`, semillas por región, fuentes de RNG, llamada de carga y diferencia entre generar/cargar.
2. Qué representan “5 criaturas exteriores”: especies, arquetipos o entidades; sus hábitats/atributos/estados, reglas de aparición, persistencia de posición, despawn y reproducción.
3. Semántica y alcance del techo de 24, y si criaturas pueden existir fuera del conjunto de regiones activas.
4. Qué persiste de vegetación, recursos recolectables y fauna; si hay regeneración y en qué casos; si cosecha y cultivo se guardan por instancia/celda.
5. Cómo se calcula y etiqueta el bioma; si existen variables ambientales continuas, estaciones, agua u otros microhábitats o sólo categorías de terreno.
6. Algoritmos y frecuencia de movimiento/ataque de fauna; detección, persecución, retorno/atasco, navegación y relación con caminos, construcciones y NPC.
7. Flujo autoritativo de eventos, sincronización de fauna, orden de actualización de usuarios simultáneos y determinismo tras reinicio.
8. Si las comunidades resumidas realizan consumo/extracción de recursos naturales o sólo cambian inventarios/contadores; detalles están declarados en estado, pero ecología de campo no.
9. Cobertura de `prueba_fauna` (31 comprobaciones históricas) y otras pruebas de red/terreno después de los últimos commits; no ejecutar ni dar por repetidos sus resultados.
10. Estado actual de rama: `ESTADO.md` se consolidó con HEAD `8483789`, pero el usuario advierte implícitamente que el documento del repositorio es la fuente; comprobar si hubo commits posteriores.

## 3. Matriz: sistemas, decisiones de alcance y opciones

| Área | Imprescindible para primera ecología jugable | Opcional después | Excesivo para el objetivo actual |
|---|---|---|---|
| Biomas | Perfiles de hábitat por bioma; especies/recursos sólo donde tengan condiciones compatibles; transiciones legibles | Subhábitats por agua, cobertura, estación y perturbación | Modelo climático/hidrológico completo en cada celda y cadenas tróficas con decenas de especies |
| Recursos | Stock finito/persistente por nodo o zona; tasa de recuperación condicionada; cosecha/consumo que reduzca stock | Sucesión secundaria, nutrientes y descanso del suelo resumidos | Regeneración ilimitada por temporizador fijo e independiente de extracción/entorno |
| Fauna | Población abstracta por especie y zona; materializar individuos sólo cerca; hambre/refugio/reproducción/mortalidad a escala simple | Migración entre zonas contiguas, territorialidad y competencia por hábitat | Resolver cada organismo, presa, planta y desplazamiento de toda región mundial en cada tick |
| Peligros | Reglas espaciales/temporales/condicionales; anuncio ligado a amenaza real; amenaza no aparece arbitrariamente junto al jugador | Eventos locales raros, guaridas persistentes y cambios por perturbación | Escalado de vida/daño al nivel del jugador, director que teletransporta amenazas a la cámara |
| Mundo persistente | Eventos/deltas autoritativos; base determinista inmutable + cambios persistentes | Registro de presión ecológica por región y recuperación fuera de línea | Guardar cada paso/posición de cada organismo del mapa entero |
| Efectos sociales/económicos | La escasez de recurso relevante repercute en disponibilidad/actividad ya existente, sin regalías | Sustitución comercial, cambios de oficio, migración/declive de comunidad | Predicción macroeconómica exacta o equilibrio de mercado mundial como prerequisito |
| Rendimiento | Simular resumen lejano; transición clara entre resumen y agentes activos | Actualizar regiones por evento/intervalos de tiempo transcurrido | Continuar ticks de IA individual en todas las regiones descargadas |
| Determinismo | RNG por subsistema/entidad/intervalo y orden estable del servidor; evitar RNG global dependiente de carga | Replays/verificación de hashes por día | Determinismo bit a bit entre arquitecturas como requisito prematuro, salvo que se decida soportarlo |

## 4. Patrones examinados en juegos y modelos

### Dwarf Fortress — potente referencia de mundo, no código reutilizable
- **Qué aporta:** mundo generado con variables geográficas y ambientales; biomas asociados a conjuntos de plantas/animales y a categorías de peligros. Las historias surgen de sistemas que interactúan, no de un escalado de enemigos al personaje.
- **Acceso y licencia:** el juego es propietario/cerrado; no existe código fuente completo verificable de la simulación para reutilizar. Los repositorios de interfaz/SDL o utilidades de terceros no son la lógica ecológica del juego. El wiki oficial es documentación comunitaria, no fuente del código.
- **Conclusión para Linde:** **REFERENCIA DE DISEÑO**, no código ni datos. Adoptar la idea de “bioma como paquete coherente de posibilidades” y de procesos de mundo que producen historia, pero no copiar raws/arte ni presentar fórmulas internas como verificadas.
- **Imprescindible/opcional/excesivo:** bioma con fauna/flora/recursos distintivos, imprescindible; genealogías y simulación histórica profunda, opcional; simular ecología e historia global detallada, excesivo.

### RimWorld — simulación de colonias y presión local, cerrado
- **Qué aporta como referencia:** ecología entendible a escala de mapa/colonia y lectura de problemas por recursos, clima y presión sobre habitantes. El diseño muestra que un modelo limitado y local puede crear consecuencias jugables sin ecosistema mundial científico.
- **Código/licencia/versionado:** código propietario; no se verificó source abierto para las reglas internas. Mods públicos son obras separadas, no prueba del código base.
- **Conclusión:** **REFERENCIA DE DISEÑO** únicamente. No copiar código ni tratar explicaciones de wiki/mod como descripción exhaustiva del motor.
- **Riesgo de trasplante:** su mundo de colonia, ritmo de eventos y condiciones de fracaso no corresponden a un servidor persistente compartido con habitantes autónomos; ataques “storyteller” pueden sentirse como director arbitrario en Linde si se imitan literalmente.

### Terraria / tModLoader — reglas de spawn contextuales y autoría server-side
- Juego base Terraria es propietario; el código completo de generación/spawn no se considera fuente abierta. tModLoader sí publica código/herramientas MIT, pero no concede derechos sobre Terraria.
- Fuente verificable de API: [`tModLoader/tModLoader`](https://github.com/tModLoader/tModLoader), snapshot `c76abfb972fc1f4ac1da84023647523ff905289b` (24-10-2026; licencia del proyecto tModLoader MIT). Archivos y docs: [Basic NPC Spawning](https://github.com/tModLoader/tModLoader/wiki/Basic-NPC-Spawning), [`NPCSpawnInfo.cs`](https://github.com/tModLoader/tModLoader/blob/c76abfb972fc1f4ac1da84023647523ff905289b/patches/tModLoader/Terraria.ModLoader/NPCSpawnInfo.cs), [SpawnCondition](https://docs.tmodloader.net/docs/stable/class_spawn_condition.html).
- Mecanismo documentado: el proceso primero elige posición de spawn y luego consulta qué tipos son elegibles; condición recibe contexto de jugador/posición/tiles/hora/bioma. La documentación señala que en multiplayer la decisión se ejecuta en servidor; `SpawnCondition` agrupa predicados reutilizables. Esto es un **filtro contextual por oportunidad de spawn**, no un modelo de población ecológica de stock y reproducción.
- Dependencias/lenguaje: C# y API tModLoader; no es compatible directamente con Godot/GDScript. Código MIT de tModLoader puede reutilizarse bajo sus términos, pero no se debe extraer código propietario de Terraria.
- Aplicación: pensar una elegibilidad declarativa por especie: hábitat válido + tiempo/condición + presión/población existente + exclusiones (poblado/amenaza próxima). Para Linde evitar el patrón vanilla de oportunidades de spawn ligadas a cada jugador cuando cree población ilimitada local.
- Clasificación: **PORTAR ALGORITMO** de filtros; **REFERENCIA DE DISEÑO** de autoría server-side; no reutilizar contenido Terraria.

### Don't Starve / Don't Starve Together — temporadas, hitos ecológicos y señales
- Código del juego cerrado; no hay fuente de simulación pública para auditar. Las wikis documentan resultados observables, no la implementación interna.
- Referencias de diseño consultadas: [No-Eyed Deer](https://dontstarve.wiki.gg/wiki/No-Eyed_Deer) y [seasons/world](https://dontstarve.wiki.gg/wiki/Seasons/World). Se documentan rebaños estacionales localizados, migración y relación con un emplazamiento/hito (stash); temporización estacional y señales de amenazas grandes.
- Aplicación: que una estación cambie qué especies están activas o dónde se encuentran; presagios ambientales previos a una amenaza; criatura/hito puede persistir por temporada y no aparecer/desaparecer como recompensa del jugador. Para Linde, primero limitar a calendario/estación sólo si el reloj y las reglas de mundo ya lo sostienen.
- Riesgo: muchos eventos de DST se aproximan automáticamente a jugadores o bases y son deliberadamente dramáticos; copiarlos literalmente contradice la exigencia de que fauna no aparezca arbitrariamente para atacar.
- Clasificación: **REFERENCIA DE DISEÑO**. No código/datos.

### Songs of Syx — fauna como recurso natural y domesticación separada
- Código propietario. Algunos builds distribuyen archivos de fuentes Java o se pueden inspeccionar mediante herramientas, pero eso no es una licencia abierta verificable para reutilización. No se inspeccionó una fuente del juego con permiso claro.
- Wiki de juego consultada: [Animals](https://songsofsyx.com/wiki/index.php/Animals), [World](https://songsofsyx.com/wiki/index.php/World), [Pasture](https://songsofsyx.com/wiki/index.php/Pasture). Documenta animales naturales ligados al clima, caza que puede fallar y pastoreo/reproducción en cautiverio como mecanismos distintos; animales silvestres pueden reproducirse.
- Aplicación: separar “cosecha de población silvestre” de “producción de ganado”, cada una con capacidad y condiciones propias; caza no debería ser una fuente infinita renovada por jugador. La domesticación puede desacoplar economía de la fauna silvestre.
- Riesgo: el wiki puede corresponder a versiones distintas, por eso no se transportan tasas ni fórmulas. Caza y población de un city builder no modelan las necesidades de fauna del RPG.
- Clasificación: **REFERENCIA DE DISEÑO**, no código/datos.

### NetLogo Wolf Sheep Predation — ejemplo pedagógico concreto, no balance listo para juego
- Modelo de Uri Wilensky (1997), [página del modelo](https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation); el propio modelo indica CC BY-NC-SA 3.0 para el modelo. El software NetLogo es GPL (licencia independiente). La versión disponible de la página no es un commit de un repositorio, por lo que se fija como modelo identificado por nombre/autor/año, no se inventa hash.
- Algoritmo documentado: agentes oveja/lobo y parches de pasto; energía baja por movimiento, alimento repone energía, reproducción probabilística, muerte por energía, y el pasto comido espera un contador fijo antes de rebrotar. La variante sin pasto produce dinámicas inestables; el modelo lo reconoce explícitamente. El modelo sirve para mostrar que si se da alimento “infinito” a herbívoros pueden fluctuar poblaciones sin equilibrio ecológico.
- Alternativa reproducible en código Python: modelo Mesa `Wolf-Sheep Predation`, [docs y archivos](https://mesa.readthedocs.io/stable/examples/advanced/wolf_sheep.html), repo [Mesa](https://github.com/mesa/mesa), HEAD consultado `7f6907859879d59d3e73757f15be9e1882dc4a52` (26-10-2026). La documentación enumera `wolf_sheep/agents.py`, `model.py`, `scheduler.py`; mecanismo individual simple con energía, hambre, movimiento y reproducción. Mesa es framework Python (no Godot) y su ejemplo es de referencia/experimento, no arquitectura de producción.
- Dependencias: NetLogo (Java/Scala) o Python/Mesa; no copiar dependencias al juego. La licencia CC BY-NC-SA del modelo implica atribución, no comercial y compartir igual para adaptaciones distribuidas; juego privado entre amigos no obliga a excluir, pero documentar origen y alcance legal.
- Clasificación: **PORTAR ALGORITMO** de contabilidad energética/limitación de recurso, no números; **REFERENCIA DE DISEÑO** para experimentos aislados. No copiar probabilidades/tasas ni asumir que el equilibrio emerge automáticamente.

### Protocolo ODD — para especificar el modelo sin sobrecomplicarlo
- Grimm et al. 2020, [ODD protocol update](https://bio.uib.no/te/papers/Grimm_2020_The_ODD_protocol_for_describing_agent-based_and_other_simulation_models.pdf) y [checklist suplementaria](https://www.jasss.org/23/2/7/S1-ODD.pdf). No es una licencia de código ni implementación.
- ODD estructura la descripción como propósito/patrones, entidades/variables/escalas, proceso/orden, conceptos de diseño, inicialización, entradas y submodelos. Relevante porque obliga a declarar qué patrón debe explicar el modelo y con qué escala/orden, no sólo añadir IA.
- Aplicación: cada mini-simulación ecológica de Linde debe documentar especies/recursos, región/tiempo, eventos, agregación, orden autoritativo, decisiones de RNG y patrones de evaluación. Clasificación: **REFERENCIA DE DISEÑO**.

## 5. Recomendación técnica por área

### 5.1 Biomas, recursos, flora y fauna

**Propuesta:** cada bioma no es sólo una textura, sino un conjunto de datos con (a) recursos geológicos/vegetales posibles, (b) especies y fases de vida compatibles, (c) condiciones de agua/cobertura/estación, (d) vulnerabilidad/recuperación por presión humana y (e) señales ambientales. El código consulta estos perfiles, pero no necesita una taxonomía científica real.

- **Mínimo:** perfiles de hábitat por bioma en datos; especies candidatas con requisitos y exclusiones; recursos explotables con stock persistente; transiciones visuales/ecológicas consistentes.
- **Opcional:** microhábitat (ribera, claro, cueva), estación local, sucesión de plantas tras abandono, competencia entre recursos por espacio.
- **Excesivo:** simular suelo, clima, nutrientes, polinización y ciclos de agua en cada celda desde el primer paso.
- **Datos necesarios a verificar:** la distinción bioma visual/mecánico; naturaleza y estatus de fauna; condiciones del generador; cómo `reglas_v1.json` entra en huella de reglas; formato de los recursos existentes.

### 5.2 Regeneración sin infinitud artificial

Distinguir cuatro categorías antes de definir reglas:
1. **No renovable en escala jugable:** minerales/depósitos de veta; extracción reduce el stock y no se repone sin fuente geológica que lo justifique.
2. **Renovable lenta:** madera, plantas perennes, poblaciones de animales; crecimiento/reproducción bajo hábitat, presión y capacidad máximos.
3. **Recurso estacional:** frutos, hierbas, migración; availability changes by calendar/weather, not arbitrary respawn at player radius.
4. **Producción domesticada:** cultivos/ganado controlados por población/trabajo, semilla/stock, espacio, agua y alimento; no regeneración silvestre.

Regla conceptual propuesta: extracción causa una reducción del stock o de la capacidad; recuperación sólo ocurre mediante proceso ecológico sujeto a condición ambiental, tiempo y techo de soporte del sitio. Si la presión excede recuperación, el área se degrada o la población cae. Si se abandona, puede recuperarse gradualmente pero sin crear riqueza instantánea. En el primer alcance, el estado agregado por región puede ser suficiente: capacidad, stock disponible, extracción/daño acumulado, último momento simulado y tendencia. No fijar tasas sin medir escala de tiempo real del mundo.

**Casos emergentes:** sobrecaza de una especie cerca de un pueblo reduce carne y piel; hogares cambian dieta/comercio con lo que haya, cazadores recorren más; herbívoros se alejan a un corredor vecino; depredador local disminuye más tarde por falta de presa. Tala intensiva reduce cobertura y madera local; aumenta exposición/erosión o altera la ruta de una especie sólo si el modelo incluye esa relación y puede mostrarla.

### 5.3 Fauna, territorialidad y depredador-presa

Usar dos escalas:
- **Lejos:** para cada región y especie, un registro resumido (población/abundancia categorizada, presión, tendencia, hábitat, evento de migración/daño); no objeto por animal. Avance por intervalo de tiempo o por eventos de extracción/estación/perturbación.
- **Cerca/visible:** instancias individuales con id estable, condición/estado y comportamiento de fauna actual; se materializan desde el agregado y al descargarse actualizan el agregado una sola vez. Evitar duplicación o “resurrección” al entrar/salir de región.

Imprescindibles: necesidades simples y finitas por grupo (alimento/refugio), selección de hábitat, dispersión acotada entre regiones adyacentes, reproducción/mortalidad limitadas por capacidad y una regla de depredación que descuente presa real. Territorialidad puede comenzar como preferencia/área de uso por especie, no como mapa detallado de cada individuo. Una depredación lejana se resuelve con transacción de población agregada; no spawn de un depredador a la vista para justificar el resultado.

Opcionales: estación de cría/migración, agrupamiento/rebaños, competencia, enfermedad, legado de individuos nombrados. Excesivo: genética, envejecimiento por individuo y cadena alimentaria completa con IA detallada en regiones descargadas.

**Aparición no arbitraria:** primero se selecciona habitat/localización elegible de la región (no la cámara), luego se materializa sólo si condiciones/stock/capacidad y presupuesto de entidad lo permiten. La cercanía de jugadores decide representación y actividad detallada, no que exista un animal nuevo. El modelo Terraria de contexto sirve como plantilla de filtros, pero su spawn alrededor de jugadores no es adecuado como población natural por sí sola.

### 5.4 Peligros hostiles y naturales

Separar:
- **Peligro basal:** clima/terreno/exposición, riesgos persistentes de lugar.
- **Fauna territorial:** criatura existente que busca alimento/defiende cría/refugio; puede atacar jugador, NPC o estructura según condiciones.
- **Evento de lugar:** guarida, criatura anclada, tormenta/crecida/incendio si existen reglas de mundo que lo sostengan.
- **Ataque dirigido por diseño:** no recomendado como mecanismo de ecología; si existe como acontecimiento, debe tener causa, origen, ruta, señales y estado persistente, nunca nacer arbitrariamente junto a un jugador.

Poblados: la decisión de usuario dice que no son mágicamente seguros; pueden sufrir ataques y desaparecer. La seguridad de aparición es requisito separado: el nuevo jugador no debe entrar junto a un enemigo sin reacción razonable. Las zonas de calma deben ser resultado de reglas ecológicas/de actividad o política de spawn claramente diferenciada, no inmunidad general. La Fase 1e desplaza slimes de la zona núcleo al generar; no impide que entren por persecución.

**Aviso verdadero y justo:** señal (huellas, restos, sonidos, vegetación alterada, NPC evita zona) debe derivar de estado real reciente y tener alcance coherente con información del personaje; no marcadores exactos a través de niebla. Para hazards, mostrar dirección/intensidad antes de daño sólo si el sistema permite una respuesta razonable. No crear una señal del peligro si el peligro ya migró sin dejar rastro histórico legible.

### 5.5 Cambios ecológicos persistentes y consecuencias sociales

Representar perturbaciones como eventos del mundo compartido: tala/cosecha/caza, incendio/tormenta, construcción de vivienda/camino, contaminación si se incluye. Cada evento actualiza stock o presión del área y produce deltas observables, y potencialmente un cambio de actividad de agentes. No reescribir relieve ni hacer que “el bioma cambie” de golpe; geografía estable, civilización/ecosistemas variables (visión).

Cadena mínima de causalidad:
`actividad → extracción/perturbación → cambio de hábitat o stock → desplazamiento/disponibilidad → efecto en oficio, dieta, seguridad o intercambio`.

Las sociedades ya tienen necesidades, producción, trueque, confianza y grupos según ESTADO. La integración prudente es conectar primero disponibilidad real de insumos con actividades económicas existentes, no introducir economía paralela ni modificar recetas/precios. Una comunidad en escasez podría reducir una producción/consumo ya modelado o recurrir a otra fuente si los datos existentes lo permiten. Cambios de riqueza, abandono y fundación son Fase 6, aún no iniciada; la Fase 7 no debe asumirlos implementados.

Ejemplo emergente (hipótesis de prueba, no resultado): extracción persistente de madera junto a una comunidad reduce stock local; sus constructores deben viajar más o comerciar; senderos de ida y vuelta consolidan ruta; más tránsito y menos cobertura desplazan una especie hacia la ribera; la caza allí aumenta el conflicto. Para que emerja de verdad hacen falta todos esos enlaces; no basta narrar el resultado como “ecología”.

### 5.6 Simulación lejana viable

No ejecutar cada agente en todos los lugares. Estado resumido por región/especie y sitio, avance a tiempo de mundo usando saltos de tiempo acotados o procesos por evento. Criterios de transición:
- Al descargar: convertir agentes cercanos a registro agregado conservando población, ubicación aproximada/territorio, heridas relevantes y recursos cargados.
- Mientras lejano: aplicar procesos agregados de alimentación, reproducción, mortalidad, extracción y migración sin producir cambios imposibles; definir orden fijo y resultado determinista.
- Al cargar: materializar hasta un cupo técnico medido desde el agregado, aplicar eventos pendientes, no duplicar individuos ni devolver automáticamente el stock extraído.

Esto se alinea con intención de escala de M1-F5, pero no presupone que exista puente de transición: `ESTADO.md` y `PLAN_MUNDO_1.md` señalan que 5b está aplazada para residentes y que fauna lejana no se simula. No introducir simultáneamente transición fauna y transición población hasta definir identidad/contabilidad por separado.

### 5.7 Determinismo, compartición y persistencia

La generación inicial determinista no es suficiente: evolución debe conservar resultados. La visión exige mundo generado una vez, crecimiento que no cambia regiones existentes y separar generación controlada de carga simple. Aplicaciones:
- Generación base = función pura de semilla, coordenadas globales y versión del generador.
- Ecología dinámica = eventos/stock persistente y ordenados por el servidor; los clientes no simulan ni generan poblaciones de manera autónoma.
- RNG derivado de clave estable por mundo/región/especie/intervalo/evento (recomendación técnica), separado por subsistema para que añadir una planta no cambie movimiento de lobos. Confirmar mecanismo existente en `Fauna.plan_region` antes de definir.
- Las regiones no se “regeneran” al explorar; una ausencia/recuperación es decisión de simulación registrada, no aleatoriedad de carga.
- Persistir estados agregados y eventos en el registro/deltas; replicar sólo cambios necesarios; cuidar tamaño de `mundo_vivo` ya señalado como deuda técnica en ESTADO.
- Orden y resolución ante dos jugadores que cazan/construyen el mismo lugar simultáneamente: una transacción autoritativa debe prevenir contar dos veces la misma presa/stock.

## 6. Alternativas de diseño y trade-offs

### A. Sólo hábitat + spawn condicionado, sin población persistente
Más barato y rápido; reglas de bioma y localización mejoran coherencia, pero la caza no reduce oferta de manera real y la fauna puede sentirse reemplazada. **No recomendado como solución final**, podría ser escalón técnico temporal si el sistema actual es así.

### B. Stock ecológico por región y agentes cercanos (recomendación de investigación)
Equilibra persistencia, coste y conducta visible. Permite agotamiento y recuperación condicionada, desplazamiento entre regiones y depredación agregada. Complejidad principal: transición individual↔agregada, idempotencia, evitar “snap back”. Recomendada para prototipo, en capas.

### C. Individuos persistentes globales
Máxima continuidad y emergencias potenciales; alto coste de CPU, memoria, guardado, navegación, red y validación. No recomendada hasta que B y mediciones demuestren necesidad.

### D. Eventos o director como sustituto de ecología
Barato y dramático, pero pierde causalidad y puede sentirse como spawn hostil dirigido. Sólo como capa opcional de acontecimientos que tengan causa y telegráfico, nunca como sustituto de población.

## 7. Pruebas y mediciones recomendadas (sin asignar valores de balance)

1. **Conservación:** extracción simultánea no duplica/recrea stock; guardado-carga y carga de región conservan el resultado; reinicio no vuelve a sembrar fauna en región ya generada.
2. **Determinismo:** mismo mundo y misma secuencia de eventos, orden de carga distinto produce mismo estado ecológico; distintos eventos cambian sólo áreas/streams afectados.
3. **Ciclo de fauna:** sin alimento, población baja; con alimento/hábitat y presión baja puede recuperarse, pero no superar la capacidad; depredación consume presas; no hay aparición de depredador sin fuente de población.
4. **Migración:** desplazamiento sólo a hábitats compatibles y regiones conectadas; no cruzar barrera imposible ni desaparecer stock a través del borde de mapa.
5. **Agotamiento/recuperación:** zona explotada cambia de manera observable; recuperación requiere tiempo/condición, y no borra la causa/registro de un evento; explotación sostenida puede superar recuperación.
6. **Interacción social:** fauna puede afectar residente, jugador, cultivo o estructura bajo reglas compartidas; actividad económica refleja recursos realmente disponibles y no se crean materiales gratis.
7. **Spawn justo:** medir distancia/tiempo/señal desde aparición hasta detección, persecución y daño, siguiendo pruebas históricas M1-C1 y la necesidad de no enemigo sin reacción; repetir 500 semillas/medición sólo si diseño/algoritmo cambian, no presentarlo como umbral nuevo.
8. **Atascos:** volver a ejecutar escenario P2 sobre fauna y medir tasas actuales, dado el historial 31% regreso/14% persecución atascada. El objetivo del plan propone <5 % para atasco; esto pertenece al plan documentado, no es balance decidido en esta investigación.
9. **Coste:** coste de tick/guardado con región cercana, muchas regiones resumidas, reconstrucción después de días offline y pico al cargar; variar carga por población/entidades; reportar p50/p95/máximo y condiciones de hardware.
10. **Red:** dos clientes cazan/recolectan simultáneamente; servidor reinicia; cliente no autorizado intenta solicitar spawn/daño; réplica sin entidad duplicada.
11. **Patrones longitudinales:** registrar población por especie, stock de recursos, intensidad de extracción, zonas degradadas/recuperadas, asentamientos viables, encuentros peligrosos. No basta que la suite pase: revisar que el comportamiento no colapse a extinción total o abundancia ilimitada en simulaciones largas con semillas múltiples.

La investigación no define ventanas/umbrales de balance; medir en unidades del tiempo real y del reloj del mundo de Linde y pedir aprobación explícita de valores conforme M1-D14.

## 8. Riesgos principales

- **Desfase entre decorado y estado:** rastro sin amenaza real, recurso agotado que sigue dibujado, criatura visible duplicada tras cargar.
- **Recursos infinitos disfrazados:** timer de respawn no condicionado al stock, hábitat y uso; población repuesta sólo por estar jugador cerca.
- **Efectos económicos no intencionados:** tocar tasas cambia progresión aunque se mantengan recetas; medir antes de tocar coste, XP, daño o recompensas.
- **Escalado indirecto:** aumentar densidad o agresividad también modifica balance, incluso sin cambiar estadísticas (M1-D14 lo requiere medir/aprobar).
- **Inestabilidad matemática o “ecosistema de juguete”:** probabilidad de reproducción, energía y ciclos elegidos a ojo generan extinción/oscilaciones. El ejemplo Wolf-Sheep muestra mecanismos didácticos, no una parametrización validada para Linde.
- **Migración de agregados incorrecta:** perder memoria/recursos o duplicar animales al cargar. Separar identidad de criatura activa y población abstracta; registrar transiciones atómicas.
- **Determinismo dependiente de orden:** RNG global compartido o iteración de diccionario inestable modifica el mundo al explorar/cargar otro bioma.
- **Multijugador y privacidad:** estado real de fauna/amenazas no debería revelarse al cliente como si el jugador lo conociera; distinción entre verdad, conocimiento, presentación ya establecida en Mapa 2.
- **Rendimiento por simulación offline:** avance de tiempo desde última sesión puede intentar procesar miles de ticks; resolver por evento/salto y limitar trabajo con equivalencia comprobada.
- **Fase 6 mezclada con Fase 7:** fundación autónoma, abandono y transición de pueblos no iniciados deben quedar como dependencias futuras, no prerequisito de primer prototipo ecológico.

## 9. Secuencia de investigación/prototipo recomendada

1. **Auditar repo sin cambios** con paths concretos de fauna/biomas/recursos/generación/guardado/servidor/pruebas; confirmar estado frente a `ESTADO.md` y establecer qué significa “una criatura por región”.
2. **Documentar un ODD mínimo** para una especie de presa, una especie hostil, un recurso vegetal y un recurso no renovable: escalas, estado, procesos, orden y patrones de aceptación. Elegir ejemplos del contenido de Linde después de leer datos.
3. **Ajustar perfiles de hábitat en datos** sin tocar estadísticas: consistencia de bioma y aparición. Repetir generación determinista y test actual de fauna.
4. **Medir exposición y señales** en primer trayecto/mundo inicial; representar rastro/peligro desde estado real. Mantener regla de aparición y no mover amenazas cerca del jugador.
5. **Experimento de stock agregado para una especie/recurso** en una región, con recolección/depredación, tope ecológico y persistencia; primero prueba headless aislada, luego mundo real. No asumir que una micro-simulación sustituye el comportamiento de NPC.
6. **Puente cercano/lejos** sólo si el prototipo necesita individuos que migren; definir reglas de identidad/contabilidad y compare exact equivalence before/after regional unload/reload.
7. **Conectar efectos económicos/sociales** después de evidenciar recurso limitante; usar necesidades y sistemas de `Asentamientos` existentes, sin comercio ni balance nuevos innecesarios.
8. **Evaluar semillas y escalas** y pedir aprobación humana antes de cerrar valores. No convertir objetivos históricos de plan en decisiones de balance sin aceptación.

## 10. Recomendación final para Linde (no vinculante)

Probar la alternativa B en forma incremental: **hábitats declarativos por bioma + stock y presión resumidos por región + entidades individuales sólo cerca + señales y peligros originados en lugares/condiciones reales**. La primera prueba debe priorizar consistencia de hábitat, persistencia y justicia de avisos, no añadir especies ni subir daño. Mantener depredadores y criaturas peligrosas limitados por hábitat y población/fuente; que la actividad de asentamientos modifique condiciones sin otorgarles seguridad absoluta. Conectar economía sólo cuando un stock limitado se demuestre relevante.

No implementar ahora ecosistema completo, enfermedades, evolución genética, incendios globales, simulación individual offline ni un director de ataques. No tocar valores de daño, XP, botín, tasas de fabricación, consumos o radios sin el proceso de medición y aprobación de M1-D14. La decisión humana pendiente más importante es qué transformación visible cuenta como recuperación/degradación significativa y con qué nivel de abstracción se debe persistir una población silvestre.

## 11. Fuentes y referencias

### Fuentes de Linde (adjuntas; autoridad de proyecto)
- `ESTADO.md` (consolidado 26-10-2026, HEAD considerado `8483789`), especialmente §§1–3 y registros de Mundo 1. **Fuente reportada**, no checkout leído en esta investigación.
- `PLAN_MUNDO_1.md`, §2.6 (auditoría de fauna) y §4 “Fase 7 — Ecología y dificultad territorial”: propone perfiles por bioma, zonas de calma, amenazas ligadas a lugares, rastros, deltas por acontecimientos y arreglo de atasco mediante BFS; aceptación histórica: atasco <5 %, primera ruta sin hostil a menos de R, aviso ≥T; R/T sin definir. Dependencia Fase 4; riesgo medio; cambios de estadísticas prohibidos sin medición.
- `VISION_MUNDO_1.md`: geografía estable/civilización cambiante; dificultad orgánica sin niveles/regiones bloqueadas; peligro legible; mundo persistente compartido y lejanía resumida.
- `DECISIONES.md`: M1-D12, M1-D14, M1-P, M1-C1/C2 y fase 7. Decisiones del usuario prevalecen; valores de prueba no son balance.

### Fuentes externas
- **Terraria tModLoader (herramienta/mod loader)**, repo y licencia: https://github.com/tModLoader/tModLoader (snapshot `c76abfb972fc1f4ac1da84023647523ff905289b`, 24-10-2026); `patches/tModLoader/Terraria.ModLoader/NPCSpawnInfo.cs`; https://github.com/tModLoader/tModLoader/wiki/Basic-NPC-Spawning ; https://docs.tmodloader.net/docs/stable/class_spawn_condition.html. Documentación/API de terceros; código del juego Terraria no abierto.
- **Don't Starve Together**, referencia observable de temporadas y fauna: https://dontstarve.wiki.gg/wiki/No-Eyed_Deer ; https://dontstarve.wiki.gg/wiki/Seasons/World. Wiki comunitaria; código propietario; no fuente primaria de implementación.
- **Songs of Syx**, referencia observable de fauna natural/domesticación: https://songsofsyx.com/wiki/index.php/Animals ; https://songsofsyx.com/wiki/index.php/World ; https://songsofsyx.com/wiki/index.php/Pasture. Wiki, versionado variable; juego propietario.
- **NetLogo Wolf Sheep Predation**, Uri Wilensky 1997: https://ccl.northwestern.edu/netlogo/models/WolfSheepPredation. Modelo descrito por autor, CC BY-NC-SA 3.0; distinguir licencia de NetLogo (GPL) y del modelo.
- **Mesa Wolf-Sheep**, ejemplo y fuentes nombradas: https://mesa.readthedocs.io/stable/examples/advanced/wolf_sheep.html ; repo https://github.com/mesa/mesa (HEAD inspeccionado `7f6907859879d59d3e73757f15be9e1882dc4a52`, 26-10-2026). Python/framework, sólo comparación algorítmica; revisar licencia del repositorio y de cada ejemplo antes de copiar.
- **ODD 2020**, Grimm et al.: https://bio.uib.no/te/papers/Grimm_2020_The_ODD_protocol_for_describing_agent-based_and_other_simulation_models.pdf ; checklist https://www.jasss.org/23/2/7/S1-ODD.pdf. Protocolo metodológico, no código.
- **Dwarf Fortress**: documentación de biomas del [wiki](https://dwarffortresswiki.org/index.php/Biome); juego y código propietario. Referencia de diseño exclusivamente; no ruta/commit de código ecológico porque no es abierto.
- **RimWorld**: juego propietario; no se encontró código fuente abierto oficial de simulación ecológica en las fuentes consultadas. Referencia de diseño solamente; no atribuir implementaciones internas específicas sin fuente primaria.

> **Límites de verificación externa:** no se clonaron/ejecutaron proyectos externos en esta entrega. Se usaron documentos oficiales/repositorios o documentación de proyecto donde disponible y wikis claramente señaladas como secundarias. No se afirman fórmulas internas de Dwarf Fortress, RimWorld, Don't Starve ni Songs of Syx. Cualquier reutilización de código debe volver a comprobar licencia, commit, avisos y archivo concreto en la fase de auditoría del repositorio.
