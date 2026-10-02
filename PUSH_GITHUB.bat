@echo off
title SentinelWatch - Publication sur GitHub
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - PUBLICATION DU PROJET SUR GITHUB
echo ======================================================================
echo.

rem 1. Verification de Git
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Git n'est pas installe ou pas accessible dans votre PATH.
    echo Telechargez et installez Git depuis : https://git-scm.com/
    pause
    exit /b 1
)

echo [1/4] Initialisation du depot Git...
if not exist ".git" (
    git init
    echo    [OK] Depot Git local initialise.
) else (
    echo    [OK] Depot Git deja present.
)

echo.
echo [2/4] Verification du fichier .gitignore...
if exist ".gitignore" (
    echo    [OK] .gitignore actif (les caches, venv et gros binaires APK sont exclus).
) else (
    echo    [ATTENTION] Fichier .gitignore absent !
)

echo.
echo [3/4] Indexation et commit des fichiers...
git add .
git commit -m "feat: SentinelWatch SOC - Threat Detection, EDR Endpoint Auditor & Flutter Mobile Console"

echo.
echo [4/4] Configuration de la branche principale...
git branch -M main

echo.
echo ======================================================================
echo    CONNEXION A VOTRE REPETOIRE GITHUB DISTANT
echo ======================================================================
echo.
git remote -v >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Depot distant deja configure.
    git remote -v
    echo.
    set /p REPO_CHOICE="Voulez-vous pousser directement vers ce depot ? (O/N) : "
    if /i "%REPO_CHOICE%"=="O" (
        git push -u origin main
        echo.
        echo [SUCCES] Projet publie sur GitHub avec succes !
        pause
        exit /b 0
    )
)

echo.
echo Veuillez creer un depot vide sur https://github.com/new
echo (Nom suggere : sentinel-watch)
echo.
set /p REPO_URL="Collez ici l'URL HTTPS de votre depot GitHub (ex: https://github.com/votre-nom/sentinel-watch.git) : "

if "%REPO_URL%"=="" (
    echo [ANNULE] Aucune URL saisie.
    pause
    exit /b 1
)

git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%

echo.
echo Envoi en cours vers GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================================
    echo   [SUCCES TOTAL] Votre projet SentinelWatch est en ligne sur GitHub !
    echo ======================================================================
) else (
    echo.
    echo [NOTE] Si GitHub vous demande une authentification :
    echo Utilisez votre compte GitHub ou un 'Personal Access Token' (PAT).
)

echo.
pause
