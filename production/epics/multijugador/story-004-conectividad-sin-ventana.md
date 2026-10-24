# Story 004: Conectividad y modo sin ventana

> **Epic**: Multijugador mundo anfitrión
> **Status**: Blocked — sin API de relay ni NAT integrada; UPnP y conexión entre máquinas reales sin verificar; hace falta decidir y probar puerto abierto, UPnP o VPN
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (conectividad y modo sin ventana)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Comprobar el modo headless y la API de red en `docs/engine-reference/godot/` para 4.7.

**Performance**: el servidor headless no carga escenas de presentación.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Desde el menú, el anfitrión abre su mundo y aparece una dirección para conectar en menos de 10 s (5 de 5 intentos).
- [ ] Un servidor headless arranca sin ventana con el mismo mundo y acepta 2 clientes en localhost durante 2 minutos sin caerse.
- [ ] Se prueba la conexión entre dos máquinas reales y se documenta en esta historia el método que funcione (puerto abierto, UPnP o VPN) y el que no. El prototipo `prototypes/red-minima/` (2026-10-23) solo probó localhost: no hay datos de red real, NAT ni UPnP (UPnP sin gateway IGD válido en la prueba).
- [ ] Un cliente en otra red conecta con el método elegido en 3 de 3 intentos (prueba manual con registro en `production/qa/evidence/`).
- [ ] Si el anfitrión no responde, el cliente muestra un mensaje de error en menos de 15 s y no queda cargando.
- [ ] Una prueba del servidor headless lista los nodos de presentación y encuentra 0.
- [ ] Captura del menú de anfitrión guardada en `production/qa/evidence/`.

---

## Implementation Notes

Los resultados de `prototypes/red-minima` (2026-10-23, localhost) cubren ENet, RPC y 15 clientes, pero no red real. Esta historia sigue bloqueada hasta probar puerto directo, UPnP o VPN entre dos máquinas en redes distintas. Ajustes recomendados si se implementa: `throttle_configure(5000, 2, 0)` en cada peer del servidor y timeout de ENet de 1000–3000 ms.

---

## Out of Scope

- 002: sincronización · 003: guardado · 006: pruebas de reconexión.

---

## Files

- `Linde/cenital/scripts/escena.gd` (cambia: menú de anfitrión)
- `Linde/cenital/scripts/red/conexion.gd` (nuevo)
- `Linde/cenital/scripts/red/servidor_headless.gd` (nuevo)
- `Linde/cenital/tests/multijugador/conexion_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/multijugador/conexion_test.gd`
- Visual (player-observable): captura en `production/qa/evidence/story-004-menu-anfitrion.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/multijugador/story-002-red-servidor-autoritativo.md`
- Unlocks: None
