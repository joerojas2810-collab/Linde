"""Write E01 review contract, inventory, gallery and complete hash manifest."""
from pathlib import Path
import json, hashlib, shutil, subprocess
from PIL import Image
from E01_producir import OUT, PKG, LOT, FREEZE, SRC, EXPECTED, ARQS, DIRS, compose, dump, sha

PROMPT='''Use case: precise-object-edit. Asset type: visual proposal for missing pixel-art equipment attack frames in an existing game, NOT a redesign. Reference images show exact existing pixel-art sprite, missing armor overlays and existing equipment. Create a single contact sheet with 3 rows, 4 columns of COMPOSED characters in the same tiny pixel style at large nearest-neighbor zoom. Row 1 light leather equipment; row 2 medium armor; row 3 heavy armor. Columns: front-facing sword impact (body twisting, sword sweeping toward viewer’s right), right-facing sword impact with feet spread, right-facing recovery, left-facing impact. Keep the same character identity, teal hair, face, height and small pixel scale shown. Armor follows the bent torso; boots follow feet without floating. Shield round wooden in the free hand, held near torso in front impact, anatomically plausible and clearly separate from sword arm. Preserve dark hard outlines, simple 2-3 tones per material, no blur, no antialias, no gradients, no text, no extra weapons, no impact bursts. Show proposed armor fit, not index mask colors. Neutral dark background. This is supporting reference for precise reproducible native-pixel overrides, not production-ready atlas.'''

def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s.strip()+'\n',encoding='utf-8')

def gallery():
    for arq in ARQS:
        for pal in ['pal_vigia','pal_zarzal','pal_albor']:
            for mode in ['antes','sin_escudo','sin_equipo']:
                sheet=Image.new('RGBA',(192,192))
                for r in range(4):
                    for c in range(4):
                        im=compose(SRC if mode=='antes' else LOT/'assets',arq,r,c,pal,
                                   shield=mode!='sin_escudo',equipped=mode!='sin_equipo',trail=mode!='antes')
                        sheet.alpha_composite(im,(c*48,r*48))
                sheet.save(LOT/f'previews/E01_{mode}_{arq}_{pal}.png')
    write(LOT/'GALERIA.html','''<!doctype html>
<html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Linde · Entregable 01</title>
<style>body{margin:32px auto;padding:0 20px;max-width:1080px;background:#20272f;color:#e8ecee;font:16px system-ui}h1{font-size:28px}button,select{font:inherit;padding:8px;background:#364350;color:white;border:1px solid #8192a3;border-radius:4px}label{display:inline-block;margin:6px 14px 14px 0}canvas{background:repeating-conic-gradient(#303b42 0% 25%,#354149 0% 50%) 0/24px 24px;image-rendering:pixelated;max-width:100%;height:auto}a{color:#a6d9ff}small{color:#b8c5ce}.links{display:flex;gap:20px;flex-wrap:wrap}img{max-width:100%;image-rendering:pixelated}#error{color:#ffb0aa}</style>
<h1>Linde · Ataque y equipo</h1><p>Candidato E01_v001 · 9 celdas corregidas · 263 celdas conservadas · estela recuperada del original.</p>
<p><small>Preview aislado: no prueba la integración ni la red de Godot. El agarre oculto del escudo requiere aceptación visual. Paletas existentes, sin nueva paleta global.</small></p>
<label>Equipo <select id="arq"><option>ligera</option><option>media</option><option>pesada</option></select></label>
<label>Familia <select id="pal"><option value="pal_vigia">Vigía</option><option value="pal_zarzal">Zarzal</option><option value="pal_albor">Albor</option></select></label>
<label>Vista <select id="mode"><option value="compuesto">Completo</option><option value="sin_escudo">Sin escudo</option><option value="sin_equipo">Base con espada y escudo</option></select></label>
<label>Escala <select id="zoom"><option>1</option><option selected>3</option><option>5</option></select></label>
<button id="play">Pausar</button> <button id="next">Siguiente cuadro</button>
<p id="phase"></p><p id="error" role="alert"></p>
<p>Antes · frente / derecha / espalda / izquierda</p><canvas id="before" aria-label="Cuatro direcciones antes de corregir"></canvas>
<p>Candidato · frente / derecha / espalda / izquierda</p><canvas id="after" aria-label="Cuatro direcciones del candidato"></canvas>
<p><small>Fases reales: preparado 50 ms, anticipación 50 ms, impacto 100 ms, recuperación 250 ms. Al pausar puedes inspeccionar cada cuadro. La estela de anticipación izquierda se conserva como en la fuente.</small></p>
<div class="links"><a href="INFORME.md">Informe y pendientes</a><a href="CONTRATO_PROPUESTO.json">Contrato</a><a href="MANIFIESTO.json">Manifiesto y hashes</a><a href="validacion/E01_resultados.json">Validación</a><a href="previews/E01_comparacion_nueve_celdas.png">Comparación por celda</a></div>
<h2>Comparación de las nueve celdas</h2><p>Antes / después de aplicar solo esa celda / pieza indexada / diferencia.</p>
<img src="previews/E01_comparacion_nueve_celdas.png" alt="Nueve comparaciones independientes a zoom 3">
<script>
const $=id=>document.getElementById(id), times=[50,50,100,250], names=['preparado','anticipación','impacto','recuperación'];
let frame=0,playing=true,last=performance.now(),elapsed=0,imgs={},revision=0;
function load(src){return new Promise((resolve,reject)=>{let i=new Image;i.onload=()=>resolve(i);i.onerror=()=>reject(Error('No se pudo cargar '+src));i.src=src})}
async function refresh(){const rev=++revision,a=$('arq').value,p=$('pal').value,m=$('mode').value;try{const loaded=await Promise.all([load(`previews/E01_antes_${a}_${p}.png`),load(`previews/E01_${m}_${a}_${p}${m==='compuesto'?'_x1':''}.png`)]);if(rev===revision){imgs={before:loaded[0],after:loaded[1]};$('error').textContent='';draw()}}catch(e){$('error').textContent=e.message}}
function draw(){const z=Number($('zoom').value);for(const id of ['before','after']){const cv=$(id);cv.width=192*z;cv.height=48*z;const ctx=cv.getContext('2d');ctx.imageSmoothingEnabled=false;if(imgs[id])for(let r=0;r<4;r++)ctx.drawImage(imgs[id],frame*48,r*48,48,48,r*48*z,0,48*z,48*z)}$('phase').textContent=`Cuadro ${frame} · ${names[frame]} · ${times[frame]} ms`}
function tick(t){const dt=t-last;last=t;if(playing){elapsed+=dt;while(elapsed>=times[frame]){elapsed-=times[frame];frame=(frame+1)%4}draw()}requestAnimationFrame(tick)}
for(const id of ['arq','pal','mode'])$(id).onchange=refresh;$('zoom').onchange=draw;
$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pausar':'Reproducir';last=performance.now()};
$('next').onclick=()=>{playing=false;$('play').textContent='Reproducir';frame=(frame+1)%4;elapsed=0;draw()};
refresh();requestAnimationFrame(tick);
</script></html>''')

def main():
    report=json.loads((LOT/'validacion/E01_resultados.json').read_text(encoding='utf-8'))
    origman=json.loads((SRC/'manifiesto.json').read_text(encoding='utf-8'))
    commit=subprocess.check_output(['git','-C',str(PKG.parents[2]),'rev-parse','HEAD'],text=True).strip()
    inventory=[]
    for arq,pieces in origman['hojas'].items():
        for part,meta in pieces.items():
            name=meta['archivo']; current=PKG.parents[1]/'cenital/arte/equipo/ataque'/name
            inventory.append({'id':f'E01_{name[:-4]}','recurso':name,'tipo':'ajustado' if name in EXPECTED else 'reutilizado',
                'ruta_entrada_paquete':f'base_proyecto/Linde/cenital/arte/equipo/ataque/{name}',
                'ruta_salida_lote':f'assets/{name}','sha256_entrada':sha(SRC/name),
                'sha256_salida':sha(LOT/'assets'/name),'celdas_cambiadas':EXPECTED.get(name,[]),
                'coincide_produccion_checkout':current.exists() and sha(current)==sha(SRC/name)})
    assert all(x['coincide_produccion_checkout'] for x in inventory),'snapshot differs from checkout'
    dump(LOT/'INVENTARIO.json',{'schema_version':1,'commit_fuente':commit,'hojas':inventory,
         'nuevo':['assets/E01_estela_ataque.png','fuentes/E01_overrides.json','GALERIA.html'],
         'pendientes':['Aceptación visual del usuario','Prueba real en Godot por integrador','Agarre oculto escudo frontal','Temporización estela izquierda anticipación']})
    order_front=['b_cuerpo','b_piel','b_botas','b_pantalon','b_tunica','b_cinturon','botas','pantalones','torso','guantes','escudo','espada','b_pelo','casco']
    dump(LOT/'CONTRATO_PROPUESTO.json',{
      'schema_version':1,'id':'E01_ATAQUE_EQUIPO_v001','estado':'candidato_validado_estructural_no_aceptado',
      'alcance':'Nueve celdas de seis hojas completas; once hojas intactas; estela independiente. Sin cambios del juego.',
      'atlas':[192,192],'celda':[48,48],'pivote':[24,48],'coordenadas':'[fila,columna] cero-base; píxeles locales x,y',
      'filas':DIRS,'poses':['preparado','anticipacion','impacto','recuperacion'],
      'fases':{'aviso':[0,1],'activo':[2],'rec':[3]},'duracion_cuadro_ms':[50,50,100,250],
      'tiempos_fuente':'base_proyecto/Linde/cenital/scripts/catalogos.gd: ANIM_PJ.ataque + anim_pj.gd',
      'escala':{'nativa':1,'dibujada':1,'zoom_juego':3,'filtro':'nearest','pivote_en_suelo':True},
      'colision':{'modificada':False,'pies_existentes':[10,6],'nota':'Lienzo y estela no redefinen alcance ni área de golpe.'},
      'indices':origman['indices'],'alfa':[0,255],
      'orden_capas_frente_espalda':order_front,
      'orden_perfiles':'Copiar arte_equipo.gd: derecha escudo antes de túnica; izquierda espada antes de túnica. Aplicar espada_delante después de guantes y antes de pelo/casco.',
      'espada_delante':origman['espada_delante'],'oculta':{'torso':'b_tunica','pantalones':'b_pantalon','botas':'b_botas'},
      'conservar':['cinturón visible','pelo bajo casco','INVERTIR_PERFILES=false','paletas y variantes existentes'],
      'celdas':report['celdas_cambiadas'],'bbox_convencion':'[x0,y0,x1,y1], extremos x1/y1 exclusivos; coordenadas locales',
      'propuesta_muestra':'previews/E01_comparacion_nueve_celdas.png',
      'fuente_editable':'fuentes/E01_overrides.json','fuente_efecto':'fuentes/E01_estela.json',
      'estela':{'archivo':'assets/E01_estela_ataque.png','ancla':[24,48],'fases_contenido':{'0,3':13,'1,2':12,'1,3':41,'2,3':24,'3,1':12},
                 'area':'Solo píxeles recuperados del original; bboxes en manifiesto de recursos. Sin efecto de impacto.',
                 'capa_propuesta':'sobre espada, validar delante/detrás en runtime','recoloreado':False},
      'decisiones_no_resueltas':['El escudo frontal se ancla al torso con mano libre oculta; no es una medición anatómica.',
          'Mantener o retimar la estela de [3,1] anticipación: se conserva fuente para no alterar fases sin acuerdo.',
          'Aprobación artística y recepción del coordinador pendientes.'],
      'integracion_propuesta':'assets/E01_manifiesto_ataque_propuesto.json es un candidato para la carpeta ataque; el cargador actual no consume efecto_estela_propuesto. El integrador debe añadir esa capa sin variar combate.',
      'esquema':'Campos descriptivos; celdas relaciona archivo/celda con bbox y métricas del validador. IDs E01 exclusivos. Colores RGB índice exactos, no colores de presentación.'})
    write(LOT/'fuentes/E01_PROMPT_MUESTRA.md',f'''# Muestra generada, no productiva

Herramienta: image_gen integrada, 24/10/2026. Entrada: previews/E01_entradas_fila_0.png y E01_entradas_fila_1.png. Salida: E01_muestra_generada_no_productiva.png.

La muestra cambia densidad de píxel y anatomía; se conserva solo como propuesta orientativa. **No se extrajeron píxeles de ella ni se usó como atlas final.** Las piezas finales compilan píxeles índice de fuentes existentes sobre geometría de ataque, con overrides editables. No hay certificado jurídico de exclusividad.

## Prompt enviado (comillas tipográficas normalizadas)

{PROMPT}''')
    write(LOT/'INFORME.md',f'''# E01 — Ataque y equipo, lote v001

Fecha: 24/10/2026. Estado: **candidato validado estructuralmente, revisado visualmente en composiciones estáticas; pendiente aceptación y prueba en Godot**. Repositorio fuente: `{commit}`.

## Hecho

- 17 hojas completas de ataque: seis ajustadas y once copiadas byte a byte. Nueve celdas antes vacías tienen contenido; las restantes **263/272 celdas son idénticas en RGBA**. Los nombres de archivo se conservan para facilitar el encaje; IDs exclusivos E01 en manifiesto.
- Base y sus siete capas reutilizadas sin cambiar píxeles ni hashes. Caminata activa intacta. Las 17 entradas de ataque de la instantánea coinciden por hash con el checkout descargado.
- Estela independiente: **102 píxeles originales** recuperados en [0,3]=13, [1,2]=12, [1,3]=41, [2,3]=24, [3,1]=12. Sin impactos ni cambios de hitbox.
- Torso: material índice reutilizado de la caminata y ajustado por filas a la ropa/silueta de ataque, protegiendo piel, pelo y cinturón. Pesada conserva cobertura adicional de hombro. Botas ajustadas a pies reales, sin traslación rígida flotante; media cubre un píxel más de tobillo. El JSON conserva cada píxel editable y su origen.
- Escudo: reutiliza exactamente la forma frente/0 de caminata, trasladada [4,16] a la celda de 48. Se corrigió una primera colocación alta durante la revisión. La cara queda libre; la espada se mantiene delante según el contrato existente.
- Galería HTML local con tres arquetipos, tres familias, cuatro direcciones, zoom 1/3/5, pausa y avance por cuadro. Composiciones con/sin escudo y base con armas. GIF por arquetipo/familia; hojas x1/x3 y comparaciones independientes por celda.
- Validación automática de tamaño, índices exactos, alfa, contenido de 16 celdas, margen de borde, silueta ±3, lista exacta de cambios e integridad de entradas. Las nueve celdas ajustadas tienen además 0 píxeles fuera de silueta ±1. Ver validacion/E01_resultados.json.

## Reutilizado / ajustado / nuevo

INVENTARIO.json identifica rutas y hashes de cada hoja. MANIFIESTO.json incluye todos los archivos de este lote, procedencia, restricciones y estado. Nuevos: estela separada, overrides, contratos, herramientas y previews. No se adoptó una paleta global nueva.

## Revisión visual realizada

Se inspeccionaron los PNG a zoom 3, cuatro direcciones, tres arquetipos, con y sin escudo, incluida la composición base/armas; se compararon Zarzal y Albor. Se comprobó la separación de pies, protección de cara y la superposición de espada. La revisión usa un compositor aislado que refleja orden/ocultación del código actual, sin tintar apariencia de base ni simular joyas/deltas. Las composiciones no acreditan integración real. La muestra generada sirve solo como propuesta, cambia densidad y no forma parte de assets/.

## Parcial y pendiente

- **Agarre del escudo frontal:** la fuente no muestra una mano libre medible. Se propone ancla de torso; el agarre queda oculto. Requiere aceptación visual, no se afirma una mano reconstruida ni un agarre probado.
- **Estela:** se conserva el contenido fuente, incluso anticipación izquierda [3,1]. El integrador decide si ese instante permanece. Se propone sobre espada; oclusión y temporización requieren revisión en Godot.
- **Oclusión:** la mano lejana y los perfiles de las celdas aceptadas se conservan; no se corrigieron fuera del alcance. Revisar con todas las ranuras/familias/variantes, jugador local y remoto.
- **Aceptación:** no se obtuvo aprobación de usuario, coordinador, director de arte ni integrador. Los pendientes vacíos en el manifiesto propuesto significan contenido candidato, no aprobación. El manifiesto original permanece intacto.

## Bloqueos y límites de prueba

Run result: **no ejecutado en Godot**. No se encontró Godot en PATH ni en las ubicaciones locales revisadas; la configuración proporcionada apunta a un ejecutable macOS ajeno a Windows. No se instaló otro motor ni se ejecutó el juego activo. No se atribuyen pruebas históricas al lote nuevo. La recepción final depende del integrador con el motor del proyecto.

## Reproducir y recibir

1. Con Python 3, Pillow y NumPy, ejecutar `python E01_producir.py` desde la raíz de salida o `python lotes/E01_v001/fuentes/herramientas/E01_producir.py`. La primera ejecución dentro del repositorio congela las entradas; el ZIP ya las incluye.
2. Ejecutar `python E01_finalizar.py` para regenerar contratos/galería/manifiesto (requiere el checkout para comparar producción). El ZIP entregado incluye esos resultados, no hace falta regenerarlos para revisar.
3. Abrir GALERIA.html sin servidor ni conexión. Ver también previews/E01_comparacion_nueve_celdas.png.
4. El integrador verifica hashes contra producción antes de copiar; no ejecutar derivar_ataque.gd sobre correcciones. Conservar overrides externos. Probar con Godot 4.7.1, ocultación de ropa base, pies/pivote, fases de ataque, caché/recoloreado y ambos clientes. Conectar estela por separado; el cargador actual no lee su campo propuesto.

## Procedencia y permisos

Originales del repositorio Linde y biblioteca/equipo suministrados por el usuario. Se conserva PRO CEDENCIA en fuentes/entradas/PROCEDENCIA_EQUIPO_ORIGINAL.md (nombre real sin espacio). No se encontró una licencia específica que permita atribuir CC0/OFL a estos sprites: **licencia de redistribución no certificada**, confirmar con sus autores. No se copió arte externo. La muestra fue generada con image_gen integrada; no se promete reproducibilidad exacta de esa muestra, sí de los PNG productivos compilados desde overrides y fuentes congeladas.

Escrituras limitadas a entregable_01/salida. Sin commits, publicación, cambios del juego ni otros entregables.
'''.replace('PRO CEDENCIA','procedencia'))
    write(OUT/'LEEME_E01.md','''# Entregable 01

Abrir `lotes/E01_v001/GALERIA.html`. Informe en `lotes/E01_v001/INFORME.md`.

17 hojas de ataque, 9 celdas reparadas, 263 intactas y estela independiente. Estado: candidato validado estructuralmente; aceptación y pruebas de Godot pendientes.

Fuentes editables: `lotes/E01_v001/fuentes/E01_overrides.json`. Reproducir assets con `python E01_producir.py` (Python 3 + Pillow + NumPy). Las entradas congeladas viajan con el lote y no se modifican.
''')
    gallery()
    tools=LOT/'fuentes/herramientas'; tools.mkdir(exist_ok=True)
    for name in ['E01_producir.py','E01_finalizar.py','E01_inspeccionar.py','E01_verificar.py']:
        shutil.copy2(OUT/name,tools/name)
    write(LOT/'validacion/E01_REVISION_VISUAL.md','''# Revisión visual del candidato

Observación estática por Codex: E01_comparacion_nueve_celdas.png, E01_torsos_sin_escudo_x3.png, E01_base_y_equipo_impacto_x3.png, compuestos pesada/Vigía, ligera/Zarzal y media/Albor. Se revisaron fuentes de frente y derecha a x3. El escudo pasó de [2,14] a [4,16] de traslación desde caminata para liberar la cara.

Resultado: máscaras siguen poses, botas separadas en apoyo y espada delante de torso/escudo. Las celdas históricas se preservaron. Calidad candidata; agarre de mano libre oculto, sin aprobación de dirección artística. Los GIF y controles se produjeron; no se afirma haber observado su reproducción en navegador ni en motor. Contrastar con referencia global al integrar.

No hubo captura del motor ni prueba de red. Una composición exportada no es una captura de Godot. La muestra de image_gen no satisface el contrato nativo y se excluye de assets.
''')
    # Store source code hash with the command, not environment-specific absolute locations.
    dump(LOT/'validacion/E01_comandos.json',{'comandos_ejecutados':['python E01_inspeccionar.py','python E01_producir.py','python E01_finalizar.py'],
      'versiones':{k:report[k] for k in ['python','pillow','numpy']},
      'validacion':'17 hojas, 9 celdas cambiadas, 263 idénticas, estela 102 píxeles; ejecución con assertions habilitadas',
      'godot':'no ejecutado; no disponible en PATH/ubicaciones inspeccionadas','codigo_productor_sha256':sha(OUT/'E01_producir.py')})
    resources=[]
    for p in sorted(LOT.rglob('*')):
        if not p.is_file() or p.name=='MANIFIESTO.json' or '__pycache__' in p.parts: continue
        rel=p.relative_to(LOT).as_posix(); suffix=p.suffix.lower()
        kind='atlas_equipo' if p.parent==LOT/'assets' and p.name in [h['archivo'] for a in origman['hojas'].values() for h in a.values()] else 'efecto_estela' if p.name=='E01_estela_ataque.png' else 'fuente' if rel.startswith('fuentes/') else 'preview' if rel.startswith('previews/') else 'documento'
        rec={'id':'E01_'+rel.replace('/','__').replace('.','_'),'tipo':kind,'ruta':rel,'sha256':sha(p),
             'origen':'Repositorio Linde provisto por el usuario; fuentes congeladas' if kind in ['atlas_equipo','efecto_estela','fuente'] else 'Producción y revisión E01',
             'autor':'Autores originales no identificados individualmente; preparación E01 por Codex',
             'herramienta':'Python/Pillow/NumPy; índices nativos reutilizados',
             'licencia_restricciones':'No certificada para arte original; confirmar con autores antes de redistribuir. Sin atribución CC0 inventada.',
             'estado':'candidato_validado_estructural' if kind in ['atlas_equipo','efecto_estela'] else 'evidencia_o_fuente',
             'pendientes':['Revisión artística del usuario e integración Godot'] if kind in ['atlas_equipo','efecto_estela'] else []}
        if kind=='atlas_equipo':
            rec['fuente_sha256']=sha(SRC/p.name);rec['celdas_cambiadas']=EXPECTED.get(p.name,[])
        if suffix=='.png':
            im=Image.open(p);rec['dimensiones']=list(im.size)
            if kind=='efecto_estela': rec['bbox_por_celda']={f'{r},{c}':list(im.crop((c*48,r*48,(c+1)*48,(r+1)*48)).getbbox()) for r in range(4) for c in range(4) if im.crop((c*48,r*48,(c+1)*48,(r+1)*48)).getbbox()}
        if p.name=='E01_muestra_generada_no_productiva.png': rec.update({'herramienta':'image_gen integrada','origen':'Referencias E01_entradas_fila_0/1; prompt en E01_PROMPT_MUESTRA.md','estado':'propuesta_no_productiva_no_integrar','pendientes':['No cumple atlas nativo; excluida de assets']})
        resources.append(rec)
    dump(LOT/'MANIFIESTO.json',{'schema_version':1,'id':'E01_v001','estado':'candidato_validado_estructural','fecha':'2026-10-24',
        'commit_fuente':commit,'contrato':'CONTRATO_PROPUESTO.json','recursos':resources,
        'integracion':'Nombres internos se proponen en assets/E01_manifiesto_ataque_propuesto.json; no copiados a producción.',
        'esquema':'Cada recurso tiene id exclusivo E01, tipo, ruta relativa al lote, sha256 de bytes, procedencia, herramienta, licencia/restricciones, estado y pendientes. El propio manifiesto se verifica por el hash externo de entrega.'})
    print(json.dumps({'recursos_manifestados':len(resources),'fuentes_checkout_coinciden':17,'galeria':'lotes/E01_v001/GALERIA.html'},ensure_ascii=False))

if __name__=='__main__': main()
