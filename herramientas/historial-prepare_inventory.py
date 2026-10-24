from pathlib import Path
import json,csv,hashlib,os,re,shutil
root=Path('work/RPG-Mundo-Vivo');records=json.load(open(root/'inventario/repositorios.json'));old=json.load(open('work/repos.json'));entries=[];summ=[]
for rec in records:
 base=root/'fuentes'/rec['name'];actual={str(p.relative_to(base)) for p in base.rglob('*') if p.is_file() or p.is_symlink()};missing=sorted(set(old[rec['repo']]['paths'])-actual);lfs=[];links=[]
 for p in sorted(base.rglob('*')):
  if p.is_symlink():
   entries.append({'repo':rec['name'],'path':str(p.relative_to(base)),'kind':'symlink','bytes':0,'sha256':'','link_target':os.readlink(p)});links.append({'path':str(p.relative_to(base)),'target':os.readlink(p),'resolved':p.exists()});continue
  if not p.is_file():continue
  h=hashlib.sha256()
  with p.open('rb') as f:
   prefix=f.read(200);h.update(prefix)
   if prefix.startswith(b'version https://git-lfs.github.com/spec/v1'):lfs.append(str(p.relative_to(base)))
   while chunk:=f.read(1024*1024):h.update(chunk)
  entries.append({'repo':rec['name'],'path':str(p.relative_to(base)),'kind':'file','bytes':p.stat().st_size,'sha256':h.hexdigest(),'link_target':''})
 summ.append({'name':rec['name'],'missing_tracked_paths':missing,'lfs_pointers':lfs,'symlinks':links,'expected_tracked_blobs':len(old[rec['repo']]['paths']),'archive_sha256':rec['archive_sha256']})
with (root/'inventario/archivos.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['repo','path','kind','bytes','sha256','link_target']);w.writeheader();w.writerows(entries)
(root/'inventario/integridad.json').write_text(json.dumps(summ,indent=2))
# Canonical copies retain the complete upstream rules and their license context.
rulebase=root/'beta/reglas-referencia';rulebase.mkdir(exist_ok=True)
paths={'Source-of-Mana':['sources/actor/stat/Formula.gd','sources/actor/stat/Experience.gd','sources/actor/Stats.gd','sources/actor/Inventory.gd','LICENSE.md'],'MineWorld':['worlds/market-town/configure/needs.yaml','worlds/market-town/configure/sleep.yaml','worlds/market-town/configure/economy.yaml','worlds/market-town/items/bread.yaml','LICENSE','NOTICE']}
for name,ps in paths.items():
 for rel in ps:
  dest=rulebase/name/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/'fuentes'/name/rel,dest)
formula=(root/'fuentes/Source-of-Mana/sources/actor/stat/Formula.gd').read_text();experience=(root/'fuentes/Source-of-Mana/sources/actor/stat/Experience.gd').read_text()
constants=[{'symbol':m[0],'type':m[1],'value_literal':m[2].strip()} for m in re.findall(r'^const\s+(\w+)\s*:\s*(\w+)\s*=\s*([^\n]+)',formula,re.M)]
body=experience.split('const _experienceTable = [',1)[1].split(']',1)[0];body=re.sub(r'#.*','',body);table=[int(v.strip()) for v in body.split(',') if v.strip()]
(root/'inventario/reglas-extraidas.json').write_text(json.dumps({'status':'reference_only_not_integrated','source_of_mana_commit':old['sourceofmana/sourceofmana']['sha'],'formula_constants':constants,'experience_table':table,'level_index_semantics':'GetNeededExperienceForNextLevel indexes currentLevel; no inferred starting level','units':'Preserved from source; not converted to target game units','mineworld_reference_files':paths['MineWorld']},indent=2))
print('Indexed',len(entries),'files/links;',len(constants),'RPG constants;',len(table),'XP entries')
for s in summ:print(s['name'],'missing',len(s['missing_tracked_paths']),'LFS',len(s['lfs_pointers']),'symlinks',len(s['symlinks']))
