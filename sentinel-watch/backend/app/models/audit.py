from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, JSON, Index
from app.database import Base

class AuditReport(Base):
    """
    Rapport d'audit de sécurité d'un poste de travail ou serveur d'entreprise.
    Contient le score de sécurité, les vulnérabilités détectées et les solutions recommandées.
    """
    __tablename__ = "audit_reports"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Informations sur la machine auditée
    hostname = Column(String(100), nullable=False, index=True) # Ex: "PC-DIRECTION-01"
    os_version = Column(String(150), nullable=False)           # Ex: "Microsoft Windows 11 Professionnel"
    ip_address = Column(String(45), nullable=False)
    mac_address = Column(String(50), nullable=True)
    domain_name = Column(String(100), nullable=True)          # Ex: "WORKGROUP" ou "ENTREPRISE.LOCAL"
    
    # Évaluation globale
    security_score = Column(Integer, nullable=False)          # Score de 0 à 100
    risk_level = Column(String(20), nullable=False)           # "CRITICAL", "HIGH", "MEDIUM", "SECURE"
    
    # Résumé des vérifications clés
    firewall_enabled = Column(Boolean, default=True)
    antivirus_active = Column(Boolean, default=True)
    dangerous_ports_count = Column(Integer, default=0)
    failed_logins_24h = Column(Integer, default=0)
    
    # Liste détaillée des constats et solutions (stockée en JSON structuré)
    findings = Column(JSON, nullable=False)
    
    # Statut du rapport
    status = Column(String(30), default="NEW", index=True)     # "NEW", "ACKNOWLEDGED", "REMEDIATED"

    __table_args__ = (
        Index("idx_audit_host_time", "hostname", "timestamp"),
    )
