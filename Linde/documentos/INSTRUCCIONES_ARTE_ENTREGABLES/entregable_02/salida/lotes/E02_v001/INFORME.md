# Entregable 02 — personaje, herramienta y estados

24/10/2026. **Candidato producido, validado estructuralmente y revisado en un preview aislado de Godot 4.7.1.** No es integración en el juego activo.

## Hecho

- 125 PNG nativos: cuatro estados, siete capas de base por estado, cinco ranuras por arquetipo, guantes cercanos/lejanos, escudo/espada candidatos y hacha independiente.
- Fuente de herramienta reutilizada: cuatro poses × cuatro direcciones, sin rediseñar identidad ni caminata. La base, el hacha y las islas excluidas recombinan exactamente el original. Solo la pieza principal del hacha se entrega como arma; las islas siguen en fuentes.
- Daño: dos poses por dirección. Caída: dos poses. Dormir: una pose. Se generó una fuente referenciada, conservada con su prompt, y se normalizó a la escala nativa usando una sola escala para todas las poses. Colores remitidos a la paleta original por región semántica; no se crea una paleta global nueva.
- Equipo reutilizado y ajustado por capas a cada pose para ligera/media/pesada, sin rehacer las caminatas ni las variantes de color. Hojas combinadas de guantes y dos capas por profundidad con unión exacta.
- Decisiones humanas confirmadas: anticipación/golpe/recuperación [1,2,3] a 100 ms por cuadro; cinturón visible; pelo debajo del casco. Esto no equivale a aceptación artística completa de las hojas nuevas.
- 500 comprobaciones estructurales correctas. 5836 comprobaciones del prototipo en Godot: 0 fallos. Doce capturas retenidas de motor, tras 60 fotogramas por presentación, cubren cuatro estados × tres arquetipos, con cuatro direcciones y todos los cuadros lógicos.
- Contactos, hojas x1/x3 y GIF; galería HTML sin conexión. El preview Godot permite cambiar estado/equipo, pausar y avanzar cuadro. La fuente editable es el raster congelado más recortes/algoritmo; todos los PNG se pueden recompilar.

## Revisión visual y ajustes

Se revisaron herramienta/pesada, daño/media, caída/ligera y dormir/pesada en capturas reales a zoom 3. Durante producción se corrigió la clasificación de pelo oscuro, se hizo exacta la recomposición de guantes y se corrigió el escudo de herramienta para no colgarlo de la mano levantada con el hacha. Se conserva la cara fuente de cada dirección. Los sprites nuevos simplifican algunos detalles al llevarlos a resolución nativa; requieren aceptación artística.

## Parcial / pendiente

- Integración en el juego: el prototipo nuevo no reemplaza el compositor actual. Falta conectarlo a inventario, selección de herramienta y jugadores local/remoto. La 01 permanece intacta.
- Caída/dormir no se activan en el juego; se entregan las poses y el contrato sin inventar eventos ni cambiar mecánicas. Los 450 ms del GIF/preview son solo demostración, no duración de gameplay.
- La única herramienta ilustrada es hacha. No se inventó un pico ni se reutiliza el hacha como uno; su producción debe autorizarse si se requiere ampliar el alcance.
- Agarres ocultos y silueta de equipo: candidatos ajustados, no aprobación de director de arte. Las manos que faltan por oclusión no se rellenan con una mano ficticia. Se declaran 34 celdas transparentes de capas aisladas; no son necesariamente huecos de la composición.
- 52 incidencias de contenido en borde, todas en herramienta, heredadas de la fuente. Las nuevas poses de daño/caída/dormir tienen margen. No se alteró la fuente para pasar un validador genérico.
- No se probaron red real, exportación ni secuencia de daño dentro del mapa. El parpadeo/invulnerabilidad no se cambia; el preview no lo simula.

## Bloqueado

Sin bloqueo de producción del lote. La recepción final depende de revisión artística e integración. No se afirma aceptación del usuario sobre las nuevas poses, solo sobre las dos decisiones explícitas.

## Pruebas y reproducibilidad

`python herramientas/E02_producir.py` y `python herramientas/E02_validar.py` desde la raíz de salida (Python + Pillow + NumPy). El archivo generado original ya está incluido; no requiere volver a llamar a image_gen. Para validar el hash del lote, consultar MANIFIESTO.json. Abrir `project.godot` dentro de lotes/E02_v001 con Godot 4.7.1 para reproducir la escena. Las pruebas son de este prototipo, sin atribuirle las 313 de E01 ni otras históricas.

Run result: ejecutado con ventana en Godot 4.7.1.stable.official.a13da4feb. Log final E02_motor.log sin errores de script; JSON y capturas en validacion/. El primer intento detectó una inferencia de tipo en el prototipo; se corrigió y se repitió la ejecución antes de emitir los resultados finales.

## Procedencia

Arte de biblioteca_01 y equipo entregado por el usuario, con originales/prompts locales incluidos como fuentes. Estados nuevos generados mediante image_gen integrada y normalizados con un pipeline técnico. No hay certificación de exclusividad ni licencia CC0 inventada: confirmar redistribución con los autores. Ningún recurso externo licenciado ni contenido de otra franquicia.

Escrituras de trabajo limitadas a entregable_02/salida, con paquete de entrega en outputs. No se modificó el juego abierto, scripts de gameplay, Maren, ataque E01, balance, guardados, red ni otros entregables. Sin commits ni publicación.
