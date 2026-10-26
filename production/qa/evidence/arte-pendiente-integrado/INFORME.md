# Integración local sobre 5b87517 — 25/10/2026

Se consultó GitHub y se avanzó main de 03fc1b8 a 5b87517. Se reaplicaron los cambios de arte y se resolvieron tres conflictos (arte_entornos, escena y documento de pendientes). No se hizo commit ni push.

Conservado del remoto: art2, operadores/saberes, huella de reglas y errores de carga; herramientas de extracción confirmadas (incluido golpe final y estaño), mano delantera/oclusión del útil; dormir proyectado sobre la cama real y cobija. Durmientes en cama usan el comportamiento remoto; sin_cama añade el petate, manteniendo pies lógicos. Accesorios de oficio se omiten al dormir. Se admite cobija del nuevo jergón para las piezas comunitarias.

Compatibilidad del nuevo follaje: natural recibe el área de acción y atenúa solo árbol/arbusto, respetando la política de la corrección A2. Minas y rocas conservan su oclusión. Los indicadores de profesión, ocupación y permanencia, la azada y las bayas son sprites PNG derivados del fuente nativo revisado; se reduce el máximo procedural de suelo 15→13 y no se añaden excepciones.

Verificación dirigida sobre esta base:
- prueba_integracion_visual_a.gd: 60 comprobaciones, 0 fallos.
- prueba_correcciones_a2_a3.gd: 49 comprobaciones, 0 fallos.
- revision_arte_pendiente.gd: catálogo, 60 tiras, 6 siluetas, ficha generada/ausente y cierre aprobados.
- Captura de integración: cama/petate, extracción aceptada de estaño y equipar/quitar una espada art2 aprobados.
- Auditoría textual de límites de dibujo: conforme, sin primitivas nuevas.
- Los archivos de artesanía, equipo, juego y desarrollo permanecen sin cambios respecto a 5b87517.

El primer intento A1 falló por CRLF locales del mapa de iconos; se restauraron solo sus saltos LF después de comprobar igualdad exacta con el blob remoto y su SHA. No cambió el contenido ni el manifiesto.

La importación finalizó correctamente. Persisten avisos conocidos al cerrar el motor. No se repitieron suites generales ni red ni secuencias largas. Las cuatro capturas son escenarios controlados en memoria, sin partidas del usuario. La galería original anterior a esta integración se conserva como evidencia histórica.
