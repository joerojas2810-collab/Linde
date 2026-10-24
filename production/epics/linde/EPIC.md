# Epic: Linde

> **Status**: In progress (el prototipo cenital existe; las historias validan y cierran brechas)
> **Brief**: `design/game-brief.md`
> **Code root actual**: `Linde/cenital/` (la plantilla espera `src/`; ver `docs/adoption-plan-2026-10-23.md`)

## Goal
Explora un valle desconocido con tu propio personaje, rompe y construye lo que encuentras y progresa por oficio y habilidades entre habitantes que viven su rutina, hasta enfrentar jefes de capítulo y de mundo.

## Scope (MVP del brief)
1. Mundo cenital con personaje propio, inicio seguro por semilla y guardado versionado.
2. Recolección de objetos rompibles e inventario con transacciones atómicas.
3. Construcción y retirada de piezas que alteran colisión y rutas.
4. Fabricación y árbol de habilidades definidos como datos.
5. Habitantes con rutina que reaccionan al mundo.
6. Misiones de capítulo y de mundo con condiciones reales y recompensa única.
7. Combate con un jefe de capítulo, un jefe de mundo y un tesoro.

Fuera de alcance: ver *Out of scope* en el brief (multijugador, generación total del mapa, economía, avance con la app cerrada, canon cerrado, sprites finales y audio).

## Build order
Las historias siguen el orden del brief: validar el bucle jugando (001, 002), combate A01 (003), el mundo reacciona (004, 005), capítulo 1 real (006), balance (007). El arte final queda fuera: lo produce GPT; el código usa marcadores de posición.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Mundo cenital, personaje propio, inicio seguro y guardado | Integration | Ready | N/A (minimal) |
| 002 | Recolección de objetos rompibles e inventario atómico | Logic | Ready | N/A (minimal) |
| 003 | Combate: jefe de capítulo, jefe de mundo y tesoro | Integration | Ready | N/A (minimal) |
| 004 | Construcción y retirada de piezas | Integration | Ready | N/A (minimal) |
| 005 | Habitantes con rutina | Logic | Ready | N/A (minimal) |
| 006 | Misiones de capítulo y de mundo | Logic | Ready | N/A (minimal) |
| 007 | Fabricación y árbol de habilidades | Logic | Ready | N/A (minimal) |
