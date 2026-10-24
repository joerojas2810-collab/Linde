# Recepción por la IA integradora

1. Verificar SHA del manifiesto y comparar estado real con commit base. No copiar juego desde este lote: no hay reemplazo de scripts productivos.
2. Importar assets/ con nearest, sin mipmaps, mantener tamaños nativos. Incorporar fuente sin modificar junto a OFL.txt y aviso de autor. Código original de preview/shader/SVG se entrega para LINDE; conservar los avisos de origen.
3. Leer ICONOS_POR_ID.json. Validar eq: con Equipo.leer y mostrar metadatos reales con Equipo.info. No confundir el icono genérico con armadura exclusiva por familia.
4. Construir controles dinámicos siguiendo CONTRATO_PROPUESTO.json de la salida. Números/selección/textos son datos reales, no los valores de muestra. XP debe usar xp_fill.svg azul: tintar el relleno rojo no produce azul correcto. Barra interior44x5 con offset10,9, recorte y valor limitado0..1; marco fijo.
5. Menú/diálogo usan composición, no imagen con texto. La comunidad es emblema genérico en diálogo, no retrato definitivo de Maren (pertenece a03). Fondo del preview es referencia conceptual ya existente; no representa captura del juego activo ni nuevo mapa.
6. Aplicar shader luz al mundo mediante rama/material apropiado, mantener HUD en CanvasLayer fuera del tinte. Integración puede preferir CanvasModulate equivalente. No cambiar reloj o combate. Máscara de sombra a pies, escala entera, sin modificar hitbox. Curva diurna y oclusión pendientes de implementación/validación real.
7. QA productivo: todas las pantallas afectadas, textos largos,0/50/100%, cantidades, familias/variantes/niveles, input/foco, ventanas, creador/unirse, día/noche y red si aplica. Guardar en production/qa/evidence del juego de trabajo. No dar por hecho esos tests por los de este preview.

## Preview reproducible

Desde raíz del lote, con Godot4.7.1 disponible (GODOT_BIN debe apuntar al ejecutable):

```sh
"$GODOT_BIN" --headless --path previews/godot --editor --quit
"$GODOT_BIN" --path previews/godot
"$GODOT_BIN" --path previews/godot -- --capturas="$PWD/previews/capturas"
"$GODOT_BIN" --headless --path previews/godot --script "$PWD/fuentes/herramientas/verificar_fuente.gd"
"$GODOT_BIN" --headless --path previews/godot --script "$PWD/fuentes/herramientas/convertir_iconos.gd" -- "$PWD/fuentes/iconos_complementarios_original.png" "$PWD/assets/nuevos"
```

1..6 pantallas, N día/noche,←→ selección y↑↓ valor. Es demostración de presentación: botones no cargan partida ni modifican estado. Tras regenerar iconos sincronizar assets/nuevos a previews/godot/assets/nuevos. Las copias del preview se entregan sincronizadas por hash. El proyecto de preview usa únicamente rutas res://, sin archivos de usuario ajenos.
