# Entrega común, sin archivos compartidos de escritura

Dentro de cada salida crear `lotes/E##_v001/` con:

- MANIFIESTO.json: lista de recursos con id E##_..., tipo, ruta relativa, SHA-256, origen/autor/herramienta, licencia/restricciones, estado y pendientes.
- assets/: PNG nativos. Para derivados conservar relación con fuente/hash y lista de celdas cambiadas.
- fuentes/: archivos editables y prompts/registro de producción necesarios para reproducir cambios.
- previews/: contacto, composición y ciclos a zoom real. Previews Godot aislados permitidos, sin dependencias absolutas al ordenador del autor.
- validacion/: comandos exactos, versiones, log/resultado y revisión visual. No afirmar calidad por aprobar formato.
- INFORME.md: reutilizado/ajustado/nuevo; hecho/parcial/pendiente/bloqueado; decisiones requeridas, archivos y limitaciones.

Contrato por tipo: atlas requiere lienzo/celda/direcciones/poses/pivote/bbox/orden de capas/secuencia/tiempos; terreno requiere vecinos/conectividad; UI requiere nueve regiones/márgenes/tamaños; efectos requiere ancla/fases/área. Todos distinguen escala nativa/dibujada/zoom y visual/colisión. Alfa, índices o paleta se verifican según tipo, no con una restricción universal inventada.

No incluir credenciales, caches, guardados personales, motor, .git ni paquetes descargados sin procedencia. Una entrega nueva usa versión nueva; no cambiar un lote recibido con el mismo hash esperado. Entregar solo la salida propia al coordinador o un ZIP de ella; las entradas comunes no necesitan devolverse.

El coordinador comprueba manifiesto, archivos/hashes, exclusividad de IDs, contrato y evidencias; el integrador valida encaje en runtime, local/remoto cuando aplique. Estados distintos: candidato → validado estructural → revisado visual → aceptado por usuario. No usar aprobación ficticia de agentes. Faltantes permanecen explícitos; no sustituirlos silenciosamente con placeholder o arte antiguo.
