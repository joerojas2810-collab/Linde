from pathlib import Path
import urllib.request,json,re,hashlib,concurrent.futures,shutil
root=Path('work/RPG-Mundo-Vivo');base=root/'fuentes/MineWorld';items=[]
for path in json.load(open(root/'inventario/integridad.json'))[0]['lfs_pointers']:
 s=(base/path).read_text();items.append({'oid':re.search(r'oid sha256:(\w+)',s)[1],'size':int(re.search(r'^size (\d+)',s,re.M)[1]),'path':path})
request=urllib.request.Request('https://github.com/yuema137/MineWorld.git/info/lfs/objects/batch',data=json.dumps({'operation':'download','transfers':['basic'],'objects':[{k:x[k] for k in ['oid','size']} for x in items]}).encode(),headers={'Accept':'application/vnd.git-lfs+json','Content-Type':'application/vnd.git-lfs+json','User-Agent':'rpg-base'})
response=json.load(urllib.request.urlopen(request,timeout=60));lookup={x['oid']:x for x in response['objects']}
def fetch(item):
 try:
  action=lookup[item['oid']]['actions']['download'];req=urllib.request.Request(action['href'],headers=action.get('header',{}));data=urllib.request.urlopen(req,timeout=120).read()
  assert len(data)==item['size'] and hashlib.sha256(data).hexdigest()==item['oid']
  (base/item['path']).write_bytes(data);(root/'beta/MineWorld'/item['path']).write_bytes(data)
  return {**item,'status':'ok'}
 except Exception as e:return {**item,'status':'error','error':str(e)}
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as p:results=list(p.map(fetch,items))
(root/'inventario/lfs-materializados.json').write_text(json.dumps(results,indent=2));print('LFS',sum(x['status']=='ok' for x in results),'/',len(results))
