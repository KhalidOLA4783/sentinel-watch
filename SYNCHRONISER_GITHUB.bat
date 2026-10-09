@echo off
title SentinelWatch - Synchronisation GitHub
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - SAUVEGARDE ET SYNCHRONISATION GITHUB
echo ======================================================================
echo.

if exist "sentinel-watch\.git" (
    cd sentinel-watch
)

git status
echo.
echo Ajout des fichiers modifies...
git add .
git commit -m "feat: portail multi-tenant, cle agent secrete et deployeur 1-clic"
git push origin main

echo.
echo ======================================================================
echo   [TERMINE] Code source synchronise avec succes sur GitHub !
echo   Depot : https://github.com/KhalidOLA4783/sentinel-watch
echo ======================================================================
pause
