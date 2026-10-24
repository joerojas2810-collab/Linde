from pathlib import Path
import subprocess,os,json,datetime
root=Path(__file__).resolve().parents[1];base=root/'beta/MineWorld';rt=root/'herramientas/runtime'
env=os.environ.copy();env.update(CARGO_HOME=str(rt/'cargo'),RUSTUP_HOME=str(rt/'rustup'),CARGO_TARGET_DIR=str(root/'beta/build'),GODOT=str(rt/'Godot.app/Contents/MacOS/Godot'),MINEWORLD_SKIP_BUILD='1',PATH=str(rt/'cargo/bin')+':'+env['PATH'])
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f');run=root/'inventario'/('comprobacion-'+stamp);run.mkdir()
save=root/'beta/partidas'/stamp;binary=str(root/'beta/build/debug/mineworld');world='worlds/rpg-beta'
checks=[('validar',[binary,'validate',world]),('simular',[binary,'run',world,'--headless','--seed','7','--days','1','--save',str(save)]),('reanudar',[binary,'run',world,'--headless','--seed','7','--days','2','--save',str(save)]),('replay',[binary,'replay',world,'--save',str(save)]),('inspeccionar',[binary,'inspect',str(save)]),('cliente-2d',['bash','mineworld-2d','--world',world,'--drive'])]
results=[]
for name,cmd in checks:
 try:
  with (run/(name+'.log')).open('w') as log:p=subprocess.run(cmd,cwd=base,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
  results.append({'check':name,'returncode':p.returncode});print(name,':', 'PASS' if p.returncode==0 else 'FAIL',flush=True)
 except subprocess.TimeoutExpired:results.append({'check':name,'returncode':124});print(name,': TIMEOUT',flush=True)
(run/'resultados.json').write_text(json.dumps(results,indent=2));print('Registros:',run)
raise SystemExit(0 if all(x['returncode']==0 for x in results) else 1)
