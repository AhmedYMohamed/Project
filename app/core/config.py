from pydantic_settings import BaseSettings
from functools import lru_cache
import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    APP_NAME: str = "MoI Digital Reporting System"
    API_VERSION: str = "v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    
    # =========================================================
    # 🔐 Secrets (Loaded from .env or docker environment)
    # =========================================================
    
    # 1. Databases (Hot & Cold)
    SQLALCHEMY_DATABASE_URI_OPS: Optional[str] = None      
    SQLALCHEMY_DATABASE_URI_ANALYTICS: Optional[str] = None 
    
    # 2. Storage
    # Local path for storage instead of Blob connection string
    LOCAL_STORAGE_PATH: str = os.getenv("LOCAL_STORAGE_PATH", "./local_storage")
    
    @property
    def ABSOLUTE_STORAGE_PATH(self) -> str:
        if os.path.isabs(self.LOCAL_STORAGE_PATH):
            return self.LOCAL_STORAGE_PATH
        return os.path.abspath(self.LOCAL_STORAGE_PATH)
    
    # 3. Security
    SECRET_KEY: Optional[str] = None
    
    # 4. Hot Path Integration (Queue)
    AZURE_SERVICE_BUS_CONNECTION_STRING: Optional[str] = None
    
    # 5. AI Services
    AZURE_SPEECH_KEY: Optional[str] = None
    AZURE_SPEECH_REGION: str = "eastus"
    AZURE_ML_ENDPOINT: Optional[str] = None
    AZURE_ML_API_KEY: Optional[str] = None
    
    # =========================================================
    # ⚙️ Static Config
    # =========================================================
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALLOWED_ORIGINS: list = [
        "https://cuddly-dollop-97654ww7wvr6cg9q-8080.app.github.dev",
        "https://cuddly-dollop-97654ww7wvr6cg9q-8000.app.github.dev"
    ]
    RATE_LIMIT_PER_MINUTE: int = 60

    class Config:
        case_sensitive = True
        env_file = ".env" if os.getenv("ENVIRONMENT", "development") == "development" else None


@lru_cache()
def get_settings() -> Settings:
    settings = Settings()
    
    # Ensure local directory exists
    os.makedirs(settings.LOCAL_STORAGE_PATH, exist_ok=True)
            
    return settings

# Instantiate settings so other modules can import it
settings = get_settings()
