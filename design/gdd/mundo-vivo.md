# Mundo vivo

> **Status**: In Design
> **Author**: usuario + Claude (modo solo: sin especialistas consultados)
> **Last Updated**: 2026-10-24
> **Last Verified**: 2026-10-24
> **Implements Pillar**: Habitantes con rutina que reaccionan al mundo (game brief, MVP)

## Summary

Mundo vivo es el sistema que hace que el valle cambie solo mientras se juega: un director en el servidor elige, según el estado del mundo, tarjetas de evento (llegadas de habitantes, avisos, misiones) a partir de datos del Atlas. Existe para que el juego no sea un capítulo cerrado: los habitantes llegan y piden cosas según lo que el jugador construye y derrota. Es un mundo compartido por todos los jugadores, que avanza con el reloj del servidor.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Habitantes, Misiones, Construcción/Mundo, Guardado, Servidor autoritativo (ADR-0001), Atlas (paquete de datos)`
> *(Category: Gameplay, Layer y Priority inferidos del brief; no hay índice de sistemas en este nivel.)*

## Overview

El Mundo vivo hace que el valle cambie mientras se juega, sin una historia escrita de principio a fin. Un conjunto de piezas de datos (habitantes con objetivo y rutina propios, variables compartidas del mundo, tarjetas de evento y plantillas de misión) lo combina un **director** que corre solo en el servidor. Cada cierto tiempo de juego evalúa qué tarjetas se cumplen según el estado del mundo (día, camas libres, lo construido, jefes caídos), elige una con azar sembrado y aplica su efecto, por ejemplo la llegada de un habitante por el camino sur. El jugador no lo activa: lo influye con lo que construye y derrota, y lo percibe como un valle que responde, con gente que llega, pide una cama o un taller, y misiones que nacen de esas necesidades. Sin este sistema el juego es un solo capítulo que se acaba; con él hay razón para volver y seguir construyendo. Es automático y compartido: un único mundo para todos los jugadores, que avanza con el reloj del servidor mientras esté encendido.

**Fantasía:** el jugador siente que el valle vive por sí mismo y que su obra importa, porque la gente llega y reacciona a lo que levanta.

## Detailed Design

### Core Rules

Los datos vienen del Atlas (contrato `atlas-contrato.md`, versión del 2026-10-24) como un paquete exportado. Los valores marcados *provisional* son de ajuste y deben vivir en datos, no en código.

1. **Paquete fijo por sesión.** El servidor carga el paquete al arrancar y lo mantiene hasta reiniciar. No se aplica en caliente.
2. **Autoridad.** Solo el servidor selecciona y aplica eventos. Un cliente no puede pedir ni forzar uno.
3. **Reloj.** El director usa el reloj compartido `d.min` y corre mientras el servidor esté encendido, haya o no jugadores conectados (ADR-0001 §5, decisión del usuario 2026-10-24). El tiempo que el servidor estuvo apagado no se simula.
4. **Cadencia.** Una evaluación por hora de juego (`_hora_en_punto`, cada 60 min de juego). *Provisional.* Como máximo **un evento aplicado por evaluación**, así que el tope es 24 por día de juego.
5. **Candidatos.** Una tarjeta es candidata si: está aprobada (ver regla 6), sus condiciones son verdaderas sobre una instantánea coherente del estado, su peso es > 0 y su enfriamiento venció. Peso 0 la desactiva.
6. **Propuestas.** Las tarjetas `proposed` solo participan si el servidor se lanza con la opción de prueba `admitir_propuestas`. *Provisional, solo prototipo*: hoy las 15 tarjetas del Atlas son `proposed` y sin esta opción el director no dispara nada.
7. **Elección.** Entre los candidatos, selección ponderada por `peso` con `_rng("evento", str(d.min))`: misma semilla y minuto, misma elección. Sin candidatos no ocurre nada.
8. **Enfriamiento.** Por ID de evento y por mundo, en minutos de juego. Empieza al aplicar los efectos con éxito. Se persiste la última activación (`ultimo[id] = d.min`). Sin activación previa está disponible. Enfriamiento 0 permite elegirlo en la siguiente evaluación, nunca dos veces en la misma.
9. **Condiciones.** Datos cerrados: hojas `{variable, operador, valor}` con `eq, neq, gt, gte, lt, lte`, y grupos `y`/`o`. Profundidad ≤ 16, nodos ≤ 256. Sin expresiones, scripts ni `eval`. Una variable inexistente es error, no «falso».
10. **Efectos.** Solo `asignar` y `sumar` sobre variables `persistida`. ≤ 64 por lista, aplicados en orden sobre una copia del estado. Si cualquiera falla (tipo, límites, variable derivada), no se aplica ninguno y el enfriamiento no cambia. Las variables `derivada` son de solo lectura.
11. **Variables.** `persistida` (se guarda; el inicial solo se usa al crear el mundo) o `derivada` (la calcula el motor desde el estado del juego; sin `inicial`). Derivadas iniciales *propuestas*: `dia`, `camas_libres`, `habitantes_presentes`, `mesa_construida`, `guardian_derrotado`.
12. **Llegadas.** Un habitante se representa con una variable booleana `<id>_presente`. Cuando el motor ve que pasa a `true` y el habitante no está en el mundo, **reconcilia**: lo coloca en el sur, en la celda `Mundo.ENTRADA` (32,46), con su rutina y su cama. Si ya está presente no hace nada (sin duplicados). Ordal se crea con `ordal_presente = true` (presente desde el inicio); Nerea con `false`.
13. **Precondición de llegada.** Una llegada exige cama libre y una ruta válida desde la entrada hasta ella. Se comprueba antes de aplicar los efectos; si falla, el evento no se aplica y su enfriamiento no cambia.
14. **Aviso.** Al aplicarse un evento, el motor avisa a todos los jugadores con el nombre de la tarjeta (el canal de avisos de mundo ya existe).
15. **Misiones por plantilla.** `condiciones_oferta` verdaderas hacen que el motor ofrezca una instancia. La aceptación es explícita. Pasa a completada cuando `condiciones_completar` son verdaderas: aplica `efectos_completar` y paga la recompensa **una sola vez**, al jugador que completa. Lo que no cabe en su inventario queda en `pendientes`. `repetible: false` impide nuevas instancias; nunca hay dos activas del mismo propietario y plantilla. Ámbito `jugador`: `efectos_completar` vacío.
16. **Registro de causas.** Cada evento aplicado guarda `{min, id, variables leídas}` en un registro acotado a 50 entradas (la más antigua sale primero). *Provisional.*
17. **Dormir** no avanza el reloj: cura y fija la cama (paso 0 del epic).
18. **Guardado.** Las claves nuevas (`vars`, `ultimo`, `llegados`, `instancias`, `registro`) entran con valores por defecto, sin subir `FORMATO`, como se hizo con `equipo`.

### States and Transitions

**Tarjeta de evento**

| Estado | Entra cuando | Sale a |
|---|---|---|
| Disponible | sin activación previa, o enfriamiento vencido | Candidata (condiciones y peso OK) |
| Candidata | pasa los filtros de la regla 5 | Aplicada (resulta elegida y los efectos no fallan) / Disponible (no elegida) |
| Aplicada | efectos confirmados | En enfriamiento |
| En enfriamiento | `d.min - ultimo[id] < enfriamiento_minutos` | Disponible |

**Instancia de misión de mundo:** `ofrecida → activa → completada`. No hay vuelta atrás. Solo `repetible: true` crea otra instancia tras cerrar la anterior.

**Habitante:** `ausente → presente` por reconciliación. No hay salida en esta versión.

### Interactions with Other Systems

| Sistema | Entra | Sale | Dueño del contrato |
|---|---|---|---|
| Habitantes (`habitantes.gd`) | horario, necesidades y objetivo de la ficha NPC | alta de un habitante (reconciliación), lectura de camas libres | Mundo vivo define el alta; Habitantes ejecuta rutinas |
| Misiones (`juego.gd`) | plantillas con condiciones sobre variables de mundo | instancias, completado, recompensa | Mundo vivo. Las misiones actuales usan 6 tipos de objetivo; las plantillas necesitan un adaptador que evalúe variables |
| Construcción / Mundo (`mundo.gd`) | piezas construidas, camas, celdas | variables derivadas | Construcción |
| Combate / jefes | jefes derrotados | variable derivada `guardian_derrotado` | Combate |
| Guardado (`guardado.gd`) | claves nuevas con defecto | `vars`, `ultimo`, `llegados`, `instancias`, `registro` | Guardado |
| Servidor (`red_servidor.gd`, ADR-0001) | `d.min`, ticks | avisos de mundo y sección de estado `mundo` | ADR-0001 |
| Atlas (GPT) | paquete JSON versionado | — | Atlas; este GDD fija lo que el juego consume |

## Edge Cases

- **Si no hay candidatos:** no ocurre nada ni cambia el estado.
- **Si hay varios candidatos:** una sola elección ponderada por evaluación; los demás esperan a la siguiente.
- **Si una condición referencia una variable inexistente:** esa tarjeta se descarta en esa evaluación y el error queda en el registro; las demás se evalúan. Al cargar el paquete, una referencia rota rechaza el paquete entero. *Alinear con el Atlas: su contrato dice «bloquea la evaluación».*
- **Si un efecto rompe un mínimo o máximo, o apunta a una derivada:** no se aplica ninguno y el enfriamiento no cambia.
- **Si el servidor se reinicia en la misma hora de juego:** la última hora evaluada se persiste para no evaluar dos veces el mismo minuto; el enfriamiento persistido impide repetir el evento.
- **Si `<id>_presente` ya es `true` y el habitante existe:** la reconciliación no hace nada.
- **Si una llegada no tiene cama libre:** llega igual y duerme al raso hasta que haya una cama (la cama es descanso, no capacidad). Si hay cama libre pero sin ruta desde la entrada, el evento no se aplica y reintenta en la siguiente evaluación.
- **Si el jugador intenta bloquear la celda de entrada (32,46):** la construcción se rechaza explícitamente. La comprobación no depende solo de una búsqueda de alcanzabilidad, porque esa búsqueda incluye su origen aunque la celda esté bloqueada.
- **Si la cama de un habitante presente se retira:** vale el comportamiento actual (`sin_cama`).
- **Si el paquete cambia entre reinicios:** las variables guardadas desconocidas se conservan y se avisan; las tarjetas retiradas se ignoran; las variables nuevas toman su inicial.
- **Si nadie está conectado:** el mundo sigue avanzando; al volver, los jugadores ven el estado resultante.
- **Si el inventario del jugador está lleno al completar una misión:** el pago queda en `pendientes`, sin perderse ni duplicarse.
- **Si se pide completar dos veces la misma instancia:** el segundo pedido no cambia nada.
- **Si una evaluación y un reinicio coinciden con un guardado a medias:** manda el último guardado válido (autoguardado ya existente cada 30 s).

## Dependencies

| Sistema | Dirección | Tipo | Nota |
|---|---|---|---|
| Habitantes | Mundo vivo depende | Duro | Sin habitantes con horario y cama no hay llegadas |
| Misiones | Mundo vivo depende | Duro | Las instancias reutilizan oferta, aceptación y `pendientes` |
| Construcción / Mundo | Mundo vivo depende | Duro | Fuente de variables derivadas y de la ruta de llegada |
| Guardado | Mundo vivo depende | Duro | Persistencia de `vars`, `ultimo`, `instancias` y `registro` |
| Servidor autoritativo (ADR-0001) | Mundo vivo depende | Duro | Solo el servidor corre el director |
| Combate / jefes | Mundo vivo depende | Blando | Solo alimenta una variable derivada |
| Atlas (paquete de datos) | Mundo vivo depende | Duro | Define tarjetas, variables y plantillas; sin paquete el director no hace nada |

Ninguna de las dependencias tiene GDD, solo código y `DECISIONES.md`; los contratos de arriba son **provisionales**. Cuando cada una tenga GDD debe listar este sistema como dependiente (bidireccionalidad).

## Acceptance Criteria

- **GIVEN** la misma semilla y el mismo minuto, **WHEN** el director evalúa dos veces desde el mismo estado, **THEN** elige la misma tarjeta.
- **GIVEN** una tarjeta con enfriamiento 120 min aplicada en el minuto M, **WHEN** el director evalúa en M+60, **THEN** no es candidata; en M+120 sí.
- **GIVEN** una tarjeta cuyo segundo efecto viola un límite, **WHEN** se aplica, **THEN** no cambia ninguna variable y `ultimo[id]` no cambia.
- **GIVEN** un efecto que escribe una variable derivada, **WHEN** se aplica, **THEN** se rechaza y queda registrado.
- **GIVEN** un evento de llegada con cama libre y ruta válida, **WHEN** se aplica, **THEN** el habitante aparece en la celda (32,46) y su variable `<id>_presente` es `true`.
- **GIVEN** el mismo evento sin cama libre, **WHEN** se aplica, **THEN** el habitante aparece igual y no tiene cama asignada.
- **GIVEN** `ordal_presente = true`, **WHEN** el motor reconcilia por segunda vez, **THEN** hay exactamente un Ordal.
- **GIVEN** una plantilla de misión con recompensa, **WHEN** el jugador la completa, **THEN** recibe XP e ítems una sola vez; si el inventario está lleno, lo que no cabe queda en `pendientes`.
- **GIVEN** un cliente que envía un pedido de evento, **WHEN** el servidor lo recibe, **THEN** lo rechaza y no cambia nada.
- **GIVEN** un jugador que duerme, **WHEN** termina la acción, **THEN** `d.min` no cambia y su vida y su cama sí.
- **GIVEN** una partida guardada antes de este sistema, **WHEN** se carga, **THEN** no se pierde nada y las claves nuevas tienen valores por defecto.
- **GIVEN** 51 eventos aplicados, **WHEN** se consulta el registro, **THEN** tiene 50 entradas y falta la más antigua.
- **GIVEN** un servidor sin `admitir_propuestas`, **WHEN** todas las tarjetas son `proposed`, **THEN** el director no dispara ninguna y lo informa por nombre.
- **GIVEN** un servidor y dos clientes en red, **WHEN** se aplica un evento, **THEN** ambos reciben el aviso y el mismo estado del mundo.
- **Evidencia visual** (estándar del proyecto): captura retenida en `production/qa/evidence/` del aviso y de Ordal en escena.
