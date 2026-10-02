from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

class AccessLogIn(BaseModel):
    """Schéma d'entrée pour l'ingestion d'un journal d'accès."""
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow, description="Horodatage UTC")
    user_identifier: Optional[str] = Field(default="anonymous", description="Nom d'utilisateur ou ID")
    ip_address: str = Field(..., description="Adresse IPv4 ou IPv6")
    country_code: Optional[str] = Field(None, description="Code pays ISO-2 (ex: FR, US)")
    city: Optional[str] = Field(None, description="Nom de la ville")
    latitude: Optional[float] = Field(None, description="Latitude géographique")
    longitude: Optional[float] = Field(None, description="Longitude géographique")
    user_agent: Optional[str] = Field(None, description="User-Agent du client")
    http_method: str = Field(default="GET", description="Méthode HTTP (GET, POST, etc.)")
    endpoint: str = Field(default="/", description="URL ou endpoint accédé")
    http_status: int = Field(default=200, description="Code de statut HTTP (200, 401, 403, 404, etc.)")
    response_time_ms: Optional[float] = Field(default=0.0, description="Temps de réponse en ms")

class AccessLogBatchIn(BaseModel):
    """Schéma pour l'ingestion groupée (batch) de journaux."""
    logs: List[AccessLogIn]

class AccessLogOut(AccessLogIn):
    """Schéma de sortie détaillé pour l'affichage dans le dashboard et l'API."""
    id: int
    is_flagged: bool
    flag_reason: Optional[str] = None

    class Config:
        from_attributes = True

class LogStats(BaseModel):
    """Statistiques globales des logs ingérés."""
    total_logs: int
    total_failed_logins: int
    unique_ips: int
    flagged_logs: int
    recent_activity_count: int
