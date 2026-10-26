# Arte pendiente — revisión completa 01

Base: 03fc1b8, 25/10/2026. Borrador integrado localmente, sin commit/push; aprobación visual final pendiente. Primer lote de minerales aprobado anteriormente.

## Alcance y procedencia
Tres nuevas generaciones integradas image_gen: mundo (24 objetos), fauna (15 orientaciones base de las 5 criaturas), equipo (6 armas/escudos, 8 conjuntos y 4 accesorios de oficio). Fuentes y prompts se conservan en arte/pendientes_v1. Recorte y derivación nativos de Godot; no llamadas API adicionales. Se corrigieron gutters, margen del letrero y encaje de equipo. Los nuevos cascos del jugador no se aplican: se conserva la cara y el casco aprobados; la armadura media también se mantiene. Ligera y pesada usan 32 capas nuevas de cuerpo.

## Integrado
Tres variantes de roca, dos arbustos con bayas adicionales, arbusto agotado por bioma, peñasco/pino ralo, árbol seco/espinoso/arenisca, arbusto de flores, juncos/cañas, helecho/tronco. Los árboles de clima seco o alpino se asignan a árboles existentes y sus transiciones; no se crean nuevas celdas ni recursos. Helechos, troncos y juncos son decorativos y no alteran paso o botín.

Fauna: se conservan el frente original y las mismas cinco especies fantásticas. Tres vistas nuevas por criatura con 60 tiras para idle/attack/hit/defeat; animación derivada por código a partir de cada pose (desplazamiento, compresión), no arte manual de todos los cuadros. El resultado sigue pendiente de revisión en movimiento. No se crearon animales reales nuevos, opción no seleccionada.

Espadas/escudos: tres siluetas de cada uno según arquetipo, manteniendo paletas/atributos y acciones. Armaduras ligera y pesada con nuevas capas, media/cascos conservados.

Habitantes: accesorios para agricultor/explorador/mercader/guardia; iconos con movimiento leve para vigilar/explorar/comerciar, sin nuevas animaciones corporales de oficio. Marcas de visitante/aspirante/residente/ausente. Ficha con retrato y datos existentes (V o J), incluidos ausentes. Se muestra explícitamente la falta de biografía cuando procede. Petate y pose de sin_cama, sin añadir fogatas ni sistema de campamentos. Casa comunitaria: una cama base, dos jergones y letrero; se reconocen solo las piezas del plano comunitario real.

## Validación acotada
Seis pares de entornos reales (misma semilla/cámara/hora), cuatro pares de láminas controladas (fauna/equipo/oficios/casa) y ficha de un colono generado por el sistema. La muestra de dormir fuerza sin_cama en un personaje de prueba; las profesiones/estados de la lámina son demostraciones de sus dibujantes, no sucesos espontáneos. QA: catálogo de 24 objetos y 60 tiras presentes, seis siluetas de arma/escudo distintas, biografía generada real, ficha ausente y cierre aprobados; sin faltantes en cargadores comprobados. Persisten avisos de cierre (30 ObjectDB/13 recursos en QA; 46/13 en captura de dos escenas). Se corrigieron errores iniciales de rutas, argumento de herramienta de la lámina y gutters durante la elaboración. No se repitieron suites generales ni red.

## Qué no cambia
Reglas, colisión, terreno, densidades, daño, botín, profesiones, permanencia y tiempos. Personaje aprobado, UI general, frentes y especies de fauna, cascos y equipo medio. Estos cambios no resuelven el balance de arraigo, construcción o rendimiento de simulación.

Galería: outputs/Arte_pendiente_completo/revision_01/GALERIA.html. Estado: revisión visual pendiente, sin commit/push.

## Integración 5b87517
Se conservan art2, el útil confirmado y el durmiente proyectado sobre la cama. Indicadores de oficio/ocupación/permanencia, azada y marcas de bayas ahora son PNG rasterizados desde su fuente editable, sin nuevas excepciones procedurales. 60 + 49 comprobaciones específicas y QA de arte/art2 aprobados; sin commit/push.

## Publicación autorizada — 25/10/2026

El usuario solicitó commit y push de esta integración sobre 5b87517. La evidencia vigente se conserva en `production/qa/evidence/arte-pendiente-integrado/`; los estados de borrador y sin publicar anteriores son históricos. Se mantienen los límites artísticos y de pruebas documentados; la publicación se identifica en el historial de Git.
