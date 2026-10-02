from app.api.logs import router as logs_router
from app.api.alerts import router as alerts_router
from app.api.audits import router as audits_router

__all__ = ["logs_router", "alerts_router", "audits_router"]
