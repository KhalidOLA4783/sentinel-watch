from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.database import engine, Base
from app.api.logs import router as logs_router
from app.api.alerts import router as alerts_router

from app.models.user import User
from app.api.auth import router as auth_router, seed_default_admin

from sqlalchemy import text

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Démarrage : Création automatique des tables dans la base SQLite / Postgres
    Base.metadata.create_all(bind=engine)
    
    # Migration automatique transparente pour ajouter la colonne organization si les tables existent déjà
    with engine.connect() as conn:
        for tbl in ["users", "audit_reports", "alerts", "access_logs"]:
            try:
                conn.execute(text(f"ALTER TABLE {tbl} ADD COLUMN organization VARCHAR(100) DEFAULT 'SentinelWatch SOC'"))
                conn.commit()
            except Exception:
                pass

    seed_default_admin()
    yield
    # Arrêt si nécessaire

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Tour de contrôle de sécurité SentinelWatch : Ingestion de logs, détection d'intrusions & alertes.",
    lifespan=lifespan
)

# Configuration CORS pour autoriser le dashboard React et l'app mobile Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Enregistrement des routes
app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
app.include_router(logs_router, prefix=settings.API_V1_PREFIX)
app.include_router(alerts_router, prefix=settings.API_V1_PREFIX)
from app.api.audits import router as audits_router
app.include_router(audits_router, prefix=settings.API_V1_PREFIX)

import os
from fastapi.responses import HTMLResponse

@app.get("/dashboard", response_class=HTMLResponse, tags=["Dashboard"])
def get_dashboard():
    """Interface Web de supervision SOC en temps réel."""
    html_path = os.path.join(os.path.dirname(__file__), "app", "static", "dashboard.html")
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse(content="<h3>Fichier dashboard.html non trouvé</h3>", status_code=404)

@app.get("/", tags=["Health"])
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "online",
        "dashboard_url": "/dashboard",
        "docs_url": "/docs"
    }

@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
