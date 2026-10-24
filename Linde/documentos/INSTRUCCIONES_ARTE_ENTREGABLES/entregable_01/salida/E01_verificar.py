"""Independent receiving check: python E01_verificar.py. No image writes."""
from pathlib import Path
import hashlib,json,re
import numpy as np
from PIL import Image

HERE=Path(__file__).resolve()
OUT=HERE.parents[4] if HERE.parent.name=='herramientas' and HERE.parent.parent.name=='fuentes' else HERE.parent
LOT=OUT/'lotes/E01_v001'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    man=json.loads((LOT/'MANIFIESTO.json').read_text(encoding='utf-8'))
    seen=set(); paths=set()
    for rec in man['recursos']:
        assert rec['id'].startswith('E01_') and rec['id'] not in seen
        seen.add(rec['id'])
        p=(LOT/rec['ruta']).resolve()
        assert p.is_relative_to(LOT.resolve()) and p.is_file(),rec['ruta']
        assert sha(p)==rec['sha256'],rec['ruta']
        paths.add(p)
    actual={p.resolve() for p in LOT.rglob('*') if p.is_file() and p.name!='MANIFIESTO.json' and '__pycache__' not in p.parts}
    assert paths==actual,'files missing in manifest'
    expected={
      'equipo_ligera_torso_ataque.png':{(0,2)},'equipo_ligera_botas_ataque.png':{(1,2),(3,2)},
      'equipo_media_torso_ataque.png':{(0,2)},'equipo_media_botas_ataque.png':{(1,2)},
      'equipo_pesada_torso_ataque.png':{(0,2),(1,2),(1,3)},'escudo_ataque.png':{(0,2)}}
    changes=0;same=0; sheets=0
    proposal=json.loads((LOT/'assets/E01_manifiesto_ataque_propuesto.json').read_text(encoding='utf-8'))
    source=LOT/'fuentes/entradas/ataque'
    for arq,pieces in proposal['hojas'].items():
        for part,meta in pieces.items():
            fn=meta['archivo'];p=LOT/'assets'/fn
            assert sha(p)==meta['sha256'] and meta['pendientes']==[]
            a=np.array(Image.open(p).convert('RGBA'));b=np.array(Image.open(source/fn).convert('RGBA'))
            assert a.shape==(192,192,4)
            changed=set()
            for r in range(4):
                for c in range(4):
                    s=np.s_[r*48:(r+1)*48,c*48:(c+1)*48]
                    if np.array_equal(a[s],b[s]):same+=1
                    else:changed.add((r,c));changes+=1
            assert changed==expected.get(fn,set()),(fn,changed)
            sheets+=1
    assert (sheets,changes,same)==(17,9,263)
    for p in (source/'base').rglob('*.png'):
        assert sha(p)==sha(LOT/'assets/base'/p.relative_to(source/'base'))
    # Check all gallery combinations and local static links, without claiming a browser run.
    for a in ['ligera','media','pesada']:
        for pal in ['pal_vigia','pal_zarzal','pal_albor']:
            for stem in [f'E01_compuesto_{a}_{pal}_x1',f'E01_antes_{a}_{pal}',f'E01_sin_escudo_{a}_{pal}',f'E01_sin_equipo_{a}_{pal}']:
                assert (LOT/'previews'/f'{stem}.png').is_file(),stem
    html=(LOT/'GALERIA.html').read_text(encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"',html):
        assert (LOT/ref).is_file(),ref
    print(json.dumps({'resultado':'CORRECTO','hashes':len(paths),'ids_unicos':len(seen),'hojas':sheets,'celdas_cambiadas':changes,'celdas_intactas':same,'base_intacta':True,'enlaces_galeria':'correctos','navegador_ejecutado':False,'godot_ejecutado':False},ensure_ascii=False))

if __name__=='__main__':main()
