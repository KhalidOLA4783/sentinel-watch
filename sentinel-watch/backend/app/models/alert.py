from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.database import Base

class Alert(Base):
    """
    Modèle SQLAlchemy pour les alertes de sécurité qualifiées
    générées par les règles heuristiques ou le modèle d'IA.
    """
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Type d'incident : BRUTE_FORCE, IMPOSSIBLE_TRAVEL, RECON_SCAN, ML_ANOMALY
    alert_type = Column(String(50), nullable=False, index=True)
    
    # Gravité : LOW, MEDIUM, HIGH, CRITICAL
    severity = Column(String(20), nullable=False, default="MEDIUM", index=True)
    organization = Column(String(100), default="SentinelWatch SOC", nullable=False, index=True)
    
    # Cible & source
    source_ip = Column(String(45), nullable=False, index=True)
    target_user = Column(String(100), nullable=True, index=True)
    
    # Description lisible et détails techniques
    description = Column(String(500), nullable=False)
    details = Column(String(1000), nullable=True) # Métadonnées complémentaires
    
    # Score d'anomalie ML éventuel (-1.0 à 1.0)
    anomaly_score = Column(Float, nullable=True)
    
    # Statut du cycle de vie de l'incident : PENDING, ACKNOWLEDGED, RESOLVED, FALSE_POSITIVE
    status = Column(String(30), nullable=False, default="PENDING", index=True)
    
    # Log associé ayant déclenché l'alerte
    log_id = Column(Integer, ForeignKey("access_logs.id"), nullable=True)
    log = relationship("AccessLog")

    __table_args__ = (
        Index("idx_alert_status_sev", "status", "severity"),
    )

class BlacklistedIP(Base):
    """
    Modèle pour les adresses IP bannies (manuellement ou automatiquement).
    """
    __tablename__ = "ip_blacklist"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ip_address = Column(String(45), unique=True, nullable=False, index=True)
    reason = Column(String(255), nullable=False)
    blocked_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, index=True)
