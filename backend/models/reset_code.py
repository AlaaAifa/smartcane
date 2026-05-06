import datetime
from sqlalchemy import Column, String, DateTime, Boolean
from backend.database import Base

class ResetCode(Base):
    __tablename__ = "reset_codes"

    email = Column(String(100), primary_key=True, index=True)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    is_used = Column(Boolean, default=False)

    def is_expired(self):
        return datetime.datetime.utcnow() > self.expires_at
