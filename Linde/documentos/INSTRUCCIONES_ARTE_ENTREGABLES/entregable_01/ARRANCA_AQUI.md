# Entregable 01 — ATAQUE_EQUIPO

Objetivo: Completar las nueve celdas de ataque y la estela separada.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E01. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Usar como autoridad contexto/PENDIENTE_DE_ARTE.md y auditorias/auditoria_estetica_actores.md. Coordenadas cero-base [fila,columna]: ligera_torso[0,2]; ligera_botas[1,2] y[3,2]; media_torso[0,2]; media_botas[1,2]; pesada_torso[0,2],[1,2],[1,3]; escudo[0,2]. Los nombres completos están en el documento original.

Conservar todas las demás celdas aceptadas. Entregar hojas completas corregidas y comparación por celda que demuestre qué cambió. Ataque usa atlas192×192/celda48×48/pivote[24,48], cuatro direcciones y cuatro fases. Reutilizar base y17 hojas actuales; no rehacer caminata. Estela: capa independiente, documentar posiciones y fase. No incluir efectos de impacto, que pertenecen al03. No ejecutar derivar_ataque.gd sobre el único original: sobrescribe archivos. Mantener correcciones como entradas/overrides reproducibles.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_01/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E01_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
