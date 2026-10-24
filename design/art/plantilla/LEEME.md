# Plantillas de alineación de sprites

Generadas por `herramientas/arte/plantilla_alineacion.gd` a partir del cuerpo del personaje compacto (sin equipo).

- `plantilla_32.png`: hoja 128x128, celdas de 32x32.
- `plantilla_16.png`: hoja 64x64, celdas de 16x16.
- `plantilla_32_x8.png` y `plantilla_16_x8.png`: las mismas ampliadas x8 (vecino más cercano), para generadores de imagen.

Orden: columnas = frames de caminata 0 a 3; filas = frente, derecha, espalda, izquierda.

En cada celda: borde gris claro, línea de suelo azul en la base, eje central punteado y silueta gris translúcida.

Ancla de los pies: píxel (16, 30) de la celda de 32 px, marcado con cruz roja de 3 px (solo en la hoja de 32).

Los tamaños 16 y 32 px son de prueba; la resolución final no está decidida.
