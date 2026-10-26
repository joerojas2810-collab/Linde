"""Paquete macOS Apple Silicon con Godot y CPython standalone ya descargados/verificados."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def lanzadores():
    common = '''#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
cd "$R"
unset PYTHONHOME PYTHONPATH
export PYTHONNOUSERSITE=1 PYTHONUTF8=1
export LINDE_PYTHON="$R/runtime/python/bin/python3"
G="$R/runtime/Godot.app/Contents/MacOS/Godot"
'''
    return {
        'Iniciar servidor.command': common + 'exec "$LINDE_PYTHON" "$R/servidor/dedicado/lanzador.py" --godot "$G"\n',
        'Jugar Linde.command': common + 'exec "$G" --path "$R/Linde/cenital"\n',
        'Guardar y cerrar servidor.command': common + 'exec "$LINDE_PYTHON" "$R/servidor/dedicado/detener.py"\n',
    }


def construir(godot, python, salida):
    if sys.platform != 'darwin' or platform.machine() != 'arm64':
        raise RuntimeError('Construir en macOS arm64; no es un paquete Intel o Linux.')
    godot = godot.resolve(strict=True)
    python = python.resolve(strict=True)
    salida = salida.resolve()
    if salida.exists():
        raise ValueError('La carpeta de salida debe ser nueva.')
    if ROOT in salida.parents and salida.parts[len(ROOT.parts)] in ('Linde', 'servidor', 'herramientas', '.git'):
        raise ValueError('La salida no puede estar dentro del código.')
    if not (godot / 'Contents/MacOS/Godot').is_file() or not (python / 'bin/python3').is_file():
        raise ValueError('Falta Godot.app o la distribución standalone de Python.')
    salida.mkdir(parents=True)
    shutil.copytree(ROOT / 'Linde/cenital', salida / 'Linde/cenital',
                    ignore=shutil.ignore_patterns('.godot', 'override.cfg', '*.log', '__pycache__', '_cuentas_windows', '*.key', '*.sqlite3*'))
    for name in ('cuentas', 'dedicado'):
        shutil.copytree(ROOT / 'servidor' / name, salida / 'servidor' / name,
                        ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '*.sqlite3*', '*.key', '*.crt', 'datos'))
    shutil.copytree(ROOT / 'licencias', salida / 'licencias')
    shutil.copy2(ROOT / 'Linde/cenital/docs/SERVIDOR_PRIVADO.md', salida / 'LEEME.md')
    shutil.copy2(ROOT / 'Linde/cenital/docs/MAC_APPLE_SILICON.md', salida / 'LEEME-MAC.md')
    runtime = salida / 'runtime'
    runtime.mkdir()
    shutil.copytree(godot, runtime / 'Godot.app', symlinks=True)
    shutil.copytree(python, runtime / 'python', symlinks=True,
                    ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
    for notice in ('Godot-LICENSE.txt', 'Godot-COPYRIGHT.txt'):
        shutil.copy2(godot.parent / notice, runtime / notice)
    py = runtime / 'python/bin/python3'
    arch = subprocess.check_output([str(py), '-I', '-c', 'import platform; print(platform.machine())'], text=True).strip()
    if arch != 'arm64':
        raise RuntimeError('El Python incluido no es arm64: ' + arch)
    subprocess.run([str(py), '-I', '-m', 'pip', 'install', '-r', str(ROOT / 'servidor/cuentas/requirements.txt')], check=True)
    for name, content in lanzadores().items():
        path = salida / name
        path.write_text(content, encoding='utf-8', newline='\n')
        path.chmod(0o755)
    executable = runtime / 'Godot.app/Contents/MacOS/Godot'
    proc = subprocess.run([str(executable), '--headless', '--path', str(salida / 'Linde/cenital'),
                           '--editor', '--import', '--quit'], capture_output=True, text=True)
    if proc.returncode or any(marker in proc.stdout + proc.stderr for marker in ('SCRIPT ERROR:', 'Parse Error:', 'Failed to load script')):
        raise RuntimeError('Falló la importación: ' + proc.stdout + proc.stderr)
    manifest = {file.relative_to(salida).as_posix(): hashlib.sha256(file.read_bytes()).hexdigest()
                for file in salida.rglob('*') if file.is_file()}
    (salida / 'SHA256.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print('Paquete Apple Silicon preparado; pendiente prueba de arranque y uso manual.')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', type=Path, required=True, help='Carpeta Godot.app')
    ap.add_argument('--python', type=Path, required=True, help='Carpeta python standalone extraída')
    ap.add_argument('--salida', type=Path, required=True)
    args = ap.parse_args()
    construir(args.godot, args.python, args.salida)
