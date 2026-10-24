# Linde — primera entrega de arte

Fecha: 2026-10-23. Estado: prueba visual, no recursos finales.

## Entregado

- `plantilla_alineacion_32.png`: guía geométrica exacta de cuatro celdas lógicas de 32×32, ampliadas ×8; línea de suelo y centro. La silueta es una guía de ocupación, no arte.
- `personaje_cuatro_vistas_original.png`: generación original RGBA de 2172×724, frente/derecha/espalda/izquierda, personaje completo quieto y sin equipo.
- `project.godot`, `main.tscn`, `prueba.gd`: escena aislada para visualizar las vistas a 28, 40 y 56 píxeles de altura visible, ampliadas ×2, junto a referencias geométricas provisionales. No modifica el juego.
- `prueba_escala_motor.png`: captura real de esa escena en Godot 4.7.1, OpenGL/Metal en Apple M3. La ejecución terminó con código 0.
- `medidas.json`: regiones medidas por umbral de alpha >192; no se ha alterado el PNG original. Las regiones se muestran mediante recorte de textura en motor.
- `PROMPT.md`: prompt utilizado.

## Lectura visual

Las cuatro vistas mantienen identidad, ropa y altura semejantes. La versión mostrada a 28 px visibles mantiene mejor proporción respecto de la puerta de prueba que las de 40 y 56. Es una evaluación visual de esta escena y no una elección definitiva de resolución.

La imagen generada no respeta una cuadrícula nativa garantizada. Se han observado píxeles semitransparentes en sus límites. No se ha reducido, limpiado ni separado en capas. Mostrar el original a escala pequeña no equivale a producir un sprite nativo de esa resolución. La escena no valida movimiento, animación, capas ni integración con el mapa real.

## Siguiente trabajo

1. Convertir y limpiar una versión nativa siguiendo la guía, conservando el original.
2. Validar paleta, bordes, píxeles y anclajes después de esa conversión.
3. Colocar esa versión en el mapa real, junto a una puerta, árbol y cofre del escenario.
4. Decidir dimensiones y acabado con esa evidencia; después abordar caminata y equipo.

## Abrir

Abrir `project.godot` en Godot. Para reproducir la captura con un ejecutable Godot instalado:

```sh
Godot --path /ruta/a/esta/carpeta -- --captura
```

No se incluye el motor. La captura se escribe como `prueba_escala_motor.png` en esta carpeta.

## Procedencia

Personaje generado con la herramienta de imágenes integrada usando referencias conceptuales propias del proyecto; plantilla y escena de prueba creadas para este encargo. No se incorporaron assets de Pokémon ni de Helbreath. El registro de generación no concede por sí mismo una licencia de terceros ni certifica exclusividad.
