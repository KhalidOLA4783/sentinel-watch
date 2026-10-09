@echo off
title SentinelWatch - Test du Statut de Surveillance Automatique
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - VERIFICATION DU STATUT DE LA SURVEILLANCE
echo ======================================================================
echo.

set "TASK_NAME=SentinelWatch_EDR_Daemon"

rem 1. Verification de l'existence de la tache planifiee
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [X] LA SURVEILLANCE N'EST PAS ENCORE ACTIVEE !
    echo.
    echo La tache Windows "%TASK_NAME%" n'a pas encore ete enregistree.
    echo.
    echo Veuillez double-cliquer sur :
    echo   ACTIVER_SURVEILLANCE_AUTOMATIQUE.bat
    echo et acceptez "Oui" dans la fenetre d'autorisation Windows.
    echo.
    echo ======================================================================
    pause
    exit /b 1
)

echo [OK] La tache de surveillance "%TASK_NAME%" est bien activee dans Windows !
echo.
echo --- DETAILS DU PLANIFICATEUR DE TACHES ---
schtasks /query /tn "%TASK_NAME%" /fo LIST | findstr /i "Nom TaskName Statut Status Prochaine Next Dernier Last"
echo.

echo ======================================================================
echo Lancement d'un scan de test immediat en arriere-plan...
schtasks /run /tn "%TASK_NAME%" >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [OK] Le scan de test a ete declenche en arriere-plan avec succes !
    echo.
    echo Les donnees de votre PC sont transmises au Cloud :
    echo https://sentinel-watch-ssty.onrender.com/dashboard
    echo.
    echo Ouvrez la page ci-dessus dans votre navigateur :
    echo vous verrez apparaitre le nom de votre PC et son score de securite !
) else (
    echo [!] Impossible de forcer le declenchement immediat.
)

echo ======================================================================
echo.
pause
