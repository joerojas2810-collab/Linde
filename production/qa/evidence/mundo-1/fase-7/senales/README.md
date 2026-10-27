# Señales causales y memoria personal (26/10/2026)

Fase 7, siguiente bloque sobre v3 aprobada. No modifica distribución, combate, estadísticas, tasas ni huella de reglas. Rama feature/fase7-ecologia, sin merge/push.

## Fuente, percepción y actualidad

Fauna.senal_desde selecciona la criatura regional viva más cercana entre las peligrosas (hostil/territorial o provocada), con identidad real, dentro del radio de conocimiento existente de Autonomia y con la misma línea de visión de combate. La extracción de Combate.linea_visible conserva el algoritmo/rayo de antes; no cambia visión de enemigos ni daño. La percepción es la del sistema de conocimiento, no la resolución/zoom de cámara del cliente. No usa planes latentes, suertes de aparición ni afirmaciones de huellas/sonidos que no existan.

El aviso muestra categoría/dirección aproximada y una opción de observar/rodear. Comparte la tarjeta existente, con título ENTORNO; prima sobre ayuda contextual cuando corresponde. No crea misiones/objetivos/recompensas ni concede invulnerabilidad. Se calcula desde la fuente viva: derrota, alejamiento, pérdida de visión o movimiento fuera de alcance lo retiran. Superposición se describe como cerca de ti, sin inventar dirección.

## Historia y conversación

Exploracion.observar registra como máximo el último avistamiento por bloque personal, con fecha, categoría, fuente/ancla internas y procedencia. No almacena coordenadas exactas ni seguimiento remoto. El mapa añade referencias aproximadas denominadas Avistamiento, fecha y fuente; su leyenda indica historia. No aplica caducidad o segundos nuevos: un registro antiguo permanece como observación histórica, nunca como confirmación de presencia actual.

Preguntar por lugares/intercambiar mapas sigue siendo voluntario y cercano. NPC puede observar fauna en ese momento o recibir el testimonio real del jugador; conserva fecha de observación. Otro jugador recibe un rumor con procedencia NPC, sin convertirlo en aviso vivo. Memorias de NPC se guardan en d.fauna.informes_npc (índice por identidad existente, no NPC/simulación nuevos), fuera de mundo_vivo replicado. No se añadió percepción distante de NPC ni rumores globales automáticos.

El guardado de personaje/mundo actual conserva recuerdos sin otro sistema de personajes. Modo legado no añade mapa/avisos. En mundos poblados v1/v2 también puede observarse fauna ya existente: es conocimiento adicional, sin migrar sus planes.

## Red y privacidad

El servidor calcula avisos por observador y los envía en el canal privado existente. Se eliminan fuente y ancla internas de la copia de memoria enviada; el guardado autoritativo las conserva para auditoría. La bienvenida/perfiles no publican informes de NPC ni mapas ajenos. La réplica solo presenta el aviso privado recibido, no deduce amenazas desde planes/instantáneas generales. No se rediseñan los snapshots generales de enemigos preexistentes; estas señales no añaden conocimiento global.

## Pruebas ejecutadas

- Señales 20/20: fuente regional realmente materializada, aviso/categoría/dirección, consulta sin mutar fauna, fuente persistente, aislamiento personal, paredes, alejamiento, movimiento, muerte, registro histórico/fecha, guardado/carga, testimonio NPC, rumor sin alarma, eliminación de IDs internos en toda la bienvenida, réplica y legado.
- ENet real, servidor y dos procesos cliente: 16/16. Solo A observa y recibe aviso/memoria; B no los hereda. Tras derrota se retira el aviso y A conserva historia. Sin IDs/anclas internos ni fuentes globales en los nuevos datos personales. Fixtures en directorio propio y servidor sin avance de combate durante el escenario para aislar causa/replicación.
- Fauna 31/31 y exploración 13/13, incluidas rayos/paredes, persistencia, mapas, privacidad previa y presupuesto histórico de bloques. No se repitió la batería general.
- UI renderizada e inspeccionada: cuatro capturas adjuntas, con aviso, retirada, mapa histórico y testimonio recibido de Maren en otra vista privada. Toman una partida ficticia/replicación; no credenciales ni partidas reales. Escenario de captura detenido para documentar estados, no playtest humano.

regresion_base.json conserva la primera ejecución (19 casos de señales + ENet/fauna/exploración). Después se añadió el caso de superposición y se reforzó el chequeo de toda la bienvenida: casos_finales.json y el log final contienen las 20 comprobaciones. No se reescribieron resultados anteriores ni se repitieron las suites no afectadas por esos últimos ajustes. Avisos ObjectDB/recursos al salir conocidos; sin SCRIPT ERROR en las pruebas finales. No se verificó otra computadora/Internet ni pantalla táctil.

## Pendientes

Se trata de avisos/avistamientos observados, no de huellas gráficas o audio. No promete todavía margen mínimo de reacción: R/T y evaluación humana siguen abiertos. Los recuerdos no prueban que el enemigo siga allí. Fuente/posición histórica permite decidir observar/evitar sin guía obligatoria, pero requiere playtest. Siguiente bloque: reproducir el atasco de fauna y mejorar navegación con la prueba acotada correspondiente. No reproducción, migración, simulación ecológica global ni economía nueva.
