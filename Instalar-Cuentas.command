#!/bin/sh
set -eu
cd "$(dirname "$0")"
python3 -m venv .venv
.venv/bin/python -m pip install -r servidor/cuentas/requirements.txt
printf '\nCuentas instaladas. Iniciar-Cenital.command --pantalla=servidor\n'
