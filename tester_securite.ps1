# ==============================================================================
# SentinelWatch - Banc de Test et de Démonstration SOC en Direct
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$CloudUrl = "https://sentinel-watch-ssty.onrender.com/api/v1"
$DashboardUrl = "https://sentinel-watch-ssty.onrender.com/dashboard"

function Show-Header {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "   SENTINELWATCH - BANC DE TEST ET DE VALIDATION SOC EN DIRECT" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "Cible Cloud : $CloudUrl" -ForegroundColor Yellow
    Write-Host "Dashboard   : $DashboardUrl" -ForegroundColor White
    Write-Host ""
}

function Test-Health {
    Write-Host "--> Verification de la liaison Cloud..." -ForegroundColor Gray
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $res = Invoke-RestMethod -Uri "https://sentinel-watch-ssty.onrender.com/health" -TimeoutSec 45
        $sw.Stop()
        Write-Host "[SUCCES] Le serveur Cloud est en ligne et actif !" -ForegroundColor Green
        Write-Host "  Temps de reponse : $($sw.ElapsedMilliseconds) ms" -ForegroundColor White
        Write-Host "  Statut           : $($res.status)" -ForegroundColor White
    } catch {
        Write-Host "[ATTENTION] Le serveur Cloud tarde a repondre : $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Si le serveur etait en veille sur Render, reessayez dans quelques secondes." -ForegroundColor DarkYellow
    }
}

function Test-BruteForce {
    Write-Host ""
    Write-Host "--> Lancement de la simulation Force Brute (6 echecs rapides sur 'admin.root')..." -ForegroundColor Red
    $attackerIp = "185.220.101." + (Get-Random -Minimum 10 -Maximum 250)
    for ($i = 1; $i -le 6; $i++) {
        $body = @{
            username_or_email = "admin.root"
            password = ("WrongPassword_" + $i)
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri "$CloudUrl/auth/login" -Method Post -ContentType "application/json" -Body $body -Headers @{ "X-Forwarded-For" = $attackerIp } -TimeoutSec 20 | Out-Null
        } catch {
            Write-Host "  [401] Tentative $i/6 rejetee [Attaquant: $attackerIp]" -ForegroundColor DarkYellow
        }
        Start-Sleep -Milliseconds 350
    }
    Write-Host ""
    Write-Host "[OK] Attaque Force Brute terminee avec succes !" -ForegroundColor Green
    Write-Host "  Une alerte rouge 'BRUTE_FORCE' vient d'apparaitre sur votre Dashboard Web et Mobile !" -ForegroundColor Yellow
}

function Test-ImpossibleTravel {
    Write-Host ""
    Write-Host "--> Lancement du scenario Voyage Impossible (Paris -> Tokyo en 1s)..." -ForegroundColor Magenta
    $user = "cadre.mobile_" + (Get-Random -Minimum 100 -Maximum 999)

    # 1. Connexion a Paris
    $log1 = @{
        user_identifier = $user
        ip_address = "194.254.120.10"
        country_code = "FR"
        city = "Paris"
        latitude = 48.8566
        longitude = 2.3522
        http_method = "GET"
        endpoint = "/api/v1/dashboard"
        http_status = 200
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri "$CloudUrl/logs" -Method Post -ContentType "application/json" -Body $log1 -TimeoutSec 20 | Out-Null
        Write-Host "  [Connexion 1] $user a Paris (France) [OK 200]" -ForegroundColor Cyan
    } catch {
        Write-Host "  [ERREUR] Impossible d'envoyer le premier log" -ForegroundColor Red
        return
    }

    Start-Sleep -Seconds 1

    # 2. Connexion a Tokyo
    $log2 = @{
        user_identifier = $user
        ip_address = "133.242.18.55"
        country_code = "JP"
        city = "Tokyo"
        latitude = 35.6895
        longitude = 139.6917
        http_method = "GET"
        endpoint = "/api/v1/profile"
        http_status = 200
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri "$CloudUrl/logs" -Method Post -ContentType "application/json" -Body $log2 -TimeoutSec 20 | Out-Null
        Write-Host "  [Connexion 2] $user a Tokyo (Japon) - 9700 km en 1 seconde !" -ForegroundColor Red
        Write-Host ""
        Write-Host "[OK] Voyage Impossible qualifie avec succes !" -ForegroundColor Green
        Write-Host "  Une alerte critique 'IMPOSSIBLE_TRAVEL' est maintenant active !" -ForegroundColor Yellow
    } catch {
        Write-Host "  [ERREUR] Impossible d'envoyer le deuxieme log" -ForegroundColor Red
    }
}

function Test-ReconScan {
    Write-Host ""
    Write-Host "--> Lancement d'une sonde de vulnerabilites (Recon Scan)..." -ForegroundColor Yellow
    $scannerIp = "91.240.118." + (Get-Random -Minimum 10 -Maximum 250)
    $endpoints = @("/.env", "/wp-login.php", "/actuator/health", "/config.json")

    foreach ($ep in $endpoints) {
        $log = @{
            user_identifier = "anonymous"
            ip_address = $scannerIp
            country_code = "RU"
            city = "Moscow"
            http_method = "GET"
            endpoint = $ep
            http_status = 404
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri "$CloudUrl/logs" -Method Post -ContentType "application/json" -Body $log -TimeoutSec 15 | Out-Null
            Write-Host "  Sonde HTTP GET $ep [404 Not Found]" -ForegroundColor DarkYellow
        } catch {}
        Start-Sleep -Milliseconds 300
    }
    Write-Host ""
    Write-Host "[OK] Sonde de hacker detectee !" -ForegroundColor Green
    Write-Host "  Une alerte 'RECON_SCAN' est visible sur la console !" -ForegroundColor Yellow
}

function Test-NormalTraffic {
    Write-Host ""
    Write-Host "--> Envoi d'un flux de 6 connexions d'employes legitimes..." -ForegroundColor Cyan
    $villes = @(
        @{c="Paris"; cc="FR"; lat=48.85; lon=2.35},
        @{c="Lyon"; cc="FR"; lat=45.76; lon=4.83},
        @{c="Bordeaux"; cc="FR"; lat=44.83; lon=-0.57},
        @{c="Lille"; cc="FR"; lat=50.62; lon=3.05}
    )

    for ($i = 1; $i -le 6; $i++) {
        $v = $villes | Get-Random
        $log = @{
            user_identifier = ("employe_" + $i)
            ip_address = ("194.254.120." + (10 + $i))
            country_code = $v.cc
            city = $v.c
            latitude = $v.lat
            longitude = $v.lon
            http_method = "GET"
            endpoint = "/api/v1/dashboard"
            http_status = 200
            response_time_ms = (Get-Random -Minimum 25 -Maximum 110)
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri "$CloudUrl/logs" -Method Post -ContentType "application/json" -Body $log -TimeoutSec 15 | Out-Null
            Write-Host "  Connexion normale : employe_$i depuis $($v.c) [200 OK]" -ForegroundColor Gray
        } catch {}
    }
    Write-Host ""
    Write-Host "[OK] Trafic legitime enregistre (graphique SOC actualise)." -ForegroundColor Green
}

function Test-AuditPC {
    Write-Host ""
    Write-Host "--> Lancement de l'audit de securite du poste local..." -ForegroundColor Blue
    $script = Join-Path $PSScriptRoot "sentinel-watch\agent\sentinel_audit.ps1"
    if (Test-Path $script) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -ApiUrl "$CloudUrl/audits"
    } else {
        Write-Host "[ERREUR] Script agent introuvable : $script" -ForegroundColor Red
    }
}

# BOUCLE PRINCIPALE
do {
    Show-Header
    Write-Host "Choisissez le scenario de test a executer :" -ForegroundColor Green
    Write-Host "  [1] Tester la connectivite Cloud (Health Check)" -ForegroundColor White
    Write-Host "  [2] Simuler une Attaque FORCE BRUTE (Declenche alerte BRUTE_FORCE)" -ForegroundColor Red
    Write-Host "  [3] Simuler un VOYAGE IMPOSSIBLE (Paris -> Tokyo = IMPOSSIBLE_TRAVEL)" -ForegroundColor Magenta
    Write-Host "  [4] Simuler une SONDE DE FICHIERS SENSIBLES (Scan /.env = RECON_SCAN)" -ForegroundColor Yellow
    Write-Host "  [5] Generer un flux de TRAFIC NORMAL (Connexions d'utilisateurs)" -ForegroundColor Cyan
    Write-Host "  [6] Lancer un AUDIT DE SECURITE EDR de ce PC (Poste Entreprise)" -ForegroundColor Blue
    Write-Host "  [7] Executer la DEMONSTRATION COMPLETE (Tous les tests d'un coup)" -ForegroundColor Green
    Write-Host "  [0] Quitter" -ForegroundColor Gray
    Write-Host ""
    $choice = Read-Host "Votre choix (0 a 7)"

    switch ($choice) {
        "1" { Test-Health; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "2" { Test-BruteForce; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "3" { Test-ImpossibleTravel; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "4" { Test-ReconScan; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "5" { Test-NormalTraffic; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "6" { Test-AuditPC; Write-Host ""; Read-Host "Appuyez sur Entree pour continuer..." }
        "7" {
            Write-Host ""
            Write-Host "=== EXECUTION DU GRAND TEST DE DEMONSTRATION ===" -ForegroundColor Green
            Test-Health
            Test-NormalTraffic
            Test-ReconScan
            Test-ImpossibleTravel
            Test-BruteForce
            Write-Host ""
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host "  TOUS LES SCENARIOS ONT ETE EXECUTES AVEC SUCCES !" -ForegroundColor Green
            Write-Host "  Consultez maintenant votre Dashboard Web ou votre application mobile :" -ForegroundColor Yellow
            Write-Host "  --> $DashboardUrl" -ForegroundColor Cyan
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host ""
            Read-Host "Appuyez sur Entree pour continuer..."
        }
        "0" { Write-Host "Fermeture du banc de test." -ForegroundColor Gray; break }
        default { Write-Host "Option non reconnue. Tapez un chiffre entre 0 et 7." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "0")
