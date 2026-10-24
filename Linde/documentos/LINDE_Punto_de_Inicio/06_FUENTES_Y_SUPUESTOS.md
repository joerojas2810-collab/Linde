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
