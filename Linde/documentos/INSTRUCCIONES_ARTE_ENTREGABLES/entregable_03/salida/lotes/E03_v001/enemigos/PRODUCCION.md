# Producción y conservación E03

Se preservan las fuentes originales de Linde y los prompts originales. Los tres suplementos se produjeron con image_gen integrado, usando atlas actuales y referencia visual de Linde; Guardián incorpora una referencia conceptual del gólem pixel del otro proyecto. El código de combate ajeno no se importa.

Conversión en Godot: partición por cuatro columnas y bandas verticales registradas explícitamente (la fuente de Slime tiene márgenes superiores irregulares; dividirla ciegamente en cuatro recortaba cuerpos). Umbral alfa0.5, componente corporal principal para quitar ruido aislado, una sola escala proporcional por actor y cuantización a la paleta previa de ese actor. Alineación al pivote original, sin escalar ancho/alto por separado ni recalibrar por cuadro. Así se conservan colores existentes, no se afirma que la paleta histórica sea una paleta global pequeña.

Las primeras cinco columnas finales se copian byteidénticas del atlas anterior. Recuperación neutral(col6) también reutiliza col0 para eliminar el cambio de tamaño/identidad que se detectó en la muestra generada. Los poses generadas de recuperación quedan en fuente, pero no se usan como obligación. Nuevos cuadros efectivos: daño, derrotaA y derrotaB por dirección,12 por actor/36 total.

El Ciervo tuvo una corrección de orientación específica en fila2/col3 de la fuente suplementaria (índices desde0): derrota mirando al norte se veía de perfil. Se usa únicamente esa celda del original corregido, conservando las otras15 de la primera fuente. Ambas fuentes y prompts se incluyen. Revisión de capturas detectó además ruido alfa que alteraba cajas y escala; el filtro corporal lo eliminó antes del cierre. Los primeros resultados no se declaran validados.

La anatomía fina, pequeñas variaciones de silueta y la suavidad de transición aún requieren aceptación visual y observación en el juego. Conservación de píxeles anteriores, formato y colores no garantizan una animación perfecta. Ningún atlas cambia reglas/hitboxes ni introduce jefes del otro proyecto.
