# Arte pendiente del mundo — 25/10/2026

> Estado local actualizado: consultar «Revisión completa 01» al final. La auditoría original se conserva como referencia del punto de partida.

Auditoría hecha leyendo `scripts/mundo_arte.gd` y `arte/mundo/`. Formato destino: PNG de 16 px por celda (copas/troncos de 64 px para árboles), con pivote en `E04_objetos.json`.

## Sprites compartidos o prestados (sustituir primero)

| Objeto | Hoy | Falta |
|---|---|---|
| `veta` (hierro), `veta_cobre`, `veta_estano` | los tres usan `E04_ore_copper.png` con un tinte (`TINTE_MENA`) | un sprite propio por mena y su variante agotada (`E04_ore_depleted` es común) |
| `arcilla` (pozo) | `E04_rock` con tinte rojizo | pozo de arcilla propio, lleno y agotado |
| `roca` | un solo sprite | 2–3 variantes (mismo tamaño) para romper la repetición |
| `arbusto` | un par con y sin bayas | 2 variantes más, y un arbusto sin bayas propio por bioma |

## Vegetación por bioma (no existe)

Los suelos ya son propios por bioma, pero los objetos son los del valle. Por bioma faltan:

- **Sierra:** peñasco grande, pino ralo.
- **Secano:** árbol seco, matorral espinoso, roca de arenisca.
- **Pradera:** arbusto bajo con flores.
- **Ribera:** juncos y cañas (cruzan el borde del agua).
- **Bosque:** helecho y tronco caído.

## Fauna

Las 5 criaturas regionales reutilizan 20 tiras de `Nuevo Juego/public/art/enemies-px`: solo vista frontal, criaturas fantásticas. Falta orientación lateral/espalda y, si se quiere fauna "animal" real, especies nuevas.

## Equipo

Espadas, escudos y armaduras generados recolorean geometría existente: faltan siluetas nuevas.

## Arraigo, oficios y vivienda (nuevo)

Las mecánicas de `docs/ARRAIGO.md` funcionan sin arte nuevo, pero se ven pobres. Falta:

- **Dormir al raso:** quien no tiene cama queda en estado `sin_cama` sin pose ni objeto (ni petate, ni fogata, ni marcador de campamento).
- **Oficios nuevos:** agricultor, explorador, mercader y guardia usan el aspecto generado por id; faltan señales de oficio (sombrero y azada, mochila de explorador, bolsa de mercader, equipo de guardia).
- **Ocupaciones:** vigilar, explorar y comerciar no tienen animación ni icono sobre el habitante.
- **Estados de permanencia:** visitante, aspirante, residente y ausente solo existen como texto en el panel J; no hay icono ni marca visual.
- **Biografía:** origen, antecedente y aspiración se leen en una línea del panel J; no hay ficha de personaje ni retrato.
- **Casa comunitaria:** reutiliza cama, muro, puerta y techo; tres camas en fila se ven repetidas. Falta una variante de cama (litera o jergón) y un letrero que distinga la casa común.

## Cómo añadirlo

Generar el PNG, copiarlo a `arte/mundo/`, registrarlo en `E04_objetos.json` (archivo, canvas, pivote) y cambiar la clave en `mundo_arte.gd` (`natural()`); `TINTE_MENA` puede borrarse cuando cada mena tenga arte propio.

## Dibujo por código aceptado (provisional, 25/10)
Lo siguiente se dibuja hoy con primitivas por excepción aprobada ([DECISIONES](DECISIONES.md#excepciones-de-dibujo-por-código-usuario-2510-provisional)) y puede sustituirse por recursos sin cambiar el aspecto: motas de pradera, hierbas, piedrecillas de secano, juncos de ribera, flor y musgo de ruinas (`arte_entornos.gd`); marcos, casillas y barras de la interfaz (`ui_viva.gd`, como 9-patch con este mismo aspecto). Al sustituirlos, bajar el máximo correspondiente en `DIBUJOS_APROBADOS`.

## Avance local — 25/10/2026: minerales y arcilla

Borrador de ocho sprites propios (hierro/cobre/estaño/arcilla, disponibles y agotados) integrado en ambos dibujantes para revisión visual. Registro y procedencia: `arte/mundo/minerales_v1/README.md`. Comparativa controlada en `outputs/Arte_minerales/revision_01/GALERIA.html` del espacio de trabajo. Una generación; ocho estados comprobados sin faltantes y sin modificar el estado del mundo. **Pendiente de aprobación visual; no marcar las filas como terminadas todavía.**

## Revisión completa 01 — 25/10/2026

Todos los apartados cuentan con borrador local: variantes/vegetación, orientaciones de fauna, siluetas de equipo y presentación de arraigo/oficios/vivienda. Primer lote de minerales aprobado; resto pendiente de aprobación visual. Detalle por punto, procedencia y límites en `arte/pendientes_v1/README.md`; galería del espacio de trabajo `outputs/Arte_pendiente_completo/revision_01/GALERIA.html`.

Límites: fauna lateral/trasera animada por derivación de poses; cascos del jugador y armadura media conservados; animales reales opcionales no incluidos; árboles de clima seco/alpino asignados a árboles existentes y sus transiciones. No se han modificado reglas/densidades. QA dirigido y captura de seis entornos aprobados. **Sin commit ni push; no marcar como entrega final hasta la revisión del usuario.**

## Integración local sobre 5b87517 — 25/10/2026

Acabado local reaplicado a la última base remota, conservando art2 y correcciones A1–A3. 60 comprobaciones visuales y 49 de pico/cama aprobadas, más revisión dirigida de arte/fichas y equipar/quitar art2. Indicadores nuevos como PNG; suelo reduce sus excepciones de 15 a 13. Sin cambios a reglas ni pruebas generales/red. Evidencia local: `outputs/Arte_pendiente_completo/integracion_5b87517/INFORME.md`. **Sin commit/push.**

## Publicación autorizada — 25/10/2026

El usuario solicitó commit y push de esta integración sobre 5b87517. La evidencia vigente se conserva en `production/qa/evidence/arte-pendiente-integrado/`; los estados de borrador y sin publicar anteriores son históricos. Se mantienen los límites artísticos y de pruebas documentados; la publicación se identifica en el historial de Git.
