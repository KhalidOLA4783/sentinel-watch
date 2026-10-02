# ==============================================================================
# SentinelWatch - Verification de Fichier Suspect sur VirusTotal (SHA-256)
# ==============================================================================

param (
    [Parameter(Position=0)]
    [string]$FilePath
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   SENTINELWATCH - ANALYSEUR VIRUSTOTAL & CALCUL DE HASH SHA-256" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

if (-not $FilePath) {
    Write-Host "Veuillez glisser-deposer un fichier ici ou saisir son chemin complet :" -ForegroundColor Yellow
    $FilePath = Read-Host "Chemin du fichier"
}

# Nettoyer les guillemets si glisser-deposer
$FilePath = $FilePath.Trim('"', "'", " ")

if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
    Write-Host "`n[ERREUR] Le fichier specifie n'existe pas : $FilePath" -ForegroundColor Red
    Write-Host "Verifiez le chemin et reessayez." -ForegroundColor Gray
    exit 1
}

$FileInfo = Get-Item -LiteralPath $FilePath
Write-Host "`nAnalyse du fichier en cours..." -ForegroundColor Gray
Write-Host "Nom        : $($FileInfo.Name)" -ForegroundColor White
Write-Host "Taille     : $([math]::Round($FileInfo.Length / 1KB, 2)) Ko ($($FileInfo.Length) octets)" -ForegroundColor White
Write-Host "Dossier    : $($FileInfo.DirectoryName)" -ForegroundColor Gray
Write-Host "Cree le    : $($FileInfo.CreationTime)" -ForegroundColor Gray

# Calcul des empreintes cryptographiques
Write-Host "`nCalcul des empreintes numeriques..." -ForegroundColor Gray
$Hash256 = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLower()
$HashMD5 = (Get-FileHash -LiteralPath $FilePath -Algorithm MD5).Hash.ToLower()

Write-Host "SHA-256 : $Hash256" -ForegroundColor Green
Write-Host "MD5     : $HashMD5" -ForegroundColor DarkGray

# Verification de la signature numerique (Authenticode)
Write-Host "`nVerification de la signature de l'editeur..." -ForegroundColor Gray
try {
    $Sig = Get-AuthenticodeSignature -LiteralPath $FilePath -ErrorAction SilentlyContinue
    if ($Sig.Status -eq "Valid") {
        Write-Host "Signature : VALIDE (Signe par : $($Sig.SignerCertificate.Subject))" -ForegroundColor Green
    } elseif ($Sig.Status -eq "NotSigned") {
        Write-Host "Signature : NON SIGNE (Attention: Fichier executable sans certificat editeur)" -ForegroundColor Yellow
    } else {
        Write-Host "Signature : $($Sig.Status) ($($Sig.StatusMessage))" -ForegroundColor Red
    }
} catch {
    Write-Host "Impossible de verifier la signature." -ForegroundColor Gray
}

# URL VirusTotal (Recherche universelle : ouvre le rapport si connu, ou propose l'upload direct si inconnu)
$VtUrl = "https://www.virustotal.com/gui/search/$Hash256"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "LIEN VIRUSTOTAL :" -ForegroundColor Yellow
Write-Host $VtUrl -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Proposition d'ouverture automatique dans le navigateur
Write-Host "`nOuverture automatique du rapport dans votre navigateur..." -ForegroundColor Green
Start-Process $VtUrl
