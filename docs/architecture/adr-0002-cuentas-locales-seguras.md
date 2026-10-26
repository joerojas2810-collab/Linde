# ADR-0002 — Cuentas privadas locales, SQLite y acceso cifrado

Estado: **Usuario**, autorizado el 26/10/2026 para la rama independiente `feature/cuentas` sobre Fase 4 `6bb89f5`. Complementa y sustituye el alcance de identidad sin cuentas/cifrado del ADR-0001 **en el flujo nuevo**. El protocolo legado se conserva para compatibilidad y pruebas, sin elevar sus garantías.

## Decisión

Reutilizar el servidor autoritativo, la réplica y el personaje ya almacenado en `d.jugadores`; añadir un servicio local Python, propiedad del proceso servidor. SQLite guarda cuentas y credenciales Argon2id mediante `argon2-cffi`; no inventarios ni personajes paralelos. El ID `cuenta:<UUID>` es estable, independiente de nombre/peer. Una cuenta tiene un personaje inicialmente.

Acceso: certificado compartido por el anfitrión y validado por el cliente, HTTPS para registro/login, ticket aleatorio de un uso (30 s), DTLS para ENet y el ticket. La API local de consumo exige origen loopback y una clave de control independiente. No se transporta la contraseña de cuenta por ENet ni se acepta una identidad declarada por el cliente. La contraseña opcional del servidor se valida por separado en el servicio de acceso.

El servidor conserva sus validaciones y una sola sesión por cuenta. El mundo sigue siendo una única autoridad y un único guardado compartido. Se guarda periódicamente, al salir y al cerrar. SQLite utiliza WAL/transacciones, respaldos y un bloqueo por directorio; el helper termina por señal o latido ausente.

## Alternativas y motivos

- Hash SHA-256 previo: insuficiente para contraseñas humanas y sin cifrado. No se reutiliza para las cuentas nuevas.
- Plugin SQLite/Argon2 nativo en Godot: necesitaría binarios mantenidos para cada plataforma y ampliar el sistema de compilación. El helper local usa bibliotecas mantenidas y no cambia la simulación. Introduce Python y un puerto TCP adicional, explícitos en instalación/guía.
- Cuentas externas/matchmaking: fuera del alcance solicitado. Tampoco se implementa relay ni administración pública.
- TLS sin autenticación del servidor o «aceptar todos los certificados»: rechazado; expondría contraseñas a intermediarios.
- Trasladar personajes a SQLite: duplicaría el modelo persistente y multiplicaría los conflictos con Fase 5. Se conserva `Guardado`, con las mismas reglas y respaldo.

## Consecuencias y límites

El anfitrión instala Python y dependencias; los clientes solo requieren el juego y el certificado público. Se abren UDP 7777 y TCP 7778 (configurables). La confianza inicial del certificado se verifica por un canal entre amigos. No hay MFA, recuperación de contraseña, exportación empaquetada del helper ni garantía de conectividad pública. El modo legado `--servidor` sigue sin cifrado y no debe usarse para Internet.

Ver instrucciones, límites de recuperación y pruebas en [CUENTAS_Y_SERVIDOR](../../Linde/cenital/docs/CUENTAS_Y_SERVIDOR.md) y el [informe verificado](../../production/qa/evidence/cuentas/INFORME.md). No se modifica generación, economía, balance ni progresión. No incorpora la skin en pausa.
