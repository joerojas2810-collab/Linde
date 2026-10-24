# E03 FX — Informe de entrega

## Hecho

- Tres atlas PNG originales y deterministas;12 celdas32×32, alfa0/255, máximo tres colores opacos por atlas, sin blur, gradiente ni dependencia de recursos del otro juego.
- Fuente Godot de generación; fichas con secuencia0–3, pivote16×16, ancla por evento, escala1 y duración estrictamente visual.
- Propuesta implementable de telegráficos como geometría dinámica, con helper puro de círculos/cápsulas y predicción por consulta de colisión sin mover enemigos.
- Godot4.7.1 ejecutó generación/relectura y15 comprobaciones geométricas: cero fallos en los reportes JSON. Se comprobaron bordes efectivos, centros, segmento nulo, paso2 y bloqueo simulado.
- Dos láminas retenidas, inspeccionadas visualmente, y galería local con atlas1:1, zoom3 y todos los cuadros a zoom6. Las imágenes son salidas diagnósticas generadas con Image, no capturas del juego ejecutándose.
- Huellas de `combate.gd`/`catalogos.gd` leídos y de los archivos entregados. Producción sin cambios.

## Parcial y pendiente

Arte de FX propuesto, no aprobado. Falta composición real sobre el mapa, lectura a zoom3 con enemigos/PJ, conexión de eventos confirmados, comportamiento local/remoto y comprobación de previsión contra obstáculos dinámicos del mundo autoritativo. No se emite aprobación del usuario ni se atribuye integración productiva a esta entrega. El resto de E03 (enemigos/Maren) se entrega por otros responsables.

## Incidencias de ejecución

El primer lanzamiento sin `--log-file` intentó crear la carpeta de usuario de Godot fuera del dominio autorizado y terminó con error de acceso/signal11. Se repitió con `--log-file` absoluto dentro de `qa/`; eso permitió finalizar ambas herramientas. Los intentos posteriores muestran advertencias de carpeta de usuario y certificados de macOS por las restricciones de este entorno; los JSON de validación se produjeron y fueron revisados. Los primeros errores de inferencia de tipos en el generador se corrigieron antes de emitir esta entrega. Los logs conservan el resultado final. No se concedió acceso ni se escribió en la carpeta de usuario de Godot.

En este entorno reproducir con log absoluto, por ejemplo:

```sh
Godot --headless --path /ruta/efectos --log-file /ruta/efectos/qa/godot_generacion.log --script res://fuentes/generar.gd
Godot --headless --path /ruta/efectos --log-file /ruta/efectos/qa/godot_geometria.log --script res://fuentes/verificar_telegrapho.gd
```

No se ejecutó una suite de juego ni un playtest de producción. La validación es del sublote y de sus funciones visuales.
