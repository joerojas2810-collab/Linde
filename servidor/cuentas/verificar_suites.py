"""Ejecuta en Windows/Linux la lista canónica de ejecutar_suites.sh."""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import sys

ap=argparse.ArgumentParser();ap.add_argument('--godot',required=True);ap.add_argument('--salida',type=Path,required=True);ap.add_argument('--suite',action='append');args=ap.parse_args()
root=Path(__file__).resolve().parents[2];project=root/'Linde/cenital';args.salida.mkdir(parents=True,exist_ok=True)
source=(project/'tests/ejecutar_suites.sh').read_text(encoding='utf-8')
suites=re.search(r'SUITES=\((.*?)\)',source,re.S)[1].split();results=json.loads((args.salida/'resumen.json').read_text(encoding='utf-8')) if (args.salida/'resumen.json').exists() else []
if args.suite:
    if any(s not in suites for s in args.suite):raise SystemExit('Suite desconocida')
    suites=args.suite
for suite in suites:
    if any(x['suite']==suite for x in results):continue
    script='res://tests/'+suite+'.gd'
    original=(project/'tests'/(suite+'.gd')).read_text(encoding='utf-8-sig')
    # Adaptador de ejecución, sin editar las suites de Fase 5/IA 1: Godot Windows
    # necesita unidad en rutas absolutas. Solo cambia el prefijo temporal literal.
    if os.name=='nt' and '"/tmp/' in original:
        adapted=project/'tests/_cuentas_windows';adapted.mkdir(exist_ok=True)
        transformed=original.replace('"/tmp/','OS.get_cache_dir()+"/').replace('res://tests/'+suite+'.gd','res://tests/_cuentas_windows/'+suite+'.gd')
        (adapted/(suite+'.gd')).write_text(transformed,encoding='utf-8')
        script='res://tests/_cuentas_windows/'+suite+'.gd'
    proc=subprocess.run([args.godot,'--headless','--path',str(project),'--script',script],capture_output=True,timeout=240)
    text=proc.stdout.decode('utf-8',errors='replace')+proc.stderr.decode('utf-8',errors='replace')
    (args.salida/(suite+'.log')).write_text(text,encoding='utf-8')
    verdict=text
    if suite=='prueba_red':verdict=(project/'tests/resultados_red.txt').read_text(encoding='utf-8')
    passes=len(re.findall(r'^(?:PASS|OK|\[OK\])',verdict,re.M));fails=len(re.findall(r'^(?:FAIL|\[FALLO\])',verdict,re.M))
    ok=proc.returncode==0 and passes>0 and fails==0 and 'SCRIPT ERROR' not in text
    results.append(dict(suite=suite,ok=ok,passes=passes,fails=fails,exit=proc.returncode))
    print(f'{suite}: {"OK" if ok else "FALLA"} ({passes} PASS, {fails} FAIL)',flush=True)
    (args.salida/'resumen.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(f'{sum(x["ok"] for x in results)}/{len(results)} suites sin fallos')
sys.exit(0 if all(x['ok'] for x in results) else 1)
