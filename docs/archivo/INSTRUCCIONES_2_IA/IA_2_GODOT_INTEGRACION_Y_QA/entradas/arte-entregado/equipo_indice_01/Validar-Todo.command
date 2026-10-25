#!/bin/zsh
set -e
DIRECTORIO_EQUIPO="${0:A:h}"
MOTOR_EQUIPO="$DIRECTORIO_EQUIPO/../../../../herramientas/runtime/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$MOTOR_EQUIPO" ]]; then
 MOTOR_EQUIPO="/Users/josephrojas/Desktop/RPG-Mundo-Vivo-2026-10-23/herramientas/runtime/Godot.app/Contents/MacOS/Godot"
fi
if [[ ! -x "$MOTOR_EQUIPO" ]]; then
 print 'No se encontró Godot; utiliza el comando de LEEME.md con tu instalación.'
 exit 1
fi
mkdir -p "$DIRECTORIO_EQUIPO/informes_revalidacion"
for HOJA_EQUIPO in "$DIRECTORIO_EQUIPO"/hojas/*.png; do
 NOMBRE_EQUIPO="${HOJA_EQUIPO:t:r}"
 "$MOTOR_EQUIPO" --headless --path "$DIRECTORIO_EQUIPO" --script "$DIRECTORIO_EQUIPO/herramientas/validar_hoja.gd" -- "$HOJA_EQUIPO" --celda=32 --modo=indice --base="$DIRECTORIO_EQUIPO/base/caminata.png" --json="$DIRECTORIO_EQUIPO/informes_revalidacion/$NOMBRE_EQUIPO.json"
done
print 'Validación terminada. Revisa también los avisos de cada informe.'
