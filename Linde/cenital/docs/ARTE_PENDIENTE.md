# Arte pendiente del mundo — 25/10/2026

Auditoría hecha leyendo `scripts/mundo_arte.gd` y `arte/mundo/`. Formato destino: PNG de 16 px por celda (copas/troncos de 64 px para árboles), con pivote en `E04_objetos.json`.

## Sprites compartidos o prestados (sustituir primero)

| Objeto | Hoy | Falta |
|---|---|---|
| `veta` (hierro), `veta_cobre`, `veta_estano` | los tres usan `E04_ore_copper.png` con un tinte (`TINTE_MENA`) | un sprite propio por mena y su variante agotada (`E04_ore_depleted` es común) |
| `arcilla` (pozo) | `E04_rock` con tinte rojizo | pozo de arcilla propio, lleno y agotado |
| `roca` | un solo sprite | 2–3 variantes (mismo tamaño) para romper la repetición |
| `arbusto` | un par con y sin bayas | 2 variantes más, y un arbusto sin bayas propio por bioma |

## Vegetación por bioma (no existe)

Los suelos ya son propios por bioma, pero los objetos son los del valle. Por bioma faltan:

- **Sierra:** peñasco grande, pino ralo.
- **Secano:** árbol seco, matorral espinoso, roca de arenisca.
- **Pradera:** arbusto bajo con flores.
- **Ribera:** juncos y cañas (cruzan el borde del agua).
- **Bosque:** helecho y tronco caído.

## Fauna

Las 5 criaturas regionales reutilizan 20 tiras de `Nuevo Juego/public/art/enemies-px`: solo vista frontal, criaturas fantásticas. Falta orientación lateral/espalda y, si se quiere fauna "animal" real, especies nuevas.

## Equipo

Espadas, escudos y armaduras generados recolorean geometría existente: faltan siluetas nuevas.

## Cómo añadirlo

Generar el PNG, copiarlo a `arte/mundo/`, registrarlo en `E04_objetos.json` (archivo, canvas, pivote) y cambiar la clave en `mundo_arte.gd` (`natural()`); `TINTE_MENA` puede borrarse cuando cada mena tenga arte propio.
