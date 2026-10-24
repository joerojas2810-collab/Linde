# E04 v002 — candidato para revisión

Terreno con 47 conexiones por material; agua con cuatro cuadros; árboles de 48 y 64 píxeles, copas separadas y estados agotados reutilizados.

## Realizado

Se revisó el inventario de PNG del repositorio (2057 archivos, 546 hashes distintos), se conservaron los originales y se reutilizaron las fuentes disponibles. Esta iteración no realizó generaciones de imágenes nuevas. Los lotes v001 permanecen intactos.

La vista de Godot usa los datos del mapa y las reglas originales de movimiento/colisión, congeladas y verificadas por hash. El proyecto de prueba no escribe partidas. Las capturas son del prototipo aislado; no acreditan integración en el juego activo.

Validación de Godot: 1303 comprobaciones, 0 fallos. Las comprobaciones independientes y de reproducibilidad están en validacion/. La reproducción conservó los hashes de los recursos.

## Parcial y pendiente

Revisión visual de árboles de 64 píxeles, bordes y agua; aprobación de escala/paleta. Falta aceptación artística e integración en el juego activo. No se verificaron red, exportaciones ni partidas multijugador. No hay bloqueos para revisar esta propuesta.

## Contrato y reutilización

Celda lógica de 16 píxeles. Las dimensiones visuales y pivotes no cambian por sí solos las colisiones. Los JSON de assets documentan conexiones, geometría y fuentes. Los originales, recortes y recibos de reutilización están en fuentes/. En la 05, la dependencia de la 04 está congelada por versión y hash.

Procedencia: recursos existentes del proyecto y derivados de sus píxeles. Se conserva su régimen de derechos; esta entrega no concede una licencia nueva ni declara los recursos de dominio público. Los hashes y rutas de origen se conservan en los recibos de fuentes y la auditoría.

## Cómo revisar

Abrir GALERIA.html. Para el prototipo, importar lotes/E04_v002/project.godot en Godot 4.7.1 y ejecutar la escena principal. WASD mueve; 1–4 cambia vistas; T alterna árboles; O cambia copas; F1 muestra colisiones; Esc sale. En la 05, C alterna la puerta visual.

Desde la raíz de esta entrega: python herramientas/E04_continuar.py reconstruye los recursos con Pillow; python herramientas/E04_validar_v002.py ejecuta la verificación independiente (Pillow y NumPy). Las capturas requieren Godot y no se regeneran con esos comandos.
