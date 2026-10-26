# IA 2 — Cuentas y servidor: validación del 26/10/2026

Rama independiente `feature/cuentas`; base confirmada Fase 4 `6bb89f5`. Datos ficticios aislados. No se probó Internet público ni una segunda computadora física.

## Resultados ejecutados

- **4 pruebas unitarias Python, sin fallos**: registro/login, identificador estable, contraseña privada independiente, hashes Argon2id/sales distintas, tickets de un uso/caducidad, límites de intentos, respaldo e identidad del certificado. Evidencia `python.txt` (archivo local de ejecución; resumen registrado aquí).
- **35 comprobaciones de integración, sin fallos** (`integracion.json`): procesos reales de Godot y servicio HTTPS; servidor sin contraseña, dos clientes simultáneos, registro, login, rechazo de sesión duplicada, reconexión tras reinicio, inventario no vacío, equipo, XP, aspecto y mapa personal; separación entre cuentas, errores de ambas contraseñas, CA no confiable, bloqueo de una segunda instancia sobre la misma carpeta, integridad SQLite y respaldos. Los 35 incluyen comprobaciones de finalización/cierre, no equivalen a 35 funcionalidades distintas.
- **Posición**: comparación adicional de las respuestas reales del cliente antes/después del reinicio: `[600,364]` en ambos ingresos. No se simuló traslado entre computadoras.
- **5 comprobaciones de recuperación, sin fallos** (`recuperacion.json`): autoguardado después de 34 segundos sin desconectar; terminación forzada de un proceso servidor de prueba; detección de desconexión; apagado del servicio por ausencia de latido; nuevo login/progreso y conservación del mundo desde el último autoguardado.
- **Interfaz real** (`crear_servidor.png`, `servidor_activo.png`, `servidor_cerrado.png`, `registro_login.png`, `error_puerto.png`): inicio y cierre por botones en UDP 7777/TCP 7778; separación de campos y ocultación de ambas contraseñas; validación de puertos. Capturas inspeccionadas.
- **Regresión final: 36 de 37 suites sin fallos**, detalle `regresion.json`. Único fallo persistente: la comprobación histórica del SHA-256 de 96 archivos E04/E05 en `prueba` (329 PASS y 1 FAIL), ya documentada antes de esta rama. No se modificó ni ocultó.

## Ajustes de ejecución en Windows

La primera ejecución encontró rutas `/tmp` de Unix en suites anteriores; al fallar el guardado, algunas no terminaban. El ejecutor genera copias temporales ignoradas en `tests/_cuentas_windows/`, cambiando únicamente el prefijo por `OS.get_cache_dir()` y la ruta de autorreferencia de sus procesos hijo. Las suites originales no se editaron. La ejecución inicial de saberes y orientación falló por esas rutas; las repeticiones corregidas dieron **87 PASS** y **14 PASS** respectivamente. Sus resultados finales reemplazan esos fallos de preparación, con log individual indicado en `regresion.json`.

`prueba_integracion_visual_a` falló inicialmente por CRLF añadidos al checkout de `ICONOS_POR_ID.json`. Se verificó igualdad de contenido normalizando CRLF y se repusieron los bytes exactos de Git (SHA `5fe0e8f2756e51ae5b843aa8d98a59a656930e3a889740c8553efc7239118bf2`), sin editar manifiestos ni contenido. Repetición: **60 PASS, 0 FAIL**. Es independiente del fallo E04/E05 que permanece.

Se restauraron los metadatos `.import` y los dos JSON de evidencia histórica reescritos por suites antiguas. No forman parte de los cambios de cuentas.

## Conectividad: qué significa la prueba

- Localhost: ejecutado con procesos separados, HTTPS validado y DTLS/ENet.
- IP de interfaz LAN de esta PC `192.168.100.190`: ejecutado con un cliente local; comprueba la escucha fuera de loopback en esta máquina.
- Dos equipos por LAN: **no ejecutado**. El firewall entrante de otra computadora no se verificó.
- Internet/NAT/CGNAT: **no ejecutado**. Un puerto en escucha no acredita acceso público.
- Transporte antiguo: sus suites de red siguen pasando. `--servidor` histórico conserva su modo sin cifrado para compatibilidad; el menú nuevo usa exclusivamente cuentas y cifrado.

## Alcance conservado

`juego.gd`, `mundo.gd`, `guardado.gd`, `asentamientos.gd`, `exploracion.gd`, `lugares.gd`, `terreno.gd`, `autonomia.gd`, `catalogos.gd` y `datos/` sin diferencias contra `6bb89f5`. No se reimplementó el personaje en SQLite ni se tocó balance, generación, economía o progresión. Los avisos de recursos/ObjectDB al salir siguen presentes; no se presentan como un arreglo de esta rama.

## Límites restantes

Python y dependencias en el anfitrión; certificados distribuidos manualmente; no instalador/exportación autocontenida; sin recuperación de contraseña/MFA ni servicio externo. Una caída puede perder hasta el intervalo de autoguardado. Conservar juntos mundo, SQLite, claves y certificados en los respaldos. Las pruebas usan una carpeta propia y credenciales ficticias; no se adaptó ni vinculó la partida individual de El Rayo y no se retomó la skin en pausa.

## Integración con IA 1

No hubo merge a main ni cambios en su checkout. Revisar y coordinar los puntos compartidos de `escena.gd` (menú/entrada), `hud_vivo.gd` (modo del formulario), `red_cliente.gd` (DTLS/ticket) y `red_servidor.gd` (opción DTLS). Los cambios de cuentas propiamente dichos viven en `scripts/cuentas/` y `servidor/cuentas/`. Conservar las adiciones de Fase 5 a esos lectores, registros y a la documentación al resolver conflictos. No sustituir archivos completos por los de esta rama.

Los commits pueden recuperarse desde el clon independiente con `git fetch <ruta-al-clon-Linde-cuentas> feature/cuentas`, revisar `FETCH_HEAD` y después integrar los commits coordinadamente. La rama queda local, sin push ni merge no solicitado.
