"""Regresión de Fase 7 sobre el árbol combinado, con Godot real y logs por suite."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SUITES = ('prueba_fauna', 'prueba_habitats', 'prueba_distribucion_fauna',
          'prueba_territorios_fauna', 'prueba_senales_fauna', 'prueba_senales_red',
          'prueba_navegacion_fauna', 'prueba_decisiones_fauna')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', type=Path, required=True)
    ap.add_argument('--salida', type=Path, required=True)
    args = ap.parse_args()
    args.salida.mkdir(parents=True, exist_ok=True)
    results = []
    for suite in SUITES:
        try:
            proc = subprocess.run([str(args.godot.resolve()), '--headless', '--path', str(ROOT / 'Linde/cenital'),
                                   '--script', 'res://tests/' + suite + '.gd'],
                                  capture_output=True, text=True, errors='replace', timeout=180)
            output = proc.stdout + proc.stderr
            ok = proc.returncode == 0 and bool(re.search(r'^PASS\b', output, re.M)) and not re.search(r'^FAIL\b|SCRIPT ERROR:|Parse Error:', output, re.M)
        except subprocess.TimeoutExpired as exc:
            output = 'Timeout de la suite: ' + str(exc)
            ok = False
        (args.salida / (suite + '.log')).write_text(output, encoding='utf-8')
        results.append({'suite': suite, 'ok': ok})
        print(('PASS ' if ok else 'FAIL ') + suite, flush=True)
        if not ok:
            print(output, flush=True)
    (args.salida / 'resumen.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    if not all(result['ok'] for result in results):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
