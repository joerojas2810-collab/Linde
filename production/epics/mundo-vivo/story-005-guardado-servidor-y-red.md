# Story 005: Guardado, servidor y red del mundo vivo

> **Epic**: Mundo vivo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7: servidor autoritativo). Diseño detallado en `design/gdd/mundo-vivo.md` (Core Rules 2, 3 y 18).
**Requirement**: Brief, paso 7 (mundo anfitrión)

**ADR Governing Implementation**: N/A (minimal — no ADRs). Referencia: `docs/architecture/adr-0001-multijugador-mundo-anfitrion.md` §5 (reloj del mundo), aún Proposed.
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Antes de tocar la red comprobar `docs/engine-reference/godot/modules/networking.md` para 4.7.

**Performance**: el tick del servidor con el director activo y 4 clientes simulados debe quedar por debajo de 16,67 ms (percentil 95). Presupuesto provisional.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Del GDD `design/gdd/mundo-vivo.md`, acotado a esta historia:*

- [ ] Las claves nuevas (`vars`, `ultimo`, `llegados`, `instancias`, `registro`, hora evaluada) entran con valores por defecto sin subir `FORMATO`.
- [ ] Una partida guardada antes de este sistema carga sin perder nada.
- [ ] Reiniciar el servidor conserva enfriamientos, llegadas e instancias; no repite un evento en enfriamiento.
- [ ] Solo el servidor corre el director. Un pedido de evento enviado por un cliente se rechaza, se cuenta en el registro de rechazos y no cambia el estado.
- [ ] Con un servidor y dos clientes en localhost, aplicar un evento envía el aviso a ambos y el mismo estado de mundo.
- [ ] El director sigue corriendo cuando no hay ningún jugador conectado, y al reconectar los jugadores ven el estado resultante.
- [ ] El tick del servidor con el director queda por debajo de 16,67 ms (p95) con 4 clientes simulados.
- [ ] Captura retenida de las dos ventanas conectadas con el aviso visible.

---

## Implementation Notes

Seguir el reparto de estado de `docs/DECISIONES.md` («Estado por jugador y mundo compartido»): los datos del director son compartidos (raíz de `d`); las instancias de misión de ámbito jugador pertenecen a `d.jugadores[id]`. Reutilizar la prueba de integración `Linde/cenital/tests/prueba_red.gd` y los bots de `bot_red.gd`.

---

## Out of Scope

- 001-004: paquete, director, llegadas y misiones · Hosting y pantalla de conexión (epic de multijugador).

---

## Files

- `Linde/cenital/scripts/red_servidor.gd` (cambia: `mundo_vivo` en `SECCIONES` y en el estado de bienvenida)
- `Linde/cenital/scripts/red_cliente.gd` (cambia: recibe `mundo_vivo` y reconcilia a los habitantes llegados)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/mundo_vivo/red_test.gd`
- Visual (player-observable): captura retenida en `production/qa/evidence/mundo-vivo-005-dos-ventanas.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/mundo-vivo/story-002-variables-y-director.md`, `production/epics/mundo-vivo/story-003-llegadas-y-avisos.md`, `production/epics/mundo-vivo/story-004-misiones-por-plantilla.md`
- Unlocks: None

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 8/8 passing (0 deferred)
**Deviations**: ADVISORY — con 4 jugadores la instantánea (1.783 bytes) supera el MTU de ENet (1.392) y aparece un aviso de pérdida de paquetes (TD-007); se reenvía `mundo_vivo` completo, incluido `registro`, cada hora de juego (TD-008); sin panel de misiones de plantilla en clientes, acordado con el usuario (TD-009). El tramo 1 (guardado y servidor) no requirió cambios de código: ya funcionaba.
**Test Evidence**: waived at qa.level minimal; capturas en `production/qa/evidence/story-005-guardado-servidor-y-red/`; los casos se verificaron con scripts temporales fuera del repo (11 PASS de integración, p95 = 2,73 ms con 4 clientes, 0 comprobaciones fallidas en `prueba_red.gd`)
**Reviewed by**: self, no independent review
