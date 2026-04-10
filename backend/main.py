from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, List, Optional
from models import UserDocument, Alert, StaffUser, LoginRequest, TokenResponse, ResetRequest, ResetPassword, VerifyOTPRequest
import uvicorn
from datetime import datetime, timedelta
import uuid
import os
from dotenv import load_dotenv
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from fastapi import BackgroundTasks

app = FastAPI(title="Smart Cane API", version="2.0.0")
load_dotenv()

# Email Configuration
conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_FROM_NAME=os.getenv("MAIL_FROM_NAME"),
    MAIL_STARTTLS=os.getenv("MAIL_STARTTLS", "True") == "True",
    MAIL_SSL_TLS=os.getenv("MAIL_SSL_TLS", "False") == "True",
    USE_CREDENTIALS=os.getenv("USE_CREDENTIALS", "True") == "True",
    VALIDATE_CERTS=os.getenv("VALIDATE_CERTS", "True") == "True",
    TEMPLATE_FOLDER=os.path.join(os.path.dirname(__file__), 'templates')
)
fastmail = FastMail(conf)

# CORS for desktop app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== IN-MEMORY DATABASE ====================
db_staff: Dict[str, StaffUser] = {}
db_reset_codes: Dict[str, Dict] = {} # email -> {"code": str, "expires_at": datetime}
db_users: Dict[str, UserDocument] = {}
db_alerts: Dict[str, Alert] = {}

# Seed default admin account
db_staff["admin_001"] = StaffUser(
    staff_id="admin_001",
    name="Admin Principal",
    email="aifaalaa97@gmail.com",
    password="123456",
    role="admin",
    shift="matin"
)
db_staff["staff_001"] = StaffUser(
    staff_id="staff_001",
    name="Mohamed Ben Ali",
    email="staff@smartcane.com",
    password="staff123",
    role="staff",
    shift="soir"
)

# Seed demo users
db_users["user_001"] = UserDocument(
    user_id="user_001",
    nom="Ben Slama",
    prenom="Mohamed",
    birthday="1985-06-15",
    email="m.benslama@example.com",
    phone_number_malvoyant="+216 20 123 456",
    phone_number_famille="+216 55 987 654",
    status="normal",
    is_online=True,
    latitude=36.8065,
    longitude=10.1815
)
db_users["user_002"] = UserDocument(
    user_id="user_002",
    nom="Trabelsi",
    prenom="Fatma",
    birthday="1990-03-22",
    email="f.trabelsi@example.com",
    phone_number_malvoyant="+216 22 333 444",
    phone_number_famille="+216 55 111 222",
    status="normal",
    is_online=False,
    latitude=36.8190,
    longitude=10.1660
)
db_users["user_003"] = UserDocument(
    user_id="user_003",
    nom="Bouazizi",
    prenom="Ahmed",
    birthday="1978-11-05",
    email="a.bouazizi@example.com",
    phone_number_malvoyant="+216 25 555 666",
    phone_number_famille="+216 98 777 888",
    status="normal",
    is_online=True,
    latitude=36.7980,
    longitude=10.1720
)

# Seed demo alerts
db_alerts["alert_001"] = Alert(
    alert_id="alert_001",
    user_id="user_001",
    type="SOS",
    latitude=36.8065,
    longitude=10.1815,
    timestamp="2026-03-31T14:30:00Z",
    status="active"
)
db_alerts["alert_002"] = Alert(
    alert_id="alert_002",
    user_id="user_002",
    type="HELP",
    latitude=36.8190,
    longitude=10.1660,
    timestamp="2026-03-31T15:10:00Z",
    status="active"
)
db_alerts["alert_003"] = Alert(
    alert_id="alert_003",
    user_id="user_003",
    type="SOS",
    latitude=36.7980,
    longitude=10.1720,
    timestamp="2026-03-30T09:45:00Z",
    status="resolved",
    resolved_by="staff_001",
    resolved_at="2026-03-30T09:55:00Z"
)

# ==================== AUTH ====================
@app.post("/auth/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    for staff in db_staff.values():
        if staff.email.lower() == req.email.lower() and staff.password == req.password:
            # Simple token = staff_id (in production: use real JWT)
            return TokenResponse(
                token=f"token_{staff.staff_id}",
                role=staff.role,
                name=staff.name,
                staff_id=staff.staff_id
            )
    raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

@app.post("/auth/request-reset")
async def request_reset(req: ResetRequest, background_tasks: BackgroundTasks):
    print(f"DEBUG: Received request-reset for {req.email}")
    # Check if user exists
    user_exists = any(s.email.lower() == req.email.lower() for s in db_staff.values())
    if not user_exists:
        raise HTTPException(status_code=404, detail="Aucun compte associé à cet e-mail")
    
    import random
    code = str(random.randint(100000, 999999))
    expires_at = datetime.now() + timedelta(minutes=10)
    db_reset_codes[req.email] = {"code": code, "expires_at": expires_at}
    
    print("\n" + "="*50)
    print(f"AUTHENTICATION - PASSWORD RESET REQUEST")
    print(f"USER EMAIL: {req.email}")
    print(f"VERIFICATION CODE: {code}")
    print(f"EXPIRES AT: {expires_at.strftime('%H:%M:%S')}")
    print("="*50 + "\n")
    
    # Send real email in background
    message = MessageSchema(
        subject="Code de vérification Smart Cane",
        recipients=[req.email],
        template_body={"otp_code": code},
        subtype=MessageType.html,
    )
    background_tasks.add_task(fastmail.send_message, message, template_name="otp_email.html")
    
    return {"status": "success", "message": "Code de vérification généré et envoyé par e-mail"}

@app.post("/auth/verify-otp")
async def verify_otp(req: VerifyOTPRequest):
    print(f"DEBUG: Received verify-otp for {req.email} with code {req.code}")
    if req.email not in db_reset_codes:
        raise HTTPException(status_code=400, detail="Aucune demande en cours")
    
    reset_data = db_reset_codes[req.email]
    if datetime.now() > reset_data["expires_at"]:
        del db_reset_codes[req.email]
        raise HTTPException(status_code=400, detail="Le code a expiré (limite 10 min)")
        
    if req.code != reset_data["code"]:
        raise HTTPException(status_code=400, detail="Code de vérification incorrect")
    
    return {"status": "success", "message": "Code vérifié"}

@app.post("/auth/reset-password")
async def reset_password(req: ResetPassword):
    print(f"DEBUG: Received reset-password for {req.email}")
    # Security check: must have a pending reset code (meaning OTP was verified in the previous step)
    if req.email not in db_reset_codes:
        raise HTTPException(status_code=400, detail="Action non autorisée ou session expirée")
    
    # Update password in db_staff
    for staff_id, staff in db_staff.items():
        if staff.email == req.email:
            staff.password = req.new_password
            del db_reset_codes[req.email]
            print(f"SUCCESS: Password updated for {req.email}")
            return {"status": "success", "message": "Mot de passe mis à jour"}
            
    raise HTTPException(status_code=404, detail="Utilisateur non trouvé")

# ==================== DASHBOARD STATS ====================
@app.get("/dashboard/stats")
async def get_dashboard_stats():
    total_users = len(db_users)
    active_alerts = sum(1 for a in db_alerts.values() if a.status == "active")
    sos_count = sum(1 for a in db_alerts.values() if a.type == "SOS" and a.status == "active")
    help_count = sum(1 for a in db_alerts.values() if a.type == "HELP" and a.status == "active")
    resolved_count = sum(1 for a in db_alerts.values() if a.status == "resolved")
    online_count = sum(1 for u in db_users.values() if u.is_online)
    return {
        "total_users": total_users,
        "online_users": online_count,
        "active_alerts": active_alerts,
        "sos_count": sos_count,
        "help_count": help_count,
        "resolved_count": resolved_count,
    }

# Helper to check if a user has an active alert
def has_active_alert(user_id: str) -> bool:
    return any(a.user_id == user_id and a.status == "active" for a in db_alerts.values())

# ==================== USERS ====================
@app.get("/users", response_model=List[UserDocument])
async def get_all_users():
    users = []
    for u in db_users.values():
        u_copy = u.model_copy()
        if not has_active_alert(u.user_id):
            u_copy.latitude = None
            u_copy.longitude = None
        users.append(u_copy)
    return users

@app.get("/users/{user_id}", response_model=UserDocument)
async def get_user(user_id: str):
    if user_id not in db_users:
        raise HTTPException(status_code=404, detail="User not found")
    u = db_users[user_id].model_copy()
    if not has_active_alert(user_id):
        u.latitude = None
        u.longitude = None
    return u

@app.post("/users", response_model=UserDocument)
async def create_or_update_user(user: UserDocument):
    if not user.user_id:
        user.user_id = f"user_{uuid.uuid4().hex[:8]}"
    db_users[user.user_id] = user
    return user

# ==================== ALERTS ====================
@app.post("/alerts")
async def receive_alert(alert: Alert):
    alert.alert_id = f"alert_{uuid.uuid4().hex[:8]}"
    alert.status = "active"
    db_alerts[alert.alert_id] = alert

    # Update user status
    if alert.user_id in db_users:
        db_users[alert.user_id].status = alert.type

    print(f"!!! {alert.type} ALERT from {alert.user_id} !!!")
    return {"status": "success", "alert_id": alert.alert_id}

@app.get("/alerts", response_model=List[Alert])
async def get_all_alerts():
    return list(db_alerts.values())

@app.get("/alerts/active", response_model=List[Alert])
async def get_active_alerts():
    return [a for a in db_alerts.values() if a.status in ["active", "processing", "reopened"]]

@app.get("/alerts/history", response_model=List[Alert])
async def get_alerts_history():
    return [a for a in db_alerts.values() if a.status == "resolved"]

@app.delete("/alerts/history")
async def clear_alerts_history():
    global db_alerts
    # Keep only active alerts
    db_alerts = {k: v for k, v in db_alerts.items() if v.status != "resolved"}
    return {"status": "success", "message": "Alert history cleared"}

@app.put("/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str, staff_id: str = "staff_001", staff_name: str = "Staff"):
    if alert_id not in db_alerts:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = db_alerts[alert_id]
    alert.status = "resolved"
    alert.resolved_by = staff_id
    alert.resolved_by_name = staff_name
    alert.resolved_at = datetime.now().isoformat()
    # Clear take status when resolved
    alert.taken_by = None
    alert.taken_by_name = None

    # Reset user status
    if alert.user_id in db_users:
        db_users[alert.user_id].status = "normal"

    return {"status": "success", "message": f"Alert {alert_id} resolved"}

@app.put("/alerts/{alert_id}/reactivate")
async def reactivate_alert(alert_id: str, staff_id: str, staff_name: str):
    if alert_id not in db_alerts:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = db_alerts[alert_id]
    
    # RBAC check: only the person who resolved it or any admin can reactivate
    is_admin = db_staff.get(staff_id) and db_staff[staff_id].role == "admin"
    if staff_id != alert.resolved_by and not is_admin:
        raise HTTPException(status_code=403, detail="Only the person who resolved this alert or an Admin can reactivate it")

    alert.status = "reopened"
    alert.reactivated_by = staff_id
    alert.reactivated_by_name = staff_name
    alert.reactivated_at = datetime.now().isoformat()
    
    # Assign it back to the person who reactivated it (processing state)
    alert.taken_by = staff_id
    alert.taken_by_name = staff_name
    
    # Restore user status
    if alert.user_id in db_users:
        db_users[alert.user_id].status = alert.type
        
    return {"status": "success", "message": f"Alert {alert_id} reactivated"}

@app.put("/alerts/{alert_id}/take")
async def take_alert(alert_id: str, staff_id: str, staff_name: str):
    if alert_id not in db_alerts:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = db_alerts[alert_id]
    if alert.taken_by and alert.taken_by != staff_id:
        raise HTTPException(status_code=400, detail=f"Alert already taken by {alert.taken_by_name}")
    alert.taken_by = staff_id
    alert.taken_by_name = staff_name
    alert.status = "processing"
    return {"status": "success", "message": f"Alert {alert_id} taken by {staff_name}"}

@app.put("/alerts/{alert_id}/release")
async def release_alert(alert_id: str):
    if alert_id not in db_alerts:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = db_alerts[alert_id]
    alert.taken_by = None
    alert.taken_by_name = None
    return {"status": "success", "message": f"Alert {alert_id} released"}

# ==================== STAFF ====================
@app.get("/staff", response_model=List[StaffUser])
async def get_all_staff():
    return list(db_staff.values())

@app.post("/staff", response_model=StaffUser)
async def create_staff(staff: StaffUser):
    if not staff.staff_id:
        import uuid
        staff.staff_id = f"staff_{uuid.uuid4().hex[:8]}"
    db_staff[staff.staff_id] = staff
    return staff

@app.put("/staff/{staff_id}", response_model=StaffUser)
async def update_staff(staff_id: str, updated_staff: StaffUser):
    if staff_id not in db_staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    # Preserve original password if not provided in update (optional logic)
    if not updated_staff.password:
        updated_staff.password = db_staff[staff_id].password
    db_staff[staff_id] = updated_staff
    return updated_staff

# ==================== PERFORMANCE (Admin) ====================
@app.get("/performance")
async def get_staff_performance():
    performance = {}
    for staff in db_staff.values():
        resolved = sum(1 for a in db_alerts.values() if a.resolved_by == staff.staff_id and a.status == "resolved")
        pending = sum(1 for a in db_alerts.values() if a.status == "active")
        processed = resolved  # Simplification for demo
        
        performance[staff.staff_id] = {
            "staff_name": staff.name,
            "role": staff.role,
            "shift": staff.shift,
            "alerts_processed": processed,
            "alerts_resolved": resolved,
            "alerts_pending": pending,
        }
    return performance

@app.get("/")
async def root():
    return {"message": "Smart Cane API v2.0 — Dashboard Ready"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
