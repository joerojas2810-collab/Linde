# Story 005: Habitantes con rutina

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: la ruta (BFS) se recalcula solo al cambiar el mundo o la actividad; presupuesto provisional 60 fps / 16,67 ms.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Maren elige su actividad por hora y energía y llega a su destino por una ruta.
- [ ] Rodea las paredes nuevas y nunca las atraviesa.
- [ ] Encerrada, queda en estado "bloqueado" y retoma la ruta al retirar el muro.
- [ ] Dormir exige llegar a la cama: sin cama no recupera energía.
- [ ] Posición, energía y relación se guardan y se cargan.
- [ ] Observar un día completo (24 min reales) sin que quede atascada ni atraviese nada.

---

## Implementation Notes

Existe: `habitantes.gd` (necesidad → actividad → ruta BFS → ejecución), un solo habitante. Energía −4/h despierta y +12/h dormida son valores **propios y provisionales**, no heredados de MineWorld. El avance con la app cerrada está fuera de alcance (P06): al dormir el jugador se recoloca al habitante.

---

## Out of Scope

- Más habitantes, comercio y relaciones complejas.
- Simulación lejana o con la app cerrada.

---

## Files

- `Linde/cenital/scripts/habitantes.gd`, `juego.gd`, `mundo.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/...`. Existente: `Linde/cenital/tests/prueba.gd` (ruta, rodeo, encierro y recuperación, dormir, sin cama).

**Status**: [x] Existe · [ ] Observación de un día pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-004-construccion.md`
- Unlocks: `production/epics/linde/story-006-misiones.md`
