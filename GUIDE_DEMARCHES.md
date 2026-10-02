# 🛡️ SentinelWatch — Guide Maître & Démarches d'Utilisation Réelles

Bienvenue sur le guide officiel de **SentinelWatch**, le système de surveillance de sécurité, détection d'intrusions par IA, audit réel de postes d'entreprise (EDR Posture), boîte à outils forensic et console mobile Android (APK).

---

## 📌 Sommaire des Démarches

1. [Démarrage Rapide en 1 Clic (Les Fichiers `.bat`)](#1-démarrage-rapide-en-1-clic-les-fichiers-bat)
2. [Protocole de Test 100% Réel (Sans Simulateur)](#2-protocole-de-test-100-réel-sans-simulateur)
3. [Installation & Connexion de l'Application Mobile (APK)](#3-installation--connexion-de-lapplication-mobile-apk)
4. [La Boîte à Outils Forensic & VirusTotal](#4-la-boîte-à-outils-forensic--virustotal)
5. [Comment Vendre et Déployer le Projet chez un Client](#5-comment-vendre-et-déployer-le-projet-chez-un-client)
6. [Plan Complet des Fichiers du Projet](#6-plan-complet-des-fichiers-du-projet)

---

## 1. Démarrage Rapide en 1 Clic (Les Fichiers `.bat`)

Tous les outils essentiels ont été automatisés sous forme de fichiers exécutables directement dans le dossier :  
📁 `C:\Users\Khaled\Videos\APK\`

| Fichier Exécutable | Rôle & Action Immédiate |
| :--- | :--- |
| **`COMPILER_NOUVEL_APK.bat`** | Compile l'application Android avec le système de connexion et les autorisations réseau, puis génère **`SentinelWatch.apk`**. |
| **`LANCER_SERVEUR.bat`** | Allume le serveur backend central et **ouvre automatiquement le Tableau de Bord Web** dans votre navigateur (`http://localhost:8000/dashboard`). |
| **`AUTORISER_PORT_FIREWALL.bat`** | Ouvre le port 8000 dans le pare-feu Windows pour permettre au smartphone de communiquer avec le PC en Wi-Fi. |
| **`LANCER_AUDIT.bat`** | Lance le scan de sécurité réel de votre machine Windows (Pare-feu, Defender, RDP/NLA, Hosts, Temp) et envoie la note sur 100 au serveur. |
| **`AFFICHER_MON_IP_POUR_TELEPHONE.bat`** | Affiche l'adresse IP Wi-Fi exacte de votre PC (ex: `http://192.168.1.38:8000/api/v1`) pour la connexion mobile. |
| **`VERIFIER_FICHIER_VIRUSTOTAL.bat`** | Glissez n'importe quel fichier suspect dessus : il calcule son SHA-256 et ouvre directement la recherche VirusTotal. |
| **`SUPPRIMER_FICHIERS_INUTILES.bat`** | Nettoie les fichiers obsolètes, anciens caches et scripts redondants. |

---

## 2. Protocole de Test 100% Réel (Sans Simulateur)

Le projet ne repose sur aucun faux script de simulation : tout est testable en conditions réelles.

### Test Réel N°1 : Le Scan de Sécurité du Poste Windows
1. Double-cliquez sur **`LANCER_SERVEUR.bat`** pour démarrer la tour de contrôle.
2. Double-cliquez sur **`LANCER_AUDIT.bat`** pour scanner votre machine.
3. Allez sur votre navigateur dans l'onglet **« 🛡️ Audits Postes Entreprise »** :
   - Vous voyez le nom de votre PC, votre système d'exploitation et votre vrai score de sécurité sur 100.
   - Chaque faille découverte (ex: port RDP ouvert, installeur dans `%TEMP%`, pare-feu coupé) détaille son risque et fournit une commande de remédiation en 1 clic.

### Test Réel N°2 : Déclencher une Vraie Attaque par Force Brute (Sans Simulateur)
Pour prouver que l'algorithme de détection fonctionne avec de vraies requêtes :
Ouvrez une fenêtre PowerShell et collez cette commande pour envoyer 6 tentatives de connexion échouées avec de faux identifiants :

```powershell
1..6 | ForEach-Object {
    Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/logs" -Method Post -ContentType "application/json" -Body '{"ip_address":"198.51.100.42","endpoint":"/api/v1/auth/login","http_method":"POST","http_status":401,"user_identifier":"admin.root","latitude":48.85,"longitude":2.35}'
}
```

**Résultat immédiat :**
- Le moteur mathématique (`rules.py`) calcule le dépassement du seuil de 5 échecs consécutifs en moins de 60 secondes.
- L'alerte rouge **`BRUTE_FORCE`** apparaît en direct sur votre Tableau de Bord Web et sur votre application mobile !
- Cliquez sur **"Bannir l'IP"** : l'IP `198.51.100.42` est immédiatement neutralisée dans la liste noire.

---

## 3. Installation & Connexion de l'Application Mobile (APK)

L'application Android native intègre désormais un **système complet d'authentification utilisateur**, les autorisations réseau Wi-Fi sécurisées et le **Pilote Autonome de Remédiation en 1 Clic**.

### A. Générer le nouvel APK avec Connexion
1. Sur votre PC, double-cliquez sur **`COMPILER_NOUVEL_APK.bat`**.
2. Le script configure automatiquement Java OpenJDK 17 LTS, compile le code Flutter et dépose directement à la racine :
   📁 `C:\Users\Khaled\Videos\APK\SentinelWatch.apk`

### B. Autoriser le pare-feu du PC
Pour que votre smartphone puisse joindre votre PC en Wi-Fi, faites un clic droit sur **`AUTORISER_PORT_FIREWALL.bat`** > **Exécuter en tant qu'administrateur** *(cette étape n'est à faire qu'une seule fois)*.

### C. Transférer l'APK sur votre smartphone
- **Option 1 (Le plus simple) :** Ouvrez **WhatsApp Web** sur votre PC et envoyez `SentinelWatch.apk` dans votre propre discussion (*Message à vous-même*).
- **Option 2 :** Branchez votre smartphone par câble USB et copiez le fichier dans le dossier *Téléchargements*.
- **Option 3 :** Glissez le fichier sur Google Drive et téléchargez-le sur votre téléphone.

### D. Installer & Se Connecter depuis le Smartphone
1. Désinstallez l'ancienne version sur votre téléphone si elle était présente.
2. Appuyez sur `SentinelWatch.apk` depuis vos téléchargements et installez-la.
3. Lancez l'application : l'écran de **Connexion SentinelWatch SOC** apparaît.
4. **Identifiants de sécurité par défaut :**
   - **Nom d'utilisateur / Email :** `admin`
   - **Mot de passe :** `Admin123!`
   - **URL Serveur :** Pré-remplie automatiquement avec votre IP Wi-Fi (`http://192.168.1.38:8000/api/v1`).
5. Appuyez sur **« SE CONNECTER À LA CONSOLE »** (ou cliquez sur « Créer un compte analyste » si vous voulez vous inscrire avec votre propre nom !).
6. Vous êtes connecté : vos alertes s'actualisent en direct, et en cas d'attaque critique, le **Pilote Autonome** vous propose un bouton pour bannir l'IP en 1 clic !

---

## 4. La Boîte à Outils Forensic & VirusTotal

Accessible directement dans l'onglet **« 🔬 Boîte à Outils & VirusTotal »** du Tableau de Bord Web :

1. **Calculateur SHA-256 en local & VirusTotal :**
   - Glissez n'importe quel fichier suspect dans l'espace prévu : le navigateur calcule son empreinte SHA-256 en quelques millisecondes via l'API Web Crypto sans jamais envoyer le fichier sur un serveur externe (confidentialité 100%).
   - Un bouton vous emmène directement sur la page officielle VirusTotal pour vérifier la réputation auprès de 70 antivirus mondiaux.
2. **Contrôles Rapides Système :**
   - **Fichier HOSTS (`C:\Windows\System32\drivers\etc\hosts`)** : Détection des détournements DNS et commandes pour inspecter/éditer.
   - **Intégrité Système** : Commandes `DISM.exe /Online /Cleanup-image /Restorehealth` et `sfc /scannow` pour restaurer les DLL Windows modifiées.
   - **Bureau à distance (RDP & NLA)** : Vérification du chiffrement NLA obligatoire pour bloquer les ransomwares.
   - **Historique PowerShell** : Détection des scripts furtifs (`IEX`, `DownloadString`, base64).
3. **Les 4 Outils Gratuits Recommandés :**
   - Liens directs et cas d'usage vers les standards de l'industrie : **Sysinternals Autoruns**, **Sysinternals Process Explorer**, **Sysinternals TCPView** et **Malwarebytes AdwCleaner**.

---

## 5. Comment Vendre et Déployer le Projet chez un Client

### Les 2 Formules Commerciales Rentables :
1. **L'Audit Flash de Sécurité (Prestation One-Shot : 500 € à 1 500 €) :**  
   Vous vous déplacez avec votre clé USB ou envoyez le script `sentinel_audit.ps1` au client. En 15 minutes, vous analysez 20 PC, remettez un rapport de posture avec score sur 100 et le plan d'action de remédiation au dirigeant.
2. **L'Abonnement Mensuel de Protection SOC (30 € à 50 € / poste / mois) :**  
   Le serveur SentinelWatch tourne dans le Cloud (Cloud Run ou VPS). L'agent tourne chaque matin sur les PC des employés. Le dirigeant a l'application mobile sur son smartphone et gère les alertes en direct. Pour 25 salariés : **1 000 € / mois de revenu récurrent**.

### Déploiement Industriel sur 50 Ordinateurs (Sans Rien Installer) :
En entreprise, l'administrateur informatique n'a pas besoin de passer sur chaque machine :
- Il dépose `sentinel_audit.ps1` dans la politique de groupe **GPO Windows** ou **Microsoft Intune**.
- Le script s'exécute silencieusement à l'ouverture de session de chaque collaborateur :
  ```powershell
  .\sentinel_audit.ps1 -ApiUrl "https://soc.votre-entreprise.com/api/v1/audits"
  ```
- Les 50 machines et leurs scores remontent automatiquement sur votre Tableau de Bord !

---

## 6. Plan Complet des Fichiers du Projet

```text
C:\Users\Khaled\Videos\APK\
│
├── GUIDE_DEMARCHES.md                    <-- Ce guide officiel complet
├── README.md                             <-- Résumé d'accueil rapide
├── SentinelWatch.apk                     <-- Fichier d'installation Android prêt (20 Mo)
│
├── LANCER_SERVEUR.bat                    <-- Allume le serveur + ouvre le navigateur Web
├── LANCER_AUDIT.bat                      <-- Scanne la machine Windows en 1 clic
├── COPIER_APK_ICI.bat                    <-- Copie l'APK à la racine
├── AFFICHER_MON_IP_POUR_TELEPHONE.bat    <-- Affiche l'adresse Wi-Fi pour l'app mobile
├── VERIFIER_FICHIER_VIRUSTOTAL.bat       <-- Glisser-déposer un fichier suspect pour VirusTotal
├── REINITIALISER_PROJET_PROD.bat         <-- Nettoyage et remise à zéro de la base de données
│
└── sentinel-watch/
    ├── dashboard.html                    <-- Code source du Tableau de Bord Web SOC & Audits
    │
    ├── backend/                          <-- Cœur FastAPI, SQLAlchemy & Détection
    │   ├── main.py                       <-- Point d'entrée de l'API
    │   ├── sentinelwatch.db              <-- Base de données SQLite locale
    │   ├── requirements.txt              <-- Dépendances Python
    │   └── app/
    │       ├── detection/                <-- Moteur Haversine + Machine Learning Isolation Forest
    │       ├── models/                   <-- Tables Logs, Alertes, Blacklist, Audits
    │       ├── schemas/                  <-- Modèles Pydantic de validation
    │       └── static/                   <-- Interface Web SOC & Forensic
    │
    ├── agent/                            <-- Outils de scan réel sur machine
    │   ├── sentinel_audit.ps1            <-- Agent d'audit complet Windows (sans dépendance)
    │   ├── check_virustotal.ps1          <-- Analyseur de hash et ouverture VirusTotal
    │   └── agent.py                      <-- Agent universel multi-plateforme Python
    │
    ├── mobile/                           <-- Application Mobile Flutter
    │   ├── lib/                          <-- Code source Dart (Écrans, Alertes, Modèles)
    │   └── build/.../app-release.apk     <-- Binaire APK compilé de production
    │
    └── deploy/                           <-- Déploiement Cloud (Google Cloud Platform)
        ├── deploy_gcp.ps1                <-- Déploiement automatique Cloud Run + Cloud SQL
        └── GCP_DEPLOYMENT_GUIDE.md       <-- Documentation d'architecture cloud
```
