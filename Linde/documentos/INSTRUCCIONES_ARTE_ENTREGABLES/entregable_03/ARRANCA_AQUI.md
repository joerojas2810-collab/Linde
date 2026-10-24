# Entregable 03 — ENEMIGOS_NPC_Y_EFECTOS

Objetivo: Completar enemigos, Maren y efectos generales.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E03. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Reutilizar tres atlas de enemigos existentes; sus cinco columnas no incluyen todos los estados. Completar daño, muerte, recuperación y pulido necesario; mapear anticipación/ataque a estados reales sin modificar tiempos, radios o hitboxes. Usar tamaños por enemigo conforme al atlas y contrato actual, no hitbox=tamaño PNG.

Crear Maren derivando identidad de la base existente, con cuatro orientaciones y contacto con el PJ. No cambiar rutinas o diálogos. Producir efectos de impacto, daño y recolección y propuesta de telegráficos legibles ajustados a geometría mecánica. Estela de espada pertenece exclusivamente a01; herramienta a02; iluminación ambiental a06. Cada efecto declara ancla, fases, duración visual y escala.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_03/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E03_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
