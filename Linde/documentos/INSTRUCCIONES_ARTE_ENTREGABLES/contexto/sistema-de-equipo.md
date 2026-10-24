# Sistema de equipo de Linde: familias, piedras, joyas y sets

> **Estado: PROPUESTA v1 SIMPLIFICADA** (decisiones cerradas por delegación del usuario, 2026-10-23). Pendiente de implementación.
> **Todos los números de este documento son PROVISIONALES** (economía y progresión numérica son A03, pendiente; el combate es A01, pendiente). Sirven para fijar la forma de las fórmulas, no el balance.
> **Es una expansión**, no parte del MVP de `design/game-brief.md` (7 ítems). Se plantea tras el paso 2 del *Build order* (combate cerrado) y es coherente con el paso 7 (multijugador).
> Inspiración conceptual: la idea de organizar el equipo por sets de piezas con mejora separada. No se copian nombres, tablas, probabilidades ni arte de ningún juego.
> Relacionado: `Linde/cenital/scripts/catalogos.gd`, `juego.gd`, `Linde/cenital/docs/DECISIONES.md` (sección «Equipo y defensa»), `Linde/documentos/instrucciones-recursos-arte.md`.

---

## Resumen

El equipo de Linde pasa de 3 ranuras planas a **familias de exactamente 5 piezas** (casco, torso, guantes, botas, pantalones) más el escudo. Cada pieza es una instancia con tres ejes independientes: la **familia** (arquetipo, potencia, origen, bono de set), la **variante** dada por una piedra incrustada (Divino, Brillante u Oscuro, con ventajas y desventajas) y el **nivel de mejora** `+0..+5` con la joya Chispa de Temple, que siempre sube la pieza. El **bono de set** lo da la familia con más piezas puestas (solo uno activo). Solo se tocan `hp`, `def` y `vel`; el estado de la pieza vive en la clave del ítem (`eq:familia:ranura:variante:nivel`), de modo que el inventario atómico actual no se reescribe. Se entra con la fórmula de defensa proporcional, tres familias de ejemplo (Vigía fabricable, Zarzal de farmeo, Albor de jefe repetible) y arte por 3 siluetas con colores índice recoloreados por paleta.

---

## 1. Lógica global

### 1.1 Cuatro ejes que no se mezclan

| Eje | Qué es | Dónde vive | Cambia con | Afecta a |
|---|---|---|---|---|
| **Familia** | Set de exactamente 5 piezas con nombre propio (Vigía, Zarzal, Albor). Define arquetipo, potencia, origen y bono de set. | Dato de catálogo | Nada (inmutable en una pieza) | Estadísticas base, silueta, bono de set |
| **Variante** | La piedra incrustada: Divino (Piedra de Alma), Brillante (Piedra de Armonía), Oscuro (Piedra de Bendición), o «sin piedra». | Instancia de pieza | Una piedra | Nombre, paleta y multiplicadores (ventajas **y** desventajas) |
| **Nivel de mejora** | `+0..+5` aplicado con joyas. | Instancia de pieza | Joya de mejora | Multiplicador de la pieza |
| **Bono de set** | Efecto por número de piezas **de la misma familia** equipadas. | Calculado al equipar | El equipo puesto | Estadísticas totales |

Regla de oro: **ningún eje se deduce de otro.** Una pieza de una familia rara puede estar sin piedra y en +0; una común puede estar en +5 con piedra. Rareza ≠ poder: la rareza es solo una etiqueta de *cómo se obtiene* (color del nombre en la UI) y no entra en ninguna fórmula.

### 1.2 Piezas y ranuras

- Ranuras de set (5): `casco`, `torso`, `guantes`, `botas`, `pantalones`.
- Ranuras de mano (fuera del set, no cuentan para el bono): `escudo` (ya existe) y el arma. El arma **sigue como hoy** (mejor `dmg` del inventario, sin ranura).
- Convención de nombre: «Casco de <Familia> <Variante> +N». Sin piedra: «Casco de Vigía +2». En +0 se omite el sufijo: «Casco de Vigía Oscuro». Las variantes son nombre propio invariable (no concuerdan en género).

### 1.3 Ciclo de progresión (primera rebanada)

1. **Fabricar** una familia básica (Vigía) en la mesa con materiales del valle. Es la primera defensa real y reemplaza al equipo provisional.
2. **Elegir una piedra** (Divino, Brillante u Oscuro) para especializar una pieza: cada una cambia defensa, vida y velocidad en sentidos distintos.
3. **Mejorar con joyas** (+1 a +5) con coste creciente; la mejora siempre sube.
4. **Farmear** una familia por zona (Zarzal, bosque): piezas sueltas por caída, nunca todo de golpe. Aparecen las primeras decisiones de mezcla («tengo 3 de Zarzal y 2 de Vigía»).
5. **Cazar** una familia exclusiva de jefe repetible (Albor, Gran Ciervo, reaparece a las 72 h): potencia algo mayor, pero no estrictamente mejor que una familia fabricada y bien mejorada (ver 3.3).
6. El jugador acaba eligiendo **una familia de set + una o dos piezas sueltas de otra** según el bono que quiere, sus variantes y la mejora invertida.

Se cumple el principio de oficio y crecimiento del brief: el progreso es de elección, no solo de número.

### 1.4 Atributos disponibles

| Atributo | ¿Existe hoy? | Uso en esta propuesta |
|---|---|---|
| Vida máxima (`hp`, `C.HP_BASE = 40`) | Sí | Sí |
| Defensa (`def`) | Sí | Sí, con fórmula proporcional (3.7) |
| Velocidad de movimiento (`vel`, 1.0 base) | Sí | Sí |
| Regeneración de vida | No | Fuera de la v1 (decisión 12) |
| Reducción de daño porcentual aparte | No | No hace falta: la fórmula 3.7 ya es proporcional |
| Resistencia mágica / elemental, bloqueo, velocidad de ataque, estados alterados, suerte de botín | **Requieren sistema nuevo** | No |
| Durabilidad | **Requiere sistema nuevo** | No (decisión 11) |

La primera versión solo toca `hp`, `def` y `vel`. Ninguna variante ni bono de set menciona nada de las filas «requiere sistema nuevo».

---

## 2. Arquitectura de datos

### 2.1 Entidades y relaciones

```
arquetipo 1──* familia 1──5 pieza(slot) ──(instancia)── variante ?, nivel N
                  │
                  └─ bono_set (por número de piezas)
variante   (catálogo de piedras)       joya (catálogo, 1 en la v1)
origen     (fabricable | zona | jefe) ── dato dentro de la familia
```

Todo es dato con **IDs estables en minúsculas, sin tildes y sin espacios** (`vigia`, `zarzal`, `albor`, `divino`, `brillante`, `oscuro`). Un ID publicado no se renombra nunca (la UI muestra `nombre`, que sí puede cambiar). Añadir una familia, variante o joya es añadir un objeto JSON y, si procede, una receta o tabla de caída: **sin código nuevo**.

Archivos propuestos (carpeta nueva `Linde/cenital/datos/equipo/`): `arquetipos.json`, `familias.json`, `variantes.json`, `joyas.json`. Se cargan una vez en `catalogos.gd` y `validar()` los comprueba (2.5).

### 2.2 Campos

**arquetipo** (`ligera`, `media`, `pesada`): `silueta` (id de arte compartido), `mult` {`def`, `hp`}, `vel_pct` (por unidad de peso, ver 3.1).

**familia**: `id`, `nombre`, `arquetipo`, `potencia` (multiplicador, ver 3.3), `paleta` (id), `origen` {`tipo`: `fabricable`|`zona`|`jefe`, más campos propios del tipo}, `rareza` (`comun`|`rara`|`unica`, solo etiqueta de UI/color), `bono_set` (lista de umbrales), `piezas`: ids de las 5 piezas.

**variante**: `id`, `nombre`, `paleta_delta` (id), `mult` {`def`, `hp`}, `vel_pct_delta`, `piedra` (id del ítem consumible). La variante «sin piedra» es la ausencia (`""`): multiplicadores 1.0.

**joya**: `id`, `nombre`, `funcion` (`mejorar`), `coste_por_nivel`.

**instancia de pieza** (lo que el jugador tiene): `familia`, `ranura`, `variante` (`""` o id), `nivel` (0..`NIVEL_MAX`).

### 2.3 Cómo se guarda una pieza (decisión técnica central)

El inventario actual es `{id: cantidad}` (pilas, `Inv.cambiar` atómico). Para no reescribirlo, **el estado de la instancia se codifica en la clave del ítem**:

```
eq:<familia>:<ranura>:<variante>:<nivel>
eq:vigia:casco::0               Casco de Vigía          (sin piedra, +0)
eq:vigia:casco:oscuro:2         Casco de Vigía Oscuro +2
eq:albor:torso:divino:0         Torso de Albor Divino
```

- El equipo no apila (`pila: 1`): cada pieza ocupa un hueco, como hoy.
- Mejorar o cambiar piedra = quitar una clave y añadir otra en **una sola transacción** (`Inv.cambiar` ya es todo-o-nada).
- `equipo` guarda la misma clave por ranura: `{"casco": "eq:vigia:casco:oscuro:2", ...}`.
- Un parser único (`Equipo.leer(clave) -> Dictionary`) valida: familia existe, ranura pertenece a la familia, variante existe, `0 <= nivel <= NIVEL_MAX`. Clave inválida = pieza sin familia (5.7).
- Como la clave ya no es un ID de `C.ITEMS`, **todo acceso a nombre, pila y estadísticas pasa por `Equipo.info(clave)`** (devuelve lo mismo que una entrada de `C.ITEMS` para claves `eq:`; para el resto se usa `C.ITEMS`). Ver 7.1.
- **Límite conocido:** si más adelante se quisieran tiradas aleatorias por pieza o durabilidad, hay que pasar a instancias con ID propio. Hoy no se necesita (decisión 1).

### 2.4 Ejemplo JSON (corto, PROVISIONAL)

```json
{
  "familia": {
    "id": "vigia", "nombre": "Vigía", "arquetipo": "media", "potencia": 1.00,
    "paleta": "pal_vigia", "rareza": "comun",
    "origen": {"tipo": "fabricable", "estacion": "mesa", "habilidad": "artesano"},
    "piezas": ["casco", "torso", "guantes", "botas", "pantalones"],
    "bono_set": [
      {"piezas": 2, "efecto": {"def_pct": 0.05}},
      {"piezas": 3, "efecto": {"hp_pct": 0.05}},
      {"piezas": 5, "efecto": {"def_pct": 0.05, "vel_pct": 0.02}}
    ]
  },
  "variante": {
    "id": "oscuro", "nombre": "Oscuro", "piedra": "piedra_bendicion",
    "paleta_delta": "delta_oscuro",
    "mult": {"def": 1.20, "hp": 1.00}, "vel_pct_delta": -0.010
  },
  "joya": {
    "id": "chispa", "nombre": "Chispa de Temple", "funcion": "mejorar",
    "coste_por_nivel": {"1": 1, "2": 1, "3": 2, "4": 3, "5": 4}
  }
}
```

**Joya de la v1: solo Chispa de Temple** (`mejorar`). Sube una pieza de +N a +N+1, siempre. Más joyas se añaden después por datos.

### 2.5 Validación (`catalogos.validar()` ampliado)

Se rechaza el catálogo si hay: familia sin exactamente 5 piezas distintas de las 5 ranuras; arquetipo, paleta, piedra o ítem de origen inexistente; ID duplicado; bono de set con umbral fuera de 2..5 o no creciente; bono acumulado de una familia por encima de +12 % def o +10 % vida; `potencia_max / potencia_min > 1.20`; coste de mejora ausente para algún nivel de 1 a `NIVEL_MAX`; **una variante que domina a otra o a «sin piedra»** (todos sus multiplicadores ≥ y alguno >, incluida la velocidad); una familia fabricable sin receta o de jefe/zona sin tabla de caída que la alcance (alcanzabilidad, como el resto del catálogo).

---

## 3. Fórmulas (todas PROVISIONALES)

### 3.1 Estadísticas de una pieza

Constantes de ranura (`datos`, no en código):

| Ranura | `def_base` | `hp_base` | peso de velocidad |
|---|---|---|---|
| casco | 2 | 3 | 1.0 |
| torso | 4 | 6 | 1.0 |
| guantes | 1 | 1 | 0.5 |
| botas | 1 | 2 | 2.0 |
| pantalones | 2 | 3 | 0.5 |
| **Suma** | **10** | **15** | **5.0** |

(Casco 2 y torso 4 coinciden con los valores provisionales actuales.)

Arquetipos:

| Arquetipo | `mult.def` | `mult.hp` | `vel_pct` por peso |
|---|---|---|---|
| ligera | 0.70 | 1.20 | +1.0 % |
| media | 1.00 | 1.00 | 0 % |
| pesada | 1.40 | 1.00 | -1.5 % |

Fórmulas, con `N` = nivel de mejora y `K_N = 0.10`:

```
mejora(N)    = 1 + K_N * N
def_pieza    = def_base[r] * A.def  * F.potencia * V.def * mejora(N)
hp_pieza     = hp_base[r]  * A.hp   * F.potencia * V.hp  * mejora(N)
vel_pieza    = peso[r] * (A.vel_pct + V.vel_pct_delta)          (sin mejora ni potencia)
```

La velocidad **no** crece con la mejora ni con la potencia: así la mejora no rompe el límite de velocidad ni hace a la ligera estrictamente mejor.

### 3.2 Estadísticas finales

```
def_eq = suma(def_pieza)                               (sin redondeo por pieza)
hp_eq  = suma(hp_pieza)
vel_eq = suma(vel_pieza) + bono_set.vel_pct

DEF = floor( def_eq * (1 + min(bono_set.def_pct, 0.25)) )
HP  = floor( (HP_BASE + hab.hp + hp_eq) * (1 + min(bono_set.hp_pct, 0.25)) )
VEL = clamp( 1.0 + hab.vel + vel_eq,  0.70, 1.30 )
```

Se redondea **una vez, al final** (nunca por pieza ni al cargar). Se recalculan desde cero en `stats()` cada vez, como hoy: nada se acumula en el guardado.

**Por qué el techo de velocidad es 1.30:** las habilidades existentes `pies_ligeros` (+0.15) y `explorador` (+0.10) ya suman +0.25, o sea 1.25 sin equipo. Con el techo anterior (1.20) el equipo no podría aportar nada a quien las tiene y las habilidades quedarían recortadas. 1.30 deja margen al equipo y sigue siendo un tope de seguridad (un set de Zarzal Brillante con bono completo llegaría a 1.41 y se recorta).

### 3.3 Potencia por familia y relación entre arquetipos

| Familia | Arquetipo | Origen | `potencia` |
|---|---|---|---|
| Vigía | media | fabricable | 1.00 |
| Zarzal | ligera | farmeo (bosque) | 1.10 |
| Albor | pesada | jefe (Gran Ciervo) | 1.20 |

Invariante validada: `potencia_max / potencia_min <= 1.20`. Esto acota **solo el factor `potencia`**; no acota la diferencia entre arquetipos, que es deliberada: la **pesada pesa en defensa, la ligera en vida y velocidad, la media es equilibrada y la que más se beneficia de mejorar**. Cifras reales de un set completo, sin piedra, sin bono de set, sin habilidades:

| Set | `def_eq` | `hp_eq` | `vel_eq` |
|---|---|---|---|
| Vigía +0 | 10.0 | 15.0 | 0 % |
| Vigía +5 (`mejora` 1.50) | 15.0 | 22.5 | 0 % |
| Zarzal +0 | 7.7 | 19.8 | +5.0 % |
| Zarzal +5 | 11.55 | 29.7 | +5.0 % |
| Albor +0 | 16.8 | 18.0 | -7.5 % |
| Albor +5 | 25.2 | 27.0 | -7.5 % |

Lectura: Vigía +5 **no** supera a Albor +0 en defensa (15.0 frente a 16.8), pero sí en vida (22.5 frente a 18.0) y en velocidad (0 % frente a -7.5 %). Albor manda en defensa; Zarzal en vida y velocidad; la rareza no da ventaja en todo. La rareza decide el estilo (arquetipo) y el prestigio, no una victoria automática.

### 3.4 Ejemplos numéricos (PROVISIONALES)

Set completo de 5 piezas, +0, sin bono de set, sin habilidades (media, potencia 1.00):

| Set | `def_eq` | `hp_eq` | `vel_eq` |
|---|---|---|---|
| Vigía sin piedra | 10 * 1.00 = **10.0** | 15.0 | 0 % |
| Vigía **Divino** (def 0.90, hp 1.15, vel +0.5 %/peso) | 9.0 | 17.25 | +2.5 % |
| Vigía **Brillante** (def 1.00, hp 0.90, vel +1.0 %/peso) | 10.0 | 13.5 | +5.0 % |
| Vigía **Oscuro** (def 1.20, hp 1.00, vel -1.0 %/peso) | 12.0 | 15.0 | -5.0 % |

Con bono de set (ver 3.5) y `HP_BASE = 40`: **Vigía Oscuro completa, +0**: `def_eq 12.0`; bonos de 2 y 5 piezas de defensa = `+10 %` acumulado dentro de la familia, bono de 3 piezas `+5 %` de vida y `+2 %` de velocidad -> `DEF = floor(12.0 * 1.10) = floor(13.2) = 13`; `HP = floor((40 + 15) * 1.05) = floor(57.75) = 57`; `VEL = 1 + (-0.05 + 0.02) = 0.97`.

Mejora desigual: casco Vigía +3 y las otras 4 en +0 -> casco `2*1.30 = 2.6`, resto 8 -> `def_eq = 10.6` (cada pieza cuenta lo suyo; no hay media ni mínimo).

### 3.5 Bono de set y reglas anti-acumulación

Definiciones: `c(F)` = número de piezas equipadas cuya familia es F (cuentan la familia, **no** la variante ni el nivel). Cada familia declara umbrales (2, 3, 5); los efectos de umbrales ya alcanzados **se suman dentro de esa familia** (el de 5 incluye los de 2 y 3).

Reglas:

1. **Solo un bono de set activo:** el de la familia con mayor `c(F)`, y solo si `c >= 2`. Dos sets de 2 piezas no dan nada.
2. **Empate:** gana la familia que tenga el `torso` equipado; si ninguna, la que tenga el `casco`; si ninguna, ninguna (determinista, sin depender del orden de equipar).
3. **Manos fuera:** escudo y arma no cuentan.
4. **Mismo efecto no se repite:** cada umbral se aplica una vez; equipar/desequipar recalcula desde cero (no hay estado que acumular al cargar).
5. **Límites globales (provisionales):** `def_pct <= +25 %`, `hp_pct <= +25 %`, `vel` final en `[0.70, 1.30]`. Los bonos de set son solo `def_pct`, `hp_pct`, `vel_pct`.
6. **Tamaño del bono:** el bono total de una familia no supera +12 % de defensa ni +10 % de vida. Es pequeño a propósito: mezclar piezas debe seguir siendo competitivo (ver 5.2).
7. **El bono no depende de la mejora ni de la variante** (evita un quinto eje).

Bono de las 3 familias (PROVISIONAL), con el total acumulado a 5 piezas:

| Familia | 2 piezas | 3 piezas | 5 piezas | Total a 5 |
|---|---|---|---|---|
| Vigía | +5 % def | +5 % vida | +5 % def, +2 % vel | def 10 %, vida 5 %, vel 2 % |
| Zarzal | +3 % vel | +5 % vida | +5 % vida, +3 % vel | def 0 %, vida 10 %, vel 6 % |
| Albor | +4 % def | +4 % def | +4 % def, +5 % vida | def 12 %, vida 5 %, vel 0 % |

Comprobación de la regla 6: Vigía 10 % def y 5 % vida; Zarzal 0 % def y 10 % vida; Albor 12 % def y 5 % vida. Las tres cumplen (<= 12 % def y <= 10 % vida).

### 3.6 Mejora con joyas (Chispa de Temple)

`NIVEL_MAX = 5` (cabe ampliar por datos). La Chispa **siempre** sube la pieza de +N a +N+1; no hay azar. Coste (PROVISIONAL):

| De -> a | +0->+1 | +1->+2 | +2->+3 | +3->+4 | +4->+5 |
|---|---|---|---|---|---|
| Coste (joyas) | 1 | 1 | 2 | 3 | 4 |

Coste total de +0 a +5: 11 joyas. Una pieza en +5 no admite más mejora (se rechaza sin gastar la joya). Como no hay azar, no se necesita flujo aleatorio ni semilla para mejorar.

### 3.7 Daño recibido (defensa proporcional, entra en la v1)

```
daño recibido = max(1, round(n * 20 / (20 + DEF)))
```

Ejemplos con DEF 12: 62.5 % del daño; con DEF 25: 44 %; nunca 0 %.

**Motivo:** el primer set completo ya da DEF ≈ 10-12 (3.4), y con `max(1, n - def)` el slime (4 de daño) pasaría a 1 y el jefe (12) a ~2: el combate quedaría trivializado desde el primer set. Con la proporcional y DEF 13 el slime hace 2 y el jefe 7.

---

## 4. Obtención: tres categorías

Rareza = cómo se consigue, no cuánto pesa.

| Categoría | Familia ejemplo | Cómo | Notas |
|---|---|---|---|
| **Fabricable** | Vigía | Receta en mesa (hoy: lingote, madera, fibra) + habilidad `artesano` | Cualquier jugador puede fabricarla y comerciarla. Es la base del sistema. |
| **Farmeo por zona** | Zarzal | Caída de enemigos y objetos del bosque, una pieza suelta cada vez, tirada por jugador | Probabilidad provisional 6 % por pieza por derrota, con garantía: tras 15 intentos sin caída, la siguiente es segura (decisión 7). |
| **Exclusiva de jefe** | Albor | Gran Ciervo del Claro (`tipo: mundo`, reaparece cada 72 h): una pieza que **el jugador aún no tiene** por derrota, tirada individual | Nunca el mismo hueco dos veces hasta completar el set. |

El Guardián de las Ruinas es jefe de capítulo y **no reaparece**; por eso **no** sirve para una familia de 5 piezas. Da una recompensa única fuera del set (a definir en A02).

Piedras (consumibles, ingredientes de las variantes; origen provisional): **Piedra de Alma** (Divino) en la zona del estanque, **Piedra de Armonía** (Brillante) en el bosque, **Piedra de Bendición** (Oscuro) en las ruinas. Las tres entran en la v1 (son solo datos).

Contenido de ejemplo = prueba; la narrativa y los jefes finales son A02, abierto.

---

## 5. Reglas de consistencia

1. **Pieza suelta (sin las otras 4):** se puede equipar; solo aporta sus estadísticas (sin bono por debajo de 2). Nunca hay penalización por llevar menos piezas.
2. **Variantes mezcladas dentro de una familia:** válido. El bono de set cuenta la familia; cada pieza aporta su variante (Divino en botas y Oscuro en torso, si el jugador quiere).
3. **Mejora desigual:** válido; cada pieza vale lo suyo, sin media ni mínimo (3.4).
4. **Cambiar de piedra tras mejorar:** conserva el nivel +N, la familia y la ranura. Cuesta una piedra nueva; la piedra anterior **se pierde**. No se puede cambiar la familia de una pieza.
5. **Quitar la piedra sin sustituirla:** no existe (decisión 8: las piedras incrustadas no se recuperan); la piedra se cambia solo sustituyéndola.
6. **Sin durabilidad:** las piezas no se desgastan ni se reparan (decisión 11).
7. **Pieza sin familia** (clave inválida, familia retirada, ítem heredado `casco_hierro`): el cargado nunca la borra. Se migra (7.3) o, si no existe equivalente, queda en inventario como «Pieza desconocida», no equipable, y se registra un aviso. Nunca se pierde ni se duplica (misma política que las recompensas pendientes).
8. **Cambios de balance:** los multiplicadores son dato, así que se pueden cambiar sin código. Como no se guarda ninguna estadística derivada, todas las partidas y piezas existentes se recalculan solas. Sí se guarda la clave (familia/ranura/variante/nivel), por lo que **nunca se cambia el significado de un ID**; para retirar algo se marca `retirada: true`, se mantiene el equivalente de migración y se avisa en el parche.
9. **Multijugador (mundo anfitrión):** inventario y equipo son estado por jugador; las estadísticas finales las calcula el servidor desde las claves (el cliente no envía números). Botín de farmeo y de jefe: tirada **por jugador** (flujo por semilla, jugador y objeto), así no se roba ni se compite por la misma pieza; fabricables y materiales comunes pueden seguir siendo compartidos. **Intercambio directo** libre entre dos jugadores (mundo entre amigos): transacción atómica en el servidor (ambos lados validan cabida; todo-o-nada) de piezas, joyas y piedras. Sin tienda, subastas ni precios de servidor (A03).

---

## 6. Las tres familias de ejemplo (PROVISIONALES)

Cada una tiene exactamente 5 piezas. Los nombres de pieza siguen «<Ranura> de <Familia>».

| Familia | Arquetipo | Origen | Piezas | Receta o caída (provisional) |
|---|---|---|---|---|
| **Vigía** | media | Fabricable en mesa, habilidad `artesano` | Casco, Torso, Guantes, Botas, Pantalones de Vigía | Casco: 2 lingote + 1 madera. Torso: 4 lingote + 1 madera. Guantes: 1 lingote + 1 fibra. Botas: 2 lingote + 1 fibra. Pantalones: 2 lingote + 2 fibra. (Casco y torso conservan las recetas del equipo provisional actual.) |
| **Zarzal** | ligera | Farmeo en el bosque | Casco, Torso, Guantes, Botas, Pantalones de Zarzal | Caen de enemigos del bosque al 6 % por pieza elegida al azar, con garantía a los 15 intentos. |
| **Albor** | pesada | Exclusiva del Gran Ciervo del Claro (jefe de mundo, 72 h) | Casco, Torso, Guantes, Botas, Pantalones de Albor | Una pieza por derrota y jugador, de las que le faltan. |

Piedras de la v1 (multiplicadores PROVISIONALES):

| Piedra | Variante | Ventaja | Desventaja | Mult. (def / hp / vel por peso) |
|---|---|---|---|---|
| (ninguna) | sin piedra | neutra | — | 1.00 / 1.00 / 0 |
| Piedra de Alma | Divino | más vida, algo más de velocidad | menos defensa | 0.90 / 1.15 / +0.5 % |
| Piedra de Armonía | Brillante | más velocidad | menos vida | 1.00 / 0.90 / +1.0 % |
| Piedra de Bendición | Oscuro | más defensa | más lento | 1.20 / 1.00 / -1.0 % |

**Comprobación de no dominancia** (regla de validación 2.5; cada par tiene una estadística donde gana cada lado):

| Par | Gana el primero en | Gana el segundo en |
|---|---|---|
| Divino / sin piedra | hp | def |
| Brillante / sin piedra | vel | hp |
| Oscuro / sin piedra | def | vel |
| Divino / Brillante | hp | def, vel |
| Divino / Oscuro | hp, vel | def |
| Brillante / Oscuro | vel | def, hp |

Ningún par queda dominado.

---

## 7. Impacto en el código actual

Actualmente (`catalogos.gd`, `juego.gd`): 3 ranuras (`casco`, `coraza`, `escudo`), ítems de ID plano con `equipo` y `def`, `stats().def` como suma plana.

### 7.1 Qué se reemplaza

| Archivo | Hoy | Cambio |
|---|---|---|
| `catalogos.gd` líneas 25-27 | `casco_hierro`, `coraza_hierro`, `escudo_madera` con `def` fija | Se eliminan casco/coraza de hierro; **se conserva** `escudo_madera` (ranura `escudo`). Las piezas pasan a derivarse de `familias.json`. |
| `catalogos.gd` línea 29 | `RANURAS = ["casco","coraza","escudo"]` | `RANURAS = ["casco","torso","guantes","botas","pantalones","escudo"]` (`coraza` pasa a `torso`) |
| `catalogos.gd` líneas 58-60 | Recetas de casco/coraza de hierro | Las recetas de Vigía se generan desde la familia (`origen.tipo = fabricable`); escudo igual que hoy |
| `catalogos.gd` línea 135 (`validar`) | comprueba `equipo`/`def` del ítem | Se amplía con las comprobaciones del 2.5 |
| `juego.gd` líneas 39 y 50 | `equipo` por defecto con 3 ranuras | 6 ranuras; carga completa claves que falten con `""` |
| `juego.gd` líneas 139-140 (`stats`) | suma de `def` de los ítems | Llama a `Equipo.stats_de(d.equipo)` y aplica 3.2 |
| `juego.gd` líneas 262-277 (`equipar`/`desequipar`) | ranura = `ITEMS[item].equipo` | La ranura sale del parser de la clave; mismas garantías atómicas |
| `juego.gd` `danar_pj` | `max(1, n - def)` | `max(1, round(n * 20 / (20 + DEF)))` (3.7) |
| `inventario.gd` línea 7 | `C.ITEMS[clave].pila` | Pila vía `Equipo.info(clave)` (las claves `eq:` no están en `C.ITEMS` y fallarían) |
| `juego.gd` líneas ~199, 202, 281, 302, 354, 510 | Indexan `C.ITEMS[clave]` (estadísticas, herramientas, textos) | Resolver nombre, pila y estadísticas con `Equipo.info(clave)`; `C.ITEMS` solo para ítems normales |
| `hud.gd` línea 54 | `C.ITEMS[clave]` para el nombre | `Equipo.info(clave)` |
| `escena.gd` líneas ~210-217 y 254 | `C.ITEMS[clave]` en la escena/mundo | `Equipo.info(clave)` |
| `guardado.gd` (`FORMATO = 2` desde el refactor de estado por jugador) | sin migración de equipo | `FORMATO = 3` con migración del equipo (7.3), encadenada tras la 1 → 2 existente |
| `capas_sprite.gd` | solo casco, coraza, escudo, espada | Capas por ranura y arquetipo (sección 8) |
| UI inventario (`hud.gd`) | sección «Equipado» de 3 ranuras | 6 ranuras, nombre completo, estadísticas, bono de set activo |
| `tests/prueba.gd` | 130 PASS actuales | Añadir pruebas de 7.4 |

Regla de implementación: ninguna función indexa `C.ITEMS[clave]` con una clave que pueda ser `eq:…` sin pasar antes por `Equipo.info(clave)`.

Archivos nuevos: `scripts/equipo.gd` (funciones puras: `leer`, `info`, `construir`, `stats_de`, `bono_set`, `mejorar`), `datos/equipo/*.json`.

### 7.2 Qué no se toca

Inventario atómico, guardado con checksum/`.bak`, flujos de azar por semilla, arma como «mejor `dmg`» del inventario, habilidades.

### 7.3 Migración de partidas

Mapa de herencia (se aplica en `guardado.gd` al subir el formato de 2 a 3, sin perder objetos; el equipo vive ahora en `d.jugadores[id].equipo`, no en la raíz):
`casco_hierro -> eq:vigia:casco::0`, `coraza_hierro -> eq:vigia:torso::0`, `escudo_madera` igual. En `d.equipo`, `coraza` pasa a `torso` y las ranuras nuevas se rellenan con `""`. Lo que ya estaba en inventario y en equipo se convierte en las dos ubicaciones. Una clave desconocida sigue la regla 5.7. Se conserva el `.bak` previo a migrar.

### 7.4 Pruebas necesarias (todas deterministas)

Las de los criterios de aceptación (sección 13). Verificación visual (estándar del proyecto): captura retenida en `production/qa/evidence/` del panel de inventario con 6 ranuras, de una pieza en cada arquetipo y de una variante.

---

## 8. Impacto en el arte y qué pedir a GPT

**Restricción:** el arte lo produce GPT; no hay arte único por variante. Se proponen **3 siluetas compartidas** (ligera, media, pesada) y **variantes por cambio de paleta**. Cero arte extra por familia.

### 8.1 Esquema

- Cada arquetipo tiene **5 hojas** (una por ranura) sobre el personaje fijado, mismo formato que `personaje_<capa>.png` (4 columnas de caminata × 4 filas de orientación, ancla en los pies). Total: **3 arquetipos × 5 ranuras = 15 hojas**, más escudo.
- Las hojas se piden en **colores índice** (por ejemplo, rojo = color principal, verde = sombra, azul = acento, gris = detalle neutro). Godot sustituye los índices por la paleta de la familia y le aplica el delta de la variante. Así Vigía, Zarzal y Albor (y sus 3 variantes) salen de las mismas hojas **sin nuevas imágenes**.
- Las familias del mismo arquetipo se distinguen **solo por paleta** (decisión 13).
- Iconos 16×16 provisional: una imagen por ranura y arquetipo (15) en colores índice, recoloreados igual; más 3 piedras y 1 joya.
- Se aplican las reglas comunes de `instrucciones-recursos-arte.md` (píxel único, fondo transparente, sin texto).

### 8.2 Orden de petición

0. **Antes que nada:** Fase 0-2 del documento de arte (plantilla de alineación, personaje fijado, tamaño de lienzo y **paleta compartida**). Pedir equipo antes de fijar escala obligaría a rehacerlo.
1. **Media (Vigía), 5 piezas, solo orientación frente** + prueba en el mapa. Valida el esquema de colores índice y el solapamiento con ropa base.
2. Media en 4 orientaciones y caminata de 4 cuadros.
3. **Pesada** y **ligera** (misma plantilla), 5 piezas cada una.
4. Escudo (ya previsto en la Fase 3) y confirmación del orden de capas.
5. Iconos de ranura × arquetipo, piedras y Chispa de Temple.
6. Las paletas de familia y variante se definen **en datos** (no son imágenes).

Fragmento de prompt orientativo (se completa con las reglas comunes y la paleta tras la fase 2):

> Equipment layer sheet for the Linde character, MEDIUM armor archetype, slot: helmet. 4 columns x 4 rows (walk frames x front/right/back/left), same anchor and cell size as the base character. Use ONLY these flat index colours: pure red = main colour, pure green = shadow, pure blue = accent, mid gray = neutral detail. No outline colour variation, no shading outside these colours. Transparent background. No text.

Comprobaciones al recibir: solo los colores índice permitidos, mismo ancla y tamaño que el personaje, y recoloreado correcto en el mapa antes de pedir el resto.

---

## 9. Decisiones cerradas (v1)

| # | Decisión | Motivo |
|---|---|---|
| 1 | Estado de la pieza en la clave del ítem (`eq:familia:ranura:variante:nivel`). | No reescribe el inventario atómico; alcanza para esta versión. |
| 2 | 5 ranuras de set más escudo; el arma queda sin ranura. | `coraza` pasa a `torso`; el arma es otra propuesta. |
| 3 | Variantes con las piedras del usuario: Alma -> Divino, Armonía -> Brillante, Bendición -> Oscuro; las tres en la v1. | Son solo datos; ninguna domina a otra (6). |
| 4 | Variante como nombre propio invariable. | Evita concordancias de género y facilita la localización. |
| 5 | El bono de set cuenta la familia, no variante ni nivel. | Mezclar sigue siendo viable y no se añade un quinto eje. |
| 6 | Solo la joya Chispa de Temple. | Menos contenido que equilibrar; más joyas se añaden por datos. |
| 7 | Farmeo por caída directa (6 %) con garantía a los 15 intentos. | Progreso asegurado sin sistema de fragmentos. |
| 8 | Las piedras incrustadas no se recuperan. | Sumidero simple; evita ciclos de piedras. |
| 9 | Mejora sin azar: la Chispa siempre sube; `NIVEL_MAX = 5`; coste 1, 1, 2, 3, 4; `mejora(N) = 1 + 0.10*N`. | Más simple de implementar, de probar y de entender para el jugador. |
| 10 | Defensa proporcional `max(1, round(n * 20 / (20 + DEF)))` ya en la v1. | El primer set completo da DEF ≈ 10-12 y con `max(1, n - def)` el slime (4) pasa a 1 y el jefe (12) a ~2: trivializa el combate desde el primer set. |
| 11 | Sin durabilidad. | Requiere sistema nuevo y no aporta a la fantasía de oficio. |
| 12 | Solo `hp`, `def`, `vel`. | Vocabulario existente; nada que requiera sistema nuevo. |
| 13 | Familias del mismo arquetipo se distinguen solo por paleta. | Cero arte extra. |
| 14 | Arma = mejor `dmg` del inventario. | Se mantiene hasta cerrar A01. |
| 15 | Intercambio directo libre entre jugadores; botín de farmeo y de jefe con tirada por jugador. | Mundo entre amigos; sin vínculo de propiedad que implementar ni explicar. |
| 16 | Familia de jefe = Gran Ciervo (repetible); el Guardián da una recompensa única fuera del set. | El Guardián no reaparece y no permite completar 5 piezas. |
| 17 | Potencia por familia en 1.00-1.20 (cociente máximo 1.20), validada. | Acota el factor `potencia`; la identidad de arquetipo es deliberada (3.3). |
| 18 | Orden de implementación: (a) `equipo.gd` + datos + pruebas con 3 familias y las 3 piedras, sin tocar arte; (b) migración y UI de 6 ranuras; (c) arte en índice tras la fase 2 de arte; (d) multijugador cuando exista el estado por jugador. | Valida la lógica antes de gastar arte. |

---

## 10. Fuera de la v1

- **Reciclar / desmontar piezas:** evita una fábrica de materiales; se estudiará con la economía (A03).
- **Lacre de Guarda y Cuño de Traspaso:** joyas extra (proteger y mover nivel entre piezas); se añaden después por datos.
- **Adornos de familia:** capa de arte extra por familia; en la v1 solo paleta.
- **Fallos de mejora:** la mejora no tiene azar ni pérdida de nivel.
- **Ligadura de piezas:** sin vínculo de propiedad; el intercambio es libre. Ampliación futura si el mundo se abre a desconocidos.
- **Durabilidad y reparación:** requiere sistema nuevo.
- **Atributos que requieren sistema nuevo:** resistencias, bloqueo, velocidad de ataque, estados alterados, suerte de botín, regeneración.
- Además, fuera de este documento: balance numérico (A03), combate final (A01), canon de nombres y jefes (A02), tienda y precios, armas, arte final y hoja de estilo.

---

## 11. Dependencias

**Este sistema necesita (hacia arriba):**
- `catalogos.gd` (`ITEMS`, `RANURAS`, recetas, `validar()`), `juego.gd` (`stats`, `equipar`, `desequipar`, `danar_pj`), `inventario.gd` (`Inv.cambiar` atómico), `guardado.gd` (`FORMATO` y migración).
- Habilidades existentes (`hab.hp`, `hab.vel`, `artesano`) y `C.HP_BASE`.
- Jefe repetible Gran Ciervo (72 h) y enemigos del bosque como fuentes de caída; piedras y Chispa como ítems nuevos.
- Fase 0-2 del documento de arte (escala y paleta) antes de pedir las hojas.

**Dependen de este sistema (hacia abajo):**
- `hud.gd` y `escena.gd` (nombres y estadísticas vía `Equipo.info`), `capas_sprite.gd` (capas por ranura y arquetipo).
- Combate (A01): la fórmula de defensa 3.7 pasa a ser parte de él.
- Economía (A03): costes de mejora, precios y orígenes de piedra.
- Multijugador (paso 7): cálculo de estadísticas en servidor e intercambio atómico.
- Narrativa (A02): nombres, jefes y la recompensa única del Guardián.

---

## 12. Parámetros ajustables

Todos son dato (JSON en `Linde/cenital/datos/equipo/`), valores PROVISIONALES:

| Parámetro | Valor | Vive en |
|---|---|---|
| `NIVEL_MAX` | 5 | `joyas.json` / constantes de equipo |
| `K_N` (mejora por nivel) | 0.10 | `joyas.json` |
| Coste de mejora por nivel | 1, 1, 2, 3, 4 joyas | `joyas.json` |
| `def_base`, `hp_base`, peso por ranura | tabla 3.1 | `arquetipos.json` (ranuras) |
| Multiplicadores y `vel_pct` por arquetipo | tabla 3.1 | `arquetipos.json` |
| `potencia` por familia | 1.00 / 1.10 / 1.20 | `familias.json` |
| Bonos de set por umbral | tabla 3.5 | `familias.json` |
| Topes de bono (`def_pct`, `hp_pct`) | 0.25 / 0.25 | constantes de equipo |
| Límite de velocidad | [0.70, 1.30] | constantes de equipo |
| Multiplicadores de variante | Divino 0.90/1.15/+0.5 %, Brillante 1.00/0.90/+1.0 %, Oscuro 1.20/1.00/-1.0 % | `variantes.json` |
| Constante de defensa | 20 | constantes de equipo |
| Probabilidad de caída / garantía | 6 % / 15 intentos | tabla de caída de la familia |
| Intervalo de reaparición del jefe | 72 h | jefe `tipo: mundo` |
| Recetas de Vigía | sección 6 | `familias.json` / recetas |

---

## 13. Criterios de aceptación

Todos con prueba automática determinista en `tests/prueba.gd` salvo el último punto de 7.4 (captura).

1. **5 piezas por familia:** toda familia de `familias.json` tiene exactamente 5 piezas, una por ranura; `validar()` rechaza una familia con 4, con 6 o con una ranura repetida.
2. **Ninguna variante domina:** de los 6 pares entre {sin piedra, Divino, Brillante, Oscuro}, ninguno cumple «todos los multiplicadores ≥ y alguno >»; `validar()` rechaza un catálogo que añada una variante dominante.
3. **Determinismo de `stats()`:** dos llamadas seguidas con el mismo estado devuelven diccionarios idénticos, y también tras guardar y cargar.
4. **Mejora:** una pieza en +0 con 11 joyas llega a +5 gastando exactamente 1, 1, 2, 3 y 4; en cada intento sube exactamente un nivel; en +5 se rechaza sin gastar la joya; con joyas insuficientes se rechaza sin cambios.
5. **Equipar y desequipar atómicos:** con el inventario lleno, desequipar se rechaza y deja inventario y equipo idénticos; el cambio de pieza equipada por una del inventario no pierde ni duplica ninguna.
6. **Bono de set único y determinista:** con 3 Vigía + 2 Zarzal solo actúa el de Vigía; con empate 2+2 gana la familia con el torso (si ninguno, la del casco, si ninguno, ningún bono); el resultado es el mismo en todas las permutaciones del orden de equipar.
7. **Límites:** el bono acumulado de cada familia es ≤ 12 % def y ≤ 10 % vida; `DEF` y `HP` usan como máximo +25 % de bono; `VEL` queda siempre en [0.70, 1.30] (caso máximo: Zarzal Brillante completo con `pies_ligeros` y `explorador` da 1.30).
8. **Migración FORMATO 2 -> 3** (y una partida de formato 1 la recorre entera, 1 -> 2 -> 3): una partida con casco, coraza y escudo equipados y repetidos en inventario queda con el mismo número total de objetos, `coraza` convertida en `torso`, las 3 ranuras nuevas en `""` y el `.bak` presente.
9. **Intercambio entre jugadores atómico:** si la cabida de cualquiera de los dos inventarios no alcanza, ninguno cambia; si alcanza, ambos cambian y el total de objetos se conserva.
10. **Defensa:** para `n` en 1..50 y `DEF` en 0..60, `max(1, round(n * 20 / (20 + DEF)))` nunca da 0, con `DEF = 0` devuelve `n` y no crece al aumentar `DEF`.
11. **Claves inválidas:** 10 claves malformadas (familia inexistente, ranura ajena, variante desconocida, nivel 6, formato roto…) cargadas desde un guardado quedan todas como «Pieza desconocida», no equipables, sin desaparecer ni duplicarse (cuenta total igual antes y después).
12. **Cifras de referencia:** `Vigía Oscuro` completa en +0 sin habilidades da `DEF 13`, `HP 57`, `VEL 0.97` (3.4); `potencia_max / potencia_min <= 1.20` en el catálogo.

---

## 14. Cambios respecto a la propuesta inicial

- Variantes renombradas a Divino, Brillante y Oscuro (las tres en la v1) con multiplicadores nuevos; comprobación de no dominancia incluida como regla de validación.
- Mejora sin azar, con coste creciente; defensa proporcional adelantada a la v1; solo paleta en arte; intercambio libre; recortes listados en «Fuera de la v1».
- Corrección de `HP`: se redondea una vez al final (el ejemplo anterior daba 55,65); ejemplo recalculado con las fórmulas finales.
- Bonos de set recalculados: la familia Albor superaba el tope de +12 % de defensa (16 %); las tres familias cumplen ahora la regla.
- Límite de velocidad ampliado de 1.20 a 1.30 por las habilidades existentes (+0.25 ya suman 1.25).
- Sección 3.3 reescrita: la afirmación «Vigía +5 supera a Albor +0» era falsa para la defensa; se muestran las cifras reales y la potencia solo acota su propio factor.
- Tabla de impacto del código ampliada con las funciones que indexan `C.ITEMS[clave]` y fallarían con claves `eq:…`; todo pasa por `Equipo.info(clave)`.
- Cambiar de piedra tras mejorar conserva el nivel (coherente con 5.4).
- Añadidos: Resumen, Dependencias, Parámetros ajustables y Criterios de aceptación.
