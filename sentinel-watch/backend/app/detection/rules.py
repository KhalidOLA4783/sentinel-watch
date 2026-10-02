import math
from datetime import datetime, timedelta
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.log import AccessLog
from app.models.alert import Alert

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calcule la distance orthodromique (à vol d'oiseau) en kilomètres
    entre deux points GPS à l'aide de la formule de Haversine.
    """
    R = 6371.0  # Rayon moyen de la Terre en km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2.0)**2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0)**2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))

    return R * c

def check_impossible_travel(db: Session, current_log: AccessLog) -> Optional[Alert]:
    """
    Détecte le scénario 'Voyage Impossible' :
    Deux connexions distantes pour le même compte utilisateur dans un laps de temps
    impliquant une vitesse de déplacement surhumaine (> 900 km/h).
    """
    if not current_log.user_identifier or current_log.user_identifier == "anonymous":
        return None
    if current_log.latitude is None or current_log.longitude is None:
        return None

    # Recherche du dernier log précédent pour ce même utilisateur
    prev_log = db.query(AccessLog).filter(
        AccessLog.user_identifier == current_log.user_identifier,
        AccessLog.id != current_log.id,
        AccessLog.timestamp <= current_log.timestamp,
        AccessLog.latitude.isnot(None),
        AccessLog.longitude.isnot(None)
    ).order_by(desc(AccessLog.timestamp)).first()

    if not prev_log:
        return None

    # Si même ville ou même IP, pas d'impossible travel
    if prev_log.ip_address == current_log.ip_address:
        return None

    time_diff_hours = (current_log.timestamp - prev_log.timestamp).total_seconds() / 3600.0
    if time_diff_hours <= 0:
        return None

    # Calcul distance
    distance_km = haversine_distance_km(
        prev_log.latitude, prev_log.longitude,
        current_log.latitude, current_log.longitude
    )

    # Si distance significative (> 150 km)
    if distance_km > 150.0:
        calculated_speed = distance_km / time_diff_hours
        if calculated_speed > 900.0: # Vitesse d'un avion de ligne standard
            time_diff_mins = time_diff_hours * 60.0
            ville1 = f"{prev_log.city or 'Inconnu'} ({prev_log.country_code or '??'})"
            ville2 = f"{current_log.city or 'Inconnu'} ({current_log.country_code or '??'})"
            
            desc_text = (
                f"Voyage impossible détecté pour '{current_log.user_identifier}' : "
                f"{distance_km:.0f} km parcourus en seulement {time_diff_mins:.1f} min "
                f"({calculated_speed:.0f} km/h) entre {ville1} et {ville2}."
            )

            return Alert(
                alert_type="IMPOSSIBLE_TRAVEL",
                severity="CRITICAL",
                source_ip=current_log.ip_address,
                target_user=current_log.user_identifier,
                description=desc_text,
                details=f"IP précédente: {prev_log.ip_address} | Distance: {distance_km:.1f}km | Vitesse: {calculated_speed:.0f}km/h",
                anomaly_score=1.0,
                log_id=current_log.id
            )

    return None

def check_bruteforce(db: Session, current_log: AccessLog) -> Optional[Alert]:
    """
    Détecte les tentatives de force brute / dictionnaire :
    Rafale d'échecs (401/403) sur une fenêtre glissante de 60 secondes.
    """
    if current_log.http_status not in [401, 403]:
        return None

    window_start = current_log.timestamp - timedelta(seconds=60)

    # Nombre d'échecs sur cette IP dans la dernière minute
    fail_count = db.query(AccessLog).filter(
        AccessLog.ip_address == current_log.ip_address,
        AccessLog.http_status.in_([401, 403]),
        AccessLog.timestamp >= window_start
    ).count()

    if fail_count >= 5:
        # Anti-flood d'alertes : vérifier si une alerte BRUTE_FORCE existe déjà sur cette IP dans les 30s
        recent_alert = db.query(Alert).filter(
            Alert.source_ip == current_log.ip_address,
            Alert.alert_type == "BRUTE_FORCE",
            Alert.timestamp >= current_log.timestamp - timedelta(seconds=30)
        ).first()

        if not recent_alert:
            severity = "CRITICAL" if fail_count >= 15 else "HIGH"
            desc_text = (
                f"Attaque par Force Brute détectée : {fail_count} tentatives d'authentification échouées "
                f"en moins de 60s depuis {current_log.ip_address} sur le compte '{current_log.user_identifier}'."
            )
            return Alert(
                alert_type="BRUTE_FORCE",
                severity=severity,
                source_ip=current_log.ip_address,
                target_user=current_log.user_identifier,
                description=desc_text,
                details=f"Tentatives échouées: {fail_count} dans la fenêtre de 60s",
                anomaly_score=0.9,
                log_id=current_log.id
            )

    return None

def check_recon_scan(db: Session, current_log: AccessLog) -> Optional[Alert]:
    """
    Détecte les sondes et scans de vulnérabilités (fuzzing d'endpoints sensibles, 404 en rafale).
    """
    sensitive_keywords = [
        "/.env", "/wp-login", "config.json", "phpmyadmin", "backup.sql",
        "/.git", "actuator", "/api/internal", "/server-status"
    ]

    matched_keyword = None
    for kw in sensitive_keywords:
        if kw in current_log.endpoint.lower():
            matched_keyword = kw
            break

    if matched_keyword:
        # Vérifier anti-flood
        recent_alert = db.query(Alert).filter(
            Alert.source_ip == current_log.ip_address,
            Alert.alert_type == "RECON_SCAN",
            Alert.timestamp >= current_log.timestamp - timedelta(seconds=20)
        ).first()

        if not recent_alert:
            desc_text = (
                f"Sonde de vulnérabilités / Scan suspect détecté depuis {current_log.ip_address} : "
                f"tentative d'accès au fichier/endpoint sensible '{current_log.endpoint}'."
            )
            return Alert(
                alert_type="RECON_SCAN",
                severity="HIGH",
                source_ip=current_log.ip_address,
                target_user=current_log.user_identifier,
                description=desc_text,
                details=f"Mot-clé détecté: {matched_keyword} | Statut HTTP: {current_log.http_status}",
                anomaly_score=0.85,
                log_id=current_log.id
            )

    return None
