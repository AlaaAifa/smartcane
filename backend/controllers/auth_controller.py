import os
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from backend import models
from backend.database import get_db

router = APIRouter(prefix="/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    admin_email = os.getenv("ADMIN_EMAIL")
    admin_password = os.getenv("ADMIN_PASSWORD")

    # 1. Authentification Admin (via .env)
    if req.email == admin_email and req.password == admin_password:
        return {
            "token": "admin_mock_token_123456789",
            "role": "admin",
            "name": "System Admin",
            "staff_id": "admin_001"
        }
    
    # 2. Authentification Staff (via Database)
    staff = db.query(models.Staff).filter(models.Staff.email == req.email).first()
    
    if staff and staff.password_login == req.password:
        return {
            "token": f"staff_mock_token_{staff.cin}",
            "role": "staff",
            "name": staff.nom,
            "staff_id": staff.cin
        }
    
    raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
