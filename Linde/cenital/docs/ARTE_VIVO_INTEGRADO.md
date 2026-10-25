# Arte vivo e interfaz integrados

La escena principal usa scripts/arte_entornos.gd y scripts/hud_vivo.gd, con ui_viva.gd. No requiere las carpetas de muestras.

## Acabado
Cinco biomas exteriores (bosque, pradera, sierra, secano, ribera), valle, cantera, ruinas e interior. Se conservan terreno, recursos, colisión, densidad de vegetación, personaje, cámara 3x y luz nocturna. Paletas por entorno, decoración agrupada, sombras de contacto y atlas original de objetos dibujado con más detalle; agua animada con tinte coherente en sus 47 conexiones. Enemigos y fauna conservan su arte actual.

## Interfaz
Mochila en cuadrícula de veinte celdas con paginación, siete ranuras de equipo, vista del personaje con sus capas reales, ficha de selección y acciones existentes. Navegación con flechas, Enter y ratón; cerrar con Esc o botón. Se conservan Nunito y Lora, ahora con más margen, centrado por métricas y elipsis en textos largos. HUD con cifras de vida/XP separadas de sus barras; indicadores de mundo ocultos mientras está abierto el inventario.

## Procedencia
arte/mundo/vivo/objetos_originales.png y atlas.json proceden sin cambios de Linde/arte-entregado/biblioteca_01/escenario/originales/objetos.png y config.json. Se reutilizan los iconos E06 y viajero071. Paneles y detalles ambientales se dibujan en Godot; no se añadieron generaciones de imágenes para esta integración.

## Comprobación breve
Ejecutar tests/revision_visual_integrada.gd con render gráfico y opcional -- --salida=<carpeta>. Verifica en la escena principal equipar/quitar, usar ungüento, navegación, última página, ayuda y disponibilidad de recursos; genera capturas de revisión con guardado aislado. La galería aprobada cubrió diez vistas (incluida noche) y verificó que el dibujante no modifica el estado persistente. No se repitieron suites generales ni pruebas de red. Persisten avisos de objetos y recursos en uso al cerrar Godot (28 ObjectDB y 12 recursos en esta revisión sobre 86ae9e2).

## Actualización de base
Se incorporó 86ae9e2 antes de publicar. Se conservan solares, casas, campos, puestos, minerales y orden estable de dibujo. La presentación hereda los nuevos tejados, puertas y cultivos de mundo_arte.gd. Prueba de orden de dibujo: 6 comprobaciones aprobadas.
