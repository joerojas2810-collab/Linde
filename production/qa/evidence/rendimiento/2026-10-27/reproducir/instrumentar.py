"""Instrumentación temporal sobre una COPIA de Linde/cenital. No usar en la partida habitual.
Uso: python3 instrumentar.py /ruta/copia/Linde/cenital
Las muestras no se suman: los alcances son inclusivos y pueden anidarse.
"""
from pathlib import Path
import re,sys,json,shutil
root=Path(sys.argv[1]).resolve()
spec={
'juego.gd':{'tick':('dt','tick'),'actualizar_regiones':('','regiones_total')},
'habitantes.gd':{'paso':('dt','npc_movimiento')},
'autonomia.gd':{'paso':('','npc_decisiones_necesidades')},
'sociedad.gd':{'actualizar':('','economia_sociedad'),'decidir':('nid','npc_decidir')},
'asentamientos.gd':{'actualizar':('','economia_regional'),'actualizar_demandas':('','economia_demandas'),'_alcance':('centro','navegacion_regional')},
'mundo.gd':{'camino':('desde, meta, area, transitable','navegacion'),'actualizar_regiones':('centros','regiones_streaming')},
'fauna.gd':{'actualizar':('','fauna')},
'escena.gd':{'_draw':('','render_cpu'),'_process':('delta','escena_process')}}
backup={}
for filename,methods in spec.items():
 p=root/'scripts'/filename;s=p.read_text()
 if 'const PerfMed =' in s:raise RuntimeError('Ya instrumentado: '+filename)
 backup[filename]=s
 # Bloqueo de compilación presente en a7f9766, ajeno al cambio de rendimiento.
 if filename=='escena.gd':s=s.replace('\t\t\t\tif j.vivo != null and not j.autonomia.activa():','\t\t\tif j.vivo != null and not j.autonomia.activa():')
 indent='\t' if any(line.startswith('\t') for line in s.splitlines()) else ' '
 s=s.replace('\n','\nconst PerfMed = preload("res://tests/perf_registro.gd")\n',1)
 for name,(args,label) in methods.items():
  m=re.search(r'^func '+re.escape(name)+r'\((.*)\)([^\n]*):\n',s,re.M)
  if not m:raise RuntimeError((filename,name))
  signature=m.group();ret='-> void' not in signature
  call=f'_med_original_{name}({args})'
  body=indent+'var inicio_med := Time.get_ticks_usec()\n'+indent+('var resultado_med = ' if ret else '')+call+'\n'+indent+f'PerfMed.anotar("{label}",Time.get_ticks_usec()-inicio_med)\n'+(indent+'return resultado_med\n' if ret else '')
  s=s[:m.start()]+signature+body+'\n'+signature.replace('func '+name+'(', 'func _med_original_'+name+'(')+s[m.end():]
 p.write_text(s)
(root/'perf-originales.json').write_text(json.dumps(backup))
for filename in ['perf_registro.gd','perf_escenarios.gd']:
 shutil.copy2(Path(__file__).with_name(filename),root/'tests'/filename)
p=root/'project.godot';(root/'perf-project-original.godot').write_text(p.read_text())
p.write_text(p.read_text().replace('[application]\n','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir="/tmp/linde-perf-user"\n'))
print('Instrumentado en copia; restaurar scripts desde perf-originales.json y project desde perf-project-original.godot al terminar.')
