import os
import random
import datetime
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from dotenv import load_dotenv
from backend import models, schemas, security

# Load environment variables
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
load_dotenv(env_path)

conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_FROM_NAME=os.getenv("MAIL_FROM_NAME", "Smart Cane Support"),
    MAIL_STARTTLS=os.getenv("MAIL_STARTTLS", "True") == "True",
    MAIL_SSL_TLS=os.getenv("MAIL_SSL_TLS", "False") == "True",
    USE_CREDENTIALS=os.getenv("USE_CREDENTIALS", "True") == "True",
    VALIDATE_CERTS=os.getenv("VALIDATE_CERTS", "True") == "True",
    TEMPLATE_FOLDER=os.path.join(os.path.dirname(os.path.dirname(__file__)), "tools", "templates")
)

async def send_otp_email(email: str, otp: str):
    message = MessageSchema(
        subject="Smart Cane - Verification Code",
        recipients=[email],
        template_body={"otp_code": otp},
        subtype=MessageType.html
    )
    fm = FastMail(conf)
    await fm.send_message(message, template_name="otp_email.html")

def generate_otp() -> str:
    return "".join([str(random.randint(0, 9)) for _ in range(6)])

async def request_password_reset(db: Session, email: str) -> Tuple[bool, str]:
    admin_email = os.getenv("ADMIN_EMAIL")
    user = db.query(models.Staff).filter(models.Staff.email == email).first()
    
    if not user and email != admin_email:
        return False, "Utilisateur non trouvé"
    
    otp = generate_otp()
    expires_at = datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
    
    db_reset_code = db.query(models.ResetCode).filter(models.ResetCode.email == email).first()
    if db_reset_code:
        db_reset_code.code = otp
        db_reset_code.expires_at = expires_at
    else:
        db_reset_code = models.ResetCode(email=email, code=otp, expires_at=expires_at)
        db.add(db_reset_code)
    
    db.commit()
    
    try:
        await send_otp_email(email, otp)
        print(f"OTP sent to {email}: {otp}")
        return True, "Code envoyé avec succès"
    except Exception as e:
        print(f"Error sending email: {e}")
        print(f"FALLBACK OTP for {email}: {otp}")
        return True, f"Code généré (vérifiez la console): {otp}"

def verify_otp(db: Session, email: str, code: str) -> Tuple[bool, str]:
    db_reset_code = db.query(models.ResetCode).filter(models.ResetCode.email == email).first()
    
    if not db_reset_code:
        return False, "Aucun code demandé pour cet email"
    
    if db_reset_code.is_expired():
        return False, "Le code a expiré"
    
    if db_reset_code.code != code:
        return False, "Code incorrect"
    
    return True, "Code valide"

def reset_password(db: Session, email: str, code: str, new_password: str) -> Tuple[bool, str]:
    is_valid, message = verify_otp(db, email, code)
    if not is_valid:
        return False, message
    
    admin_email = os.getenv("ADMIN_EMAIL")
    user = db.query(models.Staff).filter(models.Staff.email == email).first()
    
    hashed_password = security.get_password_hash(new_password)
    
    if not user:
        if email == admin_email:
            user = models.Staff(
                cin="ADMIN_SYS",
                nom="System Admin",
                email=email,
                password_login=hashed_password,
                role="staff",
                shift="matin"
            )
            db.add(user)
        else:
            return False, "Utilisateur non trouvé"
    else:
        user.password_login = hashed_password
    
    db.delete(db.query(models.ResetCode).filter(models.ResetCode.email == email).first())
    db.commit()
    
    return True, "Mot de passe réinitialisé avec succès"
