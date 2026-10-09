@echo off
title SentinelWatch - Synchronisation avec GitHub
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - SYNCHRONISATION DU PROJET SUR GITHUB
echo ======================================================================
echo.
echo Ce script envoie automatiquement vos dernieres modifications sur GitHub :
echo   - Le nouveau README.md complet (avec les 4 methodes d'utilisation)
echo   - La suppression des anciens scripts de test et indices
echo   - Le nouveau systeme de securite et de changement d'identifiants
echo   - La console Web et l'application mobile actualisees
echo.

echo [1/3] Preparation des fichiers modifies (git add)...
git add -A

echo.
echo [2/3] Creation du commit...
git commit -m "docs & feat: v0.3 - integration des 4 methodes autonomes, nouveau README et durcissement securite"

echo.
echo [3/3] Envoi vers GitHub (git push origin main)...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================================
    echo   [SUCCES TOTAL] Votre depot GitHub a ete mis a jour !
    echo   Actualisez votre navigateur sur GitHub pour voir apparaitre
    echo   la nouvelle presentation sans les anciens scripts.
    echo ======================================================================
) else (
    echo.
    echo [INFO] Si une invite d'authentification s'affiche, validez-la pour finaliser l'envoi.
)

echo.
pause
