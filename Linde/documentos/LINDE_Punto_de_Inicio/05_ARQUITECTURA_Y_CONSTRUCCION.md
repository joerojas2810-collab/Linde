# Arquitectura y guía de construcción

## Estado real del código

El archivo incluido contiene un prototipo **lateral** en Godot. Implementa movimiento y salto, edición de bloques, necesidades, una rutina simple de Ada, una pequeña misión y guardado local. La entrega anterior registró 31 comprobaciones automatizadas aprobadas. Es evidencia histórica de ese código, no validación del juego cenital ni de una migración futura.

No están implementados en esa base el creador de PJ, el combate RPG, el árbol de habilidades, los jefes, la campaña ni la navegación cenital. No confundir tener repositorios descargados con tener sus módulos integrados.

## Base técnica propuesta

Continuar con Godot y GDScript para aprovechar el trabajo local. La instalación usada en el equipo original es Godot 4.7.1; verificar compatibilidad en el entorno de construcción. Empezar como aplicación local para un jugador, una propuesta técnica reversible mientras se decide si habrá red.

Conservar el prototipo anterior y crear un proyecto o carpeta independiente, por ejemplo `Linde/cenital`. No reemplazar el lanzador existente hasta disponer de una ejecución comprobada. Si el constructor tiene solo el paquete, extraer el archivo de código en una carpeta de referencia y crear el nuevo proyecto a su lado.

## Responsabilidades

| Módulo propuesto | Responsabilidad |
|---|---|
| Catálogos | Definiciones de objetos, recetas, habilidades, misiones y encuentros |
| Estado de mundo | IDs, regiones, objetos, construcciones y cambios persistentes |
| Generación | Semilla, versión y validación de puntos iniciales |
| Actor | Entrada, desplazamiento, colisiones y acciones |
| Apariencia | Capas del PJ y animación, sin decidir recompensas |
| Inventario y fabricación | Transacciones y requisitos |
| Construcción | Validación de huella y modificación del mundo |
| Progresión | Desbloqueos y aplicación derivada de efectos |
| Misiones | Condiciones, estados y entregas únicas |
| Encuentros y combate | Estados de enemigos, daño y resolución |
| Habitantes | Objetivos, actividades, navegación y horarios |
| Persistencia | Validación, versiones, migración y respaldo |
| Presentación | Cámara, UI, sonido y efectos |

Son límites de responsabilidad, no una obligación de crear un archivo por fila. Mantener una autoridad única sobre inventario y mundo. La UI solicita acciones y muestra resultados; no concede recursos por su cuenta.

## Modelo espacial

Separar coordenadas de celda y posición en píxeles con conversiones explícitas. Separar suelo, colisión, objetos interactuables y elementos dibujados por encima. Para navegación, utilizar una representación actualizable de celdas transitables o una alternativa equivalente verificada en Godot.

La construcción y destrucción actualizan navegación y colisión coherentemente. Las entradas a interiores o cuevas necesitan destinos válidos y retorno seguro. No trasladar gravedad, impulso de salto ni generación por columnas del lateral.

## Contratos de datos

Todas las entidades persistentes tienen IDs estables; los catálogos usan referencias verificables. Cada partida declara versión de formato y de contenido. Separar definición de un árbol de sus instancias y de sus cambios. Conservar resultados de botín, recompensas otorgadas y desbloqueos para evitar duplicaciones.

Centralizar parámetros con unidad, procedencia y estado: heredado sin cambios, adaptado, provisional o validado localmente. Un cambio de escala temporal obliga a revisar consumo de necesidades, regeneración y horarios de manera conjunta.

## Orden de construcción por dependencias

1. Inspeccionar código y fuentes disponibles; registrar qué se reutiliza y bajo qué condiciones.
2. Probar escala visual, cuatro direcciones, colisiones y apariencia compuesta en una escena pequeña.
3. Conectar estado de mundo, inicio aleatorio seguro y guardado versionado.
4. Conectar recolección, inventario y construcción con persistencia.
5. Añadir fabricación y progresión a partir de contratos y reglas documentadas.
6. Resolver combate; integrar enemigos y encuentros con estados y recompensas.
7. Conectar misiones, capítulos y habitantes a eventos y condiciones reales.
8. Expandir contenido y comportamiento a partir de lo comprobado.

Este orden expresa dependencias, no un límite de contenido ni una definición de beta. No establece duración ni cifras de producción.

## Comprobaciones que deben acompañar las funciones

- Las cuatro direcciones permiten rodear edificios; tejados y sprites no crean colisiones falsas.
- Un conjunto documentado de semillas produce puntos iniciales transitables con salida; guardar y cargar conserva el mismo mundo modificado.
- Recoger, fabricar, construir y retirar conservan recursos según sus reglas; el inventario lleno tiene una respuesta definida.
- Cambiar una construcción actualiza las rutas; un NPC no atraviesa una pared nueva.
- Una habilidad no se aplica dos veces al cargar y los requisitos no forman bloqueos involuntarios.
- Una misión distingue condiciones actuales de hechos pasados y entrega cada recompensa una sola vez.
- Un cofre conserva su resultado; un jefe derrotado conserva el estado y respeta su política de reaparición.
- Un guardado interrumpido o inválido tiene recuperación comprobada.
- Las combinaciones de apariencia mantienen anclajes y orientación en las animaciones disponibles.

Añadir pruebas cuando exista comportamiento concreto y riesgo real. No escribir comprobaciones que solo repitan constantes sin verificar su efecto.
