# 🛡️ SentinelWatch — Tour de Contrôle Sécurité, EDR & SIEM Allégé

> **Système de cybersécurité autonome : Détection d'intrusions spatiotemporelles & IA, Agent Windows EDR silencieux 24h/24, Console SOC multi-organisation et Application Mobile d'intervention rapide.**

<p align="center">
  <a href="https://render.com/deploy?repo=https://github.com/KhalidOLA4783/sentinel-watch">
    <img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render">
  </a>
  <a href="https://sentinel-watch-ssty.onrender.com/dashboard">
    <img src="https://img.shields.io/badge/Console%20Live-Render%20Cloud-00c7b7?logo=render&logoColor=white" alt="Live Demo">
  </a>
  <img src="https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white" alt="Python 3.11">
  <img src="https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Flutter-Android%20Mobile-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Windows-EDR%20Daemon-0078D6?logo=windows&logoColor=white" alt="Windows EDR">
</p>

---

## 🏛️ Architecture Globale & Fonctionnement Autonome

Une fois configuré, **SentinelWatch ne nécessite aucune action manuelle au quotidien** :

```mermaid
flowchart TD
    subgraph POSTES["1. Postes & Serveurs Entreprise (Silencieux)"]
        EDR["Tâche planifiée de fond\n(SentinelWatch_EDR_Daemon)\nScan Defender, Pare-feu, Ports"]
    end

    subgraph CLOUD["2. Cerveau Central Cloud (24h/24)"]
        API["Backend FastAPI (Render / GCP / Docker)"]
        DET["Moteur de Détection\n- Règles Heuristiques (Brute-force, Vitesse Haversine)\n- IA Scikit-Learn (Isolation Forest)"]
        DB[("Base de Données Cloisonnée\nMulti-Organisation")]
        API --> DET --> DB
    end

    subgraph PILOTAGE["3. Intervention & Supervision (À la demande)"]
        MOB["📱 Application Mobile Flutter\n(Astreinte 4G/5G, Alertes, Ban 1-clic)"]
        WEB["💻 Console Web SOC\n(Cartographie, Boîte à outils forensic)"]
    end

    EDR -->|Rapports périodiques (X-Sentinel-Key)| API
    DB -->|Flux temps réel| MOB
    DB -->|Flux temps réel| WEB
    MOB -->|Riposte / Bannissement IP| API
    WEB -->|Riposte / Bannissement IP| API
```

---

## 📖 Les 4 Méthodes d'Utilisation de SentinelWatch

---

### 🟢 Méthode 1 : Surveillance Automatique en Tâche de Fond (Poste Windows)
*Cette méthode installe l'agent EDR silencieux sur une machine Windows 10, 11 ou Windows Server. Vous n'avez pas besoin de laisser de terminal ouvert ni de démarrer de serveur.*

1. **Activer la surveillance sur un poste** :
   * Double-cliquez sur `ACTIVER_SURVEILLANCE_AUTOMATIQUE.bat` en acceptant les droits Administrateur.
   * Le script inscrit la tâche planifiée `SentinelWatch_EDR_Daemon` dans Windows.
2. **Fonctionnement invisible** :
   * L'agent audite automatiquement l'état de Windows Defender, le pare-feu, les ports d'écoute à risque et la télémétrie système.
   * Il transmet ses diagnostics chiffrés directement au Cloud à intervalle régulier.
3. **Vérifier le statut à tout moment** :
   * Double-cliquez sur `VERIFIER_STATUT_SURVEILLANCE.bat` pour confirmer que le démon veille correctement.

---

### 📱 Méthode 2 : Supervision Mobile d'Astreinte (Application Android APK)
*Permet au responsable de sécurité ou à l'administrateur système de surveiller son parc et de neutraliser les attaques depuis son smartphone en 4G/5G ou Wi-Fi.*

1. **Génération de l'application** :
   * Double-cliquez sur `COMPILER_NOUVEL_APK.bat` pour construire le fichier `SentinelWatch.apk` de production.
2. **Installation sur votre téléphone** :
   * **Via Wi-Fi direct** : Double-cliquez sur `SERVEUR_TELECHARGEMENT_APK.bat` et ouvrez le lien affiché dans le navigateur de votre téléphone.
   * **Via câble USB ou messagerie** : Copiez le fichier `SentinelWatch.apk` sur votre smartphone et installez-le.
3. **Intervention en direct** :
   * Connectez-vous avec vos identifiants administrateur.
   * En cas d'attaque détectée (ex: force brute), le bandeau **Pilote Autonome de Sécurité** s'active.
   * Appuyez sur **« Valider le Bannissement IP Immédiat »** pour bloquer instantanément l'attaquant au pare-feu.

---

### 💻 Méthode 3 : Console Web SOC & Espaces Multi-Organisations
*Pour piloter la sécurité globale de l'entreprise ou gérer plusieurs clients de façon étanche.*

1. **Accès au Dashboard** :
   * Ouvrez l'adresse de votre console : **[https://sentinel-watch-ssty.onrender.com/dashboard](https://sentinel-watch-ssty.onrender.com/dashboard)**.
2. **Isolation Multi-Tenants** :
   * Cliquez sur **« Créer une Organisation »** pour obtenir un espace dédié.
   * Chaque organisation possède une clé secrète d'agent unique (`agent_key`). Aucune donnée n'est partagée entre organisations.
3. **Déploiement en 1-Clic pour vos collaborateurs** :
   * Dans l'onglet *Audits Postes Entreprise*, cliquez sur **« Télécharger .bat d'Installation »**.
   * Transmettez ce fichier `.bat` à vos collaborateurs : un simple double-clic rattache automatiquement leur machine à votre tableau de bord.
4. **Gestion de vos identifiants** :
   * Cliquez sur le bouton **« Sécurité »** (icône de clé) dans la barre supérieure pour modifier votre identifiant et votre mot de passe à tout moment.

---

### 🛠️ Méthode 4 : Hébergement Dédié Privé (Self-Hosted / On-Premise)
*Pour les infrastructures exigeant un hébergement 100% interne ou souverain.*

#### Option A : Déploiement Cloud Render en 1-Clic
Cliquez sur le bouton **Deploy to Render** en haut du README pour instancier votre propre serveur cloud gratuit en quelques minutes.

#### Option B : Déploiement Local ou VPS avec Docker Compose
```bash
git clone https://github.com/KhalidOLA4783/sentinel-watch.git
cd sentinel-watch
docker compose up -d
```
* Accès au Dashboard local : `http://localhost:8000/dashboard`
* Documentation interactive de l'API (Swagger) : `http://localhost:8000/docs`

#### Option C : Déploiement Google Cloud Platform (GCP)
Déploiement serverless durci sur **Cloud Run** et **Cloud SQL** :
```powershell
cd deploy
.\deploy_gcp.ps1 -ProjectId "votre-projet-gcp" -Region "europe-west1"
```
*(Consultez le guide complet : [`deploy/GCP_DEPLOYMENT_GUIDE.md`](deploy/GCP_DEPLOYMENT_GUIDE.md)).*

---

## 🗂️ Répertoire des Scripts & Outils à la Racine

| Fichier / Script | Rôle & Usage |
| :--- | :--- |
| `ACTIVER_SURVEILLANCE_AUTOMATIQUE.bat` | Installe l'agent EDR en tâche planifiée Windows silencieuse. |
| `VERIFIER_STATUT_SURVEILLANCE.bat` | Vérifie si la surveillance automatique est bien active sur le PC. |
| `COMPILER_NOUVEL_APK.bat` | Compile l'application Android Flutter en version Release (`SentinelWatch.apk`). |
| `SERVEUR_TELECHARGEMENT_APK.bat` | Démarre un partage Wi-Fi local pour installer l'APK sur mobile facilement. |
| `CHANGER_IDENTIFIANTS_ADMIN.bat` | Met à jour l'identifiant et le mot de passe administrateur en 1 clic. |
| `NETTOYER_FICHIERS_TEST.bat` | Nettoie les fichiers de simulation et d'audit temporaires. |
| `sentinel-watch/agent/sentinel_audit.ps1` | Agent PowerShell d'audit de sécurité des postes (score sur 100). |

---

## 📁 Structure du Projet

```text
sentinel-watch/
├── backend/                  # API FastAPI, Sécurité & Moteur IA
│   ├── app/
│   │   ├── api/              # Endpoints: auth, logs, alerts, audits, blacklist
│   │   ├── detection/        # Moteur heuristique + Scikit-Learn Isolation Forest
│   │   ├── models/           # Modèles SQLAlchemy (User, Log, Alert, Audit)
│   │   ├── schemas/          # Validation Pydantic v2
│   │   └── static/           # Console Web SOC autonome (Tailwind + Chart.js)
│   ├── Dockerfile            # Image de production non-root
│   ├── main.py               # Point d'entrée FastAPI
│   └── requirements.txt      # Dépendances Python
├── agent/                    # Agent EDR Windows natif
│   └── sentinel_audit.ps1    # Script d'audit de posture système
├── mobile/                   # Application Mobile Flutter
│   ├── lib/                  # Screens (Login, Home, AlertDetail, Blacklist)
│   └── pubspec.yaml
├── deploy/                   # Déploiement Cloud (GCP Cloud Run & Cloud SQL)
├── render.yaml               # Infrastructure-as-Code pour Render Cloud
└── docker-compose.yml        # Orchestration locale
```

---

## 🎯 Compétences Démontrées & Atouts Techniques

* **Cybersécurité Défensive (Blue Team / SOC)** : Détection d'attaques par force brute, calculs de vitesses spatiotemporelles anormales (formule de Haversine), fuzzing d'endpoints et remédiation dynamique par liste noire et pare-feu.
* **Audit & Posture Endpoint (EDR)** : Collecte de télémétrie Windows sans agent lourd tiers, scoring CIS-like et détection de mauvaises configurations de sécurité.
* **Intelligence Artificielle** : Détection d'anomalies de comportement non supervisée grâce à **Isolation Forest** (Scikit-Learn).
* **Multi-Tenancy & Sécurité d'Accès** : Cloisonnement strict des organisations, authentification PBKDF2-HMAC-SHA256, clés d'agents d'infrastructure dédiées.
* **DevOps & Multi-Plateforme** : Déploiement Cloud automatisé (Render Blueprint, Docker, GCP Cloud Run) et application mobile compagnon réactive (**Flutter**).
