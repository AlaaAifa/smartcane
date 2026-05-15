import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from backend.database import Base


class Utilisateur(Base):
    __tablename__ = "utilisateur"

    cin = Column(String(50), primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    age = Column(Integer)
    adresse = Column(String(255))
    email = Column(String(100), unique=True, index=True, nullable=False)
    numero_de_telephone = Column(String(50))
    role = Column(String(50), nullable=False)
    photo_url = Column(Text, nullable=True)
    cree_le = Column(DateTime, default=datetime.datetime.utcnow)

    locations = relationship("Location", back_populates="utilisateur")
    abonnements = relationship("Abonnement", back_populates="utilisateur")

    __mapper_args__ = {
        "polymorphic_on": role,
        "polymorphic_identity": "utilisateur",
    }


class Client(Utilisateur):
    __tablename__ = "client"

    cin = Column(String(50), ForeignKey("utilisateur.cin", ondelete="CASCADE"), primary_key=True)
    contact_familial = Column(String(50))
    etat_de_sante = Column(String(1000))
    sim_de_la_canne = Column(String(50))

    __mapper_args__ = {
        "polymorphic_identity": "client",
    }


class Staff(Utilisateur):
    __tablename__ = "staff"

    cin = Column(String(50), ForeignKey("utilisateur.cin", ondelete="CASCADE"), primary_key=True)
    password_login = Column(String(255))
    shift = Column(String(20), default="matin")  # matin ou soir

    __mapper_args__ = {
        "polymorphic_identity": "staff",
    }


class Admin(Staff):
    __mapper_args__ = {
        "polymorphic_identity": "admin",
    }
