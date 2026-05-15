from datetime import date, datetime
from typing import Optional, Union, Literal

from pydantic import BaseModel, EmailStr, Field


class UtilisateurBase(BaseModel):
    cin: str
    nom: str
    age: Optional[int] = None
    adresse: Optional[str] = None
    email: EmailStr
    numero_de_telephone: Optional[str] = None
    role: str
    photo_url: Optional[str] = None


class UtilisateurCreate(UtilisateurBase):
    pass


class UtilisateurUpdate(BaseModel):
    nom: Optional[str] = None
    age: Optional[int] = None
    adresse: Optional[str] = None
    email: Optional[EmailStr] = None
    numero_de_telephone: Optional[str] = None
    role: Optional[str] = None
    photo_url: Optional[str] = None


class Utilisateur(UtilisateurBase):
    cree_le: datetime

    class Config:
        from_attributes = True


class ClientBase(UtilisateurBase):
    contact_familial: Optional[str] = None
    etat_de_sante: Optional[str] = None
    sim_de_la_canne: Optional[str] = None


class ClientCreate(ClientBase):
    role: Literal["client"] = "client"


class ClientUpdate(UtilisateurUpdate):
    contact_familial: Optional[str] = None
    etat_de_sante: Optional[str] = None
    sim_de_la_canne: Optional[str] = None


class Client(ClientBase):
    cree_le: datetime

    class Config:
        from_attributes = True


class StaffBase(UtilisateurBase):
    shift: Optional[str] = "matin"


class StaffCreate(StaffBase):
    password_login: str
    role: Literal["staff", "admin"] = "staff"


class StaffUpdate(UtilisateurUpdate):
    password_login: Optional[str] = None
    shift: Optional[str] = None


class Staff(StaffBase):
    cree_le: datetime

    class Config:
        from_attributes = True


class CanneBase(BaseModel):
    sim_de_la_canne: str
    version: Optional[str] = None
    statut: Optional[str] = "disponible"
    type: Optional[str] = None


class CanneCreate(CanneBase):
    pass


class CanneUpdate(BaseModel):
    version: Optional[str] = None
    statut: Optional[str] = None
    type: Optional[str] = None


class Canne(CanneBase):
    class Config:
        from_attributes = True


class LocationBase(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    date_de_location: Optional[date] = None
    date_de_retour: Optional[date] = None


class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    sim_de_la_canne: Optional[str] = None
    cin_utilisateur: Optional[str] = None
    date_de_location: Optional[date] = None
    date_de_retour: Optional[date] = None


class Location(LocationBase):
    id: int
    date_de_location: date

    class Config:
        from_attributes = True


class AbonnementBase(BaseModel):
    sim_de_la_canne: str
    cin_utilisateur: str
    type_d_abonnement: Optional[str] = None
    date_de_fin: Optional[date] = None


class AbonnementCreate(AbonnementBase):
    pass


class AbonnementUpdate(BaseModel):
    sim_de_la_canne: Optional[str] = None
    cin_utilisateur: Optional[str] = None
    type_d_abonnement: Optional[str] = None
    date_de_debut: Optional[date] = None
    date_de_fin: Optional[date] = None


class Abonnement(AbonnementBase):
    id: int
    date_de_debut: date

    class Config:
        from_attributes = True


class AlertBase(BaseModel):
    user_id: Optional[str] = None
    type: str
    latitude: float
    longitude: float
    cane_status: Optional[str] = "normal"


class AlertCreate(AlertBase):
    alert_id: str
    status: Optional[str] = "active"
    resolved_by: Optional[str] = None
    resolved_at: Optional[datetime] = None
    response_time: Optional[str] = None


class AlertUpdate(BaseModel):
    user_id: Optional[str] = None
    type: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: Optional[str] = None
    cane_status: Optional[str] = None
    resolved_by: Optional[str] = None
    resolved_at: Optional[datetime] = None
    taken_by: Optional[str] = None
    response_time: Optional[str] = None
    reactivated_by: Optional[str] = None
    reactivated_at: Optional[datetime] = None


class Alert(AlertBase):
    alert_id: str
    timestamp: datetime
    status: str
    cane_status: str
    resolved_by: Optional[str] = None
    resolved_at: Optional[datetime] = None
    taken_by: Optional[str] = None
    response_time: Optional[str] = None
    reactivated_by: Optional[str] = None
    reactivated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class PasswordResetRequest(BaseModel):
    email: EmailStr

class OTPVerificationRequest(BaseModel):
    email: EmailStr
    code: str

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str
    new_password: str

class MessageReplyRequest(BaseModel):
    email: EmailStr
    subject: str
    reply_body: str
    original_message: str
