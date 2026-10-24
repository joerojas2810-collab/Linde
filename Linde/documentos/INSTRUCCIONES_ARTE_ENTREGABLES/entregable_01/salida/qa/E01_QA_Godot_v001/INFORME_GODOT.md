# E01 — Validación real en Godot

24/10/2026. Motor: Godot 4.7.1.stable.official.a13da4feb. Ejecución con ventana 1280×800, OpenGL Compatibility / AMD Radeon. Salida final del proceso: 0.

## Resultado

- 10.883 comprobaciones del compositor: 0 fallos. Cubre 3 arquetipos × 3 familias × 3 apariencias × 4 direcciones × 4 cuadros; además ranuras aisladas y personaje sin equipo.
- Validador original de Godot: 17/17 hojas, 0 errores y 0 avisos.
- Comprobado: carga real de las piezas antes vacías, selección de celdas, pivote [24,48], ocultación de ropa base por ranura, espada delante del torso y reutilización de caché.
- Nueve capturas reales del motor, tres arquetipos por tres familias, después de 60 fotogramas renderizados por presentación. Las cuatro poses y cuatro direcciones aparecen a zoom 3 nearest en cada captura, antes/candidato lado a lado.
- Revisadas visualmente las capturas pesada/Vigía, ligera/Zarzal y media/Albor: cara libre, apoyo de botas, cobertura del torso y espada por delante. No se detectó un nuevo defecto que exigiera modificar las nueve correcciones.
- Los scripts de composición, parámetros y carga de imágenes son copias byte a byte del proyecto. Los PNG candidatos conservan los hashes del lote E01_v001.
- La ejecución final terminó sin errores ni avisos en E01_motor.log. El primer intento tuvo rutas de datos de usuario inaccesibles; se resolvió usando una copia portable del motor y APPDATA local de la prueba. No se modificó el motor original.

## Alcance y pendientes

Esto valida el lote con el compositor real en una escena aislada. No es integración en el mapa, prueba multijugador ni exportación del juego. La estela se dibuja explícitamente en esta escena: el cargador productivo sigue necesitando que la conecte el integrador. El agarre oculto del escudo y la estela de anticipación izquierda siguen pendientes de aceptación artística. No se atribuye aprobación al usuario.

El informe antiguo incluido en E01_entrega describe correctamente el estado anterior, sin motor. Este anexo sustituye únicamente esa limitación: ahora sí existen ejecución, pruebas y capturas reales de Godot. El lote artístico recibido permanece inmutable.

## Reproducir

Abrir E01_QA_Godot/project.godot con Godot 4.7.1; la escena ejecuta las comprobaciones y guarda nueve PNG en evidencia antes de cerrarse. No contiene el ejecutable del motor ni cachés. La importación inicial puede regenerar metadatos.

Comandos utilizados (rutas relativas al espacio de trabajo):

    Godot_v4.7.1-stable_win64_console.exe --headless --path work/E01_godot/salida/lotes/E01_v001/validacion/godot --editor --import --quit
    Godot_v4.7.1-stable_win64_console.exe --path work/E01_godot/salida/lotes/E01_v001/validacion/godot --windowed --resolution 1280x800 --log-file evidencia/E01_motor.log --quit-after 1200

En esta máquina se usó una copia portable y APPDATA dentro de work/E01_godot/runtime/appdata. El motor no viaja en el ZIP.
