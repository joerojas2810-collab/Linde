#!/bin/bash
# Ejecuta las suites vigentes de Linde (22 previas a I1a + operadores + dos suites visuales A1–A3), una tras otra, y escribe un resumen único.
# Uso:  Linde/cenital/tests/ejecutar_suites.sh [suite ...]     (sin argumentos: todas)
# Variables: GODOT (ruta al ejecutable), SALIDA (carpeta de logs; por defecto una temporal).
# Código de salida: 0 si todas pasan; 1 si alguna falla; 2 si falta el ejecutable de Godot.
# Una suite pasa si Godot sale con 0, imprime al menos una línea PASS/OK, ninguna FAIL y ningún SCRIPT ERROR.
# prueba_red se lee de tests/resultados_red.txt. Las suites *_red reescriben los .json de production/qa/evidence/{terreno,crecimiento};
# revisa `git status` tras ejecutar y restaura lo que no quieras conservar.
# Los avisos de recursos al cerrar son conocidos (ESTADO.md §3) y no cuentan.
set -u
R="$(cd "$(dirname "$0")/../../.." && pwd)"
P="$R/Linde/cenital"
G="${GODOT:-$R/herramientas/runtime/Godot.app/Contents/MacOS/Godot}"
[ -x "$G" ] || { echo "No se encuentra Godot en $G (define GODOT o ejecuta Iniciar-Cenital.command una vez)." >&2; exit 2; }
SALIDA="${SALIDA:-$(mktemp -d "${TMPDIR:-/tmp}/linde-suites.XXXXXX")}"
mkdir -p "$SALIDA"

SUITES=(prueba prueba_reglas prueba_saberes prueba_desarrollo prueba_sociedad prueba_autonomia
        prueba_arraigo prueba_casas_arraigo prueba_aspecto prueba_ui prueba_proteccion prueba_terreno
        prueba_fauna prueba_habitats prueba_distribucion_fauna prueba_orden_dibujo prueba_caminos prueba_campos_cultivo prueba_casas
        prueba_crecimiento prueba_carga_crecimiento prueba_poblados prueba_aparicion prueba_amenazas prueba_poblado_inicial
        prueba_lugares prueba_lugares_ui prueba_lugares_red prueba_preexistentes prueba_preexistentes_ui prueba_preexistentes_red prueba_vivienda prueba_vivienda_ui prueba_vivienda_red prueba_taller prueba_taller_ui prueba_taller_red prueba_exploracion prueba_exploracion_ui prueba_pistas prueba_pistas_ui prueba_orientacion_red prueba_red prueba_terreno_red prueba_crecimiento_red prueba_operadores prueba_integracion_visual_a prueba_correcciones_a2_a3)
[ $# -gt 0 ] && SUITES=("$@")
[ $# -eq 0 ] && export LINDE_VALIDACION_COMPLETA=1

# La red usa clientes reales y deja user://pruebas_linde/; se importa una vez para que res:// esté al día.
[ -d "$P/.godot" ] || "$G" --headless --path "$P" --import --log-file "$SALIDA/import.log" >/dev/null 2>&1

fallidas=0; total=0
printf "%-26s %5s %6s %6s  %s\n" SUITE SALIDA PASS FAIL RESULTADO
for s in "${SUITES[@]}"; do
  total=$((total+1))
  out="$SALIDA/$s.out"
  "$G" --headless --path "$P" --log-file "$SALIDA/$s.log" --script "res://tests/$s.gd" >"$out" 2>&1
  rc=$?
  pass=$(grep -cE '^(PASS|OK)' "$out"); fail=$(grep -cE '^FAIL' "$out"); err=$(grep -c 'SCRIPT ERROR' "$out")
  if [ "$s" = prueba_red ]; then   # esta suite no imprime por consola: escribe tests/resultados_red.txt
    pass=$(grep -c '^\[OK\]' "$P/tests/resultados_red.txt" 2>/dev/null); fail=$(grep -c '^\[FALLO\]' "$P/tests/resultados_red.txt" 2>/dev/null)
  fi
  if [ $rc -eq 0 ] && [ "$pass" -gt 0 ] && [ "$fail" -eq 0 ] && [ "$err" -eq 0 ]; then res=OK; else res=FALLA; fallidas=$((fallidas+1)); fi
  printf "%-26s %5s %6s %6s  %s\n" "$s" "$rc" "$pass" "$fail" "$res"
done
echo "---"
echo "$((total-fallidas)) de $total suites sin fallos. Salidas completas en: $SALIDA"
[ $fallidas -eq 0 ]
