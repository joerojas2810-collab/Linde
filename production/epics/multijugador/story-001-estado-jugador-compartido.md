# Story 001: Estado por jugador y compartido, migración del guardado

> **Epic**: Multijugador mundo anfitrión
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (estado por jugador separado del compartido)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: presupuesto provisional 60 fps / 16,67 ms (`.claude/docs/technical-preferences.md`). El refactor no añade trabajo por fotograma.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Cada dato del juego queda clasificado como compartido (mundo, construcciones, habitantes, reloj) o por jugador (inventario, misiones, apariencia, posición); una prueba lista los campos y falla si alguno no tiene ámbito.
- [ ] Con un solo jugador, las 130 comprobaciones de `Linde/cenital/tests/prueba.gd` pasan sin cambiar sus expectativas.
- [ ] Un guardado en formato 1 (el formato actual) se convierte a formato 2 sin pérdida: inventario, misiones, tiempo, mundo y habitantes son iguales campo a campo antes y después.
- [ ] Un guardado en formato 2 se guarda y se vuelve a cargar con el mismo estado (prueba de ida y vuelta con 3 jugadores de ejemplo).
- [ ] Convertir un guardado ya en formato 2 no cambia ningún dato; un formato desconocido se rechaza sin tocar el archivo original.
- [ ] El archivo de formato 1 se conserva como respaldo hasta que la conversión se verifica.
- [ ] Las capturas de menú y HUD de `Linde/cenital/tests/capturas` coinciden píxel a píxel con las de antes del cambio.

---

## Implementation Notes

Separar el estado en dos objetos (compartido y por jugador) antes de tocar la red. La conversión de formato va en `guardado.gd` y se prueba con un guardado real de formato 1 copiado a la carpeta de pruebas. No cambiar el juego de un jugador: si una prueba existente falla, el refactor está mal, no la prueba.

---

## Out of Scope

- 002: red · 003: guardado con varios personajes · 005: permisos y botín · 006: pruebas de red.

---

## Files

- `Linde/cenital/scripts/estado_mundo.gd` (nuevo)
- `Linde/cenital/scripts/estado_jugador.gd` (nuevo)
- `Linde/cenital/scripts/guardado.gd` (cambia: conversión a formato 2)
- `Linde/cenital/scripts/mundo.gd`, `Linde/cenital/scripts/juego.gd` (cambian: leen el estado separado)
- `Linde/cenital/tests/multijugador/estado_test.gd` (nuevo)
- `Linde/cenital/tests/multijugador/migracion_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `Linde/cenital/tests/multijugador/estado_test.gd` y `migracion_test.gd` (raíz de pruebas del proyecto: `Linde/cenital/tests`, como en linde).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/multijugador/story-002-red-servidor-autoritativo.md`
