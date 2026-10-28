# §8 y §9. Código fuente, servidor multijugador y distribución (entregables E, F, G)

**Verificado el 2026-10-28.** Fuentes: documentación oficial de Luanti (Linux, Windows, servidor,
*remote media*), `minetest.conf.example` 5.17.0, API de GitHub y comunicado del incidente de ContentDB.

---

# §8. Cómo obtener el código fuente (entregable E)

## 8.1 Regla general

Todo lo que Linde necesita es **código abierto descargable por Git**. No hay instaladores, ni
cuentas, ni licencias que comprar. Lo único que **no** se puede hacer hoy es usar el instalador de
contenido del cliente, porque ContentDB está caído (§0.3).

## 8.2 Motor Luanti

### Opción 1 — Binario oficial (recomendado)

Descarga directa de la versión **5.17.0**:

| Plataforma | Archivo | Enlace |
|---|---|---|
| Windows x64 | `luanti-5.17.0-win64.zip` (16 MB) | <https://github.com/luanti-org/luanti/releases/tag/5.17.0> |
| Windows instalador | `luanti-5.17.0.exe` (11 MB) | ídem |
| **macOS Apple Silicon** | `luanti_5.17.0_macos12.3_arm64.zip` (12 MB) | ídem |
| macOS Intel | `luanti_5.17.0_macos12.3_x86_64.zip` | ídem |
| Android | `luanti-5.17.0-arm64-v8a.apk` | ídem |

**Linux:** el proyecto **no publica binario de Linux** en las *releases*; se usa el paquete de la
distribución (puede estar atrasado) o los binarios headless mantenidos por la comunidad:
<https://github.com/rollerozxa/luantiserver> (recomendado por la documentación oficial).

### Opción 2 — Código fuente

```bash
git clone https://github.com/luanti-org/luanti.git
cd luanti
git checkout 5.17.0          # fijar versión, no usar master
```

Compilación solo servidor (sin cliente, sin dependencias gráficas):

```bash
cmake -S . -B build -DBUILD_CLIENT=0 -DBUILD_SERVER=1 -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

> **Para Linde no hace falta compilar el motor.** Solo se compila si se quiere un `luantiserver`
> headless propio o si se necesita una arquitectura sin binario oficial. **No se modifica el motor.**

## 8.3 Juego base (Mineclonia)

```bash
git clone https://codeberg.org/mineclonia/mineclonia.git
cd mineclonia
git checkout 0.124.1                      # etiqueta = versión exacta
# o por commit, si la etiqueta cambia:
# git checkout 7410cf18a231b4dd094bd90dc534951ef17b4275
```

Espejo alternativo (útil si Codeberg está lento): <https://github.com/mineclonia-mirror/mineclonia>.

Descarga por ZIP, sin Git:

```
https://codeberg.org/mineclonia/mineclonia/archive/0.124.1.zip
```

El ZIP se descomprime y la carpeta se renombra a `mineclonia` dentro de `games/`.

## 8.4 Mods

Cada mod se clona en el commit fijado en [`anexos/mods_pin.sh`](anexos/mods_pin.sh). Plantilla:

```bash
git clone https://github.com/minetest-mods/moreores.git mods/moreores
cd mods/moreores && git checkout <commit>
```

ZIP genérico de GitHub (sin Git):

```
https://codeload.github.com/<usuario>/<repo>/zip/<commit-o-rama>
```

ZIP de Codeberg:

```
https://codeberg.org/<usuario>/<repo>/archive/<etiqueta>.zip
```

> **Aviso de seguridad:** el incidente de ContentDB recomienda comparar cualquier paquete
> descargado entre el 22 y el 26 de octubre de 2026 con el repositorio upstream. Clonar por Git en
> un commit concreto evita el problema de raíz.

## 8.5 Texturas, sonidos y modelos reutilizables

| Fuente | Qué se puede usar | Licencia |
|---|---|---|
| Mineclonia | Todo su arte interno | GPL-3.0 / `LEGAL.md` (por paquete) |
| Minetest Game | Texturas y sonidos base | **CC BY-SA 3.0** (atribución + compartir igual) |
| Luanti | Texturas del motor | CC BY-SA 3.0 |
| `3d_armor` | Arte de armaduras | CC BY-SA 3.0 |
| Prototipo Godot de Linde | Hojas de personaje, paletas, iconos | **propio** |

Regla: **cada archivo de arte que entre en Linde debe tener su licencia y su autor registrados** en
`licencias/`. El proyecto ya tiene esa carpeta y esa convención.

## 8.6 Gestión de versiones y conservación de modificaciones

El problema real no es descargar, es **actualizar sin perder lo propio**. Tres reglas:

1. **Nunca editar dentro de `mineclonia/` ni de un mod ajeno.** Todo lo de Linde vive en
   `juego/mods/linde_*`.
2. **Fijar por etiqueta o commit** en un archivo de versiones (`mods_pin.sh`). Actualizar = cambiar
   una línea y volver a ejecutar.
3. **Si hay que tocar un mod ajeno, hacer fork** y registrar el cambio:
   ```bash
   git clone https://github.com/autor/mod.git linde_mods/mod
   cd linde_mods/mod
   git remote add upstream https://github.com/autor/mod.git
   git checkout -b linde-parche
   # ... cambios ...
   git commit -m "linde: adaptar <mod> a mcl_*"
   git diff upstream/master...HEAD > ../../licencias/parches/mod.patch
   ```
   El parche queda versionado; al actualizar el upstream se reaplica.

### ¿Juego propio derivado o dependencia?

**Las dos cosas, en momentos distintos** (detalle en §7.6):

- **Durante el desarrollo:** Mineclonia **como dependencia sin modificar**, y los mods de Linde en
  `worlds/linde/worldmods/`. Así se puede actualizar Mineclonia con un `git pull` sin tocar nada
  de Linde.
- **Para distribuir:** un script arma `games/linde/` copiando Mineclonia fijada + `linde_core` +
  `linde_assets` + un `game.conf` propio. El ZIP resultante es «Linde», pero se reconstruye desde
  el repositorio en un comando.

Ventaja de no forkear: se heredan las correcciones de Mineclonia. Inconveniente: no se puede
renombrar contenido interno (por ejemplo, que «creeper» se llame distinto) sin un fork o sin un mod
de renombrado. Para la primera beta, **no forkear**.

## 8.7 Integrar código de terceros respetando licencias

| Licencia | Qué obliga | Qué hacer en Linde |
|---|---|---|
| MIT / Zlib / BSD | Conservar aviso de copyright | Copiar `LICENSE` a `licencias/`; citar autor en el README |
| LGPL-2.1 (3d_armor, areas, unified_inventory) | Aviso + permitir reemplazo del componente | Mantener el mod como carpeta separada y sin enlazar estáticamente; publicar los cambios que se hagan |
| GPL-3.0 (Mineclonia, travelnet, cottages, mob_core) | Todo el derivado distribuido debe ser GPL-3.0 y con código disponible | **Linde se publica con GPL-3.0**; incluir `LICENSE` y el código de `linde_core` |
| AGPLv3 (Repixture) | Como GPL, también para uso en red | Motivo para **no** usar Repixture como base (mezclar AGPL con GPL-3.0 ya es delicado) |
| CC BY-SA 3.0/4.0 (arte) | Atribución + compartir igual | Registro de autoría por archivo en `licencias/` |
| **Sin licencia** | Todos los derechos reservados | **No redistribuir**; pedir permiso o sustituir (ver §5.J) |

---

# §9. Servidor multijugador privado para 5–10 jugadores (entregable F)

## 9.0 Dimensionamiento (cifras oficiales)

La [documentación de servidor](https://docs.luanti.org/for-server-hosts/setup/) fija la referencia
para **≈10 jugadores**:

| Recurso | Recomendación oficial | Comentario para Linde |
|---|---|---|
| CPU | ≥2 núcleos, preferible 4; **frecuencia por núcleo alta** | Luanti es sobre todo monohilo: un i5/Ryzen 5 moderno rinde más que muchos núcleos lentos |
| RAM | 4 GB «debería alcanzar»; escalar con Mineclonia/VoxeLibre | Con Mineclonia: **6–8 GB** es prudente |
| Disco | 30 GB SSD/NVMe | El mundo crece con la exploración |
| Red | 20 Mbps | Subida doméstica típica en Argentina puede ser 10–20 Mbps: suficiente para 5–10 jugadores |
| Puerto | **30000/UDP** | Luanti usa **solo UDP** |

## 9.1 Servidor en Windows 11

Procedimiento verificado contra la [guía oficial de Windows](https://docs.luanti.org/for-server-hosts/setup/windows/):

1. Descargar `luanti-5.17.0-win64.zip` y descomprimir en `C:\Linde\luanti\`.
2. Poner el juego en `C:\Linde\luanti\games\mineclonia\` (carpeta con `game.conf` dentro).
3. Abrir PowerShell en `C:\Linde\luanti\bin` y ejecutar:
   ```powershell
   .\luanti.exe --server --worldname linde --gameid mineclonia
   ```
   La primera vez crea el mundo. Si no se pasa `--worldname` y hay varios, el servidor se queja
   («Multiple worlds are available»).
4. **Firewall:** Windows Defender pregunta la primera vez. Si se denegó, hay que abrir
   *Firewall de Windows Defender con seguridad avanzada* → regla de entrada → **UDP 30000**.
5. **Arranque automático y reinicio ante caídas:** un `.bat` con bucle, tal como publica la
   documentación:
   ```bat
   @echo off
   :crash
   luanti.exe --server --worldname linde --gameid mineclonia
   goto crash
   ```
   Para arrancar con Windows: Programador de tareas → «Al iniciar sesión» → ese `.bat`.
6. **Persistencia:** el mundo vive en `C:\Linde\luanti\worlds\linde\`. Se guarda solo cada
   `server_map_save_interval` (5,3 s) y al apagar.
7. **Administración:** consola del servidor; comandos `/privs`, `/kick`, `/ban`, `/shutdown`.
   Dar privilegios de admin a los amigos de confianza: `/privs <jugador> basic_privs,privs,server`.
8. **Rendimiento:** usar SSD; no dejar el servidor en un disco externo USB; cerrar el cliente en
   la misma máquina si se puede (el cliente consume CPU/GPU que necesita el servidor).

**Ventaja de Windows:** es el sistema de la mayoría de los amigos y el que el proyecto ya usa
(`Iniciar-Servidor.bat` existe). **Inconveniente:** el arranque automático requiere sesión iniciada,
y Windows Update puede reiniciar la máquina.

## 9.2 Servidor en macOS Apple Silicon

**Compatibilidad nativa: sí.** La release 5.17.0 publica `luanti_5.17.0_macos12.3_arm64.zip`
(12 MB), es decir, **binario arm64 nativo**, no Rosetta. [V]

Procedimiento:

1. Descargar el ZIP arm64, descomprimir y arrastrar `Luanti.app` a `/Applications`.
2. Primera ejecución: **clic derecho → Abrir** (Gatekeeper bloquea binarios no notarizados).
3. Poner el juego en
   `~/Library/Application Support/Luanti/games/mineclonia/`.
4. Ejecutar el servidor desde la Terminal, usando el binario **dentro** del bundle:
   ```bash
   "/Applications/Luanti.app/Contents/MacOS/luanti" --server \
       --worldname linde --gameid mineclonia
   ```
   La ruta del bundle es estable; no hace falta instalar nada más.
5. Firewall de macOS: *Ajustes del sistema → Red → Firewall → Opciones* y permitir `luanti`.
6. Arranque automático: `launchd` con un `.plist` en `~/Library/LaunchAgents/`, o simplemente un
   `.command` en el escritorio (el proyecto ya tiene `Iniciar-Cenital.command` como precedente).
7. **Diferencia respecto a Windows:** no hay guía oficial de macOS para servidores; la lista de la
   documentación cubre Linux, Windows, TrueNAS y Docker. **Lo anterior se deduce de la existencia
   del binario y de la interfaz de línea de comandos común; no está publicado como guía oficial,
   así que hay que probarlo.** [P]
8. **Limitaciones conocidas:** los Mac con Apple Silicon duermen y suspenden procesos; hay que
   desactivar la suspensión (*Ajustes → Batería → Prevent automatic sleeping*) si se quiere un
   servidor 24/7. El rendimiento monohilo de los chips M-series es **excelente** para Luanti.

## 9.3 Servidor en Linux (PC dedicada o VPS)

Verificado contra la [guía oficial de Linux](https://docs.luanti.org/for-server-hosts/setup/linux/):

1. **Binario headless:** `luantiserver` (paquete de la distro, o binarios de
   <https://github.com/rollerozxa/luantiserver>).
2. **Instalación mínima:**
   ```bash
   sudo useradd -r -m -d /opt/linde linde
   sudo -u linde mkdir -p /opt/linde/luanti/{bin,games,worlds}
   # copiar luantiserver a bin/, mineclonia a games/, linde_core a worlds/linde/worldmods/
   ```
3. **Servicio systemd** (`/etc/systemd/system/linde.service`):
   ```ini
   [Unit]
   Description=Linde RPG (Luanti)
   After=network-online.target

   [Service]
   Type=simple
   User=linde
   WorkingDirectory=/opt/linde/luanti
   ExecStart=/opt/linde/luanti/bin/luantiserver --worldname linde --gameid mineclonia --logfile /var/log/linde.log
   Restart=always
   RestartSec=5
   StandardOutput=journal

   [Install]
   WantedBy=multi-user.target
   ```
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now linde
   journalctl -u linde -f
   ```
4. **Firewall:** `sudo ufw allow 30000/udp` (solo UDP; Luanti no usa TCP).
5. **Actualizaciones:** `git -C /opt/linde/luanti/games/mineclonia fetch && git checkout <nueva>`,
   luego `systemctl restart linde`. Probar antes en un mundo de prueba.
6. **Copias de seguridad:** ver §9.6, con `tar` + `sqlite3 .backup` y `systemd timer`.
7. **Administración remota:** SSH; `journalctl` para logs; la consola del servidor se puede dejar en
   `screen`/`tmux` si no se usa systemd.

**Ventaja:** es la única opción que da **24/7 real** en hardware propio o VPS.

## 9.4 Conexión desde internet

### 9.4.1 Lo que hay que entender primero

- **Puerto:** 30000/**UDP**. Abrir TCP no sirve.
- **IP pública:** es la que el servidor debe dar a los amigos (o un dominio).
- **NAT:** el router debe redirigir el puerto UDP 30000 a la IP **local** del servidor.
- **CGNAT:** si el ISP pone al cliente detrás de CGNAT, **no se puede abrir el puerto**. La propia
  documentación de Luanti lo dice: «Keep in mind that if you are behind CGNAT, you are unable to
  host a public server from home at all» [V]. Comprobación rápida: si la IP del router (WAN) no
  coincide con la que ven los servicios de «cuál es mi IP», hay CGNAT.

### 9.4.2 Alternativas según el caso

| Situación | Solución | Costo | Notas |
|---|---|---|---|
| IP pública, sin CGNAT | *Port forwarding* UDP 30000 + firewall | 0 | La más simple y de menor latencia |
| IP dinámica | *Port forwarding* + **DNS dinámico** (DuckDNS, No-IP, Cloudflare DNS con script) | 0 | Los amigos usan un nombre, no una IP |
| CGNAT o no se quiere exponer la IP | **Tailscale** (red privada tipo VPN) | 0 (plan personal) | Cada amigo instala Tailscale y usa la IP 100.x del servidor. **No requiere abrir puertos.** El servidor sigue siendo privado [C] |
| Amigos que no quieren instalar VPN | **playit.gg** (túnel UDP) | 0 (4 puertos, 2 agentes en el plan gratuito) | Funciona con Luanti (reportes de la comunidad). Verificar límites actuales: en 2026 el **TCP genérico pasó a ser de pago**; el **UDP genérico** sigue disponible en el plan gratuito [C] |
| Servidor 24/7 sin PC encendida | VPS con *free tier* (§9.5) | 0 | La única opción de gratuidad permanente real |

### 9.4.3 Recomendación concreta para Linde

Para **5–10 amigos de confianza**, la combinación con mejor relación seguridad/esfuerzo es:

> **Servidor en la PC de un amigo (Windows o macOS) + Tailscale + lista de jugadores permitidos.**
>
> Motivos: no se expone nada a Internet, no hay puertos que abrir, no hay CGNAT que sortear, y el
> servidor sigue siendo accesible desde cualquier red. El costo es que cada amigo instala una app
> más y que la PC debe estar encendida.

### 9.4.4 Seguridad y permisos

- `default_privs = interact, shout` (valor por defecto [V]) es correcto para amigos.
- **No dar `server` ni `privs` a todos.** Crear un admin y dar `basic_privs` a los demás.
- Activar `enable_rollback_recording = true` [V] para poder revertir destrozos.
- Con `secure.enable_security = true` (por defecto) los mods no pueden ejecutar comandos del
  sistema. Mantenerlo.
- Contraseñas: el backend por defecto (`auth_backend = sqlite`) guarda *hashes* SRP; aun así, para
  amigos, Tailscale ya autentica la red.

## 9.5 Servidor gratuito permanente: qué es verdad y qué no

| Servicio | ¿Gratis permanente? | ¿Sirve para Luanti? | Evidencia |
|---|---|---|---|
| **Oracle Cloud Always Free** | **Sí**, indefinido | **Sí**: 2 OCPU ARM, 12 GB RAM, 200 GB disco, 10 TB de egreso | [V] reducción aplicada 2026-06-15 y exigible desde 2026-08-18 (<https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/>) |
| Google Cloud free tier (e2-micro) | Sí, con cuotas | Posible, pero 1 vCPU y 1 GB: justo para 10 jugadores | [C] verificar condiciones |
| AWS Free Tier | **No** (12 meses) | — | Prueba temporal, no permanente |
| Render / Railway / Fly.io | No (créditos o suspensión) | **No**: no ofrecen UDP arbitrario o duermen el proceso | [C] |
| Hosting específico de Luanti (`luanti.ch`, `pinehosting`) | **No**, son de pago | Sí | La propia doc los lista como opciones de pago |
| Aternos y similares | Gratis con cola | **No soportan Luanti** (solo Minecraft) | [C] |
| PC propia + Tailscale/playit | Gratis, **pero depende de tu PC encendida** | Sí | §9.4 |

### La distinción que hay que dejar clara

- **Gratis permanente de verdad:** Oracle Always Free (con tarjeta de verificación y riesgo de que
  cambien las condiciones, como ya pasó en junio de 2026) y una PC propia.
- **Gratis «mientras tu PC esté encendida»:** Tailscale, playit.gg, DNS dinámico. No son hosting:
  son túneles. Si la PC se apaga, el servidor no existe.
- **Prueba temporal:** AWS 12 meses, créditos de GCP, Railway.
- **No gratuito disfrazado:** cualquier hosting de juegos con «plan gratis» que suspende por
  inactividad no sirve para un mundo persistente de un RPG.

> **Recomendación:** empezar con **PC propia + Tailscale** (costo 0, inmediato) y, si el proyecto
> crece, mover a **Oracle Always Free** con el mismo `worlds/linde/` copiado. La migración es copiar
> una carpeta (§9.6).

## 9.6 Operación y mantenimiento (entregable F, segunda parte)

### Arrancar y detener

- **Arrancar:** el comando de §9.1–9.3. Con systemd: `systemctl start linde`.
- **Detener bien:** `systemctl stop linde` (envía SIGTERM → el servidor guarda y cierra) o el
  comando `/shutdown` en la consola. **Nunca matar el proceso con `kill -9`**: puede corromper
  `map.sqlite`.

### Añadir o quitar mods

1. **Parar el servidor.**
2. Poner/quitar la carpeta en `worlds/linde/worldmods/` (mods del mundo) o en `games/mineclonia/mods/`
   (mods del juego).
3. Arrancar y leer el log: los errores de dependencias aparecen como
   `Failed to load mod "x": depends on y`.
4. **Quitar un mod con nodos ya colocados deja nodos desconocidos** (`unknown`) en el mundo. No
   corrompe, pero ensucia. Añadir mods de generación **solo afecta terreno nuevo** (§5.F).

### Actualizar el juego

```bash
cd games/mineclonia
git fetch --tags && git checkout 0.125.0   # ejemplo
```
Antes: copia de seguridad del mundo. Después: entrar y comprobar que `linde_core` cargó sin avisos
de overrides.

### Guardar el mundo

- Automático cada 5,3 s (`server_map_save_interval`).
- Al apagar correctamente.
- Manual: `/shutdown` y esperar a que el proceso termine.

### Copias de seguridad (la parte que evita perder la partida)

**Backup en frío (recomendado, simple y seguro):**

```bash
systemctl stop linde
tar czf respaldos/linde-$(date +%F-%H%M).tar.gz -C /opt/linde/luanti/worlds linde
systemctl start linde
```

**Backup en caliente (sin parar el servidor):** copiar la base SQLite de forma consistente:

```bash
sqlite3 /opt/linde/luanti/worlds/linde/map.sqlite \
        ".backup '/backup/map-$(date +%F-%H%M).sqlite'"
cp /opt/linde/luanti/worlds/linde/{players.sqlite,map_meta.txt,world.mt,mod_storage.sqlite} /backup/
```
*(Técnica estándar de SQLite; **no probada en este proyecto** [P].)*

**Automatización:** `systemd timer` diario para el backup en frío (con parada breve de 20 s) o
`cron` con el backup en caliente. Rotar: 7 diarios + 4 semanales.

**Restaurar:**
```bash
systemctl stop linde
tar xzf respaldos/linde-2026-10-28-0300.tar.gz -C /opt/linde/luanti/worlds/
systemctl start linde
```

### Administrar jugadores y permisos

| Acción | Comando |
|---|---|
| Ver privilegios | `/privs <jugador>` |
| Dar admin limitado | `/privs <jugador> basic_privs` |
| Expulsar / banear | `/kick <jugador>` · `/ban <jugador>` |
| Lista de conectados | `/status` |
| Proteger zonas | mod `areas` (si se instala) |
| Revertir destrozos | `enable_rollback_recording = true` + comandos de rollback |

### Evitar pérdida o corrupción

1. Apagar siempre con `/shutdown` o `systemctl stop`.
2. `sqlite_synchronous = 2` (por defecto [V]) prioriza integridad.
3. Backups automáticos y **probar la restauración** al menos una vez al mes (un backup que nunca se
   restauró no es un backup).
4. No editar `map.sqlite` a mano. Para operaciones masivas, usar herramientas del juego o mods.
5. Fijar versiones: una actualización a mitad de partida es el escenario típico de corrupción.

### Migrar el mundo a otra computadora

1. Parar el servidor.
2. Copiar **toda** la carpeta `worlds/linde/` (incluye `map.sqlite`, `players.sqlite`,
   `mod_storage.sqlite`, `map_meta.txt`, `world.mt`, `worldmods/`).
3. Copiar `games/mineclonia/` y los mods en la **misma versión**.
4. Arrancar en la máquina nueva. Si la versión del motor es la misma o mayor, funciona.

### Compartir el juego con amigos

Ver §9.7 (entregable G).

## 9.7 Distribución de Linde (entregable G)

### Lo que **no** hay que hacer

**No hay que enviar el juego a los amigos.** Al conectarse a un servidor, Luanti descarga
automáticamente texturas, sonidos y modelos (`remote media`, verificado en la
[guía oficial](https://docs.luanti.org/for-server-hosts/remote-media/)). El cliente **no necesita
tener Mineclonia ni `linde_core` instalados**. Esto es una ventaja enorme frente a Minecraft.

### Lo que sí hay que hacer

| Nivel | Cómo | Esfuerzo | Cuándo |
|---|---|---|---|
| **1. Instrucción de 3 pasos** | «Instalá Luanti 5.17.0 desde luanti.org, abrí, *Join Game*, escribí `linde.tailXXXX.ts.net:30000`» | 1 mensaje | **Beta con amigos** |
| **2. ZIP del cliente** | ZIP con Luanti + un `minetest.conf` que trae el servidor precargado | 30 min | Si los amigos se traban |
| **3. Juego propio publicado** | `games/linde/` empaquetado y subido a ContentDB como `game` | 1 día | Cuando ContentDB vuelva |
| **4. Instalador/launcher** | Un `.exe`/`.dmg` con Inno Setup o un script que descarga y descomprime | 1–2 días | Solo si hay jugadores externos |
| **5. Servidor de medios propio** | `remote_media` con nginx para acelerar la primera conexión | 2 horas | Si el ZIP de medios supera ~50 MB |

### Detalle de cada opción

**1. Instrucción directa (recomendada para la beta).** El amigo instala el binario oficial de su
sistema (§8.2), abre Luanti, pestaña *Join Game*, escribe la dirección. La primera conexión tarda
porque descarga los medios de Mineclonia (cientos de MB); las siguientes son rápidas porque el
cliente los cachea.

**2. ZIP del cliente.** Se prepara una carpeta con el binario oficial + `minetest.conf` con
`address = <servidor>`, `port = 30000`, `name = <sugerido>`. No incluye el juego: eso lo manda el
servidor. **No se puede llamar «instalador»**: es un ZIP que se descomprime.

**3. Juego propio en ContentDB.** Un juego es una carpeta `games/linde/` con `game.conf`
(`title = Linde RPG`, `description`, `first_mod`, `last_mod`). Se publica como paquete tipo `game`
siguiendo la guía de creadores. **Requisito:** licencia clara de todo lo incluido (Mineclonia
GPL-3.0 obliga a que Linde sea GPL-3.0). **Bloqueado** hasta que ContentDB vuelva.

**4. Launcher.** No se recomienda escribirlo: el cliente oficial ya tiene lista de servidores y
ContentDB. Un launcher propio solo se justifica si Linde se distribuye a gente que no sabe
descomprimir un ZIP, y en ese caso conviene un `.exe` con Inno Setup que **descargue** el binario
oficial en lugar de empaquetarlo (así se evita redistribuir el motor y se cumple LGPL sin
complicaciones).

**5. Servidor de medios.** Con `remote_media = https://media.linde.example/` y `index.mth`
generado con el script oficial. Útil si la conexión inicial es lenta, pero **no necesario para 10
amigos**.

### Qué se descarga automáticamente y qué debe estar instalado

| Elemento | ¿Lo envía el servidor? |
|---|---|
| Texturas, sonidos, modelos `.b3d`/`.obj`/`.gltf` | **Sí**, automáticamente |
| Definiciones de nodos, ítems, recetas, HUD, formspec | **Sí** (son código del servidor) |
| El juego (`games/mineclonia`) | **No**: va en el servidor |
| El motor Luanti | **No**: lo instala el jugador |
| Packs de texturas del cliente | No; son opcionales y del jugador |
| Mods de cliente (CSM) | No; el servidor no los necesita |

**Conclusión del entregable G:** para la beta, los amigos **solo instalan Luanti**. Publicar Linde
como juego propio es un paso posterior, cuando ContentDB esté disponible y la licencia esté
resuelta.
