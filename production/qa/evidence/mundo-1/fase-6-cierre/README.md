# Cierre funcional aprobado de Fase 6 — 26/10/2026

Rama `codex/fase6-economia-regional`; commits `e15bfda` (enseñanza) y `ab86408` (crecimiento/fundación). Conserva todo el avance anterior.

| Comprobación puntual | Resultado |
|---|---|
| Aprendizaje regional: maestro real, tiempo, no concesión por stock/oficio, persistencia y migración del conocimiento | 8/8 |
| Expansión: viviendas pagadas, camas físicas, cultivos, NPC migrantes, presión renovable, no fundar sin crisis, ventaja territorial, ruta, interrupción y reinicio, conservación exacta de cada recurso, llegada idempotente y réplica | 24/24 |
| Crisis/abandono/recuperación afectadas | 15/15 |
| Tránsitos, reservas, trueque y retorno afectados | 21/21 |
| Contabilidad e integración regional afectadas | 19/19 |
| Respuestas locales, migración e integración afectadas | 17/17 |
| **Total** | **104/104** |

No se ejecutaron suites históricas, auditorías generales o simulaciones extensas. Las comprobaciones se hicieron durante la integración: respuestas/crisis/tránsito/aprendizaje preceden los últimos ajustes aislados a la expansión y al botín alimentario; economía y expansión se verificaron después de esos ajustes. Expansión compara la continuación con/sin reinicio desde un trayecto interrumpido y exige igualdad del registro completo de Asentamientos.

Fixtures: los materiales iniciales se declaran como entradas del escenario; no son dotaciones del ejecutor. El terreno despejado y los pisos existentes impiden o habilitan alternativas de forma explícita sin alterar el relieve base ni conceder drops. Los cuatro fundadores/residentes proceden de los cuatro NPC iniciales de las dos comunidades: se construyen camas y se trasladan por rutas reales. Una amenaza creada con el constructor de Combate impide recuperar el otro sitio; sin esa condición, el selector elige recuperación antes de fundación. El test no fuerza fundar ignorando esa alternativa. No se clonan residentes para ampliar el origen.

Los avisos conocidos de certificados/recursos al cerrar persisten. La réplica se comprueba en proceso mediante el protocolo existente; no certifica dos clientes por sockets, Internet, rendimiento a escala ni frecuencia natural de fundaciones.

## Contraste con el Diseño Maestro

| Invariante de §9 | Implementación/evidencia |
|---|---|
| Balance material y causa | Cofres únicos, reservas de tránsito y costes exactos; test verifica origen + destino + construcción + consumo por cada ítem. Cultivos solo acreditan cosechas reales. |
| Identidad única | Los mismos diccionarios pasan de origen a operación a destino; IDs y saberes acompañan al residente. |
| Lugar/ocupación única | Solar pendiente pertenece solo a Tránsitos; al llegar se registra pueblo y edificio una vez. Recuperación conserva el ID y derechos originales. |
| Determinismo | Selecciones ordenadas, rutas persistidas y RNG existente; continuación tras reinicio produce exactamente el mismo registro. No se ejecutó una nueva matriz de órdenes de exploración. |
| Resumido limitado por capacidad/recursos | Presupuesto laboral compartido, maestro/alumno ocupados, recetas explícitas, infraestructura real, costes de piezas, camas y consumo vigentes; sin salida por población o tiempo abstracto. La equivalencia general detallado↔resumido continúa fuera del alcance 5b. |
| Límite técnico explícito | Falta de ruta/carga/comida/solar detiene la operación; no hay teletransporte, sustitución de materiales ni población de respaldo. |

Cierre de los sistemas funcionales aprobados, no una certificación de balance, equivalencia 5b o multijugador externo. Siguen explícitamente diferidos propiedad de terceros, fundación por oportunidad sin crisis y transición 5b. No quedan decisiones de diseño abiertas para este alcance.
