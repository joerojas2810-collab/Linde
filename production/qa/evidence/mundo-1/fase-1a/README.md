# Mundo 1 · Línea base con el paso 1a aplicado (hashes completos)

> **Fecha**: 2026-10-26 · **Código medido**: `HEAD 58e142a` (incluye `2ac3f67`, el registro `mundo.poblados`) · **Godot**: 4.7.1 stable · **Sin `ignorar`**: los hashes cuentan el estado completo, incluido `mundo.poblados`.
> Sirve de referencia para el paso 1b (refactorización sin cambios de comportamiento): tras cada cambio, `Linde/cenital/tests/medir_todo.sh --comparar production/qa/evidence/mundo-1/fase-1a <nueva>` debe dar «igual» en los 8 archivos.

Generada con `Linde/cenital/tests/medir_todo.sh production/qa/evidence/mundo-1/fase-1a` (misma batería y configuraciones que la [Fase 0](../fase-0/README.md)).

| Resultado | Valor |
|---|---|
| Hash final, semilla 123, 4 días | `432f2d0da74c81a6` |
| Hash final, semilla 456, 4 días | `71c9f9a446c32c80` |
| Habitantes finales | 5 y 5 |
| CPU (no comparable por igualdad): tick medio | 2,36 ms (123) y 3,31 ms (456) |

Los hashes difieren de los de la Fase 0 (`ac3f5636ea27630b`, `a7a314b6196c7736`) únicamente por la clave `mundo.poblados`; con `ignorar=mundo.poblados` coinciden (comprobado el 26/10 al cerrar 1a). Los demás archivos (`inicio`, `ritmo-s*`) se comparan igual que en la Fase 0; los de `ritmo` incluyen además las líneas de recursos iniciales del Valle.
