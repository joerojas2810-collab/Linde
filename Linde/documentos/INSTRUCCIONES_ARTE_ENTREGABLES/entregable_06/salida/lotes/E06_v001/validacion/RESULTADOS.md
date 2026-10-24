# Comprobación E06, 24/10/2026

- 37 PNG reutilizados idénticos por SHA-256 al origen; ocho nuevos32x32, no vacíos, alfa binaria y máximo25 colores opacos;45 PNG de recursos comprobados. Dos SVG y un shader complementarios.
- Godot4.7.1/OpenGL Compatibility Apple M3: ejecución gráfica final terminó0, siete capturas reales1280x720 (seis pantallas diurnas y HUD nocturno). Sin errores de script/render en log final.
- Se inspeccionaron capturas, se corrigieron bandas oscuras en títulos, alineación del menú y escala no entera de casillas. Son capturas de preview con fondo conceptual, no del juego activo.
- Región de barra/HUD idéntica entre día y noche; región del mundo distinta. Comprobación binaria en capturas.json. Texto de hora cambia intencionadamente.
- Font.has_char verificó ÁÉÍÓÚÜÑáéíóúüñ¿¡ y números sin glifos faltantes; muestra de lectura renderizada. Fuente y OFL reales incluidas. No constituye auditoría completa de accesibilidad ni de todos los idiomas.
- Primer import encontró errores de script que fueron corregidos. En sandbox la ejecución gráfica abortó antes de abrir ventana; el render real se ejecutó con permiso y terminó0. Los procesos headless iniciales emitieron avisos de user://, certificados y settings del entorno; no se ocultan como si fueran fallos del juego. Los logs finales de conversión/font pueden conservar aviso de certificados; no requirieron red.
- No se ejecutaron suites del juego, peers de red ni integración a HUD productivo: no se modificaron. No hubo aceptación visual del usuario ni revisión humana de interacción física de teclado. Los atajos están implementados en preview y se dejan reproducibles.
