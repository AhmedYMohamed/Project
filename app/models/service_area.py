from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Integer, Unicode
from sqlalchemy.orm import relationship

from app.core.database import BaseOps 

class OfficerServiceArea(BaseOps):
    __tablename__ = "OfficerServiceArea"
    __table_args__ = {'schema': 'dbo'}

    # Primary Key
    id = Column("id", Integer, primary_key=True, index=True, autoincrement=True)
    
    # Foreign Key
    userId = Column(
        "userId",
        String(450), 
        ForeignKey("dbo.User.userId", ondelete="CASCADE"),
        nullable=False
    )
    
    # Coordinates & Location
    latitude = Column("latitude", Float, nullable=False)
    longitude = Column("longitude", Float, nullable=False)
    cityName = Column("cityName", Unicode(255), nullable=False)
    
    # Time window for this service area assignment
    startDate = Column("startDate", DateTime, nullable=False)
    endDate = Column("endDate", DateTime, nullable=True)

    # Relationships
    user = relationship("User", backref="service_areas")

    def __repr__(self):
        return f"<OfficerServiceArea(id={self.id}, userId={self.userId}, location={self.cityName})>"
