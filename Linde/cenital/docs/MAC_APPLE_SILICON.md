# Linde — Mac con chip Apple (M1/M2/M3/M4 o posterior)

Paquete experimental **arm64**, no Intel. Construcción aprobada el 26/10/2026:
[ejecución 40426412243](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412243),
código `a4fffda`. [Descargar artefacto](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412243/artifacts/12700236801),
aproximadamente 237 MB, retención 14 días. El workflow `Servidor privado Mac Apple
Silicon` solo publica el ZIP si pasan las pruebas. Consultar su ejecución para
conocer el resultado; este documento por sí solo no certifica una construcción.

## Descargar y abrir

**Recomendado:** [descargar ZIP Mac sin cuenta de GitHub](https://github.com/joerojas2810-collab/Linde/releases/download/v0.1.0-preview.1/Linde-Mac-Apple-Silicon.zip)
desde la Release pública experimental. Extraerlo **una sola vez** para obtener
`Linde Mac`, y seguir desde el paso 4 de abajo. No caduca a los 14 días como Actions.

Los pasos 1–3 siguientes corresponden únicamente a la alternativa de Actions:

1. En GitHub → **Actions → Servidor privado Mac Apple Silicon**, abrir una ejecución
   verde de `arena/9a96dc31-linde`.
2. En **Artifacts**, descargar `Linde-Mac-Apple-Silicon-servidor-y-juego`. GitHub puede
   pedir iniciar sesión; la retención es de 14 días.
3. Extraer el ZIP del artefacto. Dentro viene **Linde-Mac-Apple-Silicon.zip**: extraer
   también ese archivo, que conserva permisos ejecutables y enlaces de macOS.
4. Mover la carpeta **Linde Mac** completa a una ubicación con permiso de escritura,
   por ejemplo una carpeta propia de Juegos. No separar los archivos de `runtime/`.
5. Abrir **Jugar Linde.command**. Para jugar solo: **Jugar local / servidores
   privados (sin cuenta global)** → **Nueva partida**.

No necesitas instalar Godot, Python, Homebrew, Rosetta ni una VPN. El paquete
incluye Godot universal ejecutado nativamente y Python/dependencias arm64. No cambia
el protocolo ni convierte guardados; usar la misma versión de Linde en los clientes.

### Si macOS bloquea la primera apertura

El contenedor de Linde y sus `.command` no están firmados/notarizados por un
Developer ID propio. El runner no reproduce la cuarentena de una descarga por Safari.

- Comprueba que procede de la ejecución oficial de este repositorio.
- Prueba clic derecho → **Abrir** en el `.command` y, si macOS lo ofrece, confirma.
- Si sigue bloqueado: **Ajustes del Sistema → Privacidad y seguridad → Abrir de
  todos modos** para el componente específico que acabas de intentar abrir.
- Si identifica `Godot.app` como bloqueado, está en `runtime/`; la primera apertura
  directa puede abrir el gestor del motor: ciérralo y vuelve a `Jugar Linde.command`.
- No desactives Gatekeeper globalmente, no ejecutes como administrador y no aceptes
  un binario que macOS marque como malware. Ante ese aviso detente y reporta el texto.

El ZIP interno está diseñado para conservar permisos. Si el `.command` aparece
como documento y no se puede ejecutar tras extraerlo con otra herramienta, usa el
Descompresor de macOS y vuelve a extraer el ZIP interno original.

## Iniciar servidor y entrar en la misma Mac

1. Doble clic en **Iniciar servidor.command**; se abrirá Terminal.
2. Espera la escucha UDP 7777/TCP 7778. Conserva abierta esa ventana.
3. Abre **Jugar Linde.command**, elige el modo local/privado y después **Unirse**.
4. Dirección `127.0.0.1`, UDP `7777`, TCP `7778` en opciones avanzadas.
5. Escribe un nombre visible. Por defecto no hay contraseña del mundo.
6. Compara la huella SHA-256 con la de la ventana del servidor antes de confirmar.
7. Para cerrar, abre **Guardar y cerrar servidor.command** y espera la confirmación
   en la consola original. También puedes pulsar Ctrl+C en esa consola. No fuerces
   su cierre con el botón X ni apagues antes de que guarde.

La primera ejecución crea `servidor/datos/servidor.json`. Para poner contraseña,
cierra el servidor, edita `password` en ese JSON y vuelve a iniciarlo. Mantén el
JSON válido y `privado: true`. El mundo predeterminado está bajo
`servidor/datos/mundos/amigos/`. Respalda esa carpeta completa con el servidor parado.

## Unirse desde otra computadora, Mac o Windows

- En la misma red: usar la IP LAN de la Mac anfitriona, no `127.0.0.1`.
- Desde otra casa: usar su IP pública/dominio y configurar en el router UDP `7777`
  y TCP `7778` hacia la Mac. Permitir la conexión en el firewall sin desactivarlo.
- CGNAT puede impedir el acceso directo; el paquete no evita esa limitación.
- Quien aloja mantiene su PC y servidor encendidos. Los demás solo abren el juego.
- La cuenta/credencial privada de un personaje no se transfiere automáticamente de
  Windows a Mac. El mismo nombre visible no recupera el personaje: respalda y copia
  tu carpeta `servidores_privados/` a tu propia Mac por un medio seguro si quieres
  recuperar el acceso desde otro equipo. Nunca la compartas con otros jugadores.

Datos del cliente macOS: normalmente en
`~/Library/Application Support/Godot/app_userdata/`, en la carpeta del proyecto.
Ahí viven `perfil_local.cfg`, `perfiles/` y `servidores_privados/`. Esta última
contiene secretos. Ver la guía general para respaldos, confianza y certificados.

## Qué comprueba el workflow

Comprueba arm64, hashes de los runtimes, Python/HTTPS, compilación de scripts Godot,
perfil local, identidad global, dos clientes separados con reconexión, contraseña y
certificado incorrectos. Construye con Python standalone relocatable y las licencias
incluidas, mueve el paquete a una ruta con espacios y prueba arranque/cierre con
mundo guardado. Luego crea el ZIP con `ditto`, lo extrae y repite el arranque/cierre.

No es un playtest de la interfaz, una prueba de cuarentena/Gatekeeper en una Mac
personal, ni una prueba entre Windows y Mac, dos computadoras físicas o Internet.
Estos últimos recorridos requieren validación manual.
