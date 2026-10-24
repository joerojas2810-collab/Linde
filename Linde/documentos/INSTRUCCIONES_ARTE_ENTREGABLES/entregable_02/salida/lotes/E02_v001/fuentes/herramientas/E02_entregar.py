"""Create documentation, offline gallery and resource manifest for E02."""
from pathlib import Path
import json,hashlib,shutil
from PIL import Image
HERE=Path(__file__).resolve();OUT=HERE.parents[4] if HERE.parent.parent.name=='fuentes' else HERE.parents[1];LOT=OUT/'lotes/E02_v001'
def dump(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def write(p,x):p.write_text(x.strip()+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def excluded(p):return any(k in p.parts for k in ['.godot','__pycache__']) or p.suffix in ['.import','.uid'] or p.name.endswith('.log.1')
def main():
 result=json.loads((LOT/'validacion/E02_resultados.json').read_text(encoding='utf-8'))
 godot=json.loads((LOT/'validacion/E02_godot.json').read_text(encoding='utf-8'))
 assert godot['fallos']==[]
 sources=json.loads((LOT/'fuentes/E02_hashes_entradas.json').read_text(encoding='utf-8'))
 dump(LOT/'INVENTARIO.json',{'id':'E02_INVENTARIO','reutilizado':{
  'herramienta_original':'fuentes/entradas/personaje/herramienta.png','caminata_y_equipo':'fuentes/entradas/equipo/',
  'paletas':'fuentes/entradas/paletas.json','procedencia_personaje':'fuentes/entradas/personaje/LEEME.md'},
  'ajustado':'Se separan base/hacha y se ajustan materiales índice de equipo a poses nuevas, sin regenerar caminata.',
  'nuevo':'Daño 2 poses, caída 2 poses y dormir 1 pose por dirección; base por capas, guantes separados por profundidad, manifests, herramientas y evidencia.',
  'fuente_generada':'fuentes/E02_estados_generado.png','recortes':'fuentes/E02_recortes_generados.json',
  'png_nativos':result['png_nativos'],'fuentes_sha256':sources,
  'no_incluido':['Pico de piedra: la fuente hacha no representa un pico.','Eventos de caída/dormir en el juego','Maren','Nuevos efectos de impacto','Cambios de ataque E01']})
 states={}
 for state in ['herramienta','dano','caida','dormir']:
  m=json.loads((LOT/f'assets/{state}/E02_estado.json').read_text(encoding='utf-8'))
  states[state]={'manifiesto':f'assets/{state}/E02_estado.json','atlas':m['atlas'],'celda':[48,48],'pivote':[24,48],
   'filas':['frente','derecha','espalda','izquierda'],'poses':{'herramienta':['preparado','anticipacion','golpe','recuperacion'],
   'dano':['reaccion','recuperacion'],'caida':['rodillas','suelo'],'dormir':['reposo_acostado']}[state],
   'mapping_cuadro_logico_a_columna':m['cuadros_runtime_a_fuente'],'duracion_ms':m['duracion_cuadro_ms'],
   'escala_nativa':1,'escala_dibujada':1,'zoom':3,'filtro':'nearest'}
 dump(LOT/'CONTRATO_PROPUESTO.json',{'schema_version':1,'id':'E02_PJ_HERRAMIENTA_Y_ESTADOS_v001','estado':'candidato_validado_y_revisado_en_preview',
  'estados':states,'autoridad':'Dimensiones propuestas al integrador, no cambio unilateral de tamaños del juego.',
  'decisiones_usuario_confirmadas':[{'decision':'herramienta','texto':'Sí: tres poses en 0,30 s','mapping':[1,2,3],'ms':[100,100,100]},
  {'decision':'oclusiones','texto':'Conservar cinturón y pelo bajo casco','cinturon':'visible','pelo':'debajo_del_casco'}],
  'base_capas':['cuerpo','piel','pelo','tunica','pantalon','botas','cinturon'],
  'indices':{'principal':'#ff0000','sombra':'#00ff00','acento':'#0000ff','detalle':'#808080'},'alpha':[0,255],
  'equipo':'Cinco ranuras originales por ligera/media/pesada, escudo/espada compartidos y hacha separada. Familia/variante/paleta conservan el esquema existente.',
  'guantes':'Guantes cercanos y lejanos separados; union RGBA exacta igual al atlas combinado. No dibujar atlas combinado además de los dos desdoblados.',
  'orden_abajo_a_arriba':['cuerpo','piel','ropa_base_no_oculta','guantes_lejana','escudo_en_perfil_derecha','tunica_si_no_hay_torso','cinturon',
   'botas','pantalones','torso','guantes_cercana','escudo_frente_espalda_izquierda','espada_solo_dano','pelo','casco','hacha_solo_herramienta'],
  'oculta':{'torso':'tunica','pantalones':'pantalon','botas':'botas'},
  'escudo_herramienta':'Ancla propuesta junto al torso; la mano que levanta el hacha no es mano libre de escudo. Validar agarre oculto en integración.',
  'herramienta':'Solo hacha de la fuente, con handle/acero originales; islas sueltas se conservan en fuentes, no en la capa de hacha.',
  'visibilidad_propuesta':{'herramienta':['hacha','escudo'],'dano':['espada','escudo'],'caida':[],'dormir':[]},
  'tiempos_no_definidos':'Caída y dormir no tienen duración de juego propuesta. Los ciclos de preview usan 450 ms de demostración, sin significado de gameplay.',
  'bbox':'Cada PNG/celda tiene bbox [x0,y0,x1,y1] de extremo superior exclusivo en validacion/E02_resultados.json; celdas transparentes explícitas allí.',
  'bordes':'52 incidencias de contenido en borde solo en herramienta, heredadas de su fuente; no desplazar el pivote ni reducir al personaje para esconderlas.',
  'colision':'Sin cambios; el lienzo no define hitbox. Conservar PIES 10x6, alcance, daño, cadencias, invulnerabilidad y parpadeo.',
  'instrucciones_integracion':'Ver PARA_INTEGRAR.md. No sustituir todo el compositor por el prototipo; conservar E01 y los consumidores local/remoto.',
  'pendientes':['Aceptación artística de las nuevas poses y anclas','Integración local/remota y prueba de red','Pico si se requiere representar picar','Conexión de caída/dormir sin modificar sus reglas']})
 write(LOT/'PARA_INTEGRAR.md','''# Integrar E02 sin alterar reglas

1. Verificar los hashes del lote y de los scripts/manifiestos actuales. La salida E01 se conserva como dependencia inmutable; no regenerar sus hojas.
2. Cargar cada estado por su propio atlas y número de columnas: herramienta 192×192; daño/caída 96×192; dormir 48×192. Celda 48 y pivote [24,48] para todos. El cargador actual solo conoce ataque/caminata y supone 4 columnas: no copiar estos atlas bajo esos nombres.
3. Para herramienta, cuadro lógico 0→columna1, 1→2, 2→3. Mantener 3 cuadros/0,30 s sin tocar ANIM_PJ ni cd_obj. El preparado (columna0) queda disponible en el archivo fuente; no añadirlo al ciclo lógico. Local/remoto deben usar la misma tabla.
4. Daño: dos cuadros/0,60 s; conservar prioridad sobre ataque/herramienta e invulnerabilidad/parpadeo existentes. _cuadro_arte debe permitir estos estados, en vez de devolver 0. No añadir golpes, retrasos ni rediseñar derrota.
5. Las siete capas de base y el equipo siguen el esquema de ranuras/familias/paletas. Ocultar solo la ropa correspondiente cuando la ranura realmente esté equipada y tenga una pieza válida. El prototipo muestra sets completos para inspección, no implementa el inventario del juego.
6. Dibujar guantes lejanos detrás del torso y cercanos delante; ambos consumen la misma paleta de la ranura guantes. No dibujar dos veces el atlas combinado. Respetar el cinturón visible y pelo bajo casco confirmados por el usuario.
7. Hacha es una capa propia, no equipo de espada ni un efecto de impacto. Mostrarla solo cuando la acción real corresponda a talar con hacha. La fuente no es un pico: no mostrar hacha al picar ni por tener cualquier herramienta en inventario. El protocolo actual no transmite identidad de herramienta de la acción; coordinar un dato de presentación con la integración, sin cambiar reglas. No adivinarlo para remotos.
8. Para acciones sin herramienta, mostrar las manos y base/equipo apropiados. Las manos que no se ven en la fuente no fueron reconstruidas. El escudo durante herramienta usa ancla propuesta al torso porque el hacha ocupa una mano; requiere revisión del agarre.
9. Caída/dormir son propuestas de presentación. No conectar eventos nuevos, retrasar reaparición, alterar hora/cura ni exigir nuevas condiciones de cama sin autorización. No declarar la animación integrada por tener un PNG.
10. Revalidar carga, mapping, pivote, variantes y oclusiones con el compositor del juego, ranuras ausentes, daños, herramienta correcta y dos clientes. Los 5.836 checks del preview E02 no sustituyen esa prueba.
''')
 write(LOT/'INFORME.md',f'''# Entregable 02 — personaje, herramienta y estados

24/10/2026. **Candidato producido, validado estructuralmente y revisado en un preview aislado de Godot 4.7.1.** No es integración en el juego activo.

## Hecho

- {result['png_nativos']} PNG nativos: cuatro estados, siete capas de base por estado, cinco ranuras por arquetipo, guantes cercanos/lejanos, escudo/espada candidatos y hacha independiente.
- Fuente de herramienta reutilizada: cuatro poses × cuatro direcciones, sin rediseñar identidad ni caminata. La base, el hacha y las islas excluidas recombinan exactamente el original. Solo la pieza principal del hacha se entrega como arma; las islas siguen en fuentes.
- Daño: dos poses por dirección. Caída: dos poses. Dormir: una pose. Se generó una fuente referenciada, conservada con su prompt, y se normalizó a la escala nativa usando una sola escala para todas las poses. Colores remitidos a la paleta original por región semántica; no se crea una paleta global nueva.
- Equipo reutilizado y ajustado por capas a cada pose para ligera/media/pesada, sin rehacer las caminatas ni las variantes de color. Hojas combinadas de guantes y dos capas por profundidad con unión exacta.
- Decisiones humanas confirmadas: anticipación/golpe/recuperación [1,2,3] a 100 ms por cuadro; cinturón visible; pelo debajo del casco. Esto no equivale a aceptación artística completa de las hojas nuevas.
- {result['comprobaciones']} comprobaciones estructurales correctas. {godot['comprobaciones']} comprobaciones del prototipo en Godot: 0 fallos. Doce capturas retenidas de motor, tras 60 fotogramas por presentación, cubren cuatro estados × tres arquetipos, con cuatro direcciones y todos los cuadros lógicos.
- Contactos, hojas x1/x3 y GIF; galería HTML sin conexión. El preview Godot permite cambiar estado/equipo, pausar y avanzar cuadro. La fuente editable es el raster congelado más recortes/algoritmo; todos los PNG se pueden recompilar.

## Revisión visual y ajustes

Se revisaron herramienta/pesada, daño/media, caída/ligera y dormir/pesada en capturas reales a zoom 3. Durante producción se corrigió la clasificación de pelo oscuro, se hizo exacta la recomposición de guantes y se corrigió el escudo de herramienta para no colgarlo de la mano levantada con el hacha. Se conserva la cara fuente de cada dirección. Los sprites nuevos simplifican algunos detalles al llevarlos a resolución nativa; requieren aceptación artística.

## Parcial / pendiente

- Integración en el juego: el prototipo nuevo no reemplaza el compositor actual. Falta conectarlo a inventario, selección de herramienta y jugadores local/remoto. La 01 permanece intacta.
- Caída/dormir no se activan en el juego; se entregan las poses y el contrato sin inventar eventos ni cambiar mecánicas. Los 450 ms del GIF/preview son solo demostración, no duración de gameplay.
- La única herramienta ilustrada es hacha. No se inventó un pico ni se reutiliza el hacha como uno; su producción debe autorizarse si se requiere ampliar el alcance.
- Agarres ocultos y silueta de equipo: candidatos ajustados, no aprobación de director de arte. Las manos que faltan por oclusión no se rellenan con una mano ficticia. Se declaran {len(result['celdas_transparentes_declaradas'])} celdas transparentes de capas aisladas; no son necesariamente huecos de la composición.
- {len(result['contenido_en_borde'])} incidencias de contenido en borde, todas en herramienta, heredadas de la fuente. Las nuevas poses de daño/caída/dormir tienen margen. No se alteró la fuente para pasar un validador genérico.
- No se probaron red real, exportación ni secuencia de daño dentro del mapa. El parpadeo/invulnerabilidad no se cambia; el preview no lo simula.

## Bloqueado

Sin bloqueo de producción del lote. La recepción final depende de revisión artística e integración. No se afirma aceptación del usuario sobre las nuevas poses, solo sobre las dos decisiones explícitas.

## Pruebas y reproducibilidad

`python herramientas/E02_producir.py` y `python herramientas/E02_validar.py` desde la raíz de salida (Python + Pillow + NumPy). El archivo generado original ya está incluido; no requiere volver a llamar a image_gen. Para validar el hash del lote, consultar MANIFIESTO.json. Abrir `project.godot` dentro de lotes/E02_v001 con Godot 4.7.1 para reproducir la escena. Las pruebas son de este prototipo, sin atribuirle las 313 de E01 ni otras históricas.

Run result: ejecutado con ventana en Godot 4.7.1.stable.official.a13da4feb. Log final E02_motor.log sin errores de script; JSON y capturas en validacion/. El primer intento detectó una inferencia de tipo en el prototipo; se corrigió y se repitió la ejecución antes de emitir los resultados finales.

## Procedencia

Arte de biblioteca_01 y equipo entregado por el usuario, con originales/prompts locales incluidos como fuentes. Estados nuevos generados mediante image_gen integrada y normalizados con un pipeline técnico. No hay certificación de exclusividad ni licencia CC0 inventada: confirmar redistribución con los autores. Ningún recurso externo licenciado ni contenido de otra franquicia.

Escrituras de trabajo limitadas a entregable_02/salida, con paquete de entrega en outputs. No se modificó el juego abierto, scripts de gameplay, Maren, ataque E01, balance, guardados, red ni otros entregables. Sin commits ni publicación.
''')
 write(LOT/'GALERIA.html','''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Linde · E02</title>
<style>body{max-width:1100px;margin:32px auto;padding:0 20px;font:16px system-ui;background:#20272f;color:#e8ecee}select{font:inherit;padding:9px;background:#354452;color:white;border:1px solid #a0adba;border-radius:4px}img{image-rendering:pixelated;max-width:100%;height:auto;background:#28333e}a{color:#addcff}p{line-height:1.5}small{color:#bfccd6}.links{display:flex;flex-wrap:wrap;gap:18px}</style>
<h1>Linde · Entregable 02</h1><p>Herramienta, daño, caída y dormir. Candidato de arte y composición, probado en Godot; pendiente integración al juego.</p>
<label>Estado <select id="state"><option value="herramienta">Herramienta</option><option value="dano">Daño</option><option value="caida">Caída</option><option value="dormir">Dormir</option></select></label>
<label>Equipo <select id="arq"><option value="ligera">Ligera</option><option value="media">Media</option><option value="pesada">Pesada</option></select></label>
<p id="time"></p><img id="cycle" alt="Ciclo de las cuatro direcciones a zoom 3"><p><small>Frente / derecha / espalda / izquierda. Caída y dormir no definen tiempos ni eventos del juego.</small></p>
<h2>Captura real de Godot</h2><img id="godot" alt="Base y composición de equipo en Godot">
<h2>Reglas de oclusión confirmadas</h2><p>Cinturón visible y pelo bajo casco. Mano lejana detrás del torso, cercana delante. En herramienta, escudo junto al torso, sin atribuirle una mano libre que no se ve.</p><img src="previews/E02_oclusiones_alternativas.png" alt="Muestra de las alternativas de cinturón y pelo">
<div class="links"><a href="INFORME.md">Informe</a><a href="CONTRATO_PROPUESTO.json">Contrato</a><a href="MANIFIESTO.json">Recursos y hashes</a><a href="PARA_INTEGRAR.md">Integración</a><a href="validacion/E02_resultados.json">Validación estructural</a><a href="validacion/E02_godot.json">Pruebas Godot</a></div>
<script>function show(){const s=document.getElementById('state').value,a=document.getElementById('arq').value;document.getElementById('cycle').src=`previews/E02_${s}_${a}.gif`;document.getElementById('godot').src=`validacion/E02_godot_${s}_${a}.png`;document.getElementById('time').textContent=s==='herramienta'?'Tres poses: anticipación → golpe → recuperación. 100 ms cada una, total 0,30 s.':s==='dano'?'Dos cuadros, 300 ms cada uno, total 0,60 s.':'Demostración de poses: los 450 ms de reproducción no son una regla de juego.'}document.getElementById('state').onchange=show;document.getElementById('arq').onchange=show;show();</script></html>''')
 write(OUT/'LEEME_E02.md','''# Entregable 02

Abrir `lotes/E02_v001/GALERIA.html` o el proyecto Godot aislado de ese directorio. Teclas: 1 herramienta, 2 daño, 3 caída, 4 dormir, Tab cambia arquetipo, Espacio pausa, flecha derecha avanza cuadro y Esc sale.

El arte está producido y probado en preview, pendiente de integración y recepción artística. No modifica la copia jugable de E01.

Reproducir con `python herramientas/E02_producir.py` y `python herramientas/E02_validar.py`. Las fuentes generadas congeladas están incluidas; no requieren una nueva generación para compilar.
''')
 # All tools needed by the editable source are also carried inside the lot.
 (LOT/'fuentes/herramientas').mkdir(exist_ok=True)
 for p in (OUT/'herramientas').glob('*.py'):shutil.copy2(p,LOT/'fuentes/herramientas'/p.name)
 files=[]
 for p in sorted(LOT.rglob('*')):
  if not p.is_file() or excluded(p) or p.name=='MANIFIESTO.json':continue
  rel=p.relative_to(LOT).as_posix();kind='atlas_nativo' if rel.startswith('assets/') and p.suffix=='.png' else 'fuente' if rel.startswith('fuentes/') else 'evidencia' if rel.startswith('validacion/') else 'preview' if rel.startswith('previews/') else 'contrato_o_herramienta'
  rec={'id':'E02_'+rel.replace('/','__').replace('.','_'),'tipo':kind,'ruta':rel,'sha256':sha(p),
   'origen':'Biblioteca del usuario + ajuste/normalización E02; detalles en INVENTARIO y fuentes/E02_PROMPT.md',
   'autor_herramienta':'Codex; Python/Pillow/NumPy para compilación, Godot 4.7.1 para revisión; image_gen integrada para fuente de nuevas poses',
   'licencia_restricciones':'No certificada; conservar procedencia y confirmar derechos con autores antes de redistribuir.',
   'estado':'candidato_validado_estructural_revisado_en_preview' if kind=='atlas_nativo' else 'fuente_o_evidencia',
   'pendientes':['Aceptación artística e integración local/remota'] if kind=='atlas_nativo' else []}
  if p.suffix=='.png':rec['dimensiones']=list(Image.open(p).size)
  if kind=='atlas_nativo':
   state=p.relative_to(LOT/'assets').parts[0]
   source='fuentes/entradas/personaje/herramienta.png' if state=='herramienta' else 'fuentes/E02_estados_generado.png'
   rec['fuentes']=[{'ruta':source,'sha256':sha(LOT/source)}]
   bits=p.stem.split('_')
   if len(bits)>=3 and bits[1] in ['ligera','media','pesada','compartido']:
    piece='guantes' if bits[2]=='guantes' else bits[2]
    name=f'equipo_{bits[1]}_{piece}_caminata.png' if bits[1]!='compartido' else f'{piece}_caminata.png'
    walk='fuentes/entradas/equipo/'+name
    rec['fuentes'].append({'ruta':walk,'sha256':sha(LOT/walk)})
   n=Image.open(p).width//48
   rec['celdas_derivadas']=[[r,c] for r in range(4) for c in range(n)]
  files.append(rec)
 dump(LOT/'MANIFIESTO.json',{'schema_version':1,'id':'E02_v001','fecha':'2026-10-24','estado':'candidato_producido_y_probado_en_preview',
  'contrato':'CONTRATO_PROPUESTO.json','recursos':files,'esquema':'Rutas relativas al lote. SHA-256 de bytes; IDs E02 exclusivos. El hash del manifiesto se transporta con el ZIP. No se incluyen motor, caches, importaciones ni guardados.'})
 print(json.dumps({'recursos':len(files),'png_nativos':result['png_nativos'],'pruebas_godot':godot['comprobaciones'],'fallos':0},ensure_ascii=False))
if __name__=='__main__':main()
