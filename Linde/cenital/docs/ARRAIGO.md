# Arraigo, oficios y vivienda

Contrato de la primera versión (etapas 0–11 de la propuesta «Arraigo y Vidas en Movimiento» + «Profesiones, Oficios y Sociedad Productiva»). Todo es provisional y se afina jugando; los valores están en `datos/autonomia/reglas.json` (`sociedad.arraigo`, `sociedad.biografia`, `sociedad.inmigracion`, `sociedad.vivienda`, `sociedad.vigilancia`, `sociedad.exploracion`).

## Llegada
- La llegada depende de la **presión** (`Sociedad.presion()`): sustento (riqueza) × seguridad (robos de los últimos 2 días) + un pequeño bono por oficios que faltan. Las camas no intervienen.
- El director usa la variable `presion_llegada` (porcentaje; 100 = se puede acoger a alguien) y también cuenta actividad construida que no sean camas.
- Quien llega sin cama libre **duerme al raso** donde está, con la mitad de recuperación (`DESCANSO_AL_RASO` en `habitantes.gd`).

## Permanencia (`scripts/arraigo.gd`)
- Estados: visitante → aspirante → residente; ausente (conserva ficha, inventario y recuerdos y puede regresar).
- El arraigo (0–1) mezcla sustento, seguridad, relaciones, oportunidades, condiciones e historia; la motivación del personaje cambia los pesos. Se evalúa una vez por día de juego.
- Los colonos de partidas anteriores cuentan como residentes y reciben una biografía razonable.

## Biografía
- Origen, antecedente, motivación y aspiración salen de listas de datos. Los antecedentes con persona (deuda, conocido, rival) solo apuntan a habitantes que existen y siembran confianza; la deuda se salda con bienes reales.
- Una aspiración cumplida se registra y pasa a otra; no se repite.

## Oficios
- Profesión (`perfil.oficio`), ocupación (`estado.ocupacion`) y habilidades (práctica de `Desarrollo.rango`) son cosas distintas. Se ven en el panel J.
- `perfil.prioridad` reordena las ocupaciones; no crea sistemas aparte. Oficios: cantero, artesano, albañil, recolector, agricultor, explorador, mercader, guardia.
- Sin albañil en el valle, cualquiera levanta casas con madera. El mercader solo opera con `acordar()`; el guardia disuade el hurto durante su turno.
- La probabilidad de que llegue cada oficio sube cuando falta.

## Vivienda
- Un solar se planifica **para alguien** (`parcela.para`); la cama construida en él es de esa persona.
- Con dos o más personas al raso se planifica una **casa comunitaria** (`vivienda.comunitaria`): tres camas bajo un mismo techo. La capacidad son sus camas.

## Marcharse y regresar (decisiones del 25/10)
- Quien se marcha **conserva** pertenencias personales (inventario), biografía, vínculos, deudas y recuerdos; su ficha sigue en `colonos`. Al regresar es la misma persona (mismo id, nombre e historia), como visitante.
- Los **edificios no se borran**. Siguen a nombre de su dueño (`dueno: npc:<id>`) mientras esté ausente:
  - Su **cama** se libera (`camas_asignadas`), así que otro puede usarla; al volver no tiene cama garantizada y puede tomar una libre.
  - Un **solar planificado para él** (`parcela.para`) puede reasignarse a quien duerma al raso; las piezas ya construidas se conservan.
  - Su **cofre y sus piezas personales** siguen siendo suyos: no pasan a otro por ausencia. Como nadie los vigila, un cofre ajeno sin candado es más fácil de robar (ya ocurre hoy con cualquier cofre sin dueño cerca).
  - Lo **del grupo** (depósito, campos, estaciones) sigue siendo del grupo y lo usa quien lo necesite.
  - No hay herencia ni abandono automático: pasar un edificio de un ausente a otro dueño queda como decisión futura.
- **Avisos:** solo los personajes relevantes (residentes, con ayudas a un jugador o con deuda abierta) generan aviso a los jugadores; el resto queda en el registro de sucesos (`partida`, `regreso`).

## Verificación del 25/10 (resultados reales)
Simulación sin jugador, 7 días de juego, 100.800 ticks de 0,1 s (script de la sesión, no incluido en el repo), semillas 123 y 7, tras corregir `habitat.permite_pieza`:

| | semilla 123 | semilla 7 |
|---|---|---|
| Habitantes día 7 | 8 | 9 (límite técnico 12) |
| Llegadas | 6 | 7 |
| Casas completas día 7 | 5 (antes de la corrección del relevo: 3) | 6 (antes: 0) |
| Marchas / regresos | 0 / 0 | 0 / 0 |
| Persistencia tras guardar y cargar | idéntica | idéntica |
| Tick medio / peor | 4,0 ms / 6,5 s | 3,4 ms / 4,1 s |

Construcción dirigida (`tests/prueba_casas_arraigo.gd`, ticks reales, sin albañil, madera de respaldo): casa individual 8/8 piezas y comunitaria 13/13 piezas (tres camas), ambas completas en la primera muestra, a las 30 horas de juego.

Persistencia (`tests/prueba_arraigo.gd`): biografía, deuda, vínculos, inventario, recuerdos y estado de permanencia, de presentes y de un ausente, quedan idénticos tras guardar y cargar; el ausente que regresa es la misma persona.

### Comportamientos anómalos (sin ajustar el balance)
- **Nadie se marcha en 7 días.** La presión sube a 1,5–1,65 y llega una persona por día hasta el límite de 12; el arraigo nunca baja del umbral de partida (0,35). Ni `partida` ni `regreso` aparecen en los sucesos. El mecanismo está probado por pruebas dirigidas, pero no se ha visto en una partida libre.
- **Llegadas lineales.** Una por día (`espera_min` 1440), sin saturación hasta `max_habitantes`; la riqueza llega a 600–690. El mercader no llegó en ninguna de las dos semillas.
- **Pausas de planificación.** Hay 69–73 ticks mayores de 800 ms (los peores, 4–7 s) con 2 a 9 habitantes. Medido con la misma semilla durante 2 días: código en HEAD, 0 ticks lentos (peor 210 ms); HEAD más solo los archivos de arraigo, 0 (peor 269 ms); árbol de trabajo completo, 18 (peor 3,4 s). Por tanto no vienen de arraigo sino de cambios sin commit de otra sesión (`desarrollo.gd`, `artesania.gd`, `juego.gd`, saberes). Las ocupaciones activas en esos momentos son fabricar y proveerse.
- **Una parcela queda `bloqueada`** en ambas semillas (un obstáculo en el solar); ya existía y se reintenta.
- **Relevo de obra (corregido):** el albañil sin ladrillos bloqueaba a los demás y `_refugio` exigía ladrillo mientras `_casa` ya aceptaba madera. Ahora `_refugio` usa madera sin ladrillos a mano y otros ayudan si la obra lleva `vivienda.relevo_min` (24 h) esperando.

## Pendiente conocido
- El campamento no tiene lugar fijo ni arte (ver `ARTE_PENDIENTE.md`).
- Aprendizaje entre NPC, especializaciones, reputación profesional, ausentes con simulación resumida e identidades de asentamiento quedan fuera de esta versión.
- Las casas siguen sin completarse de forma fiable en simulaciones largas (el respaldo de madera ahora sí cabe en el solar, pero no se ha medido).
- Prueba: `tests/prueba_arraigo.gd`.
