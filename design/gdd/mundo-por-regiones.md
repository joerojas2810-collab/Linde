# Linde · exterior por regiones, v1

## Objetivo

Permitir explorar y modificar territorio fuera del valle sin diseñar cada mapa a mano ni mantener todo el mundo en memoria. La misma semilla y versión deben reconstruir el mismo terreno; los cambios del jugador sobreviven a descarga, guardado y red.

## Decisiones

1. Conservar el valle de autor, sus coordenadas y sus lugares de campaña. Generar solo el exterior, con transición de color, agua y densidad junto al borde.
2. Adaptar la base MIT de Infinite Generation Demo y usar FastNoiseLite de Godot. Mantener procedencia, revisión y licencia; no atribuir a la demo la persistencia o descarga que no implementaba.
3. Regiones de 16 × 16; muestreo de altitud, humedad y temperatura en coordenadas globales. Biomas y recursos usan reglas congeladas de la v1.
4. Cargar el entorno de todos los jugadores activos, descargar el resto y mantener el valle para sus NPC. Guardar semilla/versión y alteraciones, sin copias completas del terreno.
5. Conservar al servidor como autoridad de movimientos y modificaciones; reconstrucción local del terreno en clientes. Protocolo 4 para separar geometrías incompatibles.
6. Mantener navegación finita. No prometer planificación regional para NPC: sus recursos, camas asignables y objetivos se quedan en el valle en esta etapa.
7. Límite técnico de ±65.536 celdas, carga síncrona de regiones pequeñas y red de caminos ortogonales provisional. No presentarlo como un mundo infinito o una simulación global completa.

## Criterios de aceptación

- Cruzar andando los antiguos bordes y moverse en coordenadas negativas, con cámara y colisión correctas.
- Semillas iguales producen el mismo exterior con cualquier orden de carga; semillas distintas lo cambian. Una huella impide alterar silenciosamente la v1.
- Recolectar, dañar parcialmente, construir, usar cofres protegidos y fijar camas fuera del valle funcionan con las acciones normales.
- Descargar, guardar, cargar y volver conserva exactamente esas modificaciones y sus identidades. Reaparecer en una cama descargada recarga su entorno.
- Viajar repetidamente no hace crecer la caché de terreno indefinidamente. Desconectar a un jugador libera regiones que ya nadie necesita.
- Dos clientes reales cruzan el borde, ven el mismo terreno, reciben las diferencias del servidor y respetan candados/permisos en un cofre exterior.
- Las partidas anteriores conservan el valle; las versiones futuras incompatibles se rechazan. Las regresiones existentes siguen pasando en su modo correspondiente.

## Etapas posteriores

Planificación de viajes largos para NPC, colonización y asentamientos, actividad distante resumida, lugares y peligros generados, hidrología y caminos más naturales, carga en segundo plano y optimización de diferencias de red por interés regional. Estas capacidades no forman parte de la primera expansión.

Implementación y uso: `Linde/cenital/docs/MUNDO_POR_REGIONES.md`. Evidencia: `production/qa/evidence/terreno/`.
