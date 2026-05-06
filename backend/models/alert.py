import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Alert(Base):
    __tablename__ = "alert"

    alert_id = Column(String(50), primary_key=True, index=True)
    user_id = Column(String(50), ForeignKey("utilisateur.cin"), nullable=True)
    type = Column(String(20), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(20), default="active")
    cane_status = Column(String(20), default="normal") # normal, moving, SOS active
    resolved_by = Column(String(100))
    resolved_at = Column(DateTime)
    taken_by = Column(String(100))
    response_time = Column(String(50))
    reactivated_by = Column(String(100))
    reactivated_at = Column(DateTime)

    utilisateur = relationship("Utilisateur", backref="alerts")
