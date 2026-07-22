from sqlalchemy import Column, String, DateTime, func, ForeignKey, UnicodeText
from sqlalchemy.orm import relationship

from app.core.database import BaseOps

class ReportMessage(BaseOps):
    __tablename__ = "ReportMessage"
    __table_args__ = {'schema': 'dbo'}

    messageId = Column("messageId", String(450), primary_key=True, index=True)
    reportId = Column(
        "reportId",
        String(450),
        ForeignKey("dbo.Report.reportId", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    senderId = Column(
        "senderId",
        String(450),
        ForeignKey("dbo.User.userId", ondelete="CASCADE"),
        nullable=False
    )
    senderRole = Column("senderRole", String(50), nullable=False)
    messageText = Column("messageText", UnicodeText, nullable=False)
    createdAt = Column("createdAt", DateTime, nullable=False, server_default=func.getutcdate())

    # Relationships
    report = relationship("Report", back_populates="messages")
    sender = relationship("User", foreign_keys=[senderId])

    def __repr__(self):
        return f"<ReportMessage(messageId={self.messageId}, reportId={self.reportId}, senderRole={self.senderRole})>"
