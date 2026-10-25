# Contrato de intercambio y recepción

1. Ambos leen la misma base y comparan BASE_SHA256.json con su proyecto antes de editar. Si cambia, registrar diferencias; nunca copiar la instantánea completa encima del proyecto vivo.
2. IA1 propone en `salida/contratos/LOTE_ID.json` los IDs y especificaciones. IA2 responde compatibilidad en su propia salida; cualquier cambio de mecánica/estilo sin decisión vuelve al usuario. Contrato antes de generar arte faltante.
3. IA1 entrega lotes inmutables `salida/lotes/LOTE_ID/`, con manifiesto, PNG nativos, fuente/prompts, licencia/procedencia, galería de composición, resultados y lista de pendientes. Estados: candidato, validado_estructura, revisado_visual, aceptado_usuario. No confundirlos.
4. IA2 registra recepción por ID/hash, integra en una copia/checkout del proyecto actual, y produce parche/archivos tocados, logs y evidencia. No cambia PNG aceptados silenciosamente: devuelve defecto e ID a IA1. IA1 no modifica scripts productivos. Un único dueño del registro y manifiestos productivos: IA2.
5. Congelar hash antes de entrega. Una revisión crea versión nueva, con relación al lote anterior. No retirar un pendiente sin reemplazo visible validado.

Cada recurso del manifiesto incluye: id, tipo, archivo, sha256, origen, autor/herramienta, licencia y restricciones, referencia, estado, pendientes. Para atlas además lienzo, celda, filas/direcciones, columnas/poses, pivote y bbox, orden de capas y secuencia de cuadros. Para terreno: vecinos/conectividad y tamaño de dibujo. Para UI: márgenes nueve regiones, tamaños mínimo/máximo. Para animación: duración de presentación y correspondencia con estado existente (sin alterar duración mecánica). Registrar paleta/índices, alfa y filtro; distinguir escala de archivo, silueta, colisión y zoom.

Validar dimensiones, alfa, índices/colores por tipo, integridad de celdas, pivotes, continuidad y ausencia de recortes. Revisar además en contacto a zoom real: cuatro direcciones, animación, equipo completo, mano lejana, oclusiones y local/remoto. El validador genérico no certifica calidad ni acepta automáticamente huecos de ataque. Adjuntar política de pendientes explícita.

Informe final obligatorio: hecho/pendiente con IDs, archivos modificados, comandos exactos y salida, capturas, decisiones, limitaciones y siguiente acción concreta. Nunca marcar un lote cerrado por tener todos los nombres de archivo.
