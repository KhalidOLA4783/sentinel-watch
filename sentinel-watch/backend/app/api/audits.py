from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.audit import AuditReport
from app.models.alert import Alert
from app.schemas.audit import AuditReportIn, AuditReportOut

router = APIRouter(prefix="/audits", tags=["Enterprise Audit & Posture"])

@router.post("", response_model=AuditReportOut, status_code=status.HTTP_201_CREATED)
def receive_audit_report(report_in: AuditReportIn, db: Session = Depends(get_db)):
    """
    Reçoit le rapport d'audit de sécurité d'un poste ou serveur d'entreprise.
    Stocke les vulnérabilités constatées et génère des alertes si failles critiques.
    """
    findings_data = [item.model_dump() for item in report_in.findings]

    db_report = AuditReport(
        hostname=report_in.hostname,
        os_version=report_in.os_version,
        ip_address=report_in.ip_address,
        mac_address=report_in.mac_address,
        domain_name=report_in.domain_name,
        security_score=report_in.security_score,
        risk_level=report_in.risk_level,
        firewall_enabled=report_in.firewall_enabled,
        antivirus_active=report_in.antivirus_active,
        dangerous_ports_count=report_in.dangerous_ports_count,
        failed_logins_24h=report_in.failed_logins_24h,
        findings=findings_data,
        status="NEW"
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)

    # Si le score de sécurité est faible ou présence de faille critique,
    # générer automatiquement une alerte dans la tour de contrôle
    if report_in.security_score < 70 or report_in.risk_level in ["CRITICAL", "HIGH"]:
        critical_findings = [f for f in report_in.findings if f.severity in ["CRITICAL", "HIGH"]]
        reasons = ", ".join([f.title for f in critical_findings[:2]])
        
        alert = Alert(
            alert_type="ENDPOINT_SECURITY_FLAW",
            severity="CRITICAL" if report_in.security_score < 50 else "HIGH",
            source_ip=report_in.ip_address,
            target_user=report_in.hostname,
            description=f"Faiblesses critiques sur {report_in.hostname} (Score: {report_in.security_score}/100) : {reasons}",
            details=f"OS: {report_in.os_version} | Failles critiques: {len(critical_findings)}",
            anomaly_score=float((100 - report_in.security_score) / 100.0),
            status="PENDING"
        )
        db.add(alert)
        db.commit()

    return db_report

@router.get("", response_model=List[AuditReportOut])
def get_audit_reports(
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=100),
    hostname: Optional[str] = None,
    risk_level: Optional[str] = None
):
    """Récupère l'historique des audits de machines d'entreprise."""
    query = db.query(AuditReport)
    if hostname:
        query = query.filter(AuditReport.hostname.ilike(f"%{hostname}%"))
    if risk_level:
        query = query.filter(AuditReport.risk_level == risk_level.upper())

    return query.order_by(desc(AuditReport.timestamp)).limit(limit).all()

@router.get("/{report_id}", response_model=AuditReportOut)
def get_audit_detail(report_id: int, db: Session = Depends(get_db)):
    """Récupère le détail complet d'un audit de machine avec ses solutions recommandées."""
    report = db.query(AuditReport).filter(AuditReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Rapport d'audit introuvable")
    return report
