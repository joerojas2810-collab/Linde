# Linde — jugar local y servidor privado entre amigos

**Paquete experimental Windows x64 — 26/10/2026.** El workflow comprueba el
proyecto con Godot y publica el paquete solo tras pasar sus pruebas automatizadas.
No es una certificación de conexión entre dos computadoras físicas o por Internet.
La distribución se realiza como artefacto de Actions, no como release permanente.
El modo global de cuentas sigue disponible y no es necesario para este modo privado.

## Conseguir el paquete Windows

En GitHub:

1. Abrir **Actions → Servidor privado Windows**.
2. Ejecutar **Run workflow** sobre `arena/9a96dc31-linde`, o abrir la ejecución
   automática iniciada al publicar los cambios de código.
3. Esperar a que termine correctamente. Si falla, consultar los logs; no ignorar
   errores de importación, de integración o del paquete.
4. Descargar el artefacto **Linde-Windows-servidor-y-juego** y extraerlo completo.
   Dentro viene **Linde-Windows-servidor-y-juego.zip**: extraer también ese ZIP en
   una carpeta nueva, por ejemplo `C:\Juegos\Linde`. No ejecutar desde el ZIP ni
   mezclar archivos con una descarga anterior.
   GitHub puede pedir iniciar sesión para descargar artefactos. La retención es de
   14 días; esto no es todavía un release permanente.

El paquete incluye el proyecto, Godot, Python y dependencias del servicio. No requiere
instalarlos globalmente ni descargar nada al jugar. Es un paquete portable con el
motor y fuentes, no un ejecutable exportado único. No mover los ejecutables fuera
de sus carpetas. El binario de Godot se comprueba con SHA-256 al construir y el
paquete incluye un manifiesto SHA256.json de sus archivos iniciales.

## Jugar solo, sin cuentas ni Internet

1. Ejecutar **Jugar Linde.bat**.
2. Elegir **Jugar local / servidores privados (sin cuenta global)**.
3. Seleccionar **Nueva partida**, personalizar el personaje y empezar.
4. Para volver, elegir **Continuar** o **Cargar partida** con el mismo perfil local.

Las partidas locales pertenecen al perfil de esa instalación de usuario. No se
fusionan automáticamente con las partidas de las cuentas globales antiguas.

## Anfitrión: iniciar un mundo compartido

1. Extraer el paquete en una carpeta con permiso de escritura. Evitar Program Files.
2. Ejecutar **Iniciar servidor.bat**. El primer arranque crea la configuración y el
   mundo. El servidor no abre una ventana del juego.
3. Esperar el mensaje **escuchando UDP 7777 y TCP 7778**. Un fallo debe permanecer
   visible en la consola. La escucha no garantiza que Internet pueda llegar a esa PC.
4. La consola muestra la **huella SHA-256** del certificado. Enviarla a los amigos
   por un canal de confianza (por ejemplo, la conversación habitual del grupo).
5. Dejar abierta la consola. El anfitrión también abre **Jugar Linde.bat** para jugar.

El mundo no tiene contraseña por defecto. Antes de exponerlo en Internet conviene
cerrar guardando, editar `servidor/datos/servidor.json` y volver a iniciar:

```json
{
  "carpeta": "mundos/amigos",
  "puerto": 7777,
  "https": 7778,
  "semilla": 1,
  "password": "Una contraseña compartida con tus amigos",
  "autoridad": "",
  "privado": true
}
```

Las rutas relativas se resuelven desde la carpeta de ese JSON. Por defecto el mundo
queda en `servidor/datos/mundos/amigos/`. La semilla solo afecta la creación inicial;
cambiarla no regenera un mundo guardado. Mantener `privado: true`: el modo false
requiere la autoridad de cuentas del flujo anterior. Usar una carpeta nueva para
este modo; no hay migración o fusión automática de identidades antiguas.

## Unirse, incluido el anfitrión

1. Abrir **Jugar Linde.bat**.
2. Elegir **Jugar local / servidores privados (sin cuenta global)** y luego **Unirse**.
3. Escribir la dirección:
   - Anfitrión en la misma computadora: `127.0.0.1`.
   - Otro equipo de la misma LAN: IPv4 local del anfitrión, por ejemplo `192.168.1.50`.
   - Desde otra casa: IP pública o dominio del anfitrión, con los puertos accesibles.
4. Dejar UDP `7777` y, en opciones avanzadas, TCP `7778`, salvo que el anfitrión
   haya configurado otros valores. Escribir IP/dominio sin `https://` ni `:puerto`.
   Esta pantalla inicial soporta IPv4 y dominios, no direcciones IPv6 literales.
5. Escribir el nombre visible (2–16 caracteres) y la contraseña del mundo, si tiene.
6. Pulsar **Conectar**. La primera vez aparece la huella del servidor: **compararla
   exactamente con la del anfitrión antes de aceptar**. Si no coincide, cancelar.
7. Las siguientes conexiones usan el certificado recordado y la credencial del
   personaje generada automáticamente. No hay otra cuenta o contraseña que recordar.

El nombre visible no permite apropiarse de otro personaje. La credencial privada
se genera aleatoriamente, se guarda antes del primer acceso y el servidor conserva
su verificador Argon2id. El progreso se guarda en ese servidor. El mismo personaje
no puede tener dos sesiones simultáneas en el mismo mundo.

## Jugar desde otra casa: red como en un servidor Forge

En la PC anfitriona y su router:

1. Reservar una IPv4 LAN estable para la PC en DHCP.
2. Permitir **UDP 7777** y **TCP 7778** entrantes en el firewall, preferiblemente
   restringidos a los amigos cuando sea posible. No desactivar el firewall entero.
3. Redirigir ambos puertos en el router a esa IPv4 LAN y sus mismos puertos.
4. Compartir la IP pública/dominio. No compartir 127.0.0.1 ni la IP LAN con quien
   está en otra casa. Si la IP pública cambia, actualizar la dirección compartida.
5. Probar desde una conexión externa real; usar la IP pública desde la LAN puede
   fallar por ausencia de NAT loopback aunque la configuración externa sea correcta.

Este modo **no requiere TCP 7790**. No usa VPN, relay, matchmaking ni apertura
UPnP automática. Con CGNAT o doble NAT el port forwarding puede no bastar; consultar
al proveedor por una IP pública, que puede o no tener costo. No poner toda la PC en
DMZ como solución rápida. Un comprobador solo TCP no valida el puerto UDP del juego.

## Guardar, cerrar y volver a iniciar

- Ejecutar **Guardar y cerrar servidor.bat**, o pulsar Ctrl+C en la consola iniciada
  por el lanzador. Esperar la confirmación de cierre y guardado antes de apagar.
- No cerrar a la fuerza desde el administrador de tareas ni asumir que el botón X
  de la consola garantiza un cierre limpio.
- Para continuar, ejecutar **Iniciar servidor.bat** desde la misma carpeta/configuración.
- Las caídas pueden perder el intervalo desde el último autoguardado (hasta 30 s).

## Respaldos y cambio de PC

Con el servidor detenido, respaldar la carpeta del mundo completa: `mundo.json`,
respaldos, `cuentas.sqlite3`, certificados y claves. No copiar solo SQLite mientras
está activo; cerrar antes o usar su respaldo. No compartir datos del servidor con
jugadores: contienen secretos y verificadores.

En el cliente, abrir la carpeta de datos de Godot para Linde y respaldar:

- `perfil_local.cfg` y `perfiles/`: identidad y partidas locales.
- `servidores_privados/`: certificados recordados y credenciales de personajes privados.

En Windows normalmente está bajo `%APPDATA%\Godot\app_userdata\`, dentro de la
carpeta con el nombre del proyecto. Estas credenciales son secretos: no subirlas a
Git ni enviarlas a otras personas. Copiarlas únicamente a tu propia PC por un medio
seguro. Si se pierden, no hay recuperación automática por nombre o contraseña del
mundo. La cuenta global no recupera estos personajes privados.

Si cambia el certificado del servidor, la conexión se rechaza: primero restaurar
el certificado y la clave originales desde el respaldo del anfitrión. Solo ante
un reemplazo intencional confirmado se puede retirar el `.crt` recordado de esa
dirección; el nuevo certificado representa otra identidad y generará otra credencial.
No hay migración automática del personaje en ese caso.

## Alcance y comprobaciones pendientes

El workflow Windows comprueba Python, importa recursos y compila los scripts de
acceso/servidor con Godot 4.7.1. También ejecuta perfil local con guardado/carga,
identidad global y dos clientes en modos existente y privado, incluyendo reconexión,
contraseñas y certificados incorrectos. Después construye el paquete con Python y
Godot incluidos y verifica escucha y cierre con mundo guardado usando ese paquete.

Descargar únicamente el artefacto de una ejecución **verde**. Consultar la ejecución
que produjo ese artefacto para conocer el resultado real, no solo esta descripción.
Estas pruebas usan procesos separados en un runner Windows; **no equivalen a un
playtest manual, una PC limpia física, dos computadoras LAN ni dos casas distintas**.
Persisten avisos históricos de recursos/ObjectDB al salir y se han observado avisos
de buffers UDP llenos en las pruebas; no se certifica rendimiento bajo carga.
Linux y Mac Intel no tienen paquete portable nuevo en esta entrega; desde fuente
requieren Godot y Python como antes. Para Mac Apple Silicon, ver la sección siguiente.

## Mac Apple Silicon

Construcción separada con motor y Python arm64 incluidos, lanzadores `.command` y
ZIP que conserva permisos/enlaces. Ver [paso a paso Mac](MAC_APPLE_SILICON.md).
La disponibilidad depende de una ejecución verde del workflow Mac; no usar el ZIP
Windows en macOS. No hay paquete Intel en esta entrega.

## Cómo se construyó Windows — lógica paso a paso

1. **Reutilizar el servidor real.** `red_servidor.gd` conserva la simulación
   autoritativa y las reglas; `cuentas/main_servidor.gd` lo ejecuta sin ventana.
   No se creó otro mundo o motor de red paralelo.
2. **Separar el modo privado de la cuenta global.** El botón local/privado genera
   un perfil persistente para los guardados individuales. Para el servidor privado,
   el cliente guarda una credencial aleatoria por certificado del mundo; el nombre
   visible no funciona como contraseña ni como prueba de identidad. El servicio
   conserva el verificador Argon2id y emite un ticket de un uso para entrar.
3. **Conservar la seguridad de la conexión.** Solo se consulta el certificado público
   sin confianza previa. El usuario confirma su huella por un canal de confianza;
   después HTTPS y DTLS verifican ese certificado. Una sustitución no se acepta
   automáticamente. El modo global de cuentas sigue como alternativa.
4. **Automatizar el inicio.** `lanzador.py` crea/lee `servidor.json`, resuelve rutas,
   valida puertos, prepara un archivo temporal privado y arranca Godot headless.
   Godot consume ese archivo; el JSON persistente no se destruye. Así la contraseña
   del mundo no se pasa en argumentos de consola.
5. **Empaquetar lo que antes había que instalar.** `empaquetar_windows.py` copia el
   proyecto sin cachés viejas ni datos privados, el Godot oficial, CPython 3.11 con
   sus bibliotecas y las dependencias fijadas. Añade licencias y un manifiesto SHA-256.
   El paquete contiene fuentes y runtimes, no un export único de Godot.
6. **Crear tres entradas simples.** `Iniciar servidor.bat`, `Jugar Linde.bat` y
   `Guardar y cerrar servidor.bat` apuntan a los ejecutables incluidos. El último
   solicita el cierre por el mecanismo del servidor, en vez de matar el proceso.
7. **Validar en Windows.** GitHub Actions comprueba el hash del motor, ejecuta Python,
   importa recursos, compila los scripts dinámicos y prueba guardado/carga local,
   identidad global, dos clientes y reconexión en los modos existente y privado.
8. **Probar el producto, no solo el código fuente.** Después de construir, ejecuta
   el Python y Godot del propio paquete, espera escucha, pide cierre y comprueba
   el guardado. También espera la liberación del bloqueo del helper de acceso.
   Solo si esos pasos pasan publica el artefacto descargable.
9. **Mantener explícito el límite de red.** UDP 7777 mueve la partida; TCP 7778
   gestiona el acceso seguro. El paquete no abre el router ni resuelve CGNAT.
   Las pruebas de CI ocurren en una máquina; no certifican conexión entre casas.

## Versión combinada Fase 7 — paquetes corregidos (26/10/2026)

Código `a4fffda` en `arena/9a96dc31-linde`, descendiente de `feature/fase7-arena`.
[Windows aprobado](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412236)
y [Mac aprobado](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412243).

Se corrigió la dependencia de la caché global para ImagenUtil con preloads explícitos.
Windows ahora publica un ZIP interno que preserva `.godot`, omitido por defecto al
subir carpetas ocultas a Artifacts. Se extrae y prueba el cliente (menú y perfil local
con guardado/carga), además del servidor, antes de publicar en ambos sistemas.

Se ejecutaron ocho suites de Fase 7 y las integraciones previas. Se hizo portable la
ruta temporal de prueba_fauna. El test de hábitats mantiene los valores históricos
exactos de terreno, planes, ocupación y especies; el hash global del fixture anterior
a la economía regional no representa ese contrato. Se comprueba por separado que el
estado completo actual es igual entre órdenes y que las consultas no lo modifican.
No se regeneraron los fixtures históricos ni se cambió la distribución de fauna para
forzar el resultado. No implica prueba de GPU/interfaz en un equipo físico ni Internet.

Para actualizar un mundo existente: detener y respaldar primero su carpeta completa;
no copiar solo mundo.json, pues la identidad/certificado y SQLite del servidor también
son necesarios. Los clientes deben usar la misma versión que el servidor. No borrar
los datos personales de Godot para actualizar el programa.
