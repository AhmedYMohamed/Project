from sqlalchemy import Column, String, Boolean, DateTime, func, CheckConstraint, ForeignKey, Unicode
from sqlalchemy.orm import relationship, backref

from app.core.database import BaseOps 

class User(BaseOps):
    __tablename__ = "User"
    __table_args__ = (
        CheckConstraint(
            "(isAnonymous = 1) OR (email IS NOT NULL) OR (phoneNumber IS NOT NULL)",
            name="CK_User_ContactInfo"
        ),
        {'schema': 'dbo'}
    )

    # Primary Key
    userId = Column("userId", String(450), primary_key=True, index=True)
    
    # Attributes
    isAnonymous = Column("isAnonymous", Boolean, nullable=False, default=False)
    createdAt = Column("createdAt", DateTime, nullable=False, server_default=func.getutcdate())
    role = Column("role", String(50), nullable=False, default="citizen")
    
    email = Column("email", String(256), nullable=True)
    phoneNumber = Column("phoneNumber", String(20), nullable=True)
    hashedNationalId = Column("hashedNationalId", String(256), nullable=True, unique=True, index=True)
    hashedDeviceId = Column("hashedDeviceId", String(256), nullable=True)
    passwordHash = Column(String(256), nullable=True)

    # Lawyer Module Fields
    lawyerId = Column("lawyerId", String(450), ForeignKey("dbo.User.userId", ondelete="SET NULL"), nullable=True)
    syndicateId = Column("syndicateId", String(100), nullable=True, unique=True, index=True)
    digitalSignatureUrl = Column("digitalSignatureUrl", Unicode(2048), nullable=True)
    lawyerQrCode = Column("lawyerQrCode", String(256), nullable=True, unique=True, index=True)

    # Relationships
    reports = relationship("Report", foreign_keys="[Report.userId]", back_populates="user")
    citizens = relationship("User", foreign_keys=[lawyerId], backref=backref("lawyer", remote_side=[userId]))

    def __repr__(self):
        return f"<User(userId={self.userId}, role={self.role})>"