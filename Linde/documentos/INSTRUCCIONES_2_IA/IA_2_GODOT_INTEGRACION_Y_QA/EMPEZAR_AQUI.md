# IA 2 — Integración Godot y QA

Tu misión es llevar los recursos al juego activo y demostrar su funcionamiento. Lee REGLAS.md, ESTADO_VERIFICADO.md, INTERCAMBIO.md y originales. Eres única dueña de scripts/escenas/datos de presentación, manifiestos productivos, registro de recepción y QA. Puedes delegar revisión y tareas independientes con archivos exclusivos; serializa escena.gd, hud.gd y registro. No modificar bibliotecas históricas ni rehacer arte aceptado.

## Orden de trabajo exacto

1. Trabajar en checkout/copia del proyecto real actual; comparar BASE_SHA256.json. La copia `base_proyecto` es referencia congelada, no sustituto del repositorio vivo. Guardar diff inicial y no sobrescribir cambios ajenos. Registrar baseline nuevo (comandos/logs), sin repetir contadores antiguos.
2. Acordar con IA1 contrato de lotes antes de arte nuevo. Puedes avanzar con assets ya existentes e infraestructura mientras llegan lotes; la aceptación final depende de recibirlos. Mantener un solo registro de arte por ID y hash y un error explícito para recursos faltantes; no ocultarlos con dibujos viejos.
3. Ataque: conservar compositor/animación existente y recoloreado CPU/caché. Integrar9 correcciones por celda y retirar solo pendientes efectivamente reparados. Mantener overrides en pipeline antes de regenerar. Añadir estela por fase, revisar espada/escudo y mano lejana en4 direcciones/3 arquetipos, local/remoto.
4. Añadir estados gráficos herramienta/daño a arte_equipo.gd y _cuadro_arte; conservar prioridades y reglas de anim_pj.gd. Resolver4 poses fuente→3 cuadros existentes por contrato; caída/dormir requieren conexión de presentación, no nuevas mecánicas. Preservar parpadeo de invulnerabilidad y equipos/variantes. Documentar oclusión cinturón/pelo acordada.
5. Mundo: reemplazar rutas de arte.gd por recursos/atlas con IDs, escalas y pivotes; terreno conectado, estados rotos/golpes/constr sin modificar cosecha/regeneración/colisión. Separar casa y ordenar tejados/copas. Construcción y ghost con texturas; no cambiar costes/alcance. No añadir acceso visual a agua/cueva sin geometría lógica autorizada.
6. Enemigos/NPC: mapear atlas a los estados reales y sus tiempos; tamaños visuales independientes de hitboxes. Maren con sprite/orientación. Integrar efectos legibles según las áreas y fases reales, sin desplazar hitboxes.
7. UI: integrar panel nueve regiones, iconos porID, salud/XP/cantidades/selección, diálogo/menú, tipografía con licencia, input y foco. Coordinar escala y contraste. Sustituir iluminación/sombras con tratamiento acordado. Mantener soporte al tamaño de ventana actual.
8. Retirar fallback artístico viejo en PJ local, remoto, creador si aplica, NPC/mundo/enemigos/UI, solo al existir reemplazo completo. Revisar consumidores de capas_sprite/ apariencia/arte.gd antes de eliminar. Crear lista de dibujo técnico permitido (debug, selección, barras/telegráficos si acordados); grep draw_* es una ayuda, no aceptación.
9. Validar cada lote y ejecutar pruebas relevantes; capturar escena real y ciclos, local/remoto,4 direcciones/3 arquetipos, fase ataque/herramienta/daño, objetos agotados, oclusión casa, HUD y errores por recurso ausente. Guardar logs/capturas en `production/qa/evidence/` del proyecto de trabajo con índice y contexto. Si no se puede escribir, informar bloqueo y ruta alternativa sin afirmar equivalencia.
10. Entregar diff acotado/archivos cambiados, hashes recibidos, comandos/logs y matriz hecho/pendiente. No exportar build ni afirmar listo sin evidencia. No tocar balance, red o guardados salvo corrección indispensable documentada y autorizada.

## Comandos de arranque (desde raíz de proyecto)

Consultar primero project.yaml y motor instalado. En esta máquina:

```sh
GODOT_BIN='/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/herramientas/runtime/Godot.app/Contents/MacOS/Godot'
"$GODOT_BIN" --headless --path Linde/cenital --editor --quit
"$GODOT_BIN" --headless --path Linde/cenital --script res://tests/prueba.gd
"$GODOT_BIN" --headless --path Linde/cenital --quit-after 5
"$GODOT_BIN" --path Linde/cenital --windowed --resolution 1280x720
```

Revisar cabeceras/requisitos de tests/prueba_ui.gd, prueba_red.gd, bot_red.gd, tira_ataque.gd y herramientas/arte/test_validador.gd antes de ejecutarlos; usar sus argumentos reales y conservar log/exit code. No asumir que scripts de red arrancan sin peers ni que todo test se invoca igual. Motor4.7.1 no incluido. Registro de herramientas/arte/validar_hoja.gd sirve de validación estructural; revisión visual sigue siendo obligatoria.
