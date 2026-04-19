from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import date, datetime

# --- Modèles adaptés pour la structure MySQL ---

class Utilisateur(BaseModel):
    cin: str
    nom: str
    age: Optional[int] = None
    adresse: Optional[str] = None
    email: EmailStr
    numero_de_telephone: Optional[str] = None
    contact_familial: Optional[str] = None
    etat_de_sante: Optional[str] = None
    sim_de_la_canne: Optional[str] = None
    cree_le: Optional[datetime] = None
    mis_a_jour_le: Optional[datetime] = None
    
    # Informations sur la canne (jointure)
    cane_version: Optional[str] = None
    cane_statut: Optional[str] = None
    cane_type: Optional[str] = None

class Canne(BaseModel):
    sim_de_la_canne: str
    version: Optional[str] = None
    statut: str = "disponible"  # disponible, louee, vendue
    type: Optional[str] = None  # location, abonnement
    
    # Informations sur l'utilisateur (jointure)
    utilisateur_nom: Optional[str] = None
    utilisateur_cin: Optional[str] = None

class Location(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    date_de_location: date
    date_de_retour: Optional[date] = None
    
    # Informations additionnelles (jointures)
    utilisateur_nom: Optional[str] = None
    canne_version: Optional[str] = None

class Abonnement(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    type_d_abonnement: Optional[str] = None
    date_de_debut: date
    date_de_fin: Optional[date] = None
    
    # Informations additionnelles (jointures)
    utilisateur_nom: Optional[str] = None
    canne_version: Optional[str] = None

class StaffMySQL(BaseModel):
    cin: str
    nom: str
    email: EmailStr
    mot_de_passe: str
    numero_de_telephone: Optional[str] = None
    adresse: Optional[str] = None
    role: str = "staff"  # admin, staff
    poste_periode_travail: Optional[str] = None  # matin, soir
    cree_le: Optional[datetime] = None
    mis_a_jour_le: Optional[datetime] = None
    admin_cin: Optional[str] = None

class Admin(BaseModel):
    cin: str
    nom: str
    email: EmailStr
    mot_de_passe: str

# --- Modèles pour les opérations CRUD ---

class CreateUtilisateurRequest(BaseModel):
    cin: str
    nom: str
    age: Optional[int] = None
    adresse: Optional[str] = None
    email: EmailStr
    numero_de_telephone: Optional[str] = None
    contact_familial: Optional[str] = None
    etat_de_sante: Optional[str] = None
    sim_de_la_canne: Optional[str] = None

class CreateCanneRequest(BaseModel):
    sim_de_la_canne: str
    version: Optional[str] = None
    statut: str = "disponible"
    type: Optional[str] = None

class CreateLocationRequest(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    date_de_location: date
    date_de_retour: Optional[date] = None

class CreateAbonnementRequest(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    type_d_abonnement: Optional[str] = None
    date_de_debut: date
    date_de_fin: Optional[date] = None

class CreateStaffRequest(BaseModel):
    cin: str
    nom: str
    email: EmailStr
    mot_de_passe: str
    numero_de_telephone: Optional[str] = None
    adresse: Optional[str] = None
    role: str = "staff"
    poste_periode_travail: Optional[str] = None

class UpdateUtilisateurRequest(BaseModel):
    nom: Optional[str] = None
    age: Optional[int] = None
    adresse: Optional[str] = None
    email: Optional[EmailStr] = None
    numero_de_telephone: Optional[str] = None
    contact_familial: Optional[str] = None
    etat_de_sante: Optional[str] = None
    sim_de_la_canne: Optional[str] = None

class UpdateCanneRequest(BaseModel):
    version: Optional[str] = None
    statut: Optional[str] = None
    type: Optional[str] = None

class UpdateStaffRequest(BaseModel):
    nom: Optional[str] = None
    email: Optional[EmailStr] = None
    mot_de_passe: Optional[str] = None
    numero_de_telephone: Optional[str] = None
    adresse: Optional[str] = None
    role: Optional[str] = None
    poste_periode_travail: Optional[str] = None

# --- Modèles de réponse ---

class DashboardStatsResponse(BaseModel):
    total_utilisateurs: int
    total_staff: int
    total_cannes: int
    cannes_disponibles: int
    cannes_louees: int
    cannes_vendues: int
    locations_actives: int
    abonnements_actifs: int

class UtilisateurResponse(BaseModel):
    cin: str
    nom: str
    age: Optional[int]
    email: str
    telephone: Optional[str]
    contact_familial: Optional[str]
    etat_de_sante: Optional[str]
    canne_attribuee: Optional[bool] = False
    cane_details: Optional[dict] = None
