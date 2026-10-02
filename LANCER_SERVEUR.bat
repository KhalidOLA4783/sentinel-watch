@echo off
title SentinelWatch - Serveur Central SOC
cd /d "%~dp0sentinel-watch\backend"

echo ======================================================================
echo    SENTINELWATCH - DEMARRAGE DU SERVEUR SOC
echo ======================================================================
echo Chargement des modules IA et demarrage de l'API...
echo.

rem Attendre 5 secondes que le serveur Python charge scikit-learn puis ouvrir le navigateur
start "" cmd /c "timeout /t 5 /nobreak >nul & start http://127.0.0.1:8000/dashboard"

if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe main.py
) else (
    python main.py
)

pause
