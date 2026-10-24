#!/bin/bash
# Abre Linde (Mac). Busca Godot 4.7.1 en este orden: variable GODOT, herramientas/runtime, o lo descarga del release oficial.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"
P="$R/Linde/cenital"
RT="$R/herramientas/runtime"
TAG="4.7.1-stable"
ZIP="Godot_v4.7.1-stable_macos.universal.zip"
SHA="897cb7f9799796c717ae75f31446aed883dc92b1d6c3b33d893cc7843fff2fa9"
G="${GODOT:-$RT/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$G" ]; then
  echo "Descargando Godot $TAG (una sola vez, ~160 MB)..."
  mkdir -p "$RT"
  curl -fL --progress-bar -o "$RT/$ZIP" "https://github.com/godotengine/godot/releases/download/$TAG/$ZIP"
  if ! echo "$SHA  $RT/$ZIP" | shasum -a 256 -c - >/dev/null 2>&1; then
    rm -f "$RT/$ZIP"
    echo "ERROR: la descarga no coincide con el sha256 oficial; no se usa." >&2
    exit 1
  fi
  unzip -q -o "$RT/$ZIP" -d "$RT"
  rm -f "$RT/$ZIP"
fi
[ -d "$P/.godot" ] || "$G" --headless --path "$P" --import >/dev/null 2>&1
exec "$G" --path "$P" -- "$@"
