#!/usr/bin/env bash
# ==============================================================================
# Script de Déploiement Automatisé SentinelWatch sur Google Cloud Platform (Bash)
# ==============================================================================
set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null)}
REGION="europe-west1"
SERVICE_NAME="sentinelwatch-api"
DB_INSTANCE_NAME="sentinelwatch-db"
DB_PASSWORD="SecurePass_$(openssl rand -hex 6 2>/dev/null || echo 'Pass2026Sentinel!')"

if [ -z "$PROJECT_ID" ]; then
  echo "Erreur: Veuillez spécifier un Project ID GCP. Exemple: ./deploy_gcp.sh mon-projet-id"
  exit 1
fi

echo "============================================================"
echo "🛡️ DÉPLOIEMENT SENTINELWATCH SUR GOOGLE CLOUD PLATFORM"
echo "Projet GCP : $PROJECT_ID | Région : $REGION"
echo "============================================================"

# 1. Activation des APIs
echo "[1/5] Activation des APIs GCP..."
gcloud services enable run.googleapis.com sqladmin.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com --project "$PROJECT_ID"

# 2. Dépôt Artifact Registry
echo "[2/5] Vérification du dépôt Artifact Registry..."
if ! gcloud artifacts repositories describe sentinelwatch-repo --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud artifacts repositories create sentinelwatch-repo --repository-format=docker --location="$REGION" --project="$PROJECT_ID"
fi

# 3. Instance Cloud SQL
echo "[3/5] Vérification de l'instance Cloud SQL..."
if ! gcloud sql instances describe "$DB_INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Création de Cloud SQL PostgreSQL..."
  gcloud sql instances create "$DB_INSTANCE_NAME" --database-version=POSTGRES_15 --tier=db-f1-micro --region="$REGION" --root-password="$DB_PASSWORD" --project="$PROJECT_ID"
  gcloud sql databases create sentinelwatch_db --instance="$DB_INSTANCE_NAME" --project="$PROJECT_ID"
fi

CONNECTION_NAME="$PROJECT_ID:$REGION:$DB_INSTANCE_NAME"

# 4. Build et Push
echo "[4/5] Construction de l'image de conteneur..."
IMAGE_TAG="$REGION-docker.pkg.dev/$PROJECT_ID/sentinelwatch-repo/sentinelwatch-backend:latest"
cd "$(dirname "$0")/../backend"
gcloud builds submit --tag "$IMAGE_TAG" --project="$PROJECT_ID"

# 5. Déploiement Cloud Run
echo "[5/5] Déploiement sur Google Cloud Run..."
DB_URL="postgresql://postgres:$DB_PASSWORD@/sentinelwatch_db?host=/cloudsql/$CONNECTION_NAME"
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE_TAG" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --add-cloudsql-instances "$CONNECTION_NAME" \
  --set-env-vars "DATABASE_URL=$DB_URL,DEBUG=False" \
  --memory 512Mi \
  --port 8080 \
  --project "$PROJECT_ID"

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --platform managed --region "$REGION" --format "value(status.url)" --project="$PROJECT_ID")
echo "============================================================"
echo "🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !"
echo "Dashboard Web : $SERVICE_URL/dashboard"
echo "Swagger Docs  : $SERVICE_URL/docs"
echo "============================================================"
