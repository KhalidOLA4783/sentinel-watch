@echo off
title SentinelWatch - Adresse IP pour Smartphone
echo ======================================================================
echo    ADRESSE A ENTRER DANS L'APPLICATION MOBILE SUR VOTRE TELEPHONE
echo ======================================================================
echo.

powershell.exe -NoProfile -Command "$ips = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -match '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))' }).IPAddress; if ($ips) { foreach ($ip in $ips) { Write-Host '>> Tapez exactement ceci dans l''app : ' -NoNewline; Write-Host ('http://' + $ip + ':8000/api/v1') -ForegroundColor Green } } else { Write-Host '>> Tapez : http://192.168.X.X:8000/api/v1 (remplacez par votre IP Wi-Fi)' -ForegroundColor Yellow }"

echo.
echo ======================================================================
echo RAPPEL : Votre telephone et votre PC doivent etre connectes sur le
echo MEME reseau Wi-Fi (meme Box Internet ou partage de connexion).
echo ======================================================================
echo.
pause
