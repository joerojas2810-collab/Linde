# Integración propuesta E03

## Enemigos existentes

Los tres atlas finales tienen9 columnas×4direcciones: reposo, pasoA, pasoB, aviso, impacto, daño, recuperación, derrotaA, derrotaB. Celda32/pivote16,29 para Slime;48/pivote24,45 para Guardián/Ciervo. Las primeras cinco columnas son idénticas a las anteriores. Columna6 copia el reposo aceptado; recuperación puede mostrar brevemente4 y volver a6 durante el estado real `recupera`, sin saltos entre una identidad vieja y nueva. No sustituir su duración por la de una galería.

- Reposo:col0; caminata:1,0,2,0 solo cuando hay desplazamiento real, dirección cardinal desde movimiento/orientación existente.
- Aviso:col3 y cuenta real de e.t/info.aviso. Resolver el impacto en el instante actual de Linde, no al terminar una animación nueva. Mantener daño, alcance, tolerancia, objetivos y recuperación.
- Daño:col5 como reacción visual breve al confirmar pérdida de HP; no paraliza ni reinicia el ciclo de ataque. Tiempo propuesto0.12s de presentación, no invulnerabilidad nueva. Si interfiere con un aviso importante, priorizar señal legible antes que ocultar intención.
- Derrota:7→8 como residuo gráfico no interactivo después de la muerte real, propuesta0.24s total. Recompensas y eliminación lógica ocurren cuando ya ocurrían; conservar posición/dirección antes de borrar la entidad. No retrasar experiencia/botín ni mantener colisión por animar un cadáver.

Actualmente `combate.paso` filtra muertos en el mismo paso. `_danar` tampoco emite evento gráfico. Estos recursos requieren una conexión de presentación explícita; no basta con inferir daño cada frame. El snapshot remoto actual no transmite ID estable ni home por enemigo: contiene tipo/posición/estado/hp/ataque/tiempo/dirección. No asociar entidades remotas por índice de array ni prometer correlación perfecta por proximidad. El integrador debe diseñar eventos/identidad gráfica estables, con deduplicación, y validar el protocolo con su dueño. Este lote no lo implementa ni modifica la red.

## NPC modulares

Seguir REPARTO_PJ_NPC.md y maren/modular/INTEGRACION.md: una base compartida, presets y caché del compositor existente. Maren usa look[1,0,2]; no hay NPC nuevos de lógica. La hoja independiente imagegen se conserva solo como referencia. Mantener rutina/velocidad/diálogo; conectar orientación al desplazamiento existente. Ampliar prendas o peinados por piezas requerirá contrato con02, no dibujar otro atlas entero por cada habitante.

## Efectos y señales

Seguir efectos/INTEGRACION_FX_Y_TELEGRAFOS.md. Los tres atlas4cuadros/celda32/pivote16,16 son impacto, daño y recolección. Tiempos propuestos0.16/0.20/0.28s, exclusivamente visuales. Activar desde eventos confirmados y una única vez, conservar posición si objeto/enemigo desaparece. No añadir estela de espada (01), herramienta (02) ni luz (06).

Geometría real: centro enemigo=pies−tam/2, centroPJ=pies−6. Ataques circulares comparan radio+6 contra ese centro. Embestida usa cápsula del segmento realmente recorrido hasta colisión, radioancho/2+6; el avance es instantáneo en resolución. Solo puede dañar al objetivo fijado actual. Mostrar marca/etiqueta de objetivo en multijugador para no prometer daño a todos.

## Reproducir revisión

Desde raíz del lote, con GODOT_BIN apuntando a Godot4.7.1:

```sh
"$GODOT_BIN" --headless --path previews/godot --editor --quit
"$GODOT_BIN" --path previews/godot
"$GODOT_BIN" --path previews/godot -- --capturas="$PWD/previews/capturas"
"$GODOT_BIN" --headless --path previews/godot --script "$PWD/enemigos/fuentes/convertir.gd" -- "$PWD/enemigos"
```

1 estados,2 composición,3FX;←→ dirección;Espacio pausa. La composición es un escenario técnico independiente con recursos históricos, no el mapa del juego activo. El ciclo demostrativo no fija tiempos mecánicos. Después de regenerar, sincronizar atlas a previews/godot/assets/enemigos y reimportar. Las copias entregadas están sincronizadas.

QA productivo pendiente: todos los estados/direcciones, transiciones y anclas, golpes y muerte sin retrasar mecánica, multiobjetivo/red/deduplicación, oclusión/escala con mundo definitivo y aceptación de estilo. El contraste de detalle casa/actores queda registrado en COORDINACION_ESTILO.md; no confundir claridad estructural con coherencia artística aprobada.
