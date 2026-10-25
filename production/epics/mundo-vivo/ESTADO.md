# Linde — estado verificado

> **Consolidado**: 2026-10-25 · **Rama**: `main` · **Último commit considerado**: `324f339` · **Modo**: solo (sin revisión independiente)
>
> **Nota de hashes (2026-10-25)**: un `git pull --rebase` reescribió los commits locales. Los hashes de este documento son los vigentes en `main`; los previos al rebase eran H0 `a5414fb`, M0 `67d52ca`, K1 `07813c2`, rendimiento `2ccb99a` y mochila `990d549`. Las cifras de pruebas siguen siendo las registradas por cada sesión.
>
> **Regla de este documento**: dice qué existe y qué se comprobó, **con fecha y alcance de cada comprobación**. Ninguna cifra de pruebas de aquí se ha vuelto a ejecutar en la consolidación del 25/10: son recuentos *registrados* por la sesión que los obtuvo. Si el código contradice este texto, prevalece el código verificado y hay que corregir este texto.

**Dónde está cada cosa**: orden de lectura y política en [CLAUDE.md](../../../CLAUDE.md#documentación-qué-leer-y-cómo-mantenerla) · decisiones en [DECISIONES.md](../../../Linde/cenital/docs/DECISIONES.md) (índice único) · visión original en [LINDE_Punto_de_Inicio](../../../Linde/documentos/LINDE_Punto_de_Inicio/00_LEEME.md) · historial completo de este documento hasta el 25/10 en [docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md](../../../docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md).

## 1. Qué es hoy el juego

RPG 2D cenital de mundo vivo en Godot 4.7.1 (`Linde/cenital`). Jugador con personaje propio en un valle de autor de 64×48 celdas más un exterior generado por regiones. **La autonomía de los habitantes es el modo principal** (decisión del usuario, 24/10): el juego se genera a partir de las decisiones del jugador y de los habitantes, no de una campaña escrita. Servidor autoritativo con réplica en clientes (ENet, IP directa).

El director de tarjetas y las misiones de plantilla del epic *mundo-vivo* (historias 001–005) siguen en el código pero quedan suspendidos mientras la autonomía está activa; la campaña del capítulo 1 se verifica con `--campana`. Su cierre «5 de 5» corresponde al director de tarjetas, no a la visión completa.

## 2. Sistemas implementados

«Registrado» = lo que la fuente dice haberse comprobado, con su fecha. «Límites» son los declarados por esa misma fuente.

| Sistema | Qué hace | Contrato / guía | Evidencia | Verificación registrada | Límites declarados |
|---|---|---|---|---|---|
| Base: mundo, inventario, combate, guardado, misiones | Mapa de autor, recolección, fabricación, construcción, cofres, jefes, guardado versionado (formato 3) | [DECISIONES](../../../Linde/cenital/docs/DECISIONES.md) | `tests/prueba.gd` | 23–24/10: suite general (213 → 326 PASS según fecha) | Números de combate sin balance; nunca jugado a mano |
| Red / servidor autoritativo | Servidor sin ventana o anfitrión; réplica; validación de pedidos; protocolo 5 (25/10) | [ADR-0001](../../../docs/architecture/adr-0001-multijugador-mundo-anfitrion.md), sección Red de DECISIONES | `tests/prueba_red.gd`, `resultados_red.txt` | 24/10: 3 clientes (11 PASS), p95 2,73 ms con 4 clientes, solo localhost | Sin Internet real ni latencia simulada; sin relay/NAT; sin cifrado |
| Director de tarjetas (epic mundo-vivo) | Tarjetas de datos, llegadas, misiones de plantilla | [GDD mundo-vivo](../../../design/gdd/mundo-vivo.md), [README del epic](README.md) | `production/qa/evidence/story-00X-*/` | 24/10 con scripts temporales **fuera del repo** | Sin revisión de diseño/código; paquete de datos es copia de prueba (`fixture: true`) |
| Autonomía y sociedad | Necesidades, producción, trueque, confianza, grupos, memoria | [AUTONOMIA](../../../Linde/cenital/docs/AUTONOMIA.md), [GDD sociedad](../../../design/gdd/sociedad-emergente.md) | `evidence/autonomia/`, `evidence/sociedad/` | 24/10: 33 + 48 comprobaciones sin fallos | Sin guerras ni facciones generadas; balance provisional |
| Desarrollo: materiales, equipo, pericia | Gramática forma/material/técnica/calidad, práctica, laminados, obras de habitantes | [DESARROLLO](../../../Linde/cenital/docs/DESARROLLO.md), [GDD](../../../design/gdd/desarrollo-generativo.md) | `evidence/desarrollo/` | 24/10: 55 sin fallos (`tests/prueba_desarrollo.gd`; reejecutada el 25/10 por la investigación: 55, 0 fallos) | No es generación ilimitada: formas y efectos están en código |
| Saberes y enseñanza (K1 del plan maestro; commit `4141ae9`) | Conocimiento por actor separado de la pericia (`valido`/`sabe`/`puede`/`conoce`/`candidatos`); siembra por oficio y experiencia; enseñanza autónoma entre habitantes y del jugador con habitantes por intención de servidor; panel «Saberes» en el taller; huella de reglas en el saludo de red (protocolo 7) | [PLAN_MAESTRO §10 K1](../../../docs/investigacion/innovacion-emergente/PLAN_MAESTRO.md), [PLAN_IMPLEMENTACION §19](../../../docs/investigacion/innovacion-emergente/PLAN_IMPLEMENTACION.md) | `tests/prueba_saberes.gd`, `tests/captura_saberes.gd`, `evidence/saberes/` | 25/10, copia estable del árbol con M0, UI y huella en el saludo: las 22 suites pasan sin fallos: `prueba_saberes` 87, `prueba_desarrollo` 57, `prueba_sociedad` 48, `prueba_autonomia` 33, `prueba_arraigo` 76, `prueba_casas_arraigo` 3, `prueba_reglas` 72, `prueba_aspecto` 225, `prueba_ui` 13, `prueba_proteccion` 51, `prueba_terreno` 49, `prueba_fauna` 31, `prueba_orden_dibujo` 6, `prueba_caminos` 7, `prueba_campos_cultivo` 8, `prueba_casas` 13, `prueba_crecimiento` 27, `prueba_carga_crecimiento` 1, `prueba` 327, `prueba_red` 11 OK (clientes reales, protocolo 7), `prueba_terreno_red` y `prueba_crecimiento_red` PASS. Tras el cambio de `_ampliar` de otra sesión se repitieron `prueba_saberes` 87 y `prueba_desarrollo` 57 (sin fallos) | Lección del jugador instantánea; réplica abierta (sin privacidad); P2 (motivo `reglas_distintas` en la UI) pendiente; el diario muestra el tipo «ensenanza» sin texto; las copias de prueba de `*_red` necesitan la ruta de evidencia del repositorio |
| Mundo que crece y protección | Carácter, hurto, propiedad, cofres con candado, colonos, economía de fibra | [PROTECCION_Y_ECONOMIA](../../../Linde/cenital/docs/PROTECCION_Y_ECONOMIA.md) | `evidence/proteccion/` | 24/10: 51 comprobaciones; simulación de 10 días con semilla 123 | Balance provisional; cliente de red viendo colonos/cofres no verificado |
| Exterior por regiones | Terreno generado v1/v2 por semilla, caché de 25 regiones, diferencias persistentes | [MUNDO_POR_REGIONES](../../../Linde/cenital/docs/MUNDO_POR_REGIONES.md), [GDD](../../../design/gdd/mundo-por-regiones.md) | `evidence/terreno/` | 24/10: 49 comprobaciones; 25/10: la suite desactiva expediciones y registró 4 fallos de caché previos | Rango ±65.536 celdas; carga síncrona; sin enemigos propios fuera del valle |
| Arte de biomas y fase 7 | Texturas por bioma; viajero y habitantes modulares | [ARTE_BIOMAS](../../../Linde/cenital/docs/ARTE_BIOMAS.md), [FASE_07](../../../Linde/cenital/docs/FASE_07.md) | `evidence/biomas/`, `evidence/fase7/` | 24/10: capturas inspeccionadas | Aceptación artística pendiente en todos los lotes |
| Fauna regional | 5 criaturas exteriores, aparición determinista | [FAUNA_Y_PELIGROS](../../../Linde/cenital/docs/FAUNA_Y_PELIGROS.md) | `evidence/fauna/` | 24/10: 31 comprobaciones | Balance provisional; sin simulación lejana |
| Minerales, recetas aprendidas, expediciones, caminos, cultivos, casas | Commit `720f6e9` | commit y `tests/prueba_caminos.gd`, `prueba_campos_cultivo.gd`, `prueba_casas.gd` | `evidence/inspeccion-2026-10-25/INFORME.md` | 25/10: 10 suites, 301 PASS, 0 fallos (inspección) | Expediciones/cultivos/casas sin verificar en multijugador |
| Solares persistentes y primeros puestos regionales | Commit `323d1a2`; compatibilidad de terreno v1/v2 | [CRECIMIENTO_Y_ASENTAMIENTOS](../../../Linde/cenital/docs/CRECIMIENTO_Y_ASENTAMIENTOS.md) | `evidence/crecimiento/` | 25/10 (ver el README de evidencia) | Puestos = población resumida, no ciudades autónomas; Internet sin certificar |
| Mochila de habitantes, pasivas por práctica, reparto de decisiones | Commit `324f339` | mensaje del commit | — | **Las suites de regresión no se repitieron tras el último ajuste** (según el propio commit) | Las casas siguen sin completarse en 4 días de simulación |
| Aspectos | Aspecto propio por habitante y jugador | [ASPECTOS](../../../Linde/cenital/docs/ASPECTOS.md) | — (sin carpeta de evidencia propia) | 24/10: `prueba_aspecto.gd` 225 PASS | — |
| Arraigo (`arraigo.gd`) | Commit `9d8602d` (trabajo de otra sesión, ya confirmado) | — | `tests/prueba_arraigo.gd`, `prueba_casas_arraigo.gd` | `prueba_arraigo` 76 y `prueba_casas_arraigo` 3 según el recuento de K1 (25/10); no repetido aquí | Sin documentar |
| Propiedades físicas de materiales (M0). **Aprobada 25/10; commit `e0dc0dd`** | Cada material tiene dureza, tenacidad y densidad; cada forma pondera dureza/tenacidad; la velocidad sale de la densidad. Recetas, costes, técnicas y los 9 laminados no cambian. Sube `EVALUADOR_VERSION` y `version` de reglas a 2 | [PLAN_MAESTRO](../../../docs/investigacion/innovacion-emergente/PLAN_MAESTRO.md) (§10 «Estado de M0») | `tests/prueba_reglas.gd`, `tests/dorados/artesania_v1.json` | 25/10: `prueba_reglas` 72 PASS, 0 fallos; en copias aisladas con y sin M0: `prueba_desarrollo` 57, `prueba_saberes` 73, `prueba` 327, `prueba_autonomia` 33 y `prueba_sociedad` 48, sin fallos | Valores físicos provisionales (no balance cerrado); el bronce domina al hierro en las siete formas (heredado) y hay 14 dominancias registradas en total; el redondeo a enteros recorta la diferenciación (torso de cobre, hierro y bronce valen 5/5 en calidad 0); la densidad aún debe demostrar relevancia práctica |
| Huella de reglas y evaluador versionado (H0, `huella.gd`) | Cada mundo guardado lleva el sello de las reglas con que se creó; `Guardado.cargar` rechaza sin escribir un mundo con reglas distintas (excepción solo con depuración + `--aceptar-reglas-distintas`); dorado de 693 claves de fabricación. Commit `70d7b5f` | [PLAN_MAESTRO](../../../docs/investigacion/innovacion-emergente/PLAN_MAESTRO.md) (§7, §10 «Estado de H0») | `tests/prueba_reglas.gd`, `tests/dorados/artesania_v1.json` | 25/10: `prueba_reglas` 60 PASS, 0 fallos; `prueba` 327 PASS, 0 fallos; `prueba_terreno` 49 y `prueba_crecimiento` 27 sin fallos; `prueba_desarrollo`: 1 fallo en el árbol compartido, idéntico con y sin H0, y 57 PASS sin fallos en copias aisladas con y sin H0 (el fallo dependía del trabajo concurrente en `desarrollo.gd`); `prueba_autonomia` 33, `prueba_sociedad` 48 y `prueba_red` 11 sin fallos, con y sin H0 | Los guardados anteriores se rechazan (sin huella); la interfaz aún muestra «No hay partida legible»; **pendientes de integración, obligatorias antes del playtest multijugador externo:** (P1) comparar la huella en el saludo de red y (P2) mostrar el motivo `reglas_distintas` en la interfaz (ver PLAN_MAESTRO §10, «Integraciones pendientes de H0»); la huella y el dorado no cubren fórmulas ni generadores escritos en código (alcance exacto en el mismo documento); incidencia abierta sin explicar: fallo intermitente de `prueba_desarrollo` |

Arte: los seis lotes de arte (E01–E06) están integrados como *candidatos*; la lista exacta de lo que falta está en [ARTE_PENDIENTE](../../../Linde/cenital/docs/ARTE_PENDIENTE.md). Los recursos de procedencia viven en `Linde/arte-entregado/` y `Linde/documentos/INSTRUCCIONES_ARTE_ENTREGABLES/` (ver «Qué no mover» en la política de CLAUDE.md).

## 3. Pendientes vigentes

Comprobados el 25/10 por las sesiones indicadas; ninguno reverificado hoy.

- **Casas autónomas**: en cuatro/cinco días de economía simulada todavía no se completan de forma consistente; las obras preparadas sí se completan y reanudan.
- **Planificación**: con 12 habitantes la caché está acotada pero había pausas de varios segundos; `324f339` reportó bajar el tick más lento de 4.382 ms a 354 ms en 4 días (semilla 123). Falta distribuir la planificación entre fotogramas.
- **Equilibrio** de comida y ladrillos; ampliar las rutinas de la población regional.
- **Internet real**: ninguna prueba con latencia real. Expediciones, cultivos y casas sin probar con clientes.
- **Compatibilidad**: una roca extraída puede reaparecer como estaño por el cambio de generador v1 (la sesión del 25/10 añadió compatibilidad v1/v2; no reverificado aquí).
- **Revisión**: el GDD de mundo-vivo no pasó por `/design-review` ni el código por `/code-review`. (El «sin confirmar» del GDD citado el 25/10 ya no aplica: el árbol está limpio.)
- **Arte**: aceptación artística de todos los lotes; disparadores de caída y dormir; ver ARTE_PENDIENTE.
- **Avisos de recursos al cerrar** persisten en todas las suites.

### Decisiones del usuario aún abiertas (del epic, 24/10)
1. **TD-001**: ¿impedir tapar la entrada del valle o corregir el criterio y el GDD?
2. Aprobar las tarjetas del Atlas (hoy `proposed`) y el canon de Ordal y Nerea (A02).
3. Variable inexistente en una tarjeta: el contrato de GPT dice «bloquea la evaluación»; el código descarta solo esa tarjeta.
4. Contenido propio de Ordal y Nerea.
5. Hosting del servidor siempre encendido y pantalla de conexión.

### Deuda técnica
Registrada en [docs/tech-debt-register.md](../../../docs/tech-debt-register.md) (TD-001 a TD-009: entrada tapable, tabla de aspecto en código, aviso de llegada pobre, instantánea sobre el MTU de ENet, `mundo_vivo` reenviado completo, etc.). Sin registrar: `CADENCIA_MIN` sin usar y constantes de ritmo en código; rastreador de misiones que desborda; ámbito jugador tratado como compartido.

## 3b. I1a — progreso verificado (autorizada 2026-10-25)

- **Evidencia visual pendiente (E0):** captura del mensaje «reglas distintas» en el menú, sin tomar.
- **E0 (P2), commit `6e9656a`:** `Juego.cargar` conserva el error en `ultimo_error`; `Juego.mensaje_carga` muestra «reglas distintas» (con los componentes) y lo distingue de un archivo ilegible y del rechazo de conexión («Reglas distintas a las del servidor», «Versión distinta del servidor»). Alojar y el servidor sin ventana no sustituyen en silencio un mundo rechazado. `prueba_reglas` 79/79 (13 nuevas «P2»); `prueba`, `prueba_ui`, `prueba_saberes` sin fallos. **Sin captura de pantalla del mensaje** (solo texto en el menú existente).
- **E1, línea base antes de `art2:` (2026-10-25, `tests/medir_i1a.gd`; línea base de **3 horas simuladas**, no de un día; mundo semilla 123):** guardado 9.689 B; réplica de bienvenida 14.100 B; instantánea 1.836 B; 684 claves `art1:` válidas, la más larga 40 caracteres; `A.leer` 9,7 µs, `info` 17,9 µs, `receta` 31,9 µs, `visible` 14,9 µs. `planos` del jugador devolvió 0 (sin saberes ni materiales en ese mundo), así que su tiempo no es representativo y se medirá en E6 con un jugador equipado.
- **E2 (`art2:` aislado, sin integrar en equipo/inventario/red; commit en la entrada de E2 del historial):** `reglas_v1.json` v3 con bloque `operadores` (refuerzo madera 0,10 / piedra 0,16 / fibra 0,12; grosor fino ×0,92 −/+0,03 ×0,75, grueso ×1,10 −0,03 ×1,5; tope 1,30×); `artesania.gd` `EVALUADOR_VERSION` 3 con `leer2/clave2/info2/receta2/visible2/enumerar2`. Clave `art2:forma:material:tecnica:calidad:refuerzo:grosor`; nivel predeterminado de refuerzo `sin` (la clave más larga con «ninguno» medía 49 > 48; con `sin` mide 47, así que se conserva `MAX_TEXTO`=48 y no se sube el protocolo); al menos un operador no predeterminado (sin operadores la pieza es `art1:`). Espacio: 1.692 variantes válidas. `art1:` intacto: el hash del dorado de 693 claves no cambió (`c4485701…`). Suite nueva `prueba_operadores` (44 comprobaciones) y sección `art2` del dorado.
  - **Presupuesto (medido):** razón continua máxima 1,2538 (tope 1,30); tras redondear ninguna estadística supera el tope aplicado al valor base redondeado.
  - **Dominancia:** 0 con valores continuos comparando insumo por insumo (incluida la pieza `art1:` equivalente); 0 por unidades totales (comparación auxiliar y aproximada: no equipara materiales distintos, ver limitación en la suite).
  - **Hallazgo del redondeo (sin resolver):** con estadísticas enteras 631 de 1.692 variantes (37 %) tienen ventaja nominal de potencia sin ningún dmg/def/hp entero superior a la pieza sin operadores (por forma: botas 52, casco 82, escudo 134, espada 101, guantes 89, pantalones 107, torso 66; `sin+grueso` 230, `fibra+normal` 128, `piedra+fino` 67…) y 1.646 pares «pieza art1 > variante» (misma o mejor estadística entera con menos insumos). En E6 esas variantes deben mostrar «sin efecto visible en combate» o no ofrecerse; decisión pendiente del usuario.

## 4. Cómo verificarlo

Desde la raíz del repo, con `herramientas/runtime/Godot.app/Contents/MacOS/Godot`:

- Jugar: `Linde/cenital/Iniciar-Cenital.command`. Prueba de autonomía aislada: `Iniciar-Prueba-Autonomia.command`. Campaña histórica: argumento `--campana`.
- Importar: `--headless --path Linde/cenital --import`
- Suites: `--headless --path Linde/cenital --script res://tests/<suite>.gd`. Suites vigentes en `Linde/cenital/tests/`: `prueba` (general), `prueba_ui`, `prueba_red`, `prueba_aspecto`, `prueba_autonomia`, `prueba_sociedad`, `prueba_desarrollo`, `prueba_proteccion`, `prueba_terreno`, `prueba_terreno_red`, `prueba_fauna`, `prueba_orden_dibujo`, `prueba_caminos`, `prueba_campos_cultivo`, `prueba_casas`, `prueba_crecimiento`, `prueba_crecimiento_red`. El resultado se lee de la salida (`PASS`/`FAIL` y comprobaciones fallidas); **no hay recuento canónico**: los números cambian con cada sesión y los registrados arriba son históricos.
- Si el editor falla al abrir el registro de logs, añadir `--log-file` a una ruta escribible (descubierto el 25/10).
- Servidor: `Godot --headless --path Linde/cenital -- --servidor --guardado=<ruta> --duracion=<s>`.
- Evidencia visual: capturas en `production/qa/evidence/<tema>/` con `tests/captura_*.gd`.

## 5. Epic *mundo-vivo* (histórico)

Plan y reglas: [README](README.md), [EPIC](EPIC.md), [GDD](../../../design/gdd/mundo-vivo.md).

| # | Historia | Estado | Notas |
|---|---|---|---|
| 001 | Paquete de datos, habitantes desde datos y Ordal | Complete | Dormir no salta el reloj |
| 002 | Variables del mundo y director | Complete | `CADENCIA_MIN` definida y sin uso |
| 003 | Llegadas de habitantes y avisos | Complete con AC-9 sin cumplir | La entrada se puede tapar (TD-001) |
| 004 | Misiones por plantilla y recompensas | Complete | Texto largo del rastreador desborda |
| 005 | Guardado, servidor y red | Complete | Instantánea sobre el MTU (TD-007) |

Las verificaciones originales (36, 14, 20, 11 casos, capturas) se hicieron con scripts temporales fuera del repo; no se pueden repetir hoy tal cual. Detalle en el [historial](../../../docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md).

## 6. Dependencias fuera del repo

- **Atlas de GPT**: `/Users/josephrojas/Documents/ChatGPT/Linde/docs/atlas-contrato.md` y `world/`. El paquete `Linde/cenital/datos/mundo/` es una copia modificada de sus 15 tarjetas más las nuestras; el original no se tocó.
- **Arte de enemigos** reutilizado de `Nuevo Juego/public/art/enemies-px` (indicación del usuario).

## 7. Mapa del historial archivado

El [archivo](../../../docs/archivo/ESTADO-mundo-vivo-hasta-2026-10-25.md) conserva sin cambios: §1–9 estado original del epic; §10 prueba de autonomía; §11 decisión «autonomía modo principal» y sociedad; §12 desarrollo; §13 mundo que crece; §14 protección y economía; §15 exterior por regiones; §16 arte de biomas; §17 fauna; superposición al caminar; inspección consolidada del 25/10.
