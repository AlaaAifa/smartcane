import os
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from backend import models, schemas, security
from backend.database import get_db
from backend.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    admin_email = os.getenv("ADMIN_EMAIL")
    
    # 1. Vérifier la base de données
    user = db.query(models.Staff).filter(models.Staff.email == req.email).first()
    
    if user:
        # Si l'utilisateur existe en base, on utilise UNIQUEMENT le mot de passe de la base
        if security.verify_password(req.password, user.password_login):
            # Priorité à l'email admin défini dans le .env, sinon on prend le rôle de la base
            role = "admin" if req.email == admin_email else user.role
            return {
                "token": f"token_{user.cin}",
                "role": role,
                "name": user.nom,
                "staff_id": user.cin,
                "photo_url": user.photo_url
            }
        else:
            # Mot de passe incorrect pour un utilisateur existant
            raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    # 2. Authentification Admin Fallback (via .env) - UNIQUEMENT si l'admin n'est pas encore en base
    admin_password_env = os.getenv("ADMIN_PASSWORD")
    if req.email == admin_email:
        if req.password == admin_password_env:
            return {
                "token": "admin_mock_token_123456789",
                "role": "admin",
                "name": "System Admin",
                "staff_id": "admin_001"
            }
    
    raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

@router.post("/request-reset")
async def request_reset(req: schemas.PasswordResetRequest, db: Session = Depends(get_db)):
    success, message = await auth_service.request_password_reset(db, req.email)
    if not success:
        raise HTTPException(status_code=404, detail=message)
    return {"message": message}

@router.post("/verify-otp")
def verify_otp(req: schemas.OTPVerificationRequest, db: Session = Depends(get_db)):
    is_valid, message = auth_service.verify_otp(db, req.email, req.code)
    if not is_valid:
        raise HTTPException(status_code=400, detail=message)
    return {"message": message}

@router.post("/reset-password")
def reset_password(req: schemas.PasswordResetConfirm, db: Session = Depends(get_db)):
    success, message = auth_service.reset_password(db, req.email, req.code, req.new_password)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {"message": message}
