# Story 002: Red mínima con servidor autoritativo

> **Epic**: Multijugador mundo anfitrión
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (servidor autoritativo y cliente)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Antes de usar la API de red (ENet, MultiplayerPeer, MultiplayerSynchronizer) comprobarla en `docs/engine-reference/godot/` para 4.7.

**Performance**: el tick del servidor con 4 clientes simulados debe quedar por debajo de 16,67 ms (percentil 95). Presupuesto provisional (`.claude/docs/technical-preferences.md`).

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Dos instancias del juego en localhost (un servidor y un cliente) se conectan en menos de 5 s en 10 de 10 intentos.
- [ ] El cliente envía solo intenciones (dirección de movimiento, acción). Una prueba envía una posición falsa desde el cliente y el servidor la rechaza: la posición resultante no supera la velocidad máxima por tick.
- [ ] Con latencia simulada de 100 ms y 0 % de pérdida, la posición mostrada en el cliente difiere de la del servidor en menos de 1 celda en el 95 % de los ticks durante 60 s de movimiento continuo.
- [ ] Una acción (romper un objeto, construir una pieza) pedida por el cliente se aplica una vez en el servidor, y ambas instancias muestran el resultado. Enviar la misma acción dos veces con el mismo id no la duplica.
- [ ] Con 2 jugadores en movimiento continuo, el tráfico por jugador es menor de 20 KB/s, medido con un contador de bytes durante 60 s.
- [ ] Con 4 clientes simulados sin ventana, el tick del servidor queda por debajo de 16,67 ms en el percentil 95 durante 60 s.
- [ ] Captura de pantalla de las dos ventanas conectadas guardada en `production/qa/evidence/`.

---

## Implementation Notes

El servidor es la única fuente de verdad: valida cada intención contra el estado de la historia 001. El cliente nunca escribe posiciones ni inventario directamente. Un identificador de acción por petición evita duplicados. Empezar con sincronización de posiciones y una sola acción (romper objeto) y añadir el resto después de pasar los criterios.

---

## Out of Scope

- 001: separación de estado · 003: guardado de varios personajes · 004: conectividad fuera de localhost y modo sin ventana · 006: pruebas de desconexión y reconexión.

---

## Files

- `Linde/cenital/scripts/red/servidor.gd` (nuevo)
- `Linde/cenital/scripts/red/cliente.gd` (nuevo)
- `Linde/cenital/scripts/red/mensajes.gd` (nuevo)
- `Linde/cenital/scripts/juego.gd` (cambia: arranque como servidor o cliente)
- `Linde/cenital/tests/multijugador/red_test.gd` (nuevo)
- `Linde/cenital/tests/multijugador/sincronizacion_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory), but the retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration: `Linde/cenital/tests/multijugador/red_test.gd` y `sincronizacion_test.gd`
- Visual (player-observable): captura retenida en `production/qa/evidence/story-002-dos-ventanas.png`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/multijugador/story-001-estado-jugador-compartido.md`
- Unlocks: `production/epics/multijugador/story-003-guardado-varios-personajes.md`, `production/epics/multijugador/story-004-conectividad-sin-ventana.md`, `production/epics/multijugador/story-006-pruebas-sincronizacion-reconexion.md`
