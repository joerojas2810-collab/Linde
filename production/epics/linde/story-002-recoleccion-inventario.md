# Story 002: Recolección de objetos rompibles e inventario atómico

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: no performance impact expected — lógica por evento, sin trabajo por cuadro.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Cada objeto rompible exige la herramienta o los golpes indicados y se rompe una sola vez.
- [ ] El botín se entrega en una sola transacción: con inventario lleno el objeto no se rompe y no se pierde nada.
- [ ] El botín probabilístico es el mismo para la misma semilla y objeto (cargar no lo cambia).
- [ ] Los arbustos regeneran tras 24 h de juego, solo si la celda está libre de construcciones y actores.
- [ ] El recorrido del capítulo 1 se completa solo con acciones del juego (la prueba `t_flujo` de `prueba.gd` lo recorre sin ciclos de recursos).
- [ ] Una sesión a mano recolectando: el inventario al final coincide con lo recogido (sin pérdidas ni duplicados), anotado en `production/qa/evidence/story-002-sesion.md`.

---

## Implementation Notes

Existe: `inventario.gd` (operaciones atómicas todo-o-nada), `juego.gd` (`golpear_objeto`), `catalogos.gd` (objetos). La roca se puede picar a mano (10 golpes) para evitar el ciclo pico↔piedra. Valores de golpes, botín y capacidad son **provisionales** (A03).

---

## Out of Scope

- 004: colocar piezas · 007: fabricar herramientas y habilidades.

---

## Files

- `Linde/cenital/scripts/inventario.gd`, `juego.gd`, `catalogos.gd`, `mundo.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/...`. Existente: `Linde/cenital/tests/prueba.gd` (recolección, inventario lleno, botín determinista, regeneración, flujo del capítulo 1).

**Status**: [x] Existe · [ ] Sesión a mano pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-001-mundo-personaje-guardado.md`
- Unlocks: `production/epics/linde/story-003-combate-jefes-tesoro.md`, `production/epics/linde/story-004-construccion.md`, `production/epics/linde/story-007-fabricacion-habilidades.md`
