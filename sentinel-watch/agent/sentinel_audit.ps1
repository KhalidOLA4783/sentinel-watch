# ==============================================================================
# SentinelWatch - Agent d'Audit et de Posture de Securite Entreprise
# Compatible avec : Windows 10, Windows 11, Windows Server 2016 a 2025
# Execution : Aucune dependance requise (ni Python, ni Node.js)
# ==============================================================================

param (
    [string]$ApiUrl = "http://127.0.0.1:8000/api/v1/audits",
    [switch]$Standalone = $false
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   SENTINELWATCH - AUDIT DE SECURITE DU POSTE D'ENTREPRISE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Analyse approfondie des composants du systeme..." -ForegroundColor Yellow

$Score = 100
$Findings = @()
$Hostname = $env:COMPUTERNAME

$OsInfo = "Windows"
try {
    $OsObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($OsObj) { $OsInfo = $OsObj.Caption }
} catch {}

$MainIp = "127.0.0.1"
try {
    $Ips = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -notmatch "Loopback" }).IPAddress
    if ($Ips -and $Ips.Count -gt 0) { $MainIp = $Ips[0] }
} catch {}

$Domain = "WORKGROUP"
try {
    $CompObj = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($CompObj -and $CompObj.Domain) { $Domain = $CompObj.Domain }
} catch {}

# ------------------------------------------------------------------------------
# 1. AUDIT DU PARE-FEU WINDOWS (FIREWALL)
# ------------------------------------------------------------------------------
Write-Host "[1/8] Verification du Pare-feu Windows..." -ForegroundColor Gray
$FirewallOk = $true
$DisabledProfiles = @()
try {
    $Profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    if ($Profiles) {
        foreach ($p in $Profiles) {
            if (-not $p.Enabled) {
                $DisabledProfiles += $p.Name
                $FirewallOk = $false
            }
        }
    }
    if (-not $FirewallOk) {
        $Score -= 20
        $Findings += [PSCustomObject]@{
            title = "Pare-feu Windows Desactive"
            severity = "CRITICAL"
            category = "FIREWALL"
            observation = "Le pare-feu est inactif sur les profils : $($DisabledProfiles -join ', ')."
            risk = "La machine ne filtre aucun paquet entrant. Un pirate sur le reseau peut cibler directement les services sans obstacle."
            solution = "Reactiver immediatement le pare-feu Windows pour tous les profils (Domaine, Prive, Public)."
            remediation_command = "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True"
        }
    }
} catch {
    Write-Warning "Impossible de lire le statut du pare-feu."
}

# ------------------------------------------------------------------------------
# 2. AUDIT DE L'ANTIVIRUS / PROTECTION EN TEMPS REEL (DEFENDER / EDR)
# ------------------------------------------------------------------------------
Write-Host "[2/8] Verification de la Protection Antivirus..." -ForegroundColor Gray
$AntivirusOk = $true
try {
    $MpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($MpStatus) {
        if (-not $MpStatus.RealTimeProtectionEnabled) {
            $Score -= 25
            $AntivirusOk = $false
            $Findings += [PSCustomObject]@{
                title = "Protection Antivirus en Temps Reel Inactive"
                severity = "CRITICAL"
                category = "ANTIVIRUS"
                observation = "Windows Defender est present mais la protection en temps reel est coupee."
                risk = "Les ransomwares, malwares et scripts malveillants peuvent s'executer sans etre interceptes."
                solution = "Activer la protection en temps reel et mettre a jour les signatures antivirales."
                remediation_command = "Set-MpPreference -DisableRealtimeMonitoring `$false"
            }
        }
        if ($MpStatus.AntivirusSignatureAge -gt 7) {
            $Score -= 10
            $Findings += [PSCustomObject]@{
                title = "Signatures Antivirus Obsoletes ($($MpStatus.AntivirusSignatureAge) jours)"
                severity = "MEDIUM"
                category = "ANTIVIRUS"
                observation = "Les definitions de virus n'ont pas ete mises a jour depuis plus d'une semaine."
                risk = "Incapacite a detecter les dernieres variantes de malwares et zero-days recentes."
                solution = "Declencher une mise a jour immediate des definitions Windows Defender."
                remediation_command = "Update-MpSignature"
            }
        }
    }
} catch {
    Write-Host "Antivirus tiers ou verification Defender ignoree." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 3. AUDIT DU BUREAU A DISTANCE (RDP) ET PORTS SENSIBLES
# ------------------------------------------------------------------------------
Write-Host "[3/8] Audit approfondi du Bureau a Distance (RDP) et ports..." -ForegroundColor Gray
$DangerousPortsFound = 0
try {
    $ListeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    
    # Verification RDP Port 3389 et Registre
    $RdpPort = $ListeningPorts | Where-Object { $_.LocalPort -eq 3389 }
    $RdpReg = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -ErrorAction SilentlyContinue
    $RdpNlaReg = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -ErrorAction SilentlyContinue

    $IsRdpEnabled = ($RdpReg -and $RdpReg.fDenyTSConnections -eq 0) -or ($RdpPort)
    $IsNlaEnabled = ($RdpNlaReg -and $RdpNlaReg.UserAuthentication -eq 1)

    if ($IsRdpEnabled) {
        $DangerousPortsFound++
        if (-not $IsNlaEnabled) {
            $Score -= 20
            $Findings += [PSCustomObject]@{
                title = "Bureau a Distance RDP Actif SANS Authentification NLA"
                severity = "CRITICAL"
                category = "NETWORK_PORTS"
                observation = "Le service RDP (port 3389) est ouvert et le chiffrement Network Level Authentication (NLA) est desactive."
                risk = "Vulnerabilite critique aux attaques de type BlueKeep et au forçage de mot de passe avant toute authentification."
                solution = "Exiger l'authentification NLA obligatoire ou desactiver le RDP si inutile."
                remediation_command = "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1"
            }
        } else {
            $Score -= 10
            $Findings += [PSCustomObject]@{
                title = "Bureau a Distance (RDP - Port 3389) Accessible"
                severity = "MEDIUM"
                category = "NETWORK_PORTS"
                observation = "Le port 3389 est en ecoute avec authentification NLA activee."
                risk = "Exposition aux tentatives de force brute sur le reseau d'entreprise."
                solution = "Restreindre le RDP derriere un VPN ou le desactiver si non utilise."
                remediation_command = "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 1"
            }
        }
    }

    # Telnet 23
    $Telnet = $ListeningPorts | Where-Object { $_.LocalPort -eq 23 }
    if ($Telnet) {
        $DangerousPortsFound++
        $Score -= 20
        $Findings += [PSCustomObject]@{
            title = "Protocole Telnet Non Chiffre Detecte (Port 23)"
            severity = "CRITICAL"
            category = "NETWORK_PORTS"
            observation = "Un service Telnet est actif sur le port 23."
            risk = "Tous les mots de passe et commandes transitent en clair non chiffre sur le reseau."
            solution = "Desactiver Telnet et basculer sur un acces securise chiffre SSH (Port 22)."
            remediation_command = "Stop-Service -Name TlntSvr -ErrorAction SilentlyContinue; Set-Service -Name TlntSvr -StartupType Disabled -ErrorAction SilentlyContinue"
        }
    }
} catch {
    Write-Host "Analyse des ports limitee." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 4. AUDIT DU FICHIER HOSTS (DETECTION REDIRECTION DNS / PHISHING)
# ------------------------------------------------------------------------------
Write-Host "[4/8] Verification du fichier hosts Windows..." -ForegroundColor Gray
try {
    $HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $HostsPath) {
        $HostsContent = Get-Content $HostsPath -ErrorAction SilentlyContinue | Where-Object {
            $_ -and $_.Trim() -notmatch "^\s*#"
        }
        
        $SuspiciousEntries = @()
        foreach ($line in $HostsContent) {
            $trimmed = $line.Trim()
            # Ignorer localhost standard
            if ($trimmed -notmatch "^\s*(127\.0\.0\.1|::1)\s+localhost\b") {
                $SuspiciousEntries += $trimmed
            }
        }

        if ($SuspiciousEntries.Count -gt 0) {
            $Score -= 20
            $Findings += [PSCustomObject]@{
                title = "Entrees Personnalisees Detectees dans le Fichier Hosts ($($SuspiciousEntries.Count))"
                severity = "HIGH"
                category = "HOSTS_FILE"
                observation = "Le fichier hosts contient des redirections manuelles : $($SuspiciousEntries -join ' | ')."
                risk = "Technique courante de logiciels malveillants pour detourner la navigation web, bloquer les mises a jour antivirus ou rediriger vers des sites pirates."
                solution = "Inspecter le fichier hosts et supprimer les correspondances IP/domaines non sollicitees."
                remediation_command = "notepad $HostsPath"
            }
        }
    }
} catch {
    Write-Host "Verification hosts ignoree." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 5. AUDIT DE L'HISTORIQUE POWERSHELL (COMMANDES MALVEILLANTES / STAGERS)
# ------------------------------------------------------------------------------
Write-Host "[5/8] Analyse de l'historique des commandes PowerShell..." -ForegroundColor Gray
try {
    $HistoryPath = ""
    try {
        $HistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
    } catch {}

    if (-not $HistoryPath -or -not (Test-Path $HistoryPath)) {
        $HistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }

    if (Test-Path $HistoryPath) {
        $HistoryLines = Get-Content $HistoryPath -Tail 200 -ErrorAction SilentlyContinue
        $SuspiciousCommands = @()
        $SusPattern = "(?i)(DownloadString|Invoke-Expression|\bIEX\b|-EncodedCommand|\b-enc\s+[A-Za-z0-9+/=]{10,}|\bmimikatz\b|\bbypass\s+-c\b|certutil.*-urlcache)"

        foreach ($cmd in $HistoryLines) {
            if ($cmd -match $SusPattern) {
                $SuspiciousCommands += $cmd.Trim()
            }
        }

        if ($SuspiciousCommands.Count -gt 0) {
            $Score -= 25
            $Sample = if ($SuspiciousCommands.Count -gt 2) { ($SuspiciousCommands[0..1] -join " | ") + " (...)" } else { $SuspiciousCommands -join " | " }
            $Findings += [PSCustomObject]@{
                title = "Commandes PowerShell Furtives ou Suspectes Detectees ($($SuspiciousCommands.Count))"
                severity = "CRITICAL"
                category = "POWERSHELL_HISTORY"
                observation = "Historique contenant des instructions a haut risque (IEX, encodage base64, ou telechargement distant) : $Sample"
                risk = "Indice fort d'activite offensive, d'infection par dropper sans fichier (fileless malware) ou de prise de controle a distance."
                solution = "Examiner l'historique complet, identifier la session utilisateur concernee, et inspecter les processus en memoire."
                remediation_command = "notepad `"$HistoryPath`""
            }
        }
    }
} catch {
    Write-Host "Historique PowerShell protege ou inaccessible." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 6. SCAN DES EXECUTABLES RECENTS EN DOSSIER TEMPORAIRE (AVEC HASH SHA-256)
# ------------------------------------------------------------------------------
Write-Host "[6/8] Scan des executables temporaires (%TEMP%) et calcul SHA-256..." -ForegroundColor Gray
try {
    $TempDirs = @($env:TEMP, "$env:APPDATA")
    $SuspiciousFiles = @()

    foreach ($td in $TempDirs) {
        if (Test-Path $td) {
            $RecentExecs = Get-ChildItem -Path $td -Filter "*.exe" -File -Recurse -Depth 1 -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
                Select-Object -First 3

            foreach ($file in $RecentExecs) {
                $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()
                $SuspiciousFiles += [PSCustomObject]@{
                    Name = $file.Name
                    FullName = $file.FullName
                    Hash = $fileHash
                }
            }
        }
    }

    if ($SuspiciousFiles.Count -gt 0) {
        $Score -= 15
        foreach ($sf in $SuspiciousFiles) {
            $Findings += [PSCustomObject]@{
                title = "Fichier Executable Recent dans Dossier Temp : $($sf.Name)"
                severity = "HIGH"
                category = "VIRUSTOTAL_SCAN"
                observation = "Fichier : $($sf.FullName) | SHA-256 : $($sf.Hash)"
                risk = "L'emplacement %TEMP% ou %APPDATA% est l'endroit numero 1 utilise par les chevaux de Troie pour s'installer."
                solution = "Verifier l'integrite de ce hash sur VirusTotal : https://www.virustotal.com/gui/search/$($sf.Hash)"
                remediation_command = "Start-Process 'https://www.virustotal.com/gui/search/$($sf.Hash)'"
            }
        }
    }
} catch {
    Write-Host "Scan des dossiers temporaires termine." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 7. AUDIT DES COMPTES LOCAUX ET PRIVILEGES ADMINISTRATEURS
# ------------------------------------------------------------------------------
Write-Host "[7/8] Audit des comptes et privileges administrateurs..." -ForegroundColor Gray
try {
    $Guest = Get-LocalUser -Name "Invite", "Guest" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq $true }
    if ($Guest) {
        $Score -= 15
        $Findings += [PSCustomObject]@{
            title = "Compte Invite (Guest) Actif"
            severity = "HIGH"
            category = "USER_ACCOUNTS"
            observation = "Le compte anonyme Invite est active sur ce systeme."
            risk = "Permet a n'importe quel individu connecte au reseau d'ouvrir une session sans mot de passe."
            solution = "Desactiver immediatement le compte invite par defaut."
            remediation_command = "Disable-LocalUser -Name '$($Guest.Name)'"
        }
    }

    $Admins = Get-LocalGroupMember -Group "Administrateurs", "Administrators" -ErrorAction SilentlyContinue
    if ($Admins -and $Admins.Count -gt 3) {
        $Score -= 10
        $Findings += [PSCustomObject]@{
            title = "Trop d'Utilisateurs avec Droits Administrateurs Locaux ($($Admins.Count))"
            severity = "MEDIUM"
            category = "USER_ACCOUNTS"
            observation = "$($Admins.Count) comptes disposent des privileges administrateurs sur cette machine."
            risk = "Violation du principe de moindre privilege. En cas de piratage, l'attaquant a les pleins pouvoirs."
            solution = "Retrograder les comptes non essentiels en simples utilisateurs standards."
            remediation_command = "Get-LocalGroupMember -Group 'Administrateurs'"
        }
    }
} catch {
    Write-Host "Audit des comptes administrateurs termine." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 8. VRAIS EVENEMENTS DE SECURITE WINDOWS (Event ID 4625 - Echecs d'authentification)
# ------------------------------------------------------------------------------
Write-Host "[8/8] Lecture des journaux de securite Windows (dernieres 24h)..." -ForegroundColor Gray
$RealFailedLogons = 0
try {
    $Yesterday = (Get-Date).AddDays(-1)
    $Events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$Yesterday} -ErrorAction SilentlyContinue
    if ($Events) {
        $RealFailedLogons = $Events.Count
        if ($RealFailedLogons -ge 5) {
            $Score -= 15
            $Findings += [PSCustomObject]@{
                title = "Tentatives Repetees d'Acces Echouees ($RealFailedLogons echecs en 24h)"
                severity = "HIGH"
                category = "SECURITY_LOGS"
                observation = "$RealFailedLogons tentatives de connexion avec mot de passe errone enregistrees par Windows."
                risk = "Possible attaque par force brute locale ou tentative d'usurpation de mot de passe."
                solution = "Verifier l'Observateur d'Evenements (EventID 4625) et configurer un seuil de verrouillage."
                remediation_command = "net accounts /lockoutthreshold:5 /lockoutduration:30"
            }
        }
    }
} catch {
    Write-Host "Journaux de securite Windows proteges ou aucun echec constate." -ForegroundColor Gray
}

# Calcul final du score
if ($Score -lt 0) { $Score = 0 }

$RiskLevel = "SECURE"
if ($Score -lt 45) { $RiskLevel = "CRITICAL" }
elseif ($Score -lt 70) { $RiskLevel = "HIGH" }
elseif ($Score -lt 90) { $RiskLevel = "MEDIUM" }

# ------------------------------------------------------------------------------
# AFFICHAGE DU RAPPORT FORMATTE EN CONSOLE
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   BILAN DE SECURITE DE LA MACHINE : $Hostname" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$ScoreColor = "Green"
if ($RiskLevel -eq "CRITICAL") { $ScoreColor = "Red" }
elseif ($RiskLevel -eq "HIGH") { $ScoreColor = "Yellow" }
elseif ($RiskLevel -eq "MEDIUM") { $ScoreColor = "DarkYellow" }

Write-Host "SCORE DE SECURITE : $Score / 100" -ForegroundColor $ScoreColor
Write-Host "NIVEAU DE RISQUE  : $RiskLevel" -ForegroundColor $ScoreColor
Write-Host "Systeme           : $OsInfo" -ForegroundColor White
Write-Host "Adresse IP        : $MainIp (Domaine: $Domain)" -ForegroundColor White
Write-Host "Failles detectees : $($Findings.Count)" -ForegroundColor White

Write-Host ""
Write-Host "--- DETAIL DES PROBLEMES DETECTES ET SOLUTIONS RECOMMANDEES ---" -ForegroundColor Yellow

if ($Findings.Count -eq 0) {
    Write-Host "[OK] Aucune vulnerabilite majeure detectee ! La machine respecte les standards de securite." -ForegroundColor Green
} else {
    $Index = 1
    foreach ($f in $Findings) {
        $BadgeColor = "Yellow"
        if ($f.severity -eq "CRITICAL") { $BadgeColor = "Red" }
        elseif ($f.severity -eq "HIGH") { $BadgeColor = "Magenta" }

        Write-Host ""
        Write-Host "[$Index] $($f.title) " -NoNewline -ForegroundColor White
        Write-Host "[$($f.severity)]" -ForegroundColor $BadgeColor
        Write-Host "  * Constat  : $($f.observation)" -ForegroundColor Gray
        Write-Host "  * Danger   : $($f.risk)" -ForegroundColor DarkGray
        Write-Host "  * Solution : $($f.solution)" -ForegroundColor Green
        if ($f.remediation_command) {
            Write-Host "  * Commande : $($f.remediation_command)" -ForegroundColor Cyan
        }
        $Index++
    }
}

# ------------------------------------------------------------------------------
# RECOMMANDATION DES OUTILS FORENSIC GRATUITS
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "--- TROUSSE D'OUTILS FORENSIC ET DE DESINFECTION RECOMMANDES ---" -ForegroundColor Cyan
Write-Host "1. Sysinternals Autoruns        : Verifier la persistance (demarrage, taches planifiees)" -ForegroundColor White
Write-Host "2. Sysinternals Process Explorer: Verifier les processus actifs avec scan VirusTotal direct" -ForegroundColor White
Write-Host "3. Sysinternals TCPView         : Suivre les sockets et connexions IP en temps reel" -ForegroundColor White
Write-Host "4. Malwarebytes / AdwCleaner    : Desinfection rapide des spywares et logiciels indesirables" -ForegroundColor White
Write-Host "5. Integrite Systemes           : Lancer 'sfc /scannow' et 'DISM /Online /Cleanup-Image /RestoreHealth'" -ForegroundColor White

# ------------------------------------------------------------------------------
# ENVOI AUTOMATIQUE AU BACKEND SENTINELWATCH
# ------------------------------------------------------------------------------
if (-not $Standalone -and -not [string]::IsNullOrWhiteSpace($ApiUrl)) {
    Write-Host ""
    Write-Host "Envoi du rapport au serveur SentinelWatch ($ApiUrl)..." -ForegroundColor Gray
    
    $FindingsArray = @()
    foreach ($item in $Findings) {
        $FindingsArray += @{
            title = $item.title
            severity = $item.severity
            category = $item.category
            observation = $item.observation
            risk = $item.risk
            solution = $item.solution
            remediation_command = $item.remediation_command
        }
    }

    $PayloadObj = @{
        hostname = $Hostname
        os_version = $OsInfo
        ip_address = $MainIp
        domain_name = $Domain
        security_score = [int]$Score
        risk_level = $RiskLevel
        firewall_enabled = [bool]$FirewallOk
        antivirus_active = [bool]$AntivirusOk
        dangerous_ports_count = [int]$DangerousPortsFound
        failed_logins_24h = [int]$RealFailedLogons
        findings = $FindingsArray
    }
    
    $PayloadJson = $PayloadObj | ConvertTo-Json -Depth 5

    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $PayloadJson -ContentType "application/json; charset=utf-8" -TimeoutSec 5
        Write-Host "[OK] Rapport transmis avec succes au SOC SentinelWatch ! (ID Audit: $($Response.id))" -ForegroundColor Green
    } catch {
        Write-Host "[!] Le serveur SentinelWatch n'etait pas joignable ($ApiUrl). Le rapport est affiche ci-dessus en local." -ForegroundColor DarkYellow
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
