# LINDE · Biblioteca inicial de escenario

36 PNG nativos generados para continuar la dirección visual aprobada del pueblo. No son el escenario integrado del juego ni un paquete final. Abrir `catalogo.html` para inspeccionar cada ID o `catalogo.png` para una vista conjunta.

## Contenido

- 16 tiles de 16×16 px: dos hierbas, camino, agua, cuatro bordes camino-hierba, cuatro orillas, suelo de madera, muro de piedra, suelo de ruinas y escalones.
- 16 objetos en lienzos de 48×48 px: tres árboles, roca, cobre, arbusto, barril, valla, cofre cerrado/abierto/con tesoro, banco, horno, cama, empalizada y puente.
- 4 construcciones de 96×96 px: casa con puerta cerrada/abierta, cobertizo de trabajo y entrada de cueva.
- 3 hojas originales generadas conservadas sin modificaciones en `originales/`.
- `manifest.json`: IDs, archivo, tamaño, pivote provisional, celda de procedencia y estado.
- `config.json` + `convertir.gd` + `medir.gd`: extracción reproducible mediante Godot 4.7.1. `PROMPTS.md`: instrucciones exactas de las tres generaciones.

## Conversión y comprobación

Se recortaron las celdas del atlas, ajustando manualmente los límites entre filas de objetos porque la generación no respetó una rejilla uniforme. Los objetos se ajustan proporcionalmente dentro del lienzo con margen y apoyo inferior; el terreno usa un recorte interior de 1 px para evitar líneas de separación y se reduce a 16×16. Escalado por vecino más cercano y umbral de alfa 0.5, sin suavizado. Godot exportó correctamente los 36 archivos. El catálogo nativo completo fue inspeccionado visualmente. Las transparencias son binarias por construcción. No se normalizó una paleta común ni se volvió a dibujar el arte con rectángulos.

Para repetir en un entorno con Godot disponible: `godot --headless --path . --script res://convertir.gd` y después `godot --headless --path . --script res://medir.gd`. El segundo paso registra bbox real, pivote al centro inferior del bbox y tamaño de dibujo propuesto por familia.

## Pendiente antes de integrar

- Calibrar el tamaño físico de cada familia junto al personaje y una puerta. Todos los objetos comparten un lienzo; `expected_draw_size` propone una escala por familia (árbol32, roca16, cofre24, por ejemplo), aún sin aprobar en mapa. El catálogo amplía objetos ×2 y tiles ×6: no representa su escala de juego.
- Ajustar pivotes según la base real visible: se midió el centro inferior del bbox, pero ese anclaje debe contrastarse con el apoyo de cada objeto en el suelo. Separar volumen de colisión y copas/tejados para oclusión.
- Comprobar y retocar bordes: existen transiciones cardinales, pero faltan esquinas internas y externas, conexiones, desembocaduras y un TerrainSet. No se ha certificado continuidad del teselado.
- Casa cerrada/abierta son variantes de generación: no son cuadros de una animación alineada píxel a píxel. Necesitan alinear fachada/tejado antes de animar o sustituir solamente la puerta.
- Construcciones son sprites completos, no un kit modular. El muro es un tile visual, no un sistema de muros conectables.
- Agua, horno y vegetación están quietos. Objetos destruibles necesitan estados adicionales y su propia lógica, sonidos y efectos.
- Colores y densidad de detalle requieren revisión conjunta con personajes/equipo. La propiedad de uso y política legal de imágenes generadas debe evaluarse para la distribución prevista; este documento no afirma exclusividad ni copia una licencia upstream.

## Procedencia

Producción nueva con image_gen integrada a partir de la referencia original de LINDE y las instrucciones incluidas. No se importó arte de Pokémon, Helbreath ni otros repositorios. Los originales permanecen disponibles para revisión. La extracción técnica no convierte automáticamente el material en un tileset validado.
