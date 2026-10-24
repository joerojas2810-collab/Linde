# Epic: Multijugador mundo anfitrión

> **Status**: Planned (historias listas; 004 bloqueada hasta verificar la conectividad)
> **Brief**: `design/game-brief.md` (Build order, paso 7)
> **ADR**: ver ADR propuesto (`docs/architecture/adr-0001-multijugador-mundo-anfitrion.md`, aún no aceptado)
> **Code root actual**: `Linde/cenital/` (la plantilla espera `src/`; ver `docs/adoption-plan-2026-10-23.md`)

## Goal
Un anfitrión abre su mundo desde el menú o con un servidor sin ventana, y hasta 15 jugadores se conectan para explorar, construir y progresar en el mismo valle. El mundo avanza solo mientras el servidor está encendido. El servidor es autoritativo; el estado de cada jugador es separado del estado compartido.

## Scope
1. Estado por jugador separado del estado compartido, con migración del guardado a formato 2.
2. Red mínima con servidor autoritativo: dos jugadores en localhost, posiciones y acciones sincronizadas.
3. Guardado y carga con varios personajes e identidad simple por jugador.
4. Conectividad y modo sin ventana (anfitrión desde el menú y servidor headless).
5. Permisos de construcción y botín por jugador, con intercambio directo entre jugadores.
6. Pruebas de sincronización, desconexión y reconexión.

Fuera de alcance: servidor MMO masivo, cuentas con seguridad de producción, economía de servidor (A03), avance con la aplicación cerrada (P06). Ver *Out of scope* en el brief.

## Build order
1. **001** primero: el refactor de estado es barato ahora y caro después.
2. **002** red mínima, base de todo lo demás.
3. **003** guardado con varios personajes.
4. **004** conectividad, bloqueada hasta probar entre máquinas reales puerto abierto, UPnP o VPN.
5. **005** permisos y botín, sobre 003.
6. **006** pruebas de sincronización, desconexión y reconexión, sobre 002 y 003.

Grafo de dependencias: 001 → 002 → 003 → 005; 002 → 004; 002 + 003 → 006.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Estado por jugador y compartido, migración del guardado | Logic | Ready | ver ADR propuesto |
| 002 | Red mínima con servidor autoritativo | Integration | Ready | ver ADR propuesto |
| 003 | Guardado y carga con varios personajes e identidad | Logic | Ready | ver ADR propuesto |
| 004 | Conectividad y modo sin ventana | Integration | Blocked — sin API de relay ni NAT integrada; UPnP y conexión entre máquinas reales sin verificar | ver ADR propuesto |
| 005 | Permisos de construcción y botín por jugador | Logic | Ready | ver ADR propuesto |
| 006 | Pruebas de sincronización, desconexión y reconexión | Integration | Ready | ver ADR propuesto |
