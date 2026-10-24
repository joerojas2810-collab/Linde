# Maren — candidato E03

ACTUALIZACIÓN: la propuesta principal es ahora `modular/`: NPC basado en las capas compartidas de PJ, preset Maren[1,0,2], equipo opcional y API ArteEquipo existente. La hoja nueva descrita abajo queda referencia visual opcional no canónica. No se propone un sistema separado de NPC ni una hoja horneada por personaje. Ver modular/INTEGRACION.md.

Hecho: hoja nativa128×128, celdas32×32, pivote[16,32], cuatro orientaciones sur/este/norte/oeste, reposo/pasoA/reposo/pasoB. Las columnas0 y2 son idénticas. Silueta14–15px de ancho y23–24px de alto; escala común en todas las celdas, nearest y alfa0/255. Paleta común de24 colores. No se modificó el juego.

Nueva interpretación visual discreta: pelo castaño, ropa verde tierra y delantal marrón. Referencias: caminata del PJ existente y visual_objetivo de LINDE. No se inventan historia, oficios mecánicos, diálogos ni rutinas. La identidad es candidata para aprobación visual.

Fuente generada con herramienta incorporada image_gen; prompt conservado en fuentes/PROMPT.txt y original1254×1254 en fuentes/maren_imagegen.png. Conversión reproducible en Godot4.7.1 mediante fuentes/convertir.gd: divide cuadrícula proporcional4×4, recorta por alfa≥0.5, aplica escala global basada en altura máxima24px, centra y alinea al pie, cuantiza24 colores, repite reposo. No se dibujaron sprites por código. La cuantización es procesamiento de la imagen generada.

Validación de PNG con PIL solo lectura: validacion/estructura.json. Revisión visual del contacto sobre verde en previews/maren_contacto_x6.png confirma perfiles y espalda sin cara. Las poses de caminar son candidatas; falta revisión de ciclo en movimiento y composición junto al PJ dentro de la preview consolidada. No se afirma integración ni aprobación.

Para reproducir: ejecutar Godot --headless --log-file /tmp/e03_maren.log --path fuentes --script res://convertir.gd desde esta carpeta. El motor de este ordenador está en herramientas/runtime/Godot.app/Contents/MacOS/Godot del proyecto. Durante ejecución el sandbox negó crear userdata del motor y produjo aviso de certificados; con log explícito el script terminó0 y escribió PNG válidos. El primer intento sin log explícito terminó por señal11 al no poder crear userdata. No se presenta como prueba del juego.

Pendiente: aprobación de identidad y estilo, composición consolidada a zoom3 y ciclo, decisión de animación de trabajo si se exige. Mantener selector/rutina actual: elegir fila según movimiento existente y columna según secuencia del runtime, sin alterar velocidad o horario. No hay animación de combate/daño/trabajo en esta hoja.
