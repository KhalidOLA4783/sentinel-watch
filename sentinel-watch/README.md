# 🛡️ SentinelWatch — Tour de Contrôle Sécurité & SIEM Allégé

> **Système complet de détection d'intrusions, supervision SOC en direct et intervention d'urgence mobile.**  
> Ingestion de logs, détection heuristique & Machine Learning (Isolation Forest), Dashboard Web SOC cloisonné multi-organisation, Agent d'audit Windows EDR silencieux et Application Mobile Flutter.

<p align="center">
  <a href="https://render.com/deploy?repo=https://github.com/KhalidOLA4783/sentinel-watch">
    <img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render">
  </a>
  <a href="https://sentinel-watch-ssty.onrender.com/dashboard">
    <img src="https://img.shields.io/badge/Demo%20Live-Render%20Cloud-00c7b7?logo=render&logoColor=white" alt="Live Demo">
  </a>
  <img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white" alt="Python 3.11">
  <img src="https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Flutter-Mobile-02569B?logo=flutter&logoColor=white" alt="Flutter">
</p>

---

## 🚀 Deux Façons d'Utiliser SentinelWatch

SentinelWatch s'adapte aussi bien aux entreprises cherchant une solution clé en main qu'aux ingénieurs souhaitant un déploiement 100% privé :

### 🌟 Mode 1 : SaaS Cloud Multi-Organisation (Prêt à l'emploi)
- Accédez directement à la console en ligne : **[https://sentinel-watch-ssty.onrender.com/dashboard](https://sentinel-watch-ssty.onrender.com/dashboard)**
- Cliquez sur **« Créer une Organisation »** pour ouvrir votre espace dédié étanche.
- Dans l'onglet *Audits Postes Entreprise*, cliquez sur **« Télécharger .bat »** pour lier vos PC en tâche de fond 24h/24.

### 🛠️ Mode 2 : Déploiement Dédié Autonome (Self-Hosted en 1 Clic)
Pour héberger votre propre serveur totalement indépendant :
- **En 1 Clic sur Render** : Cliquez sur le bouton **[Deploy to Render]** ci-dessus pour lancer votre propre instance gratuite.
- **En local ou VPS avec Docker Compose** :
  ```bash
  git clone https://github.com/KhalidOLA4783/sentinel-watch.git
  cd sentinel-watch
  docker compose up -d
  ```
  Accédez à votre console locale : `http://localhost:8000/dashboard`

---

## 🏛️ Architecture & Flux Global

```mermaid
flowchart LR
    SIM["1. Simulateur de Trafic & Attaques\n(Normal, Brute-Force, Voyage Impossible, Scans)"] -->|POST /api/v1/logs| API["2. Backend FastAPI\n(Ingestion & Filtrage)"]
    API --> ENGINE["3. Cerveau de Détection\n- Règles Heuristiques (Haversine, Fenêtre)\n- IA Scikit-Learn (Isolation Forest)"]
    ENGINE -->|Si anomalie| DB[("Base de Données\nPostgreSQL / SQLite")]
    DB --> WEB["4. Dashboard Web SOC\n(Monitoring direct & Ban 1-clic)"]
    DB --> MOB["5. App Mobile d'Intervention\n(Flutter : Vue astreinte & Urgence)"]
    MOB -->|Bannir IP / Résoudre| API
    WEB -->|Bannir IP / Résoudre| API
```

---

## 📁 Structure du Projet

```text
sentinel-watch/
├── backend/                  # API FastAPI & Cerveau de Détection
│   ├── app/
│   │   ├── api/              # Endpoints: auth, logs, alerts, audits, blacklist
│   │   ├── detection/        # Règles heuristiques + ML Isolation Forest
│   │   ├── models/           # Modèles SQLAlchemy (User, AccessLog, Alert, AuditReport)
│   │   ├── schemas/          # Validation Pydantic v2
│   │   └── static/           # Dashboard Web SOC autonome
│   ├── Dockerfile            # Image de production non-root sécurisée
│   ├── main.py               # Point d'entrée FastAPI
│   └── requirements.txt      # Dépendances
├── agent/                    # Agent d'Audit de Sécurité Réel Windows (PowerShell)
│   └── sentinel_audit.ps1    # Scanner EDR Posture Score & Remédiations
├── mobile/                   # Application Mobile Flutter (Auth, SOC, Pilote Autonome)
│   ├── lib/                  # Screens (Login, Home, AlertDetail, Blacklist)
│   └── pubspec.yaml
├── deploy/                   # Scripts de déploiement Google Cloud Platform
│   ├── deploy_gcp.ps1        # Script PowerShell automatisé
│   ├── deploy_gcp.sh         # Script Bash (Cloud Shell / Linux)
│   └── GCP_DEPLOYMENT_GUIDE.md
├── docker-compose.yml        # Orchestration locale FastAPI + PostgreSQL
└── README.md
```

---

## ⚡ Démarrage Rapide en Local

### 1. Démarrer le Backend
```powershell
cd backend
python main.py
```
- **Dashboard Web SOC** : [http://localhost:8000/dashboard](http://localhost:8000/dashboard)
- **Documentation API (Swagger)** : [http://localhost:8000/docs](http://localhost:8000/docs)

### 2. Lancer l'Audit Réel du Poste Windows
```powershell
cd agent
powershell -ExecutionPolicy Bypass -File .\sentinel_audit.ps1
```
> Le scanner analyse en direct l'antivirus Windows Defender, le pare-feu, les ports critiques et transmet le rapport au SOC.

---

## ☁️ Déploiement sur Google Cloud Platform (GCP)

Déploie l'intégralité du projet en une commande sur **Google Cloud Run** et **Cloud SQL** :

```powershell
cd deploy
.\deploy_gcp.ps1 -ProjectId "mon-projet-gcp" -Region "europe-west1"
```

Consulte le guide complet : [`deploy/GCP_DEPLOYMENT_GUIDE.md`](deploy/GCP_DEPLOYMENT_GUIDE.md).

---

## 🎯 Compétences Démontrées & Atouts Recruteur

- **Cybersécurité** : Détection d'intrusions spatiotemporelles (Haversine), Brute-Force, Fuzzing d'endpoints sensibles, Remédiation immédiate par liste noire dynamique.
- **Data & Intelligence Artificielle** : Pipeline d'extraction de caractéristiques et détection d'anomalies non supervisée via **Isolation Forest**.
- **Fullstack Web & Mobile** : Dashboard SOC temps réel et application mobile d'intervention rapide **Flutter**.
- **DevOps & Cloud GCP** : Conteneurisation Docker durcie (non-root), déploiement serverless Cloud Run, base managée Cloud SQL PostgreSQL et FinOps (autoscaling à zéro instance).
