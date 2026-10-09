# ==============================================================================
# SentinelWatch - Activation de la Surveillance Automatique Windows
# ==============================================================================

# 1. Verification des privileges Administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Elevation des privileges Administrateur requise..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   SENTINELWATCH - ACTIVATION DE LA SURVEILLANCE AUTOMATIQUE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$TaskName = "SentinelWatch_EDR_Daemon"
$AgentScript = Join-Path $PSScriptRoot "sentinel-watch\agent\sentinel_audit.ps1"
$ApiUrl = "https://sentinel-watch-ssty.onrender.com/api/v1/audits"

Write-Host "Script Agent : $AgentScript" -ForegroundColor Gray
Write-Host "Serveur Cloud: $ApiUrl" -ForegroundColor Gray
Write-Host ""

# Verification de la presence du script
if (-not (Test-Path $AgentScript)) {
    Write-Host "[ERREUR] Le fichier agent n'a pas ete trouve a l'emplacement :" -ForegroundColor Red
    Write-Host "  $AgentScript" -ForegroundColor Red
    Write-Host ""
    Read-Host "Appuyez sur Entree pour fermer..."
    exit 1
}

# 2. Suppression de l'ancienne tache si existante
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

# 3. Creation de la nouvelle tache via Register-ScheduledTask
$Created = $false
try {
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$AgentScript`" -ApiUrl `"$ApiUrl`""
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

    $Registered = Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
    if ($Registered) {
        $Created = $true
    }
} catch {
    Write-Host "[INFO] Configuration alternative avec le planificateur standard..." -ForegroundColor Yellow
}

# Fallback si Register-ScheduledTask echoue
if (-not $Created) {
    $RunnerBat = Join-Path $PSScriptRoot "sentinel-watch\agent\run_daemon.bat"
    $schRes = & schtasks /create /tn $TaskName /tr "`"$RunnerBat`"" /sc HOURLY /mo 1 /rl HIGHEST /f 2>&1
    if ($LASTEXITCODE -eq 0) {
        $Created = $true
    } else {
        Write-Host "[ERREUR schtasks] $schRes" -ForegroundColor Red
    }
}

if ($Created) {
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "  [SUCCES TOTAL] LA SURVEILLANCE AUTOMATIQUE EST ACTIVEE !" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Votre PC est desormais securise et surveille :" -ForegroundColor White
    Write-Host "  - Scan automatique effectue toutes les heures." -ForegroundColor White
    Write-Host "  - Execution 100% invisible en arriere-plan (pas de fenetre)." -ForegroundColor White
    Write-Host "  - Donnees transmises en continu a votre serveur Cloud Render." -ForegroundColor White
    Write-Host ""
    Write-Host "Lancement immediat du premier audit de test en arriere-plan..." -ForegroundColor Yellow
    try {
        Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Write-Host "[OK] Premier scan lance avec succes !" -ForegroundColor Green
    } catch {
        & schtasks /run /tn $TaskName >$null 2>&1
        Write-Host "[OK] Premier scan declenche !" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Vous pouvez suivre les resultats en direct sur :" -ForegroundColor Cyan
    Write-Host "  https://sentinel-watch-ssty.onrender.com/dashboard" -ForegroundColor Cyan
} else {
    Write-Host "[ERREUR] Impossible de planifier la surveillance automatique." -ForegroundColor Red
    Write-Host "Verifiez que votre compte possede bien les droits Administrateur." -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Read-Host "Appuyez sur Entree pour fermer cette fenetre..."
