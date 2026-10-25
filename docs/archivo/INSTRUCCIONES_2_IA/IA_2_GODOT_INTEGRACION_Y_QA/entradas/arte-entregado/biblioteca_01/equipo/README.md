# Linde — Equipo, prueba de apariencia estática

**Entrega parcial de arte, 2026-10-23.** Cuatro apariencias completas del personaje con equipo, cada una en frente, derecha, espalda e izquierda. No son capas intercambiables.

Abrir `galeria.html` o `comparacion_base_y_equipo.png`: primera fila base aprobada, siguientes filas casco, coraza, escudo y espada.

## Archivos

- `equipo_estatico_128x128.png`: atlas 4 columnas × 4 filas; celda de 32 × 32 px.
- `assets/`: 16 poses individuales, además de cuatro tiras de 128 × 32 px por tipo de equipo.
- `manifest.json`: IDs, rutas, tamaño, dirección, ancla y estado de cada recurso.
- `checks.json`: 16 comprobaciones de transparencia binaria y contenido no vacío.
- `base_aprobada.png`: copia de la pose aprobada utilizada para comparar. No cambia el archivo de origen.
- `original_equipo.png`: lámina generada original conservada.
- `convertir.gd`: conversión reproducible Godot 4.7.1.

## Uso y límite principal

Estas poses permiten comprobar la apariencia de cada equipo por separado sustituyendo temporalmente el sprite completo. **No permiten equipar simultáneamente casco, coraza, escudo y espada ni animar la caminata.**

Cada celda tiene 32 × 32 px, ocupa hasta 27 px de alto y toca la línea de pies y=32; el ancla propuesta es (16,32). El tamaño de cuerpo varía ligeramente entre la lámina generada y el personaje aprobado, particularmente bajo el casco. No se certifica correspondencia de píxeles con la base.

Se valoró la extracción por máscara de acero para casco y coraza: no preserva por sí sola sus contornos oscuros ni resuelve el pelo que debe quedar tapado. Las piezas de madera y guardas de espada tampoco se recuperan con ese criterio. Por ello **no se entregan máscaras aproximadas como capas modulares terminadas**.

La siguiente entrega de equipo debe dibujar/revisar cada capa sobre la misma base, con máscaras de oclusión y reconstrucción comprobadas, y después extenderla a los fotogramas de caminata/herramienta/ataque. La lateralidad visual del escudo y la espada de estas poses es consistente con las manos izquierda/derecha del personaje, pero la oclusión entre varias piezas simultáneas no está probada.

## Procedencia y conversión

Fuente recibida del agente principal, creada con `image_gen` integrado:
`exec-1e95e895-846b-46ab-b371-19dd0a261086.png`.

Se conservaron original y referencia. Godot realiza alfa con umbral 0,5, eliminación de componentes desconectados de celdas vecinas, recorte, reducción nearest y colocación en celda. La retención del componente de ocho vecinos más grande elimina los restos de botas del personaje de la fila anterior. Se inspeccionó la comparación resultante para comprobar que no perdiera manos ni armas.

La imagen original constituye la evidencia generativa; no es arte propietario importado. No se garantiza exclusividad jurídica. Consultar el registro general de prompts de la biblioteca para el texto del generador conservado por el agente principal.

No hubo cambios del juego ni integración en producción. Los avisos del sandbox sobre directorio de usuario/certificados de Godot no impidieron la conversión, finalizada con código 0 mediante log temporal.
