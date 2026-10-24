# Story 001: Mundo cenital, personaje propio, inicio seguro y guardado

> **Epic**: Linde
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: presupuesto provisional 60 fps / 16,67 ms (`.claude/docs/technical-preferences.md`); el dibujo del mundo recorre solo las celdas visibles.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*De la meta y el fallo del brief, acotado a esta historia. Gran parte ya tiene prueba automática; falta la sesión jugada a mano (build order 1).*

- [ ] El personaje se crea con nombre y apariencia elegidos y aparece así en la partida.
- [ ] Se mueve arriba, abajo, izquierda y derecha sin diagonales; las paredes y los objetos lo bloquean y se pueden rodear los edificios.
- [ ] 100 semillas dan un inicio libre, con salida, y lejos de enemigos y jefes; la misma semilla da el mismo inicio.
- [ ] Guardar y cargar conserva el estado completo (inventario, mundo modificado, misiones, tiempo, habitantes).
- [ ] Un guardado corrupto o interrumpido se recupera desde el respaldo y nunca se sobrescribe en silencio.
- [ ] Una sesión jugada a mano de al menos 10 minutos sin reiniciar ni quedar atrapado; el usuario anota en `production/qa/evidence/story-001-sesion.md` qué movimientos se sintieron mal, o «ninguno».

---

## Implementation Notes

Existe y ya pasa sus pruebas: `mundo.gd` (mapa de autor, inicio por semilla), `guardado.gd` (formato versionado, checksum, `.bak`), `escena.gd`/`hud.gd` (menú y creador). Lo pendiente es **jugarlo** y anotar lo que se sienta mal; no rehacer lo probado. El arte es provisional (lo producirá GPT).

---

## Out of Scope

- 002: recolección e inventario · 003: combate · 004: construcción · 005: habitantes · 006: misiones · 007: fabricación y habilidades.
- Sprites finales y audio.

---

## Files

- `Linde/cenital/scripts/mundo.gd`, `guardado.gd`, `juego.gd`, `escena.gd`, `hud.gd`, `apariencia.gd`, `params.gd`
- `Linde/cenital/tests/prueba.gd`, `Linde/cenital/tests/prueba_ui.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: playtest doc OR `tests/integration/...`. Existentes: `Linde/cenital/tests/prueba.gd` (130 comprobaciones) y `prueba_ui.gd` (12). Falta anotar la sesión manual.

**Status**: [x] Pruebas automáticas existen · [ ] Sesión a mano pendiente

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/linde/story-002-recoleccion-inventario.md`, `production/epics/linde/story-004-construccion.md`
