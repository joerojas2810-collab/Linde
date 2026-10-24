# Story 003: Guardado y carga con varios personajes e identidad

> **Epic**: Multijugador mundo anfitrión
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md` (Build order, paso 7)
**Requirement**: Brief, paso 7 (guardado con varios personajes)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.1 | **Risk**: HIGH (Godot 4.7, `docs/engine-reference/godot/VERSION.md`)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Performance**: guardar 15 personajes en menos de 500 ms (mediana de 10 ejecuciones) en el equipo de desarrollo.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*Decisión base: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado).*

- [ ] Un mundo guarda entre 1 y 15 personajes, cada uno con su id, nombre y apariencia; una prueba guarda y carga 15 personajes con los datos iguales.
- [ ] La identidad se crea la primera vez con un id generado y se guarda en el perfil local. Reconectar con ese id devuelve el mismo personaje; un id desconocido crea un personaje nuevo (3 casos probados).
- [ ] Dos jugadores con el mismo nombre visible reciben personajes con ids distintos.
- [ ] Un personaje desconectado se conserva intacto en el guardado (inventario y misiones iguales tras 10 ciclos de guardado y carga).
- [ ] Un guardado de 15 personajes ocupa menos de 2 MB.
- [ ] Un guardado interrumpido a mitad (simulado) se recupera desde el respaldo, y ningún personaje del guardado anterior se pierde.

---

## Implementation Notes

Extender el formato 2 de la historia 001 con una lista de personajes indexada por id. El id de identidad es local y simple: no hay cuentas ni contraseñas en esta historia. Reutilizar el checksum y el `.bak` de `guardado.gd`.

---

## Out of Scope

- 001: separación de estado · 002: red · 004: conectividad · 005: permisos y botín · 006: pruebas de reconexión.

---

## Files

- `Linde/cenital/scripts/guardado.gd` (cambia: lista de personajes)
- `Linde/cenital/scripts/identidad_jugador.gd` (nuevo)
- `Linde/cenital/scripts/estado_jugador.gd` (cambia: id y nombre)
- `Linde/cenital/tests/multijugador/guardado_personajes_test.gd` (nuevo)
- `Linde/cenital/tests/multijugador/identidad_test.gd` (nuevo)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `Linde/cenital/tests/multijugador/guardado_personajes_test.gd` y `identidad_test.gd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/multijugador/story-002-red-servidor-autoritativo.md`
- Unlocks: `production/epics/multijugador/story-005-permisos-botin-jugador.md`, `production/epics/multijugador/story-006-pruebas-sincronizacion-reconexion.md`
