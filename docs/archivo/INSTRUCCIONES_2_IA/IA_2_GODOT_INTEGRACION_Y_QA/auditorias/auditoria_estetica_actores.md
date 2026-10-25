# Auditoría de actores, equipo y ataque para separar arte / integración

Fecha de lectura: 2026-10-24. Producción inspeccionada SOLO LECTURA: `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/Linde`. No se ejecutaron suites ni se modificó producción.

## Resultado

El personaje y sus **17 hojas de equipo de caminata ya están integrados**. Los 17 PNG en `cenital/arte/equipo/` son byte a byte iguales a `arte-entregado/equipo_indice_01/hojas/`. La caminata base es idéntica a `arte-entregado/biblioteca_01/personaje/caminata.png`. No pedir otro personaje ni rehacer caminata, ranuras, recoloreado o geometría de equipo completa.

Ataque: existe una derivación útil de 17 hojas con 9 celdas vacías explícitamente declaradas. El trabajo nuevo debe completar esas celdas, separar un efecto de estela y producir los estados que faltan. No presentar los 17 atlas de ataque como completos.

## Escala, ancla y contrato efectivo

- `cenital/scripts/params.gd`: `CELDA=16`, `PIES=Vector2(10,6)` (colisión), `SPRITE=Vector2i(16,24)` nominal, `ZOOM=3`, `PASO_S=.12`. El tamaño nominal del dibujo antiguo no es el lienzo PNG ni la caja de colisión.
- Caminata real: atlas128×128; celdas32×32; pivote [16,32]. Ataque real: atlas192×192; celdas48×48; pivote [24,48]. Filas frente/derecha/espalda/izquierda, cuatro columnas.
- Ataque columnas: preparado, anticipacion, impacto, recuperacion. `anim_pj.gd:FASE` asigna aviso→0/1, activo→2, rec→3.
- Índices exactos principal#FF0000, sombra#00FF00, acento#0000FF, detalle#808080; alfa binaria. Reutilizar el contrato del manifiesto integrado y el validador. Calidad y encaje requieren revisión además de formato.
- `arte_equipo.gd:OCULTA`: torso oculta b_tunica, pantalones oculta b_pantalon, botas oculta b_botas. Cinturón no se oculta. Base separa cuerpo/piel/botas/pantalon/tunica/cinturon/pelo.
- `arte_equipo.gd:ORDEN_DERECHA`: escudo detrás de torso y espada delante; izquierda invierte esos papeles. `INVERTIR_PERFILES` existe y se comparte con `capas_sprite.gd`. Ataque puede adelantar espada por celda mediante `espada_delante` del manifiesto.
- `equipo.gd:visible()` entrega ranura/arquetipo/silueta/familia/variante/paleta/delta. Cinco ranuras de set + escudo (`catalogos.gd:RANURAS`); espada se añade según inventario en `escena.gd:_equipo_visible`. No diseñar una nueva estructura incompatible.
- Recoloreado CPU/caché ya existe: `arte_equipo.gd:mapa_indices`, `recolorear`, `textura_pieza`, `capas_base`; datos en `cenital/datos/equipo/{arquetipos,familias,joyas,paletas,variantes}.json`.

## Las 9 celdas que necesita arte

Fuente doble que coincide: `cenital/arte/equipo/ataque/PENDIENTE_DE_ARTE.md` y `manifiesto.json:hojas.*.*.pendientes`. Coordenadas [fila,columna], base cero:

| Hoja relativa a ataque/ | Celda | Dirección / pose |
|---|---|---|
| equipo_ligera_torso_ataque.png | [0,2] | frente / impacto |
| equipo_ligera_botas_ataque.png | [1,2] | derecha / impacto |
| equipo_ligera_botas_ataque.png | [3,2] | izquierda / impacto |
| equipo_media_torso_ataque.png | [0,2] | frente / impacto |
| equipo_media_botas_ataque.png | [1,2] | derecha / impacto |
| equipo_pesada_torso_ataque.png | [0,2] | frente / impacto |
| equipo_pesada_torso_ataque.png | [1,2] | derecha / impacto |
| equipo_pesada_torso_ataque.png | [1,3] | derecha / recuperacion |
| escudo_ataque.png | [0,2] | frente / impacto |

Hoy el cargador omite la pieza pendiente y **no oculta su ropa base**; evita superponer una pose de caminata mal colocada. Al rellenar una celda hay que retirar solo su pendiente correspondiente y recalcular hash/validación. Conservar las otras celdas aceptadas salvo defecto visible documentado.

Estela separada descartada del compuesto: [0,3]13px, [1,2]12px, [1,3]41px, [2,3]24px, [3,1]12px. No confundir esas cinco celdas con las nueve piezas vacías. Es una capa de efecto, no un rol de equipo.

El generador `../herramientas/arte/derivar_ataque.gd` sobrescribe la carpeta ataque/ y PENDIENTE_DE_ARTE.md. Está fuera de Linde. Antes de ejecutar otra vez, la integración debe preservar correcciones manuales como entradas externas o revisar el generador. No arreglar solo el MD generado.

## Estados: lo que existe y lo que falta

- `anim_pj.gd:estado_y_cuadro` prioriza dano > ataque > herramienta > caminar > reposo.
- `escena.gd:_cuadro_arte` deja animar caminar/ataque; todos los demás estados devuelven cuadro0. `arte_equipo.gd:comandos` implementa únicamente conjunto ataque o conjunto caminata. Por ello tener herramienta/dano en el selector **no significa ver esas animaciones** con el sistema nuevo.
- Herramienta: existe el compuesto 192×192 `arte-entregado/biblioteca_01/personaje/herramienta.png`; reutilizarlo como identidad/poses. Falta separarlo en base/capas y equipo por arquetipo, su manifiesto/cargador y efecto/herramienta que corresponda. Existe un desacuerdo pendiente: compuesto cuatro columnas frente a `catalogos.gd:ANIM_PJ.herramienta` tres cuadros totales/.3s; no inventar silenciosamente una correspondencia.
- Dano: declarado dos cuadros/.6s; no encontré hojas equivalentes en la biblioteca de personaje. Además el personaje parpadea por invulnerabilidad en `escena.gd:_dibujar_pj`; conservar regla y coordinar nueva animación.
- Caida: declarado dos cuadros, sin uso; dormir: un cuadro, sin uso, según comentario y selector actual. Producir arte no conecta estados a derrota/cama: integración debe resolver presentación sin alterar mecánica.
- Reposo actual: caminata cuadro0. No hace falta nuevo idle salvo decisión artística explícita.
- Apariencia actual: cambio de tonos sobre máscaras de piel/pelo/túnica/pantalón. No confundir variantes coloreadas de biblioteca con geometrías nuevas de peinado/ropa.
- Maren todavía usa `Apar.dibujar` en `_dibujar_npc`; no está usando el nuevo compositor aunque jugador local/remoto sí.

## Desfase documental que debe resolverse antes de entregar dos paquetes

`documentos/contrato-equipo.md` sigue afirmando que el recoloreado y la constante INVERTIR_PERFILES no existen, que torso/coraza es decisión abierta y que las hojas actuales son estáticas. Es historia anterior a la integración. El código/manifiestos actuales contradicen esas frases. Adjuntar una actualización/fe de estado y no enviar ese documento como única autoridad.

`PLAN_ESTETICA_2_SESIONES.md` reconoce caminata/equipo hechos y ataque parcial correctamente, pero 1.8 «cerrar todo» no fija nombres, hojas ni tiempos de herramienta/dano/caida/dormir. Sus instrucciones de arte aún no son un contrato de lote completo. La fuente herramienta existe y debe viajar en el paquete artístico. No volver al código de `arte-entregado/*/mapa_muestra` ni sustituir cenital por esas muestras antiguas.

## Paquete IA arte: entradas exactas y permisos

Copiar como entradas de SOLO LECTURA:

1. `documentos/LINDE_Punto_de_Inicio/referencias/visual_objetivo.png`.
2. `arte-entregado/biblioteca_01/personaje/{LEEME.md,manifest.json,ataque.png,herramienta.png,caminata.png,capas/}` y prompts/procedencia si se redistribuyen derivados.
3. `cenital/arte/equipo/` completo, incluidos manifiestos, base/capas, ataque/base, ataque/referencia y pendientes. La carpeta destino de la artista debe ser separada, no esta producción.
4. `arte-entregado/equipo_indice_01/{fuentes_arquetipos,fuentes_reutilizadas,PROCEDENCIA.md}` si existen los documentos individuales; conservar mapas de origen y evidencias.
5. `documentos/{instrucciones-recursos-arte.md,contrato-equipo.md,sistema-de-equipo.md}` con esta fe de estado; `cenital/datos/equipo/paletas.json` y manifiestos como autoridad técnica actual.
6. `../herramientas/arte/validar_hoja.gd` y `derivar_ataque.gd` como referencia/validación en copia aislada.

Salida arte: candidatos de las nueve celdas/atlas conservando todo lo aceptado; estela aparte; nuevos estados con dimensiones, pivotes, filas/columnas/tiempos acordados; índice de archivos y hashes, procedencia por recurso, vista compuesta/ciclo, validación. No scripts de juego ni cambios de colisión/datos de balance. No regenerar las 17 caminatas.

## Paquete IA integración Godot: entradas y dominio

Trabaja sobre una copia/checkout del **cenital actual** con scripts, datos, escenas y pruebas. Entradas adicionales: lote artístico congelado con hashes, manifiestos, esta auditoría y plan. Dominios: `scripts/arte_equipo.gd`, `anim_pj.gd`, `escena.gd`, manifiestos y copia de assets a `cenital/arte/`; datos de arte nuevos; registro y pruebas. `capas_sprite.gd` es fallback, no borrarlo hasta demostrar que no queda ningún consumidor. No tocar originales en `arte-entregado/`.

Responsabilidad integración: declarar/validar estados y su correspondencia de cuadros; añadir nuevo estado sin volver al procedural; mantener pivote, profundidad y oclusiones; limpiar pendientes por celda realmente sustituida; conservar caché/recoloreado/ranuras; probar local y remoto; retener capturas y ciclos. No usar resultado del validador de caminata como garantía de estado de ataque: el validador genérico exige dieciséis celdas, mientras ataque actual permite huecos declarados y tiene política específica de calidad/seguimiento.
