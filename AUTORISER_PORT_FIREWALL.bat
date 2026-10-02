@echo off
title SentinelWatch - Autoriser l'acces du telephone
cd /d "%~dp0"

:: Verification des droits administrateur et auto-elevation
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Demande des droits administrateur...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ======================================================================
echo    OUVERTURE DU PORT 8000 POUR VOTRE SMARTPHONE (PARE-FEU WINDOWS)
echo ======================================================================
echo.

rem Supprime l'ancienne regle si elle existait
netsh advfirewall firewall delete rule name="SentinelWatch Port 8000" >nul 2>&1

rem Cree la regle sur TOUS les profils reseau (Prive, Public, Domaine)
netsh advfirewall firewall add rule name="SentinelWatch Port 8000" dir=in action=allow protocol=TCP localport=8000 profile=any >nul 2>&1

if %errorlevel% equ 0 (
    echo ======================================================================
    echo   [SUCCES TOTAL] Le pare-feu autorise desormais votre telephone !
    echo   Le port 8000 est ouvert sur tous les types de reseau Wi-Fi.
    echo ======================================================================
) else (
    echo [ERREUR] Impossible d'ajouter la regle de pare-feu.
)

echo.
echo Adresse a verifier :
powershell.exe -NoProfile -Command "$ips = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -match '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))' }).IPAddress; foreach ($ip in $ips) { Write-Host '>> ' -NoNewline; Write-Host ('http://' + $ip + ':8000/api/v1') -ForegroundColor Green }"

echo.
pause
