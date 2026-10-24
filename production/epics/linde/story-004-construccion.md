# Story 004: Construcción y retirada de piezas

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: la rejilla de colisión se reconstruye solo al cambiar el mundo; presupuesto provisional 60 fps / 16,67 ms.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Colocar una pieza respeta coste, terreno, objetos y actores; retirarla devuelve el 100 % solo en piezas propias.
- [ ] Una construcción que cerraría un lugar esencial (los puntos de `Mundo.ESENCIALES`: inicio del camino, puerta e interior de la casa, cama de Maren, entrada de la arena, cofre del tesoro y claro) o encerraría al jugador se rechaza y se revierte.
- [ ] Un cofre con contenido no se puede retirar; no se pierde nada al retirar.
- [ ] Colocar o retirar actualiza colisión y rutas al instante.
- [ ] Dormir en una cama propia lleva al amanecer, cura y fija el punto de reaparición.
- [ ] Las construcciones persisten en el guardado.
- [ ] Una sesión a mano: se construye un refugio de muros con una abertura de entrada (no existe pieza de puerta) y se duerme en él.

---

## Implementation Notes

Existe: `juego.gd` (`construir`, `retirar`, `dormir`, cofres), `mundo.gd` (piezas, alcanzabilidad de lugares esenciales). La preview verde/roja está en `escena.gd` (modo B). Costes y piezas son provisionales (A03).

---

## Out of Scope

- 005: reacción de los habitantes a las construcciones · 007: recetas.
- Piezas de más de 1×1 y orientación.

---

## Files

- `Linde/cenital/scripts/juego.gd`, `mundo.gd`, `escena.gd`, `catalogos.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: `tests/integration/...` OR playtest doc. Existente: `Linde/cenital/tests/prueba.gd` (construcción, esenciales, encierro, retirada, cofres, dormir).

**Status**: [x] Pruebas automáticas existen · [ ] Sesión a mano pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-001-mundo-personaje-guardado.md`, `production/epics/linde/story-002-recoleccion-inventario.md`
- Unlocks: `production/epics/linde/story-005-habitantes.md`
