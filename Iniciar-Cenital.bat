@echo off
rem Abre Linde (Windows). Busca Godot 4.7.1: variable GODOT, herramientas\runtime, o lo descarga del release oficial.
setlocal
set "R=%~dp0"
set "P=%R%Linde\cenital"
set "RT=%R%herramientas\runtime"
set "TAG=4.7.1-stable"
set "ZIP=Godot_v4.7.1-stable_win64.exe.zip"
set "SHA=c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1"
set "EXE=%RT%\Godot_v4.7.1-stable_win64.exe"
if defined GODOT set "EXE=%GODOT%"
if not exist "%EXE%" (
  echo Descargando Godot %TAG% ^(una sola vez, ~85 MB^)...
  if not exist "%RT%" mkdir "%RT%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $z='%RT%\%ZIP%'; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/godotengine/godot/releases/download/%TAG%/%ZIP%' -OutFile $z; if ((Get-FileHash $z -Algorithm SHA256).Hash.ToLower() -ne '%SHA%') { Remove-Item $z; throw 'La descarga no coincide con el sha256 oficial' }; Expand-Archive -Force $z '%RT%'; Remove-Item $z"
  if errorlevel 1 (
    echo ERROR: no se pudo descargar o verificar Godot.
    pause
    exit /b 1
  )
)
if not exist "%P%\.godot" "%EXE%" --headless --path "%P%" --import >nul 2>&1
"%EXE%" --path "%P%" -- %*
