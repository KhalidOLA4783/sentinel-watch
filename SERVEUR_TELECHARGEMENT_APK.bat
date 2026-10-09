@echo off
title SentinelWatch - Telecharger APK sur Smartphone
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - TRANSFERT RAPIDE DE L'APK SUR SMARTPHONE
echo ======================================================================
echo.

if not exist "SentinelWatch.apk" (
    echo [ATTENTION] Le fichier SentinelWatch.apk n'existe pas encore.
    echo Double-cliquez d'abord sur COMPILER_NOUVEL_APK.bat pour le fabriquer.
    echo.
    pause
    exit /b
)

echo [OK] SentinelWatch.apk est pret pour l'installation !
echo.
echo ----------------------------------------------------------------------
echo  3 FACONS SIMPLES D'ENVOYER L'APK SUR VOTRE SMARTPHONE :
echo ----------------------------------------------------------------------
echo.
echo  1. VIA WHATSAPP WEB / TELEGRAM :
echo     Glissez-deposez "SentinelWatch.apk" dans une conversation avec vous-meme.
echo.
echo  2. VIA CABLE USB :
echo     Branchez votre telephone et copiez "SentinelWatch.apk" dans "Downloads".
echo.
echo  3. EN DIRECT VIA WI-FI :
echo     Connectez votre telephone au meme Wi-Fi que ce PC,
echo     puis ouvrez Chrome sur votre telephone et allez sur l'une de ces adresses :
echo.
powershell.exe -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { Write-Host ('     --> http://' + $_.IPAddress + ':8080/SentinelWatch.apk') -ForegroundColor Cyan }"
echo.
echo ======================================================================
echo Lancement du serveur de telechargement Wi-Fi (Port 8080)...
echo (Fermez cette fenetre une fois le fichier telecharge sur votre mobile)
echo ======================================================================
echo.

python -m http.server 8080
pause
