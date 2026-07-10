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
        
    BLOB_STORAGE_CONNECTION_STRING: Optional[str] = None
    BLOB_CONTAINER_NAME: str = "report-attachments"
    
    # Azure Configuration (Key Vault Access)
    AZURE_KEY_VAULT_NAME: Optional[str] = None
    AZURE_CLIENT_ID: Optional[str] = None
    
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
    ALLOWED_ORIGINS: list = ["*",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "https://special-trout-q7v4g6676g5vc6794-8080.app.github.dev",
        "https://cautious-garbanzo-69v57ww9wxr43574r-8080.app.github.dev/",
        "https://cautious-garbanzo-69v57ww9wxr43574r-8080.app.github.dev"
    ]
    RATE_LIMIT_PER_MINUTE: int = 60

    class Config:
        case_sensitive = True
        env_file = ".env" if os.getenv("ENVIRONMENT", "development") == "development" else None


@lru_cache()
def get_settings() -> Settings:
    settings = Settings()
    
    # Resolve all secrets from Azure Key Vault if configured
    if settings.AZURE_KEY_VAULT_NAME:
        logger.info(f"Connecting to Azure Key Vault: {settings.AZURE_KEY_VAULT_NAME}")
        try:
            from azure.identity import DefaultAzureCredential
            from azure.keyvault.secrets import SecretClient
            
            # Setup credential with user-assigned identity Client ID if provided
            if settings.AZURE_CLIENT_ID:
                credential = DefaultAzureCredential(managed_identity_client_id=settings.AZURE_CLIENT_ID)
            else:
                credential = DefaultAzureCredential()
                
            vault_url = f"https://{settings.AZURE_KEY_VAULT_NAME}.vault.azure.net"
            kv_client = SecretClient(vault_url=vault_url, credential=credential)
            
            # Key Vault Secret mapping: (Secret name in Key Vault, Setting name in Settings)
            secret_mapping = {
                "sql-hot-connection-string": "SQLALCHEMY_DATABASE_URI_OPS",
                "sql-cold-connection-string": "SQLALCHEMY_DATABASE_URI_ANALYTICS",
                "blob-storage-connection-string": "BLOB_STORAGE_CONNECTION_STRING",
                "azure-service-bus-connection-string": "AZURE_SERVICE_BUS_CONNECTION_STRING",
                "azure-speech-key": "AZURE_SPEECH_KEY",
                "azure-ml-api-key": "AZURE_ML_API_KEY",
                "secret-key": "SECRET_KEY"
            }
            
            for secret_name, setting_name in secret_mapping.items():
                try:
                    secret_val = kv_client.get_secret(secret_name).value
                    if secret_val:
                        setattr(settings, setting_name, secret_val)
                        logger.info(f"✓ Resolved {setting_name} from Key Vault")
                except Exception as e:
                    # Log warning but do not crash on non-mandatory parameters
                    logger.warning(f"⚠ Could not resolve secret '{secret_name}' from Key Vault: {e}")
                    
        except Exception as e:
            logger.error(f"✗ Failed to load secrets from Key Vault: {e}")
            
    # Ensure local directory exists
    os.makedirs(settings.LOCAL_STORAGE_PATH, exist_ok=True)
            
    return settings

# Instantiate settings so other modules can import it
settings = get_settings()
