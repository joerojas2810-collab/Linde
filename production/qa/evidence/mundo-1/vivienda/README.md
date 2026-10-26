# Primera vivienda funcional — 26/10/2026

Catálogo aprobado: vivienda, taller y depósito. Solo vivienda implementada; familias restantes sin instanciar. Primera entrega terminada y pagada con las piezas existentes; construcción progresiva preparada en el plano, todavía sin ejecutor por etapas.

- Núcleo: `prueba-vivienda.txt`, **29 PASS**. Huella y acceso, costos exactos, rechazo atómico por materiales/entrada/depósito previo, recorrido con movimiento real, cama/cofre, capas, servicios de vivienda, navegación/descanso de NPC, propiedad, reparación y revisión obsoleta, streaming entre regiones, reinicio y versiones futuras.
- Escena: `prueba-vivienda-ui.txt`, **8 PASS**. B ofrece vivienda, precio/vista previa, construcción con Espacio, entrada E, cama/cofre e inspección/reparación.
- ENet real: `prueba-vivienda-red.txt`, **33 PASS**. Un cliente construye mientras otro recibe la instancia, posiciones dentro/fuera con cubierta local diferente, cofre real, daño preparado, reparación pagada, rechazo de ajeno y repetición, inventarios y reinicio. Solo localhost.
- `bateria-final.txt`: **42 de 43 suites sin fallos**. General conserva 329 PASS y un único FAIL histórico por SHA256 de 96 archivos E04/E05. Todas las otras suites pasan. Batería completa ejecutada una vez al cerrar; pruebas específicas durante desarrollo.
- `hashes/` y `comparacion-legado.txt`: estado completo idéntico al cierre de Fase 5a, dos semillas × cuatro días y final, sin excluir claves. No se repiten mediciones de inicio/ritmo no afectadas.
- PNG: vista previa, exterior, umbral, interior, cofre, reparación y NPC descansando. Render real con `tests/captura_vivienda.gd`; cámara centrada en el edificio para mostrar su huella completa.

Los solares de prueba se preparan retirando recursos naturales; no se regalan elementos del edificio. Las pruebas de NPC preparan explícitamente su asignación de cama y posición cercana: verifican navegación y descanso, no migración entre pueblos. Los ensayos de reparación retiran una pared/teja mediante API del escenario; no se ha añadido destrucción automática, demolición o combate contra edificios.

Costo vivienda: **114 madera y 45 fibra**, suma de 21 muros de madera, puerta, cama, cofre vacío, 20 suelos y 41 techos; entrada con porche sin cubierta para conservar visibilidad. Reparar cobra únicamente faltantes. Mismos precios unitarios, tasas y bono de descanso existentes; no es una prueba de equilibrio a largo plazo.

No se reemplazan todavía los puestos de los asentamientos ni la casa fija del Valle. Arte reutilizado, sin recursos nuevos ni primitivas de dibujo añadidas. Persistencia probada dentro de la revisión; el catálogo se incluye en la huella de reglas y no se diseña migración para partidas anteriores. Cuentas/autenticación fuera del alcance.
