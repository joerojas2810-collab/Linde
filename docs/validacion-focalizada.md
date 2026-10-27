# Validación focalizada de red y rendimiento

**Estado al 2026-10-27: no ejecutada en este entorno.** No se encontró `godot`, `godot4` ni `herramientas/runtime`; por tanto no hay resultados dinámicos aprobados. La revisión sintáctica y de JSON no sustituye a Godot.

## Preparación y registro

En una máquina con Godot 4.7.1:

```bash
cd /ruta/a/Linde
export GODOT=/ruta/a/Godot
"$GODOT" --version
```

Guardar logs fuera del repositorio y revisar `git status` al terminar. Algunas pruebas regeneran evidencia bajo `production/qa/evidence` o `Linde/cenital/tests/resultados_red.txt`; respaldar primero los archivos existentes y no conservar resultados accidentales.

## Comandos reproducibles

```bash
# Intenciones de misión: aceptación, condición, recompensa única y que la réplica no la muta localmente.
"$GODOT" --headless --path Linde/cenital --script res://tests/prueba_misiones_red.gd

# Dos procesos cliente/servidor: movimiento, permisos, acciones compartidas, persistencia del mundo en expansión.
"$GODOT" --headless --path Linde/cenital --script res://tests/prueba_crecimiento_red.gd

# Dos clientes reales por sockets locales, salida/reconexión y guardado; incluye métricas del servidor.
"$GODOT" --headless --path Linde/cenital --script res://tests/prueba_red.gd

# Coste de simulación aislada (sin red ni combate); repetir en la misma máquina para comparar.
"$GODOT" --headless --path Linde/cenital --script res://tests/medir_equivalencia.gd -- semilla=123 dias=4 modo=poblado

# Tamaño de guardado/réplica/instantánea y microtiempos existentes.
"$GODOT" --headless --path Linde/cenital --script res://tests/medir_i1a.gd
```

`prueba_red.gd` publica p95/máximo del tick y bytes enviados en `registro.json`; verifica p95 < 16,67 ms. `prueba_crecimiento_red.gd` cubre dos clientes y cambios de regiones, pero no mide aisladamente el tiempo de carga de cada región. `medir_equivalencia.gd` no simula red ni carga/guardado. `medir_i1a.gd` informa bytes del guardado, no latencia aislada de escritura.

## Verificaciones manuales que siguen pendientes

1. **Misiones con dos clientes:** usar un mundo desechable con modo campaña y propuestas habilitadas. Conectar dos clientes; aceptar «Una cama de huésped» desde uno; comprobar que ambos ven el estado activo; construir una cama libre; entregar desde el otro; comprobar que XP y fibra se asignan solo al completador. Guardar, cerrar, reiniciar y reconectar ambos; confirmar misión completada y recompensa sin duplicación. El test automatizado `prueba_misiones_red.gd` cubre el despacho y reglas en proceso, no dos sockets ni reconexión.
2. **Frecuencias y coherencia:** mantener a dos jugadores moviéndose durante 10 s y comprobar aproximadamente 200 instantáneas recibidas por cliente (20 Hz), sin saltos que excedan la velocidad del servidor. Ejecutar una acción que modifique inventario/estado privado y otra que cambie `mundo_vivo`; anotar tiempo de servidor y recepción en ambos clientes. El estado durable/privado debe reflejarse en hasta 250 ms más latencia de red; ningún cliente debe escribir la autoridad localmente.
3. **Regiones y guardado:** con el Profiler de Godot, medir por separado la primera carga y el cruce de un límite de región, anotando p50/p95/máximo de `actualizar_regiones`. En una copia desechable del mundo, medir el tiempo de `j.guardar` y registrar tamaño del archivo y del respaldo. No comparar tiempos de máquinas distintas como prueba de igualdad.

Registrar versión/build del motor, sistema, semilla, número de clientes, RTT/red, logs completos y los valores anteriores. No ampliar usuarios ni declarar rendimiento aprobado basándose solo en localhost.
