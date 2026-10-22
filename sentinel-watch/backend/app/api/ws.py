from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from app.core.websocket import ws_manager
from app.api.deps import decode_access_token

router = APIRouter(tags=["WebSocket Realtime Stream"])

@router.websocket("/ws/live")
async def websocket_live_stream(
    websocket: WebSocket,
    token: Optional[str] = Query(None)
):
    """
    Flux WebSocket bidirectionnel pour la tour de contrôle SentinelWatch.
    Transmet en direct (< 50ms) les logs, alertes levées et remédiations (bannissements d'IP).
    """
    # Validation optionnelle du token JWT si fourni
    if token:
        try:
            decode_access_token(token)
        except Exception:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    await ws_manager.connect(websocket)
    try:
        # Message de bienvenue confirmant la liaison SOC active
        await websocket.send_json({
            "event": "CONNECTED",
            "data": {"status": "online", "message": "SentinelWatch SOC Live Feed établi"}
        })
        while True:
            # Réception de messages ou heartbeat du client
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception:
        ws_manager.disconnect(websocket)
