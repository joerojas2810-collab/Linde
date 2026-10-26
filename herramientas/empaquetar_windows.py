"""Genera un paquete Windows portable con motor, intérprete y dependencias incluidas.
Ejecutar con Python 3.11 en Windows; salida fuera del código y sin datos privados.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def construir(godot: Path, salida: Path):
    if sys.platform != 'win32':
        raise RuntimeError('Este empaquetado requiere Windows; no genera binarios de otros sistemas.')
    salida = salida.resolve()
    if salida.exists():
        raise ValueError('La salida debe ser una carpeta nueva para evitar mezclar datos privados.')
    godot = godot.resolve(strict=True)
    if salida == ROOT or ROOT in salida.parents and salida.parts[len(ROOT.parts)] in ('Linde', 'servidor', 'herramientas', '.git'):
        raise ValueError('Elige una carpeta de salida separada del código.')
    salida.mkdir(parents=True)
    shutil.copytree(ROOT / 'Linde/cenital', salida / 'Linde/cenital',
                    ignore=shutil.ignore_patterns('.godot', 'override.cfg', '*.log', '__pycache__', '_cuentas_windows', '*.key', '*.sqlite3*'))
    for name in ('cuentas', 'dedicado'):
        shutil.copytree(ROOT / 'servidor' / name, salida / 'servidor' / name,
                        ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '*.sqlite3*', '*.key', '*.crt', 'datos'))
    shutil.copytree(ROOT / 'licencias', salida / 'licencias')
    shutil.copy2(ROOT / 'Linde/cenital/docs/SERVIDOR_PRIVADO.md', salida / 'LEEME.md')
    runtime = salida / 'runtime'
    runtime.mkdir()
    shutil.copy2(godot, runtime / 'Godot.exe')
    for notice in ("Godot-LICENSE.txt", "Godot-COPYRIGHT.txt"):
        shutil.copy2(godot.parent / notice, runtime / notice)
    # Distribución oficial de CPython instalada por setup-python, copiada para uso portable.
    base = Path(sys.base_prefix)
    py = runtime / 'python'
    py.mkdir()
    for name in ('python.exe', 'pythonw.exe', 'python3.dll', 'python311.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'LICENSE.txt'):
        source = base / name
        if source.exists():
            shutil.copy2(source, py / name)
    for name in ('DLLs', 'Lib'):
        shutil.copytree(base / name, py / name, ignore=shutil.ignore_patterns('site-packages', '__pycache__', 'test', 'tests', 'idlelib', 'tkinter'))
    (py / "python311._pth").write_text(".\nLib\nDLLs\nLib/site-packages\n../../servidor/cuentas\n../../servidor/dedicado\n", encoding="ascii")
    target = py / 'Lib/site-packages'
    subprocess.run([sys.executable, '-m', 'pip', 'install', '--target', str(target),
                    '-r', str(ROOT / 'servidor/cuentas/requirements.txt')], check=True)
    # Nada de descargas o instalaciones durante el uso del paquete.
    common = '@echo off\nsetlocal\nset "PYTHONUTF8=1"\ncd /d "%~dp0"\nset "LINDE_PYTHON=%~dp0runtime\\python\\python.exe"\n'
    server = common + '"%LINDE_PYTHON%" servidor\\dedicado\\lanzador.py --godot "%~dp0runtime\\Godot.exe"\nif errorlevel 1 pause\n'
    game = common + '"%~dp0runtime\\Godot.exe" --path "%~dp0Linde\\cenital"\nif errorlevel 1 pause\n'
    stop = common + '"%LINDE_PYTHON%" servidor\\dedicado\\detener.py\nif errorlevel 1 pause\n'
    for name, content in [('Iniciar servidor.bat', server), ('Jugar Linde.bat', game), ('Guardar y cerrar servidor.bat', stop)]:
        (salida / name).write_text(content, encoding='ascii', newline='\r\n')
    # Importar aquí con el motor Windows; la máquina del jugador no necesita editor instalado.
    proc = subprocess.run([str(runtime / 'Godot.exe'), '--headless', '--path', str(salida / 'Linde/cenital'),
                           '--editor', '--import', '--quit'], capture_output=True, text=True)
    if proc.returncode or any(marker in proc.stdout + proc.stderr for marker in ('SCRIPT ERROR:', 'Parse Error:', 'Failed to load script')):
        raise RuntimeError('Falló la importación del paquete: ' + proc.stdout + proc.stderr)
    manifest = {}
    for file in salida.rglob('*'):
        if file.is_file():
            manifest[file.relative_to(salida).as_posix()] = hashlib.sha256(file.read_bytes()).hexdigest()
    (salida / 'SHA256.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'Paquete generado en {salida}; aún requiere prueba manual en otra PC y desde Internet.')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot', type=Path, required=True)
    ap.add_argument('--salida', type=Path, required=True)
    args = ap.parse_args()
    construir(args.godot, args.salida)
