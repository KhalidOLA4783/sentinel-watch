import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "SentinelWatch API"
    VERSION: str = "0.1.0"
    API_V1_PREFIX: str = "/api/v1"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sentinelwatch.db")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "sentinelwatch_super_secret_jwt_key_change_in_production_2026")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
    # Coordonnées du datacenter ou siège défendu par SentinelWatch (ex: Paris)
    DEFENDED_LAT: float = float(os.getenv("DEFENDED_LAT", "48.8566"))
    DEFENDED_LON: float = float(os.getenv("DEFENDED_LON", "2.3522"))
    DEFENDED_NAME: str = os.getenv("DEFENDED_NAME", "HQ DataCenter Paris")

    class Config:
        case_sensitive = True

settings = Settings()
