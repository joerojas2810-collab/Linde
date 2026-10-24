# Mapa de muestra · integración visual aislada

Copia del proyecto cenital del escritorio, sin cachés ni partidas. Solo `scripts/arte.gd` cambia la representación del escenario: texturas de terreno, vegetación, recursos, barril, valla, cofres, algunas construcciones y casa exterior. Reglas, generación, colisiones, inventario, enemigos y guardados se conservan. El personaje puede ser integrado por separado en esta copia.

## Verificación

Godot 4.7.1 sobre Apple M3, render GL Compatibility/Metal. `tests/captura_arte.gd` carga una partida temporal nueva semilla 1, usa los argumentos normales `--nueva=1 --ir=27,24`, captura `captura_escenario_27_24.png` a 1280×720 y termina sin guardar. Se comprobó el dibujo de la casa, pies de objetos y sustitución de sprites. No se ejecutó una prueba jugable completa de reglas tras esta adaptación exclusivamente visual.

## Decisiones de integración

- Celda de suelo 16 px y zoom del proyecto original. Árboles lienzo48, dibujados48 para mantener altura aproximada 1.5 veces el personaje; la propuesta32 del manifiesto de biblioteca resultaba demasiado pequeña al renderizar. Ajuste visual provisional.
- Roca/veta/arbusto/barril16, valla16 para conservar continuidad de celdas; cofre24, mesa/horno/cama24. Todos apoyados en centro inferior del lienzo con margen nativo2px.
- Camino/agua usan transición cardinal únicamente donde hay exactamente un borde. Esquinas múltiples conservan relleno: falta el autotile completo.
- Casa exterior es el PNG completo colocado en la entrada de fachada del orden por profundidad. Se omite tejado procedural exterior. El suelo exterior debajo de la casa oculta el antiguo borde rectangular, sin alterar celdas lógicas. Puerta de arte se aproxima a la puerta lógica; requiere validación de colisión y alineación final.
- Dentro de casa se mantienen fachada y tejado procedurales atenuados; interior de madera usa tile. La casa abierta no se alterna porque no está alineada con la cerrada.
- En el encuadre 27,24 el tejado/chimenea se recortan arriba por la cámara a zoom3 del proyecto original; no es un recorte del PNG. La escena es evidencia de integración, no un mapa terminado.
- Enemigos, habitantes, elementos sin recurso equivalente y muros construidos conservan dibujo anterior. Cueva/cobertizo no se insertaron como decoración nueva: sus ubicaciones lógicas no están definidas en esta muestra.

Este directorio no sustituye el juego del escritorio ni es una entrega de arte final.
