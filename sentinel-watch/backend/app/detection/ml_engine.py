import math
from datetime import datetime, timedelta
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.log import AccessLog
from app.models.alert import Alert

# Import conditionnel de scikit-learn pour garantir une tolérance aux pannes
try:
    import numpy as np
    from sklearn.ensemble import IsolationForest
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    IsolationForest = None
    np = None

class MLAnomalyDetector:
    """
    Détecteur d'anomalies basé sur l'algorithme non-supervisé Isolation Forest.
    Analyse le profil spatiotemporel et la dynamique de requêtage pour chaque connexion.
    """

    def __init__(self, contamination: float = 0.05):
        self.contamination = contamination
        self.model = None
        self.is_trained = False

    def _extract_features(self, db: Session, log: AccessLog) -> List[float]:
        """Extrait un vecteur de caractéristiques numériques représentatif."""
        # 1. Encodage cyclique de l'heure (0 à 23h)
        hour = log.timestamp.hour
        hour_sin = math.sin(2 * math.pi * hour / 24.0)
        hour_cos = math.cos(2 * math.pi * hour / 24.0)
        is_night = 1.0 if (hour < 6 or hour >= 22) else 0.0

        # 2. Caractère suspect du statut HTTP
        is_error = 1.0 if log.http_status in [401, 403, 404, 500] else 0.0

        # 3. Fréquence et vélocité sur les 5 dernières minutes
        window_start = log.timestamp - timedelta(minutes=5)
        ip_req_count = db.query(func.count(AccessLog.id)).filter(
            AccessLog.ip_address == log.ip_address,
            AccessLog.timestamp >= window_start
        ).scalar() or 1

        ip_fail_count = db.query(func.count(AccessLog.id)).filter(
            AccessLog.ip_address == log.ip_address,
            AccessLog.http_status.in_([401, 403]),
            AccessLog.timestamp >= window_start
        ).scalar() or 0

        # Vecteur 6-D
        return [hour_sin, hour_cos, is_night, is_error, float(ip_req_count), float(ip_fail_count)]

    def train_or_update(self, db: Session, min_samples: int = 40):
        """Entraîne ou réajuste l'Isolation Forest sur l'historique des logs normaux."""
        if not SKLEARN_AVAILABLE:
            return

        # Récupère un échantillon de logs récents
        recent_logs = db.query(AccessLog).order_by(AccessLog.id.desc()).limit(300).all()
        if len(recent_logs) < min_samples:
            return

        x_data = []
        for log_entry in recent_logs:
            x_data.append(self._extract_features(db, log_entry))

        x_array = np.array(x_data)
        
        # Initialisation du modèle Isolation Forest
        self.model = IsolationForest(
            n_estimators=75,
            contamination=self.contamination,
            random_state=42
        )
        self.model.fit(x_array)
        self.is_trained = True

    def predict_anomaly(self, db: Session, log: AccessLog) -> Optional[Alert]:
        """
        Évalue le log entrant. Si l'Isolation Forest le classe comme anomalie (-1)
        avec un score prononcé, génère une alerte de type ML_ANOMALY.
        """
        if not SKLEARN_AVAILABLE:
            return None

        # Auto-apprentissage au démarrage si suffisant de données
        if not self.is_trained:
            self.train_or_update(db)
            if not self.is_trained:
                return None

        features = np.array([self._extract_features(db, log)])
        prediction = self.model.predict(features)[0] # 1 = normal, -1 = anomalie
        score = float(self.model.decision_function(features)[0]) # Plus le score est négatif, plus c'est anomal

        if prediction == -1 and score < -0.08:
            # Vérifier anti-flood
            recent_alert = db.query(Alert).filter(
                Alert.source_ip == log.ip_address,
                Alert.alert_type == "ML_ANOMALY",
                Alert.timestamp >= log.timestamp - timedelta(seconds=30)
            ).first()

            if not recent_alert:
                desc_text = (
                    f"Comportement atypique détecté par l'IA (Isolation Forest) : "
                    f"connexion inhabituelle depuis {log.ip_address} (statut {log.http_status}, score IA: {score:.3f})."
                )
                return Alert(
                    alert_type="ML_ANOMALY",
                    severity="MEDIUM",
                    source_ip=log.ip_address,
                    target_user=log.user_identifier,
                    description=desc_text,
                    details=f"Decision score: {score:.4f} | Features: {features.tolist()[0]}",
                    anomaly_score=round(abs(score), 3),
                    log_id=log.id
                )

        return None

# Singleton global du modèle ML
ml_detector = MLAnomalyDetector()
