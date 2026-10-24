# Linde — lote 1 de equipo con colores índice

23 de octubre de 2026. Entrega de recursos de caminata según la copia adjunta de `design/art/contrato-equipo.md`. No redefine el juego ni sustituye su repositorio actual.

## Entregado

**17 hojas en `hojas/`:** cinco ranuras —casco, torso, guantes, botas y pantalones— por cada arquetipo ligera/media/pesada, más un escudo y una espada compartidos. Todas miden 128×128, con 4 columnas y 4 filas de celdas 32×32. Filas: frente, derecha, espalda, izquierda. Columnas: reposo, pasoA, transición, pasoB.

Los PNG de entrega utilizan exclusivamente los índices permitidos: rojo `#FF0000`, verde `#00FF00`, azul `#0000FF` y gris `#808080`, con alpha 0/255. No es necesario que cada pieza utilice los cuatro colores; ninguna usa colores adicionales. El rojo corresponde al material principal, no al color final visible en el juego.

**Validación:** 17/17 hojas, salida 0, cero errores y cero avisos, ejecutando el validador original con `--modo=indice --celda=32 --base=base/caminata.png`. Un segundo agente repitió la validación de forma independiente. Los informes individuales están en `informes/`; resumen en `RESUMEN_VALIDACION.json`; auditoría independiente en `fuentes_arquetipos/AUDITORIA_FINAL.md`.

## Reutilización

- Arquetipo medio: casco y torso reutilizados de los overlays ajustados de biblioteca_01.
- Escudo y espada: reutilizados de aquella misma entrega; se redujeron y anclaron a las manos para cumplir la silueta±3px del contrato.
- Guantes, pantalones y botas: derivados de las manos, piernas y pies de la caminata ya existente. Las protecciones pesadas amplían algunas coberturas de forma local.
- Ligera y pesada: solo se generaron diferencias de silueta de casco y torso mediante una edición referenciada. Original, prompt, extracción y límites se conservan en `fuentes_arquetipos/`.
- Guantes ligera/media y pantalones media/pesada comparten píxeles deliberadamente. Hay 17 archivos contractuales, no quince diseños completamente nuevos de piezas.

La base conserva exactamente su hash original. No se retocó para conseguir que pasara el validador. Los archivos fuente reutilizados también se preservan sin sobrescribirlos.

## Cómo se acompañó la caminata

Casco y torso se transportan sobre las variaciones reales del contorno de la base, por línea horizontal y por cuadro. No se añadió balanceo artificial ni se alternaron colores para eludir el aviso de pose repetida. Manos y piernas toman los cambios de posición presentes en los cuadros originales. Armas se anclan a las manos siguiendo la lateralidad del contrato.

Los cambios mínimos de contorno de la base también pueden contener irregularidades del arte original. El resultado formal del validador no demuestra fluidez artística: revisar la reproducción, especialmente perfiles, agarres y piezas pequeñas.

## Ver y comprobar

- `GALERIA.html`: reproducción animada con elección de arquetipo/dirección, piezas individuales, índices y recoloreado de demostración. Permite pausar y avanzar cuadro por cuadro.
- `INDICE_RECURSOS.html`: enlaces a **todos los PNG**, incluidos originales y auxiliares; nada queda implícitamente clasificado como hoja final por estar en esta entrega.
- `previews/arquetipos_recoloreados.png` y `equipo_completo.png`: capturas reales en Godot de la escena independiente de encaje.
- Abrir `project.godot` para ver esa escena. Teclas 1–7 alternan piezas y Espacio pausa. No es el mapa actual del juego ni demuestra integración con su equipo/red/estado por jugador.

## Decisiones de trabajo y límites

Se emplean 32 px por celda, gris exacto `#808080`, una espada/un escudo comunes y perfiles sin invertir, tal como permite la propuesta de contrato. Son decisiones operativas para producir este lote; no se presentan como decisiones finales de diseño aprobadas.

Las paletas de las vistas coloreadas son ejemplos técnicos locales, no familias o variantes aprobadas del sistema de equipo. La sustitución de índices, variantes, ocultación de ropa base y renombrado torso/coraza aún deben conectarse en el código vigente. En la escena de encaje la ropa base permanece como interior bajo las piezas; el pelo se dibuja sobre armas y bajo casco. La capa única de guantes necesita revisar la mano lejana en perfiles.

Este lote no incluye hojas de herramienta ni ataque: corresponden al lote 2, que el contrato reserva para una petición posterior. No contiene copia antigua de `mapa_muestra/`, no reemplaza el juego actual y no afirma que sus pruebas de 232 comprobaciones se hayan ejecutado.

## Reproducir validación

Usar el validador original del proyecto:

```sh
Godot --headless --script /ruta/herramientas/arte/validar_hoja.gd -- /ruta/hojas/equipo_media_torso_caminata.png --celda=32 --modo=indice --base=/ruta/base/caminata.png --json=/ruta/informe.json
```

La copia en `herramientas/validar_hoja.gd` conserva el mismo hash que el original al entregar. `herramientas/producir.gd` documenta la adaptación técnica reproducible a partir de las fuentes incluidas. No modifica el validador ni el código del juego.
