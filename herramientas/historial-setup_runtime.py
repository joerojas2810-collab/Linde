import urllib.request,hashlib,platform,subprocess,os,json
from pathlib import Path
root=Path('work/RPG-Mundo-Vivo').resolve();rt=root/'herramientas/runtime';rt.mkdir(exist_ok=True)
arch='aarch64' if platform.machine()=='arm64' else 'x86_64';url=f'https://static.rust-lang.org/rustup/dist/{arch}-apple-darwin/rustup-init'
record={'rustup_url':url,'rust_toolchain_requested':'1.97.1','system_profile_modified':False}
try:
 data=urllib.request.urlopen(url,timeout=60).read();digest=hashlib.sha256(data).hexdigest();expected=urllib.request.urlopen(url+'.sha256',timeout=30).read().decode().split()[0]
 if digest!=expected:raise ValueError('Rustup hash mismatch')
 p=rt/'rustup-init';p.write_bytes(data);p.chmod(0o755)
 env=os.environ.copy();env['CARGO_HOME']=str(rt/'cargo');env['RUSTUP_HOME']=str(rt/'rustup')
 p=subprocess.run([str(p),'-y','--no-modify-path','--profile','minimal','--default-toolchain','1.97.1'],env=env)
 record.update({'rustup_sha256':digest,'returncode':p.returncode})
except Exception as e:record['error']=str(e)
(root/'inventario/runtime.json').write_text(json.dumps(record,indent=2));print(record,flush=True)
