from sqlalchemy import Column, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Canne(Base):
    __tablename__ = "canne"

    sim_de_la_canne = Column(String(50), primary_key=True, index=True)
    version = Column(String(100))
    statut = Column(String(50), default="disponible")
    type = Column(String(50))

    locations = relationship("Location", back_populates="canne")
    abonnements = relationship("Abonnement", back_populates="canne")
