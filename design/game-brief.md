# Game Brief: Linde

**One-sentence pitch:** Explora un valle desconocido con tu propio personaje, rompe y construye lo que encuentras y progresa por oficio y habilidades entre habitantes que viven su rutina, hasta enfrentar jefes de capítulo y de mundo.

## Core loop
- Explorar: encontrar recursos, desafíos o gente que necesita algo.
- Reunir y fabricar: romper objetos, fabricar, construir (el lugar cambia).
- Actuar: misiones, relaciones con habitantes, combate y jefes.
- Recompensa: habilidades y acceso nuevo, que abren más exploración.

## Player goal & fail state — what "working" looks like
- Meta: completar el capítulo (sus misiones y su jefe) dejando el valle distinto a como lo encontraste; una sesión se siente completa si construiste algo, mejoraste una habilidad y avanzó una misión.
- Fallo: no hay game over; la derrota te devuelve a tu cama sin perder objetos (provisional, A01 pendiente).

## MVP — what must exist to be the game
- Mundo cenital con personaje propio, inicio seguro por semilla y guardado versionado.
- Recolección de objetos rompibles e inventario con transacciones atómicas.
- Construcción y retirada de piezas que alteran colisión y rutas.
- Fabricación y árbol de habilidades definidos como datos.
- Habitantes con rutina (necesidad → actividad → ruta) que reaccionan al mundo.
- Misiones de capítulo y de mundo con condiciones reales y recompensa única.
- Combate con un jefe de capítulo, un jefe de mundo y un tesoro.

## Out of scope — not building this
- Servidor MMO masivo, cuentas con seguridad de producción y economía de servidor (A03). *(El multijugador «mundo anfitrión» de 10–15 jugadores sí está en el plan: ver Build order, paso 7.)*
- Generación procedural total del mapa: mapas de autor con puntos de inicio elegibles.
- Economía, comercio y precios (A03).
- Avance del mundo con la aplicación cerrada (P06).
- Canon narrativo cerrado y narrativa generada por LLM (A02).
- Sprites finales, audio y localización.

## Build order
1. Jugar a mano el prototipo cenital existente (`Linde/cenital`) y validar que el bucle divierte: hasta ahora solo hay pruebas automáticas.
2. Cerrar el modelo de combate (A01) con jefes jugables y afinados.
3. Validar que el mundo reacciona: habitantes, rutas, camas y construcciones.
4. Capítulo 1 completo con contenido real, no de prueba (A02).
5. Balance de fabricación y habilidades (A03).
6. Hoja de estilo y sprites finales (el arte lo produce GPT).
7. **Multijugador «mundo anfitrión» estilo Minecraft para 10–15 jugadores** (decisión del usuario, 2026-10-23; A04 decidida): estado por jugador separado del compartido, red con servidor autoritativo, guardado con varios personajes, conectividad y modo sin ventana. El mundo avanza solo mientras el servidor está encendido (se conserva P06). Epic en `production/epics/multijugador/`, ADR propuesto en `docs/architecture/`. Se empieza por el refactor de estado, que es barato ahora y caro después.

---
**Who it's for / what they feel:** Jugadores en solitario de RPG de progresión y construcción que quieren sentir oficio y crecimiento, en sesiones de 20 a 60 minutos.

**Art & audio direction:** Pixel art de estética portátil clásica, sencillo y legible, con vista superior oblicua: tejados y fachadas visibles, personajes de proporciones pequeñas y expresivas, colores definidos y sombreado contenido. Escenarios transitables arriba, abajo, izquierda y derecha, siguiendo la referencia visual elegida (`Linde/documentos/LINDE_Punto_de_Inicio/referencias/visual_objetivo.png`). Audio sin definir.

**Resolución:** por definir mediante una prueba en el motor. Evaluar una cuadrícula de 16 × 16 px y comprobar si permite el detalle deseado en personajes, ropa y equipo.

**Reference game:** Pokémon HeartGold — solo la legibilidad de su vista cenital oblicua; sin sus assets, reglas ni argumento.
