# Cuenta de Linde, menú y mundos compartidos

Estado del ajuste `feature/login-inicial` (26/10/2026), sobre `main` integrado `d223398`. Implementa el flujo aprobado por el usuario:

**Abrir Linde → iniciar sesión o registrarse → menú principal → continuar, crear/cargar una partida, alojar o unirse.**

La cuenta de Linde es independiente de los mundos. Usa un servicio de identidad compartido entre las PC; no es un proveedor externo ni un servicio en la nube ya desplegado.

## 1. Configuración inicial del servicio de cuentas

Solo se hace una vez por PC. Todas deben apuntar al **mismo servicio** para reconocer la misma cuenta.

### PC que aloja las cuentas

1. Instalar Python 3.11 o posterior y ejecutar `Instalar-Cuentas.bat` (Windows) o `sh Instalar-Cuentas.command`. El entorno `.venv` usa las bibliotecas fijadas en `servidor/cuentas/requirements.txt`.
2. En el acceso inicial, abrir **Configurar servicio de cuentas** y pulsar **Activar servicio de cuentas en esta PC**. Puerto TCP predeterminado **7790**. Los datos van a `user://identidad_linde` salvo que el administrador elija otra carpeta.
3. Se crean certificado, claves y SQLite. No se registra automáticamente ninguna cuenta ni se elige una contraseña por el usuario.
4. El servicio sigue activo al cerrar una partida o el juego. Después de reiniciar la PC, abrir Linde reactiva el servicio que ese administrador configuró, conservando sus claves y su base. No se reemplazan datos perdidos en silencio: restaurar el respaldo.
5. Compartir con los amigos la dirección y puerto del servicio y **solo su certificado público `servidor.crt`** por un canal de confianza. Mantener la PC encendida y el servicio disponible para nuevos accesos. No se instala un servicio del sistema ni un inicio automático al arrancar Windows.

### Otras PC

En **Configurar servicio de cuentas**, introducir IP/dominio, TCP 7790 y el certificado público recibido. Pulsar **Usar este servicio**. No activar una autoridad local nueva en cada PC: produciría cuentas independientes. Se recuerda esta conexión, no la contraseña.

## 2. Acceso y menú principal

- Iniciar sesión o registrarse **antes** de elegir una partida. Usuario: 3–24 letras sin acentos, cifras, `_` o `-`; contraseña obligatoria sin longitud mínima adicional, máximo 128 caracteres (ajuste solicitado por el usuario el 26/10/2026). El registro pide confirmación y nombre visible.
- Después del acceso se muestran **Continuar, Nueva partida, Cargar partida, Alojar partida, Unirse, Cerrar sesión y Salir**.
- Nueva partida conserva las anteriores. Cargar muestra los mundos locales que pertenecen a esa cuenta. Continuar recuerda el elegido anteriormente.
- Las partidas individuales se guardan **en esa PC**, separadas por identidad y mundo; no hay sincronización de archivos en la nube. En multijugador, personaje y progreso se guardan en el servidor del mundo y se recuperan al entrar desde otra PC con la misma identidad.
- Cerrar sesión borra la sesión en memoria y vuelve al acceso. Las contraseñas y el token de sesión no se guardan en la configuración del cliente. La sesión dura dos horas; al volver al menú después de caducar se pide el acceso otra vez.
- El archivo individual antiguo `partida.json` queda conservado. No se atribuye automáticamente a una cuenta ni se migran mundos con reglas incompatibles. Las cuentas antiguas por servidor siguen en sus archivos; este ajuste no las fusiona por coincidencia de nombre.

## 3. Alojar y unirse a un mundo

Después de iniciar sesión, cada PC que aloje un mundo necesita también Python y las dependencias de `Instalar-Cuentas`; las PC que solo juegan como clientes no lo necesitan.

1. **Alojar partida** permite elegir UDP **7777**, HTTPS/TCP **7778**, carpeta de mundo y contraseña opcional del mundo. Vacío permite acceso sin esa contraseña; la identidad de Linde sigue siendo obligatoria.
2. El anfitrión confía en la autoridad de cuentas que validó su acceso. El mundo conserva su propio certificado y su guardado.
3. Esperar **Escuchando**. Compartir el certificado público del mundo, dirección/puertos y contraseña del mundo si tiene. El certificado de identidad y el del mundo cumplen funciones distintas.
4. **Unirse** pide únicamente dirección/puertos del mundo, su certificado y su contraseña opcional. No pide otra cuenta, registro ni contraseña de Linde.
5. El servidor conserva una única sesión simultánea del mismo personaje por mundo. La cuenta tiene el mismo ID estable entre mundos; el progreso de cada mundo permanece en su servidor.
6. **Cerrar servidor y guardar** conserva el mundo. Cerrar la aplicación que inició ese mundo también solicita su cierre. El servicio de identidad es independiente y permanece disponible; se detiene desde su configuración local cuando corresponda.

## 4. Red y certificados

- Localhost: `127.0.0.1`. Identidad TCP 7790; mundo UDP 7777 y TCP 7778.
- LAN: IP LAN de la PC correspondiente. La autoridad y el mundo pueden estar en la misma PC o en distintas. Permitir en el firewall los puertos que cada una aloje; no desactivar el firewall completo.
- Internet: además del firewall, redirigir **TCP 7790** hacia la autoridad, y **UDP 7777 + TCP 7778** hacia el servidor de mundo. Usar los puertos realmente configurados. CGNAT/doble NAT pueden impedirlo; una escucha local no acredita conectividad pública. No hay relay, UPnP automático ni matchmaking.
- La confianza se establece con los certificados recibidos por un medio seguro. El cliente valida TLS antes de enviar credenciales y comprueba que la conexión inicial corresponde a identidad, no a un mundo. No hay opción de omitir la verificación.
- Un cambio o pérdida del certificado de autoridad cambia su identidad de confianza: restaurar claves y SQLite del respaldo, no generar otra autoridad suponiendo que es la misma.
- **No se probó otra computadora física ni Internet público**. Las pruebas usan instancias separadas y dos mundos en la misma PC. Ver el alcance ejecutado en `production/qa/evidence/login-inicial/README.md`.

## 5. Persistencia y seguridad

- Identidad: SQLite almacena usuarios e ID `cuenta:<UUID>`; contraseña Argon2id con sal por usuario (`argon2-cffi`, 64 MiB/3 pasadas/paralelismo 4), límites de intentos y trabajo simultáneo. Certificados y firma usan `cryptography` y `PyJWT` mantenidos.
- La autoridad emite una sesión RS256 de dos horas con emisor, audiencia y caducidad exigidos. La sesión se entrega solo a la autoridad para obtener un permiso de 60 segundos ligado al certificado de un mundo concreto. Ese mundo verifica firma/emisor/audiencia/caducidad y evita reutilizar el permiso; comprueba por separado su contraseña y emite el ticket opaco de un uso que ya admite ENet/DTLS.
- **La contraseña de Linde y su sesión global no se entregan al anfitrión de un mundo**. No hay claves privadas de la autoridad en los clientes ni en otros servidores. La confianza del mundo se configura por su administrador, no por un paquete de un jugador.
- El personaje completo, inventario, equipo, XP, mapa y progresión siguen en `Juego`/`Guardado`. El mundo no duplica filas de cuentas ni hashes globales. Los guardados locales llevan identidad de propietario y usan rutas separadas; las cuentas no abren accidentalmente guardados ajenos por el menú. No se promete protección frente al administrador del sistema que edite archivos locales.
- El mundo se guarda antes de aceptar al personaje, cada 30 segundos, al desconectarse y al cerrar. Se conservan checksum, escritura temporal y `.bak`. SQLite utiliza WAL, transacciones y respaldos por API. Una caída puede perder hasta el intervalo de autoguardado.
- Respaldar datos de identidad (SQLite, certificado, claves) y los mundos. No copiar un SQLite activo sin su WAL; usar el respaldo o cerrar antes. Nunca compartir `servidor.key`, `control.key`, SQLite ni configuraciones privadas.
- Alcance privado entre amigos: sin MFA, recuperación de contraseña, revocación instantánea de sesiones firmadas ni empaquetado autocontenido del helper. El propietario de la autoridad conserva el control de la identidad; el del mundo, de la simulación.

## 6. Ejecución sin interfaz y compatibilidad

Identidad independiente: crear un JSON temporal `{"rol":"identidad"}` y ejecutar:

```sh
.venv/bin/python servidor/cuentas/servicio.py --datos /ruta/identidad --config /ruta/inicio-identidad.json --puerto 7790
```

El archivo temporal se consume. Para el mundo global, JSON de arranque:

```json
{"carpeta":"/ruta/mundo","puerto":7777,"https":7778,"python":"/ruta/Linde/.venv/bin/python","password":"","autoridad":"/ruta/certificado-identidad.crt"}
```

```sh
godot --headless --path Linde/cenital --script res://scripts/cuentas/main_servidor.gd -- --config=/ruta/inicio-mundo.json
```

En Windows usar `.venv/Scripts/python.exe`. La contraseña opcional del mundo va solo en el archivo temporal privado; nunca en argumentos. Crear `detener_servidor` en la carpeta del mundo para cerrar guardando; `detener_cuentas` en la autoridad solicita su cierre. Los roles legados y el comando histórico `--servidor` se conservan para las pruebas anteriores; no representan el flujo global nuevo ni su garantía de seguridad. El modo histórico sin cifrado no debe exponerse a Internet.

Los scripts de ensayo y argumentos explícitos de depuración conservan su acceso de pruebas en builds de depuración. El inicio normal exige cuenta; el servidor de mundo valida siempre el permiso auténtico aunque un cliente modificado omita su propia pantalla.

## 7. Verificación

```sh
.venv/bin/python -m unittest discover -s servidor/cuentas -p 'test_*.py' -v
.venv/bin/python servidor/cuentas/prueba_identidad_integracion.py --godot /ruta/godot --salida /ruta/nueva/qa
godot --path Linde/cenital --script res://tests/prueba_acceso_inicial.gd -- --config=/ruta/config-ensayo.json
```

El ensayo de UI recibe `salida`, `identidad`, `python` y `puerto`; usa configuración, cuentas y guardados aislados. Se prueba registro, menú, varias partidas, recuperación de respaldo, aislamiento entre cuentas y reactivación de la autoridad. No apuntar pruebas a cuentas reales. Los avisos ObjectDB/recursos al cerrar ya existentes continúan.

Fuentes técnicas: [PyJWT RS256 y validaciones](https://pyjwt.readthedocs.io/en/stable/usage.html), [Argon2-cffi](https://argon2-cffi.readthedocs.io/en/stable/parameters.html), [TLSOptions](https://docs.godotengine.org/en/stable/classes/class_tlsoptions.html), [SQLite WAL](https://sqlite.org/wal.html).

## 8. Servidor dedicado estilo Forge — paquete experimental validado en CI (26/10/2026)

Objetivo aprobado: paquete portable, servidor en la PC del anfitrión y conexión por
IP/contraseña, sin VPN ni relay. Se añadió un modo privado opcional y juego local
sin cuenta global, conservando el acceso de cuentas anterior.

**Guía de uso, red, respaldo y limitaciones:** [SERVIDOR_PRIVADO.md](SERVIDOR_PRIVADO.md).
Paquete Windows x64 construido y publicado como artefacto de Actions. No hay release
permanente ni paquete macOS/Linux. Ejecución aprobada: [40418982569](https://github.com/joerojas2810-collab/Linde/actions/runs/40418982569),
código `d1c5372`, artefacto `Linde-Windows-servidor-y-juego` (124.695.287 bytes comprimido).
Retención de 14 días, sujeto a las políticas y disponibilidad de GitHub.

### Plan activo y estado

1. **Base existente:** 9 pruebas Python anteriores pasan. La integración real se
   ejecutó en GitHub Actions con Godot 4.7.1 oficial comprobado por SHA-256.
   El motor continúa sin estar disponible en el sandbox Linux local.
2. **Modo privado:** implementado en servicio Python, cliente y formularios. Credencial
   aleatoria por certificado, persistida antes de entrar, con Argon2id del lado del
   servidor. No se confía en el nombre visible como identidad. Cuatro pruebas nuevas
   HTTPS reales pasan: certificado público, reconexión de identidad/ticket de un uso,
   contraseña del mundo y bloqueo del consumo público de tickets.
3. **Acceso sencillo y local:** implementado. Perfil local persistente separado de
   cuentas globales; formulario de IP, nombre y contraseña; descarga inicial SOLO
   del certificado público sin credenciales, confirmación explícita de huella por
   canal de confianza y verificación TLS/DTLS posterior. No sustituir certificados
   recordados automáticamente. Perfil local con guardado y carga ejecutado en Godot. La comparación manual de
   huella y la experiencia visual aún requieren playtest.
4. **Paquete:** lanzador con configuración persistente y arranque temporal privado;
   cierre por Ctrl+C o script de parada. Siete pruebas del lanzador pasan con el
   proceso de Godot simulado. Script de construcción y workflow Windows escritos,
   con CPython/Godot/dependencias incluidos y comprobación de arranque del paquete.
   Construcción, compilación explícita de scripts dinámicos, pruebas de dos clientes
   en modos existente/privado, identidad global y prueba de arranque/cierre del paquete
   aprobadas en el workflow enlazado. El paquete se puede descargar de sus artefactos.
5. **LAN:** pendiente en dos equipos físicos.
6. **Dos casas:** pendiente; requiere firewall, UDP 7777/TCP 7778 y resolver CGNAT
   cuando corresponda. El modo privado no requiere TCP 7790. No hay UPnP automático.
7. **Guía:** escrita en el enlace anterior; pendiente recorrido manual por jugadores.

### Verificación automatizada preparada

`.github/workflows/servidor-privado.yml` descarga Godot oficial comprobando SHA-256,
importa scripts/recursos, prueba perfil local, identidad global existente y dos
clientes con reconexión en modos legado y privado. Solo después construye el
paquete Windows, comprueba su arranque/cierre y publica un artefacto temporal.
La ejecución enlazada está aprobada; no extrapolar su resultado a redes/equipos físicos.

Comprobaciones ejecutadas en esta sesión:

```sh
.venv/bin/python -m unittest discover -s servidor/cuentas -p 'test_*.py' -v  # 13 OK
.venv/bin/python -m unittest discover -s servidor/dedicado -v              # 7 OK
```

Además, compilación de sintaxis Python y análisis de sintaxis GDScript mediante
`gdparse` (herramienta externa de desarrollo, no sustituto del compilador Godot).
El lanzador desde fuente sigue requiriendo Godot y Python; el paquete publicado incluye
el motor, el intérprete y las dependencias para no requerir su instalación global.
