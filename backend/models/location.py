import datetime

from sqlalchemy import Column, Date, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Location(Base):
    __tablename__ = "location"

    id = Column(Integer, primary_key=True, autoincrement=True)
    sim_de_la_canne = Column(String(50), ForeignKey("canne.sim_de_la_canne"), nullable=False)
    cin_utilisateur = Column(String(50), ForeignKey("utilisateur.cin"), nullable=False)
    date_de_location = Column(Date, default=datetime.date.today)
    date_de_retour = Column(Date, nullable=True)

    canne = relationship("Canne", back_populates="locations")
    utilisateur = relationship("Utilisateur", back_populates="locations")
