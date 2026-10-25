# Mundo por regiones · 2026-10-24

- Terreno: **49 comprobaciones**, sin fallos ni errores de script.
- Regresiones: protección 51, autonomía 33, sociedad 48, desarrollo 55, campaña histórica 327 e interfaz 13, sin fallos ni errores de script. La campaña usa `--campana`; el modo normal conserva la autonomía activada en paralelo.
- Integración exterior: servidor y dos clientes reales en procesos separados. Ambos cruzaron andando el borde; construyeron y compartieron un cofre protegido. Se rechazó la retirada sin permiso y se aceptó después de autorizarla. Coinciden las huellas de terreno, bioma e identificadores de recursos de ambos clientes y del servidor cargado; se comprobó el guardado final. Sin errores de script en los tres procesos.
- Red existente: 11 comprobaciones, cero fallos, incluida reconexión. Localhost, sin prueba de Internet ni 15 jugadores.
- Capturas de la escena real: valle, salida sur, bosque, sierra, secano y una región distante. El posicionamiento es de QA; la prueba de cruce real está en las suites de terreno y red.
- Memoria: prueba de treinta desplazamientos con caché acotada; unión de entornos de dos jugadores y descarga tras desconexión. El valle permanece residente.
- Medición local aislada: unos 28 ms para crear el valle y cargar 25 regiones exteriores en esta máquina; no es una garantía general de rendimiento ni generación en segundo plano.

`verificacion.json` guarda las versiones, cantidades y huellas de fuentes comprobadas. La v1 fija una huella de terreno para detectar cambios incompatibles con partidas existentes. Los registros conservan los avisos previos de recursos/objetos al salir de Godot.

La primera expansión incluye terreno y recursos. Los habitantes siguen planificando dentro del valle; colonización, viajes regionales y actividad distante resumida quedan pendientes.
