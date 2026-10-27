# Activación territorial v3 — propuesta B aprobada (26/10/2026)

El usuario aprobó B, incluido aplazar si no existe ubicación compatible. Rama feature/fase7-ecologia, sin merge/push. Mundos nuevos poblados usan v3; existentes v1/v2 no se migran. Las herramientas de referencia solicitan explícitamente v2 o v1, sin cambiar sus resultados esperados.

## Implementación

- Política declarativa habitats_v3.json copiada al crear el mundo. Conserva preferencias A; rutas registradas, área de pueblos y núcleo de 12 celdas como exclusión de nacimiento para hostiles/territoriales. No añade radio al camino. Peligro hostil ligado a ruina/cueva compatible de la misma región, sin añadir población/especies.
- Fauna registra una vez las decisiones por macrorregión del registro de Lugares, después de completar la génesis inicial y sus comunidades. Mantiene 36 entradas por macro, incluidas ausencias. d.fauna.territorios almacena solo planes, ID de ancla y estado pospuesto; no duplica terreno/rutas/edificios ni crea un sistema de biomas paralelo.
- plan_region v3 solo lee esos resultados. Una consulta de territorio desconocido devuelve vacío; no genera lugares/población. El registro posterior invalida las cachés vacías. Guardar/cargar conserva exactamente los planes, incluso frente a obras posteriores. La expansión tras registro de Lugares se congela en autoridad antes de materializar o guardar.
- La planificación inicial se retrasa hasta completar pueblos preexistentes. La expansión inversa en macrorregiones nuevas, incluidas negativas, se verificó con el mismo mundo/acciones; no depende del orden de descubrimiento sin cambios causales intermedios.
- Un punto sin alternativa compatible conserva ID/cantidad nominal y queda pospuesto en el guardado. No se materializa ni consume cupo activo. No hay reubicación automática ni recuperación nueva: permanece pendiente hasta una futura regla/evento explícito, aún no implementado.
- Anclas reales quedan en el plan persistente y en la entidad activa; no se envían fuentes ocultas adicionales al cliente. Heridas/bajas siguen en el sistema existente. La persecución puede entrar en los pueblos: no se cambia combate, daño ni visión, ni se crea inmunidad.
- Esquemas o territorios incompletos se rechazan al cargar; no se repara resembrando. Las versiones v1/v2 conservan su lector anterior. La huella global y sus excepciones no cambian: política y decisiones de generación pertenecen al snapshot de cada mundo, protegido por el guardado actual. Builds anteriores no se consideran compatibles para abrir v3.

## Validación final ejecutada

Cuatro suites en carpeta nueva de evidencia, sin reutilizar resúmenes fallidos:
- territorios v3: 18/18. Exactamente las posiciones/anclas B de tres semillas; consulta pura, persistencia, obras posteriores, expansión inversa, caché negativa, v2 sin migración, aplazamiento real/materialización y rechazo de registros incompletos.
- distribución v2: 17/17, creación explícita v2 y progreso persistente.
- hábitats/v1: 23/23, incluidos hashes congelados de 5.046 regiones y guardado previo.
- amenazas: 12/12, aparición/núcleo e invasión por persecución vigentes.

Integración real de cuentas, dos servidores y clientes locales: 13/13, incluida reconexión y recuperación del personaje; ambos mundos guardan política v3 y tres territorios (servidores.json). No otra PC física ni Internet. La prueba no es un playtest humano de R/T ni una medición de rendimiento/carga.

### Incidencia corregida y trazabilidad

El primer arranque rechazó la política porque JSON representaba 3 como float y la pertenencia a una lista de enteros devolvía falso. Se valida primero tipo/integridad numérica y después la versión entera. También se evita arrancar/anunciar un servidor con Juego nulo. Extracto del fallo inicial conservado; las ejecuciones fallidas completas permanecen en la carpeta externa de QA. Los avisos ObjectDB/recursos al cerrar siguen siendo los conocidos.

La revisión automática rechazó consolidar manualmente un resumen con el resultado directo de una prueba corregida. No se efectuó esa modificación: se conservaron los resultados anteriores y se ejecutaron las cuatro suites en verificacion_final, cuyos logs/resultados son los incluidos aquí. La red final también se repitió en carpeta independiente; no se declara superado su primer intento fallido.

## Límites y siguiente bloque

Se conserva cantidad nominal; el aplazamiento puede reducir presencia local según la aprobación B. No se han implementado reproducción, migración, simulación ecológica global, economía, daño a NPC/edificios, viabilidad o nuevas fuentes de población. No se cambian estadísticas ni 720 minutos de reaparición. No se fijaron R/T ni se corrigió navegación/P2.

Siguiente: señales causales de criaturas reales/estado de fuentes, con conocimiento personal y sin revelar amenazas ocultas, aprovechando estas anclas persistentes. Fase 7 no está cerrada.
