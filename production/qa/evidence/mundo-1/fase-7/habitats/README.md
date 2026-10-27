# Fase 7 — primer bloque compatible de hábitats (26/10/2026)

Base: main eb022a4, rama feature/fase7-ecologia. No se publica ni fusiona con main. Diseño maestro e informe del usuario copiados sin modificar a docs/investigacion; sus propuestas no se consideran aprobación de balance.

## Revisión focalizada

- Fauna.plan_region utiliza hash independiente (0xFA017), hasta 64 candidatos, un punto por región de 16, ID fauna_v1@x,y; elige PASTO vacío y prioriza vecino cardinal de agua como ribera. No hay pesos regionales ni señales ecológicas persistentes nuevas.
- Fauna.actualizar materializa solo en autoridad, desde regiones ya cargadas, cada segundo y con máximo 24. Guardado de bajas/heridos existente; baja hasta min + 720. La regla de retorno al origen de los sanos y aplazamiento por construcciones permanecen iguales.
- Mundo.configurar conserva generador/semilla; registro de lugares/pueblos/caminos existente. No se usa habitat.gd social (solares de viviendas) como un sistema de biomas.
- Combate conserva conductas, línea de visión, aviso y retorno directo con límite 144 px. No se añadió daño a NPC/edificios ni se fingen ataques a pueblos. No se midió P2: corresponde al bloque de navegación; R/T siguen sin decidir.
- Guardado sella datos/fauna/reglas_v1.json y catálogo mediante Huella. Modificar ese JSON ahora rechazaría mundos anteriores; se conserva byte a byte. No se añadieron excepciones de carga ni se eludió la huella.
- Réplica no es autoridad: representa instantáneas. No se amplía lo que conoce el mapa personal ni se presentan hábitats potenciales como amenazas reales.
- Main ya incorpora el primer bloque individual de Fase 6; se respeta sin agregar contratos económicos/ecología ni seguridad/viabilidad provisional.

## Implementado

Normalización y validación de perfiles declarativos en Fauna a partir del bloque biomas existente. La cadena v1 es sintaxis abreviada; la forma explícita declara tipo, suelo=pasto, sin_objeto=true y agua_vecina (requerida en ribera por defecto). Conducta se consulta desde el catálogo, sin duplicar estadísticas. Se rechazan campos desconocidos, especies/biomas inexistentes, sustratos nuevos y ponderaciones no soportadas. habitat_en consulta únicamente compatibilidad del terreno base; no es prueba de presencia de una criatura ni una señal pública. plan_region consume esa consulta manteniendo sus IDs, hash, orden y caché.

Se habilita la arquitectura declarativa equivalente; **no se activa una redistribución territorial nueva**. Antes de cambiar concentraciones, distancias a caminos o lugares, se necesita aprobación humana según el maestro y M1-D14. No se escribe otra población, registro o geometría de mundo.

## Verificación ejecutada

- Antes del cambio: fauna 31/31, terreno 49/49.
- Nueva suite: hábitats 23/23. Orden inverso y nueva instancia, perfiles compatibles y consultas sin mutar estado/cargar regiones; 3 semillas x 2 generadores x 841 regiones (5.046 combinaciones únicas).
- Firmas de planes (ID, celda, especie, bioma), muestras de terreno, estado completo inicial y huella de reglas idénticos a la línea base. Ninguna variación de cantidades o especies en las muestras.
- Guardado de prueba creado antes del cambio, cargado sin excepción de reglas; conserva 7 maderas, 31 XP y una baja vigente. Nuevo guardado con sello limpio. Fixture enteramente ficticio, sin credenciales ni cuentas reales.
- Después: fauna 31/31 (heridas, bajas, ida/vuelta, recompensas, techo y autoridad/réplica) y terreno_red 1/1 con servidor y dos clientes reales localhost. No otra PC ni Internet.
- Tiempos de una única pasada en base/después: orientativos, no benchmark de frames ni rendimiento de fauna lejana. Persisten avisos conocidos ObjectDB/recursos al salir.

La primera versión de la comparación nueva fallaba al comparar diccionarios con enteros contra números float leídos de JSON. Se corrigió el test usando el canon numérico de Huella; la comparación externa independiente confirmó que los datos no habían cambiado. No se retocaron valores esperados.

## Distribución conservada

| Semilla | Generador | Ocupadas | Porcentaje | Especies |
|---|---|---|---|---|
| 123 | 1 | 749/841 | 89.06 % | arpia_pradera: 229, diablillo_secano: 63, espectro_bosque: 192, golem_sierra: 212, slime_ribera: 53 |
| 123 | 2 | 749/841 | 89.06 % | arpia_pradera: 229, diablillo_secano: 63, espectro_bosque: 192, golem_sierra: 212, slime_ribera: 53 |
| 456 | 1 | 767/841 | 91.20 % | arpia_pradera: 297, diablillo_secano: 73, espectro_bosque: 192, golem_sierra: 175, slime_ribera: 30 |
| 456 | 2 | 767/841 | 91.20 % | arpia_pradera: 297, diablillo_secano: 73, espectro_bosque: 192, golem_sierra: 175, slime_ribera: 30 |
| 789 | 1 | 755/841 | 89.77 % | arpia_pradera: 231, diablillo_secano: 84, espectro_bosque: 217, golem_sierra: 177, slime_ribera: 46 |
| 789 | 2 | 755/841 | 89.77 % | arpia_pradera: 231, diablillo_secano: 84, espectro_bosque: 217, golem_sierra: 177, slime_ribera: 46 |

90,01 % de regiones ocupadas en esta muestra combinada. El 85 % del diseño era una medición histórica en otra muestra, no un objetivo ni una densidad nueva. Ambos generadores coinciden aquí en los planes exteriores; se verifican por separado. Las exclusiones de caminos/objetos/agua/franja del Valle siguen siendo las vigentes. No se garantiza todavía calma junto a otros pueblos o caminos.

## Pendiente / siguiente bloque

Cerrar y aprobar las reglas de distribución territorial no uniforme: relación con caminos, poblados y lugares persistentes, sin densidades/radios/pesos inventados. Luego señales causales conocidas por cada jugador y navegación/P2, con pruebas específicas. No se declaran completados esos pasos ni la Fase 7.

No se encontró LINDE_Fase_7_investigacion_ecologia.md en el repositorio ni junto a los dos adjuntos; se pidió su ubicación y queda pendiente de lectura antes de decisiones territoriales nuevas. Las consultas externas citadas por Arena son referencias del documento; no se realizó investigación adicional.

Reproducir: Godot --headless --path Linde/cenital --script res://tests/prueba_habitats.gd. Medición: res://tests/medir_habitats.gd -- --salida=RUTA_ABSOLUTA.json. Las suites históricas con /tmp se ejecutaron mediante el adaptador Windows existente, sin editar sus pruebas originales.

## Complemento localizado y contrastado (26/10/2026)

El usuario indicó nuevamente la carpeta y el archivo ya estaba disponible. Investigación completa leída y versionada en `docs/investigacion/LINDE_Fase_7_investigacion_ecologia.md`; supera la nota histórica de archivo pendiente del apartado anterior. No se ejecutó nueva investigación externa ni se importaron algoritmos/dependencias.

La investigación §5.3 llama imprescindibles a reproducción, dispersión y depredación, y recomienda el modelo de stock regional B. Prevalecen el diseño maestro (§§2, 5, 10 y 11) y la solicitud explícita del usuario: esas propuestas quedan aplazadas; no son requisitos del bloque inicial. Son aprovechables la elegibilidad por terreno/hábitat antes de materialización, la autoridad, la separación de generación/carga y las señales originadas en fuentes reales. La base implementada es compatible con esos principios, sin introducir stock o presión global.

El documento usa el estado histórico de Fase 6 y cifras de fauna/atascos reportadas: no sustituyen la medición de esta rama ni prueban capacidades nuevas del juego. No cambian densidades, reaparición de 720 minutos ni daño/estadísticas. Siguiente decisión sigue siendo la distribución territorial, que requiere propuesta y aprobación antes de activarse. Este complemento solo modifica documentación; no se repitieron pruebas de código.
