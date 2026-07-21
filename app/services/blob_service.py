import os
import uuid
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)

# Try to import Azure libraries
try:
    from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions
    from azure.core.exceptions import AzureError
    AZURE_STORAGE_AVAILABLE = True
except ImportError:
    AZURE_STORAGE_AVAILABLE = False

class BlobStorageService:
    """Hybrid Blob Storage operations (Azure Blob or Local Storage fallback)"""
    
    def __init__(self):
        self.use_azure = False
        if settings.BLOB_STORAGE_CONNECTION_STRING and settings.BLOB_CONTAINER_NAME:
            if AZURE_STORAGE_AVAILABLE:
                try:
                    self.blob_service_client = BlobServiceClient.from_connection_string(
                        settings.BLOB_STORAGE_CONNECTION_STRING
                    )
                    self.container_name = settings.BLOB_CONTAINER_NAME
                    
                    # Ensure container exists on startup/init
                    container_client = self.blob_service_client.get_container_client(self.container_name)
                    if not container_client.exists():
                        container_client.create_container()
                        logger.info(f"✓ Created Azure Blob Storage container: {self.container_name}")
                    
                    self.use_azure = True
                    logger.info("✓ Azure Blob Storage initialized successfully")
                except Exception as e:
                    logger.warning(f"⚠ Failed to initialize Azure Blob Storage client: {e}. Falling back to local storage.")
            else:
                logger.warning("⚠ BLOB_STORAGE_CONNECTION_STRING is set but azure-storage-blob is not installed. Falling back to local storage.")
        
        if not self.use_azure:
            self.storage_path = settings.ABSOLUTE_STORAGE_PATH
            os.makedirs(self.storage_path, exist_ok=True)
            logger.info("✓ Local Storage initialized")

    def upload_file(
        self, 
        file_content: bytes, 
        filename: str,
        content_type: str,
        subfolder: Optional[str] = None
    ) -> Optional[str]:
        """Upload file to Azure Blob Storage or local storage"""
        if self.use_azure:
            try:
                # Generate unique blob name
                file_extension = filename.split('.')[-1] if '.' in filename else 'bin'
                blob_name = f"{uuid.uuid4()}.{file_extension}"
                if subfolder:
                    blob_name = f"{subfolder}/{blob_name}"
                
                blob_client = self.blob_service_client.get_blob_client(
                    container=self.container_name,
                    blob=blob_name
                )
                
                blob_client.upload_blob(
                    file_content,
                    content_type=content_type,
                    overwrite=True
                )
                
                logger.info(f"✓ Uploaded file to Azure Blob: {blob_name}")
                return blob_client.url
            except Exception as e:
                logger.error(f"Error uploading file to Azure: {e}")
                return None
        else:
            # Fallback to local storage
            try:
                upload_dir = self.storage_path
                if subfolder:
                    upload_dir = os.path.join(self.storage_path, subfolder)
                    os.makedirs(upload_dir, exist_ok=True)
                
                file_extension = filename.split('.')[-1] if '.' in filename else 'bin'
                blob_name = f"{uuid.uuid4()}.{file_extension}"
                file_path = os.path.join(upload_dir, blob_name)
                
                with open(file_path, "wb") as f:
                    f.write(file_content)
                
                logger.info(f"✓ Saved file locally: {blob_name} in {subfolder or 'root'}")
                prefix = f"{subfolder}/" if subfolder else ""
                return f"/local_storage/{prefix}{blob_name}"
            except Exception as e:
                logger.error(f"Error saving file locally '{filename}': {e}")
                return None

    def delete_file(self, blob_url: str) -> bool:
        """Delete file from Azure Blob Storage or local storage"""
        if self.use_azure:
            try:
                # Parse blob name from URL
                container_prefix = f"/{self.container_name}/"
                if container_prefix in blob_url:
                    blob_name = blob_url.split(container_prefix, 1)[1].split('?')[0]
                else:
                    # Fallback to simple split
                    blob_name = blob_url.split('/')[-1].split('?')[0]
                
                blob_client = self.blob_service_client.get_blob_client(
                    container=self.container_name,
                    blob=blob_name
                )
                blob_client.delete_blob()
                logger.info(f"✓ Deleted Azure Blob: {blob_name}")
                return True
            except Exception as e:
                logger.error(f"Error deleting Azure Blob: {e}")
                return False
        else:
            # Local delete
            try:
                relative_path = blob_url.replace("/local_storage/", "").split('?')[0]
                file_path = os.path.join(self.storage_path, relative_path)
                
                if os.path.exists(file_path):
                    os.remove(file_path)
                    logger.info(f"✓ Deleted local file: {relative_path}")
                    
                    parent_dir = os.path.dirname(file_path)
                    if parent_dir != self.storage_path and not os.listdir(parent_dir):
                        os.rmdir(parent_dir)
                        logger.info(f"✓ Removed empty directory: {parent_dir}")
                    return True
                else:
                    logger.warning(f"File not found for deletion: {file_path}")
                    return False
            except Exception as e:
                logger.error(f"Unexpected error deleting local file: {e}")
                return False

    def _get_account_key(self) -> Optional[str]:
        """Retrieve account key from credential object or parse from connection string"""
        if hasattr(self, 'blob_service_client') and self.blob_service_client.credential:
            key = getattr(self.blob_service_client.credential, 'account_key', None)
            if key:
                return key
        
        conn_str = settings.BLOB_STORAGE_CONNECTION_STRING
        if conn_str:
            for part in conn_str.split(';'):
                if part.strip().startswith('AccountKey='):
                    return part.strip().split('AccountKey=', 1)[1]
        return None

    def generate_download_url(
        self, 
        blob_url: str,
        expiry_hours: int = 1
    ) -> Optional[str]:
        """Generate download URL with SAS token for Azure, or direct URL for local"""
        if self.use_azure:
            try:
                container_prefix = f"/{self.container_name}/"
                if container_prefix in blob_url:
                    blob_name = blob_url.split(container_prefix, 1)[1].split('?')[0]
                else:
                    blob_name = blob_url.split('/')[-1].split('?')[0]
                
                account_key = self._get_account_key()
                user_delegation_key = None
                if not account_key and hasattr(self.blob_service_client, 'get_user_delegation_key'):
                    user_delegation_key = self.blob_service_client.get_user_delegation_key(
                        key_start_time=datetime.now(timezone.utc),
                        key_expiry_time=datetime.now(timezone.utc) + timedelta(hours=expiry_hours)
                    )

                sas_token = generate_blob_sas(
                    account_name=self.blob_service_client.account_name,
                    container_name=self.container_name,
                    blob_name=blob_name,
                    account_key=account_key,
                    user_delegation_key=user_delegation_key,
                    permission=BlobSasPermissions(read=True),
                    expiry=datetime.now(timezone.utc) + timedelta(hours=expiry_hours)
                )
                return f"{blob_url}?{sas_token}"
            except Exception as e:
                logger.error(f"Error generating Azure SAS token: {e}")
                return None
        else:
            return blob_url

    def get_file_metadata(self, blob_url: str) -> Optional[dict]:
        """Get file metadata from Azure or local filesystem"""
        if self.use_azure:
            try:
                container_prefix = f"/{self.container_name}/"
                if container_prefix in blob_url:
                    blob_name = blob_url.split(container_prefix, 1)[1].split('?')[0]
                else:
                    blob_name = blob_url.split('/')[-1].split('?')[0]
                
                blob_client = self.blob_service_client.get_blob_client(
                    container=self.container_name,
                    blob=blob_name
                )
                properties = blob_client.get_blob_properties()
                return {
                    'size': properties.size,
                    'created_on': properties.creation_time.isoformat() if properties.creation_time else None,
                    'last_modified': properties.last_modified.isoformat() if properties.last_modified else None,
                    'content_type': properties.content_settings.content_type
                }
            except Exception as e:
                logger.error(f"Error getting Azure blob metadata: {e}")
                return None
        else:
            try:
                blob_name = blob_url.split('/')[-1].split('?')[0]
                file_path = os.path.join(self.storage_path, blob_name)
                
                if os.path.exists(file_path):
                    stat = os.stat(file_path)
                    return {
                        'size': stat.st_size,
                        'created_on': datetime.fromtimestamp(stat.st_ctime, tz=timezone.utc).isoformat(),
                        'last_modified': datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
                    }
                return None
            except Exception as e:
                logger.error(f"Unexpected error getting local metadata: {e}")
                return None

    def list_blobs(self, prefix: Optional[str] = None) -> list:
        """List files in Azure storage container or local storage directory"""
        if self.use_azure:
            try:
                container_client = self.blob_service_client.get_container_client(self.container_name)
                blobs = container_client.list_blobs(name_starts_with=prefix)
                return [b.name for b in blobs]
            except Exception as e:
                logger.error(f"Error listing Azure blobs: {e}")
                return []
        else:
            try:
                files = os.listdir(self.storage_path)
                if prefix:
                    files = [f for f in files if f.startswith(prefix)]
                return files
            except Exception as e:
                logger.error(f"Error listing local files: {e}")
                return []

    def get_blob_url(self, blob_name: str) -> str:
        """Return URL/serving URL for the blob"""
        if self.use_azure:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            return blob_client.url
        else:
            return f"/local_storage/{blob_name}"