# 🛡️ SentinelWatch — Agent d'Audit & de Posture de Sécurité d'Entreprise

Cet agent est conçu pour être déployé sur **n'importe quel ordinateur ou serveur d'entreprise** sans prérequis (il ne nécessite ni Python ni Node.js sur les machines cibles).

---

## 🚀 Comment Lancer l'Audit sur une Machine d'Entreprise

### Cas 1 : Exécution Immédiate sur un PC Windows (Poste ou Serveur)

Ouvre PowerShell en tant qu'administrateur et lance simplement :

```powershell
# 1. Se placer dans le dossier de l'agent
cd c:\Users\Khaled\Videos\APK\sentinel-watch\agent

# 2. Lancer l'audit (analyse en direct et envoi au serveur SentinelWatch)
.\sentinel_audit.ps1 -ApiUrl "http://127.0.0.1:8000/api/v1/audits"
```

> **Mode Hors-Ligne (Sans serveur)** :  
> Si tu es sur un PC sans connexion au serveur, ajoute `-Standalone` pour afficher le rapport et les solutions directement à l'écran :
> ```powershell
> .\sentinel_audit.ps1 -Standalone
> ```

---

### Cas 2 : Déploiement en Masse sur 50, 100 ou 500 PC (Active Directory / GPO)

En entreprise, un administrateur réseau n'a pas besoin de passer physiquement sur chaque poste :

```powershell
# Déploiement à distance sur tout le parc d'ordinateurs du domaine d'entreprise :
$Computers = (Get-ADComputer -Filter *).Name
Invoke-Command -ComputerName $Computers -FilePath .\sentinel_audit.ps1 -ArgumentList "http://ip-serveur-sentinelwatch:8000/api/v1/audits"
```

---

## 🔍 Ce que l'Agent Vérifie Réllement sur le Système

1. **Pare-feu Windows (Firewall)** :
   - Vérifie si les 3 profils (*Domaine*, *Privé*, *Public*) sont bien actifs.
   - *Solution automatique proposée si désactivé* : `Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True`.

2. **Antivirus & Protection en Temps Réel** :
   - Vérifie que Windows Defender ou l'antivirus d'entreprise est actif et que les signatures datent de moins de 7 jours.
   - *Solution automatique proposée* : `Update-MpSignature`.

3. **Ports Réseau Vulnérables Écoutant sur la Machine** :
   - Détecte l'ouverture du **Port 3389 (Bureau à distance RDP)**, cible favorite des attaques par ransomware.
   - Détecte la présence de services non chiffrés obsolètes (Telnet port 23, FTP port 21).

4. **Audit des Comptes et Privilèges** :
   - Détecte si le compte invité anonyme (*Guest*) est activé.
   - Liste tous les utilisateurs ayant les pleins droits administrateurs locaux (détection du sur-privilège).

5. **Vrais Journaux de Sécurité Windows (Event ID 4625)** :
   - Analyse les récents échecs réels d'authentification survenus sur la machine dans les dernières 24h pour détecter les tentatives de devinette de mot de passe.
