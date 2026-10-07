@echo off
title SentinelWatch - Synchronisation GitHub
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - SAUVEGARDE ET SYNCHRONISATION GITHUB
echo ======================================================================
echo.

git status
echo.
echo Ajout des fichiers modifies...
git add .
git commit -m "feat: surveillance automatique en arriere-plan et cloud endpoint mobile"
git push origin main

echo.
echo ======================================================================
echo   [TERMINE] Code source synchronise avec succes sur GitHub !
echo   Depot : https://github.com/KhalidOLA4783/sentinel-watch
echo ======================================================================
pause
