# Extracción de capas — experimento no aprobado

Se editó una sola vez la lámina original con image_gen para retirar cuerpos y conservar los 16 ítems en sus coordenadas. Se conserva `edicion_original.png` y el prompt. **El generador no conservó todas las geometrías solicitadas. Estas capas no deben integrarse como equipo terminado.**

## Archivos y comprobación

- 16 PNG de 32 × 32 px y cuatro tiras de 128 × 32 px: casco, coraza, escudo, espada.
- `composiciones_nativas_128x192.png`: base aprobada; base+casco; base+coraza; base+escudo; base+espada; combinación de las cuatro piezas.
- `composiciones_ampliadas.png`: misma prueba a ×6 para inspección.
- `manifest.json`: para cada ítem, rectángulo exacto de recorte del **personaje original**, tamaño reducido y desplazamiento final. No se recentró el equipo por su caja independiente.
- `checks.json`: geometría y alfa binaria de las 16 celdas. No confundir esas comprobaciones con aceptación artística.
- `../convertir_overlays.gd`: conversión/composición reproducible Godot. Se usa el mismo cálculo de componente, caja corporal, altura 27 y ancla que en los costumes.

## Fallos observados en la composición

1. **Coraza rechazada:** el generador la agrandó y la desplazó hacia arriba respecto al torso original. Tapa parte del rostro y rebasa el cinturón. La combinación completa hereda este defecto.
2. **Casco experimental:** es reconocible sobre la base, pero quedan trazos oscuros de pelo del generador y aún falta una máscara de pelo del personaje. No está validado para todos los peinados.
3. **Escudo experimental:** mantiene la lateralidad general y se prueba detrás del cuerpo en el perfil derecho. Su ajuste a mano/correa necesita revisión sobre la base definitiva.
4. **Espada experimental:** la silueta se mantiene, pero su empuñadura no está fijada a un ancla exacta de mano en las cuatro vistas. El perfil izquierdo se compone detrás del cuerpo; la mano de la base quieta no fue dibujada en postura de agarre.
5. **Oclusión incompleta:** se probó el orden detrás/delante según orientación, pero no máscaras de brazo, mano y pelo. No se afirma modularidad de producción ni combinación aprobada.

No se corrigió la coraza moviéndola o escalándola arbitrariamente para ocultar el fallo; se preservó la transformación solicitada para que el defecto sea revisable. Este experimento explica por qué la lámina generada necesita limpieza/alineación de cada ítem en una plantilla fija antes de poder usarla en caminata y ataques.

La alternativa visual estable de esta entrega siguen siendo las apariencias completas de `../assets/`, documentadas como poses estáticas sin combinación. No hubo cambios de HUD, mapa ni juego original.
