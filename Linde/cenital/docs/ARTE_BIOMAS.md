# Arte de biomas — 2026-10-24

Primera entrega integrada de superficies propias para los cinco biomas actuales. Bosque: musgo y hojarasca; sierra: suelo pedregoso gris; secano: tierra ocre seca; pradera: hierba con flores; ribera: agua azul verdosa.

Los recursos están en `arte/mundo/biomas/`. `fuente.png` es el atlas generado con la herramienta integrada image_gen; `PROMPT.txt` conserva el prompt completo y `manifiesto.json` registra procedencia y SHA-256. Cada panel se recortó por el centro y redujo con nearest a 32×32 usando Godot. Cada textura ocupa cuatro celdas de 16×16; el muestreo usa coordenadas globales con módulo positivo, sin reinicio en bordes de región.

`MundoArte.suelo()` integra los materiales. La transición desde el valle ocupa 12 celdas y entre suelos vecinos hay una mezcla de una celda. El agua conserva las conexiones y animación de las orillas existentes, armonizadas con tinte exterior; en el interior añade la textura propia con desplazamiento por cuadros. El valle mantiene su arte anterior. No cambian generación, semilla, recursos, colisiones ni guardado.

Alcance: superficies, no un paquete completo de vegetación. Árboles, arbustos, rocas y menas conservan sus sprites actuales. El patrón es periódico cada dos celdas y sigue visible en extensiones grandes; quedan posibles variantes adicionales y orillas propias como mejoras artísticas.

## Comprobación

Godot 4.7.1 importó las seis imágenes sin errores de script. `tests/prueba_terreno.gd`: 49 comprobaciones, 0 fallos; incluye huella del generador, guardado, colisión y réplica. Capturas de escena real inspeccionadas para valle, salida y cinco biomas en `production/qa/evidence/biomas/`.

Para repetir las capturas: ejecutar Godot con `--path Linde/cenital --script res://tests/captura_biomas.gd`. Requiere renderizador gráfico; no usar headless. La captura viaja mediante depuración, no es un recorrido manual. Persisten los avisos previos de recursos en uso al cerrar; el entorno restringido también emite un aviso de certificados del sistema en ejecución headless.
