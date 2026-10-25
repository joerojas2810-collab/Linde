# Auditoría independiente del lote de equipo

Fecha: 2026-10-23. Revisión sin modificar las hojas, la base ni el validador.

## Resultado de formato

Se encontraron exactamente **17 PNG** en `hojas/`: 15 hojas de cinco ranuras × tres arquetipos y dos hojas compartidas (escudo y espada). Se ejecutó **el validador original del proyecto del escritorio**, no una versión modificada, con `--celda=32 --modo=indice --base=base/caminata.png` y un informe JSON por archivo.

**17 salidas 0; cero errores y cero avisos.** Los informes completos y salidas del proceso están en `auditoria/`; `auditoria/resumen.json` registra las sumas SHA-256 de todas las entradas.

SHA-256 del validador original: `18eb68a6c4a02f24e75ed7fa9a4f0408e4cb3f922addf58095de756e5f6a5ca0`.

La base distribuida coincide byte a byte con la caminata de biblioteca_01:

`ca27efc8830dbe165bee7188f143b21a6a99c809791735d4a0e4df0bc1734347`.

Las 17 hojas cumplen dimensiones 128 × 128, colores índice, alfa binaria, contenido por celda, margen, silueta de la base ±3 px y variación de cuadros según las comprobaciones del contrato. Esto certifica esas reglas, no calidad artística o aceptación final.

## Movimiento y fuentes

Se revisó `herramientas/producir.gd`. Casco y torso se transportan horizontalmente por cada línea de la silueta real de la base entre cuadros. El algoritmo no introduce desplazamiento vertical periódico ni cambios de color para evitar el aviso de poses repetidas. Guantes, botas y pantalones se derivan de los píxeles de la caminata; escudo y espada se sitúan respecto de las manos.

El análisis independiente de capas está en `anchors_base.json`. En espalda, las cajas globales de pelo y túnica son constantes, aunque existen variaciones de contorno por línea y de píxeles dentro de esas cajas. Por ello, que las columnas difieran no equivale por sí solo a demostrar una animación fluida. Algunas variaciones pequeñas pueden ser irregularidades de la base. La revisión del ciclo en movimiento continúa siendo necesaria antes de considerar el acabado cerrado.

Las botas base llegan a y=30; existe margen inferior de un píxel. El validador confirma que las hojas nuevas conservan libre el anillo exterior.

## Revisión visual

Se observaron `previews/arquetipos_recoloreados.png` y `previews/equipo_completo.png`. Son legibles las cuatro orientaciones y las diferencias de gorro/casco y torso de los arquetipos; la cara permanece visible y las piezas siguen la escala del personaje. Se aprecia el equipo compartido superpuesto sin recorte de la celda en esas capturas. Las paletas mostradas son demostrativas, no paletas de familia aprobadas.

Estas capturas estáticas no certifican fluidez, agarre durante todo el ciclo, todas las combinaciones cruzadas de ranuras ni el comportamiento de oclusión del cargador del juego actual. La escena es una muestra aislada de arte; no prueba integración de red, inventario ni equipamiento en el repositorio vigente.

## Reutilización y límites

Los recursos nuevos preservan la base aprobada. Ligera y pesada incorporan fuentes diferenciadas de casco/torso; media reutiliza las fuentes anteriores. Algunas ranuras conservan la misma silueta entre arquetipos: los guantes ligera/media y los pantalones media/pesada son idénticos, según SHA-256. Esto debe permanecer explícito; no se han producido 15 siluetas completamente distintas. El contrato distingue arquetipos y permite siluetas compartidas, pero una dirección artística que exija diferencias en cada ranura requiere un lote adicional.

No se produjeron aquí hojas de herramienta ni ataque. No se modificó código del juego.
