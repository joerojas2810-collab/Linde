# E03 — Inventario y adaptación desde «Nuevo Juego»

Auditoría local: 24 de octubre de 2026. Fuente de consulta: `/Users/josephrojas/Desktop/Nuevo Juego`. Destino artístico: Linde. Este inventario no modifica ningún proyecto, imagen, lógica, balance, misión ni catálogo de enemigos. La autorización del usuario permite usar toda la carpeta como base, conservando el arte y la lógica de Linde.

## Resultado verificable

Hay cinco familias y nueve jefes de ruta en los datos del juego fuente. El selector `src/lib/art/enemies.ts` distingue normal, élite y jefe; el modo pixel carga `/art/enemies-px/`, mientras el modo pintado consulta primero `painted-villains.generated.json` y solo después el registro antiguo. No corresponde tratar todo `public/art/enemies/` como el diseño pintado vigente.

El registro pintado contiene **370 entradas y 159 archivos de imagen únicos**; los 159 existen. El directorio pixel contiene **550 PNG**. Estos conteos son de archivos/entradas, no de criaturas únicas ni de diseños aprobados para Linde. `INVENTARIO_FUENTES.json` contiene las rutas absolutas y SHA-256 de los seis archivos fuente de código/datos, los 159 archivos pintados resueltos y los 550 PNG pixel.

Las muestras inspeccionadas visualmente fueron el slime pixel normal de agua, el Coloso Hueco pintado vigente y el Guardián de Linde. El Coloso pintado presenta mucho más detalle, iluminación suave y adornos que el Guardián pequeño de Linde; no puede entrar por simple reducción sin revisión. El slime pixel es una referencia útil de silueta, pero su atlas tampoco resuelve las cuatro direcciones cenitales.

## Familias: conservar concepto, adaptar representación

| Familia en datos | Prefijo de arte | Identidad aprovechable | Adaptación a Linde |
|---|---|---|---|
| Slime | slime | Masa gelatinosa, ojos, deformación al atacar | Priorizar slime existente de Linde; usar el otro como referencia secundaria, sin sustituir automáticamente su identidad |
| diablillo | imp | Criatura pequeña, rasgos demoníacos, familias visuales | Candidato futuro; nueva silueta cenital, cuatro vistas, sin importar habilidades ni afinidades |
| arpía | harpy | Alas y silueta de criatura voladora | Candidato futuro; vista superior de alas y contacto/sombra conforme a Linde; no asumir vuelo mecánico |
| gólem | golem | Cuerpo pétreo segmentado, núcleo y peso | Referencia especialmente afín al Guardián actual; preservar identidad/catálogo actual y simplificar volumen/ornamentos |
| espectro | specter | Silueta flotante y sobrenatural | Candidato futuro; paleta discreta y contorno legible en terreno; no crear invisibilidad, maldición ni daño nuevo |

Estas relaciones son propuestas de adaptación artística, no aprobación de incorporar cinco familias al juego. El entregable base E03 sigue cubriendo slime, Guardián, Ciervo, Maren y efectos. El Ciervo no tiene equivalente confirmado en estas cinco familias; conservar su fuente de Linde.

## Nueve jefes y contextos del juego fuente

Extraídos literalmente de `src/lib/game/levels.ts:DUNGEON_THEMES`; sus nombres, regiones y elementos describen el juego fuente, no canon de Linde.

| ID | Nombre | Región fuente | Elemento fuente |
|---|---|---|---|
| lord_of_flies | Señor de las Moscas | Pantano de Niebla | agua |
| ash_king | Rey de Ceniza | Cumbres Ardientes | fuego |
| eternal_watcher | Vigía Eterno | Cañón del Viento | viento |
| hollow_colossus | Coloso Hueco | Cavernas de Roca | tierra |
| thunder_king | Rey del Trueno | Tormenta Eterna | rayo |
| mother_hydra | Madre Hidra | Abismo del Pantano | agua |
| withered_queen | Reina Marchita | Corazón del Volcán | tierra |
| faceless_one | El Sin Rostro | Cielo Roto | fuego |
| great_devourer | Gran Devorador | Trono de la Tormenta | viento |

No se establece aquí que sean villanos narrativos de Linde. El código fuente asigna a cada ruta dos familias y, opcionalmente, una invitada; eso es una distribución de encuentros del otro juego, no parentesco narrativo demostrado.

## Qué recurso es vigente

1. **Pintado preferido:** resolver el diseño/elemento/acción por `src/lib/art/painted-villains.generated.json`. Las rutas reales están en `public/art-review/painted-enemies/production/`, incluidas `variants/`. Ejemplos vigentes: `slime-animation-01.png`, `golem-animation-01.png`, `specter-animation-01.png`, `boss_hollow_colossus-animation-01.png`.
2. **Pixel:** `public/art/enemies-px/{design}_{element}_{action}.png`; la disposición declarada usa alto de cuadro 192, ancho de runtime 140, ancla [70,180]. El ancho de diseño declarado es 128 más padding6 por lado. No confundir con los lienzos de Linde.
3. **Pintado anterior:** `public/art/enemies/` + `enemies.generated.ts` es fallback. Una imagen vieja puede existir y no ser el diseño elegido actualmente. No marcar el directorio entero como retirado: el selector todavía lo contempla cuando falta entrada actualizada.
4. **Elementos de jefes:** el selector pintado intenta la paleta nativa del jefe si la afinidad de combate varía. No recuperar un diseño antiguo por una variante de elemento ausente.

El selector ofrece idle/attack/hit/defeat/entrance. Pixel declara respectivamente 4/4/2/4/4 cuadros; entrada solo para jefe. En la muestra pintada, las cuatro filas son estados, no direcciones. Estos registros no declaran caminata norte/sur/este/oeste; no hay evidencia en ellos de un conjunto cenital de cuatro direcciones listo para importar.

## Contrato que manda en Linde

La biblioteca existente `Linde/arte-entregado/biblioteca_01/enemigos/manifest.json` declara:

| Actor | Lienzo por celda | Atlas existente | Pivote | Filas | Columnas existentes |
|---|---|---|---|---|---|
| slime | 32×32 | 160×128 | [16,29] | sur, este, norte, oeste | reposo, caminar A, caminar B, anticipación, ataque |
| guardian | 48×48 | 240×192 | [24,45] | sur, este, norte, oeste | mismas cinco |
| ciervo | 48×48 | 240×192 | [24,45] | sur, este, norte, oeste | mismas cinco |

El manifiesto de biblioteca marca el contenido como propuesta y los tiempos como provisionales: sus segundos no sustituyen los tiempos reales de combate. Mantener hitboxes/radios/daño/experiencia/recompensas/ritmos del código de Linde. El canvas no es la hitbox. El integrador debe resolver los estados visuales contra los eventos actuales; las nuevas imágenes no autorizan habilidades, fases ni enemigos nuevos.

## Producción recomendada

1. Completar primero los actores ya presentes reutilizando los atlas de Linde; conservar sus cuadros aceptados. Del otro proyecto tomar referencias de carácter y poses solo si ayudan a las piezas faltantes.
2. Para el Guardián, el Coloso aporta la idea de masa y núcleo; no copiar su vacío estrellado, piezas doradas ni llamar al Guardián «Coloso Hueco» automáticamente.
3. Redibujar/adaptar los estados que falten a escala nativa y cuatro orientaciones, con contornos, colores por grupo y luz compatibles con el personaje y escenario actuales. La reducción automática de un pintado no constituye una adaptación terminada.
4. Mantener los nueve jefes como banco de referencias futuras separado de los recursos listos para integración. No producir 9×5 variantes elementales ni 5×3 familias completas dentro del cierre actual de E03.
5. Validar en composición con terreno y PJ, a zoom real y ampliado nearest. Comprobar lectura de anticipación/impacto, apoyo de pies, recorte, dirección y relación de tamaños. Los efectos no deben sugerir un área de daño distinta de la mecánica.

## Procedencia y límites

El usuario autorizó la reutilización como base, pero no se encontró un archivo `LICENSE*` en la raíz del proyecto fuente. Eso no demuestra ausencia de derechos ni los concede. El inventario registra procedencia y hashes, no una licencia de distribución. Tampoco se verificaron aquí términos históricos de generación de cada imagen. Conservar esos datos si aparecen en manifiestos adicionales; no declarar «CC0», «libre de derechos» ni «original garantizado» por deducción.

Esta auditoría es de archivos locales y muestras visuales, no de ejecución del juego fuente ni de pruebas del runtime Linde. No se ejecutaron suites ni se contactaron chats externos. Los SHA-256 del JSON permiten comprobar exactamente qué fuentes se revisaron.
