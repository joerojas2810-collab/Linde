# Revisión de hashes E04/E05 — 26/10/2026

## Causa comprobada

El manifiesto enumera 96 archivos: 84 PNG y 12 JSON. Los 84 PNG conservan sus hashes originales. En Windows, `core.autocrlf` convertía los 12 JSON a CRLF; al usar bytes exactos de Git, once coincidían inmediatamente con el manifiesto.

El restante, `E04_objetos.json`, fue ampliado en el commit de arte aprobado `44f6f09b644c5df95bf1c4f2fc497a5325fe4554`: conserva sin cambios sus **32 entradas anteriores** y añade **32** de minerales/pendientes_v1. El manifiesto todavía guardaba el SHA de su versión anterior. Se verificó que ese hash antiguo coincide con el blob anterior al commit; no se reemplazó un hash sin identificar la procedencia del cambio.

## Corrección

- `.gitattributes` fija LF para los JSON de `arte/mundo/` sujetos al manifiesto. Fija también LF para el mapa de iconos de interfaz, donde la revisión anterior comprobó el mismo problema de checkout.
- El manifiesto conserva los otros 95 hashes. Actualiza únicamente el SHA vigente de `E04_objetos.json` y registra el hash de origen, commit aprobado, entradas conservadas y añadidas en `adaptaciones`.
- La descripción de la prueba se refiere al manifiesto **vigente**, pues el catálogo ya no es una copia literal de la primera entrega. Se conserva exactamente la comparación SHA-256; no se elimina ni se relaja.
- No se modificaron PNG, entradas del catálogo, lógica de juego ni reglas.

## Verificación ejecutada

- Auditoría directa: **96/96** hashes vigentes coinciden.
- Comparación del catálogo anterior/actual: **32 entradas originales intactas y 32 añadidas**.
- Simulación de checkout Git con `core.autocrlf=true`: los **12 JSON** conservan sus hashes con las nuevas reglas LF.
- `tests/prueba.gd`: **330 PASS, 0 FAIL** (`general.txt`).
- `tests/prueba_integracion_visual_a.gd`: **60 PASS, 0 FAIL** (`visual.txt`).
- No se repitieron todas las demás suites de cuentas/mundo: esta revisión afecta únicamente atributos de texto, metadatos de integridad y la descripción de una prueba. Sus ejecuciones anteriores quedan registradas como históricas.

Los avisos conocidos de ObjectDB/recursos al cerrar siguen presentes; esta corrección no los aborda. No se hizo push ni merge a main. El cambio puede integrarse por separado de cuentas.
