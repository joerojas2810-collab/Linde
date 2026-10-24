# Linde — prueba 01, versión nativa

Fecha: 2026-10-23. Estado: **prueba**, no recurso final. El original (`../prueba_01/personaje_cuatro_vistas_original.png`) no se ha tocado.

## Qué se hizo
`herramientas/arte/convertir_personaje.gd` (Godot headless):
1. Detecta las 4 vistas por alfa (> 0,75) y su caja.
2. Divide cada caja en una rejilla de **34 filas** de píxel nativo (período medido ≈ 15 px en el original; cada vista queda en 19×34).
3. Toma el color **mediano** del centro de cada casilla (no promedia) y binariza el alfa.
4. Fusiona colores casi iguales: 909 colores distintos → 44.
5. Escribe una tira 1:1, una hoja 4×4 de celdas de 40 px y el manifiesto que lee `juego/cenital/scripts/capas_sprite.gd`.

## Archivos
- `personaje_nativo_cuatro_vistas.png`: 4 vistas a tamaño nativo (frente, derecha, espalda, izquierda).
- `hoja_40.png`: hoja 160×160; filas = frente, derecha, espalda, izquierda; los 4 cuadros de cada fila son iguales (aún no hay caminata).
- `medidas_nativas.json`: cajas de origen, tamaño nativo, período y paleta.
- `capturas/mapa_real.png`: captura del juego con el personaje cargado en el mapa real.
- Cargado en el juego: `juego/cenital/arte/personaje.json` + `personaje_cuerpo.png` (copia de `hoja_40.png`). Si se borra esa carpeta, el juego vuelve al dibujo procedural.

## Resultado
- Tamaño nativo 19×34; 0 píxeles semitransparentes; 4 vistas coherentes. Las pruebas del juego siguen en 0 fallos (139 de lógica, 12 de interfaz).
- En el mapa real se ve a la misma escala de píxel que el escenario: queda algo más alto que la puerta de la casa.

## Límites y puntos abiertos
- **No cabe en el lienzo de 32 de la guía**: 34 filas > 32. Se usó una celda de 40 sin reducir (una reducción no entera destruiría la rejilla). El tamaño definitivo (lienzo, tamaño de píxel) sigue por decidir con esta prueba.
- **Ancla:** aquí los pies tocan la última fila de la celda. La guía de `prueba_01` usa baseline en y=29 y la de `design/art/plantilla/` en y=30; hay que unificar las tres.
- 44 colores: no es una paleta decidida. Quedan algunos píxeles sueltos por el muestreo (por ejemplo en manos y bordes) que una limpieza manual debe revisar.
- Sin caminata, equipo ni capas separadas; la hoja es una sola capa («cuerpo») con ropa y pelo incluidos. El NPC (Maren) sigue con el dibujo procedural.
- Procedencia: personaje generado con la herramienta de imágenes integrada (ver `../prueba_01/PROMPT.md`); la conversión es propia. Esto no certifica licencia ni exclusividad.

## Reproducir
```bash
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --script herramientas/arte/convertir_personaje.gd -- \
  <ruta>/design/art/entregas/prueba_01/personaje_cuatro_vistas_original.png \
  <ruta>/design/art/entregas/prueba_01_nativo <ruta>/juego/cenital/arte
```
