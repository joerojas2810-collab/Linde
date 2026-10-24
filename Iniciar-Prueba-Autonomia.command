#!/bin/bash
# Prueba optativa; partida separada de la partida habitual.
set -euo pipefail
LINDE_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$LINDE_DIR/Iniciar-Cenital.command" --autonomia --guardado=user://prueba_autonomia.json "$@"
