from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Index
from app.database import Base

class AccessLog(Base):
    """
    Modèle SQLAlchemy représentant un journal d'accès / connexion.
    Utilisé pour l'ingestion, la visualisation et l'analyse de sécurité.
    """
    __tablename__ = "access_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Identifiant utilisateur (username, email ou session id)
    user_identifier = Column(String(100), nullable=True, default="anonymous", index=True)
    organization = Column(String(100), default="SentinelWatch SOC", nullable=False, index=True)
    
    # Données réseau & géographiques
    ip_address = Column(String(45), nullable=False, index=True)
    country_code = Column(String(3), nullable=True) # Ex: "FR", "US", "JP"
    city = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    user_agent = Column(String(255), nullable=True)
    
    # Données de la requête HTTP
    http_method = Column(String(10), nullable=False, default="GET")
    endpoint = Column(String(255), nullable=False, default="/")
    http_status = Column(Integer, nullable=False, default=200, index=True)
    response_time_ms = Column(Float, nullable=True, default=0.0)
    
    # Drapeaux de sécurité & alertes préliminaires
    is_flagged = Column(Boolean, default=False, index=True)
    flag_reason = Column(String(255), nullable=True)

    __table_args__ = (
        Index("idx_user_time", "user_identifier", "timestamp"),
        Index("idx_ip_time", "ip_address", "timestamp"),
    )
