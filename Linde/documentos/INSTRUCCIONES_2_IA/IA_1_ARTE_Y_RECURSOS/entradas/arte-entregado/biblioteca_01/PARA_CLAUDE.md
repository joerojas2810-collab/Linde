# Continuar desde esta biblioteca

Esta entrega añade recursos de arte al punto de inicio de Linde. No redefine alcance, narrativa ni balance. Lee `LEEME.md`, `VERIFICACION.md` y los manifiestos de cada sección antes de integrar.

- `personaje/`: caminata32×32; acciones48×48; máscaras/recoloreados y validación de reconstrucción. No confundir máscaras de color con un cuerpo completo bajo la ropa.
- `equipo/overlays_ajustados/`: candidatos estáticos combinables, cuatro atlas `personaje_*.png` compatibles con el cargador. Columnas repetidas: aún no equipo animado. `overlays_experimentales/` conserva un intento rechazado; no usar ese intento como recurso aprobado.
- `escenario/`:36recursos; IDs/pivotes y dimensiones en manifiesto. Los tamaños de dibujo propuestos se calibraron parcialmente en muestra; árboles se muestran a48px de lienzo. No asumir autotile completo ni colisión igual al lienzo transparente.
- `enemigos/`: tres atlas, celdas32/48,5poses y4direcciones; reglas y tiempos de animación separados. Jefes siguen siendo propuestas.
- `interfaz/`:iconos32px y componentes; solo el panel tiene prueba de nueve regiones documentada.

`mapa_muestra/` es una copia de presentación de `juego/cenital`, no un reemplazo automático. Cambios de presentación concentrados en `scripts/arte.gd`, `escena.gd`, `capas_sprite.gd` y `hud.gd`, más `arte/` y `assets/`. Comparar antes de trasladar: el proyecto original puede seguir cambiando en paralelo. No reemplazar archivos enteros sin revisar diferencias.

La muestra tiene un selector F2 para comparar PJ/enemigos con dibujo anterior, pero no restaura el escenario antiguo. Los ataques ilustrados consultan el estado existente y la presencia de espada; el hacha aún requiere discriminar tipo de recurso antes de conectar herramientas diferentes. El selector de apariencia aún no cambia las máscaras nuevas: hay que conectarlo antes de presentar personalización terminada.

Las pruebas existentes pasaron159comprobaciones de reglas y12UI. Eso no valida por sí solo calidad visual, ritmo de animación ni exportación. Se incluyen capturas reales y límites concretos por sección.

Prioridad siguiente de acabado: equipo animado en cuatro direcciones, anclas de manos/oclusiones, poses frontales de acciones, transiciones y paleta de terreno, alineación de puerta y revisión de escala. Mantener el diseño aprobado del personaje y la vista cenital. No describir la biblioteca como arte final ni como sistemas nuevos ya implementados.
