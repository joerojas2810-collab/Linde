# Optimización de `Autonomia._recurso` — resultados de aceptación

> **Fecha**: 2026-10-26 · **Autorizada por el usuario** (E1) con las condiciones de no cambiar decisiones, reglas ni balance · **Estado**: confirmado en un commit independiente (sin otros cambios). Las mediciones se hicieron sobre `HEAD 302c53d`; después entraron dos commits de otra sesión (`44f6f09`, `17f525c`) que solo tocan presentación (arte, escena, HUD) y no los archivos de simulación; el 26/10 se repitieron `prueba` (329 PASS, 1 FAIL previo), `prueba_autonomia` (33) y `prueba_sociedad` (48) sobre `17f525c` + este cambio.
> **Actualización del usuario durante la tarea**: «todo rápido y sin pruebas excesivas». Por eso se recortó el plan de verificación; lo omitido está en la sección 5.

## 1. Cambio realizado (2 archivos, +14 −2 líneas)
- [mundo.gd](../../Linde/cenital/scripts/mundo.gd) `alcanzables(desde, area, hasta = {})`: parámetro opcional. Si `hasta` (celdas como claves) no está vacío, la búsqueda **se detiene al alcanzar cualquiera de ellas** y devuelve lo visitado. Sin `hasta`, o si ninguna se alcanza, recorre todo igual que antes. Los demás llamadores no cambian.
- [autonomia.gd](../../Linde/cenital/scripts/autonomia.gd) `_recurso`: pasa como `hasta` las cuatro celdas vecinas del **candidato más cercano**. Como la función devuelve el primer candidato (en orden de distancia) con un vecino alcanzable, si el más cercano ya es alcanzable el resultado es el mismo con una búsqueda parcial; si no lo es, la búsqueda completa ocurre como antes.

**Por qué es exacto**: el orden de candidatos, las reglas de obstáculo (`bloquea`), el área, la inclusión de la celda de origen y el criterio de adyacencia no se tocaron. Solo se evita explorar celdas cuando ya se sabe la respuesta. No se añadió caché persistente, así que no hay invalidaciones ni estado nuevo.

## 2. Equivalencia funcional [M]
Se comparó, con las mismas semillas y escenarios, el **hash SHA-256 de todo el estado del juego (`j.d`) al final de cada día** y un **hash acumulado de cada resultado de `_recurso`** (habitante, ítem y objeto elegido).
- Control de determinismo: dos corridas del código original (semilla 123, 4 días) dieron hashes idénticos (`ac3f5636ea27630b`, `154453458`).
- Código original frente a optimizado: **idénticos** en todos los días de las tres configuraciones (123 × 4 días, 456 × 4 días, 123 × 9 días). Mismo número de decisiones en las dos corridas de 4 días (1.742 y 1.970), de llamadas a `_recurso` (658, 888 y 2.635) y de búsquedas de alcanzabilidad (961, 1.341 y 3.870). En la de 9 días, la línea base conserva el hash de estado por día y el conteo de `_recurso`, pero no el total de decisiones.
- Conclusión: **no cambia ninguna decisión ni resultado funcional**. Si cambiara, la integración debería detenerse; no es el caso.

## 3. Rendimiento [M]
Misma máquina, un solo proceso a la vez, 11.520 ticks de 0,5 s por cada 4 días, combate desactivado, sin jugador. La línea base de la semilla 123 es la **segunda** corrida (la primera tuvo un pico anómalo de 887 ms, atribuible a otra actividad de la máquina).

| | 123 · 4 días (2→5 hab.) | | 456 · 4 días (2→5 hab.) | | 123 · 9 días (2→10 hab.) | |
|---|---|---|---|---|---|---|
| | antes | después | antes | después | antes | después |
| Tiempo total de ticks | 62,3 s | **27,8 s (−55,4 %)** | 98,4 s | **37,7 s (−61,6 %)** | 254,7 s | **126,0 s (−50,5 %)** |
| Tick medio | 5,41 ms | 2,41 ms | 8,54 ms | 3,28 ms | 9,83 ms | 4,86 ms |
| p95 | 18,3 ms | 17,7 ms | 97,6 ms | 27,1 ms (−72 %) | — | 33,3 ms |
| p99 | 113,6 ms | 61,6 ms (−46 %) | 196,3 ms | 70,2 ms (−64 %) | — | 92,7 ms |
| Peor tick | 283,8 ms | 248,5 ms | 446,5 ms | 202,8 ms (−55 %) | 468,2 ms | 290,2 ms |
| Ticks > 100 ms | 147 | **18** | 498 | **42** | — | 192 |
| Búsquedas de alcanzabilidad | 961 | 961 | 1.341 | 1.341 | 3.870 | 3.870 |
| Celdas visitadas | 7,77 M | **2,27 M (−70,8 %)** | 11,93 M | **2,65 M (−77,8 %)** | 31,27 M | **11,28 M (−63,9 %)** |
| Tiempo en `alcanzables` | 43,5 s | 9,3 s (−78,6 %) | 69,7 s | 10,7 s (−84,6 %) | — | 47,4 s |

(«—»: no se conserva el dato de percentiles de la línea base de 9 días porque esa corrida se detuvo al pedir menos pruebas; sí se conserva su tick medio, máximo y búsquedas por día.)

**Lectura**
- El número de búsquedas no cambia: la reducción viene de que cada una visita muchas menos celdas (de ~8.000 a ~2.400 por búsqueda en 123).
- El coste total de tick baja entre **50 % y 62 %**, el tick medio en la misma proporción y los ticks de más de 100 ms bajan de 147 a 18 (123) y de 498 a 42 (456).
- **El peor tick baja poco en 123** (284 → 249 ms): los picos que quedan son búsquedas en las que el candidato más cercano **no** es alcanzable y hay que recorrer todo, que sigue costando ~40 ms por búsqueda. Con 10 habitantes el coste crece de nuevo (tick medio 4,9 ms; 192 ticks > 100 ms).
- Las cifras de CPU son de esta máquina, no un límite garantizado.

## 4. Suites [M]
Se ejecutó un subconjunto con `tests/ejecutar_suites.sh` (autonomía, persistencia y red): `prueba_autonomia` 33, `prueba_sociedad` 48, `prueba_arraigo` 76, `prueba_casas_arraigo` 3, `prueba_crecimiento` 27, `prueba_saberes` 87, `prueba_desarrollo` 57, `prueba_proteccion` 51, `prueba_fauna` 31, `prueba_terreno` 49, `prueba_red` 11 (clientes reales): **todas sin fallos**.
`prueba` (general): 329 PASS y **1 FAIL**: «mundo arte: los 96 archivos copiados de E04/E05 conservan el sha256 del manifiesto». **Falla igual con el código original** (329 PASS, 1 FAIL en una copia del árbol sin el cambio), así que no es una regresión de este cambio; es un problema previo de los archivos de arte o su manifiesto, sin investigar aquí. ESTADO.md registraba 330 PASS el 25/10.

## 5. Qué no se hizo (por la instrucción de acelerar)
- **12 habitantes**: la corrida más larga llegó a **10 habitantes** (día 9). Se detuvo la de 12 días para ahorrar tiempo, así que **no hay medición con 12**. El techo técnico de 12 se alcanza hacia el día 11–12.
- Suites no ejecutadas: `prueba_ui`, `prueba_aspecto`, `prueba_reglas`, `prueba_operadores`, `prueba_terreno_red`, `prueba_crecimiento_red`, `prueba_carga_crecimiento`, `prueba_campos_cultivo`, `prueba_casas`, `prueba_caminos`, `prueba_orden_dibujo`, las dos visuales A1–A3. Ninguna ejercita `_recurso` ni `alcanzables` salvo `prueba_terreno_red`/`prueba_crecimiento_red`, que además reescriben archivos de evidencia versionados; se omitieron para no alterarlos.
- Sin multijugador con más de un cliente en esta corrida (solo `prueba_red`).
- Sin commit. Las medidas se hicieron sobre copias del árbol con temporizadores; los scripts no están en el repo.

## 6. Qué queda por mejorar (no hecho; sin autorización)
Los ~40 ms por búsqueda cuando el candidato más cercano no es alcanzable. Opciones: recordar por habitante qué celdas son inalcanzables hasta que cambie `Mundo.version`, o recorrer el área una vez por (origen, versión) y reutilizar el resultado entre llamadas de la misma decisión. Ambas necesitan invalidación explícita y se deben probar con las mismas comprobaciones de equivalencia.
