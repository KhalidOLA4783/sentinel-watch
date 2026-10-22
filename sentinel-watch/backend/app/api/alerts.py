from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.alert import Alert, BlacklistedIP
from app.models.user import User
from app.schemas.alert import AlertOut, AlertUpdate, BlacklistCreate, BlacklistOut
from app.api.deps import get_current_user, require_role
from app.core.websocket import ws_manager
import asyncio

router = APIRouter(tags=["Alerts & Remediation"])

@router.get("/alerts", response_model=List[AlertOut])
def get_alerts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    status: Optional[str] = None,
    severity: Optional[str] = None,
    alert_type: Optional[str] = None
):
    """Liste paginée des alertes de sécurité avec filtres (Analystes & Admins)."""
    query = db.query(Alert)
    if status:
        query = query.filter(Alert.status == status.upper())
    if severity:
        query = query.filter(Alert.severity == severity.upper())
    if alert_type:
        query = query.filter(Alert.alert_type == alert_type)

    return query.order_by(desc(Alert.timestamp)).offset(offset).limit(limit).all()

@router.get("/alerts/{alert_id}", response_model=AlertOut)
def get_alert_detail(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Détail d'une alerte spécifique."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvée")
    return alert

@router.patch("/alerts/{alert_id}", response_model=AlertOut)
def update_alert_status(
    alert_id: int,
    update_in: AlertUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Met à jour le statut d'une alerte (ACKNOWLEDGED, RESOLVED, FALSE_POSITIVE)."""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvée")

    alert.status = update_in.status.upper()
    db.commit()
    db.refresh(alert)
    return alert

@router.post("/alerts/{alert_id}/ban", response_model=BlacklistOut)
def ban_ip_from_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ADMIN", "ANALYST"))
):
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
        existing.reason = f"Bannie suite à l'alerte #{alert.id} ({alert.alert_type}) par {current_user.username}"
        db_black = existing
    else:
        db_black = BlacklistedIP(
            ip_address=alert.source_ip,
            reason=f"Bannie suite à l'alerte #{alert.id} ({alert.alert_type}) par {current_user.username} : {alert.description[:100]}",
            blocked_at=datetime.utcnow(),
            is_active=True
        )
        db.add(db_black)

    # Résolution automatique de l'alerte
    alert.status = "RESOLVED"
    db.commit()
    db.refresh(db_black)

    # Diffusion WebSocket
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.create_task(ws_manager.broadcast("ALERT_RESOLVED", {"id": alert.id, "status": "RESOLVED"}))
            asyncio.create_task(ws_manager.broadcast("IP_BANNED", {
                "ip_address": db_black.ip_address,
                "reason": db_black.reason,
                "blocked_at": db_black.blocked_at.isoformat()
            }))
    except Exception:
        pass

    return db_black

@router.get("/blacklist", response_model=List[BlacklistOut])
def get_blacklist(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Liste des adresses IP actuellement bannies."""
    return db.query(BlacklistedIP).filter(BlacklistedIP.is_active == True).order_by(desc(BlacklistedIP.blocked_at)).all()

@router.post("/blacklist", response_model=BlacklistOut, status_code=status.HTTP_201_CREATED)
def add_to_blacklist(
    entry: BlacklistCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ADMIN"))
):
    """Ajoute manuellement une adresse IP à la liste noire (Réservé ADMIN)."""
    existing = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == entry.ip_address).first()
    if existing:
        existing.is_active = True
        existing.reason = f"{entry.reason} (ajouté par {current_user.username})"
        db.commit()
        db.refresh(existing)
        return existing

    new_entry = BlacklistedIP(
        ip_address=entry.ip_address,
        reason=f"{entry.reason} (ajouté par {current_user.username})",
        blocked_at=datetime.utcnow(),
        is_active=True
    )
    db.add(new_entry)
    db.commit()
    db.refresh(new_entry)
    return new_entry

@router.delete("/blacklist/{ip_address}")
def remove_from_blacklist(
    ip_address: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("ADMIN"))
):
    """Débloque une adresse IP (Réservé ADMIN)."""
    entry = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == ip_address).first()
    if not entry:
        raise HTTPException(status_code=404, detail="IP non trouvée dans la liste noire")

    entry.is_active = False
    db.commit()
    return {"message": f"IP {ip_address} débloquée avec succès par {current_user.username}"}
