# Integración de cuentas y arte con main — 26/10/2026

Solicitud del usuario: publicar e integrar todos los cambios de cuentas y la corrección de hashes. Se incorporó `origin/main` `42bef50` (Fase 5a y primera vivienda funcional) a `feature/cuentas`, sin conflictos de Git. Se preservan sus cambios de comunidades, viviendas, mundo y red; la ampliación de cuentas se mantiene en los módulos propios y en los puntos mínimos de transporte/interfaz.

Validación de la versión combinada:

- **10/10 suites seleccionadas sin fallos**, resultados por suite en `suites.json`: general, reglas, UI, comunidades (núcleo/UI/ENet), vivienda (núcleo/UI/ENet) y visual A1–A3. Logs individuales en esta carpeta. No se repitió la batería completa de 43 suites ni se presenta como ejecutada ahora.
- **35/35 comprobaciones de cuentas sin fallos**, con procesos reales de cliente/servidor, HTTPS/DTLS, reinicio, inventario/equipo/XP/mapa, sesiones duplicadas, contraseña de servidor y cuenta, certificado y protección contra arranque duplicado (`integracion.json`). Datos nuevos aislados, sin adaptar las partidas antiguas.
- **Interfaz renderizada**, inicio/cierre real en UDP 7777 y HTTPS/TCP 7778, formularios y error de puerto. Capturas de esta integración incluidas. El ensayo ahora usa una carpeta por PID para evitar reutilizar un mundo de una revisión con otras reglas.
- Los hashes E04/E05 siguen pasando en la suite general; PNG y contenido del catálogo no cambian. Las reglas de LF quedan en `.gitattributes`.
- Se mantiene el protocolo base actualizado de main y las ampliaciones heredadas de viviendas/comunidades; no se vuelve a archivos de Fase 4.

Alcance de red: localhost y conexión a la IP LAN propia, desde la misma máquina. Sin prueba desde otra computadora física ni Internet/NAT público. Los avisos conocidos de ObjectDB/recursos al cerrar permanecen. La skin sigue en pausa y no forma parte de esta publicación.

Las modificaciones de pruebas permiten elegir suites y carpeta de captura; los archivos originales de las suites de IA 1 no se editan. No se tocó su checkout ni el borrador local del arte de la skin. La integración a main y su push fueron autorizados expresamente por el usuario; el resultado remoto se comprueba después de publicar.
