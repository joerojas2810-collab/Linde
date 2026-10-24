# Aspectos compartidos de PJ y NPC

Implementación provisional del 24 de octubre de 2026. Autorizada por el usuario para ampliar la identidad visual sin sustituir el arte original.

## Opciones

Hombre y mujer seleccionan catálogos de diez peinados cada uno. Se mantienen algunos estilos compartidos. Cambiar la selección conserva el índice 0–9 y resuelve el nombre/tratamiento en el otro catálogo. Todos los tonos y colores quedan disponibles para ambos. No afecta estadísticas, colisión, equipo ni progresión.

Hombre: corto, corto uniforme, media melena, recogido, despeinado, raya izquierda, raya derecha, rizado, largo y coleta.
Mujer: pixie, corto uniforme, melena, moño, coleta, trenza, flequillo, rizado, largo y media melena.

8 tonos de piel, 10 colores de pelo, 10 colores de ropa, 8 de pantalón, 6 de botas y 6 de cinturón. Estos últimos son colores de la ropa base; las armaduras equipadas conservan su paleta propia y pueden ocultarlos.

El cuerpo y las armaduras siguen compartidos. Los peinados son tratamientos de máscara por código sobre las hojas propias existentes, con sombreado y caché; coleta y trenza separan una capa posterior, corto uniforme y despeinado mantienen la cobertura y contorno del cabello original y rizado/pixie conservan el anclaje de cabeza; no son veinte hojas de arte dibujadas individualmente. Requieren una revisión artística posterior, especialmente al dormir y al combinar pelo largo con cascos. No se incorporó material externo.

## Datos y compatibilidad

`scripts/aspecto.gd` centraliza límites, catálogos y presets provisionales por NPC. Maren: mujer con moño y ropa verde; Ordal: hombre corto uniforme con ropa ocre y piel oscura; Nerea: mujer con melena rojiza y ropa turquesa. NPC desconocidos tienen una combinación determinista propia. Esto no cambia el estado narrativo de los personajes ni sus rutinas.

Formato de `look`: `[piel, color_pelo, ropa, identidad, peinado, pantalon, botas, cinturon]`. Los primeros tres índices preservan su significado y sus colores originales. Arrays heredados de tres valores conservan el render anterior sin conversión forzosa. No se cambia el formato 3 del guardado; el array ampliado se guarda y se envía completo. Identidad: 0 hombre, 1 mujer. Índice de peinado relativo al catálogo de esa identidad. Mantener el orden de estos catálogos al publicar nuevas versiones.

La red valida tipo entero, longitud 3/8 y rangos. Protocolo elevado de 2 a 3 para evitar mezclar ejecutables antiguos que solo admiten tres campos con clientes nuevos. Ambos extremos deben actualizarse; las partidas previas siguen siendo legibles.

El paquete de mundo y el contrato Atlas no se amplían silenciosamente: no se añadieron campos a las fichas consumidas por `mundo_datos.gd`. Una futura edición de aspecto en el Atlas deberá acordar un contrato nombrado y su adaptador, reutilizando estos catálogos.

## Acceso

Nueva partida abre el creador ampliado. Alojar sin partida abre el creador antes de iniciar el mundo. En Unirse, seleccionar Conectar y pulsar P permite elegir el aspecto antes del primer ingreso. Reconectar conserva el personaje guardado por el servidor: este cambio no implementa un cambio de aspecto de personajes existentes.

## Verificación y límites

`tests/prueba_aspecto.gd` comprueba selección/validación de red, guardado, recuperación, presets, diez resultados gráficos distintos por identidad y por cada conjunto de animación, recorrido de selectores y regreso a Unirse sin crear una partida.
`tests/prueba_ui.gd` recorre creador, paneles, guardado y continuación. Se conserva la suite general.
`tests/capturar_aspectos.gd` captura el creador y una galería con render real; acepta `--salida=directorio` y por defecto escribe en `user://pruebas_aspecto`.

Durante el desarrollo se detectó y conservó una corrección simultánea de la asignación de camas en habitantes.gd. La apariencia no habilita personajes ni cambia sus rutinas: cualquier bloqueo por validación del paquete se mantiene. Las suites emiten avisos de recursos retenidos al salir; los contadores de aserciones pasan, lo que no equivale a una ejecución sin avisos.
