@echo off
setlocal
cd /d "%~dp0"
py -3 -m venv .venv
if errorlevel 1 (
  echo Instala Python 3.11 o posterior desde python.org y vuelve a ejecutar este archivo.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" -m pip install -r servidor\cuentas\requirements.txt
if errorlevel 1 (pause & exit /b 1)
echo Cuentas instaladas. Abre Iniciar-Servidor.bat para configurar el servidor.
pause
