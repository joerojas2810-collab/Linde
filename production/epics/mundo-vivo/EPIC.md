# Epic: Mundo vivo

> **Status**: Planned (historias listas; nada implementado)
> **Brief**: `design/game-brief.md` (MVP feature 5 y 6; Build order, pasos 3 y 7)
> **GDD**: `design/gdd/mundo-vivo.md` (sin revisión independiente)
> **Plan y decisiones**: `production/epics/mundo-vivo/README.md`
> **ADR**: ninguno propio; reloj compartido según `docs/architecture/adr-0001-multijugador-mundo-anfitrion.md` §5 (Proposed)
> **Code root actual**: `Linde/cenital/`

## Goal
Que el valle cambie solo mientras se juega: un director en el servidor combina habitantes, variables, tarjetas de evento y plantillas de misión (datos del Atlas) para producir llegadas, avisos y misiones, sin una historia fija.

## Build order
1. **001** paquete de datos, habitantes desde datos y Ordal.
2. **002** variables, condiciones, efectos y director.
3. **003** llegadas y avisos, sobre 001 y 002.
4. **004** misiones por plantilla, sobre 002.
5. **005** guardado, servidor y red, sobre 002, 003 y 004.

Grafo: 001 → 002 → 003 → 005; 002 → 004 → 005.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Paquete de datos, habitantes desde datos y Ordal | Integration | Complete | N/A (minimal) |
| 002 | Variables del mundo y director de eventos | Logic | Complete | N/A (minimal) |
| 003 | Llegadas de habitantes y avisos | Integration | Complete | N/A (minimal) |
| 004 | Misiones por plantilla y recompensas | Integration | Complete | N/A (minimal) |
| 005 | Guardado, servidor y red del mundo vivo | Integration | Complete | N/A (minimal) |

## Pendiente de decisión (usuario)
- Aprobar las tarjetas del Atlas (hoy `proposed`): sin ello o sin la opción de prueba `admitir_propuestas` el director no dispara nada.
- Alinear con el Atlas el tratamiento de una variable inexistente (descartar la tarjeta frente a bloquear la evaluación).
