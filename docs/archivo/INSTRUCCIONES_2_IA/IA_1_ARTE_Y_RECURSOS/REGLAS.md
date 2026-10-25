# Reglas de trabajo y autoridad

Lee primero `contexto/proyecto/CLAUDE.md`, `project.yaml`, `.claude/docs/coordination-rules.md`, `.claude/docs/coding-standards.md`, `.claude/docs/workflow-modes.md`, `.claude/docs/error-recovery-protocol.md`, `.claude/docs/run-and-observe.md`, las reglas de `.claude/rules/` aplicables y `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`. Se incluyen copias originales: este resumen no las sustituye. Lee el plan y las dos auditorías antes de proponer cambios.

## Instrucciones expresas del usuario

- Reutilizar el arte creado siempre que sea posible, sin rehacer recursos aceptados.
- Arte pixel sencillo y legible; vista cenital oblicua con tejados y fachadas, movimiento arriba/abajo/izquierda/derecha. La imagen visual_objetivo.png es la referencia artística, no una especificación automática de tamaños.
- El personaje es personalizable. Mantener el equipo, sus capas, familias y variantes actuales.
- Se autoriza utilizar agentes por sección para acelerar. Arte e integración en Godot forman parte del trabajo; no reducir la entrega a una propuesta sin archivos.
- Comprobar antes de afirmar. Diferenciar hecho, parcial, pendiente y supuesto. Entregar evidencias y registrar límites. No inventar aprobaciones de usuario ni resultados de pruebas.
- Este encargo es un punto de inicio del proyecto; no convertirlo en una definición nueva de beta ni cambiar narrativa, balance o reglas por decisiones estéticas.

## Colaboración, agentes y propiedad de archivos

El ciclo original es pregunta → opciones → decisión → borrador → aprobación. CLAUDE.md contiene la regla de pedir autorización de escritura y excepciones; conservarla y aplicarla junto con la autorización concreta que el usuario dé en la sesión. Un permiso previo claro no requiere inventar otra aprobación; una pregunta sin respuesta no autoriza nada. La preparación de estos paquetes ya fue solicitada. La ejecución futura debe respetar el alcance que el usuario autorice al enviar el paquete.

Jerarquía: coordinación → responsable de dominio → especialista. Consulta horizontal no permite imponer decisiones ni editar otro dominio. Conflictos técnicos al responsable técnico, visuales al director de arte; alcance/creatividad no resueltos al usuario. Propagar decisiones por coordinación. Ningún agente se atribuye aprobación de otro ni del usuario.

Antes de delegar: asignar objetivo, entradas, carpeta exclusiva de salida, archivos prohibidos, pruebas, criterio de aceptación y formato del informe. Paralelizar solamente tareas independientes. Especialistas recomendados: escenario, personajes/equipo, enemigos/efectos e interfaz para arte; render/composición, UI, pruebas/red y QA para integración. El coordinador conserva la responsabilidad de revisar todos los resultados. No asignar dos escritores a un archivo; serializar integración. No fijar modelos ni activar Agent Teams experimental automáticamente. Si el entorno no dispone de agentes, informar y ejecutar por secciones sin simular delegación.

Cada agente informa archivos cambiados, comprobaciones ejecutadas y resultados, incertidumbres y bloqueos. Mantener checkpoint y decisiones, cerrar todos los subtrabajos y recoger fallos. No realizar commits, publicación ni acciones externas sin la instrucción correspondiente. No sobrescribir trabajo concurrente. Las definiciones originales de roles, reglas, habilidades y hooks se adjuntan como contexto: no se afirma que estén instalados o activos en otra IA ni se ejecutan automáticamente al descomprimir.

## Límites técnicos

Proyecto activo `Linde/cenital`, Godot4.7.1/GDScript. El directorio genérico de las plantillas no cambia esta ruta. Las copias mapa_muestra son históricas y no deben reemplazar el juego. Preservar guardados, protocolo de red, mecánicas, alcance, colisiones, costes, tiempos y balance. No introducir lugares transitables nuevos para conseguir una captura bonita.

No borrar fallbacks/helpers hasta reemplazar todos sus consumidores. Validación estructural no equivale a calidad visual. No declarar eliminación del procedural por una búsqueda de draw_*: revisar rutas activas y una lista explícita de dibujo técnico permitido. No tratar todo código de tintado, barra o telegráfico como arte antiguo.

Las fuentes históricas pueden estar desactualizadas: `ESTADO_VERIFICADO.md` y los manifiestos/código de la instantánea explican las discrepancias, conservando las reglas originales. Si el proyecto real cambió después del paquete, comparar hashes y actualizar el diagnóstico antes de aplicar un parche.
