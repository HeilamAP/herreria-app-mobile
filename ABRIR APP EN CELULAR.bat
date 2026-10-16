@echo off
title Servidor Celular - Ay Oy Herreria Artistica
cd /d "%~dp0"

echo ================================================================
echo   Iniciando Servidor Movil para iPhone / Celular...
echo ================================================================

if not exist "build\web\index.html" (
    echo Compilando aplicacion web para dispositivo movil...
    call flutter build web --release
)

echo Abriendo pantalla con codigo QR en el navegador...
start "" "http://localhost:8085/qr"

echo.
node server_movil.js

pause
