# Auditoría de estética: mundo, actores e interfaz

Fecha de lectura: 2026-10-24. Raíz examinada: `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/Linde`. Solo lectura del proyecto; no se ejecutaron suites ni se modificaron sus archivos. Las conclusiones de ejecución se limitan a evidencias existentes, no a una comprobación nueva.

## Resultado

El inventario general del plan describe bien la diferencia entre biblioteca entregada y juego activo: el escenario, enemigos, Maren y HUD activos siguen con el dibujo anterior. Pero no debe presentarse la biblioteca como un kit terminado: quedan huecos de geometría, estados, escala y tratamiento de color. La retirada del dibujo anterior exige reemplazar todas las rutas de fallback, también remotos/personaje, no solo activar `usar_arte`.

## Evidencia de estado actual

| Dominio | Juego activo: ruta y símbolo | Recursos existentes separados | Trabajo necesario |
|---|---|---|---|
| Terreno | `cenital/scripts/arte.gd:34 suelo`; llamado desde `escena.gd:_draw`, línea 529 aprox. | `arte-entregado/biblioteca_01/escenario/assets`: 16 tiles16; `manifest.json`, `LEEME.md` | Conexiones completas; no se validó tileability. Incorporar por ID; las cardinales solas no producen todas las esquinas/cruces. |
| Árbol/roca/arbusto/barril/valla/cofre | `arte.gd:89 arbol`, `102 roca`, `110 arbusto`, `115 barril`, `121 valla`, `127 cofre`; `escena.gd:_dibujar_obj` | 16 objetos48, incluidos tres árboles, estados de cofre, roca, `ore_copper`, arbusto, barril y valla | Escala física por familia, pivotes reales, copas/colisiones; faltan tocón, agotados, arbusto sin bayas, valla vertical. |
| Construcción | `arte.gd:133 constr`; `escena.gd:_dibujar_constr`; fantasma en `escena.gd:561` | palisade, floor_wood, workbench, furnace, chest_closed, bed | Integrar por tipo sin alterar alcance/coste/colisión. El fantasma puede reutilizar la textura tintada; no necesariamente requiere una hoja distinta. |
| Casa | `arte.gd:160 tejado`, `179 fachada`; `escena.gd:_draw` ordena fachada y luego siempre dibuja tejado | cottage_closed/open96, crafting_shed96, cave_entrance96 | Los sprites son edificios completos, no kit modular. Separar/alinear puerta, cubierta/fachada e interior; respetar geometría lógica. |
| Habitantes | `escena.gd:620 _dibujar_npc` usa `Apar.dibujar` siempre, dirección DOWN; `habitantes.gd` no define un sprite específico | Base/capas de PJ entregados; no se encontró hoja propia de Maren | Recoloreo necesita integración, contrato de poses y dirección. No basta activar `usar_arte`. |
| Enemigos | `escena.gd:630 _dibujar_enemigo`: rectángulos y ojos; aviso blanquea color; vida con barras | `enemigos/nativos`: 3 atlas; README y validacion.json | Conectar filas/poses a estados reales; faltan daño/muerte y recuperación pulida. Los tamaños de atlas no son hitboxes. |
| Efectos | `escena.gd:_telegrafo` círculo o polígono; línea564 zona_golpe; línea660 indicador de golpes | No hojas completas de efectos encontradas en biblioteca de mundo/UI | Efectos por fase y máscara/señal cuyo radio/avance siga la regla existente. No sustituir hitbox con tamaño de imagen. |
| Luz/sombras | `hud.gd:29` tinte azul a pantalla; `escena.gd:588/612/623/636` sombras rectangulares | Sin sistema de luz nuevo entregado | Tinte por CanvasModulate/shader o equivalente y sombras compatibles. Un rectángulo técnico de pantalla no implica arte dibujado: auditar su función y criterio acordado, no solo token. |
| HUD/paneles | `hud.gd:18/19` barra; `75/76/88` panel y selección; tipografía fallback | interfaz37 PNG, 20 iconos32, panel64×48, barra y relleno44×5 | Integración de controles, márgenes, cantidades, input/foco, contraste y barra dinámica; no está validado como HUD completo. |

La única subcarpeta de `cenital/arte` encontrada es `equipo` (más hojas sueltas de personaje), no `mundo`, `enemigos` ni `interfaz`. La biblioteca incluye una `mapa_muestra` aislada con arte integrado; no confundir esa copia con `cenital` activo.

## Problemas concretos del plan

1. **No existe un único 32×32 para todo.** `params.gd` CELDA16, SPRITE16×24, ZOOM3; escenario usa tiles16/objetos48/edificios96; enemigos celdas32/48; UI iconos32, panel64×48 y relleno44×5. El validador «todo múltiplo16» rechazaría arte entregado correcto como el relleno. Debe validar contrato por tipo; distinguir lienzo, silueta, paso de píxel, tamaño dibujado y zoom. Encoger48→32 introduce factor2/3 y puede contradecir «un solo tamaño de píxel» aunque nearest esté activado. Resolver en contacto aplicado, no declararlo cumplido.
2. **Paleta unificada no existe todavía.** El README de escenario lo declara. `interfaz/checks.json` cuenta, por ejemplo, 360 colores en madera y1426 en panel. Alfa binario solo verifica transparencia; no demuestra 2–3 tonos/material, ausencia de gradientes ni una paleta global pequeña. El plan debe reservar limpieza/redibujo o cuantización revisada; copiar37 PNG no resuelve estilo.
3. **Puente/cueva/cobertizo no tienen ubicación lógica en el mapa activo.** `mundo.gd` define CASA, ARENA, CANTERA, BOSQUE, CLARO, lago rectangular; no puente o cueva/cobertizo transitables. La condición final exige capturas de puente y cueva mientras se excluyen nuevas reglas. Definir si se aceptan escenario de prueba separado, decoración no transitable o cambio autorizado de mapa. Nunca añadir puente visual sobre agua bloqueada.
4. **Estados de agotamiento requieren correspondencia real.** `mundo.gd:31 estado` conserva rotos/golpes/constr; `escena.gd:_draw` omite cualquier objeto en `rotos`; `mundo.gd:162 regenerar` restaura objetos. Dibujar tocón agotado puede ser solo render desde rotos, sin reintroducir colisión, interacción o estado persistido. No crear nuevas reglas de cosecha por tener una textura sin bayas.
5. **Dos variantes de casa no son animación.** LEEME de escenario declara que closed/open requieren alineación; no se puede alternar el edificio entero sin salto. La casa activa `Rect2i(24,16,8,7)`, puerta `(27,22)` debe seguir siendo autoridad de geometría. Separar tejado/copas exige archivos/componentes nuevos; no lo resuelve escalado de sprite completo.
6. **UI ya contiene escudo genérico.** `interfaz/assets/escudo.png` y README20 iconos lo incluyen. «Falta escudo» debe especificar icono por arquetipo/equipo, no pedir el mismo recurso otra vez. Inventario por ID debe distinguir iconos genéricos frente a las17 piezas/arquetipos actuales.
7. **Enemigos incompletos, aunque estructuralmente válidos.** Atlas5 columnas×4 direcciones: idle, dos pasos, anticipación, ataque. `enemigos/validacion.json` solo valida estructura. README declara que faltan daño, muerte, recuperación y pulido de anatomía. El plan pone «—» para slime/ciervo y solo aviso guardián: no equivale a todos los estados listos. En `combate.gd` impacto es instantáneo y después recupera; render debe mapearlo sin alterar tiempos.
8. **Fallo por arte faltante no está garantizado hoy.** `escena.gd:590–592` cae de equipo a Capas y luego Apar; `_dibujar_otro` también vuelve a Apar. Incluso `usar_arte=true` no elimina la línea anterior. El parámetro `--arte` asigna `_hay_arte()` en línea106 y puede terminar false. Retirar fallback debe incluir creador/remotos/ausencia de archivo y conservar aviso técnico legible.
9. **Prueba por búsqueda de draw_* es insuficiente.** La lista blanca debe clasificar sombras, UI dinámica, telegraphs, depuración, selección y geometría técnica. Puede marcar como falta un efecto técnico legítimo o no detectar fallback encapsulado en un helper/shader. Exigir captura y rutas activas; no convertir el objetivo de retirar el arte anterior en prohibición de GodotCanvasItem.
10. **Dependencia circular de arranque.** El lote1 debe llegar antes de sesión1, pero nombres/medidas exactos se definirían en1.2. Hace falta contrato de recursos previo y después producción; no generar esquinas, capas o efectos sin IDs, vecinos, anclas y enum de estados.

## Evidencia preexistente revisada

- `cenital/tests/capturas/exportado_arte.png`: abierto; muestra PJ/equipo nuevo rodeado de casa/vegetación/enemigos/HUD antiguos. Apoya el diagnóstico, pero no prueba el estado de una ejecución nueva.
- `arte-entregado/biblioteca_01/interfaz/galeria.png`: abierto; existen marcos e iconos reconocibles.
- `interfaz/ninepatch_check.json`: esquinas exactas a96×64,160×96,192×128, márgenes8. Solo panel; no certifica botones ni HUD final.
- `enemigos/validacion.json`: passed:true, sin cuadros vacíos o alfa parcial, scope structural_only_not_artistic_quality.
- `escenario/LEEME.md`: enumera explícitamente límites y falta de tileability/escala final.

## División recomendada sin colisiones

**IA arte:** solo carpeta de entrega nueva (no modificar `arte-entregado` histórico), PNG fuente/nativos, prompts y manifiestos propios. Produce muestras de paleta/escala, terreno completo, objetos/edificio separados y efectos/actores/UI faltantes. No toca scripts, colisiones, catálogos mecánicos ni tiempos. Cada lote cerrado con hash y lista de faltas.

**IA integración Godot:** única dueña de `cenital/scripts`, escenas, `datos/arte`, importación y copia de assets aprobados; usa los IDs del contrato. Puede integrar lote ya existente sin esperar todo el arte, pero no afirmar cierre ni usar fallback prohibido. Toma también tests/evidencias de runtime y red; copia final arte por hash, no edita originales.

**Compartido mediante contrato versionado, dueño único:** IDs, archivo, celda/lienzo, bbox/silueta, pivote, escala nativa de dibujo, secuencias por estado y dirección, zonas nueve regiones, vecinos del autotile, referencia de paleta, procedencia, estado, hashes. IA arte propone; integrador valida compatibilidad y registra recepción. No asignar simultáneamente `REGISTRO.json`, `escena.gd`, `hud.gd` o `DECISIONES.md` a dos IA.
