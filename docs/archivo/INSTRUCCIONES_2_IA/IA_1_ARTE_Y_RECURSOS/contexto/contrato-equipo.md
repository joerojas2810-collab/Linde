# Contrato de arte del equipo de Linde (seis ranuras)

## a) Alcance y estado

**PROPUESTA del lado del código, 2026-10-23. Nada de esto está aprobado ni probado con el generador.** Fija formato, nombres, colores y comprobaciones de las hojas de equipo de `Linde/documentos/sistema-de-equipo.md` (v1: 5 ranuras de set `casco`, `torso`, `guantes`, `botas`, `pantalones` + `escudo`; 3 arquetipos `ligera`, `media`, `pesada` con siluetas compartidas; familias y variantes solo por paleta, §8). El **tamaño final de celda sigue sin decidir** (Fase 2 de `instrucciones-recursos-arte.md`): se parte de las celdas de la biblioteca_01, **32×32 caminata y 48×48 acciones** (verificado en `personaje/manifest.json`). Si la celda cambia, solo cambian los números de la sección c; el validador recibe `--celda=N`.

## b) Hojas a producir

Nombre: `equipo_<arquetipo>_<ranura>_<estado>.png`, minúsculas y guiones bajos. `<ranura>` = `casco|torso|guantes|botas|pantalones`. (La ranura `torso` corresponde a la capa actual `coraza` del cargador; el renombrado es decisión abierta.)

| Lote | Hojas | Estado |
|---|---|---|
| 1 (ahora) | 3 arquetipos × 5 ranuras = **15** `equipo_<arq>_<ranura>_caminata.png` | celda 32 |
| 1 | `escudo_caminata.png` (**1**; ¿una por arquetipo? abierto) y `espada_caminata.png` (**1**, no es del set) | celda 32 |
| 2 (solo cuando se pida) | 15 × `_herramienta.png` y 15 × `_ataque.png` (+ escudo/espada) | celda 48 |

Orden de petición del sistema de equipo (§8.2): primero media, solo frente, y prueba en el mapa; luego 4 direcciones y 4 cuadros; después pesada y ligera. Total lote 1: 17 hojas.

## c) Formato de hoja y ancla

- Caminata: **128×128 = 4 columnas (cuadros) × 4 filas (orientaciones)**, celdas 32×32. Acciones: **192×192**, celdas 48×48, 4 cuadros.
- Filas, de arriba abajo: **frente, derecha, espalda, izquierda** (`FILA` de `capas_sprite.gd`). Columnas = cuadros 0-3; caminata: reposo / paso A / transición / paso B (`personaje/LEEME.md`). Propuesta: 140 ms por cuadro en caminata, 110 ms en acciones (manifiesto, sin aprobar).
- Pivote (pies, centro-abajo): **[16, 32]** en celda 32; **[24, 48]** en celda 48. Los pies del cuerpo base están en la misma línea en todas las celdas; el equipo debe encajar sobre la hoja base `personaje/caminata.png` (mismo cuadro, misma fila).
- Margen: ningún píxel opaco en el anillo exterior de 1 px de la celda.
- **El equipo debe acompañar la caminata**: las 4 columnas no pueden ser la misma pose. La entrega actual (`overlays_ajustados`, solo casco, coraza, escudo y espada) repite la pose y no cumple esto.

## d) Colores índice

Exactamente estos, sin tolerancia, fondo transparente, alfa solo **0 o 255**, sin antialiasing ni ningún otro color (ni contorno aparte):

| Rol | Hex |
|---|---|
| Rojo, color principal | `#FF0000` |
| Verde, sombra | `#00FF00` |
| Azul, acento | `#0000FF` |
| Gris, detalle neutro | `#808080` |

El gris exacto (`#808080`) es mi elección; el sistema solo dice «gris». **Sustitución en el motor** (por implementar, no existe aún): para cada píxel, `color = paleta_familia[rol]`, y luego se aplica el delta de la variante (desplazamiento de tono/valor definido en datos, §8.1). El gris no se recolorea salvo que la paleta de familia lo pida. Las paletas son datos, no imágenes.

## e) Orden de capas (abajo a arriba)

Base actual del cargador: `cuerpo, pantalon, tunica, cinturon, coraza, escudo, espada, pelo, casco` (`ORDEN_POR_DIRECCION`). Propuesta con las 6 ranuras (`b_` = ropa base, sin sufijo = equipo):

| Orientación | Orden propuesto |
|---|---|
| Frente | cuerpo, b_botas, b_pantalon, b_tunica, b_cinturon, botas, pantalones, torso, guantes, escudo, espada, pelo, casco |
| Derecha | cuerpo, b_botas, b_pantalon, **escudo**, b_tunica, b_cinturon, botas, pantalones, torso, guantes, **espada**, pelo, casco |
| Espalda | igual que Frente |
| Izquierda | cuerpo, b_botas, b_pantalon, **espada**, b_tunica, b_cinturon, botas, pantalones, torso, guantes, **escudo**, pelo, casco |

Razón (en discusión): en perfil derecho el personaje mira al este y se ve su costado derecho; la espada (mano derecha) es el brazo cercano y el escudo queda detrás del torso. En perfil izquierdo, al revés. La revisión posterior que propone lo contrario sigue **sin resolver**; se decide con la prueba en el mapa. Para invertirlo, el cargador usa una constante (`INVERTIR_PERFILES := false`): si es `true`, se intercambian las listas de `Vector2i.RIGHT` y `Vector2i.LEFT` (hoy se hace a mano en `capas_sprite.gd`; la constante es propuesta y no existe).

**Capas base ocultas** (propuesta, a confirmar en el mapa): `torso` oculta `tunica` (¿y `cinturon`? abierto); `pantalones` oculta `pantalon`; `botas` oculta las botas base. `casco`/`guantes` no ocultan nada (el pelo se dibuja bajo el casco; cuánto se recorta es abierto). Nota **no verificada**: según `personaje/LEEME.md`, `integrar.gd` fusiona piel y botas en `cuerpo`; para ocultar las botas base hay que cargarlas como capa propia (el manifiesto sí las lista como máscara).

## f) Las 12 comprobaciones del validador

`Godot --headless --script herramientas/arte/validar_hoja.gd -- <hoja.png> --celda=32 [--modo=indice|libre] [--base=<caminata.png>] [--json=ruta]`. Salida 0 = sin errores (puede haber avisos), 1 = errores, 2 = argumentos inválidos. No modifica la entrada.

| # | Comprobación | Si falla |
|---|---|---|
| 1 | archivo legible | error |
| 2 | tamaño exacto 4·celda × 4·celda | error (se omite el resto) |
| 3 | alfa solo 0/255 | error |
| 4 | solo colores índice (modo `indice`) | error |
| 5 | las 16 celdas tienen contenido | error |
| 6 | contenido a ≥1 px del borde de cada celda | error |
| 7 | las 4 columnas de cada fila no son idénticas | **aviso** «pose repetida» |
| 8 | contenido de cada celda dentro de la silueta de la base ±3 px (con `--base`) | error (detecta desplazamientos) |
| 9 | la base tiene el mismo tamaño que la hoja | error |
| 10 | número de colores opacos | informativo |
| 11 | se usa el rojo principal (modo `indice`) | aviso |
| 12 | ninguna celda con más del 90 % opaco (fondo relleno) | aviso |

**Aceptación**: 0 errores y revisión de los avisos; después, prueba de recoloreado en el mapa (no automatizada). Probado solo con hojas sintéticas (`herramientas/arte/test_validador.gd`, 13 casos, pasan).

**Ejemplo real** (modo `libre`, `overlays_ajustados/casco_atlas_128x128.png` con `--base=personaje/caminata.png`): 0 errores, 1 aviso, salida 0. Aviso: «pose repetida en las filas [0, 1, 2, 3]»; el resto OK (266 colores opacos distintos, silueta dentro de la base ±3 px). En modo `indice` falla la comprobación 4 (266 colores fuera de índice), como se espera: esa hoja es un candidato estático, no una hoja de este contrato.

## g) Lo que no cubre y decisiones abiertas

**No cubre**: animación de ataque con arma (sincronía de espada con `ataque.png`), acabado final, paleta global compartida (Fase 2), iconos 16×16 de ranura, piedras y joya, calidad artística (el validador mide formato, no estilo).

**Decisiones abiertas** (la 1 y la 2 bloquean el lote 1):
1. Tamaño final de celda (32/48 provisionales).
2. Lateralidad de perfiles (constante `INVERTIR_PERFILES`).
3. Escudo y espada: ¿una hoja por arquetipo o únicas?
4. Gris índice exacto y si hace falta un quinto índice (contorno).
5. Qué base se oculta con `torso` (`cinturon`) y cómo se trata el pelo bajo el casco.
6. `guantes`: una sola hoja para ambas manos; orden de la mano lejana en perfiles.
7. Renombrar `coraza` → `torso` en el cargador y dónde se aplica la paleta (shader o recoloreado al cargar).
8. Tolerancia de silueta ±3 px y la regla de 1 px de margen: valores propios, sin base en ningún documento.
