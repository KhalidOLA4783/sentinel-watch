from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import settings

# Normalisation de l'URL pour SQLAlchemy (Render fournit 'postgres://' au lieu de 'postgresql://')
db_url = settings.DATABASE_URL
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

# Configurations spécifiques selon le moteur (SQLite ou PostgreSQL)
connect_args = {}
if db_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    db_url,
    connect_args=connect_args,
    echo=False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """Dépendance FastAPI fournissant une session de base de données par requête."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
