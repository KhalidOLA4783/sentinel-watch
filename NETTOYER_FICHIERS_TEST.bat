@echo off
title SentinelWatch - Nettoyage des fichiers de test
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - NETTOYAGE DES FICHIERS DE TEST ET DE SIMULATION
echo ======================================================================
echo.

if exist "SIMULER_ATTAQUE_TEST.bat" (
    del /f /q "SIMULER_ATTAQUE_TEST.bat"
    echo [OK] Fichier de simulation 'SIMULER_ATTAQUE_TEST.bat' supprime avec succes.
) else (
    echo [INFO] Le fichier 'SIMULER_ATTAQUE_TEST.bat' a deja ete supprime.
)

echo.
echo ======================================================================
echo  Nettoyage termine ! Votre environnement est 100%% propre.
echo ======================================================================
echo.
pause
