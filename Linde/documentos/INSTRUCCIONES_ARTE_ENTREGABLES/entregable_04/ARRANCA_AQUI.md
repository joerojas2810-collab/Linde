# Entregable 04 — TERRENO_Y_NATURALEZA

Objetivo: Terreno conectado y recursos naturales con sus estados.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E04. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Reutilizar tiles16 y vegetación/rocas48 existentes. Completar conexiones/bordes/esquinas/cruces requeridos por el mapa, comprobar repetición y proponer agua animada con contrato explícito. Producir árboles/tocones, roca/mineral agotado, arbusto con/sin bayas. Entregar copas separables cuando sea necesario y anclas/orden de profundidad.

No producir edificios, vallas, barriles, cofres ni construcciones (05). No colocar cueva o puente en mapa ni cambiar colisiones/cosecha/regeneración. Los estados agotados son representación del estado existente. Documentar escala nativa y dibujada:48→32 no garantiza densidad uniforme. Reutilizar paleta vigente como punto de partida; no recolorear recursos de otras entregas.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_04/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E04_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
