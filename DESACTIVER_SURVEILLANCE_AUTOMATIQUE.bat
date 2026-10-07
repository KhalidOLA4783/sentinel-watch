@echo off
title SentinelWatch - Desactivation de la Surveillance Automatique
cd /d "%~dp0"

:: Verification des privileges administrateur et elevation automatique
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Demande des droits administrateur...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo    SENTINELWATCH - DESACTIVATION DE LA SURVEILLANCE AUTOMATIQUE
echo ======================================================================
echo.

set "TASK_NAME=SentinelWatch_EDR_Daemon"

schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [SUCCES] La tache de fond automatique a ete supprimee avec succes.
    echo Votre PC ne sera plus scanne automatiquement en arriere-plan.
) else (
    echo [NOTE] Aucune tache de surveillance active n'a ete trouvee.
)

echo.
pause
