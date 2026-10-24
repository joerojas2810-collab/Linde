# Personaje: caminata, acciones y máscaras

Fecha: 2026-10-23. Fuente de identidad: personaje de la prueba01 aprobado visualmente. Generación con herramienta integrada de imágenes, seguida de conversión técnica en Godot. Originales y prompts preservados.

## Archivos nativos

- `caminata.png`:128×128,4 columnas×4 filas, celda32×32. Filas frente,derecha,espalda,izquierda.
- `herramienta.png` y `ataque.png`:192×192,4×4, celda48×48. El lienzo mayor deja espacio para herramienta y estela; el cuerpo conserva aproximadamente27px de alto.
- `capas/`:7 máscaras disjuntas que reconstruyen byte a byte la caminata: cuerpo residual, piel, pelo, túnica, pantalón, botas y cinturón.
- `variante_cobre.png`, `variante_violeta.png`, `variante_arena.png`:recoloreados de muestra, no peinados ni vestimentas nuevos.
- `galeria.png`:hoja de contacto renderizada en Godot.
- `manifest.json`, `validacion.json`:contratos y pruebas técnicas.

Todas las hojas tienen alpha0/255. Caminata usa32 colores y acciones hasta48 colores, provisional por hoja, no paleta final global. Los16 cuadros de cada hoja no están vacíos, y cada dirección tiene4 cuadros distintos. Eso verifica diferencia de píxeles, no calidad de animación.

## Orden de cuadros

Caminata: reposo/pasoA/paso de transición/pasoB. Herramienta y ataque: preparado/anticipación/impacto/recuperación. Duraciones propuestas en manifiesto, sujetas a sincronización con reglas. Los cuadros de frente de acciones tienen giro de cabeza/cuerpo hacia el lado del golpe; requieren pulido si se busca una frontal estricta. La herramienta ilustrada es un hacha, no sirve para representar un pico sin producir otra variante.

La conversión localizó bandas horizontales reales en las fuentes: el generador no respetó una cuadrícula perfectamente regular. `conversion.json` registra recortes usados; `convertir.gd` aplica alpha, escala, ancla y paleta sin alterar originales. No se han detectado recortes fuera de celdas destino. Revisar manualmente cualquier discontinuidad de cabeza, manos o pies antes de producción final.

## Capas y personalización

Las máscaras permiten recolorear regiones manteniendo anclaje y animación. No son un cuerpo desnudo reconstruido ni piezas intercambiables de geometría nueva: quitar la túnica deja un hueco. La clasificación inicial por color/zona necesita revisión artística de contornos antes de añadir nuevos peinados o prendas.

`integrar.gd` recompone piel y botas dentro de cuerpo y utiliza las5 capas que entiende el cargador existente del mapa. La reconstrucción resultante coincide con la hoja original. El selector de aspecto del juego aún no cambia estas máscaras; las variantes se ven en la galería general.

## Integración de muestra

La copia `../mapa_muestra` usa caminata solo cuando el PJ se desplaza realmente. El render de ataque consulta estados reales aviso/activo/rec, únicamente cuando hay espada de hierro en inventario. El render de herramienta se activa tras una acción válida cuando hay hacha en inventario. El daño, costes y tiempos de reglas no se modificaron. El hacha es una ilustración provisional; discriminar tipo de recurso/herramienta antes de conectar otras herramientas.

F2 permite comparar el personaje/enemigos con el dibujo anterior. El escenario nuevo sigue activo. Las capturas de acciones son pruebas de poses con estado preparado en memoria, no evidencia de una secuencia completa de combate jugada.

## Ver

Abrir `../GALERIA.html` para reproducir cuadros y direcciones. Abrir `project.godot` muestra hoja de contacto. Los scripts Godot se incluyen para reproducibilidad. Python/PIL se utilizó solo para medición y comprobación de archivos, no para editar las ilustraciones.
