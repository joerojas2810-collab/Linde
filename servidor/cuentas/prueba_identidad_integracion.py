"""Identidad única antes del mundo: dos instancias de cliente y dos mundos locales."""
import argparse
import http.client
import json
import socket
import sqlite3
import ssl
import subprocess
import sys
import time
from pathlib import Path

R=Path(__file__).resolve().parents[2];P=R/'Linde/cenital'
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--godot',required=True);ap.add_argument('--salida',type=Path,required=True);a=ap.parse_args()
    out=a.salida.resolve();out.mkdir(parents=True,exist_ok=True);ident=out/'identidad';results=[];procs=[];logs=[];bots=[]
    def check(ok,name):
        results.append(dict(prueba=name,ok=bool(ok)));print(('PASS ' if ok else 'FAIL ')+name,flush=True)
        assert ok,name
    def write(path,obj):path.write_text(json.dumps(obj),encoding='utf-8');return path
    def post(port,cert,path,data=None):
        ctx=ssl.create_default_context(cafile=str(cert))
        conn=http.client.HTTPConnection('127.0.0.1',port,timeout=5)
        conn.sock=ctx.wrap_socket(socket.create_connection(('127.0.0.1',port),timeout=5),server_hostname='linde.local')
        body=json.dumps(data).encode() if data is not None else None
        conn.request('POST' if data is not None else 'GET',path,body,{'Content-Type':'application/json'})
        response=conn.getresponse();result=json.loads(response.read());conn.close();return result
    def run(script,cfg,name,wait=True):
        f=open(out/(name+'.log'),'w',encoding='utf-8');logs.append(f)
        proc=subprocess.Popen([a.godot,'--headless','--path',str(P),'--script','res://'+script,'--','--config='+str(write(out/(name+'.json'),cfg))],stdout=f,stderr=subprocess.STDOUT);procs.append(proc)
        if wait:proc.wait(timeout=35)
        return proc
    def world(name,port,password=''):
        folder=out/name;folder.mkdir(exist_ok=True);(folder/'estado.json').unlink(missing_ok=True)
        proc=run('scripts/cuentas/main_servidor.gd',dict(carpeta=str(folder),puerto=port,https=port+1,python=sys.executable,password=password,autoridad=str(ident/'servidor.crt')),name+'_inicio_'+str(len(results)),False)
        for _ in range(150):
            if proc.poll() is not None:raise RuntimeError('mundo no inició')
            if (folder/'estado.json').exists() and json.loads((folder/'estado.json').read_text(encoding='utf-8')).get('estado')=='Escuchando':return proc,folder
            time.sleep(.1)
        raise TimeoutError('inicio mundo')
    def stop(proc,folder):
        (folder/'detener_servidor').write_text('cerrar');proc.wait(timeout=15);time.sleep(1.2)
    def bot(session,folder,port,hold=1,password='',wait=True):
        index=len(bots);name='cliente_'+str(index);result=out/(name+'_resultado.json')
        proc=run('tests/bot_cuentas.gd',dict(direccion='127.0.0.1',puerto=port,puerto_cuentas=port+1,certificado_ruta=str(folder/'servidor.crt'),sesion_linde=session,servidor_password=password,mantener=hold,salida=str(result)),name,wait);bots.append(proc)
        return json.loads(result.read_text(encoding='utf-8')) if wait else (proc,result)
    authority=None
    try:
        ident.mkdir();config=write(out/'identidad_inicio.json',{'rol':'identidad'})
        log=open(out/'identidad.log','w',encoding='utf-8');logs.append(log)
        authority=subprocess.Popen([sys.executable,str(R/'servidor/cuentas/servicio.py'),'--datos',str(ident),'--config',str(config),'--puerto','18290'],stdout=log,stderr=subprocess.STDOUT);procs.append(authority)
        for _ in range(100):
            try:
                if post(18290,ident/'servidor.crt','/estado').get('rol')=='identidad':break
            except (OSError,ssl.SSLError):pass
            time.sleep(.1)
        response=post(18290,ident/'servidor.crt','/registro',dict(usuario='rayo',password='ClaveLinde123!',nombre='El Rayo'))
        check(response.get('ok') and response.get('token'),'registro funciona sin ningún mundo alojado')
        login=post(18290,ident/'servidor.crt','/login',dict(usuario='rayo',password='ClaveLinde123!'))
        check(login.get('ok') and login['id']==response['id'],'otra instancia de acceso reconoce la misma identidad')
        session=dict(id=login['id'],nombre=login['nombre'],token=login['token'],exp=login['exp'],autoridad=dict(host='127.0.0.1',puerto=18290,cert=str(ident/'servidor.crt')))
        s1,w1=world('mundo1',18277);s2,w2=world('mundo2',18377,'MundoPrivado123!')
        p,path=bot(session,w1,18277,hold=7,wait=False);time.sleep(1.8)
        duplicated=bot(session,w1,18277)
        check(not duplicated['ok'] and 'ya está' in duplicated['motivo'],'el mismo ID no entra dos veces al mismo mundo')
        p.wait(timeout=15);first=json.loads(path.read_text(encoding='utf-8'));check(first['ok'] and first['id']==session['id'],'mundo usa ID global sin recibir contraseña de Linde')
        private_wrong=bot(session,w2,18377,password='Incorrecta')
        check(not private_wrong['ok'] and 'servidor incorrecta' in private_wrong['motivo'],'contraseña privada sigue separada de la cuenta')
        other_world=bot(session,w2,18377,password='MundoPrivado123!')
        check(other_world['ok'] and other_world['id']==session['id'],'la misma cuenta entra a otro mundo sin registrarse de nuevo')
        for folder in [w1,w2]:
            with sqlite3.connect(folder/'cuentas.sqlite3') as db:check(db.execute('SELECT count(*) FROM accounts').fetchone()[0]==0,'mundo no duplica cuentas ni hashes globales: '+folder.name)
            db.close()
        reject=post(18278,w1/'servidor.crt','/login',dict(usuario='rayo',password='ClaveLinde123!'))
        check(not reject['ok'],'servidor de mundo no acepta un login paralelo')
        reject=post(18278,w1/'servidor.crt','/admitir',dict(permiso=session['token']))
        check(not reject['ok'],'token global no sirve directamente como permiso de mundo')
        stop(s1,w1)
        fixture=run('tests/preparar_cuenta_fixture.gd',dict(mundo=str(w1/'mundo.json'),id=session['id']),'progreso')
        check(fixture.returncode==0,'progreso preparado en el guardado existente')
        s1,w1=world('mundo1',18277)
        back=bot(session,w1,18277)
        check(back['ok'] and back['inv'].get('madera')==7 and back['xp']==43 and back['id']==session['id'],'reconexión desde nueva instancia recupera el personaje global')
        stop(s1,w1);stop(s2,w2)
        check(post(18290,ident/'servidor.crt','/login',dict(usuario='rayo',password='ClaveLinde123!')).get('ok'),'las cuentas siguen disponibles con todos los mundos cerrados')
    finally:
        for folder in [out/'mundo1',out/'mundo2']:
            if folder.exists():(folder/'detener_servidor').write_text('cerrar')
        if ident.exists():(ident/'detener_cuentas').write_text('cerrar')
        for proc in procs:
            if proc.poll() is None:
                try:proc.wait(timeout=10)
                except subprocess.TimeoutExpired:proc.terminate();proc.wait(timeout=5)
        for f in logs:f.close()
        write(out/'resultados.json',dict(pruebas=results,otra_pc_verificada=False,internet_verificado=False))
if __name__=='__main__':main()
