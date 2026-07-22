from app.core.database import BaseOps  # ✅ Import correct base

# Import all models
from app.models.user import User
from app.models.report import Report
from app.models.attachment import Attachment
from app.models.report_message import ReportMessage

# Export for convenience
__all__ = ['BaseOps', 'User', 'Report', 'Attachment', 'ReportMessage']