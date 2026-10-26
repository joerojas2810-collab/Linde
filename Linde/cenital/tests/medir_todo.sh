#!/bin/bash
# Ejecuta la batería de medición de Mundo 1 con configuraciones FIJAS y guarda cada salida en una carpeta.
# Uso:       Linde/cenital/tests/medir_todo.sh [carpeta_salida]        (por defecto, una carpeta temporal)
# Comparar:  Linde/cenital/tests/medir_todo.sh --comparar <carpeta_base> <carpeta_nueva>
#            muestra las diferencias de las líneas deterministas (MEDIDA_CONFIG/ESTADO/HITO/FALLO); ignora MEDIDA_CPU.
# Variables: GODOT (ruta al ejecutable). Duración aproximada: 3-4 minutos. No guarda partidas ni modifica el juego.
set -u
R="$(cd "$(dirname "$0")/../../.." && pwd)"
P="$R/Linde/cenital"
if [ "${1:-}" = "--comparar" ]; then
  base="$2"; nueva="$3"; dif=0
  for f in "$base"/*.txt; do
    n="$(basename "$f")"
    if ! diff <(grep -E '^MEDIDA_(CONFIG|ESTADO|HITO|FALLO)' "$f" | sed 's/ godot=[^ ]*//') <(grep -E '^MEDIDA_(CONFIG|ESTADO|HITO|FALLO)' "$nueva/$n" 2>/dev/null | sed 's/ godot=[^ ]*//') >/dev/null; then
      echo "DIFERENTE: $n"; dif=1
      diff <(grep -E '^MEDIDA_(CONFIG|ESTADO|HITO|FALLO)' "$f") <(grep -E '^MEDIDA_(CONFIG|ESTADO|HITO|FALLO)' "$nueva/$n" 2>/dev/null) | head -20
    else echo "igual:     $n"; fi
  done
  exit $dif
fi
G="${GODOT:-$R/herramientas/runtime/Godot.app/Contents/MacOS/Godot}"
[ -x "$G" ] || { echo "No se encuentra Godot en $G (define GODOT)." >&2; exit 2; }
S="${1:-$(mktemp -d "${TMPDIR:-/tmp}/linde-medir.XXXXXX")}"
mkdir -p "$S"
S="$(cd "$S" && pwd)"   # ruta absoluta: Godot resuelve --log-file respecto del proyecto
corre() {  # nombre script args...
  local n="$1" s="$2"; shift 2
  "$G" --headless --path "$P" --log-file "$S/$n.log" -s "res://tests/$s.gd" -- "$@" > "$S/$n.raw" 2>&1
  grep -E '^(MEDIDA_|SCRIPT ERROR|ERROR: Failed)' "$S/$n.raw" > "$S/$n.txt"
  rm -f "$S/$n.raw" "$S/$n.log"
  echo "$n: $(grep -c '^MEDIDA_' "$S/$n.txt") líneas"
}
corre inicio medir_inicio semillas=200 visibilidad=20
for s in 123 456 7 42 99; do corre "ritmo-s$s" medir_ritmo semilla=$s; done
for s in 123 456; do corre "equivalencia-s$s-d4" medir_equivalencia semilla=$s dias=4; done
echo "Salida en: $S"
