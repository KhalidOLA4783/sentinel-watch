# ☁️ Guide de Déploiement Google Cloud Platform (GCP)

Ce guide explique comment déployer l'architecture de **SentinelWatch** sur l'infrastructure managée de Google Cloud Platform (GCP) en utilisant **Cloud Run** et **Cloud SQL (PostgreSQL)**.

---

## 🏛️ Architecture Cloud Cible

```mermaid
flowchart TD
    USERS["Utilisateurs & Simulateur d'Attaques"] -->|HTTPS (TLS 1.3)| LB["Google Cloud Load Balancer / Ingress"]
    LB --> CR["Google Cloud Run (Serverless)\n- Conteneur Docker FastAPI\n- Utilisateur non-root (sécurité)\n- Autoscaling automatique"]
    CR -->|Unix Socket / Proxy Sécurisé| CSQL[("Google Cloud SQL\n- PostgreSQL 15 managé\n- Sauvegardes automatiques\n- Chiffrement au repos")]
    AR["Google Artifact Registry\n(Dépôt d'images Docker)"] -.->|Pull image au démarrage| CR
```

---

## 📋 Prérequis

1. Un compte Google Cloud avec un **Projet GCP** actif et la facturation activée.
2. Le CLI **Google Cloud SDK (`gcloud`)** installé sur ta machine :
   - Vérifier avec : `gcloud --version`
   - S'authentifier : `gcloud auth login`
   - Configurer le projet : `gcloud config set project <TON_PROJECT_ID>`

---

## 🚀 Méthode 1 : Déploiement Automatisé en 1 Seule Commande

### Depuis Windows (PowerShell) :
```powershell
cd c:\Users\Khaled\Videos\APK\sentinel-watch\deploy
.\deploy_gcp.ps1 -ProjectId "ton-id-de-projet-gcp" -Region "europe-west1"
```

### Depuis Linux / Mac / Cloud Shell (Bash) :
```bash
cd sentinel-watch/deploy
chmod +x deploy_gcp.sh
./deploy_gcp.sh "ton-id-de-projet-gcp"
```

Le script s'occupe de tout :
1. Active les APIs requises (`run`, `sqladmin`, `artifactregistry`, `cloudbuild`).
2. Crée le registre de conteneurs Docker dans Artifact Registry.
3. Provisionne l'instance managée Cloud SQL PostgreSQL et la base de données.
4. Construit l'image Docker via Google Cloud Build.
5. Déploie le service sur Cloud Run avec l'attachement sécurisé Cloud SQL.
6. Affiche ton **URL publique HTTPS** finale !

---

## 🛠️ Méthode 2 : Pas-à-Pas Manuel (GCloud CLI)

### 1. Activer les APIs GCP nécessaires
```bash
gcloud services enable run.googleapis.com \
    sqladmin.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com
```

### 2. Créer le dépôt d'images Docker
```bash
gcloud artifacts repositories create sentinelwatch-repo \
    --repository-format=docker \
    --location=europe-west1 \
    --description="Dépôt Docker SentinelWatch"
```

### 3. Provisionner l'instance Cloud SQL (PostgreSQL)
```bash
gcloud sql instances create sentinelwatch-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=europe-west1 \
    --root-password="UnMotDePasseTresRobuste123!"

# Créer la base applicative
gcloud sql databases create sentinelwatch_db --instance=sentinelwatch-db
```

### 4. Construire et pousser l'image Docker
```bash
cd ../backend
gcloud builds submit --tag europe-west1-docker.pkg.dev/$PROJECT_ID/sentinelwatch-repo/sentinelwatch-backend:latest
```

### 5. Déployer sur Google Cloud Run
```bash
# Récupérer le nom de connexion Cloud SQL (format: PROJECT:REGION:INSTANCE)
CONNECTION_NAME="$PROJECT_ID:europe-west1:sentinelwatch-db"
DB_URL="postgresql://postgres:UnMotDePasseTresRobuste123!@/sentinelwatch_db?host=/cloudsql/$CONNECTION_NAME"

gcloud run deploy sentinelwatch-api \
    --image europe-west1-docker.pkg.dev/$PROJECT_ID/sentinelwatch-repo/sentinelwatch-backend:latest \
    --platform managed \
    --region europe-west1 \
    --allow-unauthenticated \
    --add-cloudsql-instances $CONNECTION_NAME \
    --set-env-vars "DATABASE_URL=$DB_URL,DEBUG=False" \
    --memory 512Mi \
    --port 8080
```

---

## 🎯 Connecter le Simulateur & le Dashboard à l'URL Publique

Une fois déployé, Cloud Run te donne une URL HTTPS du type :  
`https://sentinelwatch-api-xyz-ew.a.run.app`

1. **Accéder au Dashboard Public** :  
   Ouvre simplement dans n'importe quel navigateur :  
   `https://sentinelwatch-api-xyz-ew.a.run.app/dashboard`
2. **Lancer le Simulateur d'attaques vers le Cloud** :  
   Depuis ta machine locale :
   ```bash
   cd simulator
   python simulator.py --url "https://sentinelwatch-api-xyz-ew.a.run.app/api/v1/logs" --mode continuous
   ```
3. **Connecter l'App Mobile Flutter** :  
   Dans l'écran d'accueil Flutter, clique sur l'icône ⚙️ (Paramètres) et indique l'URL Cloud Run !

---

## 🛡️ Arguments Clés pour tes Recruteurs & Entretiens

Lors d'un entretien technique, tu pourras valoriser :
- **Architecture Zero-Trust & Moindre Privilège** : Le conteneur Docker s'exécute avec un utilisateur système non-root dédié (`sentinel:1000`).
- **Communication Cloud SQL Sécurisée** : Connexion via le proxy socket local `/cloudsql/INSTANCE_CONNECTION_NAME` sans jamais exposer la base de données sur internet public.
- **Serverless & FinOps** : Configuration avec `--min-instances 0` pour que le coût soit de **0,00 €** lorsque le service ne reçoit pas de trafic (idéal pour un projet de démo).
- **Résilience** : Multi-workers asynchrones Uvicorn et healthchecks Docker intégrés.
