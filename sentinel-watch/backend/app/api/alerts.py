from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.alert import Alert, BlacklistedIP
from app.schemas.alert import AlertOut, AlertUpdate, BlacklistCreate, BlacklistOut

router = APIRouter(tags=["Alerts & Remediation"])

@router.get("/alerts", response_model=List[AlertOut])
def get_alerts(
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    status: Optional[str] = None,
    severity: Optional[str] = None,
    alert_type: Optional[str] = None,
    organization: Optional[str] = None
):
    """Liste paginée des alertes de sécurité avec filtres."""
    query = db.query(Alert)
    if organization:
        query = query.filter(Alert.organization == organization)
    if status:
        query = query.filter(Alert.status == status.upper())
    if severity:
        query = query.filter(Alert.severity == severity.upper())
    if alert_type:
        query = query.filter(Alert.alert_type == alert_type)

    return query.order_by(desc(Alert.timestamp)).offset(offset).limit(limit).all()

@router.get("/alerts/{alert_id}", response_model=AlertOut)
def get_alert_detail(alert_id: int, db: Session = Depends(get_db)):
    """Détail d'une alerte spécifique."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvée")
    return alert

@router.patch("/alerts/{alert_id}", response_model=AlertOut)
def update_alert_status(alert_id: int, update_in: AlertUpdate, db: Session = Depends(get_db)):
    """Met à jour le statut d'une alerte (ACKNOWLEDGED, RESOLVED, FALSE_POSITIVE)."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvée")

    alert.status = update_in.status.upper()
    db.commit()
    db.refresh(alert)
    return alert

@router.post("/alerts/{alert_id}/ban", response_model=BlacklistOut)
def ban_ip_from_alert(alert_id: int, db: Session = Depends(get_db)):
    """
    Action de remédiation 1-clic :
    Bannit immédiatement l'adresse IP source liée à une alerte et passe l'alerte en RESOLVED.
    """
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvée")

    existing = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == alert.source_ip).first()
    if existing:
        existing.is_active = True
        existing.reason = f"Bannie suite à l'alerte #{alert.id} ({alert.alert_type})"
        db_black = existing
    else:
        db_black = BlacklistedIP(
            ip_address=alert.source_ip,
            reason=f"Bannie suite à l'alerte #{alert.id} ({alert.alert_type}) : {alert.description[:100]}",
            blocked_at=datetime.utcnow(),
            is_active=True
        )
        db.add(db_black)

    # Résolution automatique de l'alerte
    alert.status = "RESOLVED"
    db.commit()
    db.refresh(db_black)
    return db_black

@router.get("/blacklist", response_model=List[BlacklistOut])
def get_blacklist(db: Session = Depends(get_db)):
    """Liste des adresses IP actuellement bannies."""
    return db.query(BlacklistedIP).filter(BlacklistedIP.is_active == True).order_by(desc(BlacklistedIP.blocked_at)).all()

@router.post("/blacklist", response_model=BlacklistOut, status_code=status.HTTP_201_CREATED)
def add_to_blacklist(entry: BlacklistCreate, db: Session = Depends(get_db)):
    """Ajoute manuellement une adresse IP à la liste noire."""
    existing = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == entry.ip_address).first()
    if existing:
        existing.is_active = True
        existing.reason = entry.reason
        db.commit()
        db.refresh(existing)
        return existing

    new_entry = BlacklistedIP(
        ip_address=entry.ip_address,
        reason=entry.reason,
        blocked_at=datetime.utcnow(),
        is_active=True
    )
    db.add(new_entry)
    db.commit()
    db.refresh(new_entry)
    return new_entry

@router.delete("/blacklist/{ip_address}")
def remove_from_blacklist(ip_address: str, db: Session = Depends(get_db)):
    """Débloque une adresse IP."""
    entry = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == ip_address).first()
    if not entry:
        raise HTTPException(status_code=404, detail="IP non trouvée dans la liste noire")

    entry.is_active = False
    db.commit()
    return {"message": f"IP {ip_address} débloquée avec succès"}
