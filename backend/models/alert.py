import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, String

from backend.database import Base


class Alert(Base):
    __tablename__ = "alert"

    alert_id = Column(String(50), primary_key=True, index=True)
    user_id = Column(String(50), ForeignKey("utilisateur.cin"), nullable=False)
    type = Column(String(20), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String(20), default="active")
    resolved_by = Column(String(100))
    resolved_at = Column(DateTime)
    taken_by = Column(String(100))
