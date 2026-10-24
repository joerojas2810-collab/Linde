# Story 002: Variables del mundo y director de eventos

> **Epic**: Mundo vivo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md` (MVP feature 5; Build order, paso 3). Diseño detallado en `design/gdd/mundo-vivo.md` (Core Rules 1-11 y 16).
**Requirement**: Brief MVP feature 5

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). `RandomNumberGenerator` con semilla, como `Juego._rng`. Prohibido `Expression`, `eval` o ejecutar datos.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Del GDD `design/gdd/mundo-vivo.md`, acotado a esta historia:*

- [ ] Con la misma semilla y el mismo minuto, dos evaluaciones desde el mismo estado eligen la misma tarjeta.
- [ ] Una tarjeta con enfriamiento 120 min aplicada en el minuto M no es candidata en M+60 y sí en M+120. Con enfriamiento 0 es elegible en la siguiente evaluación, nunca dos veces en la misma.
- [ ] Una tarjeta cuyo segundo efecto viola un límite no cambia ninguna variable ni `ultimo[id]`.
- [ ] Un efecto que escribe una variable derivada se rechaza y queda en el registro.
- [ ] Las condiciones soportan `eq, neq, gt, gte, lt, lte`, `y`/`o`, profundidad ≤ 16 y ≤ 256 nodos. Una variable inexistente descarta esa tarjeta en esa evaluación y queda registrada; las demás se evalúan.
- [ ] El director corre una vez por hora de juego (`_hora_en_punto`) y aplica como máximo un evento por evaluación. Peso 0 desactiva la tarjeta.
- [ ] Las tarjetas `proposed` solo participan con la opción de prueba `admitir_propuestas`. Sin ella el director no dispara ninguna y lo informa por nombre.
- [ ] El registro guarda `{min, id, variables leídas}` de cada evento aplicado y se acota a 50 entradas (la más antigua sale primero).
- [ ] Las variables derivadas iniciales (`dia`, `camas_libres`, `habitantes_presentes`, `mesa_construida`, `guardian_derrotado`) devuelven el valor esperado en estados armados a mano.
- [ ] Nueva pieza de construcción **«cama de huésped»** (decisión del usuario 2026-10-24): `camas_libres` cuenta las camas de huésped construidas y aún sin asignar a un habitante. La cama del jugador (`cama`), las camas de Maren y de Ordal y las camas de huésped ya asignadas no cuentan. Construir una suma 1; retirarla resta 1.
- [ ] La cama de huésped se puede construir y retirar con las reglas actuales de construcción (no cierra lugares esenciales) y se dibuja con el sprite de cama con otro tinte.
- [ ] Reiniciar en la misma hora de juego no evalúa dos veces el mismo minuto ni repite un evento en enfriamiento.

---

## Implementation Notes

Las constantes de ritmo (cada cuántos minutos se evalúa, tope del registro) son provisionales y van en datos. El evaluador de condiciones usa una tabla explícita de los seis operadores. Aplicar efectos sobre una copia del estado y confirmar solo si todos pasan. Solo el servidor ejecuta el director.

Tras la 001: el esquema de eventos, plantillas y condiciones ya lo valida `mundo_datos.gd`; esta historia lo **consume** (`paquete()`), no lo revalida. El paquete de prueba trae `abrir_taller` y `llegada_ordal`, pero `piedra_taller` no tiene proveedor y Ordal ya está presente, así que ninguna se dispara jugando: probar el director con estados armados a mano. La tarjeta que hace jugable el ciclo (`llegada_nerea`) va en la 003. La cama de huésped es una pieza nueva en `catalogos.gd` (misma estructura que `cama`, sin la bandera de cama del jugador); el arte reutiliza `bed` con tinte en `mundo_arte.gd`.

---

## Out of Scope

- 001: cargador del paquete · 003: llegadas y aviso · 004: misiones por plantilla · 005: guardado y red.

---

## Files

- `Linde/cenital/scripts/mundo_vivo.gd` (nuevo: estado, variables, condiciones, efectos y director)
- `Linde/cenital/scripts/juego.gd` (cambia: crea `vivo` y lo evalúa en `_hora_en_punto`)
- `Linde/cenital/scripts/catalogos.gd` (cambia: pieza «cama de huésped»)
- `Linde/cenital/scripts/mundo_arte.gd` (cambia: tinte de la cama de huésped)
- `Linde/cenital/datos/mundo/` (cambia: 4 variables derivadas nuevas y manifiesto)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Logic
**Required evidence**:
- Logic: `Linde/cenital/tests/mundo_vivo/director_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/mundo-vivo/story-001-paquete-habitantes-ordal.md` (implementada y verificada; corre `/story-done` sobre ella antes de `/dev-story` para que figure Complete)
- Unlocks: `production/epics/mundo-vivo/story-003-llegadas-y-avisos.md`, `production/epics/mundo-vivo/story-004-misiones-por-plantilla.md`

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 12/12 passing (0 deferred)
**Deviations**: ADVISORY — `CADENCIA_MIN = 60` está definida pero no se usa: la cadencia real la fija `Juego._hora_en_punto`; `TOPE_REGISTRO` y los costes de la cama de huésped están en código, marcados provisionales. Los criterios se verificaron con un script temporal fuera del repo (36 PASS), no con un test del repo.
**Test Evidence**: waived at qa.level minimal; capturas en `production/qa/evidence/story-002-variables-y-director/`
**Reviewed by**: self, no independent review
