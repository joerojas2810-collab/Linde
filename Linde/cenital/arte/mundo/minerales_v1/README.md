# Minerales y arcilla — borrador visual 01

25/10/2026, sobre 03fc1b8. Ocho sprites propios, llenos y agotados; una generación integrada image_gen. Fuente y prompt junto a los PNG. Recorte nativo Godot con gutters corregidos (la división uniforme incluía parte del pozo en la celda del estaño). PNG nativos 96x96 dibujados sobre canvas48, pivote24,43. No cambia la escala lógica, colisión, botín o regeneración.

Registrados en E04_objetos.json; ambos dibujantes pasan por RECURSOS_PROPIOS sin recolorear estas piezas. Se conserva TINTE_MENA para compatibilidad con otros recursos.

Revisión gráfica breve: ocho estados dibujados sin faltantes y sin cambios en m.estado. Comparativa controlada del valle, con colocación de recursos de prueba. La primera captura anterior se obtuvo antes de cambiar el dibujante. La aserción inicial sobre todo j.d se sustituyó por m.estado porque los sistemas nuevos inicializan información de actor al consultar la UI. La revisión posterior de m.estado pasó. Avisos de cierre: 30 ObjectDB y 13 recursos. No se ejecutaron suites generales ni red.

Estado: borrador local integrado para revisión; sin aprobación visual final ni commit/push. Comparación en outputs/Arte_minerales/revision_01/GALERIA.html.

## Publicación autorizada — 25/10/2026

El usuario solicitó commit y push de esta integración sobre 5b87517. La evidencia vigente se conserva en `production/qa/evidence/arte-pendiente-integrado/`; los estados de borrador y sin publicar anteriores son históricos. Se mantienen los límites artísticos y de pruebas documentados; la publicación se identifica en el historial de Git.
