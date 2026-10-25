# Estado verificado — 24/10/2026

Auditoría de archivos y evidencias existentes, no ejecución nueva de suites. Los detalles y fuentes están en `auditorias/`. No extrapolar los 159 tests de mapa_muestra al juego actual ni repetir un contador anterior sin correr pruebas.

| Área | Ya existe | Falta realmente |
|---|---|---|
| PJ y equipo | Caminata base y 17 hojas integradas; cinco ranuras de set + escudo; espada desde inventario; recoloreado por índices CPU/caché y familias; INVERTIR_PERFILES | Comprobar mano lejana y oclusiones; decidir cinturón/pelo con muestra |
| Ataque | Compositor y avance de cuadros activos; 17 hojas derivadas | Nueve celdas declaradas vacías y estela separada; QA de todas direcciones |
| Otros estados | Herramienta compuesta entregada; estados declarados en código | Separación/equipo/herramienta y mapeo 4 poses fuente→3 cuadros actuales; daño; presentación caída/dormir |
| Mundo | Biblioteca de 36 PNG y ejemplo aislado | Integración al juego activo, conexiones de terreno, agotados, vallas y casa modular alineada |
| Enemigos y NPC | Tres atlas enemigos estructuralmente válidos | Integración, daño/muerte/recuperación, Maren con sprite/dirección |
| UI | 37 PNG, escudo genérico, panel nueve regiones | HUD real, cantidades/foco, iconos por ID, XP/diálogo/menú y tipografía licenciada |
| Estilo | Referencia y recursos reutilizables | Paleta aplicada coherente, escala y densidad de píxel verificadas en escena, luz/sombras/efectos |

El contrato histórico aún dice que recoloreado y constante de perfiles no existen: eso ya cambió. Torso ya tiene correspondencia. No repetir ese trabajo. El cinturón hoy permanece y el pelo se dibuja bajo el casco: comportamiento actual no equivale a decisión artística cerrada.

Celda de mundo16; colisión pies10×6; caminata atlas128×128, celdas32×32, pivote[16,32]; ataque atlas192×192, celdas48×48, pivote[24,48]; zoom3 nearest. SPRITE16×24 nominal no impone dimensiones a los PNG. Objetos48 y edificios96 requieren contrato de tamaño dibujado; escalar48→32 no garantiza píxel uniforme. Relleno UI44×5 es válido: no exigir múltiplos de16 para todo.

No hay ubicaciones lógicas de puente/cueva/cobertizo transitables en el mapa actual. Dejarlos como referencia/preview o solicitar decisión de alcance si se desean añadir. No cambiar colisión para cumplir una captura del plan. Dos carpetas son dos responsabilidades coordinadas, no garantía de terminar en dos sesiones.

## Reparto y uso

Enviar IA_1_ARTE_Y_RECURSOS a la primera IA e IA_2_GODOT_INTEGRACION_Y_QA a la segunda. Cada una empieza por EMPEZAR_AQUI.md. Arte puede avanzar por lotes con agentes; la integración del juego tiene dueño único. Ambas carpetas incluyen reglas originales y los cuatro contextos pedidos. No se han modificado código ni arte del juego para preparar esta entrega.

Se excluyeron cachés, .git, memoria de agentes, configuración local y mapas_muestra históricos. Las reglas/habilidades/hooks viajan como contexto; no se activa ninguna configuración. El motor no está incluido. Las auditorías son lectura estática y revisión de evidencia preexistente; no se ejecutaron suites nuevas en esta preparación.
