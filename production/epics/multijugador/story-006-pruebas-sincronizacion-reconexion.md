# Story 006: Pruebas de sincronización, desconexión y reconexión

> **Epic**: Multijugador mundo anfitrión
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (sincronización, desconexión y reconexión)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: el guardado periódico no debe pausar el servidor más de 100 ms.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Con 4 clientes simulados moviéndose y actuando durante 10 minutos, ningún cliente diverge del servidor en más de 1 celda ni en más de 1 objeto de inventario (comparación de estado cada 30 s).
- [ ] Un cliente desconectado deja su personaje en el mundo 60 s y luego lo guarda. Una prueba comprueba el estado al segundo 59 y al segundo 61.
- [ ] Reconectar en menos de 60 s devuelve el personaje a la misma posición y con el mismo inventario (igualdad campo a campo).
- [ ] Reconectar después de 60 s hace aparecer el personaje en su punto de guardado, con todos sus objetos.
- [ ] Si el servidor se detiene a la fuerza, al reiniciar se pierde como máximo 60 s de juego (guardado periódico cada 60 s).
- [ ] Con el servidor encendido y 0 clientes, el reloj del mundo avanza: 60 s simulados producen 60 s de avance.
- [ ] La suite de esta historia termina en menos de 10 minutos y pasa 3 ejecuciones seguidas sin fallos.

---

## Implementation Notes

Crear un simulador de clientes sin ventana que envíe intenciones aleatorias con semilla fija (determinismo). Las pruebas de tiempo usan un reloj simulado, no el reloj real. La sesión del jugador tiene un contador de desconexión; el personaje queda en el mundo hasta que expira.

---

## Out of Scope

- 002: sincronización básica · 003: formato del guardado · 004: conectividad real entre redes.

---

## Files

- `Linde/cenital/scripts/red/sesion_jugador.gd` (nuevo)
- `Linde/cenital/tests/multijugador/simulador_clientes.gd` (nuevo, ayuda de pruebas)
- `Linde/cenital/tests/multijugador/sincronizacion_test.gd` (cambia)
- `Linde/cenital/tests/multijugador/desconexion_test.gd` (nuevo)
- `Linde/cenital/tests/multijugador/reconexion_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: `Linde/cenital/tests/multijugador/desconexion_test.gd`, `reconexion_test.gd` y `sincronizacion_test.gd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/multijugador/story-002-red-servidor-autoritativo.md`, `production/epics/multijugador/story-003-guardado-varios-personajes.md`
- Unlocks: None
