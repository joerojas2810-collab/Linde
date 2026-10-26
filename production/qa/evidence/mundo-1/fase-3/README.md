# Orientación — cierre verificado 26/10/2026

Implementación: Fase 2 `8669f62`, Fase 3 `7fa3e74`. Estado y límites completos en `production/epics/mundo-vivo/ESTADO.md` §§3e–3f.

- `pista-en-el-pueblo.png`, `opcion-ocultar-pistas.png`, `pista-exterior.png`: motor con render, 60 cuadros por captura; inspeccionadas, texto legible y controles accesibles. Ejecutar `captura_pistas.gd` con Godot sin `--headless`.
- Las capturas del mapa y de la conversación están en `../fase-2/`; se regeneraron con los recursos SVG finales y se inspeccionaron.
- `prueba-pistas.txt`: 79 comprobaciones, sin fallos.
- `prueba-orientacion-red.txt`: dos procesos cliente ENet y un servidor, 14 comprobaciones sin fallos. Posiciones/conocimiento preparados; no certifica Internet ni movimiento libre prolongado.
- `comprobaciones-nuevas.txt`: siete suites finales dirigidas. La única falla es la comprobación preexistente del hash de arte E04/E05; los contratos de dibujo y cobertura de reglas pasan.
- `bateria-final.txt`: 34 suites ejecutadas con el listado final estable; 33 sin fallos. `prueba` conserva 329 PASS y la única falla previa de arte.
- `comparacion-hashes.txt`: ocho archivos deterministas iguales entre Fase 2 y Fase 3. `hashes/` contiene la corrida posterior; la anterior a Fase 2 está en `../fase-2/hashes/`. Sin exclusiones de estado, dos semillas y cuatro días; ritmo en cinco semillas. Las líneas de CPU no se comparan.

Las pistas no modifican XP, daño, recompensas, fabricación ni economía. La Fase 4 sigue fuera del alcance. Los mapas son esquemáticos y personales, con información aproximada de hitos existentes.
