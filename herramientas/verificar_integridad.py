from pathlib import Path
import csv,hashlib,os,json
r=Path(__file__).resolve().parents[1];errors=[];count=0
with (r/'inventario/archivos.csv').open() as f:
 for row in csv.DictReader(f):
  p=r/'fuentes'/row['repo']/row['path'];count+=1
  if row['kind']=='symlink':ok=p.is_symlink() and os.readlink(p)==row['link_target']
  elif p.is_file():
   h=hashlib.sha256()
   with p.open('rb') as source:
    while chunk:=source.read(1048576):h.update(chunk)
   ok=h.hexdigest()==row['sha256']
  else:ok=False
  if not ok:errors.append(str(p))
print(json.dumps({'checked':count,'errors':errors},indent=2));raise SystemExit(bool(errors))
