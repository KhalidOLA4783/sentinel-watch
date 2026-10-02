from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from app.database import Base

class User(Base):
    """
    Modèle utilisateur pour l'accès sécurisé à la console SOC et l'application mobile.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(128), nullable=False)
    full_name = Column(String(100), nullable=True)
    role = Column(String(20), default="ADMIN", nullable=False)  # ADMIN, ANALYST, OPERATOR
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
