import json
from typing import List, Dict, Any, Optional
from fastapi import WebSocket, WebSocketDisconnect

class ConnectionManager:
    """
    Gestionnaire centralisé des sessions WebSocket pour SentinelWatch.
    Permet la diffusion en temps réel (broadcast) d'alertes, logs et métriques du SOC.
    """
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, event_type: str, data: Dict[str, Any]):
        """
        Envoie un événement typé à tous les clients connectés (Dashboard Web, Mobile).
        Format: {"event": event_type, "data": data}
        """
        message = json.dumps({"event": event_type, "data": data}, default=str)
        stale_connections = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                stale_connections.append(connection)

        for stale in stale_connections:
            self.disconnect(stale)

ws_manager = ConnectionManager()
