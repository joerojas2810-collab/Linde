# Story 007: Fabricación y árbol de habilidades

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: no performance impact expected — cálculo por acción del jugador.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Economía y progresión numérica son la decisión **A03 pendiente**: los valores son provisionales.*

- [ ] Fabricar consume y entrega de forma atómica y exige estación, herramienta y habilidad cuando la receta las pide.
- [ ] El árbol de habilidades se valida: referencias existentes, sin ciclos y todo nodo alcanzable con los puntos del nivel máximo.
- [ ] Aprender exige nivel, requisitos y puntos; los efectos se calculan desde las habilidades aprendidas y no se acumulan al cargar.
- [ ] El usuario revisa recetas, costes, experiencia y habilidades tras jugar y los confirma o ajusta; la decisión A03 se anota en `Linde/cenital/docs/DECISIONES.md`.
- [ ] Se anota en `Linde/cenital/docs/DECISIONES.md` si habrá reasignación de puntos (sí / no / pendiente con motivo); hoy no existe.

---

## Implementation Notes

Existe: `catalogos.gd` (recetas, habilidades, `validar()`), `juego.gd` (`fabricar`, `aprender`, `stats`). Los umbrales de experiencia, costes y efectos son marcadores sin balance.

---

## Out of Scope

- Economía, comercio y precios.
- Ramas de comunidad.

---

## Files

- `Linde/cenital/scripts/catalogos.gd`, `juego.gd`, `inventario.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/...`. Existente: `Linde/cenital/tests/prueba.gd` (fabricación atómica, estaciones, árbol válido, efectos derivados al cargar).

**Status**: [x] Existe · [ ] Revisión de valores pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-002-recoleccion-inventario.md`
- Unlocks: None
