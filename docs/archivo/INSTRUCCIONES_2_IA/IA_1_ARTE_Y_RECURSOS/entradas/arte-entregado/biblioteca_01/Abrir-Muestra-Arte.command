#!/bin/zsh
set -e
DIRECTORIO_ARTE="${0:A:h}"
MOTOR_ARTE="$DIRECTORIO_ARTE/../../../../herramientas/runtime/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$MOTOR_ARTE" ]]; then
 MOTOR_ARTE="/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/herramientas/runtime/Godot.app/Contents/MacOS/Godot"
fi
if [[ ! -x "$MOTOR_ARTE" ]]; then
 print 'Abre mapa_muestra/project.godot con tu instalación de Godot.'
 exit 1
fi
"$MOTOR_ARTE" --headless --editor --path "$DIRECTORIO_ARTE/mapa_muestra" --import --quit
exec "$MOTOR_ARTE" --path "$DIRECTORIO_ARTE/mapa_muestra" -- --nueva=7 --ir=27,24 --guardado="$DIRECTORIO_ARTE/mapa_muestra/partida_prueba_arte.json"
