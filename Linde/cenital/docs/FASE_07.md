# Fase 7 · arte integrado

El viajero y los habitantes usan dibujo base 128×128 a escala de mundo 0,25, cámara 3× y composición modular. Los cuadros extendidos 192×192 permiten mover brazos y armas sin agrandar el cuerpo. Se conservan tamaño físico, colisión, personalización, tiempos y guardado.

## Integración sobre 618180b

- Se conservan autonomía por defecto, sociedad, colonos, terreno por regiones, biomas, fauna y persistencia.
- Se mantienen Nunito Sans y Lora. Los nombres del mundo usan la fuente vigente con contorno, no una sustitución de la tipografía de interfaz.
- El dibujo consume Equipo.visible(), incluido el equipo `art1:`. Armaduras y armas respetan las paletas aportadas por materiales; no se modifican estadísticas, recetas ni calidad.
- Hacha y pico se muestran según objetivo e inventario, incluidos arcilla y cobre. Los remotos mantienen la limitación existente de información sobre la herramienta.
- Se incorporan las bases y los 14 modelos de pelo compartidos por las 20 entradas de menú, las capas de equipo y las animaciones por articulación de piezas. Cinturón visible y pelo debajo del casco.
- El indicador de interacción se reduce; los marcadores de depósito y etiquetas se separan de cabezas y nombres. El matiz del suelo solo cambia presentación y conserva las mezclas de biomas.

Los PNG y su manifiesto están en arte/viajero071/. El dibujante vive en scripts/viajero071.gd y arte_equipo.gd conserva sus contratos de capas anteriores para compatibilidad.

## Revisión breve

Con Godot 4.7.1 y renderizador gráfico: `--path Linde/cenital --script res://tests/revision_fase7.gd -- --salida=<carpeta>`.

El arnés realiza cinco comprobaciones: arranque/escala, tipografías, paletas del equipo artesanal, regiones/fauna/autonomía y guardado/carga. Produce cuatro capturas usando la escena y lógica actuales. No reemplaza suites completas ni una sesión multijugador. Los avisos de ObjectDB/recursos en uso al salir siguen presentes como en el prototipo anterior.

No se modifican partidas del usuario: el arnés usa rutas aisladas `user://revision_fase7/`. Las piezas y desplazamientos preparados para mostrar compatibilidad no se aplican al guardado habitual.

## Fuentes

Ver ../../documentos/FASE_07/README.md. Las tres fuentes generadas originales y sus prompts se conservan allí. No se generó arte nuevo para esta integración.
