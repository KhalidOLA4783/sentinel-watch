import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "SentinelWatch API"
    VERSION: str = "0.1.0"
    API_V1_PREFIX: str = "/api/v1"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sentinelwatch.db")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"

    class Config:
        case_sensitive = True

settings = Settings()
