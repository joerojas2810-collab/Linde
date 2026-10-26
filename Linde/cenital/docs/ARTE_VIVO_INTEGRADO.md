# Arte vivo e interfaz integrados

La escena principal usa scripts/arte_entornos.gd y scripts/hud_vivo.gd, con ui_viva.gd. No requiere las carpetas de muestras.

## Acabado
Cinco biomas exteriores (bosque, pradera, sierra, secano, ribera), valle, cantera, ruinas e interior. Se conservan terreno, recursos, colisión, densidad de vegetación, personaje, cámara 3x y luz nocturna. Paletas por entorno, decoración agrupada, sombras de contacto y atlas original de objetos dibujado con más detalle; agua animada con tinte coherente en sus 47 conexiones. Enemigos y fauna conservan su arte actual.

## Interfaz
Mochila en cuadrícula de veinte celdas con paginación, siete ranuras de equipo, vista del personaje con sus capas reales, ficha de selección y acciones existentes. Navegación con flechas, Enter y ratón; cerrar con Esc o botón. Se conservan Nunito y Lora, ahora con más margen, centrado por métricas y elipsis en textos largos. HUD con cifras de vida/XP separadas de sus barras; indicadores de mundo ocultos mientras está abierto el inventario.

## Procedencia
arte/mundo/vivo/objetos_originales.png y atlas.json proceden sin cambios de Linde/arte-entregado/biblioteca_01/escenario/originales/objetos.png y config.json. Se reutilizan los iconos E06 y viajero071. Paneles y detalles ambientales se dibujan en Godot; no se añadieron generaciones de imágenes para esta integración.

## Comprobación breve
Ejecutar tests/revision_visual_integrada.gd con render gráfico y opcional -- --salida=<carpeta>. Verifica en la escena principal equipar/quitar, usar ungüento, navegación, última página, ayuda y disponibilidad de recursos; genera capturas de revisión con guardado aislado. La galería aprobada cubrió diez vistas (incluida noche) y verificó que el dibujante no modifica el estado persistente. No se repitieron suites generales ni pruebas de red. Persisten avisos de objetos y recursos en uso al cerrar Godot (28 ObjectDB y 12 recursos en esta revisión sobre 86ae9e2).

## Actualización de base
Se incorporó 86ae9e2 antes de publicar. Se conservan solares, casas, campos, puestos, minerales y orden estable de dibujo. La presentación hereda los nuevos tejados, puertas y cultivos de mundo_arte.gd. Prueba de orden de dibujo: 6 comprobaciones aprobadas.

## Estado de aprobación (25/10)
El usuario aprobó **provisionalmente** el estilo visual mostrado en las cinco capturas (escenario, vegetación, HUD, mochila, equipo, marcos, botones y barras). Los dibujos por código de `arte_entornos.gd`, `hud_vivo.gd` y `ui_viva.gd` (49 llamadas) son excepciones específicas registradas en [DECISIONES](DECISIONES.md#excepciones-de-dibujo-por-código-usuario-2510-provisional) y controladas por función en `tests/prueba.gd`. «Se dibujan en Godot» describe lo existente, no un método para arte nuevo: el arte nuevo usa sprites y recursos gráficos.

## Integración visual A1–A3 · 25/10/2026

Implementada en la rama aislada `codex/visual-a1-a3`, base `90fd16c`, e integrada en `main` con I1a E0–E4 el 25/10/2026 por instrucción del usuario. Auditoría de Codex: A2 y A3 aprobadas para el alcance visual local demostrado; cobertura adicional de camas y multijugador pendiente. A4/A5 quedan fuera de esta integración.

- **A1:** `hacha_cobre` y `pico_cobre` reutilizan los iconos actuales de hacha/pico; nombre y material permanecen reales. Mapa y hash del manifiesto actualizados, preservando la procedencia E06. Los otros siete identificadores sin icono continúan pendientes.
- **A2:** la presentación autoritativa local conserva la herramienta de una extracción aceptada, incluido estaño, objetivo bajo los pies y golpe final. Rechazos no muestran una herramienta utilizada. No cambia extracción, inventario ni balance; los clientes conservan su comportamiento previo, sin ampliar el protocolo.
- **A3:** `dormir` y `sin_cama` seleccionan la pose acostada existente; `descansar` usa reposo y el desplazamiento conserva caminata. En la primera entrega se mantuvieron posición lógica, escala y orden de dibujo; la corrección posterior proyecta visualmente al durmiente sobre el colchón, como se detalla abajo. Las oclusiones existentes se conservan.

Verificación: [prueba específica](../tests/prueba_integracion_visual_a.gd), 60 comprobaciones sin fallos; nueve suites distintas de regresión sin fallos (802 comprobaciones contando la específica final). [Arnés de evidencia](../tests/captura_integracion_visual_a.gd), con `--salida=<directorio aislado>`, captura antes/después y secuencias sobre estados QA reproducibles. La primera lectura puede inicializar datos diferidos heredados; tras calentamiento el render no modifica el estado persistente. Persisten avisos de recursos retenidos al cerrar.

No se generaron sprites ni se cambiaron PNG, SVG, fuentes o shaders. No se implementaron A4/A5, nuevas actividades, tiempos productivos ni cambios a fabricación. La evidencia de esta sesión se conserva fuera del repositorio en `/tmp/linde-visual-a1-a3/`.


### Corrección visual posterior A2–A3 (25-10-2026)

- La presentación del durmiente se proyecta sobre su cama asignada existente solo con actividad efectiva `dormir` y adyacencia lógica. Cabecero al norte, según el único sprite de cama actual. Cabeza/cuerpo reutilizados y cobija/piecero recortados del atlas existente; sin sombra de personaje en el suelo. Despertar y `sin_cama` usan de nuevo los pies lógicos. No se cambia la asignación, ruta, posición, energía ni rutina.
- Profundidad del durmiente respecto a la cama; fachada, paredes, otros actores y techos siguen participando en el orden normal. No se añade una capa global encima de los techos.
- Herramientas: mano delantera en los perfiles, misma pose para todos los recursos que usan cada categoría. Únicamente el útil se repite en la profundidad del objetivo golpeado cuando este queda por delante. El cuerpo conserva su profundidad. El follaje que intersecta el área del útil durante una acción aceptada usa la atenuación existente del 40%; los troncos y obstáculos ajenos no se convierten en transparentes.
- Pruebas específicas: `prueba_correcciones_a2_a3.gd`. Evidencia reproducible: `captura_correcciones_a2_a3.gd`, 540 fotogramas consecutivos por versión, 9 secuencias, paso de simulación de 0,05 s. El ciclo comienza a las 05:57 con energía alta: aproxima, duerme y despierta al pasar naturalmente a las 06:00. Las cinco extracciones terminan con agotamiento comprobado; cuatro accesos transitables a (62,-128) y un caso con vegetación en (-56,-128), semilla 123. No se retira vegetación para estas capturas. Escenarios QA en memoria, sin usar partidas del usuario.
- Alcance: tres scripts de presentación (`escena.gd`, `arte_entornos.gd`, `viajero071.gd`), dos scripts QA y esta nota. No hay cambios en fabricación, balance, inventario, simulación, navegación, arte binario o protocolo. Integrado desde `codex/visual-a1-a3`, conservando el desarrollo I1a E0–E4. A4/A5 siguen pendientes.
- Límite deliberado: rocas, paredes y troncos ajenos pueden ocultar parcialmente el útil. Se conserva esa oclusión física. Las camas no tienen variantes giradas en los datos actuales. La entrada/salida de cama es una transición inmediata de presentación al cambiar el estado efectivo; no se añade una acción ni una duración artificial para acostarse.
