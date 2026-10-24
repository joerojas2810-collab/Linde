import concurrent.futures,urllib.request,tarfile,hashlib,json,time,os
from pathlib import Path
root=Path('work/RPG-Mundo-Vivo');root.mkdir(parents=True,exist_ok=True)
for d in ['fuentes','archivos-originales','documentacion','inventario','herramientas','beta','mapa-proyecto']:(root/d).mkdir(exist_ok=True)
r=json.load(open('work/repos.json'))
names={'yuema137/MineWorld':'MineWorld','ErkoKnoll/helbreath-base-game':'Helbreath-Base-Game','sourceofmana/sourceofmana':'Source-of-Mana','CleverRaven/Cataclysm-DDA':'Cataclysm-DDA','blocktest-game/blocktest':'Blocktest-Unity','blocktest-game/Blocktest-MonoGame':'Blocktest-MonoGame','mafik/libcolony':'LibColony'}
def collect(pair):
 repo,v=pair;name=names[repo];archive=root/'archivos-originales'/(name+'.tar.gz');dest=root/'fuentes'/name
 url='https://codeload.github.com/'+repo+'/tar.gz/'+v['sha']
 print('INICIO',name,flush=True)
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'rpg-source-collection'}),timeout=180) as source, archive.open('wb') as target:
   while chunk:=source.read(1024*1024):target.write(chunk)
  sha=hashlib.sha256(archive.read_bytes()).hexdigest();dest.mkdir(exist_ok=False)
  with tarfile.open(archive,'r:gz') as tar:
   for member in tar.getmembers():
    parts=Path(member.name).parts[1:]
    if not parts:continue
    if member.issym() or member.islnk():
     # Internal links are retained only if their target stays inside this snapshot.
     target=(dest/Path(*parts)).parent/member.linkname
     if member.issym() and not target.resolve().is_relative_to(dest.resolve()):raise ValueError('Unsafe symbolic link')
    if '..' in parts or Path(*parts).is_absolute():raise ValueError('Unsafe archive member')
    member.name=str(Path(*parts));tar.extract(member,dest)
  files=[p for p in dest.rglob('*') if p.is_file()]
  record={'repo':repo,'name':name,'commit':v['sha'],'branch_reference':v['branch'],'url':url,'archive_sha256':sha,'archive_bytes':archive.stat().st_size,'extracted_files':len(files),'extracted_bytes':sum(p.stat().st_size for p in files),'git_history_included':False,'submodules_fetched':False,'status':'ok'}
  print('OK',name,len(files),round(record['extracted_bytes']/1048576,1),'MiB',flush=True)
  return record
 except Exception as e:
  print('ERROR',name,str(e),flush=True);return {'repo':repo,'name':name,'status':'error','error':str(e)}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:records=list(pool.map(collect,r.items()))
(root/'inventario/repositorios.json').write_text(json.dumps(records,indent=2))
print('FIN',sum(x['status']=='ok' for x in records),'/',len(records),flush=True)
