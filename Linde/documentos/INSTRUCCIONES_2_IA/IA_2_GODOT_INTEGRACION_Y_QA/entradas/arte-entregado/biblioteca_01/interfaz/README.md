# Linde — Interfaz e iconos, entrega 01

**Estado:** biblioteca inicial de recursos nativos propuestos, 2026-10-23. No modifica código del juego ni fija la resolución artística del proyecto.

Abrir `galeria.html` para ver los archivos reales al triple de su resolución, con píxel duro. `galeria.png` es un contacto rápido sin etiquetas; la galería HTML tiene el tamaño correcto de cada ficha, sin superposiciones.

## Incluido

- 20 iconos en lienzo de **32 × 32 px**: madera, piedra, fibra, mena de hierro, lingote, baya, gelatina, ungüento, gema, hacha, pico, espada, casco, coraza, escudo, oficio, exploración, combate, comunidad y misión.
- 16 piezas de interfaz: panel de pergamino, tres estados de casilla, tres de botón, marco y barra llena de vida, tres estados de nodo de habilidad, marcador de misión, indicador de interacción, panel de tooltip y contador vacío.
- Una textura adicional de relleno rojo de **44 × 5 px**, extraída del interior de la barra generada: total **37 PNG individuales**.
- Panel de nueve regiones, márgenes izquierdo/superior/derecho/inferior **8/8/8/8 px**, lienzo **64 × 48 px**. Probado en Godot con salidas **96 × 64, 160 × 96 y 192 × 128**: esquinas exactamente conservadas. Ver `prueba_ninepatch.png` y `ninepatch_check.json`.

El tamaño de iconos de 16 × 16 mencionado anteriormente era provisional. Se eligió 32 × 32 para esta entrega porque conserva la separación de materiales y las siluetas; la galería se inspeccionó y son reconocibles a esta resolución. Falta validar su tamaño físico en el HUD real. No se entregan reducciones de 16 px como si estuvieran aprobadas.

## Integración

`manifest.json` registra ID, archivo, tamaño, región de origen y tipo. Usar filtro **nearest**, mipmaps desactivados y escalas enteras. Conservar los márgenes transparentes de cada lienzo.

En Godot, `panel.png` se puede usar en `NinePatchRect` o `StyleBoxTexture` con márgenes 8. Su tamaño mínimo recomendado es el original 64 × 48; no reducir por debajo. El centro está preparado para estirarse y se debe comprobar su acabado con el texto final.

Los otros widgets son texturas de tamaño fijo; no están certificados como nueve regiones. Los estados de botón y casilla tienen pequeños cambios de silueta internos de origen generativo. Colocarlos en el mismo rectángulo de control y comprobar visualmente el cambio de estado. No se prometen contornos idénticos.

`healthbar_full.png` es la muestra llena. `healthbar_frame.png` y `healthbar_fill.png` son piezas separadas; deben componerse con un rectángulo interior configurado por el integrador, con recorte para la cantidad de vida. **No incluyen comportamiento ni se comprobó una barra animada en el juego.**

La interfaz no contiene texto: nombres, cantidades, descripción, estados de accesibilidad e input se dibujan en el motor. Los marcadores son ilustraciones estáticas, no animaciones.

## Procedencia y comprobaciones

Dos láminas originales creadas con la herramienta integrada `image_gen`, sin importar recursos de terceros. Prompts completos en `PROMPTS.md`; originales en `original_iconos.png` y `original_widgets.png`.

`convertir.gd`: recorte de regiones, umbral de alfa 0,5 y reducción de vecino más próximo mediante Godot 4.7.1; `galeria.gd`: contacto y prueba de nueve regiones. No se usó Python para editar imágenes.

`checks.json`: 36 conversiones comprobadas con píxeles opacos no vacíos y cero alfa parcial. El relleno adicional procede de la muestra roja ya binaria; hay 37 archivos finales. Se inspeccionaron visualmente el contacto y los paneles estirados. No hay prueba interactiva de HUD ni contrato de accesibilidad.

Para regenerar desde esta carpeta, usar Godot 4.7.1:

```
Godot --headless --log-file /tmp/linde_ui_convert.log --path . --script convertir.gd
Godot --headless --log-file /tmp/linde_ui_gallery.log --path . --script galeria.gd
```

La ejecución local terminó con código 0. El sandbox impidió crear el directorio de usuario de Godot y emitió avisos del almacén de certificados; los procesos no necesitaron esos directorios, escritura externa ni red. Se indicaron logs temporales para evitar un fallo del logger durante el primer intento.

No se asigna una licencia de terceros ni se garantiza exclusividad jurídica sobre las imágenes generadas. Son candidatos originales para el proyecto, con procedencia conservada. No contienen logotipos ni personajes licenciados.
