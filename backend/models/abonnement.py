import datetime

from sqlalchemy import Column, Date, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from backend.database import Base


class Abonnement(Base):
    __tablename__ = "abonnement"

    id = Column(Integer, primary_key=True, autoincrement=True)
    sim_de_la_canne = Column(String(50), ForeignKey("canne.sim_de_la_canne"), nullable=False)
    cin_utilisateur = Column(String(50), ForeignKey("utilisateur.cin"), nullable=False)
    type_d_abonnement = Column(String(100))
    date_de_debut = Column(Date, default=datetime.date.today)
    date_de_fin = Column(Date, nullable=True)

    canne = relationship("Canne", back_populates="abonnements")
    utilisateur = relationship("Utilisateur", back_populates="abonnements")
