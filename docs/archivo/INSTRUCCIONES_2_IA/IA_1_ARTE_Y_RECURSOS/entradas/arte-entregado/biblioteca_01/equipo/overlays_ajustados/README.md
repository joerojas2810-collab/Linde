# Equipo ajustado — capas estáticas candidatas

Se corrigió técnicamente la extracción experimental con Godot, sin una nueva generación y sin alterar los originales. Se conserva la prueba fallida de `../overlays_experimentales/` para comparar.

## Cambios y resultado

- Casco y coraza: máscara de metal con saturación menor de 0,30 y valor mayor de 0,30; excluye pelo teal y piel. Se añade un contorno oscuro de un píxel derivado de sus cuatro vecinos, para separar el metal del cuerpo.
- Cada pieza se recorta, se ajusta **conservando su relación de aspecto** a un rectángulo manual de la celda de 32 × 32, y se alinea sobre la base aprobada.
- La coraza ahora ocupa el torso y deja el rostro descubierto. El casco conserva la lectura de la cara y cubre la parte superior del pelo.
- Escudo y espada se ajustaron tras inspeccionar su proximidad a las manos. En el perfil derecho el escudo va detrás del cuerpo; en el izquierdo la espada va detrás. Las otras orientaciones usan las piezas delante.

`manifest.json` registra los rectángulos exactos finales, incluida la revisión de armas tras la primera composición. Son decisiones de alineación propuestas, no dimensiones artísticas aprobadas por el usuario.

## Archivos

- 16 PNG individuales, cuatro tiras de 128 × 32 px.
- Cuatro atlas de 128 × 128 px, celda 32 × 32. Filas: frente/derecha/espalda/izquierda; columnas: **la misma pose estática repetida cuatro veces**.
- Los atlas tienen también alias `personaje_casco.png`, `personaje_coraza.png`, `personaje_escudo.png` y `personaje_espada.png`, compatibles en dimensiones y disposición con `capas_sprite.gd`.
- `personaje_equipo_fragmento.json` sirve para añadir los cuatro nombres al manifiesto existente; **no reemplaza el manifiesto del cuerpo**.
- `composiciones_nativas_128x192.png` y su ampliación: base, casco, coraza, escudo, espada, equipo completo.
- `checks.json`: alfa binaria, tamaño de atlas y repetición exacta de fotogramas.

## Límites de esta prueba

Son **capas estáticas candidatas para probar en el mapa**, no una animación terminada. Al caminar con las columnas repetidas, las manos y el equipo no acompañarán exactamente la zancada. La postura base no fue dibujada con dedos agarrando una empuñadura; faltan máscaras específicas de manos/antebrazos y pruebas con variantes de pelo y ropa. En perfiles, el cuerpo puede ocultar gran parte del equipo lejano.

La combinación estática fue inspeccionada: el fallo grande de la coraza quedó reparado y las piezas son distinguibles. Falta aceptación artística dentro del mapa y comprobación de todas las combinaciones/animaciones. No se modificó el juego, mapa ni renderer en esta tarea.

Script reproducible: `../ajustar_overlays.gd` (Godot 4.7.1). La procedencia image_gen y el prompt permanecen en la carpeta experimental. Ajustar por máscara no añade una licencia ni cambia el registro de origen.
