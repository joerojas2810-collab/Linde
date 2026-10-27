"""Solicita guardado y cierre usando la configuración persistente del lanzador."""
from pathlib import Path
import sys
from lanzador import preparar, ROOT

try:
    cfg = preparar(ROOT / 'servidor/datos/servidor.json')
    folder = Path(cfg['carpeta'])
    if not folder.is_dir():
        raise ValueError('No existe un mundo iniciado con esta configuración.')
    (folder / 'detener_servidor').write_text('guardar y cerrar', encoding='utf-8')
    print('Cierre solicitado. Espera la confirmación del servidor antes de apagar la PC.')
except (OSError, ValueError) as exc:
    print(exc, file=sys.stderr)
    sys.exit(1)
