"""Smoke test aislado del paquete: inicia, espera escucha y solicita cierre guardando."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--godot', type=Path, required=True)
    args = ap.parse_args()
    launcher = Path(__file__).with_name('lanzador.py')
    with tempfile.TemporaryDirectory(prefix='linde-paquete-') as tmp:
        root = Path(tmp)
        cfg = root / 'config.json'
        data = root / 'mundo'
        cfg.write_text(json.dumps(dict(carpeta=str(data), privado=True, puerto=19477, https=19478)))
        with (root / 'inicio.log').open('w', encoding='utf-8') as log:
            proc = subprocess.Popen([sys.executable, str(launcher), '--config', str(cfg), '--godot', str(args.godot.resolve())], stdout=log, stderr=log)
            try:
                deadline = time.monotonic() + 45
                while time.monotonic() < deadline:
                    state = data / 'estado.json'
                    if state.exists() and json.loads(state.read_text(encoding='utf-8')).get('estado') == 'Escuchando':
                        break
                    if proc.poll() is not None:
                        raise RuntimeError('El servidor terminó durante el arranque')
                    time.sleep(.2)
                else:
                    raise TimeoutError('El paquete no alcanzó Escuchando')
                (data / 'detener_servidor').write_text('guardar')
                if proc.wait(timeout=20) != 0:
                    raise RuntimeError('El servidor no terminó correctamente')
                if not (data / 'mundo.json').is_file():
                    raise RuntimeError('No se guardó el mundo')
                state = json.loads((data / 'estado.json').read_text(encoding='utf-8'))
                if not state.get('ok') or state.get('estado') != 'Cerrado; mundo guardado':
                    raise RuntimeError('No se confirmó el guardado final')
                print('PASS paquete: escucha y cierre con mundo guardado (solo localhost).')
            except BaseException:
                log.flush()
                print((root / 'inicio.log').read_text(encoding='utf-8'), file=sys.stderr)
                raise
            finally:
                if proc.poll() is None:
                    data.mkdir(exist_ok=True)
                    (data / 'detener_servidor').write_text('guardar')
                    try:
                        proc.wait(timeout=20)
                    except subprocess.TimeoutExpired:
                        proc.kill(); proc.wait()
                # El helper HTTPS recibe el cierre desde Godot y sale de forma independiente.
                deadline = time.monotonic() + 8
                while time.monotonic() < deadline:
                    try:
                        for f in data.glob('*.sqlite3*'):
                            f.rename(f)
                        break
                    except OSError:
                        time.sleep(.2)


if __name__ == '__main__':
    main()
