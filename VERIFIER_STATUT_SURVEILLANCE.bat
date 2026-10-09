@echo off
title SentinelWatch - Statut de la Surveillance EDR Automatique
cd /d "%~dp0"

echo ======================================================================
echo    SENTINELWATCH - VERIFICATION DU STATUT DE LA SURVEILLANCE WINDOWS
echo ======================================================================
echo.

powershell.exe -NoProfile -Command ^
    "$taskName = 'SentinelWatch_EDR_Daemon'; " ^
    "$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue; " ^
    "if ($null -eq $task) { " ^
    "    Write-Host '[STATUT] : INACTIF' -ForegroundColor Red; " ^
    "    Write-Host 'La tache planifiee SentinelWatch n''est pas encore installee sur ce poste.' -ForegroundColor Yellow; " ^
    "    Write-Host 'Pour l''activer, double-cliquez sur ACTIVER_SURVEILLANCE_AUTOMATIQUE.bat' -ForegroundColor Cyan; " ^
    "} else { " ^
    "    $info = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue; " ^
    "    Write-Host '[STATUT] : ACTIF ET FONCTIONNEL' -ForegroundColor Green; " ^
    "    Write-Host ('  Nom de la tache   : ' + $task.TaskName) -ForegroundColor Cyan; " ^
    "    Write-Host ('  Etat actuel       : ' + $task.State) -ForegroundColor Cyan; " ^
    "    if ($info) { " ^
    "        Write-Host ('  Derniere execution: ' + $info.LastRunTime) -ForegroundColor White; " ^
    "        Write-Host ('  Code retour       : ' + $info.LastTaskResult) -ForegroundColor White; " ^
    "        Write-Host ('  Prochaine analyse : ' + $info.NextRunTime) -ForegroundColor White; " ^
    "    } " ^
    "    Write-Host ''; " ^
    "    Write-Host 'Le demon EDR veille silencieusement et transmet les audits vers le Cloud.' -ForegroundColor Green; " ^
    "}"

echo.
echo ======================================================================
echo Options :
echo   [1] Lancer un audit de securite immediat pour verifier la liaison Cloud
echo   [2] Quitter
echo ======================================================================
set /p "CHOIX=Votre choix (1 ou 2) : "

if "%CHOIX%"=="1" (
    echo.
    echo Lancement d'une analyse ponctuelle avec transmission au Cloud...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sentinel-watch\agent\sentinel_audit.ps1" -ApiUrl "https://sentinel-watch-ssty.onrender.com/api/v1/audits"
)

echo.
pause
