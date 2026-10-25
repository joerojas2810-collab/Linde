# Plan maestro unificado: materiales, conocimiento, descubrimiento e invención en Linde

**Estado:** plan con decisiones O1–O7 confirmadas (2026-10-25). **H0 aprobada el 2026-10-25 como núcleo implementado y verificado, commit `70d7b5f` (ver §10, «Estado de H0»), con dos integraciones pendientes antes del playtest multijugador externo.** **M0 aprobada el 2026-10-25 como implementada y verificada, commit `e0dc0dd`** (ver §10, «Estado de M0»). I1a no se ha iniciado: antes hay que revisar el cierre de K1, comprobar la estabilidad del árbol compartido y coordinar ambos sistemas. K1 la desarrolla otra sesión.

**Consolidación (2026-10-25):** H0 `70d7b5f`, M0 `e0dc0dd`, K1 `4141ae9` y corrección de rendimiento (`_construir_cerca`, `_ampliar`) `c967ba9`, en commits separados y en ese orden. Las menciones «sin commit» de las secciones de estado son anteriores a esta consolidación. Pendiente explícito: **P2** (mostrar el motivo `reglas_distintas` en la interfaz). K2 e I1a no se han iniciado.
**Revisión:** 2 (2026-10-25). La revisión 1 era la primera versión unificada; esta incorpora las decisiones, la huella de reglas, la versión del evaluador, la división de I1, la ampliación de K2 y la distinción entre variantes fabricables e invención autónoma.
**Integra:** la propuesta «Materiales, Transformación y Descubrimiento» (texto del encargo), [PLAN_IMPLEMENTACION](PLAN_IMPLEMENTACION.md) (niveles A–D), [DECISIONES](DECISIONES.md), [COMPATIBILIDAD_LINDE](COMPATIBILIDAD_LINDE.md) y relectura del código actual.
**Relación con los documentos previos:** este archivo **no borra ni reescribe** ninguno. Donde contradice a PLAN_IMPLEMENTACION lo dice expresamente (§1.2) y **prevalece este plan**.

Etiquetas, como en el resto de la carpeta: **[C]** confirmado en código/datos leídos, **[I]** inferido, **[P]** propuesta, **[V]** por verificar. Las cifras marcadas «calculado a mano» salen de las fórmulas de `artesania.gd` con los valores de `reglas_v1.json`; **no se ejecutó nada** para obtenerlas.

---

## 0. Resumen

Hay **un solo sistema**, no dos: materiales e invención comparten la misma gramática (`artesania.gd`), el mismo almacén de estado (`desarrollo.gd`), los mismos catálogos (`catalogos.gd`, `reglas`) y la misma ruta de fabricación (`Inv.cambiar`, estaciones, servidor).

| Bloque | Qué entrega | Fases |
|---|---|---|
| **Cimiento de reproducibilidad** | Huella canónica de reglas, versión del evaluador, test dorado. | H0 |
| **MVP de conocimiento y descubrimiento** | Saberes por actor, enseñanza, autoría durable, descubrimiento autónomo (con saberes de dominio) y fallos. | K1, K2, K3 |
| **Expansión funcional de materiales** | Propiedades con consumidores reales; procesos (carbón, acero); cuero desde criaturas existentes. Madera dura diferida. | M0, M1, M2, (M3) |
| **Invención combinatoria** | **I1a:** variantes que el *jugador* fabrica con operadores. **I1b:** invención *autónoma de NPC*. I2: operadores adicionales. | I1a, I1b, I2 |

Orden aprobado: **F0 → H0 → (K1 ∥ M0) → I1a → K2 → I1b → M1 → K3 → I2 → M2 → S1**, con M3 diferida.

Principios que fijan esta revisión:

1. **Los 9 laminados se conservan hasta que I1a demuestre equivalencia funcional** (§4.4). Si no la demuestra, no se retiran.
2. **Una variante fabricable por el jugador no es innovación emergente.** Solo lo es la invención autónoma de un NPC que cumple los criterios E1–E6 (§9.2). I1a demuestra que el sistema de operadores *funciona*; I1b demuestra que existe *innovación*.
3. **Sin compatibilidad no significa sin versionado.** El juego se niega a cargar un mundo con reglas distintas a menos que se pida expresamente (§7).
4. **Ningún recurso entra sin fuente, proceso, consumidor y dependencias** (§6).

---

## 1. Decisiones

### 1.1 Las ocho decisiones del encargo y dónde se recogen

| # | Decisión | Dónde |
|---|---|---|
| 1 | Un solo plan integrado, sobre `desarrollo.gd`, `artesania.gd`, catálogos y sistemas existentes. | §8 |
| 2 | Clasificar laminados antes de convertirlos. | §4 |
| 3 | Propiedades con consecuencias jugables reales; ampliables; sin «dureza = daño» universal. | §5 |
| 4 | Sin compatibilidad con partidas viejas; versionado y reproducibilidad coherentes. | §7 |
| 5 | Tabla exacta de IDs; los 24 son orientativos. | §3 |
| 6 | Distinguir descubrir una técnica predefinida de inventar una variante. | §9 |
| 7 | Fuente, proceso, uso y dependencias antes de planificar cuero/hueso/tendón/cerámica/tratamientos. | §6 |
| 8 | Respetar cambios concurrentes. | §12 |

### 1.2 Qué sustituye este plan de PLAN_IMPLEMENTACION

| PLAN_IMPLEMENTACION | Decisión vigente | Motivo |
|---|---|---|
| §1.5 y D12: `reglas_v1.json` congelado; todo lo nuevo en archivos complementarios y `art2:`. | Reglas editables en sitio durante desarrollo, bajo la política de §7 (huella, versiones, evaluador). | Sin partidas que proteger. |
| §4: `mat1:` no se redefine; proporciones futuras en `mat2:`. | `mat1:` se conserva **hasta I1a-R** (retirada condicionada, §4.4). | O2. |
| §3.1: 11 saberes iniciales (2 técnicas + 9 laminados). | Los `lam:` son **transitorios**: existen mientras existan los laminados. | O2. |
| §7 nivel C (invención) como último paso, XL. | **Dividido en I1a (jugador, temprana) e I1b (NPC)**; I1a se adelanta. | Aprobación 3 y 4. |
| §7 nivel B: ~11 descubribles. | K2 se amplía con **saberes de dominio** (§9.4). | Aprobación 5. |
| §1.3 siembra sin inventor retroactivo. | **Se mantiene** para NPC iniciales de mundos nuevos. | Sigue válido. |
| §8 orden D1a/D1b/D1c. | Sustituido por M0–M3 con compuerta de consumidor. | §6. |

Todo lo demás de PLAN_IMPLEMENTACION (niveles de saber, cuatro consultas, motivo y capacidad, enseñanza, privacidad como limitación, director como consumidor) **se conserva** y es la base de K1–K3.

### 1.3 Decisiones confirmadas (2026-10-25)

| ID | Decisión confirmada | Efecto |
|---|---|---|
| **O1** | **B.** Acero y bronce tienen perfiles distintos, sin superioridad absoluta. Las ventajas por forma se validan con pruebas. | §5.3–5.5, M1 |
| **O2** | **Confirmada.** Laminados conservados hasta que I1a demuestre equivalencia funcional. | §4.4, I1a-R |
| **O3** | **Confirmada con condiciones.** El cuero procede de criaturas existentes mediante botines coherentes. **No se fijan probabilidades ni tiempos de reaparición.** Se verificó cómo lo obtendrían los NPC. | §6.2, M2, O8 |
| **O4** | **A.** Se mantienen los nombres fantásticos heredados mientras sus efectos sean compatibles con la dirección no mágica del sistema. | §3.4 |
| **O5** | **B.** Renombrar los ítems ambiguos en una ventana coordinada durante M1. | §3.2, M1 |
| **O6** | **A.** Madera dura diferida hasta comprobar que las propiedades físicas generan diferencias jugables. | M3 |
| **O7** | **A**, con el requisito de **estabilizar I1a antes de sellar** y de **sellar antes del primer playtest externo**. | §7.5 |

Aprobaciones adicionales: (1) huella canónica de reglas en el guardado con comprobación al cargar y excepción explícita para desarrollo (§7.2); (2) versión del evaluador de fabricación (§7.3); (3) dividir I1 en I1a e I1b; (4) adelantar I1a; (5) ampliar K2 con saberes de dominio.

### 1.4 Correcciones a mis evaluaciones anteriores en esta conversación

- Dije que la arcilla «casi no se usa» y que el ladrillo se hace solo con piedra. **Es incorrecto:** existe `ladrillo_arcilla` (2 arcilla → 3 ladrillos en horno) además de `ladrillo` (piedra + fibra). La arcilla tiene fuente (pozos, biomas secano y pradera) y consumidor (ladrillo). Lo que no existe es cerámica distinta del ladrillo.
- Dije que faltaba verificar si había drops animales. Verificado: no los hay (§6.2).
- Dije que la fase A tocaba solo `desarrollo.gd` y `artesania.gd`. El plan anterior también toca `juego.gd`, `red_servidor.gd` y una adaptación en `escena.gd`; este plan lo mantiene.

---

## 2. Qué existe hoy (evidencia relevante)

- **[C]** `scripts/catalogos.gd` define `ITEMS` (22 entradas), `OBJETOS` (fuentes en el mundo), `CONSTR`, `RECETAS` y `ENEMIGOS`.
- **[C]** `datos/desarrollo/reglas_v1.json` define 6 materiales de la gramática (`madera`, `piedra`, `fibra`, `hierro`, `cobre`, `bronce`), 7 formas, 3 técnicas, 4 calidades y los laminados (3 núcleos × 3 refuerzos).
- **[C]** Cada material de la gramática solo tiene `coste`, `potencia`, `vel`, `arquetipo`, `color`, `formas`. Las estadísticas de una pieza salen de `potencia` (multiplica `dmg`, `def` y `hp` de la forma) y `vel`.
- **[C]** `terreno_v1.gd` y `terreno_v2.gd` reparten objetos por bioma; `estado.generacion.version` ya distingue generaciones.
- **[C]** `datos/autonomia/reglas.json` contiene valores/reservas por ítem para los NPC. **Está modificado sin confirmar por otra sesión.**
- **[C]** Dos sistemas de conocimiento sin relación: `autonomia.descubrir_recetas` (desbloqueo inmediato de `C.RECETAS`) y `desarrollo` (gramática + práctica).
- **[C]** El combustible es **un ingrediente** (`lingote` = 2 mena + 1 madera en horno); no hay temperatura ni tipos de horno.
- **[C]** El desgaste existe en **estaciones** y **herramientas de NPC**; **las piezas de equipo no se desgastan**.
- **[C]** Cómo consiguen ítems los NPC (verificado por lectura de `sociedad.gd`, `autonomia.gd`, `habitantes.gd`, `asentamientos.gd`):
  1. Recolectar objetos del mundo (`OBJETOS.drops`, **con botín probabilístico `prob`**: `autonomia.gd` ~194–198, `sociedad.gd` ~933–946).
  2. Acuerdos y comercio con otros NPC que tengan excedente (`_obtener`, `acordar`, `_comerciar`).
  3. Retirar del depósito del grupo.
  4. Fabricar con recetas conocidas.
  5. Prospectar un recurso que nunca han tenido (`_prospectar`, que recorre `OBJETOS`).
  **No hay ninguna ruta en la que un NPC ataque criaturas ni recoja sus botines.** «Combate» aparece solo como nombre de disciplina; el guardia disuade hurtos, no combate. Los botines de enemigos (`combate.gd`: `dar_o_pendiente(def.drops, id)`) son **fijos** y solo se entregan al jugador.

---

## 3. Catálogo exacto

### 3.1 Ítems actuales (`catalogos.gd` → `ITEMS`) clasificados

| ID de ítem | Nombre | Clase | Fuente / proceso actual | Consumidor actual |
|---|---|---|---|---|
| `madera` | Madera | Materia prima | `arbol` (3), talar | Gramática (`madera`), construcción, combustible-ingrediente, recetas |
| `piedra` | Piedra | Materia prima | `roca` (2), picar | Gramática (`piedra`), construcción, ladrillo, técnica `reforzada` |
| `fibra` | Fibra | Materia prima | `arbusto` (2), campos, drops de enemigos | Gramática (`fibra`, «tejido»), técnica `ligera`, camas, techos |
| `mena` | Mena de hierro | Materia prima | `veta` (2, +gema 25 %) | Receta `lingote` |
| `cobre` | Mena de cobre | Materia prima | `veta_cobre` (2) | Receta `lingote_cobre` |
| `estano` | Mena de estaño | Materia prima | `veta_estano` (2) | Receta `lingote_bronce` |
| `arcilla` | Arcilla | Materia prima | `arcilla` (3), drop de `diablillo_secano` | Receta `ladrillo_arcilla` |
| `lingote` | Lingote | Procesado | `mena`×2 + `madera`, horno, hab. artesano | Material `hierro`, candado, joya Chispa, espada de hierro |
| `lingote_cobre` | Lingote de cobre | Procesado | `cobre`×2 + `madera`, horno | Material `cobre`, bronce, hachas/picos de cobre |
| `lingote_bronce` | Lingote de bronce | Procesado (aleación) | `lingote_cobre`×2 + `estano`, horno → 2 | Material `bronce` |
| `ladrillo` | Ladrillo | Procesado | `ladrillo` (piedra×2 + fibra → 2) y `ladrillo_arcilla` (arcilla×2 → 3), horno | `muro_ladrillo` |
| `gema` | Gema | Botín raro / insumo | Vetas (15–25 %), jefes | Joya Chispa; **no es «cuarzo»** |
| `baya`, `gelatina`, `unguento` | — | Consumibles / insumos | arbusto, slimes, mesa | Curación, ungüento, semilla de campo |
| `candado`, `hacha_piedra`, `pico_piedra`, `hacha_cobre`, `pico_cobre`, `espada_hierro`, `escudo_madera` | — | Productos finales estáticos | Recetas | Herramientas / equipo |

Además existen: los **9 laminados** `mat1:<núcleo>_<refuerzo>` (generados, no listados en `ITEMS`), las piezas `art1:` y las piezas de equipo `eq:` (`datos/equipo/`).

### 3.2 Materiales de la gramática y su ítem real

| Material (`reglas`) | Ítem que se consume | `coste` | `potencia` | `vel` | Formas |
|---|---|---|---|---|---|
| `madera` | `madera` | 3 | 0.65 | +0.01 | espada, escudo |
| `piedra` | `piedra` | 3 | 0.80 | −0.02 | espada, escudo |
| `fibra` («tejido») | `fibra` | 4 | 0.65 | +0.02 | casco, torso, guantes, botas, pantalones |
| `hierro` | `lingote` | 2 | 1.20 | −0.01 | las 7 |
| `cobre` | `lingote_cobre` | 2 | 1.00 | 0.00 | las 7 |
| `bronce` | `lingote_bronce` | 2 | 1.35 | −0.01 | las 7 |

**Renombrado aprobado (O5-B), ejecutado en M1 en ventana coordinada [P]:**

| ID actual | ID propuesto | Motivo |
|---|---|---|
| `mena` | `mena_hierro` | Hoy parece genérico pero es solo hierro |
| `lingote` | `lingote_hierro` | Ídem |
| `cobre` (ítem) | `mena_cobre` | Choca con el material `cobre`, que consume `lingote_cobre` |
| `estano` | `mena_estano` | Coherencia con los anteriores |

Precondiciones: que los cambios concurrentes de `datos/autonomia/reglas.json`, `autonomia.gd` y `sociedad.gd` estén consolidados; mapa de renombrado escrito antes de empezar; test dorado regenerado en el mismo cambio; la huella de reglas (§7.2) cambiará, lo que es esperable y se anota.

### 3.3 Los 24 materiales frente al repositorio

Criterios: **Existente** = ID propio con fuente y consumidor; **Equivalente** = versión genérica que cubre una o más entradas; **Procesado** = producto de un proceso; **Ausente**.

| Familia | Objetivo | Existente / equivalente / procesado | Ausente |
|---|---|---|---|
| Metales y minerales (5) | Hierro, cobre, estaño, plata, oro | `mena`+`lingote` (hierro), `cobre`+`lingote_cobre`, `estano`; **procesado:** `lingote_bronce` (no cuenta como materia prima) | plata, oro |
| Piedras (4) | Piedra común, granito, caliza, arcilla | `piedra` (común), `arcilla`; **procesado:** `ladrillo` | granito, caliza |
| Maderas (3) | Blanda, dura, flexible | `madera` (única, sin tipo) | dura, flexible (y «blanda» como categoría) |
| Fibras (3) | Lino, cáñamo, algodón | `fibra` (genérica; cultivable en `campo`) | lino, cáñamo, algodón |
| Animales (3) | Cuero, hueso, tendón | — | cuero, hueso, tendón |
| Reactivos y combustibles (4) | Carbón vegetal, carbón mineral, azufre, sal | — (la madera hace de combustible-ingrediente) | los 4 |
| Especiales (2) | Cuarzo, resina | `gema` (distinta: botín raro, no material técnico) | cuarzo, resina |

**Recuento [C/I]:** 7 materias primas genéricas cubren parcialmente 5 de los 7 grupos; **17 entradas del objetivo no tienen equivalente**. El bronce es aleación y no suma a las 24.

### 3.4 Nombres de tono fantástico heredados (O4-A)

**[C]** `datos/equipo/variantes.json` contiene «Piedra de Alma», «Piedra de Armonía» y «Piedra de Bendición» (variantes cosméticas con multiplicadores `def`/`hp`/`vel`) y `joyas.json` una «Chispa de Temple» (mejora numérica de equipo). Criterio vigente: **se mantienen mientras sus efectos sean numéricos o cosméticos**, sin reglas sobrenaturales. Si una futura entrada otorgara un efecto no expresable en las propiedades del sistema (por ejemplo, un poder que altere reglas del motor), se revisa con dirección creativa. Los materiales y procesos **nuevos** de este plan no usan nombres ni efectos mágicos.

---

## 4. Clasificación de los laminados

### 4.1 Qué son hoy [C]

`artesania.material(id)` construye `<núcleo>_<refuerzo>` con: `potencia = 0.85·núcleo + 0.15·refuerzo`, `vel` = media, `formas` = intersección, color mezclado, coste de pieza 1. Receta: 2 de núcleo + 2 de refuerzo → 1 unidad (`mat1:`, pila 10), en horno, con rango de artesanía ≥ 1 y conociendo ambos materiales.

### 4.2 Criterios de clasificación [P]

Un «material intermedio fabricable y comerciable» debe cumplir **todos**:

| Criterio | Pregunta |
|---|---|
| T1. Transformación real | ¿El resultado tiene propiedades que no son una media de sus partes (aleación, curtido, cocción)? |
| T2. Demanda múltiple | ¿Lo consumen al menos dos diseños o procesos distintos? |
| T3. Sentido de stock | ¿Tiene sentido fabricarlo, guardarlo y venderlo sin pieza final? |
| T4. Compromiso no dominado | ¿Ofrece una ventaja que su insumo principal no ofrece? |

Un **componente interno** falla T1 o T4: describe cómo está hecha *esta pieza*, no una sustancia con vida propia.

### 4.3 Resultado por combinación (calculado a mano)

| ID | Potencia | frente al núcleo | `vel` | Formas | T1 | T2 | T3 | T4 | Tratamiento |
|---|---|---|---|---|---|---|---|---|---|
| `hierro_madera` | 1.1175 | −7 % | 0.000 | espada, escudo | No | Parcial | Débil | Solo `vel` +0.01 | **Componente** |
| `hierro_piedra` | 1.1400 | −5 % | −0.015 | espada, escudo | No | Parcial | Débil | No | **Componente** |
| `hierro_fibra` | 1.1175 | −7 % | +0.005 | 5 de armadura | No | Parcial | Débil | `vel` +0.015 | **Componente** |
| `cobre_madera` | 0.9475 | −5 % | +0.005 | espada, escudo | No | Parcial | Débil | `vel` +0.005 | **Componente** |
| `cobre_piedra` | 0.9700 | −3 % | −0.010 | espada, escudo | No | Parcial | Débil | No | **Componente** |
| `cobre_fibra` | 0.9475 | −5 % | +0.010 | 5 de armadura | No | Parcial | Débil | `vel` +0.01 | **Componente** |
| `bronce_madera` | 1.2450 | −8 % | 0.000 | espada, escudo | No | Parcial | Débil | `vel` +0.01 | **Componente** |
| `bronce_piedra` | 1.2675 | −6 % | −0.015 | espada, escudo | No | Parcial | Débil | No | **Componente** |
| `bronce_fibra` | 1.2450 | −8 % | +0.005 | 5 de armadura | No | Parcial | Débil | `vel` +0.015 | **Componente** |

Lectura:

- **Ninguno pasa T1** (media ponderada, sin transformación) **ni T4 de forma significativa** (pierden entre 3 % y 8 % de potencia y ganan, como mucho, 0.015 de velocidad).
- **Coste:** una pieza laminada consume 1 unidad `mat1:` = 2 de núcleo + 2 de refuerzo; la pieza pura consume 2 de núcleo. Cuesta lo mismo en núcleo más 2 de refuerzo y rinde menos.
- **Duplican las técnicas:** `ligera` añade 1 `fibra` (×0.9, vel +0.02) y `reforzada` añade 1 `piedra` (×1.1, vel −0.02): el mismo concepto de refuerzo con otro mecanismo.
- **Información útil:** la intersección de `formas` hace que el refuerzo `madera`/`piedra` restrinja a espada/escudo y `fibra` a armadura. Hay **27 combinaciones forma × laminado** posibles (3 núcleos × (2 + 2 + 5)).

### 4.4 Decisión vigente (O2) y criterio de retirada [P]

| Aspecto | Decisión |
|---|---|
| Clasificación | Los 9 son **componentes internos**; ninguno es material intermedio comerciable. |
| Mientras tanto | **Se conservan sin cambios** (`mat1:`, receta de horno, saberes `lam:`) durante H0, K1, M0 y la parte de I1a anterior a la retirada. |
| Destino | El **refuerzo** se reimplementa como **operador de composición** en I1a. |
| Retirada | Solo en el subpaso **I1a-R**, **si y solo si** se cumplen R1–R4. Si no se cumplen, los laminados permanecen y no se pierde nada. |

**Condiciones de retirada:**

| ID | Condición | Cómo se comprueba |
|---|---|---|
| R1. Cobertura | Cada una de las **27 combinaciones forma × laminado** tiene una configuración alcanzable en el sistema nuevo. | Test que enumera las 27 y busca su equivalente |
| R2. Rendimiento | La potencia y la velocidad derivadas son ≥ las del laminado (dentro de la tolerancia declarada) o difieren por un compromiso documentado. | Misma enumeración; tabla de diferencias revisada por una persona |
| R3. Conocimiento | El acceso que daba cada saber `lam:` tiene equivalente (`op:` + materiales vistos) y la ruta de descubrimiento no se pierde. | Prueba de saberes |
| R4. NPC y pruebas | Los NPC que fabricaban laminados en `decidir` tienen ruta equivalente; las comprobaciones existentes sobre `mat1:` (`tests/prueba_desarrollo.gd` ~líneas 85–98) se **reescriben**, no se borran. | Prueba de NPC; revisión del diff de pruebas |

Referencias a retirar si R1–R4 se cumplen **[C]**: `desarrollo.gd` (`observar`, `conoce_laminado`, `decidir`), `escena.gd` (lista de planos), `tests/prueba_desarrollo.gd` y **`sociedad.gd` (~línea 1260, `leer_material`; archivo en edición)**. Retirarlos exige coordinar ese punto.

---

## 5. Modelo de propiedades físicas

### 5.1 Principio

Una propiedad se añade **solo si tiene un consumidor ya existente o programado en una fase concreta**. El modelo es una tabla de propiedades por material más **pesos por forma**; añadir una propiedad es añadir una columna y, cuando haga falta, un peso.

### 5.2 Consumidores reales y decisión

| Propiedad (propuesta) | Consumidor | ¿Existe hoy? | Decisión |
|---|---|---|---|
| **Dureza** | Eficacia de formas ofensivas (peso por forma) | Sí: `dmg` de `espada` | **M0** |
| **Tenacidad** | Eficacia de formas defensivas (`def`, `hp`) | Sí: `escudo`, armaduras | **M0** |
| **Densidad** | `vel` de la pieza; después, carga | Sí: `vel` | **M0** (sustituye al `vel` por material) |
| Resistencia térmica | Requisito de calor de procesos | No: no hay temperaturas ni tipos de horno | Reservada hasta que un proceso la necesite (I2: templado) |
| Elasticidad | Armas a distancia | No existen | Reservada |
| Durabilidad ambiental | Desgaste de equipo | No: el equipo no se desgasta | Reservada |
| Rareza | Generación y precio | Parcial (`terreno_v*`, `reglas.json`) | **No es propiedad de pieza** |
| Coste de procesamiento | Receta | Implícito en recetas | Sigue siendo receta |

### 5.3 Cómo evitar «dureza = daño»

Cada **forma** declara pesos sobre las propiedades; la eficacia de la pieza es la suma ponderada. Pesos **[P, ilustrativos, sin balancear]**:

| Forma | Peso dureza | Peso tenacidad |
|---|---|---|
| espada | 0.6 | 0.4 |
| escudo | 0.2 | 0.8 |
| casco / guantes / botas | 0.3 | 0.7 |
| torso / pantalones | 0.2 | 0.8 |

Valores de material elegidos para **reproducir el `potencia` actual** como media de partida, con perfiles distintos **[P, ilustrativos]**:

| Material | Dureza | Tenacidad | Media | `potencia` actual |
|---|---|---|---|---|
| madera | 0.50 | 0.80 | 0.65 | 0.65 |
| piedra | 0.90 | 0.70 | 0.80 | 0.80 |
| fibra | 0.35 | 0.95 | 0.65 | 0.65 |
| hierro | 1.30 | 1.10 | 1.20 | 1.20 |
| cobre | 0.80 | 1.20 | 1.00 | 1.00 |
| bronce | 1.50 | 1.20 | 1.35 | 1.35 |
| **acero** (M1, O1-B) | 1.80 | 0.90 | 1.35 | — (nuevo) |

Con estos números ilustrativos (eficacia = suma ponderada):

| Forma | Acero | Bronce | Mejor |
|---|---|---|---|
| espada (0.6/0.4) | 1.44 | 1.38 | **acero** |
| escudo (0.2/0.8) | 1.08 | 1.26 | **bronce** |
| casco (0.3/0.7) | 1.17 | 1.29 | **bronce** |
| torso (0.2/0.8) | 1.08 | 1.26 | **bronce** |

Es decir: el acero gana en espada y el bronce en escudo y armaduras. **Ninguno domina.**

**Aviso honesto [C/I]:** con estos mismos números ilustrativos el bronce (1.5/1.2) supera al hierro (1.3/1.1) y al cobre (0.8/1.2) en dureza y no pierde en tenacidad, es decir, **los domina en todo** salvo coste y acceso (el bronce exige cobre y estaño de fuera del valle). Las cifras de M0 son un punto de partida y deben recalibrarse; el criterio de §5.5 distingue qué dominios son aceptables.

### 5.4 Efecto de O1-B en el plan

El acero **no corrige** la jerarquía hierro < bronce con un material «mejor»; añade una **alternativa con otro perfil** y un coste distinto (carbón vegetal + hierro + saber `proc:acero`). El hierro conserva su papel de metal local y asequible.

### 5.5 Pruebas de las propiedades

1. **Equivalencia de partida (M0):** con pesos 0.5/0.5, la eficacia derivada coincide con el `potencia` actual en los 6 materiales.
2. **Validez (M0):** 7 formas × materiales ⇒ estadísticas finitas y no negativas.
3. **No dominancia acero–bronce (M1, O1-B):** existe al menos una forma donde el acero es estrictamente mejor y al menos una donde lo es el bronce, con los valores reales de `reglas`.
4. **Informe de dominancia (informativo):** tabla de dominancia por forma entre todos los materiales para revisión humana. Un material que domina a otro **con coste o acceso comparable** es un defecto de balance; si el coste/acceso lo justifica (bronce frente a cobre), se anota. Este informe **no hace fallar** el test.

---

## 6. Fuentes, procesos, usos y dependencias de lo ausente

Regla aplicada: **ningún recurso entra sin fuente, proceso, consumidor y dependencias identificados.**

### 6.1 Candidatos con razón jugable

| Recurso | Fuente | Proceso | Uso (consumidor) | Dependencias | Veredicto |
|---|---|---|---|---|---|
| **Carbón vegetal** | Ninguna nueva: se obtiene de `madera` | Receta `carbon` en horno (3 madera → 1–2 carbón, con pérdida; cifras a calibrar) | Ingrediente de acero; combustible alternativo | Receta en `catalogos.gd`; valor en `datos/autonomia/reglas.json` (**en edición**) | **M1** |
| **Acero** (proceso) | Hierro + carbón vegetal | Receta `lingote_acero` en horno: `lingote_hierro` + `carbon`; hab. artesano; saber `proc:acero` | Material de gramática con perfil duro y menos tenaz (§5.3) | M0, K1, carbón | **M1** |
| **Templado** | Pieza metálica + calor | **Operador** (no ítem): sube dureza, baja tenacidad; consume carbón | Compromiso real gracias a M0 | M0, M1, I1a | **I2** |
| **Cuero** | **Botín de criaturas existentes** (§6.2) | Crudo → curtido en una estación (mesa o nueva) | Sustituto del «tejido» en las 5 formas de armadura, con más tenacidad y más densidad | M0, decisión O8 (acceso de NPC) | **M2** |
| **Madera dura** | Árboles de otra especie por bioma | Ninguno | Más dureza y densidad que la madera | Cambio de generación (`terreno_v3`) | **M3, diferida (O6-A)** |

### 6.2 Cuero y fauna (O3)

**[C]** `datos/fauna/reglas_v1.json` solo mapea bioma → enemigo. `ENEMIGOS` contiene: espectro del bosque (`fibra`), gólem de la sierra (`piedra`), diablillo del secano (`arcilla`), arpía de pradera (`fibra`), slime de ribera y slime (`gelatina`), y dos jefes: Guardián de las Ruinas (`gema`) y **Gran Ciervo del Claro** (`gema` + `fibra`, reaparece a las 72 h). No hay fauna pasiva, caza ni ganado.

**Decisión confirmada:** el cuero crudo sale de **criaturas existentes mediante botines coherentes con cada criatura**. No se añade fauna nueva. **No se fijan ahora probabilidades, cantidades ni tiempos de reaparición**: son parámetros de balance de M2.

**Candidatas de partida [P, sujeto a revisión]:** Gran Ciervo del Claro (el más coherente), arpía de pradera y diablillo del secano. Espectro, gólem y slimes no tendrían cuero.

**Restricción técnica [C]:** los botines de `ENEMIGOS` son **fijos** (`def.drops`). Un botín ocasional exigiría un cambio pequeño en `combate.gd`. Esto se decide en M2, no ahora.

**Verificación pedida: cómo pueden obtener cuero los NPC [C, §2].** Hoy **no pueden** por su cuenta: no combaten ni recogen botines, y el botín solo llega al jugador. Opciones **[P]**:

| Opción | Descripción | Autonomía NPC | Coste / riesgo |
|---|---|---|---|
| **A. Suministro del jugador** | El jugador entrega cuero a los NPC (`peticion`, `dar`, ofrecer). Si no hay, el NPC usa tejido: **nunca se bloquea**. | Baja: depende del jugador | Mínimo; no toca archivos concurrentes |
| **B. Despojos como objeto del mundo** | Al morir una criatura deja un objeto recolectable con cuero (los `OBJETOS` ya admiten `prob` y regeneración); los NPC lo recogen con `_recolectar`. | Media: sigue requiriendo que la criatura muera | Pequeño; nuevo tipo de objeto y arte mínimo |
| **C. NPC cazadores** | Guardias/exploradores atacan criaturas cercanas y obtienen el botín. | Alta | **Alto**: comportamiento nuevo en `sociedad.gd`/`autonomia.gd` (concurrentes) y combate de NPC |
| **D. Suministro externo** | Viajeros o asentamientos traen cuero (`viajero071.gd`, `asentamientos.gd`) | Media | Por investigar [V] |

**Recomendación [P] (decisión abierta O8):** A como suelo obligatorio, evaluar B antes que C. C se considera una mejora posterior ligada a la profesión de guardia, no un requisito de M2.

### 6.3 Resto de ausentes: por qué no entran todavía

| Recurso | Fuente posible | Consumidor | Veredicto |
|---|---|---|---|
| Hueso | Botín de criaturas (no existe) | Ninguno claro | **Excluido** |
| Tendón | Botín de criaturas | Solo arcos/compuestos; **no hay armas a distancia** | **Excluido** |
| Cerámica / recipientes | Arcilla (existe) | Ninguno: no hay líquidos ni almacenaje; `ladrillo` ya cubre «arcilla cocida» | **Excluido** |
| Plata, oro | Vetas nuevas (cambio de generación) | Solo valor de intercambio | **Excluido** |
| Granito, caliza | Rocas por bioma | Construcción más resistente; **no hay daño a estructuras** | **Excluido** |
| Carbón mineral, azufre | Vetas nuevas | Ninguno | **Excluido** |
| Sal | Salinas | Conservación: **no hay deterioro de alimentos** | **Excluido** |
| Lino, cáñamo, algodón | Cultivos distintos | Cuerdas/telas: no hay formas que las distingan | **Excluido** |
| Cuarzo, resina | Vetas / árboles | Compuestos: solo si un operador de unión lo justifica | **Excluido** |
| Madera flexible | Árboles | Arcos: inexistentes | **Excluido** |

De 17 ausentes: **3 se planifican** (carbón, acero, cuero), **1 se difiere** (madera dura), **1 es operador** (templado) y **12 quedan excluidos con motivo escrito**.

---

## 7. Versionado y reproducibilidad

El objetivo: **que la falta de compatibilidad no signifique perder trazabilidad.** Sin migradores, el riesgo es cargar un mundo con reglas distintas sin saberlo.

### 7.1 Política para la etapa de desarrollo [P]

1. **Edición en sitio.** Mientras no exista sellado (§7.5), `reglas_*.json` y `catalogos.gd` se editan directamente. No se escriben migradores nuevos.
2. **Un lector por gramática, con una excepción transitoria.** Si cambia la *sintaxis* de una clave, cambia el prefijo y se elimina el lector anterior. La única excepción es I1a: `art1:`/`mat1:` y `art2:` conviven **hasta I1a-R** (§4.4) porque la prueba de equivalencia necesita ambos. Si I1a-R no se cumple, `art1:`/`mat1:` permanecen y la política se revisa.
3. **`version` en cada archivo de reglas** (entero). Se incrementa cuando cambia el resultado de `info()` o la validez de alguna clave.
4. **Estructura persistida.** `guardado.FORMATO` se incrementa cuando cambia el esquema (p. ej. `desarrollo.version` 1→2).
5. **Generación de mundo.** Un cambio de fuentes de recursos crea `terreno_v3` y sube `generacion.version` (mecanismo existente).

### 7.2 Huella canónica de reglas (aprobada)

- **Qué es.** Un hash SHA-256 de una cadena canónica construida con: los `version` de cada archivo, la `EVALUADOR_VERSION` (§7.3), el contenido de `reglas_*.json` y `saberes_*.json` con **claves ordenadas y números normalizados**, y las constantes relevantes de `catalogos.gd` (`ITEMS`, `RECETAS`, `OBJETOS`, `ENEMIGOS` con botines) serializadas con claves ordenadas.
- **Dónde se guarda.** En el mundo, junto a `generacion.version`: la huella completa y la lista de versiones que la componen (esto último para diagnosticar qué cambió).
- **Comprobación al cargar.** Si la huella del mundo difiere de la actual, **la carga se rechaza** con un mensaje que indica qué versiones difieren («mundo creado con reglas anteriores»).
- **Excepción explícita para desarrollo.** Un indicador de arranque deliberado (por ejemplo, un argumento de línea de comandos documentado) permite cargar igualmente. Al hacerlo, el estado registra un **aviso persistente** («cargado con reglas distintas») para que no se confunda con un mundo limpio. **El servidor no acepta esta excepción en modo normal.**
- **Red [P, V].** El cliente y el servidor deben comparar huella en el saludo; si difieren, la unión se rechaza. Evita que la UI del cliente (que calcula `planos()` sobre la réplica) use reglas distintas a las del servidor. **[V]** Si ya existe un saludo con versión en `red_servidor.gd`/`red_cliente.gd`.
- **Implementación [V].** Verificar la API de hash en Godot 4.7 contra `docs/engine-reference/godot/` antes de implementar.

### 7.3 Versión del evaluador (aprobada)

- **Qué es.** Una constante entera `EVALUADOR_VERSION` en `artesania.gd` (y en cualquier evaluador futuro de desarrollo) que identifica la **interpretación** de las reglas: fórmulas, orden de operaciones, redondeos, derivación de estadísticas, canonicalización de claves y validación.
- **Cuándo se incrementa.** Siempre que cambie la interpretación **aunque los JSON no cambien**. Ejemplo: cambiar `roundi` por `floori` en `info()`, alterar cómo se combinan los pesos de forma, o reordenar la resolución de empates.
- **Dónde se usa.** Forma parte de la huella (§7.2), se guarda con el mundo y se registra en el test dorado.
- **Propósito.** Detectar el caso en que el dorado y la huella de datos coinciden pero el comportamiento ha cambiado. Si el dorado falla con la misma huella de datos, la causa es el evaluador: el mensaje de error lo indica.

### 7.4 Reproducibilidad [P]

- **Test dorado.** Un archivo fijo de claves canónicas con su `info()` y `receta()` esperados, junto con `EVALUADOR_VERSION` y las versiones de reglas con las que se generó. Cambia solo mediante un commit que explica por qué.
- **Azar.** Siempre mediante `j._rng(contexto, clave)` con clave estable (`actor:saber:intento`), como ya hace `sociedad._azar` **[C]**. Los resultados confirmados **se persisten**; al cargar no se vuelven a tirar. No se depende del algoritmo interno del RNG de Godot entre versiones (PRECEDENTES, apartado de determinismo).
- **Estado canónico.** Misma semilla + mismas intenciones → mismo estado de `desarrollo` (serialización con claves ordenadas).
- **Orden de iteración.** Los desempates de candidatos usan clave ordenada o cursor rotativo persistido, nunca el orden de inserción de un `Dictionary`.

### 7.5 Sellado de reglas (O7-A con requisitos)

Se **sella** cuando se cumplan, en este orden:

1. **I1a está estable:** la clave `art2:` ya no cambia de sintaxis y I1a-R se resolvió (retirada hecha o laminados conservados de forma definitiva).
2. **Antes del primer playtest externo.** Es un requisito duro: no se entrega una build externa con reglas sin sellar.

Al sellar: se registra la huella en la documentación; se congelan los archivos de reglas; **a partir de ese momento las migraciones son obligatorias** y cada cambio de esquema o de regla incluye su migrador y su prueba.

---

## 8. Arquitectura unificada

### 8.1 Cuatro capas, cuatro conceptos distintos

| Capa | Qué es | Dónde vive | Cómo crece |
|---|---|---|---|
| **Sustancia** | Ítem apilable con fuente o proceso | `ITEMS` / `OBJETOS` / `RECETAS` | Solo con consumidor (§6) |
| **Propiedades** | Dureza, tenacidad, densidad de una sustancia usable en la gramática | `reglas` (materiales) | Una columna por consumidor nuevo |
| **Técnica / proceso** | Cómo se transforma o se trabaja | `reglas` (técnicas) y procesos | Descubrimiento (K2) o invención (I1) |
| **Diseño** | `forma` + `material` + composición + técnica + calidad | Clave `art*:` | Se deriva de las capas anteriores; no se registra en catálogo |

La **variación de composición** (proporción, refuerzo, templado) es un **parámetro del diseño**, no una sustancia. La **autoría y la historia** viven en un registro de conocimiento aparte; no forman parte de la clave del objeto (D06).

### 8.2 Un solo flujo

```
catalogos.gd (sustancias, fuentes, recetas)  ──┐
reglas (propiedades, formas, técnicas, ops)  ──┼─►  artesania.gd  ──►  info()/receta()/visible()
saberes (qué se puede saber, prerrequisitos) ──┘            ▲
                                                             │  huella + EVALUADOR_VERSION
desarrollo.gd: estado por actor (práctica, materiales vistos, saberes, investigación, historia)
      │  sabe / puede / candidatos / enseñar / experimentar
      ▼
fabricar (jugador, vía servidor) · decidir (NPC, vía ocupación «desarrollo») · Inv.cambiar · estaciones
```

### 8.3 Procesos = receta + metadatos (sin duplicar)

Un proceso **referencia** la receta de `C.RECETAS` y añade solo lo que falta: `saber` requerido, `descubrible` (bool), `intermedio` (bool). Las recetas nuevas (carbón, acero) se escriben en `catalogos.gd` como las demás. `autonomia.descubrir_recetas` (desbloqueo inmediato por ver un ítem) **se deja como está**; `desarrollo` gestiona la gramática y los procesos con saber. La frontera queda escrita aquí para no reimplementar uno dentro del otro.

---

## 9. Descubrimiento, variante fabricable e invención

### 9.1 Tres capacidades distintas

| | **Descubrimiento** | **Variante fabricable** | **Invención autónoma** |
|---|---|---|---|
| Quién | NPC o jugador | **Jugador** (también NPC si ya sabe el operador) | **NPC**, por sí solo |
| Qué es | Adquirir una posibilidad **ya definida en datos** (técnica, proceso, dominio). | Fabricar una pieza combinando **operadores que ya conoce**. | Producir por iniciativa propia una variante **no enumerada en ningún JSON**. |
| Espacio | Finito, enumerable, se agota | Grande pero acotado por operadores × niveles | Ídem, recorrido por búsqueda del NPC |
| ¿Demuestra innovación emergente? | No | **No** | **Sí, si cumple E1–E6** |
| Fase | K2 | **I1a** | **I1b** |

### 9.2 Cuándo se puede afirmar «innovación emergente» (E1–E6)

I1a demuestra que **el mecanismo de operadores funciona**, no que el mundo innove. Solo se afirma innovación emergente cuando, en I1b, se cumplan **todos**:

| ID | Criterio |
|---|---|
| E1 | La inicia un NPC **sin intención del jugador** y sin script que la ordene. |
| E2 | Responde a **motivo y capacidad** registrados (necesidad del grupo, material disponible, mejora propia…), no a un orden fijo. |
| E3 | El resultado es una **variante no escrita individualmente** en ningún JSON y no fabricada antes por ese actor. |
| E4 | Queda registrada con **autor y minuto**, de forma persistente y dentro de los topes de §9.5. |
| E5 | Es **reproducible**: misma semilla e intenciones ⇒ misma variante. |
| E6 | **Otros actores pueden conocerla** por enseñanza u observación (K1); no queda cerrada en su inventor. |

### 9.3 Qué es un operador [P]

Parámetro discreto con **ventaja y desventaja declaradas**, coste de insumo/estación/tiempo y un **presupuesto** que acota el beneficio total. Las estadísticas se **calculan** con una fórmula (propiedades de M0 + efectos de operadores); no se leen de una tabla. Un operador es un saber (`op:<id>`) que se descubre, se enseña y se siembra como cualquier otro.

| Operador | Fase | Niveles | Ventaja | Desventaja | Requiere |
|---|---|---|---|---|---|
| Refuerzo (sustituye a laminados) | I1a | ninguno / madera / piedra / fibra | Según la propiedad del refuerzo | Coste de insumo y peso | M0 |
| Grosor | I1a | fino / normal / grueso | Fino: ligero; grueso: resistente | Fino: frágil; grueso: lento y caro | M0 |
| Templado | I2 | 0 / 1 / 2 | + dureza | − tenacidad, consumo de carbón, desgaste de horno | M0, M1 |
| Proporción de aleación | diferido | 3 niveles | Dureza o tenacidad | La otra | Genera ítems por nivel; ver §9.6 |

**Decisión de diseño interna a I1a:** las técnicas `ligera` y `reforzada` hoy añaden fibra o piedra, igual que un refuerzo. I1a debe resolver el solapamiento. Opción recomendada: las técnicas pasan a ser procedimientos (rango, suelo, multiplicadores) y el insumo lo aporta el operador de refuerzo.

### 9.4 Evitar que el descubrimiento se agote: saberes de dominio (aprobado)

Con los laminados retirados quedaban ~4 descubribles (2 técnicas + los procesos de M1). K2 incorpora el nivel **`dom:<técnica>:<forma>`** (ya reservado en PLAN_IMPLEMENTACION §3.1): saber aplicar una técnica a una forma concreta.

| Concepto | Cuenta |
|---|---|
| Técnicas no triviales | 2 (`ligera`, `reforzada`) |
| Formas | 7 |
| Saberes `dom:` | 14 |
| Procesos de M1 (`proc:`) | 2 (`carbon`, `acero`) |
| Operadores de I1a (`op:`) | 2 (`refuerzo`, `grosor`) |
| **Total inicial descubrible** | **~20**, sin materiales nuevos y sin contar los 9 `lam:` transitorios |

`sabe(actor, clave)` exige `tec:` o `dom:` según `exige` en `saberes_v1.json`; cambiar el nivel exigido no cambia el almacenamiento ni las firmas. **[V]** Habrá que comprobar en K2 que 14 saberes de dominio resultan significativos y no relleno; si no, se reduce el conjunto.

### 9.5 Cómo se mantiene acotado

- Presupuesto formal verificado con un test sobre **todo** el espacio de parámetros.
- Búsqueda local del NPC: un paso de parámetro por intento desde un diseño conocido, guiado por el motivo.
- Autoría completa solo de la **primera variante por (forma, material, operador)**; el resto, contador agregado; tope duro con política de expulsión explícita.

### 9.6 Aleaciones

El **bronce** sigue siendo una *sustancia* (receta 2:1, `intermedio: true`). Variar la proporción se difiere: crearía un ítem por nivel y tensionaría la regla «no miles de variantes». Si se acepta más adelante, se modela como parámetro de la clave del lingote.

---

## 10. Plan maestro por fases

**Escala de complejidad:** S (< 1 sesión), M (1–2), L (3–5), XL (> 5). Estimaciones gruesas.
**Perfil de pruebas:** coherente con el ritmo del proyecto, cada fase lleva **pocas pruebas, centradas en lo que se rompe en silencio**. Se amplía `tests/prueba_desarrollo.gd` (55 comprobaciones hoy). Las historias que cambian algo visible conservan una captura en `production/qa/evidence/` según la norma del proyecto. **No se ejecuta nada hasta que se indique.**

### Visión general

| Fase | Bloque | Nombre | Dep. | Complejidad | Archivos principales |
|---|---|---|---|---|---|
| F0 | — | Contrato y decisiones | — | S | Solo documentos (**cerrada con esta revisión**, salvo O8) |
| **H0** | Cimiento | Huella de reglas, versión del evaluador, test dorado | F0 | S–M | `artesania.gd`, `guardado.gd`, pruebas |
| K1 | Conocimiento | Saberes, autoría y enseñanza | H0 | L | `desarrollo.gd`, `saberes_v1.json`, `juego.gd`, `red_servidor.gd`, `escena.gd`* |
| M0 | Materiales | Propiedades v2 y pesos por forma | H0 | M | `artesania.gd`, `reglas`, test dorado |
| **I1a** | Invención | Variantes fabricables con operadores; retirada condicional de laminados (I1a-R) | M0, K1 | XL | `artesania.gd`, `equipo.gd`, inventario, UI, `reglas` |
| K2 | Conocimiento | Descubrimiento autónomo, con saberes de dominio | K1 | M | `desarrollo.gd` |
| **I1b** | Invención | Invención autónoma de NPC y autoría acotada | I1a, K2 | L | `desarrollo.gd`, UI |
| M1 | Materiales | Procesos (carbón, acero) y renombrado de ítems | M0, K1 | M | `catalogos.gd`, `reglas`, `saberes_v1.json`, `datos/autonomia/reglas.json`* |
| K3 | Conocimiento | Fallos, parciales y participación del jugador | K2 | L | `desarrollo.gd`, `juego.gd`, `red_servidor.gd`, `escena.gd`* |
| I2 | Invención | Operador de templado y ampliación de operadores | I1b, M1 | M | `reglas`, `artesania.gd` |
| M2 | Materiales | Cuero desde criaturas existentes | M0, M1, O8 | L | `catalogos.gd`, `combate.gd`, `reglas` |
| S1 | Consecuencias | Historia visible, derivadas del director, especialización | K1, K2 | M | `mundo_vivo.gd`*, datos, UI |
| M3 | Materiales | Madera dura (generación v3) | M0, evidencia O6 | L | **Diferida** |

\* = archivo con cambios concurrentes; ver §12.

### F0 — Contrato y decisiones

Cerrada con las decisiones O1–O7 de esta revisión. Queda abierta **O8** (acceso de NPC al cuero), que no bloquea H0 a I2 y solo condiciona a M2.

### H0 — Cimiento de reproducibilidad (S–M)

**Objetivo.** Que ninguna fase posterior pueda cambiar reglas sin dejar rastro ni cargar un mundo con reglas distintas sin saberlo.
**Contenido.** `EVALUADOR_VERSION`; función de huella canónica (§7.2); registro de versiones y huella en el mundo; comprobación al cargar con excepción explícita de desarrollo; test dorado inicial de las 6 materiales × formas × técnicas actuales (**línea base antes de cualquier cambio**); comparación de huella en el saludo de red si ya existe un saludo con versión **[V]**.
**Dependencias.** F0.
**Archivos.** `artesania.gd`, `guardado.gd`, `tests/` (+ red si procede). **Ninguno de los archivos concurrentes.**
**Pruebas mínimas.** (1) La huella es estable entre dos ejecuciones y no depende del orden de claves; (2) cambiar un número de `reglas` cambia la huella; (3) cambiar `EVALUADOR_VERSION` cambia la huella y falla el dorado con mensaje que lo indica; (4) cargar un mundo con huella distinta se rechaza, y con el indicador explícito se carga dejando aviso.
**Aceptación.** Los cuatro puntos anteriores pasan y el dorado inicial documenta el estado actual.
**Fuera de alcance.** Cualquier cambio de reglas o de gramática.

#### Estado de H0 (2026-10-25) — implementada; commit `70d7b5f`

Solo se consignan resultados de ejecuciones reales de esta sesión (motor Godot 4.7.1 del proyecto, `--headless`).

**Archivos.** Nuevos: `scripts/huella.gd`, `tests/prueba_reglas.gd`, `tests/dorados/artesania_v1.json`. Modificados: `scripts/artesania.gd` (+3 líneas: `EVALUADOR_VERSION := 1`), `scripts/guardado.gd`. No se tocó ningún archivo con cambios concurrentes.

**Qué hace.**
- `huella.gd`: texto canónico (claves ordenadas, números normalizados, tipos no previstos visibles), hash por componente y huella total SHA-256. Componentes: `desarrollo` (`reglas_v1.json`, `saberes_v1.json` si existe), `autonomia`, `asentamientos`, `fauna`, `equipo` (arquetipos, familias, joyas, variantes), `catalogos` (20 constantes de `catalogos.gd` con efecto jugable) y `evaluador`. Excluidos a propósito: `equipo/paletas.json` (solo color), `ANIM_PJ`, `DIALOGOS` y `datos/mundo` (narrativa del director).
- `guardado.gd`: el mundo se sella al guardarse (`reglas`: huella, evaluador, versiones, componentes, `contaminado`); `inspeccionar` distingue `ok`, `ok_con_excepcion`, `reglas_distintas`, `ilegible` e `invalido`; `cargar` rechaza sin escribir nada y no cae al respaldo si el principal es válido pero incompatible; `guardar` sobre un mundo incompatible lo conserva íntegro como `.incompatible`.
- Excepción de desarrollo: solo con compilación de depuración **y** el argumento de usuario `--aceptar-reglas-distintas` (tras `--`). El mundo cargado así queda marcado `contaminado`, conserva su huella de origen y sigue rechazándose sin la excepción.
- Dorado: 693 claves de fabricación (684 `art1:` + 9 `mat1:`), hash `92a60cf8b39e9ed5a3c64dc4f1a293101b3f2d43cd8d95eb7bad41ff41822e89`, más una muestra revisable por personas. Regenerar solo con `-- --generar-dorado` tras un cambio deliberado.

**Pruebas ejecutadas (resultados reales).**

| Prueba | Resultado |
|---|---|
| `tests/prueba_reglas.gd` (nueva) | 60 comprobaciones, 0 fallos, exit 0 |
| Mutación 1: `EVALUADOR_VERSION` 1→2 (revertida) | 1 fallo, exit 1: el dorado detecta el desajuste de versión |
| Mutación 2: `roundi`→`floori` en `dmg` sin subir versión (revertida) | 2 fallos, exit 1: «cambió el comportamiento sin subir EVALUADOR_VERSION» |
| `tests/prueba.gd` (existente) | 327 PASS, 0 fallos, exit 0 |
| `tests/prueba_terreno.gd` | 49 PASS, 0 fallos, exit 0 |
| `tests/prueba_crecimiento.gd` | 27 PASS, 0 fallos, exit 0 |
| `tests/prueba_desarrollo.gd` | Árbol compartido, dos ejecuciones: 57 comprobaciones, **1 fallo** («los prototipos también desgastan la mesa utilizada»), con H0 y con `guardado.gd`/`artesania.gd` devueltos a `HEAD` (resultado idéntico). Después, sobre **copias temporales independientes** del árbol (misma instantánea; una con H0 y otra con esos dos archivos en `HEAD`): **57 PASS, 0 fallos en ambas**. Conclusión: el fallo no pertenece a H0; dependía del estado del trabajo concurrente en `desarrollo.gd`/`prueba_desarrollo.gd` en ese momento. No se determinó si esa otra sesión lo corrigió o si la prueba es intermitente. |
| Copias aisladas, con H0 / sin H0 | `prueba_autonomia` 33 / 33 PASS; `prueba_sociedad` 48 / 48 PASS; `prueba_red` 11 `[OK]` / 11 `[OK]`, sin fallos (exit 0 en todas). Resultados idénticos con y sin H0. |

Un primer diseño de `empaquetar` (sellar una copia) hizo fallar 2 comprobaciones de `prueba.gd` («guardar/cargar conserva todo el estado»); se corrigió sellando el propio diccionario del mundo, y la suite volvió a pasar completa.

**Cobertura de pruebas por requisito.** Huella determinista e independiente del orden de inserción; cambio de huella ante cambio de balance, de receta, de cada componente y del evaluador; cobertura de archivos (un JSON nuevo bajo `datos/` sin clasificar hace fallar la prueba); guardado/carga; incompatibilidad (componente distinto, evaluador distinto, sin huella, sin caída al respaldo, archivo intacto por SHA-256); excepción (apagada por defecto, marca persistente, no se «lava»); reproducción: dos mundos con la misma semilla y 180 minutos simulados dan el mismo estado canónico, y guardar→cargar lo conserva.

**Desviaciones respecto al plan.**
1. **Saludo de red no implementado.** `red_servidor.gd` y `red_cliente.gd` tienen cambios concurrentes de otra sesión (`VERSION := 6`, «saberes y enseñanza»). Verificado que existe un saludo con entero de versión; añadir la huella queda para la ventana coordinada de K1.
2. `empaquetar` deja el sello en el diccionario del mundo (no en una copia), para que mundo vivo y recargado coincidan.

**Limitaciones.**
- Los guardados anteriores a H0 no llevan huella y se rechazan (política aprobada); para abrirlos hace falta la excepción de desarrollo. Con el motor del proyecto: añadir `-- --aceptar-reglas-distintas` a los argumentos.
- La interfaz (`escena.gd`, con cambios concurrentes) sigue mostrando «No hay partida legible» ante un rechazo por reglas; el motivo real queda en `Guardado.cargar` (`error`, `motivo`) y en `push_warning`, pero aún no se muestra al jugador.
- La huella incluye `datos/autonomia/reglas.json` y `saberes_v1.json`, que otra sesión está editando: cualquier edición invalida los mundos de prueba existentes (es el comportamiento buscado, pero se notará a diario).
- La lógica escrita en código (fórmulas, generadores de terreno, sociedad) no se resume; se protege solo con `EVALUADOR_VERSION` y el dorado de artesanía.
- Los registros de la prueba incluyen líneas `ERROR: Parse JSON failed` provocadas a propósito al probar archivos corruptos. Las advertencias de instancias y recursos sin liberar al salir ya existían en las demás suites.
- No se midió el coste de calcular la huella (se calcula una vez por proceso y se cachea).

**Criterios de aceptación de H0.** Los cuatro puntos de «Pruebas mínimas» pasan (huella estable e independiente del orden; el cambio de un número de reglas la cambia; subir `EVALUADOR_VERSION` la cambia y rompe el dorado con mensaje explícito; un mundo con huella distinta se rechaza y con la excepción se carga dejando aviso) y el dorado documenta el estado actual: **cumplidos**. El único fallo observado en las suites existentes (`prueba_desarrollo.gd`) no pertenece a H0: es idéntico con y sin H0 y desaparece en una instantánea posterior del trabajo concurrente.

#### Alcance exacto de la huella y del dorado (H0)

Lo que **sí** protegen:
- **Huella.** Cambios en el contenido de los archivos de reglas listados (`desarrollo/reglas_v1.json`, `desarrollo/saberes_v1.json` si existe, `autonomia/reglas.json`, `asentamientos/reglas_v1.json`, `fauna/reglas_v1.json`, `equipo/{arquetipos,familias,joyas,variantes}.json`), en 20 constantes de `catalogos.gd` (`ITEMS`, `RECETAS`, `OBJETOS`, `CONSTR`, `ORDEN_CONSTR`, `ENEMIGOS`, `ATAQUES`, `PJ_ATAQUE`, `HAB`, `PASIVAS`, `MISIONES`, `RANURAS`, y las constantes numéricas de ritmo y de base) y en `EVALUADOR_VERSION`.
- **Dorado.** El resultado de `A.info()` y de `A.receta()` / `A.receta_material()` para las 693 claves de la gramática de artesanía (684 `art1:` y 9 `mat1:`) tal como se calcula con las reglas actuales.

Lo que **no** protegen (no debe afirmarse lo contrario):
- **Fórmulas y lógica escritas en código** fuera de `artesania.gd`: estadísticas del jugador y del equipo (`juego.gd`, `equipo.gd`), combate, sociedad, autonomía, arraigo, desarrollo, red. Un cambio ahí no altera la huella ni el dorado salvo que alguien suba `EVALUADOR_VERSION` por disciplina.
- **Generadores de terreno** (`terreno_v1.gd`, `terreno_v2.gd`, probabilidades por bioma en código): los versiona `generacion.version`, no la huella.
- **Datos excluidos a propósito:** `equipo/paletas.json` (solo color), `ANIM_PJ`, `DIALOGOS` y `datos/mundo/` (tarjetas narrativas del director).
- **Comportamiento de simulación:** el dorado no cubre economía, planificación de NPC ni decisiones; eso lo cubren las pruebas de cada sistema.
- **Intercambio por red:** hasta que se integre la comparación en el saludo (abajo), la huella no impide que un cliente use reglas distintas a las del servidor.

#### Integraciones pendientes de H0 — obligatorias antes del playtest multijugador externo

Aprobadas como pendientes el 2026-10-25. **No se implementan mientras `red_*.gd` y `escena.gd` estén en edición por otras sesiones.**

| ID | Pendiente | Archivos | Estado | Condición para empezar |
|---|---|---|---|---|
| P1 | Comparar la huella de reglas durante la conexión cliente-servidor: el cliente la envía en el saludo (`hola`) y el servidor rechaza con motivo explícito si no coincide. Existe un saludo con entero de versión (`Srv.VERSION`) [C]. | `red_servidor.gd`, `red_cliente.gd` | **Hecha el 2026-10-25 en la ventana de K1** (protocolo 7): `hola` lleva la huella; versión distinta se rechaza antes que huella; sin huella o con huella distinta se rechaza y se corta la conexión. Probado en `prueba_saberes` (con mutación que falla) y por red real en `prueba_red`. | — |
| P2 | Mostrar en la interfaz el motivo específico `reglas_distintas` cuando se rechaza un guardado, en vez de «No hay partida legible». `Guardado.cargar` ya devuelve `error`, `motivo`, `detalle` y `archivo`, pero `Juego.cargar` lo descarta al devolver `null`. | `escena.gd` y el punto de `juego.gd` que llama a `Guardado.cargar` | Pendiente | Ídem para `escena.gd` y `juego.gd` |

Sin P1 y P2 no debe distribuirse una build para un playtest multijugador externo. Ambos entran en la ventana coordinada de K1 si K1 ya está tocando esos archivos.

#### Incidencia registrada: fallo de `prueba_desarrollo.gd` («desgaste de la mesa») — explicada y corregida en la prueba

**No era intermitente: es determinista para un árbol dado** (dos ejecuciones idénticas sobre la misma copia dan el mismo resultado; con los archivos de K1 devueltos a `HEAD` sobre ese árbol, 55 comprobaciones y 1 fallo). La comprobación leía el desgaste de la mesa **al final** de 4.320 minutos; una reparación («Reparó la mesa antes de hacer un candado», minuto 3345) lo devuelve a 0 aunque el máximo durante la simulación fue 4. Cualquier cambio en la secuencia de decisiones lo cambia de lado. **Corrección (2026-10-25, solo en la prueba):** se mide el máximo durante la simulación en pasos de 60 minutos; la simulación es la misma. Verificada: con el código de `HEAD` pasa 55/0 (antes 55/1) y con K1 pasa 57/0.

### K1 — Saberes, autoría y enseñanza (L)

**Objetivo.** Los actores tienen saberes persistentes, separados de práctica y entorno, y pueden transmitirlos.
**Contenido.** Las cuatro consultas (`valido`, `sabe`, `puede`, `candidatos`); `saberes_v1.json`; almacén por actor; `historia` durable de primer descubridor y aprendices; enseñanza NPC↔NPC y jugador↔NPC validada en servidor; siembra sin autoría inventada. Subesquema `desarrollo.version = 2`. ~~`guardado.FORMATO` sube~~ **(requisito retirado el 2026-10-25 por decisión del usuario; ver «Estado de K1», punto 1)**. Los saberes `lam:` se incluyen como **transitorios**; la implementación no asume un número fijo de saberes.
**Dependencias.** H0.
**Pruebas mínimas.** (1) `sabe` sin taller ⇒ `puede` falso; (2) enseñanza NPC→NPC por proximidad, el resto no aprende; (3) intención de cliente con autor o saber manipulado ⇒ rechazada; (4) guardar/cargar sin duplicar aprendizaje ni pieza; (5) las 55 comprobaciones existentes siguen en verde.
**Aceptación.** A1–A8 del PLAN_IMPLEMENTACION §7, sin cambios.
**Fuera de alcance.** Descubrimiento autónomo, libros, olvido, secretos, comercio de conocimiento.

#### Estado de K1 (2026-10-25) — implementada con salvedades; commit `4141ae9`

Solo se consignan resultados de ejecuciones reales. Detalle de criterios y archivos en [PLAN_IMPLEMENTACION §19](PLAN_IMPLEMENTACION.md).

**Archivos.** Nuevos: `datos/desarrollo/saberes_v1.json`, `tests/prueba_saberes.gd`. Modificados: `scripts/desarrollo.gd`, `scripts/juego.gd`, `scripts/red_servidor.gd` (intenciones `ensenar_saber`/`pedir_saber`, huella en el saludo; `VERSION` 5→7), `scripts/red_cliente.gd`, `scripts/escena.gd` (panel «Saberes»), `tests/prueba_desarrollo.gd`, `tests/prueba.gd` (dos saludos de la prueba de red llevan ahora la huella); nuevos también `tests/captura_saberes.gd` y la evidencia `production/qa/evidence/saberes/`. No se tocaron `sociedad.gd`, `autonomia.gd`, `habitantes.gd`, `mundo_vivo.gd`, `artesania.gd`, `guardado.gd`, `reglas_v1.json` ni `huella.gd`.

**Aceptación A1–A8: cumplidos; núcleo aprobado por el usuario el 2026-10-25.** `prueba_saberes` 87 comprobaciones, 0 fallos (con M0 en el árbol). Verificados con mutaciones que fallan: confianza/reputación mínimas (vertical y jugador), alumno que hereda práctica (A4), historia que se borra al recortar creaciones (A5), servidor que acepta argumentos extra o saberes de longitud excesiva (A7). A1: `prueba_desarrollo` 57/0; dos comprobaciones nuevas y una reescrita por el cambio intencional (el rango ya no concede técnicas).

**Diferencias respecto a la definición de K1 de este plan.**
1. **`guardado.FORMATO` no sube — requisito retirado (2026-10-25).** Justificación y prueba: el contenedor conserva el formato 3 y su envoltura (`formato`, `checksum`, `cuerpo`); K1 solo añade datos dentro de `mundo_vivo.autonomia.desarrollo` (`version` 1→2, ampliada en `datos()`); H0 sella el mundo con una huella que incluye `saberes_v1.json`, así que un guardado anterior a K1 se rechaza antes de cualquier migración. Comprobado en `prueba_saberes` (9 comprobaciones; las mutaciones que desactivan la comprobación de huella las hacen fallar): un mundo con K1 se acepta; uno sellado antes de K1 (componente «desarrollo» sin `saberes_v1.json`, subesquema 1) se rechaza con `reglas_distintas` señalando «desarrollo» y el archivo queda intacto; con la excepción explícita se carga, queda marcado como contaminado, el subesquema pasa a 2 sin historia inventada y se conserva lo que el actor ya usaba. No existe necesidad técnica de subir `FORMATO`.
2. **UI hecha (2026-10-25).** `escena.gd` estaba sin cambios sin confirmar (tras el commit `89a7cd7`) y la sesión de rendimiento confirmó que no tenía cambios allí. Entrada «Saberes» en el taller y panel que ofrece «Pedir a X que te enseñe» y «Enseñar a X» con lo que cada uno sabe (calculado sobre datos replicados; decide el servidor); 25 líneas en `escena.gd`. Evidencia: `production/qa/evidence/saberes/` (taller, antes y después de una lección real con Maren) y `tests/captura_saberes.gd` (3 comprobaciones). Pendiente: P2 (motivo `reglas_distintas` en la UI).
3. **Huella en el saludo de red: hecha (P1)**, ver arriba. La UI de rechazo por reglas (P2) sigue pendiente. No forma parte de A1–A8.
4. **Lección con el jugador instantánea**; solo la enseñanza entre habitantes lleva 20 minutos.
5. **`valido(clave)`** (cuarta consulta) se añadió en el cierre; antes se usaba `artesania.leer` directamente.
6. **Réplica abierta**: el conocimiento de todos viaja a todos los clientes (limitación documentada, no capacidad).

**Fallo de «desgaste de la mesa» en `prueba_desarrollo`.** No es intermitente ni procede de K1: es una función determinista del árbol. Con el mismo árbol, dos ejecuciones dieron resultados idénticos; con los archivos de K1 devueltos a `HEAD` sobre el mismo árbol dio 55 comprobaciones y 1 fallo, igual que antes de tocar nada. Causa: la comprobación mira el desgaste de la mesa **al final** de 4.320 minutos, y una reparación (p. ej. «Reparó la mesa antes de hacer un candado», min 3345) lo devuelve a 0; en esa ejecución el desgaste máximo durante la simulación fue 4. K1 cambia la secuencia de decisiones y por eso el resultado final cambia. *Corregido en la prueba: ver «Incidencia registrada» más arriba.*

**Suites finales (copia estable del árbol con M0, UI y huella en el saludo; todas pasan, 0 fallos).** `prueba_saberes` 87, `prueba_desarrollo` 57, `prueba_sociedad` 48, `prueba_autonomia` 33, `prueba_arraigo` 76, `prueba_casas_arraigo` 3, `prueba_reglas` 72, `prueba_aspecto` 225, `prueba_ui` 13, `prueba_proteccion` 51, `prueba_terreno` 49, `prueba_fauna` 31, `prueba_orden_dibujo` 6, `prueba_caminos` 7, `prueba_campos_cultivo` 8, `prueba_casas` 13, `prueba_crecimiento` 27, `prueba_carga_crecimiento` 1, `prueba` 327, `prueba_red` 11 OK con clientes reales (protocolo 7), `prueba_terreno_red` y `prueba_crecimiento_red` PASS. Tras el cambio de `_ampliar` de la sesión de rendimiento se repitieron `prueba_saberes` (87) y `prueba_desarrollo` (57): sin fallos. Antes de las integraciones, `prueba_casas_arraigo` (de otra sesión) fallaba 3/3 también sin K1; ya pasa. Nota: `prueba_terreno_red` y `prueba_crecimiento_red` escriben su evidencia en una ruta relativa al repositorio; en una copia del árbol hay que crear `production/qa/evidence/{terreno,crecimiento}` junto a ella o parecen colgarse.

**Hito 1 (§11):** el juego registra y transmite conocimiento de forma persistente y autoritativa: **alcanzado**, con UI mínima y huella en el saludo.

### M0 — Propiedades v2 y pesos por forma (M)

**Objetivo.** Sustituir `potencia`/`vel` únicos por dureza, tenacidad y densidad con pesos por forma (§5).
**Contenido.** Columnas en `reglas`; pesos en `formas`; `artesania.info()` calcula eficacia ponderada; `version` de reglas y `EVALUADOR_VERSION` incrementados; dorado regenerado con commit explicativo.
**Dependencias.** H0. Independiente de K1; puede ir en paralelo (archivos distintos).
**Pruebas mínimas.** Las dos de §5.5 (equivalencia de partida y validez) y el informe informativo de dominancia.
**Aceptación.** Una espada de cobre y un escudo de cobre difieren en eficacia relativa de forma distinta que en hierro; el informe de dominancia existe y fue revisado.
**Fuera de alcance.** Resistencia térmica, elasticidad, durabilidad; laminados (siguen igual).
**Nota para O6.** El resultado de M0 es la evidencia que decide M3 (§M3).

#### Verificación de solapes de M0 (instantánea del 2026-10-25, ~17:37 hora local)

Estado: **coordinación, sin implementar.** Revisar de nuevo `git status` justo antes de empezar.

| Archivo | Papel en M0 | Estado actual | Solape |
|---|---|---|---|
| `scripts/artesania.gd` | Cálculo de eficacia ponderada; `info()`, `material()` | Solo con las 3 líneas de H0 (`EVALUADOR_VERSION`); sin edición ajena | **Ninguno conocido** |
| `datos/desarrollo/reglas_v1.json` | Columnas de dureza/tenacidad/densidad y pesos por forma; sube `version` | Sin modificar en git | **Ninguno conocido** |
| `tests/prueba_reglas.gd`, `tests/dorados/artesania_v1.json` | Dorado regenerado | Míos (H0) | Ninguno |
| `scripts/huella.gd` | Sin cambios previstos (la huella cambia sola) | Mío (H0) | Ninguno |
| `scripts/desarrollo.gd`, `tests/prueba_desarrollo.gd`, `tests/prueba_saberes.gd`, `datos/desarrollo/saberes_v1.json` | **No se tocan.** Solo consumen `A.material().formas/.nombre`, `A.leer_material`, `A.receta_material` | K1 en edición activa (modificados minutos antes de esta verificación) | **Contrato a respetar**, sin edición |
| `scripts/equipo.gd`, `scripts/escena.gd`, `scripts/sociedad.gd` | **No se tocan.** Consumen `A.info()` (claves `n, pila, equipo, dmg, def, hp, vel, c, artesania`), `combinaciones()`, `receta_material()` | `escena.gd` y `sociedad.gd` con cambios ajenos | **Contrato a respetar**, sin edición |
| `datos/autonomia/reglas.json`, `red_*.gd`, `juego.gd`, `guardado.gd`, `arraigo.gd`, `habitat.gd`, `habitantes.gd`, `autonomia.gd` | No se tocan | Varios con cambios ajenos | Ninguno |

**[C]** Los campos que M0 sustituye (`potencia` y `vel` por material) los consume solo `artesania.gd` (búsqueda en `scripts/` y `tests/`). **Contrato que M0 conserva:** las claves de `A.material()` (`nombre`, `item`, `coste`, `formas`, `color`, `arquetipo`, `fuente`) y las de `A.info()` / `A.receta()` / `A.receta_material()`. Las pruebas existentes que tocan la gramática comprueban relaciones (por ejemplo `dmg > 5`, igualdad de estadísticas tras cargar), no cifras exactas de una pieza `art1:`; `prueba.gd` usa `espada_hierro` estática, no la gramática.

**Efectos colaterales inevitables de M0 (a comunicar a las demás sesiones):**
1. Cambia `reglas_v1.json` ⇒ cambia la huella de reglas: los guardados de prueba existentes se rechazan hasta reiniciar mundos o usar `-- --aceptar-reglas-distintas`.
2. Suben `EVALUADOR_VERSION` y `version` de las reglas; el dorado se regenera con un commit que lo explique.
3. **Cambio de balance deliberado:** los pesos por forma modifican las estadísticas de las piezas de la gramática. Las cifras de §5.3 son ilustrativas y no están calibradas; M0 debe fijarlas y documentarlas. El criterio de equivalencia con el `potencia` actual solo vale con pesos 0.5/0.5.
4. Los 9 laminados se conservan (O2): su eficacia se obtiene mezclando propiedades 85/15, igual que hoy.

**Condiciones para empezar:** (a) la sesión que desarrolla K1 confirma que no tocará `artesania.gd` ni `reglas_v1.json`; (b) `git status` sin cambios nuevos en esos dos archivos; (c) indicación expresa del usuario.

#### Estado de M0 (2026-10-25) — aprobada; commit `e0dc0dd`

Coordinación previa: la sesión de K1 confirmó por mensaje que no edita `artesania.gd`, `reglas_v1.json`, `prueba_reglas.gd`, `tests/dorados/` ni `huella.gd`; antes de editar se recomprobó `git status` (sin cambios ajenos en esos archivos). Solo se consignan resultados de ejecuciones reales de esta sesión.

**Qué cambió.** `datos/desarrollo/reglas_v1.json` (`version` 1→2): cada material pasa de `potencia`/`vel` a `dureza`, `tenacidad` y `densidad`; cada forma gana `pesos` (dureza/tenacidad, suman 1); nuevo bloque `propiedades` (`referencia_densidad` 1.0, `vel_por_densidad` 0.04); `laminados.peso_densidad` 0.5. `scripts/artesania.gd` (`EVALUADOR_VERSION` 1→2): `eficacia()` y `velocidad()` nuevas, `info()` y `material()` las usan, `validar()` comprueba propiedades y pesos. **No se tocó** ninguna técnica, coste, receta, calidad ni laminado (siguen siendo 9), y no se añadió ningún material, receta ni operador.

**Cálculo.** Eficacia de la pieza = peso_dureza·dureza + peso_tenacidad·tenacidad (pesos de la forma); luego se multiplica por la técnica y la calidad como antes. Velocidad = (1 − densidad)·0.04 + velocidad de la técnica. Los laminados mezclan dureza y tenacidad 85/15 y la densidad 50/50, igual que antes mezclaban potencia y velocidad.

**Propiedades finales** (unidades de juego, no magnitudes físicas; calibradas para que la media dureza/tenacidad y la velocidad coincidan con las anteriores a M0):

| Material | Dureza | Tenacidad | Densidad | Media (= potencia previa) | Vel. (= previa) |
|---|---|---|---|---|---|
| madera | 0.45 | 0.85 | 0.75 | 0.65 | +0.01 |
| piedra | 0.95 | 0.65 | 1.50 | 0.80 | −0.02 |
| fibra («tejido») | 0.30 | 1.00 | 0.50 | 0.65 | +0.02 |
| hierro | 1.25 | 1.15 | 1.25 | 1.20 | −0.01 |
| cobre | 0.75 | 1.25 | 1.00 | 1.00 | 0.00 |
| bronce | 1.60 | 1.10 | 1.25 | 1.35 | −0.01 |

| Forma | Peso dureza | Peso tenacidad |
|---|---|---|
| espada | 0.6 | 0.4 |
| escudo | 0.2 | 0.8 |
| casco, guantes, botas | 0.3 | 0.7 |
| torso, pantalones | 0.2 | 0.8 |

Los valores de material y de forma son una **primera asignación**, no un balance cerrado: se eligieron con perfiles plausibles (piedra dura y frágil, tejido blando y tenaz, cobre blando y tenaz, bronce duro) sujetos a la continuidad con el modelo anterior. Se ajustan jugando.

**Eficacia por forma (valor continuo, técnica sencilla; antes de M0 era la potencia):**

| Forma | madera | piedra | fibra | cobre | hierro | bronce |
|---|---|---|---|---|---|---|
| espada | 0.61 | 0.83 | — | 0.95 | 1.21 | 1.40 |
| escudo | 0.77 | 0.71 | — | 1.15 | 1.17 | 1.20 |
| casco, guantes, botas | — | — | 0.79 | 1.10 | 1.18 | 1.25 |
| torso, pantalones | — | — | 0.86 | 1.15 | 1.17 | 1.20 |
| *(potencia previa)* | 0.65 | 0.80 | 0.65 | 1.00 | 1.20 | 1.35 |

**Ejemplos comparativos de piezas** (`dmg`/`def`/`hp`, técnica sencilla; de 60 celdas material × forma × calidad 0 y 3 cambian 15; las demás no cambian):

| Pieza | Antes | Después |
|---|---|---|
| Espada de hierro, calidad 3 | 7 daño | 8 daño |
| Espada de bronce, calidad 3 | 8 daño | 9 daño |
| Escudo de madera, calidad 3 | 2 defensa | 3 defensa |
| Escudo de bronce, calidad 3 | 5 defensa | 4 defensa |
| Casco de tejido, calidad 0 | 1 def / 1 vida | 2 def / 2 vida |
| Torso de cobre, calidad 0 | 4 def / 4 vida | 5 def / 5 vida |
| Torso de bronce, calidad 3 | 7 def / 7 vida | 6 def / 6 vida |
| Pantalones de bronce, calidad 0 | 3 def / 3 vida | 2 def / 2 vida |

**Dominancias detectadas (registradas, no corregidas).** Criterio: en una forma, el material A tiene eficacia y velocidad ≥ las de B (con valores continuos) y mejor en alguna. Son 14 pares; el registro está fijado en `DOMINANCIAS_CONOCIDAS` de `tests/prueba_reglas.gd`, de modo que cualquier cambio obliga a actualizarlo conscientemente.

| Dominancia | Formas | Origen |
|---|---|---|
| bronce domina a hierro (misma velocidad, mayor eficacia; mismo coste de material) | las 7 | **Heredada**: ya ocurría con la potencia 1.35 frente a 1.20 |
| hierro, cobre y bronce dominan a piedra | espada y escudo (6 pares) | **Heredada** (potencia y velocidad previas) |
| **madera domina a piedra** | escudo | **Nueva por M0**: la tenacidad de la madera (0.85) supera a la de la piedra (0.65) y su velocidad es mayor |

No hay dominancia entre hierro y cobre (el cobre es más rápido) ni de los metales sobre el tejido en armadura (el tejido es más rápido). El orden entre materiales **sí cambia según la forma** (madera/piedra: la piedra es mejor espada y la madera mejor escudo), que es la diferenciación funcional que persigue M0. Las dominancias se leen junto al coste y el acceso al material (p. ej. el bronce exige cobre y estaño del exterior); decidir si alguna es un defecto de balance queda para una revisión jugada, no para M0.

**Hallazgo (limitación vigente 2): el redondeo a enteros recorta la diferenciación.** `dmg`, `def` y `hp` son enteros y las bases de las formas son pequeñas, así que muchas diferencias de eficacia desaparecen al redondear (por ejemplo, torso de cobre, hierro y bronce valen 5/5 en calidad 0; los guantes valen 1/1 en calidad 0 con cualquier metal). Las propiedades sí afectan a la estadística, pero con poca resolución. Afinarlo (escalar las bases de las formas o conservar decimales hasta el redondeo único de `Equipo.finales`) cambia contratos de equipo y queda fuera de M0.

**Limitaciones vigentes de M0 (aprobadas como tales el 2026-10-25; no se ajusta el balance ni se cambian los contratos de equipo hasta nueva decisión).**
1. **El bronce domina al hierro en las siete formas** (misma velocidad, mayor eficacia, mismo coste de material). Heredada de la potencia previa (1.35 frente a 1.20); M0 la conserva a propósito y no la corrige.
2. **El redondeo a enteros reduce la diferenciación entre materiales** (ver el hallazgo). Corregirlo implica escalar las bases de las formas o conservar decimales en `Equipo.finales`, es decir, tocar contratos de equipo.
3. **La densidad aún tiene que demostrar relevancia práctica en el juego.** Su único efecto es la velocidad de la pieza, de −0.02 a +0.02 por material (más la velocidad de la técnica, ±0.02) sobre un multiplicador de velocidad base de 1.0; no se ha medido su efecto jugado [I]. Si resulta imperceptible, hay que dotarla de otro consumidor (carga, fatiga) o retirarla del modelo.
4. **Los valores físicos son provisionales**: las propiedades de material, los pesos por forma y las unidades de densidad son una primera asignación calibrada para la continuidad con el modelo anterior, no un balance cerrado. Se ajustan jugando y cada ajuste exige subir `version` de reglas y regenerar el dorado.

**Pruebas ejecutadas (resultados reales).**

| Prueba | Resultado |
|---|---|
| `tests/prueba_reglas.gd` | 72 comprobaciones, 0 fallos, exit 0 |
| Copias aisladas del mismo árbol, **con M0 / sin M0**: `prueba_desarrollo` | 57 PASS / 57 PASS, 0 fallos |
| `prueba_saberes` (de K1) | 73 PASS / 73 PASS, 0 fallos |
| `prueba` | 327 PASS / 327 PASS, 0 fallos |
| `prueba_autonomia` | 33 PASS / 33 PASS, 0 fallos |
| `prueba_sociedad` | 48 PASS / 48 PASS, 0 fallos |

Las pruebas de M0 distinguen cambios deliberados de regresiones: (1) con pesos 0.5/0.5 cada material y cada laminado reproduce la potencia y la velocidad de antes; (2) dos hashes capturados con el código de H0 antes de editar —recetas y `info()` sin dmg/def/hp— demuestran que solo pudieron cambiar esas tres estadísticas; (3) el dorado, que exige subir `EVALUADOR_VERSION` o la `version` de reglas y regenerarlo; (4) triplicar la dureza de un material mejora más la espada que el escudo y triplicar la tenacidad hace lo contrario; (5) un material más denso hace la pieza más lenta; (6) el registro de dominancias. Se comprobó con mutaciones sobre una copia independiente que cada tipo de regresión se detecta: coste de forma modificado (3 fallos), dureza modificada sin subir versión (3), versión del evaluador subida sin regenerar el dorado (2) y pesos de forma modificados sin declararlo (1).

**Defecto de H0 corregido.** `Huella.versiones()` indexaba por nombre de archivo y tres archivos se llaman `reglas_v1.json`; los valores se pisaban entre sí (pasaba desapercibido porque los tres valían 1). Ahora la clave incluye la ruta (`desarrollo/reglas_v1`, `fauna/reglas_v1`, `asentamientos/reglas_v1`). La huella en sí no estaba afectada: se calcula sobre el contenido.

**Efectos para otras sesiones.** Cambia la huella de reglas: los guardados de prueba creados antes de M0 se rechazan salvo con `-- --aceptar-reglas-distintas`.

**Archivos de M0.** Modificados: `datos/desarrollo/reglas_v1.json`, `scripts/artesania.gd`, `scripts/huella.gd`, `tests/prueba_reglas.gd`, `tests/dorados/artesania_v1.json` (regenerado; hash `c4485701da43a1ab609fbec0301219ebd7a8d23fc2e528841084859dc70fbeb0`, 693 claves).

**Criterios de aceptación de M0.** (a) Una espada de cobre y un escudo de cobre difieren en eficacia relativa de forma distinta que en hierro: **cumplido** (cobre: 0.95 espada / 1.15 escudo; hierro: 1.21 / 1.17). (b) El informe de dominancia existe y se registró: **cumplido** (pendiente de su revisión por una persona). (c) Con pesos 0.5/0.5 la eficacia coincide con la potencia anterior en los 6 materiales y 9 laminados: **cumplido**. (d) Estadísticas finitas y no negativas: **cumplido**.

#### Línea base de coste de artesanía (medida el 2026-10-25, antes de I1a)

Micro-benchmark en copia aislada del árbol completo (Godot headless, 684 claves `art1:`): `A.leer` 11,7 µs, `A.info` 21 µs, `A.receta` 40 µs, `A.combinaciones()` 3,8 µs, `A.material` de un laminado 8,8 µs, `A.reglas()` en caché 0,16 µs por llamada; `Huella.huella()` cacheada 22 µs; `j.guardar` 4,75 ms (22 KB) y `Guardado.cargar` 0,68 ms tras un día simulado. **Consecuencia para I1a:** el coste por llamada es bajo, pero enumerar todas las claves de un espacio combinatorio en un tick no lo es (684 claves × leer+info+receta ≈ 50 ms; con operadores el espacio crece por el producto de niveles). `planos()` y la búsqueda de NPC de I1a **no deben enumerar el espacio completo**: partir de diseños conocidos y variar un parámetro por intento (§9.5). **Diagnóstico de las pausas (comunicado por la sesión de población, 2026-10-25):** en la ejecución de esa misma línea base un día simulado (semilla 123) dio tick p50 0,06 ms, p95 0,20 ms, p99 2,65 ms y máximo 4.942 ms; el origen es `sociedad._construir_cerca`, que hace unas 180 búsquedas de caminos por intento cuando un habitante está fuera del valle. Es un defecto **preexistente**, no atribuible a H0, M0 ni K1; la sesión de población tiene autorizada su corrección y sus pruebas. Este plan no investiga más el rendimiento. **I1a no se autoriza hasta que K1 cierre y la corrección esté verificada.**

#### Integración de I1a con K1 — acuerdos y propuestas (2026-10-25)

I1a **no está autorizada ni iniciada.** Se distingue lo que K1 ya confirmó por mensaje de lo que yo propuse y sigue **sin respuesta**.

**Acordado con la sesión de K1 (confirmado por ella).**
| Tema | Acuerdo |
|---|---|
| Propiedad de archivos durante M0 | K1 no edita `artesania.gd`, `datos/desarrollo/reglas_v1.json`, `tests/prueba_reglas.gd`, `tests/dorados/` ni `scripts/huella.gd`. Era un compromiso «mientras dure M0»: **debe renovarse para I1a.** |
| Archivos de K1 | `desarrollo.gd`, `juego.gd`, `red_servidor.gd`, `red_cliente.gd`, `tests/prueba_saberes.gd`, `tests/prueba_desarrollo.gd`, `datos/desarrollo/saberes_v1.json` (este último entra en la huella de reglas). |
| `PLAN_MAESTRO.md` | K1 solo añadirá el bloque «Estado de K1» dentro de §10 K1; no toca las secciones de H0, M0 ni I1a. |
| Valores que sus pruebas leen | `prueba_desarrollo` y `prueba_saberes` leen rangos de técnicas y costes de `reglas_v1.json`. M0 no los cambió; I1a no debe cambiarlos sin avisar. Si cambian, K1 ajusta sus pruebas. |

**Propuesto por I1a, pendiente de confirmación de K1 (sin respuesta al 2026-10-25).**
| Punto | Propuesta |
|---|---|
| Saberes `op:` | Bloque `operadores` en `saberes_v1.json` con la forma de `tecnicas`; id `op:<operador>`; `catalogo()` genérico por tipo; el nivel por defecto de un operador no exige saber. |
| Contrato de `A.leer` | Mantiene `forma`, `material`, `tecnica`, `calidad` y añade `ops` opcional; `saberes_exigidos(p)` lo lee y añade un `op:` por operador con nivel no por defecto. |
| Validación en servidor de `art2:` | Reutilizar `fabricar_artefacto(clave)`; `A.leer` rechaza lo no canónico, fuera de rango o de presupuesto; luego `sabe/puede` de K1; coste y estadísticas siempre calculados en servidor. Pendiente verificar el límite de 48 caracteres de red. |
| Contratos de `desarrollo.gd` a congelar | `valido`, `sabe`, `puede`, `conoce`, `candidatos`, `planos`, `fabricar`, `comprar`, `aprender`, `saberes_exigidos`, `catalogo`, `sembrar`, `refinar`/`conoce_laminado` y el esquema persistido; K1 indicará cuáles son públicos. |
| Responsables | I1a: `artesania.gd`, `reglas_v1.json`, `huella.gd`, `guardado.gd`, `prueba_reglas.gd`, dorados. K1: `desarrollo.gd`, `saberes_v1.json`, sus pruebas, `juego.gd`, `red_*.gd`. Interfaz de variantes y las integraciones P1 y P2 de H0 en **una sola ventana coordinada** tras el cierre de K1. |
| Laminados hasta I1a-R | No se modifica `mat1:`, `lam:`, `A.combinaciones()`, `receta_material` ni la siembra `lam:` de K1; `art1:` y `art2:` conviven; K1 no añade consumidores nuevos y comunica los que existan (hoy: `desarrollo.gd`, `sociedad.gd` ~1267, `escena.gd` ~468, `prueba_desarrollo.gd` ~85–98). En I1a-R cada `lam:` pasa a `op:refuerzo` mediante una tabla y las comprobaciones sobre `mat1:` se reescriben, no se borran. |
| Cierre de K1 | K1 confirma el estado real de sus criterios A1–A8 y registra su cierre en este documento y en `ESTADO.md` solo con resultados verificados. |

**Aprobado por el usuario (2026-10-25).** I1a no empieza ni K2; secuencia H0 → K1 y M0 → I1a → K2 → I1b; el núcleo de K1 (A1–A8) está cerrado; el requisito `guardado.FORMATO` de K1 está retirado; `_ampliar` (rendimiento) se coordina con la sesión de población/NPC, que no edita `desarrollo.gd` hasta recibir su propia autorización y avisará con el hash vigente.

**Posición de K1 sobre las propuestas de I1a.** Respuesta de la sesión de K1, registrada aquí porque el mensaje no pudo entregarse (la sesión de I1a ya no estaba disponible). **Ninguna de estas propuestas está implementada ni aprobada por el usuario.**

| Propuesta | Posición de K1 | Requiere implementar |
|---|---|---|
| Saberes `op:` en `saberes_v1.json` | Aceptada. | `catalogo()` hoy construye `tec:` y `lam:` de forma explícita: pasarlo a genérico por tipo; `validar_saberes()` hoy rechaza `exige` distinto de `tec`/`lam` y habría que admitir `op`. |
| `ops` opcional en `A.leer` y `saberes_exigidos(p)` | Aceptada. | `saberes_exigidos` leerá `p.get("ops",{})`. |
| Validación de `art2:` en servidor sin intención nueva | Aceptada. | Límite de red: `fabricar_artefacto` solo pasa por `_sig` (`MAX_TEXTO` = 48 por argumento; `art1:` llega a 40). Se propone un `MAX_CLAVE` de 64 aparte del texto libre y subir `Srv.VERSION`. |
| Congelar contratos de `desarrollo.gd` | Aceptada con la clasificación siguiente. | — |
| Reparto de archivos y una sola ventana coordinada | Aceptada; la ventana de K1 (UI, P1) ya se usó. | UI de selección de variante y P2 quedan para I1a. |
| Laminados hasta I1a-R | Aceptada. Consumidores de `lam:`/`mat1:` de K1: `_heredados`, `catalogo()`, `validar_saberes()`, `saberes_v1.json` (`inicial` de Maren y Ordal), `prueba_saberes.gd` y `prueba_desarrollo.gd` ~85–98. | — |

**Contratos de `desarrollo.gd` (estado real a 2026-10-25).**
| Clase | Elementos | Estado |
|---|---|---|
| Públicos (firma congelada), **implementados y probados** | `valido`, `sabe`, `puede`, `conoce`, `candidatos`, `prerrequisitos_ok`, `planos`, `fabricar`, `comprar`, `refinar`, `conoce_laminado`, `aprender`, `sembrar`, `saberes_exigidos`, `tiene_saber`, `catalogo`, `validar_saberes`, `leccion_jugador`, `decidir(nid)->bool`, `registrar`, `rango`, `observar`, `restaurar`, `estado`, `datos`, `activa`, `cfg` | Congelados salvo ampliación pedida antes de tocarlos |
| Internos | `_ensenar`, `_elegir_leccion`, `_motivo_no_ensena`, `_heredados`, `_iniciales`, `_laminado_ok`, `_saber_de`, `_pausar`, `_descansa`, `_celdas`, `_ampliar` (en revisión por rendimiento) | Pueden cambiar sin aviso |
| Esquema persistido (`desarrollo.version` 2) | `actores[a].saber{id:{fuente,min,de}}`, `actores[a].sembrado`, `historia{id:{primero,aprendices,total}}`, `lecciones`, `pausas` | Se pueden añadir claves opcionales; no cambiar las existentes |

**Condiciones para autorizar I1a (decisión del usuario):** (1) K1 confirma su cierre; (2) la corrección de rendimiento está verificada; (3) se revisa el alcance exacto de I1a con las respuestas de K1.

### I1a — Variantes fabricables con operadores (XL)

**Objetivo.** Que el **jugador** pueda fabricar variantes funcionales mediante operadores disponibles, sin que cada variante esté en JSON. **No afirma innovación emergente** (§9).
**Contenido.**
1. Gramática `art2:` con parámetros de composición, `reglas` de operadores (`refuerzo`, `grosor`) y presupuesto.
2. Evaluador que **calcula** estadísticas; `EVALUADOR_VERSION` incrementado.
3. Soporte en `artesania`, `equipo` (`existe/info`), `visible`, inventario y réplica; límite de longitud de clave en red resuelto (hoy 48 caracteres **[C]**).
4. Operadores como saberes `op:` (K1), con siembra.
5. Resolución del solapamiento técnicas↔refuerzo (§9.3).
6. UI mínima: ver el compromiso de la variante.
7. **I1a-R (retirada condicional).** Solo si R1–R4 (§4.4) se cumplen: eliminar `mat1:`, la receta de laminados, los saberes `lam:` y el lector `art1:`; reescribir las comprobaciones sobre `mat1:`. Si no se cumplen: los laminados permanecen y I1a se cierra igualmente.
**Dependencias.** M0 (propiedades) y K1 (saberes de operador).
**Complejidad.** XL; es la más cara del plan.
**Pruebas mínimas.** (1) Presupuesto verificado sobre **todo** el espacio de parámetros; (2) clave `art2:` canónica y rechazo de parámetros fuera de rango y de cliente que fije estadísticas; (3) una variante utilizable que no figura individualmente en ningún JSON; (4) enumeración de las 27 combinaciones (R1–R2) y prueba de saberes (R3); (5) dorado regenerado; (6) medición de bytes de réplica antes y después.
**Aceptación.** C1–C3 y C5–C6 del PLAN_IMPLEMENTACION §7 (nivel C) para el jugador; R1–R4 evaluadas con resultado escrito (cumplidas o no).
**Fuera de alcance.** Invención por NPC (I1b), templado (I2), proporción de aleación.

### K2 — Descubrimiento autónomo determinista, con saberes de dominio (M)

**Objetivo.** Un NPC descubre por sí mismo una posibilidad definida, por motivo y capacidad, y queda constancia.
**Contenido.** Investigación activa (una por actor), puntuación de candidatos, progreso entero, consumo real, enfriamiento, registro en `historia`, memoria y suceso, todo dentro de `desarrollo.decidir`. **Saberes de dominio `dom:`** y operadores `op:` como candidatos (§9.4).
**Dependencias.** K1.
**Pruebas mínimas.** (1) Misma semilla y mismas intenciones ⇒ mismo estado canónico (y misma huella); (2) guardar/cargar a mitad de investigación no repite gasto ni recompensa; (3) hambre/sueño desplazan el experimento; (4) sin motivo no se investiga aunque sea posible.
**Aceptación.** B1–B7 del PLAN_IMPLEMENTACION §7 (nivel B); además, el número de saberes descubribles supera claramente el de la versión sin dominio (§9.4).
**Fuera de alcance.** Fracaso probabilístico, variantes no escritas.

### I1b — Invención autónoma de NPC (L)

**Objetivo.** Que un NPC invente, por iniciativa y capacidad propias, una variante no enumerada, y que esto cumpla **E1–E6** (§9.2). Es el primer hito que puede llamarse **innovación emergente**.
**Contenido.** Búsqueda local del NPC desde un diseño conocido (un paso de parámetro por intento) guiada por motivo (§6 del PLAN_IMPLEMENTACION); competencia con otras necesidades; registro de autoría acotada (§9.5); enseñanza de la variante (K1); suceso/recuerdo; presentación legible en UI.
**Dependencias.** I1a y K2.
**Pruebas mínimas.** (1) Un NPC produce una variante no enumerada con motivo registrado y sin intención del jugador (E1–E3); (2) con la misma semilla produce la misma (E5); (3) la autoría queda en `historia` y no crece sin límite (E4); (4) otro NPC la aprende por enseñanza (E6); (5) un cliente no puede fijar parámetros ni éxito.
**Aceptación.** E1–E6 verificables en una simulación; informe de bytes de réplica y guardado.
**Fuera de alcance.** Efectos no previstos por operadores, mecánicas nuevas, IA generativa, secretos.

### M1 — Procesos y renombrado de ítems (M)

**Objetivo.** Primera transformación real (T1–T4 de §4.2): hierro → acero mediante carbón vegetal, con conocimiento propio; y resolver los nombres ambiguos de ítems (O5-B).
**Contenido.** Recetas `carbon` y `lingote_acero` en `catalogos.gd`; material `acero` en `reglas` con perfil de §5.3; metadatos de proceso; valores de ítem para NPC; **renombrado coordinado** `mena`→`mena_hierro`, `lingote`→`lingote_hierro`, `cobre`→`mena_cobre`, `estano`→`mena_estano` (§3.2).
**Dependencias.** M0, K1. **Requiere ventana coordinada** (§12).
**Pruebas mínimas.** (1) `carbon` consume y produce lo declarado; (2) un NPC sin `proc:acero` no fabrica acero; (3) no dominancia acero–bronce (§5.5.3); (4) el validador de referencias pasa con los IDs renombrados; (5) dorado y huella regenerados.
**Aceptación.** Ruta completa árbol → carbón → acero → pieza, ejecutable por jugador y por NPC bajo las mismas reglas; el acero es mejor en espada y el bronce en escudo y armaduras (O1-B).
**Fuera de alcance.** Tipos de horno, temperaturas, templado.

### K3 — Fallos, resultados parciales y participación del jugador (L)

**Objetivo.** Resultados de experimento variados (fracaso, defectuoso, parcial, funcional) y que el jugador experimente con las mismas reglas.
**Contenido.** Resultado decidido por `j._rng` con clave `(actor, saber, intento)`; contador persistido; «descubrimiento parcial» como progreso que reduce el umbral; UI de experimento con candidato y coste visibles; intención de servidor.
**Dependencias.** K2.
**Pruebas mínimas.** (1) El resultado de un intento no cambia al recargar; (2) un fallo consume lo declarado y suma aprendizaje parcial; (3) cliente no puede fijar el resultado.
**Aceptación.** Un NPC puede fallar y reintentar; solo se experimenta con `candidatos()`, nunca con combinaciones arbitrarias.

### I2 — Operadores adicionales (M)

**Objetivo.** Ampliar el espacio de invención con el **templado** (requiere carbón y dureza↔tenacidad).
**Dependencias.** I1b, M1.
**Pruebas mínimas.** Presupuesto verificado sobre el espacio ampliado; el templado tiene ventaja y desventaja comprobables.
**Aceptación.** Un NPC puede inventar una variante templada bajo E1–E6.

### M2 — Cuero desde criaturas existentes (L)

**Compuerta:** decisión **O8** (acceso de NPC). Parámetros de balance **sin fijar** (O3).
**Contenido.** Ítem `cuero_crudo`; botines coherentes en las criaturas elegidas (§6.2); proceso de curtido (`cuero`); material de gramática `cuero` para las 5 formas de armadura, con más tenacidad y más densidad que el tejido; si hace falta un botín ocasional, cambio pequeño en `combate.gd`; ruta de acceso de NPC según O8.
**Dependencias.** M0, M1.
**Pruebas mínimas.** Fuente → proceso → pieza; un NPC consigue o sustituye el cuero sin bloquearse (opción A como suelo).
**Aceptación.** El cuero ofrece un compromiso distinto del tejido y tiene fuente reproducible; ningún NPC queda bloqueado por la falta de cuero.

### S1 — Consecuencias (M)

Historia visible; variables derivadas para el director (consumidor, no decisor); especialización emergente con histéresis; tradiciones por grupo. Según PLAN_IMPLEMENTACION §7 (nivel D2). Edición de `mundo_vivo.gd` solo con coordinación.

### M3 — Madera dura (diferida, O6-A)

No se planifica. Se reabre cuando haya **evidencia** de que las propiedades físicas generan diferencias jugables: el informe de M0 más una prueba de juego breve donde se noten materiales de distinto perfil. Requeriría `terreno_v3`, nueva especie por bioma y arte; subiría `generacion.version`.

---

## 11. Hitos y dependencias

```
F0 ─► H0 ─┬─► K1 ──────────┬──────────────┐
          │                 │              │
          └─► M0 ───────────┴─► I1a ─┐     │
                                      ├──► I1b ─► I2
                       K1 ─► K2 ──────┘     ▲
                                            │
                       M0,K1 ─► M1 ─────────┘ (I2)
                                  └─► M2 (O8)
                       K2 ─► K3
                       K1,K2 ─► S1
                       M3 diferida (evidencia de M0)
Privacidad por cliente ─► secretos, comercio de conocimiento (fuera de este plan)
```

| Hito | Se alcanza al terminar | Qué se puede afirmar |
|---|---|---|
| **Hito 0** | H0 | Las reglas están versionadas y el juego se niega a mezclar versiones. |
| **Hito 1** | K1 | El juego registra y transmite conocimiento de forma persistente y autoritativa. **No** que los NPC descubran nada. |
| **Hito 2** | I1a | El jugador fabrica variantes funcionales con operadores. **No** hay innovación emergente. |
| **Hito 3** | K2 | Los NPC descubren por sí mismos posibilidades ya definidas. |
| **Hito 4** | I1b | **Innovación emergente** (E1–E6): un NPC inventa una variante no enumerada. |
| **Hito 5** | M1 | Hay una transformación real (carbón → acero) bajo reglas compartidas. |

Orden de implementación: **H0 → (K1 ∥ M0) → I1a → K2 → I1b → M1 → K3 → I2 → M2 → S1.** K1 y M0 pueden avanzar a la vez porque tocan archivos distintos. I1a no depende de K2, de modo que la invención del jugador aparece antes de agotar el descubrimiento. La invención deja de estar «después de un catálogo de cuatro saberes»: I1a es la cuarta fase y I1b la sexta.

---

## 12. Coordinación con cambios concurrentes

**[C]** `git status` (momento de redacción de la revisión 1) mostraba cambios sin confirmar en `datos/autonomia/reglas.json`, `autonomia.gd`, `escena.gd`, `habitantes.gd`, `habitat.gd`, `mundo_vivo.gd`, `sociedad.gd`, `tests/prueba.gd`, varias tarjetas de `datos/mundo/entities/`, `design/gdd/mundo-vivo.md`, y sin rastrear `arraigo.gd` y `tests/prueba_arraigo.gd`. **Debe volver a comprobarse antes de cada fase.**

| Archivo | Fases que lo necesitan | Regla |
|---|---|---|
| `sociedad.gd`, `autonomia.gd`, `habitantes.gd` | M1 (renombrado de IDs), I1a-R (referencia a `leer_material`) | **No tocar** salvo en ventana coordinada |
| `datos/autonomia/reglas.json` | M1 (valores de `carbon`, `lingote_acero`; renombrado) | **Pedir ventana** |
| `escena.gd` | K1, K3, I1a (UI de planos y de variante) | Pedir ventana; cambios mínimos y localizados |
| `mundo_vivo.gd` | S1 | Pedir ventana |
| `combate.gd` | M2 (botines) | Comprobar `git status` antes |
| `artesania.gd`, `guardado.gd`, `desarrollo.gd`, `catalogos.gd`, `reglas`, `saberes_v1.json`, `red_servidor.gd`, `juego.gd` | H0, K*, M*, I* | Sin conflicto conocido; verificar antes de cada fase |

Punto de control antes de cada fase: `git status`, comparar los hashes de COMPATIBILIDAD, confirmar con quien tiene los cambios concurrentes qué está consolidado. **No se empieza ninguna fase sin aviso.**

---

## 13. Evaluación crítica de componentes

### 13.1 Conservar

| Componente | Motivo |
|---|---|
| `inventario.gd` (`cambiar` atómico) | Transacción correcta y ya usada por jugador y NPC |
| `artesania.leer/clave/validar` (clave canónica, rechazo de no canónicas) | Base de seguridad en servidor; solo cambia el prefijo en I1a |
| Laminados `mat1:` (hasta I1a-R) | O2: no se pierde nada hasta demostrar equivalencia |
| Estaciones y desgaste | Coste real de experimentar |
| Rangos y práctica (`desarrollo.rango/registrar`) | Es la «habilidad» de la propuesta; K1 la separa del «saber» |
| `desarrollo.materiales()` (atlas) | Debe mostrar fuentes de los materiales nuevos |
| `guardado.gd` (checksum, respaldo) | Soporta el subesquema y la huella |
| `j._rng` / `sociedad._azar` | Azar determinista por clave |
| `autonomia.descubrir_recetas` | Recetas estáticas; fuera de este plan |
| Recetas `ladrillo` y `ladrillo_arcilla` | Ya dan uso real a piedra y arcilla |
| Servidor autoritativo y réplica | Toda la seguridad depende de ello |
| Nombres fantásticos heredados (O4) | Efectos numéricos compatibles |

### 13.2 Ampliar

| Componente | Cómo |
|---|---|
| `desarrollo.estado(actor)` | `saber`, `investigacion`, `leccion` |
| `desarrollo.decidir` | De «primer plano alfabético que sobra» a candidatos puntuados con motivo (K2) y búsqueda de variantes (I1b) |
| `reglas` de materiales | Propiedades y pesos por forma (M0); operadores y presupuesto (I1a) |
| `C.RECETAS` | Carbón y acero con metadatos de proceso (M1) |
| `red_servidor.ejecutar` | Intenciones validadas (enseñar, experimentar, fabricar variante) |
| `guardado.gd` | Huella y versiones (H0) |
| Pruebas | Extender `prueba_desarrollo.gd`; test dorado |

### 13.3 Rediseñar

| Componente | Problema | Rediseño |
|---|---|---|
| **Laminados `mat1:`** | Dominados, redundantes con técnicas, fallan T1/T4 | Operador de composición (I1a), retirada condicionada a R1–R4 |
| **`conoce`** | Mezcla saber, rango, material visto y superficie de taller | Cuatro consultas; `conoce` queda como envoltura |
| **`_creacion` (64 entradas)** | Recortado; no es registro de autoría | `historia` durable |
| **Propiedad única `potencia`** | Un material es «mejor» o «peor» en todo | Dureza/tenacidad/densidad con pesos por forma (M0) |
| **Técnicas `ligera`/`reforzada`** | Solapan con refuerzo | Procedimientos puros; el insumo lo aporta el operador (I1a) |
| **Nombres ambiguos de ítems** | `cobre` mena vs material | Renombrado en M1 (O5-B) |
| **«Descubrimiento» = fabricación** | `decidir` registra fabricaciones como descubrimientos | Distinguir `suceso("descubrimiento")` de `suceso("fabricacion")` |

### 13.4 Riesgos de fondo

- **Agotamiento del espacio de descubrimiento.** Mitigado por saberes de dominio (§9.4) y por adelantar I1a; la emergencia sostenida depende de I1b, I2 y M1.
- **Confundir I1a con innovación.** Mitigado por E1–E6 (§9.2) y por el Hito 4.
- **Balance sin jugar.** Pesos, costes y presupuestos son punto de partida; se ajustan jugando.
- **Réplica.** El estado cultural de todos viaja a todos los clientes; sin privacidad no hay secretos ni comercio de conocimiento.
- **Costo de I1a.** Toca artesanía, equipo, inventario, red y UI: la fase más cara y la más fácil de subestimar. Su retirada condicional (I1a-R) limita el riesgo de regresión.
- **Huella demasiado estricta.** Puede molestar en desarrollo; por eso existe la excepción explícita (§7.2).

---

## 14. Decisiones

### 14.1 Resueltas

Ver §1.3 (O1–O7 y aprobaciones adicionales).

### 14.2 Abierta

| ID | Decisión | Opciones | Recomendación [P] | Bloquea |
|---|---|---|---|---|
| **O8** | ¿Cómo obtienen cuero los NPC sin depender exclusivamente del jugador? | A. Suministro del jugador con sustitución por tejido; B. despojos como objeto del mundo; C. NPC cazadores; D. suministro externo | A como suelo, evaluar B antes que C (§6.2) | Solo M2 |

---

## 15. Pendiente de verificar

- **[V]** Si `sociedad.valor` / las tablas de `datos/autonomia/reglas.json` tienen valor por defecto para ítems no listados (condiciona cuánto toca M1 ese archivo).
- **[V]** Si ya existe un saludo con versión entre `red_cliente.gd` y `red_servidor.gd`, para comparar la huella (H0).
- **[V]** API de hash de Godot 4.7 contra `docs/engine-reference/godot/` (H0).
- **[V]** Longitud máxima real de claves en red (48 caracteres) frente a `art2:` (I1a).
- **[V]** Que 14 saberes de dominio resulten significativos y no relleno (K2).
- **[V]** Cómo calcula la réplica cliente `planos()` (heredado).
- **[V]** Coste real de añadir propiedades a `Eq.info` / `equipo.stats_de` (M0; no se leyó `equipo.gd` entero).
- **[V]** Opción D de O8 (`viajero071.gd`, `asentamientos.gd`).
- **[V]** Estado de consolidación de los cambios concurrentes.
- **[V]** Las cifras de §4.3 y §5.3 son cálculo manual; M0 debe confirmarlas con el test dorado.

---

## 16. Hoja de ruta breve

| Orden | Fase | Entrega | Depende de | Primer paso |
|---|---|---|---|---|
| 1 | **H0** | Huella, evaluador versionado, dorado | F0 | **Primer hito implementable** |
| 2 | K1 ∥ M0 | Saberes y enseñanza ∥ propiedades v2 | H0 | — |
| 3 | I1a | Variantes del jugador; retirada condicional de laminados | M0, K1 | — |
| 4 | K2 | Descubrimiento con saberes de dominio | K1 | — |
| 5 | I1b | **Innovación emergente** (E1–E6) | I1a, K2 | — |
| 6 | M1 | Carbón, acero, renombrado | M0, K1 | Ventana coordinada |
| 7 | K3, I2, M2, S1 | Fallos, templado, cuero, consecuencias | Ver §10 | O8 para M2 |
| — | M3 | Madera dura | Evidencia de M0 | Diferida |

**Primer hito implementable: H0.** Motivos: no depende de ninguna decisión pendiente, no toca ningún archivo con cambios concurrentes (`artesania.gd`, `guardado.gd`, pruebas), es pequeño, y crea la línea base (dorado) que necesitan M0 e I1a. Antes de empezar: `git status`, confirmación expresa de inicio y mostrar el alcance exacto de archivos.

Este documento es plan, no autorización de implementación.
