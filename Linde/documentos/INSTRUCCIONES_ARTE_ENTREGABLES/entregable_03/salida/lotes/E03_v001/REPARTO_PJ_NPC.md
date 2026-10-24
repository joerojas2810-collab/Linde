# PJ y NPC: una base compartida, dominios separados

| Área | Entregable responsable | Interfaz que debe respetar |
|---|---|---|
| Ataque y equipo del PJ | 01 | Celdas48/pivote24,48; índices y capas ya definidos; no tocar desde03 |
| Herramienta y otros estados del personaje | 02 | Mismos estados/capas/anclas compartidos; coordinar cualquier ampliación común |
| NPC y Maren | 03 | Presets sobre la base existente y piezas específicas de NPC cuando se acuerden |
| Integración en el juego | Integrador único | Reutiliza compositor, caché y datos; no dos sistemas para PJ/NPC |

La base de caminata y sus siete capas ya existen. El03 entrega copias de referencia byteidénticas y presets, no una nueva base. Maren usa look[1,0,2] con las mismas capas cuerpo/piel/pelo/túnica/pantalón/botas/cinturón. Las otras combinaciones entregadas son ejemplos sin NPC nuevos de canon. Para producir más habitantes, combinar estos datos antes de solicitar imágenes nuevas.

Un recolor no crea un peinado distinto: nuevas geometrías de pelo/ropa/accesorios serían piezas reutilizables con el mismo pivote y contrato por estado/dirección. No se entregan todas esas variantes aquí. Cualquier extensión de estado común debe acordarse con02; el03 no cambia esos archivos ni los de01. Las prendas de equipo conservan oclusiones y orden del compositor actual.

La hoja Maren imagegen de la primera pasada se conserva como referencia opcional, no como ruta principal ni como requisito de un sistema por NPC. Sus rasgos exclusivos (p. ej. delantal) no se atribuyen al preset modular si no existe una pieza que los reproduzca.
