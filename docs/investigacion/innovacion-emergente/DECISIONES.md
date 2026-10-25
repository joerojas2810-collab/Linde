# Decisiones recomendadas y continuidad

> **Vigencia (consolidación documental, 2026-10-25)**: investigación verificada contra el árbol de trabajo en `HEAD 324f339` el 25/10/2026 (alcance: inspección estática; ver [README](README.md)). **No describe necesariamente el código posterior**: el árbol tenía cambios sin confirmar de otras sesiones (`habitantes.gd`, `sociedad.gd`, `autonomia.gd`, `escena.gd`, `mundo_vivo.gd`, `arraigo.gd`). Si el código verificado la contradice, prevalece el código y hay que corregir este texto. Estado del juego: [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md). Registro de decisiones: [DECISIONES del proyecto](../../../Linde/cenital/docs/DECISIONES.md).

**[P]** Estas son recomendaciones documentales para decidir una futura implementación; no constituyen autorización para cambiar el juego, sus licencias ni su protocolo.

## Registro de decisiones

| ID | Decisión propuesta [P] | Evidencia / motivo | Alternativa evaluada |
|---|---|---|---|
| D01 | Ampliar `desarrollo.gd`/`artesania.gd`. | [C] Ya integran piezas, práctica, materiales y prototipos con equipo y guardado. | Motor nuevo de crafting: duplicaría rutas y migraciones. |
| D02 | Reutilizar patrones de CDDA mediante código propio. | [C] Separa recetas, pericias y referencias; C++ acoplado y licencia CC BY-SA 3.0 con excepciones. | Copiar/portar módulos: compatibilidad y coste no resueltos. |
| D03 | Usar GDQuest como referencia de composición; no integrar sus escenas ahora. | [C] Sus módulos combinan comportamientos programados; no modelan investigación. | Importar armas modulares: cambiaría combate sin resolver transmisión. |
| D04 | Usar DF solo como precedente conceptual documentado. | [C] Notas oficiales históricas sobre aprendizaje y preservación; sin código inspeccionado. | Presentarlo como tecnología incorporable: carece de evidencia. |
| D05 | Conocimiento explícito separado de ejecución y práctica. | [C] `conoce` mezcla conocimiento y superficie de taller; los planos son derivados. | Guardar solo el resultado de `planos`: perdería significado al cambiar entorno o rango. |
| D06 | Mantener objetos canónicos y guardar procedencia aparte. | [C] Inventario agrupa por clave; historia recortada a 64 creaciones. | Autor dentro de cada clave: fragmenta pilas e identidad funcional. |
| D07 | Primer prototipo con progreso determinista y operadores acotados. | [I] Simplifica repetición, guardado y validación de costes. | Fracaso aleatorio desde el principio: más estado y balance antes de demostrar utilidad. |
| D08 | Enseñanza directa antes que libros individuales u olvido. | [C] Ya existen proximidad, relaciones, recuerdos y práctica. | Biblioteca/identidad por ejemplar primero: exige más cambios de inventario y permisos. |
| D09 | Conservar autoría histórica aunque no haya portadores accesibles. | [I] Un registro histórico no debe actuar como receta universal disponible. | Borrar el diseño al perder su último portador: rompería objetos y referencias antiguas. |
| D10 | Servidor resuelve todo y proyecta visibilidad. | [C] La réplica no simula; `mundo_vivo` se envía completo actualmente. | Ocultar secretos solo en la UI: los datos seguirían presentes en clientes. |
| D11 | No añadir dependencias ni IA generativa como requisito. | [C] Los contratos actuales son GDScript/JSON y bastan para la gramática acotada. | Motor externo, LLM o base de grafos: necesidad no demostrada. |
| D12 | Mantener `art1:`/`mat1:` y reglas v1 congeladas. | [C] Propiedades se recalculan desde reglas; cambiar JSON puede alterar piezas viejas. | Rebalancear v1 en sitio: necesitaría política explícita de migración y de compensación. |

## Riesgos y decisiones abiertas

| Riesgo [I] | Evidencia base [C] | Acción previa recomendada [P] |
|---|---|---|
| Copia incompatible de terceros | Licencias diferenciadas; licencia global de Linde no establecida por esta inspección. | Revisar archivo, versión, origen, excepciones, uso previsto, atribución y distribución antes de copiar. La carpeta `licencias/` no es una auditoría suficiente. |
| Conocimiento privado filtrado | `estado_para` y sección fiable comparten `mundo_vivo`. | Diseñar proyecciones por cliente antes de introducir secretos. |
| Atribución histórica incompleta | `creaciones` y recuerdos recortables; no toda fabricación pasa por `_creacion`. | Registro durable separado y cobertura de cada ruta confirmada. |
| Reaprendizaje automático indeseado | `restaurar` observa inventarios; comprar expone materiales. | Especificar qué aprende cada ruta y cómo convive con pérdida. |
| Sesgo de candidatos/planificación | Orden de planos y límites de decisiones. | Medir reparto por NPC y usar desempates/cursor reproducibles. |
| Saturación de red y guardado | Se serializa/compara sección y se replica entera al cambiar. | Medir y agrupar actualizaciones; índices y deltas solo donde aporten. |
| Nueva mecánica disfrazada de combinación | La gramática solo evalúa operadores existentes. | Requerir implementación y pruebas para nuevas familias de efectos. |
| Estado activo en evolución | Cambios locales ajenos al encargo durante la investigación. | Comparar hashes y revisar integración de arraigo antes de implementar. |

**[V]** Política de atribución para descubrimientos simultáneos, coautoría, secreto comercial, coste de enseñanza, pérdidas por muerte, continuidad de jugadores desconectados y calidad como identidad cultural: pendientes de decisión. [BASES_TECNICAS](BASES_TECNICAS.md) propone valores de partida, no reglas aprobadas.

## Secuencia de trabajo futura

Cada fase debe tener una revisión concreta antes de ampliar la siguiente. Ninguna se ejecuta en este encargo.

1. **[P] Congelar contrato y migración.** Elegir identidad de diseño, conocimiento inicial legado, versión de reglas y visibilidad. Enumerar llamadas desde fabricación estática, prototipos, refinado, compra, restauración y NPC. Aceptación: partidas viejas conservan objetos, práctica y capacidades previstas, sin autores inventados.
2. **[P] Registro cultural mínimo.** Guardar primer descubrimiento y aprendizajes posteriores fuera de buffers narrativos. Aceptación: recortar recuerdos o superar 64 creaciones no altera autoría; mismo diseño deduplica definición, conserva eventos independientes y ordena empates en servidor.
3. **[P] Experimentos sobre gramática actual.** Candidatos acotados, excedentes y progreso guardado. Aceptación: dos NPC con materiales/necesidades distintos pueden elegir distinto; hambre y descanso prevalecen; rechazo no consume ni entrena; cargar a mitad no repite gasto o recompensa.
4. **[P] Enseñanza directa.** Portador competente, receptor elegible, proximidad, tiempo y evento causal. Aceptación: receptor aprende diseño sin heredar pericia ni recibir producto; repetir/reconectar no duplica aprendizaje. NPC→NPC, NPC→jugador y jugador→NPC usan validaciones equivalentes.
5. **[P] Profesión reconocida.** Derivar especialidad de práctica/técnicas con estabilidad, conservar oficio de abastecimiento. Aceptación: título refleja acciones y no regala capacidad ni cambia cada minuto; se conserva tras reinicio.
6. **[P] Libros y pérdida accesible, opcionales.** Solo tras resolver copias/instancias y permisos. Aceptación: copia conserva procedencia, destruir una no borra aprendices, salida/regreso de portador cambia acceso local sin borrar historia, y técnicas básicas tienen recuperación.

## Verificación mínima antes de integrar

**[P]** Reutilizar `tests/prueba_desarrollo.gd`, pruebas de red y guardado existentes. Agregar únicamente pruebas de contratos nuevos:

- Reproducir dos veces una secuencia de intenciones y comparar estado cultural canónico; también guardar/reanudar en el punto intermedio.
- Cambiar orden de inserción de diccionarios sin cambiar la resolución de candidatos; mantener reglas/algoritmo de versión fija.
- Rechazar diseños incompatibles, calidad/pericia adulterada, enseñanza a distancia, autor enviado por cliente, progreso negativo y versiones desconocidas.
- Competencia por último insumo/soporte o reserva de estación: una sola confirmación y conservación de recursos.
- Separar primera invención mundial, aprendizaje individual y mejora de calidad; no duplicar recompensa por variaciones sin novedad técnica.
- Migrar partida sin subestado, con creación vieja sin autor verificable y con NPC ausente; segunda carga no suma progreso.
- Red real con dos clientes más servidor: secreto no aparece en bytes del receptor sin permiso; no basta esconderlo en pantalla.
- Comparar rendimiento con 1, población habitual y máximo configurado de NPC; clientes 1 y 15. Medir p95/max tick, bytes/s, guardado y carga; sostener varias jornadas y cambiar de taller.

**[V]** No se fijan milisegundos o tamaños máximos sin presupuesto de rendimiento del proyecto. Comparar con línea base y acordar umbrales antes de optimizar. La instrumentación `red_servidor` ya registra tiempos y bytes, pero este encargo no produjo un benchmark de carga.

## Resultado de verificación en esta investigación

**[C/ejecución]** Comando reproducible desde la raíz del repositorio:

```sh
herramientas/runtime/Godot.app/Contents/MacOS/Godot --headless \
  --log-file /tmp/linde-desarrollo-investigacion.log \
  --path Linde/cenital --script res://tests/prueba_desarrollo.gd
```

**[C]** Resultado: 55 comprobaciones, 0 fallos, exit code 0. En tres días simulados: 4 creaciones y 8 suelos. También se observaron avisos de certificados, 111 instancias y 13 recursos pendientes de liberar al salir. Primer intento sin ruta de log explícita: error de acceso a `user://logs` y señal 11; se resolvió para esta ejecución usando `--log-file` dentro de `/tmp`. No se cambió código para ejecutar la prueba.

**[V]** No se ejecutaron builds externos, prueba de estrés, conexiones ENet reales, auditoría legal ni pruebas de funcionalidades propuestas. La simulación existente confirma las capacidades que evalúa en el momento de ejecución, no el diseño futuro completo ni cambios concurrentes posteriores.

## Lista para retomar sin perder contexto

**[P]** Abrir README y comparar hashes; revisar cambios locales de otras sesiones; recuperar fuentes por SHA de PRECEDENTES; decidir D05/D06/D10 y migración; preparar primero un contrato pequeño de conocimiento/autoría. No comenzar copiando CDDA ni importando escenas GDQuest. Cualquier cambio al juego, dependencia o `ESTADO.md` requiere un encargo posterior dentro de su alcance.
