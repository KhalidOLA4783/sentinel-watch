@echo off
title SentinelWatch - Simulation d'Attaque Cyber en Temps Reel
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - SIMULATION D'ATTAQUE CYBER EN DIRECT
echo ======================================================================
echo.
echo Ce test va injecter une attaque par force brute (5 tentatives d'intrusion)
echo vers votre serveur Cloud : https://sentinel-watch-ssty.onrender.com
echo.
echo Gardez votre navigateur ouvert sur :
echo   https://sentinel-watch-ssty.onrender.com/dashboard
echo.
pause

echo.
echo [1/2] Envoi de l'attaque en cours...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$apiUrl = 'https://sentinel-watch-ssty.onrender.com/api/v1/logs';" ^
  "for ($i=1; $i -le 5; $i++) {" ^
  "  $body = @{ user_identifier='admin_root'; organization='SentinelWatch SOC'; ip_address='185.220.101.5'; country_code='RU'; city='Moscow'; latitude=55.75; longitude=37.61; http_method='POST'; endpoint='/api/v1/auth/login'; http_status=401; response_time_ms=120 } | ConvertTo-Json;" ^
  "  try { Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 20 | Out-Null; Write-Host \"  - Tentative $i/5 injectee...\" -ForegroundColor Yellow } catch { Write-Host \"  - Echec $i : $($_.Exception.Message)\" -ForegroundColor Red }" ^
  "}"

echo.
echo [2/2] Resultat de la simulation :
echo ======================================================================
echo  REGARDEZ VOTRE TABLEAU DE BORD DANS VOTRE NAVIGATEUR :
echo  https://sentinel-watch-ssty.onrender.com/dashboard
echo.
echo  1. Une ALERTE ROUGE CLIGNOTANTE 'BRUTE_FORCE' apparait !
echo  2. L'adresse IP attaquante '185.220.101.5' est affichee avec Moscou, Russie.
echo  3. Cliquez sur le bouton rouge 'Bannir l'IP' pour tester la riposte.
echo ======================================================================
echo.
pause
