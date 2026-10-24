# Linde — RPG Mundo Vivo

Juego cenital (vista superior) en Godot 4.7.1. Estado, controles y decisiones: `Linde/cenital/docs/DECISIONES.md`.

## Jugar

```bash
./Iniciar-Cenital.command                                   # menú normal
./Iniciar-Cenital.command --nueva=1 --equipo=zarzal:oscuro   # partida nueva con el equipo puesto
```

`--equipo=` y `--mira=` solo aplican junto a `--nueva=`. El arte anterior (dibujo por código) ya no existe.

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
| `_archivo/` | Material obsoleto (beta lateral, fuentes extraídas, logs, prototipos); se puede borrar |

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
