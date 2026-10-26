# Cuentas y servidor privado de Linde

Implementación de `feature/cuentas`, sobre Fase 4 (`6bb89f5`). Reutiliza `Juego`, los personajes de `d.jugadores`, la réplica, exploración personal, lugares y `Guardado`; no cambia generación, balance ni progresión.

## La causa del problema anterior

La antigua pantalla «Unirse» llamaba «Clave» al token del personaje. El servidor nunca pedía configurar una contraseña de acceso al mundo. Eran conceptos diferentes y el segundo no estaba implementado. El formulario nuevo separa **contraseña de cuenta** y **contraseña opcional de servidor**.

## Preparar el anfitrión

1. Instalar Python 3.11 o posterior. Ejecutar `Instalar-Cuentas.bat` (Windows) o `sh Instalar-Cuentas.command` (Linux/macOS). Crea `.venv` en esta copia y usa las versiones fijadas en `servidor/cuentas/requirements.txt`.
2. Ejecutar `Iniciar-Servidor.bat`, o iniciar Linde y elegir **Alojar partida**. Es el servidor nuevo con cuentas, en un proceso separado; la partida individual se conserva aparte.
3. Elegir el puerto UDP del juego (7777), el TCP de cuentas (7778), una carpeta de datos y, si se quiere, la contraseña del servidor. Dejarla vacía permite pruebas sin contraseña de servidor; **cada cuenta sigue necesitando su contraseña**.
4. Pulsar Iniciar. Esperar **Escuchando**. Un error de Python, dependencias, certificado, puertos o carpeta se muestra; «iniciando» no significa conectado públicamente.
5. Compartir **solo `servidor.crt`**, la huella SHA-256 y la dirección/puertos con los amigos mediante un canal de confianza. Nunca compartir `servidor.key`, `control.key`, la base SQLite ni los archivos de configuración con contraseñas.

La interfaz acepta una ruta distinta de Python. También admite `LINDE_PYTHON`. Los clientes no necesitan Python.

## Conectar y crear una cuenta

1. Abrir Linde → Unirse. Introducir IP/dominio, puerto UDP y puerto TCP de cuentas.
2. Seleccionar el certificado público recibido del anfitrión. Comprobar su huella con él por otro medio si hace falta. No hay un botón para ignorar certificados ni un envío previo en claro.
3. Introducir usuario (3–24 letras sin acentos, cifras, `_` o `-`) y contraseña de cuenta (10–128 caracteres). Escribir la contraseña del servidor **solo si es privado**.
4. Para la primera vez marcar Registrar una cuenta nueva y elegir nombre visible del personaje. En ingresos posteriores desmarcarlo y usar la misma cuenta. El nombre/aspecto enviados en otro login no sustituyen el personaje existente.
5. Al entrar desde otra instancia o computadora, usar el mismo servidor, certificado, usuario y contraseña. La cuenta recupera su mismo identificador/personaje. No copiar una partida del cliente.

Se recuerdan dirección, puertos, certificado y usuario, **nunca contraseñas**. El aspecto inicial reutiliza el creador actual; los perfiles guardados conservan su aspecto. Una cuenta tiene un personaje por mundo del servidor. No existe vinculación automática de una partida individual antigua, recuperación por correo, proveedor externo ni transferencia entre servidores diferentes.

## Localhost, LAN e Internet

- Misma PC: `127.0.0.1`, UDP 7777 y TCP 7778.
- Otra PC de la misma red: IP LAN del anfitrión (ej. `192.168.1.20`). Las escuchas son IPv4 `0.0.0.0`, no solo localhost. Permitir en el firewall **UDP 7777** para Godot y **TCP 7778** para Python/cuentas. Usar los puertos elegidos si se cambiaron. No desactivar el firewall entero.
- Internet: permitir ambos puertos en el firewall y redirigir **UDP 7777 y TCP 7778** del router a la IP LAN reservada del anfitrión. Conectar a su IP pública o dominio. El router no convierte TCP en UDP. Algunos routers no admiten conectarse a la propia IP pública desde dentro (NAT loopback): probar desde otra red.
- CGNAT/doble NAT: el reenvío del router puede no bastar; consultar al ISP o usar una red privada entre amigos. No hay UPnP automático, relay ni matchmaking implementados.
- El certificado fija la identidad del servidor, con nombre interno `linde.local`; sirve aunque la IP cambie. El cliente valida exclusivamente el certificado elegido. Si cambia el certificado, distribuir el nuevo por un medio de confianza, no desactivar la validación.
- **Alcance verificado**: consultar `production/qa/evidence/cuentas/INFORME.md`. Una conexión a la IP LAN de la misma PC no prueba el firewall entrante desde otro equipo. No se verificó Internet público ni otra computadora real.

## Seguridad y distribución del estado

- `argon2-cffi` implementa Argon2id: 64 MiB, 3 pasadas, paralelismo 4 y sal aleatoria por contraseña. Dos trabajos simultáneos como máximo, 16 conexiones HTTP, tamaño de petición limitado, intentos por IP/usuario y mensajes genéricos para contraseñas de cuenta incorrectas. La contraseña del servidor también se guarda como Argon2id.
- HTTPS/TLS valida el certificado antes de enviar credenciales. Emite un ticket aleatorio de un uso, válido 30 segundos; SQLite solo guarda su hash. El ticket también viaja cifrado en DTLS/ENet. El servidor consume el ticket por HTTPS local usando una clave de control independiente; un cliente no puede reclamar un ID de cuenta arbitrario.
- La identidad estable es `cuenta:<UUID>`, creada por el servicio. Es independiente de nombre visible, usuario y peer ID. El servidor conserva una sola sesión por ID. Las acciones mantienen todas las validaciones originales y se ejecutan con la identidad de la sesión.
- SQLite guarda únicamente usuarios, hashes, tickets y configuración de acceso. El personaje completo (posición, inventario, equipo, XP, mapa, pistas y demás campos) sigue en el único mundo de `Guardado`. No hay tabla paralela de inventario/personajes.
- El registro es abierto a quien conozca la contraseña del servidor (o a cualquiera con conectividad si se deja vacío). Adecuado para amigos, no endurecido como servicio público de producción. No hay MFA, recuperación de contraseña ni administración remota de cuentas.
- La seguridad depende de proteger la carpeta del servidor y sus claves con los permisos del usuario del sistema. El anfitrión es la autoridad; un administrador de su PC puede modificar el mundo.

## Guardado, cierre y recuperación

- Guardado del mundo antes de aceptar al personaje nuevo, cada 30 segundos, al desconectarse y al cerrar ordenadamente. Se reutilizan checksum, escritura temporal y `.bak` de `Guardado`.
- Cerrar servidor y guardar envía una señal al proceso, que guarda antes de salir. Cerrar la aplicación que lo inició también solicita el cierre. No apagar la PC hasta que termine.
- SQLite usa WAL, `synchronous=FULL`, transacciones y respaldo mediante la API de SQLite cada minuto y al cerrar el servicio. La carpeta tiene un bloqueo para evitar dos procesos de cuentas sobre el mismo mundo, incluso con puertos diferentes.
- Si Godot termina inesperadamente, el servicio de cuentas detecta el latido ausente y se apaga después de aproximadamente 20 segundos. Reiniciar después de ese plazo. Se recupera el último autoguardado válido: puede perderse hasta el intervalo de guardado, no hay promesa de cero pérdida.
- Respaldar la carpeta completa con el servidor cerrado: `mundo.json`, `.bak`, `cuentas.sqlite3`, certificados y claves. No copiar solo un SQLite activo sin su WAL; usar `cuentas.respaldo.sqlite3` o la API de backup. Restaurar mundo y cuentas del mismo conjunto de respaldo; restaurar una sola mitad puede dejar cuentas/personajes desparejados.
- Reglas de juego incompatibles siguen bloqueando la carga; este sistema no falsifica el sello ni migra mundos de versiones distintas.

## Ejecución sin interfaz

Crear un JSON de arranque **privado y temporal**:

```json
{"carpeta":"/ruta/datos/linde","puerto":7777,"https":7778,"python":"/ruta/Linde/.venv/bin/python","password":"","semilla":123}
```

```sh
godot --headless --path Linde/cenital --script res://scripts/cuentas/main_servidor.gd -- --config=/ruta/arranque.json
```

El archivo de arranque se consume/elimina. No poner la contraseña en argumentos. Cerrar creando `detener_servidor` en la carpeta del servidor, o usar la interfaz. El comando histórico `--servidor` conserva el protocolo previo para pruebas y compatibilidad: **no usa estas cuentas ni cifrado y no debe exponerse a Internet**. La interfaz nueva no lo usa.

## Pruebas reproducibles

```sh
.venv/bin/python -m unittest discover -s servidor/cuentas -p test_servicio.py -v
.venv/bin/python servidor/cuentas/prueba_integracion.py --godot /ruta/godot --salida /ruta/vacia/qa
.venv/bin/python servidor/cuentas/verificar_suites.py --godot /ruta/godot --salida /ruta/qa/regresion
godot --path Linde/cenital --script res://tests/captura_cuentas.gd
```

En Windows usar `.venv/Scripts/python.exe`. La integración crea datos y credenciales ficticias en la carpeta de salida; usar una nueva por ejecución. No ejecutar contra la partida habitual. Las capturas y logs de cierre pueden mostrar los avisos de recursos al salir ya conocidos del proyecto.

Fuentes técnicas: [ENetConnection/DTLS](https://docs.godotengine.org/en/stable/classes/class_enetconnection.html), [TLSOptions](https://docs.godotengine.org/en/stable/classes/class_tlsoptions.html), [Argon2-cffi](https://argon2-cffi.readthedocs.io/en/stable/parameters.html), [SQLite WAL](https://sqlite.org/wal.html).

### Ejecución de la validación en Windows

El ejecutor de suites genera copias temporales ignoradas para sustituir el prefijo Unix `/tmp` por `OS.get_cache_dir()` y actualizar su autorreferencia de procesos hijo. No cambia las suites originales de IA 1. El resumen consolidado registra las repeticiones necesarias de saberes/orientación y la comprobación del mapa de iconos con los bytes canónicos ya guardados en Git; no elimina el fallo histórico de arte E04/E05.

La instalación actual se ejecuta desde el proyecto fuente: el helper Python y su entorno no se empaquetan automáticamente en un export de Godot. Antes de distribuir un ejecutable independiente habrá que incorporar ese empaquetado.
