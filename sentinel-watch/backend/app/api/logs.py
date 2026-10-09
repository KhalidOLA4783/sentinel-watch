from typing import List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.database import get_db
from app.models.log import AccessLog
from app.schemas.log import AccessLogIn, AccessLogBatchIn, AccessLogOut, LogStats
from app.detection.engine import detection_engine

router = APIRouter(prefix="/logs", tags=["Logs & Ingestion"])

@router.post("", response_model=AccessLogOut, status_code=status.HTTP_201_CREATED)
def ingest_log(log_in: AccessLogIn, db: Session = Depends(get_db)):
    """
    Ingère un événement de connexion unique.
    Stocke les métadonnées réseau, temporelles et d'authentification,
    puis exécute le moteur de détection d'intrusions (règles + IA).
    """
    db_log = AccessLog(
        timestamp=log_in.timestamp or datetime.utcnow(),
        user_identifier=log_in.user_identifier,
        ip_address=log_in.ip_address,
        country_code=log_in.country_code,
        city=log_in.city,
        latitude=log_in.latitude,
        longitude=log_in.longitude,
        user_agent=log_in.user_agent,
        http_method=log_in.http_method,
        endpoint=log_in.endpoint,
        organization=log_in.organization or "SentinelWatch SOC",
        http_status=log_in.http_status,
        response_time_ms=log_in.response_time_ms,
        is_flagged=False
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)

    # Analyse de sécurité en temps réel
    detection_engine.analyze_log(db, db_log)
    db.refresh(db_log)

    return db_log

@router.post("/batch", response_model=dict, status_code=status.HTTP_201_CREATED)
def ingest_logs_batch(batch_in: AccessLogBatchIn, db: Session = Depends(get_db)):
    """
    Ingère une liste d'événements de connexion en lot pour haute performance.
    """
    db_logs = [
        AccessLog(
            timestamp=item.timestamp or datetime.utcnow(),
            user_identifier=item.user_identifier,
            organization=item.organization or "SentinelWatch SOC",
            ip_address=item.ip_address,
            country_code=item.country_code,
            city=item.city,
            latitude=item.latitude,
            longitude=item.longitude,
            user_agent=item.user_agent,
            http_method=item.http_method,
            endpoint=item.endpoint,
            http_status=item.http_status,
            response_time_ms=item.response_time_ms,
            is_flagged=False
        )
        for item in batch_in.logs
    ]
    db.add_all(db_logs)
    db.commit()

    # Analyse de chaque log
    for db_log in db_logs:
        db.refresh(db_log)
        detection_engine.analyze_log(db, db_log)

    return {"message": f"{len(db_logs)} logs ingérés et analysés avec succès", "count": len(db_logs)}

@router.get("", response_model=List[AccessLogOut])
def get_logs(
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user_identifier: Optional[str] = None,
    ip_address: Optional[str] = None,
    http_status: Optional[int] = None,
    is_flagged: Optional[bool] = None,
    organization: Optional[str] = None
):
    """
    Récupère la liste paginée des logs d'accès avec filtres optionnels.
    """
    query = db.query(AccessLog)

    if organization:
        query = query.filter(AccessLog.organization == organization)
    if user_identifier:
        query = query.filter(AccessLog.user_identifier == user_identifier)
    if ip_address:
        query = query.filter(AccessLog.ip_address == ip_address)
    if http_status:
        query = query.filter(AccessLog.http_status == http_status)
    if is_flagged is not None:
        query = query.filter(AccessLog.is_flagged == is_flagged)

    return query.order_by(desc(AccessLog.timestamp)).offset(offset).limit(limit).all()

@router.get("/stats", response_model=LogStats)
def get_log_stats(organization: Optional[str] = None, db: Session = Depends(get_db)):
    """
    Fournit un résumé statistique utile pour le dashboard de supervision (SOC).
    """
    base_query = db.query(AccessLog)
    if organization:
        base_query = base_query.filter(AccessLog.organization == organization)

    total = base_query.count()
    failed = base_query.filter(AccessLog.http_status.in_([401, 403])).count()
    unique_ips = db.query(func.count(func.distinct(AccessLog.ip_address)))
    if organization:
        unique_ips = unique_ips.filter(AccessLog.organization == organization)
    unique_ips = unique_ips.scalar() or 0

    flagged = base_query.filter(AccessLog.is_flagged == True).count()
    
    # Activité des 15 dernières minutes
    recent_threshold = datetime.utcnow() - timedelta(minutes=15)
    recent = base_query.filter(AccessLog.timestamp >= recent_threshold).count()

    return LogStats(
        total_logs=total,
        total_failed_logins=failed,
        unique_ips=unique_ips,
        flagged_logs=flagged,
        recent_activity_count=recent
    )
