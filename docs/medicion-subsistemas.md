# Medición focalizada de rendimiento

No se hicieron optimizaciones. La medición usa `Time.get_ticks_usec()`, calentamiento de 5 llamadas y reporta promedio, p95 y máximo. Cada cifra corresponde al alcance indicado; **no sumar las categorías**: una decisión de NPC puede pedir navegación, y los tiempos aislados sirven para localizar coste, no para reconstruir un tick.

## CPU y mundo

```sh
godot --headless --path Linde/cenital -s res://tests/medir_subsistemas.gd -- semilla=123 muestras=100
```

Imprime líneas `MEDIDA_CPU` para movimiento/necesidades de NPC, lote de decisiones NPC, BFS de ruta, fauna, economía/simulación regional, streaming frío de regiones y snapshot+serialización local. La configuración fija semilla 123, mundo poblado, población inicial del juego y carga regiones a saltos de 96 celdas. Cada fila incluye `n`, promedio, p95 y máximo en microsegundos.

## Render del cliente

En una ejecución **gráfica**, no headless:

```sh
godot --path Linde/cenital -- --nueva=123 --perfil-render=600
```

Omite 60 cuadros de calentamiento y mide 600 llamadas de `Escena._draw`; emite `MEDIDA_RENDER` con promedio, p95 y máximo. Mide CPU de preparación/emisión de dibujo, **no** tiempo de GPU, presentación ni VSync. Mantener resolución, renderer, zoom y cámara iguales al comparar.

## Serialización y difusión reales

```sh
godot --headless --path Linde/cenital -s res://tests/prueba_red.gd
```

La prueba existente usa servidor y clientes localhost en procesos separados. El registro `user://pruebas_linde/red/registro.json` ahora separa `snapshot` (construcción/serialización de instantánea) de `difusion` (encolado de RPC instantáneos y cambios durables), con promedio, p95 y máximo en ms; conserva también los tiempos del tick y bytes enviados. La ruta de red solo se mide con registro habilitado y al menos un cliente conectado.

## Lectura y límites

Correr cada prueba en la misma máquina, versión/configuración de Godot y modo de compilación; repetir al menos tres veces para distinguir variación del sistema. No comparar cifras headless con render gráfico ni localhost con redes reales. El benchmark de CPU es un conjunto de operaciones reales aisladas, no una reproducción completa de carga de producción. Resultados ejecutados en Apple M3 con Godot 4.7.1, tres escenarios gráficos y comparación de una corrección mínima: [informe y datos del 27/10/2026](../production/qa/evidence/rendimiento/2026-10-27/README.md). El informe distingue los tiempos CPU, los FPS gráficos, los cruces controlados de región y la red localhost.
