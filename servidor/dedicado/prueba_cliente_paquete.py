"""Arranque del cliente del paquete extraído; detecta errores aunque Godot salga con 0."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ERRORS = ('SCRIPT ERROR:', 'Parse Error:', 'Failed to load script', 'Compile Error:')


def comprobar(command):
    proc = subprocess.run(command, capture_output=True, text=True, errors='replace', timeout=90)
    output = proc.stdout + proc.stderr
    print(output, flush=True)
    if proc.returncode or any(marker in output for marker in ERRORS):
        raise RuntimeError('El cliente extraído no pudo iniciar/compilar correctamente')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', type=Path, required=True)
    args = ap.parse_args()
    godot = str(args.godot.resolve(strict=True))
    project = str(ROOT / 'Linde/cenital')
    comprobar([godot, '--headless', '--path', project, '--quit-after', '30'])
    with tempfile.TemporaryDirectory(prefix='linde-cliente-') as tmp:
        comprobar([godot, '--headless', '--path', project, '--script',
                   'res://tests/prueba_perfil_local.gd', '--', '--salida=' + str(Path(tmp) / 'perfil')])
    print('PASS cliente extraído: menú, perfil local, nueva partida y guardado/carga.')


if __name__ == '__main__':
    main()
