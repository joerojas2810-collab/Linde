# Linde cenital — estado, decisiones y procedencia (23 oct 2026)

El prototipo lateral (`beta/lateral`) no se tocó. Todo lo de aquí es código y arte propios.

## Ejecutar
- Jugar: `Iniciar-Cenital.command` (args tras `--`: `--guardado=ruta`, `--nueva=SEMILLA`, `--panel=inv|craft|hab|mis`, `--ir=x,y`).
- Lógica: `Godot --headless --path juego/cenital --script res://tests/prueba.gd` → 130 PASS, 0 FAIL.
- UI real (menú→creador→partida→paneles→guardar→continuar): `--script res://tests/prueba_ui.gd` → 12 PASS.
- `tests/capturas/`: fotogramas reales de la escena (casa, cantera, lago, ruinas, panel).
- Los "ERROR: Parse JSON failed" que imprime la prueba de persistencia son esperados: se corrompen archivos a propósito.

## Controles
WASD/flechas mover · Espacio golpear/atacar · E interactuar · I inventario · C fabricar · K habilidades · J misiones · B construir (Q/E pieza, Espacio colocar, X retirar) · F5 guardar · F1 cajas · Esc pausa. Autoguardado cada 30 s y al cerrar.

## Qué existe (módulos en `scripts/`)
| Módulo | Contenido |
|---|---|
| `catalogos.gd` | Ítems, objetos rompibles, construcciones, recetas, habilidades, enemigos/jefes, misiones, diálogos. `validar()` comprueba referencias, ciclos y alcanzabilidad |
| `mundo.gd` | Mapa de autor 64×48 (aldea, cantera, bosque, estanque, ruinas), objetos con ID, construcciones, colisión, BFS, inicio por semilla |
| `juego.gd` | Autoridad única: recolección, fabricación, construcción, cofres, misiones, progresión, jefes, tiempo, dormir |
| `inventario.gd` | Operaciones atómicas todo-o-nada con capacidad por pilas |
| `guardado.gd` | Formato versionado + checksum, `.tmp`→validar→`.bak`, corrupto se conserva como `.corrupta`, migraciones |
| `combate.gd` | Combate en tiempo real provisional, jefes con fases |
| `habitantes.gd` | Maren: necesidades→actividad→ruta→ejecución |
| `escena.gd`, `hud.gd`, `arte.gd`, `apariencia.gd` | Presentación, interfaz, arte procedural, PJ en capas |

## Decisiones (todas Propuesta, reversibles; ninguna es decisión del usuario)
| ID | Decisión | Dónde |
|---|---|---|
| P03 | 4 direcciones sin diagonales | `Mundo.dir_cardinal` |
| P04 | Celda 16 px, PJ 16×24, ancla en pies, zoom entero 3 | `params.gd` |
| P05 | Mapa de autor fijo; la semilla solo elige un inicio exterior alcanzable, con 3×3 libre y ≥12 celdas de enemigos/jefes | `Mundo.punto_inicio` |
| P06 | Sin avance del mundo con la app cerrada; al dormir el jugador se recoloca a Maren según su rutina (no se simula el intervalo) | `Habitantes.resincronizar` |
| — | Día = 24 min reales (1 s = 1 min de juego) | `catalogos.gd MIN_POR_SEG` |
| — | Roca a mano (10 golpes) para evitar el ciclo pico↔piedra; con pico 4 | `catalogos.gd` |
| — | Inventario 20 pilas; si no cabe el botín, el objeto no se rompe; recompensas de jefe/misión que no caben quedan pendientes, nunca se pierden ni duplican | `Inventario`, `Juego` |
| — | Botín probabilístico con flujo propio por (semilla, objeto, hora): cargar no lo cambia. Contenido del tesoro fijado al crear la partida | `Juego._rng` |
| — | Construir: huella 1×1, no sobre objetos/actores, y se rechaza si cierra un lugar esencial o encierra al jugador. Retirar devuelve 100 %; solo piezas propias; cofre con contenido no se retira | `Juego.construir/retirar` |
| — | Misiones: condiciones *actuales* (tener, construcción en pie) se miden ahora y pueden perderse; *históricas* (visita, jefe, cofre abierto, hablar) usan hechos guardados. Recompensa una sola vez (`recompensas`) | `Juego.objetivo_ok/entregar` |
| — | Habilidades: puntos = nivel−1; efectos se calculan desde las aprendidas (no se acumulan al cargar). **No hay reasignación de puntos** | `Juego.stats` |
| — | Mejor arma = el ítem con más daño en el inventario (sin ranura de equipo) | `Juego.stats` |
| — | Jefe de capítulo no reaparece; jefe de mundo reaparece a las 72 h de juego. La recompensa se da por cada derrota y se registra por clave | `Combate`, `Juego.jefe_derrotado` |

## A01 — Combate (PENDIENTE, modelo provisional)
Alternativa recomendada y usada: tiempo real, cuerpo a cuerpo hacia donde mira el PJ (aviso 0,1 s, activo 0,1 s, recuperación 0,25 s). Todo ataque enemigo tiene señal previa y recuperación; los jefes cambian de fase al 50 %/40 % con un ataque nuevo (onda/pisotón), no solo más vida. Muerte provisional: sin pérdida de objetos, vuelves a tu cama (o al inicio) con media vida y el encuentro se reinicia. Todos los números en `catalogos.gd` son placeholders sin balance.

## Procedencia
- Código, datos y arte propios. **No se copió código, tablas ni valores** de Blocktest, MineWorld, Source of Mana, Cataclysm-DDA, LibColony ni Helbreath; no hay assets de Helbreath ni Pokémon. Las tasas de MineWorld (hambre/cansancio) no se usan: la energía de Maren (−4/h, +12/h) es propia y provisional.
- La estructura de recetas (entradas, estación, herramienta, salidas) sigue la idea general de Cataclysm-DDA pero no usa su formato ni datos (CC BY-SA no aplica al no copiar).
- Arte: dibujado por código, inspirado en la referencia visual (`LINDE_Punto_de_Inicio/referencias/visual_objetivo.png`) sin copiarla. Es provisional; la hoja de estilo y los sprites finales siguen pendientes.
- Textos de diálogo y misiones (Maren, taller, cantera, ruinas, Guardián, Gran Ciervo) son **contenido de prueba**, no canon (A02 abierto).

## Límites conocidos / no verificado
- No se jugó a mano: la sensación de movimiento y combate no está afinada; solo hay pruebas automáticas y capturas.
- Un único habitante (Maren). Sin comercio ni economía (A03). Sin multijugador (A04).
- Creador de PJ mínimo (nombre, 3 pieles, 4 pelos, 3 ropas, origen, semilla); sin equipo visible ni capas de armas.
- Sin sonido. Sin animaciones de ataque ni de herramienta específicas; la caminata sí tiene 4 cuadros.
- Enemigos no persisten posición; los slimes reaparecen al cargar (simulación local).
- La carga de la partida no valida reglas de negocio más allá del checksum y el formato.

## Personaje por capas desde hojas PNG (`scripts/capas_sprite.gd`)
- Qué es: cargador opcional. Lee `res://arte/personaje.json` (`{"celda": 32, "capas": [...]}`) y una hoja `res://arte/personaje_<capa>.png` por capa. Si falta el manifiesto o alguna hoja, o una hoja no mide 4·celda × 4·celda, `disponible()` es false (con `errores` y aviso) y `escena.gd` sigue con el dibujo procedural (`Apariencia`).
- Formato de hoja: 4 columnas (cuadros de caminata 0..3) × 4 filas (frente, derecha, espalda, izquierda). Ancla = centro inferior de la celda, alineado con los pies del jugador; se dibuja con filtro nearest.
- Orden: constante `ORDEN_POR_DIRECCION` (capas de abajo a arriba por orientación). Casco, coraza, escudo y espada solo se dibujan si están en el `equipo` pasado a `dibujar` (hoy `[]`, el equipo aún no es visible). Espalda usa el mismo orden que frente.
- Lateralidad (sin resolver): se supone que al mirar a la derecha se ve el costado derecho (escudo detrás, espada delante). Para invertirla, intercambiar las listas de `Vector2i.RIGHT` y `Vector2i.LEFT` en esa constante.
