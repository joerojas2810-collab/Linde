# Mundo 1 · Fase 0 — línea base de medición

> **Fecha**: 2026-10-26 · **Código medido**: `HEAD 2a093b0` (incluye la optimización de `_recurso`, `785c0c4`) · **Godot**: 4.7.1 stable · Sin cambios de producción: las herramientas solo leen el juego.
> Plan: [PLAN_MUNDO_1.md](../../../../../docs/investigacion/PLAN_MUNDO_1.md) §8 · Decisiones: `M1-F0` en [DECISIONES.md](../../../../../Linde/cenital/docs/DECISIONES.md).

## Cómo reproducir y comparar
```bash
Linde/cenital/tests/medir_todo.sh <carpeta>                      # ~4 min; configuraciones fijas
Linde/cenital/tests/medir_todo.sh --comparar <base> <nueva>      # ignora MEDIDA_CPU y la versión de Godot
```
Este directorio es la línea base (`<base>`). Antes y después de cada paso de la Fase 1: generar `<nueva>` y comparar.

| Herramienta | Qué mide | Configuración fija de la batería |
|---|---|---|
| `tests/medir_equivalencia.gd` | Hash del estado completo por día y resultados de NPC | semillas 123 y 456, 4 días, combate desactivado, `ignorar=` vacío |
| `tests/medir_inicio.gd` | Distancias del punto de inicio y visibilidad de habitantes | semillas 1–200; visibilidad en las 20 primeras |
| `tests/medir_ritmo.gd` | Ritmo de un «jugador de referencia» con la API real | semillas 123, 456, 7, 42, 99; límite 3.600 s |
| `tests/medir_comun.gd` | Utilidades compartidas | — |

Etiquetas de salida: `MEDIDA_CONFIG`, `MEDIDA_ESTADO` y `MEDIDA_HITO` son **deterministas** y se comparan; `MEDIDA_CPU` depende de la máquina y **nunca** se compara por igualdad. Para cambios que solo añaden datos (p. ej. el registro `mundo.poblados` de la Fase 1a): `medir_equivalencia ... ignorar=mundo.poblados`.

**Reproducibilidad comprobada**: la semilla 123 de `medir_ritmo` dio el mismo hash dos veces; `medir_equivalencia` (sin instrumentar) reproduce los hashes finales medidos antes con una versión instrumentada (`ac3f5636ea27630b` y `a7a314b6196c7736`); `--comparar` de la línea base consigo misma da «igual» en los 8 archivos.

## Resultados

### Aparición del jugador (`inicio.txt`, 200 semillas)
| Distancia (celdas) | mín. | p10 | mediana | p90 | máx. |
|---|---|---|---|---|---|
| a la puerta de la casa | 13,0 | 16,3 | 23,8 | 34,2 | 36,4 |
| a la cama de Maren | 15,5 | 17,9 | 25,5 | 32,0 | 34,9 |
| a la salida sur | 1,0 | 4,1 | 24,4 | 35,8 | 41,1 |
| al guardián | 14,0 | 14,9 | 18,2 | 27,1 | 56,4 |
| al punto de aparición de slime más cercano | 12,0 | 12,4 | 17,0 | 22,0 | 27,1 |
| al estanque | 2,0 | 3,0 | 11,4 | 22,0 | 43,9 |

139 posiciones distintas en 200 semillas. **En las 20 primeras semillas, ningún habitante estaba dentro del encuadre de la cámara (26,7×15 celdas) al comenzar**; el más cercano estaba a una mediana de 25,5 celdas (máx. 36,1).

### Ritmo del jugador de referencia (`ritmo-s*.txt`, 5 semillas)
Tiempos en segundos de juego (1 s = 1 minuto de juego). Es una **cota inferior** de lo que tarda una persona (sin combate, menús, lectura ni dudas; cada golpe 0,3 s; desplazamientos teletransportados con coste de la ruta más corta).
| Hito | mín. | mediana | máx. | Golpes acumulados |
|---|---|---|---|---|
| primera fibra | 0,3 s | 1,6 s | 2,5 s | 1 |
| hacha de piedra | 8,1 s | 10,1 s | 12,6 s | 17 |
| pico de piedra | 24,4 s | 25,6 s | 32,6 s | 37 |
| mesa | 27,8 s | 30,5 s | 36,0 s | 40 |
| horno | 33,7 s | 41,1 s | 48,1 s | 48 |
| nivel 2 | 36,3 s | 45,0 s | 50,8 s | 51 |
| nivel 3 = «artesano» (aprendido) | 115,5 s | 136,0 s | 143,4 s | 108–111 |
| primer lingote | 125,5 s | 145,2 s | 147,9 s | 108–111 |
| llegada a la salida del Valle | 140,2 s | 160,2 s | 162,2 s | — |
| 12 celdas fuera del Valle | 143,2 s | 163,2 s | 165,2 s | — |
| regreso a la casa | 153,2 s | 173,2 s | 175,2 s | — |

Con la política voraz, **toda la cadena inicial cabe en unos 2,5–3 minutos de partida** y se rompen 46–48 objetos.

### Recursos del Valle (`MEDIDA_ESTADO ... recurso_valle`, semillas 123 y 456)
| Recurso | Al comenzar | Al terminar (123 / 456 / 7 / 42 / 99) | Regenera |
|---|---|---|---|
| Árbol | 94 | 76 / 75 / 76 / 75 / 74 | no |
| Roca | 29 | 11 / 6 / 4 / 4 / 6 | no |
| Veta de mena | 3 | **0 en las cinco** | no |
| Arbusto | 50 | — | 24 h |

### Línea base de comportamiento (`equivalencia-s*-d4.txt`)
Hash por día y resultados de NPC para 4 días: habitantes 2→5; semilla 123 al día 4: 3 camas de huésped, 2 casas completas, 42 construcciones, 12 caminos. Hashes finales: `ac3f5636ea27630b` (123), `a7a314b6196c7736` (456). CPU registrada (no comparable): tick medio 2,4 ms (123) y 3,3 ms (456).

## Limitaciones
- El «jugador de referencia» no es una persona: ni combate, ni menús, ni dudas; las cifras de ritmo son un mínimo.
- La política voraz rompe todo lo que da experiencia, incluidas las 3 vetas; un jugador real podría no hacerlo.
- Sin red ni varios jugadores; `medir_inicio` supone que todos aparecen en la misma celda (así es hoy).
- La visibilidad ignora la oclusión por la casa y mide solo el momento de aparición (06:00).
- `medir_equivalencia` no cubre guardado/carga ni multijugador.
- Solo 4 días y 2 habitantes iniciales (5 al final): no se midió con 12 habitantes.
