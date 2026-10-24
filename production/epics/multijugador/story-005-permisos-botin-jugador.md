# Story 005: Permisos de construcción y botín por jugador

> **Epic**: Multijugador mundo anfitrión
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (permisos de construcción y botín por jugador)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: comprobar rutas esenciales no debe añadir trabajo por fotograma; se ejecuta al construir o retirar una pieza.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Cada pieza construida tiene propietario. Retirar una pieza ajena se rechaza en 20 de 20 intentos de prueba.
- [ ] Tras construir, cada personaje tiene ruta a su cama, a la tienda de la aldea y a la salida del mapa, en 50 semillas de prueba. Si una pieza la corta, la construcción se rechaza.
- [ ] El botín de un tesoro va a un solo jugador: con 2 jugadores abriendo el mismo tesoro, solo uno recibe el objeto (10 de 10 ejecuciones).
- [ ] Un intercambio directo se completa solo cuando ambos jugadores confirman. Sin la confirmación de los dos, no cambia ningún inventario.
- [ ] Si un inventario cambia durante el intercambio, la transacción se cancela y ambos inventarios quedan como antes (10 casos de prueba).
- [ ] Si un jugador se desconecta con un intercambio pendiente, el intercambio se cancela sin pérdida de objetos.

---

## Implementation Notes

Reutilizar las transacciones atómicas del inventario de linde (`Linde/cenital/scripts/inventario.gd`). La regla de caminos esenciales se comprueba con la misma búsqueda de ruta que usan los habitantes; no crear un buscador nuevo. Un intercambio es una transacción de dos inventarios: o cambian los dos o ninguno.

---

## Out of Scope

- 003: guardado · 006: pruebas de red · UI de intercambio (queda en una historia de interfaz posterior).

---

## Files

- `Linde/cenital/scripts/permisos_construccion.gd` (nuevo)
- `Linde/cenital/scripts/intercambio.gd` (nuevo)
- `Linde/cenital/scripts/inventario.gd` (cambia: transacciones entre dos jugadores)
- `Linde/cenital/scripts/combate.gd` (cambia: botín del tesoro por jugador)
- `Linde/cenital/tests/multijugador/permisos_test.gd` (nuevo)
- `Linde/cenital/tests/multijugador/intercambio_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `Linde/cenital/tests/multijugador/permisos_test.gd` y `intercambio_test.gd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/multijugador/story-003-guardado-varios-personajes.md`
- Unlocks: None
