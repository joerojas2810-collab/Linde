# Protección, economía e identidad

Implementado el 24 de octubre de 2026. La sociedad continúa en la partida de prueba de autonomía; no se retiró la campaña ni se cambió el modo predeterminado.

## Cofres

Fabrica un **candado** desde C, junto a una mesa, con **2 lingotes y 2 fibras**. Abre un cofre propio con E y elige instalarlo. Se instala cerrado. El dueño y las personas autorizadas pueden transferir objetos; para compartir con cualquiera, el dueño puede dejarlo abierto. Se puede revocar un permiso incluso cuando esa persona está desconectada. Retirar el candado lo devuelve al inventario; requiere espacio y debe hacerse antes de desmontar el cofre.

Los cofres existentes se conservan abiertos y sin candado. El permiso se guarda por identidad de jugador, no por nombre visible. El servidor comprueba dueño, alcance, formato y secuencia; la transferencia vuelve a comprobar cercanía y permiso en el momento de ejecutarse. Un panel abierto no evita una revocación posterior. Los candados y permisos persisten y se replican.

Los habitantes pueden fabricar sus candados pagando materiales, usando y desgastando una mesa, y acercándose físicamente al cofre. Los ladrones no atraviesan candados. Evitan cofres cuyo dueño jugador esté cerca y esperan seis horas de juego entre hurtos. Cada cofre conserva hasta ocho incidentes, visibles al dueño; sin testigos, la autoría aparece como «Alguien». Los accesos autorizados no generan acusaciones. La reputación de un jugador se penaliza una vez por grupo testigo, aunque varios miembros presencien el mismo robo.

No hay ganzuado, llaves físicas ni rotura de candados en esta versión.

## Economía

Las reglas están en `datos/autonomia/reglas.json`, sección `sociedad`:

- Los habitantes dejan de recoger fibra de los arbustos cuando ya tienen la reserva objetivo entre inventario y cofre propio (24 por defecto). Pueden seguir buscando bayas. No se borran existencias anteriores.
- Una vez al día pueden gastar ocho fibras para renovar ropa y lecho, recuperando ocho puntos de energía. Conservan ocho fibras de reserva personal. Si deben sacar materiales de su propio cofre, se acercan a él; no hay cobros retroactivos acumulados al cargar una partida.
- El valor de la fibra baja con la abundancia del valle, hasta un mínimo del 25 %. Los precios de bienes y pagos usan la misma escala; un acuerdo ya reservado mantiene sus cantidades.
- Los proyectos comprometen sus materiales para que no se vuelvan a prestar antes de usarlos. Los compromisos abandonados vencen. Los materiales recibidos para una necesidad también quedan temporalmente comprometidos. El oficio se repone mediante producción, evitando recomprar continuamente su propio producto.
- Los depósitos no retiran la reserva de producción personal. Se reúnen materiales para vivienda y cofres antes de depositar excedentes.
- La riqueza que permite nuevas llegadas reconoce herramientas, piezas generadas, infraestructura y bienes en tránsito, además de existencias. La fibra acumulada se valora según abundancia. Sigue siendo un criterio provisional de acogida, no una garantía de alimento futuro.

## Acuerdos y habitantes

Las ayudas gratuitas dentro de un grupo no se califican como estafas. El riesgo de engaño en un trueque pagado depende de honestidad y confianza; se redujo el máximo configurado. Un vencimiento devuelve garantías y sigue siendo distinto de una estafa. El panel J muestra riesgo estimado, confianza deteriorada, reservas, valor de la fibra y hechos recientes; se pueden recorrer también las filas informativas.

Los colonos combinan su oficio con objetivos y preferencias de datos. Varían sus horarios, umbral de descanso y reservas de producción; la preferencia por alimentos aumenta la reserva de comida. Los diálogos incorporan identidad, necesidades actuales y recuerdos relevantes. Los colonos de guardados anteriores reciben identidad una sola vez, de forma determinista. Se conservan las tres familias de oficio existentes: son variaciones con efectos reales, no profesiones completamente nuevas ni diálogos generados por un servicio externo.

Los diálogos ajustan el alto de su panel a la longitud del texto. Las explicaciones y reservas del panel J se dividen por ancho para facilitar su lectura.

## Verificación y límites

Pruebas específicas en `tests/prueba_proteccion.gd`, simulación reproducible en `tests/simular_proteccion.gd` y capturas en `tests/captura_proteccion.gd`. Resultados y capturas en `production/qa/evidence/proteccion/`.

Las simulaciones son comprobaciones de funcionamiento, no un playtest de diversión o balance definitivo. Los habitantes todavía conocen existencias y recursos de forma global; los testigos se calculan por distancia, sin visión tras muros. La prueba de red existente usa localhost; las acciones nuevas también se comprueban directamente contra el servidor y la réplica, sin una sesión jugada completa por Internet. Persisten los avisos de recursos al cerrar Godot.
