import os
import uuid
import logging
from datetime import datetime, timezone
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)

class BlobStorageService:
    """Local Storage operations for report attachments (Replaces Azure Blob)"""
    
    def __init__(self):
        self.storage_path = settings.ABSOLUTE_STORAGE_PATH
        # Ensure container exists
        os.makedirs(self.storage_path, exist_ok=True)
    
    def upload_file(
        self, 
        file_content: bytes, 
        filename: str,
        content_type: str,
        subfolder: Optional[str] = None
    ) -> Optional[str]:
        """Save file locally and return the relative serving URL"""
        try:
            # Determine storage directory
            upload_dir = self.storage_path
            if subfolder:
                upload_dir = os.path.join(self.storage_path, subfolder)
                os.makedirs(upload_dir, exist_ok=True)
            
            file_extension = filename.split('.')[-1] if '.' in filename else 'bin'
            blob_name = f"{uuid.uuid4()}.{file_extension}"
            file_path = os.path.join(upload_dir, blob_name)
            
            with open(file_path, "wb") as f:
                f.write(file_content)
            
            logger.info(f"✓ Saved file locally: {blob_name} in {subfolder or 'root'} ({len(file_content)} bytes)")
            
            # Return a relative URL path that FastAPI can serve
            prefix = f"{subfolder}/" if subfolder else ""
            return f"/local_storage/{prefix}{blob_name}"
        
        except Exception as e:
            logger.error(f"Error saving file '{filename}': {e}")
            return None
    
    def delete_file(self, blob_url: str) -> bool:
        """Delete local file"""
        try:
            # Extract relative path from URL (remove /local_storage/ prefix)
            relative_path = blob_url.replace("/local_storage/", "").split('?')[0]
            file_path = os.path.join(self.storage_path, relative_path)
            
            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"✓ Deleted local file: {relative_path}")
                
                # Try to remove empty parent directory if it was a subfolder
                parent_dir = os.path.dirname(file_path)
                if parent_dir != self.storage_path and not os.listdir(parent_dir):
                    os.rmdir(parent_dir)
                    logger.info(f"✓ Removed empty directory: {parent_dir}")
                
                return True
            else:
                logger.warning(f"File not found for deletion: {file_path}")
                return False
                
        except Exception as e:
            logger.error(f"Unexpected error deleting file: {e}")
            return False
    
    def generate_download_url(
        self, 
        blob_url: str,
        expiry_hours: int = 1
    ) -> Optional[str]:
        """Local files don't need SAS tokens. Just return the URL."""
        return blob_url
    
    def get_file_metadata(self, blob_url: str) -> Optional[dict]:
        """Get file metadata from local filesystem"""
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
            logger.error(f"Unexpected error getting metadata: {e}")
            return None
            
    def list_blobs(self, prefix: Optional[str] = None) -> list:
        """List local files in the storage directory"""
        try:
            files = os.listdir(self.storage_path)
            if prefix:
                files = [f for f in files if f.startswith(prefix)]
            return files
        except Exception as e:
            logger.error(f"Error listing files: {e}")
            return []

    def get_blob_url(self, blob_name: str) -> str:
        """Return relative serving URL for the blob"""
        return f"/local_storage/{blob_name}"