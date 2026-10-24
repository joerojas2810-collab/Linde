# Sociedad emergente — rebanada de cinco capacidades

Estado: prototipo optativo implementado, 2026-10-24. No sustituye al director de tarjetas ni establece el canon. Solicitud: conectar producción/consumo, cooperación, alternativas, memoria y grupos sin escribir cada situación.

## Experiencia

El valle puede producir, necesitar, negociar, construir y fallar sin que el jugador dispare una misión. Su intervención cambia recursos y relaciones, no una rama narrativa prefijada. El panel J explica las causas y el diario conserva resultados observables.

## Reglas y contratos

- Cada habitante conserva inventario, hambre, herramientas con usos, objetivo, plan, bloqueos temporales, recuerdos y vínculos.
- Las metas proceden del estado actual: reserva alimentaria, herramientas necesarias, reparación, oficio y reservas del grupo. Se resuelven con acciones existentes y subnecesidades acotadas.
- Las transacciones conservan recursos: recolección modifica objetos reales; fabricar y construir consumen entradas; reparar consume material; todo intercambio tiene existencias reservadas en garantía.
- Un acuerdo es `activo -> cumplido | vencido`. No se entrega a distancia, no se entrega dos veces y no se reembolsa dos veces. Vencer altera confianza, devuelve materiales y conserva la causa.
- Grupos con miembros, depósito, territorio y reservas. Los intereses se expresan en acceso, ayuda, prioridad y reputación. No hay violencia entre grupos.
- Los testigos de una extracción necesitan proximidad. La evaluación económica usa conocimiento global de fuentes y posibles proveedores, una simplificación explícita.
- Las estaciones construidas por NPC son de su grupo; no son retirables por un jugador. Toda nueva obra protege rutas de jugadores, habitantes y depósitos.
- Autoridad y persistencia: solo servidor, dentro de `mundo_vivo.autonomia`; la réplica recibe estado y envía intenciones.

## Ajustes

Todo ajuste nuevo de consumo, duración, confianza, precio y límites de historial se define en `datos/autonomia/reglas.json`. Las recetas y los objetos se reutilizan de `catalogos.gd`. Balance propio provisional. Detalle operativo en `Linde/cenital/docs/AUTONOMIA.md`.

## Aceptación

1. Desde inventarios vacíos y sin estaciones regaladas, varios días de simulación producen fabricación, un acuerdo entregado físicamente, construcción y reparación sin tarjetas del director.
2. Cambiar existencias o accesibilidad cambia la elección; una meta sin solución se pospone y deja una causa.
3. Desgastar y reparar modifica objetos/materiales reales. Los consumos renuevan demanda.
4. Compromisos persisten con sus garantías; entregar, vencer, cargar y repetir pedidos no duplican objetos.
5. La confianza y la pertenencia cambian a quién se ayuda y con quién se comercia. La escasez protege recursos de grupo.
6. Una extracción observada afecta reputación; una distante no genera conocimiento automático. Contribuir al grupo consume recursos y mejora relación.
7. La partida normal y el modo de necesidades anterior mantienen sus comprobaciones; interfaz observable y evidencia retenida.

## Fuera de esta rebanada

Guerras, conquista, generación de nuevos grupos, mapas nuevos, habilidades aprendidas, equipo procedimental, descubrimiento limitado, capacidad de inventarios y balance final. La diversidad surge de reglas conocidas; nuevas mecánicas requieren nuevas acciones implementadas.
