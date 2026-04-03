from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import date, datetime

# --- Address & Subscription ---
class Address(BaseModel):
    city: str
    street: str
    postal_code: str

class Subscription(BaseModel):
    plan: str
    start_date: date
    expiry_date: date
    status: str

class CaneDetails(BaseModel):
    serial_number: str
    firmware_version: str
    last_sync: Optional[str] = None

class EmergencyContact(BaseModel):
    name: str
    relation: str
    phone: str

class MedicalInfo(BaseModel):
    blood_group: str
    condition: str
    notes: Optional[str] = None

# --- User (visually impaired person) ---
class UserDocument(BaseModel):
    user_id: str
    nom: str
    prenom: str
    birthday: date
    email: EmailStr
    phone_number_malvoyant: str
    phone_number_famille: str
    address: Optional[Address] = None
    subscription: Optional[Subscription] = None
    cane_details: Optional[CaneDetails] = None
    emergency_contacts: List[EmergencyContact] = []
    medical_info: Optional[MedicalInfo] = None
    status: str = "normal"  # normal / HELP / SOS
    is_online: bool = True
    latitude: float = 36.8065  # Default Tunis
    longitude: float = 10.1815

# --- Alert ---
class Alert(BaseModel):
    alert_id: str = ""
    user_id: str
    type: str  # "SOS" or "HELP"
    latitude: float
    longitude: float
    timestamp: str
    status: str = "active"  # active / resolved
    resolved_by: Optional[str] = None
    resolved_at: Optional[str] = None

# --- Staff / Admin ---
class StaffUser(BaseModel):
    staff_id: str
    name: str
    email: EmailStr
    password: str  # In production: hashed
    role: str  # "admin" or "staff"
    shift: str = "matin" # matin / soir

# --- Auth ---
class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    token: str
    role: str
    name: str
    staff_id: str
