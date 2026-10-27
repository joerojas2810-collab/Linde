# Fase 6 — respuestas, viajes y presión, 26/10/2026

Godot 4.7.1, semillas 123/456, rama `codex/fase6-economia-regional`.

| Prueba puntual | Resultado | Alcance |
|---|---|---|
| `prueba_transitos.gd` | 21/21 | Ruta real contigua/determinista, reservas de ambos lotes, ID idempotente, capacidad, viaje con NPC real, llegada/retorno, no acreditar antes de llegar, cancelación antes y durante, consumo esperando, reinicio en tránsito, conservación global de bienes + comida consumida, réplica sin simulación cliente |
| `prueba_respuestas_fase6.gd` | 17/17 | Receta explícita sin regalo de conocimiento, coste local, presupuesto de trabajo, no crear colonos por tiempo, migración dirigida/cama/ID, capacidad perdida antes de llegar, no cobrar consumo ni trabajo anteriores, destino abandonado no se reactiva, trueque autónomo ante carencia y cobertura sin stock ficticio |
| `prueba_reparacion_presion_f6.gd` | 12/12 | Reparación real propia con coste existente, vía del jugador/protección de dueño, mismo minuto sin cobrar dos veces, presión factual persistente y desaparición al cubrirse y sin producción retroactiva al reparar |
| `prueba_economia_regional.gd` | 19/19 | Integración del ejecutor regional afectado por cursor alimentario por residente y respuesta local; resto de sistemas anteriores preservados |

Total: 69 comprobaciones, sin fallos. Registros adjuntos. Para repetir, usar el ejecutable del proyecto con `--headless --path Linde/cenital --log-file /tmp/linde-f6-engine.log --script tests/<prueba>.gd`.

Sin suites históricas completas, simulaciones prolongadas, Internet o sockets. Los fixtures introducen entradas explícitas (stock/receta) y liberan una plaza para probar migración; no conceden esa población/materiales al juego. JSON de metadatos se normaliza al comparar int/float equivalentes. Se conservaron los avisos conocidos de certificados y recursos al cerrar.

No se probaron fundación/abandono/recuperación autónomos: siguen pendientes las políticas solicitadas al usuario. El código no simula esas decisiones ni las declara implementadas.
