# PENDIENTE DE ARTE: ataque con equipo (celda 48)

Generado por `herramientas/arte/derivar_ataque.gd` (no editar a mano; volver a ejecutar). Cada línea es una celda que NO se pudo derivar con calidad aceptable de forma automática y se dejó vacía: en esa dirección y pose el juego NO dibuja esa pieza y deja visible la capa base de `ataque.png` que la pieza ocultaría (el cuadro estático de caminata quedaba suelto o desplazado sobre la pose; visto en las tiras).

Umbrales: IoU >= 0.38 de la capa de referencia, <= 12 % de la pieza fuera de la silueta de `ataque.png` (dilatada 1 px).

| Hoja | Dirección | Pose (columna) | Motivo |
|---|---|---|---|
| ligera/torso | frente | impacto (2) | seguimiento rígido insuficiente: IoU 0.33 (mín 0.38) de 'tunica', 0 % de la pieza fuera de la silueta (máx 12 %) |
| ligera/botas | derecha | impacto (2) | seguimiento rígido insuficiente: IoU 0.41 (mín 0.38) de 'pies', 17 % de la pieza fuera de la silueta (máx 12 %) |
| ligera/botas | izquierda | impacto (2) | seguimiento rígido insuficiente: IoU 0.46 (mín 0.38) de 'pies', 14 % de la pieza fuera de la silueta (máx 12 %) |
| media/torso | frente | impacto (2) | seguimiento rígido insuficiente: IoU 0.33 (mín 0.38) de 'tunica', 0 % de la pieza fuera de la silueta (máx 12 %) |
| media/botas | derecha | impacto (2) | seguimiento rígido insuficiente: IoU 0.41 (mín 0.38) de 'pies', 13 % de la pieza fuera de la silueta (máx 12 %) |
| pesada/torso | frente | impacto (2) | seguimiento rígido insuficiente: IoU 0.33 (mín 0.38) de 'tunica', 12 % de la pieza fuera de la silueta (máx 12 %) |
| pesada/torso | derecha | impacto (2) | seguimiento rígido insuficiente: IoU 0.55 (mín 0.38) de 'tunica', 21 % de la pieza fuera de la silueta (máx 12 %) |
| pesada/torso | derecha | recuperacion (3) | seguimiento rígido insuficiente: IoU 0.53 (mín 0.38) de 'tunica', 15 % de la pieza fuera de la silueta (máx 12 %) |
| compartido/escudo | frente | impacto (2) | sin mano libre medible en ataque.png ni torso aceptado para anclar |

## Estela de la espada (efecto) descartada

Islas de estela separadas del cuerpo y de la espada en `ataque.png`; no son equipo y quedarían flotando. Falta una capa de efecto propia (celda fila,columna: píxeles): { "0,3": 13, "1,2": 12, "1,3": 41, "2,3": 24, "3,1": 12 }
