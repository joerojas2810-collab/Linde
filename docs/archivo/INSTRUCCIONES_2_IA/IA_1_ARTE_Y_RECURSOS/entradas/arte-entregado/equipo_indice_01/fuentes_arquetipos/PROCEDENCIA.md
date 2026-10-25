# Fuentes de casco y torso: ligera / pesada

Se reutiliza la identidad, postura y distribución de las cuatro orientaciones del arte aprobado de `LINDE_Biblioteca_Arte_01/equipo/overlays_ajustados/composiciones_ampliadas.png`. Se generó únicamente una derivación de vestuario con el generador integrado, sin redibujar la caminata. La imagen de origen conservada es `variantes_generadas.png`.

Los cuatro PNG `*_quieto.png` son **fuentes estáticas de piezas**, no hojas finales del contrato: 32 × 128 px; una celda de 32 × 32 por fila; frente, derecha, espalda, izquierda. Necesitan animación y ajuste sobre cada cuadro de caminata antes de validarse como entrega.

Las siluetas son distintas: ligera lleva gorro de cuero sin ala y chaleco ajustado; pesada incorpora protectores laterales del rostro y hombros que ensanchan la armadura. No son meros cambios de color del arquetipo medio.

`extraer.gd` realiza la extracción material de la imagen generada mediante Godot, muestreo de cobertura por celda y conversión determinista a los cuatro colores índice. No usa Python. Los rectángulos de origen/destino y el pivote propuesto [16,32] se guardan en `extraccion.json`. `encaje_indice.png` es una composición de diagnóstico, no arte final recoloreado. No se modificaron la base ni la caminata aprobadas.

Los cortes y la conversión de roles son decisiones técnicas locales para preparar máscaras; no se atribuyen al generador ni a un origen externo. El arquetipo medio se reutiliza por otra vía. En el atlas final, el casco debe seguir la cabeza, y el torso el tronco; no copiar las poses quietas sin transformación.

## Prompt de la edición (integrado)

Use case: precise-object-edit. Production pixel RPG equipment variants sheet. Edit target/reference image contains same approved teal-haired chibi hero front, east/right profile, back, west/left profile. Preserve EXACT identity, head/body proportions, pose, scale and pixel style. Create TWO ROWS ONLY, FOUR columns each. First row LIGHT archetype: fitted brown leather close cap with exposed face, fitted leather jerkin with small narrow shoulders; no helmet brim. Second row HEAVY archetype: compact steel open-face greathelm with cheek guards, integrated close collar, compact pronounced pauldrons, broad but fitted breastplate. Both must differ materially in contour from original medium iron brimmed helmet and original plain breastplate. Same four facing directions in both rows front/right/back/left. No weapons/shields. Keep base body skin hair trousers and boots unchanged underneath, but only change helmet and torso equipment. Thin readable pixel clusters, no painterly detail. True transparent background, no text labels or grid or environment. Each of eight sprites centered on equal square cells, same scale/feet baseline, enough blank spacing for extraction. Edges hard nearest-neighbor pixels. No animation needed; these are aligned static source costumes for extracting equipment overlays.
