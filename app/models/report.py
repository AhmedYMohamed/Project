from sqlalchemy import Column, String, Float, DateTime, Text, ForeignKey, func, CheckConstraint, Unicode, UnicodeText, Boolean
from sqlalchemy.orm import relationship

from app.core.database import BaseOps  

class Report(BaseOps):
    __tablename__ = "Report"
    __table_args__ = {'schema': 'dbo'}

    # Primary Key
    reportId = Column("reportId", String(450), primary_key=True, index=True)
    
    # Foreign Key
    userId = Column(
        "userId",
        String(450), 
        ForeignKey("dbo.User.userId", ondelete="SET NULL"),
        nullable=True
    )
    
    # Core Data Columns
    title = Column("title", Unicode(500), nullable=False)
    descriptionText = Column("descriptionText", UnicodeText, nullable=False)
    locationRaw = Column("locationRaw", Unicode(2048), nullable=True)
    latitude = Column("latitude", Float, nullable=True)
    longitude = Column("longitude", Float, nullable=True)
    
    status = Column("status", String(50), nullable=False, default="Submitted")
    categoryId = Column("categoryId", String(100), nullable=False)

    # Metadata & AI
    aiConfidence = Column(
        "aiConfidence",
        Float,
        CheckConstraint('aiConfidence >= 0 AND aiConfidence <= 1'),
        nullable=True
    )
    transcribedVoiceText = Column("transcribedVoiceText", UnicodeText, nullable=True)
    officerNote = Column("officerNote", UnicodeText, nullable=True)

    # Lawyer Review & Signature Fields
    lawyerId = Column(
        "lawyerId",
        String(450),
        ForeignKey("dbo.User.userId", ondelete="SET NULL"),
        nullable=True
    )
    lawyerSignature = Column("lawyerSignature", UnicodeText, nullable=True)
    lawyerFeedback = Column("lawyerFeedback", UnicodeText, nullable=True)
    isUrgentEscalation = Column("isUrgentEscalation", Boolean, nullable=False, default=False)

    # Timestamps
    createdAt = Column(
        "createdAt",
        DateTime,
        nullable=False,
        server_default=func.getutcdate()
    )
    updatedAt = Column(
        "updatedAt",
        DateTime,
        nullable=False,
        server_default=func.getutcdate(),
        onupdate=func.getutcdate()
    )
    
    # Relationships
    user = relationship("User", foreign_keys=[userId], back_populates="reports")
    lawyer = relationship("User", foreign_keys=[lawyerId])
    attachments = relationship(
        "Attachment",
        back_populates="report",
        cascade="all, delete-orphan"
    )
    messages = relationship(
        "ReportMessage",
        back_populates="report",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<Report(reportId={self.reportId}, title={self.title})>"