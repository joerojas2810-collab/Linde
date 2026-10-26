# Propuesta A de ubicación — no activada (26/10/2026)

Prototipo de laboratorio, no política del mundo. Reutiliza Fauna.plan_region, habitat_en y la misma lista determinista de 64 candidatos. Datos de preferencia en docs/investigacion/fase7_ubicacion_propuesta.json; ninguna escena o servidor los carga. El único refactor del juego extrae candidata_region sin alterar el cálculo.

Reglas propuestas: espectros junto a árbol/arbusto, gólems junto a roca/veta, diablillos y arpías con los cuatro vecinos cardinales de pasto vacío; slimes en su posición actual. Si el punto ya cumple se conserva; si no, se toma el primer candidato compatible con la misma especie/bioma en la misma región. Sin candidato, se conserva el original. Vecinos del terreno base, no perturbación dinámica por construcción/cosecha.

Tres semillas (123,456,789), 841 regiones por semilla: 2.523 regiones, 2.271 apariciones conservadas, 904 posiciones propuestas diferentes. Cumplimiento del criterio 1.335/2.271 → 2.239/2.271 (58,8 % → 98,6 %). No demuestra mejor seguridad, navegación o legibilidad humana. Las regiones ocupadas siguen siendo las mismas; no cumple por sí solo toda la distribución no uniforme de Fase 7.

Conservación de cantidad/especie/bioma/ID/región, orden inverso y estado/carga pura comprobados en las tres semillas. Datos detallados en resultados.json; mapas vectoriales de terreno real en GALERIA.html (diagramas de QA, no arte/capturas del juego). Apariciones reales y compatibilidad cubiertas por la regresión de 23 comprobaciones de hábitats.

No se aplica a partidas nuevas ni existentes; no cambia densidad, combate, daño, botín, regeneración, caminos, poblados ni datos sellados. Sin simulación global/reproducción/migración ni integraciones económicas. Zonas de calma y lugares peligrosos requieren una propuesta posterior; estos criterios no son un radio de seguridad.

Antes de activar: aprobación humana de estas preferencias, luego política versionada por mundo que no mueva el contenido anterior, con persistencia y red verificadas. No basta con sustituir la función actual ni el JSON sellado.

Reproducir el prototipo: Godot --headless --path Linde/cenital --script res://tests/proponer_habitats.gd -- RUTA_ABSOLUTA_SALIDA.json. Sin conexiones externas ni datos de la cuenta real.
