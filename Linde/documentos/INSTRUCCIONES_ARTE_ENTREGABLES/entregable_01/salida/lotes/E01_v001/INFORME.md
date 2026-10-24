# E01 — Ataque y equipo, lote v001

Fecha: 24/10/2026. Estado: **candidato validado estructuralmente, revisado visualmente en composiciones estáticas; pendiente aceptación y prueba en Godot**. Repositorio fuente: `42292a0b25554ef46cd914d95e91fc0590f68d9e`.

## Hecho

- 17 hojas completas de ataque: seis ajustadas y once copiadas byte a byte. Nueve celdas antes vacías tienen contenido; las restantes **263/272 celdas son idénticas en RGBA**. Los nombres de archivo se conservan para facilitar el encaje; IDs exclusivos E01 en manifiesto.
- Base y sus siete capas reutilizadas sin cambiar píxeles ni hashes. Caminata activa intacta. Las 17 entradas de ataque de la instantánea coinciden por hash con el checkout descargado.
- Estela independiente: **102 píxeles originales** recuperados en [0,3]=13, [1,2]=12, [1,3]=41, [2,3]=24, [3,1]=12. Sin impactos ni cambios de hitbox.
- Torso: material índice reutilizado de la caminata y ajustado por filas a la ropa/silueta de ataque, protegiendo piel, pelo y cinturón. Pesada conserva cobertura adicional de hombro. Botas ajustadas a pies reales, sin traslación rígida flotante; media cubre un píxel más de tobillo. El JSON conserva cada píxel editable y su origen.
- Escudo: reutiliza exactamente la forma frente/0 de caminata, trasladada [4,16] a la celda de 48. Se corrigió una primera colocación alta durante la revisión. La cara queda libre; la espada se mantiene delante según el contrato existente.
- Galería HTML local con tres arquetipos, tres familias, cuatro direcciones, zoom 1/3/5, pausa y avance por cuadro. Composiciones con/sin escudo y base con armas. GIF por arquetipo/familia; hojas x1/x3 y comparaciones independientes por celda.
- Validación automática de tamaño, índices exactos, alfa, contenido de 16 celdas, margen de borde, silueta ±3, lista exacta de cambios e integridad de entradas. Las nueve celdas ajustadas tienen además 0 píxeles fuera de silueta ±1. Ver validacion/E01_resultados.json.

## Reutilizado / ajustado / nuevo

INVENTARIO.json identifica rutas y hashes de cada hoja. MANIFIESTO.json incluye todos los archivos de este lote, procedencia, restricciones y estado. Nuevos: estela separada, overrides, contratos, herramientas y previews. No se adoptó una paleta global nueva.

## Revisión visual realizada

Se inspeccionaron los PNG a zoom 3, cuatro direcciones, tres arquetipos, con y sin escudo, incluida la composición base/armas; se compararon Zarzal y Albor. Se comprobó la separación de pies, protección de cara y la superposición de espada. La revisión usa un compositor aislado que refleja orden/ocultación del código actual, sin tintar apariencia de base ni simular joyas/deltas. Las composiciones no acreditan integración real. La muestra generada sirve solo como propuesta, cambia densidad y no forma parte de assets/.

## Parcial y pendiente

- **Agarre del escudo frontal:** la fuente no muestra una mano libre medible. Se propone ancla de torso; el agarre queda oculto. Requiere aceptación visual, no se afirma una mano reconstruida ni un agarre probado.
- **Estela:** se conserva el contenido fuente, incluso anticipación izquierda [3,1]. El integrador decide si ese instante permanece. Se propone sobre espada; oclusión y temporización requieren revisión en Godot.
- **Oclusión:** la mano lejana y los perfiles de las celdas aceptadas se conservan; no se corrigieron fuera del alcance. Revisar con todas las ranuras/familias/variantes, jugador local y remoto.
- **Aceptación:** no se obtuvo aprobación de usuario, coordinador, director de arte ni integrador. Los pendientes vacíos en el manifiesto propuesto significan contenido candidato, no aprobación. El manifiesto original permanece intacto.

## Bloqueos y límites de prueba

Run result: **no ejecutado en Godot**. No se encontró Godot en PATH ni en las ubicaciones locales revisadas; la configuración proporcionada apunta a un ejecutable macOS ajeno a Windows. No se instaló otro motor ni se ejecutó el juego activo. No se atribuyen pruebas históricas al lote nuevo. La recepción final depende del integrador con el motor del proyecto.

## Reproducir y recibir

1. Con Python 3, Pillow y NumPy, ejecutar `python E01_producir.py` desde la raíz de salida o `python lotes/E01_v001/fuentes/herramientas/E01_producir.py`. La primera ejecución dentro del repositorio congela las entradas; el ZIP ya las incluye.
2. Ejecutar `python E01_finalizar.py` para regenerar contratos/galería/manifiesto (requiere el checkout para comparar producción). El ZIP entregado incluye esos resultados, no hace falta regenerarlos para revisar.
3. Abrir GALERIA.html sin servidor ni conexión. Ver también previews/E01_comparacion_nueve_celdas.png.
4. El integrador verifica hashes contra producción antes de copiar; no ejecutar derivar_ataque.gd sobre correcciones. Conservar overrides externos. Probar con Godot 4.7.1, ocultación de ropa base, pies/pivote, fases de ataque, caché/recoloreado y ambos clientes. Conectar estela por separado; el cargador actual no lee su campo propuesto.

## Procedencia y permisos

Originales del repositorio Linde y biblioteca/equipo suministrados por el usuario. Se conserva procedencia en fuentes/entradas/PROCEDENCIA_EQUIPO_ORIGINAL.md (nombre real sin espacio). No se encontró una licencia específica que permita atribuir CC0/OFL a estos sprites: **licencia de redistribución no certificada**, confirmar con sus autores. No se copió arte externo. La muestra fue generada con image_gen integrada; no se promete reproducibilidad exacta de esa muestra, sí de los PNG productivos compilados desde overrides y fuentes congeladas.

Escrituras limitadas a entregable_01/salida. Sin commits, publicación, cambios del juego ni otros entregables.
