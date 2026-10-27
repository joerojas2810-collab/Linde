# Distribución v2 aprobada y activada — 26/10/2026

El usuario aprobó expresamente las preferencias de la comparativa A. Se activan solo al crear mundos nuevos en modo poblado. Rama feature/fase7-ecologia, sin merge ni push.

## Activación y compatibilidad

- datos/fauna/habitats_v2.json contiene los criterios aprobados: vecinos de vegetación/roca, claros cardinales y orilla conservada. Misma cantidad, especie, bioma, región e ID; sin candidato adecuado se conserva la ubicación inicial.
- Juego.nueva fija d.fauna.distribucion antes de arrancar: versión y copia completa de preferencias. Es política de generación del mundo, como semilla/versión del terreno, no una modificación de estadísticas de combate. Juego.nueva(..., modo_poblado, 1) permite construir la línea base congelada en herramientas; el flujo normal usa v2. Modo legado no cambia.
- Un guardado sin distribucion usa v1, incluso en regiones no visitadas. Cargar nunca añade ni sustituye esa política. Mantiene puntos, bajas, heridas y progreso. No hay conversión automática.
- Fauna copia la política desde el mundo y reutiliza el mismo generador/candidatos, prefiriendo ubicaciones dentro de su región. El evaluador de preferencias es compartido con el comparador; no quedan dos algoritmos.
- El snapshot pertenece al guardado versionado y protegido por checksum. Cambiar defaults del archivo no modifica mundos guardados. Se rechazan versiones/esquemas desconocidos con mensaje explícito, sin degradación silenciosa a v1. No abrir mundos v2 con builds antiguos que no conozcan esta política; compatibilidad verificada es hacia adelante.
- No se modifica Huella, su excepción, ni el JSON de reglas de combate sellado. La política de generación se conserva en el mundo, no se trata como una regla global mutable. El cliente no genera fauna ni necesita recibir todos los posibles puntos; consume la instantánea autoritativa existente.

## Pruebas ejecutadas

- prueba_distribucion_fauna: 17/17. Activación nueva, legado intacto, guardado previo, cantidades y movimientos exactos en tres semillas, las cuatro posiciones de ejemplo aprobadas, orden inverso/reinicio, snapshot independiente de defaults, rechazo de política desconocida, materialización bajo techo, heridas y bajas v2.
- prueba_habitats: 23/23. Se conserva la referencia v1 de 5.046 regiones y la huella de reglas anterior. El constructor de la medición especifica v1 de forma explícita; no se modificaron los hashes esperados.
- prueba_fauna: 31/31 (combate, persistencia, descarga, techo, réplica y reaparición vigentes).
- Integración real de cuentas con dos mundos y clientes locales: 13/13, incluido reinicio/reconexión con progreso. Ambos mundos guardados contienen política v2; politicas_servidores.json. Prueba externa/otra PC no ejecutada.

El primer intento del caso de política persistida comparaba un diccionario con version float de JSON con uno convertido a int por carga; se corrigió la comparación usando el canon numérico de Huella. Las posiciones sí eran iguales; no se cambiaron expectativas ni datos de generación. Persisten avisos ObjectDB/recursos conocidos al cerrar. No se repitieron baterías ajenas al cambio.

## Límites

Esta entrega mejora la ubicación local y conserva las mismas regiones ocupadas. No declara terminada la ecología territorial ni las zonas de calma; no añade fuentes de peligro en lugares, señales, navegación/P2, reproducción, migración o economía. No cambia daño, botín, XP, cantidades, techo, radio de carga ni plazo de 720 minutos. La adyacencia es al terreno base, no una respuesta dinámica a tala/construcción. El siguiente bloque es preparar señales que procedan de fauna real o la propuesta de calma/lugares, sin inventar R/T.
