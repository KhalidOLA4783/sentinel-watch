@echo off
title SentinelWatch - Modification des Identifiants Administrateur
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - MODIFICATION DES IDENTIFIANTS ADMINISTRATEUR
echo ======================================================================
echo.
echo Ce script met a jour votre identifiant et votre mot de passe
echo directement sur le serveur Cloud (https://sentinel-watch-ssty.onrender.com).
echo.

set /p "CURRENT_USER=Identifiant actuel [Appuyez sur Entree pour 'admin'] : "
if "%CURRENT_USER%"=="" set "CURRENT_USER=admin"

set /p "CURRENT_PASS=Mot de passe actuel : "
if "%CURRENT_PASS%"=="" (
    echo.
    echo [ERREUR] Le mot de passe actuel ne peut pas etre vide.
    echo.
    pause
    exit /b 1
)

echo.
set /p "NEW_USER=NOUVEL identifiant souhaite : "
if "%NEW_USER%"=="" (
    echo.
    echo [ERREUR] Le nouvel identifiant ne peut pas etre vide.
    echo.
    pause
    exit /b 1
)

set /p "NEW_PASS=NOUVEAU mot de passe souhaite (min. 6 caracteres) : "
if "%NEW_PASS%"=="" (
    echo.
    echo [ERREUR] Le nouveau mot de passe ne peut pas etre vide.
    echo.
    pause
    exit /b 1
)

echo.
echo [1/1] Envoi de la mise a jour vers le serveur Cloud en cours...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$apiUrl = 'https://sentinel-watch-ssty.onrender.com/api/v1/auth/change-credentials';" ^
  "$body = @{" ^
  "  current_username_or_email = '%CURRENT_USER%';" ^
  "  current_password          = '%CURRENT_PASS%';" ^
  "  new_username              = '%NEW_USER%';" ^
  "  new_password              = '%NEW_PASS%'" ^
  "} | ConvertTo-Json;" ^
  "try {" ^
  "  $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 35;" ^
  "  Write-Host '======================================================================' -ForegroundColor Green;" ^
  "  Write-Host '  [SUCCES TOTAL] Vos identifiants ont ete modifies avec succes !' -ForegroundColor Green;" ^
  "  Write-Host '======================================================================' -ForegroundColor Green;" ^
  "  Write-Host ('Nouvel identifiant : ' + $resp.user.username) -ForegroundColor Cyan;" ^
  "  Write-Host ('Organisation       : ' + $resp.user.organization) -ForegroundColor Cyan;" ^
  "  Write-Host '';" ^
  "  Write-Host 'Utilisez desormais ces nouveaux identifiants :' -ForegroundColor White;" ^
  "  Write-Host '  - Sur la console Web (https://sentinel-watch-ssty.onrender.com/dashboard)' -ForegroundColor White;" ^
  "  Write-Host '  - Sur l''application Mobile SentinelWatch' -ForegroundColor White;" ^
  "} catch {" ^
  "  Write-Host '======================================================================' -ForegroundColor Red;" ^
  "  Write-Host '  [ECHEC] Impossible de modifier les identifiants :' -ForegroundColor Red;" ^
  "  Write-Host '======================================================================' -ForegroundColor Red;" ^
  "  Write-Host $_.Exception.Message -ForegroundColor Yellow;" ^
  "  if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }" ^
  "}"

echo.
echo ======================================================================
pause
