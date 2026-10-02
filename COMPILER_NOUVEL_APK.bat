@echo off
title SentinelWatch - Compilation du Nouvel APK Android
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - COMPILATION DU NOUVEL APK (AVEC CONNEXION)
echo ======================================================================
echo.
echo [1/3] Configuration de l'environnement Java OpenJDK 17...
set "JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo.
echo [2/3] Compilation Flutter APK Release en cours...
echo (Veuillez patienter 1 a 2 minutes pendant la compilation)
echo.

cd sentinel-watch\mobile
call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] La compilation a echoue. Verifiez que Flutter est bien accessible.
    pause
    exit /b %ERRORLEVEL%
)

cd /d "%~dp0"

echo.
echo [3/3] Copie de l'APK vers la racine...
if exist "sentinel-watch\mobile\build\app\outputs\flutter-apk\app-release.apk" (
    copy /y "sentinel-watch\mobile\build\app\outputs\flutter-apk\app-release.apk" "SentinelWatch.apk"
    echo.
    echo ======================================================================
    echo   [SUCCES TOTAL] Votre nouvel APK a ete genere avec succes !
    echo ======================================================================
    echo.
    echo Fichier cree : %~dp0SentinelWatch.apk
    echo.
    echo Ce nouvel APK comprend :
    echo   1. Le systeme de Connexion / Creation de compte utilisateur
    echo   2. L'autorisation reseau HTTP Wi-Fi vers votre PC (10.20.4.12)
    echo   3. Le Pilote Autonome de securite (remediation 1-clic sur mobile)
    echo.
    echo Envoyez ce fichier "SentinelWatch.apk" sur votre smartphone
    echo (via WhatsApp Web, Bluetooth, Telegram ou cable USB),
    echo puis installez-le et connectez-vous avec :
    echo   - Nom d'utilisateur : admin
    echo   - Mot de passe : Admin123!
    echo ======================================================================
) else (
    echo [ERREUR] Le fichier APK n'a pas ete trouve.
)

echo.
pause
