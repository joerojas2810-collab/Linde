# Rendimiento local: medición y corrección focalizada — 27/10/2026

Base: `arena/09130d95-linde`, commit `a7f9766`. Apple M3, Godot 4.7.1 oficial, OpenGL Compatibility, 1280×720, zoom 3, semilla 123. Tres repeticiones secuenciales por escenario, 60 cuadros de calentamiento y 360 cuadros medidos por repetición (1.080 por escenario y versión). Ventana gráfica visible y siempre encima; no son FPS headless. FPS = cuadros / tiempo real entre callbacks posteriores al dibujo `frame_post_draw`; no son estimaciones a partir del tiempo CPU. El monitor de FPS del motor también queda en cada muestra.

## Resultado gráfico

| Escenario | FPS antes → después | Cuadro promedio ms | Cuadro p95 ms | Cuadro máximo ms | Cuadros >200 ms (de 1.080) |
|---|---:|---:|---:|---:|---:|
| quieto | 37.75 → 46.52 | 26.49 → 21.50 | 27.55 → 25.48 | 372.49 → 162.79 | 23 → 0 |
| cargadas | 37.46 → 45.64 | 26.69 → 21.91 | 27.10 → 26.02 | 361.44 → 177.88 | 24 → 0 |
| nuevas | 21.95 → 25.53 | 45.56 → 39.16 | 58.69 → 56.90 | 390.87 → 198.14 | 33 → 0 |

`quieto`: posición inicial en el poblado. `cargadas`: ida y vuelta a pie por una ruta transitable de 8 celdas dentro de las regiones iniciales. `nuevas`: seis cruces controlados de 16 celdas (una región), uno cada 60 cuadros, con carga/generación real y dibujo real; es un ensayo de streaming reproducible, no una caminata humana continua. Las posiciones y regiones cargadas están en los JSON. No se incluyen menús, generación de la partida ni la primera importación de recursos.

## Qué coincide con las pausas

Antes: los cuadros quietos de ~250–373 ms contienen ~229–233 ms en `_alcance` regional, llamado repetidamente por economía/demandas. Un cuadro puede sumar además ~109 ms de decisión de NPC. El render del poblado ronda 14 ms, el movimiento de NPC menos de 0,1 ms y la fauna no explica esas pausas. Tras la caché desaparecen los cuadros >200 ms en estos ensayos; queda un pico por decisión de NPC. En regiones nuevas el dibujo llega a decenas de ms por cuadro y mantiene los FPS bajos; esta corrección no resuelve ese límite. Las categorías son inclusivas: **no sumarlas**.

## Cambio mínimo y comprobaciones

`asentamientos.gd`: caché de sesión para `_alcance`, clave centro/radio e invalidación por `mundo.version`. Devuelve una copia para que un llamador no altere el resultado guardado. Conserva BFS, orden, reglas y persistencia. `escena.gd`: corrige una línea mal indentada de la rama que impedía compilar; no es una optimización. La instrumentación por cuadro fue temporal y se retiró del código entregado.

La prueba nueva compara alcance y orden con BFS sin caché, verifica aislamiento de resultados y actualización al construir/retirar obstáculos; otra compara el estado completo de dos mundos durante 120 ticks con/sin caché. Pasaron las pruebas de caché, equivalencia, economía regional (19 casos), expansión F6, reparación/presión F6 y decisiones de fauna (18 casos). `prueba_preexistentes` conserva un fallo de provisiones: se reprodujo también sin caché (`preexisting-baseline.out`); no se considera causado ni resuelto por este cambio. Ver logs `test-*`.

## Subsistemas durante el juego

Cada celda: **promedio / p95 / máximo en ms**, contando únicamente los cuadros donde se invocó el subsistema. Cada cuadro suma sus llamadas al mismo subsistema. Para ver también el número de cuadros activos, abrir `subsistemas.csv` o `resumen.json`. El render mide preparación/emisión CPU de `Escena._draw`, no GPU/VSync ni HUD. La simulación no corre en la red en estos escenarios locales; el coste de red es cero y se mide aparte con clientes reales.

### quieto

| Subsistema | Antes | Después |
|---|---:|---:|
| render_cpu | 13.893 / 14.296 / 30.266 | 13.844 / 14.473 / 30.906 |
| npc_movimiento | 0.027 / 0.035 / 0.080 | 0.025 / 0.034 / 0.062 |
| npc_decisiones_necesidades | 246.330 / 344.559 / 352.016 | 22.271 / 131.740 / 136.099 |
| npc_decidir | 109.953 / 111.545 / 111.545 | 109.606 / 112.027 / 112.027 |
| navegacion | 0.421 / 1.421 / 1.430 | 0.428 / 1.373 / 1.433 |
| navegacion_regional | 227.657 / 231.499 / 234.666 | 3.144 / 18.307 / 18.895 |
| fauna | 0.089 / 0.093 / 0.094 | 0.092 / 0.099 / 0.116 |
| economia_regional | 105.462 / 107.664 / 108.156 | 0.662 / 0.693 / 1.168 |
| economia_demandas | 126.452 / 130.567 / 132.206 | 6.600 / 22.509 / 23.330 |
| economia_sociedad | 0.017 / 0.019 / 0.020 | 0.013 / 0.018 / 0.021 |
| regiones_total | 0.033 / 0.043 / 0.092 | 0.028 / 0.038 / 0.051 |
| regiones_streaming | 0.010 / 0.012 / 0.025 | 0.009 / 0.011 / 0.014 |
| tick | 5.342 / 0.129 / 352.141 | 0.550 / 0.141 / 136.275 |

### cargadas

| Subsistema | Antes | Después |
|---|---:|---:|
| render_cpu | 13.900 / 14.123 / 32.706 | 13.882 / 14.491 / 31.875 |
| npc_movimiento | 0.035 / 0.030 / 1.424 | 0.035 / 0.033 / 1.388 |
| npc_decisiones_necesidades | 244.477 / 340.244 / 340.843 | 30.828 / 149.504 / 155.472 |
| npc_decidir | 108.800 / 109.099 / 109.099 | 110.320 / 113.380 / 113.380 |
| navegacion | 0.628 / 1.433 / 1.461 | 0.642 / 1.425 / 1.558 |
| navegacion_regional | 226.642 / 228.738 / 229.275 | 12.291 / 35.666 / 36.628 |
| fauna | 0.116 / 0.193 / 0.200 | 0.119 / 0.208 / 0.212 |
| economia_regional | 105.240 / 106.729 / 107.510 | 9.939 / 18.750 / 19.351 |
| economia_demandas | 125.560 / 126.507 / 126.821 | 6.436 / 22.404 / 23.269 |
| economia_sociedad | 0.018 / 0.021 / 0.031 | 0.013 / 0.016 / 0.017 |
| regiones_total | 0.048 / 0.057 / 0.144 | 0.050 / 0.066 / 0.135 |
| regiones_streaming | 0.015 / 0.017 / 0.102 | 0.015 / 0.018 / 0.097 |
| tick | 5.535 / 0.169 / 340.958 | 0.760 / 0.169 / 155.598 |

### nuevas

| Subsistema | Antes | Después |
|---|---:|---:|
| render_cpu | 30.181 / 46.156 / 79.516 | 30.269 / 46.940 / 82.013 |
| npc_movimiento | 0.042 / 0.038 / 1.513 | 0.042 / 0.039 / 1.515 |
| npc_decisiones_necesidades | 245.898 / 341.651 / 342.868 | 34.047 / 134.824 / 135.007 |
| npc_decidir | 98.401 / 111.678 / 111.678 | 98.917 / 111.853 / 111.853 |
| navegacion | 0.662 / 1.429 / 1.487 | 0.660 / 1.418 / 1.473 |
| navegacion_regional | 223.630 / 232.479 / 235.478 | 11.804 / 18.919 / 19.184 |
| fauna | 0.233 / 0.348 / 0.356 | 0.237 / 0.369 / 0.371 |
| economia_regional | 103.698 / 107.827 / 110.688 | 10.155 / 18.898 / 19.127 |
| economia_demandas | 124.233 / 129.643 / 129.927 | 5.839 / 22.487 / 22.748 |
| economia_sociedad | 0.017 / 0.021 / 0.026 | 0.014 / 0.018 / 0.021 |
| regiones_total | 0.066 / 0.050 / 2.923 | 0.065 / 0.052 / 3.108 |
| regiones_streaming | 0.040 / 0.013 / 2.877 | 0.040 / 0.013 / 3.043 |
| tick | 7.660 / 0.407 / 343.032 | 1.186 / 0.422 / 135.175 |

## Benchmark CPU aislado de la guía

Tres repeticiones, 5 llamadas de calentamiento, 40 muestras por operación (streaming: 30). Se redujo el número de muestras para mantener focalizado el trabajo; se conservan todas las líneas originales `MEDIDA_CPU`. Promedio = media de las 3 repeticiones; p95 y máximo = peor valor reportado entre las 3, **no un percentil agrupado inventado**. Las operaciones se ejecutan secuencialmente sobre el mundo del benchmark, no representan los FPS gráficos.

| Operación | Antes promedio / p95 / máximo ms | Después promedio / p95 / máximo ms |
|---|---:|---:|
| npc_movimiento_necesidades | 0.010 / 0.012 / 0.012 | 0.010 / 0.012 / 0.017 |
| npc_decisiones_lote | 105.638 / 122.154 / 124.835 | 106.818 / 121.270 / 126.916 |
| navegacion_BFS | 1.453 / 1.572 / 1.621 | 1.451 / 1.560 / 1.626 |
| fauna_actualizar | 0.073 / 0.133 / 0.135 | 0.070 / 0.082 / 0.105 |
| economia_regional | 233.949 / 251.626 / 268.725 | 4.620 / 4.945 / 4.954 |
| regiones_streaming_frio | 12.240 / 13.589 / 14.681 | 12.532 / 15.388 / 17.254 |
| red_snapshot_bytes_local | 0.009 / 0.010 / 0.013 | 0.009 / 0.010 / 0.013 |
| tick_completo_referencia | 125.739 / 357.701 / 373.268 | 11.334 / 117.851 / 139.573 |

## Red localhost: medición separada

Tres ejecuciones de `prueba_red.gd` sobre la versión corregida, con servidor y dos clientes en procesos separados. No equivale a red de Internet ni forma parte del coste de la partida local. Tiempos de la instrumentación existente, en ms.

| Repetición | Snapshot prom. / p95 / máx. | Difusión prom. / p95 / máx. | Tick prom. / p95 / máx. |
|---|---:|---:|---:|
| network-0 | 0.116 / 0.207 / 0.492 | 1.231 / 5.463 / 17.003 | 3.487 / 16.580 / 170.869 |
| network-1 | 0.120 / 0.204 / 2.507 | 1.153 / 5.627 / 8.309 | 3.441 / 11.789 / 148.777 |
| network-2 | 0.127 / 0.235 / 0.834 | 1.384 / 6.540 / 10.531 | 3.883 / 14.346 / 148.631 |

## Reproducción y límites

Ver `reproducir/`: aplicar `instrumentar.py` a una **copia** del proyecto, ejecutar `perf_escenarios.gd` con `--nueva=123 escenario=quieto|cargadas|nuevas salida=/ruta/archivo.json`, tres veces por condición. Usar `--always-on-top --position 0,0` y cliente gráfico. Ejecutar también los comandos de `docs/medicion-subsistemas.md` (aquí `muestras=40` para CPU). Para antes/después usar el mismo equipo y configuración; base `a7f9766` con la corrección de indentación y luego el parche de caché. Los ensayos se ejecutaron secuencialmente para evitar competencia entre benchmarks. El benchmark no certifica GPU, otras máquinas, sesiones largas ni una caminata humana por el exterior. Las fugas al cierre y el aviso de certificados del Godot local quedan en los logs; no se ocultaron.
