# Linde — RPG Mundo Vivo

Juego cenital (vista superior) en Godot 4.7.1. Estado, controles y decisiones: `Linde/cenital/docs/DECISIONES.md`.

## Jugar

```bash
./Iniciar-Cenital.command                                   # menú normal
./Iniciar-Cenital.command --nueva=1 --equipo=zarzal:oscuro   # partida nueva con el equipo puesto
```

`--equipo=` y `--mira=` solo aplican junto a `--nueva=`. El arte anterior (dibujo por código) ya no existe.

## Servidor privado entre amigos (experimental)

Modo opcional sin cuenta global y paquetes portables **Windows x64 y Mac Apple Silicon**,
construidos y validados automáticamente con Godot 4.7.1 el 26/10/2026.
[Windows](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412236) ·
[Mac Apple Silicon](https://github.com/joerojas2810-collab/Linde/actions/runs/40426412243).
[Guía específica Mac](Linde/cenital/docs/MAC_APPLE_SILICON.md).
Incluye Fase 7 y la corrección de recursos/clases del ZIP descargado.
Falta prueba manual entre equipos y por Internet; no es un release estable.
[Guía de juego local, servidor, conexión y respaldos](Linde/cenital/docs/SERVIDOR_PRIVADO.md).
El flujo anterior de cuentas sigue disponible.

## Prueba de autonomía

Abrir `Iniciar-Prueba-Autonomia.command` para una partida separada donde los habitantes recolectan, fabrican, desgastan y reparan herramientas, negocian entregas y abastecen grupos según sus carencias, sin tarjetas de misión. `J` muestra necesidades y permite ayudar estando cerca; `E` habla con ellos. `G` abre materiales, planos, laminados y práctica; las piezas se generan con reglas y el aprendizaje cambia las futuras fabricaciones. [Instrucciones y límites](Linde/cenital/docs/AUTONOMIA.md). [Materiales y desarrollo](Linde/cenital/docs/DESARROLLO.md).

## Estructura

| Carpeta | Contenido |
|---|---|
| `Linde/cenital/` | El juego (scripts, datos, arte, tests) |
| `Linde/documentos/` | Visión, punto de inicio, contrato de arte y sistema de equipo |
| `Linde/arte-entregado/` | Entregas de arte originales, sin alterar |
| `Linde/distribucion/` | Builds exportados |
| `design/`, `docs/`, `production/`, `.claude/` | Flujo del estudio (game brief, ADRs, épicas) |
| `herramientas/` | Motor Godot local y scripts de arte |
| `licencias/`, `archivos-originales/` | Términos y respaldos de las fuentes de terceros |
| `docs/archivo/` | Material histórico (paquetes `INSTRUCCIONES_2_IA`, estados anteriores); no es lectura de trabajo y no se borra sin aprobación |

Pruebas: `herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless --path Linde/cenital --script res://tests/prueba.gd`

## Cómo probar el juego (Mac o Windows)

No hace falta instalar nada: el lanzador descarga Godot 4.7.1 oficial la primera vez (≈85–160 MB, verificado por sha256) a `herramientas/runtime/`, que no se sube al repositorio.

| Sistema | Qué ejecutar |
|---|---|
| Mac | doble clic en `Iniciar-Cenital.command` (la primera vez: clic derecho → Abrir) |
| Windows | doble clic en `Iniciar-Cenital.bat` |

Si ya tienes Godot 4.7.1, define la variable `GODOT` con la ruta al ejecutable y el lanzador lo usa en lugar de descargar.

Con el equipo completo puesto: `Iniciar-Cenital.command --nueva=1 --equipo=zarzal:oscuro` (en Windows, el mismo comando con `.bat`).

Para colaboradores de arte: este repositorio no incluye el motor, las fuentes de terceros (`archivos-originales/`), los builds (`Linde/distribucion/`) ni la caché `.godot/`; todo eso se descarga o se regenera.

Protección y economía: puedes fabricar un candado con **2 lingotes y 2 fibras** junto a una mesa (C), instalarlo en un cofre propio (E) y gestionar permisos. En la prueba de autonomía, J explica necesidades, confianza y economía. [Guía de cofres, economía e identidad](Linde/cenital/docs/PROTECCION_Y_ECONOMIA.md).

**El mapa ahora se amplía al explorar:** el valle inicial se conserva y puedes seguir el camino al sur para encontrar territorio generado por la semilla. Construcciones, cofres y camas exteriores se guardan; el indicador superior muestra bioma y coordenadas. [Guía del mundo por regiones](Linde/cenital/docs/MUNDO_POR_REGIONES.md).
