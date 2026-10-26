# Fase 6 — saldos y economía regional, 26/10/2026

- `regional.txt`: 19 comprobaciones, 0 fallos; Godot 4.7.1, semilla 123, comunidades reales en modo poblado. Pasos acotados en momentos de cosecha/consumo/producción; sin simulación prolongada.
- `colectivas.txt`: 50 comprobaciones, 0 fallos; integración del saldo ampliado con el bloque colectivo existente.

```sh
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --path Linde/cenital --log-file /tmp/linde-regional-engine.log --script tests/prueba_economia_regional.gd
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --path Linde/cenital --log-file /tmp/linde-colectivas-engine.log --script tests/prueba_demandas_colectivas.gd
```

Contabilidad: variación del cofre igual a suma de resultados reales, IDs de extracción en objetos rotos, consumo/herramientas/usos sin duplicación, detención con stock completo, comida insuficiente, deuda, falta de herramientas y fuentes agotadas. Persistencia de cursores/resultados/saldos y continuación equivalente después de reiniciar con la misma entrada externa explícita del escenario. Bienvenida y actualización fiable de réplica en proceso, sin simulación cliente. La comparación de JSON normaliza int/float equivalentes de metadatos heredados; no tolera diferencias de cantidades.

Sin suites históricas, sockets ni Internet. Los avisos conocidos del motor al cerrar se conservan en los registros. No hay balance nuevo ni comercio, migración o fundación.
