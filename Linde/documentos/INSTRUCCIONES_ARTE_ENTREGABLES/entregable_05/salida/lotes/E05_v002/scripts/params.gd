extends RefCounted
# Valores centralizados. Todos PROVISIONALES (propuestas P03/P04), sin balance heredado.
const CELDA := 16               # px por celda (P04)
const VELOCIDAD := 64.0         # px/s = 4 celdas/s; provisional, ajustar con prueba de sensación
const PIES := Vector2(10, 6)    # px, caja de colisión a los pies (ancho, alto)
const SPRITE := Vector2i(16, 24)  # px del PJ; ancla = centro-abajo (pies)
const PASO_S := 0.12            # s por cuadro de caminata (4 cuadros)
const ZOOM := 3                 # entero, filtrado nearest
const LOCAL := "local"          # id del jugador local (por defecto en todas las acciones de Juego)
const PIEL := [Color("f1c9a5"), Color("d9a066"), Color("8d5524")]
const PELO := [Color("2b1b12"), Color("a5652d"), Color("e0b84a"), Color("7a3b8c")]
const ROPA := [Color("3b6fb6"), Color("b6453b"), Color("4a9a56")]
const PANTALON := Color("3a3a52")
const OJOS := Color("1b1b1b")
