# Story 001: Paquete de datos, habitantes desde datos y Ordal

> **Epic**: Mundo vivo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md` (MVP feature 5: habitantes con rutina; Build order, paso 3). Diseño detallado en `design/gdd/mundo-vivo.md`.
**Requirement**: Brief MVP feature 5

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Cargar JSON con `JSON.parse_string`/`FileAccess`; no hay `scripting.md` en `docs/engine-reference/godot/modules/`, comprobar las firmas contra 4.7 al implementar.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Del GDD `design/gdd/mundo-vivo.md` y del contrato del Atlas, acotado a esta historia:*

- [ ] Un cargador lee el paquete (manifiesto + entidades JSON) de `res://datos/mundo/` y lo rechaza entero ante referencia rota, tipo erróneo, operador o variable desconocidos. El error nombra el archivo y el campo.
- [ ] El paquete se carga al arrancar y no se recarga en caliente.
- [ ] La rutina de Maren sale de datos: para cada una de las 24 horas de juego, actividad y destino coinciden con la lógica actual (prueba de tabla antes/después).
- [ ] Las necesidades de Maren (energía −4/h activa, +12/h en descanso) vienen de su ficha, con los mismos resultados que hoy.
- [ ] Con `ordal_presente = true` al crear el mundo, Ordal existe con su cama y su rutina, sin pisar a Maren ni su cama.
- [ ] Si falta la cama de Ordal, queda en `sin_cama`, igual que Maren.
- [ ] Una tabla lugar → celda traduce los destinos de las fichas (`entrada_sur` → 32,46, `taller`, `plaza`, `cantera`, `bosque`). Un lugar sin celda bloquea esa rutina con un error nombrado.
- [ ] `dormir()` no cambia `d.min`; cura al jugador y fija su cama.
- [ ] Las pruebas existentes (`Linde/cenital/tests/prueba.gd`) siguen pasando.
- [ ] Captura retenida de Maren y Ordal en escena.

---

## Implementation Notes

Fuente de datos: el Atlas (`atlas-contrato.md`). Mientras su exportación esté deshabilitada (`examples_only`), usar una copia de sus tarjetas como paquete de prueba en `Linde/cenital/datos/mundo/`, marcada como tal. Mapeo de actividades: `taller` → trabajar, `plaza` → socializar, `dormir` → dormir. **Pendiente de decidir (usuario):** dónde va la cama de Ordal en el mapa; hoy solo existe `CAMA_MAREN` (`mundo.gd`). Propuesta: una celda libre dentro de la casa. No hardcodear valores de juego: tasas y horarios van en datos.

---

## Out of Scope

- 002: variables, condiciones, efectos y director · 003: llegadas y avisos · 004: misiones por plantilla · 005: guardado, servidor y red.

---

## Files

- `Linde/cenital/scripts/mundo_datos.gd` (nuevo: cargador y validación del paquete)
- `Linde/cenital/scripts/habitantes.gd` (cambia: rutina y necesidades desde datos; NPCS pasa a fichas)
- `Linde/cenital/scripts/mundo.gd` (cambia: CAMA_ORDAL (25,18), CAMAS, ESENCIALES)
- `Linde/cenital/scripts/juego.gd` (cambia: dormir() sin avanzar el reloj)
- `Linde/cenital/scripts/escena.gd` (cambia: usa habitantes.ids y fichas)
- `Linde/cenital/datos/mundo/` (nuevo: copia de prueba de 15 tarjetas del Atlas, fixture)
- `Linde/cenital/tests/prueba.gd` (cambia: 2 aserciones por la nueva especificación de dormir y la cama de Ordal)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/mundo_vivo/paquete_test.gd`
- Visual (player-observable): captura retenida en `production/qa/evidence/mundo-vivo-001-maren-ordal.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/mundo-vivo/story-002-variables-y-director.md`, `production/epics/mundo-vivo/story-003-llegadas-y-avisos.md`

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 10/10 passing (0 deferred)
**Deviations**: ADVISORY — `VEL = 24.0` y `Mundo.CAMAS` siguen en código (el contrato del Atlas no los modela); dos aserciones de `tests/prueba.gd` cambiadas por la nueva especificación de dormir y la cama de Ordal. Abiertas de diseño: «descansar» sin destino, «explorar» sin manejador (003), Ordal con el aspecto de Maren, sin evitación entre habitantes en un mismo lugar.
**Test Evidence**: waived at qa.level minimal; capturas en `production/qa/evidence/story-001-paquete-habitantes-ordal/`
**Reviewed by**: self, no independent review
