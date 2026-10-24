# E03 — Selección de mobs dentro de cada familia

Propuesta de selección artística del 24/10/2026; no aprobación de añadir enemigos ni reglas. La familia se llama **Slime** en toda entrega.

## Cuántos diseños hay realmente

El selector de arte confirma **24 identificadores base: 15 diseños de familia/rango (5×3) y 9 jefes de ruta**. Eso no significa 24 especies ni 120 mobs distintos. Los cinco elementos son variantes visuales de un mismo diseño/rango; sus colores o efectos no crean una especie nueva. `stage.ts` genera nombres de familia, prefijo de élite y numerales para repeticiones; esos numerales tampoco identifican diseños nuevos. `characters.ts` guarda familia y bossId, sin un catálogo taxonómico adicional de especies.

Hay más de un mob/diseño dentro de cada familia, pero la diferenciación normal/élite/jefe no es igual de fuerte en todas. Algunas variantes cambian realmente silueta y accesorios; otras son principalmente color o equipamiento. Además, los juegos de arte pintado y pixel pueden reinterpretar al mismo ID de manera importante.

## Elección concreta por familia

| Familia | Diseño y propuesta | Motivo visual / destino |
|---|---|---|
| Slime | **normal: referencia ahora** | El pixel es una gota pequeña y amable; el pintado es una masa ancha con ceño. Preferir simplicidad del pixel y conservar el Slime actual de Linde |
| Slime | élite: reserva | Pintado casi igual al normal; pixel añade puntas laterales. No venderlo como otra especie |
| Slime | jefe: futuro | Corona y dentadura enorme cambian la identidad y silueta; no es reemplazo del común |
| Diablillo | **normal: primera opción futura** | Cuernos, cola y alas reconocibles aun simplificados. Todavía no tiene rol mecánico en Linde |
| Diablillo | élite: reserva | Armadura y cresta/llama; más detalle, sin necesidad de producirlo antes del normal |
| Diablillo | jefe: reserva | Cuerpo robusto y grietas luminosas; sí hay diferenciación, pero requiere espacio de jefe |
| Arpía | **normal: única base futura inicial** | Pintado humanoide y pixel aviar difieren mucho: decidir identidad antes de redibujar; alas vistas desde arriba pendientes |
| Arpía | élite: reserva | Placas/hombreras y penacho; útil si más adelante hacen falta variantes |
| Arpía | jefe: reserva | Corona y cresta grandes; exceso de detalle para el objetivo actual |
| Gólem | **normal: referencia ahora para Guardián** | Roca segmentada y núcleo legibles; encaja con cantera/Guardián sin importar el mob como entidad nueva |
| Gólem | élite: reserva | Cristales/espinas de hombros y placas lo distinguen; candidato para futura evolución visual |
| Gólem | jefe: reserva | Crestas altas y núcleo mayor; no sustituir al Guardián por tamaño o rango automáticamente |
| Espectro | **normal: primera opción futura** | Capucha, ojos y manos son sencillos y reconocibles; no posee rol actual en el catálogo Linde |
| Espectro | élite: reserva | Cuernos/diadema y pechera agregan geometría real, no solo color |
| Espectro | jefe: reserva | Corona alta y capa ornamentada; reservar para una función específica |

**Decisión propuesta para este lote:** usar solo referencias del **Slime normal** y **Gólem normal** al completar actores que ya existen en Linde. El Ciervo y Maren conservan sus propias identidades. Conservar Espectro normal y Diablillo normal como primeros candidatos futuros; no fabricar ni registrar nuevas familias de combate dentro de E03 sin un alcance adicional.

Las 75 variantes pintadas de familia/rango/elemento se revisaron por su primer cuadro de reposo. Agua/fuego/tierra/viento/rayo conservan mayormente forma, accesorios y pose, cambiando materiales, brillos y colores. No se necesitan cinco copias en Linde salvo que una decisión de diseño lo requiera. Algunas entradas tienen archivos de revisión posteriores, por lo que debe resolverse cada ruta con el registro vigente, no construir nombres por intuición.

## Nueve jefes con identidad propia

Todos quedan como **banco futuro**. No son nueve versiones del Guardián ni variantes elementales de los tres actores actuales.

| ID | Diseño pintado observado | Diferencia respecto al pixel / coste de adaptación |
|---|---|---|
| boss_lord_of_flies | Insecto alado coronado, ojos grandes | Pixel insecto azul; conservar anatomía elegida, rediseñar alas cenitales |
| boss_ash_king | Rey acorazado con cetro y capa de fuego | Pixel criatura acorazada más monstruosa; decidir humanoide frente a monstruo |
| boss_eternal_watcher | Vigía encapuchado con bastón ocular | Pixel autómata de ojo central; son identidades incompatibles para copia directa |
| boss_hollow_colossus | Armadura pétrea vacía con interior luminoso | Pixel gólem portal de piedra; referencia de volumen posible, no sustitución automática del Guardián |
| boss_thunder_king | Rey con martillo, corona y capa | Pixel humanoide pétreo azul/dorado; simplificar equipo y elegir materiales |
| boss_mother_hydra | Hidra reptiliana de varias cabezas | Pixel muestra dragón/serpiente de una cabeza en la pose revisada; requiere decidir silueta y orientación |
| boss_withered_queen | Reina vegetal humanoide con cetro | Pixel criatura arbórea más abstracta; no son solo recolores |
| boss_faceless_one | Figura encapuchada roja de cuchillas curvas | Pixel espectro oscuro coronado; elegir cuerpo/armas antes de producir |
| boss_great_devourer | Monstruo bajo de gran boca y caparazón | Pixel masa verde con ojos en tallos; anatomías muy distintas |

El parentesco narrativo entre estos jefes y las cinco familias no se deduce de que compartan una ruta. Sus nombres y regiones originales están en `INVENTARIO_Y_ADAPTACION.md`; no se convirtieron en canon de Linde.

## Fuentes y comprobación visual

- `SELECCION_MOBS.json`: 24 diseños, rutas concretas y SHA-256 por cada variante pintada registrada de reposo y una muestra pixel nativa por diseño. Incluye estado propuesto y motivo; `approved:false` y `logic_imported:false` en todos.
- `CONTACTO_24_DISENOS.png`: primer reposo pintado a la izquierda y pixel a la derecha por diseño. Es una hoja diagnóstica compuesta con recortes de las fuentes, no arte de producción ni prueba de compatibilidad final.
- `CONTACTO_75_VARIANTES_PINTADAS.png`: las 5 variantes elementales de los 15 diseños de familia/rango, también diagnóstico.
- Los hashes del código consultado están en `INVENTARIO_FUENTES.json` y `SELECCION_MOBS.json`; no se copiaron fuentes completas.

Las hojas diagnósticas usan los rectángulos declarados por el registro pintado vigente y el cuadro pixel nativo 140×192. La composición cambia el tamaño de las miniaturas para comparar, por lo que **no demuestra escala de juego ni equivalencia exacta de píxeles**.

Límites: se inspeccionaron las 24 parejas de reposo nativo y las 75 muestras pintadas elementales. No se revisaron individualmente todos los ataques/daños/derrotas ni todas las variantes pixel elementales. No hay cuatro direcciones cenitales declaradas en esos contratos; falta construirlas/adaptarlas y probarlas en Linde. Ninguna selección importa daño, atributos, afinidad, turnos, hitboxes, recompensas, spawns ni misiones del juego fuente. La licencia individual de cada imagen sigue sin estar establecida por esta auditoría.
