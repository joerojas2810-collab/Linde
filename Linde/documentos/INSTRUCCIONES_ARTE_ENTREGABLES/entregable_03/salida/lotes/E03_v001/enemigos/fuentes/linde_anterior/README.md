# Enemigos: primera biblioteca nativa

Tres propuestas originales para LINDE: slime, Guardián de las Ruinas y Gran Ciervo del Claro. Los nombres, su condición de jefe y su historia son propuestas; no canon aprobado. Se crearon con imagegen integrado, conservando prompts y originales. No se copiaron recursos de juegos de referencia.

## Recursos

- `nativos/slime.png`: atlas 160×128, celdas 32×32. Silueta máxima de 16 px.
- `nativos/guardian.png`: atlas 240×192, celdas 48×48. Silueta máxima de 38 px.
- `nativos/ciervo.png`: atlas 240×192, celdas 48×48. Silueta máxima de 34 px.
- `manifest.json`: pivotes, coordenadas, secuencias y tiempos provisionales.
- `vista.html`: reproductor real de los atlas. Abrir localmente.

Filas: sur, este, norte, oeste. Columnas: quieto, paso A, paso B, anticipación, ataque. Índices desde cero. Dibujar con filtro nearest, sin mipmaps, escalas enteras. Posición de mundo coincide con el pivote indicado; no con la esquina de la textura. Las dimensiones del atlas no son hitboxes. La cámara es cenital oblicua: los perfiles son cardinales, no una cuadrícula isométrica.

## Tratamiento y comprobación

`convertir.gd` ejecutado en Godot 4.7.1 procesa las fuentes: partición uniforme 5×4, umbral alfa 0.5, recorte por silueta y una sola escala proporcional para todos los cuadros de cada enemigo. Centra horizontalmente y alinea pies a la misma base; no estira ancho/alto independientemente. Produce alfa exclusivamente 0/255 y aumentos nearest para revisión. Se verificó que los dos pasos no tienen hashes idénticos en ninguna dirección. Eso acredita cuadros distintos, no animación pulida ni anatomía perfecta.

## Límites observados

- Son ciclos cortos de dos pasos con retorno a idle. Falta pulir transición y desplazamiento de apoyo al reproducir junto al personaje.
- Slime: ojos mínimos a 16 px; en algunas poses cuesta separar ojo y núcleo dorado. El salto de silueta es intencionado. El ataque frontal se inclina parcialmente de lado; revisar antes de definir su hitbox.
- Guardián: el peso de la zancada es legible pero la fase de impacto es una pose agachada; aún no tiene recuperación animada ni efectos de golpe.
- Ciervo: los perfiles leen mejor que frente/espalda. El ataque frontal parece elevación de cabeza y necesita una pasada específica si el diseño exige embestida hacia cámara. La cornamenta requiere revisión para evitar parpadeo de píxeles entre cuadros.
- Falta daño, muerte, variantes y pruebas contra colisiones reales. Las velocidades y tiempos del manifiesto son propuestas visuales, no balance de combate.
- No se integró al juego ni se implementó IA de combate. Esta entrega es biblioteca y reproductor, no personajes jugables terminados.

La escena de aldea y el personaje aprobado guían escala y legibilidad. Los originales grandes tienen más detalle que los nativos y no deben usarse como sprites de alta resolución dentro del mapa.

## Prueba integrada posterior

Se conectaron estos tres atlas al renderizador de la **copia aislada** `../mapa_muestra`, sin modificar el proyecto del escritorio ni las reglas de combate. Capturas reales: `mapa_slime.png`, `mapa_guardian.png`, `mapa_ciervo.png`. La función de dibujo calcula orientación a partir del desplazamiento real, usa los dos pasos solo mientras existe movimiento, muestra columna 3 durante `aviso` y columna 4 al inicio de recuperación. El resto usa idle. No inventa una fase de ataque nueva: el impacto sigue siendo instantáneo según la lógica existente. F2 permite alternar el dibujo anterior en la copia. Las texturas de enemigos se cargan como recursos `Texture2D` importados. La prueba no valida balance, combate completo ni exportación del juego.
