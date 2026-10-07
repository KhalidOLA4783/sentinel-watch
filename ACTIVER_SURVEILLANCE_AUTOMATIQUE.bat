@echo off
title SentinelWatch - Activation de la Surveillance EDR Automatique
cd /d "%~dp0"

:: Verification des privileges administrateur et elevation automatique
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Demande des droits administrateur...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo    SENTINELWATCH - SURVEILLANCE AUTOMATIQUE EN TACHE DE FOND (24H/24)
echo ======================================================================
echo.
echo Configuration du Planificateur de Taches Windows...
echo.

set "SCRIPT_PATH=%~dp0sentinel-watch\agent\sentinel_audit.ps1"
set "TASK_NAME=SentinelWatch_EDR_Daemon"
set "API_URL=https://sentinel-watch-ssty.onrender.com/api/v1/audits"

rem 1. Supprime l'ancienne tache si elle existait deja
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

rem 2. Cree la tache planifiee qui s'execute TOUTES LES HEURES de facon 100%% invisible
set "CMD_ACTION=powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%SCRIPT_PATH%\" -ApiUrl \"%API_URL%\""

schtasks /create /tn "%TASK_NAME%" /tr "%CMD_ACTION%" /sc HOURLY /mo 1 /ru "SYSTEM" /f >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
    rem Fallback sans privilege SYSTEM (avec le compte utilisateur courant)
    schtasks /create /tn "%TASK_NAME%" /tr "%CMD_ACTION%" /sc HOURLY /mo 1 /f >nul 2>&1
)

if %ERRORLEVEL% EQU 0 (
    echo ======================================================================
    echo   [SUCCES TOTAL] LA SURVEILLANCE AUTOMATIQUE EST ACTIVEE !
    echo ======================================================================
    echo.
    echo Comment cela fonctionne desormais :
    echo   - Votre PC est analyse silencieusement toutes les heures.
    echo   - AUCUNE fenetre noire ne s'ouvrira pour vous deranger.
    echo   - Votre note de securite et vos failles sont envoyees au Cloud.
    echo   - Vous n'avez plus JAMAIS besoin de cliquer sur LANCER_AUDIT !
    echo.
    echo Execution du premier scan immediat en arriere-plan...
    schtasks /run /tn "%TASK_NAME%" >nul 2>&1
    echo [OK] Premier scan lance avec succes.
) else (
    echo [ERREUR] Impossible de planifier la tache automatique.
)

echo.
echo Pour arreter cette surveillance un jour, utilisez :
echo DESACTIVER_SURVEILLANCE_AUTOMATIQUE.bat
echo ======================================================================
echo.
pause
