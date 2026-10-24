# Epic: Mundo vivo — rebanada mínima

Estado: **implementado (5 de 5 historias, 2026-10-24); el estado actual está en [ESTADO.md](ESTADO.md). Este documento conserva el plan original y sus decisiones de partida.**

## Objetivo
Probar en el juego, con algo que corre, que el valle cambia solo con el tiempo y con lo que construye el jugador, sin un guion fijo escrito de principio a fin. Al terminar: un habitante nuevo llega por una tarjeta de evento, pide algo y el jugador lo cumple con los sistemas de hoy.

## Decisiones del usuario (2026-10-24)
- **Servidor siempre encendido, en un hosting.** El mundo avanza mientras el servidor esté encendido, como en Minecraft; no se congela sin jugadores. Coherente con el game brief (paso 7) y P06; no se reescribe ninguno de los dos.
- **Crecimiento mixto (C):** los hitos de misión abren posibilidades y la construcción las concreta. Sin historia fija: el mundo se compone de piezas de datos (habitantes, eventos, plantillas) que un director combina.
- **Ordal está presente desde el inicio**, para probar el multi-NPC antes de las llegadas.
- **Los habitantes que llegan aparecen en el sur**, en el extremo del camino de entrada (`Mundo.ENTRADA`, celda 32,46).
- **Dormir deja de saltar el reloj compartido.** Solo cura y fija la cama.

## Fuente de los datos
El Atlas de GPT (`/Users/josephrojas/Documents/ChatGPT/Linde/`, fuera de este repo) define el contrato: `docs/atlas-contrato.md`. Este epic es el **consumidor** en el juego. No modifica el Atlas; el Atlas no modifica `Linde/cenital/`. Ordal y Nerea son propuesta (`design_status: proposed`), no canon aprobado (A02 sigue abierto).

## Lo que ya existe y se reutiliza
- `Juego._rng(nombre, clave)`: azar sembrado y repetible.
- `Juego._hora_en_punto()`: gancho horario para el director.
- `d.npcs` y `d.min`: estado compartido de habitantes y reloj.
- `Habitantes`: ruta BFS a la cama y estado `sin_cama`.
- `Catalogos.validar()`: patrón de validación de referencias.

## Diferencias entre el contrato del Atlas y este plan (resolver antes del paso 4)
1. **Efectos.** El contrato solo permite `asignar` y `sumar` sobre variables de mundo. No hay «llega un habitante», «avisa» ni «crea misión». Resolución propuesta: la llegada es una variable (`ordal_presente`, por ejemplo) y el motor reacciona al cambio; el aviso lo emite el motor con el nombre del evento. Confirmar con el usuario/GPT.
2. **Variables derivadas.** Camas libres, piezas construidas o jefes caídos salen del estado del juego, no de contadores propios. El contrato tiene `persistir` pero no distingue «derivada de solo lectura». Hay que pedir esa distinción.
3. **Recompensas.** Las plantillas no conceden premios (`efectos_completar` solo toca variables). Las misiones actuales sí pagan (`rec`). Decidir si las misiones de mundo generadas pagan, y cómo se expresa.
4. **Lugares a celdas.** Los destinos de la rutina son `lugar` lógicos; el juego usa celdas. Hace falta una tabla lugar → celda en el adaptador (p. ej. `entrada_sur` → 32,46).
5. **Actividades.** El contrato admite dormir, trabajar, socializar, descansar y explorar; el juego hoy usa `taller`, `plaza` y `dormir`. Mapear `taller` → trabajar, `plaza` → socializar.

## Pasos (cada uno con su prueba)
0. **Arreglo previo:** `dormir()` ya no avanza el reloj. *Prueba:* tras dormir, `d.min` no cambia; HP y cama sí.
1. **Habitantes desde datos.** La rutina de Maren sale de `habitantes.gd` a un archivo de datos. *Prueba:* misma posición y actividad por hora que antes.
2. **Ordal presente desde el inicio**, con cama y rutina. *Prueba:* dos NPC con rutas y camas sin pisarse; bloqueo si falta cama.
3. **Variables del mundo**, derivadas del estado guardado cuando sea posible. *Prueba:* valor esperado en estados armados a mano.
4. **Director de eventos** en `_hora_en_punto`: candidatos (aprobados, condiciones verdaderas, peso > 0, enfriamiento vencido), elección ponderada con `_rng`, efectos atómicos (todo o nada). *Prueba:* misma semilla y hora dan la misma elección; el enfriamiento se respeta; un efecto o variable desconocidos se rechazan.
5. **Registro de causas** acotado en tamaño: qué condición disparó cada evento.
6. **Misión por plantilla** de mundo, con la decisión 3 resuelta. *Prueba:* se completa y paga una sola vez.
7. **Guardado:** claves nuevas con valores por defecto, como se hizo con `equipo`. *Prueba:* una partida antigua carga sin perder nada.
8. **Red:** el director corre solo en el servidor; el evento llega a todos. *Prueba:* integración con dos clientes (`tests/prueba_red.gd`).
9. **Evidencia visual:** captura retenida en `production/qa/evidence/` del aviso y de Ordal en escena.

## Fuera de alcance
Zonas nuevas, texto generado por LLM, economía y balance (A03), arte final de los habitantes nuevos, hosting y pantalla de conexión (van en el epic de multijugador).

## Riesgos
- Las constantes de ritmo (cada cuántas horas de juego se evalúa un evento) son provisionales: solo una partida jugada a mano dice si el valle se siente vivo o repetitivo.
- Con pocas tarjetas el mundo se repite; la variedad depende del contenido escrito.
- Una llegada necesita cama libre y ruta válida desde el sur; si no la hay, el evento no debe aplicarse.
