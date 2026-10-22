from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.log import AccessLog
from app.models.alert import Alert, BlacklistedIP
from app.detection.rules import check_impossible_travel, check_bruteforce, check_recon_scan
from app.detection.ml_engine import ml_detector
from app.soar.playbooks import playbook_engine

class DetectionEngine:
    """
    Orchestrateur central du cerveau de détection SentinelWatch.
    Exécute en cascade les règles déterministes et le modèle de Machine Learning.
    """

    def _handle_detected_alert(self, db: Session, alert: Alert) -> Alert:
        """Enregistre l'alerte et passe le relais au moteur SOAR pour remédiation autonome."""
        db.add(alert)
        db.commit()
        db.refresh(alert)
        playbook_engine.execute_playbooks(db, alert)
        return alert

    def analyze_log(self, db: Session, log: AccessLog) -> Optional[Alert]:
        """
        Analyse un événement de connexion entrant et génère une alerte si anomalie.
        """
        # 1. Vérification de la liste noire d'adresses IP
        blacklisted = db.query(BlacklistedIP).filter(
            BlacklistedIP.ip_address == log.ip_address,
            BlacklistedIP.is_active == True
        ).first()

        if blacklisted:
            log.is_flagged = True
            log.flag_reason = "IP_BLACKLISTED"
            alert = Alert(
                alert_type="BLACKLISTED_TRAFFIC",
                severity="CRITICAL",
                source_ip=log.ip_address,
                target_user=log.user_identifier,
                description=f"Tentative d'accès depuis une adresse IP bannie ({log.ip_address}). Motif de bannissement : {blacklisted.reason}",
                status="PENDING",
                log_id=log.id
            )
            return self._handle_detected_alert(db, alert)

        # 2. Règle Heuristique : Voyage Impossible (Haversine)
        travel_alert = check_impossible_travel(db, log)
        if travel_alert:
            log.is_flagged = True
            log.flag_reason = travel_alert.alert_type
            return self._handle_detected_alert(db, travel_alert)

        # 3. Règle Heuristique : Force Brute d'authentification
        brute_alert = check_bruteforce(db, log)
        if brute_alert:
            log.is_flagged = True
            log.flag_reason = brute_alert.alert_type
            return self._handle_detected_alert(db, brute_alert)

        # 4. Règle Heuristique : Scan de vulnérabilités / Endpoints sensibles
        recon_alert = check_recon_scan(db, log)
        if recon_alert:
            log.is_flagged = True
            log.flag_reason = recon_alert.alert_type
            return self._handle_detected_alert(db, recon_alert)

        # 5. Détection comportementale par IA (Isolation Forest)
        ml_alert = ml_detector.predict_anomaly(db, log)
        if ml_alert:
            log.is_flagged = True
            log.flag_reason = ml_alert.alert_type
            return self._handle_detected_alert(db, ml_alert)

        return None

detection_engine = DetectionEngine()
