# Entregable 05 — EDIFICIOS_Y_OBJETOS

Objetivo: Casa modular, construcciones y objetos fabricados.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E05. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Reutilizar casa96 y objetos entregados. Separar/alinear fachada, tejado, interior y puerta sin saltos entre abierto/cerrado; respetar geometría lógica actual de casa/puerta. Completar vallas horizontal/vertical/esquinas, barril y cofre abierto/cerrado, empalizada, suelo de madera, banco, horno y cama según IDs actuales. Los recursos ya suficientes se entregan reutilizados con hash, no se rehacen.

Ghost de construcción puede derivar por tintado: no dibujar otro atlas sin necesidad. No editar terreno o vegetación (04). Puente/cueva/cobertizo solo referencias/preview separado; no crear acceso transitable ni ampliar mapa sin decisión expresa. Entregar capas, pivotes, bbox y orden de dibujo, no scripts productivos.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_05/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E05_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
