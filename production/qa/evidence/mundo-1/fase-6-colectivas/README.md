# Fase 6 — demandas colectivas, 26/10/2026

Verificación puntual del segundo bloque, Godot 4.7.1, semillas 123 (contabilidad aislada con perfiles de prueba) y 456 (poblado real, perfiles originales, persistencia/réplica).

- `colectivas.txt`: 50 comprobaciones, 0 fallos.
- `tareas.txt`: 16 comprobaciones, 0 fallos; integración con el contrato individual anterior.

Ejecutar desde la raíz, usando el Godot del proyecto:

```sh
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --path Linde/cenital --log-file /tmp/linde-colectivas-engine.log --script tests/prueba_demandas_colectivas.gd
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --path Linde/cenital --log-file /tmp/linde-tareas-engine.log --script tests/prueba_tareas.gd
```

Alcance: stock/reservas/compromisos, garantías y su sustitución por stock, tareas en curso, continuidad de insumos, conservación del transporte, bloqueo y metas no duplicadas; adaptador regional pasivo, publicación por minuto, guardado/carga y bienvenida de réplica en proceso. Sin suites históricas, simulación prolongada, sockets ni Internet. Los avisos de certificados/recursos al cerrar quedan en los registros; las pruebas terminan con código 0.
