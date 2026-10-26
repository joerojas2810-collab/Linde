# Fase 5a — evidencia, 26/10/2026

Dos comunidades adicionales de génesis en mundos nuevos. Población regional resumida; transición 5b no implementada. La ampliación queda pausada para revisar edificios por solicitud posterior del usuario. Ver `docs/investigacion/ARQUITECTURA_EDIFICIOS_MUNDO_1.md`.

- `prueba-preexistentes.txt`: 14 PASS, 20 semillas de cierre, rutas físicas, determinismo, tres días resumidos y reinicio exacto. Desarrollo usó dos semillas.
- `prueba-preexistentes-ui.txt`: 13 PASS, escena E/L/V/J, cofre accesible, mapa, rumores y persistencia.
- `prueba-preexistentes-red.txt`: 26 PASS, servidor y dos clientes ENet locales. Posiciones, provisiones y encuentro de NPC preparados para aislar contratos.
- `bateria-completa.txt`: corrida completa original de 40 suites. `cierre.txt` explica el resultado y la corrección de fixtures de rechazo, verificada por `validacion-aparicion.txt`, más el ajuste de interacción con su verificación específica. Resultado efectivo 39/40, único fallo previo de arte.
- `hashes/` y `comparacion-legado.txt`: diez líneas de estado completo iguales a Fase 4 (dos semillas × cuatro días y final), sin excluir claves.
- PNG: escena real de ambas comunidades, conversación, ficha de identidad, cofre, reservas tras tres días y mapa. Captura reproducible `tests/captura_preexistentes.gd`; se inspeccionaron las imágenes.

No es un playtest humano, una prueba de equilibrio económico prolongado ni red por Internet. Los puestos regionales tienen camas techadas pero carecen de envolvente de vivienda completa; las capturas motivan la revisión arquitectónica. No se modifica arte ni se oculta el fallo histórico.
