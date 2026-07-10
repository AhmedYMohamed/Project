import os
import sys
# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import get_settings
from app.services.blob_service import BlobStorageService

def test_azure_integration():
    print("==================================================")
    print("Testing Azure Integration Settings and Fallbacks")
    print("==================================================")
    
    # 1. Test Config Loader
    try:
        settings = get_settings()
        print("✓ Settings loaded successfully")
        print(f"  APP_NAME: {settings.APP_NAME}")
        print(f"  ENVIRONMENT: {settings.ENVIRONMENT}")
        print(f"  DEBUG: {settings.DEBUG}")
        print(f"  AZURE_KEY_VAULT_NAME: {settings.AZURE_KEY_VAULT_NAME or 'Not Configured (Using env defaults)'}")
        print(f"  AZURE_CLIENT_ID: {settings.AZURE_CLIENT_ID or 'Not Configured'}")
        print(f"  SQLALCHEMY_DATABASE_URI_OPS: {'Configured' if settings.SQLALCHEMY_DATABASE_URI_OPS else 'Missing'}")
        print(f"  SQLALCHEMY_DATABASE_URI_ANALYTICS: {'Configured' if settings.SQLALCHEMY_DATABASE_URI_ANALYTICS else 'Missing'}")
        print(f"  BLOB_STORAGE_CONNECTION_STRING: {'Configured' if settings.BLOB_STORAGE_CONNECTION_STRING else 'Missing'}")
    except Exception as e:
        print(f"✗ Failed to load settings: {e}")
        return

    # 2. Test Blob Storage Fallback/Azure Mode
    try:
        storage = BlobStorageService()
        print("\n✓ BlobStorageService initialized successfully")
        print(f"  Use Azure storage mode: {storage.use_azure}")
        if not storage.use_azure:
            print(f"  Storage Path: {storage.storage_path}")
        else:
            print(f"  Container Name: {storage.container_name}")
    except Exception as e:
        print(f"✗ Failed to initialize BlobStorageService: {e}")
        return

    print("==================================================")
    print("Test Completed Successfully!")
    print("==================================================")

if __name__ == "__main__":
    test_azure_integration()
