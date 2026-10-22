import os
import httpx
import logging
import asyncio
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session

from app.models.alert import Alert, BlacklistedIP
from app.core.websocket import ws_manager

logger = logging.getLogger("sentinel.soar")

WEBHOOK_URL = os.getenv("SOAR_WEBHOOK_URL", "")  # URL Discord, Slack ou Webhook générique

async def send_webhook_notification(title: str, message: str, severity: str = "CRITICAL"):
    """Envoie une alerte de sécurité vers Slack, Discord ou un webhook de garde SOC."""
    if not WEBHOOK_URL:
        return
    payload = {
        "text": f"🛡️ *[SentinelWatch SOAR]* : {title}\n> {message}\n> *Niveau* : `{severity}`",
        "username": "SentinelWatch SOAR Bot"
    }
    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            await client.post(WEBHOOK_URL, json=payload)
    except Exception as e:
        logger.warning(f"Échec de notification Webhook SOAR: {e}")

class PlaybookEngine:
    """
    Moteur SOAR (Security Orchestration, Automation and Response) de SentinelWatch.
    Exécute automatiquement des remédiations (bannissement avec TTL, notification externe)
    face à des cyberattaques avérées.
    """

    @staticmethod
    def execute_playbooks(db: Session, alert: Alert) -> Optional[BlacklistedIP]:
        """
        Évalue l'incident et déclenche automatiquement le bannissement si critique.
        """
        # Playbook 1 : Auto-bannissement immédiat pour Force Brute ou Trafic d'IP bannie
        should_ban = False
        ban_duration = None  # None = définitif, ou timedelta
        reason = ""

        if alert.alert_type in ["BRUTE_FORCE", "SSH_BRUTE_FORCE"] and alert.severity in ["HIGH", "CRITICAL"]:
            should_ban = True
            ban_duration = timedelta(hours=2) # Ban temporaire de 2 heures
            reason = f"SOAR Auto-Ban (Force Brute détectée) sur IP {alert.source_ip}"

        elif alert.alert_type in ["RECON_SCAN", "PORT_SCAN"] and alert.severity in ["HIGH", "CRITICAL"]:
            should_ban = True
            ban_duration = timedelta(hours=24) # Ban de 24h pour reconnaissance
            reason = f"SOAR Auto-Ban (Scan de vulnérabilités agressif) sur IP {alert.source_ip}"

        elif alert.severity == "CRITICAL" and (alert.anomaly_score or 0) >= 0.8:
            should_ban = True
            ban_duration = None # Ban permanent
            reason = f"SOAR Auto-Ban (Anomalie critique confirmée) sur IP {alert.source_ip}"

        if not should_ban:
            return None

        # Vérifier si l'IP est déjà bannie
        existing = db.query(BlacklistedIP).filter(BlacklistedIP.ip_address == alert.source_ip).first()
        now = datetime.utcnow()
        expires_at = (now + ban_duration) if ban_duration else None

        if existing:
            existing.is_active = True
            existing.reason = reason
            existing.blocked_at = now
            existing.expires_at = expires_at
            banned_entry = existing
        else:
            banned_entry = BlacklistedIP(
                ip_address=alert.source_ip,
                reason=reason,
                blocked_at=now,
                expires_at=expires_at,
                is_active=True
            )
            db.add(banned_entry)

        alert.status = "RESOLVED"
        db.commit()
        db.refresh(banned_entry)

        # Notification asynchrone Webhook + Broadcast WebSocket
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                asyncio.create_task(send_webhook_notification(
                    title=f"IP Bloquée Automatiquement : {alert.source_ip}",
                    message=reason,
                    severity=alert.severity
                ))
                asyncio.create_task(ws_manager.broadcast("SOAR_AUTO_BAN", {
                    "ip_address": banned_entry.ip_address,
                    "reason": banned_entry.reason,
                    "expires_at": banned_entry.expires_at.isoformat() if banned_entry.expires_at else None,
                    "alert_id": alert.id
                }))
        except Exception:
            pass

        return banned_entry

    @staticmethod
    def cleanup_expired_bans(db: Session) -> int:
        """
        Lève automatiquement les restrictions d'adresses IP dont le TTL a expiré.
        """
        now = datetime.utcnow()
        expired = db.query(BlacklistedIP).filter(
            BlacklistedIP.is_active == True,
            BlacklistedIP.expires_at.isnot(None),
            BlacklistedIP.expires_at <= now
        ).all()

        count = len(expired)
        for ip in expired:
            ip.is_active = False

        if count > 0:
            db.commit()
        return count

playbook_engine = PlaybookEngine()
