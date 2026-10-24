# Instrucciones para crear los recursos de arte de Linde

> **Estado:** propuesta, revisada el 2026-10-23 tras una corrección del usuario. Sin probar con el generador. El arte final lo produce GPT (o una artista); el código usa marcadores de posición hasta recibirlo.
> **Referencias:** `LINDE_Punto_de_Inicio/referencias/visual_objetivo.png` (pueblo) y la hoja de personaje generada (concepto, no atlas de sprites).
> **Relacionado:** `design/game-brief.md` (campo *Resolución*: por definir), `prototypes/personaje-compacto/README.md`.

## Criterios de trabajo propuestos

*Proceden de la revisión del usuario y de mis pruebas; no son decisiones cerradas.*

- **Primero un personaje completo y quieto, en cuatro direcciones, probado dentro del mapa.** Solo después se separan capas, porque generarlas por separado produce desajustes.
- **La plantilla de alineación va antes de las hojas:** silueta, posición de los pies y cuadros definidos.
- **16×16 (tiles) y 32×32 (lienzo del personaje) son tamaños de prueba.** Hay que comprobar que conservan el aspecto de la referencia visual antes de fijarlos.
- **La paleta compartida se define después** de probar personaje y escenario. No hay un máximo de colores acordado todavía.
- **Procedencia:** cada recurso se registra con herramienta, fecha, prompt y licencia. No se usan assets propietarios ni personajes con derechos.

## Nota sobre una medición

En la hoja de personaje generada, una autocorrelación de bordes hecha en Godot sugiere que el personaje y el escenario usan tamaños de píxel distintos (≈ 3–4 px y ≈ 5 px). Las correlaciones eran débiles (0,3–0,5) y la medición **no está verificada** por otra vía; es una estimación mía, no un dato. Lo que sí es seguro: el propio prompt de esa hoja dice que no es un atlas validado ni una prueba de resolución nativa.

## Fases

### Fase 0 — Plantilla de alineación (antes de generar nada)
Una imagen guía por tamaño de prueba, con cuadros definidos, línea de suelo y centro marcados, y la silueta del cuerpo en las cuatro direcciones. Sirve para que el generador (o quien dibuje) respete la misma ancla en los pies. Se puede producir desde el motor.

### Fase 1 — Personaje completo de prueba
Un solo personaje con su ropa por defecto (cuerpo, pelo, túnica, pantalón, botas, cinturón), **quieto, en cuatro direcciones** (frente, derecha, espalda, izquierda), una sola imagen coherente, sin separar capas. Se coloca en el mapa real, junto a una **puerta, un árbol y un cofre provisionales** (bocetos de prueba, no el escenario definitivo, que llega en la fase 4), y se juzga contra la referencia.

> [Reglas globales] A single complete character, standing still, shown in four orientations on the alignment template (front, right profile, back, left profile). Compact adventurer: dark teal tousled hair, head about 40% of total height, short torso, clearly separated short legs, small hands, teal tunic, dark trousers, brown boots, small belt. Feet touching the same baseline in every view, same body size in all views, back view shows no face. No equipment yet.

### Fase 2 — Fijar el acabado
Con el personaje probado en el mapa se decide: tamaño de lienzo (16 o 32), tamaño de píxel, nivel de detalle y **paleta compartida** (número de colores incluido). Se registra la decisión en `design/game-brief.md` (campo *Resolución*).

### Fase 3 — Caminata, equipo y variantes
Solo tras la fase 2:
- Caminata de 4 cuadros por orientación.
- Equipo: casco, coraza, escudo y espada.
- Variantes de pelo, piel y ropa.
- Separación en capas, partiendo del personaje ya fijado, con la misma ancla.

**Lateralidad:** escudo en la mano izquierda y espada en la derecha, en las cuatro vistas.

**Orden de capas de espada y escudo según la orientación** (a confirmar con la prueba en el mapa):

| Orientación | Escudo (mano izquierda) | Espada (mano derecha) |
|---|---|---|
| Frente | delante del brazo y del torso | delante del brazo y del muslo |
| Derecha (mira a la derecha; se ve su costado derecho) | detrás del torso, apenas visible | delante del torso, es el brazo cercano |
| Espalda | a la izquierda de la imagen, parcialmente tapado por el cuerpo | a la derecha de la imagen, delante del brazo |
| Izquierda (mira a la izquierda; se ve su costado izquierdo) | delante del torso, es el brazo cercano | detrás del torso, apenas visible |

**Lateralidad en perfiles — punto en discusión.** La tabla supone la cámara al sur de la escena. Un personaje que mira al este (derecha de la pantalla) tiene su mano derecha hacia el sur, es decir, hacia la cámara, así que se ve su costado derecho y la espada es el brazo cercano. La hoja de personaje generada por GPT también muestra así los perfiles (derecha: espada delante, escudo detrás; izquierda: escudo delante). Una revisión posterior propuso lo contrario (al mirar a la derecha se ve el costado izquierdo). Queda **sin resolver**: se confirma con la prueba de la fase 1 en el mapa; si se prefiere la inversa, se intercambian las dos filas de perfil.

**Estados de animación que el juego necesita** (los tiempos son los actuales del código, provisionales; fuente: `Linde/cenital/scripts/catalogos.gd` y `params.gd`). Cada estado se pide en las 4 orientaciones:

| Estado | Cuadros sugeridos | Tiempo actual | Cuándo se usa |
|---|---|---|---|
| Reposo | 1 | — | quieto |
| Caminar | 4 | 0,12 s por cuadro | moverse |
| Usar herramienta (talar, picar, golpear arbusto) | 3 | 0,3 s entre golpes | recolección con Espacio |
| Ataque con arma | 3: aviso, golpe, recuperación | 0,10 / 0,10 / 0,25 s | combate con Espacio |
| Recibir daño | 1–2 | 0,6 s de invulnerabilidad parpadeando | tras un impacto |
| Caer / incapacitado | 2 | — | derrota del jugador |
| Dormir (opcional) | 1 | — | cama |

Los enemigos y jefes necesitan además un cuadro de **aviso de ataque** claro (el juego dibuja la zona de peligro por código; el sprite solo debe anunciar el golpe). La hoja por estado sigue el mismo formato y ancla que la de caminata.

### Fase 4 — Escenario, enemigos e iconos
Con el estilo ya fijado en la fase 2. **Todos los tamaños de esta fase (tiles de 16×16, tamaños de enemigos, iconos) son provisionales y quedan sujetos a la prueba de escala de la fase 2.**
- **Tiles:** hierba (3 variantes), camino de arena con borde de hierba, agua, orilla de piedra, suelo de madera, pared de madera, suelo de ruina, muro de ruina o acantilado, escalones.
- **Objetos** (cada uno con su tamaño): árbol (3 variantes), roca, veta de mena, arbusto con bayas, barril, valla, cofre cerrado y abierto, cofre del tesoro.
- **Construcciones del jugador:** muro de palizada, suelo de madera, mesa de trabajo, horno, cofre, cama.
- **Edificios:** casa con tejado de tejas, chimenea, fachada con puerta y ventanas.
- **Enemigos y jefes (ejemplos, no contenido narrativo aprobado, A02 abierto):** slime (≈ 12 px), «Guardián de las Ruinas» (≈ 28 px) y «Gran Ciervo del Claro» (≈ 26 px) son propuestas de prueba. Cada uno en cuatro direcciones, con caminata y un cuadro de aviso de ataque.
- **Iconos (16×16 provisional):** madera, piedra, fibra, mena de hierro, lingote, baya, gelatina, ungüento, gema, hacha de piedra, pico de piedra y espada de hierro.

## Reglas comunes de los prompts (a partir de la fase 1)

> Original pixel art for the game Linde. Clean handheld-RPG style, overhead oblique camera (roofs and facades visible). Compact chibi proportions, readable dark outline, two or three shade tones per colour, moderate pixel clusters, no textures everywhere. One consistent pixel size across the whole image, hard pixel edges, no blur, no antialiasing, no gradients, no painted shading. Transparent background (or flat magenta #FF00FF if transparency is not possible). No text, no labels, no logos, no grid lines, no drop shadow unless asked. No licensed characters or assets.

La paleta se añade a estas reglas solo tras la fase 2.

## Qué se comprueba al recibir cada imagen

- Tamaño múltiplo de la rejilla elegida.
- Fondo transparente.
- Un único tamaño de píxel en toda la imagen.
- Cuadros alineados al ancla de los pies de la plantilla.
- Aspecto coherente con la referencia visual al verlo en el mapa.
- (Tras la fase 2) paleta compartida y nombres de archivo en minúsculas con guiones bajos.

## Pendiente

- Construir la plantilla de alineación (fase 0).
- Construir el paso de reducción, limpieza y validación cuando llegue la primera imagen real.
- Confirmar el orden de capas de espada y escudo con la prueba en el mapa.
