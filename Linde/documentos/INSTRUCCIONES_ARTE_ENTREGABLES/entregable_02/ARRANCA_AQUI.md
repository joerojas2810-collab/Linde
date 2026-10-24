# Entregable 02 — PJ_HERRAMIENTA_Y_ESTADOS

Objetivo: Herramienta, daño, caída/dormir y revisión de oclusión del personaje.

## Arranque

Lee ../ARRANCA_AQUI.md, ../REGLAS.md y ../ESTADO_VERIFICADO.md. Tu identificador exclusivo es E02. Lee el contexto técnico y las auditorías pertinentes. Entradas compartidas ../contexto, ../base_proyecto y ../entradas son SOLO LECTURA. Puedes producir recursos y herramientas/previews aislados; no editar scripts del juego activo.

## Alcance exacto

Reutilizar entradas/arte-entregado/biblioteca_01/personaje/herramienta.png. Separar base/capas y equipo por arquetipo sin rediseñar identidad ni caminata. La fuente tiene cuatro poses; el runtime actual declara tres cuadros/.3s. Proponer mapping de poses conservando tiempos; requiere confirmación de compatibilidad antes de cerrar contrato. Daño declara dos cuadros/.6s. Caída y dormir están declarados pero su presentación no está conectada: entregar propuesta técnica sin inventar eventos ni cambiar reglas.

Incluir contacto de cuatro direcciones/tres arquetipos y decidir con muestra cinturón/pelo y mano lejana. No modificar hojas de ataque (01), Maren (03) ni efectos de impacto (03). Herramienta/arma usada en estas poses pertenece a02. No regenerar caminata ni variantes de color existentes. Dimensiones nuevas son propuesta hasta aceptación del integrador; no imponer32 a todo.

## Dominio exclusivo de escritura

Escribe solamente en `entregable_02/salida/`. Allí van contratos, candidatos, herramientas, previews, fuentes, lotes y reportes. Prefijo de ID `E02_`; nombres internos de integración se proponen en manifiesto, no se escriben directamente sobre rutas productivas. Si otro entregable necesita un recurso tuyo, lo consume por versión/hash y no lo modifica. No tocar registros, instrucciones o salidas ajenas.

Puedes delegar dentro de tu dominio: asignar carpetas separadas por especialista y reservar un único agente para consolidar tu manifiesto. No delegar escritura de entradas comunes. No iniciar otros entregables sin asignación del coordinador.

## Secuencia y cierre

1. Inventario reutilizado/ajustado/nuevo y pendientes, con rutas reales.
2. CONTRATO_PROPUESTO.json con dimensiones/celdas/pivotes/poses/escala y propuesta visual de muestra. Si exige una decisión no resuelta, dejarla explícita y continuar partes independientes.
3. Producción incremental por sublotes, preservando originales aceptados y procedencia.
4. Validación estructural y revisión visual a zoom real; galería/previews de composiciones, nunca solo sprites aislados. Registrar limitaciones de pruebas.
5. Entrega conforme a ../CONTRATO_DE_ENTREGA.md. INFORME.md debe distinguir hecho, parcial, pendiente y bloqueado; no simular aprobaciones ni resultados.

Este entregable está pensado para una IA independiente. Puede trabajar simultáneamente con los otros cinco porque no comparte rutas de escritura. Integración final al juego pertenece a una persona/IA integradora distinta y única.
