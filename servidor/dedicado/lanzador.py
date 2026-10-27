"""Servidor privado listo para iniciar; también conserva el modo de cuentas globales."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
DEFAULT = {"carpeta": "mundos/amigos", "puerto": 7777, "https": 7778,
           "semilla": 1, "password": "", "autoridad": "", "privado": True}


def preparar(config_path):
    config_path = Path(config_path).resolve()
    if not config_path.exists():
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config_path.write_text(json.dumps(DEFAULT, indent=2), encoding="utf-8")
        try:
            config_path.chmod(0o600)
        except OSError:
            pass
        print(f"Configuración creada en {config_path}. Mundo sin contraseña por defecto; edita password antes de exponerlo a Internet.", flush=True)
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    if not isinstance(cfg, dict):
        raise ValueError("La configuración debe ser un objeto JSON.")
    cfg = DEFAULT | cfg
    for key in ("puerto", "https"):
        if type(cfg[key]) is not int or not 1 <= cfg[key] <= 65535:
            raise ValueError(f"{key}: debe ser un entero entre 1 y 65535.")
    for key in ("carpeta", "autoridad", "password"):
        if not isinstance(cfg[key], str):
            raise ValueError(f"{key}: debe ser texto.")
    if type(cfg["privado"]) is not bool:
        raise ValueError("privado debe ser true o false.")
    if not cfg["privado"] and not cfg["autoridad"]:
        raise ValueError("Falta autoridad: este lanzador conserva el acceso con cuentas de Linde.")
    for key in ("carpeta", "autoridad"):
        if not cfg[key]:
            continue
        p = Path(cfg[key]).expanduser()
        cfg[key] = str((config_path.parent / p).resolve())
    if not cfg["privado"] and not Path(cfg["autoridad"]).is_file():
        raise ValueError("No existe el certificado público de autoridad configurado.")
    cfg["python"] = sys.executable
    return cfg


def ejecutar(godot, config_path):
    cfg = preparar(config_path)
    folder = Path(cfg["carpeta"])
    folder.mkdir(parents=True, exist_ok=True)
    # main_servidor consume y elimina este archivo; nunca pasarle la configuración persistente.
    fd, temporary = tempfile.mkstemp(prefix="arranque_", suffix=".json", dir=folder)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(cfg, f)
        command = [godot, "--headless", "--path", str(ROOT / "Linde/cenital"),
                   "--script", "res://scripts/cuentas/main_servidor.gd", "--", "--config=" + temporary]
        options = ({"creationflags": subprocess.CREATE_NEW_PROCESS_GROUP} if os.name == "nt"
                   else {"start_new_session": True})
        proc = subprocess.Popen(command, **options)
        print("Servidor iniciado. Ctrl+C solicita guardar y cerrar. La escucha local no garantiza acceso desde Internet.", flush=True)
        try:
            return proc.wait()
        except KeyboardInterrupt:
            # El proceso hijo no recibe Ctrl+C: cierre por el mecanismo existente.
            (folder / "detener_servidor").write_text("guardar y cerrar", encoding="utf-8")
            print("Esperando el cierre; no fuerces la salida si quieres conservar el mundo.", flush=True)
            while proc.poll() is None:
                try:
                    time.sleep(.2)
                except KeyboardInterrupt:
                    print("El cierre sigue pendiente.", flush=True)
            return proc.returncode
    finally:
        Path(temporary).unlink(missing_ok=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--config", type=Path, default=ROOT / "servidor/datos/servidor.json")
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    args = ap.parse_args()
    try:
        return ejecutar(args.godot, args.config)
    except (OSError, ValueError) as exc:
        print(f"No se pudo iniciar: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
