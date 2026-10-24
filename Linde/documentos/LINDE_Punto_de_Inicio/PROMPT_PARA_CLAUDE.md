# Instrucción para Claude

Quiero que empieces a construir un RPG 2D de mundo vivo a partir de este paquete. Es un **punto de inicio del proyecto**, no una especificación de beta ni un alcance cerrado. No conviertas este encargo en una planificación de beta.

Lee primero `00_LEEME.md` y después los documentos numerados. Distingue Acordado, Propuesta y Pendiente. Utiliza las propuestas reversibles para avanzar y registra las decisiones nuevas; no las atribuyas al usuario ni afirmes que existe una historia definitiva.

El objetivo es vista cenital oblicua, pixel art sencillo y navegación arriba/abajo/izquierda/derecha. PJ personalizable; inicio aleatorio seguro; recolección y objetos rompibles; construcción; árbol de habilidades; misiones de capítulos y de mundo; tesoros, recompensas y jefes de ambos tipos. Narrativa original inspirada en oficios/progresión, exploración, comunidad y aventura de las referencias descritas, sin copiar sus universos.

La referencia en `referencias/visual_objetivo.png` es conceptual. La base de código adjunta es lateral y debe conservarse como referencia; no digas que ya implementa el juego cenital. Extrae `codigo_base/prototipo_lateral_fuentes.zip` e inspecciónalo antes de reutilizar. En el equipo original hay más fuentes en `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/fuentes`; si esa ruta no existe, usa la matriz de commits para localizar lo necesario. El paquete no incluye la biblioteca completa ni un motor instalado transportable.

Construye en una carpeta nueva. Comprueba el motor disponible y empieza por una escena ejecutable que demuestre movimiento cenital, colisiones, escala y apariencia. Después conecta estado, persistencia e interacciones siguiendo dependencias. Implementa y verifica trabajo concreto en cada etapa; no te limites a devolver otro plan. El orden de trabajo no limita la visión del proyecto.

Prioriza reutilizar reglas y código verificables. Revisa licencia por archivo y conserva avisos. No utilices assets propietarios de Helbreath ni recursos de Pokémon. No combines servidores completos ni copies fórmulas sin sus dependencias. Los valores nuevos deben centralizarse y marcarse como provisionales con unidades y motivo. Los valores heredados no equivalen a balance probado para este juego.

No inventes credenciales, pruebas ejecutadas, sistemas implementados, fechas de entrega ni aprobaciones del usuario. Si una decisión pendiente bloquea un contrato esencial —por ejemplo, el modelo de combate— explica brevemente la alternativa recomendada y sigue con trabajo independiente mientras se decide. No cierres canon narrativo para poder probar movimiento o inventario.

Entrega código ejecutable, instrucciones reales para abrirlo, registro de decisiones/procedencia y una explicación breve de lo construido, lo probado y lo pendiente. Comprueba las funciones relevantes indicadas en `05_ARQUITECTURA_Y_CONSTRUCCION.md` cuando existan. Mantén los documentos actualizados conforme cambie el proyecto.
