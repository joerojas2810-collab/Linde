# E03 — Efectos y señales de combate

Estado: candidatos originales técnicos; sin aprobación de dirección de arte ni integración productiva. Tres atlas nuevos sencillos, 4 cuadros por efecto, celda32×32, pivote16×16, dibujo1:1 con mundo, nearest, sin suavizado, sin bucle. Son un acento de pocos píxeles; su lienzo NO representa colisión. No se reutilizan píxeles pintados ni lógica del otro juego.

## Entregado

| ID | Evento visual | Duración propuesta | Ancla |
|---|---|---|---|
| E03_fx_impacto | Golpe confirmado sobre enemigo, chispa crema/dorada | 0.16s | `Combate.centro(e)` capturado al confirmar el golpe |
| E03_fx_dano | Daño confirmado al PJ, cuatro motas rojas sin sangre | 0.20s | `Combate.centro_pj(id)` capturado al aplicar daño |
| E03_fx_recoleccion | Entrega real de recursos, destello oro/verde | 0.28s | centro del objeto recolectado o centro del receptor según evento disponible |

Todos son duraciones de presentación, no cooldown, invulnerabilidad ni ventana de daño. Reproducir0→1→2→3 una sola vez y retirar. No alterar `INVULN_S=0.6`, animación de daño del PJ, costes, drops ni tiempos de herramientas. Conservar el parpadeo existente hasta decidir visualmente su combinación. No crear un efecto por cada frame ni inferir golpe a partir de solapamiento visual.

Para integrar hay que emitir o capturar eventos **confirmados**: actualmente `_danar` no emite un evento gráfico, y muerte elimina la entidad al terminar `paso`. Guardar posición antes de eliminarla. La capa visual consume eventos con identidad por jugador/enemigo y secuencia; evita duplicarlos tras corrección o reenvío de red. Recolección se dispara al otorgar realmente el recurso (incluso si queda pendiente), no cada golpe al árbol. Estas conexiones son trabajo del integrador, no están realizadas aquí.

## Telegráficos: geometría real, no PNG estirado a ojo

Fuentes leídas: `Linde/cenital/scripts/combate.gd`, `catalogos.gd` (huellas en `qa/FUENTES_SHA256.json`). Código actual provisional. No se modifica.

- Centro enemigo: `e.pos - Vector2(0,e.tam/2)`. El ancla de pies no es el centro del área.
- Centro PJ: `pies_de(id) - Vector2(0,6)`. La tolerancia de6px se suma al área contra ese centro; no es otro desplazamiento hacia abajo ni el tamaño del PNG.
- Círculo: comprobación real `distance(centro_enemigo,centro_pj) <= radio+6`. Radios actuales base/efectivo: slime14/20, onda44/50, pisotón36/42.
- Embestida: `largo70` sirve al rango para iniciar ataque (`largo*0.8`); el golpe usa el **segmento realmente recorrido**. Avance70, ancho16 → radio de cápsula base8, efectivo14. Extremos redondos, no rectángulo de70×16.
- El avance ocurre en el mismo `_resolver`, mediante pasos2px hasta bloqueo. No hay desplazamiento continuo durante0.8s. No animar un cuerpo cruzando la zona antes de que la lógica avance, ni retrasar daño para que coincida con una interpolación inventada.
- `fuentes/telegrapho.gd` propone cálculo visual sin mutar enemigos. Para predecir pared usar la consulta actual `mundo.mover(pos,delta,Vector2(tam,tam*0.6))` sobre posición temporal, sin llamar `_mover` sobre una entidad real. La dirección es `e.dir` fijada al comenzar aviso. Si cambia un obstáculo durante aviso, recalcular usando el mundo actual. Al resolver, el segmento real prevalece sobre cualquier predicción previa. En clientes sin mundo autoritativo equivalente, etiquetar la previsión y no prometer coincidencia exacta.

Presentación propuesta: contorno dorado en límite base, borde crema en límite efectivo y punteado rojo entre ambos, relleno interior escaso para ver el terreno. El **borde exterior** comunica el peligro para el centro del objetivo; el dorado comunica el tamaño base del ataque. Mostrar una marca de centro del PJ durante QA para entender la relación con los pies. No llenar la pantalla con partículas ni depender solo del color. El dibujo es técnico dinámico y parametrizado; un círculo estático como atlas no sustituye radios reales ni colisión con paredes.

Los tiempos de señal salen de `info_ataque`: slime0.5s/rec0.8s; embestida0.8s/rec1.0s; onda1.0s/rec1.2s; pisotón0.9s/rec1.1s. La cuenta visual lee `e.t/info.aviso`; nunca escribe `e.t`. Al salir de aviso retirar la señal y opcionalmente emitir breve acento de impacto. Recuperación del enemigo se ilustra en su sprite; no dejar zona de daño activa durante recuperación.

**Multijugador:** actualmente `_resolver` solo puede dañar `e.obj`, aunque otro PJ entre en el área. La señal debe llevar identificación de objetivo fijado y una diferencia de patrón/símbolo para observadores. No presentarla como AoE para todos ni convertirla en AoE para justificar el dibujo. Ningún código de esta entrega cambia esa regla.

## Validación y revisión

Ejecutar Godot4.7.1 sobre ESTA carpeta aislada:

```sh
Godot --headless --path /ruta/efectos --script res://fuentes/generar.gd
Godot --headless --path /ruta/efectos --script res://fuentes/verificar_telegrapho.gd
```

`qa/CONTACTO_FX_x6.png`: filas impacto, daño, recolección; columnas0–3. `qa/TELEGRAFOS_GEOMETRIA_x3.png`: slime, onda, pisotón y cápsula de muestra diagonal. La cápsula diagonal es ilustración geométrica, no un ataque nuevo del catálogo. `GALERIA.html` incluye tamaño real y ampliado nearest.

Hecho: generación, relectura de atlas, alfa binaria, celdas, geometría y límites, láminas retenidas. Pendiente: composición sobre mapa vivo, rendimiento/cantidad de eventos simultáneos, distancia real de lectura a zoom3, comprobación local/remota, colisiones dinámicas autoritativas, aprobación artística y conexión de eventos. Las láminas headless no son captura del juego ni sustituyen QA de integración. No se tocó producción.
