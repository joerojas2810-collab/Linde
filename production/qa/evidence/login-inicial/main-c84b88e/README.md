# Integración de acceso inicial con main c84b88e — 26/10/2026

El usuario autorizó revisar el main remoto y subir todos los cambios aprobados. Se incorporó main c84b88e (talleres, casas comunales y primer bloque de tareas de Fase 6) en feature/login-inicial mediante cdac6e9. Coincidencias únicamente en CONTINUIDAD y ESTADO, resueltas conservando ambos trabajos. Escena combinada sin conflictos; núcleo Juego/Tareas/Asentamientos/Autonomía idéntico al main revisado.

## Validación de la versión combinada

- 9 casos unitarios Python, sin fallos (servicio e identidad; incluye contraseña corta).
- 16/16 comprobaciones de acceso y partidas, usando autoridad aislada: flujo.json.
- 13/13 comprobaciones de cuenta global y reconexión, dos mundos y clientes reales: identidad.json. Contraseñas independientes, prevención de sesión duplicada, progreso conservado y autoridad disponible sin mundos.
- 6/6 suites de regresión: UI 13, reglas 82, taller UI 7/red 36, autonomía 33 y sociedad 48; regresion.json y logs adjuntos.
- Tareas 16/16: tareas.txt. El primer intento directo falló al guardar en /tmp (ruta Linux sin unidad en Windows); repetición mediante copia temporal ignorada, adaptando solo el prefijo a OS.get_cache_dir(), sin modificar la suite ni el juego.

No se repitió toda la batería. Sin prueba en otra PC física ni Internet. Errores JSON deliberados del ensayo de recuperación y avisos conocidos de ObjectDB/recursos al salir, con comprobaciones superadas. Las pruebas usan cuentas ficticias fuera de los datos reales.

Incluye acceso antes del menú, identidad independiente, partidas por cuenta, formularios con arte existente y contraseña obligatoria sin longitud mínima adicional (máximo 128). Galería aprobada y comparativa en ../estetica/GALERIA.html. No incluye bases de cuentas, claves, sesiones, configuración privada ni la skin pausada.
