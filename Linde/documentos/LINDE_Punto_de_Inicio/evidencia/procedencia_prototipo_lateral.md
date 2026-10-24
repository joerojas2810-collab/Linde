# Procedencia de la beta lateral

Revisiones fijadas de los donantes:

- Blocktest Unity: ce515c28e84765cc561b41fc3a211a2f8f4cd168.
- Blocktest MonoGame: d7f92fedf52e444870abf1ffbd4ed8be929ce368.
- MineWorld: af5c27e78b76d4fbb64a2f845f604ffa47ad0f64.

## Reutilización concreta

| Elemento | Origen | Adaptación |
|---|---|---|
| Movimiento horizontal, salto, suelo/pared | Blocktest Unity PlayerController.cs y Player.prefab | GDScript CharacterBody2D; velocidad 7 unidades/s e impulso 17 con masa 1, valores serializados del prefab, no los defaults del script |
| Gravedad y cuerpo | Physics2DSettings.asset y Player.prefab | 9.81 × gravityScale 5; collider 0.7 × 1.8 unidades; conversión de 1 unidad a 24 px; eje y invertido |
| Capas de bloques y edición | Unity BuildSystem.cs; MonoGame TilemapShared.cs | Dos arrays independientes; primer plano colisiona; límites, inserción y borrado; sin portar networking |
| Dimensiones de mundo | MonoGame WorldState.cs | 100 × 60 celdas |
| Generación por columnas | Unity WorldGen.cs | Expresión .875 + ruido/8 y estrato stonePercentage 80; FastNoiseLite Perlin remapeado a [0,1]; no produce el mismo terreno que Unity para la misma semilla |
| Texturas de cinco bloques | Blocktest Unity Assets/Resources/Sprites/Blocks | Copias sin modificar. Atlas toma 8 px centrales del sprite de smoothing de 12 px, según metadatos y código del donante |
| Necesidades | MineWorld systems/needs y configuración Market Town | Hambre +120/h despierto, +30/h dormido; cansancio +60/h despierto, -125/h dormido; escala 0–1000, niveles iniciales 300/700 |
| Efecto del pan | MineWorld worlds/market-town/items/bread.yaml | Restauración de hambre 500 |

Licencias MIT y avisos de los donantes se preservan en upstream/. Todos los originales completos y licencias por recurso permanecen en la carpeta principal. El código adaptado de Blocktest conserva esta atribución; no se atribuye a MineWorld el sistema de guardado propio.

## Decisiones locales del prototipo, todavía sin balance validado

Son autoría de esta beta: escenario del refugio y cueva, dos huecos de techo, NPC Ada y cuaderno, ración única de bienvenida, control de disponibilidad del objetivo, inventario conservativo, alcance 4.5 tiles, intervalo de herramienta .16 s, velocidad NPC mitad de la del jugador, horario nocturno 19–06, compresión 1 segundo real = 1 minuto del mundo, límites de guardado, auto-guardado 30 s, soporte adyacente al construir, actualización de colisiones por columna, cámara, interfaz y personajes dibujados por código.

Esas cifras definen un corte de prueba; no se presentan como reglas verificadas de los juegos originales. No hay estadísticas de combate inventadas ni importación parcial de fórmulas Source of Mana en esta versión. La física está adaptada entre motores; conservar los parámetros no garantiza trayectorias idénticas a Unity.

## Recursos originales nuevos

Personajes, montañas, copas de árboles, sol, lámparas, cofre y HUD están dibujados por código. No se usó arte de Terraria, ni recursos propietarios de Helbreath, ni recursos artísticos de Source of Mana.
