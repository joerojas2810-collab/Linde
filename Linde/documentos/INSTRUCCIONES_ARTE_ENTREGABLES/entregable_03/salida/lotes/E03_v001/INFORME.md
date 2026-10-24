# E03_v001 — Enemigos, NPC modulares y efectos

## Hecho

Tres atlas ampliados de Linde (Slime, Guardián y Ciervo),9 columnas×4direcciones. Se conservan60 celdas previas byteidénticas, se reutilizan12 celdas de reposo para recuperación y se añaden36 celdas de daño/derrota. Pivotes y paletas previas conservados, alfa binaria y sin cuadros vacíos. Fuente image_gen/prompts y pipeline Godot reproducible incluidos.

Maren como preset de siete capas del PJ, copiadas byteidénticas, y dos combinaciones de demostración. Una sola base compartida PJ/NPC. Su hoja generada independiente es referencia opcional, no la ruta principal. No hay delantal modular ni nuevas geometrías de peinado/prenda presentadas como hechas.

Tres atlas FX (impacto,daño,recolección), helper/contrato de señales ajustadas al combate actual. Auditoría del otro proyecto y selección de sus referencias; cinco familias/nueve jefes no equivalen a incorporación automática. No se trae combate por turnos, estadísticas ni narrativa ajena como canon de Linde.

Preview Godot independiente con ocho capturas1280×720 y galería con reproductor de atlas por estado/dirección. Escenario de prueba usa assets históricos para comparar a zoom3; no es el juego activo ni un nuevo mapa. Diferencia de detalle de casa/actores observada por usuario y registrada para coordinación04/05/06.

## Verificado

Estructura, celdas y alfa; conservación exacta de cuadros previos y colores; hashes de siete capas;15 pruebas de geometría FX del subagente; generación/relectura de tres atlas FX; ejecución gráfica Godot4.7.1 con exit0 y ocho capturas conservadas. Logs y verificaciones específicas en subcarpetas. No se ejecutaron suites del juego ni pruebas de red porque el runtime no se modifica.

## Pendiente

Aceptación visual y decisión global de detalle; integración productiva/QA local y remoto. Faltan eventos gráficos/identidad estable de enemigos remotos para reacciones y residuos de derrota fiables: el snapshot actual no basta para correlacionar por índice. Estado real, recompensas, temporizadores y colisiones deben seguir intactos. No se conectó Maren a la rutina ni se implementó un sistema nuevo de partes en producción; se reutiliza/proporciona el contrato del ya existente.

No se adaptaron todos los mobs/jefes del otro proyecto. Quedan catalogados/propuestos por diseño y familia para decidir qué aporta al mundo, sin equiparar variantes elementales a criaturas nuevas. Nuevos peinados/prendas son piezas futuras, no combinaciones geométricas ya disponibles.

## Alcance y coordinación

Solo salida03. Sin cambios en01/02/04/05/06 ni en los proyectos fuente. Cuatro especialistas: enemigos/coordinación por agente principal, Maren modular, FX y auditoría/selección de fuentes. Resultado recogido y revisado; ninguna aprobación de usuario simulada. Git base42292a0b25554ef46cd914d95e91fc0590f68d9e. Sin commits/push.
