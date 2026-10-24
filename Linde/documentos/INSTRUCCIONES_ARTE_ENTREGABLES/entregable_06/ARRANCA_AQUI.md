# Entregable 06 — INTERFAZ_Y_TRATAMIENTO_VISUAL

Objetivo: Interfaz, tipografía y propuesta de iluminación/sombras.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E06. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Reutilizar37 PNG de interfaz, panel nueve regiones e iconos existentes. El escudo genérico ya existe. Completar necesidades por ID: salud/XP, cantidades, selección/foco, inventario/equipo, diálogo y menú. Entregar márgenes nueve regiones y tamaños admisibles; relleno44×5 es válido, no exigir múltiplos16 globalmente. Verificar licencia de cualquier tipografía nueva y adjuntarla.

Revisar contraste y paleta en una composición de HUD con escenario de referencia. Proponer sombras y luz día/noche como tratamiento de presentación, sin nuevo gameplay. No implementar cambios en hud.gd ni recolorear los PNG de otros lotes. Las recomendaciones globales de paleta van en PROPUESTAS.md para decisión del coordinador; no son autoridad unilateral. Los otros lotes pueden avanzar con la referencia común mientras se resuelve esa propuesta.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_06/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E06_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
