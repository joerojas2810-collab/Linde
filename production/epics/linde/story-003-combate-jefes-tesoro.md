# Story 003: Combate: jefe de capítulo, jefe de mundo y tesoro

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 7

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: presupuesto provisional 60 fps / 16,67 ms; la escena actual mueve hasta 12 slimes y 2 jefes con colisión por caja; medir con `/perf-profile` si baja de 60 fps.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*El modelo de combate es la decisión **A01 pendiente**: lo implementado es provisional hasta que el usuario lo juegue.*

- [ ] Todo ataque enemigo muestra una señal previa antes del impacto, y un ataque produce un solo impacto.
- [ ] El jugador golpea hacia donde mira, con aviso, golpe y recuperación.
- [ ] El jefe de capítulo cambia de fase al 50 % con un ataque nuevo; se derrota una vez, da su recompensa fija una sola vez y no reaparece tras cargar.
- [ ] El jefe de mundo reaparece a las 72 h de juego y conserva su historial de derrotas.
- [ ] Derrota del jugador: sin perder objetos, vuelve a su cama (o al inicio) con media vida y el encuentro se reinicia.
- [ ] El contenido del tesoro se fija al crear la partida, no cambia al recargar y se abre una sola vez.
- [ ] Jugados a mano ambos jefes: cada uno se puede derrotar y su señal previa se ve antes de cada impacto (anotado por el usuario en `production/qa/evidence/story-003-sesion.md`); el usuario confirma o ajusta el modelo de combate y se registra la decisión A01 en `Linde/cenital/docs/DECISIONES.md`.

---

## Implementation Notes

Existe: `combate.gd` (jugador, slimes, jefes con fases, ataques en `catalogos.gd`), `juego.gd` (`jefe_derrotado`, `_derrota`). Todos los números (vida, daño, tiempos, velocidades) son provisionales y sin balance. Los jefes no son solo "más vida": la segunda fase añade onda o pisotón.

---

## Out of Scope

- 006: misiones que piden derrotar jefes · 007: armas fabricadas.
- Animaciones y sprites de combate finales.

---

## Files

- `Linde/cenital/scripts/combate.gd`, `juego.gd`, `catalogos.gd`, `escena.gd`
- `Linde/cenital/tests/prueba.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: `tests/integration/...` OR playtest doc. Existente: `Linde/cenital/tests/prueba.gd` (aviso previo, un impacto, fases, recompensa única, reaparición, derrota, tesoro). Falta el playtest de ambos jefes.

**Status**: [x] Pruebas automáticas existen · [ ] Playtest pendiente

---

## Dependencies

- Depends on: `production/epics/linde/story-002-recoleccion-inventario.md`
- Unlocks: `production/epics/linde/story-006-misiones.md`
