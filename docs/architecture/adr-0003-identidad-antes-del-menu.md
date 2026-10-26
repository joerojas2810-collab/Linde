# ADR-0003 — Identidad única antes de elegir un mundo

**Usuario, 26/10/2026.** El usuario pidió que Linde abra con iniciar sesión/registrarse y después muestre el menú de partidas. Se consultó la diferencia entre perfiles de una PC y cuenta única entre PC; eligió explícitamente **cuenta única de Linde entre PC**. Esto amplía y sustituye el alcance por-servidor del ADR-0002 para la interfaz normal; los modos legados quedan para compatibilidad y pruebas.

## Decisión

Separar el servicio de identidad de los mundos, reutilizando SQLite, Argon2id y HTTPS existentes. Una PC o servidor privado de referencia aloja la autoridad; las demás usan su dirección y certificado. No introducir proveedor externo ni desplegar infraestructura de producción. La elección inicial de autoridad local es explícita: no generar una distinta silenciosamente en cada instalación.

La autoridad emite una sesión RS256 de dos horas. Los anfitriones de mundos no reciben la contraseña ni el token global: el cliente lo canjea ante identidad por un permiso firmado de 60 segundos, ligado al certificado del destino. El mundo verifica el certificado de autoridad configurado por su administrador, fija RS256/emisor/audiencia/caducidad, evita reuso y comprueba su contraseña propia. Después reutiliza el ticket de un uso y el flujo ENet/DTLS autoritativo del ADR-0002. PyJWT/cryptography implementan firma y verificación; no se implementa criptografía propia.

ID de cuenta estable entre mundos; un personaje por mundo y guardado existente. El menú local separa sus partidas por emisor+ID, conserva varias, comprueba propiedad y recuerda la última elegida. No trasladar inventarios/mundo a otra base ni atribuir partidas antiguas a un nombre que coincida. Las partidas locales siguen en cada PC; el progreso multijugador sigue en su servidor. Una cuenta única no implica almacenamiento de mundos en la nube.

## Alternativas y límites

- Adelantar visualmente el antiguo formulario de un mundo: seguiría requiriendo elegir ese mundo antes de una cuenta y no cumpliría la identidad entre PC.
- Crear perfiles locales en cada equipo: descartado por la elección expresa del usuario.
- Proveedor externo/cuentas en nube: fuera del alcance privado solicitado; la autoridad requiere una PC disponible y su configuración inicial de confianza.

Sesiones en memoria, sin almacenar contraseñas/token en el cliente; cierre de sesión y expiración bloquean el menú. El servicio local configurado se reactiva al abrir el juego, conserva sus claves y continúa si se cierran mundos/juego. Sin instalación de servicio del sistema, revocación instantánea de JWT, recuperación de contraseña, migración automática de cuentas antiguas ni sincronización de mundos locales. No afirmar Internet ni otra computadora física probados.

Implementación y operación: [CUENTAS_Y_SERVIDOR](../../Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md). Evidencia: [login-inicial](../../production/qa/evidence/login-inicial/README.md). La skin sigue en pausa; la nueva identidad podría servir para vincularla posteriormente, sin implementarlo aquí.
