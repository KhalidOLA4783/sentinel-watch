@echo off
title SentinelWatch - Modification des Identifiants Administrateur
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - MODIFICATION DES IDENTIFIANTS ADMINISTRATEUR
echo ======================================================================
echo.
echo Ce script met a jour de facon securisee vos acces sur le Cloud :
echo Serveur : https://sentinel-watch-ssty.onrender.com
echo.

set /p "CURRENT_USER=Identifiant ou email actuel : "
if "%CURRENT_USER%"=="" (
    echo [ERREUR] L'identifiant actuel ne peut pas etre vide.
    pause
    exit /b 1
)

set /p "CURRENT_PASS=Mot de passe actuel : "
if "%CURRENT_PASS%"=="" (
    echo [ERREUR] Le mot de passe actuel ne peut pas etre vide.
    pause
    exit /b 1
)

echo.
set /p "NEW_USER=Nouveau nom d'utilisateur (laisser vide pour conserver) : "
set /p "NEW_PASS=Nouveau mot de passe (min. 6 caracteres) : "

if "%NEW_PASS%"=="" (
    echo [ERREUR] Le nouveau mot de passe ne peut pas etre vide.
    pause
    exit /b 1
)

echo.
echo Envoi de la mise a jour au serveur Cloud en cours...
echo.

powershell.exe -NoProfile -Command ^
    "$body = @{ current_username_or_email = '%CURRENT_USER%'; current_password = '%CURRENT_PASS%'; new_username = '%NEW_USER%'; new_password = '%NEW_PASS%' } | ConvertTo-Json; " ^
    "try { " ^
    "    $res = Invoke-RestMethod -Uri 'https://sentinel-watch-ssty.onrender.com/api/v1/auth/change-credentials' -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 30; " ^
    "    Write-Host '======================================================================' -ForegroundColor Green; " ^
    "    Write-Host '  [SUCCES] Vos nouveaux identifiants ont ete enregistres avec succes !' -ForegroundColor Green; " ^
    "    Write-Host '======================================================================' -ForegroundColor Green; " ^
    "    Write-Host ('  Utilisateur : ' + $res.user.username) -ForegroundColor Cyan; " ^
    "    Write-Host ('  Email       : ' + $res.user.email) -ForegroundColor Cyan; " ^
    "    Write-Host ('  Organisation: ' + $res.user.organization) -ForegroundColor Cyan; " ^
    "    Write-Host ''; " ^
    "    Write-Host 'Vous pouvez des a present vous connecter avec ces nouveaux acces sur le Dashboard Web et l''application Mobile.' -ForegroundColor Yellow; " ^
    "} catch { " ^
    "    Write-Host '======================================================================' -ForegroundColor Red; " ^
    "    Write-Host '  [ERREUR] La modification a echoue.' -ForegroundColor Red; " ^
    "    Write-Host '======================================================================' -ForegroundColor Red; " ^
    "    if ($_.Exception.Response) { " ^
    "        $stream = $_.Exception.Response.GetResponseStream(); " ^
    "        $reader = New-Object System.IO.StreamReader($stream); " ^
    "        $errText = $reader.ReadToEnd(); " ^
    "        Write-Host ('  Detail : ' + $errText) -ForegroundColor Yellow; " ^
    "    } else { " ^
    "        Write-Host ('  Detail : ' + $_.Exception.Message) -ForegroundColor Yellow; " ^
    "    } " ^
    "}"

echo.
pause
