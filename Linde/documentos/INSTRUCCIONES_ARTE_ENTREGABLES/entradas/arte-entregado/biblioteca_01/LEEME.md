# Linde — biblioteca inicial de arte

23 de octubre de 2026. Primera pasada de recursos para continuar el proyecto, **sin definir una beta ni cerrar el alcance del juego**.

## Abrir primero

`GALERIA.html`:catálogo completo con reproducción de acciones, variantes, enemigos, objetos e interfaz. No requiere instalar paquetes; las imágenes deben permanecer junto al HTML. `mapa_muestra/project.godot`:copia aislada del mapa cenital con una parte de los recursos integrada y comprobada en Godot4.7.1. No se modificó el juego original del escritorio ni una partida del usuario.

## Qué contiene

|Sección|Resultado|Estado|
|---|---|---|
|Personaje|Caminata4direcciones×4 cuadros, hacha y ataque4×4,7 máscaras de color y3 recoloreados|Nativos y visibles en muestra; necesitan pulido de transiciones y personalización por selector|
|Escenario|16 tiles,16 objetos/construcciones,4 edificios|36 PNG nativos; conjunto de terrenos todavía incompleto para autotile|
|Enemigos|Slime, guardián y ciervo,4direcciones×5poses cada uno|60 cuadros; integrados visualmente sin cambiar reglas|
|Equipo|Casco, coraza, escudo y espada,4direcciones cada uno|Apariencias estáticas y capas ajustadas combinables de prueba; falta animar equipo|
|Interfaz|20 iconos y17 elementos/widgets derivados|Iconos nativos32px propuestos; panel ampliable comprobado; muestra HUD con panel e iconos|

Los nombres de jefes y otros contenidos de prueba son propuestas, no canon narrativo aprobado. Las dimensiones son una decisión de trabajo para esta biblioteca, no una confirmación del tamaño final de todo el arte.

## Evidencia y límites

Originales, prompts, manifiestos, scripts de conversión y comprobaciones se conservan por sección. Las verificaciones estructurales comprueban dimensiones, alpha, celdas, contenido y reconstrucción de máscaras. Las capturas de `mapa_muestra/` se produjeron en el motor, no con un montaje que simule el juego.

Las capas estáticas ajustadas de casco, coraza, espada y escudo están disponibles en el cargador de la muestra; se dibujan cuando el estado de equipo lo pide. Sus cuatro columnas repiten pose, por lo que aún no acompañan correctamente todos los movimientos de brazos. El primer intento rechazado se conserva en `equipo/overlays_experimentales`; usar `equipo/overlays_ajustados` para la prueba nueva.

La muestra conecta render de terreno, objetos, casa exterior, caminata del PJ, poses de ataque/herramienta, tres enemigos y panel/iconos de inventario. No todos los assets están colocados como contenido de mundo: por ejemplo la cueva y el cobertizo son recursos de biblioteca. El interior de la casa, habitantes y algunos indicadores conservan dibujo provisional. Las reglas, colisiones, premios y progresión son las del código copiado; no se afirman nuevas mecánicas por tener nuevos sprites.

Queda pendiente completar esquinas/transiciones y probar repetición del terreno, alinear puertas con colisiones, coordinar una paleta global, producir nuevas geometrías de pelo/ropa y sincronizar las capas ajustadas de equipo con la caminata. Las acciones y ataques de enemigos tienen observaciones visuales en sus README. Esta primera pasada no sustituye una revisión de animación cuadro por cuadro.

El motor informa recursos todavía en uso al cerrar la escena heredada. Esto se registra como limitación técnica; las capturas se completaron. Esta entrega se verificó desde proyecto, sin probar exportación distribuible.

## Cómo usar la copia de muestra

Abrir `mapa_muestra/project.godot` con Godot4 compatible, importar y ejecutar. Desde terminal, sustituir `Godot` por el ejecutable disponible:

```sh
Godot --path /ruta/mapa_muestra -- --nueva=7 --ir=27,24 --guardado=/ruta/partida_de_prueba.json
```

Usar una ruta nueva de guardado. Flechas/WASD para moverse; Espacio: acción; E: interactuar; I: inventario; Esc: menú; F2: compara el dibujo del PJ/enemigos con el anterior. F2 no devuelve el escenario a su arte anterior.

Para comprobar reglas existentes se incluyen `mapa_muestra/tests/prueba.gd` y `prueba_ui.gd`; los resultados de esta entrega se registran en `VERIFICACION.md`.

## Procedencia

Arte nuevo generado con la herramienta integrada de imágenes a partir de referencias del proyecto; conversiones técnicas en Godot. No se incorporaron assets de Pokémon ni recursos propietarios de Helbreath. Los textos de procedencia no son una certificación jurídica de exclusividad ni una auditoría de derechos. El código de la copia mantiene su procedencia y documentación; esta biblioteca no atribuye a fuentes donantes el arte generado nuevo.
