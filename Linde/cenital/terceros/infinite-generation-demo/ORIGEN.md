# Infinite Generation Demo

Origen: https://github.com/mearnest-dev/infinite-generation-demo
Revisión: 63f7400d58f5bdc1bba5fdb33e01016389ff46e4
Archivo original: Scripts/procedural_generation.gd, conservado como texto de referencia.
Licencia MIT, copyright (c) 2025 cool cat; ver LICENSE.

Adaptación ejecutada en scripts/terreno_v1.gd y scripts/mundo.gd: generación de regiones mediante coordenadas globales y campos FastNoiseLite. El original usa TileMap y semillas aleatorias, no guarda alteraciones ni implementa descarga. Linde conserva su propio dibujo, fija semillas por mundo, usa regiones de 16 celdas, añade biomas/recursos deterministas, descarga cachés y mantiene diferencias persistentes. La integración con construcción, navegación, colisión, guardado y red es específica de Linde.
