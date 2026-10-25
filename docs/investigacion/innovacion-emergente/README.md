# Innovación emergente en Linde

Investigación realizada el **25 de octubre de 2026**. Alcance: inspección estática del código de Linde y de archivos externos fijados por commit, contraste con documentación primaria y ejecución de la prueba existente de desarrollo cuando el entorno lo permite. No se implementan funciones ni se incorporan dependencias.

**Recomendación — Propuesta de diseño propia:** ampliar `desarrollo.gd` y la gramática de `artesania.gd` con conocimiento explícito por actor y procedencia durable. Conservar inventario, equipo, autonomía, sociedad, guardado y servidor. No hace falta un motor externo de invención ni IA generativa en tiempo real.

## Estado de esta carpeta (2026-10-25)

| Documento | Rol | Vigencia |
|---|---|---|
| [PLAN_MAESTRO](PLAN_MAESTRO.md) | **Plan activo** (único). Fases H0–S1, decisiones O1–O7, materiales, versionado, hoja de ruta | Revisión 2 (25/10); se actualiza al implementar |
| [PLAN_IMPLEMENTACION](PLAN_IMPLEMENTACION.md) | Antecedente: niveles A–D del conocimiento y la invención. Vigente salvo donde PLAN_MAESTRO §1.2 lo sustituye | Conservado como evidencia |
| [DECISIONES](DECISIONES.md) | D01–D12 con alternativas; verificación mínima | Decisiones: vigentes como *Propuesta*; verificación: 25/10 |
| [COMPATIBILIDAD_LINDE](COMPATIBILIDAD_LINDE.md) | Inventario del código con hashes | **Instantánea** de `HEAD 990d549` + árbol local; caduca con cada cambio en `desarrollo.gd`, `artesania.gd`, `sociedad.gd` |
| [BASES_TECNICAS](BASES_TECNICAS.md) | Modelo propuesto | Propuesta; no es descripción del código |
| [PRECEDENTES](PRECEDENTES.md) | Fuentes externas por SHA | Consulta del 25/10 |

**Cuándo leerla**: solo al trabajar en conocimiento, descubrimiento, invención o enseñanza de técnicas. No es lectura obligatoria de sesión. **Alcance de la verificación**: inspección estática y una ejecución de `tests/prueba_desarrollo.gd` (55 comprobaciones, 0 fallos, 25/10). No se probó ninguna función propuesta. Si el código actual contradice un texto de esta carpeta, prevalece el código verificado.

## Lectura y etiquetas

- [PLAN_MAESTRO.md](PLAN_MAESTRO.md): plan unificado de materiales, conocimiento, descubrimiento e invención, con decisiones confirmadas y hoja de ruta.
- [PRECEDENTES.md](PRECEDENTES.md): versiones, fuentes, algoritmos, licencias y límites de reutilización.
- [COMPATIBILIDAD_LINDE.md](COMPATIBILIDAD_LINDE.md): capacidades reales y puntos de ampliación, con referencias locales.
- [BASES_TECNICAS.md](BASES_TECNICAS.md): modelo propuesto, experimentación, transmisión y restricciones.
- [DECISIONES.md](DECISIONES.md): recomendaciones, alternativas, riesgos y tareas verificables para retomar.

Cada afirmación o grupo de afirmaciones usa una de estas categorías:

| Etiqueta | Significado |
|---|---|
| **Confirmado mediante código o documentación [C]** | Visible en los archivos/símbolos o fuentes citados; no implica validación en ejecución salvo indicación expresa. |
| **Inferido a partir de la investigación [I]** | Consecuencia razonada de evidencia; puede requerir medición o prueba. |
| **Pendiente de verificar [V]** | No hay evidencia suficiente, no se ejecutó o falta decisión del proyecto. |
| **Propuesta de diseño propia [P]** | Recomendación para Linde; no describe una función ya existente. |

## Hallazgos centrales

1. **[C]** Linde ya deriva diseños de forma, material, técnica y calidad; admite laminados, práctica especializada y prototipos autónomos. Véanse `artesania.gd` y `desarrollo.gd` en el inventario local. No partir de un sistema nuevo.
2. **[C]** Los planos artesanales se derivan de materiales observados, pericia y superficie del taller. El historial `creaciones` guarda actor, pieza, minuto e insumos, pero se recorta. No equivale a un registro permanente de invenciones.
3. **[I]** La carencia principal es distinguir diseño posible, diseño conocido, capacidad de ejecutarlo y evidencia de quién lo descubrió o enseñó. Se necesitan extensiones de estado y reglas, no duplicar fabricación.
4. **[C]** CDDA aporta recetas declarativas y pericias; GDQuest aporta composición de comportamientos programados. Dwarf Fortress aporta documentación conceptual de transmisión histórica, sin código inspeccionado reutilizable.
5. **[P]** Tratar la invención combinatoria como exploración acotada de reglas existentes. Una mecánica nueva —por ejemplo electricidad si el simulador no la soporta— exige programación, datos versionados y validación del servidor.

## Línea base y reproducción

**[C]** HEAD local observado: `990d5498330961349435abcc47ce42054a0e5a51`. El árbol ya tenía cambios sin confirmar en `datos/autonomia/reglas.json`, `scripts/habitantes.gd`, `scripts/sociedad.gd` y dos pruebas no rastreadas (`tests/_dbg.gd`, `tests/prueba_arraigo.gd`), todos bajo `Linde/cenital/`. La investigación lee el árbol de trabajo, no solo HEAD. Esos cambios no pertenecen a este encargo. El inventario de hashes de COMPATIBILIDAD permite detectar diferencias futuras.

**[C]** `project.godot` declara Godot 4.7; el motor local se identifica como 4.7.1 estable oficial, revisión `a13da4feb8d8aefc283c3763d33a2f170a18d541`.

**[C]** Se consultó la habilidad graphify: no había `graphify-out/graph.json`; su detección sobre `Linde/cenital/scripts` devolvió cero archivos compatibles. Se realizó búsqueda e inspección directa de GDScript. No se generó un grafo vacío ni se instaló software.

**[V]** Las fuentes externas se inspeccionaron, pero no se compilaron ni se ejecutaron sus demos. Las dependencias mencionadas son las visibles en los archivos consultados, no una auditoría transitiva completa. La prueba local y su resultado se registran en DECISIONES.

Para retomar: revisar primero el estado Git y los hashes locales, abrir los enlaces por commit de PRECEDENTES, y ejecutar los criterios de aceptación de DECISIONES antes de programar. Los enlaces por rama no sustituyen las versiones fijadas. No se modificó `ESTADO.md`.
