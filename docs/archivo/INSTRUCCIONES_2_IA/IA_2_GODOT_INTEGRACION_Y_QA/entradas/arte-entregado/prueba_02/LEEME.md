# Linde — recurso nativo y prueba en mapa

2026-10-23 · prueba 02 · dirección visual aprobada; resolución todavía de prueba.

## Resultado

Se preparó una variante de limpieza con la herramienta integrada de imágenes y una conversión técnica reproducible en Godot (`convertir.gd`). El original generado permanece intacto. No se usó Python para modificar imágenes; PIL se utilizó solo para medición y verificación independiente.

El atlas `mapa_prueba/arte/personaje_cuerpo.png` mide 128×128, dividido en celdas 32×32. Las filas corresponden a frente, derecha, espalda e izquierda. Las cuatro columnas repiten la misma pose: **no es una caminata animada**. `personaje_quieto_128x32.png` permite ver las cuatro orientaciones en una tira.

El cuerpo visible ocupa 15×27 px, con bbox (8,5)-(23,32) en cada celda y apoyo en el límite inferior y32. No se ensanchó el personaje para llenar el lienzo. Transparencia binaria y 32 colores opacos compartidos, escogidos provisionalmente para esta prueba; no es la paleta definitiva del proyecto. Conversión: recorte por alpha>=0.5, nearest a27px de altura, centrado y reducción de paleta común mediante k-means determinista. No sustituye una revisión artística manual de cada píxel.

## Evidencia

- `validacion_atlas.json`: medidas, alpha0/255, paleta y cuadros repetidos, comprobados independientemente por otro agente.
- `mapa_frente.png`, `mapa_derecha.png`, `mapa_espalda.png`, `mapa_izquierda.png`: capturas en Godot del personaje junto a la casa real del mapa.
- `mapa_cofre_*.png`: vistas de la misma prueba junto al cofre de la cantera.
- Motor: Godot4.7.1, OpenGL/Metal, AppleM3. Se ejecutaron importación, conversión y capturas. No se volvió a ejecutar la batería completa de lógica del juego: no se modificó esa lógica.

Se conserva una **copia aislada** del proyecto cenital en `mapa_prueba/`. No se modificó `juego/cenital` del proyecto del escritorio ni su partida. Los NPC y el escenario conservan su arte provisional; solo se evalúa el personaje y su escala, no la calidad final del mundo.

## Abrir la prueba

Abrir `mapa_prueba/project.godot` con Godot. También:

```sh
Godot --path /ruta/mapa_prueba -- --nueva=7 --ir=27,24 --guardado=/ruta/temporal.json
```

Para reproducir capturas:

```sh
Godot --path /ruta/mapa_prueba --script res://capturar_arte.gd -- --nueva=7 --ir=27,24 --guardado=/ruta/temporal.json
Godot --path /ruta/mapa_prueba --script res://capturar_cofre.gd -- --nueva=7 --ir=6,8 --guardado=/ruta/temporal.json
```

Los scripts de captura guardan PNG en la carpeta superior y cierran la ejecución. Requieren renderizado gráfico, no headless.

## Límites y observaciones

- Capa `cuerpo` = personaje completo compuesto. La personalización por piel, ropa o pelo aún no está conectada a este recurso.
- El fallback procedural conserva su formato16×24; el atlas utiliza32×32. Son caminos de dibujo diferentes, no un cambio de tamaño de colisión. La cuadrícula del mundo continúa en16px y el zoom en3.
- El cargador heredado usa `Image.load_from_file` para el atlas. Godot avisa que hay que adaptar la carga para una exportación empaquetada; la prueba se ha ejecutado desde el proyecto, no desde una exportación.
- El cierre de la escena heredada informa9 instancias ObjectDB y4 recursos todavía en uso. Las capturas se completaron, pero no se afirma un cierre sin avisos ni un juego listo para distribuir.
- No hay herramientas, ataques, equipo por capas ni animación nueva. Las cuatro poses estáticas permiten juzgar dirección y proporciones.

## Procedencia y continuación

Ver `PROMPT.md`; la fuente de diseño es el personaje de la prueba01 que el usuario consideró adecuado. Se mantiene el original generado para trazabilidad. No se incorporó arte de Pokémon ni recursos propietarios de Helbreath.

Antes de ampliar producción, revisar visualmente la versión nativa junto a la casa y el cofre. Después: corregir píxeles si corresponde, fijar el formato y producir caminata y capas usando esta misma base. No dar por aprobada la paleta o la resolución final solo porque el contrato técnico pase.
