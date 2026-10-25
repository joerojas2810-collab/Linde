# Inspección de estado y próximos pasos — 2026-10-25

Alcance: estado local de Linde, código, documentos y diez suites automatizadas. No se han corregido los hallazgos en esta inspección.

## Estado de entrega

HEAD `720f6e9`: minerales, recetas aprendidas, expediciones, caminos, campos y casas. La referencia local `origin/main` está en `4697591` (arte de fase 7); hay un commit local por delante. La corrección del orden de dibujo y su evidencia siguen sin commit. No se consultó el remoto por red en esta inspección.

Hay capacidades implementadas que el resumen histórico sigue llamando pendientes: autonomía principal, nuevas especies exteriores, minerales, aprendizaje acotado de recetas, expediciones al contorno y casas de plano fijo. AUTONOMIA.md y MUNDO_POR_REGIONES.md también conservan límites antiguos. El cierre original de 5 historias no describe el alcance completo actual.

## Verificación actual

| Suite | PASS | Fallos |
|---|---:|---:|
| Autonomía | 33 | 0 |
| Sociedad | 48 | 0 |
| Desarrollo | 55 | 0 |
| Protección | 51 | 0 |
| Terreno | 49 | 0 |
| Fauna | 31 | 0 |
| Caminos | 7 | 0 |
| Cultivos | 8 | 0 |
| Casas | 13 | 0 |
| Orden de dibujo | 6 | 0 |
| Total | 301 | 0 |

No se repitieron aquí la campaña histórica, interfaz, sesiones de red ni simulaciones largas. La suite de terreno actual desactiva expediciones: sus 49 PASS no demuestran el límite de caché del modo normal con NPC explorando. Persisten avisos de recursos al cerrar y de certificados del entorno headless.

## Hallazgos reproducidos fuera de las suites

1. **Compatibilidad de recursos del exterior.** `terreno_v1.gd:48–49` añade estaño sustituyendo algunas rocas sin cambiar la versión de generación (`mundo.gd:78`, `guardado.gd:27`). Con semilla 123, en `(56,-299)` el generador anterior daba roca y el nuevo da estaño. Se guardó una extracción `roca@56,-299`; al cargar sigue registrada, pero aparece `veta_estano@56,-299`. Los IDs incluyen el tipo, por lo que la extracción anterior no oculta el nuevo recurso. Antes de publicar: conservar el generador anterior para partidas existentes o implementar versión/migración explícitas. Añadir regresión con recursos ya extraídos y dañados en celdas afectadas.

2. **Una casa bloqueada puede no reanudarse.** `Sociedad._casa():1032` omite piezas que no caben y termina añadiendo la cama a `datos().casas` aunque `casa_completa()` sea falsa. Se reprodujo con el espacio de puerta ocupado por un cofre: completa=false, marcada_hecha=true. Tras retirar el cofre: vuelve_a_intentar=false y sigue incompleta. Requiere estados pendiente/bloqueada/completa y reintento; los tests actuales prueban un solar preparado, no este bloqueo.

3. **La vivienda no reserva el solar de la futura casa.** `_vivienda():969` usa `_construir_cerca()` para colocar una cama, sin validar el espacio del plano completo. DESARROLLO.md documenta que en una simulación previa de cinco días no se completaron casas por camas demasiado juntas; no se repitió esa simulación aquí. El siguiente incremento funcional debería reservar una parcela y accesos antes de construir la cama y permitir replanificar.

## Orden de desarrollo propuesto

1. Resolver compatibilidad de generación y el reintento de casas; incorporar ambas reproducciones a regresión.
2. Reservar parcelas de vivienda, corredores y áreas de taller/cultivo; comprobar casas completas en varias semillas, sin regalar materiales ni preparar solares.
3. Dar arte propio a las piezas nuevas: muro de ladrillo, puerta, techo y campo. Hoy usan empalizada, suelo de madera teñido y arbusto. Corregir aparte la máscara de copa del frutal. Las fases de luz tienen reparto coherente 2/12/2/8 minutos; el tono de alba y ocaso puede distinguirse sin tocar la duración.
4. Verificar expediciones y novedades en el modo normal: caché incluyendo NPC, cultivos/techos/caminos en servidor y dos clientes, guardado y reconexión, migración desde la versión anterior y rendimiento con más colonos. Después: playtest y balance de varias semillas.
5. Ampliar exploración con motivos y asentamientos regionales, una vez estable la vivienda. Hoy hay expediciones al contorno, no colonización lejana. Fauna fantástica sí; cría, depredación y combate de NPC no.

Recomendación: terminar la cadena solar → casa → residente → producción antes de añadir más criaturas o materiales. Mantener los 24 minutos del ciclo.
