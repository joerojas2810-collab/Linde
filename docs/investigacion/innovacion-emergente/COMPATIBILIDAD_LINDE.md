# Compatibilidad con Linde

> **Vigencia (consolidación documental, 2026-10-25)**: investigación verificada contra el árbol de trabajo en `HEAD 990d549` el 25/10/2026 (alcance: inspección estática; ver [README](README.md)). **No describe necesariamente el código posterior**: el árbol tenía cambios sin confirmar de otras sesiones (`habitantes.gd`, `sociedad.gd`, `autonomia.gd`, `escena.gd`, `mundo_vivo.gd`, `arraigo.gd`). Si el código verificado la contradice, prevalece el código y hay que corregir este texto. Estado del juego: [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md). Registro de decisiones: [DECISIONES del proyecto](../../../Linde/cenital/docs/DECISIONES.md).

**[C]** Raíz de juego inspeccionada: `Linde/cenital/`. Las copias de proyectos bajo entregables de arte no se toman como implementación vigente. Rutas de las tablas relativas a esa raíz; los enlaces apuntan al árbol real.

## Mapa de capacidades y ampliaciones

| Área | Evidencia confirmada [C] | Ampliación recomendada [P] / límite |
|---|---|---|
| Gramática | `scripts/artesania.gd`: `clave`, `leer`, `info`, `receta`, `validar`. `art1:forma:material:tecnica:calidad` valida representación canónica e incompatibilidad forma/material. | Conservar identidad; añadir conocimiento separado. Una clave válida no significa que su actor la conozca. |
| Materiales | `material`, `combinaciones`, `leer_material`, `receta_material`: núcleo/refuerzo; intersección de formas y propiedades derivadas. `mat1:` solo acepta combinaciones definidas, sin recursión. | Usar el catálogo actual; no simular química universal. Nuevas familias requieren reglas y migración. |
| Calidad y técnicas | `datos/desarrollo/reglas_v1.json`: calidad 0–3, práctica cada 3 acciones por rango, máximo de práctica 120; simple/ligera/reforzada. `desarrollo.rango`, `conoce` y `suelo_requerido`. | Separar saber técnica de disponer ahora de taller. No crear otra calidad aleatoria superpuesta. |
| Conocimiento | `desarrollo.estado`: práctica, materiales, proyecto. `observar` reconoce materiales de objetos y piezas; `planos` deriva combinaciones a calidad del rango actual. | Conocimientos explícitos, fuentes y progreso de investigación. Preservar desbloqueos existentes al migrar. |
| Fabricación del jugador | `desarrollo.fabricar`, `refinar`: validan conocimiento, estación y `Inv.cambiar`. `juego.fabricar` usa recetas estáticas/equipo y verifica habilidad/herramienta. | Extender ambas rutas deliberadamente: no asumir que todo pasa por `desarrollo.fabricar`. |
| Prototipos NPC | `desarrollo.decidir`: excedentes, nivel, materiales, mesa/horno accesible, mantenimiento y tope de piezas. `sociedad.decidir` lo llama tras varias necesidades. | Añadir elección por necesidad y novedad dentro de esa planificación. Mantener alimentación, descanso y acuerdos prioritarios. |
| Descubrimiento de recetas NPC | `autonomia.descubrir_recetas`: un ítem no visto en inventario abre recetas de `C.RECETAS` que lo usan como entrada. `recetas_de` une perfil y nuevas recetas. | Este desbloqueo inmediato ya existe. No volver a implementarlo; decidir cómo convive con experimentación explícita. |
| Memoria | `autonomia._recordar`: eventos con minuto/actor/detalle, deduplicación reciente y recorte. | Usar para narración; no como única fuente de verdad de autoría o conocimiento. |
| Difusión existente | `autonomia._explorar` combina bloques geográficos entre NPC cercanos; `sociedad.observar_extraccion` registra testigos cercanos. | Hay precedentes locales para contacto y testimonio. No son enseñanza de diseños/pericias. |
| Oficios | `datos/autonomia/reglas.json`: perfiles y `sociedad.inmigracion.oficios`; `asentamientos.gd` consume reglas de colonos. `sociedad.objetivos` mantiene producto/reservas del oficio. | Especialización derivada de práctica existente, técnicas y demanda; no sustituir perfiles de abastecimiento. |
| Inventario | `inventario.gd`: diccionario ítem→cantidad; `cambiar` valida resultado final antes de mutar. | Reusar transacción. Si se necesita libro individual o firma por pieza, hace falta identidad de instancia/lote: una clave compartida no conserva autor por ejemplar. |
| Equipo y visual | `equipo.existe/info` reconoce artesanía; `stats_de/finales` integra propiedades; `artesania.visible` reutiliza geometría/paleta. | No duplicar estadísticas ni prometer siluetas inéditas. Las piezas artesanales y `eq:` son familias distintas. |
| Autoría parcial | `desarrollo._creacion`: minuto, actor, clave e insumos; `tope_creaciones=64`. | Registro durable por diseño y evento de descubrimiento. La lista de 64 no conserva primera autoría indefinidamente ni identifica cada ejemplar. |
| Persistencia | `guardado.gd`: formato 3, checksum del cuerpo JSON, temporal, lectura de validación, respaldo y migraciones; `desarrollo` vive bajo `mundo_vivo.autonomia`. | Subesquema versionado y migración explícita; checksum detecta corrupción, no es una firma contra manipulación. |
| Servidor | `red_servidor.ejecutar`: sesión, secuencia, tipos, acciones permitidas. `desarrollo` valida reglas económicas; réplica no avanza tick. | Nuevas intenciones validadas; clientes nunca eligen éxito, autor ni propiedades arbitrarias. |
| Réplica | `estado_para` copia `mundo_vivo` completo; `_difundir` compara JSON por sección y envía sección cambiada. | Separar proyección visible y estado interno si hay secretos; evitar amplificar cada avance pequeño a todos. |

**[C]** En `desarrollo.conoce`, conocer se mezcla actualmente con poder ejecutar: verifica materiales, rango y superficie. `planos` enumera solo calidad del rango actual; `conoce` permite calidades inferiores. **[P]** Mantener compatibilidad de fabricación y definir una consulta adicional de conocimiento independiente del entorno, sin cambiar de golpe el significado de la función existente.

**[C]** `comprar` llama `observar` sobre la pieza recibida: transmite exposición al material, no un plano explícito con procedencia. `restaurar` también observa inventarios al cargar. **[I]** Añadir olvido sin cambiar esas rutas podría reotorgar inmediatamente conocimiento desde posesiones. **[P]** Separar exposición, evidencia y dominio técnico antes de introducir pérdida.

**[C]** `registrar` incrementa práctica por acción confirmada, tanto general como por cada material reconocido. `_creacion` solo se invoca en las rutas artesanales de jugador y prototipos NPC, no en toda fabricación estática o refinado. **[I]** Afirmar que registra toda la producción sería incorrecto. **[P]** Centralizar el registro de resultados confirmados conservando las transacciones existentes; no registrar tanto en caller como en callee.

## Balance cuantificado desde reglas actuales

**[C]** Hay 6 materiales base, 9 laminados (3 núcleos × 3 refuerzos), 7 formas, 3 técnicas y 4 calidades. La intersección de formas admite 57 pares forma/material: 30 de base y 27 laminados. Son **684 claves artesanales estructuralmente válidas** (57×3×4), antes de restricciones de conocimiento/taller. No se cuentan recetas estáticas ni `eq:`.

**[C]** La potencia deriva de material × técnica × `(1 + calidad × 0.08)`. Un laminado combina potencia 85% núcleo + 15% refuerzo; velocidad media y formas comunes. Las técnicas avanzadas añaden coste y superficie. Máximo de piezas artesanales en inventario de NPC para experimentar: 2; historial: 64. **[I]** Estos límites acotan contenido actual, pero un tope en inventario no limita la producción histórica si vende o pierde piezas.

**[P]** Medir por separado disponibilidad, beneficio económico y tiempo productivo. Evitar bucles de fabricación/barata venta/recompra que entrenen sin coste relevante. No declarar exploit confirmado sin ejecutar el ciclo completo.

## Evidencia dinámica

**[C/ejecución]** Se ejecutó la prueba ya existente `tests/prueba_desarrollo.gd` con Godot local 4.7.1 y salida de log dirigida a `/tmp/linde-investigacion/desarrollo-godot.log`: **55 comprobaciones, 0 fallos, salida 0**. Incluye claves inválidas, inventario lleno, estación, consumo, equipo, práctica, laminados, compra, guardado/carga y réplica de conocimiento. La simulación libre de 4.320 minutos produjo 4 creaciones y 8 suelos, y comprobó desgaste de mesa e independencia de tarjetas.

**[C]** El primer arranque sin `--log-file` falló al abrir `user://logs` y terminó con señal 11; el segundo ejecutó la prueba completa. Al terminar quedaron mensajes del motor sobre certificados y recursos/instancias no liberados. **[V]** No se investigaron esos avisos ni se demuestra ausencia de fugas. La prueba de réplica es en proceso y no sustituye una sesión ENet con clientes reales o una prueba de rendimiento prolongada.

## Inventario local verificable

**[C]** Hash SHA-256 del árbol de trabajo inspeccionado. Enlaces y números de línea pueden cambiar; localizar símbolos además de líneas. No se garantiza que el árbol se mantenga inmóvil durante otras sesiones concurrentes.

| Archivo | Enlace | SHA-256 |
|---|---|---|
| `scripts/artesania.gd` | [abrir](../../../Linde/cenital/scripts/artesania.gd) | `86c3fe3c2d2d6efdeed954d8c95b49b31e6e2c464d6138d0add4d30deb4fe128` |
| `scripts/desarrollo.gd` | [abrir](../../../Linde/cenital/scripts/desarrollo.gd) | `dad28f3bb8c156f2ac0abbee12f58a056d9e7017c24135f315a992c2e69f7d3b` |
| `scripts/autonomia.gd` | [abrir](../../../Linde/cenital/scripts/autonomia.gd) | `16e364dbc95c88295ead922a3ede312e7cd8d81b0aac664dea9d07fb36007dd2` |
| `scripts/sociedad.gd` | [abrir](../../../Linde/cenital/scripts/sociedad.gd) | `0ecf4e9400382cde8ffc8dc100890885439eda1b1157dceea3c5f19ea56c1331` |
| `scripts/habitantes.gd` | [abrir](../../../Linde/cenital/scripts/habitantes.gd) | `036371376bd29089e6ee532485e8bfb9b7df5adc5960cda96f5d96a57c97dcae` |
| `scripts/asentamientos.gd` | [abrir](../../../Linde/cenital/scripts/asentamientos.gd) | `f5ed7f7b29d0c02b0be76fd94312ddafc460ba8ff307bba4d1069193e7c3198a` |
| `scripts/inventario.gd` | [abrir](../../../Linde/cenital/scripts/inventario.gd) | `c3a1cbfa2a1db911a939381de532011cb470355053a3f54a46d27fa8b2b35d73` |
| `scripts/equipo.gd` | [abrir](../../../Linde/cenital/scripts/equipo.gd) | `b0c89f6c984408abfb7587d0a68c410ec75881b740081bb61cf0874d6306729c` |
| `scripts/juego.gd` | [abrir](../../../Linde/cenital/scripts/juego.gd) | `201ff961b4b98538b77b182a4e0edefd6fe5e14f770574746fdca374f9454f85` |
| `scripts/guardado.gd` | [abrir](../../../Linde/cenital/scripts/guardado.gd) | `bb1357b7dc9dc970f02df830800110f7d28099921b10691872507c8a55c5e1fe` |
| `scripts/red_servidor.gd` | [abrir](../../../Linde/cenital/scripts/red_servidor.gd) | `e10bd002a3a228a86775b58ed2bb5d9a7b786e0235010ab7d471dcdd6a70f210` |
| `scripts/red_cliente.gd` | [abrir](../../../Linde/cenital/scripts/red_cliente.gd) | `75c2435a1495c2859a59905fd01478acc9e44650e15da809cd713de1f0438668` |
| `scripts/catalogos.gd` | [abrir](../../../Linde/cenital/scripts/catalogos.gd) | `843aad00b517464f8ed8f1f97a8a4e540f1d6b63d24bc568b3e30a0401794ecb` |
| `scripts/escena.gd` | [abrir](../../../Linde/cenital/scripts/escena.gd) | `6bed603f8f6a272ee6f6758384120ed4ab620bdf28651912ad90949c95bbc862` |
| `datos/desarrollo/reglas_v1.json` | [abrir](../../../Linde/cenital/datos/desarrollo/reglas_v1.json) | `788f66316ad6abaaebd001078af35982d146f77882fb0c39c928783b023a9cc2` |
| `datos/autonomia/reglas.json` | [abrir](../../../Linde/cenital/datos/autonomia/reglas.json) | `5e8050e0b9337e866d6246a136bfd1068771d3cbbdc67f12ffb8f84114349523` |
| `tests/prueba_desarrollo.gd` | [abrir](../../../Linde/cenital/tests/prueba_desarrollo.gd) | `a6eb3c570757b8a1d22f2c8bc557ae3ef42934b0b4205f83f998235be80bd664` |
| `project.godot` | [abrir](../../../Linde/cenital/project.godot) | `4bed57c945d4a58fb5fd092552426b13afcb05d97fa7ff6358663b40bf83e800` |

### Símbolos para navegación

**[C]** Referencias obtenidas sobre esta copia:

- [`scripts/artesania.gd:13`](../../../Linde/cenital/scripts/artesania.gd#L13) — `combinaciones`.
- [`scripts/artesania.gd:54`](../../../Linde/cenital/scripts/artesania.gd#L54) — `leer`.
- [`scripts/artesania.gd:66`](../../../Linde/cenital/scripts/artesania.gd#L66) — `info`.
- [`scripts/artesania.gd:90`](../../../Linde/cenital/scripts/artesania.gd#L90) — `receta`.
- [`scripts/artesania.gd:100`](../../../Linde/cenital/scripts/artesania.gd#L100) — `visible`.
- [`scripts/desarrollo.gd:20`](../../../Linde/cenital/scripts/desarrollo.gd#L20) — `datos`.
- [`scripts/desarrollo.gd:55`](../../../Linde/cenital/scripts/desarrollo.gd#L55) — `registrar`.
- [`scripts/desarrollo.gd:85`](../../../Linde/cenital/scripts/desarrollo.gd#L85) — `conoce`.
- [`scripts/desarrollo.gd:113`](../../../Linde/cenital/scripts/desarrollo.gd#L113) — `planos`.
- [`scripts/desarrollo.gd:124`](../../../Linde/cenital/scripts/desarrollo.gd#L124) — `_creacion`.
- [`scripts/desarrollo.gd:130`](../../../Linde/cenital/scripts/desarrollo.gd#L130) — `fabricar`.
- [`scripts/desarrollo.gd:180`](../../../Linde/cenital/scripts/desarrollo.gd#L180) — `decidir`.
- [`scripts/autonomia.gd:65`](../../../Linde/cenital/scripts/autonomia.gd#L65) — `descubrir_recetas`.
- [`scripts/autonomia.gd:76`](../../../Linde/cenital/scripts/autonomia.gd#L76) — `_recordar`.
- [`scripts/autonomia.gd:85`](../../../Linde/cenital/scripts/autonomia.gd#L85) — `paso`.
- [`scripts/autonomia.gd:241`](../../../Linde/cenital/scripts/autonomia.gd#L241) — `_explorar`.
- [`scripts/sociedad.gd:612`](../../../Linde/cenital/scripts/sociedad.gd#L612) — `objetivos`.
- [`scripts/sociedad.gd:665`](../../../Linde/cenital/scripts/sociedad.gd#L665) — `decidir`.
- [`scripts/guardado.gd:27`](../../../Linde/cenital/scripts/guardado.gd#L27) — `migrar`.
- [`scripts/guardado.gd:84`](../../../Linde/cenital/scripts/guardado.gd#L84) — `guardar`.
- [`scripts/red_servidor.gd:189`](../../../Linde/cenital/scripts/red_servidor.gd#L189) — `ejecutar`.
- [`scripts/red_servidor.gd:359`](../../../Linde/cenital/scripts/red_servidor.gd#L359) — `_difundir`.
- [`scripts/red_servidor.gd:430`](../../../Linde/cenital/scripts/red_servidor.gd#L430) — `estado_para`.

## Cambio concurrente detectado

**[C]** Durante la investigación apareció `scripts/arraigo.gd` en el árbol de trabajo y `sociedad.gd` pasó a instanciarlo. Se inspeccionaron `evaluar_dia`, `_marchar` y `_regresar`: la partida marca al colono ausente y conserva su identidad/inventario/recuerdos, con posibilidad de regreso. No se modificó ese trabajo. **[P]** La futura disponibilidad de conocimiento debe consultar presencia sin borrar el conocimiento del actor ausente. **[V]** No se auditó por completo esta función concurrente ni su prueba nueva; volver a fijar el árbol antes de implementar.

Hash observado de [arraigo.gd](../../../Linde/cenital/scripts/arraigo.gd): `922558542859048eb372acf92aac546699b1135f9955ddfc121e2cd8f76eb470`.

**[C]** Al cierre también se observaron cambios concurrentes adicionales en autonomía, interfaz, mundo vivo, datos de eventos/misiones y diseño. El resultado de 55 comprobaciones corresponde al árbol al momento de ejecutar la prueba, antes de esos cambios posteriores; no certifica el árbol final de otra sesión. Los hashes registran la lectura documental, no un commit aislado de todos esos cambios.
