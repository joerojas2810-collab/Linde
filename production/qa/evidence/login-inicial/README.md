# Acceso inicial y cuenta única de Linde — 26/10/2026

Solicitud del usuario: iniciar sesión o registrarse **antes del menú**, y después crear/cargar/alojar/unirse. Se consultó si bastaba un perfil local; eligió explícitamente **cuenta única entre PC**. Rama `feature/login-inicial`, base `d223398`. Este ajuste no se publicó ni fusionó con main durante su revisión.

## Qué cambia

- Servicio independiente de identidad (TCP7790), reutilizando SQLite/Argon2id/HTTPS. Su disponibilidad no depende de tener un mundo abierto. Primera configuración explícita de autoridad; las demás PC apuntan a esa misma autoridad/certificado. En la PC anfitriona se reactiva el servicio previamente configurado, sin sustituir datos perdidos. Cerrar una partida o el juego no lo detiene.
- Acceso inicial → menú de siete opciones → guardados locales propios o conexión a mundos. Los mundos no solicitan otra cuenta ni contraseña global.
- PyJWT/cryptography validan RS256, emisor, audiencia y caducidad. Una sesión de dos horas solo se entrega a identidad; se canjea por un permiso de 60 segundos ligado al certificado del mundo. Se evita reutilización, incluido el margen de reloj de cinco segundos; después se reutiliza el ticket de un uso/DTLS. La contraseña del mundo permanece independiente.
- Varios guardados locales por identidad, dueño explícito, respaldo válido y última partida seleccionada. Los archivos locales no se sincronizan en nube. El progreso multijugador permanece en el servidor y reconoce el mismo ID global desde otras instancias. No se atribuyen archivos antiguos ni se migran reglas por coincidencia de nombre.

## Pruebas ejecutadas

- **8 casos unitarios Python, sin fallos** (`python.txt`): cuatro previos más identidad, firma/algoritmo/emisor/audiencia/expiración, permisos ligados a destino y de un uso, reutilización durante tolerancia de reloj y contraseñas independientes.
- **16 comprobaciones de flujo real de Godot, sin fallos** (`flujo.json`, `flujo.txt`): acceso bloquea el menú, servicio arrancado desde su configuración, registro, menú posterior, propiedad de partidas, crear dos sin sobrescribir, cargar progreso, Continuar recuerda selección, recuperación de respaldo, logout, aislamiento de otra cuenta, error de contraseña y mismo ID/partidas al reiniciar identidad desde otra instancia.
- **13 comprobaciones de identidad y mundos con procesos reales, sin fallos** (`integracion.json`, `integracion.txt`): cuenta creada sin mundo; otro login devuelve el mismo ID; dos servidores aceptan la misma identidad; sesión duplicada por mundo bloqueada; contraseña de mundo independiente; sus SQLite no contienen cuentas globales duplicadas; el mundo rechaza login paralelo y token global directo; reinicio recupera inventario/XP/identidad; la autoridad sigue respondiendo con todos los mundos cerrados.
- **7/7 suites de regresión**, sin fallos (`regresion.json`, `regresion.txt`): UI13, reglas82, comunidades UI13/red26, vivienda UI8/red33, visual A1–A3 60. No se repitió la batería completa.
- Capturas reales inspeccionadas: acceso, registro, menú, carga, selección de mundo y configuración. Campos vacíos o cuentas ficticias; no credenciales reales. Los datos de prueba están en carpetas propias y no se usó la configuración real del cliente en los ensayos.

## Alcance y límites

Pruebas en una misma PC con instancias/procesos separados; no se ejecutó una conexión desde otra computadora física ni por Internet/NAT público. Una cuenta única requiere la autoridad configurada y disponible, y permisos de firewall/reenvío correspondientes. No se despliega un proveedor de cuentas externo ni un servicio del sistema.

Las pruebas corrompen deliberadamente su propio guardado para verificar `.bak`: los errores JSON de ese caso son esperados y la recuperación se comprueba. Persisten los avisos ObjectDB/recursos conocidos; en un bot se observaron avisos de buffer UDP durante el ensayo, sin fallar sus comprobaciones. No se presenta como una medición de rendimiento ni de carga pública.

No se modificaron `Juego`, `Mundo`, `Guardado`, generación ni datos de reglas. Los argumentos/scripts explícitos de ensayo en builds de depuración mantienen su flujo de prueba; el inicio normal exige acceso, y el servidor valida el permiso auténtico incluso frente a un cliente que omita su UI. La skin permanece en pausa. No se vincularon las partidas antiguas de El Rayo ni se registró una cuenta real por el usuario.

Operación y respaldo: [guía](../../../../Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md); decisión [ADR-0003](../../../../docs/architecture/adr-0003-identidad-antes-del-menu.md).
