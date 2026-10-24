# Story 006: Misiones de capítulo y de mundo

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: no performance impact expected — las misiones se evalúan cada 0,5 s.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*El canon narrativo es la decisión **A02 pendiente**: los textos actuales son de prueba.*

- [ ] Las misiones pasan por disponible → activa → cumplida → entregada.
- [ ] Las condiciones actuales (tener, construcción en pie) se miden ahora y pueden perderse; las históricas (visita, jefe, cofre, hablar) usan hechos guardados.
- [ ] Cada recompensa se entrega una sola vez, también tras recargar.
- [ ] Las de capítulo se piden y entregan hablando con Maren; las de mundo se aceptan desde el diario.
- [ ] El capítulo 1 se completa de principio a fin solo con acciones del juego.
- [ ] El usuario revisa los textos de prueba y los sustituye por contenido real o confirma conservarlos; la decisión A02 se anota en `Linde/cenital/docs/DECISIONES.md`.

---

## Implementation Notes

Existe: `juego.gd` (estados, `objetivo_ok`, `entregar`, `hablar`), `catalogos.gd` (misiones y diálogos de prueba: Maren, taller, cantera, ruinas, Guardián, Gran Ciervo). El último criterio depende de decisiones del usuario sobre el canon; no se inventa contenido final.

---

## Out of Scope

- Capítulos 2 en adelante y narrativa generada por LLM.
- Más NPC que den misiones.

---

## Files

- `Linde/cenital/scripts/juego.gd`, `catalogos.gd`, `hud.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/...`. Existente: `Linde/cenital/tests/prueba.gd` (estados, condiciones actuales vs históricas, recompensa única, recarga, flujo del capítulo 1).

**Status**: [x] Existe · [ ] Revisión de textos pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-003-combate-jefes-tesoro.md`, `production/epics/linde/story-005-habitantes.md`
- Unlocks: None
