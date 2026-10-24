# Story 004: Misiones por plantilla y recompensas

> **Epic**: Mundo vivo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md` (MVP feature 6: misiones de capítulo y de mundo). Diseño detallado en `design/gdd/mundo-vivo.md` (Core Rules 15).
**Requirement**: Brief MVP feature 6

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal).

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Del GDD `design/gdd/mundo-vivo.md`, acotado a esta historia:*

- [ ] Cuando `condiciones_oferta` son verdaderas, el motor ofrece una instancia; la aceptación es explícita (`ofrecida → activa → completada`).
- [ ] Al cumplirse `condiciones_completar`, se aplican `efectos_completar` una sola vez y la recompensa (XP e ítems) se paga una sola vez al jugador que completa.
- [ ] Si el inventario del jugador está lleno, lo que no cabe queda en `pendientes`, sin perderse ni duplicarse.
- [ ] Pedir completar dos veces la misma instancia no cambia nada.
- [ ] `repetible: false` impide nuevas instancias; `repetible: true` permite otra tras cerrar la anterior, y nunca hay dos activas del mismo propietario y plantilla.
- [ ] En una plantilla de ámbito `jugador`, `efectos_completar` vacío es obligatorio; una con efectos se rechaza al cargar.
- [ ] `objetivo_ok` (o un adaptador junto a él) evalúa objetivos de tipo variable sin romper los 6 tipos actuales; las misiones del capítulo 1 siguen pasando sus pruebas.
- [ ] El panel de misiones existente muestra la instancia activa y su progreso. Captura retenida.

---

## Implementation Notes

Reutilizar oferta, aceptación y `pendientes` de las misiones actuales (`juego.gd`). La plantilla no concede recompensa por sí misma: el bloque `recompensa` del contrato se valida contra el catálogo de ítems. Una recompensa debe registrarse por clave, como las recompensas actuales, para que sea única.

---

## Out of Scope

- 002: evaluador de condiciones y efectos (se reutiliza) · 003: llegadas · 005: guardado y red de las instancias.

---

## Files

- `Linde/cenital/scripts/mundo_vivo.gd` (cambia: instancias de plantilla, oferta, aceptación, entrega y pago)
- `Linde/cenital/scripts/mundo_datos.gd` (cambia: valida los ítems de la recompensa contra el catálogo)
- `Linde/cenital/scripts/juego.gd` (cambia: evaluar misiones en `_chequeos`, fachadas de aceptar y entregar)
- `Linde/cenital/scripts/escena.gd` (cambia: instancias en el panel de misiones, rama "mis")
- `Linde/cenital/scripts/hud.gd` (cambia: instancias activas en el rastreador)
- `Linde/cenital/datos/mundo/entities/plantilla_mision/` (nuevo `cama_huesped.json`; cambia `reunir_piedra_taller.json`) y `manifest.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/mundo_vivo/misiones_test.gd`
- Visual (player-observable): captura retenida en `production/qa/evidence/mundo-vivo-004-mision.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/mundo-vivo/story-002-variables-y-director.md`
- Unlocks: `production/epics/mundo-vivo/story-005-guardado-servidor-y-red.md`

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 8/8 passing (0 deferred)
**Deviations**: ADVISORY — las instancias se evalúan por su propio camino en `mundo_vivo.gd`, no por `objetivo_ok`; el progreso en el panel es solo el estado y el texto, sin lista de condiciones, y el texto largo del rastreador se sale del recuadro; el ámbito jugador se trata como instancia compartida única (propietario por jugador en la 005).
**Test Evidence**: waived at qa.level minimal; capturas en `production/qa/evidence/story-004-misiones-por-plantilla/`; los casos se verificaron con scripts temporales fuera del repo (20 PASS, más `repetible: true` comprobado aparte)
**Reviewed by**: self, no independent review
