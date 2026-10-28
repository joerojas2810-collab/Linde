"""Corre las suites headless del juego jugable con un Godot real.

Uso:
  python3 herramientas/verificar_jugable.py --godot /ruta/Godot --salida qa/jugable

Una suite pasa si: sale con 0, imprime al menos un PASS, ningún FAIL y ningún
error de script/parseo. Los logs quedan en --salida para diagnóstico.
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROYECTO = ROOT / 'Linde' / 'cenital'

# Suites que definen el contrato de «jugable con principio y final».
SUITES = (
    'prueba_arranque',
    'prueba_campana',
    'prueba_alcanzabilidad',
    'prueba_guardado_campana',
)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', type=Path, required=True)
    ap.add_argument('--salida', type=Path, required=True)
    ap.add_argument('--suite', action='append', help='Suite extra a ejecutar (repetible)')
    args = ap.parse_args()
    args.salida.mkdir(parents=True, exist_ok=True)
    suites = list(SUITES) + (args.suite or [])
    resultados = []
    for suite in suites:
        ruta = PROYECTO / 'tests' / (suite + '.gd')
        if not ruta.is_file():
            print('OMITIR ' + suite + ' (aún no existe)', flush=True)
            continue
        try:
            proc = subprocess.run(
                [str(args.godot.resolve()), '--headless', '--path', str(PROYECTO),
                 '--script', 'res://tests/' + suite + '.gd'],
                capture_output=True, text=True, errors='replace', timeout=300)
            salida = proc.stdout + proc.stderr
            correcto = (proc.returncode == 0
                        and re.search(r'^PASS\b', salida, re.M) is not None
                        and re.search(r'^FAIL\b|SCRIPT ERROR:|Parse Error:', salida, re.M) is None)
        except subprocess.TimeoutExpired as exc:
            salida = 'Timeout de la suite: ' + str(exc)
            correcto = False
        (args.salida / (suite + '.log')).write_text(salida, encoding='utf-8')
        resultados.append({'suite': suite, 'ok': correcto})
        print(('PASS ' if correcto else 'FAIL ') + suite, flush=True)
        if not correcto:
            print(salida[-4000:], flush=True)
    (args.salida / 'resumen.json').write_text(json.dumps(resultados, indent=2), encoding='utf-8')
    if not resultados or not all(r['ok'] for r in resultados):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
