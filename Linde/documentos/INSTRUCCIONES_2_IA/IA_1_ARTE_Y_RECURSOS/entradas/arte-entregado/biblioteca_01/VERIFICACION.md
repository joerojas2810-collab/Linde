# Verificación de la biblioteca

23 de octubre de 2026. Motor local: Godot 4.7.1; capturas con OpenGL/Metal en Apple M3.

## Comprobaciones ejecutadas

- `mapa_muestra/tests/prueba.gd`: **159 comprobaciones PASS**, `FALLOS: 0`, salida 0 y sin `SCRIPT ERROR`. Incluye reglas, guardado, navegación, equipo y pruebas del cargador de capas con PNG temporales.
- `mapa_muestra/tests/prueba_ui.gd`: **12 comprobaciones PASS**, `FALLOS_UI: 0`, salida 0 y sin `SCRIPT ERROR`.
- Registros completos: `prueba.log`, `prueba_ui.log`, resumen `verificacion_pruebas.json`.
- Personaje: dimensiones exactas de3 atlas,48 cuadros no vacíos,4 cuadros distintos por dirección, alpha0/255, máscaras disjuntas con reconstrucción byte a byte de la caminata. Ver `personaje/validacion.json`.
- Enemigos:3 atlas y60 cuadros, alpha binaria, contenido y márgenes revisados. Ver `enemigos/validacion.json`.
- Escenario/interfaz/enemigos: auditoría cruzada de76 PNG listados; rutas y tamaños coincidentes, contenido visible y sin alpha parcial.
- Interfaz: panel de nueve regiones con márgenes 8, ampliado a 3 tamaños; esquinas preservadas y revisión visual de `interfaz/prueba_ninepatch.png`.
- Equipo: poses estáticas y pruebas de máscaras tienen sus comprobaciones y estado por separado; no se extrapolan a caminata o combinación válida.

## Evidencia visual

`personaje/galeria.png`; `escenario/catalogo.png`; `interfaz/galeria.png`; previews y capturas de cada enemigo; capturas del mapa `captura_biblioteca.png`, `captura_ataque.png`, `captura_herramienta.png`, `captura_inventario.png`. Las imágenes del mapa provienen de ejecuciones reales del motor. Las poses de ataque y herramienta de esas capturas se prepararon en memoria para comprobar su presentación; no representan una partida guardada ni un combate completo jugado manualmente.

## Incidencias encontradas y tratadas

La primera adaptación del cargador a texturas importadas rompía las pruebas que generan PNG en tiempo de ejecución. Se corrigió para usar recursos importados en `res://` y mantener el camino dinámico para archivos temporales. Después se repitieron ambas suites y se inspeccionaron también los mensajes de script: no se confía únicamente en el contador final del test.

El cargador del escenario se cambió a Texture2D importada en la muestra, evitando los avisos anteriores de cargar archivos fuente PNG. Esto no constituye una prueba de exportación: no se produjo un ejecutable distribuible.

Los errores de parseo JSON que aparecen en `prueba.log` son provocados por las pruebas de guardados corruptos; sus recuperaciones se comprueban a continuación. La escena heredada informa recursos/instancias todavía en uso al cerrar. No se presenta como un cierre limpio ni se oculta el aviso en los registros.

## Lo que no verifican estas pruebas

No certifican calidad artística, fluidez de todas las transiciones, paleta global, juego balanceado, contenido narrativo final, colisiones nuevas ajustadas a cada ilustración, exportación ni compatibilidad con otras plataformas. Los límites específicos de cada recurso figuran en sus documentos de sección.

## Equipo ajustado

Se intentó una edición para aislar las piezas; el primer resultado desplazaba la coraza y se conservó como rechazado. Una pasada técnica posterior filtró materiales y ajustó proporciones/anclas en celdas32. El conjunto nuevo de `equipo/overlays_ajustados/` se probó sobre la base y en el mapa: capturas `captura_equipo_frente.png`, `captura_equipo_derecha.png`, `captura_equipo_espalda.png`, `captura_equipo_izquierda.png`. Las piezas se pueden combinar estáticamente; no están sincronizadas con la caminata ni las acciones. No se declara resuelto el agarre de manos o todas las oclusiones.
