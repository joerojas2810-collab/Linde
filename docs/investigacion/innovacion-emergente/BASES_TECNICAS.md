# Bases técnicas recomendadas

> **Vigencia (consolidación documental, 2026-10-25)**: investigación verificada contra el árbol de trabajo en `HEAD 990d549` el 25/10/2026 (alcance: inspección estática; ver [README](README.md)). **No describe necesariamente el código posterior**: el árbol tenía cambios sin confirmar de otras sesiones (`habitantes.gd`, `sociedad.gd`, `autonomia.gd`, `escena.gd`, `mundo_vivo.gd`, `arraigo.gd`). Si el código verificado la contradice, prevalece el código y hay que corregir este texto. Estado del juego: [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md). Registro de decisiones: [DECISIONES del proyecto](../../../Linde/cenital/docs/DECISIONES.md).

Todo este documento es **[P] Propuesta de diseño propia**, salvo párrafos marcados [C], [I] o [V]. No es un esquema implementado ni una promesa de compatibilidad automática. Evidencia de partida: [mapa local](COMPATIBILIDAD_LINDE.md) y [precedentes fijados](PRECEDENTES.md).

## Qué puede emerger

| Nivel | Ejemplo | Tratamiento propuesto |
|---|---|---|
| Descubrimiento personal | Un NPC aprende una receta que otro ya conoce. | Añadir conocimiento por actor; no declarar una primicia mundial. |
| Invención combinatoria | Primera espada de laminado hierro/fibra y técnica ligera. | Explorar gramática existente y confirmar el primer resultado; no generar código. |
| Mejora de ejecución | La práctica permite mayor calidad o menor necesidad de superficie. | Usar rangos existentes; la pieza anterior conserva su identidad y propiedades. |
| Técnica nueva dentro de reglas | Desbloquear un procedimiento registrado que modifica costes/tiempo con límites. | Catálogo de operadores permitido y versionado, con prerrequisitos; no acumulación ilimitada de multiplicadores. |
| Mecánica completamente nueva | Proponer electricidad cuando no existe simulación de energía. | Guardar como idea o petición de contenido; requiere desarrollo posterior. Nunca ejecutar una descripción como regla de juego. |

**[C]** Linde ya cubre los tres primeros niveles parcialmente mediante observación, práctica y prototipos. **[I]** El término «descubrimiento» en la memoria actual no prueba primicia mundial: `_creacion` no deduplica por diseño y se recorta.

## Separación de identidades y capacidades

Conservar `art1:` para objetos existentes y `mat1:` para materiales. Definir identidad de diseño mediante forma, material, técnica y versión; decidir expresamente si la calidad forma parte del diseño o del resultado. Recomendación: calidad pertenece al resultado, y una mejora de calidad no crea otra invención cultural. No cambiar por ello las claves actuales de inventario.

Mantener cuatro consultas distintas: diseño estructuralmente válido; conocido por el actor; ejecutable con su pericia/entorno; elegible para experimentar. Así abandonar un taller no borra el conocimiento, y leer un manual no concede maestría. Material conocido sigue significando exposición al material, sin convertirse automáticamente en conocimiento de todas las técnicas nuevas.

## Estado persistente mínimo

Extender el subestado de desarrollo existente mediante versión de esquema; nombres ilustrativos sujetos a revisión:

| Entidad | Campos esenciales | Invariante |
|---|---|---|
| Definición de diseño | ID canónico, versión de reglas, parámetros permitidos, prerrequisitos | Derivable y verificable por servidor; sin scripts del cliente. |
| Conocimiento por actor | ID de diseño/técnica, estado (indicio/en estudio/conocido), progreso entero, fuente, minuto | Separado de práctica y de tener físicamente el producto. |
| Investigación activa | Actor, candidato, entradas reservadas, estación, progreso, próximo paso, ID de operación | Máximo acotado por actor; reanudable tras guardar/cargar. |
| Registro mundial de descubrimientos | Diseño, primer evento confirmado, autores, eventos independientes posteriores | No depende de una memoria recortable; orden total del servidor. |
| Transmisión | Diseño, emisor/fuente, receptor, modo, instante y evento origen | No concede inventario ni repite recompensa por reenvío. |
| Soporte escrito, fase posterior | ID de copia/lote, diseños contenidos, autor del texto, procedencia y ubicación | Distinguir autor del diseño, escritor, copista, docente y fabricante. |

Usar IDs de actores ya existentes (`npc:` y `pj:`), no nombres visibles. Preservar referencias de autores ausentes mediante identidades históricas mínimas. No agregar UUID por cada pieza si basta autoría por diseño. Si se quiere firma por ejemplar, evaluar primero ampliar el inventario de cantidades con instancias/lotes; sería un cambio de alcance importante.

**[C]** El inventario actual agrupa por clave y `creaciones` tiene solo 64 entradas. **[I]** Registrar autor en la clave compartida mezclaría identidad funcional con procedencia y multiplicaría entradas de inventario. Conviene separar ambas.

## Experimento autoritativo y determinista

1. Integrar la intención en `sociedad.decidir`/`desarrollo.decidir`: hambre, descanso y obligaciones continúan antes de investigar. Al jugador ofrecer un candidato y coste visibles.
2. Generar candidatos compatibles a partir de materiales conocidos y necesidades reales. Puntuar beneficio esperado respecto al equipo disponible, demanda del grupo, coste, novedad personal y especialidad. No dar a todos la misma primera combinación por orden alfabético.
3. Ordenar candidatos e IDs antes de resolver empates. Asignar presupuesto máximo de candidatos evaluados por decisión; conservar cursor para no bloquear ni favorecer siempre al mismo NPC.
4. Validar requisitos, rutas, estación, excedentes, capacidad y exclusiones antes de reservar/consumir. Una reserva debe tener dueño, plazo y reglas de cancelación; no descontar otra vez al completar.
5. Acumular progreso en unidades enteras por trabajo confirmado. En primera versión usar umbral determinista. Si se añade fracaso, usar flujo separado por actor/proyecto/intento y persistir resultado/estado; nunca repetir tirada al cargar o reintentar un pedido.
6. Confirmar una única transacción: gasto, producto o residuo explícito, desgaste, progreso y descubrimiento. Registrar autoría solo tras resultado válido. Un rechazo no entrena ni consume.
7. Guardar el resultado durable y luego emitir recuerdos/noticias resumidos. Un mensaje perdido no puede cambiar la verdad del mundo.

La práctica actual da un punto por acción, con tope. No trasladar directamente tiempos y probabilidades de CDDA. Para investigación larga, el progreso puede ser temporal, pero debe permanecer separado del contador de práctica existente hasta evaluar balance y migración.

**[I]** El límite actual de decisiones por minuto distribuye trabajo, pero no garantiza justicia si una lista estable siempre agota el presupuesto antes de llegar a los últimos. **[V]** Medir hambre de planificación con población grande antes de decidir cursor rotativo o prioridades envejecidas.

## Enseñar, copiar y difundir

Comenzar por enseñanza directa: encuentro, tiempo disponible, emisor que conoce, receptor con prerrequisitos y coste de oportunidad. Transferir conocimiento de diseño o técnica, no copiar la práctica del maestro. La práctica conjunta puede acelerar aprendizaje con techo; el bonus 2 observado en CDDA es un precedente, no un valor adoptado.

Reutilizar proximidad y contactos de autonomía/sociedad como oportunidades, sin hacer que cada cruce comparta todos los planos. Presupuesto por encuentro, lista pendiente y bloqueo temporal por pareja/diseño; limitar emisiones duplicadas. La confianza y acuerdos pueden modular voluntad de enseñar. Añadir libros y talleres docentes solo después de resolver identidad de soportes y permisos.

Distinguir noticia («alguien logró esta técnica»), indicio («se usa fibra como refuerzo»), receta ejecutable y dominio práctico. Una compra puede revelar material sin revelar procedimiento. Definir por contenido qué se puede deducir examinando/desmontando; no extraer instantáneamente toda técnica de cualquier objeto.

## Autoría y pérdida

El servidor asigna secuencia de evento y ordena confirmaciones. Primer descubridor mundial y primer aprendizaje local son hechos distintos; dos descubrimientos independientes conservan ambos eventos. La coautoría solo existe si hubo participantes registrados, no por estar cerca o por un nombre escrito por el cliente.

La pérdida operativa ocurre cuando no hay portadores activos capaces ni soportes legibles accesibles. El registro histórico no concede recetas: recordar que una técnica existió no permite fabricarla. Destruir un libro no borra conocimientos ya aprendidos; muerte/partida de un NPC puede retirar un portador sin borrar su autoría. Un jugador desconectado no debería perder conocimiento por defecto. El olvido gradual es opcional, pospuesto hasta definir interacción con `restaurar` y exposición a objetos.

Para evitar extinción que bloquee el juego: técnicas básicas recuperables por experimentos baratos, copias dispersas y rutas alternativas; técnicas raras pueden perder accesibilidad. Registrar pérdida de acceso local, no eliminar una definición usada por objetos guardados. Distinguir inaccesible, conocido históricamente y eliminado del contenido.

## Profesiones emergentes

Derivar especialidades de práctica por material/disciplina, técnicas dominadas, obras y demanda. Ejemplo: artesano con práctica en hierro y técnicas de protección adquiere reconocimiento como armero; eso no reemplaza su perfil de abastecimiento. Usar umbrales con permanencia/histéresis para no cambiar título cada minuto. Acceso a aprendices y encargos puede depender de reputación comprobable, sin bonificar repetidamente por fabricar el mismo objeto.

**[C]** Ya existen práctica por material y oficios con reservas/productos. **[P]** Extenderlos, no introducir clases profesionales exclusivas que invaliden sus recetas.

## Rendimiento, balance y red

- Acotar gramática, profundidad, efectos activos y experimentos simultáneos. No generar todas las combinaciones para cada NPC en cada tick. Índices material→diseños, técnica→prerrequisitos y actor→proyectos; invalidar caché por cambio de reglas/conocimiento/rango/entorno.
- El cálculo de superficie recorre construcciones actualmente. Mantener un índice local o caché por taller solo si mediciones muestran coste relevante. No adoptar un framework de grafos para unos pocos prerrequisitos.
- Presupuestar intentos por minuto simulado y por actor; investigar consume excedentes, estación y tiempo. Ningún ensayo debe crear recursos de la nada o permitir ciclos de costes negativos. Balancear suma de efectos, evitar crecimiento exponencial de bonus.
- Conservar RPC de intenciones; validar autor, alcance, estación, conocimiento, versión e inventario en servidor al confirmar, no solo al abrir UI. No aceptar autoría, propiedades o éxito calculados por clientes.
- La secuencia actual rechaza repetición durante conexión. Para experimentos largos o reconexión, usar ID de operación durable y registro de resultado para idempotencia. Dos actores que compiten por un soporte o estación deben resolverse en orden estable y con reservas.
- Proyección por cliente: conocimiento privado, noticias públicas y autoría publicada tienen permisos distintos. `mundo_vivo` completo no debe transportar secretos. Cambios pequeños de progreso no justifican replicar el estado cultural entero; agrupar y enviar deltas por revisión.
- Presupuesto provisional de aceptación: comparar p95 del tick, bytes/s, tamaño de guardado y tiempo de carga antes/después en misma máquina, semilla y población; definir valores finales con medición. No se ha demostrado un máximo de NPC soportado.

**[C]** El servidor declara 15 clientes ENet, 40 pedidos/s por conexión y 48 caracteres por texto; compara JSON por sección. **[I]** IDs nuevos demasiado largos serán rechazados; aumentar límites sin evaluar carga tampoco es solución. El formato propuesto debe entrar en protocolo versionado y límites explícitos.

## Evolución sin romper partidas

1. Congelar reglas v1 que interpretan `art1:`/`mat1:`. Leer versiones antiguas siempre; cambios semánticos deben usar otra versión o definición congelada. Un prefijo versionado no protege si se edita su JSON detrás.
2. Migrar estado de desarrollo: conservar materiales/práctica; marcar como legado los diseños ya habilitados según una política explícita. No inventar autores para piezas antiguas ni inferir al primero desde el historial recortado.
3. Introducir registro de autoría y enseñanza opcionales en un subesquema nuevo. No subir `guardado.FORMATO` sin evaluar si basta la versión de desarrollo; la validación debe rechazar versiones no soportadas de ese subestado.
4. Probar cargar, guardar y volver a cargar sin duplicar progreso, objetos ni eventos; conservar claves desconocidas con el comportamiento actual y diagnóstico.
5. Evitar migración dependiente del taller actual si se quiere preservar conocimiento permanente: la superficie al cargar no describe lo aprendido históricamente.

**[V]** Requieren decisión de producto: si los planos iniciales siguen siendo automáticos, si calidad define invención, qué secretos existen, coautoría, muerte permanente, recuperación de técnicas y alcance de soportes escritos. Las recomendaciones permiten una primera fase sin resolver libros individuales ni olvido.
