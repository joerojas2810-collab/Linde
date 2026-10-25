from pathlib import Path
import subprocess,hashlib,json
root=Path('/Users/josephrojas/Documents/Codex/2026-10-23/referenced-chatgpt-conversation-this-is-an/outputs/LINDE_Equipo_Indice_01')
audit=root/'fuentes_arquetipos/auditoria';audit.mkdir(exist_ok=True)
godot='/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/herramientas/runtime/Godot.app/Contents/MacOS/Godot'
validator='/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/herramientas/arte/validar_hoja.gd'
rows=[]
for path in sorted((root/'hojas').glob('*.png')):
 out=audit/(path.stem+'.json')
 r=subprocess.run([godot,'--headless','--script',validator,'--',str(path),'--celda=32','--modo=indice','--base='+str(root/'base/caminata.png'),'--json='+str(out)],capture_output=True,text=True)
 (audit/(path.stem+'.log')).write_text(r.stdout+r.stderr)
 data=json.loads(out.read_text())
 rows.append({'hoja':path.name,'salida':r.returncode,'errores':data['errores'],'avisos':data['avisos'],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
basehash=hashlib.sha256((root/'base/caminata.png').read_bytes()).hexdigest()
oldhash=hashlib.sha256((root.parent/'LINDE_Biblioteca_Arte_01/personaje/caminata.png').read_bytes()).hexdigest()
summary={'cantidad':len(rows),'base_sha256':basehash,'original_sha256':oldhash,'base_identica':basehash==oldhash,'validador_original_sha256':hashlib.sha256(Path(validator).read_bytes()).hexdigest(),'hojas':rows}
(audit/'resumen.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
