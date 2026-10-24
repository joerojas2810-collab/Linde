# Linde — punto de inicio del proyecto

Documento de trabajo · 23 de octubre de 2026 · revisión 1

Este paquete describe el juego que queremos empezar a construir. **No define una beta, un producto mínimo, una fecha de entrega ni un alcance cerrado.** Organiza la visión completa en sistemas y dependencias para poder implementarla por etapas sin perder el rumbo.

Linde es un nombre de trabajo. El objetivo es un RPG 2D de mundo vivo, con personaje creado por el jugador, exploración, recolección, construcción, progresión y aventuras de capítulos y de mundo. La vista es cenital oblicua, con desplazamiento arriba, abajo, izquierda y derecha.

## Cómo leer el paquete

1. [Visión y decisiones](01_VISION_Y_DECISIONES.md).
2. [Sistemas del juego](02_SISTEMAS_DEL_JUEGO.md).
3. [Narrativa](03_NARRATIVA.md).
4. [Arte y animación](04_ARTE_Y_ANIMACION.md).
5. [Arquitectura y construcción](05_ARQUITECTURA_Y_CONSTRUCCION.md).
6. [Fuentes, licencias y supuestos](06_FUENTES_Y_SUPUESTOS.md).
7. [Instrucción para Claude](PROMPT_PARA_CLAUDE.md).

Las etiquetas **Acordado**, **Propuesta** y **Pendiente** distinguen la intención expresada por el usuario, las decisiones sugeridas para poder trabajar y los asuntos todavía abiertos. Una propuesta puede implementarse de forma reversible y registrarse como tal; no debe presentarse después como una decisión del usuario.

## Qué existe y qué queremos construir

Existe un prototipo lateral en Godot, incluido como archivo histórico de código. Su cámara, gravedad, salto y terreno por columnas no representan la dirección actual. No contiene todavía todos los sistemas descritos aquí. La referencia visual cenital es una imagen conceptual, no una captura de un juego implementado ni un conjunto de sprites listo para usar.

Los documentos antiguos incluidos en evidencia describen una investigación o implementación anterior. **Estos documentos nuevos tienen prioridad para la dirección del proyecto.** Los archivos antiguos mantienen su título original para no falsear su historia.

## Contenido transportable

- `referencias/visual_objetivo.png`: referencia conceptual de estilo.
- `referencias/prototipo_lateral_actual.png`: estado anterior, para distinguirlo del objetivo.
- `codigo_base/prototipo_lateral_fuentes.zip`: código existente y sus avisos.
- `evidencia/`: inventario y verificaciones previas; sus conclusiones tienen el alcance indicado en cada archivo.

La biblioteca completa de repositorios permanece en el equipo original, en `/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/fuentes`. No está duplicada en este paquete. Un constructor en otro equipo puede obtener las revisiones indicadas en la matriz; la disponibilidad futura de los remotos no se garantiza.
