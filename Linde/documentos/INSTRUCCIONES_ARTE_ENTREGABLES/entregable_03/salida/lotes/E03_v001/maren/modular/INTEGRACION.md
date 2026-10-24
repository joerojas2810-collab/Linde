# NPC sobre la base compartida de LINDE

Propuesta principal: Maren es un preset `look:[1,0,2]` de las mismas capas que usa el PJ. No es un segundo sistema de sprites ni un personaje horneado independiente. `presets.json` incluye Maren y dos demostraciones de colores; las demostraciones no introducen NPC de canon.

Las siete imágenes en capas/ se copiaron byte a byte desde Linde/cenital/arte/equipo/base/capas. Cada atlas conserva128×128, celda32×32, pivote[16,32] y filas sur/este/norte/oeste. La geometría, poses y recursos se comparten; cambia solo el preset de color y equipo opcional.

## Integración propuesta sin modificar mecánicas

Reutilizar una instancia existente de `ArteEquipo`, no instanciarla en cada frame. `arte.capas_base(look)` obtiene las texturas base con la caché actual. Para dibujo completo usar `arte.comandos(pies, direccion_existente, cuadro_existente, equipo_visible, look, ArteEquipo.INVERTIR_PERFILES, estado_existente)` y dibujar cada comando conforme a `ArteEquipo.dibujar`. `equipo_visible` debe ser el resultado compatible de Equipo.visible más espada cuando corresponda; para Maren sin equipo, array vacío. No pasar IDs de inventario directamente como si fueran entradas renderizables.

Mantener dirección, cuadro y estado que la lógica ya determine. No cambiar horarios, rutas, velocidad, tiempos de combate ni diálogos para acomodar sprites. Si el NPC actual solo usa dirección fija, la conexión a dirección de su movimiento es una tarea del integrador, no una mecánica nueva.

Orden y oclusiones siguen `arte_equipo.gd`, no este preview. Torso oculta túnica; pantalones oculta pantalón base; botas oculta botas base, solo cuando la pieza se dibuja. El cinturón sigue visible. Pelo se dibuja antes de casco; la cobertura depende de píxeles del casco. Perfiles conservan escudo/espada delante/detrás según orden del runtime. No se declara resuelta la cobertura estética del cinturón o casco.

## Extensión modular posterior

Piel, pelo y túnica se tiñen según look; pantalón usa el color central P.PANTALON. Cuerpo/ojos, botas y cinturón mantienen colores de sus capas: no se inventan canales de personalización. Nuevos peinados o prendas con otra geometría serán piezas compartidas por estado/dirección/pivote y un selector explícito; no una hoja nueva por cada NPC. Eso requiere ampliar el contrato y la selección, no está implementado aquí. El delantal de la hoja imagegen opcional no existe como pieza modular y no se simula como si existiera.

## Preview reproducible y límites

Desde modular ejecutar Godot --headless --log-file /tmp/e03_modular.log --path . --script res://componer.gd. El script compone imágenes para inspección, no se integra en el runtime. Las funciones `tenir` y `valor_medio` se extrajeron sin cambios del original copiado en fuentes/arte_equipo.gd; parámetros se copian íntegros en fuentes/params.gd. Se comprueba igualdad textual del fragmento y SHA de las capas en validacion.json.

Las imágenes previews/*_compuesto.png son evidencia de composición, no fuentes que deban reemplazar capas en producción. Solo cubren caminata compartida; no inventan estados faltantes. Este kit es candidato y no aprobación del usuario.
