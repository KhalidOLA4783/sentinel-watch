# ==============================================================================
# Script de Déploiement Automatisé SentinelWatch sur Google Cloud Platform (GCP)
# Services : Cloud Run, Cloud SQL (PostgreSQL), Artifact Registry, Secret Manager
# ==============================================================================

param(
    [string]$ProjectId = "",
    [string]$Region = "europe-west1",
    [string]$ServiceName = "sentinelwatch-api",
    [string]$DbInstanceName = "sentinelwatch-db",
    [string]$DbPassword = "SecurePass_$(Get-Random -Minimum 10000 -Maximum 99999)"
)

# 1. Vérification du Project ID
if ([string]::IsNullOrWhiteSpace($ProjectId)) {
    $ProjectId = gcloud config get-value project 2>$null
    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        Write-Error "Veuillez spécifier votre GCP Project ID avec -ProjectId <VOTRE_ID_PROJET>"
        exit 1
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🛡️  DÉPLOIEMENT SENTINELWATCH SUR GOOGLE CLOUD PLATFORM" -ForegroundColor Cyan
Write-Host "Projet GCP      : $ProjectId" -ForegroundColor Yellow
Write-Host "Région          : $Region" -ForegroundColor Yellow
Write-Host "Service CloudRun: $ServiceName" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# 2. Activation des APIs Google Cloud requises
Write-Host "`n[1/6] Activation des APIs GCP..." -ForegroundColor Green
gcloud services enable `
    run.googleapis.com `
    sqladmin.googleapis.com `
    artifactregistry.googleapis.com `
    secretmanager.googleapis.com `
    cloudbuild.googleapis.com `
    --project $ProjectId

# 3. Création du dépôt Artifact Registry
Write-Host "`n[2/6] Configuration du dépôt Artifact Registry..." -ForegroundColor Green
$RepoExists = gcloud artifacts repositories describe sentinelwatch-repo --location=$Region --project=$ProjectId 2>$null
if (-not $RepoExists) {
    gcloud artifacts repositories create sentinelwatch-repo `
        --repository-format=docker `
        --location=$Region `
        --description="SentinelWatch Docker Repository" `
        --project=$ProjectId
}

# 4. Provisionnement de l'instance Cloud SQL (PostgreSQL)
Write-Host "`n[3/6] Vérification / Création de l'instance Cloud SQL ($DbInstanceName)..." -ForegroundColor Green
$DbExists = gcloud sql instances describe $DbInstanceName --project=$ProjectId 2>$null
if (-not $DbExists) {
    Write-Host "Création de l'instance Cloud SQL PostgreSQL (cela peut prendre 3-5 minutes)..." -ForegroundColor Yellow
    gcloud sql instances create $DbInstanceName `
        --database-version=POSTGRES_15 `
        --tier=db-f1-micro `
        --region=$Region `
        --root-password=$DbPassword `
        --project=$ProjectId
    
    # Création de la base de données applicative
    gcloud sql databases create sentinelwatch_db --instance=$DbInstanceName --project=$ProjectId
}

$ConnectionName = "$ProjectId:$Region:$DbInstanceName"
Write-Host "Instance Cloud SQL prête : $ConnectionName" -ForegroundColor Cyan

# 5. Build et push du conteneur avec Cloud Build
Write-Host "`n[4/6] Construction et publication de l'image de conteneur via Cloud Build..." -ForegroundColor Green
$ImageTag = "$Region-docker.pkg.dev/$ProjectId/sentinelwatch-repo/sentinelwatch-backend:latest"
Push-Location "$PSScriptRoot\..\backend"
gcloud builds submit --tag $ImageTag --project=$ProjectId
Pop-Location

# 6. Configuration de la chaîne de connexion Cloud SQL
$DbUrl = "postgresql://postgres:$DbPassword@/sentinelwatch_db?host=/cloudsql/$ConnectionName"

# 7. Déploiement sur Google Cloud Run
Write-Host "`n[5/6] Déploiement du conteneur sur Google Cloud Run..." -ForegroundColor Green
gcloud run deploy $ServiceName `
    --image $ImageTag `
    --platform managed `
    --region $Region `
    --allow-unauthenticated `
    --add-cloudsql-instances $ConnectionName `
    --set-env-vars "DATABASE_URL=$DbUrl,DEBUG=False" `
    --memory 512Mi `
    --cpu 1 `
    --min-instances 0 `
    --max-instances 5 `
    --port 8080 `
    --project $ProjectId

# 8. Récupération de l'URL publique
$ServiceUrl = gcloud run services describe $ServiceName --platform managed --region $Region --format "value(status.url)" --project=$ProjectId

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "🎉 DÉPLOIEMENT RÉUSSI SUR GOOGLE CLOUD RUN !" -ForegroundColor Green
Write-Host "URL du Dashboard Public : $ServiceUrl/dashboard" -ForegroundColor Cyan
Write-Host "URL de Swagger API Docs : $ServiceUrl/docs" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green
