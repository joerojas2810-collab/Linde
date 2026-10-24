import urllib.request,json,hashlib,subprocess
from pathlib import Path
root=Path('work/RPG-Mundo-Vivo').resolve();rt=root/'herramientas/runtime';tag='4.7.1-stable'
r=json.load(urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/godotengine/godot/releases/tags/'+tag,headers={'User-Agent':'rpg-base'}),timeout=30))
a=next(x for x in r['assets'] if x['name']=='Godot_v4.7.1-stable_macos.universal.zip');target=rt/a['name']
with urllib.request.urlopen(a['browser_download_url'],timeout=180) as source,target.open('wb') as f:
 while chunk:=source.read(1024*1024):f.write(chunk)
sha=hashlib.sha256(target.read_bytes()).hexdigest();assert a['digest']=='sha256:'+sha
subprocess.run(['ditto','-xk',str(target),str(rt)],check=True)
record={'release':tag,'url':a['browser_download_url'],'sha256':sha,'digest_matched':True,'installed_path':'herramientas/runtime/Godot.app','global_install':False}
(root/'inventario/godot.json').write_text(json.dumps(record,indent=2));print(record)
print(subprocess.run([str(rt/'Godot.app/Contents/MacOS/Godot'),'--version'],capture_output=True,text=True).stdout)
