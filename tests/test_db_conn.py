import os
import sys
# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set env var
os.environ["AZURE_KEY_VAULT_NAME"] = "moi-reporting-kv"

from app.core.database import test_database_connections

try:
    test_database_connections()
    print("✓ SQL Database connections are fully functional!")
except Exception as e:
    print(f"✗ Database connection failed: {e}")
