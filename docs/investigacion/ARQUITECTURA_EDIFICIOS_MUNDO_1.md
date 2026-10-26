# Construcciones y catálogo de edificios de Linde

Fecha: 26/10/2026. **Diagnóstico y propuesta; no es una decisión aprobada ni una implementación.** La última precisión del usuario prioriza un catálogo limitado de edificios completos y funcionales, reemplazando la propuesta anterior de construcción libre por piezas. Se pausa la ampliación de asentamientos de Fase 5 hasta resolver esta arquitectura. No se interviene en cuentas/autenticación ni se inicia Fase 6.

## Conclusión

Recomiendo **edificios de catálogo para el jugador y los NPC, compuestos internamente por elementos reales del mundo**. Cada edificio tiene identidad, acceso, interior y uso reconocibles. Elegir un edificio o un futuro plano produce la misma construcción persistente; sus mesas, camas y cofres siguen siendo los objetos existentes. La unidad de interacción y encargo es el edificio, sin exigir una paleta de paredes al jugador.

El problema actual tiene dos causas: no existe una identidad común de edificio para todas las construcciones y los puestos regionales usados en Fase 5a no contienen una vivienda completa. No se resuelve añadiendo un sprite de fachada sobre las camas.

## 1. Qué hay realmente

| Representación | Geometría y funcionamiento comprobados en código | Límite |
|---|---|---|
| Casa fija del Valle | `Mundo.CASA` define un rectángulo 8×7; borde de paredes, suelo interior y acceso sur `PUERTA_C`. Comparte coordenadas, colisiones y navegación con el exterior. Arte por capas de interior, fachada, puerta y tejado | Caso especial por constantes; sus paredes son terreno fijo, no piezas retirables de `constr`. Fachada y techo se ocultan con reglas exclusivas para esa casa |
| Viviendas individuales/comunitarias de NPC | `Habitat` reserva parcelas y accesos. `Sociedad` ejecuta plantillas por piezas relativas a una cama. Muros, puerta, mesa/camas y techos son objetos persistentes; se admiten obras incompletas/bloqueadas y contribuciones compatibles | Se planifican en el Valle. La cama es el ancla e identidad implícita. El plano individual es diminuto; no es un sistema general de habitaciones |
| Puestos regionales / comunidades de Fase 5a | `Asentamientos.PIEZAS`: dos camas de huésped, dos campos, cofre y puesto; solo se techan las dos camas | **No hay muros ni puerta, ni habitación delimitada.** La captura muestra esa representación. Su economía resumida no convierte esas camas en una casa |

Fuentes: [mundo.gd](../../Linde/cenital/scripts/mundo.gd) (`CASA`, `_init`, `bloquea`); [habitat.gd](../../Linde/cenital/scripts/habitat.gd) (`admisible`, `reservar`); [sociedad.gd](../../Linde/cenital/scripts/sociedad.gd) (`_celdas_casa`, `casa_completa`, `_casa`); [asentamientos.gd](../../Linde/cenital/scripts/asentamientos.gd) (`PIEZAS`, `crear`).

### Colisiones, suelos y accesibilidad

La cuadrícula es de 16 píxeles y la caja de pies del jugador mide 10×6. Muros, camas, mesas, horno y cofres ocupan celdas sólidas. `Mundo.mover/caja_libre` permite deslizar por ejes; `camino/alcanzables` utiliza cuatro vecinos. Es una base adecuada para interiores continuos; no hacen falta escenas interiores separadas ni teletransporte.

`estado.constr[celda]` permite **una construcción por celda**. Un suelo construido también ocupa esa entrada: hoy no se puede colocar normalmente una cama/mesa encima de ese suelo. El suelo de terreno (`T.SUELO`) sí admite mobiliario. El techo ya tiene una capa separada (`estado.techos`). El modelo de capas está incompleto para un edificio genérico.

La puerta construible tiene `bloquea:false`: su apariencia abierta/cerrada depende del jugador local y **no cambia la colisión**. No hay aquí una cerradura física de puertas. Los candados existentes pertenecen a cofres. Reutilizar la puerta actual no significa disponer de un sistema de accesos privados a habitaciones.

`casa_completa()` comprueba piezas previstas por una plantilla; no valida por sí misma una habitación cerrada, un recorrido entrada→mobiliario ni cualquier distribución alternativa. Los validadores de construcción sí comprueban rutas, pero no comparten un contrato general por edificio. En el exterior `construccion_segura` usa conectividad local; la construcción de NPC y `Habitat` siguen ligados al pueblo inicial.

### Techos y claridad visual

La casa fija tiene interior y fachada específicos de 160×160. Su tejado desaparece cuando el jugador está en `Mundo.CASA`; la fachada se atenúa. Los demás techos siguen otro algoritmo: se buscan componentes de celdas contiguas y se dibuja **el rectángulo envolvente de cada componente**, con expansión visual hacia arriba/lados. Esto puede cubrir huecos de una forma en L y unir cubiertas vecinas que no deberían ser un mismo edificio. No consulta límites de parcela, paredes o dueño.

Un grupo modular se hace casi transparente si el jugador pisa una celda techada o está junto a una puerta también techada que conecte con el grupo. No es una detección general de interior. El puesto tiene además su propio pequeño techo dibujado en el sprite. Por eso geometría habitable, apariencia y ocultación pueden divergir.

Fuentes: [escena.gd](../../Linde/cenital/scripts/escena.gd) (`_draw`, `_dibujar_techos`, `_dibujar_constr`); [mundo_arte.gd](../../Linde/cenital/scripts/mundo_arte.gd) (`constr`, `casa_interior`, `casa_fachada`, `casa_tejado`).

### Propiedad, objetos y NPC

Las piezas guardan `dueno` y `propia`; retirar depende del dueño. Los techos guardan dueño por celda. Los cofres mantienen inventario, candado y permisos en `d.cofres`, referenciados por coordenadas; sus operaciones vuelven a validar proximidad y permisos en autoridad. Los depósitos de grupos de `Sociedad` son inventarios propios del grupo, no un almacén físico unificado. Un edificio no debe copiarlos ni fusionarlos implícitamente.

Camas fijas, asignaciones de huésped, parcelas y residentes regionales tienen referencias distintas. Los NPC detallados buscan una celda adyacente al objeto para dormir/trabajar; los regionales continúan resumidos. No hace falta materializar población ni resolver 5b para que el edificio tenga un interior transitable por el jugador.

Las viviendas afectan sistemas existentes: descanso (`bono_descanso`), arraigo, camas disponibles y acogida. Además, `Desarrollo.suelo()` cuenta **piezas `suelo`** para técnicas del taller: un suelo solo dibujado como textura no cumple ese requisito. La pantalla llamada «Forja» no demuestra que exista una tercera estación: las estaciones físicas del catálogo son mesa y horno, y `mejorar/engarzar` no exigen un edificio de forja.

Fuentes: [juego.gd](../../Linde/cenital/scripts/juego.gd) (`construir`, `retirar`, `info_cofre`, `mover_cofre`, `dormir`, `mejorar`); [habitantes.gd](../../Linde/cenital/scripts/habitantes.gd) (`cama`, `_meta`, `paso`); [desarrollo.gd](../../Linde/cenital/scripts/desarrollo.gd) (`suelo`, `puede`); [mundo_vivo.gd](../../Linde/cenital/scripts/mundo_vivo.gd) (`camas_libres_lista`).

## 2. Catálogo necesario según las mecánicas actuales

Propongo **tres familias**, con pocas variantes de capacidad o distribución. No implica colocar las tres en todos los pueblos.

| Familia | Función real existente | Contenido propuesto, sin inventar nuevas mecánicas |
|---|---|---|
| Vivienda | Descanso, cama propia/huésped, residencia y acogida | Interior accesible, camas y posible cofre. Individual/comunitaria como variantes del mismo contrato; distinguir cama del jugador y de NPC |
| Taller | Fabricación, refinado, laminados, técnicas y experimentación | Mesa, horno según variante y superficie real de taller. Horno puede quedar en un anexo abierto si la distribución lo requiere. Son las mismas recetas y estaciones existentes |
| Depósito | Reservas, herramientas, intercambio de objetos y abastecimiento | Cofres reales con permisos existentes. Puede ser inicialmente una sala/anexo del taller o vivienda, sin obligar a fabricar un edificio separado |

**No hacen falta todavía** taberna, mercado, biblioteca, cuartel, hospital, molino o una forja con reglas nuevas: sus funciones específicas no existen o ya se resuelven hablando con NPC y usando mesa/horno. Revestirlas de edificios obligatorios cambiaría progresión/economía sin necesidad.

Los campos deben seguir siendo **parcelas productivas exteriores**. Una granja puede ser una variante de vivienda con huerto, sin introducir simulación agrícola paralela. Un refugio de exploración puede ser una variante pequeña de vivienda; el puesto es el ancla de una comunidad, no un cuarto tipo de casa por sí mismo.

## 3. Alternativas y costo relativo

Estimación cualitativa por sistemas afectados; no son plazos medidos.

| Alternativa | Costo inicial | Consecuencia |
|---|---|---|
| Corregir presentación y hacer unas casas de autor como la del Valle | Bajo–medio: geometría/arte y ocultación local | Resuelve una captura rápidamente, pero mantiene excepciones, propiedad fragmentada y dificultad para construir/reparar/generar edificios generales |
| **Catálogo de plantillas funcionales con piezas internas reales** | **Medio:** identidad, capas mínimas, accesos, render, adaptación de NPC/guardado/red | Aprovecha parcelas, planos y objetos existentes; admite encargos de edificios completos, obras progresivas y modificaciones controladas. Recomendado |
| Edificio monolítico con interior/mobiliario incorporados en un objeto especial | Medio al principio; alto al integrarlo | Parece simple al colocarlo, pero exige resolver otra vez colisiones interiores, inventarios, propiedad, daño y navegación; peor para modificaciones parciales |

La detección automática de cualquier casa dibujada libremente por el jugador deja de ser una prioridad con la nueva dirección. Evitamos invertir en reconocimiento arbitrario de habitaciones, fusiones y divisiones de edificios hasta que sea una necesidad real.

## 4. Arquitectura propuesta

### Unidad persistente y catálogo

Una definición versionada por tipo/variante describe huella física, suelos, paredes, entradas, interior libre, cubierta, mobiliario, puntos de uso y fases de obra. Una instancia estable guarda ID, tipo/versión, transformación, pueblo, dueño y estado de obra. Las coordenadas de sus elementos se resuelven y persisten al colocarla, usando las construcciones/cofres/techos del mundo. Cambiar el catálogo no debe regenerar una casa existente.

El registro de edificio **agrupa y referencia** los objetos, no guarda copias de sus inventarios o NPC. La identidad no debe depender de que siga existiendo una cama concreta. Puede incorporarse como sección del estado compartido del mundo; `Habitat` pasa a reservar la huella de ese catálogo en cualquier poblado. La ubicación exacta del registro debe cerrarse antes de codificar, manteniendo un único servicio de consulta y edición sobre `Mundo`.

Las piezas siguen siendo útiles para NPC, reparación, daños persistidos y ejecución de planos, aunque el menú del jugador ofrezca edificios completos. No habría dos implementaciones: generación, encargo del jugador y obra NPC ejecutan el mismo plano.

### Interior y render

Mantener una planta y coordenadas continuas. Colisiones con los muros y muebles reales; máscara exacta de interior/cubierta y entrada reconocible. Separar suelo construido del ocupante de la celda, conservando techos aparte. Antes de decidir almacenamiento, hay que adaptar también `Desarrollo.suelo`, para no perder ni regalar superficie de taller.

Dibujar la cubierta con su máscara y límite de edificio, sin rellenar automáticamente su rectángulo. Ocultación por observador local al entrar o al necesitar ver el umbral; atenuar también paredes delanteras cuando tapen al personaje/interacciones. El otro cliente puede ver el exterior mientras el primero ve dentro: es presentación local, no un estado global «tejado abierto» replicado. Reutilizar texturas existentes cuando encajen, y pedir recursos adecuados para fachadas/esquinas/transiciones que falten; no esconder colisiones mal resueltas con arte grande.

Para la primera versión, conservar muros en celdas en vez de pasarlos a aristas entre celdas. Las paredes de borde ofrecerían interiores más eficientes, pero cambiarían movimiento, navegación, construcción, arte y validadores a la vez. Tampoco hacen falta varias plantas.

### Uso real y modificaciones

Un edificio no es funcional por tener un sprite o etiqueta: validar recorrido desde el exterior hasta el acceso, área interior transitable y celdas utilizables junto a cada cama, cofre y estación. Usar la misma geometría para jugador y NPC. La validez estructural, el progreso de obra y los servicios disponibles deben distinguirse: una mesa real puede seguir existiendo aunque se haya retirado una teja. Cualquier cambio en bonos, requisitos o tiempos se decide aparte.

No exponer construcción libre por piezas como flujo principal. Proponer operaciones completas o limitadas: construir, reparar, cambiar variante/ampliar y retirar. Si falta una parte, persistirla como falta y recalcular el estado; nunca reinstalarla al cargar. Una retirada completa debe conservar o bloquear inventarios no vacíos y ocupantes según una política explícita, sin borrar cofres o NPC silenciosamente.

### Autoridad, generación y rendimiento

Reutilizar el servidor de intenciones y las diferencias fiables. Validar reserva/huella, ocupación, recursos y accesos antes de confirmar cada operación; ID y revisión del edificio evitan que una edición concurrente se aplique sobre un estado viejo. El cambio de piezas, referencias y consumo debe ser coherente para todos. En una obra progresiva, cada paso conserva el mismo contrato; no gastar el costo completo y volver a gastarlo por pieza.

La generación elige plantilla y posición mediante semilla/coordenadas/versiones, reserva el solar y conecta **la entrada del edificio** a la ruta del pueblo. Un solar no válido se rechaza, no se fuerza sobre agua u objetos. Las decisiones resueltas se guardan; descargar regiones solo elimina caché. Si una casa cruza regiones, conserva un único ID y todos sus elementos en coordenadas globales.

Calcular geometría/servicios al colocar o modificar el edificio y mantener caché con invalidación local; no buscar todas las habitaciones o recorrer todos los tejados del mundo cada fotograma. No se necesita un motor de construcción nuevo, ECS, interiores instanciados o una reescritura de la población.

## 5. Decisiones antes de multiplicar asentamientos

1. **Catálogo:** confirmar las tres familias propuestas, variantes iniciales y qué puede quedar como anexo; evitar edificios obligatorios por comodidad de presentación.
2. **Contrato espacial:** una planta, muros por celda, suelos/ocupantes/techo separados, máscara exacta de interior y puntos de acceso/uso. Fijar dimensiones mediante prueba visual y recorrido, no solo conteo de camas.
3. **Edificio terminado y obra:** edificio completo como encargo para ambos actores; resolver si el jugador lo coloca terminado o lo construye progresivamente, y qué modificaciones controladas se admiten. Los futuros planos deben usar el mismo catálogo.
4. **Puertas y propiedad:** puerta transitable con animación automática al inicio o puerta física con estado autoritativo. Recomiendo la primera inicialmente, con acceso público coherente; las puertas con llave son un cambio adicional. Dueño del edificio, residente y permisos de cada cofre deben ser conceptos distintos, sin cambios de cuentas/autenticación.
5. **Persistencia:** registro estable, estado resuelto y versión; edición parcial, demolición, contenido/ocupantes y qué hacer con las construcciones previas. El proyecto permite no migrar partidas antiguas, pero eso no exime de conservar edificios al guardar/cargar dentro de una revisión.
6. **Economía y progresión:** reutilizar precios unitarios no garantiza el mismo costo total al aumentar paredes/superficie. Medir y decidir costo total, tiempos, superficie para técnicas y capacidad de acogida antes de sustituir viviendas o estaciones existentes. No se proponen números nuevos.

## 6. Primer paso recomendado si se aprueba

Un único edificio de vivienda de catálogo, con puerta sur visible, interior continuo, muebles reales y cubierta que se oculta correctamente. Validarlo con jugador y un NPC, guardar/cargar, dos clientes situados dentro/fuera, retirada/reparación de una parte y una ubicación que cruce regiones. Después una variante de taller con las recetas y superficie existentes. Solo entonces adaptar la génesis de asentamientos, sin multiplicar comunidades para probar edificios todavía ambiguos.

Criterios de aceptación: acceso evidente al verlo, entrar/circular/salir con movimiento normal, llegar al lado de cada objeto de uso, no quedar atrapado por una edición, cubrir solo las celdas correctas, identidad/objetos intactos tras descarga y reinicio, mismo estado físico entre clientes y ocultación visual independiente. No se ha implementado este paso.

## Verificación y límites de esta revisión

Lectura directa de scripts, plantillas JSON, pruebas vigentes y capturas de Fase 5a. No existía `graphify-out/graph.json`; no se construyó un grafo general para esta auditoría acotada. La batería ya ejecutada de Fase 5 incluye `prueba_casas` (13 PASS), `prueba_casas_arraigo` (3 PASS) y crecimiento/red. Esas pruebas validan sus contratos actuales; **no prueban** el catálogo propuesto ni resuelven claridad visual o una habitación arbitraria. La revisión arquitectónica no cambió scripts de juego ni ejecutó otra batería. El código de Fase 5a implementado antes de esta solicitud queda separado de esta propuesta.
