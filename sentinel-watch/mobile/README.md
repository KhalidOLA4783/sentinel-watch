# 📱 SentinelWatch Mobile (Flutter)

Console nomade d'intervention et de supervision de sécurité en temps réel pour SentinelWatch.

---

## 🎯 Fonctionnalités Clés

- **Flux d'Alertes Temps Réel** : Réception instantanée des alertes qualifiées (`IMPOSSIBLE_TRAVEL`, `BRUTE_FORCE`, `RECON_SCAN`, `ML_ANOMALY`).
- **Dossier d'Incident Technique** : Analyse détaillée de la menace (vitesse de déplacement Haversine, nombre de tentatives, compte ciblé, IP attaquante).
- **Bouton d'Urgence 1-Tap "BANNIR L'IP"** : Déclenche immédiatement le bannissement de l'IP source sur le backend FastAPI (`POST /api/v1/alerts/{id}/ban`).
- **Gestion de la Liste Noire (Blacklist)** : Consultation des IPs bloquées et déblocage en 1 clic.
- **Sélecteur d'Environnement** : Configuration directe de l'URL API (Émulateur Android `10.0.2.2:8000`, Desktop `127.0.0.1:8000`, ou Smartphone Wi-Fi `192.168.X.X:8000`).

---

## 🚀 Comment Lancer l'Application Mobile

Dans un terminal dédié :

```bash
cd mobile

# 1. Télécharger les dépendances
flutter pub get

# 2. Lancer sur la plateforme de ton choix :

# Option A : Sur ton PC Windows directement (super rapide pour tester)
flutter run -d windows

# Option B : Dans le navigateur Web (Chrome)
flutter run -d chrome

# Option C : Sur Émulateur Android ou smartphone branché en USB
flutter run
```
