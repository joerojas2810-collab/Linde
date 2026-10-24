# Piloto de mejora del acabado E03_v002

## Qué se hizo

Dos pasadas image_gen del Guardián con casa y diseño anterior como referencias. Se buscó contorno continuo, masas amplias de piedra, separación entre miembros y material por planos con luz coherente. Cuatro orientaciones en reposo, sin cara/núcleo frontal en la espalda. Fuente y prompts se conservan; imagen nueva generada con herramienta integrada image_gen, conversión nativa en Godot. No se usó Python para editar imágenes.

La primera pasada y su reducción nearest siguen como preliminares, no recursos finales. La segunda fuente usa masas más amplias. La reducción final utiliza Lanczos para integrar información de la fuente grande, seguida de umbral alfa0.5 y cuantización a16colores; el PNG final tiene píxeles opacos/transparencia binaria y se dibuja nearest. No confundir filtrado en conversión con suavizado en runtime. Ese tratamiento es candidato visual, no garantía de mejor arte.

Atlas48×192, celdas48×48, pivote24,45 y cuatro filas sur/este/norte/oeste. Una escala proporcional común, silueta máxima34px, no se escala cada vista por separado. Render comprobado a zoom3 con casa/PJ intactos en la misma composición. No se aumenta el lienzo ni la cámara para aparentar más definición.

## Revisión y límites

Se inspeccionó el original y la captura final1280×720. La segunda propuesta separa más los planos de piedra y controla el ruido respecto al intento preliminar. El usuario debe valorar si esta dirección alcanza la limpieza buscada. La captura presenta diferencias reales de diseño/proporción del candidato: no declarar identidad o calidad idéntica por cumplir el formato.

La casa tiene más superficie en pantalla que cada actor y el PJ sigue usando su base anterior. Mejorar un Guardián no cierra la coherencia de todo el juego. El03 mantiene NPC modulares; si se necesita mejorar geometría común del PJ/NPC, se coordina con02 en lugar de crear otra base incompatible.

Pendiente: valoración del acabado; ampliar el estilo elegido a caminata, aviso, impacto, daño/derrota y a Slime/Ciervo/NPC/FX cuando corresponda. No se rehízo todo el03 a ciegas. No hay integración productiva, cambios a balance/hitboxes/lógica ni commits/push. El v001 se conserva intacto.

## Verificación

Cuatro celdas no vacías, alfa binaria, máximo16colores opacos, límites de silueta, equivalencia entre atlas nativo y copia de preview. Godot4.7.1 con OpenGLCompatibility/AppleM3, render gráfico final exit0. Captura retenida también en production/qa/evidence del proyecto de preview. Los procesos headless pueden emitir avisos de certificados/userdata del sandbox; logs incluidos. No se ejecutaron pruebas del juego porque no se modifica.

## Reproducir

Desde piloto, con GODOT_BIN configurado:

```sh
"$GODOT_BIN" --headless --path previews/godot --script "$PWD/fuentes/convertir.gd" -- "$PWD"
"$GODOT_BIN" --headless --path previews/godot --editor --quit
"$GODOT_BIN" --path previews/godot
```

Después de convertir, sincronizar nativos/guardian_piloto.png a previews/godot/assets/guardian_v002.png y reimportar. Las copias de esta entrega ya están sincronizadas. Godot y cachés no incluidos.

Procedencia: fuentes generadas para Linde, referencias del proyecto conservadas sin cambios en el preview. No se atribuye una licencia de terceros ni exclusividad jurídica al arte generado. Pixelify Sans del preview se distribuye junto a OFL.txt. La fuente principal es piloto/fuentes/guardian_piloto_original.png (segunda pasada); guardian_preliminar_original.png y PROMPT.txt corresponden al primer intento; PROMPT_segunda_pasada.txt al actual.
