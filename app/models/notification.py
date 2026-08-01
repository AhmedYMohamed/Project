import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Notification(Base):
    __tablename__ = "Notification"
    __table_args__ = {"schema": "dbo"}

    notificationId = Column(String(450), primary_key=True, default=lambda: f"notif-{uuid.uuid4()}")
    userId = Column(String(450), ForeignKey("dbo.User.userId"), nullable=False)
    title = Column(String(500), nullable=False)
    body = Column(String(2000), nullable=False)
    type = Column(String(50), nullable=True)
    reportId = Column(String(450), nullable=True)
    isRead = Column(Boolean, default=False, nullable=False)
    createdAt = Column(DateTime, default=func.now(), nullable=False)
