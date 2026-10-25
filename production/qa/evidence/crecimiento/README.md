# Verificación de crecimiento — 25/10/2026

Motor: Godot 4.7.1, macOS, ejecución local. Contrato en `Linde/cenital/docs/CRECIMIENTO_Y_ASENTAMIENTOS.md`.

- `prueba-crecimiento.txt`: 27 comprobaciones; compatibilidad de terreno, solares, reanudación de obra, costes, consumo, extracción distante, persistencia, réplica y caché.
- `regresiones/`: 10 suites, 301 comprobaciones sin fallos (autonomía, sociedad, desarrollo, protección, terreno, fauna, caminos, cultivo, casas y orden de dibujo).
- `campana.txt`: regresión completa del juego en modo campaña.
- `interfaz.txt`: 13 comprobaciones.
- `red-crecimiento.json` y `red-crecimiento.txt`: servidor y dos clientes reales, en procesos separados sobre localhost. Cruce del valle, cofre/candado, permisos, transferencia, cultivo, techo, cosecha y persistencia. No es una prueba de Internet ni de latencia artificial.
- `red-regresion.txt`: integración existente, cero comprobaciones fallidas, incluyendo reconexión y validación de acciones.
- `carga.json`: 12 habitantes, cuatro sesiones en el mismo proceso, 1200 ticks, 44 regiones. p95 0,882 ms; máximo 2910,943 ms. Esta prueba verifica población/caché; **no certifica fluidez**. Las pausas de planificación siguen pendientes. Se acotó la búsqueda de solares a 64 candidatos por llamada; no se atribuye todo el tiempo máximo a esa función.
- `simulacion-123.json`, `simulacion-456.json`: cinco días de juego sin regalos de materiales ni solares preparados, con combate desactivado. Ambas llegaron a seis habitantes, sin inventarios negativos; ninguna terminó una casa completa. Prueban crecimiento y construcción parcial, no equilibrio económico satisfactorio. Corresponden a las prioridades/recetas/cultivos finales, anteriores al límite de 64 candidatos de búsqueda por llamada.

Las cuatro imágenes usan la escena real, con posicionamiento y materiales preparados por el script de captura. Muestran el plano pagado por acciones de construcción, arte de cultivos, techo que se desvanece dentro, residentes regionales y panel J. No representan una partida autónoma ni un recorrido manual prolongado.

Los registros conservan avisos de certificados del entorno y de recursos retenidos al finalizar pruebas. No se cuentan como aserciones de juego aprobadas ni se ocultan. Una primera pasada sin acceso a `user://` falló al escribir partidas; se repitió con acceso a la carpeta de datos de Godot y se conserva aquí el resultado válido.
