"""Integración con procesos reales de Godot y HTTPS/DTLS. Nunca usa partidas habituales."""
import argparse
import json
import os
from pathlib import Path
import shutil
import socket
import sqlite3
import subprocess
import sys
import time

R = Path(__file__).resolve().parents[2]
P = R / 'Linde/cenital'

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--godot',required=True);ap.add_argument('--salida',type=Path,required=True);ap.add_argument('--privado',action='store_true');args=ap.parse_args()
    out=args.salida.resolve();out.mkdir(parents=True,exist_ok=True)
    data=out/'datos';data.mkdir(exist_ok=True)
    results=[];server=None;logs=[];bots=[]
    def check(condition,name):
        results.append({'prueba':name,'ok':bool(condition)});print(('PASS ' if condition else 'FAIL ')+name,flush=True)
        if not condition: raise AssertionError(name)
    def write(path,obj):path.write_text(json.dumps(obj),encoding='utf-8');return path
    def run_gd(script,config,log,wait=True):
        file=open(out/(log+'.log'),'w',encoding='utf-8');logs.append(file)
        proc=subprocess.Popen([args.godot,'--headless','--path',str(P),'--script','res://'+script,'--','--config='+str(config)],stdout=file,stderr=subprocess.STDOUT)
        if wait:proc.wait(timeout=40)
        return proc
    def start(password='',port=17977):
        (data/'estado.json').unlink(missing_ok=True)
        cfg=write(out/'inicio.json',dict(carpeta=str(data),puerto=port,https=port+1,python=sys.executable,password=password,semilla=123,privado=args.privado))
        proc=run_gd('scripts/cuentas/main_servidor.gd',cfg,'servidor_'+str(len(results)),False)
        for _ in range(150):
            if proc.poll() is not None:raise RuntimeError('El servidor terminó al arrancar; consulta logs')
            if (data/'estado.json').exists():
                state=json.loads((data/'estado.json').read_text(encoding="utf-8"))
                if state.get('estado')=='Escuchando':return proc
                if not state.get('ok'):raise RuntimeError(state)
            time.sleep(.1)
        raise TimeoutError('arranque')
    def stop(proc):
        (data/'detener_servidor').write_text('guardar',encoding='utf-8');proc.wait(timeout=15)
        time.sleep(1.5)
        check(proc.returncode==0,'cierre ordenado del servidor')
    def bot(name,registrar=False,password='PruebaSegura123!',private='',hold=1,host='127.0.0.1',cert=None,wait=True):
        idx=len(bots);path=out/f'cliente_{idx}.json';output=out/f'cliente_{idx}_resultado.json'
        cfg=dict(direccion=host,puerto=17977,puerto_cuentas=17978,usuario=name,password=password,servidor_password=private,registrar=registrar,nombre='El Rayo' if name=='rayo' else 'Amigo',certificado_ruta=str(cert or data/'servidor.crt'),salida=str(output),mantener=hold,privado=args.privado)
        write(path,cfg);proc=run_gd('tests/bot_cuentas.gd',path,f'cliente_{idx}',wait);bots.append(proc)
        if not wait:return proc,output
        check(proc.returncode==0,'cliente de prueba finaliza');return json.loads(output.read_text(encoding="utf-8"))
    try:
        server=start();check(True,'servidor sin contraseña inicia HTTPS y DTLS')
        first,path=bot('rayo',True,hold=8,wait=False)
        # Espera a que el servidor haya persistido al primer personaje, no solo su cuenta.
        for _ in range(80):
            world=data/'mundo.json'
            if world.exists():
                d=json.loads(json.loads(world.read_text(encoding='utf-8'))['cuerpo'])
                if any(k.startswith('cuenta:') for k in d['jugadores']):break
            time.sleep(.1)
        second=bot('amigo',True)
        check(second['ok'] and second['otros']>=1,'dos clientes reales comparten el mundo')
        duplicate=bot('rayo')
        check(not duplicate['ok'] and 'ya está' in duplicate['motivo'],'rechaza sesión simultánea')
        first.wait(timeout=20);initial=json.loads(path.read_text(encoding="utf-8"));check(initial['ok'],'registro y creación del personaje')
        check(initial['id']!=second['id'] and initial['id'].startswith('cuenta:'),'ID estable independiente de peer y nombre visible')
        check(not initial['tiene_clave'] and not second['tiene_clave'],'no transmite hashes de contraseñas en estado privado')
        check(initial['lugares']>0 and initial['mapa']['bloques'],'Fase 4 y exploración personal presentes')
        stop(server);server=None
        fixture=write(out/'fixture.json',dict(mundo=str(data/'mundo.json'),id=initial['id']))
        check(run_gd('tests/preparar_cuenta_fixture.gd',fixture,'fixture').returncode==0,'prepara progreso no vacío para recuperación')
        server=start()
        recovered=bot('rayo')
        check(recovered['ok'] and recovered['id']==initial['id'],'misma cuenta recupera personaje tras reinicio')
        check(recovered['inv'].get('madera')==7 and recovered['xp']==43 and recovered['equipo']['arma']=='espada_hierro','conserva inventario, progreso y equipo')
        check(recovered['look']==[1,2,3,0,0,1,2,1] and recovered['mapa']['bloques'].get('99,99')=='npc:maren','conserva aspecto y exploración personal')
        other=bot('amigo');check(other['id']==second['id'] and other['xp']!=43,'otra cuenta no recibe el personaje ajeno')
        wrong=bot('rayo',password='Equivocada123!');check(not wrong['ok'] and ('ya existe' in wrong['motivo'] if args.privado else 'incorrectos' in wrong['motivo']),'rechaza contraseña de cuenta incorrecta')
        # Otra instancia de cliente usando una dirección de interfaz local (no otra PC).
        lan=socket.gethostbyname(socket.gethostname())
        local_lan=bot('rayo',host=lan)
        check(local_lan['ok'],'conexión a IP de interfaz local '+lan+' (no prueba entre computadoras)')
        stop(server);server=None
        server=start('ServidorPrivado123!')
        rejected=bot('amigo',private='Incorrecta')
        check(not rejected['ok'] and 'servidor incorrecta' in rejected['motivo'],'servidor privado rechaza contraseña de servidor incorrecta')
        accepted=bot('amigo',private='ServidorPrivado123!');check(accepted['ok'],'servidor privado acepta cuenta y contraseña de servidor correctas')
        duplicate_cfg=write(out/'inicio_duplicado.json',dict(carpeta=str(data),puerto=17975,https=17976,python=sys.executable,password='NoDebeCambiar123!',estado=str(out/'estado_duplicado.json'),privado=args.privado))
        duplicate_server=run_gd('scripts/cuentas/main_servidor.gd',duplicate_cfg,'servidor_duplicado')
        check(duplicate_server.returncode!=0,'rechaza segundo servidor sobre el mismo directorio')
        still_alive=bot('amigo',private='ServidorPrivado123!')
        check(still_alive['ok'],'arranque duplicado no cambia contraseña ni detiene el servidor activo')
        # Una CA ajena debe fallar antes de cualquier envío de credenciales.
        subprocess.run([sys.executable,str(R/'servidor/cuentas/servicio.py'),'--datos',str(out/'otro_cert'),'--iniciar'],check=True,capture_output=True)
        bad_cert=bot('amigo',private='ServidorPrivado123!',cert=out/'otro_cert/servidor.crt')
        check(not bad_cert['ok'] and 'HTTPS' in bad_cert['motivo'],'rechaza certificado de servidor no confiable sin fallback')
        stop(server);server=None
        with sqlite3.connect(data/'cuentas.sqlite3') as db:
            rows=db.execute('SELECT password FROM accounts').fetchall()
            check(all(x[0].startswith('$argon2id$') for x in rows),'SQLite contiene Argon2id con sal')
            check(db.execute('PRAGMA integrity_check').fetchone()[0]=='ok','integridad de SQLite')
        db.close()
        check((data/'mundo.json.bak').exists() and (data/'cuentas.respaldo.sqlite3').exists(),'respaldos básicos de mundo y cuentas')
    finally:
        if server and server.poll() is None:
            (data/'detener_servidor').write_text('cerrar');server.wait(timeout=15)
        for proc in bots:
            if proc.poll() is None:proc.terminate();proc.wait(timeout=5)
        for f in logs:f.close()
        write(out/'resultados.json',dict(pruebas=results,internet_verificado=False,otra_computadora_verificada=False))
    return 0 if all(x['ok'] for x in results) else 1

if __name__=='__main__':sys.exit(main())
