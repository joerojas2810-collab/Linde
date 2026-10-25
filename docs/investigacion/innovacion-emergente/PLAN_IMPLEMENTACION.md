# Plan de implementación: conocimiento, descubrimiento e invención en Linde

> **Plan activo de la iniciativa «Innovación emergente»** (único plan vigente de esta iniciativa; las demás piezas de la carpeta son referencia, no plan). **Estado de fases: A implementada con salvedades (en el árbol de trabajo, sin commit; ver §19); B, C y D pendientes.** Al implementar una fase: marcar aquí su estado, registrar el resultado verificado en [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md) y anotar decisiones en el [registro](../../../Linde/cenital/docs/DECISIONES.md). Al terminar la iniciativa: archivar este plan en `docs/archivo/`.
>
> **Vigencia**: las referencias `archivo.gd:línea` de §2 son de `HEAD 324f339` con cambios locales sin confirmar de otras sesiones; verificar antes de editar.

**Estado:** plan aprobado; los seis puntos de §15 están verificados (§16) y la incrementalidad hacia `art2:` está revisada (§17). **Nivel A implementado el 2026-10-25 (§19).** Los niveles B, C y D no se han tocado.
**Fecha:** 2026-10-25. **Base:** [README](README.md), [COMPATIBILIDAD_LINDE](COMPATIBILIDAD_LINDE.md), [BASES_TECNICAS](BASES_TECNICAS.md), [DECISIONES](DECISIONES.md) (D05, D06, D10) y relectura del código actual.

Etiquetas: **[C]** confirmado en código, **[I]** inferido, **[V]** por verificar, **[P]** propuesta.

## 1. Decisiones ya tomadas

| # | Decisión | Efecto en el plan |
|---|---|---|
| 1 | Empezar con 11 saberes, sin que ese número limite el sistema. | El modelo de ids admite niveles futuros (§3). |
| 2 | Descubrimiento (posibilidades ya definidas) e invención (variantes generadas por parámetros) son capacidades distintas. | Niveles B y C separados, con criterios propios. |
| 3 | Siembra: quien ya usa una técnica la conserva, sin inventor retroactivo. | Migración inicial sin autoría inventada. |
| 4 | Réplica abierta temporal, sin secretos de fabricación. | La privacidad del conocimiento es limitación documentada (§9). |
| 5 | No se modifican ni redefinen las técnicas existentes; `reglas_v1.json` queda congelado. | Todo lo nuevo va en archivos complementarios y en el formato `art2:` (§4). |
| 6 | Los 24 materiales son catálogo objetivo, no requisito. | Primero se aprovechan materiales, aleaciones y laminados existentes (§8). |
| 7 | Experimentación determinista inicial, con consumo real, y movida por motivaciones y capacidades. | §6. |
| 8 | El director narrativo consume acontecimientos; no decide descubrimientos. | §10. |
| 9 | No se editan `sociedad.gd`, `autonomia.gd` ni `habitantes.gd` mientras haya cambios concurrentes. | §11. |

## 2. Qué existe hoy (evidencia)

- **[C]** `desarrollo.conoce` ([desarrollo.gd:85](../../../Linde/cenital/scripts/desarrollo.gd)) mezcla material visto, rango, calidad y superficie de taller. `planos` ([:113](../../../Linde/cenital/scripts/desarrollo.gd)) enumera todo lo que pasa esa prueba. No existe «saber» separado de «poder».
- **[C]** `decidir` ([:180](../../../Linde/cenital/scripts/desarrollo.gd)) recorre `planos()` en orden alfabético y fabrica el primer plano cuyo coste sobra. No hay motivo, intento, fracaso ni novedad. Lo que registra como «descubrimiento» es una fabricación.
- **[C]** `_creacion` ([:124](../../../Linde/cenital/scripts/desarrollo.gd)) guarda 64 entradas y solo se llama desde `fabricar` del jugador y `decidir` de NPC.
- **[C]** Hay dos sistemas de conocimiento sin relación: `autonomia.descubrir_recetas` (recetas estáticas de `C.RECETAS`) y `desarrollo` (gramática `art1:`/`mat1:`). Este plan toca solo el segundo.
- **[C]** La gramática actual tiene 2 técnicas no triviales (`ligera`, `reforzada`) y 9 laminados (`reglas_v1.json`). Una clave `art1:` válida es `art1:forma:material:tecnica:calidad`.
- **[C]** `desarrollo.decidir` ya se invoca desde la ocupación `"desarrollo"` de `sociedad.gd` y usa utilidades de sociedad/autonomía (`_ir`, `excedente`, `suceso`, `_recordar`, `dar`). Es el punto de entrada que permite trabajar sin editar esos archivos (§11).
- **[C]** `sociedad._azar` usa `j._rng("caracter", nid:clave:minuto)`: azar determinista por clave, reutilizable para fracasos sin tiradas repetibles al cargar.
- **[C]** Intenciones del servidor: lista cerrada en `red_servidor.ejecutar` ([:189](../../../Linde/cenital/scripts/red_servidor.gd)); ejemplo del patrón: `comprar_artefacto`. La réplica recibe `mundo_vivo` entero (`estado_para`, [:430](../../../Linde/cenital/scripts/red_servidor.gd)) y `_difundir` ([:359](../../../Linde/cenital/scripts/red_servidor.gd)) envía la misma sección a todos. La UI cliente calcula `planos()` sobre esa réplica ([escena.gd:456](../../../Linde/cenital/scripts/escena.gd)).
- **[C]** Persistencia: `desarrollo` vive en `mundo_vivo.autonomia.desarrollo` con `version:1`; `guardado.FORMATO` es 3. Un subesquema nuevo no exige subir el formato.
- **[C]** Director: `mundo_vivo.gd` tiene tabla `_derivadas` y tarjetas JSON en `datos/mundo/entities/`; se puede reaccionar a nuevas variables con datos.
- **[C]** Estado concurrente: `git status` muestra cambios sin confirmar de otra sesión en `sociedad.gd`, `autonomia.gd`, `habitantes.gd`, **`escena.gd` y `mundo_vivo.gd`** (más datos de eventos y `arraigo.gd`). `escena.gd` y `mundo_vivo.gd` no figuran en la restricción, pero se tratan igual (§11).

## 3. Modelo de conocimiento extensible

### 3.1 Niveles de saber

Un **saber** es una cadena con prefijo de nivel. Todo lo demás (progreso, autoría, enseñanza) se guarda por id de saber, así que añadir niveles es añadir ids, no cambiar el esquema.

| Nivel | Id | Significado | Estado en el MVP |
|---|---|---|---|
| Técnica general | `tec:<tecnica>` | Conoce el procedimiento en abstracto. | **Activo** |
| Proceso de material | `lam:<a>_<b>` | Sabe elaborar un laminado/aleación. | **Activo** |
| Dominio de aplicación | `dom:<tecnica>:<material>` o `dom:<tecnica>:<forma>` | Sabe aplicar la técnica a ese material o forma. | Reservado |
| Descubrimiento específico | `dis:<forma>:<material>:<tecnica>` | Conoce un diseño concreto. | Reservado |
| Operador de invención | `ope:<operador>` o `ope:<operador>:<nivel>` | Sabe aplicar un operador (tratamiento, proporción…) hasta cierto nivel. Una variante `art2:` es una **combinación de operadores que el actor sabe**, no requiere un id propio por variante (§5, §17). | Reservado, nivel C |
| Invención registrada | `inv:<id canónico>` | Procedencia de una variante notable (primera de su tipo). **No es requisito para fabricar**; solo historia y enseñanza de esa variante concreta. | Reservado, nivel C |

MVP: 2 técnicas (`ligera`, `reforzada`) + 9 laminados = **11 saberes**. La técnica `simple` es conocimiento común y no se registra.

### 3.2 Regla de exigencia por catálogo (no por código)

`datos/desarrollo/saberes_v1.json` (archivo nuevo, complementario) declara por cada técnica y proceso:

- `exige`: nivel de saber necesario para fabricar (`tec`, `dom_material`, `dom_forma` o `dis`). En el MVP todas valen `tec`.
- `prerrequisitos`: saberes o rangos necesarios para adquirirlo.
- `experimento`: coste, unidades de progreso y motivos admisibles (§6).
- `ensenable`: bool.

`sabe(actor, clave)` calcula el id exigido para esa pieza según `exige` y comprueba que el actor lo posee. Cambiar `exige` de `tec` a `dom_material` en el futuro **no cambia el almacenamiento ni las firmas**, solo el id exigido.

**Migración al refinar la exigencia [P]:** al pasar una técnica a `dom_material`, la política de siembra concede `dom:<tec>:<material>` a quien ya tenga `tec:<tec>` y práctica registrada en ese material (misma regla que §1.3; sin autoría retroactiva). Es una función de migración de subesquema, no un cambio de formato.

### 3.3 Cuatro consultas separadas

| Consulta | Qué responde | Dependencias |
|---|---|---|
| `valido(clave)` | ¿Existe dentro de las reglas? | `artesania.leer` (existe) |
| `sabe(actor, clave)` | ¿Conoce el procedimiento? Independiente del entorno. | saberes del actor |
| `puede(actor, clave)` | ¿Puede hacerlo ahora? | `sabe` + rango + superficie; insumos y estación se validan al actuar |
| `candidatos(actor)` | ¿Qué podría intentar descubrir con lo que sabe y tiene? | `saberes_v1.json`, prerrequisitos, materiales vistos |

`conoce` se conserva como envoltura (`sabe && puede`) para no cambiar las firmas de `fabricar`, `planos` y la UI.

### 3.4 Estado persistente [P]

Subesquema `desarrollo.version = 2`, dentro de `mundo_vivo.autonomia.desarrollo`:

- Por actor (`estado(actor)`): `saber: { id: {fuente, min} }`, `investigacion: {}` (máximo una activa), `leccion: {}`. `practica` y `materiales` no cambian.
- Mundial: `historia: { id: {primero:{actor,min}, aprendices:[…con tope]} }`, `intentos` por actor+saber.
- Los ids de actor son los existentes (`npc:` y `pj:`).
- `historia` está acotada mientras el número de saberes lo esté. Para las variantes (espacio grande) ver §5.4 e `inv:`.

## 4. Compatibilidad de reglas

- `reglas_v1.json` **no se edita**. Las claves `art1:` siguen resolviéndose solo con v1.
- Todo catálogo nuevo vive en archivos complementarios: `saberes_v1.json` (conocimiento) y, a partir del nivel C, `reglas_v2.json` (técnicas, operadores y parámetros nuevos), cargados de forma aditiva. Los ids nuevos no pueden colisionar con los de v1 (validación al cargar).
- Las piezas nuevas con técnicas o parámetros fuera de v1 usan el formato **`art2:`** (§5.3). `art1:` queda completamente congelado.
- `mat1:` tampoco se redefine; las proporciones nuevas usarán `mat2:` si llegan (§8).
- Cualquier cambio en `artesania.gd` para reconocer `art2:` es un cambio de código (nivel C), no de datos.

## 5. Descubrimiento frente a invención

| | **Descubrimiento** | **Invención combinatoria** |
|---|---|---|
| Qué es | Adquirir una posibilidad ya definida en datos (`saberes_v1.json`). | Generar una variante nueva mediante parámetros permitidos, sin que esté escrita en JSON. |
| Espacio | Finito y conocido (11 saberes al inicio). | Finito pero grande, derivado de operadores × niveles. |
| Se agota | Sí. | Mucho más lentamente. |
| Código nuevo | Mínimo. | Formato de clave, evaluador, validador de presupuesto, política de autoría. |
| Nivel del plan | B (MVP ampliado). | C (posterior, objetivo explícito). |

**No se llama «invención emergente» al desbloqueo de las 11 posibilidades.** Eso es descubrimiento. La invención exige el nivel C.

### 5.1 Qué significa «sin que cada variante esté en JSON» [P]

El JSON define **operadores** y **límites**, no variantes:

- Un operador es un parámetro discreto con efectos declarados y coste. Ejemplos conceptuales: proporción de refuerzo (3 niveles), grado de templado (2 niveles), grosor (2 niveles).
- Una variante es una combinación de niveles. Sus estadísticas **se calculan con una fórmula** a partir de forma, material, técnica, calidad y niveles, no se leen de una tabla.
- Cada operador declara una ventaja y una desventaja con signo opuesto (por ejemplo, más potencia a cambio de velocidad y de coste de insumos o de combustible), y un coste de superficie, tiempo o insumo.
- Un **presupuesto** (suma ponderada máxima de beneficios) acota el resultado. El validador comprueba el presupuesto sobre todo el espacio de parámetros con una prueba automática, no a mano.

### 5.2 Dificultades

1. **Balance:** no se verifica sin jugar. Mitigación: presupuesto formal en tests y valores de partida conservadores; ajuste jugando.
2. **Identidad y clave:** `art1:` no puede llevar parámetros. Hace falta `art2:` y que `Eq.existe/info`, `visible`, inventario y réplica la reconozcan. Es un cambio transversal en artesanía, equipo y UI.
3. **Autoría sin explosión de estado:** con espacio grande, `historia` por variante no es acotada (§5.4).
4. **Búsqueda del NPC:** explorar el espacio no puede ser aleatoria ciega ni exhaustiva. Se propone búsqueda local desde un diseño conocido, un paso de parámetro por intento, guiada por el motivo (§6).
5. **Presentación:** nombre legible de la variante y descripción de sus trade-offs en la UI.
6. **Red:** claves más largas; el servidor limita texto a 48 caracteres [C], hay que garantizar que la clave canónica quepa o ampliar el límite de forma controlada.
7. **Determinismo:** el orden de evaluación de parámetros y los desempates deben ser estables.

### 5.3 Dependencias del nivel C

Niveles A y B completos; formato `art2:` y su soporte en equipo/inventario/visible; `reglas_v2.json` con operadores y presupuesto; validador de presupuesto con prueba; política de autoría acotada; UI mínima para ver la variante.

### 5.4 Autoría de variantes [P]

- Se registra autoría completa solo de la **primera variante de cada (forma, material, operador)** y de las que superen un umbral de novedad definido por el catálogo.
- El resto se guarda como contador agregado, sin lista individual.
- Tope duro de entradas con política de expulsión explícita (la más antigua sin aprendices externos).

## 6. Experimentación movida por motivos y capacidades

La experimentación no se ejecuta porque exista un saber pendiente. Un NPC solo la intenta cuando concurren **motivo** y **capacidad**, y después de cubrir necesidades.

**Capacidad (todas obligatorias):** prerrequisitos de saber/rango del candidato, insumos en excedente, estación accesible y sin desgaste máximo, límite de intentos y proyecto no activo.

**Motivo (al menos uno, con peso mínimo):**
- Necesidad del grupo: carencia de una forma o producto para su rol (`objetivos`, forma no cubierta en el grupo).
- Oportunidad de material: acaba de obtener o ver un material cuyo proceso aún no domina.
- Mejora propia: su equipo actual está por debajo de lo que el candidato permitiría.
- Encargo o demanda registrada.
- Afinidad de oficio: `oficios_afines` en `saberes_v1.json` (por ejemplo, el artesano frente a técnicas de taller). No existe rasgo de curiosidad ni `prioridad` en los perfiles (§16.1, §16.2).

**Reglas:**
- Hambre, descanso, acuerdos y mantenimiento mantienen prioridad (ya ocurre en `sociedad.decidir`).
- Enfriamiento por actor y límite de intentos por saber.
- El candidato se elige por puntuación (motivo, coste, novedad personal) con desempate estable y cursor rotativo; nunca por orden alfabético.
- **MVP determinista:** cada trabajo confirmado suma una unidad entera de progreso; al alcanzar el umbral se obtiene el saber. Consume insumos, tiempo y desgaste reales.
- **Ampliación:** fracaso probabilístico con `j._rng` por (actor, saber, nº de intento); el contador se persiste y el resultado no se vuelve a tirar al cargar.
- Un rechazo antes de gastar no consume ni entrena.

## 7. Plan por niveles de capacidad

Escala de complejidad: S (menos de una sesión), M (1–2), L (3–5), XL (más de 5). Estimaciones gruesas.

### Nivel A — MVP técnico de conocimiento y enseñanza

**Objetivo.** Los actores tienen saberes propios persistentes, separados de práctica y entorno, y pueden transmitirlos.

**Contenido.**
1. Cuatro consultas (§3.3) y `saberes_v1.json`.
2. Almacén de saberes por actor, siembra inicial, `historia` con primer descubridor y aprendices.
3. Enseñanza directa NPC↔NPC (maestro con saber, alumno elegible, proximidad, confianza mínima, lección con progreso persistido) y jugador↔NPC por intención validada en servidor.
4. Memoria y sucesos en la enseñanza; mejora de vínculo.
5. Réplica abierta, sin secretos.

**Archivos.** `desarrollo.gd`, `datos/desarrollo/saberes_v1.json`, `juego.gd`, `red_servidor.gd` (nueva intención), `escena.gd` (solo adaptación de `planos`, coordinada). Ver §11 para lo que se evita editar.

**Dependencias.** Ninguna.

**Riesgos.** Romper `planos` en la réplica; coste de `suelo()` por llamada; aprendizaje duplicado tras reconexión; el estado cultural de todos viaja a todos los clientes (§9).

**Pruebas.** Ampliar `tests/prueba_desarrollo.gd` y la prueba de red: `sabe` sin taller, `puede` sin saber (falla), enseñanza a distancia, sin saber o sin confianza (rechazada), reconexión sin duplicado, adulteración de cliente (autor o saber ajeno) rechazada, guardar/cargar sin duplicar.

**Criterios de aceptación (A).**
- A1. Las 55 comprobaciones de `prueba_desarrollo.gd` siguen en verde, **salvo** las que hoy dependen del desbloqueo automático por rango (técnica `ligera` en líneas 62–66, `reforzada` en 68 y laminados en 85–102). Esas se reescriben para conceder el saber de forma explícita (`aprender` con fuente `prueba`) y se listan en el informe del nivel. Es un cambio de comportamiento **intencional**, no una regresión (§16.7).
- A2. Un actor con `sabe=true` y sin taller tiene `puede=false`; sin `sabe` nunca `puede`.
- A3. Un NPC aprende un saber por enseñanza y el resto de la población no.
- A4. El alumno no hereda práctica del maestro ni recibe producto; el maestro conserva el saber.
- A5. `historia` conserva el primer descubridor tras superar 64 creaciones y tras recortar los recuerdos.
- A6. Guardar, cargar y volver a simular no duplica aprendizaje, pieza ni evento.
- A7. Una intención de cliente con autor o saber manipulado se rechaza y cuenta en `rechazos`.
- A8. La siembra no atribuye inventor a nadie.

**Capacidad alcanzada si se cumple A:** el juego registra y transmite conocimiento de forma persistente y autoritativa. **No puede afirmarse todavía:** que los NPC descubran nada.

**Complejidad:** L.
**Fuera de alcance:** descubrimiento autónomo, libros, olvido, secretos, pago por enseñar, coautoría.

### Nivel B — Descubrimiento autónomo de posibilidades predefinidas

**Objetivo.** Un NPC descubre por sí mismo un saber definido, por motivo y capacidad propios, y queda constancia.

**Contenido.** Investigación activa (una por actor), candidatos y puntuación (§6), progreso entero, consumo real, registro en `historia` y memoria, límite de intentos. Después: fracaso probabilístico y participación del jugador (experimentar con candidato y coste visibles).

**Dependencias.** Nivel A.

**Riesgos.** Sesgo de reparto por el límite de decisiones por minuto; competencia por la misma estación; agotamiento rápido del espacio de 11 saberes (§12); balance de coste.

**Pruebas.** Reproducir dos veces la misma secuencia y comparar estado canónico; guardar/cargar a mitad de investigación sin repetir gasto ni recompensa; hambre y descanso desplazan el experimento; dos NPC con materiales y necesidades distintos eligen distinto; un saber sin motivo no se investiga aunque sea posible; ciclo de experimentos sin creación de recursos; medir reparto de intentos por NPC.

**Criterios de aceptación (B).**
- B1. Con semilla fija, un NPC descubre `tec:ligera` y otro no, y la diferencia se explica por motivo y capacidad registrados.
- B2. El gasto de insumos, tiempo y desgaste coincide exactamente con el coste declarado.
- B3. Sin motivo suficiente, un NPC con todos los prerrequisitos **no** experimenta.
- B4. Guardar/cargar a mitad del proceso no repite gasto ni completa dos veces.
- B5. Ningún bucle de experimentos genera recursos netos.
- B6. El descubrimiento queda en `historia` con actor y minuto, y se produce un recuerdo y un suceso.
- B7. Con hambre o sueño pendientes, la investigación no se ejecuta.

**Capacidad alcanzada si se cumple B:** descubrimiento autónomo de posibilidades predefinidas. **No puede afirmarse:** invención.

**Complejidad:** M (determinista); L si se añade fracaso probabilístico y UI de jugador.
**Fuera de alcance:** variantes no escritas en datos, mecánicas nuevas, investigación cooperativa.

### Nivel C — Invención combinatoria de variantes nuevas

**Objetivo.** Personajes generan variantes funcionales a partir de operadores y parámetros permitidos, sin que cada variante esté escrita en JSON.

**Contenido.** Todo lo de §5: `reglas_v2.json` con operadores y presupuesto, formato `art2:`, soporte en `artesania.gd`/equipo/inventario/visible, búsqueda local del NPC, autoría acotada, UI de la variante.

**Dependencias.** Niveles A y B; `saberes_v1.json` con `exige` flexible para `dom`/`var`; decisión sobre el límite de longitud de clave en red.

**Riesgos.** Los de §5.2; cambio transversal en artesanía y equipo; desequilibrio de poder; crecimiento del estado y de la réplica.

**Pruebas.** Test automático del presupuesto sobre **todo** el espacio de parámetros; las claves `art1:` existentes decodifican exactamente igual; clave `art2:` canónica y rechazo de parámetros fuera de rango; dos ejecuciones con la misma semilla producen la misma variante; autoría acotada no crece sin límite; medición de bytes de réplica.

**Criterios de aceptación (C).**
- C1. Existe al menos una variante utilizable que **no figura individualmente** en ningún JSON.
- C2. Cada operador tiene ventaja y desventaja verificables, y ninguna combinación supera el presupuesto.
- C3. Piezas `art1:` guardadas antes siguen idénticas en propiedades.
- C4. Un NPC produce una variante por búsqueda motivada y se registra su autoría respetando el tope.
- C5. Un cliente no puede fijar los parámetros ni el éxito; el servidor los valida.
- C6. El tamaño de réplica y guardado se mide antes y después, y queda registrado.

**Capacidad alcanzada si se cumple C:** invención combinatoria acotada. **No puede afirmarse:** mecánicas nuevas ni materiales nuevos.

**Complejidad:** XL.
**Fuera de alcance:** efectos no previstos por operadores, scripts del cliente, mecánicas nuevas (electricidad, etc.), generación con IA.

### Nivel D — Expansión de materiales y consecuencias sociales

#### D1. Materiales (ver §8) · Complejidad M por bloque
#### D2. Consecuencias sociales y narrativas

| Capacidad | Base requerida | Cómo | Complejidad |
|---|---|---|---|
| Autoría e historia visibles | A | Presentar `historia` en UI | S |
| Variables para el director | A, B | Entradas en `_derivadas` + tarjetas de datos (§10) | S |
| Especializaciones emergentes | A, B | Derivadas de práctica y saberes con histéresis; no sustituyen el perfil de abastecimiento | M |
| Colaboración entre NPC | B | Coautoría solo con participantes registrados | M |
| Tradiciones regionales | A, B | Consulta de saberes por grupo (`grupo_de`) | M |
| Difusión entre asentamientos | A | Los residentes de puestos no son actores (§16.3). Se difunde por personas que se mueven: colonos con saberes iniciales por oficio, NPC que parten y regresan, jugadores | M |
| Comercio de conocimiento | A, privacidad | Reutiliza `ofrecer`/`aceptar_oferta` y `sociedad.valor` | L |

**Criterios de aceptación (D).**
- D1. Cada material admitido justifica una posibilidad jugable nueva (§8) y pasa el validador de referencias.
- D2. Ningún material nuevo modifica propiedades de piezas guardadas.
- D3. Una especialización mostrada refleja práctica real y no cambia por minutos.
- D4. Una tradición regional se deriva de saberes de los habitantes del grupo, sin bonificación asignada a mano.
- D5. El director reacciona a un descubrimiento mediante una tarjeta de datos y no decide el descubrimiento.
- D6. Comercio de conocimiento: no se activa mientras no exista privacidad (§9).

**Capacidad alcanzada si se cumple D:** el conocimiento tiene consecuencias económicas y narrativas.
**Fuera de alcance de D:** robo de diseños, rivalidades, libros por ejemplar, olvido gradual.

## 8. Materiales

### 8.1 Principio

Los 24 materiales son el **catálogo objetivo**. Cada incorporación debe justificarse por una **posibilidad jugable nueva** (una forma, proceso o ruta que hoy no se puede hacer), no por completar la lista.

### 8.2 Estado de los 24 frente al repositorio

| Familia (objetivo) | Ya existe | Falta | Posibilidad jugable que justificaría añadirlo |
|---|---|---|---|
| Metales (5) | hierro, cobre, estaño | plata, oro | Objetos de valor y comercio; solo si hay economía que los consuma |
| Piedras (4) | piedra, arcilla | granito, caliza | Construcción resistente; cal para procesos |
| Maderas (3) | madera (única) | dura, flexible | Elasticidad para armas a distancia (hoy no existen) |
| Fibras (3) | fibra (única) | lino, cáñamo, algodón | Distinguir cuerdas y tejidos; requiere cultivo/proceso |
| Animales (3) | — (no hallé drops) | cuero, hueso, tendón | Nuevas formas de protección y compuestos |
| Reactivos y combustibles (4) | — (el combustible es madera) | carbón vegetal/mineral, azufre, sal | Procesos de horno con temperatura; conservación |
| Especiales (2) | gema (distinta) | cuarzo, resina | Adhesivos y composición |

**[C]** Existen 7 equivalentes directos; **[I]** 17 faltan. El bronce es una aleación y ya existe.

### 8.3 Orden propuesto

1. **D1a. Aprovechar lo existente.** Tratamientos como saberes (`var:`/`tec:`) sobre hierro, cobre, bronce y los 9 laminados; el atlas `desarrollo.materiales()` ya lista fuentes y usos. Sin materias nuevas. M.
2. **D1b. Primer bloque nuevo** elegido por posibilidad jugable (candidatos: animales o combustibles). Requiere datos de reglas, catálogos, formas y generación/biomas. Cambiar la generación altera mundos existentes y exige versión de generación (existe el mecanismo en `guardado.migrar`). L por bloque.
3. **D1c. Proporciones y compuestos** (`mat2:`, formas nuevas). XL, posponer.

### 8.4 Propiedades

**[C]** Hoy solo `potencia` y `vel` tienen consumidor. Las demás propiedades de la propuesta (elasticidad, resistencia térmica, etc.) se añaden **cuando exista un consumidor** (un arco, un proceso de horno), no antes.

### 8.5 Herramientas

**[C]** Las herramientas (`hacha_cobre`, `pico_cobre`) son ítems estáticos, no parte de la gramática. Incluirlas es un cambio de alcance (nuevas formas con etiqueta de herramienta). **[P]** Posponer a D1c.

## 9. Limitaciones técnicas pendientes

- **Privacidad del conocimiento:** **no existe.** La réplica envía `mundo_vivo` completo a todos los clientes. Proyectar por cliente exige separar el estado privado de `mundo_vivo`, mover el conocimiento propio a un canal privado (`privado(id)` ya existe) y reescribir `_difundir`, que hoy envía la misma sección a todos. Hasta entonces: **no se introducen secretos de fabricación**, no hay robo de diseños ni comercio de conocimiento (D6).
- **Presupuesto de rendimiento:** no está definido. Se mide antes y después de cada nivel (p95 del tick, bytes/s, tamaño de guardado y carga).
- **Límite de longitud de texto de red** (48 caracteres) condiciona las claves de nivel C.
- **Conocimiento de NPC ausentes (arraigo):** la disponibilidad debe consultar presencia sin borrar el saber; se revisará cuando el trabajo concurrente de arraigo esté consolidado.

## 10. Director narrativo

- El director es **consumidor**. Los descubrimientos los deciden `desarrollo` y las reglas de motivo/capacidad.
- Integración solo con datos: variables derivadas nuevas en `_derivadas` (por ejemplo total de saberes descubiertos, minuto del último descubrimiento, saberes conocidos por grupo) y tarjetas de evento en `datos/mundo/entities/`. Las tarjetas nuevas siguen su estado `proposed` hasta aprobarse.
- Editar `mundo_vivo.gd` para registrar esas derivadas es un cambio de código y entra en el protocolo de coordinación (§11).

## 11. Coordinación con cambios concurrentes

- **No se editan** `sociedad.gd`, `autonomia.gd`, `habitantes.gd`. Tampoco `escena.gd` ni `mundo_vivo.gd` (también con cambios sin confirmar) hasta coordinar.
- **El plan está diseñado para avanzar sin tocarlos:**
  - Experimentación y enseñanza se implementan dentro de `desarrollo.decidir`, ya invocada por la ocupación `"desarrollo"`. Llama a utilidades de esos archivos (`_ir`, `excedente`, `suceso`, `_recordar`, `dar`) sin modificarlas.
  - Solo hay que pedir coordinación si resulta necesario añadir una ocupación propia en `sociedad.ORDEN` o cambiar prioridades.
- **Contrato de compatibilidad (§16.6):** no cambian `registrar`, `rango`, `observar`, `restaurar`, `activa`, `cfg` (mutable), `estado(actor).practica/materiales`, `planos`, `conoce`, `refinar`, `fabricar`, `comprar` ni `decidir(nid) -> bool`. Las pruebas de sociedad y arraigo dependen de ello.
- **Punto de control antes de cada nivel:** `git status`, comparar hashes de los archivos de COMPATIBILIDAD (el de `sociedad.gd` ya difiere del registrado) y confirmar con la persona responsable qué cambios se han consolidado.
- **Conflictos previsibles:** adaptación de `planos` en `escena.gd` (nivel A), variables derivadas en `mundo_vivo.gd` (D2), cualquier cambio en la prioridad de ocupaciones.

## 12. Primera prueba vertical (nivel A)

Script al estilo de `tests/prueba_desarrollo.gd`: `J.nueva(123, …)`, `autonomia.activar()`, simulación por minutos.

1. **Preparación.** Dos NPC de perfil distinto (ids reales a confirmar en `datos/autonomia/reglas.json`): A sabe `tec:ligera`; B tiene rango 1, fibra y madera y mismo taller accesible, pero no el saber. Un tercer NPC C sin el saber.
2. **Antes.** `sabe(B)=false`, `puede(B)=false`; C igual.
3. **Enseñanza.** Acercar a A y B con confianza suficiente y simular hasta completar la lección. Esperado: `sabe(B)=true`; la práctica de B no cambia; A conserva el saber; C sigue sin él; `historia["tec:ligera"].aprendices` contiene a B; hay un recuerdo de aprendizaje y un suceso de enseñanza.
4. **Uso.** Simular más tiempo: B fabrica una pieza `art1:…:ligera:*` con consumo de insumos y desgaste de mesa.
5. **Persistencia.** `Guardado.empaquetar` → `desempaquetar`, recargar y comparar el estado cultural; volver a simular sin duplicar aprendizaje ni pieza.
6. **Repetibilidad.** Repetir con la misma semilla y comparar estado canónico.

Una segunda prueba cubre el nivel B: A descubre `tec:ligera` sin saberla, por motivo y capacidad, con gasto exacto.

## 13. Dependencias reales y orden

```
Nivel A (consultas + almacén + enseñanza)
  ├─► Nivel B (descubrimiento autónomo) ──► Nivel C (invención combinatoria)
  ├─► D2 sencillo: historia visible, variables del director
  └─► D1a (aprovechar materiales existentes) ──► D1b/D1c (materiales nuevos)
Privacidad por cliente ──► comercio de conocimiento, secretos, robo
```

Orden de implementación: A → B (determinista) → D2 sencillo en paralelo → B ampliado → D1a → C → D1b → resto de D2 y privacidad.

## 14. Evaluación crítica

- **Sencillo con el código actual:** consultas separadas, almacén y autoría acotada (hasta unas decenas de ids), enseñanza NPC↔NPC, variables del director, persistencia sin migración global.
- **Costoso:** invención combinatoria (formato, evaluador, presupuesto, autoría), privacidad por cliente, balance de motivos de experimentación, UI del jugador, materiales nuevos con generación de terreno, herramientas dentro de la gramática.
- **Posponer:** libros por ejemplar, olvido, robo, ocho propiedades físicas, proporciones continuas, comercio de conocimiento, los 17 materiales de golpe.
- **Riesgo de fondo:** con 11 saberes el espacio de descubrimiento se agota en pocos días de juego. La percepción de emergencia sostenida depende del nivel C y de D1, no de la maquinaria de conocimiento. Por eso §3 deja la exigencia por catálogo (`exige`) y §5 es un objetivo explícito, no un adorno.

## 15. Puntos pendientes (resueltos en §16)

Los seis puntos que figuraban aquí (ids de NPC, rasgo de curiosidad, `asentamientos.gd`, cálculo de `planos` en la réplica, límites de longitud y estado de los cambios concurrentes) se verificaron el 2026-10-25. Resultados y decisiones en §16.

## 16. Resultados de la verificación (2026-10-25)

Solo lectura y `git`/`grep`/cálculo local. No se ejecutó el juego ni las pruebas, y no se modificó código.

### 16.1 Ids reales de NPC y perfiles
- **Verifiqué:** `datos/autonomia/reglas.json` (`perfiles`, `sociedad.inmigracion.oficios`) y los tests existentes.
- **Evidencia [C]:** hay tres perfiles: `maren` (oficio artesano, grupo talleres), `ordal` (cantero, canteros) y `nerea` (recolector, talleres). `formas_por_grupo`: talleres → torso, casco; canteros → espada, escudo. `prueba_desarrollo.gd:104` ya usa `maren`. Los colonos nuevos llegan con ids dinámicos y un `molde` de estos perfiles. Ningún perfil define `prioridad`, así que todos siguen el `ORDEN` por defecto, donde `desarrollo` es la séptima ocupación.
- **Afecta al plan:** sí, en dos puntos. La prueba vertical (§12) queda fijada. La «inclinación del perfil» no puede apoyarse en `prioridad` (no existe en los datos).
- **Decisión:** prueba vertical con **A = `maren`** (sabe), **B = `nerea`** (aprende; mismo grupo y mismo taller) y **C = `ordal`** (control, otro grupo). Nerea llega por evento: la prueba debe comprobar `habitantes.ids` al empezar y, si no está, usar a `ordal` como B. La afinidad por oficio se declara en `saberes_v1.json` (`oficios_afines`), no en `prioridad`.
- **Bloqueo:** ninguno.

### 16.2 Rasgo de curiosidad
- **Verifiqué:** `sociedad.caracter` ([sociedad.gd:58](../../../Linde/cenital/scripts/sociedad.gd)) y `reglas.sociedad.caracter`.
- **Evidencia [C]:** el carácter tiene solo `honestidad`, `codicia` y `rencor` (defecto 70/30/30). `caracter()` mezcla el carácter del perfil sobre el defecto, así que un rasgo nuevo sería posible por datos, pero exige editar `reglas.json` y `sociedad.gd`, ambos con cambios concurrentes.
- **Afecta al plan:** sí. §6 no puede citar curiosidad como señal existente.
- **Decisión:** el MVP y el nivel B usan solo señales que ya existen: necesidad del grupo (forma no cubierta, `objetivos`), oportunidad de material (`observar` registra un material nuevo), mejora propia y oficio afín. La curiosidad queda como extensión opcional de datos (`caracter.curiosidad`) para cuando se coordine la edición. `codicia` y `honestidad` modularán más adelante la voluntad de enseñar o cobrar (nivel D), no el MVP.
- **Bloqueo:** ninguno.

### 16.3 `asentamientos.gd`
- **Verifiqué:** el archivo completo (154 líneas) y `datos/asentamientos/reglas_v1.json`.
- **Evidencia [C]:** los puestos regionales son un máximo de 3, con capacidad de 2 residentes. Un residente es un registro `{id, nombre, oficio, look, usos}` con oficio `recolector` o `cantero`. No tiene `npc:`, inventario, práctica ni estado de `desarrollo`. La producción es una extracción abstracta, sin conocimiento.
- **Afecta al plan:** sí. «Difusión entre asentamientos» no tiene dónde apoyarse hoy.
- **Decisión:** el conocimiento pertenece a actores (`npc:`/`pj:`). La difusión entre lugares se hará por **personas que se mueven**: colonos que llegan con saberes iniciales por oficio (datos), NPC que parten y regresan (arraigo) y jugadores. No se añade ningún gancho en asentamientos. Un «conocimiento del puesto» agregado queda fuera de alcance salvo decisión posterior.
- **Bloqueo:** ninguno.

### 16.4 Cálculo de `planos` en la réplica
- **Verifiqué:** `red_cliente.gd` (clase `Replica`), `escena.gd:456`, `desarrollo._init`, `autonomia._init` y `Srv.VERSION`.
- **Evidencia [C]:**
  - `Replica` extiende `juego.gd`. Al conectar copia `mundo_vivo` en `d` y llama a `_arrancar()`, que construye su propia `autonomia` y `desarrollo`. `planos`/`conoce` se calculan **en el cliente** sobre el estado replicado.
  - La réplica no es autoridad: `autonomia._init` ejecuta `sociedad.restaurar()` y `desarrollo.restaurar()` también allí, y `observar` ya escribe localmente.
  - El cliente lee `reglas_v1.json` de su propio paquete. El handshake comprueba solo `Srv.VERSION` (hoy 5), no los datos.
  - `mundo_vivo.autonomia.ultimo_min` cambia cada minuto, así que `_difundir` ya reenvía toda la sección `mundo_vivo` casi cada minuto de juego.
- **Afecta al plan:** sí, con cuatro reglas de diseño:
  1. `sabe`, `puede` y `candidatos` son **lecturas puras** sobre datos replicados: sin crear entradas y sin azar.
  2. Siembra, historia, progreso y toda escritura de saberes se guardan con `j.es_autoridad()`. `restaurar()` no debe sembrar en la réplica.
  3. `saberes_v1.json` viaja con el paquete: al añadirlo o cambiarlo se sube `Srv.VERSION`, que además cambia por la nueva intención.
  4. El coste adicional de red es **tamaño** del estado, no frecuencia (ya se reenvía cada minuto). Se mide en el nivel A.
- **Decisión:** adaptar `planos` sin cambiar su firma. La UI de `escena.gd` seguirá funcionando sin editarla en el nivel A.
- **Bloqueo:** ninguno.

### 16.5 Límites de longitud
- **Verifiqué:** `red_servidor.gd` (`MAX_TEXTO`, `_sig`, `_clave_valida`, `_lote`) y calculé las longitudes máximas con las reglas actuales.
- **Evidencia [C]:** `MAX_TEXTO = 48` por cada argumento de texto. La clave `art1:` más larga posible mide **40** (`art1:pantalones:hierro_fibra:reforzada:3`). `mat1:` mide como máximo 18. Los ids de saber previstos miden como máximo 37 (`dis:pantalones:bronce_fibra:reforzada`). `fabricar_artefacto` no pasa por `_clave_valida`: solo `_sig` y la validación posterior de `A.leer`. El login admite claves de 4–64.
- **Afecta al plan:** no al nivel A ni al B (todo cabe en 48). Sí al nivel C.
- **Decisión:** para `art2:` se introduce un límite propio de claves de ítem (`MAX_CLAVE`, propuesto 64) distinto del de texto libre, con subida de `Srv.VERSION`. Los parámetros se codifican de forma compacta (operador + nivel) para que la clave canónica quepa. Hasta el nivel C no se toca.
- **Bloqueo:** ninguno.

### 16.6 Estado de los cambios concurrentes
- **Verifiqué:** `git status`, `git diff --stat`, el contenido de los diffs de `autonomia.gd`, `escena.gd` y `mundo_vivo.gd`, y las firmas de las funciones que `desarrollo.gd` usa.
- **Evidencia [C]:** HEAD sigue en `324f339`. Hay 12 archivos modificados (+603/−54) sin confirmar, más `arraigo.gd` y `prueba_arraigo.gd` sin rastrear. `sociedad.gd` acumula +263 líneas y `habitat.gd` aparece ahora como modificado. **Sin modificar** respecto a HEAD: `desarrollo.gd`, `artesania.gd`, `juego.gd`, `guardado.gd`, `red_servidor.gd`, `red_cliente.gd`, `catalogos.gd`, `inventario.gd`, `equipo.gd`, `reglas_v1.json` y `prueba_desarrollo.gd`. Las firmas de `_ir`, `excedente`, `suceso`, `_obtener`, `grupo_de`, `confianza`, `_vinculo`, `_construir_estacion`, `_recordar`, `dar`, `_estacion` y `_quitar` no cambiaron entre HEAD y el árbol de trabajo.
- **Dependencia que impone un contrato:** el trabajo concurrente ya llama a `desarrollo.registrar(actor, disciplina[, objetos])` con disciplinas nuevas (`comercio`, `proteccion`, `exploracion`), a `desarrollo.rango`, `desarrollo.decidir(nid) -> bool`, `desarrollo.observar`, `desarrollo.cfg.activa` (las pruebas de sociedad y arraigo lo ponen a `false`) y `desarrollo.estado(actor).practica/materiales`. Además `_ocupar("desarrollo")` en sociedad es el punto de entrada de las decisiones.
- **Afecta al plan:** sí. Contrato de compatibilidad en §11: esas firmas y campos no cambian.
- **Decisión:** el nivel A y el B se implementan **solo en archivos sin modificar** (lista en §16.8). Antes de tocar cualquier archivo concurrente se repite `git status` y se coordina.
- **Bloqueo:** ninguno para el MVP. La **integración en la UI** (`escena.gd`) y las variables del director (`mundo_vivo.gd`) sí quedan bloqueadas hasta consolidar esos cambios.

### 16.7 Hallazgos adicionales que no estaban en §15
1. **El jugador pierde el acceso automático a técnicas avanzadas.** Hoy cualquier actor con rango suficiente puede hacer `ligera`, `reforzada` y laminados. Con saberes, el jugador necesita aprenderlos de un NPC o descubrirlos. Es el objetivo del sistema, pero implica que el jugador depende de NPC que sepan hasta que exista experimentación para jugadores (nivel B ampliado). **Decisión propuesta:** conocimiento inicial por oficio en `saberes_v1.json` (`inicial_por_oficio`: el oficio artesano conoce las técnicas y laminados básicos; el jugador empieza sin ninguno y los aprende de Maren). La siembra de partidas existentes sigue la regla aprobada (quien ya tiene rango y práctica con una técnica la conserva). **Requiere tu confirmación.**
2. **Tests existentes** (`prueba_desarrollo.gd` 62–66, 68, 85–102) asumen el desbloqueo automático. Se reescriben con concesión explícita del saber (ver A1).
3. **`restaurar()` corre también en la réplica.** Cualquier siembra debe protegerse con `es_autoridad()`.
4. **Los NPC ausentes por arraigo conservan su estado de `desarrollo`** (`_marchar` solo cambia su situación y el flag de presencia), de modo que sus saberes sobreviven y se podrán consultar al volver.

### 16.8 Resumen de bloqueos
| Punto | Bloqueo real |
|---|---|
| 1 Ids de NPC | No |
| 2 Curiosidad | No |
| 3 Asentamientos | No |
| 4 Réplica | No (reglas de diseño §16.4) |
| 5 Longitudes | No para A y B |
| 6 Concurrencia | No para A y B; sí para UI y director |
| 7.1 Conocimiento inicial del jugador | Pide tu confirmación; no impide empezar la base |

## 17. Implementación incremental sin estructuras temporales

Objetivo: que lo construido en A y B sea la base definitiva del nivel C (`art2:`), sin reemplazos.

### 17.1 Decisiones «sin arrepentimiento» que se toman desde el nivel A
1. **Descriptor de pieza, no tupla fija.** `artesania` seguirá devolviendo `{forma, material, tecnica, calidad}` para `art1:`. El código de conocimiento lee solo por una función `saberes_exigidos(descriptor) -> Array[String]`, que devuelve una **lista** de ids (en el MVP, 1–2 elementos). Con `art2:` el descriptor añade `params` y la misma función devuelve además los `ope:`. Ningún otro código cambia.
2. **Ids de saber como cadenas con prefijo** en un almacén genérico (§3.4). Los prefijos `dom:`, `dis:`, `ope:` e `inv:` no necesitan migración de esquema: son nuevas claves de un mismo diccionario.
3. **Exigencia por catálogo** (`exige` en `saberes_v1.json`). El código nunca contiene los 11 ids.
4. **La calidad no forma parte de la identidad del saber.** Aplica igual a `art1:` y `art2:`.
5. **`historia` por id de saber, con tope declarado en el propio registro** (`tope_aprendices`, `tope_entradas`). Las variantes de `art2:` no crean entradas por clave; solo `inv:` para las notables (§5.4).
6. **Subesquema `desarrollo.version = 2`** desde el nivel A. El nivel C solo añade campos opcionales; no cambia ni la versión de guardado ni la de `desarrollo`.
7. **`conoce()` se mantiene como API permanente** (`sabe && puede`), no como puente: `art2:` la usa igual.
8. **`planos()` sigue enumerando solo `art1:`.** Con `art2:` el espacio es demasiado grande para listarlo; la UI futura elige base + operadores conocidos. No se construye ninguna lista plana que luego haya que sustituir.

### 17.2 Lo que el nivel C añadirá (y que no exige rehacer A/B)
- `A.leer`/`info`/`receta`/`visible` para `art2:` y el soporte en `Eq`, inventario y réplica.
- `reglas_v2.json` con operadores, límites y presupuesto, y su validador.
- `MAX_CLAVE` en el servidor y subida de `Srv.VERSION`.
- Búsqueda local del NPC sobre operadores que ya sabe.
- Registro `inv:` acotado.

### 17.3 Riesgos de acumular deuda (a vigilar)
- Escribir condiciones sobre `p.tecnica` directamente en `sabe` en lugar de usar `saberes_exigidos` (rompería la regla 1).
- Guardar autoría en `creaciones` (el registro de 64 entradas).
- Hacer que la UI dependa de que el número de saberes sea pequeño.
- Aprendizaje de un saber por «ver» un objeto: contradice la separación exposición/dominio.

## 18. Estado de preparación del MVP

> **Superado:** el nivel A se implementó el 2026-10-25 (§19). Lo que sigue describe el estado previo a esa implementación.

**Listo para empezar el nivel A**, condicionado a tu confirmación del punto 16.7.1 (conocimiento inicial por oficio y del jugador). *(Confirmado por el usuario el 2026-10-25.)*

**Archivos que se tocarían primero (todos sin cambios concurrentes):**
1. `Linde/cenital/datos/desarrollo/saberes_v1.json` (nuevo): 11 saberes, `exige`, prerrequisitos, `inicial_por_oficio`, coste y progreso de experimento.
2. `Linde/cenital/scripts/desarrollo.gd`: `saberes_exigidos`, `valido`, `sabe`, `puede`, `candidatos`, `aprender`, `historia`, subesquema versión 2, siembra (solo autoridad) y `enseñar`/lección dentro de `decidir`.
3. `Linde/cenital/tests/prueba_saberes.gd` (nuevo) y ajustes a `tests/prueba_desarrollo.gd` (A1).
4. `Linde/cenital/scripts/juego.gd`: `ensenar`/`aprender_de` autoritativos para jugadores.
5. `Linde/cenital/scripts/red_servidor.gd`: nueva intención y subida de `VERSION` (y del cliente por la constante compartida).

**Se difiere hasta coordinar:** `escena.gd` (UI de enseñanza y experimentos), `mundo_vivo.gd` (variables del director), y cualquier ocupación nueva en `sociedad.gd`/`autonomia.gd`/`habitantes.gd`.

**Dependencias a resolver antes de empezar:**
1. Tu confirmación del conocimiento inicial (16.7.1).
2. Decidir el umbral de confianza para enseñar y la duración de la lección (valores iniciales en datos; se ajustan jugando).
3. Un `git status` limpio de los archivos de la lista anterior el día que se empiece.

**Dependencias para niveles posteriores (no bloquean A):** coordinación de `escena.gd` y `mundo_vivo.gd` (UI y director), `MAX_CLAVE` y `art2:` (nivel C), proyección por cliente (secretos y comercio).

## 19. Avance del nivel A (2026-10-25)

**Estado: implementado en el árbol de trabajo, sin commit.** Resultado de las pruebas abajo; solo se afirma lo que se ejecutó. El código no está confirmado en git y convive con cambios sin confirmar de otras sesiones.

### 19.1 Qué se hizo
| Archivo | Cambio |
|---|---|
| `Linde/cenital/datos/desarrollo/saberes_v1.json` (nuevo) | Catálogo complementario: técnicas `ligera` y `reforzada`, laminados, parámetros de enseñanza y conocimiento inicial. No toca `reglas_v1.json`. |
| `Linde/cenital/scripts/desarrollo.gd` | Subesquema versión 2; `catalogo`, `validar_saberes`, `saberes_exigidos`, `sabe`, `puede`, `conoce` (= `sabe` y `puede`), `candidatos`, `prerrequisitos_ok`, `aprender`, `sembrar` (solo autoridad), historia de aprendices, enseñanza NPC↔NPC dentro de `decidir` y `leccion_jugador`. |
| `Linde/cenital/scripts/juego.gd` | `ensenar_saber` y `pedir_saber`. |
| `Linde/cenital/scripts/red_servidor.gd` | Intenciones `ensenar_saber` y `pedir_saber`; protocolo `VERSION` 5 → 6. |
| `Linde/cenital/scripts/red_cliente.gd` | La réplica envía esas intenciones como pedidos. |
| `Linde/cenital/tests/prueba_saberes.gd` (nuevo) | 54 comprobaciones, incluida la prueba vertical. |
| `Linde/cenital/tests/prueba_desarrollo.gd` | Una comprobación reescrita y dos nuevas por el cambio esperado (ver 19.3). |

No se tocaron `sociedad.gd`, `autonomia.gd`, `habitantes.gd`, `escena.gd` ni `mundo_vivo.gd`; antes de cada edición se comprobó que los archivos modificados estaban sin cambios en git.

### 19.2 Conocimiento inicial aprobado
- Maren: `tec:ligera`, `tec:reforzada`, `lam:hierro_fibra`, `lam:bronce_fibra`. Ordal: `tec:reforzada`, `lam:hierro_piedra`. Nerea: `tec:ligera`.
- Base por oficio para colonos: artesano `tec:ligera`; cantero `tec:reforzada`; recolector, nada.
- Jugador: ninguno. Quien ya practicaba en una partida existente conserva las técnicas y laminados que su rango le permitía usar.

### 19.3 Pruebas ejecutadas (árbol de trabajo del 2026-10-25)
| Suite | Resultado |
|---|---|
| `prueba_saberes` (nueva) | 54 PASS, 0 FAIL en el primer cierre; **73 PASS, 0 FAIL** tras completar A4/A5/A7 y añadir `valido` (ver 19.7) |
| `prueba_desarrollo` | 57 PASS, 0 FAIL |
| `prueba_sociedad` | 48 PASS, 0 FAIL |
| `prueba_autonomia` | 33 PASS, 0 FAIL |
| `prueba_arraigo` (sesión concurrente) | 68 PASS, 0 FAIL |
| `prueba_aspecto` | 225 PASS, sin FAIL |
| `prueba` (general) | 327 PASS, sin FAIL |
| `prueba_red` (servidor y clientes reales en localhost, protocolo 6) | 11 [OK], 0 fallidas; p95 del tick 2,83 ms |

- **No se ejecutaron:** `prueba_ui`, `prueba_proteccion`, `prueba_terreno`, `prueba_terreno_red`, `prueba_fauna`, `prueba_orden_dibujo`, `prueba_caminos`, `prueba_campos_cultivo`, `prueba_casas`, `prueba_crecimiento`, `prueba_crecimiento_red`, `prueba_reglas`.
- **Modificadas por el nuevo comportamiento esperado:** en `prueba_desarrollo.gd`, la comprobación «una técnica avanzada también necesita espacio de taller» ahora concede antes el saber `tec:ligera`; se añadieron «el rango no concede una técnica que nadie ha enseñado» y «con práctica y componentes tampoco se elabora un laminado cuyo proceso no se conoce» (el laminado se concede antes de las tres elaboraciones). Pasaron de 55 a 57 comprobaciones.
- **Anomalía previa — investigada (ver 19.7):** el fallo de «los prototipos también desgastan la mesa utilizada» no es intermitente ni procede de K1; es una función determinista del árbol que depende de si una reparación cae al final de la simulación.
- **Sensibilidad de la prueba:** con `confianza_min` = 5 fallan las 8 comprobaciones de la prueba vertical; con `reputacion_min` = 5 fallan las del jugador. Se restauró el JSON original (comprobado con `cmp`).

### 19.4 Criterios de aceptación del nivel A
| Criterio | Estado | Evidencia y salvedad |
|---|---|---|
| A1 | Cumplido | `prueba_desarrollo` 57/0; ajustes en 19.3. |
| A2 | Cumplido en `conoce` | `sabe` sin `puede` y viceversa se comprueban. Nota: `puede` por sí solo **no** incluye `sabe` (así queda definido en §3.3); lo que exige ambos es `conoce`, que usan `fabricar`, `planos` y `decidir`. |
| A3 | Cumplido | Prueba vertical: Maren enseña a Ordal sin intervención del jugador (tras 60 min simulados); el jugador no hereda el saber. |
| A4 | Cumplido | Alumno NPC: tras completar la lección su práctica es idéntica, su rango sigue por debajo del de Maren (30 acciones) y su inventario no cambia; el maestro conserva práctica y saber. Jugador: ídem. Mucha práctica sin lección tampoco concede el saber. Una mutación que copia la práctica del maestro hace fallar la comprobación. |
| A5 | Cumplido | Con 40 recuerdos nuevos (tope 32, se pierde el recuerdo de la lección) y 70 creaciones (tope 64) la historia es idéntica. Una mutación que borra la historia al recortar creaciones hace fallar la comprobación. |
| A6 | Cumplido | Guardar, cargar, `restaurar` y 120 min más: estado idéntico, sin aprendizaje duplicado. |
| A7 | Cumplido | Rechazados **y contados por remitente** (`registro.rechazos`): argumento extra de autor, pedido incompleto, saber de 60 caracteres, habitante inexistente, remitente sin sesión y secuencia repetida; ninguno cambia saberes ni historia. Un pedido bien formado pero sin nada que enseñar **no** es rechazo de red y no concede nada. Las negativas de lógica (sin preparación, lejos, desconfianza) las decide el servidor sin contarlas. Mutaciones que relajan la firma o la longitud hacen fallar 4 comprobaciones. |
| A8 | Cumplido | La siembra no escribe historia ni inventor; la migración de una partida anterior tampoco. |

### 19.5 Desviaciones y límites conocidos
1. **La lección con el jugador es instantánea.** El plan hablaba de lección con tiempo; solo la enseñanza NPC↔NPC lleva lección de 20 minutos. Requiere proximidad, que el habitante esté despierto, `reputacion_min` y preparación.
2. **Nerea no está en el valle al empezar** (llega por evento). La prueba vertical usa a Maren y Ordal, y el jugador como control.
3. **Sin UI.** `escena.gd` está en cambios concurrentes. El jugador no puede enseñar ni pedir un saber desde la pantalla, y el panel de planos mostrará un texto desfasado mientras no se coordine. `ensenar_saber`/`pedir_saber` solo se ejercitan por código y por la red.
4. **Diario de sucesos:** el tipo `ensenanza` se muestra con su identificador porque `sociedad.texto_suceso` (archivo concurrente) no tiene texto propio.
5. **`exige` del catálogo** solo admite `tec` y `lam`; `validar_saberes` rechaza otros valores hasta implementar `dom:`/`dis:`/`ope:`.
6. **Réplica abierta:** el conocimiento de todos viaja a todos los clientes (§9). No hay privacidad.
7. **Registro de decisiones** (`Linde/cenital/docs/DECISIONES.md`): no se actualizó por estar modificado por otra sesión; pendiente de coordinar.
8. **Pendiente de revisión humana de balance:** `confianza_min`, `minutos`, `radio_busqueda_celdas` y `enfriamiento_min` son valores iniciales; no se ha jugado a mano.

### 19.8 Pendientes de integración cerrados (2026-10-25)
1. **UI de pedir y enseñar saberes:** hecha en `escena.gd` (entrada «Saberes» y panel; 25 líneas). Evidencia en `production/qa/evidence/saberes/` (`taller.png`, `saberes_antes.png`, `saberes_despues.png`) con una lección real de Maren al jugador, y `tests/captura_saberes.gd` (3 comprobaciones).
2. **Huella de reglas en el saludo (P1 de H0):** hecha; `Srv.VERSION` 7. Rechaza versión distinta, saludo sin huella y huella distinta, y corta la conexión. Probado en `prueba_saberes` (mutación que desactiva la comprobación la hace fallar) y con clientes reales en `prueba_red` (11 OK).
3. **Prueba de desgaste de mesa:** mide el máximo durante la simulación (misma simulación). Con el código de `HEAD` pasa 55/0 (antes 55/1); con K1, 57/0.
4. **Compatibilidad de guardados:** 9 comprobaciones nuevas en `prueba_saberes` (formato 3 y envoltura intactos; mundo K1 aceptado; mundo sellado antes de K1 rechazado con `reglas_distintas` y archivo intacto; excepción explícita carga con marca de contaminación y sin historia inventada). Con la comprobación de huella desactivada fallan. Requisito `guardado.FORMATO` retirado de K1.
5. `prueba_saberes` pasa de 73 a 87 comprobaciones. Suites completas en PLAN_MAESTRO §10 K1 y en ESTADO.md.

### 19.6 Siguiente paso
Según la secuencia acordada (PLAN_MAESTRO §10): H0 → K1 y M0 → I1a → K2 → I1b. El «nivel B» de este documento corresponde a **K2** y no se empieza hasta que I1a esté lista. Dependencias abiertas de K1: ventana coordinada para `escena.gd` (UI, 19.7), la huella en el saludo de red y el motivo de rechazo por reglas en la UI.

### 19.7 Cierre de K1 (2026-10-25)

**Pruebas añadidas.** A4 (alumno NPC y jugador), A5 (desbordamiento real de recuerdos y creaciones) y A7 (rechazos contados) en `tests/prueba_saberes.gd`, más `valido` como cuarta consulta. Todas verificadas con mutaciones que fallan (A4 hereda práctica; A5 borra historia al recortar; A7 firma y longitud relajadas).

**Fallo de «desgaste de la mesa».** Experimento controlado con copias del árbol: dos ejecuciones con los archivos de K1 dieron resultados idénticos (57 comprobaciones, 0 fallos); con los archivos de K1 devueltos a `HEAD`, 55 comprobaciones y 1 fallo idéntico al de antes de tocar nada. Diagnóstico con una copia instrumentada: el desgaste máximo de la mesa durante la simulación fue 4, pero la mesa terminó en 0 porque se reparó en el minuto 3345 («Reparó la mesa antes de hacer un candado»), así que una comprobación del estado final no ve el desgaste de los prototipos. Conclusión: es un defecto de diseño de la comprobación (estado final de un valor que se reinicia), sensible a cualquier cambio de la secuencia de decisiones; K1 solo la cambia de lado. No se modificó la prueba; propuesta: muestrear el máximo durante la simulación.

**Cambio mínimo de UI (no aplicado; `escena.gd` está en cambios concurrentes).** Un solo bloque en la rama `"desarrollo"` (alrededor de las líneas 429–451, tras la sección «OBRAS QUE OFRECEN LOS HABITANTES») y un texto:
```gdscript
_l("— SABERES —")
var yo: String = j.actor_desarrollo()
var dv = j.autonomia.desarrollo
for nid in j.habitantes.ids:
    for id in dv.catalogo():
        var nombre: String = dv.catalogo()[id].nombre
        if dv.tiene_saber(nid_actor, id) and not dv.tiene_saber(yo, id): _l("  Pedir a %s: %s" % [ficha, nombre], func(): j.pedir_saber(nid, id))
        elif dv.tiene_saber(yo, id) and not dv.tiene_saber(nid_actor, id): _l("  Enseñar a %s: %s" % [ficha, nombre], func(): j.ensenar_saber(nid, id))
```
(con `nid_actor = "npc:" + nid` y `ficha = j.habitantes.fichas[nid].n`). Todo se calcula sobre datos replicados; la autoridad decide. Además, el texto vacío de «planos» (línea ~457) debería decir que las técnicas se aprenden de otros. Son unas 12 líneas en una rama, en una región distinta de los 4 cambios concurrentes actuales (~536–546). Requiere ventana coordinada y una captura en `production/qa/evidence/`.

**Frente al K1 de PLAN_MAESTRO.** Las diferencias (`FORMATO` sin subir, UI, huella en el saludo de red, lección instantánea del jugador, `valido`) están en PLAN_MAESTRO §10 «Estado de K1».
