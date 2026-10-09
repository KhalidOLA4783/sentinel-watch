from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

class FindingItem(BaseModel):
    """Constat de sécurité avec explication du risque et solution concrète."""
    title: str
    severity: str  # "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"
    category: str  # "FIREWALL", "ANTIVIRUS", "NETWORK_PORTS", "USER_ACCOUNTS", "SECURITY_LOGS", "PATCHES"
    observation: str
    risk: str
    solution: str
    remediation_command: Optional[str] = None

class AuditReportIn(BaseModel):
    """Rapport d'audit envoyé par l'agent depuis la machine auditée."""
    hostname: str
    os_version: str
    ip_address: str
    mac_address: Optional[str] = None
    domain_name: Optional[str] = None
    organization: Optional[str] = "SentinelWatch SOC"
    agent_key: Optional[str] = None
    security_score: int = Field(..., ge=0, le=100)
    risk_level: str
    firewall_enabled: bool = True
    antivirus_active: bool = True
    dangerous_ports_count: int = 0
    failed_logins_24h: int = 0
    findings: List[FindingItem]

class AuditReportOut(AuditReportIn):
    """Rapport d'audit formaté pour affichage dans le dashboard et l'app mobile."""
    id: int
    timestamp: datetime
    status: str

    class Config:
        from_attributes = True
