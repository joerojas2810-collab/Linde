# Linde: canon de trabajo narrativo

> **Estado: PROPUESTA. No es canon aprobado ni una decisión del usuario.** Es una propuesta reversible del Narrative Director para desbloquear el capítulo 1 mientras **A02 sigue abierta**. Todo lo marcado «(propuesta)» está inventado aquí; lo no marcado procede de `catalogos.gd`, `Linde/documentos/sistema-de-equipo.md`, `design/game-brief.md` o `Linde/documentos/LINDE_Punto_de_Inicio/`. Al aprobar o rechazar, se actualiza la tabla de la sección 9.
> Reglas heredadas: valle de fantasía que existe por sí mismo (sin «elegido» ni «atrapado en un videojuego»); el personaje lo crea el jugador; sin nombres, mapas ni argumentos de Overgeared, Shangri-La Frontier, SAO ni la obra del slime. Multijugador «mundo anfitrión» (10-15 jugadores): los hechos del mundo son compartidos; misiones y relaciones, por jugador.
> Los textos de `catalogos.gd` (`DIALOGOS`) son de PRUEBA; este canon no los sustituye hasta que el usuario lo decida.

## 1. Premisa de trabajo y tono (propuesta)

Un valle pequeño y antiguo, con una aldea de oficios, una cantera y bosque cerrado a su alrededor. La gente vive de la piedra, la madera y la fibra. Hace poco la mena de la cantera sale «rara» y algo se ha despertado en las ruinas del sureste. El valle no espera a nadie: quien llega (viajero, aprendiz o cazador, los orígenes de prueba) es útil por lo que fabrica, descubre y ayuda a levantar, no por un destino.

Tono: cálido y artesanal, con inquietud contenida; los peligros son consecuencias del valle, no villanos de cartón. La aventura convive con construir y reunir: nadie exige salvar el mundo; el primer conflicto es de taller y de cantera.

## 2. El valle: lugares (propuesta de función; ubicación solo donde ya está dicha)

| Lugar | Función narrativa (propuesta) |
|---|---|
| Aldea y casa de Maren | Base social: vivienda, taller de Maren, cama del jugador. Aquí se entregan y se cierran las misiones. |
| Estanque | Zona tranquila de recolección; origen de la Piedra de Alma. El camino al sureste pasa por él (dicho en el diálogo de prueba). |
| Cantera (con el cofre `tesoro_cantera`) | Fuente de piedra y mena; el cofre es un secreto de exploración, misión de mundo `mundo_tesoro`. |
| Bosque | Recursos, enemigos y origen de la Piedra de Armonía y de la familia Zarzal. |
| Claro del Gran Ciervo | Lugar sagrado y peligroso del bosque; no es parte del camino del capítulo. |
| Ruinas del sureste (Guardián) | Origen de la Piedra de Bendición; lo que «despertó» y altera la mena. |

## 3. Personajes (propuesta salvo Maren)

Maren existe (da las tres misiones del capítulo 1). Su objetivo, horario y personalidad más allá de las líneas de prueba son propuestos.

| Habitante | Objetivo propio | Horario (día de juego = 24 min) | Qué ofrece al jugador |
|---|---|---|---|
| **Maren** (artesana del taller) | Reabrir el taller y comprender por qué la mena cambió, sin dejar que la cantera se cierre. | Taller de día; casa y cama de noche; visita la mesa de trabajo cuando existe. | Las misiones del capítulo 1; enseñar artesanía una vez hay mesa (`artesano`). |
| **Ordal** (cantero) | Mantener abierta la cantera aunque la vena sea inestable; le preocupa que lo culpen. | Cantera de mañana y tarde; estanque al mediodía; casa al anochecer. | Pistas sobre vetas y sobre el sureste; reacciona si el jugador construye o rompe cerca de la cantera. |
| **Nerea** (recolectora del bosque) | Cartografiar el bosque y saber si el Gran Ciervo se aleja o se acerca al lindero. | Bosque temprano; aldea a mediodía; vuelve al lindero al caer la tarde. | Pistas sobre baya, fibra y el claro; avisa del estado del Ciervo si ella lo ha visto. |

Ordal y Nerea no tienen misión asignada en el catálogo: sus ofertas son un hueco abierto para rutinas futuras, no contenido existente.

## 4. Capítulo 1 «Piedra para el taller» (propuesta; el catálogo llama a la primera misión «Piedras para el taller»)

**Pregunta dramática:** ¿puede el taller de Maren volver a trabajar con una cantera que ya no da la mena de siempre, y qué la altera?

**Beats** (condiciones reales de `MISIONES`):
1. `cap1_piedras`: hablar con Maren y entregar 6 piedras (se consumen). Maren necesita cimientos: sin base no hay taller.
2. `cap1_mesa`: construir una mesa de trabajo. Maren no puede enseñar sin ella; el jugador deja huella física en el valle.
3. `cap1_ruinas`: visitar las ruinas (`visito_ruinas`) y derrotar al Guardián. La mena rara sale de lo que despertó allí.

**Conflicto (propuesta):** la cantera, al excavar más hondo, tocó algo bajo las ruinas; el Guardián defiende ese lugar y, mientras actúe, la veta es inestable. Ordal quiere seguir picando; Maren, entender antes.
**Consecuencias:** al caer el Guardián la veta se estabiliza, la cantera y el taller «respiran» (línea de prueba de cierre), y queda abierta la pregunta de qué hay bajo las ruinas (pendiente, sección 8). Libertad: construir, picar o explorar ayuda, pero no exige dominar todos los oficios.
**Relación jefe-conflicto:** el Guardián no cierra una barra; es la causa visible del problema del taller. Misión `cap1_ruinas`: recompensa de misión 100 xp y 2 gemas; la recuperación ante bloqueo (p. ej. perder piedras) se resuelve con el juego, no con diálogo.

## 5. Jefes (propuesta de razón de ser)

- **Guardián de las Ruinas** (jefe de capítulo, no reaparece). Propuesta: construido para custodiar lo que hay bajo las ruinas; despierta cuando la excavación lo roza. Existe una sola vez porque su función se cumple una vez. Da una recompensa única fuera de set (A02).
- **Gran Ciervo del Claro** (jefe de mundo, reaparece cada 72 h de juego). Propuesta: espíritu-guardián del bosque ligado al ciclo de las estaciones; reaparece porque el bosque se renueva, no por azar. No es enemigo del taller: cazarlo es una decisión del jugador y Nerea puede cuestionarla. Su familia de armadura es Albor.

## 6. Lore de piedras y familias (propuesta; origen según `sistema-de-equipo.md`)

- **Piedra de Alma** (variante Divino, zona del estanque): se forma donde el agua quieta guarda memoria; da más vida, menos defensa.
- **Piedra de Armonía** (Brillante, bosque): nace de la vida entrelazada del bosque; da velocidad, menos vida.
- **Piedra de Bendición** (Oscuro, ruinas): quedó en las ruinas, vinculada a su custodia; da defensa, menos agilidad. Su nombre es irónico: la bendición pesa.
- **Vigía** (fabricable): armadura de los oficios de la aldea, hecha en mesa con lingote y fibra; vigilar la cantera.
- **Zarzal** (farmeo en el bosque, ligera): piezas trenzadas por quienes viven del bosque; se encuentran, no se fabrican.
- **Albor** (Gran Ciervo, pesada): piezas que el Ciervo deja al renovarse; el jugador las obtiene, no las toma.

Las piedras no explican de dónde viene la magia del mundo: eso es cosmología (sección 8).

## 7. Reglas de diálogo

1. Cada línea declara su tipo: expresiva, abre misión o cambia relación. **Ningún diálogo concede objetos, resuelve misiones ni salta condiciones**: las recompensas las da el sistema de misiones.
2. Un habitante solo sabe lo que observó: presenció, le contó otro habitante con regla de difusión, o ve en el estado del mundo (p. ej. una mesa construida a la vista).
3. Difusión (propuesta): solo hechos observados, con retraso; el interlocutor atribuye la fuente («me dijeron que…»). Nunca se difunde lo que nadie pudo ver.
4. Hechos del mundo (jefe caído, cofre abierto, construcciones) son compartidos en el mundo anfitrión; misiones, vínculos y lo que el jugador «ha contado» son por jugador.
5. Los orígenes (aprendiz, viajero, cazador) solo dan contexto de diálogo, sin ventaja numérica.

## 8. Qué queda abierto (no inventado)

Conflicto central de capítulos posteriores; final; cosmología (qué es el valle, de dónde viene la magia, si hay otros reinos); naturaleza real/virtual/otra del mundo; qué hay bajo las ruinas; motivo último del Guardián y del Ciervo; recompensa única del Guardián; ofertas reales de Ordal y Nerea; texto final de diálogos; nombre del valle.

## 9. Propuesta vs. acordado

| Elemento | Estado |
|---|---|
| Premisa abierta de región desconocida; mundo de fantasía propio, sin «elegido» ni «videojuego» | Acordado / propuesta de dirección en `01_VISION` |
| Tres misiones, jefes, cofre y 72 h | Existe en `catalogos.gd` (provisional, A01/A03) |
| Familias, piedras y variantes | Existe en `sistema-de-equipo.md` (propuesta v1) |
| Tono, premisa del valle (sec. 1) | Propuesta |
| Función narrativa de los lugares (sec. 2) | Propuesta |
| Maren: objetivo y horario; Ordal y Nerea (sec. 3) | Propuesta |
| Conflicto y consecuencias del cap. 1 (sec. 4) | Propuesta |
| Razón de ser de los jefes (sec. 5) | Propuesta |
| Lore de piedras y familias (sec. 6) | Propuesta |
| Reglas de diálogo y difusión (sec. 7) | Propuesta (basada en `03_NARRATIVA`) |
| Conflicto central, final, cosmología | Abierto |
