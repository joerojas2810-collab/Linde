"""Autoguardado y cierre inesperado con una copia de datos de integración."""
import argparse
import json
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import time

ap=argparse.ArgumentParser();ap.add_argument('--godot',required=True);ap.add_argument('--origen',type=Path,required=True);ap.add_argument('--salida',type=Path,required=True);args=ap.parse_args()
root=Path(__file__).resolve().parents[2];project=root/'Linde/cenital';out=args.salida.resolve();out.mkdir(parents=True,exist_ok=True)
data=out/'datos';shutil.copytree(args.origen,data)
godot=args.godot.replace('_console.exe','.exe')
results=[];processes=[];files=[]
def check(ok,name):
    results.append(dict(prueba=name,ok=bool(ok)));print(('PASS ' if ok else 'FAIL ')+name,flush=True)
    assert ok,name
def world():return json.loads(json.loads((data/'mundo.json').read_text(encoding='utf-8'))['cuerpo'])
def launch(script,cfg,name):
    path=out/(name+'.json');path.write_text(json.dumps(cfg),encoding='utf-8')
    log=open(out/(name+'.log'),'w',encoding='utf-8');files.append(log)
    p=subprocess.Popen([godot,'--headless','--path',str(project),'--script','res://'+script,'--','--config='+str(path)],stdout=log,stderr=subprocess.STDOUT);processes.append(p);return p
def start(name):
    (data/'estado.json').unlink(missing_ok=True)
    p=launch('scripts/cuentas/main_servidor.gd',dict(carpeta=str(data),puerto=18077,https=18078,python=sys.executable,password=''),name)
    for _ in range(120):
        if p.poll() is not None:raise RuntimeError('falló inicio')
        if (data/'estado.json').exists() and json.loads((data/'estado.json').read_text(encoding='utf-8')).get('estado')=='Escuchando':return p
        time.sleep(.1)
    raise TimeoutError('inicio')
def bot(hold,name):
    return launch('tests/bot_cuentas.gd',dict(direccion='127.0.0.1',puerto=18077,puerto_cuentas=18078,usuario='rayo',password='PruebaSegura123!',servidor_password='',registrar=False,nombre='Otro nombre',certificado_ruta=str(data/'servidor.crt'),salida=str(out/(name+'_resultado.json')),mantener=hold),name)
try:
    server=start('inicio_crash');before=world()['min'];client=bot(50,'cliente_crash')
    time.sleep(34)
    snapshot=world();check(snapshot['min']>before+20,'autoguardado periódico escribe sin desconectar')
    server.kill();server.wait(timeout=5)
    client.wait(timeout=12)
    check(not json.loads((out/'cliente_crash_resultado.json').read_text(encoding='utf-8'))['ok'],'cliente detecta cierre inesperado')
    # El helper debe apagarse por latido ausente, sin terminarlo desde la prueba.
    deadline=time.monotonic()+25
    while time.monotonic()<deadline:
        s=socket.socket();s.settimeout(.2)
        listening=s.connect_ex(('127.0.0.1',18078))==0;s.close()
        if not listening:break
        time.sleep(.5)
    check(not listening,'servicio local se apaga tras perder el latido')
    server=start('reinicio_crash');client=bot(1,'cliente_recuperado');client.wait(timeout=25)
    result=json.loads((out/'cliente_recuperado_resultado.json').read_text(encoding='utf-8'))
    check(result['ok'] and result['inv'].get('madera')==7 and result['xp']==43,'reconecta y recupera progreso tras cierre inesperado')
    (data/'detener_servidor').write_text('guardar',encoding='utf-8');server.wait(timeout=15)
    check(world()['min']>=snapshot['min'],'mundo conserva el último autoguardado tras reinicio')
finally:
    for p in processes:
        if p.poll() is None:p.terminate();p.wait(timeout=5)
    for f in files:f.close()
    (out/'resultados.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
