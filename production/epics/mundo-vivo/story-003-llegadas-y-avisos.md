# Story 003: Llegadas de habitantes y avisos

> **Epic**: Mundo vivo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md` (MVP feature 5; Build order, paso 3). Diseño detallado en `design/gdd/mundo-vivo.md` (Core Rules 12-14).
**Requirement**: Brief MVP feature 5

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal).

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Del GDD `design/gdd/mundo-vivo.md`, acotado a esta historia:*

- [ ] Un evento de llegada (`<id>_presente = true`) con cama libre y ruta válida hace aparecer al habitante en la celda 32,46 con su rutina y su cama.
- [ ] Sin cama libre o sin ruta desde la entrada, el evento no se aplica, el enfriamiento no cambia y se reintenta en la siguiente evaluación.
- [ ] La reconciliación es idempotente: con `ordal_presente = true` ya existente y reconciliando dos veces, hay exactamente un Ordal.
- [ ] Nerea (`nerea_presente` inicial `false`) llega por su tarjeta `llegada_nerea` (condiciones: `nerea_presente = false` y `camas_libres ≥ 1`; añadirla al paquete de prueba) cuando se cumplen. Ciclo jugable: construir una cama de huésped → en la siguiente hora de juego el director puede hacerla llegar por el sur.
- [ ] La llegada asigna la cama de huésped a Nerea, y `camas_libres` baja en 1.
- [ ] La actividad `explorar` tiene manejador: la rutina de Nerea (explorar en el bosque 05:00–12:00 y 15:00–20:00, socializar en la plaza, dormir en su cama) funciona sin quedar bloqueada. Propuesta: `explorar` se comporta como `trabajar` (ir al destino, tasa activa) y se guarda con su nombre.
- [ ] Al aplicarse un evento, todos los jugadores reciben un aviso con el nombre de la tarjeta.
- [ ] `habitantes_presentes` y `camas_libres` se actualizan tras cada llegada.
- [ ] Una llegada no se produce si el jugador ha bloqueado la entrada: la regla de construcción ya lo impide (la entrada es un lugar esencial) y una prueba lo confirma.
- [ ] Cada habitante tiene su propio aspecto (piel, pelo, ropa) con las piezas existentes, en una tabla del juego (el contrato del Atlas no tiene campo de aspecto). Maren, Ordal y Nerea se distinguen a simple vista; el aspecto de Maren no cambia respecto al actual (`[1, 0, 2]`). *(Añadido el 2026-10-24 por decisión del usuario.)*
- [ ] Captura retenida del aviso y del habitante recién llegado en el camino sur.

---

## Implementation Notes

La llegada es una variable booleana; el motor reacciona a su cambio y no hay operación «crear habitante» en los datos. La precondición (cama libre y ruta BFS desde `Mundo.ENTRADA`) se comprueba antes de confirmar los efectos. Reutilizar el canal de avisos de mundo que ya llega a todos.

---

## Out of Scope

- 001: paquete y habitantes desde datos · 002: director · 004: misiones · 005: guardado y red.

---

## Files

- `Linde/cenital/scripts/mundo_vivo.gd` (cambia: precondición de llegada, camas_libres_lista, nombre)
- `Linde/cenital/scripts/habitantes.gd` (cambia: reconciliación, explorar, cama asignada, tabla de aspecto)
- `Linde/cenital/scripts/escena.gd` (cambia: dibuja a cada habitante con su aspecto)
- `Linde/cenital/scripts/juego.gd` (cambia: aviso a todos y reconciliación tras un evento)
- `Linde/cenital/datos/mundo/entities/evento/llegada_nerea.json` (nuevo: tarjeta de llegada de Nerea) y `manifest.json`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/mundo_vivo/llegadas_test.gd`
- Visual (player-observable): captura retenida en `production/qa/evidence/mundo-vivo-003-llegada-sur.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/mundo-vivo/story-001-paquete-habitantes-ordal.md`, `production/epics/mundo-vivo/story-002-variables-y-director.md`
- Unlocks: `production/epics/mundo-vivo/story-005-guardado-servidor-y-red.md`

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 10/11 passing. **AC-9 NO se cumple** (cerrada por decisión del usuario): se puede construir un muro en la celda de entrada (32,46) y la llegada aparece sobre él; la regla de construcción no lo impide. Registrado como TD-001.
**Deviations**: ADVISORY — `ASPECTO` y `VEL` en código (TD-002); clave obsoleta en `camas_asignadas` tras retirar una cama (TD-003); aviso solo con el nombre de la tarjeta (TD-004); Ordal y Nerea comparten diálogo genérico (TD-005); el GDD afirma que la entrada ya está protegida (TD-006).
**Test Evidence**: waived at qa.level minimal; capturas en `production/qa/evidence/story-003-llegadas-y-avisos/`; los casos se verificaron con un script temporal fuera del repo (14 PASS)
**Reviewed by**: self, no independent review
